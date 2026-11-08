#!/usr/bin/env node
// Gera professores.json (cada habilidade e rank do pet do caçador, com as feras que ensinam) e feras.json
// (cada fera domável conhecida). Juntas duas fontes pelo npc id:
//   - Forever-Hunter-Pets (MIT): tools/data.json no commit da branch padrão (sha resolvido na execução).
//     Belegung: teach.conf 1 = belegt (dono ou 3 relatos de outros melders), 2 = unsicher (2 relatos).
//     Velocidade por fera: os traços de Angriffstempo (kind trait), cujo teach lista as feras daquele tempo.
//   - Petopia Forever (sem licença aberta; uso pessoal, marcado como fonte): páginas abilities.php e
//     attackspeed.php.
// Nome em inglês: Petopia, depois QuestieDB (data/Forever/foreverNpcDB.lua), senão o alemão (nomeIngles: false).
// Zona: Petopia, senão o nome do uiMapID no wago (UiMap).
//
// Uso: node gerar-professores.mjs [--cache <pasta>] [--saida-dir <pasta>]
//   --cache       guarda e reaproveita as respostas (HTML, data.json, Questie, wago) nessa pasta
//   --saida-dir   onde escrever professores.json e feras.json (padrão: esta pasta)

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const UA = 'wow-modder-guia-pets/1.0 (uso pessoal)';
const FHP_REPO = 'Jazzman1976/Forever-Hunter-Pets';
const PET_ABIL = 'https://www.wow-petopia.com/forever/abilities.php';
const PET_VEL = 'https://www.wow-petopia.com/forever/attackspeed.php';
const QUESTIE_API = 'https://api.github.com/repos/Questie/QuestieDB/contents/data/Forever/foreverNpcDB.lua';
const WAGO_URL = 'https://wago.tools/db2/UiMap/csv?build=1.60.1.70862';

// Habilidades do FHP (alemão) e o nome que a Petopia usa em inglês. Traços de velocidade não entram aqui.
const DE_PARA_EN = {
  'Ducken': 'Cower',
  'Knurren': 'Growl',
  'Große Ausdauer': 'Great Stamina',
  'Sturmangriff': 'Charge',
  'Klaue': 'Claw',
  'Beißen': 'Bite',
  'Feuerwiderstand': 'Fire Resistance',
  'Demoralisierendes Kreischen': 'Demoralizing Screech',
  'Frostwiderstand': 'Frost Resistance',
  'Schattenwiderstand': 'Shadow Resistance',
  'Naturwiderstand': 'Nature Resistance',
  'Arkanwiderstand': 'Arcane Resistance',
  'Natürliche Rüstung': 'Natural Armor',
  'Wutgeheul': 'Furious Howl',
  'Skorpidgift': 'Scorpid Poison',
  'Blitzschlagatem': 'Lightning Breath',
  'Prankenhieb': 'Swipe',
  'Zwicken': 'Pinch',
  'Zerstückeln': 'Dismember',
  'Sehnenriss': 'Tendon Rip',
  'Meins!': 'Mine!',
  'Wildes Verwunden': 'Savage Rend',
  'Gespinst': 'Web',
  'Staubwolke': 'Dust Cloud',
  'Tanz des Täuschers': "Trickster's Dance",
};

const ENT = { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ', copy: '©' };

// ---------- argumentos e leitura com cache ----------

function lerArgs(argv) {
  const o = { cache: null, saida: HERE };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--cache' || a === '--saida-dir') {
      if (argv[i + 1] === undefined) throw new Error(`${a} pede uma pasta`);
      const v = path.resolve(argv[++i]);
      if (a === '--cache') o.cache = v; else o.saida = v;
    } else throw new Error(`argumento desconhecido: ${a}`);
  }
  return o;
}
const ARGS = lerArgs(process.argv.slice(2));

async function obter(nome, url, cabecalhos = {}) {
  const arq = ARGS.cache ? path.join(ARGS.cache, nome) : null;
  if (arq && fs.existsSync(arq)) return fs.readFileSync(arq, 'utf8');
  const r = await fetch(url, { headers: { 'User-Agent': UA, ...cabecalhos } });
  if (!r.ok) throw new Error(`HTTP ${r.status} em ${url}: não contornar, relatar`);
  const txt = await r.text();
  if (arq) { fs.mkdirSync(ARGS.cache, { recursive: true }); fs.writeFileSync(arq, txt); }
  return txt;
}

