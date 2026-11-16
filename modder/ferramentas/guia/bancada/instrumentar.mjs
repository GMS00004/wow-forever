// Reescreve um .lua para a bancada de valor secreto (CONTRATO.md 11.2).
// instrumentar(texto, nomeArquivo) devolve o texto Lua reescrito, sem criar nem remover quebra de linha:
//   - condicao de if, elseif, while e repeat-until, operando de not e lado esquerdo de and/or -> __B( ... )
//   - a == b -> __EQ(a, b); a ~= b -> (not __EQ(a, b))
//   - indice nao literal t[k] -> t[__K(k)]
// Uso direto: node bancada/instrumentar.mjs arquivo.lua   (imprime o texto reescrito)
import { createRequire } from "node:module";
import { readFileSync } from "node:fs";
import { pathToFileURL } from "node:url";
import { resolve } from "node:path";

const require = createRequire(import.meta.url);
const luaparse = require("luaparse");

const LITERAIS = new Set(["StringLiteral", "NumericLiteral", "BooleanLiteral", "NilLiteral"]);

// acha o operador entre os dois operandos, pulando comentarios
function acharOperador(texto, de, ate, op) {
  let i = de;
  while (i < ate) {
    if (texto.startsWith("--", i)) {
      const m = /^--\[(=*)\[/.exec(texto.slice(i, ate));
      if (m) {
        const fim = texto.indexOf("]" + m[1] + "]", i + m[0].length);
        i = fim < 0 ? ate : fim + m[1].length + 2;
      } else {
        const fim = texto.indexOf("\n", i);
        i = fim < 0 ? ate : fim;
      }
      continue;
    }
    if (texto.startsWith(op, i)) return i;
    i++;
  }
  throw new Error("operador " + op + " nao encontrado");
}

export function instrumentar(texto, nomeArquivo = "?") {
  let ast;
  try {
    ast = luaparse.parse(texto, { luaVersion: "5.1", ranges: true, comments: false });
  } catch (e) {
    throw new Error(nomeArquivo + ": " + e.message);
  }
  // edicao: { ini, fim, texto, cls (0 fecha, 1 meio, 2 abre), prof }
  const edicoes = [];
  const embrulhar = (no, profPai, nome) => {
    edicoes.push({ ini: no.range[0], fim: no.range[0], texto: nome + "(", cls: 2, prof: profPai + 0.5 });
    edicoes.push({ ini: no.range[1], fim: no.range[1], texto: ")", cls: 0, prof: profPai + 0.5 });
  };
  const visitar = (n, prof) => {
    if (!n || typeof n !== "object") return;
    if (Array.isArray(n)) { n.forEach((x) => visitar(x, prof)); return; }
    switch (n.type) {
      case "IfClause":
      case "ElseifClause":
      case "WhileStatement":
      case "RepeatStatement":
        if (n.condition) embrulhar(n.condition, prof, "__B");
        break;
      case "UnaryExpression":
        if (n.operator === "not") embrulhar(n.argument, prof, "__B");
        break;
      case "LogicalExpression":
        embrulhar(n.left, prof, "__B");
        break;
      case "BinaryExpression":
        if (n.operator === "==" || n.operator === "~=") {
          const neg = n.operator === "~=";
          const pos = acharOperador(texto, n.left.range[1], n.right.range[0], n.operator);
          edicoes.push({ ini: n.range[0], fim: n.range[0], texto: neg ? "(not __EQ(" : "__EQ(", cls: 2, prof });
          edicoes.push({ ini: pos, fim: pos + 2, texto: ",", cls: 1, prof });
          edicoes.push({ ini: n.range[1], fim: n.range[1], texto: neg ? "))" : ")", cls: 0, prof });
        }
        break;
      case "IndexExpression":
        if (n.index && !LITERAIS.has(n.index.type)) embrulhar(n.index, prof, "__K");
        break;
      default:
    }
    for (const k of Object.keys(n)) {
      if (k === "range" || k === "loc" || k === "type") continue;
      visitar(n[k], prof + 1);
    }
  };
  visitar(ast, 0);

  edicoes.sort((a, b) => {
    if (a.ini !== b.ini) return a.ini - b.ini;
    if (a.cls !== b.cls) return a.cls - b.cls;
    return a.cls === 0 ? b.prof - a.prof : a.prof - b.prof; // fecha: interno primeiro; abre: externo primeiro
  });
  // aplica de tras para frente: monta a saida do fim ao comeco
  let saida = texto;
  for (let i = edicoes.length - 1; i >= 0; i--) {
    const e = edicoes[i];
    saida = saida.slice(0, e.ini) + e.texto + saida.slice(e.fim);
  }
  return saida;
}

const ehDireto = process.argv[1] && pathToFileURL(resolve(process.argv[1])).href === import.meta.url;
if (ehDireto) {
  const arq = process.argv[2];
  if (!arq) { console.error("uso: node bancada/instrumentar.mjs arquivo.lua"); process.exit(2); }
  process.stdout.write(instrumentar(readFileSync(arq, "utf8"), arq));
}
