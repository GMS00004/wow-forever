// Teste do Planejador.lua (CompraForever) no fengari. Uso: node ferramentas/compra/testar-planejador.mjs
// Saida: `FALHA <caso>: <motivo>` por falha e `casos=<n> erros=<e>`. Codigo 0 sem erro, 1 com erro.
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const aqui = dirname(fileURLToPath(import.meta.url));
const modder = resolve(aqui, '..', '..');
const require = createRequire(join(modder, 'ferramentas', 'guia', 'package.json'));
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);

function carregar(texto, nome, nargs, push) {
  const b = to_luastring(texto);
  let st = lauxlib.luaL_loadbuffer(L, b, b.length, to_luastring('=' + nome));
  if (st === 0) { push && push(); st = lua.lua_pcall(L, nargs, 1, 0); }
  if (st !== 0) { const r = lua.lua_tostring(L, -1); throw new Error(r ? to_jsstring(r) : 'erro'); }
  const r = lua.lua_tostring(L, -1);
  const v = r ? to_jsstring(r) : '';
  lua.lua_pop(L, 1);
  return v;
}

// ns e o serializador JSON (chaves ordenadas) ficam em globais do estado de teste
carregar(`
NS = {}
function SER(v)
  local t = type(v)
  if t == "nil" then return "null" end
  if t == "boolean" then return tostring(v) end
  if t == "number" then
    if v == math.floor(v) then return string.format("%d", v) end
    return string.format("%.14g", v)
  end
  if t == "string" then return '"' .. v:gsub('\\\\', '\\\\\\\\'):gsub('"', '\\\\"') .. '"' end
  if next(v) == nil then return "[]" end
  local n, c = #v, 0
  for _ in pairs(v) do c = c + 1 end
  local out = {}
  if n > 0 and n == c then
    for i = 1, n do out[i] = SER(v[i]) end
    return "[" .. table.concat(out, ",") .. "]"
  end
  local ks = {}
  for k in pairs(v) do ks[#ks + 1] = k end
  table.sort(ks, function(a, b) return tostring(a) < tostring(b) end)
  for i, k in ipairs(ks) do out[i] = SER(tostring(k)) .. ":" .. SER(v[k]) end
  return "{" .. table.concat(out, ",") .. "}"
end
return "ok"
`, 'prep', 0);

const fonte = readFileSync(join(modder, 'addons-proprios', 'CompraForever', 'Planejador.lua'), 'utf8');
carregar(fonte, 'Planejador.lua', 2, () => {
  lua.lua_pushstring(L, to_luastring('CompraForever'));
  lua.lua_getglobal(L, to_luastring('NS'));
});

// roda o corpo Lua (que devolve a entrada), planeja (uma ou duas vezes) e devolve o JSON
function planejar(luaEntrada, dobro) {
  const corpo = `
    local ent = (function() ${luaEntrada} end)()
    local a = SER(NS.planejar(ent))
    if ${dobro ? 'true' : 'false'} then return a .. "\\n#####\\n" .. SER(NS.planejar(ent)) end
    return a`;
  const t0 = performance.now();
  const s = carregar(corpo, 'caso', 0);
  const ms = performance.now() - t0;
  const partes = s.split('\n#####\n');
  return { plano: JSON.parse(partes[0]), textos: partes, ms };
}

// ---------- entradas ----------
// cabecalho comum: um produto 100 (vende 1000, pilha 20), reagente 10, receita 1 usa 2 do 10
const cab = (extra = '') => `
  local ent = { dinheiro = 1000000, espacos = 100, conhecidas = { [1] = true }, desconto = 0, lucroMin = 50,
    margemMin = 5, estoque = {},
    dados = { receitas = { [1] = { nome = "R1", produto = 100, qtd = 1, reagentes = { { 10, 2 } } } },
      itens = { [100] = { nome = "Prod", vende = 1000, pilha = 20 }, [10] = { nome = "Reag", pilha = 20 } } },
    escadas = {} }
  ${extra}
  return ent`;
