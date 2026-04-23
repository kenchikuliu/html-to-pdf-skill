#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  html_to_pdf.sh --input <url-or-html-file> --output <output.pdf> [--timeout-ms <ms>]

Options:
  --input       URL (http/https) or local HTML file path
  --output      Output PDF path (must end with .pdf)
  --timeout-ms  Optional process timeout in milliseconds (default: 120000)
USAGE
}

INPUT=""
OUTPUT=""
TIMEOUT_MS="120000"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)
      INPUT="${2:-}"
      shift 2
      ;;
    --output)
      OUTPUT="${2:-}"
      shift 2
      ;;
    --timeout-ms)
      TIMEOUT_MS="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$INPUT" || -z "$OUTPUT" ]]; then
  echo "Both --input and --output are required." >&2
  usage
  exit 2
fi

if [[ "$OUTPUT" != *.pdf ]]; then
  echo "Output path must end with .pdf: $OUTPUT" >&2
  exit 2
fi

if [[ ! "$TIMEOUT_MS" =~ ^[0-9]+$ ]]; then
  echo "--timeout-ms must be an integer." >&2
  exit 2
fi

SOURCE_URL="$INPUT"
if [[ "$INPUT" =~ ^https?:// ]]; then
  SOURCE_URL="$INPUT"
else
  if [[ ! -f "$INPUT" ]]; then
    echo "Local input file not found: $INPUT" >&2
    exit 2
  fi
  case "$INPUT" in
    *.html|*.htm) ;;
    *)
      echo "Local input should be an .html/.htm file: $INPUT" >&2
      exit 2
      ;;
  esac

  if command -v python3 >/dev/null 2>&1; then
    SOURCE_URL="$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).resolve().as_uri())' "$INPUT")"
  else
    ABS_PATH="$(cd "$(dirname "$INPUT")" && pwd)/$(basename "$INPUT")"
    SOURCE_URL="file://$ABS_PATH"
  fi
fi

CHROME=""
if command -v google-chrome >/dev/null 2>&1; then
  CHROME="$(command -v google-chrome)"
elif command -v chromium >/dev/null 2>&1; then
  CHROME="$(command -v chromium)"
elif [[ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]]; then
  CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
elif command -v chrome >/dev/null 2>&1; then
  CHROME="$(command -v chrome)"
fi

if [[ -z "$CHROME" ]]; then
  echo "No Chrome/Chromium binary found." >&2
  echo "Install Google Chrome or Chromium, then rerun." >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

# Use shell timeout when available; otherwise run directly.
if command -v timeout >/dev/null 2>&1; then
  timeout "$((TIMEOUT_MS / 1000))" "$CHROME" \
    --headless=new \
    --disable-gpu \
    --no-sandbox \
    --print-to-pdf="$OUTPUT" \
    "$SOURCE_URL"
else
  "$CHROME" \
    --headless=new \
    --disable-gpu \
    --no-sandbox \
    --print-to-pdf="$OUTPUT" \
    "$SOURCE_URL"
fi

if [[ ! -s "$OUTPUT" ]]; then
  echo "PDF was not generated or is empty: $OUTPUT" >&2
  exit 1
fi

echo "PDF generated: $OUTPUT"
