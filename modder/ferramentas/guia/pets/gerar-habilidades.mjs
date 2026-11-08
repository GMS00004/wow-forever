#!/usr/bin/env node
// Gera habilidades.json: famílias de pet do caçador e as habilidades de cada uma
// (ranks, nível do pet e custo em pontos de treino), a partir das tabelas DB2 do
// cliente do WoW Forever publicadas no wago.tools.
//
// Uso: node gerar-habilidades.mjs [--build 1.60.1.70862] [--cache <pasta>] [--saida <arquivo>]
//   --cache  guarda os CSV baixados e reaproveita nas próximas execuções
//   --saida  arquivo JSON de saída (padrão: habilidades.json ao lado do script)

import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';

const BUILD_PADRAO = '1.60.1.70862';
const LINHA_GERAL = 270;
const COL_CUSTO = 'Field_5_5_4_67090_014_1';
const TABELAS = {
  CreatureFamily: ['ID', 'Name_lang', 'PetFoodMask', 'SkillLine_0', 'SkillLine_1'],
  SkillLine: ['ID', 'DisplayName_lang'],
  SkillLineAbility: ['ID', 'SkillLine', 'Spell', COL_CUSTO],
  SpellLevels: ['ID', 'DifficultyID', 'BaseLevel', 'SpellLevel', 'SpellID'],
  Spell: ['ID', 'NameSubtext_lang'],
  SpellName: ['ID', 'Name_lang'],
};
const BITS_DIETA = [
  [1, 'Meat'], [2, 'Fish'], [4, 'Cheese'], [8, 'Bread'],
  [16, 'Fungus'], [32, 'Fruit'], [64, 'Raw Meat'], [128, 'Raw Fish'],
];
const TRACO_VELOCIDADE = /^(Faster|Slower) Attack\b/;

function argumentos(argv) {
  const opts = {
    build: BUILD_PADRAO,
    cache: null,
    saida: path.join(import.meta.dirname, 'habilidades.json'),
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const valor = () => {
      const v = argv[++i];
      if (v === undefined || v.startsWith('--')) throw new Error(`${a} pede um valor`);
      return v;
    };
    if (a === '--build') opts.build = valor();
    else if (a === '--cache') opts.cache = path.resolve(valor());
    else if (a === '--saida') opts.saida = path.resolve(valor());
    else throw new Error(`argumento desconhecido: ${a}`);
  }
  return opts;
}

// Parser de CSV (RFC 4180): aspas duplicadas dentro de campo entre aspas, vírgula e
// quebra de linha dentro de campo entre aspas, CRLF ou LF.
function parseCsv(texto) {
  if (texto.charCodeAt(0) === 0xfeff) texto = texto.slice(1);
  const linhas = [];
  let campo = '';
  let linha = [];
  let entreAspas = false;
  let campoAspas = false;
  for (let i = 0; i < texto.length; i++) {
    const c = texto[i];
    if (entreAspas) {
      if (c === '"') {
        if (texto[i + 1] === '"') { campo += '"'; i++; }
        else entreAspas = false;
      } else {
        campo += c;
      }
    } else if (c === '"' && campo === '' && !campoAspas) {
      entreAspas = true;
      campoAspas = true;
    } else if (c === ',') {
      linha.push(campo); campo = ''; campoAspas = false;
    } else if (c === '\n' || c === '\r') {
      if (c === '\r' && texto[i + 1] === '\n') i++;
      linha.push(campo); campo = ''; campoAspas = false;
      linhas.push(linha); linha = [];
    } else {
      campo += c;
    }
  }
  if (entreAspas) throw new Error('CSV termina dentro de campo entre aspas');
  if (campo !== '' || campoAspas || linha.length > 0) {
    linha.push(campo);
    linhas.push(linha);
  }
  return linhas.filter((l) => !(l.length === 1 && l[0] === ''));
}

