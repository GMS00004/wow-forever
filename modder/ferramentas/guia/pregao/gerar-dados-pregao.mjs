// Gera Dados.lua do PregaoForever a partir do ItemSparse (CSV exportado do wago.tools).
// Uso: node gerar-dados-pregao.mjs [caminho do CSV]
// Padrao: dados/pregao/cache/ItemSparse-1.60.1.70938.csv (a partir da raiz modder).
// Grava addons-proprios/PregaoForever/Dados.lua (sobrescreve).
// Os dados servem so a triagem; o preco que decide e lido ao vivo no jogo.
import { readFileSync, writeFileSync } from 'node:fs';
import { basename, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const aqui = fileURLToPath(new URL('.', import.meta.url));
const raizModder = resolve(aqui, '../../..');
const csvPadrao = resolve(raizModder, 'dados/pregao/cache/ItemSparse-1.60.1.70938.csv');
const saida = resolve(raizModder, 'addons-proprios/PregaoForever/Dados.lua');
const BUILD = '1.60.1.70938';

const csvPath = process.argv[2] ? resolve(process.argv[2]) : csvPadrao;

// CSV com campos entre aspas (aspas dobradas e quebras de linha dentro do campo).
function parseCSV(texto) {
  const linhas = [];
  let linha = [];
  let campo = '';
  let aspas = false;
  for (let i = 0; i < texto.length; i++) {
    const c = texto[i];
    if (aspas) {
      if (c === '"') {
        if (texto[i + 1] === '"') { campo += '"'; i++; } else aspas = false;
      } else campo += c;
    } else if (c === '"') {
      aspas = true;
    } else if (c === ',') {
      linha.push(campo); campo = '';
    } else if (c === '\n' || c === '\r') {
      if (c === '\r' && texto[i + 1] === '\n') i++;
      linha.push(campo); campo = '';
      linhas.push(linha); linha = [];
    } else {
      campo += c;
    }
  }
  if (campo !== '' || linha.length > 0) { linha.push(campo); linhas.push(linha); }
  return linhas;
}

const texto = readFileSync(csvPath, 'utf8');
const [cabecalho, ...registros] = parseCSV(texto);
const col = (nome) => {
  const i = cabecalho.indexOf(nome);
  if (i < 0) throw new Error(`coluna ${nome} ausente no cabecalho do CSV`);
  return i;
};
const iId = col('ID');
const iVenda = col('SellPrice');
const iPilha = col('Stackable');

const inteiro = (s, onde) => {
  if (!/^\d+$/.test(s)) throw new Error(`valor nao inteiro em ${onde}: "${s}"`);
  return Number(s);
};

const vend = new Map();
const pilha = new Map();
const vistos = new Set();
let lidas = 0;
for (const r of registros) {
  if (r.length === 1 && r[0] === '') continue;
  lidas++;
  const id = inteiro(r[iId], 'ID');
  if (vistos.has(id)) throw new Error(`ID repetido: ${id}`);
  vistos.add(id);
  const venda = inteiro(r[iVenda], `SellPrice do ID ${id}`);
  const pil = inteiro(r[iPilha], `Stackable do ID ${id}`);
  if (venda > 0) vend.set(id, venda);
  if (pil > 1) pilha.set(id, pil);
}

const ordenar = (m) => [...m.entries()].sort((a, b) => a[0] - b[0]);
const linhasTabela = (entradas) => {
  const out = [];
  for (let i = 0; i < entradas.length; i += 12) {
    out.push('\t' + entradas.slice(i, i + 12).map(([k, v]) => `[${k}]=${v}`).join(',') + ',');
  }
  return out.join('\n');
};

const hoje = new Date().toISOString().slice(0, 10);
const nomeEntrada = basename(csvPath);
const conteudo = [
  '-- Dados.lua do PregaoForever: dados estaticos para a triagem. GERADO por gerar-dados-pregao.mjs; nao editar a mao.',
  '-- Origem: wago.tools, tabela ItemSparse, build ' + BUILD + '.',
  '-- Arquivo de entrada: ' + nomeEntrada,
  '-- Gerado em ' + hoje + '.',
  '-- ns.vend: SellPrice (preco de venda ao vendedor), so itens com preco maior que zero.',
  '-- ns.pilha: Stackable, so itens com tamanho de pilha maior que 1.',
  '-- Serve so a triagem: o preco que decide e lido ao vivo no jogo.',
  '',
  'local _, ns = ...',
  '',
  'ns.vend = {',
  linhasTabela(ordenar(vend)),
  '}',
  '',
  'ns.pilha = {',
  linhasTabela(ordenar(pilha)),
  '}',
  '',
].join('\n');

if (/[^\x00-\x7F]/.test(conteudo)) throw new Error('conteudo gerado tem caractere fora do ASCII');

writeFileSync(saida, conteudo, 'utf8');

const kb = (Buffer.byteLength(conteudo, 'utf8') / 1024).toFixed(1);
console.log(`CSV: ${csvPath}`);
console.log(`linhas de dados lidas: ${lidas}`);
console.log(`ns.vend: ${vend.size} itens (SellPrice > 0)`);
console.log(`ns.pilha: ${pilha.size} itens (Stackable > 1)`);
console.log(`gravado: ${saida} (${kb} KB)`);
