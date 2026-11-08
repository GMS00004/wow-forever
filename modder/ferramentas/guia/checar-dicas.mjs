// Checador do Dicas.lua (GuiaForeverDicas). Uso: node checar-dicas.mjs <caminho do Dicas.lua>
// Sai com 0 e imprime "ok" quando tudo passa; sai com 1 listando cada problema.
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';

const require = createRequire(import.meta.url);
const luaparse = require('luaparse'); // instale uma vez: npm install, nesta pasta

const CLASSES = ['HUNTER', 'SHAMAN'];
const LISTAS = ['magias', 'armas', 'pets', 'rotacao', 'atributos', 'notas'];
const CAMPOS = {
  magias: ['nivel', 'texto', 'fonte'],
  armas: ['de', 'ate', 'texto', 'fonte'],
  pets: ['de', 'ate', 'texto', 'fonte'],
  rotacao: ['de', 'ate', 'texto', 'fonte'],
  atributos: ['texto', 'fonte'],
  notas: ['texto', 'fonte'],
  // v2: lista por classe, com as mesmas regras de nivel das outras listas por nivel
  petTreino: ['de', 'ate', 'habilidade', 'texto', 'fonte'],
};
// Campos opcionais (v2, ARQUITETURA.md secao 7): aceitos em toda entrada das listas de LISTAS;
// "magia" e "id" (id de magia do cliente, para o icone; ARQUITETURA.md 11.6) so em magias;
// petTreino nao tem opcionais.
const OPCIONAIS = ['tags', 'raca', 'zona', 'requer', 'prio'];
const TAGS = ['pvp', 'grupo', 'fimdejogo', 'escolhapet'];
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
];
const permitidos = (lista) => {
  if (lista === 'petTreino') return CAMPOS[lista];
  return [...CAMPOS[lista], ...OPCIONAIS, ...(lista === 'magias' ? ['magia', 'id'] : [])];
};
const TEXTO_MAX = 160;

const caminho = process.argv[2];
if (!caminho) {
  console.log('uso: node checar-dicas.mjs <caminho do Dicas.lua>');
  process.exit(1);
}

const problemas = [];
const erro = (onde, msg) => problemas.push(`${onde}: ${msg}`);

