// Checador estatico das regras de leilao do PregaoForever (Lua; sem interpretador).
// Uso: node pregao/checar-pregao.mjs <pasta do addon>
// Le os .lua do primeiro nivel da pasta, analisa cada um com luaparse (luaVersion 5.1) e imprime uma linha
// por achado, "<arquivo>:<linha> R<nn> <texto>", e no fim "RESUMO arquivos=<n> erros=<e>". Sai 0 so com erros=0.
// Regras: ARQUITETURA.md (regras 3 a 15 e 20) e DESIGN.md, paragrafo "Checadores estaticos" (I2, I9).
// R00 e a sintaxe (nem 5.1 nem 5.3). R21 e o alcance de tecla_ por timer, OnUpdate ou evento.
//
// APROXIMACOES (o que de fato se confere; o resto e dinamico, da bancada, ou revisao da sessao principal):
// R03 tratador de SetScript/HookScript (qualquer script, exceto nil) e de C_Timer.After/NewTimer/NewTicker
//     tem de ser ns.seguro(...) escrito direto no argumento. Nome guardado em variavel nao e seguido: achado.
// R04 SetScript, AddNamedTab, AddTab e SetTabSystem em quadro global sem prefixo do addon, e atribuicao a campo
//     de tabela global sem prefixo (SlashCmdList e o prefixo PregaoForever/SLASH_PREGAOFOREVER/BINDING_ passam).
//     HookScript e hooksecurefunc passam; isso e a lista dos quatro ganchos.
// R05 nome de addon de terceiro (lista TERCEIROS, com _ depois) como raiz de identificador ou como texto exato:
//     so em Pontes.lua, e so dentro de pcall/xpcall. Nao resolve o que o nome aponta.
// R06 em Acoes.lua: as 8 funcoes de acao so dentro de funcao tecla_*; sem C_Timer, RegisterEvent,
//     RegisterUnitEvent e "OnUpdate". Fora de Acoes.lua: nenhuma funcao de acao (chamada, referencia ou definicao),
//     e nenhuma referencia a tecla_* fora dela sem estar dentro de SetScript("OnClick", ...).
// R07 por tecla_*: no caminho de execucao, no maximo uma funcao de acao (if conta o maior ramo; laco que tem
//     acao conta como duas). PostItem: o terceiro argumento tem de ser o literal 1. ASSUNCAO: a posicao da
//     quantidade (indice 2) segue a referencia da API; confirmar contra ela antes do portao.
// R08 cada referencia a funcao de acao numa tecla_* precisa ter, antes dela no mesmo tecla_*, chamadas a
//     Cofre.autoriza e a Livro.intencao. Confere so a ordem no texto, nao que o retorno foi checado.
// R09 funcoes de consulta (as 9 da regra 9) so em Pedidos.lua. Folego e T_pulso sao dinamicos (I9).
// R10 nome proibido como trecho de identificador (inclui formas com C_); trecho em texto literal (inclui
//     "EditBox" em CreateFrame e "MOUSEWHEEL"); ':Click(' como metodo.
// R12 (a) SetFont e CreateFont: fonte fora do padrao; (b) funcao com SetTextColor e sem SetText nem
//     SetFormattedText no proprio corpo: estado so em cor. Nao confere: 5 linhas, "Show N more", tooltip.
// R13 teto duro (segmento Tetos, TETO_* ou teto + maiuscula) so atribuido em Tetos.lua; ritmo (segmento com
//     PorMinuto, ou T_pulso) so em Config.lua e Calibrado.lua; nivel concedido (segmento com "concedid") so
//     atribuido como math.min do proprio campo, fora de Config.lua e Calibrado.lua. Nao confere "so aperta"
//     nem "so de dinheiro".
// R14 unpack e bit como globais; ".." com "/" de operando, ou tostring(a / b); construcao so de 5.3 (//, bit,
//     goto, label): o parse 5.1 falha, o script refaz com 5.3 e acha pelo AST. Arquivos puros (Estimadores.lua,
//     Motor.lua, Sombra.lua) so usam locais e globais de Lua comum (LUA_OK); nenhum global do jogo nem do addon.
// R15 atribuicao a campo do banco (segmento PregaoForeverDB, PregaoForeverCharDB, banco, pers, diario) com
//     GetTime, GetTimePreciseSec ou debugprofilestop no alvo ou no valor. Nao segue hora guardada em variavel.
// R20 no banco: playerName em qualquer lugar; owners e nomes de jogador (seller, bidder, owner...) no alvo;
//     como valor, so se o valor for o proprio nome (nao #owners, que e contagem).
// R21 funcao alcancada por entrada (SetScript OnUpdate ou OnEvent, C_Timer) chega a um nome tecla_*. Alcance
//     por nome: qualquer nome do addon citado no corpo alcancado entra no caminho. Sem resolver tabela, entao
//     um nome igual em dois lugares gera achado (conservador).
//
// Codigos de saida: 0 sem achados; 1 com achados; 2 uso errado.
import { createRequire } from 'node:module';
import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { join } from 'node:path';

