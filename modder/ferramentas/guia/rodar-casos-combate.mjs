// Roda o checar-combate.mjs contra cada pasta de casos-combate\ e confere o esperado.
// Uso: node rodar-casos-combate.mjs
import { spawnSync } from 'node:child_process';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const aqui = dirname(fileURLToPath(import.meta.url));
// pasta: [args extras, regra do unico ERRO esperado (null = nenhum), regra do unico AVISO esperado (ou null)]
const casos = {
  'bom': [[], null, null],
  'r1': [[], 'R1', null], 'r2': [[], 'R2', null], 'r3': [[], 'R3', null], 'r4': [[], 'R4', null],
  'r5': [[], 'R5', null], 'r6': [[], 'R6', null], 'r7': [[], 'R7', null], 'r8': [[], 'R8', null], 'r9': [[], 'R9', null],
  'r2-aura-ok': [[], null, null], 'r2-aura-sem-guarda': [[], 'R2', null], 'r2-aura-sem-secreto': [[], 'R2', null],
  'r6-aviso': [[], null, 'R6'],
  'prefixos': [['--prefixos', 'MeuExtra'], null, null],
  'toc': [['--toc'], 'TOC', null],
};
let falhas = 0;
for (const [pasta, [extra, regraErro, regraAviso]] of Object.entries(casos)) {
  const r = spawnSync(process.execPath, [join(aqui, 'checar-combate.mjs'), join(aqui, 'casos-combate', pasta), ...extra], { encoding: 'utf8' });
  const linhas = r.stdout.split(/\r?\n/);
  const erros = linhas.filter(l => l.startsWith('ERRO '));
  const avisos = linhas.filter(l => l.startsWith('AVISO '));
  const problemas = [];
  const regraDe = l => (l.match(/ ([A-Z0-9]+): /) || [])[1];
  if (regraErro) {
    const unico = regraErro !== 'TOC'; // o .toc desencontrado gera um ERRO por arquivo de diferenca
    if ((unico && erros.length !== 1) || !erros.length || erros.some(e => regraDe(e) !== regraErro)) problemas.push(`esperava ${unico ? 'exatamente 1' : 'so'} ERRO ${regraErro}, veio ${erros.length}`);
    if (r.status !== 1) problemas.push(`codigo ${r.status}, esperava 1`);
  } else {
    if (erros.length) problemas.push(`esperava 0 ERRO, veio ${erros.length}`);
    if (r.status !== 0) problemas.push(`codigo ${r.status}, esperava 0`);
  }
  if (regraAviso) { if (avisos.length !== 1 || regraDe(avisos[0]) !== regraAviso) problemas.push(`esperava exatamente 1 AVISO ${regraAviso}, veio ${avisos.length}`); }
  else if (avisos.length) problemas.push(`esperava 0 AVISO, veio ${avisos.length}`);
  if (problemas.length) { falhas++; console.log(`FALHA ${pasta}: ${problemas.join('; ')}`); linhas.filter(Boolean).forEach(l => console.log('     ' + l)); }
  else console.log(`ok    ${pasta}`);
}
console.log(falhas ? `${falhas} caso(s) com falha` : `todos os ${Object.keys(casos).length} casos como esperado`);
process.exit(falhas ? 1 : 0);
