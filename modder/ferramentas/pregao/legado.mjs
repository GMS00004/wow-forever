// Custo de levar as seis profissoes de oficio ao 150 (o marco que da Legacy point), comprando todo o material, e
// quanto volta vendendo o que sobrar no vendedor ou no leilao. Contrato em CONTRATO.md, secao 10.
// Uso: node legado.mjs [--ate 150] [--marcos "150"] [--de "Enchanting=37,Alchemy=12"] [--feito "Leatherworking=150"]
//                      [--profissoes "alchemy,tailoring"] [--desconto-vendedor 0] [--tempo-craft 10]
//                      [--relatorio <arquivo.md>] [--sem-faixas]
import { pathToFileURL } from 'node:url';
import { writeFile, mkdir } from 'node:fs/promises';
import path from 'node:path';
import { ARQ_PRECOS, DADOS, lerJson, moeda, arqReceitas, acharProfissao, PROFISSOES } from './comum.mjs';
import { calcular, comDesconto, lerDesconto, aprendeTxt } from './crafts.mjs';
import { escolherRota } from './rota.mjs';
import { carregarNaowh } from './naowh.mjs';

const JANELA_AUCTIONATOR = 21600; // segundos, como no crafts.mjs
const CORTE_LEILAO = 0.95;        // o leilao fica com 5% (inferido do cliente, como no crafts.mjs)
const PROF_MAX = 3;               // niveis de fabricar um reagente (letra F), como no crafts.mjs
const APPRENTICE_CAP = 75;        // teto do Apprentice; o Journeyman vai a 150
const FAIXAS = [50, 75, 100, 125, 150, 175, 200, 250, 275];
// Custo de um craft na escolha da rota e do fabricar (secao 10.3), em cobre. So pesa na escolha; os totais sao so ouro.
export const TEMPO_CRAFT = 10;
const USO = 'uso: node legado.mjs [--ate 150] [--marcos "150"] [--treino-ate 200] [--de "Enchanting=37"] [--feito "Leatherworking=150"] [--profissoes "alchemy,tailoring"] [--desconto-vendedor 0] [--tempo-craft 10] [--relatorio <arq.md>] [--sem-faixas]';

const chave = (id) => String(id);
const reagentesDe = (r) => r.reagentes.filter((g) => Number(g.id) !== 0 && g.qtd > 0);

// ---------- livro de ofertas ----------

// Custo de comprar q unidades no leilao pela foto publica (secao 10.4): os lotes mais baratos da foto e, depois deles,
// o preco sobe em linha reta ate o p25 (25% das unidades) e a mediana (50%); acima disso fica na mediana.
// Devolve { custo, aviso }: aviso 'metade' quando q passa da metade do que esta a venda, 'falta' quando passa do total.
export function custoLivro(pub, q) {
  if (!(q > 0)) return { custo: 0, aviso: null };
  const U = Math.max(0, pub.unid || 0);
  const lotes = (pub.baratos || []).map(([p, n]) => [p, n]).sort((a, b) => a[0] - b[0]);
  let custo = 0;
  let resta = q;
  let acc = 0;
  let ultimo = pub.min;
  for (const [p, n] of lotes) {
    const t = Math.min(n, resta);
    custo += t * p;
    resta -= t;
    acc += n;
    ultimo = p;
    if (resta <= 0) break;
  }
  if (resta > 0) {
    // Curva por pontos (quantidade acumulada, preco), sempre crescente.
    const pts = [[acc, ultimo]];
    let p25 = Math.max(pub.p25 ?? ultimo, ultimo);
    const med = Math.max(pub.med ?? p25, p25);
    if (0.25 * U > acc) pts.push([0.25 * U, p25]);
    else p25 = ultimo;
    if (0.5 * U > Math.max(acc, 0.25 * U)) pts.push([0.5 * U, med]);
    const precoEm = (x) => {
      for (let k = 1; k < pts.length; k++) {
        const [x0, y0] = pts[k - 1], [x1, y1] = pts[k];
        if (x <= x1) return y0 + ((y1 - y0) * (x - x0)) / (x1 - x0);
      }
      return pts[pts.length - 1][1];
    };
    // Integral do preco de acc a acc+resta (trapezios por trecho; depois do ultimo ponto, preco constante).
    let x = acc;
    const fim = acc + resta;
    const quebras = pts.map((p) => p[0]).filter((v) => v > x && v < fim);
    for (const b of [...quebras, fim]) {
      custo += ((precoEm(x) + precoEm(b)) / 2) * (b - x);
      x = b;
    }
  }
  const aviso = U > 0 && q > U ? 'falta' : U > 0 && q > 0.5 * U ? 'metade' : U === 0 ? 'falta' : null;
  return { custo: Math.round(custo), aviso };
}

// ---------- precos e fontes ----------

function precosDe(receitas, precos, agora) {
  const itens = receitas.itens || {};
  const pubItens = precos.publico?.itens || {};
  const vendedor = new Set((precos.vendedor || []).map(chave));
  const auct = precos.auctionator || null;
  const aucFresco = auct !== null && agora - auct.em <= JANELA_AUCTIONATOR;
  // Preco de leilao (min do modo 'min' do crafts.mjs): Auctionator fresco com idade 0, senao o minimo publico.
  const pl = (id) => {
    const k = chave(id);
    const a = aucFresco ? auct.itens?.[k] : null;
    if (a && a.idadeDias === 0 && a.preco != null) return a.preco;
    return pubItens[k] ? pubItens[k].min : null;
  };
  const pv = (id) => {
    const it = itens[chave(id)];
    return vendedor.has(chave(id)) && it && it.compra > 0 ? it.compra : null;
  };
  // Saidas por dia (media nos dias com 23 horas ou mais), como no crafts.mjs.
  const horas = precos.publico?.horas || {};
  const diasCheios = Object.keys(horas).filter((d) => horas[d] >= 23);
  const saiDia = (id) => {
    const s = precos.publico?.saidas?.[chave(id)];
    if (!s || !diasCheios.length) return null;
    return diasCheios.reduce((t, d) => t + (s[d] || 0), 0) / diasCheios.length;
  };
  return { itens, pubItens, pl, pv, saiDia };
}

// ---------- custo com tempo ----------

