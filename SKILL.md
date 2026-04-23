---
name: html-to-pdf
description: Convert web pages or local HTML files into PDF using headless Chrome, and scaffold a deployable web API service for URL-to-PDF and URL-to-screenshot workflows. Use when asked to export a URL as PDF, convert an .html file to PDF, generate screenshots, or deploy HTML/PDF capture as a web service.
---

# HTML to PDF

## Quick Workflow

1. Validate input is either a URL (`http://` or `https://`) or a local HTML path.
2. Pick output path ending with `.pdf`.
3. Run `scripts/html_to_pdf.sh --input <url-or-file> --output <pdf-path>`.
4. Verify output with `ls -lh` and `pdfinfo`.

## Commands

```bash
# URL -> PDF
bash scripts/html_to_pdf.sh \
  --input "https://example.com" \
  --output "/tmp/example.pdf" \
  --wait-ms 12000 \
  --no-header

# Local HTML -> PDF
bash scripts/html_to_pdf.sh \
  --input "/path/page.html" \
  --output "/tmp/page.pdf" \
  --wait-ms 12000 \
  --no-header

# JS-heavy page with dark/gradient background -> readable print
bash scripts/html_to_pdf.sh \
  --input "/path/page.html" \
  --output "/tmp/page-readable.pdf" \
  --wait-ms 20000 \
  --no-header \
  --white-bg
```

## Script Behavior

- Auto-detect Chrome binary from common macOS/Linux paths.
- Accept URL or local `.html` file path.
- Convert local files to `file://` URLs automatically.
- Wait for JS-heavy pages with `--wait-ms`.
- Remove most default print header/footer markers with `--no-header`.
- Optionally force white background/black text for local HTML with `--white-bg`.
- Create output directory if missing.
- Fail fast with clear error messages.

## Validation

Run after each conversion:

```bash
ls -lh /path/output.pdf
pdfinfo /path/output.pdf | rg '^(Title|Pages|Page size):'
```

If `pdfinfo` is missing, use `file /path/output.pdf` as fallback.

## Deploy As Service

Generate a deployable service template:

```bash
bash scripts/scaffold_web_service.sh --output-dir /path/to/html-pdf-shot-service
```

The generated service provides:

- `POST /pdf` for URL -> PDF
- `POST /screenshot` for URL -> PNG/JPEG
- `GET /healthz` health check

Run locally:

```bash
cd /path/to/html-pdf-shot-service
npm install
npm start
```

Docker deploy (generic web platforms):

```bash
cd /path/to/html-pdf-shot-service
docker build -t html-pdf-shot-service .
docker run --rm -p 8080:8080 html-pdf-shot-service
```

Example API calls:

```bash
curl -X POST 'http://localhost:8080/pdf' \
  -H 'content-type: application/json' \
  -d '{"url":"https://learn.charliiai.com/","waitMs":2000}' \
  --output out.pdf

curl -X POST 'http://localhost:8080/screenshot' \
  -H 'content-type: application/json' \
  -d '{"url":"https://learn.charliiai.com/","waitMs":2000,"fullPage":true}' \
  --output out.png
```
