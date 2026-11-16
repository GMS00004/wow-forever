// Casos de preco fixo da rota. Uso: node testes/testar-rota.mjs  (a partir de ferramentas/pregao)
// Sai com codigo 0 e "erros=0" quando calcularRota() e textoLua() devolvem o esperado de testes/caso-rota.json.
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const aqui = path.dirname(fileURLToPath(import.meta.url));
const mod = await import('../rota.mjs');
const base = JSON.parse(await readFile(path.join(aqui, 'caso-base.json'), 'utf8'));
const rota = JSON.parse(await readFile(path.join(aqui, 'caso-rota.json'), 'utf8'));

function igual(a, b) {
  if (typeof a === 'number' && typeof b === 'number') return Math.abs(a - b) < 1e-6;
  if (a === null || b === null || typeof a !== 'object' || typeof b !== 'object') return a === b;
  if (Array.isArray(a) !== Array.isArray(b)) return false;
  if (Array.isArray(a)) return a.length === b.length && a.every((v, i) => igual(v, b[i]));
  const ka = Object.keys(a).sort(), kb = Object.keys(b).sort();
  return ka.length === kb.length && ka.every((k, i) => k === kb[i] && igual(a[k], b[k]));
}

let erros = 0, conferidos = 0;
const falha = (msg) => { erros++; console.log(msg); };
const confere = (rotulo, veio, esperado) => {
  conferidos++;
  if (!igual(veio === undefined ? null : veio, esperado)) falha(`${rotulo}: esperado ${JSON.stringify(esperado)}, veio ${JSON.stringify(veio)}`);
};

if (typeof mod.calcularRota !== 'function') falha('rota.mjs nao exporta calcularRota');
if (typeof mod.textoLua !== 'function') falha('rota.mjs nao exporta textoLua');

const precos = {
  ...base.precos,
  auctionator: null,
  publico: { ...base.precos.publico, historico: rota.historico, historicoDias: rota.historicoDias },
};

if (erros === 0) {
  for (const caso of rota.casos) {
    const r = mod.calcularRota(base.receitas, precos, { de: caso.de, ate: caso.ate, agora: rota.agora, sem: caso.sem, so: caso.so });
    const e = caso.esperado;
    const n = caso.nome.split(':')[0];
    confere(`[${n}] de`, r.de, caso.de);
    confere(`[${n}] ate`, r.ate, caso.ate);
    confere(`[${n}] chegou`, r.chegou, e.chegou);
    confere(`[${n}] parou`, r.parou, e.parou);
    for (const [k, v] of Object.entries(e.totais)) confere(`[${n}] totais.${k}`, r.totais && r.totais[k], v);
    confere(`[${n}] numero de passos`, r.passos && r.passos.length, e.passos.length);
    e.passos.forEach((pe, i) => {
      const p = (r.passos || [])[i] || {};
      for (const [k, v] of Object.entries(pe)) confere(`[${n}] passo ${i + 1} ${k}`, p[k], v);
    });
    if (e.lua) confere(`[${n}] textoLua`, mod.textoLua(r, '2026-11-16 15:04'), e.lua);
  }
}

console.log(`casos=${rota.casos.length} campos=${conferidos} erros=${erros}`);
process.exit(erros ? 1 : 0);