// Custo de cada item e de cada receita com o tempo (secao 10.3). tempo e o custo de um craft, em cobre: fabricar um
// reagente (letra F) so vence comprar quando a economia paga os crafts a mais. Fonte de um item: L (leilao),
// V (vendedor) ou F (fabricar, ate 3 niveis); vale o menor m + tempo * cpu; no empate, L, V, F. Funcao pura.
// fonte(id) -> { letra, m (cobre por unidade), cpu (crafts por unidade), receita (a que fabrica, na letra F) }.
// porReceita: magia -> { m (cobre por craft), cpu (crafts por craft, contando os reagentes fabricados) } ou null.
// ajuste (opcional): Map id -> preco por unidade no leilao, no lugar do minimo (o preco medio do livro de ofertas para a
// quantidade que a rota anterior comprou; secao 10.4).
// Fabricar so pelas receitas que nao pedem padrao: no esquema 2, as que vem com a profissao e as de treinador pelo
// Naowh (um Tanning Rack fabricado pediria o Blueprint, que a conta nao paga); no esquema 1, todas, como no crafts.mjs.
export const fabricavel = (receitas, r) => receitas.esquema < 2 || r.inicial === true || r.naowh?.origem === 'trainer';

export function custosComTempo(receitas, precos, { agora, tempo, ajuste = null }) {
  const { pl, pv } = precosDe(receitas, precos, agora);
  const porProduto = new Map();
  for (const r of receitas.receitas) {
    if (!r.produto || !fabricavel(receitas, r)) continue;
    const k = chave(r.produto.id);
    if (!porProduto.has(k)) porProduto.set(k, []);
    porProduto.get(k).push(r);
  }
  const memo = new Map();
  const visitando = new Set();
  const total = (x) => x.m + tempo * x.cpu;
  function fonteEm(id, prof) {
    const k = chave(id);
    if (memo.has(k)) return { res: memo.get(k), cortou: false };
    const c = [];
    const L = ajuste && ajuste.has(k) && pl(id) !== null ? ajuste.get(k) : pl(id);
    if (L !== null) c.push({ letra: 'L', m: L, cpu: 0, receita: null });
    const V = pv(id);
    if (V !== null) c.push({ letra: 'V', m: V, cpu: 0, receita: null });
    let cortou = false;
    const receitasDoItem = porProduto.get(k) || [];
    if (receitasDoItem.length) {
      if (prof >= PROF_MAX || visitando.has(k)) cortou = true;
      else {
        visitando.add(k);
        for (const r of receitasDoItem) {
          let m = 0, cpu = 1, ok = true;
          for (const g of reagentesDe(r)) {
            const s = fonteEm(g.id, prof + 1);
            if (s.cortou) cortou = true;
            if (s.res.m === null) { ok = false; break; }
            m += g.qtd * s.res.m;
            cpu += g.qtd * s.res.cpu;
          }
          if (ok) c.push({ letra: 'F', m: m / r.produto.qtd, cpu: cpu / r.produto.qtd, receita: r });
        }
        visitando.delete(k);
      }
    }
    let e = null;
    for (const x of c) if (e === null || total(x) < total(e) - 1e-9) e = x;
    const res = e || { letra: null, m: null, cpu: 0, receita: null };
    if (!cortou) memo.set(k, res);
    return { res, cortou };
  }
  const fonte = (id) => fonteEm(id, 1).res;
  const porReceita = new Map();
  for (const r of receitas.receitas) {
    let m = 0, cpu = 1, ok = true;
    for (const g of reagentesDe(r)) {
      const s = fonte(g.id);
      if (s.m === null) { ok = false; break; }
      m += g.qtd * s.m;
      cpu += g.qtd * s.cpu;
    }
    porReceita.set(r.magia, ok ? { m, cpu } : null);
  }
  return { fonte, porReceita, tempo };
}

// ---------- balanco de uma rota ----------

