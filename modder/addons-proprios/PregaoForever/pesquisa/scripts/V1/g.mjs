// busca com caminho relativo curto. uso: node g.mjs <regex> <subpasta relativa a AddOns ou .> [contexto] [max] [filtroNomeArquivo]
import fs from 'node:fs';
import path from 'node:path';
const ROOT = '<espelho>/Interface/AddOns';
const [, , pat, sub = '.', ctxS = '0', maxS = '60', nameFilter = ''] = process.argv;
const re = new RegExp(pat);
const ctx = Number(ctxS), max = Number(maxS);
const nameRe = nameFilter ? new RegExp(nameFilter) : null;
let n = 0;
function walk(d) {
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, e.name);
    if (e.isDirectory()) { walk(p); if (n >= max) return; continue; }
    if (!/\.(lua|xml|toc)$/i.test(e.name)) continue;
    if (nameRe && !nameRe.test(p.replace(/\\/g, '/'))) continue;
    const lines = fs.readFileSync(p, 'utf8').split(/\r?\n/);
    for (let i = 0; i < lines.length; i++) {
      if (re.test(lines[i])) {
        const rel = path.relative(ROOT, p).replace(/\\/g, '/');
        const a = Math.max(0, i - ctx), b = Math.min(lines.length - 1, i + ctx);
        for (let j = a; j <= b; j++) console.log(`${rel}:${j + 1}${j === i ? ':' : '-'} ${lines[j].slice(0, 220)}`);
        if (ctx) console.log('--');
        if (++n >= max) return;
      }
    }
  }
}
const start = path.join(ROOT, sub);
if (fs.statSync(start).isFile()) {
  const lines = fs.readFileSync(start, 'utf8').split(/\r?\n/);
  for (let i = 0; i < lines.length && n < max; i++) if (re.test(lines[i])) {
    const a = Math.max(0, i - ctx), b = Math.min(lines.length - 1, i + ctx);
    for (let j = a; j <= b; j++) console.log(`${j + 1}${j === i ? ':' : '-'} ${lines[j].slice(0, 220)}`);
    if (ctx) console.log('--'); n++;
  }
} else walk(start);
console.log(`[${n} ocorrencias]`);
