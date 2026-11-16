// Casos de preco fixo da calculadora. Uso: node testes/testar-crafts.mjs  (a partir de ferramentas/pregao)
// Sai com codigo 0 e "erros=0" quando calcular() devolve os campos esperados de testes/caso-base.json.
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const aqui = path.dirname(fileURLToPath(import.meta.url));
const { calcular } = await import('../crafts.mjs');
const base = JSON.parse(await readFile(path.join(aqui, 'caso-base.json'), 'utf8'));

function igual(a, b) {
  if (typeof a === 'number' && typeof b === 'number') return Math.abs(a - b) < 1e-6;
  if (a === null || b === null || typeof a !== 'object' || typeof b !== 'object') return a === b;
  if (Array.isArray(a) !== Array.isArray(b)) return false;
  if (Array.isArray(a)) {
    const x = [...a].map(String).sort(), y = [...b].map(String).sort();
    return x.length === y.length && x.every((v, i) => v === y[i]);
  }
  const ka = Object.keys(a).sort(), kb = Object.keys(b).sort();
  return ka.length === kb.length && ka.every((k, i) => k === kb[i] && igual(a[k], b[k]));
}

let erros = 0, conferidos = 0;
for (const caso of base.casos) {
  const precos = { ...base.precos, auctionator: caso.auctionator };
  const r = calcular(base.receitas, precos, { pericia: caso.pericia, agora: caso.agora });
  if (r.semPreco !== caso.semPreco) { erros++; console.log(`[${caso.nome}] semPreco: esperado ${caso.semPreco}, veio ${r.semPreco}`); }
  if (r.linhas.length !== base.receitas.receitas.length) { erros++; console.log(`[${caso.nome}] linhas: esperado ${base.receitas.receitas.length}, veio ${r.linhas.length}`); }
  for (const [magia, campos] of Object.entries(caso.esperado)) {
    const linha = r.linhas.find(l => String(l.magia) === magia);
    if (!linha) { erros++; console.log(`[${caso.nome}] magia ${magia}: linha ausente`); continue; }
    for (const [campo, esperado] of Object.entries(campos)) {
      conferidos++;
      const veio = linha[campo] === undefined ? null : linha[campo];
      if (!igual(veio, esperado)) { erros++; console.log(`[${caso.nome}] magia ${magia} ${campo}: esperado ${JSON.stringify(esperado)}, veio ${JSON.stringify(veio)}`); }
    }
  }
}
console.log(`casos=${base.casos.length} campos=${conferidos} erros=${erros}`);
process.exit(erros ? 1 : 0);
