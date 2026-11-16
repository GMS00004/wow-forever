// Baixa os arquivos publicos de preco do leilao, le a exportacao do Auctionator e grava dados/pregao/precos.json.
// Contrato em CONTRATO.md, secao 4. Uso: node baixar-precos.mjs
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { PUBLICO, URL_PUBLICA, CASA_PUBLICA, ARQ_PRECOS, gravarJson, pastaSavedVariables } from './comum.mjs';

// Troca por espacos o conteudo de strings Lua que tem chaves e os comentarios "--".
// O tamanho do texto nao muda, entao as posicoes continuam valendo. Assim as chaves contam certo.
function mascarar(texto) {
  let out = '';
  let i = 0;
  const n = texto.length;
  while (i < n) {
    const c = texto[i];
    if (c === '"' || c === "'") {
      out += c;
      i++;
      while (i < n && texto[i] !== c && texto[i] !== '\n') {
        if (texto[i] === '\\' && i + 1 < n) {
          const e = texto[i + 1];
          out += ' ' + (e === '{' || e === '}' ? ' ' : e);
          i += 2;
          continue;
        }
        out += texto[i] === '{' || texto[i] === '}' ? ' ' : texto[i];
        i++;
      }
      if (i < n && texto[i] === c) { out += c; i++; }
    } else if (c === '-' && texto[i + 1] === '-') {
      while (i < n && texto[i] !== '\n') { out += ' '; i++; }
    } else {
      out += c;
      i++;
    }
  }
  return out;
}

// Acha `["chave"] = {` dentro de [de, ate) do texto mascarado e devolve [inicio, fim] do conteudo, ou null.
function acharBloco(m, chave, de = 0, ate = m.length) {
  const re = new RegExp(`\\[\\s*"${chave}"\\s*\\]\\s*=\\s*\\{`, 'g');
  re.lastIndex = de;
  const r = re.exec(m);
  if (!r || r.index >= ate) return null;
  const ini = r.index + r[0].length;
  let prof = 1;
  for (let i = ini; i < ate; i++) {
    if (m[i] === '{') prof++;
    else if (m[i] === '}' && --prof === 0) return [ini, i];
  }
  return null;
}

// Le o GuiaForever.lua. Devolve { em, itens: { "<id>": { preco, idadeDias } } } ou null sem o bloco ah.
export function lerExportacao(texto) {
  const m = mascarar(texto);
  const ah = acharBloco(m, 'ah');
  if (!ah) return null;
  const [ini, fim] = ah;
  const emM = /\["em"\]\s*=\s*([-+]?[\d.]+)/.exec(m.slice(ini, fim));
  const em = emM ? Number(emM[1]) : null;
  const itens = {};
  const p = acharBloco(m, 'p', ini, fim);
  if (p) {
    const re = /\["(\d+)"\]\s*=\s*([-+]?[\d.]+(?:[eE][-+]?\d+)?)\s*,?/g;
    for (const r of m.slice(p[0], p[1]).matchAll(re)) {
      const v = Number(r[2]);
      const preco = Math.floor(v);
      itens[r[1]] = { preco, idadeDias: Math.round((v - preco) * 1000) };
    }
  }
  return { em, itens };
}

const sha256 = (texto) => createHash('sha256').update(texto).digest('hex');

async function baixarTexto(nome) {
  const url = `${URL_PUBLICA}/${nome}`;
  const r = await fetch(url);
  if (!r.ok) throw new Error(`HTTP ${r.status} em ${url}`);
  return await r.text();
}

// "a=1 b=x y=2" -> { a: '1', b: 'x', y: '2' }; so pega os pares com "=".
function lerKv(linha) {
  return Object.fromEntries(
    linha.trim().split(/\s+/).filter((p) => p.includes('=')).map((p) => {
      const i = p.indexOf('=');
      return [p.slice(0, i), p.slice(i + 1)];
    }),
  );
}

