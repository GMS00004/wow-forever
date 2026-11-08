#!/usr/bin/env node
// Confere o textos.json (textos curtos em inglês do guia de pets do caçador) e imprime um resumo.
// Sai com código 1 se alguma checagem falhar.
//
// Uso: node checar-textos.mjs [arquivo.json]   (padrão: textos.json ao lado do script)

import { readFile } from 'node:fs/promises';
import path from 'node:path';

const arquivo = process.argv[2]
  ? path.resolve(process.argv[2])
  : path.join(import.meta.dirname, 'textos.json');

const FONTES = new Set([
  'Saltii',
  'LudiDeo (beta)',
  'Gladius (beta)',
  'Kargoz (beta)',
  'MetaGoblin (beta)',
  'Method',
  'Blizzard',
  'Petopia',
  'LudiDeo tier (beta)',
]);

const FAMILIAS = [
  'Cat', 'Raptor', 'Wind Serpent', 'Scorpid', 'Boar', 'Carrion Bird', 'Bear', 'Gorilla',
  'Turtle', 'Spider', 'Crab', 'Hyena', 'Crocolisk', 'Bat', 'Bird of Prey', 'Tallstrider',
  'Wolf', 'Fox',
];

const MAX_T = 160;
const ASCII = /^[\x20-\x7E]*$/;

let dados;
try {
  dados = JSON.parse(await readFile(arquivo, 'utf8'));
} catch (erro) {
  console.error(`FALHA: ${arquivo} não abre como JSON: ${erro.message}`);
  process.exit(1);
}

const falhas = [];
const checa = (ok, msg) => { if (!ok) falhas.push(msg); };

// Confere um par {t, f} (linha de texto com fonte).
function checaLinha(linha, onde) {
  if (!linha || typeof linha !== 'object') {
    checa(false, `${onde}: não é um objeto {t, f}`);
    return;
  }
  const { t, f } = linha;
  checa(typeof t === 'string' && t.length > 0, `${onde}: "t" vazio ou ausente`);
  if (typeof t === 'string' && t.length > 0) {
    checa(ASCII.test(t), `${onde}: "t" tem caractere fora do ASCII: ${t}`);
    checa(t.length <= MAX_T, `${onde}: "t" tem ${t.length} caracteres (máximo ${MAX_T}): ${t}`);
  }
  checa(FONTES.has(f), `${onde}: "f" fora da lista: ${f}`);
}

// regras
const regras = Array.isArray(dados.regras) ? dados.regras : [];
checa(Array.isArray(dados.regras), 'regras ausente ou não é lista');
checa(regras.length >= 10, `regras tem ${regras.length} linhas (mínimo 10)`);
regras.forEach((linha, i) => checaLinha(linha, `regras[${i}]`));

// familias
const familias = dados.familias ?? {};
checa(typeof familias === 'object' && !Array.isArray(familias), 'familias ausente ou não é objeto');
for (const nome of FAMILIAS) {
  const fam = familias[nome];
  checa(fam !== undefined, `família ausente: ${nome}`);
  if (!fam) continue;
  const notas = Array.isArray(fam.notas) ? fam.notas : [];
  checa(notas.length >= 2, `família ${nome} tem ${notas.length} notas (mínimo 2)`);
  notas.forEach((linha, i) => checaLinha(linha, `familias.${nome}.notas[${i}]`));
}
for (const nome of Object.keys(familias)) {
  checa(FAMILIAS.includes(nome), `família desconhecida no arquivo: ${nome}`);
}

// habilidades
const habilidades = dados.habilidades ?? {};
checa(typeof habilidades === 'object' && !Array.isArray(habilidades), 'habilidades ausente ou não é objeto');
const nomesHab = Object.keys(habilidades);
for (const nome of nomesHab) {
  checaLinha(habilidades[nome], `habilidades.${nome}`);
}

const notasTotal = FAMILIAS.reduce((soma, nome) => soma + (familias[nome]?.notas?.length ?? 0), 0);
const minNotas = Math.min(...FAMILIAS.map((nome) => familias[nome]?.notas?.length ?? 0));

if (falhas.length > 0) {
  console.error(`FALHAS (${falhas.length}):`);
  for (const f of falhas) console.error(`  - ${f}`);
  console.error(`textos.json: ${arquivo}`);
  process.exit(1);
}

console.log(`textos.json: ${arquivo}`);
console.log(`regras: ${regras.length} linhas (mínimo 10)`);
console.log(`familias: ${FAMILIAS.length} de 18; notas no total ${notasTotal}; menor número de notas por família ${minNotas}`);
console.log(`habilidades: ${nomesHab.length}`);
console.log('OK: todas as checagens passaram.');
