// Casos dos padroes da rota (CONTRATO.md, secoes 6.1 e 6.2). Uso: node testes/testar-padroes.mjs (a partir de ferramentas/pregao)
// Usa as receitas e precos fixos de caso-base.json: a Belt (magia 2) e a unica receita com padrao (item 900);
// Leggings (magia 1) e de treinador. O caso R4 de caso-rota.json mostra que, so com Leggings e Belt de 170 a 177,
// a Leggings esgota o limite no 176 e so a Belt leva ao 177.
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const aqui = path.dirname(fileURLToPath(import.meta.url));
const mod = await import('../rota.mjs');
const base = JSON.parse(await readFile(path.join(aqui, 'caso-base.json'), 'utf8'));
const rotaCasos = JSON.parse(await readFile(path.join(aqui, 'caso-rota.json'), 'utf8'));
const agora = rotaCasos.agora;

let erros = 0, conferidos = 0;
const confere = (rotulo, veio, esperado) => {
  conferidos++;
  const ok = JSON.stringify(veio === undefined ? null : veio) === JSON.stringify(esperado);
  if (!ok) { erros++; console.log(`${rotulo}: esperado ${JSON.stringify(esperado)}, veio ${JSON.stringify(veio)}`); }
};

for (const f of ['situacaoPadroes', 'escolherRota', 'lerConhecidas', 'dadosAddon']) {
  if (typeof mod[f] !== 'function') { erros++; console.log(`rota.mjs nao exporta ${f}`); }
}

const precosCom = (mudar) => {
  const p = JSON.parse(JSON.stringify({ ...base.precos, auctionator: null }));
  mudar(p);
  return p;
};
const sit = (precos, conhecidas) => mod.situacaoPadroes(base.receitas, precos, { agora, conhecidas });
const opc = { de: 170, ate: 177, agora, sem: [], so: ['Leggings', 'Belt'] };

