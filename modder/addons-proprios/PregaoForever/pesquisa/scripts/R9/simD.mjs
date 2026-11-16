// simD.mjs — erro da formula fechada de reserva (secao 3.4 do R9) contra o modelo exato simulado.
// Unidades: horizonte = 1 e demanda = 1 por horizonte (A, rho, beta, ell como no simC).
function rng(seed) {
  let s = seed >>> 0;
  return () => {
    s = (s + 0x6D2B79F5) >>> 0;
    let t = s;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const R = rng(31337);
const ex = () => -Math.log(1 - R());
function simP(A, rho, ell, beta, N) {
  let hit = 0;
  const ro = 1 / beta, rp = rho / ell, tot = ro + rp, pd = ro / tot;
  for (let i = 0; i < N; i++) {
    let x = A, t = 0;
    for (;;) {
      t += ex() / tot;
      if (t > 1) break;
      if (R() < pd) { x -= ex() * beta; if (x <= 0) { hit++; break; } } else x += ex() * ell;
    }
  }
  return hit / N;
}
function erf(x) {
  const sg = x < 0 ? -1 : 1;
  x = Math.abs(x);
  const t = 1 / (1 + 0.3275911 * x);
  const y = 1 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * Math.exp(-x * x);
  return sg * y;
}
const Phi = (z) => 0.5 * (1 + erf(z / Math.SQRT2));
function lnPhiNeg(z) {
  if (z < 5) return Math.log(Math.max(Phi(-z), 1e-300));
  return -0.5 * z * z - Math.log(z) - 0.9189385332 - 1 / (z * z);
}
function pIG(a, m, s2) { // horizonte 1
  const s = Math.sqrt(s2);
  const z1 = (m - a) / s, z2 = (a + m) / s, e = 2 * m * a / s2;
  const t2 = z2 > 0 ? Math.exp(e + lnPhiNeg(z2)) : Math.exp(e) * Phi(-z2);
  return Math.min(1, Phi(z1) + t2);
}
// demanda sozinha: N(1) ~ Poisson composto, media 1, variancia 2*beta -> gama (Wilson-Hilferty)
function pDem(A, beta) {
  const k = 1 / (2 * beta); // forma
  const x = A / (2 * beta); // limiar em unidades da escala
  const z = (Math.cbrt(x / k) - (1 - 1 / (9 * k))) / Math.sqrt(1 / (9 * k));
  return 1 - Phi(z);
}
function fallback(A, rho, beta, ell) {
  const s2 = 2 * (beta + rho * ell);
  let p = pIG(A + beta, 1 - rho, s2);
  p = Math.min(p, pDem(A, beta));
  if (rho > 1) {
    const eta = (rho - 1) / (ell + rho * beta);
    p = Math.min(p, (1 - eta * beta) * Math.exp(-eta * A));
  }
  return p;
}
// variante: mistura "nenhum lote chega antes" + "chega pelo menos um"
function fallback2(A, rho, beta, ell) {
  const base = fallback(A, rho, beta, ell);
  if (rho === 0) return base;
  const pi0 = Math.exp(-(rho / ell) * Math.min(A, 1)); // nenhum lote durante o consumo da fila
  const hi = pDem(A, beta);
  const withLot = Math.min(base, pDem(A + ell, beta));
  return pi0 * hi + (1 - pi0) * withLot;
}
const stats = {};
const add = (k, e) => { const s = stats[k] || (stats[k] = { n: 0, sum: 0, max: 0 }); s.n++; s.sum += e; if (e > s.max) s.max = e; };
const rows = [];
for (let n = 0; n < 600; n++) {
  const A = 0.01 + R() * 1.6, rho = R() * 2.5, beta = Math.exp(Math.log(0.002) + R() * Math.log(0.3 / 0.002)), ell = Math.exp(Math.log(0.002) + R() * Math.log(1 / 0.002));
  const truth = simP(A, rho, ell, beta, 8000);
  const f1 = fallback(A, rho, beta, ell), f2 = fallback2(A, rho, beta, ell);
  const lumpy = ell > 0.25 * A ? 'lotes grandes (ell > A/4)' : 'fluxo granular (ell <= A/4)';
  const reg = rho < 0.8 ? 'rho<0.8' : (rho <= 1.2 ? '0.8<=rho<=1.2' : 'rho>1.2');
  add('F1 | ' + lumpy + ' | ' + reg, Math.abs(f1 - truth));
  add('F2 | ' + lumpy + ' | ' + reg, Math.abs(f2 - truth));
  add('F1 | tudo', Math.abs(f1 - truth));
  add('F2 | tudo', Math.abs(f2 - truth));
  if (Math.abs(f2 - truth) > 0.15) rows.push([A.toFixed(3), rho.toFixed(2), beta.toFixed(4), ell.toFixed(4), truth.toFixed(3), f1.toFixed(3), f2.toFixed(3)].join(' '));
}
for (const k of Object.keys(stats).sort()) console.log(k + ' | n=' + stats[k].n + ' | erro medio abs=' + (stats[k].sum / stats[k].n).toFixed(3) + ' | erro max=' + stats[k].max.toFixed(3));
console.log('piores (A rho beta ell | verdade | F1 | F2):');
for (const r of rows.slice(0, 15)) console.log('  ' + r);