async function resolverSha() {
  const h = { 'User-Agent': UA, Accept: 'application/vnd.github+json' };
  if (process.env.GITHUB_TOKEN) h.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;
  const r = await fetch(`https://api.github.com/repos/${FHP_REPO}/commits/HEAD`, { headers: h });
  if (!r.ok) throw new Error(`HTTP ${r.status} ao resolver o sha do FHP: não contornar, relatar`);
  return (await r.json()).sha;
}

// ---------- utilitários de texto ----------

function decodificar(s) {
  return s.replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (m, e) => {
    if (e[0] === '#') {
      const cp = e[1] === 'x' || e[1] === 'X' ? parseInt(e.slice(2), 16) : parseInt(e.slice(1), 10);
      return String.fromCodePoint(cp);
    }
    return ENT[e.toLowerCase()] ?? m;
  });
}

// "2-3" -> {min 2, max 3}; "5" -> {5, 5}; outro -> null
function faixa(txt) {
  const m = /^(\d+)(?:-(\d+))?$/.exec(String(txt).trim());
  if (!m) return null;
  return { min: Number(m[1]), max: Number(m[2] ?? m[1]) };
}

// "Cat, 37, Badlands" / "Wolf, 2-3, Zul'Gurub (Raid)" -> familia, nivel, zona
function partirEntidade(inner) {
  const p = decodificar(inner).split(', ');
  return { familia: p[0] ?? null, nivelTxt: p[1] ?? null, zona: p.slice(2).join(', ') || null };
}

// CSV simples (aspas duplas, "" escapado)
function lerCsv(txt) {
  const linhas = [];
  let campo = '', linha = [], aspas = false;
  for (let i = 0; i < txt.length; i++) {
    const c = txt[i];
    if (aspas) {
      if (c === '"') { if (txt[i + 1] === '"') { campo += '"'; i++; } else aspas = false; } else campo += c;
    } else if (c === '"') aspas = true;
    else if (c === ',') { linha.push(campo); campo = ''; }
    else if (c === '\n') { linha.push(campo); linhas.push(linha); linha = []; campo = ''; }
    else if (c !== '\r') campo += c;
  }
  if (campo || linha.length) { linha.push(campo); linhas.push(linha); }
  return linhas;
}

// ---------- Petopia ----------

// A zona pode ter parênteses ("Zul'Gurub (Raid)"): o texto vai até o ")</li>" do fim da linha.
const RE_NPC_PET = /<li class='abilityranknpc classic forever'><a class='npclink classic forever' href='https:\/\/www\.wowhead\.com\/forever\/npc=(\d+)'>([^<]*)<\/a> \(([^<]*)\)<\/li>/g;
const RE_NPC_VEL = /<li class='attackspeednpc classic forever'><a class='npclink classic forever' href='https:\/\/www\.wowhead\.com\/forever\/npc=(\d+)'>([^<]*)<\/a> \(([^<]*)\)<\/li>/g;