const require = createRequire(import.meta.url);
const luaparse = require('luaparse');

const pasta = process.argv[2];
if (!pasta || !existsSync(pasta) || !statSync(pasta).isDirectory()) {
  console.error('uso: node pregao/checar-pregao.mjs <pasta do addon>');
  process.exit(2);
}

// ---------- listas ----------
const PREFIXOS = ['PregaoForever', 'SLASH_PREGAOFOREVER', 'BINDING_'];
const prefixado = n => PREFIXOS.some(p => n.startsWith(p));
const ACOES = new Set(['PostItem', 'PostCommodity', 'ConfirmPostItem', 'ConfirmPostCommodity', 'PlaceBid',
  'StartCommoditiesPurchase', 'CancelAuction', 'ConfirmCommoditiesPurchase']);
const CONSULTAS = new Set(['SendBrowseQuery', 'RequestMoreBrowseResults', 'SendSearchQuery', 'SendSellSearchQuery',
  'RefreshCommoditySearchResults', 'RefreshItemSearchResults', 'RequestMoreCommoditySearchResults',
  'RequestMoreItemSearchResults', 'QueryOwnedAuctions']);
const PROIBIDOS = ['TakeInboxMoney', 'TakeInboxItem', 'TakeInboxTextItem', 'AutoLootMailItem', 'DeleteInboxItem',
  'ReturnInboxItem', 'SetOpeningAll', 'SendMail', 'BuyMerchantItem', 'BuybackItem', 'SellAllJunkItems',
  'UseContainerItem', 'DeleteCursorItem', 'SetCVar', 'SetBinding', 'SaveBindings', 'RunScript', 'RunMacro',
  'RunMacroText', 'loadstring', 'EditBox', 'SendChatMessage', 'SendAddonMessage', 'RegisterAddonMessagePrefix',
  'QueryBids', 'SearchForItemKeys', 'SearchForFavorites', 'RequestOwnedAuctionBidderInfo', 'ReplicateItems',
  'CancelSell'];
const PROIBIDOS_TEXTO = [...PROIBIDOS, 'MOUSEWHEEL'];
const TERCEIROS = ['Auctionator', 'TradeSkillMaster', 'TSM', 'Oribos', 'Auctioneer', 'AuctionDB', 'TomTom', 'ElvUI',
  'LibStub', 'Questie', 'RXP', 'NaowhForever'];
const ehTerceiro = n => TERCEIROS.some(t => n === t || n.startsWith(t + '_'));
const BANCO = /^(PregaoForeverDB|PregaoForeverCharDB|banco|Banco|pers|diario|Diario)$/;
const NOMES_JOGADOR = new Set(['owners', 'owner', 'ownername', 'seller', 'sellername', 'bidder', 'biddername',
  'highbidder', 'highbiddername']);
const RELOGIOS = ['GetTime', 'GetTimePreciseSec', 'debugprofilestop'];
const RITMO = n => /PorMinuto/.test(n) || n === 'T_pulso';
const TETO = n => n === 'Tetos' || /^TETO_/.test(n) || /^teto[A-Z]/.test(n);
const CONCEDIDO = n => /concedid/i.test(n);
const PUROS = ['estimadores.lua', 'motor.lua', 'sombra.lua'];
const LUA_OK = new Set(['assert', 'error', 'ipairs', 'next', 'pairs', 'pcall', 'xpcall', 'select', 'tonumber',
  'tostring', 'type', 'rawget', 'rawset', 'rawequal', 'setmetatable', 'getmetatable', 'math', 'string', 'table']);
