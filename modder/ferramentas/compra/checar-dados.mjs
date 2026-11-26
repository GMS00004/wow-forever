// Relê addons-proprios/CompraForever/Dados.lua no fengari (Lua 5.3) e confere o contrato (secao 2 e 12.1).
// Uso: node ferramentas/compra/checar-dados.mjs [--exigir-full]
//   --exigir-full: o bloco rotas tem de vir de um Full com menos de 6 horas (k).
// Codigo 0 = ok; 1 = alguma falha (lista no stdout).
import { createRequire } from 'node:module';
import { existsSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const RAIZ = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const SAIDA = join(RAIZ, 'addons-proprios', 'CompraForever', 'Dados.lua');
const ARQ_ROTAS = join(RAIZ, 'dados', 'pregao', 'rotas.json');
const EXIGIR_FULL = process.argv.includes('--exigir-full');
const SLUGS = ['alchemy', 'blacksmithing', 'enchanting', 'engineering', 'leatherworking', 'tailoring'];
const requireGuia = createRequire(join(RAIZ, 'ferramentas', 'guia', 'package.json'));
const fengari = requireGuia('fengari');
const { lua, lauxlib, lualib, to_luastring } = fengari;

const falhas = [];
const falha = (msg) => falhas.push(msg);

const texto = readFileSync(SAIDA, 'utf8');
if (/[^\x00-\x7f]/.test(texto)) {
  const n = (texto.match(/[^\x00-\x7f]/g) || []).length;
  falha(`(e) ${n} caractere(s) fora do ASCII`);
}

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);

// Carrega o Dados.lua sozinho; o tempo de carga vai para (l), no fim.
const tCarga0 = performance.now();
let st = lauxlib.luaL_loadstring(L, to_luastring(texto + '\n'));
if (st !== lua.LUA_OK) falha('carga do Dados.lua: ' + lua.lua_tojsstring(L, -1));
else {
  st = lua.lua_pcall(L, 0, 0, 0);
  if (st !== lua.LUA_OK) falha('execucao do Dados.lua: ' + lua.lua_tojsstring(L, -1));
}
const msCarga = performance.now() - tCarga0;