function tabelaDe(nome, texto) {
  const linhas = parseCsv(texto);
  const cab = linhas[0];
  for (const col of TABELAS[nome]) {
    if (!cab.includes(col)) {
      throw new Error(`${nome}: coluna ${col} ausente (cabeçalho começa com ${cab.slice(0, 8).join(',')})`);
    }
  }
  const registros = [];
  for (let n = 1; n < linhas.length; n++) {
    const l = linhas[n];
    if (l.length !== cab.length) {
      throw new Error(`${nome}: linha ${n + 1} tem ${l.length} campos, cabeçalho tem ${cab.length}`);
    }
    registros.push(Object.fromEntries(cab.map((c, i) => [c, l[i]])));
  }
  return registros;
}

async function baixar(nome, build) {
  const url = `https://wago.tools/db2/${nome}/csv?build=${build}`;
  let ultimo;
  for (let tentativa = 1; tentativa <= 2; tentativa++) {
    try {
      const r = await fetch(url);
      if (!r.ok) throw new Error(`HTTP ${r.status}`);
      return await r.text();
    } catch (e) {
      ultimo = e;
      console.error(`  ${nome}: tentativa ${tentativa} falhou (${e.message})`);
    }
  }
  throw new Error(`${nome}: sem resposta após 2 tentativas (${ultimo.message}) em ${url}`);
}

async function obterCsv(nome, opts) {
  if (!opts.cache) return baixar(nome, opts.build);
  const arq = path.join(opts.cache, `${nome}-${opts.build}.csv`);
  try {
    const texto = await readFile(arq, 'utf8');
    console.error(`  ${nome}: cache ${arq}`);
    return texto;
  } catch (e) {
    if (e.code !== 'ENOENT') throw e;
  }
  const texto = await baixar(nome, opts.build);
  await mkdir(opts.cache, { recursive: true });
  await writeFile(arq, texto, 'utf8');
  console.error(`  ${nome}: baixado (${texto.length} caracteres)`);
  return texto;
}

function rankDe(subtexto) {
  if (subtexto === '') return 1;
  const m = /^Rank (\d+)$/.exec(subtexto);
  return m ? Number(m[1]) : null;
}

function dietaDe(mascara) {
  const nomes = BITS_DIETA.filter(([bit]) => (mascara & bit) !== 0).map(([, n]) => n);
  const desconhecido = mascara & ~255;
  return { nomes, desconhecido };
}

