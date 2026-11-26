// Casos de preco fixo do legado.mjs e dos campos do esquema 2 (CONTRATO.md, secao 10). Uso: node testes/testar-legado.mjs
import { custoLivro, livro, custosComTempo, balanco, avaliarProfissao, precosParaLegado, comFullCompra, creditarIntermediarios, avaliarTrechos, exportarRota } from '../legado.mjs';
import { lerFullCompra } from '../baixar-precos.mjs';
import { calcular } from '../crafts.mjs';
import { situacaoPadroes } from '../rota.mjs';
import { lerTabelaLua, naowhDaProfissao, lerVendorReagents } from '../naowh.mjs';

// Os casos usam dados de exemplo da casa us-111 (Alianca Normal): fixa a casa e a faccao para o resultado
// nao depender do jogador ativo de quem roda (comum.mjs, casaPublica() e faccao()).
process.env.WOW_CASA = 'us-111';
process.env.WOW_FACCAO = 'Alliance';

const erros = [];
let campos = 0;
const igual = (nome, real, esperado) => {
  campos++;
  if (JSON.stringify(real) !== JSON.stringify(esperado)) erros.push(`${nome}: ${JSON.stringify(real)} (esperado ${JSON.stringify(esperado)})`);
};

// ---------- L1: livro de ofertas ----------
{
  const pub = { min: 10, p25: 20, med: 30, unid: 100, baratos: [[10, 5], [12, 5]] };
  igual('L1 3 un', custoLivro(pub, 3), { custo: 30, aviso: null });
  igual('L1 10 un', custoLivro(pub, 10), { custo: 110, aviso: null });
  igual('L1 25 un', custoLivro(pub, 25), { custo: 350, aviso: null });   // 110 + (12+20)/2*15
  igual('L1 50 un', custoLivro(pub, 50), { custo: 975, aviso: null });   // 350 + (20+30)/2*25
  igual('L1 60 un', custoLivro(pub, 60), { custo: 1275, aviso: 'metade' });
  igual('L1 120 un', custoLivro(pub, 120), { custo: 3075, aviso: 'falta' });
  igual('L1 0 un', custoLivro(pub, 0), { custo: 0, aviso: null });
}

// ---------- caso base do esquema 2 ----------
const receitas = {
  esquema: 2,
  profissao: { id: 1, nome: 'Teste', slug: 'teste' },
  naowh: { versao: 't', ranks: [{ cap: 150, pericia: 50, custo: 500, nivel: null, nome: 'Journeyman Teste' }] },
  receitas: [
    { magia: 101, nome: 'Rolo', produto: { id: 3, qtd: 1 }, reagentes: [{ id: 1, qtd: 2 }], amarela: 10, cinza: 20, pontos: 1, itemReceita: null, inicial: true },
    { magia: 102, nome: 'Bolsa', produto: { id: 4, qtd: 1 }, reagentes: [{ id: 3, qtd: 2 }, { id: 2, qtd: 1 }], amarela: 30, cinza: 60, pontos: 1, itemReceita: null, inicial: false,
      naowh: { aprende: 10, origem: 'trainer', custo: 50, lados: [] }, ferramentas: [{ categoria: 9, nome: 'Vara', itens: [5] }] },
    { magia: 103, nome: 'Encanto', produto: null, reagentes: [{ id: 6, qtd: 1 }], amarela: 40, cinza: 80, pontos: 1, itemReceita: null, inicial: false, encantamento: true,
      naowh: { aprende: 20, origem: 'trainer', custo: 100, lados: [] } },
    { magia: 104, nome: 'Quest', produto: { id: 7, qtd: 1 }, reagentes: [{ id: 1, qtd: 1 }], amarela: 5, cinza: 15, pontos: 1, itemReceita: null, inicial: false,
      naowh: { aprende: 1, origem: 'quest', custo: null, lados: [] } },
    { magia: 105, nome: 'Horda', produto: { id: 8, qtd: 1 }, reagentes: [{ id: 1, qtd: 1 }], amarela: 5, cinza: 15, pontos: 1, inicial: false,
      itemReceita: { id: 9, nome: 'Pattern: Horda', periciaExigida: 1, compra: 300 }, naowh: { aprende: 1, origem: 'vendor', custo: null, lados: ['H'] } },
  ],
  itens: {
    1: { nome: 'Pano', vende: 2, compra: 0, pilha: 20, vinculo: 0, qualidade: 1 },
    2: { nome: 'Linha', vende: 1, compra: 5, pilha: 20, vinculo: 0, qualidade: 1 },
    3: { nome: 'Rolo', vende: 15, compra: 0, pilha: 20, vinculo: 0, qualidade: 1 },
    4: { nome: 'Bolsa', vende: 50, compra: 0, pilha: 1, vinculo: 0, qualidade: 1 },
    5: { nome: 'Vara', vende: 10, compra: 100, pilha: 1, vinculo: 0, qualidade: 1 },
    6: { nome: 'Po', vende: 1, compra: 0, pilha: 20, vinculo: 0, qualidade: 1 },
    7: { nome: 'Coisa', vende: 1, compra: 0, pilha: 20, vinculo: 0, qualidade: 1 },
    8: { nome: 'Coisa H', vende: 1, compra: 0, pilha: 20, vinculo: 0, qualidade: 1 },
  },
};
const pub = (min, unid = 5000) => ({ tipo: 'c', min, p25: min, med: min, unid, lotes: 10, baratos: [[min, unid]] });
const precos = {
  publico: { foto: 1000, itens: { 1: pub(10), 4: pub(80, 20), 6: pub(7), 3: pub(25) }, saidas: {}, horas: {} },
  auctionator: null,
  vendedor: [2, 5, 9],
};
const agora = 2000;

