// Confere dados/pregao/precos.json contra o contrato (secao 4) e o leitor da exportacao do Auctionator.
// Uso: node testes/checar-precos.mjs
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { ARQ_PRECOS, CASA_PUBLICA, lerJson } from '../comum.mjs';

const aqui = path.dirname(fileURLToPath(import.meta.url));
const erros = [];
const exige = (cond, msg) => { if (!cond) erros.push(msg); };

// 1. Leitor da exportacao, contra o arquivo de exemplo.
const { lerExportacao } = await import('../baixar-precos.mjs');
exige(typeof lerExportacao === 'function', 'baixar-precos.mjs nao exporta lerExportacao');
if (typeof lerExportacao === 'function') {
  const ex = lerExportacao(await readFile(path.join(aqui, 'sv-exemplo.lua'), 'utf8'));
  const esperado = { em: 1794850000, itens: { '4234': { preco: 209, idadeDias: 0 }, '5963': { preco: 3900, idadeDias: 2 }, '2321': { preco: 100, idadeDias: 1 }, '8170': { preco: 1900, idadeDias: 3 }, '1206': { preco: 896, idadeDias: 0 } } };
  exige(ex && ex.em === esperado.em, `exemplo em: ${ex && ex.em}`);
  exige(ex && Object.keys(ex.itens).length === 5, `exemplo itens: ${ex && Object.keys(ex.itens).join(',')}`);
  for (const [id, v] of Object.entries(esperado.itens)) exige(ex && ex.itens[id] && ex.itens[id].preco === v.preco && ex.itens[id].idadeDias === v.idadeDias, `exemplo ${id}: ${ex && JSON.stringify(ex.itens[id])}`);
  exige(lerExportacao('GuiaForeverDB = {\n["versao"] = 1,\n}\n') === null, 'sem bloco ah deveria devolver null');
}

// 2. O arquivo gravado.
const p = await lerJson(ARQ_PRECOS);
exige(p.esquema === 1, 'esquema');
const pub = p.publico || {};
exige(pub.casa === CASA_PUBLICA, `casa: ${pub.casa}`);
const idadeFotoH = (Date.now() / 1000 - pub.foto) / 3600;
exige(Number.isInteger(pub.foto) && idadeFotoH >= 0 && idadeFotoH < 6, `foto com ${idadeFotoH.toFixed(1)} h`);
const itens = pub.itens || {};
exige(Object.keys(itens).length >= 6000, `itens publicos: ${Object.keys(itens).length} (esperado 6000 ou mais)`);
const hl = itens['4234'];
exige(hl && hl.tipo === 'c' && hl.min > 0 && hl.p25 >= hl.min && hl.med >= hl.p25 && hl.unid > 1000 && hl.lotes > 10 && Array.isArray(hl.baratos) && hl.baratos.length >= 1 && hl.baratos[0][0] === hl.min && hl.baratos[0][1] > 0, `4234: ${JSON.stringify(hl)}`);
exige(itens['5963'] && itens['5963'].tipo === 'i', `5963: ${JSON.stringify(itens['5963'])}`);
let ruins = 0;
for (const v of Object.values(itens)) if (![v.min, v.p25, v.med, v.unid, v.lotes].every(Number.isInteger) || (v.tipo !== 'c' && v.tipo !== 'i')) ruins++;
exige(ruins === 0, `itens publicos com campo errado: ${ruins}`);
const dias = Object.keys(pub.horas || {});
exige(dias.length >= 3 && dias.every(d => /^\d{8}$/.test(d)) && Object.values(pub.horas).every(h => typeof h === 'number' && h > 0 && h <= 25), `horas: ${JSON.stringify(pub.horas)}`);
const s = (pub.saidas || {})['4234'];
exige(s && Object.keys(s).length >= 3 && Object.values(s).every(Number.isInteger), `saidas 4234: ${JSON.stringify(s)}`);
exige(Object.keys(pub.saidas || {}).length >= 1000, `saidas: ${Object.keys(pub.saidas || {}).length} itens`);
exige(Array.isArray(p.vendedor) && p.vendedor.length === 3734 && p.vendedor.includes(2321) && p.vendedor.includes(4289) && !p.vendedor.includes(1206), `vendedor: ${p.vendedor && p.vendedor.length}`);
if (p.auctionator !== null) {
  const a = p.auctionator;
  exige(a && Number.isInteger(a.em) && a.itens && Object.keys(a.itens).length > 100, 'auctionator presente, mas incompleto');
  const v = a && a.itens && Object.values(a.itens)[0];
  exige(v && Number.isInteger(v.preco) && Number.isInteger(v.idadeDias), `auctionator item: ${JSON.stringify(v)}`);
}

// 3. Historico diario (CONTRATO 4.2). Null quando o download ou a validacao falhou: nao e erro.
exige('historico' in pub, 'historico ausente em publico');
const hist = pub.historico;
if (hist != null) {
  const hd = pub.historicoDias;
  const hdOk = Array.isArray(hd) && hd.length === 2 && hd.every((d) => Number.isInteger(d) && /^\d{8}$/.test(String(d))) && hd[0] <= hd[1];
  exige(hdOk, `historicoDias: ${JSON.stringify(hd)}`);
  const [ini, fim] = hdOk ? hd : [Infinity, -Infinity];
  const nh = Object.keys(hist).length;
  exige(nh >= 5000, `historico: ${nh} itens (esperado 5000 ou mais)`);
  const h4 = hist['4234'];
  exige(Array.isArray(h4) && h4.length >= 3, `historico 4234: ${JSON.stringify(h4)}`);
  const falhas = {};
  const falha = (tipo, id, e) => { falhas[tipo] ??= { n: 0, ex: `${id} ${JSON.stringify(e)}` }; falhas[tipo].n++; };
  for (const [id, lista] of Object.entries(hist)) {
    let anterior = -Infinity;
    for (const e of lista) {
      if (!(Array.isArray(e) && e.length === 4 && e.every(Number.isInteger))) { falha('entrada sem 4 inteiros', id, e); continue; }
      const [d, min, med, unid] = e;
      if (!(/^\d{8}$/.test(String(d)) && d >= ini && d <= fim)) falha('data fora de historicoDias', id, e);
      if (!(min > 0)) falha('min nao maior que 0', id, e);
      if (min > med) falha('min maior que mediana', id, e);
      if (!(unid >= 0)) falha('unidades negativas', id, e);
      if (d <= anterior) falha('dias fora de ordem ou repetidos', id, e);
      anterior = d;
    }
  }
  for (const [tipo, f] of Object.entries(falhas)) erros.push(`historico ${tipo}: ${f.n} (ex.: ${f.ex})`);
}

for (const e of erros) console.log('ERRO', e);
console.log(`publicos=${Object.keys(itens).length} saidas=${Object.keys(pub.saidas || {}).length} vendedor=${p.vendedor ? p.vendedor.length : null} auctionator=${p.auctionator ? Object.keys(p.auctionator.itens).length : 'null'} erros=${erros.length} historico=${hist == null ? 'null' : Object.keys(hist).length}`);
process.exit(erros.length ? 1 : 0);
