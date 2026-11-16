// Le o CentralForeverDB (SavedVariables do addon) e, opcionalmente, o BugGrabberDB e um taint.log,
// e imprime um relatorio em secoes. So leitura: nenhum arquivo e alterado.
// Uso: node ler-diario-central.mjs --sv <arquivo> [--bug <BugGrabber.lua>] [--taint <taint.log>]
// Saida: 0 leu tudo; 1 arquivo ausente ou que nao carrega; 2 uso errado.
import { createRequire } from 'node:module';
import { readFileSync, existsSync } from 'node:fs';
import { basename } from 'node:path';

const require = createRequire(import.meta.url);
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');

const USO = 'uso: node ler-diario-central.mjs --sv <arquivo> [--bug <arquivo do BugGrabber>] [--taint <arquivo taint.log>]';

// serializador em Lua, rodado no mesmo estado: tabela vira JSON; chaves 1..n viram lista
const SERIALIZADOR = String.raw`
local esc = { ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }
local function texto(s)
  local r = string.gsub(s, '[%c"\\]', function(c)
    return esc[c] or ('\\u' .. string.format('%04x', string.byte(c)))
  end)
  return '"' .. r .. '"'
end
local function numero(n)
  if n ~= n or n == math.huge or n == -math.huge then return 'null' end
  return tostring(n)
end
local function valor(v)
  local tv = type(v)
  if tv == 'string' then return texto(v) end
  if tv == 'number' then return numero(v) end
  if tv == 'boolean' then
    if v then return 'true' end
    return 'false'
  end
  if tv ~= 'table' then return 'null' end
  local chaves, n = {}, 0
  for k in pairs(v) do
    n = n + 1
    chaves[n] = { s = tostring(k), k = k }
  end
  local lista = true
  for i = 1, n do
    if v[i] == nil then lista = false; break end
  end
  local out = {}
  if lista then
    for i = 1, n do out[i] = valor(v[i]) end
    return '[' .. table.concat(out, ',') .. ']'
  end
  table.sort(chaves, function(a, b) return a.s < b.s end)
  for i, c in ipairs(chaves) do
    out[i] = texto(c.s) .. ':' .. valor(v[c.k])
  end
  return '{' .. table.concat(out, ',') .. '}'
end
__cfjson = valor
`;

// roda um texto Lua no estado; devolve null se rodou, ou o texto do erro
function rodar(L, texto, nome) {
  const bytes = to_luastring(texto);
  let st = lauxlib.luaL_loadbuffer(L, bytes, bytes.length, to_luastring('=' + nome));
  if (st === 0) st = lua.lua_pcall(L, 0, 0, 0);
  return st === 0 ? null : erroDoTopo(L);
}

// le o erro do topo da pilha e tira da pilha
function erroDoTopo(L) {
  const r = lua.lua_tostring(L, -1);
  const msg = r ? to_jsstring(r) : '(erro que nao e texto)';
  lua.lua_pop(L, 1);
  return msg;
}

// carrega o arquivo num estado novo e devolve a global como objeto JS
function ler(arquivo, global) {
  if (!existsSync(arquivo)) throw new Error('arquivo nao encontrado: ' + arquivo);
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  let erro = rodar(L, readFileSync(arquivo, 'utf8'), basename(arquivo));
  if (erro === null) erro = rodar(L, SERIALIZADOR, 'serializador');
  if (erro !== null) throw new Error('nao carregou ' + arquivo + ': ' + erro);
  const bytes = to_luastring('return __cfjson(' + global + ')');
  if (lauxlib.luaL_loadbuffer(L, bytes, bytes.length, to_luastring('=consulta')) !== 0) {
    throw new Error('nao serializou ' + arquivo + ': ' + erroDoTopo(L));
  }
  if (lua.lua_pcall(L, 0, 1, 0) !== 0) throw new Error('nao serializou ' + arquivo + ': ' + erroDoTopo(L));
  const json = to_jsstring(lua.lua_tostring(L, -1));
  lua.lua_pop(L, 1);
  if (json === 'null') throw new Error(global + ' nao foi definida em ' + arquivo);
  return JSON.parse(json);
}

function lerTexto(arquivo) {
  if (!existsSync(arquivo)) throw new Error('arquivo nao encontrado: ' + arquivo);
  return readFileSync(arquivo, 'utf8');
}

