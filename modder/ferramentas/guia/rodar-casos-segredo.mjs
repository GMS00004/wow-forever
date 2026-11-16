// Roda cada caso de casos-segredo\ num estado fengari novo, com bancada\segredo.lua e o caso reescrito
// por bancada\instrumentar.mjs. "erro-*.lua" tem de falhar com erro "bancada: ..." na linha marcada com
// "-- AQUI"; "ok-*.lua" tem de rodar sem erro e sem violacoes.
// Uso: node rodar-casos-segredo.mjs
import { createRequire } from 'node:module';
import { readFileSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { instrumentar } from './bancada/instrumentar.mjs';

const require = createRequire(import.meta.url);
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const aqui = dirname(fileURLToPath(import.meta.url));
const pastaCasos = join(aqui, 'casos-segredo');
const textoSegredo = readFileSync(join(aqui, 'bancada', 'segredo.lua'), 'utf8');

// carrega e roda um texto Lua; devolve { ok, erro }
function rodar(L, texto, nomeChunk) {
  const bytes = to_luastring(texto);
  let st = lauxlib.luaL_loadbuffer(L, bytes, bytes.length, to_luastring('=' + nomeChunk));
  if (st === 0) st = lua.lua_pcall(L, 0, 0, 0);
  if (st === 0) return { ok: true, erro: '' };
  const r = lua.lua_tostring(L, -1);
  const erro = r ? to_jsstring(r) : '(erro que nao e texto)';
  lua.lua_pop(L, 1);
  return { ok: false, erro };
}

// roda um trecho Lua que devolve um texto
function consultar(L, trecho) {
  const bytes = to_luastring(trecho);
  if (lauxlib.luaL_loadbuffer(L, bytes, bytes.length, to_luastring('=consulta')) !== 0 || lua.lua_pcall(L, 0, 1, 0) !== 0) {
    lua.lua_pop(L, 1);
    return '?';
  }
  const r = to_jsstring(lua.lua_tostring(L, -1));
  lua.lua_pop(L, 1);
  return r;
}

const arquivos = readdirSync(pastaCasos).filter((f) => f.endsWith('.lua')).sort();
let falhas = 0;
for (const arq of arquivos) {
  const nome = arq.replace(/\.lua$/, '');
  const original = readFileSync(join(pastaCasos, arq), 'utf8');
  const problemas = [];
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  const carga = rodar(L, textoSegredo, 'segredo');
  if (!carga.ok) { problemas.push('segredo.lua nao carregou: ' + carga.erro); }
  else {
    let reescrito = null;
    try { reescrito = instrumentar(original, arq); } catch (e) { problemas.push('instrumentar: ' + e.message); }
    if (reescrito !== null) {
      if (reescrito.split('\n').length !== original.split('\n').length) problemas.push('a reescrita mudou o numero de linhas');
      const r = rodar(L, reescrito, arq);
      if (nome.startsWith('erro-')) {
        const linhaAqui = original.split('\n').findIndex((l) => l.includes('-- AQUI')) + 1;
        if (r.ok) problemas.push('esperava erro e rodou sem erro');
        else if (!r.erro.startsWith('bancada: ')) problemas.push('erro nao comeca com "bancada: ": ' + r.erro);
        else if (linhaAqui === 0) problemas.push('caso sem a marca "-- AQUI"');
        else if (!r.erro.endsWith('(' + arq + ':' + linhaAqui + ')')) problemas.push('linha errada (esperava ' + linhaAqui + '): ' + r.erro);
      } else if (nome.startsWith('ok-')) {
        if (!r.ok) problemas.push('erro inesperado: ' + r.erro);
        else {
          const viol = consultar(L, 'return table.concat(__seg.violacoes, "; ")');
          if (viol !== '') problemas.push('violacoes: ' + viol);
        }
      } else problemas.push('nome fora da convencao (erro-* ou ok-*)');
    }
  }
  if (problemas.length) { falhas++; console.log(`FALHA ${nome}: ${problemas.join('; ')}`); }
  else console.log(`ok    ${nome}`);
}
console.log(falhas ? `${falhas} caso(s) com falha` : `todos os ${arquivos.length} casos como esperado`);
process.exit(falhas ? 1 : 0);