// Baixa o indice e os dois arquivos da casa; confere o SHA-256. Se nao bater, tenta uma vez de novo.
async function baixarVerificado() {
  const nomeCasa = `${CASA_PUBLICA}.txt`;
  const nomeSales = `${CASA_PUBLICA}-sales.txt`;
  for (let tentativa = 1; tentativa <= 2; tentativa++) {
    const indice = await baixarTexto('index.txt');
    const linhas = indice.split(/\r?\n/).map(lerKv);
    const kvCasa = linhas.find((kv) => kv.file === nomeCasa);
    const kvSales = linhas.find((kv) => kv.art === nomeSales);
    if (!kvCasa || !kvSales) throw new Error(`index.txt sem ${nomeCasa} ou ${nomeSales}`);
    const casa = await baixarTexto(nomeCasa);
    const sales = await baixarTexto(nomeSales);
    const ok1 = sha256(casa) === kvCasa.sha256;
    const ok2 = sha256(sales) === kvSales.sha256;
    if (ok1 && ok2) return { indice, casa, sales };
    const ruins = [!ok1 && nomeCasa, !ok2 && nomeSales].filter(Boolean).join(', ');
    console.log(`AVISO sha256 nao bate (${ruins}), tentativa ${tentativa} de 2`);
  }
  return null;
}

// us-110.txt: cabecalho chave=valor e linhas "<tipo> <id> <min> <p25> <mediana> <unid> <lotes> <baratos>".
// Item repetido: fica a linha de menor min.
export function lerCasa(texto) {
  const cab = {};
  const itens = {};
  let repetidos = 0;
  for (const linha of texto.split('\n')) {
    const l = linha.trim();
    if (!l || l.startsWith('#')) continue;
    const partes = l.split(' ');
    if (partes[0] === 'c' || partes[0] === 'i') {
      if (partes.length < 7) throw new Error(`linha de casa com ${partes.length} campos: ${l.slice(0, 60)}`);
      const [tipo, id, min, p25, med, unid, lotes, baratos = ''] = partes;
      const entrada = {
        tipo,
        min: Number(min),
        p25: Number(p25),
        med: Number(med),
        unid: Number(unid),
        lotes: Number(lotes),
        baratos: baratos ? baratos.split(',').map((x) => x.split('x').map(Number)) : [],
      };
      if (id in itens) {
        repetidos++;
        if (entrada.min < itens[id].min) itens[id] = entrada;
      } else {
        itens[id] = entrada;
      }
    } else if (l.includes('=')) {
      const i = l.indexOf('=');
      cab[l.slice(0, i)] = l.slice(i + 1);
    }
  }
  if (!cab.snapshot) throw new Error('us-110.txt sem snapshot no cabecalho');
  return { foto: Number(cab.snapshot), itens, repetidos };
}

// us-110-sales.txt: "d <AAAAMMDD> <horas>" e "s <id> <AAAAMMDD>:<unid>,...".
export function lerVendas(texto) {
  const horas = {};
  const saidas = {};
  for (const linha of texto.split('\n')) {
    const partes = linha.trim().split(' ');
    if (partes[0] === 'd' && partes.length >= 3) {
      horas[partes[1]] = Number(partes[2]);
    } else if (partes[0] === 's' && partes.length >= 3) {
      const dias = (saidas[partes[1]] ??= {});
      for (const par of partes[2].split(',')) {
        const [dia, u] = par.split(':');
        if (dia) dias[dia] = Number(u);
      }
    }
  }
  return { horas, saidas };
}

