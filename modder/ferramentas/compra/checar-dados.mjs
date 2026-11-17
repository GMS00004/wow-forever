// Relê addons-proprios/CompraForever/Dados.lua no fengari (Lua 5.3) e confere o contrato (secao 2).
// Uso: node ferramentas/compra/checar-dados.mjs
// Codigo 0 = ok; 1 = alguma falha (lista no stdout).
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const RAIZ = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const SAIDA = join(RAIZ, 'addons-proprios', 'CompraForever', 'Dados.lua');
const requireGuia = createRequire(join(RAIZ, 'ferramentas', 'guia', 'package.json'));
const fengari = requireGuia('fengari');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = fengari;

const falhas = [];
const falha = (msg) => falhas.push(msg);

// Carrega o Dados.lua e roda um serializador em Lua que devolve uma linha por entrada.
const texto = readFileSync(SAIDA, 'utf8');
if (/[^\x00-\x7f]/.test(texto)) {
  const n = (texto.match(/[^\x00-\x7f]/g) || []).length;
  falha(`(e) ${n} caractere(s) fora do ASCII`);
}

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const serializador = `
local o = {}
local d = CompraForeverDados
for k, r in pairs(d.receitas) do
  local rs = {}
  for _, p in ipairs(r.reagentes) do rs[#rs + 1] = p[1] .. ':' .. p[2] end
  o[#o + 1] = 'R|' .. k .. '|' .. tostring(r.produto) .. '|' .. tostring(r.qtd) .. '|' .. table.concat(rs, ',')
end
for k, i in pairs(d.itens) do
  o[#o + 1] = 'I|' .. k .. '|' .. tostring(i.vende) .. '|' .. tostring(i.pilha) .. '|' .. tostring(i.vendedor)
end
for k, v in pairs(d.fabrica) do o[#o + 1] = 'F|' .. k .. '|' .. tostring(v) end
__saida = table.concat(o, '\\n')
`;

let st = lauxlib.luaL_loadstring(L, to_luastring(texto + '\n' + serializador));
if (st !== lua.LUA_OK) {
  falha('carga do Dados.lua: ' + lua.lua_tojsstring(L, -1));
} else {
  st = lua.lua_pcall(L, 0, 0, 0);
  if (st !== lua.LUA_OK) falha('execucao do Dados.lua: ' + lua.lua_tojsstring(L, -1));
}

const receitas = new Map();
const itens = new Map();
const fabrica = new Map();
if (!falhas.length) {
  lua.lua_getglobal(L, to_luastring('__saida'));
  const linhas = lua.lua_tojsstring(L, -1).split('\n').filter(Boolean);
  for (const l of linhas) {
    const c = l.split('|');
    if (c[0] === 'R') {
      const reag = c[4] ? c[4].split(',').map((p) => p.split(':').map(Number)) : [];
      receitas.set(Number(c[1]), { produto: Number(c[2]), qtd: Number(c[3]), reagentes: reag.map(([id, qtd]) => ({ id, qtd })) });
    } else if (c[0] === 'I') {
      itens.set(Number(c[1]), { vende: Number(c[2]), pilha: Number(c[3]), vendedor: c[4] === 'nil' ? null : Number(c[4]) });
    } else if (c[0] === 'F') {
      fabrica.set(Number(c[1]), Number(c[2]));
    }
  }
}

if (!falhas.length) {
  // (a) receita 4096
  const r = receitas.get(4096);
  const esperado = [{ id: 4461, qtd: 6 }, { id: 4234, qtd: 4 }, { id: 2321, qtd: 2 }];
  if (!r) falha('(a) receita 4096 ausente');
  else {
    if (r.produto !== 4455) falha(`(a) produto da 4096 = ${r.produto}, esperado 4455`);
    if (r.qtd !== 1) falha(`(a) qtd da 4096 = ${r.qtd}, esperado 1`);
    const a = JSON.stringify(r.reagentes);
    if (a !== JSON.stringify(esperado)) falha(`(a) reagentes da 4096 = ${a}`);
  }

  // (b) vendedor de 2321 e ausencia em 4461
  const i2321 = itens.get(2321);
  if (!i2321) falha('(b) item 2321 ausente');
  else if (i2321.vendedor !== 100) falha(`(b) itens[2321].vendedor = ${i2321.vendedor}, esperado 100`);
  const i4461 = itens.get(4461);
  if (!i4461) falha('(b) item 4461 ausente');
  else if (i4461.vendedor !== null) falha(`(b) itens[4461].vendedor = ${i4461.vendedor}, esperado ausente`);

  // (c) todo reagente de toda receita existe em itens
  let semItem = 0;
  for (const [magia, rec] of receitas) {
    for (const g of rec.reagentes) {
      if (!itens.has(g.id)) { semItem++; falha(`(c) receita ${magia}: reagente ${g.id} ausente em itens`); }
    }
    if (!itens.has(rec.produto)) falha(`(c) receita ${magia}: produto ${rec.produto} ausente em itens`);
  }

  // (d) quantidade de receitas
  if (receitas.size < 314) falha(`(d) receitas = ${receitas.size}, esperado >= 314`);

  // (f) extra: fabrica aponta para receita existente
  for (const [item, magia] of fabrica) {
    if (!receitas.has(magia)) falha(`fabrica[${item}] = ${magia}: receita fora de receitas`);
  }

  console.log(`receitas=${receitas.size} itens=${itens.size} fabrica=${fabrica.size}`);
}

if (falhas.length) {
  console.log('checar-dados: FALHAS');
  for (const f of falhas) console.log('  ' + f);
  process.exit(1);
}
console.log('checar-dados: ok');
process.exit(0);
