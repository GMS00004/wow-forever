// Mapa id de item -> nome do icone, para o real.html desenhar a aba Crafts (GuiaForever 1.4).
// Le os ids do RotaCrafts.lua (produto, materiais e padroes) e cruza as tabelas Item (IconFileDataID) e
// ManifestInterfaceData (nome do arquivo) do wago.tools no build do cliente (cache do pregao).
// Uso (nesta pasta): node itens-icones.mjs   -> grava itens-icones.json e lista os icones que faltam em icones\
import { pathToFileURL, fileURLToPath } from 'node:url';
import { readFile, writeFile, access } from 'node:fs/promises';
import path from 'node:path';

const aqui = path.dirname(fileURLToPath(import.meta.url));
const { tabela } = await import(pathToFileURL(path.join(aqui, '..', '..', 'pregao', 'comum.mjs')).href);
const lua = await readFile(path.join(aqui, '..', '..', '..', 'addons-proprios', 'GuiaForever', 'RotaCrafts.lua'), 'utf8');

const ids = new Set();
for (const m of lua.matchAll(/(?:produto|id|padrao) = (\d+)/g)) ids.add(Number(m[1]));

const fdid = new Map();
for (const r of await tabela('Item', ['ID', 'IconFileDataID'])) {
  if (ids.has(Number(r.ID))) fdid.set(Number(r.ID), Number(r.IconFileDataID));
}
const quero = new Set(fdid.values());
const nomes = new Map();
for (const r of await tabela('ManifestInterfaceData', ['ID', 'FilePath', 'FileName'])) {
  if (quero.has(Number(r.ID))) nomes.set(Number(r.ID), String(r.FileName).replace(/\.blp$/i, '').toLowerCase());
}
const mapa = {};
for (const [id, f] of fdid) if (nomes.has(f)) mapa[id] = nomes.get(f);
await writeFile(path.join(aqui, 'itens-icones.json'), JSON.stringify(mapa, null, 1) + '\n');

const faltam = [];
for (const n of new Set(Object.values(mapa))) {
  try { await access(path.join(aqui, 'icones', n + '.jpg')); } catch { faltam.push(n); }
}
console.log(`itens=${ids.size} com_icone=${Object.keys(mapa).length} faltam_baixar=${faltam.length}${faltam.length ? ': ' + faltam.join(' ') : ''}`);