// Balanco de estoque, compras, ferramentas, padroes, treino e sobras de uma rota ja escolhida. Funcao pura.
// custos e o resultado do custosComTempo (as mesmas fontes que a rota usou para escolher).
export function balanco(receitas, precos, rota, linhas, { agora, custos }) {
  const { itens, pubItens, pl, pv, saiDia } = precosDe(receitas, precos, agora);
  const porMagia = new Map(receitas.receitas.map((r, i) => [r.magia, { r, l: linhas[i] }]));
  const fonte = (id) => custos.fonte(id);
  const tempo = custos.tempo;

  const estoque = new Map();
  const compras = new Map();
  const fabricados = new Map();
  const add = (m, k, q) => m.set(k, (m.get(k) || 0) + q);
  const tirar = (id, q) => {
    const k = chave(id);
    const t = Math.min(estoque.get(k) || 0, q);
    if (t) estoque.set(k, estoque.get(k) - t);
    return q - t;
  };
  // Obtem q unidades: primeiro do estoque, depois pela fonte mais barata. Fabricar abre nos reagentes da receita.
  function obter(id, q, prof = 0, caminho = new Set()) {
    const k = chave(id);
    const resta = tirar(id, q);
    if (resta <= 0) return;
    const f = fonte(id);
    if (f.letra === 'F' && prof < PROF_MAX && !caminho.has(k)) {
      const r = f.receita;
      const n = Math.ceil(resta / r.produto.qtd);
      const c2 = new Set(caminho);
      c2.add(k);
      for (const g of reagentesDe(r)) obter(g.id, g.qtd * n, prof + 1, c2);
      add(fabricados, r.magia, n);
      const sobra = n * r.produto.qtd - resta;
      if (sobra > 0) add(estoque, k, sobra);
      return;
    }
    add(compras, k, resta);
  }

  const ferramentas = [];
  const objetos = [];
  const jaTem = new Set();
  const totalDe = (f) => f.m + tempo * f.cpu;
  let objetoMontado = null;
  for (const p of rota.passos) {
    const { r } = porMagia.get(p.magia);
    // Objeto de acampamento (secao 10.7): o item se gasta ao montar; passos seguidos que pedem o mesmo objeto usam o
    // mesmo, e cada volta a ele depois de outro passo monta um novo.
    if (r.foco?.acampamento) {
      if (objetoMontado !== r.foco.nome) {
        let melhor = null;
        for (const id of r.foco.itens) {
          const f = fonte(id);
          if (f.m !== null && (melhor === null || totalDe(f) < totalDe(melhor.f))) melhor = { id, f };
        }
        if (melhor) {
          obter(melhor.id, 1);
          objetos.push({ nome: r.foco.nome, id: melhor.id, origem: { L: 'leilao', V: 'vendedor', F: 'fabricar' }[melhor.f.letra], preco: Math.round(melhor.f.m), passo: p.nome });
        } else objetos.push({ nome: r.foco.nome, id: null, origem: 'sem preco', preco: null, passo: p.nome });
        objetoMontado = r.foco.nome;
      }
    } else objetoMontado = null;
    for (const fer of r.ferramentas || []) {
      const ch = fer.categoria ? `c${fer.categoria}` : `i${fer.itens.join('-')}`;
      if (jaTem.has(ch)) continue;
      jaTem.add(ch);
      const doEstoque = fer.itens.find((id) => (estoque.get(chave(id)) || 0) > 0);
      if (doEstoque) {
        estoque.set(chave(doEstoque), estoque.get(chave(doEstoque)) - 1);
        ferramentas.push({ nome: fer.nome, id: doEstoque, item: itens[chave(doEstoque)]?.nome ?? chave(doEstoque), origem: 'estoque', preco: 0, passo: p.nome });
        continue;
      }
      let melhor = null;
      for (const id of fer.itens) {
        const f = fonte(id);
        if (f.m !== null && (melhor === null || totalDe(f) < totalDe(melhor.f))) melhor = { id, f };
      }
      if (!melhor) {
        ferramentas.push({ nome: fer.nome, id: null, item: null, origem: 'sem preco', preco: null, passo: p.nome });
        continue;
      }
      obter(melhor.id, 1);
      const origem = { L: 'leilao', V: 'vendedor', F: 'fabricar' }[melhor.f.letra];
      ferramentas.push({ nome: fer.nome, id: melhor.id, item: itens[chave(melhor.id)]?.nome ?? chave(melhor.id), origem, preco: Math.round(melhor.f.m), passo: p.nome });
    }
    for (const g of reagentesDe(r)) obter(g.id, g.qtd * p.crafts);
    if (r.produto) add(estoque, chave(r.produto.id), r.produto.qtd * p.crafts);
  }

  // Compras com preco: vendedor pelo preco dele; leilao pelo livro de ofertas (e, ao lado, pelo minimo).
  const listaCompras = [];
  for (const [k, q] of compras) {
    const f = fonte(k);
    const it = itens[k];
    const pub = pubItens[k] || null;
    const linha = { id: Number(k), nome: it?.nome ?? k, qtd: q, onde: null, custo: null, custoMin: null, aviso: null, listados: pub ? pub.unid : null, saiDia: saiDia(k) };
    if (f.letra === 'V') {
      linha.onde = 'vendedor';
      linha.custo = linha.custoMin = q * pv(k);
    } else if (f.letra === 'L' || f.letra === 'F') {
      // F aqui so quando o limite de niveis cortou o fabricar: compra no leilao se houver preco.
      const L = pl(k);
      if (L === null) {
        linha.onde = 'sem preco';
        linha.aviso = 'sem preco';
      } else {
        linha.onde = 'leilao';
        linha.custoMin = q * L;
        if (pub) {
          const lv = custoLivro(pub, q);
          linha.custo = Math.max(lv.custo, linha.custoMin);
          linha.aviso = lv.aviso;
        } else {
          linha.custo = linha.custoMin;
          linha.aviso = 'sem profundidade';
        }
      }
    } else {
      linha.onde = 'sem preco';
      linha.aviso = 'sem preco';
    }
    listaCompras.push(linha);
  }
  listaCompras.sort((a, b) => (b.custo ?? 0) - (a.custo ?? 0) || a.id - b.id);

  // Sobras: o que ficou no estoque, vendido no vendedor ou no leilao (o melhor por unidade; leilao so sem vinculo).
  const sobras = [];
  for (const [k, q] of estoque) {
    if (!(q > 0)) continue;
    const it = itens[k];
    const vendeUn = it ? it.vende : 0;
    const vinculado = it ? it.vinculo === 1 : false;
    const L = vinculado ? null : pl(k);
    const leilaoUn = L !== null ? Math.round(L * CORTE_LEILAO) : null;
    const melhorUn = leilaoUn !== null && leilaoUn > vendeUn ? leilaoUn : vendeUn;
    sobras.push({
      id: Number(k), nome: it?.nome ?? k, qtd: q, vendedor: q * vendeUn, leilaoUn, melhor: q * melhorUn,
      ondeMelhor: leilaoUn !== null && leilaoUn > vendeUn ? 'leilao' : 'vendedor', vinculado,
      listados: pubItens[k]?.unid ?? null, saiDia: saiDia(k), pilha: it?.pilha ?? 1,
    });
  }
  sobras.sort((a, b) => b.melhor - a.melhor || a.id - b.id);

  // Padroes comprados (cada um uma vez) e treino de receitas pelo Naowh.
  const padroes = new Map();
  const treinoReceitas = [];
  const vistas = new Set();
  let semCustoTreino = 0;
  for (const p of rota.passos) {
    const pd = p.padrao;
    if (pd && (pd.situacao === 'leilao' || pd.situacao === 'vendedor') && pd.id != null && !padroes.has(pd.id)) {
      padroes.set(pd.id, { id: pd.id, nome: pd.nome, onde: pd.situacao, preco: pd.preco, receita: p.nome });
    }
    if (vistas.has(p.magia)) continue;
    vistas.add(p.magia);
    if (pd && pd.situacao === 'treinador') {
      const l = porMagia.get(p.magia).l;
      if (l && typeof l.treino === 'number') treinoReceitas.push({ nome: p.nome, custo: l.treino, aprende: l.aprende });
      else semCustoTreino++;
    }
  }
  const ranks = (receitas.naowh?.ranks || []).slice().sort((a, b) => (a.cap ?? 0) - (b.cap ?? 0));
  const treinoNiveis = [];
  let capAnterior = APPRENTICE_CAP;
  for (const k of ranks) {
    if (k.cap === null) continue;
    if (rota.de <= capAnterior && rota.ate > capAnterior) treinoNiveis.push({ nome: k.nome ?? `ate ${k.cap}`, custo: k.custo, pericia: k.pericia, nivel: k.nivel });
    capAnterior = k.cap;
  }

  const soma = (lista, campo) => lista.reduce((t, x) => t + (x[campo] ?? 0), 0);
  const materiais = soma(listaCompras, 'custo');
  const materiaisMin = soma(listaCompras, 'custoMin');
  const totPadroes = soma([...padroes.values()], 'preco');
  const treino = soma(treinoReceitas, 'custo') + soma(treinoNiveis, 'custo');
  const custoTotal = materiais + totPadroes + treino;
  const vendaVendedor = soma(sobras, 'vendedor');
  const vendaLeilao = soma(sobras, 'melhor');
  return {
    compras: listaCompras,
    ferramentas,
    objetos,
    sobras,
    padroes: [...padroes.values()],
    treinoReceitas,
    treinoNiveis,
    semCustoTreino,
    fabricados: [...fabricados].map(([magia, n]) => ({ magia, nome: porMagia.get(magia)?.r.nome ?? String(magia), crafts: n })),
    totais: {
      crafts: rota.totais.crafts,
      craftsExtra: [...fabricados.values()].reduce((a, b) => a + b, 0),
      materiais, materiaisMin, padroes: totPadroes, treino, custoTotal,
      vendaVendedor, vendaLeilao,
      liquidoVendedor: vendaVendedor - custoTotal,
      liquidoLeilao: vendaLeilao - custoTotal,
      avisos: listaCompras.filter((c) => c.aviso).length,
    },
  };
}

