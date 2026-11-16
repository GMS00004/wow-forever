// simA.mjs — confere a formula de primeira passagem (secao 3 do R9) contra simulacao.
// Fila nascimento-morte: q unidades na frente + a nossa; demanda lam (un/h) tira da frente;
// concorrentes entram na frente a nu (un/h). T = instante em que a nossa unidade vende.
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
const R = rng(20261116);

function erf(x) { // Abramowitz-Stegun 7.1.26
  const sg = x < 0 ? -1 : 1;
  x = Math.abs(x);
  const t = 1 / (1 + 0.3275911 * x);
  const y = 1 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * Math.exp(-x * x);
  return sg * y;
}
const Phi = (z) => 0.5 * (1 + erf(z / Math.SQRT2));
function lnPhiNeg(z) { // ln Phi(-z), z > 0, estavel na cauda
  if (z < 5) return Math.log(Math.max(Phi(-z), 1e-300));
  return -0.5 * z * z - Math.log(z) - 0.9189385332 - 1 / (z * z);
}
// P(T <= D) para movimento browniano com deriva m e variancia s2 por hora, barreira a
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
function pErlang(k, lamD) { // P(Poisson(lamD) >= k)
  let term = Math.exp(-lamD), acc = term;
  for (let j = 1; j < k; j++) { term *= lamD / j; acc += term; }
  return 1 - acc;
}
function simBD(q, lam, nu, D, N) {
  let hit = 0;
  const tot = lam + nu;
  for (let i = 0; i < N; i++) {
    let x = q + 1, t = 0;
    for (;;) {
      t += -Math.log(1 - R()) / tot;
      if (t > D) break;
      if (R() < lam / tot) { x--; if (x === 0) { hit++; break; } } else x++;
    }
  }
  return hit / N;
}
// demanda em lotes (Poisson composto): pedidos a taxa lam/bm, tamanho geometrico de media bm
function simBatch(q, lam, bm, D, N) {
  let hit = 0;
  const mu = lam / bm;
  for (let i = 0; i < N; i++) {
    let x = q + 1, t = 0;
    for (;;) {
      t += -Math.log(1 - R()) / mu;
      if (t > D) break;
      const b = 1 + Math.floor(Math.log(1 - R()) / Math.log(1 - 1 / bm));
      x -= b;
      if (x <= 0) { hit++; break; }
    }
  }
  return hit / N;
}
const N = 40000;
console.log('--- A1: nascimento-morte (unidades soltas). colunas: q lam nu D | sim | IG(a=q+1) | IG(a=q+0.5) | Erlang(nu=0)');
for (const lam of [10]) {
  for (const nu of [0, 5, 9, 10, 12, 20]) {
    for (const q of [0, 5, 20, 60]) {
      for (const D of [2, 8, 24]) {
        const sim = simBD(q, lam, nu, D, N);
        const a1 = pIG(q + 1, lam - nu, lam + nu, D);
        const a2 = pIG(q + 0.5, lam - nu, lam + nu, D);
        const ex = nu === 0 ? pErlang(q + 1, lam * D).toFixed(3) : '-';
        console.log([q, lam, nu, D].join(' ') + ' | ' + sim.toFixed(3) + ' | ' + a1.toFixed(3) + ' | ' + a2.toFixed(3) + ' | ' + ex);
      }
    }
  }
}
console.log('--- A2: P(T<inf) com nu > lam: sim (D=2000h) vs (lam/nu)^(q+1) vs exp(2ma/s2)');
for (const [lam, nu] of [[10, 12], [10, 20]]) {
  for (const q of [0, 5, 20]) {
    const sim = simBD(q, lam, nu, 400, 4000);
    const ex = Math.pow(lam / nu, q + 1);
    const df = Math.exp(2 * (lam - nu) * (q + 1) / (lam + nu));
    console.log([q, lam, nu].join(' ') + ' | ' + sim.toFixed(4) + ' | ' + ex.toFixed(4) + ' | ' + df.toFixed(4));
  }
}
console.log('--- A3: demanda em lotes (media bm, geometrica; phi = E[B^2]/E[B] = 2bm-1). q lam bm D | sim | IG(s2=lam*phi, a=q+1) | IG(a=q+1+(phi-1)/2) | Poisson simples');
for (const bm of [3, 8]) {
  const lam = 10, phi = 2 * bm - 1;
  for (const q of [0, 5, 20, 60]) {
    for (const D of [2, 8]) {
      const sim = simBatch(q, lam, bm, D, N);
      const a1 = pIG(q + 1, lam, lam * phi, D);
      const a2 = pIG(Math.max(0.5, q + 1 - (phi - 1) / 2), lam, lam * phi, D);
      const po = pErlang(q + 1, lam * D);
      console.log([q, lam, bm, D].join(' ') + ' | ' + sim.toFixed(3) + ' | ' + a1.toFixed(3) + ' | ' + a2.toFixed(3) + ' | ' + po.toFixed(3));
    }
  }
}
console.log('--- A4: concorrente reativo. tempo na frente ~ Exp(media tauR h). q lam tauR | sim | (lam*tauR/(1+lam*tauR))^(q+1)');
for (const tauR of [1 / 12, 0.25, 1]) {
  for (const lam of [2, 10]) {
    for (const q of [0, 3]) {
      let hit = 0;
      const M = 100000;
      for (let i = 0; i < M; i++) {
        const tf = -Math.log(1 - R()) * tauR;
        let t = 0, k = 0;
        while (k < q + 1) { t += -Math.log(1 - R()) / lam; if (t > tf) break; k++; }
        if (k === q + 1) hit++;
      }
      const f = Math.pow(lam * tauR / (1 + lam * tauR), q + 1);
      console.log([q, lam, tauR.toFixed(3)].join(' ') + ' | ' + (hit / M).toFixed(4) + ' | ' + f.toFixed(4));
    }
  }
}
