// Leitor fora do jogo das SavedVariables do PregaoForever.
// Gramatica congelada: ARQUITETURA.md, secao 4 (um exemplo por tipo, copiado de la). Esquema do banco: DESIGN.md, secao 6.
// Contrato da mesa (DESIGN.md, "Contratos de dados"): le sem executar (luaparse, luaVersion 5.1, encodingMode pseudo-latin1),
// confere esquema, fim == seq e identifica registros por (epoca, seq); recusa o registro de versao desconhecida e conta;
// arquiva a copia crua e grava o JSON.
// Uso (de wow/modder/ferramentas/guia/):
//   node pregao/ler-pregao.mjs --ida-e-volta
//   node pregao/ler-pregao.mjs <arquivo SavedVariables>
import { createRequire } from 'node:module';
import { readFileSync, writeFileSync, copyFileSync, mkdirSync, constants } from 'node:fs';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const luaparse = require('luaparse');
const aqui = dirname(fileURLToPath(import.meta.url));
const PASTA_ARQUIVO = join(aqui, '..', '..', '..', 'dados', 'pregao', 'arquivo');
const PASTA_JSON = join(aqui, '..', '..', '..', 'dados', 'pregao', 'json');

// ---------- listas da gramatica ----------
const ESQUEMAS = ['1'];
const ORIGENS_ACAO = ['key', 'mouse', 'outside'];
const ORIGENS_LOTE = ['comprado', 'coletado'];
const ESTADOS_LOTE = ['maos', 'postado', 'vendido', 'npc', 'retirado'];
const JANELAS = ['play', 'between'];
const REGRAS_POST = ['m', 'u', 'f'];
const GARGALOS = ['capital', 'sinal', 'vazao', 'giro', ''];
const TIPOS_ITEM = ['c', 'i'];
const ACOES = ['post', 'buy', 'cancel', 'outside'];
const DEGRAU = ['preco', 'qtd', 'donos', 'proprias', 'conta'];
const LEILAO = ['id', 'arremate', 'lance', 'faixa', 'qtd', 'dono', 'conta'];
const DIA = ['dia', 'min', 'qtd'];
const BLOCO = ['bloco', 'min', 'qtd'];
const GIRO = ['bloco', 'vendas', 'exposicao'];
const RESTO = ['contagem', 'soma'];
const BILHETE_BUY = ['total', 'teto', 'fracao', 'saida'];
const BILHETE_POST = ['duracao', 'regra', 'deposito', 'fila'];
const BILHETE_CANCEL = ['deposito', 'custo', 'fila'];
// registros com numero de serie (seq) que nao se repetem dentro de uma epoca
const SEQ_UNICA = new Set(['livro', 'sinais', 'correio', 'fora', 'sessoes']);

// ---------- campos basicos ----------
const isTab = v => v !== null && typeof v === 'object';
const INTEIRO = /^-?\d+$/;
function int(s, onde) {
  const n = Number(s);
  if (typeof s !== 'string' || !INTEIRO.test(s) || String(n) !== s || !Number.isSafeInteger(n))
    throw new Error(`${onde}: inteiro canonico esperado`);
  return n;
}
function bin(s, onde) {
  if (s !== '0' && s !== '1') throw new Error(`${onde}: 0 ou 1 esperado`);
  return Number(s);
}
function txt(s, onde) {
  if (typeof s !== 'string') throw new Error(`${onde}: texto esperado`);
  return s;
}
function opc(s, lista, onde) {
  if (!lista.includes(s)) throw new Error(`${onde}: valor fora da lista`);
  return s;
}
const opcional = (s, f, onde) => (s === '' ? null : f(s, onde));
function numero(v, onde) {
  if (!Number.isSafeInteger(v)) throw new Error(`${onde}: inteiro esperado no SavedVariables`);
  return v;
}
const I = (s, onde) => int(s, onde);
const S = (s, onde) => txt(s, onde);
const B = (s, onde) => bin(s, onde);
const M = (s, onde) => {
  if (typeof s !== 'string' || !/^[FE]*$/.test(s)) throw new Error(`${onde}: marcas fora de F e E`);
  return s;
};