// ---------- C1: crafts.mjs com o esquema 2 ----------
{
  const { linhas } = calcular(receitas, precos, { pericia: 1, agora });
  const [a, b, c] = linhas;
  igual('C1 inicial aprende', [a.aprende, a.aprendeFonte, a.aprendeEstimado], [1, 'inicial', false]);
  igual('C1 naowh aprende e treino', [b.aprende, b.aprendeFonte, b.treino], [10, 'naowh', 50]);
  igual('C1 encantamento venda e leilao', [c.vendaNpc, c.precoLeilao, c.lucroLeilao, c.produtoId, c.qtd], [0, null, null, null, 0]);
  igual('C1 encantamento custo', c.custo, 7);
}

// ---------- S1: situacao dos padroes ----------
{
  const sit = situacaoPadroes(receitas, precos, { agora, conhecidas: new Set() });
  igual('S1 inicial', sit.get(101).situacao, 'conhecida');
  igual('S1 treinador pelo Naowh', sit.get(102).situacao, 'treinador');
  igual('S1 quest sem item fica fora', sit.get(104).situacao, 'fora');
  igual('S1 padrao so de vendedor da Horda', sit.get(105).situacao, 'fora');
}

// ---------- T1: fabricar ou comprar, com o tempo ----------
{
  const c0 = custosComTempo(receitas, precos, { agora, tempo: 0 });
  igual('T1 tempo 0 fabrica o Rolo', [c0.fonte(3).letra, c0.fonte(3).m], ['F', 20]);
  const c10 = custosComTempo(receitas, precos, { agora, tempo: 10 });
  igual('T1 tempo 10 compra o Rolo', [c10.fonte(3).letra, c10.fonte(3).m], ['L', 25]);
  igual('T1 receita da Bolsa com tempo 0', c0.porReceita.get(102), { m: 45, cpu: 3 });
  const aj = custosComTempo(receitas, precos, { agora, tempo: 0, ajuste: new Map([['1', 20]]) });
  igual('T1 ajuste do preco do Pano', aj.fonte(1).m, 20);
}

// ---------- B1: balanco de uma rota fixa ----------
{
  const { linhas } = calcular(receitas, precos, { pericia: 1, agora });
  const custos = custosComTempo(receitas, precos, { agora, tempo: 0 });
  const rota = {
    de: 1, ate: 100, chegou: 100, parou: null,
    passos: [
      { magia: 101, nome: 'Rolo', crafts: 4, padrao: { situacao: 'conhecida', preco: 0 } },
      { magia: 102, nome: 'Bolsa', crafts: 2, padrao: { situacao: 'treinador', preco: 0 } },
      { magia: 103, nome: 'Encanto', crafts: 3, padrao: { situacao: 'treinador', preco: 0 } },
    ],
    totais: { crafts: 9 },
  };
  const b = balanco(receitas, precos, rota, linhas, { agora, custos });
  const compras = Object.fromEntries(b.compras.map((c) => [c.nome, [c.qtd, c.onde, c.custo]]));
  igual('B1 compras', compras, { Vara: [1, 'vendedor', 100], Pano: [8, 'leilao', 80], Po: [3, 'leilao', 21], Linha: [2, 'vendedor', 10] });
  igual('B1 ferramenta', b.ferramentas.map((f) => [f.nome, f.origem, f.preco]), [['Vara', 'vendedor', 100]]);
  igual('B1 sobras', b.sobras.map((s) => [s.nome, s.qtd, s.vendedor, s.melhor, s.ondeMelhor]), [['Bolsa', 2, 100, 152, 'leilao']]);
  igual('B1 treino', [b.totais.treino, b.treinoNiveis.map((k) => k.custo), b.treinoReceitas.map((x) => x.custo)], [650, [500], [50, 100]]);
  igual('B1 totais', [b.totais.materiais, b.totais.custoTotal, b.totais.vendaVendedor, b.totais.liquidoVendedor, b.totais.vendaLeilao, b.totais.liquidoLeilao],
    [211, 861, 100, -761, 152, -709]);
}

