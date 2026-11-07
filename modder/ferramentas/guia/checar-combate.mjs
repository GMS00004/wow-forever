// Checador estatico de combate e de API para addons do WoW Forever (Lua 5.1, sem interpretador).
// Uso: node checar-combate.mjs <pasta do addon> [--toc] [--prefixos A,B]
// Regras R1..R9 e --toc: ver ARQUITETURA.md (secoes 1 e 2) e o cabecalho de cada regra abaixo.
import { createRequire } from 'node:module';
import { readFileSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const luaparse = require('luaparse');
const aqui = dirname(fileURLToPath(import.meta.url));

// ---------- argumentos ----------
const args = process.argv.slice(2);
const pasta = args.find(a => !a.startsWith('--') && args[args.indexOf(a) - 1] !== '--prefixos');
const usarToc = args.includes('--toc');
const iPref = args.indexOf('--prefixos');
const extras = iPref >= 0 && args[iPref + 1] ? args[iPref + 1].split(',').map(s => s.trim()).filter(Boolean) : [];
if (!pasta) { console.error('uso: node checar-combate.mjs <pasta do addon> [--toc] [--prefixos A,B]'); process.exit(2); }

const PREFIXOS_GLOBAIS = ['GuiaForever', 'UIForever', 'SLASH_GUIAFOREVER', 'SLASH_UIFOREVER', 'BINDING_', ...extras];
const temPrefixo = n => PREFIXOS_GLOBAIS.some(p => n.startsWith(p));
const TERCEIROS = ['TomTom', 'NaowhForever', 'RXP', 'ElvUI', 'LibStub', 'ElvDB', 'ElvPrivateDB', 'ElvCharacterDB', 'Questie', 'QuestieLoader', 'LibQuestieDB', 'UIForever_', 'GuiaForever_'];
const ehTerceiro = n => TERCEIROS.some(p => n.startsWith(p));

// ---------- listas da API ----------
const lerLista = (nome) => readFileSync(join(aqui, 'api-forever', nome), 'utf8');
const aspas = (txt) => new Set([...txt.matchAll(/"([^"\n]+)"/g)].map(m => m[1]));
const globalAPI = aspas(lerLista('GlobalAPI.lua'));
const frameXML = aspas(lerLista('FrameXML.lua'));
const eventos = new Set([...lerLista('Events.lua').matchAll(/"([A-Z][A-Z0-9_]+)"/g)].map(m => m[1]));
const templates = new Set([...lerLista('Templates.lua').matchAll(/\["([^"\n]+)"\]\s*=/g)].map(m => m[1]));

const BASE_PADRAO = `assert collectgarbage dofile error gcinfo getfenv getmetatable ipairs load loadfile loadstring module newproxy next pairs pcall
print rawequal rawget rawset require select setfenv setmetatable tonumber tostring type unpack xpcall _G _VERSION coroutine debug io math os string table bit
strtrim strsplit strjoin strconcat tinsert tremove wipe format date time GetTime hooksecurefunc geterrorhandler issecretvalue debugstack securecall
CreateFrame CreateFont abs ceil floor max min mod sqrt random deg rad sin cos tan asin acos atan atan2 exp log log10 fmod frexp ldexp modf
sort strbyte strchar strfind strlen strlower strmatch strrep strsub strupper gsub gmatch`.split(/\s+/);
const baseOk = new Set(BASE_PADRAO);

const PROTEGIDAS = new Set(['CreateMacro', 'EditMacro', 'DeleteMacro', 'SetBinding', 'SetBindingMacro', 'SetBindingSpell', 'SetBindingClick',
  'SaveBindings', 'PickupAction', 'PlaceAction', 'SetCVar', 'C_CVar.SetCVar', 'SetUIPanelLayoutAttribute', ':SetAttribute', '.SetAttribute']);
const SECRETAS = new Set(['UnitAttackSpeed', 'UnitRangedDamage', 'UnitRangedAttackPower', 'GetUnitSpeed', 'C_Spell.GetSpellCooldown',
  'GetSpellCharges', 'C_Spell.GetSpellCharges']);
const QUENTES = new Set(['COMBAT_LOG_EVENT_UNFILTERED', 'UNIT_AURA', 'SPELL_UPDATE_COOLDOWN']);
const PROIBIDAS = new Set(['C_Traits.PurchaseRank', 'C_Traits.CommitConfig', 'BuyTrainerService', 'CastSpell', 'CastSpellByName', 'CastSpellByID',
  'UseContainerItem', 'C_Container.UseContainerItem', 'LoadAddOn', 'C_AddOns.LoadAddOn']);
const GUARDA_COMBATE = new Set(['emCombate', 'ns.emCombate', 'InCombatLockdown']);

// ---------- utilidades de AST ----------
// caminho de uma expressao: { texto, raiz, global } ou null. Metodo (a:b) vira ':b'.
function caminho(e) {
  if (!e) return null;
  // _G.X e _G["X"] valem como o global X
  if (e.type === 'MemberExpression' && e.indexer === '.' && e.base.type === 'Identifier' && e.base.name === '_G' && e.base.isLocal === false)
    return { texto: e.identifier.name, raiz: e.identifier.name, global: true };
  if (e.type === 'IndexExpression' && e.base.type === 'Identifier' && e.base.name === '_G' && e.base.isLocal === false && e.index.type === 'StringLiteral')
    return { texto: valorString(e.index), raiz: valorString(e.index), global: true };
  if (e.type === 'Identifier') return { texto: e.name, raiz: e.name, global: e.isLocal === false };
  if (e.type === 'MemberExpression') {
    if (e.indexer === ':') return { texto: ':' + e.identifier.name, raiz: null, global: false, metodo: e.identifier.name, base: caminho(e.base) };
    const b = caminho(e.base);
    if (!b || b.metodo) return null;
    return { texto: b.texto + '.' + e.identifier.name, raiz: b.raiz, global: b.global };
  }
  if (e.type === 'IndexExpression') {
    const b = caminho(e.base);
    if (!b || b.metodo) return null;
    if (e.index.type === 'StringLiteral') return { texto: b.texto + '.' + e.index.value, raiz: b.raiz, global: b.global };
    return { texto: b.texto + '.?', raiz: b.raiz, global: b.global };
  }
  return null;
}
const ehString = e => e && e.type === 'StringLiteral';
const valorString = e => (e.value != null ? e.value : String(e.raw).slice(1, -1));
const argsDe = c => c.type === 'CallExpression' ? c.arguments : c.type === 'StringCallExpression' ? [c.argument] : [c.arguments];
const ehCall = n => n.type === 'CallExpression' || n.type === 'StringCallExpression' || n.type === 'TableCallExpression';
const ehFuncao = n => n.type === 'FunctionDeclaration';
const antes = (a, b) => a.line < b.line || (a.line === b.line && a.column <= b.column);

function andar(n, pais, fn) {
  if (!n || typeof n !== 'object') return;
  if (Array.isArray(n)) { for (const x of n) andar(x, pais, fn); return; }
  if (!n.type) return;
  fn(n, pais);
  pais.push(n);
  for (const k in n) if (k !== 'loc' && k !== 'range' && k !== 'comments' && k !== 'globals') andar(n[k], pais, fn);
  pais.pop();
}
function contem(n, pred) {
  let ach = false;
  andar(n, [], x => { if (!ach && pred(x)) ach = true; });
  return ach;
}
// todas as expressoes (sem entrar em funcoes aninhadas) de um no
function semFuncoes(n, fn) {
  (function rec(x) {
    if (!x || typeof x !== 'object') return;
    if (Array.isArray(x)) { x.forEach(rec); return; }
    if (!x.type) return;
    fn(x);
    if (ehFuncao(x)) return;
    for (const k in x) if (k !== 'loc' && k !== 'range') rec(x[k]);
  })(n);
}

// Os "usos" de um caminho: callee de chamada, ou primeiro argumento de pcall/xpcall (referencia protegida).
function usosDe(no, pais) {
  const r = [];
  if (!ehCall(no)) return r;
  const cp = caminho(no.base);
  if (!cp) return r;
  r.push({ cam: cp, no: no.base, chamada: no });
  if (cp.texto === 'pcall' || cp.texto === 'xpcall') {
    const a = argsDe(no)[0];
    const ap = a && caminho(a);
    if (ap) r.push({ cam: ap, no: a, chamada: no, viaPcall: true });
  }
  return r;
}

// ---------- coleta ----------
const arquivos = readdirSync(pasta).filter(f => f.toLowerCase().endsWith('.lua')).sort();
const achados = [];
let erros = 0, avisos = 0;
const reporta = (nivel, arq, linha, regra, msg) => {
  achados.push(`${nivel} ${arq}:${linha} ${regra}: ${msg}`);
  if (nivel === 'ERRO') erros++; else avisos++;
};

const asts = [];
const definidos = new Set(); // globais definidos pelo proprio addon
for (const arq of arquivos) {
  const texto = readFileSync(join(pasta, arq), 'utf8');
  let ast;
  try { ast = luaparse.parse(texto, { luaVersion: '5.1', comments: true, locations: true, scope: true }); }
  catch (e) { reporta('ERRO', arq, e.line || 0, 'SINTAXE', e.message); continue; }
  asts.push({ arq, ast });
  andar(ast, [], (n) => {
    if (n.type === 'AssignmentStatement') for (const v of n.variables) { const c = caminho(v); if (c && c.global && v.type === 'Identifier') definidos.add(c.raiz); }
    if (n.type === 'FunctionDeclaration' && n.identifier && n.identifier.type === 'Identifier' && n.identifier.isLocal === false) definidos.add(n.identifier.name);
  });
}

// ---------- guardas ----------
function condMencionaCombate(cond) {
  return contem(cond, x => ehCall(x) && GUARDA_COMBATE.has((caminho(x.base) || {}).texto));
}
function temReturn(corpo) {
  let ach = false;
  semFuncoes(corpo, x => { if (x.type === 'ReturnStatement') ach = true; });
  return ach;
}
function condMenciona(cond, texto) {
  return contem(cond, x => (x.type === 'Identifier' || x.type === 'MemberExpression' || x.type === 'IndexExpression') && (caminho(x) || {}).texto === texto);
}
function funcaoPai(pais) { for (let i = pais.length - 1; i >= 0; i--) if (ehFuncao(pais[i])) return i; return -1; }

// funcao "externa" para R1: sobe por funcoes passadas como argumento de pcall/xpcall
function funcaoGuardadora(pais) {
  let i = funcaoPai(pais);
  while (i >= 0) {
    const f = pais[i], pai = pais[i - 1];
    const viaPcall = pai && ehCall(pai) && ['pcall', 'xpcall'].includes((caminho(pai.base) || {}).texto) && argsDe(pai)[0] === f;
    const viaForaDeCombate = pai && ehCall(pai) && (caminho(pai.base) || {}).texto === 'ns.foraDeCombate' && argsDe(pai).includes(f);
    if (viaForaDeCombate) return { ok: true };
    if (!viaPcall) return { idx: i, f };
    // sobe para a funcao que contem o pcall
    let j = i - 1;
    while (j >= 0 && !ehFuncao(pais[j])) j--;
    if (j < 0) return { idx: -1, f: null };
    i = j;
  }
  return { idx: -1, f: null };
}

function comentarioAcima(ast, linhas) {
  return (ast.comments || []).some(c => /fora-de-combate/.test(c.value) && linhas.includes(c.loc.end.line + 1) && c.loc.start.line === c.loc.end.line);
}

function guardaR1(ast, no, pais) {
  const g = funcaoGuardadora(pais);
  if (g.ok) return true;
  // forma 3: comentario na linha de cima da chamada, do comando que a contem ou de qualquer funcao envolvente
  const linhas = [no.loc.start.line];
  for (const p of pais) if (ehFuncao(p) || /Statement$/.test(p.type)) linhas.push(p.loc.start.line);
  if (comentarioAcima(ast, linhas)) return true;
  // forma 1: if (emCombate/InCombatLockdown) ... return, antes da chamada, na mesma funcao
  const corpo = g.f ? g.f.body : ast.body;
  let ach = false;
  semFuncoes(corpo, x => {
    if (x.type !== 'IfStatement') return;
    if (!antes(x.loc.end, no.loc.start)) return;
    for (const cl of x.clauses) if (cl.condition && condMencionaCombate(cl.condition) && temReturn(cl.body)) ach = true;
  });
  return ach;
}

function guardaExistencia(texto, chamada, pais) {
  for (let i = pais.length - 1; i >= 0; i--) {
    const p = pais[i], filho = pais[i + 1] || chamada;
    if ((p.type === 'IfClause' || p.type === 'ElseifClause') && p.condition && filho !== p.condition && condMenciona(p.condition, texto)) return true;
    if (p.type === 'LogicalExpression' && p.operator === 'and' && p.right === filho && condMenciona(p.left, texto)) return true;
    // retorno antecipado: um "if ... X.Y ... then return end" antes, no mesmo bloco
    if (Array.isArray(p.body) || p.type === 'Chunk') {
      const lista = Array.isArray(p.body) ? p.body : [];
      for (const s of lista) {
        if (s === filho) break;
        if (s.type === 'IfStatement' && s.clauses.some(cl => cl.condition && condMenciona(cl.condition, texto) && temReturn(cl.body))) return true;
      }
    }
  }
  return false;
}

// ---------- analise ----------
for (const { arq, ast } of asts) {
  const R = (nivel, no, regra, msg) => reporta(nivel, arq, no.loc.start.line, regra, msg);
  andar(ast, [], (n, pais) => {
    // R4: atribuicao a global fora dos prefixos
    if (n.type === 'AssignmentStatement') {
      for (const v of n.variables) {
        const c = caminho(v);
        if (!c || !c.global) continue;
        if (temPrefixo(c.raiz) || c.raiz === 'SlashCmdList' || c.raiz === '_G') continue;
        if (v.type !== 'Identifier' && ehTerceiro(c.raiz)) continue; // campo em dado salvo de terceiro, de proposito
        R('ERRO', v, 'R4', `atribuicao a global fora dos prefixos: ${c.texto}`);
      }
    }
    if (n.type === 'FunctionDeclaration' && n.identifier) {
      const c = caminho(n.identifier);
      if (c && c.global && !temPrefixo(c.raiz) && c.raiz !== 'SlashCmdList') R('ERRO', n, 'R4', `funcao global fora dos prefixos: ${c.texto}`);
    }
    if (!ehCall(n)) return;
    const a = argsDe(n);
    const cp = caminho(n.base);
    const nomeBase = cp ? cp.texto : null;
    const dentroPcall = pais.some((p, i) => ehFuncao(p) && pais[i - 1] && ehCall(pais[i - 1]) && ['pcall', 'xpcall'].includes((caminho(pais[i - 1].base) || {}).texto) && argsDe(pais[i - 1])[0] === p)
      || ['pcall', 'xpcall'].includes(nomeBase);

    // R3: X:SetScript com X global fora dos prefixos
    if (cp && cp.metodo === 'SetScript' && cp.base && cp.base.global && !temPrefixo(cp.base.raiz))
      R('ERRO', n, 'R3', `SetScript em quadro global alheio: ${cp.base.texto}`);

    // R5 e R6: eventos
    let ev = null, viaPcallEv = false;
    if (cp && (cp.metodo === 'RegisterEvent' || cp.metodo === 'RegisterUnitEvent' || nomeBase === 'ns.ao' || nomeBase === 'registrarEvento')) ev = a[0];
    else if (nomeBase === 'pcall' && a[0]) {
      const c0 = caminho(a[0]);
      if (c0 && /\.(RegisterEvent|RegisterUnitEvent)$/.test(c0.texto)) { ev = a[2]; viaPcallEv = true; }
    }
    if (ev) {
      const lits = ehString(ev) ? [ev] : ev.type === 'TableConstructorExpression' ? ev.fields.map(f => f.value).filter(ehString) : [];
      for (const l of lits) {
        const nome = valorString(l);
        if (!/^[A-Z][A-Z0-9_]+$/.test(nome)) continue;
        if (QUENTES.has(nome)) R('ERRO', n, 'R5', `evento quente registrado: ${nome}`);
        else if (!eventos.has(nome)) R(dentroPcall || viaPcallEv ? 'AVISO' : 'ERRO', n, 'R6', `evento inexistente em Events.lua: ${nome}`);
      }
    }

    // R8: templates do CreateFrame
    if (nomeBase === 'CreateFrame' && a[3] && ehString(a[3])) {
      for (const t of valorString(a[3]).split(',').map(s => s.trim()).filter(Boolean))
        if (!templates.has(t)) R('ERRO', n, 'R8', `template inexistente em Templates.lua: ${t}`);
    }

    // usos: R1, R2, R9, R7
    for (const u of usosDe(n, pais)) {
      const t = u.cam.texto;
      const usoNo = u.viaPcall ? u.no : n;
      const ehSetAttr = u.cam.metodo === 'SetAttribute' || t.endsWith('.SetAttribute');
      if (((u.cam.global && PROTEGIDAS.has(t)) || ehSetAttr) && !guardaR1(ast, usoNo, pais))
        R('ERRO', usoNo, 'R1', `chamada protegida sem guarda de combate: ${t}`);
      if (u.cam.global) {
        if (SECRETAS.has(t) || t.startsWith('C_UnitAuras.')) R('ERRO', usoNo, 'R2', `API que devolve valor secreto: ${t}`);
        if (PROIBIDAS.has(t)) R('ERRO', usoNo, 'R9', `chamada proibida pelo contrato: ${t}`);
      }
    }

    // R7: global ou membro de tabela global fora da lista permitida, sem guarda de existencia
    const alvos = [];
    if (cp && !cp.metodo) alvos.push({ cam: cp, no: n.base });
    if (nomeBase === 'pcall' && a[0]) { const c0 = caminho(a[0]); if (c0 && !c0.metodo) alvos.push({ cam: c0, no: a[0] }); }
    for (const al of alvos) {
      const c = al.cam;
      if (!c.global) continue;
      const partes = c.texto.split('.');
      const raiz = partes[0];
      if (baseOk.has(raiz) || ehTerceiro(raiz) || definidos.has(raiz) || temPrefixo(raiz)) continue;
      const chave = partes.length > 1 ? partes[0] + '.' + partes[1] : raiz;
      if (globalAPI.has(chave) || frameXML.has(chave) || globalAPI.has(c.texto) || frameXML.has(c.texto)) continue;
      if (guardaExistencia(c.texto, n, pais) || (chave !== c.texto && guardaExistencia(chave, n, pais))) continue;
      R('ERRO', al.no, 'R7', `fora da API do Forever e sem guarda de existencia: ${c.texto}`);
    }
  });
}

// ---------- toc ----------
if (usarToc) {
  const tocs = readdirSync(pasta).filter(f => f.toLowerCase().endsWith('.toc'));
  if (!tocs.length) reporta('ERRO', '(pasta)', 0, 'TOC', 'nenhum .toc na pasta');
  for (const t of tocs) {
    const lista = readFileSync(join(pasta, t), 'utf8').split(/\r?\n/).map(s => s.trim()).filter(s => s && !s.startsWith('#') && /\.lua$/i.test(s)).map(s => s.replace(/\\/g, '/'));
    const noToc = new Set(lista), naPasta = new Set(arquivos);
    for (const f of noToc) if (!naPasta.has(f)) reporta('ERRO', t, 0, 'TOC', `listado no .toc mas ausente na pasta: ${f}`);
    for (const f of naPasta) if (!noToc.has(f)) reporta('ERRO', t, 0, 'TOC', `esta na pasta mas nao no .toc: ${f}`);
  }
}

const chaveOrd = l => { const m = l.match(/^(S+) (S+):(d+) /); return m ? m[2] + ':' + String(m[3]).padStart(6, '0') + m[1] : l; };
achados.sort((a, b) => chaveOrd(a) < chaveOrd(b) ? -1 : 1);
for (const l of achados) console.log(l);
console.log(`resumo: ${arquivos.length} arquivo(s), ${erros} erro(s), ${avisos} aviso(s)`);
process.exit(erros ? 1 : 0);
