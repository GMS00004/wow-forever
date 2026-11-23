// Gera as receitas a partir das tabelas do cliente.
// Uso: node gerar-receitas.mjs                         grava receitas-lw.json (esquema 1, contrato secao 3) e imprime as contagens
//      node gerar-receitas.mjs --profissao <nome|todas> grava receitas-<slug>.json (esquema 2, secao 10), com o Naowh
//      node gerar-receitas.mjs --profissao todas --sem-naowh   o mesmo, sem a tabela do Naowh
//      node gerar-receitas.mjs --conferir-vendedor        so confere o preco de vendedor (nao grava nada)
import { createReadStream } from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';
import { tabela, ARQ_RECEITAS, arqReceitas, gravarJson, pastaSavedVariables, BUILD, moeda, PROFISSOES, acharProfissao } from './comum.mjs';
import { carregarNaowh, naowhDaProfissao } from './naowh.mjs';

const PROFISSAO_LW = { id: 165, nome: 'Leatherworking' };
const MAX_DIVERGENCIAS = 30;
// Efeitos de magia do cliente: 24 cria item; 53 e 54 encantam um item (permanente e temporario).
const EFEITO_CRIAR = 24;
const EFEITOS_ENCANTAR = new Set([53, 54]);
// AcquireMethod da SkillLineAbility: 1 vem com a profissao (MinSkillLineRank 1); 3 nunca se aprende.
const VEM_COM_A_PROFISSAO = 1;
const NUNCA = 3;
const USO = 'uso: node gerar-receitas.mjs [--profissao <nome|todas> [--sem-naowh]] | --conferir-vendedor';

// Saida de terminal so em ASCII: tira acentos e troca o resto por '?'.
const ascii = s => String(s).normalize("NFD").replace(/\p{Mn}/gu, "").replace(/[^ -~]/g, "?");

// Comparacao de texto por codigo (igual ao que o testes/checar-receitas.mjs usa para a ordem).
const cmpTexto = (x, y) => (x < y ? -1 : x > y ? 1 : 0);

// O BuyPrice da tabela vale para o lote de VendorStackCount unidades; 0 vale 1.
const vendorStack = r => Number(r.VendorStackCount) || 1;

// Le so o bloco AUCTIONATOR_VENDOR_PRICE_CACHE do Auctionator.lua, linha a linha, e para ao fechar o bloco.
// Os outros blocos do arquivo nao sao lidos nem interpretados.
async function lerBlocoVendedor(arq) {
  const entradas = [];
  const erros = [];
  let estado = 'procura';
  const fluxo = createReadStream(arq, { encoding: 'utf8' });
  const linhas = readline.createInterface({ input: fluxo, crlfDelay: Infinity });
  try {
    for await (const linha of linhas) {
      if (estado === 'procura') {
        if (/^AUCTIONATOR_VENDOR_PRICE_CACHE = \{\s*$/.test(linha)) estado = 'bloco';
        continue;
      }
      if (linha.trim() === '}') { estado = 'fim'; break; }
      const m = /^\s*\["([^"]+)"\] = (-?\d+(?:\.\d+)?),?\s*$/.exec(linha);
      if (!m) erros.push(`linha do bloco nao reconhecida: ${linha.slice(0, 60)}`);
      else if (/^\d+$/.test(m[1])) entradas.push([m[1], Number(m[2])]);
      // Chave que nao e ID de item (ex.: "__dbversion") e metadado do Auctionator: ignorada.
    }
  } finally {
    linhas.close();
    fluxo.destroy();
  }
  if (estado === 'procura') throw new Error('bloco AUCTIONATOR_VENDOR_PRICE_CACHE nao achado em Auctionator.lua');
  if (estado === 'bloco') erros.push('bloco AUCTIONATOR_VENDOR_PRICE_CACHE sem a linha de fechamento');
  return { entradas, erros };
}

