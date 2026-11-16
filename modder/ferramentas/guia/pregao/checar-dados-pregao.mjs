// Confere o Dados.lua do PregaoForever gerado por gerar-dados-pregao.mjs.
// Uso: node checar-dados-pregao.mjs [caminho do CSV] [caminho do Dados.lua]
// Confere: (a) so ASCII; (b) analisa com luaparse, Lua 5.1; (c) contagens e ids batem com o CSV;
// (d) valores inteiros positivos, e em ns.vend menores que 10.000.000; (e) cabecalho cita o build 70938.
// Sai com 0 so com erros=0.
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
import { basename, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const luaparse = require('luaparse');

const aqui = fileURLToPath(new URL('.', import.meta.url));
const raizModder = resolve(aqui, '../../..');
const csvPath = process.argv[2]
  ? resolve(process.argv[2])
  : resolve(raizModder, 'dados/pregao/cache/ItemSparse-1.60.1.70938.csv');
const luaPath = process.argv[3]
  ? resolve(process.argv[3])
  : resolve(raizModder, 'addons-proprios/PregaoForever/Dados.lua');

let erros = 0;
const erro = (msg) => { erros++; console.log('ERRO ' + msg); };

// CSV com campos entre aspas (mesmo parser do gerador, escrito de novo para conferir de forma independente).
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

// Contagens esperadas, lidas direto do CSV.
const [cabecalho, ...registros] = parseCSV(readFileSync(csvPath, 'utf8'));
const iId = cabecalho.indexOf('ID');
const iVenda = cabecalho.indexOf('SellPrice');
const iPilha = cabecalho.indexOf('Stackable');
if (iId < 0 || iVenda < 0 || iPilha < 0) { console.log('ERRO CSV sem colunas ID/SellPrice/Stackable'); console.log('RESUMO erros=1'); process.exit(1); }

const esperadoVend = new Map();
const esperadoPilha = new Map();
let linhasCsv = 0;
for (const r of registros) {
  if (r.length === 1 && r[0] === '') continue;
  linhasCsv++;
  const id = Number(r[iId]);
  const venda = Number(r[iVenda]);
  const pil = Number(r[iPilha]);
  if (venda > 0) esperadoVend.set(id, venda);
  if (pil > 1) esperadoPilha.set(id, pil);
}

// (a) ASCII
const texto = readFileSync(luaPath, 'utf8');
const foraAscii = texto.match(/[^\x00-\x7F]/g);
if (foraAscii) erro(`(a) ${foraAscii.length} caractere(s) fora do ASCII`);

// (b) sintaxe Lua 5.1
let ast = null;
try {
  ast = luaparse.parse(texto, { luaVersion: '5.1', scope: false });
} catch (e) {
  erro(`(b) sintaxe Lua 5.1: ${e.message}`);
}

// Le uma tabela "ns.X = { [k]=v, ... }" do AST; devolve Map(id -> valor) ou null.
function lerTabela(nome) {
  const atribuicoes = ast.body.filter(s => s.type === 'AssignmentStatement'
    && s.variables.length === 1
    && s.variables[0].type === 'MemberExpression'
    && s.variables[0].base.type === 'Identifier' && s.variables[0].base.name === 'ns'
    && s.variables[0].identifier.name === nome);
  if (atribuicoes.length !== 1) { erro(`(c) ns.${nome} deve ser atribuido uma vez (achei ${atribuicoes.length})`); return null; }
  const init = atribuicoes[0].init;
  if (init.length !== 1 || init[0].type !== 'TableConstructorExpression') { erro(`(c) ns.${nome} nao e uma tabela literal`); return null; }
  const mapa = new Map();
  for (const campo of init[0].fields) {
    if (campo.type !== 'TableKey' || campo.key.type !== 'NumericLiteral' || campo.value.type !== 'NumericLiteral') {
      erro(`(d) ns.${nome}: entrada fora de [numero]=numero: tipo ${campo.type}`);
      continue;
    }
    const chave = campo.key.raw;
    const valor = campo.value.raw;
    if (!/^\d+$/.test(chave)) erro(`(d) ns.${nome}: chave nao e inteiro positivo: ${chave}`);
    if (!/^\d+$/.test(valor)) erro(`(d) ns.${nome}: valor nao e inteiro positivo: ${valor}`);
    const id = Number(chave);
    if (mapa.has(id)) erro(`(c) ns.${nome}: id repetido ${id}`);
    mapa.set(id, Number(valor));
  }
  return mapa;
}

let vend = null;
let pilha = null;
if (ast) {
  // Nada de global: so as duas atribuicoes a ns e o local de entrada.
  const tipos = ast.body.map(s => s.type);
  const esperado = ['LocalStatement', 'AssignmentStatement', 'AssignmentStatement'];
  if (tipos.length !== 3 || tipos.some((t, i) => t !== esperado[i])) erro(`(c) estrutura inesperada: ${tipos.join(', ')}`);
  vend = lerTabela('vend');
  pilha = lerTabela('pilha');
}

// (c) contagens e conjuntos de ids
const lidasVend = vend ? vend.size : 0;
const lidasPilha = pilha ? pilha.size : 0;
console.log(`linhas no CSV: ${linhasCsv}`);
console.log(`itens com SellPrice > 0 no CSV: ${esperadoVend.size} (ns.vend lido: ${lidasVend})`);
console.log(`itens com Stackable > 1 no CSV: ${esperadoPilha.size} (ns.pilha lido: ${lidasPilha})`);
if (vend && vend.size !== esperadoVend.size) erro(`(c) contagem ns.vend ${vend.size} != ${esperadoVend.size}`);
if (pilha && pilha.size !== esperadoPilha.size) erro(`(c) contagem ns.pilha ${pilha.size} != ${esperadoPilha.size}`);
if (vend) {
  let faltam = 0, sobram = 0, diferentes = 0;
  for (const [id, v] of esperadoVend) { if (!vend.has(id)) faltam++; else if (vend.get(id) !== v) diferentes++; }
  for (const id of vend.keys()) if (!esperadoVend.has(id)) sobram++;
  if (faltam || sobram || diferentes) erro(`(c) ns.vend difere do CSV: faltam ${faltam}, sobram ${sobram}, valor diferente ${diferentes}`);
}
if (pilha) {
  let faltam = 0, sobram = 0, diferentes = 0;
  for (const [id, v] of esperadoPilha) { if (!pilha.has(id)) faltam++; else if (pilha.get(id) !== v) diferentes++; }
  for (const id of pilha.keys()) if (!esperadoPilha.has(id)) sobram++;
  if (faltam || sobram || diferentes) erro(`(c) ns.pilha difere do CSV: faltam ${faltam}, sobram ${sobram}, valor diferente ${diferentes}`);
}

// (d) faixas
if (vend) for (const [id, v] of vend) {
  if (!(v > 0)) erro(`(d) ns.vend[${id}] = ${v} nao e positivo`);
  if (!(v < 10000000)) erro(`(d) ns.vend[${id}] = ${v} nao e menor que 10.000.000`);
}
if (pilha) for (const [id, v] of pilha) {
  if (!(v > 1)) erro(`(d) ns.pilha[${id}] = ${v} nao e maior que 1`);
}

// (e) cabecalho cita o build 70938
const cabecalhoLua = texto.split('\n').filter(l => l.startsWith('--')).join('\n');
if (!/build\s+[\d.]*70938\b/.test(cabecalhoLua)) erro('(e) cabecalho nao cita o build 70938');

console.log(`arquivo: ${basename(luaPath)} (${(Buffer.byteLength(texto, 'utf8') / 1024).toFixed(1)} KB)`);
console.log(`RESUMO erros=${erros}`);
process.exit(erros === 0 ? 0 : 1);
