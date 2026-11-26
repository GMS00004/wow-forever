// Rota de uma profissao entre duas pericias, fora do jogo (PregaoForever): Leatherworking pelo receitas-lw.json e,
// com --profissao, as seis profissoes de oficio (secao 10). Contrato em CONTRATO.md, secao 6.
// Uso: node rota.mjs --de 186 --ate 225 [--sem "A,B"] [--so "A,B"] [--lua] [--profissao <nome>]
import { pathToFileURL } from 'node:url';
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { ARQ_RECEITAS, ARQ_PRECOS, lerJson, moeda, pastaSavedVariables, arqReceitas, acharProfissao, PROFISSOES, faccao } from './comum.mjs';
import { calcular, comDesconto, lerDesconto, DESCONTO_VENDEDOR, aprendeTxt } from './crafts.mjs';

const JANELA_AUCTIONATOR = 21600; // segundos: a exportacao do Auctionator so vale ate 6 horas (como no crafts.mjs)
const TOLERANCIA = 1e-9;
const MAX_PASSOS = 20;
const USO = 'uso: node rota.mjs --de 186 --ate 225 [--sem "A,B"] [--so "A,B"] [--conheco "A,B"] [--todos-padroes] [--desconto-vendedor 10] [--lua | --addon <RotaCrafts.lua>] [--profissao <nome>]';

const chave = (id) => String(id);
const minusc = (s) => String(s).toLowerCase();

// Reagentes validos de uma receita: id diferente de 0 e quantidade maior que 0.
const reagentesDe = (r) => r.reagentes.filter((g) => Number(g.id) !== 0 && g.qtd > 0);

// Chance de subir a pericia s com uma craft da receita (mesma regra do crafts.mjs).
function chanceEm(r, s) {
  if (r.pontos === 0) return 0;
  if (s < r.amarela) return 1;
  if (s >= r.cinza) return 0;
  return Math.min(1, Math.max(0, (r.cinza - s) / (r.cinza - r.amarela)));
}

// O que o J precisa para refazer custo e resultado com o preco do Auctionator (secao 6.3): o produto, se ele
// pode ir ao leilao e, por reagente, a quantidade por craft, o preco que a ferramenta usou, a letra (L leilao,
// V vendedor, F fabricar) e o preco de vendedor quando o vendedor vende o item. Reagente com letra F leva tambem
// `fab`, a receita mais barata que o faz (um nivel): quantos saem por craft e os reagentes dela, para o J refazer o
// preco de fabricar com o leilao de agora (por exemplo, curar a Medium Hide em vez de comprar a Cured Medium Hide).
function dadosVivos(r, l, receitas, vendedor, linhas) {
  const prod = r.produto ? receitas.itens?.[chave(r.produto.id)] : null; // encantamento: sem produto (secao 10)
  const fab = linhas ? mapaFab(receitas, linhas) : null;
  const mat = (g) => {
    const it = receitas.itens?.[chave(g.id)];
    return {
      id: g.id,
      nome: it?.nome ?? chave(g.id),
      un: g.qtd,
      preco: g.preco,
      letra: g.letra,
      vendedor: vendedor.has(chave(g.id)) && it && it.compra > 0 ? it.compra : null,
    };
  };
  return {
    produto: r.produto ? r.produto.id : null,
    produtoQtd: r.produto ? r.produto.qtd : 0,
    vinculado: prod ? prod.vinculo === 1 : false,
    precoLeilao: l.precoLeilao ?? null,
    precosMat: (l.reagentes || []).map((g) => {
      const m = mat(g);
      const f = g.letra === 'F' && fab ? fab.get(chave(g.id)) : null;
      if (f) m.fab = { qtd: f.r.produto.qtd, mats: (f.l.reagentes || []).map(mat) };
      return m;
    }),
  };
}

// Por item produzido, a receita de menor custo por unidade (a do candidato F do crafts.mjs, um nivel).
const memoFab = new WeakMap();
function mapaFab(receitas, linhas) {
  let m = memoFab.get(linhas);
  if (m) return m;
  m = new Map();
  receitas.receitas.forEach((r, i) => {
    const l = linhas[i];
    if (!l || l.semPreco || l.custo === null || !r.produto) return;
    const k = chave(r.produto.id);
    const un = l.custo / r.produto.qtd;
    const atual = m.get(k);
    if (!atual || un < atual.un) m.set(k, { r, l, un });
  });
  memoFab.set(linhas, m);
  return m;
}

