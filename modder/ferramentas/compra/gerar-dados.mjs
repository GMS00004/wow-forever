// Gera addons-proprios/CompraForever/Dados.lua (contrato do addon, secoes 2 e 12.1) a partir de:
//   dados/pregao/receitas-lw.json  (receitas e itens de Leatherworking)
//   dados/pregao/precos.json       (so o campo vendedor: lista de itemIDs do vendedor)
//   dados/pregao/rotas.json        (opcional, esquema 1 do legado.mjs --rotas: vira o campo rotas, secao 12.1)
// Uso: node ferramentas/compra/gerar-dados.mjs
// Sem dependencias fora de ferramentas/pregao/comum.mjs (BUILD e a pasta dados/pregao vem de la).
// Funcao de escrita de Lua copiada de ferramentas/pregao/rota.mjs.
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { BUILD, DADOS } from '../pregao/comum.mjs';

const RAIZ = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const ENTRADA_RECEITAS = join(RAIZ, 'dados', 'pregao', 'receitas-lw.json');
const ENTRADA_PRECOS = join(RAIZ, 'dados', 'pregao', 'precos.json');
const ENTRADA_ROTAS = join(DADOS, 'rotas.json');
const SAIDA = join(RAIZ, 'addons-proprios', 'CompraForever', 'Dados.lua');