async function main() {
  const opts = argumentos(process.argv.slice(2));
  console.error(`build ${opts.build}`);

  const T = {};
  for (const nome of Object.keys(TABELAS)) {
    T[nome] = tabelaDe(nome, await obterCsv(nome, opts));
  }

  const linhaExiste = new Set(T.SkillLine.map((r) => Number(r.ID)));
  const nomeSpell = new Map(T.SpellName.map((r) => [Number(r.ID), r.Name_lang]));
  const subtextoSpell = new Map(T.Spell.map((r) => [Number(r.ID), r.NameSubtext_lang]));

  // Nível do pet: BaseLevel, ou SpellLevel quando BaseLevel é 0. Prefere dificuldade 0.
  const nivelSpell = new Map();
  for (const r of T.SpellLevels) {
    const id = Number(r.SpellID);
    const base = Number(r.BaseLevel);
    const nivel = base > 0 ? base : Number(r.SpellLevel);
    const atual = nivelSpell.get(id);
    if (!atual || (Number(r.DifficultyID) === 0 && atual.dificuldade !== 0)) {
      nivelSpell.set(id, { nivel, dificuldade: Number(r.DifficultyID) });
    }
  }

  // Família de caçador: liga à linha geral de pet (270) e tem dieta (PetFoodMask != 0).
  // A família Imp liga à linha 270 mas tem máscara 0 (demônio de bruxo, não é pet de caçador).
  const todasComLinhaGeral = T.CreatureFamily
    .map((r) => ({
      id: Number(r.ID),
      nome: r.Name_lang,
      mascara: Number(r.PetFoodMask),
      linha: Number(r.SkillLine_0),
      linhaGeral: Number(r.SkillLine_1),
    }))
    .filter((f) => f.linhaGeral === LINHA_GERAL);
  const familias = todasComLinhaGeral.filter((f) => f.mascara !== 0);
  const familiasExcluidas = todasComLinhaGeral.filter((f) => f.mascara === 0);

  const avisos = [];
  for (const f of familiasExcluidas) {
    avisos.push(`família excluída: ${f.nome} (id ${f.id}, linha própria ${f.linha}): SkillLine_1 ${LINHA_GERAL} mas PetFoodMask 0`);
  }
  for (const f of familias) {
    if (!linhaExiste.has(f.linha)) avisos.push(`família ${f.nome}: linha própria ${f.linha} não existe em SkillLine`);
    const d = dietaDe(f.mascara);
    if (d.desconhecido) avisos.push(`família ${f.nome}: bits de dieta sem nome (${d.desconhecido})`);
  }
  const linhasExcluidas = new Set(familiasExcluidas.map((f) => f.linha));
  const linhasFamiliasExcluidas = T.SkillLineAbility.filter((r) => linhasExcluidas.has(Number(r.SkillLine))).length;

  const familiaDaLinha = new Map();
  for (const f of familias) {
    if (f.linha === 0) continue;
    if (!familiaDaLinha.has(f.linha)) familiaDaLinha.set(f.linha, []);
    familiaDaLinha.get(f.linha).push(f);
  }
  const linhasPet = new Set([LINHA_GERAL, ...familiaDaLinha.keys()]);

  // Classifica cada linha de pet (SkillLineAbility) em incluída ou fora, com motivo.
  const linhas = T.SkillLineAbility
    .filter((r) => linhasPet.has(Number(r.SkillLine)))
    .sort((a, b) => Number(a.ID) - Number(b.ID));
  const totalLinhas = linhas.length;

  const registros = [];
  const tracos = new Map();
  const porNome = new Map();
  const ordemNomes = [];

  for (const r of linhas) {
    const linha = Number(r.SkillLine);
    const spellId = Number(r.Spell);
    const reg = { id: Number(r.ID), linha, spellId, nome: null, motivo: null };
    registros.push(reg);

    const nome = nomeSpell.get(spellId);
    if (nome === undefined) { reg.motivo = 'spell sem nome no SpellName'; continue; }
    reg.nome = nome;

    if (linha === LINHA_GERAL && TRACO_VELOCIDADE.test(nome)) {
      tracos.set(spellId, nome);
      reg.motivo = 'traço de velocidade (fora de geral e de habilidades)';
      continue;
    }

    const rank = rankDe(subtextoSpell.get(spellId) ?? '');
    if (rank === null) { reg.motivo = `rank ilegível (NameSubtext "${subtextoSpell.get(spellId)}")`; continue; }

    // Sem linha em SpellLevels, o nível fica null (a linha é mantida e contada na saída).
    const niv = nivelSpell.get(spellId);
    const nivelPet = niv ? niv.nivel : null;

    const custoBruto = r[COL_CUSTO];
    if (custoBruto === '' || !/^-?\d+$/.test(custoBruto)) { reg.motivo = `custo em pontos vazio ou não numérico ("${custoBruto}")`; continue; }

    if (!porNome.has(nome)) {
      porNome.set(nome, { linhas: new Set(), familias: new Set(), geral: false, spells: new Map() });
      ordemNomes.push(nome);
    }
    const e = porNome.get(nome);
    e.linhas.add(linha);
    if (linha === LINHA_GERAL) e.geral = true;
    else for (const f of familiaDaLinha.get(linha)) e.familias.add(f.id);

    if (!e.spells.has(spellId)) {
      e.spells.set(spellId, { rank, nivelPet, pt: Number(custoBruto), linhas: new Set([linha]) });
    } else {
      e.spells.get(spellId).linhas.add(linha);
    }
    reg.rank = rank;
  }

  // Duplicatas: mesmo nome e mesmo rank com spell ids diferentes. Mantém o menor spell id.
  const duplicados = [];
  const habilidades = {};
  const perdedores = new Map(); // nome -> Set(spellId)
  for (const nome of ordemNomes) {
    const e = porNome.get(nome);
    const porRank = new Map();
    for (const [spellId, s] of e.spells) {
      if (!porRank.has(s.rank)) porRank.set(s.rank, []);
      porRank.get(s.rank).push(spellId);
    }
    const ranks = [];
    for (const rank of [...porRank.keys()].sort((a, b) => a - b)) {
      const ids = porRank.get(rank).sort((a, b) => a - b);
      const [mantido, ...outros] = ids;
      const sm = e.spells.get(mantido);
      ranks.push({ rank, spellId: mantido, nivelPet: sm.nivelPet, pt: sm.pt });
      if (outros.length) {
        if (!perdedores.has(nome)) perdedores.set(nome, new Set());
        for (const o of outros) perdedores.get(nome).add(o);
        duplicados.push({
          nome,
          rank,
          mantido: { spellId: mantido, nivelPet: sm.nivelPet, pt: sm.pt },
          descartados: outros.map((o) => ({ spellId: o, nivelPet: e.spells.get(o).nivelPet, pt: e.spells.get(o).pt })),
        });
      }
    }
    const familiasNomes = e.geral
      ? ['all']
      : familias.filter((f) => e.familias.has(f.id)).map((f) => f.nome);
    habilidades[nome] = {
      linhas: [...e.linhas].sort((a, b) => a - b),
      familias: familiasNomes,
      ranks,
    };
  }

  // Contagem de linhas fora (linha perdedora de duplicata recebe o motivo aqui).
  for (const reg of registros) {
    if (reg.motivo === null && perdedores.has(reg.nome) && perdedores.get(reg.nome).has(reg.spellId)) {
      reg.motivo = 'duplicata de rank (outro spell id mantido em duplicados)';
    }
  }
  const foraPorMotivo = new Map();
  let incluidas = 0;
  for (const reg of registros) {
    if (reg.motivo === null) { incluidas++; continue; }
    foraPorMotivo.set(reg.motivo, (foraPorMotivo.get(reg.motivo) ?? 0) + 1);
  }

  const geral = [];
  for (const nome of ordemNomes) {
    if (porNome.get(nome).geral && !geral.includes(nome)) geral.push(nome);
  }

  const saida = {
    build: opts.build,
    geradoEm: new Date().toISOString(),
    fonte: `wago.tools DB2 (wowf ${opts.build})`,
    familias: familias.map((f) => ({
      id: f.id,
      nome: f.nome,
      linha: f.linha,
      dieta: dietaDe(f.mascara).nomes,
      habilidades: ordemNomes.filter((n) => {
        const e = porNome.get(n);
        return !e.geral && e.familias.has(f.id);
      }),
    })),
    geral,
    habilidades,
    tracosVelocidade: [...tracos].sort((a, b) => a[0] - b[0]).map(([spellId, nome]) => ({ spellId, nome })),
    duplicados,
  };

  await mkdir(path.dirname(opts.saida), { recursive: true });
  await writeFile(opts.saida, JSON.stringify(saida, null, 2) + '\n', 'utf8');

  const totalRanks = Object.values(habilidades).reduce((s, h) => s + h.ranks.length, 0);
  console.log(`saida: ${opts.saida}`);
  console.log(`familias de caçador (SkillLine_1 = ${LINHA_GERAL}): ${familias.length}`);
  console.log(`habilidades: ${Object.keys(habilidades).length}, ranks: ${totalRanks}, geral: ${geral.length}, traços de velocidade: ${saida.tracosVelocidade.length}`);
  const semNivel = Object.values(habilidades).reduce((s, h) => s + h.ranks.filter((r) => r.nivelPet === null).length, 0);
  console.log(`linhas de pet (SkillLineAbility, famílias de caçador + 270): ${totalLinhas}, incluídas: ${incluidas}, fora: ${totalLinhas - incluidas}`);
  for (const [motivo, n] of [...foraPorMotivo].sort((a, b) => b[1] - a[1])) {
    console.log(`  fora ${n}: ${motivo}`);
  }
  console.log(`linhas de famílias excluídas (fora do cálculo acima): ${linhasFamiliasExcluidas}`);
  console.log(`ranks incluídos sem nível em SpellLevels (nivelPet null): ${semNivel}`);
  console.log(`duplicados de rank: ${duplicados.length}`);
  for (const a of avisos) console.log(`aviso: ${a}`);
}

main().catch((e) => {
  console.error(`erro: ${e.message}`);
  process.exitCode = 1;
});
