// Checa os .lua de um addon sem interpretador: sintaxe Lua 5.1, so ASCII, e lista as
// variaveis globais que cada arquivo usa (para conferir contra a API do jogo).
// Uso: node checar-lua.mjs <pasta do addon> [--globais]
import { createRequire } from 'node:module';
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const require = createRequire(import.meta.url);
const luaparse = require('luaparse');
const pasta = process.argv[2];
const mostrarGlobais = process.argv.includes('--globais');
if (!pasta) { console.error('uso: node checar-lua.mjs <pasta do addon> [--globais]'); process.exit(2); }

let falhas = 0;
for (const arq of readdirSync(pasta).filter(f => f.endsWith('.lua')).sort()) {
  const texto = readFileSync(join(pasta, arq), 'utf8');
  if (/[^\x00-\x7F]/.test(texto)) { console.log('ERRO ' + arq + ': caractere fora do ASCII'); falhas++; continue; }
  let ast;
  try { ast = luaparse.parse(texto, { luaVersion: '5.1', scope: true }); }
  catch (e) { console.log('ERRO ' + arq + ': ' + e.message); falhas++; continue; }
  console.log('ok   ' + arq);
  if (mostrarGlobais) {
    const g = new Set();
    (function andar(n) {
      if (!n || typeof n !== 'object') return;
      if (Array.isArray(n)) { n.forEach(andar); return; }
      if (n.type === 'Identifier' && n.isLocal === false) g.add(n.name);
      for (const k in n) if (k !== 'loc' && k !== 'range') andar(n[k]);
    })(ast);
    console.log('     globais: ' + [...g].sort().join(' '));
  }
}
process.exit(falhas ? 1 : 0);
