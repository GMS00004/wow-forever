// Checador do Ajuda.lua (GuiaForeverAjuda). Uso: node checar-ajuda.mjs <caminho do Ajuda.lua>
// Sai com 0 e imprime "ok" quando tudo passa; sai com 1 listando cada problema.
// Esqueleto e lista de fontes iguais aos do checar-dicas.mjs (contrato: ARQUITETURA.md, secao 7).
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';

const require = createRequire(import.meta.url);
const luaparse = require('luaparse'); // instale uma vez: npm install, nesta pasta

const CLASSES = ['HUNTER', 'SHAMAN', 'PALADIN']; // PALADIN permitida, nao obrigatoria (tarefa T1)
const ABAS = ['agora', 'pet', 'talentos', 'combate', 'profissoes', 'ajuda'];
const CAMPOS_PERGUNTA = ['id', 'aba', 'pergunta', 'linhas'];
const CAMPOS_LINHA = ['texto', 'fonte'];
const FONTES = [
  'Method',
  'DoubleZug',
  'Kargoz (beta)',
  'Gladius (beta)',
  'LudiDeo (beta)',
  'MetaGoblin (beta)',
  'RestedXP',
  'Naowh',
  'leak',
  'Saltii', // guia de pets do Saltii (comum\fontes\builds\saltii-hunter-pets.md), 2026-11-08
  'you', // decisao do proprio dono (ficha), como nas teclas (Teclas.lua, f = "you")
  'Perfect Gaming Weather', // fontes do Ignatius Stonejaw (comum\fontes\builds\), 2026-11-08 (tarefa T1)
  'Deadmanfred',
  'Jurdi',
  'DwarfLord (beta)',
  'Blizzard', // nota oficial de 03/11 (ficha do Ignatius Stonejaw)
  'ReptilioPlays', // Leatherworking (comum\fontes\profissoes\reptilio-leatherworking.md), 2026-11-13
];
const PERGUNTA_MAX = 90;
const TEXTO_MAX = 160;

const caminho = process.argv[2];
if (!caminho) {
  console.log('uso: node checar-ajuda.mjs <caminho do Ajuda.lua>');
  process.exit(1);
}

const problemas = [];
const erro = (onde, msg) => problemas.push(`${onde}: ${msg}`);

function sair(resultadoOk, contagens) {
  if (problemas.length === 0) {
    console.log('ok');
    for (const [classe, c] of Object.entries(contagens)) {
      console.log(`${classe}: perguntas ${c.perguntas}`);
    }
    process.exit(0);
  }
  console.log(`FALHA: ${problemas.length} problema(s) em ${caminho}`);
  for (const p of problemas) console.log(`  - ${p}`);
  process.exit(1);
}

// Regra 1: so ASCII
let bytes;
try {
  bytes = readFileSync(caminho);
} catch (e) {
  console.log(`FALHA: nao consegui ler ${caminho}: ${e.message}`);
  process.exit(1);
}
{
  const linhas = bytes.toString('latin1').split('\n');
  linhas.forEach((linha, i) => {
    for (let k = 0; k < linha.length; k++) {
      const c = linha.charCodeAt(k);
      if (c > 0x7f) {
        erro(`linha ${i + 1}`, `byte nao ASCII 0x${c.toString(16).toUpperCase()} (texto deve ser ASCII)`);
        break;
      }
    }
  });
}

// Regra 1: Lua 5.1 valido
let ast;
try {
  ast = luaparse.parse(bytes.toString('latin1'), {
    encodingMode: 'pseudo-latin1',
    luaVersion: '5.1',
    comments: false,
    locations: true,
  });
} catch (e) {
  erro('Lua', `nao e Lua 5.1 valido: ${e.message}`);
  sair(false, {});
}

const contagens = {};

// Regra 2: atribuicao global GuiaForeverAjuda
const atrib = ast.body.find(
  (s) =>
    s.type === 'AssignmentStatement' &&
    s.variables.length === 1 &&
    s.variables[0].type === 'Identifier' &&
    s.variables[0].name === 'GuiaForeverAjuda',
);
if (!atrib) {
  erro('arquivo', 'falta a atribuicao global GuiaForeverAjuda = { ... }');
  sair(false, {});
}
if (atrib.init.length !== 1) {
  erro(`linha ${atrib.loc.start.line}`, 'GuiaForeverAjuda deve ter um unico valor');
  sair(false, {});
}
const init = atrib.init[0];
// O esqueleto usa "GuiaForeverAjuda = GuiaForeverAjuda or {}": vazio, sem perguntas, passa.
const ehOrVazio =
  init.type === 'LogicalExpression' &&
  init.operator === 'or' &&
  init.left.type === 'Identifier' &&
  init.left.name === 'GuiaForeverAjuda' &&
  init.right.type === 'TableConstructorExpression' &&
  init.right.fields.length === 0;
if (ehOrVazio) sair(true, {});
if (init.type !== 'TableConstructorExpression') {
  erro(`linha ${atrib.loc.start.line}`, 'GuiaForeverAjuda deve ser uma tabela { ... } (ou GuiaForeverAjuda or {})');
  sair(false, {});
}

const nomeChave = (campo) => {
  if (campo.type === 'TableKeyString') return campo.key.name;
  if (campo.type === 'TableKey' && campo.key.type === 'StringLiteral') return campo.key.value;
  return null;
};

const topo = {};
for (const campo of init.fields) {
  const nome = nomeChave(campo);
  const onde = `linha ${campo.loc.start.line}`;
  if (nome === null) {
    erro(onde, 'item sem chave (esperado HUNTER ou SHAMAN)');
    continue;
  }
  if (!CLASSES.includes(nome)) {
    erro(onde, `chave de classe desconhecida "${nome}"`);
    continue;
  }
  if (topo[nome]) {
    erro(onde, `classe ${nome} repetida`);
    continue;
  }
  topo[nome] = campo.value;
}

