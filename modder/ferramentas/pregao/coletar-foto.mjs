// Guarda a foto horaria publica de precos do leilao (da casa do jogador, casaPublica() em comum.mjs) em --pasta,
// sem sobrescrever as anteriores.
// Uso: node coletar-foto.mjs [--pasta <dir>] [--fonte <dir>] [--casa us-NNN]
// --fonte le index.txt e <casa>.txt desse diretorio (teste). Sem ele, baixa de URL_PUBLICA.
// Saida: uma linha, igual a do coletor.log sem a data. Codigos: 0 novo/repetida, 1 erro, 2 sha256.
import { readFile, writeFile, mkdir, appendFile, readdir } from 'node:fs/promises';
import { gzipSync } from 'node:zlib';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { PUBLICO, URL_PUBLICA, casaPublica, sha256, lerKv } from './comum.mjs';

const LIMITE_LOG = 2000;
const ESPERA_SHA_MS = 20000;
const PASTA_PADRAO = path.join(PUBLICO, 'fotos');

class ErroColeta extends Error {
  constructor(msg, codigo = 1) {
    super(msg);
    this.codigo = codigo;
  }
}

// Texto em uma linha so com ASCII imprimivel.
const ascii = (s) => String(s).replace(/\s+/g, ' ').replace(/[^\x20-\x7e]/g, '?').trim();

function carimbo(d = new Date()) {
  const p = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
}

function lerArgs(argv) {
  const opc = { pasta: PASTA_PADRAO, fonte: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--pasta' || a === '--fonte') {
      const v = argv[++i];
      if (!v || v.startsWith('--')) throw new ErroColeta(`${a} sem valor`);
      opc[a.slice(2)] = path.resolve(v);
    } else {
      throw new ErroColeta(`argumento desconhecido: ${ascii(a)}`);
    }
  }
  return opc;
}

async function lerTextoOpcional(arq) {
  try {
    return await readFile(arq, 'utf8');
  } catch (e) {
    if (e.code === 'ENOENT') return '';
    throw e;
  }
}

// Acrescenta a linha ao coletor.log (guarda as ultimas 2000) e devolve a linha sem a data.
async function registrar(pasta, tipo, detalhe) {
  const arq = path.join(pasta, 'coletor.log');
  await mkdir(pasta, { recursive: true });
  const antigas = (await lerTextoOpcional(arq)).split('\n').filter((l) => l !== '');
  const linhas = [...antigas, `${carimbo()} ${tipo} ${detalhe}`].slice(-LIMITE_LOG);
  await writeFile(arq, linhas.join('\n') + '\n');
  return `${tipo} ${detalhe}`;
}

// Confere "#qmi 1" e devolve { snapshot, built, sha } da linha file=<casa>.txt do index.
function lerIndice(texto) {
  const linhas = texto.split(/\r?\n/);
  if (linhas[0].trim() !== '#qmi 1') throw new ErroColeta('index.txt sem #qmi 1');
  const kvs = linhas.map(lerKv);
  const built = kvs.find((kv) => kv.built !== undefined)?.built;
  const casa = kvs.find((kv) => kv.file === `${casaPublica()}.txt`);
  if (!/^\d+$/.test(built ?? '')) throw new ErroColeta('index.txt sem built=');
  if (!casa || !/^\d+$/.test(casa.snapshot ?? '') || !/^[0-9a-f]{64}$/.test(casa.sha256 ?? '')) {
    throw new ErroColeta(`index.txt sem linha valida de ${casaPublica()}.txt`);
  }
  return { snapshot: casa.snapshot, built, sha: casa.sha256 };
}

async function baixarBytes(nome) {
  const url = `${URL_PUBLICA}/${nome}`;
  const r = await fetch(url);
  if (!r.ok) throw new ErroColeta(`HTTP ${r.status} em ${nome}`);
  return Buffer.from(await r.arrayBuffer());
}

// Devolve { snapshot, built, sha, casa (Buffer) } com o sha256 conferido.
// Com --fonte: uma tentativa. Sem --fonte: se nao bater, espera 20 s e baixa de novo uma vez.
async function obterFoto(fonte) {
  const nome = `${casaPublica()}.txt`;
  const tentativas = fonte ? 1 : 2;
  for (let t = 1; t <= tentativas; t++) {
    const indiceBuf = fonte ? await readFile(path.join(fonte, 'index.txt')) : await baixarBytes('index.txt');
    const casa = fonte ? await readFile(path.join(fonte, nome)) : await baixarBytes(nome);
    const ind = lerIndice(indiceBuf.toString('utf8'));
    if (sha256(casa) === ind.sha) return { ...ind, casa };
    if (t < tentativas) await new Promise((r) => setTimeout(r, ESPERA_SHA_MS));
  }
  throw new ErroColeta(`sha256 nao bate para ${nome}${fonte ? '' : ' apos nova tentativa'}`, 2);
}

async function principal(argv) {
  let opc;
  try {
    opc = lerArgs(argv);
  } catch (e) {
    console.log(`erro ${ascii(e.message)}`);
    return 1;
  }
  const pasta = opc.pasta;
  let tipo = 'erro';
  let detalhe = '';
  let codigo = 0;
  try {
    const foto = await obterFoto(opc.fonte);
    const nomeGz = `${casaPublica()}-${foto.snapshot}.txt.gz`;
    const arqIndice = path.join(pasta, 'indice.txt');
    await mkdir(pasta, { recursive: true });
    const indiceAtual = await lerTextoOpcional(arqIndice);
    const nomes = await readdir(pasta);
    const jaTem = indiceAtual.split('\n').some((l) => l.split(' ')[0] === foto.snapshot);
    if (jaTem || nomes.includes(nomeGz)) {
      tipo = 'repetida';
      detalhe = `snapshot=${foto.snapshot} ja gravada`;
    } else {
      const texto = foto.casa.toString('utf8');
      const itens = texto.split('\n').filter((l) => l.startsWith('c ') || l.startsWith('i ')).length;
      await writeFile(path.join(pasta, nomeGz), gzipSync(foto.casa), { flag: 'wx' });
      const sep = indiceAtual !== '' && !indiceAtual.endsWith('\n') ? '\n' : '';
      await appendFile(arqIndice, `${sep}${foto.snapshot} ${foto.built} ${nomeGz} ${itens} ${sha256(foto.casa)}\n`);
      tipo = 'novo';
      detalhe = `snapshot=${foto.snapshot} itens=${itens}`;
    }
  } catch (e) {
    codigo = e instanceof ErroColeta ? e.codigo : 1;
    tipo = 'erro';
    detalhe = ascii(e.message);
  }
  let linha;
  try {
    linha = await registrar(pasta, tipo, detalhe);
  } catch (e) {
    linha = `${tipo} ${detalhe} (log nao gravado: ${ascii(e.message)})`;
    codigo = codigo || 1;
  }
  console.log(linha);
  return codigo;
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  process.exitCode = await principal(process.argv.slice(2));
}