// ---------- uma profissao ----------

// Custo do ponto no legado (secao 10.3): o que se perde no vendedor (lucro nao conta: nao fica abaixo de 0), mais o
// tempo de cada craft, inclusive os reagentes fabricados. Funcao pura.
export function custoPontoLegado(custos) {
  return (r, l, e) => {
    const c = custos.porReceita.get(r.magia);
    if (!c) return Infinity;
    return Math.max(0, c.m - (l.vendaNpc ?? 0)) * e + custos.tempo * c.cpu * e;
  };
}

// Nota de uma rota com balanco: chega mais longe vence; depois, o liquido no vendedor menos o tempo dos crafts.
const notaDe = (x, tempo) => ({ chegou: x.rota.chegou, valor: x.bal.totais.liquidoVendedor - tempo * (x.bal.totais.crafts + x.bal.totais.craftsExtra) });
const melhorQue = (a, b) => a.chegou > b.chegou || (a.chegou === b.chegou && a.valor > b.valor + 1e-9);

// Uma avaliacao com os precos de leilao ajustados (ajuste, ou null para o minimo): rota, balanco e a busca de
// ferramentas (tira as receitas de uma ferramenta se a rota ainda chega e a nota melhora).
function avaliarCom(receitas, precos, linhas, { de, ate, agora, tempo, ajuste, treinoAte = null }) {
  const custos = custosComTempo(receitas, precos, { agora, tempo, ajuste });
  const custoPonto = custoPontoLegado(custos);
  const rodar = (semMagias) => {
    const rota = escolherRota(receitas, precos, { de, ate, agora, sem: [], so: null, conhecidas: new Set(), semMagias, custoPonto });
    return { rota, bal: balanco(receitas, precos, rota, linhas, { agora, custos }), semMagias, custos };
  };
  // Receita que pede objeto de acampamento sem preco em lugar nenhum fica fora desde o comeco.
  const semPrecoObjeto = new Set();
  for (const r of receitas.receitas) {
    if (r.foco?.acampamento && !r.foco.itens.some((id) => custos.fonte(id).m !== null)) semPrecoObjeto.add(r.magia);
    // treinoAte (secao 10.6): receita de treinador que se aprende acima disso fica fora (o Expert do Forever pode nao
    // ensinar acima do 200; o Telonis, de Leatherworking, so ensina ate o 200, visto pelo dono em 2026-11-17).
    if (treinoAte !== null && !r.inicial && r.naowh?.origem === 'trainer' && (r.naowh.aprende ?? 0) > treinoAte) semPrecoObjeto.add(r.magia);
  }
  // Pede a ferramenta ou o objeto de acampamento com esse nome.
  const pede = (r, nome) => (r.ferramentas || []).some((x) => x.nome === nome) || (r.foco?.acampamento && r.foco.nome === nome);
  let atual = rodar(semPrecoObjeto);
  const evitadas = [];
  const tentadas = new Set();
  for (let volta = 0; volta < 6; volta++) {
    const cats = new Map();
    for (const f of [...atual.bal.ferramentas, ...atual.bal.objetos]) if (f.preco) cats.set(f.nome, f);
    let troca = null;
    for (const [nome] of cats) {
      if (tentadas.has(nome)) continue;
      tentadas.add(nome);
      const sem = new Set(atual.semMagias);
      for (const r of receitas.receitas) if (pede(r, nome)) sem.add(r.magia);
      const prova = rodar(sem);
      if (melhorQue(notaDe(prova, tempo), notaDe(troca ? troca.prova : atual, tempo))) troca = { prova, nome };
    }
    if (!troca) break;
    atual = troca.prova;
    evitadas.push(troca.nome);
  }
  return { ...atual, semFerramentas: evitadas };
}

const assinatura = (rota) => rota.passos.map((p) => `${p.magia}x${p.crafts}`).join(',');

