// Confere, na documentacao gerada da Blizzard (api-forever/doc/*.lua), as marcas de valor secreto
// de que o CentralForever depende (contrato, secao 11.1). Sem dependencias: so texto e regex simples.
// Uso: node conferir-doc.mjs            (confere; sai 1 se alguma ancora falhar ou faltar arquivo)
//      node conferir-doc.mjs --autoteste (prova que a conferencia acusa falta e sobra de marca)
import { readFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const DOC = join(dirname(fileURLToPath(import.meta.url)), 'api-forever', 'doc');
const BAIXAR = 'baixe com node baixar-api-forever.mjs (versoes em api-forever.json)';

// tipo "funcao": bloco do Name = "X" ate o proximo Name de mesma indentacao (ou menor).
// tipo "campo": linha do campo dentro do bloco da tabela (campo "tabela").
// tipo "evento": bloco do LiteralName (type antes de state no payload).
// tem: texto que tem de aparecer no bloco. nao: texto que nao pode aparecer.
const ANCORAS = [
  { arq: 'DamageMeterDocumentation.lua', nome: 'GetCombatSessionFromType', tipo: 'funcao', tem: ['SecretWhenInCombat = true'] },
  { arq: 'DamageMeterDocumentation.lua', nome: 'GetCombatSessionFromID', tipo: 'funcao', tem: ['SecretWhenInCombat = true'] },
  { arq: 'DamageMeterDocumentation.lua', nome: 'GetSessionDurationSeconds', tipo: 'funcao', nao: ['SecretWhen'] },
  { arq: 'DamageMeterDocumentation.lua', nome: 'IsDamageMeterAvailable', tipo: 'funcao', nao: ['SecretWhen'] },
  { arq: 'DamageMeterDocumentation.lua', nome: 'ResetAllCombatSessions', tipo: 'funcao', nao: ['SecretWhen'] },
  { arq: 'DamageMeterDocumentation.lua', nome: 'isLocalPlayer', tipo: 'campo', tabela: 'DamageMeterCombatSource', tem: ['NeverSecret = true'] },
  { arq: 'DamageMeterDocumentation.lua', nome: 'totalAmount', tipo: 'campo', tabela: 'DamageMeterCombatSource', nao: ['NeverSecret'] },
  { arq: 'DamageMeterDocumentation.lua', nome: 'amountPerSecond', tipo: 'campo', tabela: 'DamageMeterCombatSource', nao: ['NeverSecret'] },
  { arq: 'UnitDocumentation.lua', nome: 'UnitDetailedThreatSituation', tipo: 'funcao', tem: ['SecretWhenUnitThreatValuesRestricted = true', 'MayReturnNothing = true'] },
  { arq: 'UnitDocumentation.lua', nome: 'UnitThreatSituation', tipo: 'funcao', tem: ['SecretWhenUnitThreatStateRestricted = true'], nao: ['ValuesRestricted'] },
  { arq: 'UnitDocumentation.lua', nome: 'UnitThreatLeadSituation', tipo: 'funcao', tem: ['SecretWhenUnitThreatStateRestricted = true'] },
  { arq: 'UnitDocumentation.lua', nome: 'UnitThreatPercentageOfLead', tipo: 'funcao', tem: ['SecretWhenUnitThreatValuesRestricted = true'] },
  { arq: 'UnitDocumentation.lua', nome: 'UnitExists', tipo: 'funcao', nao: ['SecretWhen'] },
  { arq: 'UnitDocumentation.lua', nome: 'UnitCanAttack', tipo: 'funcao', nao: ['SecretWhen'] },
  { arq: 'UnitDocumentation.lua', nome: 'UnitAffectingCombat', tipo: 'funcao', nao: ['SecretWhen'] },
  { arq: 'UnitDocumentation.lua', nome: 'UnitIsDeadOrGhost', tipo: 'funcao', nao: ['SecretWhen'] },
  { arq: 'ThreatDocumentation.lua', nome: 'GetThreatStatusColor', tipo: 'funcao', tem: ['SecretArguments = "AllowedWhenUntainted"'] },
  { arq: 'SimpleFontStringAPIDocumentation.lua', nome: 'SetText', tipo: 'funcao', tem: ['SecretArguments = "AllowedWhenTainted"'] },
  { arq: 'SimpleFontStringAPIDocumentation.lua', nome: 'SetFormattedText', tipo: 'funcao', tem: ['SecretArguments = "AllowedWhenTainted"'] },
  { arq: 'SimpleStatusBarAPIDocumentation.lua', nome: 'SetValue', tipo: 'funcao', tem: ['SecretArguments = "AllowedWhenTainted"'] },
  { arq: 'SimpleStatusBarAPIDocumentation.lua', nome: 'SetMinMaxValues', tipo: 'funcao', tem: ['SecretArguments = "AllowedWhenTainted"'] },
  { arq: 'SimpleStatusBarAPIDocumentation.lua', nome: 'SetStatusBarColor', tipo: 'funcao', tem: ['SecretArguments = "AllowedWhenTainted"'] },
  { arq: 'SimpleRegionAPIDocumentation.lua', nome: 'SetAlphaFromBoolean', tipo: 'funcao', tem: ['SecretArguments = "AllowedWhenTainted"'] },
  { arq: 'SimpleRegionAPIDocumentation.lua', nome: 'SetVertexColorFromBoolean', tipo: 'funcao', tem: ['SecretArguments = "AllowedWhenTainted"'] },
  { arq: 'SimpleScriptRegionAPIDocumentation.lua', nome: 'SetShown', tipo: 'funcao', tem: ['SecretArguments = "AllowedWhenUntainted"'] },
  { arq: 'LocalizationDocumentation.lua', nome: 'AbbreviateNumbers', tipo: 'funcao', tem: ['SecretArguments = "AllowedWhenTainted"'] },
  { arq: 'LocalizationDocumentation.lua', nome: 'AbbreviateLargeNumbers', tipo: 'funcao', tem: ['SecretArguments = "AllowedWhenTainted"'] },
  { arq: 'StringUtilDocumentation.lua', nome: 'RoundToNearestString', tipo: 'funcao', tem: ['SecretArguments = "AllowedWhenTainted"'] },
  { arq: 'StringUtilDocumentation.lua', nome: 'WrapString', tipo: 'funcao', tem: ['SecretArguments = "AllowedWhenTainted"'] },
  { arq: 'RestrictedActionsDocumentation.lua', nome: 'ADDON_RESTRICTION_STATE_CHANGED', tipo: 'evento' },
];

const indent = l => /^\t*/.exec(l)[0].length;
const ehNome = l => /^\t*Name = "/.test(l);

// Bloco que comeca na linha i e vai ate o proximo Name de indentacao igual ou menor.
function blocoAPartir(linhas, i) {
  const ind = indent(linhas[i]);
  let j = i + 1;
  while (j < linhas.length && !(ehNome(linhas[j]) && indent(linhas[j]) <= ind)) j++;
  return linhas.slice(i, j);
}

function blocoDeNome(linhas, nome) {
  const i = linhas.findIndex(l => l.trimStart().startsWith('Name = "' + nome + '"'));
  return i < 0 ? null : blocoAPartir(linhas, i);
}

// Bloco do evento: vai do Name que vem antes do LiteralName (de indentacao menor).
function blocoDoEvento(linhas, k) {
  let p = k - 1;
  while (p >= 0 && !(ehNome(linhas[p]) && indent(linhas[p]) < indent(linhas[k]))) p--;
  return p < 0 ? null : blocoAPartir(linhas, p);
}

function conferirTexto(texto, a, ok, falhas) {
  for (const s of a.tem || []) {
    if (texto.includes(s)) ok.push('tem ' + s);
    else falhas.push('falta ' + s);
  }
  for (const s of a.nao || []) {
    if (texto.includes(s)) falhas.push('tem proibido ' + s);
    else ok.push('sem ' + s);
  }
}

function conferirAncora(linhas, a) {
  const ok = [], falhas = [];
  if (a.tipo === 'funcao') {
    const bloco = blocoDeNome(linhas, a.nome);
    if (!bloco) falhas.push('funcao nao encontrada');
    else conferirTexto(bloco.join('\n'), a, ok, falhas);
  } else if (a.tipo === 'campo') {
    const tab = blocoDeNome(linhas, a.tabela);
    if (!tab) falhas.push('tabela ' + a.tabela + ' nao encontrada');
    else {
      const linha = tab.find(l => l.includes('Name = "' + a.nome + '"'));
      if (!linha) falhas.push('campo nao encontrado em ' + a.tabela);
      else {
        conferirTexto(linha, a, ok, falhas);
        if (!falhas.length && !(a.tem || a.nao)) ok.push('campo presente');
      }
    }
  } else if (a.tipo === 'evento') {
    const k = linhas.findIndex(l => l.includes('LiteralName = "' + a.nome + '"'));
    const bloco = k < 0 ? null : blocoDoEvento(linhas, k);
    if (!bloco) falhas.push('evento nao encontrado');
    else {
      const it = bloco.findIndex(l => l.includes('Name = "type"'));
      const is = bloco.findIndex(l => l.includes('Name = "state"'));
      if (it < 0 || is < 0) falhas.push('payload sem type ou sem state');
      else if (it > is) falhas.push('state vem antes de type');
      else ok.push('type antes de state');
    }
  }
  return { ok: falhas.length === 0, texto: ok.join('; '), motivo: falhas.join('; ') };
}

// docs: nome do arquivo -> texto (ausente = arquivo nao baixado).
function conferir(docs, ancoras) {
  return ancoras.map(a => {
    const texto = docs[a.arq];
    if (texto === undefined) {
      return { a, ok: false, texto: '', motivo: 'arquivo ausente (' + BAIXAR + ')' };
    }
    return { a, ...conferirAncora(texto.split(/\r?\n/), a) };
  });
}

function linha(r) {
  return (r.ok ? 'ok    ' : 'FALHA ') + r.a.arq + ' ' + r.a.nome + ': ' + (r.ok ? r.texto : r.motivo);
}

function principal() {
  const docs = {};
  for (const arq of new Set(ANCORAS.map(a => a.arq))) {
    const p = join(DOC, arq);
    if (existsSync(p)) docs[arq] = readFileSync(p, 'utf8');
  }
  const res = conferir(docs, ANCORAS);
  for (const r of res) console.log(linha(r));
  const ok = res.filter(r => r.ok).length;
  console.log(ok + ' de ' + res.length + ' ancoras conferem');
  return ok === res.length ? 0 : 1;
}

// Texto falso: falta SecretWhenInCombat em GetCombatSessionFromType (obrigatoria ausente) e
// SecretWhenInCombat aparece em GetSessionDurationSeconds (proibida presente).
const TEXTO_FALSO = [
  'local DamageMeter =',
  '{',
  '\tFunctions =',
  '\t{',
  '\t\t\t{',
  '\t\t\t\tName = "GetCombatSessionFromType",',
  '\t\t\t\tType = "Function",',
  '\t\t\t},',
  '\t\t\t{',
  '\t\t\t\tName = "GetCombatSessionFromID",',
  '\t\t\t\tType = "Function",',
  '\t\t\t\tSecretWhenInCombat = true,',
  '\t\t\t},',
  '\t\t\t{',
  '\t\t\t\tName = "GetSessionDurationSeconds",',
  '\t\t\t\tType = "Function",',
  '\t\t\t\tSecretWhenInCombat = true,',
  '\t\t\t},',
  '\t\t},',
  '\t},',
].join('\n');

function autoteste() {
  const res = conferir({ 'DamageMeterDocumentation.lua': TEXTO_FALSO }, ANCORAS);
  const faltou = res.find(r => r.a.nome === 'GetCombatSessionFromType' && !r.ok && r.motivo.includes('falta SecretWhenInCombat = true'));
  const sobrou = res.find(r => r.a.nome === 'GetSessionDurationSeconds' && !r.ok && r.motivo.includes('tem proibido SecretWhen'));
  const aprovou = res.filter(r => r.a.arq === 'DamageMeterDocumentation.lua' && r.a.nome === 'GetCombatSessionFromID' && r.ok);
  if (faltou) console.log(linha(faltou));
  if (sobrou) console.log(linha(sobrou));
  if (aprovou.length) console.log(linha(aprovou[0]));
  if (faltou && sobrou && aprovou.length) {
    console.log('autoteste ok: as duas falhas plantadas foram acusadas e a ancora certa passou');
    return 0;
  }
  console.log('autoteste FALHOU: a conferencia nao acusou as falhas plantadas');
  return 1;
}

process.exitCode = process.argv.includes('--autoteste') ? autoteste() : principal();