function sair(resultadoOk, contagens) {
  if (problemas.length === 0) {
    console.log('ok');
    for (const [classe, c] of Object.entries(contagens)) {
      const listas = c.petTreino !== undefined ? [...LISTAS, 'petTreino'] : LISTAS;
      console.log(`${classe}: ${listas.map((l) => `${l} ${c[l]}`).join(', ')}`);
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

// Regra 2: atribuicao global GuiaForeverDicas
const atrib = ast.body.find(
  (s) =>
    s.type === 'AssignmentStatement' &&
    s.variables.length === 1 &&
    s.variables[0].type === 'Identifier' &&
    s.variables[0].name === 'GuiaForeverDicas',
);
if (!atrib) {
  erro('arquivo', 'falta a atribuicao global GuiaForeverDicas = { ... }');
  sair(false, {});
}
if (atrib.init.length !== 1 || atrib.init[0].type !== 'TableConstructorExpression') {
  erro(`linha ${atrib.loc.start.line}`, 'GuiaForeverDicas deve ser uma tabela { ... }');
  sair(false, {});
}

const nomeChave = (campo) => {
  if (campo.type === 'TableKeyString') return campo.key.name;
  if (campo.type === 'TableKey' && campo.key.type === 'StringLiteral') return campo.key.value;
  return null;
};

const topo = {};
for (const campo of atrib.init[0].fields) {
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
for (const classe of CLASSES) {
  if (!topo[classe]) erro('GuiaForeverDicas', `falta a classe ${classe}`);
}

const inteiroEntre = (node, min, max) => {
  if (!node || node.type !== 'NumericLiteral') return null;
  const v = node.value;
  return Number.isInteger(v) && v >= min && v <= max ? v : null;
};

function checarEntrada(onde, node, lista) {
  if (node.type !== 'TableConstructorExpression') {
    erro(onde, 'entrada deve ser uma tabela { ... }');
    return {};
  }
  const campos = {};
  for (const campo of node.fields) {
    const l = `linha ${campo.loc.start.line}`;
    const nome = campo.type === 'TableKeyString' ? campo.key.name : null;
    if (nome === null) {
      erro(`${onde} ${l}`, 'campo sem nome (esperado nivel/de/ate/texto/fonte, e opcionais)');
      continue;
    }
    if (!permitidos(lista).includes(nome)) {
      erro(`${onde} ${l}`, `campo desconhecido "${nome}" em ${lista}`);
      continue;
    }
    if (nome in campos) {
      erro(`${onde} ${l}`, `campo "${nome}" repetido`);
      continue;
    }
    campos[nome] = campo.value;
  }
  for (const req of CAMPOS[lista]) {
    if (!(req in campos)) erro(onde, `falta o campo "${req}"`);
  }

  // texto
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
  // fonte
  const f = campos.fonte;
  if (f) {
    if (f.type !== 'StringLiteral' || !FONTES.includes(f.value)) {
      const shown = f.type === 'StringLiteral' ? f.value : '(nao e string)';
      erro(onde, `fonte invalida "${shown}" (use: ${FONTES.join(', ')})`);
    }
  }
  // habilidade (so petTreino)
  const h = campos.habilidade;
  if (h && (h.type !== 'StringLiteral' || h.value.trim() === '')) erro(onde, 'habilidade deve ser texto nao vazio');
  // tags: lista de textos, cada um dos TAGS
  const tg = campos.tags;
  if (tg) {
    if (tg.type !== 'TableConstructorExpression') {
      erro(onde, `tags deve ser lista de textos { "pvp", ... } (use: ${TAGS.join(', ')})`);
    } else {
      for (const item of tg.fields) {
        const v = item.type === 'TableValue' ? item.value : null;
        if (!v || v.type !== 'StringLiteral') {
          erro(`${onde} linha ${item.loc.start.line}`, `item de tags deve ser texto (use: ${TAGS.join(', ')})`);
        } else if (!TAGS.includes(v.value)) {
          erro(onde, `tag invalida "${v.value}" (use: ${TAGS.join(', ')})`);
        }
      }
    }
  }
  // prio: 1 essencial, 2 util, 3 opcional
  const pr = campos.prio;
  if (pr && inteiroEntre(pr, 1, 3) === null) erro(onde, 'prio deve ser inteiro de 1 a 3');
  // texto livre nao vazio
  for (const nome of ['raca', 'zona', 'requer', 'magia']) {
    const v = campos[nome];
    if (v && (v.type !== 'StringLiteral' || v.value.trim() === '')) erro(onde, `${nome} deve ser texto nao vazio`);
  }
  return campos;
}

const contarLista = (classe, lista, node) => {
  const onde0 = `${classe}.${lista}`;
  if (node.type !== 'TableConstructorExpression') {
    erro(onde0, 'lista deve ser uma tabela { ... }');
    return;
  }
  const entradas = [];
  for (const campo of node.fields) {
    if (campo.type !== 'TableValue') {
      erro(`${onde0} linha ${campo.loc.start.line}`, 'item deve ser uma entrada { ... } sem chave');
      continue;
    }
    entradas.push(campo.value);
  }
  if (entradas.length === 0 && lista !== 'pets') {
    erro(onde0, 'lista vazia (so pets pode ser vazia)');
  }
  let anterior = null;
  entradas.forEach((node2, i) => {
    const onde = `${onde0}[${i + 1}]`;
    const campos = checarEntrada(onde, node2, lista);
    if (lista === 'magias') {
      const n = inteiroEntre(campos.nivel, 1, 60);
      if (campos.nivel && n === null) erro(onde, 'nivel deve ser inteiro de 1 a 60');
      if (campos.id && inteiroEntre(campos.id, 1, 99999999) === null) erro(onde, 'id deve ser inteiro positivo');
      if (n !== null) {
        if (anterior !== null && n < anterior) erro(onde, `nivel ${n} fora de ordem (anterior ${anterior})`);
        anterior = n;
      }
    } else if (lista === 'armas' || lista === 'pets' || lista === 'rotacao' || lista === 'petTreino') {
      const de = inteiroEntre(campos.de, 1, 60);
      const ate = inteiroEntre(campos.ate, 1, 60);
      if (campos.de && de === null) erro(onde, 'de deve ser inteiro de 1 a 60');
      if (campos.ate && ate === null) erro(onde, 'ate deve ser inteiro de 1 a 60');
      if (de !== null && ate !== null && de > ate) erro(onde, `de (${de}) maior que ate (${ate})`);
      if (de !== null) {
        if (anterior !== null && de < anterior) erro(onde, `de ${de} fora de ordem (anterior ${anterior})`);
        anterior = de;
      }
    }
  });
  contagens[classe] = contagens[classe] || {};
  contagens[classe][lista] = entradas.length;
};

for (const classe of CLASSES) {
  const tab = topo[classe];
  if (!tab) continue;
  contagens[classe] = {};
  if (tab.type !== 'TableConstructorExpression') {
    erro(classe, 'deve ser uma tabela { ... }');
    continue;
  }
  const campos = {};
  for (const campo of tab.fields) {
    const nome = nomeChave(campo);
    const onde = `${classe} linha ${campo.loc.start.line}`;
    if (nome === null) {
      erro(onde, 'item sem chave');
      continue;
    }
    if (nome in campos) {
      erro(onde, `campo "${nome}" repetido`);
      continue;
    }
    campos[nome] = campo.value;
  }
  // personagem
  const p = campos.personagem;
  if (!p) erro(classe, 'falta o campo personagem');
  else if (p.type !== 'StringLiteral' || p.value.trim() === '') erro(classe, 'personagem deve ser string nao vazia');
  // listas
  for (const lista of LISTAS) {
    if (!(lista in campos)) {
      erro(classe, `falta a lista ${lista}`);
      continue;
    }
    contarLista(classe, lista, campos[lista]);
  }
  // petTreino (opcional por classe); se existir, nao pode ser vazia
  if ('petTreino' in campos) contarLista(classe, 'petTreino', campos.petTreino);
}

sair(true, contagens);
