// Teste do planejador de rota (ns.planejarRota) do Planejador.lua (CompraForever, CONTRATO secao 12) no fengari.
// Uso: node ferramentas/compra/testar-rota.mjs [--planejador <caminho do Planejador.lua>]
// Saida: `FALHA <caso>: <motivo>` por falha e `casos=<n> erros=<e>`. Codigo 0 sem erro, 1 com erro.
// Os numeros esperados vem de uma implementacao JS independente (chance, ganho, crafts) aqui no arquivo.
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const aqui = dirname(fileURLToPath(import.meta.url));
const modder = resolve(aqui, '..', '..');
const require = createRequire(join(modder, 'ferramentas', 'guia', 'package.json'));
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');

const iArq = process.argv.indexOf('--planejador');
const arqPlanejador = iArq >= 0 && process.argv[iArq + 1]
  ? resolve(process.argv[iArq + 1])
  : join(modder, 'addons-proprios', 'CompraForever', 'Planejador.lua');

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

carregar(`
NS = {}
function SER(v)
  local t = type(v)
  if t == "nil" then return "null" end
  if t == "boolean" then return tostring(v) end
  if t == "number" then
    if v == math.huge then return "1e999" end
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

carregar(readFileSync(arqPlanejador, 'utf8'), 'Planejador.lua', 2, () => {
  lua.lua_pushstring(L, to_luastring('CompraForever'));
  lua.lua_getglobal(L, to_luastring('NS'));
});

// objeto JS -> literal Lua (chaves so de digitos viram numericas; null/undefined somem)
let litRev = false;
function lit(v) {
  if (v === null || v === undefined) return 'nil';
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'number') return Number.isFinite(v) ? String(v) : (v > 0 ? 'math.huge' : '-math.huge');
  if (typeof v === 'string') return JSON.stringify(v);
  if (Array.isArray(v)) return '{' + v.map(lit).join(',') + '}';
  const partes = [];
  for (const k of (litRev ? Object.keys(v).reverse() : Object.keys(v))) {
    if (v[k] === undefined || v[k] === null) continue;
    partes.push(`${/^\d+$/.test(k) ? `[${k}]` : `[${JSON.stringify(k)}]`}=${lit(v[k])}`);
  }
  return '{' + partes.join(',') + '}';
}

function planejar(ent, dobro, rev) {
  litRev = !!rev;
  const corpo = `
    local ent = ${lit(ent)}
    local a = SER(NS.planejarRota(ent))
    if ${dobro ? 'true' : 'false'} then return a .. "\\n#####\\n" .. SER(NS.planejarRota(ent)) end
    return a`;
  const t0 = performance.now();
  const s = carregar(corpo, 'caso', 0);
  const ms = performance.now() - t0;
  litRev = false;
  const partes = s.split('\n#####\n');
  return { plano: JSON.parse(partes[0]), textos: partes, ms };
}
// avalia uma expressao Lua com `ent` definido e devolve o JSON do resultado
function avaliar(ent, expr) {
  return JSON.parse(carregar(`local ent = ${lit(ent)}\n return SER(${expr})`, 'expr', 0));
}

// ---------- implementacao JS independente da formula ----------
const chanceJS = (r, s) => (r.pontos <= 0 ? 0 : s < r.amarela ? 1 : s >= r.cinza ? 0 : (r.cinza - s) / (r.cinza - r.amarela));
// ganho: chance*pontos da receita mais, com credito, o que os intermediarios F (ate 3 niveis) dao por craft
function ganhoJS(rota, trecho, rec, x, credito) {
  const somaF = (r, mult, nivel) => {
    let g = 0;
    for (const [id, q] of r.reagentes) {
      const f = trecho.fontes[id];
      if (f && f.f === 'F' && nivel <= 3) {
        const fr = rota.receitas[f.magia];
        const k = mult * q / fr.qtd;
        g += k * chanceJS(fr, x) * fr.pontos + somaF(fr, k, nivel + 1);
      }
    }
    return g;
  };
  return chanceJS(rec, x) * rec.pontos + (credito ? somaF(rec, 1, 1) : 0);
}
function faltamJS(rota, trecho, passo, s, credito, corte) {
  const rec = rota.receitas[passo.magia];
  const ate = corte ? Math.min(passo.ate, corte) : passo.ate;
  if (s >= ate) return 0;
  let t = 0;
  for (let x = Math.max(s, passo.de); x < ate; x++) {
    const g = ganhoJS(rota, trecho, rec, x, credito);
    if (g <= 0) return null;
    t += 1 / g;
  }
  return Math.ceil(t - 1e-9);
}

// ---------- fixture: Engineering 1-150 do legado-225-2026-11-23-1801 ----------
const eng = JSON.parse(readFileSync(join(modder, 'dados', 'pregao', 'receitas-engineering.json'), 'utf8'));
const porNome = (n) => eng.receitas.find((r) => r.nome === n);
const magiaDe = (n) => porNome(n).magia;
function receitaRota(r) {
  const o = {
    nome: r.nome, produto: r.produto ? r.produto.id : null, qtd: r.produto ? r.produto.qtd : null,
    reagentes: r.reagentes.map((g) => [g.id, g.qtd]), amarela: r.amarela, cinza: r.cinza, pontos: r.pontos,
    aprende: r.naowh.aprende, origem: r.inicial ? 'inicial' : (r.naowh.origem === 'trainer' ? 'treinador' : r.naowh.origem),
    treino: r.naowh.custo,
  };
  if (r.ferramentas) o.ferramentas = r.ferramentas.map((f) => ({ nome: f.nome, itens: f.itens }));
  if (r.foco) o.foco = r.foco.nome;
  return o;
}
const NOMES = ['Rough Dynamite', 'Rough Copper Bomb', 'Copper Tube', 'Coarse Blasting Powder', 'Coarse Dynamite',
  'Practice Lock', 'Large Copper Bomb', 'Heavy Dynamite', 'Bronze Framework'];
const FAIXAS = [[1, 59], [59, 65], [65, 75], [75, 91], [91, 100], [100, 105], [105, 125], [125, 145], [145, 150]];
const MAG = Object.fromEntries(NOMES.map((n) => [n, magiaDe(n)]));
const HBP = magiaDe('Heavy Blasting Powder');
const TETOS = { 2838: 354, 4364: 97, 2840: 110, 2592: 144, 2589: 27, 2841: 185, 4359: 120, 4357: 14, 4404: 69,
  2836: 92, 2880: 94, 2319: 120 };
const MARTELO = 5956;

function ladder(teto, tiers = 40, qtd = 20, inicio = 0.6) {
  const l = [];
  for (let i = 0; i < tiers; i++) {
    l.push({ preco: Math.max(1, Math.floor(teto * inicio) + Math.floor(i * teto * (1 - inicio) / (tiers - 1))), qtd, leilao: 1000 + i, inteiro: false });
  }
  return l;
}
function fixEng(opc = {}) {
  const receitas = {};
  for (const n of NOMES) receitas[MAG[n]] = receitaRota(porNome(n));
  receitas[HBP] = receitaRota(porNome('Heavy Blasting Powder'));
  const passos = NOMES.map((n, i) => ({ magia: MAG[n], de: FAIXAS[i][0], ate: FAIXAS[i][1], crafts: 0 }));
  const fontes = {};
  for (const [id, t] of Object.entries(TETOS)) fontes[id] = { f: 'L', qtd: 1, custo: 1, teto: t };
  fontes[4377] = opc.f4377 || { f: 'F', magia: HBP };
  fontes[MARTELO] = opc.martelo || { f: 'V', qtd: 1, preco: 18 };
  const trechos = [{ de: 1, ate: 150, chegou: 150, passos, fontes, totais: {} }];
  if (opc.trecho2) {
    receitas[99100] = { nome: 'Big Bronze Bomb', produto: 99101, qtd: 1, reagentes: [[2841, 2]], amarela: 150, cinza: 180, pontos: 1,
      aprende: 140, origem: 'treinador', treino: 600 };
    trechos.push({ de: 150, ate: 175, chegou: 175, passos: [{ magia: 99100, de: 150, ate: 175, crafts: 0 }],
      fontes: { 2841: { f: 'L', qtd: 1, custo: 1, teto: 185 } }, totais: {} });
  }
  const rota = {
    nome: 'Engineering', curto: 'Eng', linha: 202,
    ranks: [{ nome: 'Journeyman Engineering', cap: 150, pericia: 50, custo: 500, nivel: 10 },
      { nome: 'Expert Engineering', cap: 225, pericia: 125, custo: 5000, nivel: 20 }],
    receitas, trechos,
  };
  const itens = {};
  const todos = new Set([MARTELO, 4358, 4360, 4361, 4364, 4365, 4370, 6712, 4377, 4378, 4382, 99101]);
  for (const r of Object.values(receitas)) for (const [id] of r.reagentes) todos.add(id);
  for (const id of todos) {
    const it = eng.itens[String(id)];
    itens[id] = { nome: it ? it.nome : `item${id}`, vende: it ? it.vende : 1, pilha: it ? it.pilha : 20, vinculo: 0 };
  }
  const escadas = {};
  for (const [id, t] of Object.entries(TETOS)) escadas[id] = ladder(t);
  const conhecidas = {};
  for (const n of NOMES) conhecidas[MAG[n]] = true;
  conhecidas[HBP] = true;
  if (opc.trecho2) conhecidas[99100] = true;
  return {
    rota, itens, alvo: 150, pericia: 1, max: 150, nivel: 60, conhecidas, bolsa: {}, correio: {}, dinheiro: 1e9, espacos: 1000,
    desconto: 10, tolerancia: 10, margem: 0, escadas, credito: false, credVenda: {},
    fonte: { tipo: 'full', em: 1000, n: 100 }, ultimoFull: 900, agora: 2000,
  };
}
const clone = (o) => JSON.parse(JSON.stringify(o));
const passoDe = (e, nome) => e.rota.trechos[0].passos.find((p) => p.magia === MAG[nome]);

// simulacao JS independente das quantidades a comprar (estoque virtual, F expandido, sem preco)
function precisoJS(e, credito) {
  const tr = e.rota.trechos[0];
  const estoque = {}, comprar = {};
  for (const p of tr.passos) {
    if (p.de >= e.alvo || p.ate <= e.pericia) continue;
    const rec = e.rota.receitas[p.magia];
    const n = faltamJS(e.rota, tr, { ...p, ate: Math.min(p.ate, e.alvo) }, e.pericia, credito);
    const pega = (id, q) => {
      const t = Math.min(estoque[id] || 0, q);
      estoque[id] = (estoque[id] || 0) - t;
      q -= t;
      if (q <= 0) return;
      const f = tr.fontes[id];
      if (f && f.f === 'F') {
        const fr = e.rota.receitas[f.magia];
        const c = Math.ceil(q / fr.qtd);
        for (const [rid, rq] of fr.reagentes) pega(rid, rq * c);
        estoque[id] = (estoque[id] || 0) + c * fr.qtd - q;
      } else comprar[id] = (comprar[id] || 0) + q;
    };
    if (rec.ferramentas && !(e.bolsa[MARTELO] > 0)) { if (!(comprar[MARTELO] > 0)) comprar[MARTELO] = 1; }
    for (const [id, q] of rec.reagentes) pega(id, q * n);
    if (rec.produto) estoque[rec.produto] = (estoque[rec.produto] || 0) + n * rec.qtd;
  }
  return comprar;
}
const NAO_CREDITO = { 2838: 144, 4364: 130, 2840: 105, 2592: 78, 2589: 141, 2841: 17, 4359: 17, 4357: 133, 4404: 26, 2836: 19, 2880: 15, 2319: 6 };

// ---------- casos ----------
const casos = [];
const caso = (nome, corpo) => casos.push({ nome, corpo });
const item = (lista, id) => lista.find((x) => x.id === id);
const craftDe = (p, nome) => p.crafts.find((c) => c.magia === MAG[nome]);
const somaCrafts = (p) => p.crafts.reduce((a, c) => a + c.n, 0);

caso('R1 Rough Dynamite do 1 = 119 (credito falso e verdadeiro)', (e) => {
  for (const cred of [false, true]) {
    const ent = fixEng(); ent.credito = cred; ent.alvo = 59;
    const esp = faltamJS(ent.rota, ent.rota.trechos[0], passoDe(ent, 'Rough Dynamite'), 1, cred);
    if (esp !== 119) e(`JS independente deu ${esp}`);
    const direto = avaliar(ent, `NS.rotaFaltam(ent.rota, ent.rota.trechos[1], ent.rota.trechos[1].passos[1], 1, ${cred})`);
    if (direto !== 119) e(`rotaFaltam credito=${cred} deu ${direto}`);
    const { plano } = planejar(ent);
    const c = craftDe(plano, 'Rough Dynamite');
    if (!c || c.n !== 119) e(`plano credito=${cred}: n=${c && c.n}`);
    if (plano.rota.atual.faltam !== 119) e(`atual.faltam ${plano.rota.atual.faltam}`);
  }
});

caso('R2 Rough Dynamite do 40 = 78 (credito falso e verdadeiro)', (e) => {
  for (const cred of [false, true]) {
    const ent = fixEng(); ent.credito = cred; ent.alvo = 59; ent.pericia = 40;
    const esp = faltamJS(ent.rota, ent.rota.trechos[0], passoDe(ent, 'Rough Dynamite'), 40, cred);
    if (esp !== 78) e(`JS independente deu ${esp}`);
    const { plano } = planejar(ent);
    const c = craftDe(plano, 'Rough Dynamite');
    if (!c || c.n !== 78) e(`plano credito=${cred}: n=${c && c.n}`);
    if (plano.rota.passos[0].n !== 78) e(`passos[0].n ${plano.rota.passos[0].n}`);
  }
});

caso('R3 do 59: Rough Dynamite 0, Rough Copper Bomb 7', (e) => {
  const ent = fixEng(); ent.pericia = 59;
  const a = avaliar(ent, 'NS.rotaFaltam(ent.rota, ent.rota.trechos[1], ent.rota.trechos[1].passos[1], 59, false)');
  if (a !== 0) e(`Rough Dynamite deu ${a}`);
  const b = avaliar(ent, 'NS.rotaFaltam(ent.rota, ent.rota.trechos[1], ent.rota.trechos[1].passos[2], 59, false)');
  if (b !== 7) e(`Rough Copper Bomb deu ${b}`);
  if (faltamJS(ent.rota, ent.rota.trechos[0], passoDe(ent, 'Rough Copper Bomb'), 59, false) !== 7) e('JS independente != 7');
  const { plano } = planejar(ent);
  if (plano.rota.atual.magia !== MAG['Rough Copper Bomb'] || plano.rota.atual.faltam !== 7) e(`atual ${JSON.stringify(plano.rota.atual)}`);
  if (plano.rota.passos[0].estado !== 'feito') e(`passos[0] ${plano.rota.passos[0].estado}`);
});

caso('R4 do 62: Rough Copper Bomb 4', (e) => {
  const ent = fixEng(); ent.pericia = 62;
  const esp = faltamJS(ent.rota, ent.rota.trechos[0], passoDe(ent, 'Rough Copper Bomb'), 62, false);
  if (esp !== 4) e(`JS independente deu ${esp}`);
  const { plano } = planejar(ent);
  if (plano.rota.atual.faltam !== 4) e(`atual.faltam ${plano.rota.atual.faltam}`);
  const c = craftDe(plano, 'Rough Copper Bomb');
  if (!c || c.n !== 4) e(`craft n=${c && c.n}`);
});

caso('R5 Copper Tube 10 e Practice Lock 5 exatos', (e) => {
  const ent = fixEng();
  const ct = faltamJS(ent.rota, ent.rota.trechos[0], passoDe(ent, 'Copper Tube'), 65, false);
  const pl = faltamJS(ent.rota, ent.rota.trechos[0], passoDe(ent, 'Practice Lock'), 100, false);
  if (ct !== 10 || pl !== 5) e(`JS independente ${ct} ${pl}`);
  const n = avaliar(ent, `{ NS.rotaFaltam(ent.rota, ent.rota.trechos[1], ent.rota.trechos[1].passos[3], 65, false),
    NS.rotaFaltam(ent.rota, ent.rota.trechos[1], ent.rota.trechos[1].passos[6], 100, false) }`);
  if (n[0] !== 10 || n[1] !== 5) e(`Lua deu ${n}`);
  // todos os passos do 1 ao 150, sem credito, conferidos contra o JS
  const { plano } = planejar(ent);
  const esperado = [119, 7, 10, 19, 15, 5, 26, 72, 6];
  plano.rota.passos.forEach((p, i) => { if (p.n !== esperado[i]) e(`passo ${i + 1} (${p.nome}) n=${p.n}, esperado ${esperado[i]}`); });
  NOMES.forEach((nome, i) => {
    const js = faltamJS(ent.rota, ent.rota.trechos[0], passoDe(ent, nome), 1, false);
    if (js !== esperado[i]) e(`JS ${nome} ${js} != ${esperado[i]}`);
  });
});

caso('R6 plano da Engineering 1-150 do 1', (e) => {
  const ent = fixEng();
  const { plano: p } = planejar(ent);
  const r = p.rota;
  if (p.modo !== 2) e(`modo ${p.modo}`);
  if (r.estado !== 'ok' || p.motivo !== 'fim') e(`estado ${r.estado} motivo ${p.motivo}`);
  if (r.chega !== 150 || r.limite !== 150) e(`chega ${r.chega} limite ${r.limite}`);
  const esperado = [119, 7, 10, 19, 15, 5, 26, 72, 6];
  if (p.crafts.length !== 9 || !p.crafts.every((c, i) => c.n === esperado[i] && c.custo === 0)) e(`crafts ${JSON.stringify(p.crafts.map((c) => c.n))}`);
  if (r.atual.i !== 1 || r.atual.magia !== MAG['Rough Dynamite'] || r.atual.faltam !== 119 || r.atual.encantar !== false) e(`atual ${JSON.stringify(r.atual)}`);
  if (r.passos[0].estado !== 'agora' || r.passos.slice(1).some((x) => x.estado !== 'compra')) e(`estados ${r.passos.map((x) => x.estado)}`);
  const falta = precisoJS(ent, false);
  for (const [id, q] of Object.entries(NAO_CREDITO)) {
    const l = item(p.leilao, +id);
    if (!l || l.qtd !== q) e(`leilao ${id}: ${l && l.qtd}, esperado ${q}`);
    if (falta[id] !== q) e(`JS independente ${id}: ${falta[id]}`);
    if (l) {
      const soma = l.lotes.reduce((a, x) => a + x.qtd * x.preco, 0);
      const qtd = l.lotes.reduce((a, x) => a + x.qtd, 0);
      if (soma !== l.custo || qtd !== l.qtd) e(`lotes de ${id} nao somam: ${soma}/${l.custo} ${qtd}/${l.qtd}`);
      if (l.teto !== Math.floor(TETOS[id] * 110 / 100)) e(`teto de ${id}: ${l.teto}`);
      if (l.precoMax > l.teto) e(`precoMax ${l.precoMax} > teto ${l.teto} em ${id}`);
    }
  }
  if (p.leilao.length !== 12) e(`${p.leilao.length} linhas de leilao`);
  const ordem = [4357, 2589, 2840, 4359, 2880, 2836, 4364, 2841, 4404, 2838, 2592, 2319];
  const vistos = p.leilao.map((l) => l.id);
  if (JSON.stringify([...vistos].sort((a, b) => a - b)) !== JSON.stringify([...ordem].sort((a, b) => a - b))) e(`ids ${vistos}`);
  for (let i = 1; i < p.leilao.length; i++) if (p.leilao[i].passo < p.leilao[i - 1].passo) e('leilao fora da ordem de passo');
  if (p.leilao.some((l) => l.id === 4377)) e('Heavy Blasting Powder foi comprado (devia ser fabricado)');
  if (item(p.leilao, 2838).passo !== 8) e(`Heavy Stone no passo ${item(p.leilao, 2838).passo}`);
  const v = p.vendedor;
  if (v.length !== 1 || v[0].id !== MARTELO || v[0].qtd !== 1 || v[0].custo !== Math.floor(18 * 90 / 100) || v[0].tipo !== 'ferramenta') e(`vendedor ${JSON.stringify(v)}`);
  const somaL = p.leilao.reduce((a, l) => a + l.custo, 0);
  if (p.totais.gasto !== somaL + v[0].custo) e(`gasto ${p.totais.gasto} != ${somaL + v[0].custo}`);
  if (r.restante !== p.totais.gasto) e(`restante ${r.restante} != gasto ${p.totais.gasto}`);
  const scanEsp = Object.keys(NAO_CREDITO).map(Number).sort((a, b) => a - b);
  if (JSON.stringify(r.scan) !== JSON.stringify(scanEsp)) e(`scan ${r.scan}`);
  if (p.totais.espacos <= 0 || p.totais.espacos > 998) e(`espacos ${p.totais.espacos}`);
  if (r.proximo !== 'ah') e(`proximo ${r.proximo}`);
  if (r.dicas.length !== 0) e(`dicas ${r.dicas}`);
  if (r.velho !== false) e('velho devia ser false (ultimoFull 900 < fonte 1000; agora - fonte = 1000 s)');
  if (r.treinar.length !== 0) e(`treinar ${JSON.stringify(r.treinar)}`);
  if (p.fabricar.length !== 0 || p.sobra.length !== 0 || p.doEstoque.length !== 0 || p.revenda.length !== 0) e('listas vazias do formato 4 nao estao vazias');
});

caso('R7 prefixo por bolsa (espacos curtos)', (e) => {
  const ent = fixEng(); ent.espacos = 20;
  const { plano: p } = planejar(ent);
  if (p.motivo !== 'espaco') e(`motivo ${p.motivo}`);
  if (p.totais.espacos > 18) e(`espacos ${p.totais.espacos} > 18`);
  if (p.rota.chega >= 150) e(`chega ${p.rota.chega}`);
  if (p.crafts.length < 1 || p.crafts[0].magia !== MAG['Rough Dynamite']) e('devia comecar pela Rough Dynamite');
  // prefixo: so o ultimo craft e parcial
  const ps = p.rota.passos;
  p.crafts.forEach((c, i) => {
    const q = ps.find((x) => x.magia === c.magia);
    if (i < p.crafts.length - 1 && c.n !== q.n) e(`passo ${c.magia} parcial no meio do prefixo`);
    if (c.n > q.n) e('n maior que o faltam');
  });
  // maximalidade: um espaco a menos encolhe o plano
  const menor = clone(ent); menor.espacos = p.totais.espacos + 1;
  const { plano: p2 } = planejar(menor);
  if (somaCrafts(p2) >= somaCrafts(p)) e(`com ${menor.espacos} espacos o plano nao encolheu (${somaCrafts(p2)} vs ${somaCrafts(p)})`);
  const igual = clone(ent); igual.espacos = p.totais.espacos + 2;
  if (somaCrafts(planejar(igual).plano) !== somaCrafts(p)) e('com o espaco justo o plano mudou');
  // compra so o que os crafts do prefixo pedem (as quantidades batem com o JS)
});

caso('R8 prefixo por dinheiro', (e) => {
  const ent = fixEng(); ent.dinheiro = 5000;
  const { plano: p } = planejar(ent);
  if (p.motivo !== 'dinheiro') e(`motivo ${p.motivo}`);
  if (p.totais.gasto > 5000) e(`gasto ${p.totais.gasto} > 5000`);
  if (p.rota.chega >= 150 || p.crafts.length < 1) e(`chega ${p.rota.chega}`);
  const menos = clone(ent); menos.dinheiro = p.totais.gasto - 1;
  if (somaCrafts(planejar(menos).plano) >= somaCrafts(p)) e('gasto-1 nao encolheu o plano');
  const justo = clone(ent); justo.dinheiro = p.totais.gasto;
  const pj = planejar(justo).plano;
  if (somaCrafts(pj) !== somaCrafts(p)) e('dinheiro exato mudou o plano');
  const sem = clone(ent); sem.dinheiro = 0;
  const p0 = planejar(sem).plano;
  if (p0.crafts.length !== 0 || p0.motivo !== 'dinheiro' || p0.totais.gasto !== 0) e(`sem dinheiro: ${p0.crafts.length} crafts, motivo ${p0.motivo}`);
  if (p0.rota.restante <= 0) e('restante devia continuar calculado sem dinheiro');
});

caso('R9 limite do teto (dentro e fora) e degrau inteiro', (e) => {
  // Rough Blasting Powder (teto 14, tolerancia 10 => limite 15): 100 a 10, 30 a 15 (dentro), 1000 a 16 (fora)
  const ent = fixEng();
  ent.alvo = 65;
  ent.escadas[4357] = [{ preco: 10, qtd: 100, leilao: 1, inteiro: false }, { preco: 15, qtd: 30, leilao: 2, inteiro: false },
    { preco: 16, qtd: 1000, leilao: 3, inteiro: false }];
  const { plano: p } = planejar(ent);
  const l = item(p.leilao, 4357);
  if (!l) { e('sem linha de 4357'); return; }
  if (l.teto !== 15) e(`teto ${l.teto}`);
  if (l.lotes.some((x) => x.preco > 15)) e('comprou acima do limite');
  if (!l.lotes.some((x) => x.preco === 15)) e('o degrau de 15 (dentro do limite) ficou de fora');
  if (l.qtd !== 129) e(`qtd ${l.qtd}, esperado 129 (119 + 10)`);
  if (p.motivo !== 'preco') e(`motivo ${p.motivo}`);
  const c = p.rota.curtos.find((x) => x.id === 4357);
  if (!c || c.tipo !== 'preco' || c.cap !== 15 || c.falta <= 0) e(`curtos ${JSON.stringify(p.rota.curtos)}`);
  // 119 (passo 1) + 14 (passo 2) = 133 precisa; 130 disponiveis: o passo 2 fica com 5 crafts (10 po) -> 129... confere o JS
  const rd = craftDe(p, 'Rough Dynamite'), rb = craftDe(p, 'Rough Copper Bomb');
  if (!rd || rd.n !== 119) e(`Rough Dynamite ${rd && rd.n}`);
  if (!rb || rb.n !== 5) e(`Rough Copper Bomb ${rb && rb.n}, esperado 5 (11 po de 130-119)`);
  if (p.rota.chega >= 65) e(`chega ${p.rota.chega}`);
  // sem tolerancia o limite cai para 14: o degrau de 15 fica fora
  const t0 = clone(ent); t0.tolerancia = 0;
  const l0 = item(planejar(t0).plano.leilao, 4357);
  if (l0.teto !== 14 || l0.lotes.some((x) => x.preco > 14) || l0.qtd !== 100) e(`tolerancia 0: ${JSON.stringify(l0)}`);
  // leilao de item (degrau inteiro): dentro do limite, o lote todo sai e a sobra serve ao passo seguinte
  const inteiro = fixEng(); inteiro.alvo = 65;
  inteiro.escadas[4357] = [{ preco: 12, qtd: 130, leilao: 7, inteiro: true }, { preco: 20, qtd: 500, leilao: 8, inteiro: true }];
  const pi = planejar(inteiro).plano;
  const li = item(pi.leilao, 4357);
  if (!li || li.qtd !== 130 || li.custo !== 12 * 130 || !li.inteiro || li.lotes.length !== 1) e(`inteiro ${JSON.stringify(li)}`);
  if (pi.motivo !== 'preco' && pi.motivo !== 'fim') e(`motivo inteiro ${pi.motivo}`);
  // um unico degrau inteiro com sobra: comprado inteiro, a sobra vai ao estoque e o passo 2 nao compra de novo
  const sobra = fixEng(); sobra.alvo = 65;
  sobra.escadas[4357] = [{ preco: 12, qtd: 140, leilao: 7, inteiro: true }];
  const ps = planejar(sobra).plano;
  const ls = item(ps.leilao, 4357);
  if (!ls || ls.qtd !== 140 || ps.motivo !== 'fim' || ls.lotes.length !== 1) e(`sobra ${JSON.stringify(ls)} motivo ${ps.motivo}`);
  // degrau inteiro acima do teto nao entra
  const caro = fixEng(); caro.alvo = 59;
  caro.escadas[4357] = [{ preco: 16, qtd: 500, leilao: 9, inteiro: true }];
  const pc = planejar(caro).plano;
  if (item(pc.leilao, 4357) || pc.motivo !== 'preco' || pc.crafts.length !== 0) e(`caro: ${pc.motivo} ${pc.crafts.length}`);
  // sem escada: semPreco
  const sem = fixEng(); sem.alvo = 59; delete sem.escadas[4357];
  const pn = planejar(sem).plano;
  if (pn.motivo !== 'semPreco' || !pn.rota.curtos.some((x) => x.id === 4357 && x.tipo === 'semPreco')) e(`sem escada: ${pn.motivo}`);
});

caso('R10 o correio conta como estoque', (e) => {
  const ent = fixEng(); ent.alvo = 59;
  ent.correio = { 2589: 119, 4357: 119 };
  const { plano: p } = planejar(ent);
  if (item(p.leilao, 2589) || item(p.leilao, 4357)) e('comprou o que ja estava no correio');
  if (p.rota.proximo !== 'mail') e(`proximo ${p.rota.proximo}`);
  if (p.rota.reservar['2589'] !== 119 || p.rota.reservar['4357'] !== 119) e(`reservar ${JSON.stringify(p.rota.reservar)}`);
  if (p.motivo !== 'fim') e(`motivo ${p.motivo}`);
  // a bolsa tambem; o que falta e comprado so no excedente
  const mix = fixEng(); mix.alvo = 59;
  mix.bolsa = { 2589: 50 }; mix.correio = { 2589: 30 };
  const pm = planejar(mix).plano;
  if (item(pm.leilao, 2589).qtd !== 39) e(`Linen ${item(pm.leilao, 2589).qtd}, esperado 39`);
  // o correio ocupa bolsa quando chega: espacos curtos barram
  const apertado = fixEng(); apertado.alvo = 59;
  apertado.correio = { 2589: 119, 4357: 119 }; apertado.espacos = 10;
  const pa = planejar(apertado).plano;
  if (pa.motivo !== 'espaco' || pa.crafts.length !== 0) e(`apertado: ${pa.motivo} ${pa.crafts.length}`);
});

caso('R11 receita nao conhecida e F que nao pode fabricar', (e) => {
  const ent = fixEng(); ent.pericia = 59; ent.conhecidas = {};
  const { plano: p } = planejar(ent);
  if (p.rota.atual.magia !== MAG['Rough Copper Bomb']) e(`atual ${p.rota.atual.magia}`);
  if (p.rota.proximo !== 'trainer') e(`proximo ${p.rota.proximo}`);
  const t = p.rota.treinar;
  const rcb = t.find((x) => x.magia === MAG['Rough Copper Bomb']);
  if (!rcb || rcb.custo !== 130 || rcb.aprende !== 30) e(`treinar ${JSON.stringify(t)}`);
  if (!t.some((x) => x.magia === HBP)) e('Heavy Blasting Powder (F) devia estar em treinar');
  for (let i = 1; i < t.length; i++) if (t[i].aprende < t[i - 1].aprende) e('treinar fora da ordem de aprende');
  if (t.some((x) => x.magia === MAG['Rough Dynamite'])) e('receita inicial nao entra em treinar');
  if (p.crafts.length === 0) e('o plano ainda compra para a receita a aprender');
  // F de origem leilao, sem teto: bloqueio
  const b = fixEng(); b.pericia = 125; b.conhecidas = {};
  b.rota.receitas[HBP].origem = 'leilao'; b.rota.receitas[HBP].padrao = 99900;
  const pb = planejar(b).plano;
  if (pb.motivo !== 'bloqueio') e(`motivo ${pb.motivo}`);
  const cb = pb.rota.curtos.find((x) => x.tipo === 'bloqueio');
  if (!cb || cb.magia !== HBP || cb.id !== 4377) e(`curtos ${JSON.stringify(pb.rota.curtos)}`);
  // F que nao pode fabricar mas tem teto: compra no leilao
  const c = clone(b);
  c.rota.trechos[0].fontes[4377] = { f: 'F', magia: HBP, teto: 41 };
  c.escadas[4377] = ladder(41);
  const pc = planejar(c).plano;
  const l = item(pc.leilao, 4377);
  if (!l || l.qtd !== 144) e(`4377 leilao ${l && l.qtd}`);
  if (pc.rota.scan.indexOf(4377) < 0) e('4377 devia estar no scan');
  if (item(pc.leilao, 2838)) e('Heavy Stone nao devia ser comprado');
  // F aprendivel no treinador a tempo: fabrica
  const d = fixEng(); d.pericia = 125; d.conhecidas = {};
  const pd = planejar(d).plano;
  if (item(pd.leilao, 4377) || !item(pd.leilao, 2838)) e('com aprende <= de do passo devia fabricar');
});

caso('R12 rank e nivel', (e) => {
  // nivel 9: o teto do nivel e 75
  const a = fixEng(); a.pericia = 60; a.max = 75; a.nivel = 9;
  const pa = planejar(a).plano;
  const r = pa.rota;
  if (r.limite !== 75) e(`limite ${r.limite}`);
  if (!r.rank || r.rank.cap !== 150 || r.rank.bloqueado !== true || r.rank.custo !== 500 || r.rank.nivel !== 10) e(`rank ${JSON.stringify(r.rank)}`);
  if (pa.motivo !== 'limite') e(`motivo ${pa.motivo}`);
  if (r.chega !== 75) e(`chega ${r.chega}`);
  if (pa.crafts.some((c) => c.ate > 75)) e('craft passa do limite');
  const n3 = faltamJS(a.rota, a.rota.trechos[0], passoDe(a, 'Copper Tube'), 60, false, 75);
  const c3 = craftDe(pa, 'Copper Tube');
  if (!c3 || c3.n !== n3) e(`Copper Tube ${c3 && c3.n} != ${n3}`);
  if (pa.rota.passos.find((x) => x.magia === MAG['Coarse Blasting Powder']).n !== 0) e('passo acima do limite devia ter n=0');
  // nivel 10: o limite sobe, o rank continua sugerido (perícia ja chegou a 50) sem bloqueio
  const b = fixEng(); b.pericia = 60; b.max = 75; b.nivel = 10;
  const pb = planejar(b).plano;
  if (pb.rota.limite !== 150 || !pb.rota.rank || pb.rota.rank.bloqueado !== false) e(`nivel 10: ${JSON.stringify(pb.rota.rank)}`);
  if (pb.rota.proximo === 'trainer') e('longe do teto nao devia mandar ao treinador');
  // no teto do rank: trainer
  const c = fixEng(); c.pericia = 75; c.max = 75; c.nivel = 60;
  const pc = planejar(c).plano;
  if (pc.rota.proximo !== 'trainer' || !pc.rota.rank) e(`teto: ${pc.rota.proximo}`);
  // Expert: alvo 175, pericia 148 max 150, nivel 19 -> bloqueado; limite 150 por capNivel
  const d = fixEng({ trecho2: true }); d.alvo = 175; d.pericia = 148; d.max = 150; d.nivel = 19;
  const pd = planejar(d).plano;
  if (pd.rota.limite !== 150 || !pd.rota.rank || pd.rota.rank.cap !== 225 || pd.rota.rank.bloqueado !== true || pd.rota.rank.nivel !== 20) e(`Expert: limite ${pd.rota.limite} ${JSON.stringify(pd.rota.rank)}`);
  if (pd.motivo !== 'limite') e(`Expert motivo ${pd.motivo}`);
  // nivel 20 desbloqueia e junta os passos dos dois trechos
  const f = fixEng({ trecho2: true }); f.alvo = 175; f.pericia = 148; f.max = 150; f.nivel = 20;
  const pf = planejar(f).plano;
  if (pf.rota.limite !== 175 && pf.rota.limite !== 150) e(`limite ${pf.rota.limite}`);
  // nivel nil conta 60
  const g = fixEng(); delete g.nivel; g.pericia = 148; g.max = 150; g.alvo = 150;
  if (planejar(g).plano.rota.limite !== 150) e('nivel nil');
  const h = fixEng({ trecho2: true }); delete h.nivel; h.alvo = 175; h.pericia = 150; h.max = 225;
  const ph = planejar(h).plano;
  if (ph.rota.limite !== 175 || ph.rota.estado !== 'ok') e(`passos de dois trechos: limite ${ph.rota.limite} estado ${ph.rota.estado}`);
  if (!craftDe(ph, 'Big Bronze Bomb') && !ph.crafts.some((x) => x.magia === 99100)) e('passo do segundo trecho ausente');
});

caso('R13 venda e reserva', (e) => {
  const ent = fixEng(); ent.pericia = 80;
  ent.bolsa = { 4358: 50, 4364: 100, [MARTELO]: 1, 4357: 30, 4360: 9 };
  ent.credVenda = { 4358: 40, 4364: 100, [MARTELO]: 1, 4357: 30, 4360: 20 };
  const { plano: p } = planejar(ent);
  const v = p.rota.vender;
  if (v['4358'] !== 40) e(`4358 -> ${v['4358']}, esperado 40 (nenhum passo pede)`);
  if (v['4364']) e(`4364 -> ${v['4364']}: os passos que faltam consomem o estoque`);
  if (p.rota.reservar['4364'] !== 100) e(`reservar 4364 ${p.rota.reservar['4364']}`);
  if (v[String(MARTELO)]) e('ferramenta nao se vende');
  if (v['4357']) e('materia-prima que nao e produto da rota nao se vende');
  if (v['4360'] !== 9) e(`4360 -> ${v['4360']}, esperado min(20, 9) = 9`);
  // sem credito (addon nao craftou), nada sai
  const sem = clone(ent); sem.credVenda = {};
  if (Object.keys(planejar(sem).plano.rota.vender).length !== 0) e('sem credito nao vende');
  // credito maior que a bolsa menos a reserva
  const c = clone(ent); c.credVenda = { 4358: 500 };
  if (planejar(c).plano.rota.vender['4358'] !== 50) e('limitado pela bolsa');
  // padrao e objeto nunca vendem
  const x = fixEng(); x.pericia = 80; x.rota.receitas[MAG['Practice Lock']].padrao = 4358;
  x.bolsa = { 4358: 10 }; x.credVenda = { 4358: 10 };
  if (planejar(x).plano.rota.vender['4358']) e('padrao nao se vende');
});

caso('R14 credito do intermediario (Heavy Dynamite)', (e) => {
  const base = fixEng(); base.pericia = 125; base.alvo = 145;
  const tr = base.rota.trechos[0];
  const passo = { ...passoDe(base, 'Heavy Dynamite') };
  const sem = faltamJS(base.rota, tr, passo, 125, false);
  const com = faltamJS(base.rota, tr, passo, 125, true);
  if (sem !== 72) e(`JS sem credito ${sem}`);
  if (com !== 24) e(`JS com credito ${com}`);
  for (const [cred, esp] of [[false, 72], [true, 24]]) {
    const ent = clone(base); ent.credito = cred;
    const { plano: p } = planejar(ent);
    const c = craftDe(p, 'Heavy Dynamite');
    if (!c || c.n !== esp) e(`credito=${cred}: n=${c && c.n}, esperado ${esp}`);
    const hs = item(p.leilao, 2838);
    if (!hs || hs.qtd !== esp * 2) e(`Heavy Stone credito=${cred}: ${hs && hs.qtd}, esperado ${esp * 2}`);
    const w = item(p.leilao, 2592);
    if (!w || w.qtd !== esp) e(`Wool credito=${cred}: ${w && w.qtd}`);
    const g = avaliar(ent, `NS.rotaGanho(ent.rota, ent.rota.trechos[1], ${MAG['Heavy Dynamite']}, 130, ${cred})`);
    const gj = ganhoJS(ent.rota, tr, ent.rota.receitas[MAG['Heavy Dynamite']], 130, cred);
    if (Math.abs(g - gj) > 1e-9) e(`rotaGanho credito=${cred}: ${g} != ${gj}`);
  }
  // o crafts do 12.1 (qtd = 48 com credito) bate com 24 crafts x 2
  // com 3 niveis de F e ciclo: nao trava
  const ciclo = clone(base);
  ciclo.rota.receitas[HBP].reagentes = [[4377, 1]];
  const pc = planejar(ciclo).plano;
  if (!pc.rota) e('ciclo derrubou o plano');
});

caso('R15 alvo atingido', (e) => {
  const ent = fixEng(); ent.pericia = 150;
  ent.bolsa = { 4358: 50, 4378: 30 }; ent.credVenda = { 4358: 40, 4378: 30 };
  const { plano: p } = planejar(ent);
  if (p.rota.estado !== 'feito' || p.rota.proximo !== 'done') e(`${p.rota.estado} ${p.rota.proximo}`);
  if (p.leilao.length || p.vendedor.length || p.crafts.length) e('feito nao compra nem crafta');
  if (p.rota.vender['4358'] !== 40 || p.rota.vender['4378'] !== 30) e(`vender ${JSON.stringify(p.rota.vender)}`);
  if (p.rota.atual) e('atual devia ser nil');
  // portoes
  const sd = fixEng(); sd.rota = undefined;
  const a = planejar(sd).plano;
  if (a.rota.estado !== 'semDados') e(`semDados ${a.rota.estado}`);
  const sp = fixEng(); sp.pericia = undefined;
  const b = planejar(sp).plano;
  if (b.rota.estado !== 'semPericia' || b.rota.proximo !== 'open' || b.leilao.length) e(`semPericia ${b.rota.estado} ${b.rota.proximo}`);
  const na = fixEng(); na.pericia = 0;
  const c = planejar(na).plano;
  if (c.rota.estado !== 'naoAprendida' || c.rota.proximo !== 'trainer' || c.leilao.length) e(`naoAprendida ${c.rota.estado}`);
  // lacuna
  const gap = fixEng(); gap.pericia = 70;
  gap.rota.trechos[0].passos = gap.rota.trechos[0].passos.filter((x) => x.magia !== MAG['Copper Tube']);
  const d = planejar(gap).plano;
  if (d.rota.estado !== 'lacuna' || d.rota.lacuna !== 70 || d.leilao.length) e(`lacuna ${d.rota.estado} ${d.rota.lacuna}`);
  const gap2 = fixEng(); gap2.pericia = 40;
  const d2 = planejar(gap2).plano;
  if (d2.rota.estado !== 'ok') e(`sem lacuna: ${d2.rota.estado}`);
  // velho
  const nov = fixEng(); nov.ultimoFull = { em: 1500 };
  if (planejar(nov).plano.rota.velho !== true) e('Full mais novo que a fonte devia dar velho');
  const ant = fixEng(); ant.ultimoFull = 900; ant.agora = 1000 + 21601;
  if (planejar(ant).plano.rota.velho !== true) e('fonte com mais de 6 h devia dar velho');
  const ok = fixEng(); ok.ultimoFull = 900; ok.agora = 1000 + 21599;
  if (planejar(ok).plano.rota.velho !== false) e('fonte recente nao e velha');
});

caso('R16 encantamento sem item', (e) => {
  const enc = JSON.parse(readFileSync(join(modder, 'dados', 'pregao', 'receitas-enchanting.json'), 'utf8'));
  const base = enc.receitas.find((r) => !r.produto && r.reagentes.length >= 1);
  if (!base) { e('sem receita de encantamento sem produto'); return; }
  const rec = { ...receitaRota(base), encantar: true, produto: null, qtd: null };
  const rota = {
    nome: 'Enchanting', curto: 'Ench', linha: 333, ranks: [],
    receitas: { [base.magia]: rec },
    trechos: [{ de: 1, ate: Math.max(base.cinza, 30), passos: [{ magia: base.magia, de: Math.max(1, base.amarela - 1), ate: base.cinza, crafts: 0 }],
      fontes: Object.fromEntries(base.reagentes.map((g) => [g.id, { f: 'L', qtd: 1, custo: 1, teto: 50 }])), totais: {} }],
  };
  const itens = {};
  for (const f of base.ferramentas || []) rota.trechos[0].fontes[f.itens[0]] = { f: 'V', qtd: 1, preco: 10 };
  for (const g of base.reagentes) itens[g.id] = { nome: `r${g.id}`, vende: 1, pilha: 20 };
  const escadas = {};
  for (const g of base.reagentes) escadas[g.id] = ladder(50);
  const de = rota.trechos[0].passos[0].de;
  const ent = { rota, itens, alvo: base.cinza, pericia: de, max: 75, nivel: 60, conhecidas: { [base.magia]: true }, bolsa: {}, correio: {},
    dinheiro: 1e9, espacos: 500, desconto: 10, tolerancia: 10, margem: 0, escadas, credito: true, credVenda: {}, fonte: { tipo: 'publica', em: 1 }, agora: 2 };
  const { plano: p } = planejar(ent);
  const esp = faltamJS(rota, rota.trechos[0], rota.trechos[0].passos[0], de, true);
  if (p.rota.estado !== 'ok' || !p.rota.atual || p.rota.atual.encantar !== true) e(`atual ${JSON.stringify(p.rota.atual)}`);
  if (p.rota.atual.faltam !== esp) e(`faltam ${p.rota.atual.faltam} != ${esp}`);
  if (p.crafts.length !== 1 || p.crafts[0].n !== esp) e(`crafts ${JSON.stringify(p.crafts)}`);
  for (const g of base.reagentes) {
    const l = item(p.leilao, g.id);
    if (!l || l.qtd !== g.qtd * esp) e(`reagente ${g.id}: ${l && l.qtd}, esperado ${g.qtd * esp}`);
  }
  if (Object.keys(p.rota.vender).length !== 0) e('sem produto nada se vende');
  if (p.motivo !== 'fim') e(`motivo ${p.motivo}`);
  if (p.rota.proximo !== 'ah') e(`proximo ${p.rota.proximo}`);
});

caso('R17 ferramenta fabricada', (e) => {
  const ent = fixEng({ martelo: { f: 'F', magia: 99001 } });
  ent.rota.receitas[99001] = { nome: 'Fake Hammer', produto: MARTELO, qtd: 1, reagentes: [[2840, 2]], amarela: 1, cinza: 2, pontos: 1,
    aprende: 1, origem: 'inicial' };
  ent.pericia = 59;
  const { plano: p } = planejar(ent);
  if (item(p.vendedor, MARTELO) || item(p.leilao, MARTELO)) e('o martelo fabricado nao se compra');
  const cu = item(p.leilao, 2840);
  // Copper Bar: 2 do martelo + RCB 7 + Copper Tube 20 + LCB 78 = 107
  if (!cu || cu.qtd !== 107) e(`Copper Bar ${cu && cu.qtd}, esperado 107`);
  if (p.rota.vender[String(MARTELO)]) e('ferramenta nao se vende');
  // ja na bolsa: nada a fabricar
  const t = clone(ent); t.bolsa = { [MARTELO]: 1 };
  if (item(planejar(t).plano.leilao, 2840).qtd !== 105) e('martelo na bolsa devia dispensar a fabricacao');
  // outro item da lista de ferramentas na bolsa tambem serve
  const t2 = clone(ent); t2.bolsa = { 260811: 1 };
  if (item(planejar(t2).plano.leilao, 2840).qtd !== 105) e('ferramenta alternativa na bolsa');
  // a ferramenta comprada no vendedor entra uma vez so e fica na bolsa
  const v = fixEng(); v.pericia = 59;
  const pv = planejar(v).plano;
  if (!item(pv.vendedor, MARTELO) || item(pv.vendedor, MARTELO).qtd !== 1) e('martelo no vendedor, uma vez');
  // objeto de acampamento: escolhe o de menor custo e monta uma vez
  const o = fixEng(); o.pericia = 59;
  o.rota.receitas[MAG['Rough Copper Bomb']].acampamento = { nome: 'Portable Anvil', itens: [7001, 7002] };
  o.rota.trechos[0].fontes[7001] = { f: 'V', qtd: 1, preco: 500 };
  o.rota.trechos[0].fontes[7002] = { f: 'V', qtd: 1, preco: 200 };
  const po = planejar(o).plano;
  const ob = po.vendedor.filter((x) => x.tipo === 'objeto');
  if (ob.length !== 1 || ob[0].id !== 7002) e(`objeto ${JSON.stringify(ob)}`);
  if (!po.rota.dicas.includes('PLACE Portable Anvil')) e(`dicas ${po.rota.dicas}`);
  // padrao: receita nao conhecida de origem leilao
  const pa = fixEng(); pa.pericia = 59; pa.conhecidas = { [MAG['Rough Dynamite']]: true };
  pa.rota.receitas[MAG['Rough Copper Bomb']].origem = 'vendedor';
  pa.rota.receitas[MAG['Rough Copper Bomb']].padrao = 8800;
  pa.rota.trechos[0].fontes[8800] = { f: 'V', qtd: 1, preco: 100 };
  const pp = planejar(pa).plano;
  const pad = pp.vendedor.find((x) => x.id === 8800);
  if (!pad || pad.tipo !== 'padrao' || pad.qtd !== 1 || pad.custo !== 90) e(`padrao ${JSON.stringify(pad)}`);
  pa.bolsa = { 8800: 1 };
  const pp2 = planejar(pa).plano;
  if (pp2.vendedor.find((x) => x.id === 8800)) e('padrao na bolsa nao se compra');
  if (!pp2.rota.dicas.includes('LEARN item8800') && !pp2.rota.dicas.some((x) => x.startsWith('LEARN'))) e(`dicas ${pp2.rota.dicas}`);
});

caso('R18 determinismo', (e) => {
  const ent = fixEng(); ent.credito = true; ent.espacos = 60; ent.dinheiro = 30000;
  ent.bolsa = { 4358: 5, 2589: 7, 4357: 3 }; ent.correio = { 2840: 10 };
  const { textos } = planejar(ent, true);
  if (textos[0] !== textos[1]) e('duas chamadas seguidas deram planos diferentes');
  // mesma entrada com as tabelas construidas em outra ordem
  const a = planejar(ent).textos[0], b = planejar(ent, false, true).textos[0];
  if (a !== b) e('a ordem de construcao das tabelas mudou o plano');
  const antes = JSON.stringify(ent);
  planejar(ent);
  if (JSON.stringify(ent) !== antes) e('a entrada foi alterada');
});

// ---------- R19 desempenho: Blacksmithing 1-225 sintetico ----------
function fixBS() {
  const bs = JSON.parse(readFileSync(join(modder, 'dados', 'pregao', 'receitas-blacksmithing.json'), 'utf8'));
  const cand = bs.receitas.filter((r) => r.produto && r.pontos > 0 && r.reagentes.length > 0 && r.cinza - r.amarela >= 10);
  const receitas = {}, passos = [], fontes = { 5956: { f: "V", qtd: 1, preco: 18 } }, escadas = {}, itens = {};
  let s = 1;
  while (s < 225) {
    // entre as que ainda dao ponto em s, a de maior cinza
    const ok = cand.filter((r) => r.amarela <= s + 16 && r.cinza > s + 2);
    ok.sort((a, b) => b.cinza - a.cinza || a.magia - b.magia);
    const r = ok[0];
    if (!r) break;
    const ate = Math.min(r.cinza, 225, s + 17);
    receitas[r.magia] = { ...receitaRota(r), origem: 'inicial' };
    passos.push({ magia: r.magia, de: s, ate, crafts: 0 });
    for (const g of r.reagentes) {
      if (!fontes[g.id]) {
        fontes[g.id] = { f: 'L', qtd: 1, custo: 1, teto: 100 };
        escadas[g.id] = ladder(100, 200, 15, 0.3);
        itens[g.id] = { nome: `m${g.id}`, vende: 5, pilha: 20 };
      }
    }
    itens[r.produto.id] = { nome: `p${r.produto.id}`, vende: 7, pilha: 20 };
    s = ate;
  }
  const rota = { nome: 'Blacksmithing', curto: 'BS', linha: 164, ranks: [{ nome: 'Journeyman', cap: 150, pericia: 50, custo: 500, nivel: 10 },
    { nome: 'Expert', cap: 225, pericia: 125, custo: 5000, nivel: 20 }], receitas, trechos: [{ de: 1, ate: 225, passos, fontes, totais: {} }] };
  return { rota, itens, alvo: 225, pericia: 1, max: 225, nivel: 60, conhecidas: Object.fromEntries(Object.keys(receitas).map((m) => [m, true])),
    bolsa: {}, correio: {}, dinheiro: 1e10, espacos: 3000, desconto: 10, tolerancia: 10, margem: 0, escadas, credito: true, credVenda: {},
    fonte: { tipo: 'full', em: 1, n: 1 }, agora: 2 };
}
caso('R19 desempenho (Blacksmithing 1-225; 119 replanejamentos)', (e) => {
  const ent = fixBS();
  const np = ent.rota.trechos[0].passos.length;
  if (np < 12 || np > 22) e(`rota sintetica com ${np} passos`);
  const { plano: p, ms } = planejar(ent);
  if (p.rota.estado !== 'ok') e(`estado ${p.rota.estado}`);
  if (ms >= 1000) e(`um plano levou ${ms.toFixed(0)} ms`);
  if (p.crafts.length < 5) e(`so ${p.crafts.length} crafts: motivo ${p.motivo}`);
  // plano de bolsa curta: forca a busca binaria em varios pontos
  const curta = clone(ent); curta.espacos = 40;
  const t1 = performance.now();
  const pc = planejar(curta).plano;
  const m1 = performance.now() - t1;
  if (pc.motivo !== 'espaco' || m1 >= 1000) e(`bolsa curta: ${pc.motivo} ${m1.toFixed(0)} ms`);
  // 119 replanejamentos seguidos (a pericia sobe 1 por vez)
  const n119 = carregar(`
    local ent = ${lit(ent)}
    local t0 = os.clock()
    for i = 1, 119 do
      ent.pericia = i
      NS.planejarRota(ent)
    end
    return tostring(os.clock() - t0)`, 'perf', 0);
  const t2 = performance.now();
  carregar(`
    local ent = ${lit(ent)}
    for i = 1, 119 do
      ent.pericia = i
      NS.planejarRota(ent)
    end
    return "ok"`, 'perf2', 0);
  const m2 = performance.now() - t2;
  if (m2 >= 1000) e(`119 replanejamentos levaram ${m2.toFixed(0)} ms (os.clock ${n119})`);
  process.stderr.write(`# R19: plano ${ms.toFixed(0)} ms, bolsa curta ${m1.toFixed(0)} ms, 119 replanejamentos ${m2.toFixed(0)} ms, ${np} passos\n`);
});