// tupla "a:b:c" e listas "t1;t2" ou "t1,t2" de tuplas
function tupla(s, nomes, onde) {
  if (typeof s !== 'string') throw new Error(`${onde}: texto esperado`);
  const p = s.split(':');
  if (p.length !== nomes.length) throw new Error(`${onde}: ${nomes.length} campos separados por ":" esperados`);
  const o = {};
  nomes.forEach((k, i) => { o[k] = int(p[i], onde); });
  return o;
}
const serTupla = (o, nomes) => nomes.map(k => o[k]).join(':');
function tuplas(s, nomes, sepLista, onde) {
  if (typeof s !== 'string') throw new Error(`${onde}: texto esperado`);
  return s === '' ? [] : s.split(sepLista).map(x => tupla(x, nomes, onde));
}
const serTuplas = (lista, nomes, sepLista) => lista.map(o => serTupla(o, nomes)).join(sepLista);

// resumo: "chave=min:qtd;..."
function chaveMinQtd(s, onde) {
  if (typeof s !== 'string') throw new Error(`${onde}: texto esperado`);
  if (s === '') return [];
  return s.split(';').map(e => {
    const i = e.indexOf('=');
    if (i <= 0) throw new Error(`${onde}: entrada sem chave`);
    return { chave: e.slice(0, i), ...tupla(e.slice(i + 1), ['min', 'qtd'], onde) };
  });
}
const serChaveMinQtd = lista => lista.map(o => `${o.chave}=${serTupla(o, ['min', 'qtd'])}`).join(';');

// chave de item: "itemID" (commodity) ou "itemID:itemLevel:itemSuffix" (item)
function decChave(s, onde) {
  let m = /^(\d+)$/.exec(s);
  if (m) return { itemID: int(m[1], onde) };
  m = /^(\d+):(\d+):(\d+)$/.exec(s);
  if (m) return { itemID: int(m[1], onde), itemLevel: int(m[2], onde), itemSuffix: int(m[3], onde) };
  throw new Error(`${onde}: chave de item fora do formato`);
}
const encChave = o => (o.itemLevel === undefined ? String(o.itemID) : `${o.itemID}:${o.itemLevel}:${o.itemSuffix}`);

// bilhete do livro, conforme o verbo; verbo sem formato conhecido guarda o texto cru
function decBilhete(verbo, s, onde) {
  if (s === '') return null;
  if (verbo === 'buy') return tupla(s, BILHETE_BUY, onde);
  if (verbo === 'cancel') return tupla(s, BILHETE_CANCEL, onde);
  if (verbo === 'post') {
    const p = s.split(':');
    if (p.length !== 4) throw new Error(`${onde}: bilhete de post com 4 campos esperado`);
    return { duracao: int(p[0], onde), regra: opc(p[1], REGRAS_POST, onde), deposito: int(p[2], onde), fila: int(p[3], onde) };
  }
  return { bruto: s };
}
function encBilhete(o) {
  if (o === null) return '';
  if (o.bruto !== undefined) return o.bruto;
  if ('total' in o) return serTupla(o, BILHETE_BUY);
  if ('custo' in o) return serTupla(o, BILHETE_CANCEL);
  return [o.duracao, o.regra, o.deposito, o.fila].join(':');
}

// cauda da foto de commodity: 8 baldes ou T (truncada)
function decCauda(s, onde) {
  if (s === 'T') return 'T';
  const p = typeof s === 'string' ? s.split(',') : [];
  if (p.length !== 8) throw new Error(`${onde}: cauda com 8 baldes ou T`);
  return p.map(x => int(x, onde));
}
const encCauda = c => (c === 'T' ? 'T' : c.join(','));

// ---------- linhas versionadas ----------
// n = campos da linha inteira, contando a versao. livre: o ultimo campo pode conter "|".
function reg(n, cols, livre = false) {
  if (cols.length + 1 !== n) throw new Error(`gramatica: ${n} campos declarados, ${cols.length + 1} nas colunas`);
  return {
    n,
    livre,
    dec(p, onde) {
      const o = {};
      cols.forEach(([k, f], i) => { o[k] = f(p[i], onde, o); });
      return o;
    },
    enc(o) { return cols.map(([k, , e]) => (e ? e(o[k]) : o[k])); },
  };
}
const serLista = (nomes, sep) => v => serTuplas(v, nomes, sep);
const decLista = (nomes, sep) => (s, onde) => tuplas(s, nomes, sep, onde);

