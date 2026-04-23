#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  html_to_pdf.sh --input <url-or-html-file> --output <output.pdf> [--timeout-ms <ms>] [--wait-ms <ms>] [--no-header] [--white-bg]

Options:
  --input       URL (http/https) or local HTML file path
  --output      Output PDF path (must end with .pdf)
  --timeout-ms  Optional process timeout in milliseconds (default: 120000)
  --wait-ms     Virtual time budget to let JS render before print (default: 12000)
  --no-header   Pass --print-to-pdf-no-header to Chrome
  --white-bg    For local HTML, inject a white-background/black-text override before printing
USAGE
}

INPUT=""
OUTPUT=""
TIMEOUT_MS="120000"
WAIT_MS="12000"
NO_HEADER="0"
WHITE_BG="0"
TMP_HTML=""

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
    --wait-ms)
      WAIT_MS="${2:-}"
      shift 2
      ;;
    --no-header)
      NO_HEADER="1"
      shift
      ;;
    --white-bg)
      WHITE_BG="1"
      shift
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

if [[ ! "$WAIT_MS" =~ ^[0-9]+$ ]]; then
  echo "--wait-ms must be an integer." >&2
  exit 2
fi

SOURCE_URL="$INPUT"
if [[ "$INPUT" =~ ^https?:// ]]; then
  if [[ "$WHITE_BG" == "1" ]]; then
    echo "--white-bg currently supports local HTML files only." >&2
    exit 2
  fi
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

  LOCAL_HTML="$INPUT"
  if [[ "$WHITE_BG" == "1" ]]; then
    TMP_HTML="$(mktemp /tmp/html-to-pdf.XXXXXX.html)"
    awk 'BEGIN{injected=0} {if(!injected && $0 ~ /<\/head>/){print "<style id=\"pdf-white-bg\">"; print "body { background: #ffffff !important; animation: none !important; background-size: auto !important; color: #111111 !important; }"; print "header, .subtitle, h1, h2, h3, h4, p, span, div, td, th { color: #111111 !important; }"; print ".stat-item, .controls, .table-container, .search-box input, .filter-btn, .detail-btn { background: #ffffff !important; border-color: #d1d5db !important; }"; print "</style>"; injected=1} print }' "$INPUT" > "$TMP_HTML"
    LOCAL_HTML="$TMP_HTML"
  fi

  if command -v python3 >/dev/null 2>&1; then
    SOURCE_URL="$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).resolve().as_uri())' "$LOCAL_HTML")"
  else
    ABS_PATH="$(cd "$(dirname "$LOCAL_HTML")" && pwd)/$(basename "$LOCAL_HTML")"
    SOURCE_URL="file://$ABS_PATH"
  fi
fi

cleanup() {
  if [[ -n "$TMP_HTML" && -f "$TMP_HTML" ]]; then
    rm -f "$TMP_HTML"
  fi
}
trap cleanup EXIT

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

# Build Chrome args.
CHROME_ARGS=(
  --headless=new
  --disable-gpu
  --no-sandbox
  --virtual-time-budget="$WAIT_MS"
  --print-to-pdf="$OUTPUT"
)

if [[ "$NO_HEADER" == "1" ]]; then
  CHROME_ARGS+=(--print-to-pdf-no-header)
fi

CHROME_ARGS+=("$SOURCE_URL")

# Use shell timeout when available; otherwise run directly.
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_SEC="$(((TIMEOUT_MS + 999) / 1000))"
  timeout "$TIMEOUT_SEC" "$CHROME" "${CHROME_ARGS[@]}"
else
  "$CHROME" "${CHROME_ARGS[@]}"
fi

if [[ ! -s "$OUTPUT" ]]; then
  echo "PDF was not generated or is empty: $OUTPUT" >&2
  exit 1
fi

echo "PDF generated: $OUTPUT"
