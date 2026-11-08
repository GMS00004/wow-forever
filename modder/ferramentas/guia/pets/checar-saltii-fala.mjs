// Checa saltii-fala.json (regras, notas e habilidades da fala do Saltii) e a
// secao "Fala do video" da fonte markdown. Sai com 1 se algo falhar.
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const aqui = dirname(fileURLToPath(import.meta.url));
const jsonPath = resolve(aqui, 'saltii-fala.json');
const fontePath = resolve(aqui, '..', '..', '..', '..', 'comum', 'fontes', 'builds', 'saltii-hunter-pets.md');
const MAX = 160;
const erros = [];

let dados;
try {
  dados = JSON.parse(readFileSync(jsonPath, 'utf8'));
} catch (e) {
  console.error(`ERRO: ${jsonPath} nao abre como JSON: ${e.message}`);
  process.exit(1);
}

const regras = Array.isArray(dados.regras) ? dados.regras : [];
if (regras.length < 4) erros.push(`regras tem ${regras.length} linha(s), o minimo e 4`);

const itens = [];
regras.forEach((r, i) => itens.push({ rotulo: `regras[${i}]`, obj: r }));
const familias = dados.familias && typeof dados.familias === 'object' ? dados.familias : {};
for (const [fam, corpo] of Object.entries(familias)) {
  const notas = Array.isArray(corpo?.notas) ? corpo.notas : [];
  notas.forEach((n, i) => itens.push({ rotulo: `familias.${fam}.notas[${i}]`, obj: n }));
}
const habilidades = dados.habilidades && typeof dados.habilidades === 'object' ? dados.habilidades : {};
for (const [hab, obj] of Object.entries(habilidades)) {
  itens.push({ rotulo: `habilidades.${hab}`, obj });
}

for (const { rotulo, obj } of itens) {
  const t = obj?.t;
  if (typeof t !== 'string') {
    erros.push(`${rotulo}: falta o campo t`);
    continue;
  }
  if (/[^\x00-\x7F]/.test(t)) erros.push(`${rotulo}: caractere fora do ASCII`);
  if (t.length > MAX) erros.push(`${rotulo}: ${t.length} caracteres (maximo ${MAX})`);
  if (obj.f !== 'Saltii') erros.push(`${rotulo}: f="${obj.f}" (deve ser "Saltii")`);
}

let md;
try {
  md = readFileSync(fontePath, 'utf8');
} catch (e) {
  erros.push(`fonte nao lida: ${fontePath} (${e.message})`);
}
if (md !== undefined) {
  const m = md.search(/^## Fala do v.deo\s*$/m);
  if (m < 0) erros.push('fonte: secao "Fala do video" nao encontrada');
  else if (/pendente/i.test(md.slice(m))) erros.push('fonte: a secao "Fala do video" ainda contem "Pendente"');
}

if (erros.length) {
  for (const e of erros) console.error(`ERRO: ${e}`);
  console.error(`FALHOU: ${erros.length} problema(s)`);
  process.exit(1);
}

const nNotas = itens.length - regras.length - Object.keys(habilidades).length;
console.log(`OK: ${regras.length} regras, ${nNotas} notas de familia, ${Object.keys(habilidades).length} habilidades; todos os t em ASCII e até ${MAX} caracteres; fonte sem "Pendente" na fala.`);
process.exit(0);
