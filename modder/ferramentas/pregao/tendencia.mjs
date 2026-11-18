// Tendencia de preco do leilao (PregaoForever), fora do jogo. Node 24, sem dependencias.
// Uso:
//   node tendencia.mjs --item <id|nome>                                 curva do item: fotos de hoje e ontem, diario, faixa, percentil
//   node tendencia.mjs --elasticidade [--min-vendas 800] [--linhas 25]  ranking de materiais com gap de preco
//   node tendencia.mjs --vigia                                          itens da lista de vigia do CompraForever
// Opcoes: --pasta <dir das fotos> --precos <arquivo> --sv <CompraForever.lua> --hoje AAAA-MM-DD
// Contrato em CONTRATO.md, secao 4. Saida so em ASCII. Dinheiro em cobre inteiro (moeda() de comum.mjs).
import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import zlib from 'node:zlib';
import { pathToFileURL } from 'node:url';
import { PUBLICO, ARQ_PRECOS, ARQ_RECEITAS, CASA_PUBLICA, lerJson, moeda, pastaSavedVariables, tabela } from './comum.mjs';
import { lerCasa } from './baixar-precos.mjs';

const TAXA = 0.95;          // o leilao cobra 5% sobre a venda: ganho = mediana de (med * 0.95 - min)
const DIAS_JANELA = 4;      // janela das vendas e das medianas diarias
const DIAS_FAIXA = 7;       // janela da faixa de precos do diario
const MIN_MEDIANA = 150;    // cobre: mediana das medianas diarias minima no ranking
const MIN_FOTOS_GAPH = 12;  // fotos horarias minimas para calcular gapH
const MIN_VENDAS_PADRAO = 800;
const LINHAS_PADRAO = 25;
const USO = 'uso: node tendencia.mjs --item <id|nome> | --elasticidade [--min-vendas 800] [--linhas 25] | --vigia\n' +
  '  opcoes: [--pasta <dir>] [--precos <arq>] [--sv <CompraForever.lua>] [--hoje AAAA-MM-DD]';

// Erro com codigo de saida: 2 = uso, 1 = dado.
class Parar extends Error {
  constructor(msg, codigo = 1) { super(msg); this.codigo = codigo; }
}

// ---------- texto e datas ----------
const pad2 = (n) => String(n).padStart(2, '0');

// Tira acento e troca o que sobrar fora de ASCII imprimivel por '?'.
function ascii(s) {
  return String(s).normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^\x20-\x7e]/g, '?');
}

// Chave de busca de nome: sem acento, sem caixa, sem espacos nas pontas.
const chaveBusca = (s) => ascii(s).toLowerCase().trim();

function formatarDia(d) { return `${d.getFullYear()}${pad2(d.getMonth() + 1)}${pad2(d.getDate())}`; }

// Epoch em segundos -> AAAAMMDD na hora local.
const diaDe = (epoch) => formatarDia(new Date(epoch * 1000));
const horaDe = (epoch) => { const d = new Date(epoch * 1000); return `${pad2(d.getHours())}:${pad2(d.getMinutes())}`; };

// AAAAMMDD somado de n dias (calendario local).
const somarDias = (dia, n) =>
  formatarDia(new Date(Number(dia.slice(0, 4)), Number(dia.slice(4, 6)) - 1, Number(dia.slice(6, 8)) + n));
const isoDia = (dia) => `${dia.slice(0, 4)}-${dia.slice(4, 6)}-${dia.slice(6, 8)}`;

// ---------- estatistica ----------
// Quantil por interpolacao linear (tipo 7). Lista vazia: null.
function quantil(valores, q) {
  const v = [...valores].sort((a, b) => a - b);
  const n = v.length;
  if (!n) return null;
  const h = (n - 1) * q;
  const lo = Math.floor(h);
  const hi = Math.ceil(h);
  return v[lo] + (h - lo) * (v[hi] - v[lo]);
}
const mediana = (v) => quantil(v, 0.5);

