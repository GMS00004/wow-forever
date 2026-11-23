// Leitura da tabela de receitas do Naowh Forever (CONTRATO.md, secao 10.2). Decisao do dono em 2026-11-23: a pericia
// de aprender, a origem e o custo de treino de cada receita vem do RecipeData.lua do NaowhForever_Professions
// instalado ("by hand from Wowhead Forever", README do autor). So leitura, na hora: nada do arquivo e copiado
// para o projeto. Sem dependencia: um leitor proprio do subconjunto de Lua do arquivo (tabelas, numeros, textos,
// true, false e nil; comentarios com --).
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { pastaAddOns } from './comum.mjs';

// Tabela Lua -> JS. So posicional vira array; so com chave vira objeto; misto vira objeto com __lista.
export function lerTabelaLua(texto, inicio = 0) {
  let i = inicio;
  const erro = (m) => { throw new Error(`RecipeData: ${m} (posicao ${i})`); };
  function ws() {
    for (;;) {
      while (i < texto.length && /\s/.test(texto[i])) i++;
      if (texto[i] === '-' && texto[i + 1] === '-') {
        if (texto[i + 2] === '[' && texto[i + 3] === '[') {
          const f = texto.indexOf(']]', i + 4);
          i = f < 0 ? texto.length : f + 2;
        } else {
          const f = texto.indexOf('\n', i);
          i = f < 0 ? texto.length : f + 1;
        }
        continue;
      }
      return;
    }
  }
  function str() {
    const q = texto[i++];
    let s = '';
    while (i < texto.length && texto[i] !== q) {
      if (texto[i] === '\\') {
        const c = texto[i + 1];
        s += c === 'n' ? '\n' : c === 't' ? '\t' : c;
        i += 2;
      } else s += texto[i++];
    }
    if (texto[i] !== q) erro('texto sem fim');
    i++;
    return s;
  }
  function num() {
    const m = /^-?(?:0x[0-9a-fA-F]+|\d+\.?\d*(?:[eE][-+]?\d+)?|\.\d+)/.exec(texto.slice(i, i + 40));
    if (!m) erro('numero invalido');
    i += m[0].length;
    return Number(m[0]);
  }
  function valor() {
    ws();
    const c = texto[i];
    if (c === '{') return tabela();
    if (c === '"' || c === "'") return str();
    if (c === '-' || c === '.' || (c >= '0' && c <= '9')) return num();
    const m = /^[A-Za-z_][A-Za-z0-9_]*/.exec(texto.slice(i, i + 64));
    if (m && (m[0] === 'true' || m[0] === 'false' || m[0] === 'nil')) {
      i += m[0].length;
      return m[0] === 'true' ? true : m[0] === 'false' ? false : null;
    }
    return erro(`valor inesperado "${texto.slice(i, i + 20)}"`);
  }
  function tabela() {
    i++; // {
    const lista = [];
    const obj = {};
    let comChave = false;
    for (;;) {
      ws();
      if (i >= texto.length) erro('tabela sem fim');
      if (texto[i] === '}') { i++; break; }
      let chave;
      if (texto[i] === '[') {
        i++;
        chave = valor();
        ws();
        if (texto[i] !== ']') erro('esperava ]');
        i++;
        ws();
        if (texto[i] !== '=') erro('esperava =');
        i++;
      } else {
        const m = /^[A-Za-z_][A-Za-z0-9_]*/.exec(texto.slice(i, i + 64));
        if (m) {
          let j = i + m[0].length;
          while (/\s/.test(texto[j])) j++;
          if (texto[j] === '=' && texto[j + 1] !== '=') {
            chave = m[0];
            i = j + 1;
          }
        }
      }
      const v = valor();
      if (chave === undefined) lista.push(v);
      else {
        obj[String(chave)] = v;
        comChave = true;
      }
      ws();
      if (texto[i] === ',' || texto[i] === ';') i++;
    }
    if (!comChave) return lista;
    if (lista.length) obj.__lista = lista;
    return obj;
  }
  ws();
  if (texto[i] !== '{') erro('esperava {');
  const v = tabela();
  return { valor: v, fim: i };
}

