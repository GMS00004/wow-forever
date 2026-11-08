// Checa ludideo-tier.json: 18 familias, notas S/A/B/C/D, texto ASCII de ate 160 caracteres,
// e as tres letras fixas (Cat leveling S, Bat PvP S, Crocolisk PvP S). Imprime a tabela.
import { readFileSync } from 'node:fs';

const FAMILIAS = [
  'Cat', 'Raptor', 'Wind Serpent', 'Scorpid', 'Boar', 'Carrion Bird', 'Bear', 'Gorilla', 'Turtle',
  'Spider', 'Crab', 'Hyena', 'Crocolisk', 'Bat', 'Bird of Prey', 'Tallstrider', 'Wolf', 'Fox',
];
const LETRAS = ['S', 'A', 'B', 'C', 'D'];
const FIXAS = [
  ['Cat', 'leveling', 'S'],
  ['Bat', 'pvp', 'S'],
  ['Crocolisk', 'pvp', 'S'],
];

const erros = [];
let dados;
try {
  dados = JSON.parse(readFileSync(new URL('./ludideo-tier.json', import.meta.url), 'utf8'));
} catch (e) {
  console.error(`ERRO: nao consegui ler ludideo-tier.json: ${e.message}`);
  process.exit(1);
}

const familias = dados.familias ?? {};

for (const nome of FAMILIAS) {
  if (!(nome in familias)) erros.push(`familia faltando: ${nome}`);
}
for (const nome of Object.keys(familias)) {
  if (!FAMILIAS.includes(nome)) erros.push(`familia fora da lista das 18: ${nome}`);
}

for (const nome of FAMILIAS) {
  const e = familias[nome];
  if (!e) continue;
  for (const campo of ['leveling', 'pvp']) {
    if (!LETRAS.includes(e[campo])) {
      erros.push(`${nome}: ${campo} = ${JSON.stringify(e[campo])} nao e S/A/B/C/D`);
    }
  }
  if (!Array.isArray(e.notas) || e.notas.length < 1 || e.notas.length > 3) {
    erros.push(`${nome}: precisa de 1 a 3 notas`);
    continue;
  }
  e.notas.forEach((n, i) => {
    if (typeof n?.t !== 'string') {
      erros.push(`${nome}: nota ${i + 1} sem campo t`);
      return;
    }
    if (/[^\x00-\x7F]/.test(n.t)) erros.push(`${nome}: nota ${i + 1} tem caractere fora do ASCII`);
    if (n.t.length > 160) erros.push(`${nome}: nota ${i + 1} tem ${n.t.length} caracteres (max 160)`);
  });
}

for (const [nome, campo, letra] of FIXAS) {
  const valor = familias[nome]?.[campo];
  if (valor !== letra) erros.push(`${nome}: ${campo} deveria ser "${letra}", esta ${JSON.stringify(valor)}`);
}

// Tabela
const cab = ['Familia', 'Leveling', 'PvP', 'Expl. L', 'Expl. P', 'Notas'];
const linhas = FAMILIAS.filter((n) => n in familias).map((n) => {
  const e = familias[n];
  return [
    n,
    String(e.leveling ?? '?'),
    String(e.pvp ?? '?'),
    String(e.explicita?.leveling ?? '?'),
    String(e.explicita?.pvp ?? '?'),
    String(e.notas?.length ?? 0),
  ];
});
const larguras = cab.map((c, i) => Math.max(c.length, ...linhas.map((l) => l[i].length)));
const fmt = (l) => l.map((c, i) => c.padEnd(larguras[i])).join('  ');
console.log(fmt(cab));
console.log(larguras.map((w) => '-'.repeat(w)).join('  '));
linhas.forEach((l) => console.log(fmt(l)));
console.log('');

if (erros.length) {
  console.log(`FALHOU (${erros.length} problema(s)):`);
  for (const e of erros) console.log(`  - ${e}`);
  process.exit(1);
}
console.log(`OK: ${FAMILIAS.length} familias, notas S/A/B/C/D, texto ASCII ate 160 caracteres, letras fixas conferidas.`);
process.exit(0);
