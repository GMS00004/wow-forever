// Baixa as listas e a documentação da API do WoW Forever para api-forever\ (fora do git), nos commits fixados em
// api-forever.json, e confere o hash git (blob) de cada arquivo. São elas que o checar-combate.mjs, o
// rodar-central.mjs e o conferir-doc.mjs leem. Sem dependências: Node 20+ (fetch nativo), sem conta nem chave.
// Uso: node baixar-api-forever.mjs                       baixa o que falta ou está diferente; confere tudo
//      node baixar-api-forever.mjs --conferir            só confere a pasta, sem rede (sai 1 se algo diferir)
//      node baixar-api-forever.mjs --atualizar-hashes    depois de trocar um commit no json: baixa e regrava os hashes
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const AQUI = path.dirname(fileURLToPath(import.meta.url));
const ARQ_PIN = path.join(AQUI, 'api-forever.json');
const PASTA = path.join(AQUI, 'api-forever');
const so = (f) => process.argv.includes(f);
const conferir = so('--conferir');
const atualizar = so('--atualizar-hashes');

const blob = (buf) => createHash('sha1').update(`blob ${buf.length}\0`).update(buf).digest('hex');

async function baixar(repo, commit, de) {
  const url = `https://raw.githubusercontent.com/${repo}/${commit}/${de}`;
  for (let tentativa = 1; tentativa <= 3; tentativa++) {
    try {
      const r = await fetch(url, { headers: { 'User-Agent': 'wow-modder' } });
      if (r.ok) return Buffer.from(await r.arrayBuffer());
      if (r.status === 404) throw new Error(`404 em ${url}`);
      if (tentativa === 3) throw new Error(`HTTP ${r.status} em ${url}`);
    } catch (e) {
      if (tentativa === 3 || String(e.message).startsWith('404')) throw e;
    }
    await new Promise((ok) => setTimeout(ok, 1500 * tentativa));
  }
}

const pin = JSON.parse(readFileSync(ARQ_PIN, 'utf8'));
let baixados = 0, iguais = 0, diferentes = 0;
for (const fonte of pin.fontes) {
  for (const a of fonte.arquivos) {
    const destino = path.join(PASTA, ...a.para.split('/'));
    const local = existsSync(destino) ? readFileSync(destino) : null;
    if (!atualizar && local && blob(local) === a.blob) { iguais++; continue; }
    if (conferir) {
      diferentes++;
      console.log(`DIFERENTE ${a.para} (${local ? 'hash diferente' : 'ausente'})`);
      continue;
    }
    const buf = await baixar(fonte.repo, fonte.commit, a.de);
    if (atualizar) a.blob = blob(buf);
    else if (blob(buf) !== a.blob) throw new Error(`hash diferente do fixado em ${a.de} (${fonte.repo}@${fonte.commit.slice(0, 8)})`);
    mkdirSync(path.dirname(destino), { recursive: true });
    writeFileSync(destino, buf);
    baixados++;
  }
  if (!conferir) {
    const marca = `${fonte.commit.slice(0, 8)} ${fonte.data} ${fonte.build} ${fonte.repo}\n`;
    const pastaMarca = fonte.arquivos[0].para.includes('/') ? path.join(PASTA, fonte.arquivos[0].para.split('/')[0]) : PASTA;
    mkdirSync(pastaMarca, { recursive: true });
    writeFileSync(path.join(pastaMarca, '_commit.txt'), marca);
  }
}
if (atualizar) writeFileSync(ARQ_PIN, JSON.stringify(pin, null, 2) + '\n');
const total = pin.fontes.reduce((s, f) => s + f.arquivos.length, 0);
console.log(`API-FOREVER arquivos=${total} baixados=${baixados} iguais=${iguais}${conferir ? ` diferentes=${diferentes}` : ''}${atualizar ? ' hashes=regravados' : ''}`);
process.exit(conferir && diferentes > 0 ? 1 : 0);