const POS_QTD_POSTITEM = 2; // terceiro argumento (indice 0-based); ver a assuncao no cabecalho
const OPS_53 = new Set(['//', '&', '|', '~', '<<', '>>']);

// ---------- AST ----------
const PULAR = {
  MemberExpression: ['identifier'],
  TableKeyString: ['key'],
  FunctionDeclaration: ['identifier', 'parameters'],
  LocalStatement: ['variables'],
  ForNumericStatement: ['variable'],
  ForGenericStatement: ['variables'],
  GotoStatement: ['label'],
  LabelStatement: ['label'],
};
const IGNORAR = new Set(['type', 'loc', 'range', 'comments', 'globals', 'scope', 'raw']);
function chaves(n, pular = true) {
  const pulados = pular ? (PULAR[n.type] || []) : [];
  return Object.keys(n).filter(k => !IGNORAR.has(k) && !pulados.includes(k));
}
// percorre os nos; cb(no, ancestrais). Com pular, nao entra em nomes de declaracao nem no nome de campo.
function percorrer(n, cb, pais = [], pular = true) {
  if (!n || typeof n !== 'object') return;
  if (Array.isArray(n)) { for (const x of n) percorrer(x, cb, pais, pular); return; }
  if (!n.type) return;
  cb(n, pais);
  pais.push(n);
  for (const k of chaves(n, pular)) percorrer(n[k], cb, pais, pular);
  pais.pop();
}
// nos do corpo sem entrar em funcoes aninhadas
function diretas(n, saida = []) {
  if (!n || typeof n !== 'object') return saida;
  if (Array.isArray(n)) { for (const x of n) diretas(x, saida); return saida; }
  if (!n.type || n.type === 'FunctionDeclaration') return saida;
  saida.push(n);
  for (const k of chaves(n)) diretas(n[k], saida);
  return saida;
}
const ehChamada = n => n.type === 'CallExpression' || n.type === 'StringCallExpression' || n.type === 'TableCallExpression';
const argsDe = c => c.type === 'CallExpression' ? c.arguments
  : c.type === 'StringCallExpression' ? [c.argument]
  : c.type === 'TableCallExpression' ? [c.arguments] : [];
const ehString = e => !!e && e.type === 'StringLiteral';
const valorString = e => (e.value != null ? e.value : String(e.raw).slice(1, -1));
const antes = (a, b) => a.line < b.line || (a.line === b.line && a.column < b.column);

