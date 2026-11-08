// Junta os textos do guia de pets num textos.json so, que o gerar-guia.mjs le.
// Entradas (nesta pasta): textos-base.json (regras, notas por familia e dicas por habilidade,
// escritos das fontes do dono em 2026-11-08), saltii-fala.json (o que a fala do video do Saltii traz
// de novo) e ludideo-tier.json (nota de leveling e de PvP e observacoes da tier list do LudiDeo).
// Idempotente: refaz o textos.json inteiro a cada execucao, sem repetir linha (mesmo texto).
// Uso: node juntar-textos.mjs   (depois: node checar-textos.mjs e node gerar-guia.mjs ...)
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const pasta = path.dirname(fileURLToPath(import.meta.url));
const ler = (nome, obrigatorio = true) => {
  const p = path.join(pasta, nome);
  if (!fs.existsSync(p)) {
    if (obrigatorio) throw new Error(`falta ${nome}`);
    return null;
  }
  return JSON.parse(fs.readFileSync(p, 'utf8'));
};

const base = ler('textos-base.json');
const fala = ler('saltii-fala.json', false);
const tier = ler('ludideo-tier.json', false);

const vistos = new Set();
const unico = (x) => {
  const k = x.t.trim().toLowerCase();
  if (vistos.has(k)) return false;
  vistos.add(k);
  return true;
};

// regras: os passos de aprender um rank (os que comecam com "Step") primeiro, depois as regras da fala
// do Saltii (onde fica o Beast Training, pular rank, Beast Lore...), depois o resto da base
const passos = base.regras.filter((r) => /^Step \d/.test(r.t));
const resto = base.regras.filter((r) => !/^Step \d/.test(r.t));
const regras = [...passos, ...(fala?.regras || []), ...resto].filter(unico);

// familias: a nota da tier list primeiro, depois a base, a fala do Saltii e as outras notas da tier list
const familias = {};
const nomes = new Set([
  ...Object.keys(base.familias || {}),
  ...Object.keys(fala?.familias || {}),
  ...Object.keys(tier?.familias || {}),
]);
for (const nome of nomes) {
  const t = tier?.familias?.[nome]?.notas || [];
  const lista = [
    ...t.slice(0, 1),
    ...(base.familias?.[nome]?.notas || []),
    ...(fala?.familias?.[nome]?.notas || []),
    ...t.slice(1),
  ].filter(unico);
  familias[nome] = { notas: lista };
}

// habilidades: uma linha por habilidade; a da base vale, a da fala entra onde a base nao tem
const habilidades = { ...(fala?.habilidades || {}), ...(base.habilidades || {}) };

const fontes = [
  { id: 'LudiDeo (beta)', nome: 'LudiDeo, Hunter Pet MASTERCLASS (beta data)', url: 'https://www.youtube.com/watch?v=pCgIGcumOss', data: '2026-11-02' },
  { id: 'LudiDeo tier (beta)', nome: 'LudiDeo, Hunter Pet Tier List (beta data)', url: 'https://www.youtube.com/watch?v=ZIiXgHdTkBI', data: '2026-11-02' },
  { id: 'Gladius (beta)', nome: 'Gladius Gaming, Ultimate Hunter Guide', url: 'https://www.youtube.com/watch?v=J1kDM4QI3Ks', data: '2026-11-02' },
  { id: 'Kargoz (beta)', nome: 'Kargoz, 1-60 Beast Mastery Hunter Leveling Guide', url: 'https://www.youtube.com/watch?v=rn6Cjl8zQbc', data: '2026-10-05' },
  { id: 'MetaGoblin (beta)', nome: 'MetaGoblin, The NEW WAY to Level Hunter 1-60', url: 'https://www.youtube.com/watch?v=F2dBd9PP8q0', data: '2026-11-02' },
  { id: 'Method', nome: 'Method, WoW Forever Hunter Leveling Guide', url: 'https://www.method.gg/wow-forever/wow-forever-hunter-leveling-guide-and-talents', data: '2026-11-03' },
  { id: 'Blizzard', nome: 'Blizzard beta notes (Kaivax) and Class Deep Dive', url: 'https://us.forums.blizzard.com/en/wow/t/2360696', data: '2026-11-03' },
];

const saida = { regras, familias, habilidades, fontes };
fs.writeFileSync(path.join(pasta, 'textos.json'), JSON.stringify(saida, null, 2) + '\n');
const nNotas = Object.values(familias).reduce((s, f) => s + f.notas.length, 0);
console.log(`textos.json: ${regras.length} regras, ${Object.keys(familias).length} familias, ${nNotas} notas, ${Object.keys(habilidades).length} habilidades`);
console.log(`entradas: base sim, fala do Saltii ${fala ? 'sim' : 'nao'}, tier do LudiDeo ${tier ? 'sim' : 'nao'}`);
