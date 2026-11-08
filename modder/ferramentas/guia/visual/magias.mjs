#!/usr/bin/env node
// Gera magias.json: nome de magia -> id de magia do cliente do WoW Forever, para o icone de cada
// linha da janela J (ARQUITETURA.md, secao 11.6). So fatos: id e nivel vem da TrainingData.lua do
// addon NaowhForever_Training (nada de codigo copiado); os nomes sem linha ali vem da tabela
// SpellName do wago.tools no build do cliente.
//
// Uso: node visual/magias.mjs [--gravar]
//   sem flag: gera magias.json e lista o que ficou sem id; nao mexe no Dicas.lua
//   --gravar: tambem insere `id = <n>, ` nas entradas de magias de HUNTER e SHAMAN do Dicas.lua

import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const AQUI = path.dirname(fileURLToPath(import.meta.url));
const BUILD = '1.60.1.70862';
const CACHE = path.join(AQUI, 'cache');
const SAIDA = path.join(AQUI, 'magias.json');
const DICAS = path.resolve(AQUI, '..', '..', '..', 'addons-proprios', 'GuiaForever', 'Dicas.lua');
const TRAINING = 'C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/NaowhForever_Training/Data/TrainingData.lua';
const CLASSES_TD = { 3: 'HUNTER', 7: 'SHAMAN' };
const CLASSES_DICAS = ['HUNTER', 'SHAMAN'];

// Nomes que nao estao na TrainingData: entram pelo menor id com nome exatamente igual no SpellName.
const EXTRAS = [
  'Auto Shot', 'Raptor Strike', 'Growl', 'Summon Hawk', 'Intimidation', 'Bestial Wrath',
  'Freezing Trap', 'Rapid Fire', 'Aimed Shot', 'Multi-Shot', 'Feed Pet', 'Call Pet', 'Revive Pet',
  'Dismiss Pet', 'Tame Beast', 'Beast Lore', 'Track Beasts', 'Track Humanoids', 'Track Undead',
  'Track Hidden', 'Eagle Eye', 'Mend Pet', 'Stormstrike', 'Maelstrom Weapon', 'Rage of the Farseer',
  'Searing Totem', 'Fire Nova', 'Ghost Wolf', 'Water Shield', 'Lightning Shield', 'Magma Totem',
  'Windfury Totem', 'Earth Shock', 'Flame Shock', 'Lightning Bolt', 'Healing Wave', 'Stoneclaw Totem',
];
// Habilidades de pet (Bite, Claw, Charge, Cower, Dash, Natural Armor, Great Stamina) ficam de fora:
// pelo menor id o nome casava com magia de outra classe (Charge 100 e a do guerreiro). O id delas
// vem do PetGuia.lua (ranks[1].id, dados do cliente). Growl fica: 2649 e o do pet.
// Id fixo quando o menor id do SpellName e outra magia de mesmo nome (conferido no CSV em 2026-11-08):
// Intimidation 7093 nao e o talento do cacador, 19577 e.
const FIXOS = { 'Intimidation': 19577 };

const gravar = process.argv.includes('--gravar');