// utilitarios
const fmt = (v) => (v === undefined || v === null ? '-' : typeof v === 'object' ? JSON.stringify(v) : String(v));
const itens = (o) => (Array.isArray(o) ? o : o && typeof o === 'object' ? Object.values(o) : []);
const chavesOrd = (o) => (o && typeof o === 'object' ? Object.keys(o).sort() : []);
const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
const pares = (o, excl = []) => chavesOrd(o).filter((k) => !excl.includes(k)).map((k) => `${k}=${fmt(o[k])}`).join(' ');

// conta os valores; as chaves de 'ordem' sempre aparecem, e 'sem' conta os nulos
function contar(valores, ordem) {
  const cont = new Map(ordem.map((k) => [k, 0]));
  let sem = 0;
  for (const v of valores) {
    if (v === undefined || v === null) { sem++; continue; }
    const k = String(v);
    cont.set(k, (cont.get(k) ?? 0) + 1);
  }
  const partes = [...cont].map(([k, n]) => `${k}=${n}`);
  if (sem) partes.push(`sem=${sem}`);
  return partes.join(' ');
}

const CAMPOS_DANO = ['dps', 'total', 'geral', 'duracao'];
const CAMPOS_AMEACA = ['estado', 'pct', 'tanque', 'geral', 'lider'];
const VALORES_CAMPO = ['secreto', 'legivel', 'nada'];
const FONTES = ['current', 'expired', 'nenhuma'];

function secaoCarga(d) {
  const linhas = [];
  const carga = d.diario?.carga;
  for (const p of chavesOrd(carga)) {
    const c = carga[p] ?? {};
    const tem = c.tem ?? {};
    const existe = chavesOrd(tem).filter((k) => tem[k] === true);
    const falta = chavesOrd(tem).filter((k) => tem[k] !== true);
    linhas.push(`[${p}]`);
    linhas.push(`  quando=${fmt(c.quando)} versao=${fmt(c.versao)} build=${fmt(c.build?.versao)} numero=${fmt(c.build?.numero)} interface=${fmt(c.build?.interface)}`);
    linhas.push(`  classe=${fmt(c.classe)} papel=${fmt(c.papel)} nome=${fmt(c.nome)}`);
    linhas.push(`  disponivel=${fmt(c.disponivel)} motivo=${fmt(c.motivo)}`);
    linhas.push(`  cvars: ${pares(c.cvar) || '-'}`);
    linhas.push(`  no cliente: ${existe.join(', ') || '-'}${falta.length ? ' | ausente: ' + falta.join(', ') : ''}`);
  }
  return linhas;
}

function secaoFormatos(d) {
  const linhas = [];
  const carga = d.diario?.carga;
  for (const p of chavesOrd(carga)) {
    const fs = itens(carga[p]?.formatos);
    if (!fs.length) continue;
    linhas.push(`[${p}]`);
    for (const f of fs) linhas.push(`  n=${fmt(f.n)} inteiro=${fmt(f.inteiro)} abrev=${fmt(f.abrev)} grande=${fmt(f.grande)}`);
  }
  return linhas;
}

function secaoLarguras(d) {
  const linhas = [];
  const carga = d.diario?.carga;
  for (const p of chavesOrd(carga)) {
    const l = carga[p]?.larguras;
    if (!l) continue;
    linhas.push(`[${p}] ${pares(l) || '-'}`);
  }
  return linhas;
}

function secaoLutas(d) {
  const lutas = itens(d.diario?.lutas);
  if (!lutas.length) return [];
  const grupos = new Map();
  for (const l of lutas) {
    const chave = `${fmt(l.zona)} | instancia=${fmt(l.instancia)} | chefe=${fmt(l.chefe)}`;
    if (!grupos.has(chave)) grupos.set(chave, []);
    grupos.get(chave).push(l);
  }
  const linhas = [`quantas: ${lutas.length}`];
  for (const [chave, g] of [...grupos].sort((a, b) => cmp(a[0], b[0]))) {
    const tent = g.map((l) => l.resumo?.tentativas).filter((x) => typeof x === 'number');
    const media = tent.length ? (tent.reduce((a, b) => a + b, 0) / tent.length).toFixed(2) : '-';
    const soma = (campo) => g.reduce((a, l) => a + (typeof l[campo] === 'number' ? l[campo] : 0), 0);
    linhas.push(`[${chave}] lutas=${g.length}`);
    for (const c of CAMPOS_DANO) linhas.push(`  dano.${c}: ${contar(g.map((l) => l.dano?.[c]), VALORES_CAMPO)}`);
    for (const c of CAMPOS_AMEACA) linhas.push(`  ameaca.${c}: ${contar(g.map((l) => l.ameaca?.[c]), VALORES_CAMPO)}`);
    linhas.push(`  resumo: media de tentativas=${media} | fonte: ${contar(g.map((l) => l.resumo?.fonte), FONTES)}`);
    linhas.push(`  pulsos=${soma('pulsos')} eventosDano=${soma('eventosDano')} eventosAmeaca=${soma('eventosAmeaca')}`);
  }
  return linhas;
}