// Rota de "de" a "ate" sem padrao na mao (so as receitas iniciais, de treinador e com padrao a venda), com o custo do
// ponto do legado, e o balanco. A rota escolhe pelo preco minimo e a compra anda no livro de ofertas; entao a conta se
// refaz com cada item pelo preco medio da quantidade que a rota anterior comprou, ate a rota repetir (no maximo 4
// vezes), e vale a de melhor nota. tempo: custo de um craft, em cobre. Funcao pura.
export function avaliarProfissao(receitas, precos, { de, ate, agora, tempo = TEMPO_CRAFT, treinoAte = null }) {
  const { linhas } = calcular(receitas, precos, { pericia: de, agora });
  const base = { de, ate, agora, tempo, treinoAte };
  let atual = avaliarCom(receitas, precos, linhas, { ...base, ajuste: null });
  let melhor = atual;
  let voltas = 0;
  let ajuste = new Map();
  const vistas = new Set([assinatura(atual.rota)]);
  for (; voltas < 4; voltas++) {
    ajuste = new Map(ajuste);
    for (const c of atual.bal.compras) {
      if (c.onde === 'leilao' && c.qtd > 0 && c.custo != null) ajuste.set(String(c.id), c.custo / c.qtd);
    }
    const prova = avaliarCom(receitas, precos, linhas, { ...base, ajuste });
    if (melhorQue(notaDe(prova, tempo), notaDe(melhor, tempo))) melhor = prova;
    const s = assinatura(prova.rota);
    atual = prova;
    if (vistas.has(s)) break;
    vistas.add(s);
  }
  return { de, ate, tempo, rota: melhor.rota, bal: melhor.bal, linhas, custos: melhor.custos, semFerramentas: melhor.semFerramentas, voltas: voltas + 1 };
}

// Precos para o legado (secao 10.5): reagente de vendedor so se o vendedor vende sem limite (a lista
// VendorReagents.lua do Naowh: linha, frasco, tinta, sal, fluxo, vareta e madeira); ferramenta e padrao, de que basta
// uma unidade, continuam com a lista publica inteira. Sem a lista do Naowh, vale a lista publica. Funcao pura.
// Livro do full scan do CompraForever (secao 10.9): com ate 6 horas, ele vale no lugar da foto publica para os itens
// que estao nele (minimo, p25, mediana e unidades do livro inteiro, e os niveis mais baratos para o livro de ofertas), e
// a exportacao do Auctionator sai (o full le o leilao inteiro). Item fora do full fica com a foto publica. Funcao pura.
export function comFullCompra(precos, agora) {
  const f = precos.fullCompra;
  if (!f || !f.n || !(agora - f.em <= JANELA_AUCTIONATOR)) return precos;
  const itens = { ...(precos.publico?.itens || {}) };
  for (const [id, x] of Object.entries(f.itens)) {
    const niveis = x.niveis;
    const quantil = (q) => {
      const alvo = q * x.unid;
      let acc = 0;
      for (const [p, n] of niveis) {
        acc += n;
        if (acc >= alvo) return p;
      }
      return niveis[niveis.length - 1][0];
    };
    itens[id] = { tipo: 'f', min: niveis[0][0], p25: quantil(0.25), med: quantil(0.5), unid: x.unid, lotes: x.lotes, baratos: niveis };
  }
  return {
    ...precos,
    publico: { ...precos.publico, itens, foto: f.em, fotoPublica: precos.publico?.foto ?? null },
    auctionator: null,
    fonteLeilao: { tipo: 'full', em: f.em, n: f.n },
  };
}

export function precosParaLegado(precos, receitas, ilimitados) {
  if (!ilimitados) return precos;
  const cheia = new Set(precos.vendedor || []);
  const ok = new Set();
  for (const id of ilimitados) ok.add(id);
  for (const r of receitas.receitas) {
    if (r.itemReceita && cheia.has(r.itemReceita.id)) ok.add(r.itemReceita.id);
    for (const fer of r.ferramentas || []) for (const id of fer.itens) if (cheia.has(id)) ok.add(id);
  }
  return { ...precos, vendedor: [...ok].sort((a, b) => a - b) };
}

// ---------- relatorio ----------

const ASCII = (s) => String(s).replace(/[^\x20-\x7e]/g, '?');
const mo = (v) => (v === null || v === undefined ? '-' : moeda(v));
const sinal = (v) => (v === null || v === undefined ? '-' : (v > 0 ? '+' : '') + moeda(v));
const p2 = (v) => String(v).padStart(2, '0');
function dataHora(epoch) {
  const d = new Date(epoch * 1000);
  return `${d.getFullYear()}-${p2(d.getMonth() + 1)}-${p2(d.getDate())} ${p2(d.getHours())}:${p2(d.getMinutes())}`;
}
const celula = (s, n) => {
  const t = ASCII(s);
  return (t.length > n ? t.slice(0, n - 2) + '..' : t).padEnd(n);
};
const linhaTab = (cols, larg) => cols.map((c, i) => celula(c, larg[i])).join(' ').trimEnd();
const md = (s) => String(s).replace(/\|/g, '/');
const um = (v) => (v === null || v === undefined ? '-' : String(Math.round(v * 10) / 10));

function situacaoTxt(p) {
  const pd = p.padrao;
  if (!pd) return '-';
  if (pd.situacao === 'conhecida') return 'vem com a profissao';
  if (pd.situacao === 'treinador') return p.treino != null ? `treinador (${moeda(p.treino)})` : 'treinador';
  if (pd.situacao === 'leilao') return `padrao no leilao ${moeda(pd.preco)}`;
  if (pd.situacao === 'vendedor') return `padrao no vendedor ${moeda(pd.preco)}`;
  return pd.situacao;
}

