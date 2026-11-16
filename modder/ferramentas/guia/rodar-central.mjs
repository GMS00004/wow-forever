// Bancada da central: roda um addon (CentralForever ou um de brinquedo) fora do jogo, no fengari (Lua 5.3),
// com a API do WoW simulada (bancada\api-central.lua), valores secretos (bancada\segredo.lua), os cenarios
// C01 a C34 (bancada\cenarios-central.lua) e os invariantes A0. Contrato: CONTRATO.md, secao 11.4.
//
// Uso: node rodar-central.mjs [--addon <pasta>] [--cenario <id>] [--matriz] [--listar] [--autoteste]
//   --addon      pasta do addon (padrao: ..\..\addons-proprios\CentralForever). Addon que nao e o CentralForever
//                roda so o roteiro generico (GEN) e os invariantes, sem as afirmacoes C01 a C34.
//   --cenario    so este cenario (ex.: C02)
//   --matriz     cada cenario com cada chave U1 a U10 trocada, uma por vez
//   --listar     lista os cenarios implementados
//   --autoteste  roda casos-central\minimo (tem de dar 0) e cada casos-central\mutante-* (tem de dar 1, citando o
//                invariante de esperado.txt); sai 0 so se todos se comportarem assim
// Saida: 0 sem falha; 1 com falha de invariante ou de afirmacao; 2 se um arquivo do addon nao carregou.
// Arquivos: visual\cache\central-<id>.json (arvore de quadros) e visual\cache\CentralForever-sv.lua (C02 e C03).
import { createRequire } from 'node:module';
import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync, statSync } from 'node:fs';
import { join, dirname, resolve, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { instrumentar } from './bancada/instrumentar.mjs';

const require = createRequire(import.meta.url);
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const aqui = dirname(fileURLToPath(import.meta.url));
const pastaCache = join(aqui, 'visual', 'cache');
const pastaCasos = join(aqui, 'casos-central');

// ---------- argumentos ----------
const argv = process.argv.slice(2);
function valorDe(flag) {
  const i = argv.indexOf(flag);
  return i >= 0 ? argv[i + 1] : undefined;
}
const opAddon = valorDe('--addon');
const opCenario = valorDe('--cenario');
const opMatriz = argv.includes('--matriz');
const opListar = argv.includes('--listar');
const opAuto = argv.includes('--autoteste');
const addonPadrao = resolve(aqui, '..', '..', 'addons-proprios', 'CentralForever');

// ---------- textos Lua da bancada ----------
const textoSegredo = readFileSync(join(aqui, 'bancada', 'segredo.lua'), 'utf8');
const textoApi = readFileSync(join(aqui, 'bancada', 'api-central.lua'), 'utf8');
const textoCenarios = readFileSync(join(aqui, 'bancada', 'cenarios-central.lua'), 'utf8');
const textoWidget = readFileSync(join(aqui, 'api-forever', 'WidgetAPI.lua'), 'utf8');

// ---------- ponte com o fengari ----------
function rodarChunk(L, texto, nomeChunk) {
  const bytes = to_luastring(texto);
  let st = lauxlib.luaL_loadbuffer(L, bytes, bytes.length, to_luastring('=' + nomeChunk));
  if (st === 0) st = lua.lua_pcall(L, 0, 0, 0);
  if (st === 0) return { ok: true, erro: '' };
  const r = lua.lua_tostring(L, -1);
  const erro = r ? to_jsstring(r) : '(erro que nao e texto)';
  lua.lua_pop(L, 1);
  return { ok: false, erro };
}

// roda um trecho que devolve um texto
function chamarTexto(L, trecho) {
  const bytes = to_luastring(trecho);
  let st = lauxlib.luaL_loadbuffer(L, bytes, bytes.length, to_luastring('=chamada'));
  if (st === 0) st = lua.lua_pcall(L, 0, 1, 0);
  const r = lua.lua_tostring(L, -1);
  const txt = r ? to_jsstring(r) : '';
  lua.lua_pop(L, 1);
  if (st !== 0) throw new Error(txt);
  return txt;
}

function globalTexto(L, nome, texto) {
  lua.lua_pushstring(L, to_luastring(texto));
  lua.lua_setglobal(L, to_luastring(nome));
}

function litLua(v) {
  if (typeof v === 'number') return String(v);
  if (typeof v === 'boolean') return v ? 'true' : 'false';
  return JSON.stringify(String(v));
}

function globalArquivos(L, arquivos) {
  lua.lua_createtable(L, arquivos.length, 0);
  arquivos.forEach((a, i) => {
    lua.lua_createtable(L, 0, 2);
    lua.lua_pushstring(L, to_luastring(a.nome));
    lua.lua_setfield(L, -2, to_luastring('nome'));
    lua.lua_pushstring(L, to_luastring(a.texto));
    lua.lua_setfield(L, -2, to_luastring('texto'));
    lua.lua_rawseti(L, -2, i + 1);
  });
  lua.lua_setglobal(L, to_luastring('__ARQUIVOS'));
}

function novoEstado(opcoes, arquivos) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  globalTexto(L, '__WIDGET_TEXTO', textoWidget);
  const chaves = Object.entries(opcoes.chaves || {}).map(([k, v]) => `${k}=${litLua(v)}`).join(',');
  const src = `__OPCOES = { id = ${litLua(opcoes.id || '')}, generico = ${opcoes.generico ? 'true' : 'false'}, chaves = { ${chaves} } }`;
  for (const [txt, nome] of [[src, 'opcoes'], [textoSegredo, 'segredo'], [textoApi, 'api-central'], [textoCenarios, 'cenarios-central']]) {
    const r = rodarChunk(L, txt, nome);
    if (!r.ok) throw new Error(`${nome}: ${r.erro}`);
  }
  if (arquivos) globalArquivos(L, arquivos);
  return L;
}