if (erros === 0) {
  // 1. situacao de cada receita
  const fora = sit(precosCom(() => {}), new Set());
  confere('[S1] Belt sem anuncio nem vendedor', fora.get(2).situacao, 'fora');
  confere('[S1] Belt visto', fora.get(2).visto, null);
  confere('[S1] Leggings sem item', fora.get(1).situacao, 'treinador');
  confere('[S2] Belt conhecida', sit(precosCom(() => {}), new Set([2])).get(2).situacao, 'conhecida');
  const noLeilao = sit(precosCom((p) => { p.publico.itens['900'] = { tipo: 'i', min: 300, p25: 300, med: 350, unid: 3, lotes: 3, baratos: [[300, 1]] }; }), new Set()).get(2);
  confere('[S3] Belt no leilao', [noLeilao.situacao, noLeilao.preco, noLeilao.listados], ['leilao', 300, 3]);
  const noVendedor = sit(precosCom((p) => { p.vendedor = [...p.vendedor, 900]; }), new Set()).get(2);
  confere('[S4] Belt de vendedor', [noVendedor.situacao, noVendedor.preco], ['vendedor', 500]);
  const comHist = sit(precosCom((p) => { p.publico.historico = { 900: [[20261114, 250, 260, 2], [20261115, 280, 300, 4]] }; }), new Set()).get(2);
  confere('[S5] Belt fora com historico', comHist.visto, { dia: 20261115, min: 280, med: 300, unid: 4 });

  // 2. escolha da rota
  const r1 = mod.escolherRota(base.receitas, precosCom(() => {}), { ...opc, conhecidas: new Set() });
  confere('[E1] sem o padrao, para no 176', r1.chegou, 176);
  confere('[E1] so Leggings', [...new Set(r1.passos.map((p) => p.nome))], ['Leggings']);
  confere('[E1] Belt vale esperar', r1.esperar.map((e) => [e.nome, e.padrao.id]), [['Belt', 900]]);
  confere('[E1] padroes', r1.totais.padroes, 0);

  const r2 = mod.escolherRota(base.receitas, precosCom(() => {}), { ...opc, conhecidas: new Set([2]) });
  const ref = mod.calcularRota(base.receitas, precosCom(() => {}), { de: 170, ate: 177, agora, sem: [], so: opc.so });
  confere('[E2] conhecida: igual a calcularRota', [r2.chegou, r2.totais.piorCaso, r2.passos.length], [ref.chegou, ref.totais.piorCaso, ref.passos.length]);
  confere('[E2] nada a esperar', r2.esperar.length, 0);
  confere('[E2] situacao no passo da Belt', r2.passos.find((p) => p.nome === 'Belt').padrao.situacao, 'conhecida');

  const precosLeilao = precosCom((p) => { p.publico.itens['900'] = { tipo: 'i', min: 300, p25: 300, med: 350, unid: 3, lotes: 3, baratos: [[300, 1]] }; });
  const r3 = mod.escolherRota(base.receitas, precosLeilao, { ...opc, conhecidas: new Set() });
  confere('[E3] comprando o padrao chega ao 177', r3.chegou, 177);
  confere('[E3] preco do padrao uma vez', r3.totais.padroes, 300);
  confere('[E3] pior caso com padroes', r3.totais.piorCasoComPadroes, r3.totais.piorCaso - 300);

  // 3. textoLua e dadosAddon com a situacao do padrao
  const lua = mod.textoLua(r3, '2026-11-16 21:13');
  confere('[L1] nota de compra no leilao', lua.some((l) => l.includes('buy the pattern on the AH 3s 00c')), true);
  const dados = mod.dadosAddon(r3, base.receitas, { quando: '2026-11-16 21:13', agora, conhecidasEm: null, conhecidasTxt: 'none recorded' });
  confere('[D1] tabela global', dados.includes('GuiaForeverRotaCrafts = {'), true);
  confere('[D1] padrao no leilao', dados.includes('{ id = 900, nome = "Pattern: Belt", situacao = "leilao", preco = 300, listados = 3 }'), true);
  confere('[D1] produto da Belt', dados.includes('magia = 2, produto = 201,'), true);
  let n = 0;
  for (const c of dados) { if (c === '{') n++; else if (c === '}') n--; if (n < 0) break; }
  confere('[D1] chaves fechadas', n, 0);

  // 3b. numeros vivos do J (secao 6.3): precos por reagente, produto e alternativa por passo
  const leg = r3.passos.find((p) => p.nome === 'Leggings');
  const belt = r3.passos.find((p) => p.nome === 'Belt');
  confere('[V1] precosMat da Leggings', leg.precosMat, [
    { id: 100, nome: 'Leather', un: 10, preco: 200, letra: 'L', vendedor: 600 },
    { id: 101, nome: 'Thread', un: 2, preco: 100, letra: 'V', vendedor: 100 },
    { id: 102, nome: 'Gem', un: 1, preco: 900, letra: 'L', vendedor: null },
  ]);
  confere('[V1] produto e leilao da Leggings', [leg.produto, leg.produtoQtd, leg.vinculado, leg.precoLeilao], [200, 1, false, 3900]);
  confere('[V2] alternativa da Leggings: Belt com o padrao no custo',
    [leg.alternativa.nome, Math.round(leg.alternativa.esperado * 1000) / 1000, Math.round(leg.alternativa.piorCaso), leg.alternativa.padrao.preco],
    ['Belt', 6.924, -11724, 300]);
  confere('[V3] Belt sem alternativa: a Leggings ja gastou o limite de 25%', belt.alternativa, null);
  // 3c. desconto de reputacao no vendedor (secao 6.4)
  const { comDesconto, lerDesconto } = await import('../crafts.mjs');
  const rd = comDesconto(base.receitas, 10);
  confere('[R1] compra com 10% e venda igual', [rd.itens['101'].compra, rd.itens['101'].vende, rd.itens['105'].compra], [90, 25, 45]);
  confere('[R1] padrao de vendedor com 10%', rd.receitas.find((r) => r.magia === 2).itemReceita.compra, Math.round(base.receitas.receitas.find((r) => r.magia === 2).itemReceita.compra * 0.9));
  confere('[R1] original intacto e 0 sem copia', [base.receitas.itens['101'].compra, comDesconto(base.receitas, 0) === base.receitas], [100, true]);
  confere('[R2] desconto invalido', [lerDesconto('100').erro !== undefined, lerDesconto('x').erro !== undefined, lerDesconto('10')], [true, true, 10]);
  const leg10 = mod.escolherRota(rd, precosLeilao, { ...opc, conhecidas: new Set() }).passos.find((p) => p.nome === 'Leggings');
  confere('[R3] Thread do vendedor a 90 na Leggings', leg10.precosMat.find((g) => g.id === 101), { id: 101, nome: 'Thread', un: 2, preco: 90, letra: 'V', vendedor: 90 });

  confere('[V4] Lua com esperado, precosMat e alternativa',
    [dados.includes('esperado = 9.785, produtoQtd = 1, vinculado = false, precoLeilao = 3900,'),
     dados.includes('{ id = 101, nome = "Thread", un = 2, preco = 100, letra = "V", vendedor = 100 }'),
     dados.includes('alternativa = { magia = 2, nome = "Belt", produto = 201,')],
    [true, true, true]);

  // 3d. fabricar um reagente (letra F): a receita que o faz vai junto, um nivel (secao 6.3)
  const precosHide = precosCom((p) => {
    p.publico.itens['900'] = { tipo: 'i', min: 300, p25: 300, med: 350, unid: 3, lotes: 3, baratos: [[300, 1]] };
    p.publico.itens['104'] = { ...p.publico.itens['104'], min: 100, p25: 100 };
  });
  const beltF = mod.escolherRota(base.receitas, precosHide, { ...opc, conhecidas: new Set([2]) }).passos.find((p) => p.nome === 'Belt');
  const hide = beltF.precosMat.find((g) => g.id === 103);
  confere('[V5] Cured Hide fabricada: letra, preco e receita', [hide.letra, hide.preco, hide.fab && hide.fab.qtd, hide.fab && hide.fab.mats.map((m) => [m.id, m.un, m.letra])],
    ['F', 250, 1, [[104, 1, 'L'], [105, 3, 'V']]]);

  // 3e. receitas que pagam no vendedor (secao 6.5)
  const ln = r3.lucroNpc || [];
  confere('[N1] lista existe, ate 15, maior lucro primeiro',
    [Array.isArray(r3.lucroNpc), ln.length <= 15, ln.every((v, i) => i === 0 || ln[i - 1].lucroNpc >= v.lucroNpc)], [true, true, true]);
  confere('[N1] so receitas que da para fazer e acima de -15% do custo',
    ln.every((v) => v.padrao.situacao !== 'fora' && v.lucroNpc > -0.15 * v.custo && v.aprende < 177), true);
  confere('[N2] Lua com a secao lucroNpc', dados.includes('  lucroNpc = {'), true);

  // 4. receitas gravadas pelo GuiaForever (SavedVariables)
  const sv = [
    'GuiaForeverDB = {',
    '["personagens"] = {',
    '["Outro-Reino"] = { ["nivel"] = 10, },',
    '["Hexumlite-Reino"] = {',
    '["receitasLW"] = {',
    '["quem"] = "Hexumlite",',
    '["em"] = 1794880000,',
    '["pericia"] = 186,',
    '["ids"] = {',
    '[2149] = true,',
    '[9208] = true,',
    '},',
    '["n"] = 2,',
    '},',
    '},',
    '},',
    '}',
  ].join('\n');
  const k = mod.lerConhecidas(sv);
  confere('[C1] conhecidas', k && [k.quem, k.em, k.pericia, [...k.ids].sort((a, b) => a - b)], ['Hexumlite', 1794880000, 186, [2149, 9208]]);
  confere('[C2] sem bloco', mod.lerConhecidas('GuiaForeverDB = { ["ah"] = { } }'), null);
}

console.log(`casos=4 campos=${conferidos} erros=${erros}`);
process.exit(erros ? 1 : 0);
