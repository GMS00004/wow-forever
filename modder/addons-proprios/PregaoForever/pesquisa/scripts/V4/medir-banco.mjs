// Gera um PregaoForeverDB no formato da secao 6 do design (SINTESE.v1) com os volumes
// da tabela, mede o tamanho real em dois estilos de gravacao, a contagem de constantes,
// a memoria estimada em Lua 5.1 (64 bits), o tempo do luaparse e o ganho de Deflate.
// Uso: node medir-banco.mjs
import fs from 'node:fs';
import zlib from 'node:zlib';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const luaparse = require('C:/GMS/Claude Code Projects/wow/modder/ferramentas/guia/node_modules/luaparse');

const DADOS = '<dados>/';
const OUT = '<tmp>/V4-desempenho/';

// ---------- CSV ----------
function lerCSV(caminho) {
  const txt = fs.readFileSync(caminho, 'utf8');
  const linhas = []; let campo = ''; let linha = []; let aspas = false;
  for (let i = 0; i < txt.length; i++) {
    const c = txt[i];
    if (aspas) {
      if (c === '"') { if (txt[i + 1] === '"') { campo += '"'; i++; } else aspas = false; }
      else campo += c;
    } else if (c === '"') aspas = true;
    else if (c === ',') { linha.push(campo); campo = ''; }
    else if (c === '\n') { linha.push(campo); linhas.push(linha); linha = []; campo = ''; }
    else if (c !== '\r') campo += c;
  }
  if (campo.length || linha.length) { linha.push(campo); linhas.push(linha); }
  const cab = linhas.shift();
  return linhas.filter(l => l.length === cab.length).map(l => Object.fromEntries(cab.map((h, j) => [h, l[j]])));
}

// ---------- PRNG com semente ----------
let s = 20261116;
const rnd = () => { s = (s * 1103515245 + 12345) & 0x7fffffff; return s / 0x7fffffff; };
const gauss = () => Math.sqrt(-2 * Math.log(rnd() + 1e-12)) * Math.cos(2 * Math.PI * rnd());
const logn = (mediana, sd) => Math.exp(Math.log(mediana) + sd * gauss());
const int = x => Math.max(1, Math.round(x));
const escolhe = a => a[Math.floor(rnd() * a.length)];

// ---------- Itens do cliente ----------
const sparse = lerCSV(DADOS + 'ItemSparse.csv');
const itemTab = lerCSV(DADOS + 'Item.csv');
const classe = new Map(itemTab.map(r => [r.ID, r.ClassID]));
const qCol = Object.keys(sparse[0]).find(k => /OverallQuality/i.test(k));
const itens = sparse.map(r => ({ id: +r.ID, sell: +r.SellPrice, stack: +r.Stackable, q: +(r[qCol] || 0), cls: +(classe.get(r.ID) || 0), ilvl: +(r.ItemLevel || 0) }));
const comVenda = itens.filter(i => i.sell > 0);
const maxId = Math.max(...itens.map(i => i.id));

// ---------- Dados.lua (secao 13) ----------
function gerarDados() {
  const lin = ['local _, ns = ...', 'ns.dados = {'];
  for (const i of comVenda) lin.push(`[${i.id}]="${i.sell}:${i.stack}:${i.q}:${i.cls}",`);
  lin.push('}');
  const txt = lin.join('\n') + '\n';
  const consts = new Set(); for (const i of comVenda) { consts.add('n' + i.id); consts.add(`s${i.sell}:${i.stack}:${i.q}:${i.cls}`); }
  // alternativa: so o preco de vendedor, numerico
  const alt = ['local _, ns = ...', 'ns.vend = {'];
  for (const i of comVenda) alt.push(`[${i.id}]=${i.sell},`);
  alt.push('}');
  const txtAlt = alt.join('\n') + '\n';
  const constsAlt = new Set(); for (const i of comVenda) { constsAlt.add('n' + i.id); constsAlt.add('n' + i.sell); }
  return { txt, consts: consts.size, txtAlt, constsAlt: constsAlt.size };
}

// ---------- Chaves de mercado ----------
function chaveDe(i) { return (i.stack > 1) ? String(i.id) : `${i.id}:${i.ilvl}:0`; }
function minPreco(i) { return i.sell > 0 ? int(i.sell * logn(4, 1.0)) : int(logn(3000, 1.5)); }
function qtd(i) { return i.stack > 1 ? int(logn(300, 1.3)) : int(logn(3, 0.9)); }