// Funcao pura: nao le arquivo e nao usa relogio. A hora vem em opcoes.agora (epoch em segundos).
export function calcularRota(receitas, precos, opcoes) {
  const { de, ate, agora } = opcoes;
  const sem = new Set((opcoes.sem || []).map(minusc));
  const so = opcoes.so == null ? null : new Set(opcoes.so.map(minusc));
  // semMagias (secao 10): receitas a tirar pelo ID da magia, para o legado.mjs testar a rota sem uma ferramenta.
  const semMagias = opcoes.semMagias instanceof Set ? opcoes.semMagias : new Set(opcoes.semMagias || []);
  // custoPonto (secao 10.3): funcao (r, l, e) => custo do ponto, para o legado.mjs pesar o tempo de cada craft e nao
  // premiar lucro de vendedor com craft a mais. Sem ela, o custo do ponto no pior caso, como sempre.
  const custoPonto = typeof opcoes.custoPonto === 'function' ? opcoes.custoPonto : null;

  // Constantes por receita: calcular() nao depende da pericia para custo, venda, leilao, limite e aprende.
  // opcoes.linhas (as linhas de um calcular() ja feito) poupa a conta quando a rota roda muitas vezes.
  const { linhas } = opcoes.linhas ? { linhas: opcoes.linhas } : calcular(receitas, precos, { pericia: de, agora });
  const rec = receitas.receitas.map((r, i) => ({ r, l: linhas[i] }));

  // Um ponto por vez.
  const n = rec.map(() => 0);
  const pontos = [];
  let parou = null;
  let chegou = ate;
  for (let s = de; s < ate; s++) {
    const cands = [];
    rec.forEach(({ r, l }, i) => {
      if (l.semPreco || l.vendaNpc === null) return;
      if (l.aprende > s) return;
      if (semMagias.has(r.magia)) return;
      const nome = minusc(r.nome);
      if (sem.has(nome) || (so !== null && !so.has(nome))) return;
      const c = chanceEm(r, s);
      if (!(c > 0)) return;
      const e = 1 / (c * r.pontos);
      if (l.ate !== null && n[i] + e > l.ate) return;
      cands.push({ i, e, k: custoPonto ? custoPonto(r, l, e) : (l.custo - l.vendaNpc) * e });
    });
    if (cands.length === 0) {
      parou = { pericia: s, motivo: 'sem receita' };
      chegou = s;
      break;
    }
    // Menor custo do ponto no pior caso; no empate, maior lucro no leilao (nulo perde); depois, menor magia.
    const minK = Math.min(...cands.map((c) => c.k));
    const [vence] = cands
      .filter((c) => c.k <= minK + TOLERANCIA)
      .sort((a, b) => {
        const la = rec[a.i].l.lucroLeilao, lb = rec[b.i].l.lucroLeilao;
        if (la !== lb) {
          if (la === null) return 1;
          if (lb === null) return -1;
          return lb - la;
        }
        return rec[a.i].r.magia - rec[b.i].r.magia;
      });
    n[vence.i] += vence.e;
    pontos.push({ s, i: vence.i, e: vence.e });
  }

  // Pontos seguidos da mesma receita formam um passo.
  const grupos = [];
  for (const p of pontos) {
    const ult = grupos[grupos.length - 1];
    if (ult && ult.i === p.i) {
      ult.ate = p.s + 1;
      ult.esperado += p.e;
    } else {
      grupos.push({ i: p.i, de: p.s, ate: p.s + 1, esperado: p.e });
    }
  }

  const vendedor = new Set((precos.vendedor || []).map(chave));
  const passos = grupos.map((g) => {
    const { r, l } = rec[g.i];
    const crafts = Math.ceil(g.esperado - TOLERANCIA);
    const piorCaso = crafts * (l.vendaNpc - l.custo);
    const materiais = reagentesDe(r).map((x) => ({
      id: Number(x.id),
      nome: receitas.itens?.[chave(x.id)]?.nome ?? chave(x.id),
      qtd: x.qtd * crafts,
    }));
    const h = r.produto ? precos.publico?.historico?.[chave(r.produto.id)] : null;
    return {
      ...dadosVivos(r, l, receitas, vendedor, linhas),
      de: g.de,
      ate: g.ate,
      magia: r.magia,
      nome: r.nome,
      crafts,
      esperado: g.esperado,
      custo: l.custo,
      vendaNpc: l.vendaNpc,
      lucroLeilao: l.lucroLeilao,
      aprende: l.aprende,
      aprendeEstimado: l.aprendeEstimado,
      aprendeFonte: l.aprendeFonte,
      treino: l.treino,
      itemReceita: r.itemReceita != null,
      listados: l.listados,
      saiDia: l.saiDia,
      piorCaso,
      seVender: l.lucroLeilao === null ? piorCaso : crafts * l.lucroLeilao,
      materiais,
      historico: Array.isArray(h) && h.length > 0 ? h.slice(-4) : null,
    };
  });

  const totais = passos.reduce(
    (t, p) => ({
      crafts: t.crafts + p.crafts,
      custo: t.custo + p.crafts * p.custo,
      piorCaso: t.piorCaso + p.piorCaso,
      seVender: t.seVender + p.seVender,
    }),
    { crafts: 0, custo: 0, piorCaso: 0, seVender: 0 },
  );

  return { de, ate, chegou, parou, passos, totais };
}

// ---------- padroes (secao 6.1) ----------

// Situacao do padrao de cada receita, por magia. Funcao pura.
// conhecida: o personagem ja sabe (opcoes.conhecidas, um Set de magias); treinador: receita sem item;
// vendedor: o padrao esta na lista de itens de vendedor; leilao: anunciado agora (exportacao do
// Auctionator com ate 6 horas e idade 0, ou a foto publica); fora: nenhum dos anteriores.
// opcoes.lado ("A" ou "H") e a faccao dos vendedores que contam; sem ele, a do jogador (faccao() em comum.mjs).
export function situacaoPadroes(receitas, precos, opcoes) {
  const { agora } = opcoes;
  const lado = opcoes.lado || faccao().letra;
  const conhecidas = opcoes.conhecidas || new Set();
  const vendedor = new Set(precos.vendedor || []);
  const auc = precos.auctionator && agora - precos.auctionator.em <= JANELA_AUCTIONATOR ? precos.auctionator.itens : null;
  const mapa = new Map();
  for (const r of receitas.receitas) {
    if (conhecidas.has(r.magia) || r.inicial) {
      mapa.set(r.magia, { situacao: 'conhecida', preco: 0 });
      continue;
    }
    const nw = r.naowh || null;
    const ir = r.itemReceita;
    // Esquema 2 (secao 10): o Naowh diz quem ensina. Treinador vale mesmo com item de receita; sem item e sem
    // treinador (quest, drop, vendedor, origem desconhecida ou receita que o Naowh nao tem), a receita fica fora.
    if (nw && nw.origem === 'trainer') {
      mapa.set(r.magia, { situacao: 'treinador', preco: 0 });
      continue;
    }
    if (!ir) {
      if (receitas.esquema >= 2) mapa.set(r.magia, { situacao: 'fora', preco: null, visto: null, motivo: nw ? `origem ${nw.origem}` : 'sem dado do Naowh' });
      else mapa.set(r.magia, { situacao: 'treinador', preco: 0 });
      continue;
    }
    const base = { id: ir.id, nome: ir.nome };
    const pub = precos.publico?.itens?.[chave(ir.id)];
    const a = auc?.[chave(ir.id)];
    // Com o Naowh, padrao de vendedor so conta se algum vendedor dele e da faccao do jogador ou neutro ("A", "H" ou "AH").
    const ladoVende = !nw || !nw.lados || nw.lados.length === 0 || nw.lados.some((x) => x.includes(lado));
    if (vendedor.has(ir.id) && ir.compra > 0 && ladoVende) {
      mapa.set(r.magia, { ...base, situacao: 'vendedor', preco: ir.compra });
    } else if (a && a.idadeDias === 0) {
      mapa.set(r.magia, { ...base, situacao: 'leilao', preco: a.preco, listados: pub ? pub.unid : null });
    } else if (pub) {
      mapa.set(r.magia, { ...base, situacao: 'leilao', preco: pub.min, listados: pub.unid });
    } else {
      const h = precos.publico?.historico?.[chave(ir.id)];
      const v = Array.isArray(h) && h.length ? h[h.length - 1] : null;
      mapa.set(r.magia, { ...base, situacao: 'fora', preco: null, visto: v ? { dia: v[0], min: v[1], med: v[2], unid: v[3] } : null });
    }
  }
  return mapa;
}