// ---------- A1: avaliacao de ponta a ponta ----------
{
  const a = avaliarProfissao(receitas, precos, { de: 1, ate: 40, agora, tempo: 0 });
  igual('A1 chega ao fim', [a.rota.chegou, a.rota.parou], [40, null]);
  igual('A1 nenhuma receita fora entrou', a.rota.passos.some((p) => p.magia === 104 || p.magia === 105), false);
  igual('A1 liquido = venda - compra', a.bal.totais.liquidoVendedor, a.bal.totais.vendaVendedor - a.bal.totais.custoTotal);
}

// ---------- N1: leitor do Naowh ----------
{
  const t = lerTabelaLua('{ [7] = { skillSpell = 1, recipes = { { spell = 5, skill = 10, source = "trainer", cost = 25, vendors = { { 1, "Npc", "AH", 1, 2.5, 3 } } }, -- nota\n { spell = 6, yellow = 1 } }, ranks = { { cap = 150, skill = 50, cost = 500, name = "J" } } } }').valor;
  const p = naowhDaProfissao(t, 7);
  igual('N1 receita', p.receitas.get(5), { aprende: 10, origem: 'trainer', custo: 25, padrao: null, produto: null, amarela: null, cinza: null, lados: ['AH'] });
  igual('N1 ranks', p.ranks, [{ cap: 150, pericia: 50, custo: 500, nivel: null, nome: 'J' }]);
  igual('N1 vendor reagents', [...lerVendorReagents('x.VendorReagents = {\n [2320] = true, [3371] = true,\n}')], [2320, 3371]);
}

// ---------- V1: lista de vendedor do legado ----------
{
  const pr = precosParaLegado({ ...precos, vendedor: [2, 5, 9, 1] }, receitas, new Set([2]));
  igual('V1 so linha, ferramenta e padrao', pr.vendedor, [2, 5, 9]);
  igual('V1 sem lista do Naowh', precosParaLegado(precos, receitas, null).vendedor, [2, 5, 9]);
}

// ---------- F1: livro do full scan do CompraForever ----------
{
  const sv = 'CompraForeverDB = {\n["ultimoFull"] = 100,\n["full"] = {\n["em"] = 1000,\n["n"] = 2,\n["itens"] = {\n[2589] = "54;2;9:14,11:40",\n[7000] = "2;2;300:1,1500:1",\n},\n},\n}\n';
  const f = lerFullCompra(sv);
  igual('F1 leitura', [f.em, f.n, f.itens['2589'], f.itens['7000'].niveis], [1000, 2, { unid: 54, lotes: 2, niveis: [[9, 14], [11, 40]] }, [[300, 1], [1500, 1]]]);
  igual('F1 sem bloco', lerFullCompra('CompraForeverDB = {\n["ultimoFull"] = 100,\n}\n'), null);
  const base = { publico: { foto: 900, itens: { 2589: pub(20), 1: pub(10) } }, auctionator: { em: 990, itens: {} }, fullCompra: f };
  const m = comFullCompra(base, 2000);
  igual('F1 full no lugar da foto', [m.publico.itens['2589'].min, m.publico.itens['2589'].p25, m.publico.itens['2589'].med, m.publico.itens['2589'].unid], [9, 9, 11, 54]);
  igual('F1 item fora do full fica com a foto', m.publico.itens['1'].min, 10);
  igual('F1 Auctionator sai e a fonte fica marcada', [m.auctionator, m.fonteLeilao, m.publico.foto, m.publico.fotoPublica], [null, { tipo: 'full', em: 1000, n: 2 }, 1000, 900]);
  igual('F1 livro pelos niveis do full', custoLivro(m.publico.itens['2589'], 20).custo, 9 * 14 + 11 * 6);
  igual('F1 full velho nao entra', comFullCompra(base, 1000 + 21601), base);
}