// ---------- Banco ----------
function gerarBanco(fase, opts = {}) {
  const N_RESUMO = opts.nResumo || 8000, N_DIAS = 1500, DIAS = 14;
  const N_FOCO = 40, FOTOS = fase === 1 ? 16 : 48;
  const t0 = 1794700000; // ~2026-11
  const amostra = [...itens].sort(() => rnd() - 0.5).slice(0, N_RESUMO);
  const db = { esquema: 1, seq: 0, recibo: 0, calib: {}, itens: {}, resumo: {}, dias: {}, fotos: {}, sinais: [], pers: {}, sessoes: [], sonda: {}, log: [], fim: 0 };
  // resumo: uma string
  const partes = amostra.map(i => `${chaveDe(i)}=${minPreco(i)}:${qtd(i)}`);
  db.resumo = { t: t0, completa: true, n: N_RESUMO, dados: partes.join(';') };
  // dias
  const dia0 = Math.floor(t0 / 86400);
  for (const i of amostra.slice(0, N_DIAS)) {
    const reg = []; for (let d = 0; d < DIAS; d++) reg.push(`${dia0 - d}:${minPreco(i)}:${qtd(i)}`);
    db.dias[chaveDe(i)] = reg.join(';');
  }
  // fotos
  const foco = amostra.slice(0, N_FOCO);
  let auctionID = 312000000; let nLeiloesItem = []; let maiorFotoItem = 0;
  for (const i of foco) {
    const anel = [];
    for (let f = 0; f < FOTOS; f++) {
      const t = t0 - f * 600;
      if (i.stack > 1) {
        let p = minPreco(i); const deg = [];
        for (let j = 0; j < 12; j++) { deg.push(`${p}:${qtd(i)}:${int(logn(2, 0.8))}:${rnd() < 0.05 ? qtd(i) : 0}`); p = int(p * (1 + rnd() * 0.08)); }
        const baldes = []; for (let b = 0; b < 8; b++) { baldes.push(`${p}:${int(logn(800, 1.2))}`); p = int(p * 1.25); }
        anel.push(`${t}|1|${deg.join(',')}|${baldes.join(',')}|0`);
      } else {
        const n = Math.min(400, int(logn(8, 1.1)));
        nLeiloesItem.push(n);
        const L = []; let p = minPreco(i);
        for (let a = 0; a < n; a++) { L.push(`${auctionID++}:${p}:${int(p * 0.7)}:${1 + Math.floor(rnd() * 4)}:1:0`); p = int(p * (1 + rnd() * 0.1)); }
        const sF = `${t}|1|${L.join(',')}`; maiorFotoItem = Math.max(maiorFotoItem, sF.length);
        anel.push(sF);
      }
    }
    db.fotos[chaveDe(i)] = anel;
  }
  // sinais
  const estr = ['venda_verdes', 'venda_sobras', 'piso', 'vao', 'sniper'];
  for (let k = 0; k < 2000; k++) {
    const i = escolhe(amostra); const tot = int(logn(500, 1));
    db.sinais.push(`${k + 1}|${t0 - k * 30}|${escolhe(estr)}|${1 + Math.floor(rnd() * 3)}|${chaveDe(i)}|${int(logn(60, 1))}|${tot}:${int(tot * 1.3)}:0.0${Math.floor(rnd() * 9)}:${int(tot * 1.2)}|${rnd() < 0.5 ? 1 : 0}|${rnd() < 0.5 ? 'sold' : 'gone'}:${int(logn(40, 1))}`);
  }
  // pers: um negociador; livro, lotes, proprios, cofre, correio
  const nomes = opts.quatro ? ['Hexumlite', 'Rurik', 'Fingolfin', 'Ignatius'] : ['Hexumlite'];
  const verbos = ['post', 'buy', 'cancel', 'confirm'];
  for (const nome of nomes) {
    const livro = [], lotes = [], correio = [];
    for (let k = 0; k < 2000; k++) {
      const i = escolhe(amostra); const din = 50000 + Math.floor(rnd() * 400000);
      livro.push(`${k + 1}|${t0 - k * 40}|${escolhe(verbos)}|${chaveDe(i)}|${qtd(i)}|${minPreco(i)}|${escolhe(estr)}|${int(logn(500, 1))}:${int(logn(700, 1))}:0.03:${int(logn(600, 1))}|${din}|${din - int(logn(300, 1))}|AUCTION_HOUSE_AUCTION_CREATED|${t0 - k * 40 + 1}|key`);
    }
    for (let k = 0; k < 300; k++) { const i = escolhe(amostra); lotes.push(`${chaveDe(i)}|${qtd(i)}|${int(logn(400, 1))}|bought|sold|${t0 - k * 300}:${int(logn(600, 1))}`); }
    for (let k = 0; k < 300; k++) { const i = escolhe(amostra); correio.push(`${t0 - k * 300}|sold|${chaveDe(i)}|${int(logn(600, 1))}|${int(logn(600, 1))}|${int(logn(30, 1))}|${int(logn(30, 1))}|${3600 + Math.floor(rnd() * 600)}`); }
    db.pers[nome] = { livro, lotes, proprios: [], cofre: { banca: 40000, perdaDia: 0, depDia: 0 }, correio };
  }
  // calib: 11 parametros x 100 amostras
  for (const p of ['corte', 'deposito', 'rs', 'rx', 'rc', 'atraso', 'entrega', 'cadencia', 'freq', 'sumiu', 'eta']) {
    db.calib[p] = { amostras: Array.from({ length: 100 }, () => Math.round(rnd() * 1e6) / 1e3), n: 100, v: 0.05, medido: true, em: t0 };
  }
  for (let k = 0; k < 300; k++) { const i = escolhe(amostra); db.itens[chaveDe(i)] = `${i.sell}:${i.stack > 1 ? 'c' : 'i'}:${i.stack}:2`; }
  for (let k = 0; k < 60; k++) db.sessoes.push(`${t0 - k * 86400}|5520|21|14|3|11|1075|tiq=15;mu=0.15;eta=0.5`);
  for (let k = 0; k < 30; k++) db.sonda['S' + k] = `${t0}|ok|medida ${k} valor ${Math.round(rnd() * 1e5)}`;
  for (let k = 0; k < 60; k++) db.log.push(`${t0 - k} [Pedidos] folego encerrado: 20 buscas em 41 s, 0 dropped, resumo completo`);
  return { db, nLeiloesItem, maiorFotoItem };
}