function checarLinha(onde, node) {
  if (node.type !== 'TableConstructorExpression') {
    erro(onde, 'linha deve ser uma tabela { texto, fonte }');
    return;
  }
  const campos = {};
  for (const campo of node.fields) {
    const l = `linha ${campo.loc.start.line}`;
    const nome = campo.type === 'TableKeyString' ? campo.key.name : null;
    if (nome === null) {
      erro(`${onde} ${l}`, 'campo sem nome (esperado texto/fonte)');
      continue;
    }
    if (!CAMPOS_LINHA.includes(nome)) {
      erro(`${onde} ${l}`, `campo desconhecido "${nome}" em linhas`);
      continue;
    }
    if (nome in campos) {
      erro(`${onde} ${l}`, `campo "${nome}" repetido`);
      continue;
    }
    campos[nome] = campo.value;
  }
  for (const req of CAMPOS_LINHA) {
    if (!(req in campos)) erro(onde, `falta o campo "${req}"`);
  }
  const t = campos.texto;
  if (t) {
    if (t.type !== 'StringLiteral') {
      erro(onde, 'texto deve ser string');
    } else if (t.value.trim() === '') {
      erro(onde, 'texto vazio');
    } else if (t.value.length > TEXTO_MAX) {
      erro(onde, `texto com ${t.value.length} caracteres (maximo ${TEXTO_MAX})`);
    }
  }
  const f = campos.fonte;
  if (f) {
    if (f.type !== 'StringLiteral' || !FONTES.includes(f.value)) {
      const shown = f.type === 'StringLiteral' ? f.value : '(nao e string)';
      erro(onde, `fonte invalida "${shown}" (use: ${FONTES.join(', ')})`);
    }
  }
}

function checarPergunta(onde, node, classe, ids) {
  if (node.type !== 'TableConstructorExpression') {
    erro(onde, 'entrada deve ser uma tabela { ... }');
    return;
  }
  const campos = {};
  for (const campo of node.fields) {
    const l = `linha ${campo.loc.start.line}`;
    const nome = campo.type === 'TableKeyString' ? campo.key.name : null;
    if (nome === null) {
      erro(`${onde} ${l}`, 'campo sem nome (esperado id/aba/pergunta/linhas)');
      continue;
    }
    if (!CAMPOS_PERGUNTA.includes(nome)) {
      erro(`${onde} ${l}`, `campo desconhecido "${nome}" em ajuda`);
      continue;
    }
    if (nome in campos) {
      erro(`${onde} ${l}`, `campo "${nome}" repetido`);
      continue;
    }
    campos[nome] = campo.value;
  }
  for (const req of CAMPOS_PERGUNTA) {
    if (!(req in campos)) erro(onde, `falta o campo "${req}"`);
  }

  // id: texto unico dentro da classe
  const id = campos.id;
  if (id) {
    if (id.type !== 'StringLiteral' || id.value.trim() === '') {
      erro(onde, 'id deve ser texto nao vazio');
    } else if (ids.has(id.value)) {
      erro(onde, `id "${id.value}" repetido em ${classe} (o id e unico dentro da classe)`);
    } else {
      ids.add(id.value);
    }
  }
  // aba
  const aba = campos.aba;
  if (aba && (aba.type !== 'StringLiteral' || !ABAS.includes(aba.value))) {
    const shown = aba.type === 'StringLiteral' ? aba.value : '(nao e string)';
    erro(onde, `aba invalida "${shown}" (use: ${ABAS.join(', ')})`);
  }
  // pergunta
  const p = campos.pergunta;
  if (p) {
    if (p.type !== 'StringLiteral' || p.value.trim() === '') {
      erro(onde, 'pergunta deve ser texto nao vazio');
    } else if (p.value.length > PERGUNTA_MAX) {
      erro(onde, `pergunta com ${p.value.length} caracteres (maximo ${PERGUNTA_MAX})`);
    }
  }
  // linhas: ao menos uma
  const li = campos.linhas;
  if (li) {
    if (li.type !== 'TableConstructorExpression') {
      erro(onde, 'linhas deve ser uma lista { { texto, fonte } }');
    } else {
      const itens = [];
      for (const campo of li.fields) {
        if (campo.type !== 'TableValue') {
          erro(`${onde} linha ${campo.loc.start.line}`, 'item de linhas deve ser { texto, fonte } sem chave');
          continue;
        }
        itens.push(campo.value);
      }
      if (itens.length === 0) erro(onde, 'linhas vazia (ao menos uma linha)');
      itens.forEach((no, i) => checarLinha(`${onde} linhas[${i + 1}]`, no));
    }
  }
}

for (const classe of CLASSES) {
  const lista = topo[classe];
  if (!lista) continue;
  if (lista.type !== 'TableConstructorExpression') {
    erro(classe, 'deve ser uma lista de perguntas { ... }');
    continue;
  }
  const entradas = [];
  for (const campo of lista.fields) {
    if (campo.type !== 'TableValue') {
      erro(`${classe} linha ${campo.loc.start.line}`, 'item deve ser uma pergunta { ... } sem chave');
      continue;
    }
    entradas.push(campo.value);
  }
  const ids = new Set();
  entradas.forEach((no, i) => checarPergunta(`${classe}[${i + 1}]`, no, classe, ids));
  contagens[classe] = { perguntas: entradas.length };
}

sair(true, contagens);