// ---------- L2: preco da ultima unidade (livro().ultimo) ----------
{
  // Mesmo livro do L1: lotes [10 x5] e [12 x5], U=100, p25=20, mediana=30. Curva depois dos lotes (acc=10, ultimo=12):
  // pontos (10,12), (25,20), (50,30); acima de 50 fica em 30.
  const pub = { min: 10, p25: 20, med: 30, unid: 100, baratos: [[10, 5], [12, 5]] };
  const u = (q) => livro(pub, q).ultimo;
  const r4 = (v) => Math.round(v * 1e4) / 1e4;
  igual('L2 dentro do primeiro lote', u(3), 10);
  igual('L2 fim do primeiro lote', u(5), 10);
  igual('L2 dentro do segundo lote', u(7), 12);
  igual('L2 fim do segundo lote', u(10), 12);
  igual('L2 na curva, a meio do trecho', r4(u(15)), r4(12 + (8 * 5) / 15)); // 12 + (20-12) * (15-10)/(25-10)
  igual('L2 na curva, no p25', u(25), 20);
  igual('L2 na curva, na mediana', u(50), 30);
  igual('L2 alem do total fica na mediana', u(120), 30);
  igual('L2 sem compra', livro(pub, 0), { custo: 0, aviso: null, ultimo: null });
  igual('L2 custoLivro sem o campo ultimo', Object.keys(custoLivro(pub, 25)), ['custo', 'aviso']);
  igual('L2 custo igual ao do L1', livro(pub, 25).custo, 350);
}

// ---------- B2: intermediario fabricado so quando ja se aprende no passo; treino uma vez ----------
const rB = {
  esquema: 2,
  profissao: { id: 2, nome: 'Teste2', slug: 'teste2' },
  naowh: { versao: 't', ranks: [{ cap: 150, pericia: 50, custo: 500, nivel: null, nome: 'J' }, { cap: 225, pericia: 125, custo: 5000, nivel: 22, nome: 'E' }, { cap: 300, pericia: 200, custo: 50000, nivel: null, nome: 'A' }] },
  receitas: [
    { magia: 201, nome: 'Po Fino', produto: { id: 30, qtd: 1 }, reagentes: [{ id: 1, qtd: 1 }], amarela: 100, cinza: 140, pontos: 1, itemReceita: null, inicial: false,
      naowh: { aprende: 125, origem: 'trainer', custo: 500, lados: [] }, ferramentas: [{ categoria: 7, nome: 'Pinca', itens: [5] }] },
    { magia: 202, nome: 'Bomba', produto: { id: 31, qtd: 1 }, reagentes: [{ id: 30, qtd: 2 }], amarela: 100, cinza: 140, pontos: 1, itemReceita: null, inicial: true },
  ],
  itens: {
    1: { nome: 'Pano', vende: 2, compra: 0, pilha: 20, vinculo: 0 },
    5: { nome: 'Pinca', vende: 10, compra: 100, pilha: 1, vinculo: 0 },
    30: { nome: 'Po Fino', vende: 5, compra: 0, pilha: 20, vinculo: 0 },
    31: { nome: 'Bomba', vende: 9, compra: 0, pilha: 20, vinculo: 0 },
  },
};
const precosB = { publico: { foto: 1000, itens: { 1: pub(10), 30: pub(500, 50) }, saidas: {}, horas: {} }, auctionator: null, vendedor: [5] };
const passoB = (de, ate, crafts) => ({ magia: 202, nome: 'Bomba', de, ate, crafts, padrao: { situacao: 'conhecida', preco: 0 } });
const rotaB = (passos) => ({ de: passos[0].de, ate: passos[passos.length - 1].ate, chegou: passos[passos.length - 1].ate, parou: null, passos, totais: { crafts: passos.reduce((t, x) => t + x.crafts, 0) } });
{
  const { linhas } = calcular(rB, precosB, { pericia: 1, agora });
  const custos = custosComTempo(rB, precosB, { agora, tempo: 0 });
  igual('B2 a conta pede fabricar o Po Fino', custos.fonte(30).letra, 'F');
  // De 100: o Po Fino (aprende 125) nao se fabrica, e comprado: 10 unidades, teto = max(ultimo, minimo) = 500.
  const a = balanco(rB, precosB, rotaB([passoB(100, 110, 5)]), linhas, { agora, custos });
  igual('B2 comprado antes do aprender', [a.compras.map((c) => [c.id, c.qtd, c.onde, c.teto]), a.fabricados, a.treinoReceitas, a.totais.treino],
    [[[30, 10, 'leilao', 500]], [], [], 0]);
  igual('B2 fonte comprada', a.fontes, { 30: { f: 'L', qtd: 10, custo: 5000, teto: 500 } });
  // De 130: fabrica; o treino do Po Fino entra uma vez (dois passos), a Pinca e obtida, o Pano e comprado.
  const b = balanco(rB, precosB, rotaB([passoB(130, 135, 5), passoB(135, 140, 5)]), linhas, { agora, custos });
  igual('B2 treino uma vez, fabricado', b.treinoReceitas, [{ nome: 'Po Fino', custo: 500, aprende: 125, magia: 201, fabricado: true }]);
  igual('B2 treino no total', [b.totais.treino, b.totais.craftsExtra], [500, 20]);
  igual('B2 ferramenta obtida', b.ferramentas.map((f) => [f.nome, f.origem, f.preco]), [['Pinca', 'vendedor', 100]]);
  igual('B2 compras', b.compras.map((c) => [c.id, c.qtd, c.onde, c.teto ?? null, c.preco ?? null]).sort((x, y) => x[0] - y[0]), [[1, 20, 'leilao', 10, null], [5, 1, 'vendedor', null, 100]]);
  igual('B2 fontes', b.fontes, { 1: { f: 'L', qtd: 20, custo: 200, teto: 10 }, 5: { f: 'V', qtd: 1, preco: 100 }, 30: { f: 'F', magia: 201, qtd: 20, teto: 500 } });
}

