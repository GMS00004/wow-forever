// Checa os .lua de um addon sem interpretador: sintaxe Lua 5.1, so ASCII, e lista as
// variaveis globais que cada arquivo usa (para conferir contra a API do jogo).
// Uso: node checar-lua.mjs <pasta do addon> [--globais] [--so A.lua,B.lua]
// --so: confere so os arquivos listados (tarefas em paralelo na mesma pasta nao se atrapalham).
import { createRequire } from 'node:module';
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const require = createRequire(import.meta.url);
const luaparse = require('luaparse');
const pasta = process.argv[2];
const mostrarGlobais = process.argv.includes('--globais');
const iSo = process.argv.indexOf('--so');
const so = iSo >= 0 && process.argv[iSo + 1] ? new Set(process.argv[iSo + 1].split(',').map(s => s.trim()).filter(Boolean)) : null;
if (!pasta) { console.error('uso: node checar-lua.mjs <pasta do addon> [--globais] [--so A.lua,B.lua]'); process.exit(2); }

let falhas = 0;
const todos = readdirSync(pasta).filter(f => f.endsWith('.lua')).sort();
if (so) for (const f of so) if (!todos.includes(f)) { console.log('ERRO ' + f + ': pedido em --so e ausente na pasta'); falhas++; }
for (const arq of todos.filter(f => !so || so.has(f))) {
  const texto = readFileSync(join(pasta, arq), 'utf8');
  if (/[^\x00-\x7F]/.test(texto)) { console.log('ERRO ' + arq + ': caractere fora do ASCII'); falhas++; continue; }
  let ast;
  try { ast = luaparse.parse(texto, { luaVersion: '5.1', scope: true, locations: true }); }
  catch (e) { console.log('ERRO ' + arq + ': ' + e.message); falhas++; continue; }
  // Escape invalido em string entre aspas (2026-11-08): o Lua 5.1 aceita "\I" e guarda so o "I",
  // entao "Interface\Icons\X" vira "InterfaceIconsX" sem erro nenhum. Validos: \a \b \f \n \r \t
  // \v \\ \" \' \<quebra de linha> e \ddd. String longa ([[...]]) nao tem escape e fica de fora.
  const ruins = [];
  (function strings(n) {
    if (!n || typeof n !== 'object') return;
    if (Array.isArray(n)) { n.forEach(strings); return; }
    if (n.type === 'StringLiteral' && typeof n.raw === 'string' && (n.raw[0] === '"' || n.raw[0] === "'")) {
      const corpo = n.raw.slice(1, -1);
      for (let i = 0; i < corpo.length; i++) {
        if (corpo[i] !== '\\') continue;
        const c = corpo[i + 1];
        if (c === undefined || !/[abfnrtv\\"'\n\r0-9]/.test(c)) {
          ruins.push('linha ' + (n.loc ? n.loc.start.line : '?') + ': "\\' + (c || '') + '"');
        }
        i++;
      }
    }
    for (const k in n) if (k !== 'loc' && k !== 'range') strings(n[k]);
  })(ast);
  if (ruins.length) {
    console.log('ERRO ' + arq + ': escape invalido em string (o Lua 5.1 come a barra): ' + ruins.join('; '));
    falhas++;
    continue;
  }
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