// Percentil de x: porcentagem inteira dos valores menores ou iguais a x. Lista vazia: null.
function percentil(valores, x) {
  if (!valores.length) return null;
  return Math.round((100 * valores.filter((v) => v <= x).length) / valores.length);
}

// Tabela ASCII. dirs[i] = 'l' (alinha a esquerda) ou 'r' (a direita). Largura pela maior celula.
function montarTabela(cab, dirs, linhas) {
  const larg = cab.map((c, i) => Math.max(c.length, ...linhas.map((l) => l[i].length)));
  const fmt = (vals) =>
    vals.map((v, i) => (dirs[i] === 'r' ? v.padStart(larg[i]) : v.padEnd(larg[i]))).join('  ').trimEnd();
  return [fmt(cab), ...linhas.map(fmt)];
}

// ---------- argumentos ----------
function lerArgs(argv) {
  const o = {
    modo: null, item: null, minVendas: MIN_VENDAS_PADRAO, linhas: LINHAS_PADRAO,
    pasta: path.join(PUBLICO, 'fotos'), precos: ARQ_PRECOS, sv: null, hoje: null,
  };
  let modo = null;
  const definir = (m) => {
    if (modo && modo !== m) throw new Parar('use so um modo: --item, --elasticidade ou --vigia', 2);
    modo = m;
  };
  const inteiro = (v, nome) => {
    if (!/^\d+$/.test(v)) throw new Parar(`${nome} pede um inteiro`, 2);
    return Number(v);
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const prox = () => {
      if (i + 1 >= argv.length) throw new Parar(`${a} pede um valor`, 2);
      i++;
      return argv[i];
    };
    if (a === '--item') { definir('item'); o.item = prox(); }
    else if (a === '--elasticidade') definir('elasticidade');
    else if (a === '--vigia') definir('vigia');
    else if (a === '--min-vendas') o.minVendas = inteiro(prox(), a);
    else if (a === '--linhas') o.linhas = inteiro(prox(), a);
    else if (a === '--pasta') o.pasta = prox();
    else if (a === '--precos') o.precos = prox();
    else if (a === '--sv') o.sv = prox();
    else if (a === '--hoje') {
      const h = prox();
      if (!/^\d{4}-\d{2}-\d{2}$/.test(h)) throw new Parar('--hoje pede AAAA-MM-DD', 2);
      o.hoje = h.replaceAll('-', '');
    }
    else throw new Parar(`opcao desconhecida: ${a}`, 2);
  }
  if (!modo) throw new Parar('escolha um modo: --item, --elasticidade ou --vigia', 2);
  if (modo === 'item' && o.item === null) throw new Parar('--item pede um id ou um nome', 2);
  o.modo = modo;
  return o;
}

// ---------- nomes ----------
let sparseMapa = null;
// Display_lang do ItemSparse (cache do cliente), carregado so quando preciso. Mapa id -> nome.
async function sparse() {
  if (!sparseMapa) {
    const reg = await tabela('ItemSparse', ['ID', 'Display_lang']);
    sparseMapa = new Map(reg.map((r) => [String(r.ID), r.Display_lang]));
  }
  return sparseMapa;
}

// Nome do item: receitas-lw.json primeiro; sem nome la, o ItemSparse.
async function nomeDe(id, receitas) {
  const r = receitas.itens?.[id]?.nome;
  if (r) return r;
  const s = (await sparse()).get(String(id));
  return s || `item ${id}`;
}