function hojeLocal() {
  const d = new Date();
  const p = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

// ---------- CSV do wago.tools (mesmo padrao de download e cache do pets/gerar-habilidades.mjs) ----------

function parseCsv(texto) {
  const linhas = [];
  let linha = [];
  let campo = '';
  let aspas = false;
  for (let i = 0; i < texto.length; i++) {
    const c = texto[i];
    if (aspas) {
      if (c === '"') {
        if (texto[i + 1] === '"') { campo += '"'; i++; } else { aspas = false; }
      } else {
        campo += c;
      }
    } else if (c === '"') {
      aspas = true;
    } else if (c === ',') {
      linha.push(campo); campo = '';
    } else if (c === '\n' || c === '\r') {
      if (c === '\r' && texto[i + 1] === '\n') i++;
      linha.push(campo); campo = '';
      linhas.push(linha); linha = [];
    } else {
      campo += c;
    }
  }
  if (aspas) throw new Error('CSV termina dentro de campo entre aspas');
  if (campo !== '' || linha.length > 0) { linha.push(campo); linhas.push(linha); }
  return linhas.filter((l) => !(l.length === 1 && l[0] === ''));
}

async function baixarSpellName() {
  const url = `https://wago.tools/db2/SpellName/csv?build=${BUILD}`;
  let ultimo;
  for (let tentativa = 1; tentativa <= 2; tentativa++) {
    try {
      const r = await fetch(url);
      if (!r.ok) throw new Error(`HTTP ${r.status}`);
      return await r.text();
    } catch (e) {
      ultimo = e;
      console.error(`  SpellName: tentativa ${tentativa} falhou (${e.message})`);
    }
  }
  throw new Error(`SpellName: sem resposta apos 2 tentativas (${ultimo.message}) em ${url}`);
}

function lerSpellName(texto) {
  const linhas = parseCsv(texto.replace(/^\uFEFF/, ''));
  const cab = linhas[0];
  const iId = cab.indexOf('ID');
  const iNome = cab.indexOf('Name_lang');
  if (iId < 0 || iNome < 0) throw new Error(`SpellName: colunas ID/Name_lang ausentes (cabecalho: ${cab.slice(0, 8).join(',')})`);
  const nomePorId = new Map();
  const idsPorNome = new Map();
  const extras = new Set(EXTRAS);
  for (const l of linhas.slice(1)) {
    if (l.length !== cab.length) throw new Error(`SpellName: linha com ${l.length} campos, cabecalho tem ${cab.length}`);
    const id = Number(l[iId]);
    const nome = l[iNome];
    if (!nome) continue;
    if (!nomePorId.has(id)) nomePorId.set(id, nome);
    if (extras.has(nome)) {
      if (!idsPorNome.has(nome)) idsPorNome.set(nome, []);
      idsPorNome.get(nome).push(id);
    }
  }
  for (const ids of idsPorNome.values()) ids.sort((a, b) => a - b);
  return { nomePorId, idsPorNome };
}

async function obterSpellName() {
  const arq = path.join(CACHE, `SpellName-${BUILD}.csv`);
  let texto;
  try {
    texto = await readFile(arq, 'utf8');
    console.error(`  SpellName: cache ${arq}`);
  } catch (e) {
    if (e.code !== 'ENOENT') throw e;
    texto = await baixarSpellName();
    const tabela = lerSpellName(texto); // valida antes de gravar no cache
    await mkdir(CACHE, { recursive: true });
    await writeFile(arq, texto, 'utf8');
    console.error(`  SpellName: baixado (${texto.length} caracteres)`);
    return tabela;
  }
  return lerSpellName(texto);
}

// ---------- TrainingData.lua (so regex: entradas { nivel, spellID, preco, ... }) ----------

async function lerTrainingData() {
  const texto = await readFile(TRAINING, 'utf8');
  const build = (texto.split(/\r?\n/, 1)[0].match(/build (\d+\.\d+\.\d+\.\d+)/) || [])[1] ?? '?';
  const entradas = [];
  let classe = null;
  for (const l of texto.split(/\r?\n/)) {
    const c = l.match(/^\s*\[(\d+)\] = \{/);
    if (c) { classe = CLASSES_TD[Number(c[1])] ?? null; continue; }
    if (!classe) continue;
    const e = l.match(/^\s*\{\s*(\d+),\s*(\d+),\s*\d+/);
    if (e) entradas.push({ classe, nivel: Number(e[1]), id: Number(e[2]) });
  }
  return { build, entradas };
}

// ---------- Dicas.lua ----------

function nomeDaEntrada(linha) {
  const m = linha.match(/ magia = "([^"]*)"/);
  if (m) return m[1];
  const t = linha.match(/ texto = "([^"]*)"/);
  return t ? t[1].split(/:|\.| \(/)[0].trim() : '';
}

async function main() {
  const spell = await obterSpellName();
  const td = await lerTrainingData();
  console.error(`  TrainingData: build ${td.build}; ${td.entradas.length} entradas de ${Object.values(CLASSES_TD).join(' e ')}`);

  // 1. TrainingData: menor nivel por nome; empate, menor id.
  const porNome = new Map();
  const semNomeTD = new Set();
  const colisoes = new Set();
  for (const e of td.entradas) {
    const nome = spell.nomePorId.get(e.id);
    if (!nome) { semNomeTD.add(e.id); continue; }
    const atual = porNome.get(nome);
    if (!atual) {
      porNome.set(nome, { id: e.id, nivel: e.nivel, classe: e.classe });
      continue;
    }
    if (atual.classe !== e.classe) colisoes.add(nome);
    if (e.nivel < atual.nivel || (e.nivel === atual.nivel && e.id < atual.id)) {
      porNome.set(nome, { id: e.id, nivel: e.nivel, classe: e.classe });
    }
  }
  const magias = {};
  const ordem = [...porNome.entries()].sort((a, b) => a[1].nivel - b[1].nivel || a[1].id - b[1].id || (a[0] < b[0] ? -1 : 1));
  for (const [nome, v] of ordem) {
    magias[nome] = { id: v.id, nivel: v.nivel, classe: v.classe, de: 'TrainingData' };
  }
  const nTD = ordem.length;

  // 2. Nomes extras que nao estao na TrainingData.
  const semId = [];
  const ambiguos = [];
  let nSpell = 0;
  for (const nome of EXTRAS) {
    if (porNome.has(nome)) continue;
    const ids = spell.idsPorNome.get(nome);
    if (!ids) { semId.push({ onde: 'lista', nome }); continue; }
    if (FIXOS[nome] && ids.includes(FIXOS[nome])) {
      magias[nome] = { id: FIXOS[nome], de: 'SpellName (id fixo)' };
      nSpell++;
      continue;
    }
    magias[nome] = { id: ids[0], de: 'SpellName (menor id)' };
    nSpell++;
    if (ids.length > 1) ambiguos.push(`${nome} (${ids.length} linhas no SpellName, menor ${ids[0]})`);
  }

  await writeFile(SAIDA, JSON.stringify({ build: BUILD, gerado: hojeLocal(), magias }, null, 2) + '\n', 'utf8');
  console.log(`magias.json: ${Object.keys(magias).length} nomes (TrainingData ${nTD}, SpellName ${nSpell}) em ${SAIDA}`);

  // 3. Entradas de magias do Dicas.lua (HUNTER e SHAMAN).
  const texto = await readFile(DICAS, 'utf8');
  const linhas = texto.split('\n');
  let classe = null;
  let emMagias = false;
  const entradas = [];
  for (let i = 0; i < linhas.length; i++) {
    const l = linhas[i];
    const c = l.match(/^  (\w+) = \{/);
    if (c) { classe = c[1]; emMagias = false; continue; }
    if (/^    magias = \{/.test(l)) { emMagias = CLASSES_DICAS.includes(classe); continue; }
    if (emMagias && /^    \}/.test(l)) { emMagias = false; continue; }
    if (emMagias && /^\s*\{ nivel = \d+, /.test(l)) {
      const nome = nomeDaEntrada(l);
      const id = Object.hasOwn(magias, nome) ? magias[nome].id : null;
      entradas.push({ linha: i, classe, nome, id });
    }
  }
  const comId = entradas.filter((e) => e.id !== null).length;
  console.log(`Dicas.lua: ${entradas.length} entradas de magia (HUNTER/SHAMAN), ${comId} com id`);

  if (gravar) {
    let mudou = 0;
    for (const e of entradas) {
      if (e.id === null) continue;
      const antes = linhas[e.linha];
      const depois = / id = \d+, /.test(antes)
        ? antes.replace(/ id = \d+, /, ` id = ${e.id}, `)
        : antes.replace(/(nivel = \d+, )/, `$1id = ${e.id}, `);
      if (depois !== antes) { linhas[e.linha] = depois; mudou++; }
    }
    if (mudou > 0) await writeFile(DICAS, linhas.join('\n'), 'utf8');
    console.log(`Dicas.lua: ${mudou} linha(s) alterada(s) com --gravar`);
  }

  for (const e of entradas) {
    if (e.id === null) semId.push({ onde: `Dicas ${e.classe} linha ${e.linha + 1}`, nome: e.nome });
  }

  if (colisoes.size) console.error(`  aviso: nome nas duas classes (escolhido o de menor nivel): ${[...colisoes].join(', ')}`);
  if (semNomeTD.size) console.error(`  aviso: ids da TrainingData sem nome no SpellName: ${[...semNomeTD].join(', ')}`);
  if (ambiguos.length) console.error(`  aviso: nomes com mais de uma linha no SpellName (vale o menor id): ${ambiguos.join('; ')}`);

  console.log(`sem id: ${semId.length}`);
  for (const s of semId) console.log(`  ${s.onde}: ${s.nome}`);
}

main().catch((e) => {
  console.error(`erro: ${e.message}`);
  process.exit(1);
});
