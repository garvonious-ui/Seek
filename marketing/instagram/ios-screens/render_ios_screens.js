// Renders ios-screens/screens.html to PNG frame sequences with Playwright.
// Usage: node render_ios_screens.js jobs.json
//   jobs.json: [{ "out": "../ads/screens/ios/chat_night", "dur": 4.2, "fps": 30, "cfg": {...} }]
// Each job writes <out>/00000.png ... at 1170x2532 (390x844 @3x, iPhone 15/16)
// plus <out>.png (the last frame) as a still.
const fs = require('fs'), path = require('path'), http = require('http');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '..', '..', '..');
const MIME = { '.html': 'text/html', '.ttf': 'font/ttf', '.otf': 'font/otf', '.png': 'image/png' };

function serve() {
  return new Promise(resolve => {
    const s = http.createServer((req, res) => {
      const fp = path.join(REPO, decodeURIComponent(req.url.split('?')[0]));
      if (!fp.startsWith(REPO)) { res.writeHead(403); return res.end(); }
      fs.readFile(fp, (err, data) => {
        if (err) { res.writeHead(404); return res.end(); }
        res.writeHead(200, { 'Content-Type': MIME[path.extname(fp)] || 'application/octet-stream' }); res.end(data);
      });
    });
    s.listen(0, '127.0.0.1', () => resolve(s));
  });
}

(async () => {
  const jobs = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  const server = await serve(); const port = server.address().port;
  const browser = await chromium.launch();
  for (const job of jobs) {
    const out = path.resolve(path.dirname(process.argv[2]), job.out);
    fs.mkdirSync(out, { recursive: true });
    const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3 });
    page.on('pageerror', e => console.error('PAGEERR', e.message));
    await page.goto(`http://127.0.0.1:${port}/marketing/instagram/ios-screens/screens.html`, { waitUntil: 'networkidle' });
    await page.evaluate(cfg => window.init(cfg), job.cfg);
    await page.waitForTimeout(150);
    const n = Math.round(job.dur * job.fps);
    for (let f = 0; f < n; f++) {
      await page.evaluate(t => window.setT(t), f / job.fps);
      await page.screenshot({ path: path.join(out, String(f).padStart(5, '0') + '.png') });
    }
    fs.copyFileSync(path.join(out, String(n - 1).padStart(5, '0') + '.png'), out + '.png');
    console.log(`${path.basename(out)}: ${n} frames`);
    await page.close();
  }
  await browser.close(); server.close();
})();
