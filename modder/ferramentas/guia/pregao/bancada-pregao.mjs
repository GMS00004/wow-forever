// Bancada do PregaoForever: roda o addon (ou o brinquedo) fora do jogo, no fengari (Lua 5.3), contra um falso da API do WoW
// com casa de leilao, throttle, dinheiro, bolsas, correio, relogio controlado e bindings (pregao\bancada\*.lua).
// Contrato: addons-proprios\PregaoForever\ARQUITETURA.md, secao 5.
//
// Uso: node pregao/bancada-pregao.mjs [--addon <pasta>] [--auto-teste] [--cenarios <grupo>] [--cenario <id>] [--injecoes]
//   --addon       pasta do addon (padrao: ..\..\addons-proprios\PregaoForever; no --auto-teste, o brinquedo)
//   --auto-teste  roda casos-pregao\cenarios\autoteste contra casos-pregao\brinquedo (so confere o falso)
//   --cenarios    roda os cenarios de casos-pregao\cenarios\<grupo>\*.lua
//   --cenario     roda so este (arquivo <id>.lua ou campo id), em qualquer grupo (ou no grupo dado por --cenarios)
//   --injecoes    lista os nomes aceitos pelo passo `injetar`
// Saida: uma linha `OK <id>` ou `FALHA <id>: <motivo>` por cenario e `RESUMO cenarios=<n> erros=<e>`.
// Codigo: 0 sem erro; 1 com cenario reprovado; 2 se um arquivo do addon nao carregou.
// Cenario com `esperado_falha = true` (ou um trecho do motivo) deve reprovar: conta OK se reprovar, erro se passar.
import { createRequire } from 'node:module';
import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync, statSync } from 'node:fs';
import { join, dirname, resolve, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const aqui = dirname(fileURLToPath(import.meta.url));
const guia = resolve(aqui, '..');
const modder = resolve(guia, '..', '..');
const pastaFalso = join(aqui, 'bancada');
const pastaCenarios = join(guia, 'casos-pregao', 'cenarios');
const pastaBrinquedo = join(guia, 'casos-pregao', 'brinquedo');
const pastaSaidas = join(modder, 'dados', 'pregao', 'bancada');
const addonPadrao = join(modder, 'addons-proprios', 'PregaoForever');

const argv = process.argv.slice(2);
const valorDe = (flag) => { const i = argv.indexOf(flag); return i >= 0 ? argv[i + 1] : undefined; };
const opAddon = valorDe('--addon');
const opAuto = argv.includes('--auto-teste');
const opGrupo = valorDe('--cenarios');
const opCenario = valorDe('--cenario');
const opInjecoes = argv.includes('--injecoes');

// ---------- ponte com o fengari ----------
function rodarChunk(L, texto, nomeChunk, nres = 0) {
  const bytes = to_luastring(texto);
  let st = lauxlib.luaL_loadbuffer(L, bytes, bytes.length, to_luastring('=' + nomeChunk));
  if (st === 0) st = lua.lua_pcall(L, 0, nres, 0);
  if (st === 0) {
    if (nres === 0) return { ok: true, valor: '' };
    const r = lua.lua_tostring(L, -1);
    const v = r ? to_jsstring(r) : '';
    lua.lua_pop(L, 1);
    return { ok: true, valor: v };
  }
  const r = lua.lua_tostring(L, -1);
  const erro = r ? to_jsstring(r) : '(erro que nao e texto)';
  lua.lua_pop(L, 1);
  return { ok: false, erro };
}

function globalArquivos(L, arquivos) {
  lua.lua_createtable(L, 0, 1);
  lua.lua_createtable(L, arquivos.length, 0);
  arquivos.forEach((a, i) => {
    lua.lua_createtable(L, 0, 2);
    lua.lua_pushstring(L, to_luastring(a.nome));
    lua.lua_setfield(L, -2, to_luastring('nome'));
    lua.lua_pushstring(L, to_luastring(a.texto));
    lua.lua_setfield(L, -2, to_luastring('texto'));
    lua.lua_rawseti(L, -2, i + 1);
  });
  lua.lua_setfield(L, -2, to_luastring('arquivos'));
  lua.lua_setglobal(L, to_luastring('__ADDON'));
}

function globalTexto(L, nome, texto) {
  lua.lua_pushstring(L, to_luastring(texto));
  lua.lua_setglobal(L, to_luastring(nome));
}

const textosFalso = ['nucleo.lua', 'leilao.lua', 'executor.lua'].map((n) => ({ nome: n.replace(/\.lua$/, ''), texto: readFileSync(join(pastaFalso, n), 'utf8') }));

function novoEstado(arquivos) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  for (const f of textosFalso.slice(0, 2)) {
    const r = rodarChunk(L, f.texto, f.nome);
    if (!r.ok) throw new Error(`${f.nome}: ${r.erro}`);
  }
  globalArquivos(L, arquivos);
  const r = rodarChunk(L, textosFalso[2].texto, textosFalso[2].nome);
  if (!r.ok) throw new Error(`${textosFalso[2].nome}: ${r.erro}`);
  return L;
}