const COMPRA = new Set(['leilao', 'vendedor']);

// Valor de uma rota com padroes: quem chega mais longe vence; depois, o maior pior caso ja com o preco
// dos padroes comprados (cada padrao conta uma vez).
function avaliar(rota, sit) {
  const comprados = new Map();
  for (const p of rota.passos) {
    const s = sit.get(p.magia);
    if (s && COMPRA.has(s.situacao)) comprados.set(s.id, s.preco);
  }
  const padroes = [...comprados.values()].reduce((a, b) => a + b, 0);
  return { chegou: rota.chegou, valor: rota.totais.piorCaso - padroes, padroes };
}

const melhor = (a, b) => a.chegou > b.chegou || (a.chegou === b.chegou && a.valor > b.valor + TOLERANCIA);

// Rota so com o que da para fazer: receitas conhecidas, de treinador ou com padrao a venda agora.
// Um padrao a venda so entra se se paga na rota (busca local: poe ou tira um padrao por vez enquanto
// melhora). opcoes: { de, ate, agora, sem, so, conhecidas }. Funcao pura.
export function escolherRota(receitas, precos, opcoes) {
  const { de, ate, agora } = opcoes;
  const sit = situacaoPadroes(receitas, precos, opcoes);
  const { linhas } = calcular(receitas, precos, { pericia: de, agora });
  const semBase = new Set((opcoes.sem || []).map(minusc));
  const so = opcoes.so == null ? null : new Set(opcoes.so.map(minusc));

  const fora = [];
  const compraveis = [];
  receitas.receitas.forEach((r, i) => {
    const s = sit.get(r.magia);
    const nome = minusc(r.nome);
    if (semBase.has(nome) || (so !== null && !so.has(nome))) return;
    if (s.situacao === 'fora') fora.push(r.nome);
    else if (COMPRA.has(s.situacao) && linhas[i].aprende < ate && r.cinza > de) compraveis.push(r.nome);
  });

  const rodar = (aceitos) => {
    const sem = [...semBase, ...fora, ...compraveis.filter((n) => !aceitos.has(n))];
    const rota = calcularRota(receitas, precos, { de, ate, agora, sem, so: opcoes.so ?? null, linhas, semMagias: opcoes.semMagias, custoPonto: opcoes.custoPonto });
    return { rota, nota: avaliar(rota, sit) };
  };

  let aceitos = new Set();
  let atual = rodar(aceitos);
  for (let volta = 0; volta < 50; volta++) {
    let troca = null;
    for (const n of compraveis) {
      const prova = new Set(aceitos);
      if (prova.has(n)) prova.delete(n);
      else prova.add(n);
      const r = rodar(prova);
      if (melhor(r.nota, (troca || atual).nota)) troca = { ...r, aceitos: prova };
    }
    if (!troca) break;
    atual = troca;
    aceitos = troca.aceitos;
  }

  // A mesma rota supondo todos os padroes na mao: o que ela usa e nao esta a venda e o que vale
  // esperar no leilao.
  const livre = calcularRota(receitas, precos, { de, ate, agora, sem: [...semBase], so: opcoes.so ?? null, linhas, semMagias: opcoes.semMagias, custoPonto: opcoes.custoPonto });
  const esperar = [];
  for (const p of livre.passos) {
    const s = sit.get(p.magia);
    if (s.situacao === 'fora' && !esperar.some((e) => e.magia === p.magia)) {
      esperar.push({ magia: p.magia, nome: p.nome, padrao: { id: s.id, nome: s.nome }, visto: s.visto });
    }
  }

  const rota = atual.rota;
  for (const p of rota.passos) {
    const s = sit.get(p.magia);
    p.padrao = { situacao: s.situacao, preco: s.preco, id: s.id ?? null, nome: s.nome ?? null, listados: s.listados ?? null };
  }
  rota.totais.padroes = atual.nota.padroes;
  rota.totais.piorCasoComPadroes = rota.totais.piorCaso - atual.nota.padroes;
  rota.esperar = esperar;
  rota.livre = { totais: livre.totais, chegou: livre.chegou };
  const excluida = (r) => semBase.has(minusc(r.nome)) || (so !== null && !so.has(minusc(r.nome)));
  alternativas(rota, receitas, linhas, sit, excluida, precos);
  rota.lucroNpc = listaLucroNpc(receitas, linhas, sit, excluida, precos, ate);
  return rota;
}

const MAX_LUCRO_NPC = 15;