const ESPEC = {
  itens: reg(5, [
    ['vend', I], ['tipo', (s, onde) => opc(s, TIPOS_ITEM, onde)], ['pilha', I], ['conf', B],
  ]),
  resumo: reg(2, [['entradas', (s, onde) => chaveMinQtd(s, onde), v => serChaveMinQtd(v)]]),
  dias: reg(2, [['entradas', decLista(DIA, ';'), serLista(DIA, ';')]]),
  blocos: reg(2, [['entradas', decLista(BLOCO, ';'), serLista(BLOCO, ';')]]),
  giro: reg(2, [['entradas', decLista(GIRO, ';'), serLista(GIRO, ';')]]),
  tri: reg(4, [['saida', I], ['tremor', I], ['t', I]]),
  fotosCom: reg(7, [
    ['seq', I], ['t', I], ['marcas', M], ['qtot', I],
    ['degraus', decLista(DEGRAU, ','), serLista(DEGRAU, ',')],
    ['cauda', decCauda, encCauda],
  ]),
  fotosItem: reg(8, [
    ['seq', I], ['t', I], ['marcas', M], ['donos', I], ['nomesVieram', I],
    ['leiloes', decLista(LEILAO, ','), serLista(LEILAO, ',')],
    ['resto', (s, onde) => tupla(s, RESTO, onde), v => serTupla(v, RESTO)],
  ]),
  sinais: reg(14, [
    ['seq', I], ['t', I], ['estrategia', S], ['nivel', I], ['chave', S], ['qtd', I], ['preco', I],
    ['previsto', I], ['motivo', S], ['executou', B], ['desfecho', S], ['realizado', I], ['exposicao', I],
  ]),
  livro: reg(16, [
    ['seq', I], ['t', I], ['verbo', S], ['chave', S], ['qtd', I], ['preco', I], ['estrategia', S],
    ['origem', (s, onde) => opc(s, ORIGENS_ACAO, onde)], ['antes', I], ['depois', I], ['eco', S], ['tEco', I],
    ['erro', S],
    ['bilhete', (s, onde, o) => decBilhete(o.verbo, s, onde), encBilhete],
    ['fotoEm', (s, onde) => opcional(s, int, onde)],
  ]),
  lote: reg(10, [
    ['seq', I], ['t', I], ['chave', S], ['qtd', I], ['custo', I],
    ['origem', (s, onde) => opc(s, ORIGENS_LOTE, onde)],
    ['estado', (s, onde) => opc(s, ESTADOS_LOTE, onde)],
    ['tFecho', I], ['resultado', S],
  ]),
  correio: reg(14, [
    ['seq', I], ['t', I], ['tipo', S], ['chave', S], ['bid', I], ['buyout', I], ['deposit', I],
    ['consignment', I], ['moneyDelay', I], ['etaHour', I], ['etaMin', I], ['count', I], ['commerce', I],
  ]),
  fora: reg(5, [['seq', I], ['t', I], ['variacao', I], ['janela', (s, onde) => opc(s, JANELAS, onde)]]),
  proprios: reg(8, [
    ['auctionID', I], ['estado', I], ['qtd', I], ['tempo', I], ['lance', I], ['arremate', I], ['t', I],
  ]),
  cofre: reg(4, [['gatilho', S], ['t', I], ['seq', I]]),
  calib: reg(6, [['valor', I], ['n', I], ['medido', I], ['em', I], ['build', I]]),
  sessoes: reg(9, [
    ['seq', I], ['tIni', I], ['tFim', I],
    ['acoes', (s, onde) => tupla(s, ACOES, onde), v => serTupla(v, ACOES)],
    ['resultado', I], ['fora', I], ['gargalo', (s, onde) => opc(s, GARGALOS, onde)], ['parametros', S],
  ]),
  npc: reg(4, [['compra', I], ['disponivel', I], ['t', I]]),
  sonda: reg(4, [['t', I], ['build', I], ['resultado', S]], true),
  log: reg(4, [['t', I], ['nivel', S], ['texto', S]], true),
};