// Serializadores em Lua: __saida (receitas, itens, fabrica: uma linha por entrada) e __rotas (JSON do bloco rotas).
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
local function ser(v)
  local t = type(v)
  if t == 'table' then
    local n = 0
    for _ in pairs(v) do n = n + 1 end
    local out = {}
    if n == 0 then return '[]' end
    if n == #v then
      for i = 1, #v do out[i] = ser(v[i]) end
      return '[' .. table.concat(out, ',') .. ']'
    end
    local ks = {}
    for k in pairs(v) do ks[#ks + 1] = k end
    table.sort(ks, function(a, b) return tostring(a) < tostring(b) end)
    for i, k in ipairs(ks) do out[i] = '"' .. tostring(k) .. '":' .. ser(v[k]) end
    return '{' .. table.concat(out, ',') .. '}'
  elseif t == 'string' then
    return '"' .. v .. '"'
  elseif t == 'number' or t == 'boolean' then
    return tostring(v)
  end
  return 'null'
end
__rotas = ser(rawget(CompraForeverDados, 'rotas'))
`;

const carregou = falhas.length === 0;
if (carregou) {
  st = lauxlib.luaL_loadstring(L, to_luastring(serializador));
  if (st === lua.LUA_OK) st = lua.lua_pcall(L, 0, 0, 0);
  if (st !== lua.LUA_OK) falha('serializador: ' + lua.lua_tojsstring(L, -1));
}

const receitas = new Map();
const itens = new Map();
const fabrica = new Map();
let rot = null;
if (carregou && !falhas.length) {
  lua.lua_getglobal(L, to_luastring('__saida'));
  const linhas = lua.lua_tojsstring(L, -1).split('\n').filter(Boolean);
  lua.lua_pop(L, 1);
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
  lua.lua_getglobal(L, to_luastring('__rotas'));
  const json = lua.lua_tojsstring(L, -1);
  lua.lua_pop(L, 1);
  try { rot = JSON.parse(json); } catch (e) { falha(`bloco rotas do Dados.lua nao le como JSON: ${e.message}`); }
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

// (g) a (k): bloco rotas (contrato 12.1), so quando o Dados.lua carregou.
if (carregou && !falhas.length) {
  const temArq = existsSync(ARQ_ROTAS);
  if (!rot && temArq) falha('(g) dados/pregao/rotas.json existe, mas o Dados.lua nao tem o bloco rotas: rode ferramentas/compra/gerar-dados.mjs');
  else if (!rot && EXIGIR_FULL) falha('--exigir-full: o Dados.lua nao tem o bloco rotas');
  else if (!rot) console.log('rotas: sem bloco rotas no Dados.lua (sem rotas.json): (g)-(k) nao rodam');
  else checarRotas(rot);
}

function checarRotas(rot) {
  const profs = rot.profs ?? {};
  const itensRota = rot.itens ?? {};
  const temItem = (id) => Object.prototype.hasOwnProperty.call(itensRota, String(id));
  const ref = (id, onde) => { if (!temItem(id)) falha(`(i) ${onde} ${id} ausente em rotas.itens`); };
  let trechos = 0, passos = 0;

  // (g) versao, as seis profissoes, dois ou tres trechos: 1 de 1 ate chegar a 150; 2 do fim do 1 ate 225; o 3, se houver
  // (--ate 250 --marcos 150,225), do fim do 2 ate o ate dele (AVISO se a rota parar antes).
  if (rot.versao !== 1) falha(`(g) rotas.versao = ${rot.versao}, esperado 1`);
  for (const slug of SLUGS) {
    const p = profs[slug];
    if (!p) { falha(`(g) rotas.profs.${slug} ausente`); continue; }
    const tr = p.trechos ?? [];
    trechos += tr.length;
    if (tr.length !== 2 && tr.length !== 3) { falha(`(g) ${slug}: ${tr.length} trecho(s), esperado 2 ou 3`); continue; }
    const [t1, t2, t3] = tr;
    if (t1.de !== 1) falha(`(g) ${slug}: trecho 1 comeca em ${t1.de}, esperado 1`);
    if (t2.de !== t1.ate) falha(`(g) ${slug}: trecho 2 comeca em ${t2.de}, esperado ${t1.ate} (fim do trecho 1)`);
    if (t2.chegou !== 225) falha(`(g) ${slug}: trecho 2 chega ao ${t2.chegou}, esperado 225`);
    if (t3) {
      if (t3.de !== t2.ate) falha(`(g) ${slug}: trecho 3 comeca em ${t3.de}, esperado ${t2.ate} (fim do trecho 2)`);
      if (!(t3.ate > t3.de)) falha(`(g) ${slug}: trecho 3 de ${t3.de} ate ${t3.ate}`);
      else if (t3.chegou !== t3.ate) console.log(`AVISO ${slug}: trecho 3 chega ao ${t3.chegou}, alvo ${t3.ate}`);
    }

    // (h) passos contiguos de de a chegou; cada magia de passo existe, amarela < cinza, pontos > 0.
    for (const [i, t] of tr.entries()) {
      let esperado = t.de;
      for (const ps of t.passos ?? []) {
        passos++;
        if (ps.de !== esperado) falha(`(h) ${slug} trecho ${i + 1}: passo da magia ${ps.magia} comeca em ${ps.de}, esperado ${esperado}`);
        esperado = ps.ate;
      }
      if (esperado !== t.chegou) falha(`(h) ${slug} trecho ${i + 1}: passos chegam a ${esperado}, chegou = ${t.chegou}`);
      for (const ps of t.passos ?? []) {
        const r = p.receitas?.[ps.magia];
        if (!r) { falha(`(h) ${slug}: passo com magia ${ps.magia} fora de receitas`); continue; }
        // amarela == cinza ocorre em receita sem faixa amarela (ex.: Skycaller's Mail Boots, 205/205): so AVISO.
        if (r.amarela > r.cinza || r.amarela === undefined) falha(`(h) ${slug}: magia ${ps.magia} (${r.nome}) amarela ${r.amarela} maior que cinza ${r.cinza}`);
        else if (r.amarela === r.cinza) console.log(`AVISO ${slug}: magia ${ps.magia} (${r.nome}) amarela = cinza = ${r.cinza}`);
        if (!(r.pontos > 0)) falha(`(h) ${slug}: magia ${ps.magia} (${r.nome}) sem pontos`);
      }
    }

    // (i) itens citados existem em rotas.itens; fontes com f, teto/qtd, preco ou magia conforme a letra.
    for (const [magia, r] of Object.entries(p.receitas ?? {})) {
      const onde = `${slug} receita ${magia}:`;
      if (r.produto !== undefined && r.produto !== null) ref(r.produto, `${onde} produto`);
      for (const g of r.reagentes ?? []) ref(g[0], `${onde} reagente`);
      for (const f of r.ferramentas ?? []) for (const id of f.itens ?? []) ref(id, `${onde} ferramenta`);
      for (const id of r.acampamento?.itens ?? []) ref(id, `${onde} objeto de acampamento`);
      if (r.padrao !== undefined && r.padrao !== null) ref(r.padrao, `${onde} padrao`);
    }
    for (const [i, t] of tr.entries()) {
      for (const [id, f] of Object.entries(t.fontes ?? {})) {
        const onde = `${slug} trecho ${i + 1} fonte`;
        ref(id, `${onde}`);
        if (!['L', 'V', 'F'].includes(f.f)) falha(`(i) ${onde} ${id}: f = ${f.f}, esperado L, V ou F`);
        if (f.f === 'L' && !(Number.isInteger(f.teto) && f.teto > 0 && f.qtd > 0)) falha(`(i) ${onde} ${id}: L sem teto inteiro > 0 ou qtd > 0`);
        if (f.f === 'V' && !(f.preco > 0)) falha(`(i) ${onde} ${id}: V sem preco > 0`);
        if (f.f === 'F' && !(f.magia !== undefined && p.receitas?.[f.magia])) falha(`(i) ${onde} ${id}: F com magia ${f.magia} fora de receitas`);
      }
    }

    // (j) todo rank com nivel; receita de passo de treinador com aprende (treino ausente so e AVISO).
    for (const rk of p.ranks ?? []) if (rk.nivel === null || rk.nivel === undefined) falha(`(j) ${slug}: rank ${rk.nome} sem nivel`);
    const magiasDePasso = new Set(tr.flatMap((t) => (t.passos ?? []).map((x) => x.magia)));
    for (const magia of magiasDePasso) {
      const r = p.receitas?.[magia];
      if (!r || r.origem !== 'treinador') continue;
      if (r.aprende === undefined || r.aprende === null) falha(`(j) ${slug}: receita ${magia} (${r.nome}) de treinador sem aprende`);
      if (r.treino === undefined || r.treino === null) console.log(`AVISO ${slug}: receita ${magia} (${r.nome}) de treinador sem treino`);
    }
  }

  // (k) fonte com tipo e em; com --exigir-full, tipo full e no maximo 6 horas.
  const fo = rot.fonte;
  if (!fo) falha('(k) rotas.fonte ausente');
  else {
    if (typeof fo.tipo !== 'string') falha('(k) fonte.tipo ausente');
    if (typeof fo.em !== 'number') falha('(k) fonte.em ausente');
    if (EXIGIR_FULL) {
      if (fo.tipo !== 'full') falha(`(k) --exigir-full: fonte.tipo = ${fo.tipo}, esperado full`);
      if (typeof fo.em === 'number') {
        const horas = (Date.now() / 1000 - fo.em) / 3600;
        if (horas > 6) falha(`(k) --exigir-full: fonte de ha ${horas.toFixed(1)} h (limite 6 h)`);
      }
    }
  }
  console.log(`rotas: profs=${Object.keys(profs).length} trechos=${trechos} passos=${passos} itens=${Object.keys(itensRota).length}`);
}

// (l) tamanho e tempo de carga do Dados.lua (o arquivo inteiro, com ou sem rotas).
const kb = Buffer.byteLength(texto) / 1024;
if (kb >= 400) falha(`(l) Dados.lua com ${Math.round(kb)} KB (limite 400 KB)`);
if (msCarga >= 300) falha(`(l) carga do Dados.lua no fengari levou ${Math.round(msCarga)} ms (limite 300 ms)`);

if (falhas.length) {
  console.log('checar-dados: FALHAS');
  for (const f of falhas) console.log('  ' + f);
  process.exit(1);
}
console.log('checar-dados: ok');
process.exit(0);