function lerPetopiaHabilidades(html) {
  const secoes = [...html.matchAll(/<h3 class='guide_heading classic forever' id='([^']+)'><img[^>]*>([^<]*)<\/h3>/g)];
  const habilidades = [];
  const ranks = new Map();   // "Nome N" -> { habilidade, rank, nivel, custo, professores: Map(npc -> {nome, familia, nivelTxt, zona}) }
  const npcs = new Map();    // npc -> { nome, familia, nivelTxt, zona } (primeira aparição)
  secoes.forEach((s, i) => {
    const nome = decodificar(s[2]).trim();
    habilidades.push(nome);
    const trecho = html.slice(s.index, i + 1 < secoes.length ? secoes[i + 1].index : html.length);
    const cab = [...trecho.matchAll(/<li id='[^']*' class='abilityrank classic forever'><span class='abilityrankname classic forever'>([^<]*)<\/span>: Pet Level (\d+), Cost (\d+) TP\./g)];
    cab.forEach((c, k) => {
      const nomeRank = decodificar(c[1]).trim();
      const m = /^(.*) (\d+)$/.exec(nomeRank);
      if (!m || m[1] !== nome) throw new Error(`rank “${nomeRank}” fora da habilidade “${nome}”`);
      const chave = `${nome} ${Number(m[2])}`;
      if (ranks.has(chave)) throw new Error(`rank duplicado na Petopia: ${chave}`);
      const corpo = trecho.slice(c.index, k + 1 < cab.length ? cab[k + 1].index : trecho.length);
      const professores = new Map();
      for (const n of corpo.matchAll(RE_NPC_PET)) {
        const id = Number(n[1]);
        const e = partirEntidade(n[3]);
        const info = { nome: decodificar(n[2]).trim(), familia: e.familia, nivelTxt: e.nivelTxt, zona: e.zona };
        professores.set(id, info);
        if (!npcs.has(id)) npcs.set(id, info);
      }
      ranks.set(chave, { habilidade: nome, rank: Number(m[2]), nivel: Number(c[2]), custo: Number(c[3]), professores });
    });
  });
  return { habilidades, ranks, npcs };
}

function lerPetopiaVelocidade(html) {
  const npcs = new Map();      // npc -> { nome, familia, nivelTxt, zona, velocidade }
  const conflitos = [];
  const secoes = [...html.matchAll(/<h4 class='guideheading attackspeed classic forever' id='attackspeed_([\d.]+)'>[^<]*<\/h4>\s*<ul[^>]*>([\s\S]*?)<\/ul>/g)];
  for (const s of secoes) {
    const vel = Number(s[1]);
    for (const n of s[2].matchAll(RE_NPC_VEL)) {
      const id = Number(n[1]);
      const e = partirEntidade(n[3]);
      if (npcs.has(id)) {
        if (npcs.get(id).velocidade !== vel) conflitos.push({ npc: id, de: npcs.get(id).velocidade, para: vel });
        continue;
      }
      npcs.set(id, { nome: decodificar(n[2]).trim(), familia: e.familia, nivelTxt: e.nivelTxt, zona: e.zona, velocidade: vel });
    }
  }
  return { npcs, secoes: secoes.length, conflitos };
}

// ---------- QuestieDB e wago ----------

function lerQuestieNomes(lua) {
  const nomes = new Map();
  for (const m of lua.matchAll(/^\[(\d+)\] = \{'((?:\\.|[^'\\])*)'/gm)) {
    nomes.set(Number(m[1]), m[2].replace(/\\(.)/g, '$1'));
  }
  return nomes;
}

function lerWagoZonas(csv) {
  const linhas = lerCsv(csv);
  const cab = linhas[0];
  const iNome = cab.indexOf('Name_lang'), iId = cab.indexOf('ID');
  if (iNome < 0 || iId < 0) throw new Error('cabeçalho do wago UiMap sem Name_lang/ID');
  const zonas = new Map();
  for (const l of linhas.slice(1)) if (l[iId]) zonas.set(String(l[iId]), l[iNome]);
  return zonas;
}

// ---------- principal ----------