// ---------- addon ----------
function lerAddon(pasta) {
  const tocs = readdirSync(pasta).filter((f) => f.toLowerCase().endsWith('.toc'));
  if (tocs.length === 0) return { erro: `sem .toc em ${pasta}` };
  const toc = tocs[0];
  const nomeToc = toc.replace(/\.toc$/i, '');
  const linhas = readFileSync(join(pasta, toc), 'utf8').split(/\r?\n/).map((l) => l.trim()).filter((l) => l && !l.startsWith('#'));
  const lista = linhas.filter((l) => /\.lua$/i.test(l));
  const arquivos = [];
  const cargaFalhou = [];
  for (const nome of lista) {
    const caminho = join(pasta, nome.replace(/\\/g, '/'));
    if (!existsSync(caminho)) { cargaFalhou.push(`${nome}: arquivo do .toc nao existe`); continue; }
    try {
      arquivos.push({ nome: basename(nome), texto: instrumentar(readFileSync(caminho, 'utf8'), nome) });
    } catch (e) {
      cargaFalhou.push(`${nome}: ${e.message}`);
    }
  }
  return { nomeToc, arquivos, cargaFalhou };
}

// ---------- cenarios ----------
let listaCache = null;
function listaDeCenarios() {
  if (listaCache) return listaCache;
  const L = novoEstado({ id: 'C01' }, null);
  const txt = chamarTexto(L, 'return __cenarios.listar()');
  listaCache = txt.split('\n').filter(Boolean).map((l) => {
    const m = /^(\S+)\s+(.*)$/.exec(l);
    return { id: m[1], titulo: m[2] };
  });
  return listaCache;
}

const PADRAO_U = { U1: 'erro', U2: 'campos', U3: 'secreta', U4: 'legivel', U5: 'secreta', U6: 'nada', U7: 'dono', U8: 0.6, U9: 'coleta', U10: 'existe' };
const ALTERNATIVAS_U = { U1: ['aceita'], U2: ['inacessivel'], U3: ['legivel'], U4: ['secreto'], U5: ['legivel'], U6: ['valores'], U7: ['propria'], U8: [0, 5], U9: ['naocoleta'], U10: ['nao'] };