// caminho de uma expressao: texto ("a.b.c"), raiz, global (raiz sem local) e metodo (para a:b)
function caminho(e) {
  if (!e) return null;
  if (e.type === 'Identifier') return { texto: e.name, raiz: e.name, global: e.isLocal === false, metodo: null };
  if (e.type === 'MemberExpression') {
    if (e.indexer === ':') {
      const base = caminho(e.base);
      return { texto: ':' + e.identifier.name, raiz: base ? base.raiz : null, global: base ? base.global : false,
        metodo: e.identifier.name, base };
    }
    if (e.base.type === 'Identifier' && e.base.name === '_G' && e.base.isLocal === false)
      return { texto: e.identifier.name, raiz: e.identifier.name, global: true, metodo: null };
    const b = caminho(e.base);
    if (!b || b.metodo) return null;
    return { texto: b.texto + '.' + e.identifier.name, raiz: b.raiz, global: b.global, metodo: null };
  }
  if (e.type === 'IndexExpression') {
    const idx = e.index.type === 'StringLiteral' ? valorString(e.index) : '?';
    if (e.base.type === 'Identifier' && e.base.name === '_G' && e.base.isLocal === false && idx !== '?')
      return { texto: idx, raiz: idx, global: true, metodo: null };
    const b = caminho(e.base);
    if (!b || b.metodo) return null;
    return { texto: b.texto + '.' + idx, raiz: b.raiz, global: b.global, metodo: null };
  }
  return null;
}
const nomeDeAlvo = e => {
  if (!e) return null;
  if (e.type === 'Identifier') return e.name;
  if (e.type === 'MemberExpression') return e.identifier.name;
  if (e.type === 'IndexExpression' && e.index.type === 'StringLiteral') return valorString(e.index);
  return null;
};
// nome de uma funcao: pelo identificador, ou pelo alvo da atribuicao/local que a guarda
function nomeDeFuncao(f, pais) {
  if (f.identifier) return nomeDeAlvo(f.identifier);
  const pai = pais[pais.length - 1];
  if (pai && (pai.type === 'AssignmentStatement' || pai.type === 'LocalStatement') && pai.init) {
    const i = pai.init.indexOf(f);
    if (i >= 0) return nomeDeAlvo(pai.variables[i]);
  }
  return null;
}
// funcao tecla_ mais proxima entre os ancestrais
function funcaoTecla(pais) {
  for (let i = pais.length - 1; i >= 0; i--) {
    const p = pais[i];
    if (p.type !== 'FunctionDeclaration') continue;
    const nm = nomeDeFuncao(p, pais.slice(0, i));
    if (nm && nm.startsWith('tecla_')) return p;
  }
  return null;
}
const ehSetScriptOnClick = p => {
  if (!ehChamada(p)) return false;
  const cp = caminho(p.base) || {};
  const a = argsDe(p);
  return cp.metodo === 'SetScript' && ehString(a[0]) && valorString(a[0]) === 'OnClick';
};
const ehSeguro = e => !!e && e.type === 'CallExpression' && (caminho(e.base) || {}).texto === 'ns.seguro';
const ehPcall = pais => pais.some(p => ehChamada(p) && ['pcall', 'xpcall'].includes((caminho(p.base) || {}).texto));
// acao em um no que e campo (a.PostItem) ou identificador
const nomeRef = n => n.type === 'Identifier' ? n.name : n.type === 'MemberExpression' ? n.identifier.name : null;
// contagem de funcoes de acao no caminho de execucao: if pega o maior ramo; laco com acao conta como duas
function contaCaminho(n) {
  if (!n || typeof n !== 'object') return 0;
  if (Array.isArray(n)) return n.reduce((s, x) => s + contaCaminho(x), 0);
  if (!n.type) return 0;
  if (n.type === 'IfStatement') {
    let cond = 0, melhor = 0;
    for (const cl of n.clauses) {
      if (cl.condition) cond += contaCaminho(cl.condition);
      melhor = Math.max(melhor, contaCaminho(cl.body));
    }
    return cond + melhor;
  }
  if (['WhileStatement', 'RepeatStatement', 'ForNumericStatement', 'ForGenericStatement'].includes(n.type))
    return contaCaminho(n.body) > 0 ? 2 : 0;
  if (n.type === 'MemberExpression') {
    const acao = ACOES.has(n.identifier.name);
    return (acao ? 1 : 0) + contaCaminho(n.base);
  }
  if (n.type === 'Identifier') return ACOES.has(n.name) ? 1 : 0;
  let s = 0;
  for (const k of chaves(n)) s += contaCaminho(n[k]);
  return s;
}
const memo = new Map();
function nomesEm(n) {
  const s = new Set();
  percorrer(n, x => { if (x.type === 'Identifier') s.add(x.name); }, [], false);
  return s;
}
function nomesDoCorpo(f) {
  if (!memo.has(f)) memo.set(f, nomesEm(f.body));
  return memo.get(f);
}

// ---------- coleta dos arquivos ----------
const arquivos = readdirSync(pasta).filter(f => f.toLowerCase().endsWith('.lua')).sort();
const achados = []; // { arq, linha, regra, msg }
const ach = (arq, linha, regra, msg) => achados.push({ arq, linha, regra, msg });
const analisados = [];
for (const arq of arquivos) {
  const texto = readFileSync(join(pasta, arq), 'utf8');
  const opc = v => ({ luaVersion: v, locations: true, scope: true, comments: false });
  let ast, ver = '5.1', e51 = null;
  try { ast = luaparse.parse(texto, opc('5.1')); }
  catch (err51) {
    try { ast = luaparse.parse(texto, opc('5.3')); ver = '5.3'; e51 = err51; }
    catch (err53) { ach(arq, err53.line || 0, 0, `sintaxe (5.1 e 5.3): ${err53.message}`); continue; }
  }
  analisados.push({ arq, ast, ver, e51 });
}
if (!arquivos.length) ach('(pasta)', 0, 0, 'nenhum .lua no primeiro nivel da pasta');