const degraus = (lista, inteiro = false) =>
  '{ ' + lista.map(([p, q], i) => `{ preco = ${p}, qtd = ${q}, leilao = ${i + 1}, inteiro = ${inteiro} }`).join(', ') + ' }';

const casos = [];
const caso = (nome, luaEntrada, verifica, dobro = false) => casos.push({ nome, luaEntrada, verifica, dobro });
const craft = (p, m) => p.crafts.find((c) => c.magia === m);
const item = (lista, id) => lista.find((x) => x.id === id);

caso('P1 escada que sobe: para no lucroMin', cab(`
  ent.lucroMin = 450
  ent.escadas[10] = ${degraus([[100, 10], [200, 10], [300, 10], [500, 100]])}`), (p, e) => {
  const c = craft(p, 1);
  if (!c || c.n !== 10) e(`n=${c && c.n}, esperado 10`);
  if (p.motivo !== 'lucro') e(`motivo ${p.motivo}`);
  if (p.totais.gasto !== 3000) e(`gasto ${p.totais.gasto}, esperado 3000`);
  if (p.totais.lucro !== 7000) e(`lucro ${p.totais.lucro}, esperado 7000`);
});

caso('P2 dinheiro curto', cab(`
  ent.dinheiro = 1500
  ent.escadas[10] = ${degraus([[100, 10], [200, 10], [300, 10], [500, 100]])}`), (p, e) => {
  if (p.motivo !== 'dinheiro') e(`motivo ${p.motivo}`);
  if (p.totais.gasto > 1500) e(`gasto ${p.totais.gasto} > dinheiro`);
  const c = craft(p, 1);
  if (!c || c.n !== 6) e(`n=${c && c.n}, esperado 6`);
});

caso('P3 bolsas curtas (produto pilha 1)', cab(`
  ent.espacos = 5
  ent.dados.itens[100].pilha = 1
  ent.escadas[10] = ${degraus([[100, 1000]])}`), (p, e) => {
  if (p.motivo !== 'espaco') e(`motivo ${p.motivo}`);
  if (p.totais.espacos > 5) e(`espacos ${p.totais.espacos} > 5`);
  const c = craft(p, 1);
  if (!c || c.n !== 4) e(`n=${c && c.n}, esperado 4`);
});

caso('P4 reagente compartilhado: maior lucro leva o barato', `
  return { dinheiro = 1000000, espacos = 100, conhecidas = { [1] = true, [2] = true }, desconto = 0,
    lucroMin = 50, margemMin = 5, estoque = {},
    dados = { receitas = {
        [1] = { nome = "A", produto = 100, qtd = 1, reagentes = { { 10, 2 } } },
        [2] = { nome = "B", produto = 101, qtd = 1, reagentes = { { 10, 1 } } } },
      itens = { [100] = { nome = "PA", vende = 1200 }, [101] = { nome = "PB", vende = 900 }, [10] = { nome = "X" } } },
    escadas = { [10] = ${degraus([[100, 5]])} } }`, (p, e) => {
  const a = craft(p, 1), b = craft(p, 2);
  if (!a || a.n !== 2) e(`A n=${a && a.n}, esperado 2`);
  if (!b || b.n !== 1) e(`B n=${b && b.n}, esperado 1`);
  if (a && a.custo !== 400) e(`A custo ${a.custo}, esperado 400`);
  if (p.crafts[0] && p.crafts[0].magia !== 1) e('A nao veio primeiro');
  const l = item(p.leilao, 10);
  if (!l || l.qtd !== 5) e('leilao do 10 deveria ter 5');
});

caso('P5 degrau inteiro: lote cobrado, resto vai para os seguintes', cab(`
  ent.dados.receitas[1].reagentes = { { 10, 6 } }
  ent.escadas[10] = ${degraus([[100, 20], [100, 20]], true)}`), (p, e) => {
  const c = craft(p, 1);
  if (!c || c.n !== 6) e(`n=${c && c.n}, esperado 6`);
  if (p.totais.gasto !== 4000) e(`gasto ${p.totais.gasto}, esperado 4000 (dois lotes)`);
  const l = item(p.leilao, 10);
  if (!l || l.qtd !== 40 || l.inteiro !== true || l.lotes.length !== 2) e('leilao deveria ter 2 lotes inteiros, 40 un');
  const s = item(p.sobra, 10);
  if (!s || s.qtd !== 4) e(`sobra ${s && s.qtd}, esperado 4`);
  if (p.totais.lucro !== 2000) e(`lucro ${p.totais.lucro}, esperado 2000`);
});