// roda um cenario num estado novo; devolve o resultado do Lua (ou um resultado de erro da bancada)
function rodarCenario(addon, id, generico, chaves) {
  const L = novoEstado({ id, generico, chaves }, addon.arquivos);
  try {
    const txt = chamarTexto(L, 'return __bancada.executar()');
    return JSON.parse(txt);
  } catch (e) {
    return { id, falhas: [{ inv: 'BANCADA', msg: 'erro da bancada: ' + String(e.message).split('\n')[0] }], cargaFalhou: [], naoSimuladas: [], fotos: [], final: [], sv: '' };
  }
}

function resumoFalhas(r) {
  const vistos = new Set();
  const itens = [];
  for (const f of r.falhas || []) {
    const m = f.msg.length > 240 ? f.msg.slice(0, 237) + '...' : f.msg;
    if (!vistos.has(m)) { vistos.add(m); itens.push(m); }
  }
  return itens;
}

function gravarSaidas(r) {
  mkdirSync(pastaCache, { recursive: true });
  const saida = { id: r.id, titulo: r.titulo, chaves: r.chaves, tFinal: r.tFinal, fotos: r.fotos, final: r.final, chat: r.chat, avisos: r.avisos, falhas: r.falhas };
  writeFileSync(join(pastaCache, `central-${r.id}.json`), JSON.stringify(saida, null, 1) + '\n');
  if (r.id === 'C02' || r.id === 'C03') writeFileSync(join(pastaCache, 'CentralForever-sv.lua'), r.sv);
}

// roda todos os cenarios de um addon e devolve as execucoes
// opcoes: { cenario, matriz, imprimir, gravar }
function rodarAddon(pasta, opcoes) {
  const addon = lerAddon(pasta);
  if (addon.erro) return { erroFatal: addon.erro, execucoes: [], carga: [] };
  const central = addon.nomeToc === 'CentralForever';
  let ids = central ? listaDeCenarios().map((c) => c.id).filter((i) => i !== 'GEN') : ['GEN'];
  if (opcoes.cenario) {
    if (!listaDeCenarios().some((c) => c.id === opcoes.cenario)) return { erroFatal: `cenario inexistente: ${opcoes.cenario}`, execucoes: [], carga: [] };
    ids = ids.filter((i) => i === opcoes.cenario);
    if (ids.length === 0) ids = [opcoes.cenario];
  }
  const execucoes = [];
  if (addon.cargaFalhou.length) {
    if (opcoes.imprimir) for (const c of addon.cargaFalhou) console.log(`CARGA ${c}`);
    return { execucoes, carga: addon.cargaFalhou, central };
  }
  const variantes = [{ rotulo: '', chaves: {} }];
  if (opcoes.matriz) {
    for (const [k, alts] of Object.entries(ALTERNATIVAS_U)) for (const v of alts) variantes.push({ rotulo: `${k}=${v}`, chaves: { [k]: v } });
  }
  const generico = !central;
  for (const id of ids) {
    for (const v of opcoes.matriz ? variantes : variantes.slice(0, 1)) {
      const r = rodarCenario(addon, id, generico, v.chaves);
      r.rotulo = v.rotulo;
      execucoes.push(r);
      if (r.cargaFalhou && r.cargaFalhou.length) {
        if (opcoes.imprimir) for (const c of r.cargaFalhou) console.log(`CARGA ${c}`);
        return { execucoes, carga: r.cargaFalhou, central };
      }
      const falhas = resumoFalhas(r);
      if (opcoes.imprimir) {
        const nome = v.rotulo ? `${id} ${v.rotulo}` : id;
        console.log(falhas.length ? `FALHA ${nome}: ${falhas.join('; ')}` : `ok    ${nome}`);
      }
      if (opcoes.gravar && !v.rotulo) gravarSaidas(r);
    }
  }
  return { execucoes, carga: [], central };
}