// divide a linha; com livre, o ultimo campo recebe o resto (com "|")
function partir(linha, n, onde, livre) {
  const p = linha.split('|');
  if (livre && p.length > n) return [...p.slice(0, n - 1), p.slice(n - 1).join('|')];
  if (p.length !== n) throw new Error(`${onde}: ${n} campos esperados, ${p.length} lidos`);
  return p;
}

// Le uma linha. Versao diferente de 1: devolve null e conta em ctx.desconhecidos (nao decodifica).
// Linha invalida: lanca erro.
function lerLinha(tipo, linha, onde, ctx) {
  if (typeof linha !== 'string') throw new Error(`${onde}: valor nao e texto`);
  if (linha.split('|', 1)[0] !== '1') { ctx.desconhecidos++; return null; }
  const spec = ESPEC[tipo];
  const p = partir(linha, spec.n, onde, spec.livre);
  return spec.dec(p.slice(1), onde);
}
function encodeLinha(tipo, obj, versao = '1') {
  return [versao, ...ESPEC[tipo].enc(obj)].join('|');
}

// fecho: tabela { dinheiro, t, seq }, gravada no PLAYER_LOGOUT
function decFechoTab(f, onde) {
  if (!isTab(f)) throw new Error(`${onde}: tabela esperada`);
  return { dinheiro: numero(f.dinheiro, onde), t: numero(f.t, onde), seq: numero(f.seq, onde) };
}

// ---------- leitura do SavedVariables (sem executar) ----------
const utf8 = s => (typeof s === 'string' ? Buffer.from(s, 'latin1').toString('utf8') : s);

// AST do luaparse para valor Lua. Strings vem como bytes em latin1 (pseudo-latin1) e voltam em UTF-8.
function paraJs(no, onde) {
  switch (no.type) {
    case 'TableConstructorExpression': {
      const obj = {};
      let pos = 0;
      for (const f of no.fields) {
        if (f.type === 'TableValue') { pos++; obj[String(pos)] = paraJs(f.value, `${onde}[${pos}]`); }
        else if (f.type === 'TableKeyString') obj[f.key.name] = paraJs(f.value, `${onde}.${f.key.name}`);
        else if (f.type === 'TableKey') {
          const k = paraJs(f.key, onde);
          if (k === null || typeof k === 'object') throw new Error(`${onde}: chave fora do formato`);
          obj[String(k)] = paraJs(f.value, `${onde}[${k}]`);
        } else throw new Error(`${onde}: campo fora do formato`);
      }
      return obj;
    }
    case 'StringLiteral': return utf8(no.value);
    case 'NumericLiteral': return no.value;
    case 'BooleanLiteral': return no.value;
    case 'NilLiteral': return null;
    case 'UnaryExpression':
      if (no.operator === '-' && no.argument.type === 'NumericLiteral') return -no.argument.value;
      break;
    default: break;
  }
  throw new Error(`${onde}: valor fora do formato (${no.type})`);
}

function lerSavedVariables(texto) {
  let ast;
  try { ast = luaparse.parse(texto, { luaVersion: '5.1', encodingMode: 'pseudo-latin1' }); }
  catch (e) { throw new Error(`nao e Lua 5.1 valido (${e.message})`); }
  const globais = {};
  for (const st of ast.body) {
    const ok = st.type === 'AssignmentStatement' && st.variables.length === 1 && st.init.length === 1
      && st.variables[0].type === 'Identifier' && st.init[0].type === 'TableConstructorExpression';
    if (!ok) throw new Error('comando que nao e "NOME = { ... }" (o arquivo nao e executado)');
    globais[st.variables[0].name] = paraJs(st.init[0], st.variables[0].name);
  }
  return globais;
}