async function main() {
  const sha = await resolverSha();
  const fhp = JSON.parse(await obter(`fhp-data-${sha}.json`, `https://raw.githubusercontent.com/${FHP_REPO}/${sha}/tools/data.json`));

  const metaArq = ARGS.cache && path.join(ARGS.cache, 'petopia-lido.json');
  let lidoEm;
  if (metaArq && fs.existsSync(metaArq)) lidoEm = JSON.parse(fs.readFileSync(metaArq, 'utf8')).lidoEm;
  else lidoEm = new Date().toISOString();
  const htmlAbil = await obter('petopia-abilities.html', PET_ABIL);
  const htmlVel = await obter('petopia-attackspeed.html', PET_VEL);
  if (metaArq && !fs.existsSync(metaArq)) fs.writeFileSync(metaArq, JSON.stringify({ lidoEm }, null, 2));

  const questieLua = await obter('questie-foreverNpcDB.lua', QUESTIE_API, { Accept: 'application/vnd.github.raw' });
  const wagoCsv = await obter('wago-UiMap-1.60.1.70862.csv', WAGO_URL);

  const pet = lerPetopiaHabilidades(htmlAbil);
  const vel = lerPetopiaVelocidade(htmlVel);
  const questieNomes = lerQuestieNomes(questieLua);
  const wagoZonas = lerWagoZonas(wagoCsv);

  // Informação de fera vinda da Petopia (página de habilidades primeiro, depois a de velocidade)
  const petInfo = new Map(pet.npcs);
  for (const [id, v] of vel.npcs) if (!petInfo.has(id)) petInfo.set(id, v);

  // Velocidade por fera vinda do FHP: traços de Angriffstempo
  const velFhp = new Map();
  let conflitosVelFhp = 0;
  for (const a of fhp.abilities.filter((x) => x.kind === 'trait')) {
    for (const t of a.teach) {
      const s = Number(a.speed);
      if (velFhp.has(t.id) && velFhp.get(t.id) !== s) conflitosVelFhp++;
      else velFhp.set(t.id, s);
    }
  }

  // Família do FHP (número) -> nome em inglês, pelas feras que as duas fontes têm
  const famContagem = new Map();
  for (const [id, b] of Object.entries(fhp.beasts)) {
    const p = petInfo.get(Number(id));
    if (b.fam == null || !p?.familia) continue;
    if (!famContagem.has(b.fam)) famContagem.set(b.fam, new Map());
    const c = famContagem.get(b.fam);
    c.set(p.familia, (c.get(p.familia) ?? 0) + 1);
  }
  const famMap = new Map();
  let famConflitos = 0;
  for (const [fam, c] of famContagem) {
    if (c.size > 1) famConflitos++;
    famMap.set(fam, [...c].sort((x, y) => y[1] - x[1])[0][0]);
  }

  // Habilidades do FHP (sem traços) mapeadas para o nome da Petopia
  const chaves = new Map(); // "Nome N" -> { habilidade, rank, fhp, pet, teachFhp: Map(npc -> conf), teachPet }
  const pegar = (k, hab, rank) => {
    if (!chaves.has(k)) chaves.set(k, { habilidade: hab, rank, fhp: null, pet: null, teachFhp: new Map(), teachPet: new Map() });
    return chaves.get(k);
  };
  for (const a of fhp.abilities) {
    if (a.kind === 'trait') continue;
    const en = DE_PARA_EN[a.de];
    if (!en) throw new Error(`habilidade do FHP sem correspondência na Petopia: “${a.de}”`);
    if (!pet.habilidades.includes(en)) throw new Error(`“${en}” não está na página de habilidades da Petopia`);
    for (const r of a.ranks) {
      const e = pegar(`${en} ${r.rank}`, en, r.rank);
      e.fhp = { spellId: r.id, nivel: r.level, tp: r.tp };
    }
    for (const t of a.teach) {
      const e = pegar(`${en} ${t.rank}`, en, t.rank);
      e.teachFhp.set(t.id, t.conf);
    }
  }
  for (const [k, r] of pet.ranks) {
    const e = pegar(k, r.habilidade, r.rank);
    e.pet = { nivel: r.nivel, custo: r.custo };
    for (const [npc] of r.professores) e.teachPet.set(npc, true);
  }

  // Fera: nome, família, faixa, zona, velocidade e fontes
  const idsFhp = Object.keys(fhp.beasts).map(Number);
  const idsPetTeach = new Set(); for (const r of pet.ranks.values()) for (const id of r.professores.keys()) idsPetTeach.add(id);
  const universo = [...new Set([...idsFhp, ...idsPetTeach])].sort((x, y) => x - y);

  const feras = new Map();
  const faltaNomeIngles = [];
  const faltaFamilia = [];
  const faltaZona = [];
  for (const npc of universo) {
    const fb = fhp.beasts[npc];
    const p = petInfo.get(npc);
    let nome, nomeIngles = true;
    if (p?.nome) nome = p.nome;
    else if (questieNomes.has(npc)) nome = questieNomes.get(npc);
    else { nome = fb?.de ?? null; nomeIngles = false; faltaNomeIngles.push(npc); }
    const familia = p?.familia ?? (fb && fb.fam != null ? famMap.get(fb.fam) ?? null : null);
    if (!familia) faltaFamilia.push(npc);
    const faixaFera = fb ? { min: fb.min, max: fb.max } : (faixa(p?.nivelTxt) ?? { min: null, max: null });
    let zona = p?.zona ?? null;
    if (!zona && fb) {
      const zs = Object.keys(fhp.coords[npc] ?? {}).map((z) => wagoZonas.get(z) ?? z);
      zona = zs.length ? zs.join(' / ') : null;
    }
    if (!zona) faltaZona.push(npc);
    const velocidade = velFhp.get(npc) ?? vel.npcs.get(npc)?.velocidade ?? null;
    const fontes = [];
    if (fb) fontes.push('FHP');
    if (p) fontes.push('Petopia');
    feras.set(npc, { nome, nomeIngles, familia, ...faixaFera, zona, velocidade, ensina: [], fontes });
  }

  // Ranks: junta as duas fontes; professores de cada rank
  const ordem = [...chaves.values()].sort((x, y) => pet.habilidades.indexOf(x.habilidade) - pet.habilidades.indexOf(y.habilidade) || x.rank - y.rank);
  const divergencias = [];
  const saidaRanks = {};
  let semProfessor = 0;
  for (const e of ordem) {
    const chave = `${e.habilidade} ${e.rank}`;
    const nivelPet = e.fhp?.nivel ?? e.pet?.nivel ?? null;
    const pt = e.fhp?.tp ?? e.pet?.custo ?? null;
    const divs = [];
    if (e.fhp?.nivel != null && e.pet?.nivel != null && e.fhp.nivel !== e.pet.nivel) divs.push({ campo: 'nivelPet', fhp: e.fhp.nivel, petopia: e.pet.nivel });
    if (e.fhp?.tp != null && e.pet?.custo != null && e.fhp.tp !== e.pet.custo) divs.push({ campo: 'pt', fhp: e.fhp.tp, petopia: e.pet.custo });
    divergencias.push(...divs.map((d) => ({ rank: chave, ...d })));

    const profs = [...new Set([...e.teachFhp.keys(), ...e.teachPet.keys()])].map((npc) => {
      const f = feras.get(npc);
      const conf = e.teachFhp.get(npc);
      const fontes = [];
      if (e.teachFhp.has(npc)) fontes.push('FHP');
      if (e.teachPet.has(npc)) fontes.push('Petopia');
      return {
        npcId: npc,
        nome: f.nome,
        nomeIngles: f.nomeIngles,
        familia: f.familia,
        min: f.min,
        max: f.max,
        zona: f.zona,
        velocidade: f.velocidade,
        fontes,
        confirmado: conf === 1 ? true : conf === 2 ? false : null,
      };
    }).sort((x, y) => x.nome.localeCompare(y.nome, 'en'));

    if (!profs.length) semProfessor++;
    for (const p of profs) feras.get(p.npcId).ensina.push(chave);

    saidaRanks[chave] = {
      spellId: e.fhp?.spellId ?? null,
      nivelPet,
      pt,
      ...(divs.length ? { divergencias: divs.map(({ campo, fhp: a, petopia: b }) => ({ campo, fhp: a, petopia: b })) } : {}),
      professores: profs,
    };
  }

  const agora = new Date().toISOString();
  const professores = {
    geradoEm: agora,
    fontes: {
      fhp: { repo: `https://github.com/${FHP_REPO}`, sha, licenca: 'MIT', arquivo: 'tools/data.json' },
      petopia: { url: PET_ABIL, velocidade: PET_VEL, lidoEm, licenca: 'sem licença aberta; uso pessoal, marcado como fonte' },
      questieDB: { repo: 'https://github.com/Questie/QuestieDB', arquivo: 'data/Forever/foreverNpcDB.lua' },
      wago: { url: WAGO_URL },
    },
    ranks: saidaRanks,
  };

  const feraSaida = {};
  for (const npc of universo) feraSaida[npc] = feras.get(npc);

  fs.mkdirSync(ARGS.saida, { recursive: true });
  fs.writeFileSync(path.join(ARGS.saida, 'professores.json'), JSON.stringify(professores, null, 2) + '\n');
  fs.writeFileSync(path.join(ARGS.saida, 'feras.json'), JSON.stringify({ geradoEm: agora, fontes: professores.fontes, feras: feraSaida }, null, 2) + '\n');

  const totalProfs = Object.keys(saidaRanks).length;
  console.log(`ranks: ${totalProfs} (sem professor: ${semProfessor}); feras: ${universo.length}; divergências: ${divergencias.length}`);
  console.log(`sha FHP ${sha}; Petopia: ${pet.ranks.size} ranks, ${pet.npcs.size} feras (habilidades), ${vel.npcs.size} (velocidade)`);
  if (conflitosVelFhp || vel.conflitos.length || famConflitos) console.log(`avisos: velocidade FHP em conflito ${conflitosVelFhp}; velocidade Petopia em conflito ${vel.conflitos.length}; família FHP com mais de um nome ${famConflitos}`);
  if (faltaNomeIngles.length) console.log(`sem nome em inglês (alemão, nomeIngles false): ${faltaNomeIngles.join(', ')}`);
  if (faltaFamilia.length) console.log(`sem família: ${faltaFamilia.join(', ')}`);
  if (faltaZona.length) console.log(`sem zona: ${faltaZona.join(', ')}`);
  console.log(`escrito em ${ARGS.saida}`);
}

main().catch((e) => {
  console.error(`erro: ${e.message}`);
  process.exit(1);
});