// O RecipeData.lua inteiro: a tabela atribuida a ns.RecipeData, por ID de SkillLine.
export function lerRecipeData(texto) {
  const i0 = texto.indexOf('ns.RecipeData');
  if (i0 < 0) throw new Error('RecipeData: ns.RecipeData nao achado');
  const i1 = texto.indexOf('{', i0);
  return lerTabelaLua(texto, i1).valor;
}

// Dados de uma profissao: receitas por magia e os niveis de treino. Funcao pura.
// Cada receita: { aprende, origem, custo, padrao, produto, amarela, cinza, lados }. lados sao as faccoes dos
// vendedores do padrao ("A", "H" ou "AH"), da lista vendors ou sellers do autor.
export function naowhDaProfissao(dados, skillLine) {
  const p = dados?.[String(skillLine)];
  if (!p || typeof p !== 'object') return null;
  const receitas = new Map();
  const lista = Array.isArray(p.recipes) ? p.recipes : [];
  for (const r of lista) {
    if (!r || typeof r !== 'object' || r.spell == null) continue;
    const magia = Number(r.spell);
    if (receitas.has(magia)) continue;
    const lados = new Set();
    for (const vend of [r.vendors, r.sellers]) {
      if (!Array.isArray(vend)) continue;
      for (const v of vend) if (Array.isArray(v) && typeof v[2] === 'string') lados.add(v[2]);
    }
    receitas.set(magia, {
      aprende: typeof r.skill === 'number' ? r.skill : null,
      origem: typeof r.source === 'string' ? r.source : null,
      custo: typeof r.cost === 'number' ? r.cost : null,
      padrao: typeof r.recipe === 'number' ? r.recipe : null,
      produto: typeof r.item === 'number' ? r.item : null,
      amarela: typeof r.yellow === 'number' ? r.yellow : null,
      cinza: typeof r.grey === 'number' ? r.grey : null,
      lados: [...lados].sort(),
    });
  }
  const ranks = (Array.isArray(p.ranks) ? p.ranks : [])
    .filter((k) => k && typeof k === 'object')
    .map((k) => ({
      cap: typeof k.cap === 'number' ? k.cap : null,
      pericia: typeof k.skill === 'number' ? k.skill : null,
      custo: typeof k.cost === 'number' ? k.cost : null,
      nivel: typeof k.level === 'number' ? k.level : null,
      nome: typeof k.name === 'string' ? k.name : null,
    }));
  return { receitas, ranks };
}

// VendorReagents.lua: "the reagents trade-goods vendors sell for gold without limit, by item ID" (o autor). Devolve o
// Set dos IDs com valor true. Funcao pura.
export function lerVendorReagents(texto) {
  const ids = new Set();
  const i0 = texto.indexOf('VendorReagents');
  if (i0 < 0) return ids;
  const t = lerTabelaLua(texto, texto.indexOf('{', i0)).valor;
  for (const [k, v] of Object.entries(Array.isArray(t) ? {} : t)) if (v === true && /^\d+$/.test(k)) ids.add(Number(k));
  return ids;
}

// Le o RecipeData.lua, o VendorReagents.lua e a versao do TOC do NaowhForever_Professions instalado. Sem o addon,
// devolve null; sem o VendorReagents.lua, reagentesIlimitados sai null.
export async function carregarNaowh() {
  const pasta = path.join(await pastaAddOns(), 'NaowhForever_Professions');
  let texto, toc;
  try {
    texto = await readFile(path.join(pasta, 'Data', 'RecipeData.lua'), 'utf8');
    toc = await readFile(path.join(pasta, 'NaowhForever_Professions.toc'), 'utf8');
  } catch (e) {
    if (e.code === 'ENOENT') return null;
    throw e;
  }
  let reagentesIlimitados = null;
  try {
    reagentesIlimitados = lerVendorReagents(await readFile(path.join(pasta, 'Data', 'VendorReagents.lua'), 'utf8'));
  } catch (e) {
    if (e.code !== 'ENOENT') throw e;
  }
  const versao = (/^##\s*Version:\s*(.+?)\s*$/m.exec(toc) || [])[1] || null;
  return { versao, dados: lerRecipeData(texto), reagentesIlimitados };
}