// ---------- Serializadores ----------
function luaStr(v) { return '"' + v.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n') + '"'; }
function ehArray(o) { return Array.isArray(o); }
// estilo A (hipotese: o gravador do cliente indenta com tab e comenta o indice do vetor)
function serA(v, ind = '') {
  if (typeof v === 'string') return luaStr(v);
  if (typeof v === 'number') return String(v);
  if (typeof v === 'boolean') return v ? 'true' : 'false';
  const prox = ind + '\t'; const lin = ['{'];
  if (ehArray(v)) v.forEach((x, k) => lin.push(`${prox}${serA(x, prox)}, -- [${k + 1}]`));
  else for (const [k, x] of Object.entries(v)) lin.push(`${prox}[${luaStr(k)}] = ${serA(x, prox)},`);
  lin.push(ind + '}'); return lin.join('\n');
}
// estilo B (minimo, sem espaco)
function serB(v) {
  if (typeof v === 'string') return luaStr(v);
  if (typeof v === 'number') return String(v);
  if (typeof v === 'boolean') return v ? 'true' : 'false';
  if (ehArray(v)) return '{' + v.map(serB).join(',') + '}';
  return '{' + Object.entries(v).map(([k, x]) => `[${luaStr(k)}]=${serB(x)}`).join(',') + '}';
}

// ---------- Memoria estimada em Lua 5.1, 64 bits ----------
// TString: cabecalho 24 + len + 1; Table: 56 + 16 por slot do vetor + 40 por no do hash (potencia de 2)
const pot2 = n => { let p = 1; while (p < n) p *= 2; return n ? p : 0; };
function memLua(v, vistos = new Set()) {
  if (typeof v === 'string') { if (vistos.has(v)) return 0; vistos.add(v); return 24 + v.length + 1; }
  if (typeof v !== 'object') return 0;
  let m = 56;
  if (ehArray(v)) { m += 16 * pot2(v.length); for (const x of v) m += memLua(x, vistos); }
  else { const e = Object.entries(v); m += 40 * pot2(e.length); for (const [k, x] of e) m += memLua(k, vistos) + memLua(x, vistos); }
  return m;
}

// ---------- Constantes de uma funcao (o arquivo de SV e um chunk) ----------
function contarConstantes(txt) {
  const set = new Set(); const re = /"((?:[^"\\]|\\.)*)"|(?<![\w.])(-?\d+(?:\.\d+)?)(?![\w.])/g; let m;
  while ((m = re.exec(txt))) set.add(m[1] !== undefined ? 's' + m[1] : 'n' + m[2]);
  return set.size;
}

function medirParse(txt, rotulo) {
  global.gc && global.gc();
  const h0 = process.memoryUsage().heapUsed; const t = process.hrtime.bigint();
  let ok = true, nulo = null, erro = '';
  try {
    const ast = luaparse.parse(txt, { encodingMode: 'pseudo-latin1' });
    const ms = Number(process.hrtime.bigint() - t) / 1e6; const h1 = process.memoryUsage().heapUsed;
    const astNone = luaparse.parse('x = "abc"');
    nulo = astNone.body[0].init[0].value;
    return { rotulo, ok, ms: Math.round(ms), heapMB: +((h1 - h0) / 1048576).toFixed(1), valorPadraoNone: nulo };
  } catch (e) { ok = false; erro = e.message; return { rotulo, ok, erro }; }
}

