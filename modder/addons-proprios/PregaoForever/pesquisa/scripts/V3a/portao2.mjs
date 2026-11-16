// portao2.mjs - complementos: (a) quanto cada condicao do portao do design trabalha; (b) numero de grupos; (c) cauda direita (loteria); (d) tetos em cobre.
function rng(seed) { let s = seed >>> 0; return () => { s = (s + 0x6D2B79F5) >>> 0; let t = s; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
const R = rng(77);
const gauss = () => Math.sqrt(-2 * Math.log(1 - R())) * Math.cos(2 * Math.PI * R());
const expo = (m) => -m * Math.log(1 - R());
const pc = (x) => (100 * x).toFixed(1).padStart(5) + '%';
function amostra(n, K, k, sigma, rho) { const zc = []; for (let j = 0; j < K; j++) zc.push(gauss()); const s = []; for (let i = 0; i < n; i++) { const g = i % K, m = Math.min(1, 0.30 + expo(0.10)); s.push({ g, m, r: k * m + sigma * (Math.sqrt(rho) * zc[g] + Math.sqrt(1 - rho) * gauss()) }); } return s; }
const conds = (s) => { const tot = s.reduce((a, x) => a + x.r, 0); const top = s.map(x => x.r).sort((a, b) => b - a); return [tot > 0, tot - top[0] - top[1] - top[2] > 0, tot / s.reduce((a, x) => a + x.m, 0) >= 0.5]; };
const N = 20000;
console.log('== a. Cada condicao sozinha, estrategia sem valor (k = 0), 30 sinais independentes');
console.log('sigma | soma>0 | sem os 3 melhores>0 | razao>=0,5 | as tres | so as duas primeiras');
for (const sigma of [0.2, 0.35, 0.5]) { const c = [0, 0, 0, 0, 0]; for (let i = 0; i < N; i++) { const [a, b, d] = conds(amostra(30, 30, 0, sigma, 0)); if (a) c[0]++; if (b) c[1]++; if (d) c[2]++; if (a && b && d) c[3]++; if (a && b) c[4]++; } console.log(`${sigma} | ${c.map(x => pc(x / N)).join(' | ')}`); }
console.log('\n== b. Numero de grupos item-dia (correlacao 0,5 dentro do grupo), sigma 0,5: P(passar no portao do design)');
console.log('grupos | k=0 (sem valor) | k=1 (vale o previsto)');
for (const K of [2, 3, 5, 6, 8, 10, 15, 30]) { let a = 0, b = 0; for (let i = 0; i < N; i++) { const [x, y, z] = conds(amostra(30, K, 0, 0.5, 0.5)); if (x && y && z) a++; const [p, q, w] = conds(amostra(30, K, 1, 0.5, 0.5)); if (p && q && w) b++; } console.log(`${String(K).padStart(2)} | ${pc(a / N)} | ${pc(b / N)}`); }
console.log('\n== c. Cauda direita (loteria): cada sinal perde 5% do custo, e com prob. q ganha +400%. Media = -0,05 + 4,05q. Previsto 0,40.');
console.log('q | media | soma>0 e razao>=0,5 (sem a regra dos 3 melhores) | portao completo');
for (const q of [0.005, 0.0123, 0.03, 0.06, 0.10]) { let a = 0, b = 0; for (let i = 0; i < N; i++) { const s = []; for (let j = 0; j < 30; j++) s.push({ m: 0.4, r: R() < q ? 4.0 : -0.05 }); const [x, y, z] = conds(s); if (x && z) a++; if (x && y && z) b++; } console.log(`${q} | ${(-0.05 + 4.05 * q).toFixed(3)} | ${pc(a / N)} | ${pc(b / N)}`); }
console.log('\n== d. Tetos da secao 9.2 em cobre');
for (const B of [40000, 20000, 10000, 3000]) {
  const t = { conf: 0.02 * B, ordem: 0.05 * B, ordemDuro: 0.10 * B, item: 0.10 * B, itemDuro: 0.20 * B, estoque: 0.5 * B, depRisco: 0.05 * B, depDia: 0.02 * B, perdaDia: 0.05 * B, perdaItem: 0.01 * B, semExpl: 0.01 * B };
  console.log(`B = ${B} c: confirmacao ${t.conf} | ordem ${t.ordem} (duro ${t.ordemDuro}) | item ${t.item} (duro ${t.itemDuro}) | estoque ${t.estoque} | deposito em risco ${t.depRisco} | deposito perdido/dia ${t.depDia} | perda do dia ${t.perdaDia} | perda por item ${t.perdaItem} | sem explicacao ${t.semExpl}`);
  console.log('   v do item | deposito 24 h (60% de v; base 1.4) | simultaneos no teto de risco | expiracoes/dia no teto de perdido | 1 expiracao passa de 1% (bloqueia o item)? | ate 17/11 (minimo 1 prata): simultaneos, expiracoes/dia');
  for (const v of [50, 200, 500, 1000, 2000]) { const d = Math.max(1, Math.floor(0.6 * v)); const dOld = Math.max(100, d); console.log(`   ${String(v).padStart(4)} c | ${String(d).padStart(4)} c | ${Math.floor(t.depRisco / d)} | ${Math.floor(t.depDia / d)} | ${d > t.perdaItem ? 'sim' : 'nao'} | ${Math.floor(t.depRisco / dOld)}, ${Math.floor(t.depDia / dOld)}`); }
}
console.log('\n== e. Calibracao da frequencia de venda com o teto de deposito perdido: 10 desfechos por classe e duracao');
for (const [v, P] of [[500, 0.4], [1000, 0.4], [500, 0.2]]) { const d = 0.6 * v; const porDia = Math.floor(800 / d); console.log(`   verde de v=${v} c, 24 h, deposito ${d} c, P(venda)=${P}: o teto de 800 c/dia deixa ${porDia} expiracoes por dia -> cerca de ${(porDia / (1 - P)).toFixed(1)} postagens por dia -> ${Math.ceil(10 / (porDia / (1 - P)))} dias para 10 desfechos (B = 4 ouro)`); }
console.log('\n== f. Resumo (secao 0): giro da banca');
console.log('   5,09 ouro a 10% e 15%:', (0.10 * 50912 / 100).toFixed(0), 'e', (0.15 * 50912 / 100).toFixed(0), 'prata | banca de 4 ouro com teto de estoque de 50%:', 0.10 * 20000 / 100, 'e', 0.15 * 20000 / 100, 'prata por giro');