// ---------- addon ----------
function lerAddon(pasta) {
  if (!existsSync(pasta)) return { erro: `pasta do addon nao existe: ${pasta}` };
  const tocs = readdirSync(pasta).filter((f) => f.toLowerCase().endsWith('.toc'));
  if (tocs.length === 0) return { erro: `sem .toc em ${pasta}` };
  const linhas = readFileSync(join(pasta, tocs[0]), 'utf8').split(/\r?\n/).map((l) => l.trim()).filter((l) => l && !l.startsWith('#'));
  const arquivos = [];
  const cargaFalhou = [];
  for (const nome of linhas.filter((l) => /\.lua$/i.test(l))) {
    const caminho = join(pasta, nome.replace(/\\/g, '/'));
    if (!existsSync(caminho)) { cargaFalhou.push(`${nome}: arquivo do .toc nao existe`); continue; }
    arquivos.push({ nome: basename(nome), texto: readFileSync(caminho, 'utf8') });
  }
  return { arquivos, cargaFalhou };
}

// ---------- cenarios ----------
function arquivosDoGrupo(grupo) {
  const pasta = join(pastaCenarios, grupo);
  if (!existsSync(pasta) || !statSync(pasta).isDirectory()) return [];
  return readdirSync(pasta).filter((f) => f.toLowerCase().endsWith('.lua')).sort().map((f) => join(pasta, f));
}
function todosOsGrupos() {
  if (!existsSync(pastaCenarios)) return [];
  return readdirSync(pastaCenarios).filter((d) => statSync(join(pastaCenarios, d)).isDirectory()).sort();
}

// roda um arquivo de cenario num estado novo
function rodarArquivo(addon, arquivo) {
  const texto = readFileSync(arquivo, 'utf8');
  let L;
  try {
    L = novoEstado(addon.arquivos);
  } catch (e) {
    return { status: 'bancada', motivo: `erro da bancada: ${e.message}`, saidas: [], nao_simuladas: [], carga: [] };
  }
  globalTexto(L, '__CENARIO_TEXTO', texto);
  globalTexto(L, '__CENARIO_NOME', basename(arquivo));
  const r = rodarChunk(L, 'return __bancada.rodar(__CENARIO_TEXTO, __CENARIO_NOME)', 'rodar', 1);
  if (!r.ok) return { status: 'bancada', motivo: `erro da bancada: ${String(r.erro).split('\n')[0]}`, saidas: [], nao_simuladas: [], carga: [] };
  try {
    return JSON.parse(r.valor);
  } catch (e) {
    return { status: 'bancada', motivo: `resposta ilegivel da bancada: ${e.message}`, saidas: [], nao_simuladas: [], carga: [] };
  }
}

function gravarSaidas(saidas) {
  if (!saidas || saidas.length === 0) return;
  mkdirSync(pastaSaidas, { recursive: true });
  for (const s of saidas) writeFileSync(join(pastaSaidas, basename(s.nome)), s.texto);
}