// Acha o item por id ou nome. Nome: sem acento e sem caixa, so entre itens com dados no precos.json.
// Exato unico vence; senao, um so candidato vence; mais de um devolve a lista (ate 10).
async function acharItem(arg, pub) {
  if (/^\d+$/.test(arg)) return { id: arg };
  const alvo = chaveBusca(arg);
  if (!alvo) throw new Parar('--item pede um id ou um nome', 2);
  const comDados = new Set([
    ...Object.keys(pub.historico || {}), ...Object.keys(pub.itens || {}), ...Object.keys(pub.saidas || {}),
  ]);
  const nomes = await sparse();
  const achados = [...comDados]
    .filter((id) => nomes.has(id) && chaveBusca(nomes.get(id)).includes(alvo))
    .map((id) => ({ id, nome: ascii(nomes.get(id)), chave: chaveBusca(nomes.get(id)) }))
    .sort((a, b) => (a.nome < b.nome ? -1 : a.nome > b.nome ? 1 : Number(a.id) - Number(b.id)));
  const exatos = achados.filter((a) => a.chave === alvo);
  if (exatos.length === 1) return { id: exatos[0].id };
  if (achados.length === 1) return { id: achados[0].id };
  if (!achados.length) throw new Parar(`nenhum item com nome "${ascii(arg)}" nos dados de preco`);
  const aviso = achados.length > 10 ? ' (mostrando 10)' : '';
  return {
    candidatos: [
      `ambiguo: ${achados.length} itens com "${ascii(arg)}"${aviso}`,
      ...achados.slice(0, 10).map((a) => `  ${a.id.padEnd(7)} ${a.nome}`),
      'use --item <id>',
    ],
  };
}

// ---------- precos.json ----------
// Dias (AAAAMMDD) presentes no historico, ate hoje, em ordem.
function diasDoHistorico(pub, hoje) {
  const dias = new Set();
  for (const arr of Object.values(pub.historico || {})) {
    for (const e of arr) {
      const d = String(e[0]);
      if (d <= hoje) dias.add(d);
    }
  }
  return [...dias].sort();
}

// Historico diario do item como [{ dia, min, med, unid }], so ate hoje.
function historicoDe(pub, id, hoje) {
  return (pub.historico?.[id] || [])
    .map(([d, min, med, unid]) => ({ dia: String(d), min, med, unid }))
    .filter((e) => e.dia <= hoje);
}

// Media de unidades vendidas por dia na janela (dias sem registro contam zero).
function vendasMedias(pub, id, janela) {
  if (!janela.length) return 0;
  const s = pub.saidas?.[id] || {};
  return janela.reduce((a, d) => a + (Number(s[d]) || 0), 0) / janela.length;
}

// ---------- fotos horarias (formato congelado do coletor) ----------
// Le as fotos us-111-<snapshot>.txt.gz da pasta. Guarda so os itens pedidos (ids).
// Devolve { total, ilegiveis, lista: [{ snap, dia, hora, itens: Map<id, {min,p25,med,unid,lotes}>}] }, da mais antiga.
async function lerFotos(pasta, ids) {
  let nomes;
  try { nomes = await readdir(pasta); } catch (e) {
    if (e.code === 'ENOENT') nomes = [];
    else throw e;
  }
  const re = new RegExp(`^${CASA_PUBLICA}-(\\d+)\\.txt\\.gz$`);
  const arqs = nomes
    .filter((n) => re.test(n))
    .map((n) => ({ arq: n, snap: Number(n.match(re)[1]) }))
    .sort((a, b) => a.snap - b.snap);
  const lista = [];
  let ilegiveis = 0;
  for (const { arq, snap } of arqs) {
    let casa;
    try {
      casa = lerCasa(zlib.gunzipSync(await readFile(path.join(pasta, arq))).toString('utf8'));
    } catch {
      ilegiveis++;
      continue;
    }
    const itens = new Map();
    for (const id of ids) {
      const it = casa.itens[id];
      if (it) itens.set(String(id), { min: it.min, p25: it.p25, med: it.med, unid: it.unid, lotes: it.lotes });
    }
    lista.push({ snap, dia: diaDe(snap), hora: horaDe(snap), itens });
  }
  return { total: lista.length, ilegiveis, lista };
}