// Receitas que pagam no vendedor (secao 6.5), para a secao "Vendor profit" do J: as que da para fazer (nao "fora"),
// que se aprendem antes do fim da rota e cujo lucro no vendedor, aos precos da rota, passa de -15% do custo (o J
// mostra so as que pagam ao preco de agora). Maior lucro primeiro; no maximo MAX_LUCRO_NPC. Funcao pura.
function listaLucroNpc(receitas, linhas, sit, excluida, precos, ate) {
  const vendedor = new Set((precos.vendedor || []).map(chave));
  const cands = [];
  receitas.receitas.forEach((r, i) => {
    const l = linhas[i];
    if (l.semPreco || l.lucroNpc === null || l.custo === null || excluida(r)) return;
    const s0 = sit.get(r.magia);
    if (!s0 || s0.situacao === 'fora' || l.aprende >= ate) return;
    if (l.lucroNpc <= -0.15 * l.custo) return;
    cands.push({ r, l, s0 });
  });
  cands.sort((a, b) => b.l.lucroNpc - a.l.lucroNpc || a.r.magia - b.r.magia);
  return cands.slice(0, MAX_LUCRO_NPC).map(({ r, l, s0 }) => ({
    magia: r.magia,
    nome: r.nome,
    custo: l.custo,
    vendaNpc: l.vendaNpc,
    lucroNpc: l.lucroNpc,
    limite: l.ate,
    aprende: l.aprende,
    aprendeEstimado: l.aprendeEstimado,
    amarela: r.amarela,
    cinza: r.cinza,
    pontos: r.pontos,
    padrao: { situacao: s0.situacao, preco: s0.preco, id: s0.id ?? null, nome: s0.nome ?? null },
    materiais: reagentesDe(r).map((x) => ({ id: Number(x.id), nome: receitas.itens?.[chave(x.id)]?.nome ?? chave(x.id), qtd: x.qtd })),
    ...dadosVivos(r, l, receitas, vendedor, linhas),
  }));
}

// Segunda melhor receita de cada passo, na mesma faixa (secao 6.3): a de menor perda no pior caso para os
// mesmos pontos, entre as que da para fazer (nao "fora"), que se aprendem ate o comeco do passo, dao ponto em
// toda a faixa e cabem no limite de 25%. Um padrao a comprar entra no custo dela. Grava p.alternativa (ou null).
function alternativas(rota, receitas, linhas, sit, excluida, precos) {
  const vendedor = new Set((precos.vendedor || []).map(chave));
  const usados = new Map(); // magia -> crafts esperados que a rota ja gastou antes do passo (limite de 25%)
  for (const p of rota.passos) {
    let melhor = null;
    receitas.receitas.forEach((r, i) => {
      const l = linhas[i];
      if (r.magia === p.magia || l.semPreco || l.vendaNpc === null || excluida(r)) return;
      const s0 = sit.get(r.magia);
      if (!s0 || s0.situacao === 'fora' || l.aprende > p.de) return;
      let e = 0;
      for (let s = p.de; s < p.ate; s++) {
        const c = chanceEm(r, s);
        if (!(c > 0)) return;
        e += 1 / (c * r.pontos);
      }
      if (l.ate !== null && (usados.get(r.magia) || 0) + e > l.ate) return;
      const padrao = COMPRA.has(s0.situacao) ? s0.preco : 0;
      const k = (l.custo - l.vendaNpc) * e + padrao;
      if (melhor === null || k < melhor.k - TOLERANCIA) melhor = { r, l, e, k, s0 };
    });
    usados.set(p.magia, (usados.get(p.magia) || 0) + p.esperado);
    if (melhor === null) {
      p.alternativa = null;
      continue;
    }
    const { r, l, e, s0 } = melhor;
    p.alternativa = {
      magia: r.magia,
      nome: r.nome,
      esperado: e,
      custo: l.custo,
      vendaNpc: l.vendaNpc,
      piorCaso: (l.vendaNpc - l.custo) * e - (COMPRA.has(s0.situacao) ? s0.preco : 0),
      padrao: { situacao: s0.situacao, preco: s0.preco, id: s0.id ?? null, nome: s0.nome ?? null },
      ...dadosVivos(r, l, receitas, vendedor, linhas),
    };
  }
}

// ---------- roteiro em Lua ----------

// Dinheiro com sinal: "+" quando maior que 0.
const sinal = (v) => (v > 0 ? '+' : '') + moeda(v);