// ---------- C2: credito dos intermediarios (o caso C1 acima e do crafts.mjs) ----------
{
  const R = (extra302) => ({
    esquema: 2, profissao: { id: 3, nome: 'Teste3', slug: 'teste3' }, naowh: { versao: 't', ranks: [] },
    receitas: [
      { magia: 301, nome: 'Bombinha', produto: { id: 20, qtd: 1 }, reagentes: [{ id: 40, qtd: 2 }], amarela: 10, cinza: 40, pontos: 1, itemReceita: null, inicial: true },
      { magia: 302, nome: 'Po', produto: { id: 40, qtd: 1 }, reagentes: [{ id: 1, qtd: 1 }], amarela: 10, cinza: 40, pontos: 1, itemReceita: null, inicial: true, ...extra302 },
    ],
    itens: { 1: { nome: 'Pano', vende: 2, compra: 0, pilha: 20, vinculo: 0 }, 20: { nome: 'Bombinha', vende: 9, compra: 0, pilha: 20, vinculo: 0 }, 40: { nome: 'Po', vende: 1, compra: 0, pilha: 20, vinculo: 0 } },
  });
  const pr = { publico: { foto: 1000, itens: { 1: pub(10), 40: pub(1000) }, saidas: {}, horas: {} }, auctionator: null, vendedor: [] };
  // Chance de 301 e 302 em x: (40 - x) / 30 (amarela 10, cinza 40). Cada Bombinha pede 2 Po, e cada Po fabricado vale um
  // craft da mesma chance: ganho = 3 * chance; sem o credito, ganho = chance.
  let semC = 0, comC = 0;
  for (let x = 10; x < 30; x++) { const ch = (40 - x) / 30; semC += 1 / ch; comC += 1 / (3 * ch); }
  const mk = (de, ate, crafts) => ({ de, ate, chegou: ate, parou: null, passos: [{ magia: 301, nome: 'Bombinha', de, ate, crafts, esperado: semC }], totais: { crafts } });
  const rec = R({});
  const custos = custosComTempo(rec, pr, { agora, tempo: 0 });
  igual('C2 o Po e fabricado', custos.fonte(40).letra, 'F');
  const rota = mk(10, 30, Math.ceil(semC - 1e-9));
  const c = creditarIntermediarios(rec, rota, custos);
  igual('C2 crafts com credito = ceil(soma de 1/(3 chance))', [c.passos[0].crafts, c.totais.crafts], [Math.ceil(comC - 1e-9), Math.ceil(comC - 1e-9)]);
  igual('C2 esperado com credito', Math.round(c.passos[0].esperado * 1e6), Math.round(comC * 1e6));
  igual('C2 a rota original nao muda', [rota.passos[0].crafts, rota.totais.crafts], [Math.ceil(semC - 1e-9), Math.ceil(semC - 1e-9)]);
  igual('C2 o credito reduz os crafts', c.passos[0].crafts < rota.passos[0].crafts, true);
  // Receita F que so se aprende em 20, com o passo comecando em 10: sem credito (a conta de antes).
  const tardia = R({ inicial: false, naowh: { aprende: 20, origem: 'trainer', custo: 50, lados: [] } });
  const ct = custosComTempo(tardia, pr, { agora, tempo: 0 });
  igual('C2 F ainda nao aprendida nao da credito', creditarIntermediarios(tardia, rota, ct).passos[0].crafts, Math.ceil(semC - 1e-9));
  // Ganho zero (passo alem do cinza): o passo fica como estava.
  const quebrada = mk(35, 45, 7);
  igual('C2 ganho zero mantem o passo', creditarIntermediarios(rec, quebrada, custos).passos[0].crafts, 7);
}

