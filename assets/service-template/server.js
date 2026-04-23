import express from 'express';
import { chromium } from 'playwright';

const app = express();
app.use(express.json({ limit: '1mb' }));

const PORT = Number(process.env.PORT || 8080);
const DEFAULT_WAIT_MS = Number(process.env.DEFAULT_WAIT_MS || 1500);
const DEFAULT_VIEWPORT_WIDTH = Number(process.env.DEFAULT_VIEWPORT_WIDTH || 1440);
const DEFAULT_VIEWPORT_HEIGHT = Number(process.env.DEFAULT_VIEWPORT_HEIGHT || 2200);

function parseUrl(input) {
  if (!input || typeof input !== 'string') {
    throw new Error('Missing url');
  }
  const parsed = new URL(input);
  if (!['http:', 'https:'].includes(parsed.protocol)) {
    throw new Error('Only http/https URLs are supported');
  }
  return parsed.toString();
}

async function withPage(options, fn) {
  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-dev-shm-usage']
  });

  try {
    const context = await browser.newContext({
      viewport: {
        width: Number(options.viewportWidth || DEFAULT_VIEWPORT_WIDTH),
        height: Number(options.viewportHeight || DEFAULT_VIEWPORT_HEIGHT)
      }
    });
    const page = await context.newPage();
    await fn(page);
    await context.close();
  } finally {
    await browser.close();
  }
}

app.get('/healthz', (_req, res) => {
  res.json({ ok: true, service: 'html-pdf-shot-service' });
});

app.post('/pdf', async (req, res) => {
  try {
    const url = parseUrl(req.body?.url);
    const waitMs = Number(req.body?.waitMs || DEFAULT_WAIT_MS);
    const format = req.body?.format || 'A4';
    const landscape = Boolean(req.body?.landscape);
    const printBackground = req.body?.printBackground !== false;

    let buffer;
    await withPage(req.body || {}, async (page) => {
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 120000 });
      if (waitMs > 0) {
        await page.waitForTimeout(waitMs);
      }
      buffer = await page.pdf({
        format,
        landscape,
        printBackground,
        margin: { top: '10mm', right: '10mm', bottom: '10mm', left: '10mm' }
      });
    });

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'inline; filename="export.pdf"');
    res.send(buffer);
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

app.post('/screenshot', async (req, res) => {
  try {
    const url = parseUrl(req.body?.url);
    const waitMs = Number(req.body?.waitMs || DEFAULT_WAIT_MS);
    const fullPage = req.body?.fullPage !== false;
    const type = req.body?.type === 'jpeg' ? 'jpeg' : 'png';

    let buffer;
    await withPage(req.body || {}, async (page) => {
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 120000 });
      if (waitMs > 0) {
        await page.waitForTimeout(waitMs);
      }
      buffer = await page.screenshot({
        fullPage,
        type,
        quality: type === 'jpeg' ? Number(req.body?.quality || 85) : undefined
      });
    });

    res.setHeader('Content-Type', type === 'jpeg' ? 'image/jpeg' : 'image/png');
    res.setHeader('Content-Disposition', `inline; filename="shot.${type}"`);
    res.send(buffer);
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`Service listening on :${PORT}`);
});