// ---------- modo --item ----------
async function modoItem(arg, ctx) {
  const { pub, hoje, janela, faixa, receitas } = ctx;
  const achado = await acharItem(arg, pub);
  if (achado.candidatos) return { codigo: 1, linhas: achado.candidatos };
  const id = achado.id;
  const nome = await nomeDe(id, receitas);
  const agora = pub.itens?.[id] || null;
  const hist = historicoDe(pub, id, hoje);
  const fotos = await lerFotos(ctx.pasta, [id]);
  const s = pub.saidas?.[id] || {};
  const L = [];

  L.push(`${ascii(nome)} (id ${id})`);
  const quando = pub.foto ? `foto ${horaDe(pub.foto)} ${isoDia(diaDe(pub.foto))}` : 'sem hora de foto';
  L.push(agora
    ? `agora: min ${moeda(agora.min)}  p25 ${moeda(agora.p25)}  med ${moeda(agora.med)}  unid ${agora.unid}  (${quando})`
    : `agora: sem preco no leilao  (${quando})`);
  L.push('');

  if (fotos.total === 0) {
    L.push('sem fotos horarias ainda (coletor)');
  } else {
    const ontem = somarDias(hoje, -1);
    const recentes = fotos.lista.filter((f) => f.dia === hoje || f.dia === ontem);
    if (!recentes.length) {
      L.push('nenhuma foto de hoje ou ontem');
    } else {
      L.push(`fotos de hoje e de ontem (${recentes.length}):`);
      const linhas = recentes.map((f) => {
        const it = f.itens.get(id);
        const c = it ? [moeda(it.min), moeda(it.p25), moeda(it.med), String(it.unid), String(it.lotes)] : ['-', '-', '-', '-', '-'];
        return [isoDia(f.dia), f.hora, ...c];
      });
      L.push(...montarTabela(['dia', 'hora', 'min', 'p25', 'med', 'unid', 'lotes'], ['l', 'r', 'r', 'r', 'r', 'r', 'r'], linhas));
    }
  }
  if (fotos.ilegiveis) L.push(`fotos ilegiveis (ignoradas): ${fotos.ilegiveis}`);
  L.push('');

  L.push('diario (historico):');
  if (!hist.length) {
    L.push('  sem historico');
  } else {
    const linhas = hist.map((e) => [
      isoDia(e.dia), moeda(e.min), moeda(e.med), String(e.unid), s[e.dia] === undefined ? '-' : String(s[e.dia]),
    ]);
    L.push(...montarTabela(['dia', 'min', 'mediana', 'unid listadas', 'saidas do dia'], ['l', 'r', 'r', 'r', 'r'], linhas));
  }
  L.push('');

  const f7 = hist.filter((e) => faixa.includes(e.dia));
  L.push(f7.length
    ? `faixa 7 dias: min ${moeda(Math.min(...f7.map((e) => e.min)))} .. mediana ${moeda(mediana(f7.map((e) => e.med)))}`
    : 'faixa 7 dias: sem dados');

  const doFotos = fotos.lista.map((f) => f.itens.get(id)?.min).filter((v) => v !== undefined);
  const base = doFotos.length ? doFotos : hist.map((e) => e.min);
  const sufixo = doFotos.length ? '' : ' (base: diario)';
  if (!agora) L.push('agora: sem preco; percentil -');
  else if (!base.length) L.push('agora: sem base de minimos para o percentil');
  else L.push(`agora ${moeda(agora.min)} esta no percentil ${percentil(base, agora.min)}% dos minimos horarios${sufixo}`);

  L.push(`vendas/dia (media ${DIAS_JANELA} dias): ${Math.round(vendasMedias(pub, id, janela))}`);
  return { linhas: L };
}

