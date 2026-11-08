#!/usr/bin/env node
// Confere professores.json e feras.json gerados por gerar-professores.mjs.
// Falha (código 1) se algum professor de referência estiver faltando, se Broken Tooth não tiver velocidade 1.0 e
// família Cat, ou se houver menos de 200 feras. Imprime um resumo ao final.
// Uso: node checar-professores.mjs [pasta com os JSON] (padrão: esta pasta)

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const pasta = process.argv[2] ? path.resolve(process.argv[2]) : HERE;

const prof = JSON.parse(fs.readFileSync(path.join(pasta, 'professores.json'), 'utf8'));
const feras = JSON.parse(fs.readFileSync(path.join(pasta, 'feras.json'), 'utf8')).feras;
const ranks = prof.ranks;

const falhas = [];
const checar = (ok, texto) => { if (!ok) falhas.push(texto); return ok; };

const professoresDe = (chave) => ranks[chave]?.professores ?? null;
const temProfessor = (chave, trecho) => {
  const lista = professoresDe(chave);
  if (!lista) return false;
  return lista.some((p) => p.nome.includes(trecho));
};

checar(professoresDe('Claw 2') !== null, 'rank "Claw 2" ausente em professores.json');
checar(temProfessor('Claw 2', 'Strigid'), 'Claw 2 sem professor com "Strigid" no nome');
checar(temProfessor('Claw 3', 'Black Bear Patriarch'), 'Claw 3 sem professor com "Black Bear Patriarch" no nome');
checar(temProfessor("Trickster's Dance 1", 'Gray Fox'), "Trickster's Dance 1 sem professor com \"Gray Fox\" no nome");

const broken = Object.values(feras).find((f) => f.nome === 'Broken Tooth' && f.familia === 'Cat' && f.velocidade === 1);
checar(Boolean(broken), 'Broken Tooth ausente em feras.json com velocidade 1.0 e família Cat');

const totalFeras = Object.keys(feras).length;
checar(totalFeras >= 200, `feras.json tem ${totalFeras} feras (mínimo 200)`);

// Resumo
const chaves = Object.keys(ranks);
const comProf = chaves.filter((k) => ranks[k].professores.length > 0).length;
const semProf = chaves.length - comProf;
const divergencias = chaves.reduce((s, k) => s + (ranks[k].divergencias?.length ?? 0), 0);
const porFamilia = {};
for (const f of Object.values(feras)) {
  const fam = f.familia ?? '(sem família)';
  porFamilia[fam] = (porFamilia[fam] ?? 0) + 1;
}
const semNomeIngles = Object.values(feras).filter((f) => f.nomeIngles === false).length;

console.log(`Ranks: ${chaves.length}; com professor: ${comProf}; sem professor: ${semProf}`);
console.log(`Feras: ${totalFeras}; com velocidade: ${Object.values(feras).filter((f) => f.velocidade != null).length}; sem nome em inglês: ${semNomeIngles}`);
console.log('Feras por família:');
for (const [fam, n] of Object.entries(porFamilia).sort((a, b) => b[1] - a[1])) console.log(`  ${fam}: ${n}`);
console.log(`Divergências entre FHP e Petopia (nível do pet e custo): ${divergencias}`);
console.log(`Professores de referência: Claw 2 (Strigid), Claw 3 (Black Bear Patriarch), Trickster's Dance 1 (Gray Fox), Broken Tooth (Cat, 1.0)`);

if (falhas.length) {
  for (const f of falhas) console.error(`FALHA: ${f}`);
  console.error(`${falhas.length} checagem(ns) falharam`);
  process.exit(1);
}
console.log('OK: todas as checagens passaram');