// ---------- R20 rotas reais: ns.rotaFaltam (Lua) x crafts gravados pelo JS (Dados.lua, 12.1) ----------
caso('R20 rotaFaltam do Lua = crafts do JS em todo passo das rotas reais', (e) => {
  carregar(readFileSync(join(modder, 'addons-proprios', 'CompraForever', 'Dados.lua'), 'utf8'), 'Dados.lua', 0);
  const regs = JSON.parse(carregar(`
    local cred = CompraForeverDados.rotas.credito ~= false
    local slugs = {}
    for k in pairs(CompraForeverDados.rotas.profs) do slugs[#slugs + 1] = k end
    table.sort(slugs)
    local out = {}
    for _, slug in ipairs(slugs) do
      local rota = CompraForeverDados.rotas.profs[slug]
      for i, trecho in ipairs(rota.trechos) do
        for j, passo in ipairs(trecho.passos) do
          local lua = NS.rotaFaltam(rota, trecho, passo, passo.de, cred)
          out[#out + 1] = { slug = slug, i = i, j = j, magia = passo.magia, de = passo.de, ate = passo.ate,
            js = passo.crafts, ok = lua ~= nil, lua = lua }
        end
      end
    end
    return SER(out)`, 'R20', 0));
  if (regs.length === 0) e('nenhum passo em CompraForeverDados.rotas.profs');
  let k = 0;
  for (const r of regs) {
    const lu = r.ok ? r.lua : null;
    if (lu === r.js) continue;
    k++;
    if (k <= 20) console.log(`R20 ${r.slug} trecho ${r.i} passo ${r.j} magia ${r.magia} ${r.de}-${r.ate}: lua ${lu ?? 'nil'} js ${r.js}`);
  }
  console.log(`# R20: ${regs.length} passos, ${k} divergencias`);
  if (k) e(`${k} divergencia(s) entre rotaFaltam (Lua) e crafts (JS); ver as linhas R20 acima`);
});

let erros = 0;
for (const c of casos) {
  const falhas = [];
  try { c.corpo((m) => falhas.push(m)); } catch (err) { falhas.push(`excecao: ${err.message}`); }
  for (const f of falhas) { console.log(`FALHA ${c.nome}: ${f}`); erros++; }
}
console.log(`casos=${casos.length} erros=${erros}`);
process.exit(erros ? 1 : 0);