// definicoes e entradas (R21), de todos os arquivos
const defs = new Map();
const entradas = [];
for (const { arq, ast } of analisados) {
  percorrer(ast, (n, pais) => {
    if (n.type === 'FunctionDeclaration') {
      const nm = nomeDeFuncao(n, pais);
      if (nm) { if (!defs.has(nm)) defs.set(nm, []); defs.get(nm).push(n); }
    }
    if (!ehChamada(n)) return;
    const cp = caminho(n.base) || {};
    const a = argsDe(n);
    let tipo = null, alvo = null;
    if ((cp.metodo === 'SetScript' || cp.metodo === 'HookScript') && ehString(a[0])
      && ['OnUpdate', 'OnEvent'].includes(valorString(a[0]))) { tipo = valorString(a[0]); alvo = a[1]; }
    if (['C_Timer.After', 'C_Timer.NewTimer', 'C_Timer.NewTicker'].includes(cp.texto)) { tipo = 'timer'; alvo = a[1]; }
    if (tipo && alvo && alvo.type !== 'NilLiteral') entradas.push({ arq, linha: n.loc.start.line, tipo, alvo });
  });
}

// ---------- regras por arquivo ----------
for (const { arq, ast, ver, e51 } of analisados) {
  const nome = arq.toLowerCase();
  const ehAcoes = nome === 'acoes.lua', ehPedidos = nome === 'pedidos.lua', ehPontes = nome === 'pontes.lua';
  const ehTetos = nome === 'tetos.lua', ehAjuste = nome === 'config.lua' || nome === 'calibrado.lua';
  const ehPuro = PUROS.includes(nome);

  // R14: construcoes so de 5.3 (o parse 5.1 falhou e o 5.3 leu o arquivo)
  if (ver === '5.3') {
    let achou = 0;
    percorrer(ast, n => {
      const op = n.operator;
      const suspeito = (n.type === 'BinaryExpression' && OPS_53.has(op)) || (n.type === 'UnaryExpression' && op === '~');
      if (suspeito) { achou++; ach(arq, n.loc.start.line, 14, `operador so de Lua 5.3 (fora do subconjunto comum): ${op}`); }
      if (n.type === 'GotoStatement' || n.type === 'LabelStatement') { achou++; ach(arq, n.loc.start.line, 14, `goto ou rotulo so de Lua 5.3`); }
    });
    if (!achou) ach(arq, e51 && e51.line || 0, 14, `construcao so de Lua 5.3: ${e51 ? e51.message : ''}`);
  }

  // R3, R4, R12, R13, R14 (globais e divisao), R15, R20: passadas pelo AST
  const refs = [];
  percorrer(ast, (n, pais) => {
    // R3: tratadores
    if (ehChamada(n)) {
      const cp = caminho(n.base) || {};
      const a = argsDe(n);
      let alvo, rotulo = cp.texto;
      if (cp.metodo === 'SetScript' || cp.metodo === 'HookScript') { alvo = a[1]; rotulo = ':' + cp.metodo; }
      else if (['C_Timer.After', 'C_Timer.NewTimer', 'C_Timer.NewTicker'].includes(cp.texto)) alvo = a[1];
      if (alvo && alvo.type !== 'NilLiteral' && !ehSeguro(alvo))
        ach(arq, n.loc.start.line, 3, `tratador sem ns.seguro: ${rotulo}`);
      // R4: quadro global de terceiros (Blizzard) com SetScript ou aba
      const quadro = cp.base;
      if (cp.metodo && quadro && quadro.global && !prefixado(quadro.raiz) && quadro.raiz !== 'SlashCmdList') {
        if (cp.metodo === 'SetScript') ach(arq, n.loc.start.line, 4, `SetScript em quadro da Blizzard: ${quadro.texto}`);
        if (['AddNamedTab', 'AddTab', 'SetTabSystem'].includes(cp.metodo))
          ach(arq, n.loc.start.line, 4, `aba em quadro da Blizzard: ${quadro.texto}:${cp.metodo}`);
      }
      // R5: terceiro so em Pontes.lua, dentro de pcall (a chamada tambem conta como uso do nome da raiz)
      // R12: fonte
      if (cp.metodo === 'SetFont' || cp.texto === 'CreateFont')
        ach(arq, n.loc.start.line, 12, `fonte fora do padrao: ${cp.texto || ':' + cp.metodo}`);
      // R10: ':Click(' como metodo
      if (cp.metodo === 'Click') ach(arq, n.loc.start.line, 10, `:Click( proibido`);
      // R7: quantidade de PostItem (direto ou por pcall/xpcall)
      let nomeChamado = cp.metodo || (cp.texto || '').split('.').pop();
      let argsR = a;
      if (['pcall', 'xpcall'].includes(cp.texto) && a[0]) {
        const deslocar = cp.texto === 'pcall' ? 1 : 2;
        if (nomeDeAlvo(a[0]) === 'PostItem') { nomeChamado = 'PostItem'; argsR = a.slice(deslocar); }
      }
      if (nomeChamado === 'PostItem') {
        const q = argsR[POS_QTD_POSTITEM];
        if (!q || q.type !== 'NumericLiteral' || q.value !== 1)
          ach(arq, n.loc.start.line, 7, `PostItem sem quantidade 1 no terceiro argumento`);
      }
    }
    // R4: atribuicao em campo de tabela global de terceiros
    if (n.type === 'AssignmentStatement') {
      n.variables.forEach((v, i) => {
        if (v.type === 'Identifier') return;
        const c = caminho(v);
        if (c && c.global && !prefixado(c.raiz) && c.raiz !== 'SlashCmdList')
          ach(arq, v.loc.start.line, 4, `atribuicao em campo de tabela global da Blizzard: ${c.texto}`);
      });
      // R13 (teto, ritmo, nivel concedido) e R15/R20 (banco) por alvo
      n.variables.forEach((v, i) => {
        const c = caminho(v);
        if (!c) return;
        const segs = c.texto.split('.');
        const valor = n.init[i];
        if (segs.some(TETO) && !ehTetos)
          ach(arq, v.loc.start.line, 13, `teto duro definido fora de Tetos.lua: ${c.texto}`);
        if (segs.some(RITMO) && !ehAjuste)
          ach(arq, v.loc.start.line, 13, `ritmo definido fora de Config.lua: ${c.texto}`);
        if (segs.some(CONCEDIDO) && !ehAjuste) {
          const minimo = valor && valor.type === 'CallExpression' && (caminho(valor.base) || {}).texto === 'math.min'
            && argsDe(valor).some(x => (caminho(x) || {}).texto === c.texto);
          if (!minimo) ach(arq, v.loc.start.line, 13, `nivel concedido so pode descer (math.min do proprio campo): ${c.texto}`);
        }
        if (segs.some(s => BANCO.test(s))) {
          const relogio = [];
          percorrer([v, valor], x => {
            if (ehChamada(x) && RELOGIOS.includes((caminho(x.base) || {}).texto)) relogio.push(caminho(x.base).texto);
          }, [], false);
          if (relogio.length) ach(arq, v.loc.start.line, 15, `hora de intervalo gravada no banco (usa GetServerTime): ${c.texto} <- ${relogio[0]}`);
          const nomesAlvo = nomesEm(v);
          const nomesValor = valor ? nomesEm(valor) : new Set();
          if ([...nomesAlvo, ...nomesValor].some(x => x.toLowerCase() === 'playername'))
            ach(arq, v.loc.start.line, 20, `playerName gravado no banco: ${c.texto}`);
          if ([...nomesAlvo].some(x => NOMES_JOGADOR.has(x.toLowerCase())))
            ach(arq, v.loc.start.line, 20, `nome de jogador como chave ou alvo no banco: ${c.texto}`);
          const copia = valor && ['Identifier', 'MemberExpression', 'IndexExpression'].includes(valor.type)
            ? (caminho(valor) || {}).texto : null;
          if (copia && copia.split('.').some(s => NOMES_JOGADOR.has(s.toLowerCase())))
            ach(arq, v.loc.start.line, 20, `nome de jogador copiado para o banco: ${copia}`);
        }
      });
    }
    // R12: funcao que pinta cor e nao escreve texto
    if (n.type === 'FunctionDeclaration') {
      const chamadas = diretas(n.body).filter(ehChamada);
      let cor = null, texto = false;
      for (const c of chamadas) {
        const m = (caminho(c.base) || {}).metodo;
        if (m === 'SetTextColor' && !cor) cor = c;
        if (m === 'SetText' || m === 'SetFormattedText') texto = true;
      }
      if (cor && !texto) ach(arq, cor.loc.start.line, 12, `estado so em cor (funcao sem SetText): SetTextColor`);
    }
    // R14: globais proibidos e divisao virando texto
    if (n.type === 'Identifier' && n.isLocal === false) {
      if (n.name === 'unpack' || n.name === 'bit')
        ach(arq, n.loc.start.line, 14, `global fora do subconjunto comum 5.1/5.3: ${n.name}`);
      else if (ehPuro && !LUA_OK.has(n.name))
        ach(arq, n.loc.start.line, 14, `global do jogo ou do addon em arquivo puro: ${n.name}`);
    }
    if (n.type === 'FunctionDeclaration' && ehPuro && n.identifier && n.identifier.type === 'Identifier'
      && n.identifier.isLocal === false)
      ach(arq, n.loc.start.line, 14, `funcao global em arquivo puro: ${n.identifier.name}`);
    const divide = e => !!e && e.type === 'BinaryExpression' && e.operator === '/';
    if (n.type === 'BinaryExpression' && n.operator === '..' && (divide(n.left) || divide(n.right)))
      ach(arq, n.loc.start.line, 14, `numero dividido vira texto sem math.floor`);
    if (ehChamada(n) && (caminho(n.base) || {}).texto === 'tostring' && divide(argsDe(n)[0]))
      ach(arq, n.loc.start.line, 14, `tostring de divisao (5.3 mostra 5.0)`);

    // refs: nomes de funcao de acao, consulta e tecla_ (sem declaracoes de atribuicao de tecla_)
    if (n.type === 'Identifier' || n.type === 'MemberExpression') {
      const nm = nomeRef(n);
      if (nm && (ACOES.has(nm) || CONSULTAS.has(nm) || nm.startsWith('tecla_'))) {
        const pai = pais[pais.length - 1];
        const ehAlvoDeAtribuicao = pai && pai.type === 'AssignmentStatement' && pai.variables.includes(n);
        if (!(ehAlvoDeAtribuicao && nm.startsWith('tecla_'))) refs.push({ nm, no: n, pais: pais.slice() });
      }
    }
    // definicao de funcao de acao fora de Acoes.lua
    if (n.type === 'FunctionDeclaration' && !ehAcoes) {
      const nm = nomeDeFuncao(n, pais);
      if (nm && ACOES.has(nm)) ach(arq, n.loc.start.line, 6, `funcao de acao definida fora de Acoes.lua: ${nm}`);
    }
    // R10: textos proibidos (os nomes vem na passada crua, abaixo)
    if (n.type === 'StringLiteral') {
      const v = valorString(n);
      const t = PROIBIDOS_TEXTO.find(p => v.includes(p));
      if (t) ach(arq, n.loc.start.line, 10, `texto proibido no addon: "${t}"`);
    }
    // R6, R10 e R9 no que e exclusivo de Acoes.lua
    if (ehAcoes) {
      if (n.type === 'Identifier' && n.name === 'C_Timer') ach(arq, n.loc.start.line, 6, `C_Timer em Acoes.lua`);
      if (n.type === 'MemberExpression' && ['RegisterEvent', 'RegisterUnitEvent'].includes(n.identifier.name))
        ach(arq, n.loc.start.line, 6, `${n.identifier.name} em Acoes.lua`);
      if (n.type === 'StringLiteral' && valorString(n) === 'OnUpdate')
        ach(arq, n.loc.start.line, 6, `OnUpdate em Acoes.lua`);
    }
    // R5: nome de addon de terceiro
    let nomeTerceiro = null;
    if (n.type === 'Identifier' && ehTerceiro(n.name)) nomeTerceiro = n.name;
    if (n.type === 'StringLiteral' && TERCEIROS.includes(valorString(n))) nomeTerceiro = valorString(n);
    if (nomeTerceiro) {
      if (!ehPontes) ach(arq, n.loc.start.line, 5, `nome de addon de terceiro fora de Pontes.lua: ${nomeTerceiro}`);
      else if (!ehPcall(pais)) ach(arq, n.loc.start.line, 5, `nome de addon de terceiro fora de pcall: ${nomeTerceiro}`);
    }
  });

  // R10: nome proibido em qualquer identificador, inclusive campo (C_Mail.X) e declaracao
  percorrer(ast, n => {
    if (n.type !== 'Identifier') return;
    const t = PROIBIDOS.find(p => n.name.includes(p));
    if (t) ach(arq, n.loc.start.line, 10, `nome proibido no addon: ${n.name} (${t})`);
  }, [], false);

  // R6, R7, R8, R9 sobre as referencias
  // R9: funcao de consulta fora de Pedidos.lua
  for (const r of refs) {
    if (CONSULTAS.has(r.nm) && !ehPedidos)
      ach(arq, r.no.loc.start.line, 9, `funcao de consulta fora de Pedidos.lua: ${r.nm}`);
  }
  // R6: funcao de acao e tecla_
  const porTecla = new Map();
  for (const r of refs) {
    const linha = r.no.loc.start.line;
    if (ACOES.has(r.nm)) {
      if (!ehAcoes) ach(arq, linha, 6, `funcao de acao fora de Acoes.lua: ${r.nm}`);
      else {
        const f = funcaoTecla(r.pais);
        if (!f) ach(arq, linha, 6, `funcao de acao fora de funcao tecla_: ${r.nm}`);
        else { if (!porTecla.has(f)) porTecla.set(f, []); porTecla.get(f).push(r); }
      }
    }
    if (r.nm.startsWith('tecla_') && !ehAcoes && !r.pais.some(ehSetScriptOnClick))
      ach(arq, linha, 6, `tecla_ chamada fora do OnClick: ${r.nm}`);
  }
  // R7 (contagem por caminho) e R8 (autoriza e intencao antes), por funcao tecla_
  for (const [f, lista] of porTecla) {
    const nomeF = nomeDeFuncao(f, []) || 'tecla_';
    if (contaCaminho(f.body) > 1)
      ach(arq, f.loc.start.line, 7, `mais de uma funcao de acao no mesmo caminho de ${nomeF}`);
    const autoriza = [], intencao = [];
    percorrer(f.body, x => {
      if (!ehChamada(x)) return;
      const t = (caminho(x.base) || {}).texto || '';
      if (t === 'Cofre.autoriza' || t.endsWith('.Cofre.autoriza')) autoriza.push(x.loc.start);
      if (t === 'Livro.intencao' || t.endsWith('.Livro.intencao')) intencao.push(x.loc.start);
    });
    for (const r of lista) {
      const p = r.no.loc.start;
      if (!autoriza.some(g => antes(g, p))) ach(arq, p.line, 8, `funcao de acao sem Cofre.autoriza antes no mesmo clique: ${r.nm}`);
      if (!intencao.some(g => antes(g, p))) ach(arq, p.line, 8, `funcao de acao sem Livro.intencao antes no mesmo clique: ${r.nm}`);
    }
  }
}