// ---------- X1: exportacao da rota para o CompraForever ----------
{
  const { linhas } = calcular(rB, precosB, { pericia: 1, agora });
  const custos = custosComTempo(rB, precosB, { agora, tempo: 0 });
  const rota = rotaB([passoB(130, 135, 5), passoB(135, 140, 5)]);
  const bal = balanco(rB, precosB, rota, linhas, { agora, custos });
  const { prof, itens } = exportarRota('tailoring', rB, [{ a: { de: 130, ate: 140, rota, bal }, faixas: [] }]);
  igual('X1 chaves da profissao', Object.keys(prof), ['nome', 'curto', 'linha', 'ranks', 'receitas', 'trechos']);
  igual('X1 nome, curto e linha', [prof.nome, prof.curto, prof.linha], ['Teste2', 'Tail', 2]);
  igual('X1 nivel do rank: o do Naowh ou pelo teto', prof.ranks.map((k) => [k.cap, k.nivel]), [[150, 10], [225, 22], [300, 35]]);
  igual('X1 receitas: passos e F', Object.keys(prof.receitas), ['201', '202']);
  igual('X1 receita F de treinador', prof.receitas[201], {
    nome: 'Po Fino', produto: 30, qtd: 1, reagentes: [[1, 1]], amarela: 100, cinza: 140, pontos: 1, aprende: 125, origem: 'treinador', treino: 500,
    ferramentas: [{ nome: 'Pinca', itens: [5] }], foco: null, acampamento: null,
  });
  igual('X1 receita inicial', [prof.receitas[202].origem, prof.receitas[202].treino, prof.receitas[202].reagentes], ['inicial', null, [[30, 2]]]);
  const t = prof.trechos[0];
  igual('X1 trecho', [Object.keys(t), t.de, t.ate, t.chegou], [['de', 'ate', 'chegou', 'passos', 'fontes', 'totais'], 130, 140, 140]);
  igual('X1 passos seguidos', [t.passos, t.passos[0].ate === t.passos[1].de], [[{ magia: 202, de: 130, ate: 135, crafts: 5 }, { magia: 202, de: 135, ate: 140, crafts: 5 }], true]);
  igual('X1 letras das fontes', Object.fromEntries(Object.entries(t.fontes).map(([k, f]) => [k, f.f])), { 1: 'L', 5: 'V', 30: 'F' });
  igual('X1 totais', t.totais, { custo: bal.totais.custoTotal, crafts: 10, craftsExtra: 20 });
  igual('X1 itens citados', Object.keys(itens), ['1', '5', '30', '31']);
  igual('X1 item', itens[5], { nome: 'Pinca', vende: 10, pilha: 1, vinculo: 0 });
  const segs = avaliarTrechos(receitas, precos, { de: 1, ate: 40, marcos: [20, 99], agora, tempo: 0, faixas: false });
  igual('X1 avaliarTrechos parte nos marcos', segs.map((x) => [x.a.de, x.a.ate, x.faixas.length]), [[1, 20, 0], [20, 40, 0]]);
}

for (const e of erros) console.log('ERRO', e);
console.log(`casos=13 campos=${campos} erros=${erros.length}`);
process.exit(erros.length ? 1 : 0);
