/**
 * patch-server.js
 *
 * Runs at Docker build time to inject a /health endpoint and a safe root
 * handler into backend/server.js before the server is started.
 *
 * Injection point: the line immediately after `app.use(express.json())`.
 * If that line is not found the patch is appended just before the first
 * `app.listen(` call so the server still gets the routes.
 */

const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'backend', 'server.js');
let src = fs.readFileSync(serverPath, 'utf8');

const healthRoute = `
// --- Railway health check ---
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Safe root handler – serves index.html when it exists, falls back to health
app.get('/', (req, res, next) => {
  const indexPath = path.join(__dirname, '..', 'index.html');
  if (require('fs').existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.json({ status: 'ok' });
  }
});
// --- end Railway health check ---
`;

// Prefer to inject right after app.use(express.json())
const jsonMiddlewarePattern = /app\.use\(express\.json\(\)\);?/;
if (jsonMiddlewarePattern.test(src)) {
  src = src.replace(jsonMiddlewarePattern, (match) => match + '\n' + healthRoute);
  console.log('patch-server.js: injected health routes after express.json() middleware');
} else {
  // Fall back: inject before the first app.listen(
  const listenPattern = /app\.listen\(/;
  if (listenPattern.test(src)) {
    src = src.replace(listenPattern, healthRoute + '\napp.listen(');
    console.log('patch-server.js: injected health routes before app.listen()');
  } else {
    console.error('patch-server.js: could not find injection point – server.js unchanged');
    process.exit(1);
  }
}

fs.writeFileSync(serverPath, src, 'utf8');
console.log('patch-server.js: backend/server.js patched successfully');