async function conferirVendedor() {
  const itens = await tabela('ItemSparse', ['ID', 'Display_lang', 'BuyPrice', 'VendorStackCount']);
  const porId = new Map(itens.map(r => [String(Number(r.ID)), r]));

  const arq = path.join(await pastaSavedVariables(), 'Auctionator.lua');
  const { entradas, erros } = await lerBlocoVendedor(arq);

  // Classes: igual (ate 1 cobre do BuyPrice); desconto (BuyPrice vezes 0,95, 0,90, 0,85 ou 0,80, com ate 1 cobre); senao divergente.
  const FATORES_DESCONTO = [0.95, 0.90, 0.85, 0.80];
  const classe = (compra, cobre) => {
    if (Math.abs(cobre - compra) <= 1) return 'igual';
    if (FATORES_DESCONTO.some(f => Math.abs(cobre - compra * f) <= 1)) return 'desconto';
    return 'divergente';
  };

  const vistos = new Set();
  let comparados = 0;
  const cont = { igual: 0, desconto: 0, divergente: 0 };
  const divergencias = [];
  for (const [id, cobre] of entradas) {
    if (vistos.has(id)) { erros.push(`id ${id} repetido no bloco`); continue; }
    vistos.add(id);
    const r = porId.get(id);
    if (!r) continue; // id que nao esta no ItemSparse nao entra na conferencia
    comparados++;
    const compra = Number(r.BuyPrice) / vendorStack(r);
    const k = classe(compra, cobre);
    cont[k]++;
    if (k === 'divergente') divergencias.push({ id, nome: r.Display_lang, tab: compra, jogo: cobre });
  }

  console.log(ascii(`comparados=${comparados} iguais=${cont.igual} desconto=${cont.desconto} divergentes=${cont.divergente}`));
  for (const d of divergencias.slice(0, MAX_DIVERGENCIAS)) {
    console.log(ascii(`${d.id} | ${d.nome} | tabela ${moeda(d.tab)} | jogo ${moeda(d.jogo)}`));
  }
  for (const e of erros) console.log(ascii(`ERRO ${e}`));
  process.exitCode = erros.length ? 1 : 0;
}

// Tabelas do cliente, lidas uma vez por execucao (as seis profissoes usam as mesmas).
let memoTabelas = null;
async function tabelas(esquema) {
  if (memoTabelas && memoTabelas.esquema >= esquema) return memoTabelas;
  const t = {
    esquema,
    sla: await tabela('SkillLineAbility', ['SkillLine', 'Spell', 'TrivialSkillLineRankLow', 'TrivialSkillLineRankHigh', 'NumSkillUps', 'AcquireMethod']),
    se: await tabela('SpellEffect', ['SpellID', 'Effect', 'EffectIndex', 'EffectItemType', 'EffectBasePointsF']),
    sr: await tabela('SpellReagents', ['SpellID', 'Reagent_0', 'Reagent_7', 'ReagentCount_0', 'ReagentCount_7']),
    sn: await tabela('SpellName', ['ID', 'Name_lang']),
    is: await tabela('ItemSparse', ['ID', 'Display_lang', 'SellPrice', 'BuyPrice', 'VendorStackCount', 'Stackable', 'Bonding', 'OverallQualityID', 'RequiredSkillRank']),
    ie: await tabela('ItemEffect', ['ID', 'TriggerType', 'SpellID']),
    ixi: await tabela('ItemXItemEffect', ['ItemEffectID', 'ItemID']),
  };
  if (esquema >= 2) {
    t.st = await tabela('SpellTotems', ['SpellID', 'RequiredTotemCategoryID_0', 'RequiredTotemCategoryID_1', 'Totem_0', 'Totem_1']);
    t.tc = await tabela('TotemCategory', ['ID', 'Name_lang', 'TotemCategoryType', 'TotemCategoryMask']);
    t.scr = await tabela('SpellCastingRequirements', ['SpellID', 'RequiresSpellFocus']);
    t.sfo = await tabela('SpellFocusObject', ['ID', 'Name_lang']);
  }
  memoTabelas = t;
  return t;
}

