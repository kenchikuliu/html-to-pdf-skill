---
name: html-to-pdf
description: Convert web pages or local HTML files into PDF using headless Chrome. Use when asked to export a URL as PDF, convert an .html file to PDF, generate printable snapshots of pages, or batch-render links/doc pages for sharing/archiving.
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
  --output "/tmp/example.pdf"

# Local HTML -> PDF
bash scripts/html_to_pdf.sh \
  --input "/path/page.html" \
  --output "/tmp/page.pdf"
```

## Script Behavior

- Auto-detect Chrome binary from common macOS/Linux paths.
- Accept URL or local `.html` file path.
- Convert local files to `file://` URLs automatically.
- Create output directory if missing.
- Fail fast with clear error messages.

## Validation

Run after each conversion:

```bash
ls -lh /path/output.pdf
pdfinfo /path/output.pdf | rg '^(Title|Pages|Page size):'
```

If `pdfinfo` is missing, use `file /path/output.pdf` as fallback.
