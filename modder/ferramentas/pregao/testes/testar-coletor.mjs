// Testes do coletar-foto.mjs, com --fonte (sem rede). Uso: node testes/testar-coletor.mjs
// Usa uma pasta temporaria em os.tmpdir() e apaga no fim.
import { mkdtemp, mkdir, readFile, readdir, writeFile, rm } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { gunzipSync } from 'node:zlib';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { PUBLICO } from '../comum.mjs';

const AQUI = path.dirname(fileURLToPath(import.meta.url));
const COLETOR = path.resolve(AQUI, '..', 'coletar-foto.mjs');

let casos = 0;
let erros = 0;
function conferir(nome, ok, extra = '') {
  casos++;
  if (!ok) {
    erros++;
    console.log(`FALHOU ${nome}${extra ? ` (${extra})` : ''}`);
  }
}

function rodar(args) {
  const r = spawnSync(process.execPath, [COLETOR, ...args], { encoding: 'utf8' });
  return { codigo: r.status, saida: (r.stdout ?? '').trim(), erro: (r.stderr ?? '').trim() };
}

async function linhasDe(arq) {
  return (await readFile(arq, 'utf8')).split('\n').filter((l) => l !== '');
}

async function gzsEm(pasta) {
  try {
    return (await readdir(pasta)).filter((n) => n.endsWith('.txt.gz'));
  } catch {
    return [];
  }
}

async function main() {
  const base = await mkdtemp(path.join(tmpdir(), 'coletor-foto-'));
  try {
    const textoIndice = await readFile(path.join(PUBLICO, 'index.txt'), 'utf8');
    const casaFonte = await readFile(path.join(PUBLICO, 'us-111.txt'));
    const m = /^file=us-111\.txt\s.*?\bsnapshot=(\d+)/m.exec(textoIndice);
    const snapshot = m ? m[1] : '';
    conferir('index tem snapshot de us-111.txt', snapshot !== '');

    const pasta = path.join(base, 'fotos');
    const args = ['--pasta', pasta, '--fonte', PUBLICO];

    // 1a execucao: grava.
    const r1 = rodar(args);
    conferir('1a codigo 0', r1.codigo === 0, `codigo=${r1.codigo} ${r1.erro}`);
    conferir('1a saida comeca com novo', r1.saida.startsWith('novo'), r1.saida);
    const gzNome = `us-111-${snapshot}.txt.gz`;
    let gzIgual = false;
    try {
      gzIgual = gunzipSync(await readFile(path.join(pasta, gzNome))).equals(casaFonte);
    } catch {
      gzIgual = false;
    }
    conferir('gz existe e gunzip e identico ao us-111.txt', gzIgual, gzNome);
    const idx1 = await linhasDe(path.join(pasta, 'indice.txt')).catch(() => []);
    conferir('indice tem 1 linha', idx1.length === 1, `${idx1.length} linhas`);
    const campos = (idx1[0] ?? '').split(' ');
    conferir('indice tem 5 campos', campos.length === 5, `${campos.length} campos`);
    conferir('indice snapshot igual ao do index', campos[0] === snapshot, campos[0]);

    // 2a execucao: repetida, nada novo.
    const r2 = rodar(args);
    conferir('2a codigo 0', r2.codigo === 0, `codigo=${r2.codigo} ${r2.erro}`);
    conferir('2a saida comeca com repetida', r2.saida.startsWith('repetida'), r2.saida);
    const idx2 = await linhasDe(path.join(pasta, 'indice.txt')).catch(() => []);
    conferir('indice continua com 1 linha', idx2.length === 1, `${idx2.length} linhas`);
    const log2 = await linhasDe(path.join(pasta, 'coletor.log')).catch(() => []);
    conferir('log tem 2 linhas', log2.length === 2, `${log2.length} linhas`);

    // sha256 errado: um byte alterado no us-111.txt; sai com 2 e nao grava gz.
    const fonteRuim = path.join(base, 'fonte-ruim');
    await mkdir(fonteRuim, { recursive: true });
    await writeFile(path.join(fonteRuim, 'index.txt'), textoIndice);
    const alterado = Buffer.from(casaFonte);
    alterado[100] ^= 0x01;
    await writeFile(path.join(fonteRuim, 'us-111.txt'), alterado);
    const pastaRuim = path.join(base, 'fotos-ruim');
    const r3 = rodar(['--pasta', pastaRuim, '--fonte', fonteRuim]);
    conferir('sha errado: codigo 2', r3.codigo === 2, `codigo=${r3.codigo} ${r3.erro}`);
    conferir('sha errado: saida comeca com erro sha256', r3.saida.startsWith('erro sha256'), r3.saida);
    conferir('sha errado: nenhum gz gravado', (await gzsEm(pastaRuim)).length === 0);

    console.log(`testar-coletor: casos=${casos} erros=${erros}`);
    process.exitCode = erros > 0 ? 1 : 0;
  } finally {
    await rm(base, { recursive: true, force: true });
  }
}

main().catch((e) => {
  console.log(`testar-coletor: erro ${String(e.message).replace(/[^\x20-\x7e]/g, '?')}`);
  process.exitCode = 1;
});
