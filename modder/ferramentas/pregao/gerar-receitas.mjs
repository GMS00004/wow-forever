// Gera dados/pregao/receitas-lw.json (contrato, secao 3) a partir das tabelas do cliente.
// Uso: node gerar-receitas.mjs                      grava receitas-lw.json e imprime as contagens
//      node gerar-receitas.mjs --conferir-vendedor  so confere o preco de vendedor (nao grava nada)
import { createReadStream } from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';
import { tabela, ARQ_RECEITAS, gravarJson, pastaSavedVariables, BUILD, moeda } from './comum.mjs';

const PROFISSAO = { id: 165, nome: 'Leatherworking' };
const MAX_DIVERGENCIAS = 30;

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

async function gerar() {
  const sla = await tabela('SkillLineAbility', ['SkillLine', 'Spell', 'TrivialSkillLineRankLow', 'TrivialSkillLineRankHigh', 'NumSkillUps']);
  const se = await tabela('SpellEffect', ['SpellID', 'Effect', 'EffectIndex', 'EffectItemType', 'EffectBasePointsF']);
  const sr = await tabela('SpellReagents', ['SpellID', 'Reagent_0', 'Reagent_7', 'ReagentCount_0', 'ReagentCount_7']);
  const sn = await tabela('SpellName', ['ID', 'Name_lang']);
  const is = await tabela('ItemSparse', ['ID', 'Display_lang', 'SellPrice', 'BuyPrice', 'VendorStackCount', 'Stackable', 'Bonding', 'OverallQualityID', 'RequiredSkillRank']);
  const ie = await tabela('ItemEffect', ['ID', 'TriggerType', 'SpellID']);
  const ixi = await tabela('ItemXItemEffect', ['ItemEffectID', 'ItemID']);

  // Indices por chave, para as juncoes sem varrer as tabelas grandes a cada receita.
  const itemPorId = new Map(is.map(r => [String(Number(r.ID)), r]));
  const nomePorMagia = new Map(sn.map(r => [Number(r.ID), r.Name_lang]));
  const reagPorMagia = new Map();
  for (const r of sr) if (!reagPorMagia.has(Number(r.SpellID))) reagPorMagia.set(Number(r.SpellID), r);

  // Criar item (efeito 24): vale a linha de menor EffectIndex da magia.
  const efeitoCriar = new Map();
  for (const r of se) {
    if (Number(r.Effect) !== 24) continue;
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

  // Item de receita: entre os itens ligados que existem no ItemSparse, prefere "Pattern: <nome>"; depois, o menor ID.
  function itemDaReceita(magia, nome) {
    const candidatos = [];
    for (const efeito of efeitosPorMagia.get(magia) || []) {
      for (const itemId of itensPorEfeito.get(efeito) || []) {
        const r = itemPorId.get(String(itemId));
        if (r) candidatos.push({ id: itemId, row: r });
      }
    }
    if (!candidatos.length) return null;
    const padrao = `Pattern: ${nome}`;
    const peso = c => (c.row.Display_lang === padrao ? 0 : 1);
    candidatos.sort((a, b) => peso(a) - peso(b) || a.id - b.id);
    const c = candidatos[0];
    return {
      id: c.id,
      nome: c.row.Display_lang,
      periciaExigida: Number(c.row.RequiredSkillRank),
      compra: Math.ceil(Number(c.row.BuyPrice) / vendorStack(c.row)),
    };
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

  // Magias de Leatherworking, sem repetir.
  const magiasLW = new Map();
  for (const r of sla) {
    if (Number(r.SkillLine) !== 165) continue;
    const magia = Number(r.Spell);
    if (!magiasLW.has(magia)) magiasLW.set(magia, r);
  }

  const receitas = [];
  let semItem = 0, semReagente = 0, semItemSparse = 0;
  for (const [magia, r] of magiasLW) {
    const criar = efeitoCriar.get(magia);
    if (!criar) { semItem++; continue; }

    const reagentes = reagentesDe(magia);
    if (!reagentes.length) { semReagente++; continue; }

    const produtoId = Number(criar.EffectItemType);
    const produtoQtd = Number(criar.EffectBasePointsF) || 1;
    const faltaItem = !itemPorId.has(String(produtoId)) || reagentes.some(g => !itemPorId.has(String(g.id)));
    if (faltaItem) { semItemSparse++; continue; }

    const nome = nomePorMagia.get(magia);
    if (nome === undefined) throw new Error(`magia ${magia} sem nome em SpellName`);

    receitas.push({
      magia,
      nome,
      produto: { id: produtoId, qtd: produtoQtd },
      reagentes,
      amarela: Number(r.TrivialSkillLineRankLow),
      cinza: Number(r.TrivialSkillLineRankHigh),
      pontos: Number(r.NumSkillUps),
      itemReceita: itemDaReceita(magia, nome),
    });
  }

  receitas.sort((a, b) => a.amarela - b.amarela || cmpTexto(a.nome, b.nome));

  // Itens citados (produto e reagentes) das receitas incluidas, com a chave em texto.
  const itens = {};
  const pegar = id => {
    const k = String(id);
    if (itens[k]) return;
    const r = itemPorId.get(k);
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
    pegar(x.produto.id);
    for (const g of x.reagentes) pegar(g.id);
  }

  const comItemReceita = receitas.filter(x => x.itemReceita).length;
  const contagem = {
    receitas: receitas.length,
    semItem,
    semReagente,
    semItemSparse,
    comItemReceita,
  };
  const obj = {
    esquema: 1,
    build: BUILD,
    geradoEm: new Date().toISOString(),
    profissao: PROFISSAO,
    contagem,
    receitas,
    itens,
  };
  await gravarJson(ARQ_RECEITAS, obj);

  console.log(ascii(`magias=${magiasLW.size} receitas=${contagem.receitas} semItem=${semItem} semReagente=${semReagente} semItemSparse=${semItemSparse} comItemReceita=${comItemReceita} itens=${Object.keys(itens).length}`));
}

if (process.argv.includes('--conferir-vendedor')) await conferirVendedor();
else await gerar();