// vendors.txt: "v=" tem a lista de itens em base 36, cada um a diferenca para o anterior.
// Valida contra vendor_items, canary_vendor e canary_clean. Devolve { lista } ou { erro }.
export function lerVendedores(texto) {
  const kv = {};
  for (const linha of texto.split('\n')) {
    const l = linha.trim();
    const i = l.indexOf('=');
    if (i > 0) kv[l.slice(0, i)] = l.slice(i + 1);
  }
  if (!kv.v) return { erro: 'sem linha v=' };
  const lista = [];
  let soma = 0;
  for (const d of kv.v.split(',')) {
    if (!d) continue;
    const delta = parseInt(d, 36);
    if (!Number.isInteger(delta)) return { erro: `delta invalido: ${d.slice(0, 20)}` };
    soma += delta;
    lista.push(soma);
  }
  if (String(lista.length) !== kv.vendor_items) return { erro: `total ${lista.length}, vendor_items=${kv.vendor_items}` };
  const set = new Set(lista);
  const cv = (kv.canary_vendor || '').split(',').filter(Boolean).map(Number);
  const cc = (kv.canary_clean || '').split(',').filter(Boolean).map(Number);
  if (!cv.length || !cc.length) return { erro: 'sem canary_vendor ou canary_clean' };
  const faltam = cv.filter((x) => !set.has(x));
  if (faltam.length) return { erro: `canary_vendor fora da lista: ${faltam.join(',')}` };
  const sobram = cc.filter((x) => set.has(x));
  if (sobram.length) return { erro: `canary_clean dentro da lista: ${sobram.join(',')}` };
  return { lista };
}

// Le GuiaForever.lua da pasta SavedVariables. Sem arquivo ou sem bloco ah: null.
async function lerAuctionator() {
  const pasta = await pastaSavedVariables();
  let texto;
  try {
    texto = await readFile(path.join(pasta, 'GuiaForever.lua'), 'utf8');
  } catch (e) {
    if (e.code === 'ENOENT') return null;
    throw e;
  }
  return lerExportacao(texto);
}

const iso = (s) => (Number.isFinite(s) ? new Date(s * 1000).toISOString() : 'sem data');

async function principal() {
  const baixado = await baixarVerificado();
  if (!baixado) {
    console.log('ERRO sha256 nao bate apos nova tentativa; precos.json nao gravado');
    process.exitCode = 2;
    return;
  }
  const vendorsTexto = await baixarTexto('vendors.txt');
  await mkdir(PUBLICO, { recursive: true });
  await writeFile(path.join(PUBLICO, 'index.txt'), baixado.indice);
  await writeFile(path.join(PUBLICO, `${CASA_PUBLICA}.txt`), baixado.casa);
  await writeFile(path.join(PUBLICO, `${CASA_PUBLICA}-sales.txt`), baixado.sales);
  await writeFile(path.join(PUBLICO, 'vendors.txt'), vendorsTexto);

  const casa = lerCasa(baixado.casa);
  const vendas = lerVendas(baixado.sales);
  const vend = lerVendedores(vendorsTexto);
  const auct = await lerAuctionator();

  const obj = {
    esquema: 1,
    geradoEm: new Date().toISOString(),
    publico: {
      casa: CASA_PUBLICA,
      foto: casa.foto,
      itens: casa.itens,
      saidas: vendas.saidas,
      horas: vendas.horas,
    },
    auctionator: auct,
    vendedor: vend.lista ?? null,
  };
  await gravarJson(ARQ_PRECOS, obj);

  console.log(`publico: foto ${iso(casa.foto)} itens=${Object.keys(casa.itens).length} repetidos=${casa.repetidos}`);
  console.log(`saidas: dias=${Object.keys(vendas.horas).length} itens=${Object.keys(vendas.saidas).length}`);
  if (vend.lista) console.log(`vendedor: itens=${vend.lista.length}`);
  else console.log(`AVISO vendedor: null (${vend.erro})`);
  if (auct) {
    const n = Object.keys(auct.itens).length;
    const idade0 = Object.values(auct.itens).filter((x) => x.idadeDias === 0).length;
    console.log(`auctionator: exportacao ${iso(auct.em)} precos=${n} idade0=${idade0}`);
  } else {
    console.log('auctionator: sem exportacao');
  }
  console.log(`gravado: ${ARQ_PRECOS}`);
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  principal().catch((e) => {
    console.log(`ERRO ${e.message}`);
    process.exitCode = 1;
  });
}
