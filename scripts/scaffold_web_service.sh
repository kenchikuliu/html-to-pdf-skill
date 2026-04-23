#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scaffold_web_service.sh --output-dir <path>

Description:
  Copy the deployable Playwright web service template
  (/pdf and /screenshot endpoints) into <path>.
USAGE
}

OUTPUT_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      OUTPUT_DIR="${2:-}"
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

if [[ -z "$OUTPUT_DIR" ]]; then
  echo "--output-dir is required." >&2
  usage
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$SKILL_DIR/assets/service-template"

if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo "Template directory missing: $TEMPLATE_DIR" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
cp "$TEMPLATE_DIR/package.json" "$OUTPUT_DIR/package.json"
cp "$TEMPLATE_DIR/server.js" "$OUTPUT_DIR/server.js"
cp "$TEMPLATE_DIR/Dockerfile" "$OUTPUT_DIR/Dockerfile"

echo "Service template generated at: $OUTPUT_DIR"