caso('P6 estoque antes do leilao, sem gastar dinheiro', cab(`
  ent.dinheiro = 400
  ent.estoque[10] = 4
  ent.escadas[10] = ${degraus([[100, 100]])}`), (p, e) => {
  const d = item(p.doEstoque, 10);
  if (!d || d.qtd !== 4) e(`doEstoque ${d && d.qtd}, esperado 4`);
  const c = craft(p, 1);
  if (!c || c.n !== 4) e(`n=${c && c.n}, esperado 4`);
  if (p.totais.gasto !== 400) e(`gasto ${p.totais.gasto}, esperado 400`);
  const l = item(p.leilao, 10);
  if (!l || l.qtd !== 4) e('leilao deveria comprar so 4');
  if (p.totais.lucro !== 3200) e(`lucro ${p.totais.lucro}, esperado 3200 (4000-400-400)`);
  if (p.motivo !== 'dinheiro') e(`motivo ${p.motivo}`);
});

caso('P7 vendedor com desconto 10', cab(`
  ent.desconto = 10
  ent.dinheiro = 940
  ent.dados.itens[10].vendedor = 105`), (p, e) => {
  const v = item(p.vendedor, 10);
  if (!v) { e('sem vendedor'); return; }
  if (v.qtd !== 10) e(`qtd ${v.qtd}, esperado 10`);
  if (v.custo !== 10 * Math.floor(105 * 90 / 100)) e(`custo ${v.custo}, esperado 940`);
  if (p.leilao.length !== 0) e('nao deveria comprar no leilao');
  if (p.motivo !== 'dinheiro') e(`motivo ${p.motivo}`);
});

caso('P8 fabricar mais barato que o leilao', `
  return { dinheiro = 1000, espacos = 100, conhecidas = { [1] = true, [2] = true }, desconto = 0,
    lucroMin = 50, margemMin = 5, estoque = {},
    dados = { receitas = {
        [1] = { nome = "Final", produto = 100, qtd = 1, reagentes = { { 20, 1 } } },
        [2] = { nome = "Inter", produto = 20, qtd = 1, reagentes = { { 30, 3 } } } },
      itens = { [100] = { nome = "PF", vende = 2000 }, [20] = { nome = "Inter" }, [30] = { nome = "Cru" } },
      fabrica = { [20] = 2 } },
    escadas = { [20] = ${degraus([[1000, 50]])}, [30] = ${degraus([[100, 100]])} } }`, (p, e) => {
  const f = p.fabricar.find((x) => x.magia === 2);
  if (!f || f.n !== 3) e(`fabricar n=${f && f.n}, esperado 3`);
  const cru = item(p.leilao, 30);
  if (!cru || cru.qtd !== 9) e(`cru qtd ${cru && cru.qtd}, esperado 9`);
  if (item(p.leilao, 20)) e('nao deveria comprar o intermediario');
  const c = craft(p, 1);
  if (!c || c.n !== 3) e(`n=${c && c.n}, esperado 3`);
  if (p.totais.gasto > 1000) e('gasto acima do dinheiro');
});

caso('P9 revenda abaixo do preco', `
  return { dinheiro = 1000000, espacos = 100, conhecidas = {}, desconto = 0, lucroMin = 10, margemMin = 5,
    estoque = {}, dados = { receitas = {}, itens = { [50] = { nome = "Barato", pilha = 1 } } },
    revenda = { [50] = 150 },
    escadas = { [50] = ${degraus([[80, 5], [90, 5], [200, 5]])} } }`, (p, e) => {
  if (p.crafts.length !== 0) e('crafts deveria ser vazio');
  const r = item(p.revenda, 50);
  if (!r) { e('sem revenda'); return; }
  if (r.qtd !== 10) e(`qtd ${r.qtd}, esperado 10`);
  if (r.custo !== 850) e(`custo ${r.custo}, esperado 850`);
  if (r.venda !== 1500) e(`venda ${r.venda}, esperado 1500`);
  if (r.lucro !== 650) e(`lucro ${r.lucro}, esperado 650`);
  if (r.precoMax !== 90) e(`precoMax ${r.precoMax}, esperado 90`);
});

