// Roda os checadores (checar-dicas.mjs e checar-ajuda.mjs) em cada caso de casos/.
// Caso com erroEsperado null: tem de sair com 0 e imprimir "ok".
// Caso com erroEsperado (regex): tem de sair com 1 e listar exatamente 1 problema casando a regex.
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const aqui = dirname(fileURLToPath(import.meta.url));
const casos = join(aqui, 'casos');
const CHECADORES = {
  dicas: join(aqui, 'checar-dicas.mjs'),
  ajuda: join(aqui, 'checar-ajuda.mjs'),
};

const TABELA = [
  // Dicas.lua (checar-dicas.mjs)
  { checador: 'dicas', arquivo: 'bom.lua', erroEsperado: null },
  { checador: 'dicas', arquivo: 'ruim-acento.lua', erroEsperado: /byte nao ASCII/ },
  { checador: 'dicas', arquivo: 'ruim-nivel61.lua', erroEsperado: /nivel deve ser inteiro de 1 a 60/ },
  { checador: 'dicas', arquivo: 'ruim-de-maior-ate.lua', erroEsperado: /de \(12\) maior que ate \(10\)/ },
  { checador: 'dicas', arquivo: 'ruim-fonte-invalida.lua', erroEsperado: /fonte invalida "Wowhead"/ },
  { checador: 'dicas', arquivo: 'ruim-texto-161.lua', erroEsperado: /texto com 161 caracteres/ },
  { checador: 'dicas', arquivo: 'ruim-sem-rotacao-shaman.lua', erroEsperado: /falta a lista rotacao/ },
  { checador: 'dicas', arquivo: 'ruim-campo-extra.lua', erroEsperado: /campo desconhecido "extra"/ },
  { checador: 'dicas', arquivo: 'ruim-tag-invalida.lua', erroEsperado: /tag invalida "xyz"/ },
  { checador: 'dicas', arquivo: 'ruim-tags-string.lua', erroEsperado: /tags deve ser lista de textos/ },
  { checador: 'dicas', arquivo: 'ruim-prio-4.lua', erroEsperado: /prio deve ser inteiro de 1 a 3/ },
  { checador: 'dicas', arquivo: 'ruim-pettreino-sem-habilidade.lua', erroEsperado: /falta o campo "habilidade"/ },
  // Ajuda.lua (checar-ajuda.mjs), na subpasta casos/ajuda/
  { checador: 'ajuda', arquivo: 'ajuda/bom.lua', erroEsperado: null },
  { checador: 'ajuda', arquivo: 'ajuda/ruim-id-repetido.lua', erroEsperado: /id "pet-feed" repetido/ },
  { checador: 'ajuda', arquivo: 'ajuda/ruim-pergunta-longa.lua', erroEsperado: /pergunta com \d+ caracteres \(maximo 90\)/ },
  { checador: 'ajuda', arquivo: 'ajuda/ruim-fonte-invalida.lua', erroEsperado: /fonte invalida "Wowhead"/ },
];

let falhas = 0;

function rodar(checador, arquivo) {
  const r = spawnSync(process.execPath, [CHECADORES[checador], join(casos, arquivo)], { encoding: 'utf8' });
  return { code: r.status, out: (r.stdout || '') + (r.stderr || '') };
}

for (const caso of TABELA) {
  const r = rodar(caso.checador, caso.arquivo);
  const problemas = r.out.split('\n').filter((l) => l.startsWith('  - '));
  if (caso.erroEsperado === null) {
    const ok = r.code === 0 && /^ok$/m.test(r.out);
    if (!ok) falhas++;
    console.log(`${ok ? 'PASSOU OK    ' : 'ERRO        '} [${caso.checador}] ${caso.arquivo} -> saida ${r.code} (esperado 0, com "ok")`);
    if (!ok) console.log(r.out.trimEnd().split('\n').map((l) => '    ' + l).join('\n'));
    continue;
  }
  const motivoOk = problemas.some((l) => caso.erroEsperado.test(l));
  const ok = r.code === 1 && motivoOk && problemas.length === 1;
  if (!ok) falhas++;
  const quadro = ok ? 'BARRADO OK  ' : 'ERRO        ';
  const detalhe = problemas.length ? problemas.map((l) => l.slice(4)).join(' | ') : '(sem problema listado)';
  console.log(`${quadro} [${caso.checador}] ${caso.arquivo} -> saida ${r.code}`);
  console.log(`    motivo: ${detalhe}`);
  if (!ok) console.log(`    esperado: saida 1, 1 problema casando ${caso.erroEsperado}`);
}

console.log(falhas === 0 ? `\nTodos os casos como esperado (${TABELA.length} casos).` : `\n${falhas} caso(s) fora do esperado.`);
process.exit(falhas === 0 ? 0 : 1);
