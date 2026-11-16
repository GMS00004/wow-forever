// pstar.mjs - confere W1, P* (design 7.2) e W (R9 4.1) por Monte Carlo e casos-limite.
function rng(seed) { let s = seed >>> 0; return () => { s = (s + 0x6D2B79F5) >>> 0; let t = s; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
const R = rng(12345);
const pstar = (p, v, c, du, rs, rx) => (1 - rx) * du / (p * (1 - c) - v + (rs - rx) * du);
const W1 = (P, p, v, c, du, rs, rx) => P * (p * (1 - c) - (1 - rs) * du) + (1 - P) * (v - (1 - rx) * du);
const Wrep = (P, p, c, du, rs, rx) => p * (1 - c) - (1 - rs) * du - ((1 - P) / P) * (1 - rx) * du;

// Monte Carlo: caixa liquido final de 1 unidade, partindo de 0 (o item nao tem custo).
function mcOnce(P, p, v, c, du, rs, rx, N) { // posta 1 vez; se expira, vende ao NPC
  let s = 0; for (let i = 0; i < N; i++) { let cash = -du; if (R() < P) cash += p * (1 - c) + rs * du; else cash += rx * du + v; s += cash; } return s / N;
}
function mcRepost(P, p, v, c, du, rs, rx, N, K) { // reposta ate vender, no maximo K ciclos, depois NPC
  let s = 0; for (let i = 0; i < N; i++) { let cash = 0, sold = false; for (let k = 0; k < K && !sold; k++) { cash -= du; if (R() < P) { cash += p * (1 - c) + rs * du; sold = true; } else cash += rx * du; } if (!sold) cash += v; s += cash; } return s / N;
}
console.log('== 1. Exemplo da secao 3.1 (v=50, p=200, c=0.05, rs=1, rx=0)');
for (const du of [100, 30]) {
  const ps = pstar(200, 50, 0.05, du, 1, 0);
  console.log(`du=${du}: P* = ${(100 * ps).toFixed(2)}%`);
  for (const dP of [-0.10, -0.03, 0, 0.03, 0.10]) {
    const P = ps + dP;
    const a = mcOnce(P, 200, 50, 0.05, du, 1, 0, 400000);
    const b = mcRepost(P, 200, 50, 0.05, du, 1, 0, 400000, 200);
    console.log(`  P=${P.toFixed(3)}  1 tentativa - v = ${(a - 50).toFixed(2)} (formula ${(W1(P, 200, 50, 0.05, du, 1, 0) - 50).toFixed(2)})   repostar - v = ${(b - 50).toFixed(2)} (formula ${(Wrep(P, 200, 0.05, du, 1, 0) - 50).toFixed(2)})`);
  }
}
console.log('\n== 2. Telas 11.3');
console.log('Bandit Cloak v=50 d=30 p=200: needs', (100 * pstar(200, 50, 0.05, 30, 1, 0)).toFixed(1) + '%');
console.log('Copper Ore x20 v=5 d=20 (du=1) p=108: needs', (100 * pstar(108, 5, 0.05, 1, 1, 0)).toFixed(2) + '%');
console.log('Ring: 5/20/60% de 45c =', [0.05, 0.2, 0.6].map(f => (f * 45).toFixed(2)).join(' / '));
console.log('Linen x14 a 9c, v=13: pay', 14 * 9, 'cap', 14 * 12, 'exit', 14 * 13, 'EV', 14 * 4, '% de 4g', (100 * 126 / 40000).toFixed(3), 'EV/3 teclas', (56 / 3).toFixed(1), 'lucro no teto', 182 - 168, 'por tecla', ((182 - 168) / 3).toFixed(1));
console.log('Session: por acao', (1075 / 49).toFixed(2), 'por hora', (1075 / (92 / 60)).toFixed(1));
console.log('Mail: bruto se liquido 1420 e corte 5%:', (1420 / 0.95).toFixed(1), 'corte', (1420 / 0.95 * 0.05).toFixed(1));

console.log('\n== 3. Casos-limite de P*');
const casos = [
  ['p no piso v/(1-c), rs=1, rx=0', 50 / 0.95, 50, 0.05, 30, 1, 0],
  ['p no piso, rs=0, rx=0 (deposito nunca volta)', 50 / 0.95, 50, 0.05, 30, 0, 0],
  ['p=60, rs=0, rx=0', 60, 50, 0.05, 30, 0, 0],
  ['p=200, rs=0, rx=0', 200, 50, 0.05, 30, 0, 0],
  ['p=200, rs=1, rx=1 (volta sempre)', 200, 50, 0.05, 30, 1, 1],
  ['deposito zero', 200, 50, 0.05, 0, 1, 0],
  ['v=0 e deposito 1c', 200, 0, 0.05, 1, 1, 0],
  ['p abaixo do piso (p=40)', 40, 50, 0.05, 30, 1, 0],
  ['v maior que p (v=300,p=200)', 200, 300, 0.05, 180, 1, 0],
];
for (const [n, p, v, c, du, rs, rx] of casos) console.log(`  ${n}: denominador=${(p * (1 - c) - v + (rs - rx) * du).toFixed(2)}  P*=${pstar(p, v, c, du, rs, rx)}`);

console.log('\n== 4. Heterogeneidade de P (P por item ~ Beta, media Pm): 1 tentativa e linear; repostar nao');
function betaSample(a, b) { // via gamas (Marsaglia-Tsang simplificado para a,b>=1)
  const g = (k) => { const d = k - 1 / 3, cc = 1 / Math.sqrt(9 * d); for (;;) { let x, vv; do { x = Math.sqrt(-2 * Math.log(1 - R())) * Math.cos(2 * Math.PI * R()); vv = 1 + cc * x; } while (vv <= 0); vv = vv * vv * vv; const u = R(); if (Math.log(u) < 0.5 * x * x + d - d * vv + d * Math.log(vv)) return d * vv; } };
  const x = g(a), y = g(b); return x / (x + y);
}
for (const [a, b] of [[2, 3], [1, 1.5], [1, 4]]) {
  const Pm = a / (a + b); let s1 = 0, s2 = 0; const N = 300000, du = 30;
  for (let i = 0; i < N; i++) { const P = betaSample(a, b); s1 += W1(P, 200, 50, 0.05, du, 1, 0); let cash = 0, sold = false; for (let k = 0; k < 500 && !sold; k++) { cash -= du; if (R() < P) { cash += 190 + du; sold = true; } } s2 += cash; }
  console.log(`  Beta(${a},${b}) Pm=${Pm.toFixed(2)}: 1 tentativa MC=${(s1 / N).toFixed(1)} formula(Pm)=${W1(Pm, 200, 50, 0.05, du, 1, 0).toFixed(1)} | repostar ate vender MC=${(s2 / N).toFixed(1)} formula W(Pm)=${Wrep(Pm, 200, 0.05, du, 1, 0).toFixed(1)}`);
}

console.log('\n== 5. Veredito AUCTION com 10 desfechos: P(frequencia > P*) dado o P verdadeiro');
const binomTail = (n, p, kmin) => { let s = 0; for (let k = kmin; k <= n; k++) { let cmb = 1; for (let i = 0; i < k; i++) cmb = cmb * (n - i) / (i + 1); s += cmb * p ** k * (1 - p) ** (n - k); } return s; };
for (const [ps, n] of [[0.176, 10], [0.417, 10], [0.176, 30], [0.417, 30]]) {
  const kmin = Math.floor(ps * n) + 1;
  const linha = [0.5 * ps, 0.75 * ps, ps, 1.25 * ps, 1.5 * ps].map(P => `P=${P.toFixed(3)}:${binomTail(n, P, kmin).toFixed(3)}`).join('  ');
  console.log(`  P*=${ps} n=${n} (precisa de ${kmin} vendas): ${linha}`);
}
// intervalo de Wilson para 4 de 10
const wilson = (k, n, z) => { const ph = k / n, den = 1 + z * z / n, cen = ph + z * z / (2 * n), rad = z * Math.sqrt(ph * (1 - ph) / n + z * z / (4 * n * n)); return [(cen - rad) / den, (cen + rad) / den]; };
console.log('  Wilson 80% para 4 de 10:', wilson(4, 10, 1.2816).map(x => x.toFixed(3)).join(' a '), ' 95%:', wilson(4, 10, 1.96).map(x => x.toFixed(3)).join(' a '));
console.log('  Wilson 80% para 2 de 10:', wilson(2, 10, 1.2816).map(x => x.toFixed(3)).join(' a '));

console.log('\n== 6. Delta_canc (R9 4.6): algebra por diferenca direta');
{
  let maxErr = 0;
  for (let i = 0; i < 100000; i++) {
    const P = R(), p = 50 + 500 * R(), c = 0.1 * R(), du = 100 * R(), rs = R(), rx = R(), rc = R(), W = 600 * R(), h = R(), Tm = 24 * R(), k = 50 * R();
    const fica = P * (p * (1 - c) + rs * du) + (1 - P) * (W + rx * du) - h * Tm;
    const canc = rc * du - k + W;
    const d = P * (W - p * (1 - c)) + du * (rc - rs * P - rx * (1 - P)) + h * Tm - k;
    maxErr = Math.max(maxErr, Math.abs((canc - fica) - d));
  }
  console.log('  erro maximo |(EV_cancela - EV_fica) - Delta_canc| =', maxErr.toExponential(2));
  // exemplo Tin Ore: h = rho_cap*V
  const V = 176 * 20, rho = 0.002, kappa = 45;
  for (const [P, Tm, Wst, p] of [[0.0, 12, 170 * 20 * 0.95, 176 * 20], [0.05, 12, 170 * 20 * 0.95, 176 * 20], [0.3, 8, 170 * 20 * 0.95, 176 * 20]]) {
    const du = 100; const d = P * (Wst - p * 0.95) + du * (0 - 1 * P - 0) + rho * V * Tm - kappa;
    console.log(`  lote 20 x 176c, P=${P}, Tm=${Tm}h, W*=${Wst.toFixed(0)} rs=1 rc=rx=0, h=0.002*V, kappa=45c: Delta_canc=${d.toFixed(1)}; com h=0: ${(d - rho * V * Tm).toFixed(1)}`);
  }
}
console.log('\n== 7. Limiares de compra: R9 5.1/5.2/5.3 contra design 7.4');
{
  const U = 100, mu = 0.15, eta = 0.5, c = 0.05;
  console.log('  R9 5.2 sem eta: a_max =', (U / (1 + mu)).toFixed(1), '| R9 5.1 com eta na saida: a_max =', (eta * U / (1 + mu)).toFixed(1), '| design 7.4 (eta no ganho): a_max =', (eta * U / (eta + mu)).toFixed(1));
  console.log('  vao: razao minima p_{k+1}/pmedio  R9 5.3 =', ((1 + mu) / (1 - c)).toFixed(3), '| pelo teste 7.4 =', ((1 + mu / eta) / (1 - c)).toFixed(3));
  const a = 85; console.log('  U=100, a=85: 7.4 ->', eta * (U - a), '>=', mu * a, '?', eta * (U - a) >= mu * a);
  console.log('  theta_s do exemplo R9 5.2:', (0.95 * Math.exp(-0.08) * 0.98 / 1.10).toFixed(3), ' com eta=0.5 na saida:', (0.5 * 0.95 * Math.exp(-0.08) * 0.98 / 1.10).toFixed(3), ' pelo 7.4 (mu=0.15):', (0.95 * Math.exp(-0.08) * 0.98 * 0.5 / 0.65).toFixed(3));
}