function secaoMarkdown(nome, a, faixas, jaFeito, receitas) {
  const { rota, bal } = a;
  const t = bal.totais;
  const focos = new Map(receitas.receitas.filter((r) => r.foco?.acampamento).map((r) => [r.magia, r.foco.nome]));
  const L = [];
  L.push(`## ${nome} (${a.de} a ${a.ate})${jaFeito ? ', ja feito' : ''}`, '');
  if (rota.parou) L.push(`A rota parou em ${rota.parou.pericia}: nenhuma receita da ponto com os filtros e limites. Os numeros abaixo valem ate ${rota.chegou}.`, '');
  L.push(`${t.crafts} crafts na rota${t.craftsExtra ? ` e ${t.craftsExtra} para fabricar reagente` : ''}. Compra total ${mo(t.custoTotal)} (materiais ${mo(t.materiais)} pelo livro de ofertas, ${mo(t.materiaisMin)} se tudo saisse ao minimo; padroes ${mo(t.padroes)}; treino ${mo(t.treino)}). Vendendo o que sobra no vendedor voltam ${mo(t.vendaVendedor)} (liquido ${sinal(t.liquidoVendedor)}); vendendo cada item onde paga mais, com o leilao como teto, voltam ${mo(t.vendaLeilao)} (liquido ${sinal(t.liquidoLeilao)}).`, '');
  if (a.semFerramentas.length) L.push(`A rota evita as receitas que pedem ${a.semFerramentas.join(' e ')}: sem elas o liquido fica melhor.`, '');

  L.push('### Passos', '', '| Faixa | Receita | Crafts | Aprende | Custo por craft | Vendedor por craft | Padrao ou treino |', '|---|---|---|---|---|---|---|');
  for (const p of rota.passos) {
    const c = a.custos.porReceita.get(p.magia);
    const custo = c ? Math.round(c.m) : p.custo;
    const extra = c && c.cpu > 1.0001 ? ` (+${Math.round((c.cpu - 1) * 10) / 10} crafts de reagente)` : '';
    const foco = focos.has(p.magia) ? `; pede ${focos.get(p.magia)}` : '';
    L.push(`| ${p.de}-${p.ate} | ${md(p.nome)} | ${p.crafts} | ${aprendeTxt(p)} | ${mo(custo)}${extra} | ${mo(p.vendaNpc)} | ${md(situacaoTxt(p) + foco)} |`);
  }
  L.push('');

  L.push('### Lista de compras', '', '| Item | Quantidade | Onde | Total | A venda agora | Saidas por dia | Aviso |', '|---|---|---|---|---|---|---|');
  for (const c of bal.compras) {
    const aviso = c.aviso === 'metade' ? 'mais da metade do que esta a venda: comprar em dias diferentes' : c.aviso === 'falta' ? 'mais do que esta a venda agora' : c.aviso ?? '';
    L.push(`| ${md(c.nome)} | ${c.qtd} | ${c.onde} | ${mo(c.custo)} | ${c.listados ?? '-'} | ${um(c.saiDia)} | ${aviso} |`);
  }
  L.push('');

  if (bal.ferramentas.length) {
    L.push('### Ferramentas', '', '| Ferramenta | Item | Como | Preco | Pedida em |', '|---|---|---|---|---|');
    for (const f of bal.ferramentas) L.push(`| ${md(f.nome)} | ${md(f.item ?? '-')} | ${f.origem} | ${mo(f.preco)} | ${md(f.passo)} |`);
    L.push('');
  }
  if (bal.objetos.length) {
    L.push('### Objetos de acampamento (um por montagem, gasto ao montar)', '', '| Objeto | Como | Preco | Montado para |', '|---|---|---|---|');
    for (const o of bal.objetos) L.push(`| ${md(o.nome)} | ${o.origem} | ${mo(o.preco)} | ${md(o.passo)} |`);
    L.push('');
  }
  if (bal.fabricados.length) {
    L.push(`Fabricado fora da rota para servir de reagente: ${bal.fabricados.map((f) => `${f.crafts} ${f.nome}`).join(', ')}.`, '');
  }
  if (bal.padroes.length) {
    L.push(`Padroes a comprar: ${bal.padroes.map((p) => `${p.nome} (${p.onde}, ${moeda(p.preco)})`).join('; ')}.`, '');
  }
  const tr = [...bal.treinoNiveis.map((k) => `${k.nome} ${mo(k.custo)}${k.nivel ? ` (nivel ${k.nivel})` : ''}`), ...bal.treinoReceitas.map((x) => `${x.nome} ${mo(x.custo)}`)];
  if (tr.length) L.push(`Treino: ${tr.join('; ')}${bal.semCustoTreino ? `; ${bal.semCustoTreino} receita(s) de treinador sem custo conhecido` : ''}.`, '');

  L.push('### O que sobra e onde vender', '', '| Item | Quantidade | Vendedor | Leilao por unidade (menos 5%) | Melhor | A venda agora | Saidas por dia |', '|---|---|---|---|---|---|---|');
  for (const s of bal.sobras) {
    L.push(`| ${md(s.nome)} | ${s.qtd} | ${mo(s.vendedor)} | ${s.vinculado ? 'vinculado' : mo(s.leilaoUn)} | ${mo(s.melhor)} (${s.ondeMelhor}) | ${s.listados ?? '-'} | ${um(s.saiDia)} |`);
  }
  if (!bal.sobras.length) L.push('| nada sobra | | | | | | |');
  L.push('');

  if (faixas.length) {
    L.push(`### Comecando de outra pericia (ate ${a.ate})`, '', '| De | Compra total | Liquido no vendedor | Liquido no leilao (teto) |', '|---|---|---|---|');
    for (const f of faixas) L.push(`| ${f.de} | ${mo(f.bal.totais.custoTotal)} | ${sinal(f.bal.totais.liquidoVendedor)} | ${sinal(f.bal.totais.liquidoLeilao)} |`);
    L.push('');
  }
  return L;
}

function avisosFixos(precos) {
  return [
    'Avisos:',
    '',
    '1. Chance de ponto pela formula do Classic (nao conferida no Forever); os crafts sao o numero esperado, nao garantido.',
    '2. Preco do leilao: foto publica da casa us-111 (arquivo de terceiro, RuslanMunasipov/quest-murder-prices); o scan do Auctionator so entra se exportado ha menos de 6 horas.',
    '3. Compra pelo livro de ofertas: os 5 lotes mais baratos da foto e, depois, a curva ate o p25 e a mediana; a foto muda de hora em hora.',
    '4. Leilao como teto: supoe vender tudo ao minimo de hoje menos 5%; o deposito se perde se nao vender, e item de equipamento nao tem numero de saidas.',
    '5. Pericia de aprender e custo de treino pelo Naowh Forever (tabela feita a mao pelo autor a partir da Wowhead Forever); Apprentice fora da conta (o Naowh nao traz o custo). O Journeyman pede nivel 10 do personagem, e o Expert (125 a 225) pede nivel 20.',
    '6. Receita sem item e sem treinador no Naowh fica fora da rota. Reagente de vendedor so da lista do Naowh dos que o vendedor vende sem limite (linha, frasco, tinta, sal, fluxo, vareta, madeira); ferramenta e padrao pela lista publica (QuestieDB); padrao de vendedor so com vendedor da Alianca ou neutro no Naowh.',
    '7. Nada coletado: barra de metal, couro e tecido vem do leilao; intermediario da propria profissao e fabricado quando sai mais barato, so por receita que vem com a profissao ou de treinador.',
    '8. Objeto de acampamento (Tanning Rack, Spinning Wheel, Fermenter, Anarchist\'s Workbench) pelo cliente (SpellCastingRequirements): um item do leilao por montagem; Anvil e Forge, as cidades tem. Quanto tempo um objeto montado dura nao esta no cliente.',
    `9. Fontes: foto publica de ${precos.publico?.foto ? dataHora(precos.publico.foto) : 'sem data'}; tabelas do cliente do build em uso pela ferramenta.`,
  ];
}

