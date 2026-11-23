// Casos de preco fixo do legado.mjs e dos campos do esquema 2 (CONTRATO.md, secao 10). Uso: node testes/testar-legado.mjs
import { custoLivro, custosComTempo, balanco, avaliarProfissao, precosParaLegado, comFullCompra } from '../legado.mjs';
import { lerFullCompra } from '../baixar-precos.mjs';
import { calcular } from '../crafts.mjs';
import { situacaoPadroes } from '../rota.mjs';
import { lerTabelaLua, naowhDaProfissao, lerVendorReagents } from '../naowh.mjs';

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

for (const e of erros) console.log('ERRO', e);
console.log(`casos=9 campos=${campos} erros=${erros.length}`);
process.exit(erros.length ? 1 : 0);