// Texto em Lua: aspas e barras invertidas escapadas.
const escapaLua = (t) => t.replace(/\\/g, '\\\\').replace(/"/g, '\\"');

// Linhas do roteiro para a tabela passos do ProfissoesB.lua. quando e "AAAA-MM-DD HH:MM".
export function textoLua(rota, quando) {
  const out = [];
  const jaVistas = new Set();
  for (const p of rota.passos) {
    const mats = p.materiais.map((m) => `${m.qtd} ${m.nome}`).join(', ');
    const notas = [];
    const pd = p.padrao;
    const repetida = jaVistas.has(p.magia);
    jaVistas.add(p.magia);
    if (!pd) {
      if (p.itemReceita) notas.push('pattern');
    } else if (repetida && (pd.situacao === 'leilao' || pd.situacao === 'vendedor')) {
      notas.push('same pattern as above');
    } else if (pd.situacao === 'conhecida') {
      notas.push('known');
    } else if (pd.situacao === 'leilao') {
      notas.push(`buy the pattern on the AH ${moeda(pd.preco)}`);
    } else if (pd.situacao === 'vendedor') {
      notas.push(`pattern from a vendor ${moeda(pd.preco)}`);
    } else if (pd.situacao === 'treinador') {
      notas.push('trainer');
    }
    notas.push(`worst case ${sinal(p.piorCaso)}`);
    if (p.lucroLeilao !== null) notas.push(`if sold ${sinal(p.seVender)}`);
    const texto = `${p.nome} (${p.crafts}x): ${mats} (${notas.join('; ')})`;
    out.push(`      { de = ${p.de}, ate = ${p.ate}, texto = "${escapaLua(texto)}" },`);
  }
  if (rota.parou) out.push(`      -- stopped at ${rota.parou.pericia}: no recipe gives a point`);
  out.push(`      -- route from the crafts tool (rota.mjs), prices of ${quando}`);
  return out;
}

// ---------- dados da aba Crafts do GuiaForever (secao 6.2) ----------

const luaStr = (s) => `"${escapaLua(String(s))}"`;
const luaNum = (v) => (v === null || v === undefined || !Number.isFinite(v) ? 'nil' : String(Math.round(v)));
// Numero com ate 3 casas (crafts esperados).
const luaDec = (v) => (v === null || v === undefined || !Number.isFinite(v) ? 'nil' : String(Math.round(v * 1000) / 1000));
// Precos por reagente para os numeros vivos do J (secao 6.3).
const luaPrecosMat = (lista) => (lista || [])
  .map((g) => {
    const fab = g.fab ? `, fab = { qtd = ${luaNum(g.fab.qtd)}, mats = { ${luaPrecosMat(g.fab.mats)} } }` : '';
    return `{ id = ${g.id}, nome = ${luaStr(g.nome ?? g.id)}, un = ${g.un}, preco = ${luaNum(g.preco)}, letra = ${g.letra ? `"${g.letra}"` : 'nil'}, vendedor = ${luaNum(g.vendedor)}${fab} }`;
  })
  .join(', ');

// Arquivo RotaCrafts.lua inteiro (texto), a partir do resultado do escolherRota. Funcao pura.
export function dadosAddon(rota, receitas, meta) {
  const prod = new Map(receitas.receitas.map((r) => [r.magia, r.produto?.id ?? null]));
  const L = [];
  L.push('-- GuiaForever: Crafts tab data. Generated by ferramentas/pregao/rota.mjs --addon; do not edit by hand.');
  L.push(`-- Prices of ${meta.quando}. Known recipes: ${meta.conhecidasTxt}.${meta.desconto ? ` Vendor discount: ${meta.desconto}%.` : ''}`);
  L.push('GuiaForeverRotaCrafts = {');
  L.push(`  profissao = "Leatherworking", de = ${rota.de}, ate = ${rota.ate}, chegou = ${rota.chegou},`);
  L.push(`  precos = ${luaStr(meta.quando)}, geradoEm = ${luaNum(meta.agora)}, conhecidasEm = ${luaNum(meta.conhecidasEm)},`);
  const t = rota.totais;
  L.push(`  totais = { crafts = ${t.crafts}, custo = ${luaNum(t.custo)}, piorCaso = ${luaNum(t.piorCaso)}, seVender = ${luaNum(t.seVender)}, padroes = ${luaNum(t.padroes ?? 0)} },`);
  L.push('  passos = {');
  for (const p of rota.passos) {
    const pd = p.padrao || { situacao: p.itemReceita ? 'conhecida' : 'treinador', preco: 0 };
    const padrao = pd.id
      ? `{ id = ${pd.id}, nome = ${luaStr(pd.nome)}, situacao = "${pd.situacao}", preco = ${luaNum(pd.preco)}, listados = ${luaNum(pd.listados)} }`
      : `{ situacao = "${pd.situacao}" }`;
    const mats = p.materiais.map((m) => `{ id = ${m.id}, nome = ${luaStr(m.nome)}, qtd = ${m.qtd} }`).join(', ');
    L.push(`    { de = ${p.de}, ate = ${p.ate}, magia = ${p.magia}, produto = ${luaNum(prod.get(p.magia))}, nome = ${luaStr(p.nome)},`);
    L.push(`      crafts = ${p.crafts}, custo = ${luaNum(p.custo)}, vendaNpc = ${luaNum(p.vendaNpc)}, piorCaso = ${luaNum(p.piorCaso)}, seVender = ${luaNum(p.seVender)},`);
    L.push(`      aprende = ${luaNum(p.aprende)}, aprendeEstimado = ${p.aprendeEstimado ? 'true' : 'false'}, padrao = ${padrao},`);
    L.push(`      esperado = ${luaDec(p.esperado)}, produtoQtd = ${luaNum(p.produtoQtd ?? 1)}, vinculado = ${p.vinculado ? 'true' : 'false'}, precoLeilao = ${luaNum(p.precoLeilao)},`);
    L.push(`      precosMat = { ${luaPrecosMat(p.precosMat)} },`);
    const a = p.alternativa;
    if (a) {
      const ap = a.padrao && a.padrao.id
        ? `{ id = ${a.padrao.id}, nome = ${luaStr(a.padrao.nome)}, situacao = "${a.padrao.situacao}", preco = ${luaNum(a.padrao.preco)} }`
        : `{ situacao = "${a.padrao ? a.padrao.situacao : 'treinador'}" }`;
      L.push(`      alternativa = { magia = ${a.magia}, nome = ${luaStr(a.nome)}, produto = ${luaNum(a.produto)}, produtoQtd = ${luaNum(a.produtoQtd ?? 1)},`);
      L.push(`        vinculado = ${a.vinculado ? 'true' : 'false'}, precoLeilao = ${luaNum(a.precoLeilao)}, esperado = ${luaDec(a.esperado)}, custo = ${luaNum(a.custo)}, vendaNpc = ${luaNum(a.vendaNpc)}, piorCaso = ${luaNum(a.piorCaso)},`);
      L.push(`        padrao = ${ap}, precosMat = { ${luaPrecosMat(a.precosMat)} } },`);
    }
    L.push(`      materiais = { ${mats} } },`);
  }
  L.push('  },');
  L.push('  esperar = {');
  for (const e of rota.esperar || []) {
    const v = e.visto;
    const visto = v ? `{ dia = ${v.dia}, min = ${luaNum(v.min)}, med = ${luaNum(v.med)}, unid = ${luaNum(v.unid)} }` : 'nil';
    L.push(`    { magia = ${e.magia}, nome = ${luaStr(e.nome)}, padrao = ${luaNum(e.padrao.id)}, padraoNome = ${luaStr(e.padrao.nome)}, visto = ${visto} },`);
  }
  L.push('  },');
  // receitas que pagam no vendedor (secao 6.5), para a secao "Vendor profit"; materiais por craft
  L.push('  lucroNpc = {');
  for (const v of rota.lucroNpc || []) {
    const pd = v.padrao && v.padrao.id
      ? `{ id = ${v.padrao.id}, nome = ${luaStr(v.padrao.nome)}, situacao = "${v.padrao.situacao}", preco = ${luaNum(v.padrao.preco)} }`
      : `{ situacao = "${v.padrao ? v.padrao.situacao : 'treinador'}" }`;
    const mats = v.materiais.map((m) => `{ id = ${m.id}, nome = ${luaStr(m.nome)}, qtd = ${m.qtd} }`).join(', ');
    L.push(`    { magia = ${v.magia}, nome = ${luaStr(v.nome)}, produto = ${luaNum(v.produto)}, produtoQtd = ${luaNum(v.produtoQtd ?? 1)}, vinculado = ${v.vinculado ? 'true' : 'false'}, precoLeilao = ${luaNum(v.precoLeilao)},`);
    L.push(`      custo = ${luaNum(v.custo)}, vendaNpc = ${luaNum(v.vendaNpc)}, lucroNpc = ${luaNum(v.lucroNpc)}, limite = ${luaNum(v.limite)}, aprende = ${luaNum(v.aprende)}, aprendeEstimado = ${v.aprendeEstimado ? 'true' : 'false'},`);
    L.push(`      amarela = ${luaNum(v.amarela)}, cinza = ${luaNum(v.cinza)}, pontos = ${luaNum(v.pontos)}, padrao = ${pd},`);
    L.push(`      precosMat = { ${luaPrecosMat(v.precosMat)} },`);
    L.push(`      materiais = { ${mats} } },`);
  }
  L.push('  },');
  if (rota.parou) L.push(`  parou = ${rota.parou.pericia},`);
  L.push('}');
  return L.join('\n') + '\n';
}

// ---------- receitas conhecidas, gravadas pelo GuiaForever (secao 6.1) ----------

// Fim do bloco que abre em texto[ini] ("{"), contando chaves fora de strings.
function fimBloco(texto, ini) {
  let n = 0;
  let str = false;
  for (let i = ini; i < texto.length; i++) {
    const c = texto[i];
    if (str) {
      if (c === '\\') i++;
      else if (c === '"') str = false;
    } else if (c === '"') str = true;
    else if (c === '{') n++;
    else if (c === '}' && --n === 0) return i;
  }
  return -1;
}

// Le o bloco ["receitasLW"] do GuiaForever.lua (SavedVariables). Sem bloco: null. Funcao pura.
export function lerConhecidas(texto) {
  const m = /\["receitasLW"\]\s*=\s*\{/.exec(texto);
  if (!m) return null;
  const ini = m.index + m[0].length - 1;
  const fim = fimBloco(texto, ini);
  if (fim < 0) return null;
  const bloco = texto.slice(ini, fim + 1);
  const num = (k) => {
    const x = new RegExp(`\\["${k}"\\]\\s*=\\s*(\\d+)`).exec(bloco);
    return x ? Number(x[1]) : null;
  };
  const quem = /\["quem"\]\s*=\s*"([^"]*)"/.exec(bloco);
  const mi = /\["ids"\]\s*=\s*\{/.exec(bloco);
  const ids = new Set();
  if (mi) {
    const a = mi.index + mi[0].length - 1;
    const b = fimBloco(bloco, a);
    for (const x of bloco.slice(a, b + 1).matchAll(/\[(\d+)\]\s*=\s*true/g)) ids.add(Number(x[1]));
  }
  return { quem: quem ? quem[1] : null, em: num('em'), pericia: num('pericia'), ids };
}

async function conhecidasDoDisco() {
  try {
    const pasta = await pastaSavedVariables();
    return lerConhecidas(await readFile(path.join(pasta, 'GuiaForever.lua'), 'utf8'));
  } catch (e) {
    if (e.code === 'ENOENT') return null;
    throw e;
  }
}

// ---------- linha de comando ----------

const ASCII = (s) => String(s).replace(/[^\x20-\x7e]/g, '?');
const celula = (s, n) => {
  const t = ASCII(s);
  return (t.length > n ? t.slice(0, n - 2) + '..' : t).padEnd(n);
};
const mo = (v) => moeda(v);

// Hora local HH:MM a partir de epoch em segundos.
function hora(epoch) {
  const d = new Date(epoch * 1000);
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}

// Hora local AAAA-MM-DD HH:MM a partir de epoch em segundos.
function dataHora(epoch) {
  const d = new Date(epoch * 1000);
  const p = (v) => String(v).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

// Idade em "35 min" ou "2 h 05 min".
function idade(seg) {
  const s = Math.max(0, Math.floor(seg));
  const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
  return h ? `${h} h ${String(m).padStart(2, '0')} min` : `${m} min`;
}


// Linha da tabela: oito colunas com largura fixa e a ultima (ultimos dias) sem corte.
const LARGURAS = [7, 22, 6, 7, 14, 14, 14, 8];
const linhaTab = (cols) =>
  (cols.slice(0, LARGURAS.length).map((c, i) => celula(c, LARGURAS[i])).join(' ') + ' ' + cols[LARGURAS.length]).trimEnd();

// Cabecalho com foto publica e exportacao do Auctionator, igual ao crafts.mjs.
function horasTxt(precos, agora) {
  const foto = precos.publico?.foto;
  const fotoTxt = foto ? `foto publica ${hora(foto)} (ha ${idade(agora - foto)})` : 'foto publica sem data';
  let aucTxt = 'Auctionator: sem exportacao';
  if (precos.auctionator) {
    const seg = agora - precos.auctionator.em;
    aucTxt = `Auctionator: exportado ${hora(precos.auctionator.em)} (ha ${idade(seg)})`;
    if (seg > JANELA_AUCTIONATOR) aucTxt += ', velha: nao usada';
  }
  return `${fotoTxt} | ${aucTxt}`;
}

// Reagentes da rota somados por id, do que mais se usa para o que menos.
function agregaMateriais(passos) {
  const m = new Map();
  for (const p of passos) {
    for (const x of p.materiais) {
      const c = m.get(x.id) || { id: x.id, nome: x.nome, qtd: 0 };
      c.qtd += x.qtd;
      m.set(x.id, c);
    }
  }
  return [...m.values()].sort((a, b) => b.qtd - a.qtd || a.id - b.id);
}

// Quebra "312 Thick Leather, 52 Wildvine" em ate 4 linhas de 110 caracteres; o que nao couber vira "e mais N".
function quebrarMateriais(mats) {
  const itens = mats.map((m) => `${m.qtd} ${m.nome}`);
  const txt = (a) => a.join(', ');
  const L = [];
  let atual = [];
  let i = 0;
  for (; i < itens.length; i++) {
    const cand = [...atual, itens[i]];
    if (txt(cand).length <= 110) {
      atual = cand;
      continue;
    }
    if (L.length === 3) break; // a quarta linha e a atual e nao cabe mais nada
    L.push(txt(atual));
    atual = [itens[i]];
  }
  if (i === itens.length) {
    if (atual.length) L.push(txt(atual));
    return L;
  }
  const fim = [...atual];
  let N = itens.length - i;
  while (fim.length && txt(fim).length + `, e mais ${N}`.length > 110) {
    fim.pop();
    N++;
  }
  L.push(fim.length ? `${txt(fim)}, e mais ${N}` : `e mais ${N}`);
  return L;
}

function relatorio(res, precos, agora, nome = 'Leatherworking') {
  const out = [`ROTA - ${nome} - de ${res.de} a ${res.ate}`, horasTxt(precos, agora)];

  out.push(linhaTab(['faixa', 'receita', 'crafts', 'aprende', 'custo/craft', 'pior caso', 'se vender', 'listados', 'ultimos dias']));
  if (res.passos.length === 0) out.push('nenhum passo');
  for (const p of res.passos.slice(0, MAX_PASSOS)) {
    out.push(linhaTab([
      `${p.de}-${p.ate}`,
      p.nome,
      String(p.crafts),
      aprendeTxt(p),
      mo(p.custo),
      mo(p.piorCaso),
      mo(p.seVender),
      String(p.listados ?? '-'),
      p.historico ? p.historico.map((h) => h[3]).join('/') : '-',
    ]));
  }
  if (res.passos.length > MAX_PASSOS) out.push(`mais ${res.passos.length - MAX_PASSOS} passos`);

  if (res.parou) out.push(`parou em ${res.parou.pericia}: nenhuma receita da ponto com os filtros e limites`);

  const t = res.totais;
  out.push(`total: ${t.crafts} crafts | materiais ${mo(t.custo)} | pior caso ${mo(t.piorCaso)} | se tudo vender ${mo(t.seVender)}`);

  const mats = quebrarMateriais(agregaMateriais(res.passos));
  if (mats.length === 0) {
    out.push('materiais: nenhum');
  } else {
    out.push('materiais:');
    out.push(...mats);
  }

  if (res.passos.some((p) => p.padrao)) {
    if (t.padroes) out.push(`padroes a comprar: ${mo(t.padroes)} | pior caso com os padroes ${mo(t.piorCasoComPadroes)}`);
    const vistos = new Set();
    for (const p of res.passos) {
      if (vistos.has(p.magia)) continue;
      vistos.add(p.magia);
      const pd = p.padrao;
      let txt = 'treinador';
      if (pd.situacao === 'conhecida') txt = 'ja conhecida';
      else if (pd.situacao === 'leilao') txt = `comprar o padrao no leilao ${mo(pd.preco)}${pd.listados ? ` (${pd.listados} anunciados)` : ''}`;
      else if (pd.situacao === 'vendedor') txt = `padrao de vendedor ${mo(pd.preco)}`;
      out.push(`  ${p.nome}: ${txt}`);
    }
    for (const e of res.esperar || []) {
      const v = e.visto;
      const vt = v ? `visto em ${String(v.dia).slice(6, 8)}/${String(v.dia).slice(4, 6)} a ${mo(v.min)}, ${v.unid} anuncios` : 'nunca visto no leilao';
      out.push(`esperar no leilao: ${e.padrao.nome} (${vt}); melhoraria a rota`);
    }
    if (res.livre) out.push(`com todos os padroes na mao: pior caso ${mo(res.livre.totais.piorCaso)}`);
  } else {
    const comPadrao = [...new Set(res.passos.filter((p) => p.itemReceita).map((p) => p.nome))];
    out.push(`precisa do padrao: ${comPadrao.length ? comPadrao.join(', ') : 'nenhuma'}`);
  }
  if (res.ate > 225) out.push('acima de 225 pede o Artisan (pericia 200 e nivel 35)');
  out.push('aviso: chance de ponto: formula do Classic, nao conferida no Forever | ~ = pericia de aprender estimada');
  out.push('aviso: limite por receita: 25% do listado de cada reagente; reagente comum a duas receitas nao soma');
  return out;
}

const nomesDe = (v) => v.split(',').map((s) => s.trim());

// Le --de, --ate, --sem, --so e --lua. Devolve { erro } se faltar ou vier errado.
function lerOpcoes(argv) {
  const op = { de: null, ate: null, sem: [], so: null, lua: false, conheco: [], todosPadroes: false, addon: null, desconto: DESCONTO_VENDEDOR, profissao: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--lua') {
      op.lua = true;
    } else if (a === '--todos-padroes') {
      op.todosPadroes = true;
    } else if (a === '--profissao') {
      const p = acharProfissao(argv[++i]);
      if (!p) return { erro: `--profissao pede uma de: ${Object.keys(PROFISSOES).join(', ')}` };
      op.profissao = p;
    } else if (a === '--desconto-vendedor') {
      const d = lerDesconto(argv[++i]);
      if (d.erro) return d;
      op.desconto = d;
    } else if (a === '--conheco') {
      const v = argv[++i];
      if (v === undefined) return { erro: '--conheco pede uma lista de nomes separada por virgula' };
      op.conheco = nomesDe(v);
    } else if (a === '--addon') {
      const v = argv[++i];
      if (v === undefined) return { erro: '--addon pede o caminho do RotaCrafts.lua' };
      op.addon = v;
    } else if (a === '--de' || a === '--ate') {
      const v = argv[++i];
      if (v === undefined || !/^\d+$/.test(v)) return { erro: `${a} pede um numero inteiro` };
      op[a.slice(2)] = Number(v);
    } else if (a === '--sem' || a === '--so') {
      const v = argv[++i];
      if (v === undefined) return { erro: `${a} pede uma lista de nomes separada por virgula` };
      if (a === '--sem') op.sem = nomesDe(v);
      else op.so = nomesDe(v);
    } else {
      return { erro: `argumento desconhecido: ${a}` };
    }
  }
  if (op.de === null) return { erro: 'falta --de' };
  if (op.ate === null) return { erro: 'falta --ate' };
  if (op.de >= op.ate) return { erro: '--de precisa ser menor que --ate' };
  return op;
}

async function lerEntrada(arq, script) {
  try {
    return await lerJson(arq);
  } catch (e) {
    if (e.code === 'ENOENT') {
      console.error(`falta ${arq}: rode antes ${script}`);
      process.exit(2);
    }
    throw e;
  }
}

async function linhaDeComando(argv) {
  const op = lerOpcoes(argv);
  if (op.erro) {
    console.error(`${op.erro}\n${USO}`);
    process.exit(2);
  }
  // Desconto de reputacao no vendedor (secao 6.4): vale para a compra de itens e padroes de vendedor.
  // --profissao (secao 10): o arquivo da profissao; sem ele, o receitas-lw.json da rota do J.
  if (op.profissao && op.addon) {
    console.error('--addon so vale para a rota do J (Leatherworking, sem --profissao)');
    process.exit(2);
  }
  const arq = op.profissao ? arqReceitas(op.profissao.slug) : ARQ_RECEITAS;
  const gerar = op.profissao ? `gerar-receitas.mjs --profissao ${op.profissao.slug}` : 'gerar-receitas.mjs';
  const receitas = comDesconto(await lerEntrada(arq, gerar), op.desconto);
  const precos = await lerEntrada(ARQ_PRECOS, 'baixar-precos.mjs');

  const nomes = new Set(receitas.receitas.map((r) => minusc(r.nome)));
  for (const nome of [...op.sem, ...(op.so || []), ...op.conheco]) {
    if (!nomes.has(minusc(nome))) {
      console.error(`nome de receita nao existe: ${nome}\n${USO}`);
      process.exit(2);
    }
  }

  const agora = Math.floor(Date.now() / 1000);
  // Conhecidas: as que o GuiaForever gravou ao abrir a janela de Leatherworking (so na rota do J), mais as de --conheco.
  const sv = op.todosPadroes || op.profissao ? null : await conhecidasDoDisco();
  const conhecidas = new Set(sv ? sv.ids : []);
  const porNome = new Map(receitas.receitas.map((r) => [minusc(r.nome), r.magia]));
  for (const n of op.conheco) conhecidas.add(porNome.get(minusc(n)));
  const conhecidasTxt = sv
    ? `${sv.ids.size} from the game${sv.em ? ` (${dataHora(sv.em)})` : ''}${op.conheco.length ? ` + ${op.conheco.length} by hand` : ''}`
    : op.conheco.length ? `${op.conheco.length} by hand` : 'none recorded';

  const base = { de: op.de, ate: op.ate, agora, sem: op.sem, so: op.so };
  const res = op.todosPadroes ? calcularRota(receitas, precos, base) : escolherRota(receitas, precos, { ...base, conhecidas });
  const epoch = precos.auctionator ? precos.auctionator.em : precos.publico?.foto;
  const quando = epoch == null ? 'sem data' : dataHora(epoch);

  if (op.addon) {
    if (op.todosPadroes) {
      console.error('--addon nao combina com --todos-padroes');
      process.exit(2);
    }
    const texto = dadosAddon(res, receitas, { quando, agora, conhecidasEm: sv ? sv.em : null, conhecidasTxt, desconto: op.desconto });
    await writeFile(op.addon, texto.split('\n').map(ASCII).join('\n'));
    console.log(`gravado: ${op.addon} (${res.passos.length} passos, conhecidas: ${conhecidasTxt})`);
  } else if (op.lua) {
    console.log(textoLua(res, quando).map(ASCII).join('\n'));
  } else {
    if (!op.todosPadroes) console.log(`conhecidas: ${conhecidasTxt}`);
    console.log(relatorio(res, precos, agora, receitas.profissao?.nome ?? 'Leatherworking').map(ASCII).join('\n'));
    console.log(`desconto de vendedor: ${op.desconto}% na compra${op.desconto ? ' (Darnassus; fora de la, --desconto-vendedor 0)' : ''}`);
  }
}

// So roda a linha de comando quando o arquivo e chamado direto.
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  linhaDeComando(process.argv.slice(2)).catch((e) => {
    console.error(`erro: ${e.message}`);
    process.exit(1);
  });
}