// ---------- linha de comando ----------

function lerOpcoes(argv) {
  const op = { ate: 150, de: {}, profissoes: Object.keys(PROFISSOES), desconto: 0, relatorio: null, faixas: true, tempo: TEMPO_CRAFT, treinoAte: null, marcos: [], feito: { leatherworking: 150 } };
  const pares = (v, nome) => {
    const out = {};
    for (const par of v.split(',')) {
      const [n, x] = par.split('=').map((s) => s.trim());
      const p = acharProfissao(n);
      if (!p || !/^\d+$/.test(x || '')) return { erro: `${nome}: par invalido ${par}` };
      out[p.slug] = Number(x);
    }
    return out;
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--ate') {
      const v = argv[++i];
      if (!/^\d+$/.test(v || '')) return { erro: '--ate pede um inteiro' };
      op.ate = Number(v);
    } else if (a === '--de' || a === '--feito') {
      const v = argv[++i];
      if (!v) return { erro: `${a} pede "Profissao=N,..."` };
      const p = pares(v, a);
      if (p.erro) return p;
      if (a === '--de') op.de = p;
      else op.feito = p;
    } else if (a === '--marcos') {
      const v = argv[++i];
      if (!/^\d+(,\d+)*$/.test(v || '')) return { erro: '--marcos pede pericias separadas por virgula, como "150"' };
      op.marcos = v.split(',').map(Number).sort((x, y) => x - y);
    } else if (a === '--profissoes') {
      const v = argv[++i];
      const lista = (v || '').split(',').map((s) => acharProfissao(s));
      if (!v || lista.some((p) => !p)) return { erro: `--profissoes pede nomes de: ${Object.keys(PROFISSOES).join(', ')}` };
      op.profissoes = lista.map((p) => p.slug);
    } else if (a === '--desconto-vendedor') {
      const d = lerDesconto(argv[++i]);
      if (d.erro) return d;
      op.desconto = d;
    } else if (a === '--relatorio') {
      op.relatorio = argv[++i];
      if (!op.relatorio) return { erro: '--relatorio pede um caminho' };
    } else if (a === '--tempo-craft') {
      const v = argv[++i];
      if (!/^\d+$/.test(v || '')) return { erro: '--tempo-craft pede um inteiro (cobre por craft)' };
      op.tempo = Number(v);
    } else if (a === '--treino-ate') {
      const v = argv[++i];
      if (!/^\d+$/.test(v || '')) return { erro: '--treino-ate pede uma pericia (inteiro)' };
      op.treinoAte = Number(v);
    } else if (a === '--sem-faixas') {
      op.faixas = false;
    } else return { erro: `argumento desconhecido: ${a}` };
  }
  return op;
}

const CAMPOS = ['custoTotal', 'vendaVendedor', 'liquidoVendedor', 'vendaLeilao', 'liquidoLeilao'];
const somaTotais = (lista) => {
  const t = { crafts: 0 };
  for (const c of CAMPOS) t[c] = 0;
  for (const x of lista) {
    t.crafts += x.crafts + x.craftsExtra;
    for (const c of CAMPOS) t[c] += x[c];
  }
  return t;
};