// Monta o objeto de receitas de uma profissao. esquema 1: o formato da secao 3, sem nada a mais (receitas-lw.json);
// esquema 2: secao 10 (inicial, nunca, encantamento, ferramentas e o Naowh, quando houver).
async function montar(prof, esquema, naowh) {
  const { sla, se, sr, sn, is, ie, ixi, st, tc, scr, sfo } = await tabelas(esquema);

  // Indices por chave, para as juncoes sem varrer as tabelas grandes a cada receita.
  const itemPorId = new Map(is.map(r => [String(Number(r.ID)), r]));
  const nomePorMagia = new Map(sn.map(r => [Number(r.ID), r.Name_lang]));
  const reagPorMagia = new Map();
  for (const r of sr) if (!reagPorMagia.has(Number(r.SpellID))) reagPorMagia.set(Number(r.SpellID), r);

  // Criar item (efeito 24): vale a linha de menor EffectIndex da magia. Encantar (53 e 54): so a marca.
  const efeitoCriar = new Map();
  const encanta = new Set();
  for (const r of se) {
    const ef = Number(r.Effect);
    if (EFEITOS_ENCANTAR.has(ef)) encanta.add(Number(r.SpellID));
    if (ef !== EFEITO_CRIAR) continue;
    const magia = Number(r.SpellID);
    const atual = efeitoCriar.get(magia);
    if (!atual || Number(r.EffectIndex) < Number(atual.EffectIndex)) efeitoCriar.set(magia, r);
  }

  // Item de receita (TriggerType 6): ItemEffect por magia e, dele, os ItemID ligados.
  const efeitosPorMagia = new Map();
  for (const r of ie) {
    if (Number(r.TriggerType) !== 6) continue;
    const magia = Number(r.SpellID);
    if (!efeitosPorMagia.has(magia)) efeitosPorMagia.set(magia, []);
    efeitosPorMagia.get(magia).push(Number(r.ID));
  }
  const itensPorEfeito = new Map();
  for (const r of ixi) {
    const efeito = Number(r.ItemEffectID);
    if (!itensPorEfeito.has(efeito)) itensPorEfeito.set(efeito, []);
    itensPorEfeito.get(efeito).push(Number(r.ItemID));
  }

  const itemReceitaDe = (id, row) => ({
    id,
    nome: row.Display_lang,
    periciaExigida: Number(row.RequiredSkillRank),
    compra: Math.ceil(Number(row.BuyPrice) / vendorStack(row)),
  });

  // Item de receita: entre os itens ligados que existem no ItemSparse, prefere "Pattern: <nome>" (no esquema 2,
  // tambem Recipe, Plans, Formula, Schematic e Design); depois, o menor ID.
  const PREFIXOS = esquema >= 2 ? ['Pattern', 'Recipe', 'Plans', 'Formula', 'Schematic', 'Design', 'Manual'] : ['Pattern'];
  function itemDaReceita(magia, nome) {
    const candidatos = [];
    for (const efeito of efeitosPorMagia.get(magia) || []) {
      for (const itemId of itensPorEfeito.get(efeito) || []) {
        const r = itemPorId.get(String(itemId));
        if (r) candidatos.push({ id: itemId, row: r });
      }
    }
    if (!candidatos.length) return null;
    const nomes = new Set(PREFIXOS.map(p => `${p}: ${nome}`));
    const peso = c => (nomes.has(c.row.Display_lang) ? 0 : 1);
    candidatos.sort((a, b) => peso(a) - peso(b) || a.id - b.id);
    const c = candidatos[0];
    return itemReceitaDe(c.id, c.row);
  }

  // Reagentes da magia; par com item 0 ou quantidade 0 e ignorado.
  function reagentesDe(magia) {
    const r = reagPorMagia.get(magia);
    if (!r) return [];
    const saida = [];
    for (let i = 0; i < 8; i++) {
      const id = Number(r[`Reagent_${i}`]);
      const qtd = Number(r[`ReagentCount_${i}`]);
      if (id && qtd) saida.push({ id, qtd });
    }
    return saida;
  }

  // Ferramentas (esquema 2): SpellTotems da magia. Categoria pedida (RequiredTotemCategoryID) vale para todo item cuja
  // categoria tem o mesmo tipo e contem a mascara pedida (a Runed Silver Rod serve onde se pede a Runed Copper Rod);
  // Totem_N e um item exato.
  const totemPorMagia = new Map();
  const catPorId = new Map();
  const itensPorCat = new Map();
  if (esquema >= 2) {
    for (const r of st) if (!totemPorMagia.has(Number(r.SpellID))) totemPorMagia.set(Number(r.SpellID), r);
    for (const r of tc) catPorId.set(Number(r.ID), { nome: r.Name_lang, tipo: Number(r.TotemCategoryType), mascara: Number(r.TotemCategoryMask) >>> 0 });
    for (const r of is) {
      const c = Number(r.TotemCategoryID);
      if (!c) continue;
      if (!itensPorCat.has(c)) itensPorCat.set(c, []);
      itensPorCat.get(c).push(Number(r.ID));
    }
  }
  function satisfazem(cat) {
    const pedida = catPorId.get(cat);
    const out = [];
    for (const [c2, ids] of itensPorCat) {
      const k = catPorId.get(c2);
      if (c2 === cat || (pedida && k && k.tipo === pedida.tipo && ((k.mascara & pedida.mascara) >>> 0) === pedida.mascara)) out.push(...ids);
    }
    return [...new Set(out)].sort((a, b) => a - b);
  }
  function ferramentasDe(magia) {
    const r = totemPorMagia.get(magia);
    if (!r) return [];
    const out = [];
    for (const k of [0, 1]) {
      const cat = Number(r[`RequiredTotemCategoryID_${k}`]);
      if (cat) out.push({ categoria: cat, nome: catPorId.get(cat)?.nome ?? String(cat), itens: satisfazem(cat).filter(id => itemPorId.has(String(id))) });
      const tot = Number(r[`Totem_${k}`]);
      if (tot) out.push({ categoria: null, nome: itemPorId.get(String(tot))?.Display_lang ?? String(tot), itens: itemPorId.has(String(tot)) ? [tot] : [] });
    }
    return out;
  }

  // Objeto por perto (esquema 2): SpellCastingRequirements.RequiresSpellFocus da magia e o nome no SpellFocusObject.
  // E objeto de acampamento quando existe item com o mesmo nome no ItemSparse (Tanning Rack, Spinning Wheel, Fermenter):
  // ele se compra e se gasta ao montar. Anvil e Forge existem nas cidades e nao contam como acampamento.
  const focoPorMagia = new Map();
  const nomeFoco = new Map();
  const itensPorNome = new Map();
  const NA_CIDADE = new Set(['Anvil', 'Forge']);
  if (esquema >= 2) {
    for (const r of scr) if (Number(r.RequiresSpellFocus) && !focoPorMagia.has(Number(r.SpellID))) focoPorMagia.set(Number(r.SpellID), Number(r.RequiresSpellFocus));
    for (const r of sfo) nomeFoco.set(Number(r.ID), r.Name_lang);
    for (const r of is) {
      if (!itensPorNome.has(r.Display_lang)) itensPorNome.set(r.Display_lang, []);
      itensPorNome.get(r.Display_lang).push(Number(r.ID));
    }
  }
  function focoDe(magia) {
    const id = focoPorMagia.get(magia);
    if (!id) return null;
    const nome = nomeFoco.get(id) ?? String(id);
    const itens = NA_CIDADE.has(nome) ? [] : (itensPorNome.get(nome) || []).slice().sort((a, b) => a - b);
    return { id, nome, acampamento: itens.length > 0, itens };
  }

  // Magias da profissao, sem repetir.
  const magias = new Map();
  for (const r of sla) {
    if (Number(r.SkillLine) !== prof.id) continue;
    const magia = Number(r.Spell);
    if (!magias.has(magia)) magias.set(magia, r);
  }

  const nw = esquema >= 2 && naowh ? naowhDaProfissao(naowh.dados, prof.id) : null;
  const receitas = [];
  let semItem = 0, semReagente = 0, semItemSparse = 0, nunca = 0, encantamentos = 0;
  const cNaowh = { comDado: 0, semDado: 0, divergenciasCor: 0, padraoDoNaowh: 0 };
  for (const [magia, r] of magias) {
    const am = Number(r.AcquireMethod);
    if (esquema >= 2 && am === NUNCA) { nunca++; continue; }
    const criar = efeitoCriar.get(magia);
    const soEncanta = esquema >= 2 && !criar && encanta.has(magia);
    if (!criar && !soEncanta) { semItem++; continue; }

    const reagentes = reagentesDe(magia);
    if (!reagentes.length) { semReagente++; continue; }

    const produto = criar ? { id: Number(criar.EffectItemType), qtd: Number(criar.EffectBasePointsF) || 1 } : null;
    const faltaItem = (produto && !itemPorId.has(String(produto.id))) || reagentes.some(g => !itemPorId.has(String(g.id)));
    if (faltaItem) { semItemSparse++; continue; }

    const nome = nomePorMagia.get(magia);
    if (nome === undefined) throw new Error(`magia ${magia} sem nome em SpellName`);

    const rec = {
      magia,
      nome,
      produto,
      reagentes,
      amarela: Number(r.TrivialSkillLineRankLow),
      cinza: Number(r.TrivialSkillLineRankHigh),
      pontos: Number(r.NumSkillUps),
      itemReceita: itemDaReceita(magia, nome),
    };
    if (esquema >= 2) {
      rec.inicial = am === VEM_COM_A_PROFISSAO;
      if (soEncanta) { rec.encantamento = true; encantamentos++; }
      const fer = ferramentasDe(magia);
      if (fer.length) rec.ferramentas = fer;
      const foco = focoDe(magia);
      if (foco) rec.foco = foco;
      const d = nw ? nw.receitas.get(magia) : null;
      if (d) {
        cNaowh.comDado++;
        rec.naowh = { aprende: d.aprende, origem: d.origem, custo: d.custo, lados: d.lados };
        if (d.amarela !== null && (d.amarela !== rec.amarela || d.cinza !== rec.cinza)) cNaowh.divergenciasCor++;
        // Padrao que o cliente nao liga a receita, mas o Naowh da: vale o item do Naowh, se existir no ItemSparse.
        if (!rec.itemReceita && d.padrao && itemPorId.has(String(d.padrao))) {
          rec.itemReceita = itemReceitaDe(d.padrao, itemPorId.get(String(d.padrao)));
          cNaowh.padraoDoNaowh++;
        }
      } else if (nw) cNaowh.semDado++;
    }
    receitas.push(rec);
  }

  receitas.sort((a, b) => a.amarela - b.amarela || cmpTexto(a.nome, b.nome));

  // Itens citados (produto, reagentes e, no esquema 2, ferramentas) das receitas incluidas, com a chave em texto.
  const itens = {};
  const pegar = id => {
    const k = String(id);
    if (itens[k]) return;
    const r = itemPorId.get(k);
    if (!r) return;
    itens[k] = {
      nome: r.Display_lang,
      vende: Number(r.SellPrice),
      compra: Math.ceil(Number(r.BuyPrice) / vendorStack(r)),
      pilha: Number(r.Stackable),
      vinculo: Number(r.Bonding),
      qualidade: Number(r.OverallQualityID),
    };
  };
  for (const x of receitas) {
    if (x.produto) pegar(x.produto.id);
    for (const g of x.reagentes) pegar(g.id);
    for (const f of x.ferramentas || []) for (const id of f.itens) pegar(id);
    for (const id of x.foco?.itens || []) pegar(id);
  }

  const comItemReceita = receitas.filter(x => x.itemReceita).length;
  const contagem = { receitas: receitas.length, semItem, semReagente, semItemSparse, comItemReceita };
  const obj = { esquema, build: BUILD, geradoEm: new Date().toISOString(), profissao: prof, contagem, receitas, itens };
  if (esquema >= 2) {
    Object.assign(contagem, {
      nunca,
      encantamentos,
      iniciais: receitas.filter(x => x.inicial).length,
      comFerramenta: receitas.filter(x => x.ferramentas).length,
      comAcampamento: receitas.filter(x => x.foco?.acampamento).length,
    });
    obj.naowh = nw ? { versao: naowh.versao, ranks: nw.ranks, ...cNaowh } : null;
  }
  return { obj, magias: magias.size };
}