// ---------- modo --elasticidade ----------
async function modoElasticidade(ctx) {
  const { pub, hoje, janela, minVendas, linhas } = ctx;

  // Candidatos: vendas medias na janela e mediana das medianas diarias no piso.
  const cands = [];
  for (const id of Object.keys(pub.saidas || {})) {
    const vend = vendasMedias(pub, id, janela);
    if (vend <= 0 || vend < minVendas) continue;
    const h = historicoDe(pub, id, hoje).filter((e) => janela.includes(e.dia));
    if (!h.length) continue;
    const med = mediana(h.map((e) => e.med));
    if (med < MIN_MEDIANA) continue;
    const gap = mediana(h.filter((e) => e.med > 0).map((e) => (e.med - e.min) / e.med));
    const ganho = mediana(h.map((e) => e.med * TAXA - e.min));
    cands.push({ id, vend, h, med, gap, ganho, score: ganho * Math.log(vend) });
  }
  cands.sort((a, b) => b.score - a.score);

  const topo = cands.slice(0, linhas);
  const fotos = await lerFotos(ctx.pasta, topo.map((c) => c.id));
  const fonte = `fonte: diario ${janela.length ? `${janela[0]}-${janela[janela.length - 1]}` : 'sem dias'}, fotos=${fotos.total}`;
  const L = [];
  if (!topo.length) {
    L.push(`nenhum item passa o filtro (vendas/dia >= ${minVendas}, mediana >= ${MIN_MEDIANA} cobre)`);
  } else {
    const linhasTab = [];
    for (const c of topo) {
      const agora = pub.itens?.[c.id] || null;
      const p25s = fotos.lista.map((f) => f.itens.get(c.id)?.p25).filter((v) => v !== undefined);
      let gapH = null;
      if (fotos.total >= MIN_FOTOS_GAPH && p25s.length) {
        const m = mediana(p25s);
        if (m > 0) gapH = (m - quantil(p25s, 0.1)) / m;
      }
      const nome = (await nomeDe(c.id, ctx.receitas)).slice(0, 29);
      linhasTab.push([
        c.id,
        ascii(nome).padEnd(29),
        String(Math.round(c.vend)),
        moeda(c.med),
        c.gap === null ? '-' : (100 * c.gap).toFixed(1),
        gapH === null ? '-' : (100 * gapH).toFixed(1),
        moeda(c.ganho),
        agora ? `${moeda(agora.min)}/${moeda(agora.p25)}` : '-',
        c.h.map((e) => `${e.dia.slice(4)}:${moeda(e.min)}/${moeda(e.med)}`).join(' '),
      ]);
    }
    L.push(...montarTabela(
      ['id', 'nome', 'vend/dia', 'med.mediana', 'gap%', 'gapH%', 'ganho/un', 'agora min/p25', 'dias min/med'],
      ['l', 'l', 'r', 'r', 'r', 'r', 'r', 'l', 'l'],
      linhasTab,
    ));
  }
  if (fotos.ilegiveis) L.push(`fotos ilegiveis (ignoradas): ${fotos.ilegiveis}`);
  L.push(fonte);
  return { linhas: L };
}

// ---------- modo --vigia ----------
// Indice do fechamento do '{' na posicao i, pulando strings "..." e comentarios --. -1 se nao fecha.
function fecharBloco(texto, i) {
  let prof = 0;
  for (let k = i; k < texto.length; k++) {
    const c = texto[k];
    if (c === '"') {
      k++;
      while (k < texto.length && texto[k] !== '"') {
        if (texto[k] === '\\') k++;
        k++;
      }
    } else if (c === '-' && texto[k + 1] === '-') {
      const fim = texto.indexOf('\n', k);
      if (fim < 0) return -1;
      k = fim;
    } else if (c === '{') {
      prof++;
    } else if (c === '}') {
      prof--;
      if (prof === 0) return k;
    }
  }
  return -1;
}

