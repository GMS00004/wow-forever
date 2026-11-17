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