caso('P10 determinismo e empate pela menor magia', `
  return { dinheiro = 100, espacos = 100, conhecidas = { [5] = true, [3] = true }, desconto = 0,
    lucroMin = 50, margemMin = 5, estoque = {},
    dados = { receitas = {
        [5] = { nome = "Cinco", produto = 105, qtd = 1, reagentes = { { 11, 1 } } },
        [3] = { nome = "Tres", produto = 103, qtd = 1, reagentes = { { 10, 1 } } } },
      itens = { [105] = { nome = "P5", vende = 1000 }, [103] = { nome = "P3", vende = 1000 },
                [10] = { nome = "X" }, [11] = { nome = "Y" } } },
    escadas = { [10] = ${degraus([[100, 50]])}, [11] = ${degraus([[100, 50]])} } }`, (p, e, x) => {
  if (x.textos.length !== 2 || x.textos[0] !== x.textos[1]) e('duas execucoes deram saidas diferentes');
  const t = craft(p, 3);
  if (!t || t.n !== 1) e('a magia 3 deveria levar o empate');
  if (craft(p, 5)) e('a magia 5 nao deveria craftar (sem dinheiro)');
}, true);

caso('P11 nada paga', cab(`
  ent.escadas[10] = ${degraus([[1000, 100]])}`), (p, e) => {
  if (p.crafts.length !== 0) e('crafts deveria ser vazio');
  if (p.motivo !== 'lucro') e(`motivo ${p.motivo}`);
  if (p.totais.gasto !== 0) e('gasto deveria ser 0');
});

caso('P12 desempenho: 50 receitas, escadas de 200 degraus', `
  local ent = { dinheiro = 1000000000, espacos = 1000000, conhecidas = {}, desconto = 0, lucroMin = 50,
    margemMin = 5, estoque = {}, dados = { receitas = {}, itens = {} }, escadas = {} }
  local function esc(id)
    ent.dados.itens[id] = { nome = "I" .. id, pilha = 20 }
    local l = {}
    for k = 1, 200 do l[k] = { preco = 20 + k * 2, qtd = 50, leilao = k, inteiro = false } end
    ent.escadas[id] = l
  end
  for c = 0, 9 do esc(500 + c) end
  for i = 1, 50 do
    local m = 1000 + i
    local comp, p1, p2 = 500 + (i - 1) % 10, 600 + i, 700 + i
    esc(p1) esc(p2)
    ent.conhecidas[m] = true
    ent.dados.receitas[m] = { nome = "R" .. i, produto = 2000 + i, qtd = 1, reagentes = { { comp, 1 }, { p1, 1 }, { p2, 1 } } }
    ent.dados.itens[2000 + i] = { nome = "P" .. i, vende = 3000 + i * 5, pilha = 20 }
  end
  return ent`, (p, e, x) => {
  if (x.ms >= 1000) e(`${Math.round(x.ms)} ms (limite 1000)`);
  const total = p.crafts.reduce((s, c) => s + c.n, 0);
  if (total !== 5000) e(`crafts ${total}, esperado 5000`);
  if (p.motivo !== 'limite') e(`motivo ${p.motivo}`);
});

let erros = 0;
for (const c of casos) {
  const falhas = [];
  const e = (m) => falhas.push(m);
  try {
    const x = planejar(c.luaEntrada, c.dobro);
    c.verifica(x.plano, e, x);
  } catch (err) {
    falhas.push('excecao: ' + (err && err.message ? err.message : err));
  }
  if (falhas.length) { erros++; console.log(`FALHA ${c.nome.split(' ')[0]}: ${falhas.join('; ')}`); }
}
console.log(`casos=${casos.length} erros=${erros}`);
process.exit(erros ? 1 : 0);
