#!/usr/bin/env node
// Confere o habilidades.json gerado por gerar-habilidades.mjs e imprime um resumo.
// Sai com código 1 se alguma checagem falhar.
//
// Uso: node checar-habilidades.mjs [arquivo.json]   (padrão: habilidades.json ao lado do script)

import { readFile } from 'node:fs/promises';
import path from 'node:path';

const arquivo = process.argv[2]
  ? path.resolve(process.argv[2])
  : path.join(import.meta.dirname, 'habilidades.json');

const dados = JSON.parse(await readFile(arquivo, 'utf8'));
const falhas = [];
const checa = (ok, msg) => { if (!ok) falhas.push(msg); };
const iguais = (a, b) => a.length === b.length && a.every((v, i) => v === b[i]);
const mesmoConjunto = (a, b) => a.length === b.length && [...a].sort().join('|') === [...b].sort().join('|');

const hab = dados.habilidades ?? {};
const familias = dados.familias ?? [];

// Bite: níveis e custos conferidos contra o cliente.
const bite = hab['Bite'];
checa(bite !== undefined, 'Bite ausente');
if (bite) {
  const niveis = bite.ranks.map((r) => r.nivelPet);
  const pts = bite.ranks.map((r) => r.pt);
  checa(iguais(niveis, [1, 8, 16, 24, 32, 40, 48, 56]), `Bite nivelPet esperado [1,8,16,24,32,40,48,56], veio [${niveis}]`);
  checa(iguais(pts, [1, 4, 7, 10, 13, 17, 21, 25]), `Bite pt esperado [1,4,7,10,13,17,21,25], veio [${pts}]`);
}

// Claw: 8 ranks.
const claw = hab['Claw'];
checa(claw !== undefined && claw.ranks.length === 8, `Claw deveria ter 8 ranks, tem ${claw ? claw.ranks.length : 'nenhum (ausente)'}`);

// Trickster's Dance: família Fox, rank 1, nível do pet 20.
const dance = hab["Trickster's Dance"];
const fox = familias.find((f) => f.nome === 'Fox');
const danceOk = dance !== undefined
  && dance.familias.includes('Fox')
  && dance.ranks.some((r) => r.rank === 1 && r.nivelPet === 20)
  && fox !== undefined && fox.habilidades.includes("Trickster's Dance");
checa(danceOk, "Fox sem Trickster's Dance rank 1 em nivelPet 20");

// Número de famílias de caçador.
checa(familias.length >= 18 && familias.length <= 19, `número de famílias ${familias.length}, esperado entre 18 e 19`);

// Dieta de Cat: Meat e Fish.
const cat = familias.find((f) => f.nome === 'Cat');
checa(cat !== undefined && mesmoConjunto(cat.dieta, ['Meat', 'Fish']), `dieta de Cat deveria ser Meat e Fish, veio [${cat ? cat.dieta : 'Cat ausente'}]`);

// Resumo.
console.log(`arquivo: ${arquivo}`);
console.log(`build ${dados.build}, gerado em ${dados.geradoEm}`);
console.log('');
for (const f of familias) {
  console.log(`${f.nome} (linha ${f.linha}, dieta ${f.dieta.join(', ') || '-'}): ${f.habilidades.length} habilidades`);
  console.log(`  ${f.habilidades.join(' | ')}`);
}
console.log('');
const totalRanks = Object.values(hab).reduce((s, h) => s + h.ranks.length, 0);
console.log(`famílias: ${familias.length}`);
console.log(`habilidades de família: ${Object.values(hab).filter((h) => !h.familias.includes('all')).length}`);
console.log(`habilidades no total: ${Object.keys(hab).length}, ranks: ${totalRanks}`);
console.log(`geral (linha 270): ${(dados.geral ?? []).length}, traços de velocidade: ${(dados.tracosVelocidade ?? []).length}`);
console.log(`duplicados de rank: ${(dados.duplicados ?? []).length}`);
console.log('');

if (falhas.length) {
  for (const m of falhas) console.log(`FALHA: ${m}`);
  console.log('resultado: FALHOU');
  process.exitCode = 1;
} else {
  console.log('resultado: OK');
}