// esquema tem de voltar nao nulo e conhecido (o luaparse em modo padrao devolve null em toda string)
function checarCabecalho(db) {
  const e = db.esquema;
  if (e === null || e === undefined) throw new Error('esquema nao voltou (nulo ou ausente)');
  if (!ESQUEMAS.includes(String(e))) throw new Error(`esquema desconhecido: ${String(e)}`);
  if (typeof db.epoca !== 'number' || typeof db.seq !== 'number') throw new Error('epoca ou seq ausentes');
}

// entradas de uma tabela Lua: chaves numericas em ordem numerica, demais na ordem do arquivo
function entradas(obj) {
  if (!isTab(obj)) return [];
  const ks = Object.keys(obj);
  if (ks.length && ks.every(k => /^\d+$/.test(k))) ks.sort((a, b) => Number(a) - Number(b));
  return ks.map(k => [k, obj[k]]);
}

// Decodifica o banco inteiro. Nunca lanca por registro: o que nao le vai para invalidos.
function lerBanco(db, globais) {
  const r = { registros: {}, desconhecidos: 0, invalidos: [], duplicados: 0 };
  const vistos = new Set();
  const conta = rotulo => { r.registros[rotulo] = (r.registros[rotulo] || 0) + 1; };
  const invalido = (onde, motivo) => r.invalidos.push({ onde, motivo });

  const linha = (tipo, valor, onde, rotulo = tipo) => {
    try {
      const o = lerLinha(tipo, valor, onde, r);
      if (o === null) return null;
      conta(rotulo);
      if (SEQ_UNICA.has(rotulo)) {
        const k = `${db.epoca}:${o.seq}`;
        if (vistos.has(k)) r.duplicados++; else vistos.add(k);
      }
      return o;
    } catch (e) { invalido(onde, e.message); return null; }
  };
  const tabela = (obj, onde, tipo, rotulo = tipo) => {
    const out = {};
    if (obj === undefined || obj === null) return out;
    if (!isTab(obj)) { invalido(onde, 'esperava tabela'); return out; }
    for (const [k, v] of entradas(obj)) {
      const o = linha(tipo, v, `${onde}[${k}]`, rotulo);
      if (o !== null) out[k] = o;
    }
    return out;
  };
  const lista = (obj, onde, tipo, rotulo = tipo) => Object.values(tabela(obj, onde, tipo, rotulo));
  const decCofre = (c, onde) => {
    if (c === undefined || c === null) return null;
    if (!isTab(c)) { invalido(onde, 'esperava tabela'); return null; }
    const contadores = {};
    for (const [k, v] of entradas(c)) if (k !== 'disjuntores') contadores[k] = v;
    return { contadores, disjuntores: tabela(c.disjuntores, `${onde}.disjuntores`, 'cofre', 'disjuntores') };
  };
  const decFecho = (f, onde) => {
    if (f === undefined || f === null) return null;
    try { const o = decFechoTab(f, onde); conta('fecho'); return o; }
    catch (e) { invalido(onde, e.message); return null; }
  };

  const casas = {};
  for (const [ck, c] of entradas(db.casas)) {
    const onde = `casas[${ck}]`;
    if (!isTab(c)) { invalido(onde, 'esperava tabela'); continue; }
    const fotos = {};
    for (const [k, v] of entradas(c.fotos)) {
      // fotos[chave] e o anel de fotos da chave (lista de linhas); uma linha solta tambem e aceita
      const tipoFoto = k.includes(':') ? 'fotosItem' : 'fotosCom';
      if (isTab(v)) {
        const anel = lista(v, `${onde}.fotos[${k}]`, tipoFoto, 'fotos');
        if (anel.length > 0) fotos[k] = anel;
      } else {
        const o = linha(tipoFoto, v, `${onde}.fotos[${k}]`, 'fotos');
        if (o !== null) fotos[k] = [o];
      }
    }
    let resumo = null;
    const rs = c.resumo ?? null;
    if (isTab(rs)) {
      const d = linha('resumo', rs.dados, `${onde}.resumo.dados`, 'resumo');
      resumo = { t: rs.t ?? null, tr: rs.tr ?? null, pedidos: rs.pedidos ?? null, completa: rs.completa ?? null, n: rs.n ?? null, entradas: d ? d.entradas : null };
    } else if (typeof rs === 'string') {
      const d = linha('resumo', rs, `${onde}.resumo`, 'resumo');
      resumo = { entradas: d ? d.entradas : null };
    } else if (rs !== null) invalido(`${onde}.resumo`, 'esperava tabela ou texto');
    casas[ck] = {
      resumo,
      itens: tabela(c.itens, `${onde}.itens`, 'itens'),
      dias: tabela(c.dias, `${onde}.dias`, 'dias'),
      blocos: tabela(c.blocos, `${onde}.blocos`, 'blocos'),
      giro: tabela(c.giro, `${onde}.giro`, 'giro'),
      tri: tabela(c.tri, `${onde}.tri`, 'tri'),
      fotos,
      npc: tabela(c.npc, `${onde}.npc`, 'npc'),
    };
  }

  const pers = {};
  for (const [nome, p] of entradas(db.pers)) {
    const onde = `pers[${nome}]`;
    if (!isTab(p)) { invalido(onde, 'esperava tabela'); continue; }
    pers[nome] = {
      livro: lista(p.livro, `${onde}.livro`, 'livro'),
      lotes: lista(p.lotes, `${onde}.lotes`, 'lote', 'lotes'),
      abertos: lista(p.abertos, `${onde}.abertos`, 'lote', 'abertos'),
      correio: lista(p.correio, `${onde}.correio`, 'correio'),
      fora: lista(p.fora, `${onde}.fora`, 'fora'),
      proprios: lista(p.proprios, `${onde}.proprios`, 'proprios'),
      cofre: decCofre(p.cofre, `${onde}.cofre`),
      fecho: decFecho(p.fecho, `${onde}.fecho`),
    };
  }

  const calib = {};
  for (const [param, v] of entradas(db.calib)) {
    const itens = isTab(v) ? entradas(v).map(([, x]) => x) : [v];
    const cabecalho = linha('calib', itens[0], `calib[${param}]`);
    const amostras = itens.slice(1);
    amostras.forEach(() => conta('amostras'));
    calib[param] = { cabecalho, amostras };
  }

  return {
    esquema: String(db.esquema),
    epoca: db.epoca,
    seq: db.seq,
    fim: db.fim,
    saidaLimpa: typeof db.fim === 'number' && db.fim === db.seq,
    recibo: db.recibo ?? null,
    salvoEm: db.salvoEm ?? null,
    sobrescritos: db.sobrescritos ?? null,
    bancoDesde: globais.PregaoForeverCharDB?.bancoDesde ?? null,
    casas,
    pers,
    sinais: lista(db.sinais, 'sinais', 'sinais'),
    sessoes: lista(db.sessoes, 'sessoes', 'sessoes'),
    sonda: tabela(db.sonda, 'sonda', 'sonda'),
    log: lista(db.log, 'log', 'log'),
    calib,
    registros: r.registros,
    desconhecidos: r.desconhecidos,
    invalidos: r.invalidos,
    duplicados: r.duplicados,
  };
}