function injecoes() {
  const L = novoEstado([]);
  const r = rodarChunk(L, 'return __bancada.listaDeInjecoes()', 'injecoes', 1);
  return r.ok ? r.valor : `(erro: ${r.erro})`;
}

// ---------- modos ----------
if (opInjecoes) {
  console.log(injecoes());
  process.exit(0);
}

let pastaAddon;
let arquivos = [];
if (opAuto) {
  pastaAddon = opAddon ? resolve(process.cwd(), opAddon) : pastaBrinquedo;
  arquivos = arquivosDoGrupo('autoteste');
  if (opCenario) arquivos = arquivos.filter((a) => basename(a, '.lua') === opCenario);
} else if (opGrupo !== undefined || opCenario !== undefined) {
  pastaAddon = opAddon ? resolve(process.cwd(), opAddon) : addonPadrao;
  const grupos = opGrupo !== undefined ? [opGrupo] : todosOsGrupos().filter((g) => g !== 'autoteste');
  arquivos = grupos.flatMap(arquivosDoGrupo);
  if (opCenario) arquivos = arquivos.filter((a) => basename(a, '.lua') === opCenario);
} else {
  console.log('uso: node pregao/bancada-pregao.mjs [--addon <pasta>] (--auto-teste | --cenarios <grupo> | --cenario <id>) [--injecoes]');
  console.log('RESUMO cenarios=0 erros=1');
  process.exit(1);
}

if (arquivos.length === 0) {
  const onde = opAuto ? 'autoteste' : (opGrupo !== undefined ? `o grupo ${opGrupo}` : 'os grupos');
  console.log(`NENHUM CENARIO para ${opCenario ? `o id ${opCenario} em ` : ''}${onde} (pasta ${pastaCenarios})`);
  console.log('RESUMO cenarios=0 erros=0');
  process.exit(0);
}

const addon = lerAddon(pastaAddon);
if (addon.erro) {
  console.log(`CARGA ${addon.erro}`);
  console.log('RESUMO cenarios=0 erros=1');
  process.exit(2);
}
if (addon.cargaFalhou.length) {
  for (const c of addon.cargaFalhou) console.log(`CARGA ${c}`);
  console.log(`RESUMO cenarios=0 erros=${addon.cargaFalhou.length}`);
  process.exit(2);
}

let erros = 0;
let cargaFalhou = false;
const naoSim = new Set();
for (const arq of arquivos) {
  const r = rodarArquivo(addon, arq);
  const id = r.id || basename(arq, '.lua');
  for (const n of r.nao_simuladas || []) naoSim.add(n);
  gravarSaidas(r.saidas);
  if (r.status === 'carga') {
    console.log(`CARGA ${id}: ${r.motivo}`);
    cargaFalhou = true;
    erros++;
    continue;
  }
  const esperado = r.esperado_falha;
  if (esperado) {
    const trecho = typeof esperado === 'string' ? esperado : '';
    if (r.status === 'falha' && (!trecho || String(r.motivo).includes(trecho))) {
      console.log(`OK ${id} (falhou como esperado: ${r.motivo})`);
    } else {
      console.log(`FALHA ${id}: devia reprovar${trecho ? ` com "${trecho}"` : ''} e ${r.status === 'falha' ? `reprovou por outro motivo: ${r.motivo}` : 'passou'}`);
      erros++;
    }
    continue;
  }
  if (r.status === 'ok') {
    console.log(`OK ${id}`);
  } else {
    console.log(`FALHA ${id}: ${r.motivo}`);
    erros++;
  }
}
if (naoSim.size) console.log(`NAO SIMULADAS (aceitas sem efeito pelo falso): ${[...naoSim].sort().join(', ')}`);
console.log(`RESUMO cenarios=${arquivos.length} erros=${erros}`);
process.exit(cargaFalhou ? 2 : (erros ? 1 : 0));