// ---------- R21: entrada (timer, OnUpdate, evento) alcanca tecla_ ----------
for (const e of entradas) {
  const fila = [...nomesEm(e.alvo)];
  const vistos = new Set();
  let achou = null;
  while (fila.length && !achou) {
    const nm = fila.pop();
    if (vistos.has(nm)) continue;
    vistos.add(nm);
    if (nm.startsWith('tecla_')) { achou = nm; break; }
    for (const f of defs.get(nm) || []) for (const x of nomesDoCorpo(f)) if (!vistos.has(x)) fila.push(x);
  }
  if (achou) ach(e.arq, e.linha, 21, `funcao alcancada por ${e.tipo} chega a tecla_: ${achou}`);
}

// ---------- saida ----------
const ordemArq = new Map(arquivos.map((a, i) => [a, i]));
ordemArq.set('(pasta)', -1);
achados.sort((x, y) => (ordemArq.get(x.arq) - ordemArq.get(y.arq)) || (x.linha - y.linha) || (x.regra - y.regra));
for (const a of achados) console.log(`${a.arq}:${a.linha} R${String(a.regra).padStart(2, '0')} ${a.msg}`);
console.log(`RESUMO arquivos=${arquivos.length} erros=${achados.length}`);
process.exit(achados.length ? 1 : 0);