// Le ["vigia"]["itens"] do CompraForeverDB: [{ id, nome, teto }]. Sem bloco: [].
export function lerVigia(texto) {
  const i = texto.indexOf('["vigia"]');
  if (i < 0) return [];
  const j = texto.indexOf('["itens"]', i);
  if (j < 0) return [];
  const ini = texto.indexOf('{', j);
  const fim = ini < 0 ? -1 : fecharBloco(texto, ini);
  if (fim < 0) return [];
  const bloco = texto.slice(ini, fim + 1);
  const re = /\[(\d+)\]\s*=\s*\{/g;
  const out = [];
  let m;
  while ((m = re.exec(bloco))) {
    const abre = m.index + m[0].length - 1;
    const fecha = fecharBloco(bloco, abre);
    if (fecha < 0) break;
    const corpo = bloco.slice(abre, fecha + 1);
    re.lastIndex = fecha + 1;
    const teto = corpo.match(/\["teto"\]\s*=\s*(\d+)/);
    const nome = corpo.match(/\["nome"\]\s*=\s*"((?:[^"\\]|\\.)*)"/);
    if (teto) out.push({ id: m[1], nome: nome ? nome[1] : null, teto: Number(teto[1]) });
  }
  return out.sort((a, b) => Number(a.id) - Number(b.id));
}

async function modoVigia(ctx) {
  const { pub, hoje } = ctx;
  const arq = ctx.sv || path.join(await pastaSavedVariables(), 'CompraForever.lua');
  let texto = null;
  try { texto = await readFile(arq, 'utf8'); } catch (e) {
    if (e.code !== 'ENOENT') throw e;
  }
  const lista = texto === null ? [] : lerVigia(texto);
  if (!lista.length) return { linhas: ['vigia vazia'] };

  const fotos = await lerFotos(ctx.pasta, lista.map((v) => v.id));
  const doDia = fotos.lista.filter((f) => f.dia === hoje);
  const L = [];
  for (const v of lista) {
    const agora = pub.itens?.[v.id] || null;
    const nome = v.nome ? ascii(v.nome) : ascii(await nomeDe(v.id, ctx.receitas));
    const abaixo = doDia.filter((f) => f.itens.has(v.id) && f.itens.get(v.id).min <= v.teto).length;
    const doFotos = fotos.lista.map((f) => f.itens.get(v.id)?.min).filter((x) => x !== undefined);
    const base = doFotos.length ? doFotos : historicoDe(pub, v.id, hoje).map((e) => e.min);
    const sufixo = doFotos.length ? '' : ' (base: diario)';
    const pct = agora && base.length ? `${percentil(base, agora.min)}%${sufixo}` : '-';
    L.push(`${nome} (id ${v.id}): teto ${moeda(v.teto)}, agora ${agora ? moeda(agora.min) : 'sem preco'}, ` +
      `abaixo do teto em ${abaixo} de ${doDia.length} fotos de hoje, percentil ${pct}`);
  }
  return { linhas: L };
}

// ---------- principal ----------
async function principal(argv) {
  const o = lerArgs(argv);
  const hoje = o.hoje || formatarDia(new Date());
  const precos = await lerJson(o.precos);
  const pub = precos.publico || {};
  let receitas = { itens: {} };
  try { receitas = await lerJson(ARQ_RECEITAS); } catch (e) {
    if (e.code !== 'ENOENT') throw e;
  }
  const dias = diasDoHistorico(pub, hoje);
  const ctx = {
    ...o, pub, hoje, receitas,
    janela: dias.slice(-DIAS_JANELA),
    faixa: dias.slice(-DIAS_FAIXA),
  };
  if (o.modo === 'item') return modoItem(o.item, ctx);
  if (o.modo === 'elasticidade') return modoElasticidade(ctx);
  return modoVigia(ctx);
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  principal(process.argv.slice(2)).then(
    (r) => {
      for (const l of r.linhas) console.log(ascii(l));
      process.exitCode = r.codigo || 0;
    },
    (e) => {
      console.error(`erro: ${ascii(e.message)}`);
      if (e instanceof Parar && e.codigo === 2) console.error(USO);
      process.exitCode = e instanceof Parar ? e.codigo : 1;
    },
  );
}