// ---------- uso (b): ler um arquivo ----------
const carimbo = d => {
  const p = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
};

function resumoPessoas(pers) {
  const linhas = [];
  for (const [nome, p] of Object.entries(pers)) {
    const verbos = {};
    const origens = { key: 0, mouse: 0, outside: 0 };
    for (const a of p.livro) {
      verbos[a.verbo] = (verbos[a.verbo] || 0) + 1;
      origens[a.origem]++;
    }
    const cont = `livro ${p.livro.length}, lotes ${p.lotes.length}, abertos ${p.abertos.length}, correio ${p.correio.length}, `
      + `fora ${p.fora.length}, proprios ${p.proprios.length}, disjuntores ${p.cofre ? Object.keys(p.cofre.disjuntores).length : 0}, `
      + `fecho ${p.fecho ? 'sim' : 'nao'}`;
    const vTxt = Object.keys(verbos).sort().map(v => `${v}=${verbos[v]}`).join(' ') || 'nenhuma';
    linhas.push(`  ${nome}: ${cont}`);
    linhas.push(`     acoes: ${vTxt} | origem: key=${origens.key} mouse=${origens.mouse} outside=${origens.outside}`);
  }
  return linhas;
}

function lerArquivo(caminho) {
  const nome = basename(caminho);
  const parar = msg => {
    console.log(`ERRO ${msg}`);
    console.log('RESUMO registros=0 desconhecidos=0 invalidos=0 erros=1');
    process.exit(1);
  };

  let bruto;
  try { bruto = readFileSync(caminho); } catch { parar(`nao consegui ler ${nome}`); }
  let globais;
  try { globais = lerSavedVariables(bruto.toString('latin1')); } catch (e) { parar(`${nome}: ${e.message}`); }
  const db = globais.PregaoForeverDB;
  if (!isTab(db)) parar(`${nome}: falta PregaoForeverDB`);
  try { checarCabecalho(db); } catch (e) { parar(`${nome}: ${e.message}`); }

  const r = lerBanco(db, globais);

  const nomeCopia = `${carimbo(new Date())}-PregaoForever.lua`;
  const nomeJson = `${nomeCopia}.json`;
  mkdirSync(PASTA_ARQUIVO, { recursive: true });
  mkdirSync(PASTA_JSON, { recursive: true });
  try { copyFileSync(caminho, join(PASTA_ARQUIVO, nomeCopia), constants.COPYFILE_EXCL); }
  catch (e) { parar(`copia ${nomeCopia} nao gravada (${e.code || 'erro'})`); }
  const saida = { arquivo: nome, copia: nomeCopia, ...r };
  try { writeFileSync(join(PASTA_JSON, nomeJson), JSON.stringify(saida, null, 2) + '\n', { flag: 'wx' }); }
  catch (e) { parar(`json ${nomeJson} nao gravado (${e.code || 'erro'})`); }

  const total = Object.values(r.registros).reduce((a, b) => a + b, 0);
  const L = [];
  L.push(`arquivo: ${nome}`);
  L.push(`esquema: ${r.esquema} | epoca: ${r.epoca} | seq: ${r.seq} | fim: ${r.fim}`);
  L.push(`saida limpa: ${r.saidaLimpa ? 'sim' : 'nao'}`);
  L.push(`registros por tipo: ${Object.entries(r.registros).map(([k, v]) => `${k}=${v}`).join(' ') || 'nenhum'}`);
  L.push(`desconhecidos (versao diferente de 1): ${r.desconhecidos} | invalidos: ${r.invalidos.length} | duplicados (epoca, seq): ${r.duplicados}`);
  L.push(`personagens: ${Object.keys(r.pers).length}`);
  L.push(...resumoPessoas(r.pers));
  if (r.invalidos.length) {
    L.push('invalidos (primeiros 5):');
    for (const i of r.invalidos.slice(0, 5)) L.push(`  ${i.onde}: ${i.motivo}`);
  }
  L.push(`copia: ${nomeCopia}`);
  L.push(`json: ${nomeJson}`);
  L.push(`RESUMO registros=${total} desconhecidos=${r.desconhecidos} invalidos=${r.invalidos.length} erros=0`);
  console.log(L.join('\n'));
  process.exit(0);
}

