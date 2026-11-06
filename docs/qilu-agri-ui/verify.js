const fs = require('fs'), vm = require('vm'), path = require('path');
const dir = __dirname;
const app = fs.readFileSync(path.join(dir, 'assets/app.js'), 'utf8');
const defined = new Set([...app.matchAll(/^ {4}(\w+): *P\(/gm)].map(m => m[1]));

let bad = 0;
const files = fs.readdirSync(dir).filter(x => x.endsWith('.html')).sort();
for (const f of files) {
  const src = fs.readFileSync(path.join(dir, f), 'utf8');
  const errs = [];

  // 1) inline script syntax
  const scripts = [...src.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)];
  scripts.forEach((m, i) => {
    try { new vm.Script(m[1], { filename: f + '#' + i }); }
    catch (e) { errs.push('SYNTAX ' + e.message); }
  });

  // 2) icon references resolve
  const refs = new Set();
  for (const m of src.matchAll(/\bI\.([A-Za-z][A-Za-z0-9]*)/g)) refs.add(m[1]);
  for (const m of src.matchAll(/\['[a-z]\d+', *'[^']*', *'([A-Za-z][A-Za-z0-9]*)'\]/g)) refs.add(m[1]);
  for (const m of src.matchAll(/\[\['[a-z]\d+', *'[^']*', *'([A-Za-z][A-Za-z0-9]*)'\]\]/g)) refs.add(m[1]);
  const missing = [...refs].filter(x => !defined.has(x));

  // 3) leftover placeholder tokens
  const lm = src.match(/undefined|\[object Object\]|Lorem ipsum/);

  // 4) balanced backticks
  const ticks = (src.match(/`/g) || []).length;

  // 5) every <a href="x.html"> target must exist on disk
  const links = [...new Set([...src.matchAll(/href="([0-9A-Za-z_.-]+\.html)/g)].map(m => m[1]))];
  const dead = links.filter(h => !fs.existsSync(path.join(dir, h)));

  // 6) css/js asset refs
  const assets = [...new Set([...src.matchAll(/(?:href|src)="(assets\/[^"]+)"/g)].map(m => m[1]))];
  const missAssets = assets.filter(a => !fs.existsSync(path.join(dir, a)));

  const oddTicks = ticks % 2 !== 0;
  const ok = !errs.length && !missing.length && !lm && !oddTicks && !dead.length && !missAssets.length;
  if (!ok) bad++;
  console.log((ok ? 'PASS ' : 'FAIL ') + f.padEnd(26) +
    ' scripts=' + scripts.length + ' icons=' + refs.size + ' links=' + links.length +
    (missing.length ? '  MISSING_ICON:' + missing.join(',') : '') +
    (lm ? '  LEFTOVER:' + lm[0] : '') +
    (oddTicks ? '  ODD_BACKTICK:' + ticks : '') +
    (dead.length ? '  DEAD_LINK:' + dead.join(',') : '') +
    (missAssets.length ? '  MISSING_ASSET:' + missAssets.join(',') : '') +
    (errs.length ? '  ' + errs.join(' | ') : ''));
}
console.log('\n>> icons in library: ' + defined.size + ' | pages: ' + files.length);
console.log(bad ? '>> ' + bad + ' file(s) need fixes' : '>> ALL CLEAN');