// ---------- modos ----------
if (opListar) {
  const lista = listaDeCenarios();
  for (const c of lista) console.log(`${c.id}  ${c.titulo}`);
  console.log(`${lista.length} cenarios implementados (C01 a C34 so rodam no CentralForever; GEN roda nos addons de brinquedo)`);
  process.exit(0);
}

if (opAuto) {
  let falhas = 0;
  const confere = (cond, texto) => {
    console.log(`${cond ? 'ok   ' : 'FALHA'} autoteste ${texto}`);
    if (!cond) falhas++;
  };
  const pastaMinimo = join(pastaCasos, 'minimo');
  {
    const r = rodarAddon(pastaMinimo, { imprimir: false });
    const msgs = r.execucoes.flatMap(resumoFalhas);
    confere(!r.erroFatal && r.carga.length === 0 && msgs.length === 0, `minimo (esperado 0 falhas${msgs.length ? '; veio: ' + msgs.join('; ') : ''}${r.carga.length ? '; carga: ' + r.carga.join('; ') : ''}${r.erroFatal ? '; ' + r.erroFatal : ''})`);
  }
  const mutantes = existsSync(pastaCasos) ? readdirSync(pastaCasos).filter((d) => d.startsWith('mutante-') && statSync(join(pastaCasos, d)).isDirectory()).sort() : [];
  if (mutantes.length === 0) { console.log('FALHA autoteste: nenhum mutante em casos-central'); falhas++; }
  for (const d of mutantes) {
    const arq = join(pastaCasos, d, 'esperado.txt');
    const esperado = existsSync(arq) ? readFileSync(arq, 'utf8').trim() : '';
    if (!esperado) { confere(false, `${d} (falta esperado.txt)`); continue; }
    const r = rodarAddon(join(pastaCasos, d), { imprimir: false });
    const msgs = r.execucoes.flatMap(resumoFalhas);
    const cita = msgs.some((m) => m.startsWith(esperado + ':'));
    confere(!r.erroFatal && r.carga.length === 0 && msgs.length > 0 && cita,
      `${d} (esperado ${esperado}${cita ? '' : '; veio: ' + (msgs.join('; ') || (r.carga.join('; ') || r.erroFatal || 'nada'))})`);
  }
  console.log(falhas ? `AUTOTESTE: ${falhas} problema(s)` : 'AUTOTESTE: o minimo passa e cada mutante e acusado pelo invariante certo');
  process.exit(falhas ? 1 : 0);
}

// ---------- execucao normal ----------
const pastaAddon = opAddon ? resolve(process.cwd(), opAddon) : addonPadrao;
const res = rodarAddon(pastaAddon, { cenario: opCenario, matriz: opMatriz, imprimir: true, gravar: true });
if (res.erroFatal) {
  console.log(`ERRO: ${res.erroFatal}`);
  process.exit(2);
}
const porInv = {};
let comFalha = 0;
const naoSim = new Set();
for (const r of res.execucoes) {
  const falhas = resumoFalhas(r);
  if (falhas.length) comFalha++;
  for (const f of r.falhas || []) {
    const inv = f.inv || '?';
    porInv[inv] = (porInv[inv] || 0) + 1;
  }
  for (const n of r.naoSimuladas || []) naoSim.add(n);
}
const total = res.execucoes.length;
if (naoSim.size) console.log(`NAO SIMULADAS (lidas pelo addon e ausentes no ambiente): ${[...naoSim].sort().join(', ')}`);
if (res.carga.length) {
  console.log(`RESUMO: o addon nao carregou (${res.carga.length} arquivo(s)); nenhum cenario rodou`);
  process.exit(2);
}
const invs = Object.keys(porInv).sort().map((k) => `${k}=${porInv[k]}`).join(' ');
console.log(`RESUMO: ${total} execucoes, ${total - comFalha} ok, ${comFalha} com falha${invs ? ` (mensagens por tipo: ${invs})` : ''}`);
process.exit(comFalha ? 1 : 0);
