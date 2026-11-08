#!/usr/bin/env node
// Confere guia.json (saida do gerar-guia.mjs). Codigo 1 se algo falhar.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const aqui = path.dirname(fileURLToPath(import.meta.url));
const g = JSON.parse(fs.readFileSync(path.join(aqui, 'guia.json'), 'utf8'));
const temSaltii = fs.existsSync(path.join(aqui, 'saltii.json'));
const erros = [];
const falha = (m) => erros.push(m);

if (g.familias.length < 18) falha(`menos de 18 familias (${g.familias.length})`);
const cat = g.familias.find((f) => f.nome === 'Cat');
for (const h of ['Claw', 'Bite', 'Dash', 'Prowl']) if (!cat?.habilidades.includes(h)) falha(`Cat sem ${h}`);
const claw3 = g.habilidades.Claw?.ranks.find((r) => r.r === 3);
if (!claw3 || claw3.pet !== 16 || claw3.pt !== 7) falha(`Claw 3 deveria ser pet 16 e pt 7: ${JSON.stringify(claw3 && { pet: claw3.pet, pt: claw3.pt })}`);
if (temSaltii) {
  const p0 = claw3?.prof?.[0];
  if (!p0 || p0.n !== 'Black Bear Patriarch' || p0.s !== true) falha(`primeiro professor de Claw 3: ${JSON.stringify(p0)}`);
}
const td1 = g.habilidades["Trickster's Dance"]?.ranks.find((r) => r.r === 1);
if (!td1?.prof?.some((p) => p.n === 'Gray Fox')) falha("Trickster's Dance 1 sem Gray Fox");
const gs = g.habilidades['Great Stamina'];
if (!gs || gs.ranks.length !== 10) falha(`Great Stamina com ${gs?.ranks.length} ranks (esperado 10)`);
if (!gs?.treinador || gs.ranks.some((r) => r.prof)) falha('Great Stamina deveria ser treinador sem prof');

function texto(onde, campo, v, max) {
  if (typeof v !== 'string') return;
  if (/[^\x00-\x7f]/.test(v)) falha(`${onde}.${campo} com caractere fora do ASCII: ${v}`);
  if (max && v.length > max) falha(`${onde}.${campo} com ${v.length} caracteres`);
}
for (const r of g.regras) texto('regras', 't', r.t, 160);
for (const f of g.familias) {
  for (const n of f.notas) texto(f.nome + '.notas', 't', n.t, 160);
  for (const r of f.rapidas) { texto(f.nome + '.rapidas', 'n', r.n); texto(f.nome + '.rapidas', 'z', r.z); }
}
let ranks = 0, comProf = 0, sMarcados = 0;
for (const [nome, h] of Object.entries(g.habilidades)) {
  texto(nome, 'desc', h.desc, 160);
  for (const r of h.ranks) {
    ranks++;
    if (r.prof) comProf++;
    for (const p of r.prof || []) {
      texto(`${nome} ${r.r}`, 'n', p.n); texto(`${nome} ${r.r}`, 'z', p.z);
      if (p.s) sMarcados++;
    }
  }
}
console.log(`Familias ${g.familias.length}, habilidades ${Object.keys(g.habilidades).length}, ranks ${ranks}, ranks com professor ${comProf}, professores do Saltii marcados ${sMarcados}, divergencias ${g.divergencias?.length ?? 0}, descartados ${g.descartados?.length ?? 0} (saltii.json ${temSaltii ? 'presente' : 'ausente'})`);
if (erros.length) { for (const e of erros) console.error('FALHA: ' + e); process.exit(1); }
console.log('OK');
