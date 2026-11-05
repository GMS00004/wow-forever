// Roda o checar-dicas.mjs em cada caso de casos/. Falha se o bom nao passar ou se um ruim passar
// ou falhar por motivo diferente do esperado (e com exatamente 1 problema).
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const aqui = dirname(fileURLToPath(import.meta.url));
const checador = join(aqui, 'checar-dicas.mjs');
const casos = join(aqui, 'casos');

const ruins = [
  { arq: 'ruim-acento.lua', motivo: /byte nao ASCII/, regra: 'acento no texto (regra 1)' },
  { arq: 'ruim-nivel61.lua', motivo: /nivel deve ser inteiro de 1 a 60/, regra: 'nivel 61 (regra 3)' },
  { arq: 'ruim-de-maior-ate.lua', motivo: /de \(12\) maior que ate \(10\)/, regra: 'de > ate (regra 4)' },
  { arq: 'ruim-fonte-invalida.lua', motivo: /fonte invalida "Wowhead"/, regra: 'fonte fora da lista (regra 5)' },
  { arq: 'ruim-texto-161.lua', motivo: /texto com 161 caracteres/, regra: 'texto com 161 caracteres (regra 5)' },
  { arq: 'ruim-sem-rotacao-shaman.lua', motivo: /falta a lista rotacao/, regra: 'falta rotacao do SHAMAN (regra 2)' },
  { arq: 'ruim-campo-extra.lua', motivo: /campo desconhecido "extra"/, regra: 'campo desconhecido (regra 6)' },
];

let falhas = 0;

function rodar(arq) {
  const r = spawnSync(process.execPath, [checador, join(casos, arq)], { encoding: 'utf8' });
  return { code: r.status, out: (r.stdout || '') + (r.stderr || '') };
}

// Caso bom
{
  const r = rodar('bom.lua');
  const ok = r.code === 0 && /^ok$/m.test(r.out);
  if (!ok) falhas++;
  console.log(`${ok ? 'PASSOU OK    ' : 'ERRO        '} bom.lua -> saida ${r.code} (esperado 0, com "ok")`);
  if (!ok) console.log(r.out.trimEnd().split('\n').map((l) => '    ' + l).join('\n'));
}

// Casos ruins
for (const caso of ruins) {
  const r = rodar(caso.arq);
  const problemas = r.out.split('\n').filter((l) => l.startsWith('  - '));
  const motivoOk = problemas.some((l) => caso.motivo.test(l));
  const ok = r.code === 1 && motivoOk && problemas.length === 1;
  if (!ok) falhas++;
  const quadro = ok ? 'BARRADO OK  ' : 'ERRO        ';
  const detalhe = problemas.length ? problemas.map((l) => l.slice(4)).join(' | ') : '(sem problema listado)';
  console.log(`${quadro} ${caso.arq} -> saida ${r.code}, regra: ${caso.regra}`);
  console.log(`    motivo: ${detalhe}`);
  if (!ok) console.log(`    esperado: saida 1, 1 problema casando ${caso.motivo}`);
}

console.log(falhas === 0 ? `\nTodos os casos como esperado (${1 + ruins.length} casos).` : `\n${falhas} caso(s) fora do esperado.`);
process.exit(falhas === 0 ? 0 : 1);
