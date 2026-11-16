// simA2.mjs — primeira passagem com demanda e cobertura em lotes (secao 3 do R9).
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
const R = rng(777);
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
function pIG(a, m, s2, D) {
  const s = Math.sqrt(s2 * D);
  const z1 = (m * D - a) / s;
  const z2 = (a + m * D) / s;
  const e = 2 * m * a / s2;
  let t2;
  if (z2 > 0) t2 = Math.exp(e + lnPhiNeg(z2));
  else t2 = Math.exp(e) * Phi(-z2);
  return Math.min(1, Phi(z1) + t2);
}
const geo = (mean) => (mean <= 1 ? 1 : 1 + Math.floor(Math.log(1 - R()) / Math.log(1 - 1 / mean)));
function sim(q, lam, bm, nu, lm, D, N) {
  let hit = 0;
  const ro = lam / bm, rp = nu / lm, tot = ro + rp;
  for (let i = 0; i < N; i++) {
    let x = q + 1, t = 0;
    for (;;) {
      t += -Math.log(1 - R()) / tot;
      if (t > D) break;
      if (R() < ro / tot) { x -= geo(bm); if (x <= 0) { hit++; break; } } else x += geo(lm);
    }
  }
  return hit / N;
}
const N = 30000;
let maxErr0 = 0, maxErr1 = 0, sumAbs0 = 0, sumAbs1 = 0, n = 0;
console.log('q lam bm nu lm D | sim | C0: a=q+1 | C1: a=q+1+(phiL-1)/2');
for (const bm of [1, 3, 8]) {
  for (const [nu, lm] of [[0, 1], [5, 1], [5, 6], [9, 6], [12, 6], [20, 10]]) {
    for (const q of [0, 5, 20, 60]) {
      for (const D of [2, 8, 24]) {
        const lam = 10;
        const phiL = 2 * bm - 1, phiN = 2 * lm - 1;
        const s2 = lam * phiL + nu * phiN;
        const p = sim(q, lam, bm, nu, lm, D, N);
        const c0 = pIG(q + 1, lam - nu, s2, D);
        const c1 = pIG(q + 1 + (phiL - 1) / 2, lam - nu, s2, D);
        maxErr0 = Math.max(maxErr0, Math.abs(c0 - p));
        maxErr1 = Math.max(maxErr1, Math.abs(c1 - p));
        sumAbs0 += Math.abs(c0 - p); sumAbs1 += Math.abs(c1 - p); n++;
        if (Math.abs(c1 - p) > 0.03 || (q === 20 && D === 8)) {
          console.log([q, lam, bm, nu, lm, D].join(' ') + ' | ' + p.toFixed(3) + ' | ' + c0.toFixed(3) + ' | ' + c1.toFixed(3));
        }
      }
    }
  }
}
console.log('casos=' + n + ' erro max C0=' + maxErr0.toFixed(3) + ' C1=' + maxErr1.toFixed(3) + ' erro medio abs C0=' + (sumAbs0 / n).toFixed(4) + ' C1=' + (sumAbs1 / n).toFixed(4));
