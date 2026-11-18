// Funcoes comuns das ferramentas de precos e receitas do PregaoForever (fora do jogo).
// Node 24, sem dependencias. Contrato em CONTRATO.md, nesta pasta.
import { readFile, writeFile, mkdir, readdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const AQUI = path.dirname(fileURLToPath(import.meta.url));
export const BUILD = '1.60.1.70938';
export const RAIZ_MODDER = path.resolve(AQUI, '..', '..');
export const DADOS = path.join(RAIZ_MODDER, 'dados', 'pregao');
export const CACHE = path.join(DADOS, 'cache');
export const PUBLICO = path.join(DADOS, 'publico');
export const ARQ_RECEITAS = path.join(DADOS, 'receitas-lw.json');
export const ARQ_PRECOS = path.join(DADOS, 'precos.json');
export const CASA_PUBLICA = 'us-111';
export const URL_PUBLICA = 'https://github.com/RuslanMunasipov/quest-murder-prices/releases/download/current';

// CSV com aspas (campo pode ter virgula, aspas dobradas e quebra de linha). Devolve objetos por cabecalho.
export function lerCsv(texto, nome = 'csv') {
  const linhas = [];
  let campo = '', linha = [], aspas = false;
  for (let i = 0; i < texto.length; i++) {
    const c = texto[i];
    if (aspas) {
      if (c === '"') { if (texto[i + 1] === '"') { campo += '"'; i++; } else aspas = false; } else campo += c;
    } else if (c === '"') aspas = true;
    else if (c === ',') { linha.push(campo); campo = ''; }
    else if (c === '\n') { linha.push(campo); campo = ''; linhas.push(linha); linha = []; }
    else if (c !== '\r') campo += c;
  }
  if (campo !== '' || linha.length) { linha.push(campo); linhas.push(linha); }
  if (!linhas.length) throw new Error(`${nome}: vazio`);
  const cab = linhas[0];
  const registros = [];
  for (let n = 1; n < linhas.length; n++) {
    const l = linhas[n];
    if (l.length === 1 && l[0] === '') continue;
    if (l.length !== cab.length) throw new Error(`${nome}: linha ${n + 1} tem ${l.length} campos, cabecalho tem ${cab.length}`);
    registros.push(Object.fromEntries(cab.map((c, i) => [c, l[i]])));
  }
  return registros;
}

// Tabela do cliente em CSV, do wago.tools, com cache em dados/pregao/cache.
export async function tabela(nome, colunas = []) {
  const arq = path.join(CACHE, `${nome}-${BUILD}.csv`);
  let texto;
  try { texto = await readFile(arq, 'utf8'); } catch (e) {
    if (e.code !== 'ENOENT') throw e;
    const url = `https://wago.tools/db2/${nome}/csv?build=${BUILD}`;
    const r = await fetch(url);
    if (!r.ok) throw new Error(`${nome}: HTTP ${r.status} em ${url}`);
    texto = await r.text();
    await mkdir(CACHE, { recursive: true });
    await writeFile(arq, texto);
  }
  const reg = lerCsv(texto, nome);
  for (const c of colunas) if (!(c in reg[0])) throw new Error(`${nome}: coluna ${c} ausente`);
  return reg;
}

// Pasta SavedVariables da conta (o nome da pasta da conta nao e gravado em arquivo do projeto).
export async function pastaSavedVariables() {
  const inst = JSON.parse(await readFile(path.resolve(RAIZ_MODDER, '..', 'comum', 'instalacao.json'), 'utf8'));
  const contas = path.join(inst.raiz, '_forever_', 'WTF', 'Account');
  const achadas = [];
  for (const d of await readdir(contas, { withFileTypes: true })) {
    if (d.isDirectory() && d.name !== 'SavedVariables') achadas.push(path.join(contas, d.name, 'SavedVariables'));
  }
  if (achadas.length !== 1) throw new Error(`esperava 1 conta em WTF/Account, achei ${achadas.length}`);
  return achadas[0];
}

// 31511 -> "3g 15s 11c"; negativo com sinal; zero -> "0c".
export function moeda(cobre) {
  const n = Math.round(Math.abs(cobre));
  const g = Math.floor(n / 10000), s = Math.floor((n % 10000) / 100), c = n % 100;
  const p = [];
  if (g) p.push(`${g}g`);
  if (g || s) p.push(g ? `${String(s).padStart(2, '0')}s` : `${s}s`);
  p.push(g || s ? `${String(c).padStart(2, '0')}c` : `${c}c`);
  return (cobre < 0 ? '-' : '') + p.join(' ');
}

export async function gravarJson(arq, obj) {
  await mkdir(path.dirname(arq), { recursive: true });
  await writeFile(arq, JSON.stringify(obj));
}
export async function lerJson(arq) { return JSON.parse(await readFile(arq, 'utf8')); }

export const sha256 = (texto) => createHash('sha256').update(texto).digest('hex');

export async function baixarTexto(nome) {
  const url = `${URL_PUBLICA}/${nome}`;
  const r = await fetch(url);
  if (!r.ok) throw new Error(`HTTP ${r.status} em ${url}`);
  return await r.text();
}

// "a=1 b=x y=2" -> { a: '1', b: 'x', y: '2' }; so pega os pares com "=".
export function lerKv(linha) {
  return Object.fromEntries(
    linha.trim().split(/\s+/).filter((p) => p.includes('=')).map((p) => {
      const i = p.indexOf('=');
      return [p.slice(0, i), p.slice(i + 1)];
    }),
  );
}