async function linhaDeComando(argv) {
  const op = lerOpcoes(argv);
  if (op.erro) {
    console.error(`${op.erro}\n${USO}`);
    process.exit(2);
  }
  const agora = Math.floor(Date.now() / 1000);
  // Full scan do CompraForever com ate 6 horas: vale no lugar da foto publica (secao 10.9).
  const precosBase = comFullCompra(await lerJson(ARQ_PRECOS), agora);
  const naowh = await carregarNaowh();
  const ilimitados = naowh?.reagentesIlimitados ?? null;
  const precos = precosBase;
  const resultados = [];
  for (const slug of op.profissoes) {
    let receitas;
    try {
      receitas = comDesconto(await lerJson(arqReceitas(slug)), op.desconto);
    } catch (e) {
      if (e.code === 'ENOENT') {
        console.error(`falta ${arqReceitas(slug)}: rode antes node gerar-receitas.mjs --profissao todas`);
        process.exit(2);
      }
      throw e;
    }
    const de = op.de[slug] ?? 1;
    if (de >= op.ate) continue;
    const pr = precosParaLegado(precosBase, receitas, ilimitados);
    // Trechos entre os marcos (secao 10.6): de 1 ao primeiro marco, de um marco ao seguinte e do ultimo ao --ate.
    const pontos = [de, ...op.marcos.filter((m) => m > de && m < op.ate), op.ate];
    const segs = [];
    for (let i = 0; i + 1 < pontos.length; i++) {
      const a = avaliarProfissao(receitas, pr, { de: pontos[i], ate: pontos[i + 1], agora, tempo: op.tempo, treinoAte: op.treinoAte });
      const faixas = op.faixas
        ? FAIXAS.filter((f) => f > pontos[i] && f < pontos[i + 1]).map((f) => avaliarProfissao(receitas, pr, { de: f, ate: pontos[i + 1], agora, tempo: op.tempo, treinoAte: op.treinoAte }))
        : [];
      segs.push({ a, faixas, feito: op.feito[slug] != null && pontos[i + 1] <= op.feito[slug] });
    }
    const total = somaTotais(segs.map((s) => s.a.bal.totais));
    resultados.push({ slug, nome: PROFISSOES[slug].nome, segs, total, receitas, build: receitas.build, naowh: receitas.naowh?.versao ?? null });
  }
  resultados.sort((x, y) => y.total.liquidoVendedor - x.total.liquidoVendedor);

  const faixaTxt = (s) => `${s.a.de}-${s.a.rota.chegou}`;
  const linhaSeg = (r, s) => {
    const t = s.a.bal.totais;
    return [r.nome + (s.feito ? ' *' : ''), faixaTxt(s), String(t.crafts + t.craftsExtra), mo(t.custoTotal), mo(t.vendaVendedor), sinal(t.liquidoVendedor), mo(t.vendaLeilao), sinal(t.liquidoLeilao)];
  };
  const linhaTotal = (nome, faixa, t) => [nome, faixa, String(t.crafts), mo(t.custoTotal), mo(t.vendaVendedor), sinal(t.liquidoVendedor), mo(t.vendaLeilao), sinal(t.liquidoLeilao)];
  const todos = somaTotais(resultados.flatMap((r) => r.segs.map((s) => s.a.bal.totais)));
  const pendentes = somaTotais(resultados.flatMap((r) => r.segs.filter((s) => !s.feito).map((s) => s.a.bal.totais)));
  const temFeito = resultados.some((r) => r.segs.some((s) => s.feito));

  // Resumo no terminal.
  const larg = [17, 8, 7, 13, 13, 13, 13, 13];
  const out = [`LEGADO - custo ate ${op.ate}${op.marcos.length ? ` (marcos ${op.marcos.join(', ')})` : ''}, comprando tudo | ${precos.fonteLeilao?.tipo === 'full' ? 'full do CompraForever' : 'foto publica'} ${precos.publico?.foto ? dataHora(precos.publico.foto) : 'sem data'} | desconto de vendedor ${op.desconto}% | tempo ${op.tempo}c por craft${op.treinoAte !== null ? ` | treinador so ate ${op.treinoAte}` : ''}`];
  out.push(linhaTab(['profissao', 'faixa', 'crafts', 'compra', 'volta vend.', 'liq. vend.', 'teto leilao', 'liq. leilao'], larg));
  for (const r of resultados) {
    for (const s of r.segs) out.push(linhaTab(linhaSeg(r, s), larg));
    if (r.segs.length > 1) out.push(linhaTab(linhaTotal(`  ${r.nome} total`, `${r.segs[0].a.de}-${r.segs[r.segs.length - 1].a.rota.chegou}`, r.total), larg));
  }
  out.push(linhaTab(linhaTotal('TODAS', '', todos), larg));
  if (temFeito) out.push(linhaTab(linhaTotal('SEM O JA FEITO', '', pendentes), larg));
  if (temFeito) out.push(`* ja feito (--feito ${Object.entries(op.feito).map(([k, v]) => `${PROFISSOES[k]?.nome ?? k}=${v}`).join(',')})`);
  const paradas = resultados.flatMap((r) => r.segs.filter((s) => s.a.rota.parou).map((s) => `${r.nome} em ${s.a.rota.parou.pericia}`));
  if (paradas.length) out.push(`parou: ${paradas.join(', ')}`);

  // Relatorio em Markdown.
  const quando = precos.publico?.foto ? dataHora(precos.publico.foto) : 'sem data';
  const fonteTxt = precos.fonteLeilao?.tipo === 'full'
    ? `o full scan do CompraForever de ${quando} (${precos.fonteLeilao.n} itens; o que nao estava nele, pela foto publica us-111 de ${precos.publico.fotoPublica ? dataHora(precos.publico.fotoPublica) : 'sem data'})`
    : `a foto publica do leilao us-111 de ${quando}${precos.auctionator && agora - precos.auctionator.em <= JANELA_AUCTIONATOR ? ` e o scan do Auctionator exportado em ${dataHora(precos.auctionator.em)}` : ''}`;
  const L = [
    `# Custo do ${op.ate} nas profissoes de oficio (Legacy point)`,
    '',
    `Gerado em ${dataHora(agora)} pelo legado.mjs, com ${fonteTxt}, build ${resultados[0]?.build ?? '-'} e Naowh ${resultados[0]?.naowh ?? 'nao'}. Desconto de vendedor ${op.desconto}%. Na escolha da rota e do fabricar, cada craft vale ${op.tempo}c de tempo (so na escolha; os totais sao so ouro). Nada coletado: tudo comprado.${op.treinoAte !== null ? ` Receita de treinador so ate a pericia ${op.treinoAte}.` : ''}${op.marcos.length ? ` Cada trecho entre marcos (${op.marcos.join(', ')}) e uma conta propria, partindo do marco anterior.` : ''}`,
    '',
    '| Profissao | Faixa | Crafts | Compra total | Volta no vendedor | Liquido no vendedor | Teto no leilao | Liquido no leilao |',
    '|---|---|---|---|---|---|---|---|',
  ];
  const md8 = (c) => `| ${c.join(' | ')} |`;
  for (const r of resultados) {
    for (const s of r.segs) {
      const c = linhaSeg(r, s);
      c[0] = r.nome + (s.feito ? ' (ja feito)' : '');
      L.push(md8(c));
    }
    if (r.segs.length > 1) L.push(md8(linhaTotal(`${r.nome}, total`, `${r.segs[0].a.de}-${r.segs[r.segs.length - 1].a.rota.chegou}`, r.total)));
  }
  L.push(md8(linhaTotal('Todas', '', todos)));
  if (temFeito) L.push(md8(linhaTotal('Todas, sem o ja feito', '', pendentes)));
  L.push('');
  for (const r of resultados) for (const s of r.segs) L.push(...secaoMarkdown(r.nome, s.a, s.faixas, s.feito, r.receitas));
  L.push(...avisosFixos(precos), '');

  const arq = op.relatorio || path.join(DADOS, 'relatorios', `legado-${op.ate}-${dataHora(agora).replace(/[: ]/g, '').replace(/^(\d{4})-(\d{2})-(\d{2})(\d{4})$/, '$1-$2-$3-$4')}.md`);
  await mkdir(path.dirname(arq), { recursive: true });
  await writeFile(arq, L.join('\n'));
  out.push(`relatorio: ${arq}`);
  console.log(out.map(ASCII).join('\n'));
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  linhaDeComando(process.argv.slice(2)).catch((e) => {
    console.error(`erro: ${e.stack || e.message}`);
    process.exit(1);
  });
}
