import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const dir = path.dirname(fileURLToPath(import.meta.url));
const falhas = [];

let dados;
try {
  dados = JSON.parse(fs.readFileSync(path.join(dir, 'saltii.json'), 'utf8'));
} catch (e) {
  console.error(`FALHA: saltii.json não abre: ${e.message}`);
  process.exit(1);
}

const doadores = dados.doadores ?? {};
const temDoador = (chave, n, nv, z) => (doadores[chave] ?? []).some(d =>
  d.n === n && (nv === undefined || d.nv === nv) && (z === undefined || d.z === z));

if (!temDoador('Claw 3', 'Black Bear Patriarch', '16-17', 'Loch Modan')) {
  falhas.push('doadores["Claw 3"] sem Black Bear Patriarch (nv 16-17, Loch Modan)');
}
if (!temDoador('Bite 2', 'Prowler')) {
  falhas.push('doadores["Bite 2"] sem Prowler');
}
if ((doadores['Demoralizing Screech 1'] ?? []).length !== 2) {
  falhas.push('doadores["Demoralizing Screech 1"] não tem dois itens');
}

const nFamilias = Object.keys(dados.familias ?? {}).length;
if (nFamilias !== 18) {
  falhas.push(`familias tem ${nFamilias} chaves, esperado 18`);
}

const EN_DASH = '–';
for (const [chave, lista] of Object.entries(doadores)) {
  for (const d of lista) {
    if (String(d.nv).includes(EN_DASH)) falhas.push(`en-dash em doadores["${chave}"] nv "${d.nv}"`);
  }
}
for (const r of dados.raros ?? []) {
  if (String(r.nv).includes(EN_DASH)) falhas.push(`en-dash em raros "${r.n}" nv "${r.nv}"`);
}

const itens = Object.values(doadores).reduce((s, l) => s + l.length, 0);
console.log(`doadores: ${itens} itens em ${Object.keys(doadores).length} ranks`);

if (falhas.length) {
  for (const f of falhas) console.error(`FALHA: ${f}`);
  process.exit(1);
}
console.log('OK: checagens passaram');