// ---------- uso (a): ida e volta da gramatica ----------
function idaEVolta() {
  // exemplos copiados de ARQUITETURA.md, linhas 217 a 297 (sonda e log sem exemplo na gramatica: construidos da linha)
  const caso = (tipo, texto, rotulo = tipo) => ({
    rotulo,
    texto,
    dec: t => lerLinha(tipo, t, rotulo, { desconhecidos: 0 }),
    enc: o => encodeLinha(tipo, o),
  });
  const casos = [
    { rotulo: 'chave de item (commodity)', texto: '2589', dec: t => decChave(t, 'chave'), enc: encChave },
    { rotulo: 'chave de item (item)', texto: '6541:18:845', dec: t => decChave(t, 'chave'), enc: encChave },
    caso('itens', '1|13|c|20|1'),
    caso('resumo', '1|2589=9:3120;2770=54:880'),
    caso('dias', '1|20773:9:3120;20774:10:2890'),
    caso('blocos', '1|124640:9:3120;124641:9:3300'),
    caso('giro', '1|124640:38:5400'),
    caso('tri', '1|4200|0|1794873600'),
    caso('fotosCom', '1|8841|1794873600|FE|214|9:14:2:0:0,10:200:5:0:0|0,0,0,0,0,0,0,0', 'fotos (commodity)'),
    caso('fotosItem', '1|8850|1794873700|F|2|1|771:20000:0:2:1:0:0,774:21500:0:3:1:0:0|0:0', 'fotos (item)'),
    caso('sinais', '1|9002|1794874000|piso|1|2589|14|9|56|NEW|0|sold|52|7400'),
    caso('livro', '1|9010|1794874100|post|6541:18:845|1|20000|venda_verdes|key|31200|31170|created|1794874101||24:m:30:0|1794874058'),
    caso('lote', '1|9011|1794874100|6541:18:845|1|0|coletado|postado|0|0', 'lotes, abertos'),
    caso('correio', '1|9050|1794880000|seller|6541:18:845|20000|20000|30|1000|0|0|0|1|0'),
    caso('fora', '1|9060|1794881000|1240|play'),
    caso('proprios', '1|771|1|1|3600|0|20000|1794874200'),
    caso('cofre', '1|perda_dia|1794875000|9031', 'cofre (disjuntor)'),
    caso('calib', '1|500|3|1|1794880000|70938'),
    caso('sessoes', '1|9100|1794870000|1794875520|21:14:3:11|1075|2400|capital|'),
    caso('npc', '1|500|3|1794874300'),
    caso('sonda', '1|1794880500|70938|passo ok', 'sonda (construido da linha)'),
    caso('log', '1|1794880600|info|texto com | barra', 'log (construido da linha)'),
    {
      rotulo: 'fecho (tabela)',
      texto: { dinheiro: 31000, t: 1794875520, seq: 9099 },
      dec: o => decFechoTab(o, 'fecho'),
      enc: o => ({ dinheiro: o.dinheiro, t: o.t, seq: o.seq }),
    },
  ];

  let erros = 0;
  for (const c of casos) {
    try {
      const sai = c.enc(c.dec(c.texto));
      const igual = typeof c.texto === 'string' ? sai === c.texto : JSON.stringify(sai) === JSON.stringify(c.texto);
      if (igual) console.log(`OK ${c.rotulo}`);
      else { erros++; console.log(`FALHA ${c.rotulo}: voltou ${JSON.stringify(sai)}`); }
    } catch (e) { erros++; console.log(`FALHA ${c.rotulo}: ${e.message}`); }
  }

  // registro de versao 2: a leitura tem de recusar e contar
  const ctx = { desconhecidos: 0 };
  const v2 = encodeLinha('itens', { vend: 13, tipo: 'c', pilha: 20, conf: 1 }, '2');
  const lida = lerLinha('itens', v2, 'versao 2', ctx);
  if (v2 === '2|13|c|20|1' && lida === null && ctx.desconhecidos === 1) console.log(`OK versao 2 recusada e contada (${v2})`);
  else { erros++; console.log(`FALHA versao 2: lida=${JSON.stringify(lida)} contada=${ctx.desconhecidos}`); }

  console.log(`RESUMO tipos=${casos.length} erros=${erros}`);
  process.exit(erros ? 1 : 0);
}

// ---------- entrada ----------
function main() {
  const args = process.argv.slice(2);
  if (args.length === 1 && args[0] === '--ida-e-volta') return idaEVolta();
  if (args.length === 1 && !args[0].startsWith('--')) return lerArquivo(args[0]);
  console.error('uso: node pregao/ler-pregao.mjs --ida-e-volta');
  console.error('     node pregao/ler-pregao.mjs <arquivo SavedVariables PregaoForever.lua>');
  process.exit(1);
}

try {
  main();
} catch (e) {
  // so o codigo do erro: mensagens de sistema de arquivo trazem caminhos
  console.log(`ERRO inesperado (${e.code || e.message})`);
  console.log('RESUMO registros=0 desconhecidos=0 invalidos=0 erros=1');
  process.exit(1);
}