// Texto em Lua: barras invertidas e aspas escapadas; controles viram \ddd (checar-lua exige escapes validos).
const escapaLua = (t) => t
  .replace(/\\/g, '\\\\')
  .replace(/"/g, '\\"')
  .replace(/[\x00-\x1f\x7f]/g, (c) => '\\' + String(c.charCodeAt(0)).padStart(3, '0'));
const luaStr = (s) => `"${escapaLua(String(s))}"`;

// Tira acentos (NFD) e troca o que sobrar fora do ASCII por '?'. Conta os trocados.
let naoAscii = 0;
function asciiSeguro(texto) {
  const sem = String(texto).normalize('NFD').replace(/[̀-ͯ]/g, '');
  return sem.replace(/[^\x00-\x7f]/g, () => { naoAscii++; return '?'; });
}
const luaTexto = (s) => luaStr(asciiSeguro(s));

const receitasJson = JSON.parse(readFileSync(ENTRADA_RECEITAS, 'utf8'));
const precosJson = JSON.parse(readFileSync(ENTRADA_PRECOS, 'utf8'));
if (!Array.isArray(precosJson.vendedor)) throw new Error('precos.json: campo vendedor nao e array');
const vendedor = new Set(precosJson.vendedor);

const itensJson = receitasJson.itens;
const todas = receitasJson.receitas;

// Quem produz cada item (magia de menor id, se houver mais de uma).
const produtoras = new Map();
for (const r of todas) {
  const p = r.produto.id;
  if (!produtoras.has(p) || r.magia < produtoras.get(p)) produtoras.set(p, r.magia);
}

// Receitas incluidas: as que vendem o produto, mais as que produzem reagente delas (fabrica).
const porMagia = new Map(todas.map((r) => [r.magia, r]));
const vende = (id) => (itensJson[id]?.vende ?? 0);
const base = todas.filter((r) => vende(r.produto.id) > 0);
const incluidas = new Map(base.map((r) => [r.magia, r]));
for (const r of base) {
  for (const g of r.reagentes) {
    const m = produtoras.get(g.id);
    if (m !== undefined && !incluidas.has(m)) incluidas.set(m, porMagia.get(m));
  }
}

// fabrica: reagente das receitas incluidas -> magia que o produz (um nivel, menor magia).
const fabrica = new Map();
for (const r of incluidas.values()) {
  for (const g of r.reagentes) {
    const m = produtoras.get(g.id);
    if (m !== undefined) fabrica.set(g.id, m);
  }
}

// itens: produtos e reagentes das receitas incluidas.
const idsItens = new Set();
for (const r of incluidas.values()) {
  idsItens.add(r.produto.id);
  for (const g of r.reagentes) idsItens.add(g.id);
}
const faltando = [...idsItens].filter((id) => !itensJson[id]);
if (faltando.length) throw new Error('item sem entrada em itens: ' + faltando.join(', '));

// --- rotas (contrato 12.1), de dados/pregao/rotas.json esquema 1 ---
// Campos do JSON que o 12.1 nao lista saem do Lua e viram AVISO (lista em ignorados).
const ignorados = [];
const soConhecidos = (obj, lista, onde) => {
  for (const k of Object.keys(obj)) if (!lista.includes(k)) ignorados.push(`${onde}${k}`);
  return obj;
};
const vazio = (v) => v === undefined || v === null || v === false;
const luaValor = (v) => {
  if (typeof v === 'string') return luaTexto(v);
  if (typeof v === 'number' || typeof v === 'boolean') return String(v);
  throw new Error(`valor fora do contrato: ${JSON.stringify(v)}`);
};
// "nome = valor", ou null quando o campo e null/undefined/false (nao escreve).
const campo = (nome, v, f = luaValor) => (vazio(v) ? null : `${nome} = ${f(v)}`);
const tabela = (partes) => { const p = partes.filter((x) => x !== null); return p.length ? `{ ${p.join(', ')} }` : '{}'; };
const arranjo = (xs, f) => (xs.length ? `{ ${xs.map((x, i) => f(x, i)).join(', ')} }` : '{}');
const ordenaChaves = (ks) => [...ks].sort((a, b) => {
  const na = /^\d+$/.test(a), nb = /^\d+$/.test(b);
  if (na && nb) return Number(a) - Number(b);
  if (na !== nb) return na ? -1 : 1;
  return a < b ? -1 : a > b ? 1 : 0;
});
const chaveLua = (k) => {
  if (/^\d+$/.test(k)) return `[${k}]`;
  if (/^[A-Za-z_][A-Za-z0-9_]*$/.test(k)) return k;
  throw new Error(`chave fora do contrato: ${k}`);
};
const entradas = (obj, f) => ordenaChaves(Object.keys(obj)).map((k) => `${chaveLua(k)} = ${f(obj[k], k)}`);
const reagenteLua = (g) => {
  if (!Array.isArray(g) || g.length !== 2) throw new Error(`reagente fora do esquema: ${JSON.stringify(g)}`);
  return `{ ${luaValor(g[0])}, ${luaValor(g[1])} }`;
};
const FONTE_ROTA = ['tipo', 'em', 'n'];
const fonteRotaLua = (f) => {
  soConhecidos(f, FONTE_ROTA, 'fonte.');
  return tabela([campo('tipo', f.tipo), campo('em', f.em), campo('n', f.n)]);
};
const itemRotaLua = (it, id) => {
  soConhecidos(it, ['nome', 'vende', 'pilha', 'vinculo'], `itens.${id}.`);
  return tabela([campo('nome', it.nome), campo('vende', it.vende), campo('pilha', it.pilha), campo('vinculo', it.vinculo)]);
};
const NIVEL_POR_TETO = { 150: 10, 225: 20, 300: 35 }; // comum\referencia\profissoes-forever.md:28
const rankLua = (r, onde) => {
  soConhecidos(r, ['nome', 'cap', 'pericia', 'custo', 'nivel'], onde);
  const nivel = r.nivel ?? NIVEL_POR_TETO[r.cap] ?? null;
  return tabela([campo('nome', r.nome), campo('cap', r.cap), campo('pericia', r.pericia), campo('custo', r.custo), campo('nivel', nivel)]);
};
const ferramentaLua = (f, onde) => {
  soConhecidos(f, ['nome', 'itens'], onde);
  return tabela([campo('nome', f.nome), campo('itens', f.itens, (x) => arranjo(x, luaValor))]);
};
const receitaLua = (r, onde) => {
  soConhecidos(r, ['nome', 'produto', 'qtd', 'reagentes', 'amarela', 'cinza', 'pontos', 'aprende', 'origem', 'treino',
    'ferramentas', 'foco', 'acampamento', 'padrao', 'encantar'], onde);
  return tabela([
    campo('nome', r.nome),
    campo('produto', r.produto),
    campo('qtd', r.qtd),
    campo('reagentes', r.reagentes, (rs) => arranjo(rs, reagenteLua)),
    campo('amarela', r.amarela),
    campo('cinza', r.cinza),
    campo('pontos', r.pontos),
    campo('aprende', r.aprende),
    campo('origem', r.origem),
    campo('treino', r.treino),
    campo('padrao', r.padrao),
    campo('ferramentas', r.ferramentas, (fs) => arranjo(fs, (f, i) => ferramentaLua(f, `${onde}.ferramentas[${i}].`))),
    campo('foco', r.foco),
    campo('acampamento', r.acampamento, (a) => { soConhecidos(a, ['nome', 'itens'], `${onde}.acampamento.`); return tabela([campo('nome', a.nome), campo('itens', a.itens, (x) => arranjo(x, luaValor))]); }),
    r.encantar === true ? 'encantar = true' : null,
  ]);
};
const passoLua = (p, onde) => {
  soConhecidos(p, ['magia', 'de', 'ate', 'crafts'], onde);
  return tabela([campo('magia', p.magia), campo('de', p.de), campo('ate', p.ate), campo('crafts', p.crafts)]);
};
const fonteLua = (f, onde) => {
  soConhecidos(f, ['f', 'magia', 'qtd', 'custo', 'teto', 'preco'], onde);
  return tabela([campo('f', f.f), campo('magia', f.magia), campo('qtd', f.qtd), campo('custo', f.custo), campo('teto', f.teto), campo('preco', f.preco)]);
};
const trechoLua = (t, onde) => {
  soConhecidos(t, ['de', 'ate', 'chegou', 'passos', 'fontes', 'totais'], onde);
  return tabela([
    campo('de', t.de),
    campo('ate', t.ate),
    campo('chegou', t.chegou),
    `passos = ${arranjo(t.passos ?? [], (p, i) => passoLua(p, `${onde}.passos[${i}].`))}`,
    `fontes = ${tabela(entradas(t.fontes ?? {}, (f, k) => fonteLua(f, `${onde}.fontes[${k}].`)))}`,
    campo('totais', t.totais, (tt) => { soConhecidos(tt, ['custo', 'crafts', 'craftsExtra'], `${onde}.totais.`); return tabela([campo('custo', tt.custo), campo('crafts', tt.crafts), campo('craftsExtra', tt.craftsExtra)]); }),
  ]);
};
function profLinhas(slug, p, onde) {
  soConhecidos(p, ['nome', 'curto', 'linha', 'ranks', 'receitas', 'trechos'], onde);
  const out = [`      ${chaveLua(slug)} = {`];
  out.push(`        ${[campo('nome', p.nome), campo('curto', p.curto), campo('linha', p.linha)].filter(Boolean).join(', ')},`);
  out.push(`        ranks = ${arranjo(p.ranks ?? [], (r, i) => rankLua(r, `${onde}ranks[${i}].`))},`);
  out.push('        receitas = {');
  const rec = p.receitas ?? {};
  for (const magia of ordenaChaves(Object.keys(rec))) out.push(`          ${chaveLua(magia)} = ${receitaLua(rec[magia], `${onde}receitas[${magia}]`)},`);
  out.push('        },');
  out.push('        trechos = {');
  (p.trechos ?? []).forEach((t, i) => out.push(`          ${trechoLua(t, `${onde}trechos[${i}].`)},`));
  out.push('        },');
  out.push('      },');
  return out;
}
// Devolve as linhas do campo rotas (com a indentacao de CompraForeverDados) e os contadores do resumo.
function rotasLua(r) {
  soConhecidos(r, ['esquema', 'geradoEm', 'fonte', 'credito', 'treinoAte', 'itens', 'profs'], '');
  const cab = ['versao = 1', campo('geradoEm', r.geradoEm)].filter(Boolean).join(', ');
  const topo = [
    campo('fonte', r.fonte, fonteRotaLua),
    campo('credito', r.credito),
    campo('treinoAte', r.treinoAte),
  ].filter(Boolean);
  const linhas = ['  rotas = {', `    ${cab},`];
  if (topo.length) linhas.push(`    ${topo.join(', ')},`);
  linhas.push('    itens = {');
  const itens = r.itens ?? {};
  for (const id of ordenaChaves(Object.keys(itens))) linhas.push(`      ${chaveLua(id)} = ${itemRotaLua(itens[id], id)},`);
  linhas.push('    },');
  linhas.push('    profs = {');
  const profs = r.profs ?? {};
  for (const slug of ordenaChaves(Object.keys(profs))) linhas.push(...profLinhas(slug, profs[slug], `profs.${slug}.`));
  linhas.push('    },');
  linhas.push('  },');
  const passos = Object.values(profs).reduce((n, p) => n + (p.trechos ?? []).reduce((m, t) => m + (t.passos ?? []).length, 0), 0);
  return { linhas, profs: Object.keys(profs).length, passos, itens: Object.keys(itens).length };
}

let rot = { linhas: [], profs: 0, passos: 0, itens: 0 };
if (!existsSync(ENTRADA_ROTAS)) console.log('AVISO sem rotas.json');
else {
  const rj = JSON.parse(readFileSync(ENTRADA_ROTAS, 'utf8'));
  if (rj.esquema !== 1) console.log(`AVISO rotas.json com esquema ${rj.esquema} (o gerador le o esquema 1): sem rotas`);
  else {
    rot = rotasLua(rj);
    if (ignorados.length) console.log(`AVISO rotas.json: ${ignorados.length} campo(s) fora do 12.1 ignorados: ${ignorados.join(', ')}`);
  }
}

const ordem = (a, b) => a - b;
const L = [];
L.push('-- CompraForever: generated by ferramentas/compra/gerar-dados.mjs; do not edit by hand.');
const agora = new Date();
const pad = (n) => String(n).padStart(2, '0');
const geradoEm = `${agora.getFullYear()}-${pad(agora.getMonth() + 1)}-${pad(agora.getDate())} ${pad(agora.getHours())}:${pad(agora.getMinutes())}`;
L.push('CompraForeverDados = {');
L.push(`  build = ${luaStr(BUILD)}, geradoEm = ${luaStr(geradoEm)},`);
L.push('  receitas = {');
for (const magia of [...incluidas.keys()].sort(ordem)) {
  const r = incluidas.get(magia);
  const regs = r.reagentes.map((g) => `{ ${g.id}, ${g.qtd} }`).join(', ');
  L.push(`    [${magia}] = { nome = ${luaTexto(r.nome)}, produto = ${r.produto.id}, qtd = ${r.produto.qtd}, reagentes = { ${regs} } },`);
}
L.push('  },');
L.push('  itens = {');
let vendedores = 0;
for (const id of [...idsItens].sort(ordem)) {
  const it = itensJson[id];
  const pilha = it.pilha ?? 1;
  const v = it.vende ?? 0;
  let extra = '';
  // Vendedor so para suprimento comum (linha, tinta, alvejante, sal), vendido sem limite em toda cidade. Couro e
  // outros itens da lista publica de vendedor sao de estoque limitado e caros: ficam so no leilao (decisao 2026-11-17).
  const comum = /( Thread| Dye)$|^(Bleach|Salt)$/.test(it.nome || '');
  if (comum && vendedor.has(id) && (it.compra ?? 0) > 0) { extra = `, vendedor = ${it.compra}`; vendedores++; }
  L.push(`    [${id}] = { nome = ${luaTexto(it.nome)}, vende = ${v}, pilha = ${pilha}${extra} },`);
}
L.push('  },');
const fabEntradas = [...fabrica.keys()].sort(ordem).map((k) => `[${k}] = ${fabrica.get(k)}`);
L.push(`  fabrica = { ${fabEntradas.join(', ')} },`);
for (const l of rot.linhas) L.push(l);
L.push('}');
L.push('');

writeFileSync(SAIDA, L.join('\n'), 'utf8');
console.log(`receitas=${incluidas.size} itens=${idsItens.size} fabrica=${fabrica.size} vendedor=${vendedores} rotas=${rot.profs} passos=${rot.passos} itensRota=${rot.itens} naoAscii=${naoAscii}`);
console.log(`gravado: ${SAIDA}`);