async function gerarLegado() {
  const { obj, magias } = await montar(PROFISSAO_LW, 1, null);
  await gravarJson(ARQ_RECEITAS, obj);
  const c = obj.contagem;
  console.log(ascii(`magias=${magias} receitas=${c.receitas} semItem=${c.semItem} semReagente=${c.semReagente} semItemSparse=${c.semItemSparse} comItemReceita=${c.comItemReceita} itens=${Object.keys(obj.itens).length}`));
}

async function gerarProfissoes(alvo, comNaowh) {
  const lista = alvo === 'todas'
    ? Object.entries(PROFISSOES).map(([slug, p]) => ({ slug, ...p }))
    : [acharProfissao(alvo)];
  if (lista.some(p => !p)) {
    console.error(`profissao desconhecida: ${alvo} (use ${Object.keys(PROFISSOES).join(', ')} ou todas)`);
    process.exit(2);
  }
  const naowh = comNaowh ? await carregarNaowh() : null;
  if (comNaowh && !naowh) console.log('aviso: NaowhForever_Professions nao achado na pasta AddOns; segue sem o Naowh');
  if (naowh) console.log(ascii(`naowh: versao ${naowh.versao}`));
  for (const p of lista) {
    const { obj, magias } = await montar({ id: p.id, nome: p.nome, slug: p.slug }, 2, naowh);
    await gravarJson(arqReceitas(p.slug), obj);
    const c = obj.contagem;
    const n = obj.naowh;
    console.log(ascii(`${p.slug}: magias=${magias} receitas=${c.receitas} iniciais=${c.iniciais} encantamentos=${c.encantamentos} nunca=${c.nunca} semItem=${c.semItem} semReagente=${c.semReagente} semItemSparse=${c.semItemSparse} comItemReceita=${c.comItemReceita} comFerramenta=${c.comFerramenta} comAcampamento=${c.comAcampamento}`
      + (n ? ` naowh=${n.comDado}/${n.comDado + n.semDado} divergenciasCor=${n.divergenciasCor} padraoDoNaowh=${n.padraoDoNaowh}` : ' naowh=nao')));
  }
}

const argv = process.argv.slice(2);
if (argv.includes('--conferir-vendedor')) await conferirVendedor();
else if (argv.includes('--profissao')) {
  const v = argv[argv.indexOf('--profissao') + 1];
  if (!v || v.startsWith('--')) { console.error(USO); process.exit(2); }
  const resto = argv.filter((a, i) => a !== '--profissao' && i !== argv.indexOf('--profissao') + 1 && a !== '--sem-naowh');
  if (resto.length) { console.error(`argumento desconhecido: ${resto[0]}\n${USO}`); process.exit(2); }
  await gerarProfissoes(v.toLowerCase(), !argv.includes('--sem-naowh'));
} else if (argv.length) {
  console.error(`argumento desconhecido: ${argv[0]}\n${USO}`);
  process.exit(2);
} else await gerarLegado();