function secoes(db, ser) {
  const r = {};
  for (const k of Object.keys(db)) r[k] = Buffer.byteLength(`["${k}"] = ` + ser(db[k]));
  return r;
}
const KB = n => +(n / 1024).toFixed(1);

const saida = {};
// Dados.lua
const d = gerarDados();
fs.writeFileSync(OUT + 'Dados-gerado.lua', d.txt);
saida.dados = { itensNoCSV: itens.length, comPrecoVenda: comVenda.length, maiorItemID: maxId, KB_formato_design: KB(Buffer.byteLength(d.txt)), constantes_formato_design: d.consts, KB_so_preco: KB(Buffer.byteLength(d.txtAlt)), constantes_so_preco: d.constsAlt, limite_constantes_lua51: 262143 };
saida.dados.parse = medirParse(d.txt, 'Dados.lua');

for (const fase of [1, 2]) {
  const { db, nLeiloesItem, maiorFotoItem } = gerarBanco(fase);
  const a = 'PregaoForeverDB = ' + serA(db) + '\n';
  const b = 'PregaoForeverDB = ' + serB(db) + '\n';
  fs.writeFileSync(OUT + `PregaoForever-fase${fase}-estiloA.lua`, a);
  const secA = secoes(db, serA), secB = secoes(db, serB);
  const def = zlib.deflateRawSync(Buffer.from(b));
  const b64 = def.toString('base64');
  saida['fase' + fase] = {
    KB_estiloA_tab_e_comentario: KB(Buffer.byteLength(a)),
    KB_estiloB_minimo: KB(Buffer.byteLength(b)),
    secoesKB_estiloA: Object.fromEntries(Object.entries(secA).map(([k, v]) => [k, KB(v)])),
    secoesKB_estiloB: Object.fromEntries(Object.entries(secB).map(([k, v]) => [k, KB(v)])),
    bytes_por_linha_resumo: +(db.resumo.dados.length / 8000).toFixed(1),
    bytes_por_dia_em_dias: +(Object.values(db.dias).reduce((s, x) => s + x.length, 0) / (1500 * 14)).toFixed(1),
    bytes_medio_foto: +(Object.values(db.fotos).flat().reduce((s, x) => s + x.length, 0) / Object.values(db.fotos).flat().length).toFixed(0),
    leiloes_por_foto_de_item_mediana_max: [nLeiloesItem.sort((x, y) => x - y)[Math.floor(nLeiloesItem.length / 2)], Math.max(...nLeiloesItem)],
    maior_foto_de_item_bytes: maiorFotoItem,
    bytes_medio_sinal: +(db.sinais.reduce((s, x) => s + x.length, 0) / db.sinais.length).toFixed(0),
    bytes_medio_acao: +(Object.values(db.pers)[0].livro.reduce((s, x) => s + x.length, 0) / 2000).toFixed(0),
    constantes_no_arquivo: contarConstantes(b),
    memoria_lua_estimada_MB: +(memLua(db) / 1048576).toFixed(2),
    deflate_KB: KB(def.length), deflate_base64_KB: KB(b64.length), razao_deflate_base64: +(Buffer.byteLength(b) / b64.length).toFixed(2),
    parse_estiloA: medirParse(a, 'fase' + fase + 'A'),
  };
}
// quatro negociadores (pers por personagem) e teto de 3 e 5 MB
{
  const { db } = gerarBanco(2, { quatro: true });
  const a = 'PregaoForeverDB = ' + serA(db) + '\n';
  saida.fase2_quatro_pers = { KB_estiloA: KB(Buffer.byteLength(a)), parse: medirParse(a, 'quatro') };
  const big = a.repeat(1); let x = a; while (Buffer.byteLength(x) < 5 * 1048576) x += '\nPregaoForeverDB2 = ' + serA(db) + '\n';
  saida.cinco_MB = { KB: KB(Buffer.byteLength(x)), parse: medirParse(x, '5MB') };
}
// dias com chave de data de 8 digitos (aaaammdd) em vez de 5
saida.nota = 'estilo A = hipotese do gravador do cliente (tab + comentario de indice); medir na S1';
fs.writeFileSync(OUT + 'medidas.json', JSON.stringify(saida, null, 2));
console.log(JSON.stringify(saida, null, 2));
