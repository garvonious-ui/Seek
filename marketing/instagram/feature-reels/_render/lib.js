// shared playwright helpers
const http = require('http');
const fs = require('fs');
const path = require('path');
const ROOT = __dirname;
const EXEC = path.join(ROOT, '.pw/chromium-1140/chrome-linux/chrome');
const MIME = { '.html': 'text/html', '.jsx': 'text/babel', '.css': 'text/css', '.ttf': 'font/ttf', '.js': 'text/javascript' };

function serve() {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      const u = decodeURIComponent(req.url.split('?')[0]);
      const fp = path.join(ROOT, u === '/' ? 'frame.html' : u);
      fs.readFile(fp, (err, data) => {
        if (err) { res.writeHead(404); res.end('nf'); return; }
        res.writeHead(200, { 'Content-Type': MIME[path.extname(fp)] || 'application/octet-stream' });
        res.end(data);
      });
    });
    server.listen(0, '127.0.0.1', () => resolve(server));
  });
}
module.exports = { serve, EXEC, ROOT };