function secaoAvulsas(d) {
  const av = itens(d.diario?.avulsas);
  if (!av.length) return [];
  const porTipo = new Map();
  for (const a of av) {
    const t = fmt(a.tipo);
    porTipo.set(t, (porTipo.get(t) ?? 0) + 1);
  }
  const tipos = [...porTipo].sort((a, b) => cmp(a[0], b[0])).map(([t, n]) => `${t}=${n}`).join(' ');
  const linhas = [`total: ${av.length}`, `por tipo: ${tipos}`, 'cinco mais recentes:'];
  const recentes = [...av].sort((a, b) => cmp(String(b.quando ?? ''), String(a.quando ?? ''))).slice(0, 5);
  for (const a of recentes) linhas.push(`  ${fmt(a.quando)} ${fmt(a.tipo)} ${pares(a, ['quando', 'tipo'])}`);
  return linhas;
}

function secaoPersonagens(d) {
  const linhas = [];
  const pers = d.personagens;
  for (const n of chavesOrd(pers)) {
    const p = pers[n] ?? {};
    linhas.push(`[${n}]`);
    linhas.push(`  ultima: ${pares(p.ultima) || '-'}`);
    linhas.push(`  cvarAntes=${fmt(p.cvarAntes)} nativaVisivel=${fmt(p.nativaVisivel)} coletaSemJanela=${fmt(p.coletaSemJanela)} semLinha=${fmt(p.semLinha)} reservaFeita=${fmt(p.reservaFeita)}`);
  }
  return linhas;
}

function secaoLog(d) {
  return itens(d.log).slice(-10).map(String);
}

function secaoBug(bugDb) {
  const tem = (s) => String(s ?? '').includes('CentralForever');
  const erros = itens(bugDb.errors).filter((e) => tem(e?.message) || tem(e?.stack));
  if (!erros.length) return ['nenhum erro com CentralForever'];
  const linhas = [`${erros.length} erro(s) com CentralForever`];
  for (const e of erros) {
    linhas.push(`- time=${fmt(e.time)} counter=${fmt(e.counter)}`);
    for (const l of String(e.message ?? '').split(/\r?\n/).slice(0, 2)) linhas.push(`    ${l}`);
  }
  return linhas;
}

function secaoTaint(texto) {
  const achadas = texto.split(/\r?\n/).filter((l) => l.includes('CentralForever'));
  if (!achadas.length) return ['nenhuma linha com CentralForever'];
  const linhas = achadas.slice(0, 40);
  if (achadas.length > 40) linhas.push(`(mais ${achadas.length - 40} linhas nao mostradas)`);
  return linhas;
}

// main
const args = process.argv.slice(2);
const opc = {};
for (let i = 0; i < args.length; i++) {
  if (['--sv', '--bug', '--taint'].includes(args[i]) && i + 1 < args.length) opc[args[i].slice(2)] = args[++i];
  else { console.error(USO); process.exit(2); }
}
if (!opc.sv) { console.error(USO); process.exit(2); }

let d;
let bugDb = null;
let taint = null;
try {
  d = ler(opc.sv, 'CentralForeverDB');
  if (opc.bug) bugDb = ler(opc.bug, 'BugGrabberDB');
  if (opc.taint) taint = lerTexto(opc.taint);
} catch (e) {
  console.error('erro: ' + e.message);
  process.exit(1);
}

const secoes = [
  ['Carga', secaoCarga(d)],
  ['Formatos', secaoFormatos(d)],
  ['Larguras', secaoLarguras(d)],
  ['Lutas', secaoLutas(d)],
  ['Avulsas', secaoAvulsas(d)],
  ['Personagens', secaoPersonagens(d)],
  ['Log', secaoLog(d)],
];
if (bugDb !== null) secoes.push(['Erros do BugGrabber', secaoBug(bugDb)]);
if (taint !== null) secoes.push(['Taint', secaoTaint(taint)]);

for (const [titulo, linhas] of secoes) {
  console.log('== ' + titulo + ' ==');
  for (const l of linhas.length ? linhas : ['(vazio)']) console.log(l);
  console.log('');
}
process.exit(0);
