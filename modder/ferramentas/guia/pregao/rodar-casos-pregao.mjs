// Roda o checar-pregao.mjs contra cada pasta de casos-pregao\regras\ e confere o esperado.
// Uso: node pregao/rodar-casos-pregao.mjs   (a partir de ferramentas\guia; funciona de qualquer pasta)
// esperado.txt: "0" (bom: saida 0) ou "R<nn>" (ruim: saida diferente de 0 com o id R<nn> numa linha de achado).
import { spawnSync } from 'node:child_process';
import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const aqui = dirname(fileURLToPath(import.meta.url));
const raiz = join(aqui, '..', 'casos-pregao', 'regras');
const checador = join(aqui, 'checar-pregao.mjs');

const pastas = existsSync(raiz) && statSync(raiz).isDirectory()
  ? readdirSync(raiz).filter(p => statSync(join(raiz, p)).isDirectory()).sort()
  : [];

let erros = 0;
for (const caso of pastas) {
  const dir = join(raiz, caso);
  const arqEsperado = join(dir, 'esperado.txt');
  const problemas = [];
  let esperado = null;
  if (!existsSync(arqEsperado)) problemas.push('falta esperado.txt');
  else {
    esperado = readFileSync(arqEsperado, 'utf8').trim();
    if (!/^(0|R\d{2})$/.test(esperado)) problemas.push(`esperado.txt invalido: "${esperado}"`);
  }
  const r = spawnSync(process.execPath, [checador, dir], { encoding: 'utf8' });
  const linhas = (r.stdout || '').split(/\r?\n/).filter(Boolean);
  if (!problemas.length) {
    if (esperado === '0') {
      if (r.status !== 0) problemas.push(`codigo ${r.status}, esperava 0`);
    } else {
      if (r.status === 0) problemas.push(`codigo 0, esperava diferente de 0`);
      const achou = linhas.some(l => l.split(' ')[1] === esperado);
      if (!achou) problemas.push(`o id ${esperado} nao aparece na saida`);
    }
  }
  if (problemas.length) {
    erros++;
    console.log(`FALHA ${caso}: ${problemas.join('; ')}`);
    linhas.forEach(l => console.log('     ' + l));
  } else {
    console.log(`OK    ${caso}`);
  }
}
if (!pastas.length) { erros++; console.log(`FALHA nenhuma pasta de caso em ${raiz}`); }
console.log(`RESUMO casos=${pastas.length} erros=${erros}`);
process.exit(erros ? 1 : 0);
