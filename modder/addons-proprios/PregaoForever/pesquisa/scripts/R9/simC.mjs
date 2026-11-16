// simC.mjs — tabela adimensional de P(vender ate D) (secao 3 do R9).
// Modelo continuo em unidades de "demanda do horizonte": horizonte = 1, demanda = 1 por horizonte.
//   A    = (q + 0.5) / (lam * D)        fila na frente
//   rho  = nu / lam                     razao de cobertura
//   beta = phiL / (2 * lam * D)         tamanho medio do pedido (exponencial)
//   ell  = phiN / (2 * lam * D)         tamanho medio do lote que entra na frente (exponencial)
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
let R = rng(4242);
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
// 1) confere o mapeamento discreto -> continuo contra os casos discretos do simA2
const geo = (mean) => (mean <= 1 ? 1 : 1 + Math.floor(Math.log(1 - R()) / Math.log(1 - 1 / mean)));
function simDisc(q, lam, bm, nu, lm, D, N) {
  let hit = 0;
  const ro = lam / bm, rp = nu / lm, tot = ro + rp;
  for (let i = 0; i < N; i++) {
    let x = q + 1, t = 0;
    for (;;) {
      t += ex() / tot;
      if (t > D) break;
      if (R() < ro / tot) { x -= geo(bm); if (x <= 0) { hit++; break; } } else x += geo(lm);
    }
  }
  return hit / N;
}
console.log('--- C1: discreto (geometrico) vs continuo com A=(q+0.5)/(lam D), beta=phiL/(2 lam D), ell=phiN/(2 lam D)');
console.log('q lam bm nu lm D | discreto | continuo');
let worst = 0, sum = 0, cnt = 0;
for (const bm of [1, 3, 8]) {
  for (const [nu, lm] of [[0, 1], [5, 1], [5, 6], [9, 6], [12, 6], [20, 10]]) {
    for (const q of [0, 2, 5, 20, 60]) {
      for (const D of [2, 8, 24]) {
        const lam = 10, phiL = 2 * bm - 1, phiN = 2 * lm - 1;
        const pdisc = simDisc(q, lam, bm, nu, lm, D, 20000);
        const pc = nu === 0
          ? simP((q + 0.5) / (lam * D), 0, 1, phiL / (2 * lam * D), 20000)
          : simP((q + 0.5) / (lam * D), nu / lam, phiN / (2 * lam * D), phiL / (2 * lam * D), 20000);
        const e = Math.abs(pdisc - pc);
        sum += e; cnt++;
        if (e > worst) worst = e;
        if (e > 0.03) console.log([q, lam, bm, nu, lm, D].join(' ') + ' | ' + pdisc.toFixed(3) + ' | ' + pc.toFixed(3));
      }
    }
  }
}
console.log('casos=' + cnt + ' erro max=' + worst.toFixed(3) + ' erro medio abs=' + (sum / cnt).toFixed(4));

// 2) tabela na grade e erro de interpolacao
const gA = [0.01, 0.03, 0.06, 0.1, 0.15, 0.22, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.25, 1.5, 2, 3];
const gR = [0, 0.25, 0.5, 0.75, 0.9, 1.0, 1.1, 1.25, 1.5, 2, 3];
const gB = [0.002, 0.01, 0.03, 0.1, 0.3];
const gL = [0.002, 0.01, 0.03, 0.1, 0.3, 1];
const NP = 1500;
const t0 = Date.now();
const T = [];
for (let i = 0; i < gA.length; i++) {
  T.push([]);
  for (let j = 0; j < gR.length; j++) {
    T[i].push([]);
    for (let k = 0; k < gB.length; k++) {
      T[i][j].push([]);
      for (let l = 0; l < gL.length; l++) {
        T[i][j][k].push(gR[j] === 0 ? simP(gA[i], 0, 1, gB[k], NP) : simP(gA[i], gR[j], gL[l], gB[k], NP));
      }
    }
  }
}
console.log('--- C2: tabela ' + gA.length + 'x' + gR.length + 'x' + gB.length + 'x' + gL.length + ' = ' + (gA.length * gR.length * gB.length * gL.length) + ' entradas, ' + NP + ' caminhos por entrada, ' + ((Date.now() - t0) / 1000).toFixed(1) + ' s');
function loc(g, x, logScale) {
  const n = g.length;
  if (x <= g[0]) return [0, 0];
  if (x >= g[n - 1]) return [n - 2, 1];
  let i = 0;
  while (g[i + 1] < x) i++;
  const f = logScale ? Math.log(x / g[i]) / Math.log(g[i + 1] / g[i]) : (x - g[i]) / (g[i + 1] - g[i]);
  return [i, f];
}
function interp(A, rho, beta, ell) {
  const [i, fa] = loc(gA, A, false), [j, fr] = loc(gR, rho, false), [k, fb] = loc(gB, beta, true), [l, fl] = loc(gL, ell, true);
  let v = 0;
  for (let da = 0; da < 2; da++) for (let dr = 0; dr < 2; dr++) for (let db = 0; db < 2; db++) for (let dl = 0; dl < 2; dl++) {
    const w = (da ? fa : 1 - fa) * (dr ? fr : 1 - fr) * (db ? fb : 1 - fb) * (dl ? fl : 1 - fl);
    if (w > 0) v += w * T[i + da][j + dr][k + db][l + dl];
  }
  return v;
}
let wI = 0, sI = 0, nI = 0;
const worstRows = [];
for (let n = 0; n < 250; n++) {
  const A = 0.01 + R() * 1.6, rho = R() * 2.5, beta = Math.exp(Math.log(0.002) + R() * Math.log(0.3 / 0.002)), ell = Math.exp(Math.log(0.002) + R() * Math.log(1 / 0.002));
  const truth = simP(A, rho, ell, beta, 20000);
  const it = interp(A, rho, beta, ell);
  const e = Math.abs(truth - it);
  sI += e; nI++;
  if (e > wI) wI = e;
  if (e > 0.04) worstRows.push([A.toFixed(3), rho.toFixed(2), beta.toFixed(4), ell.toFixed(4), truth.toFixed(3), it.toFixed(3)].join(' '));
}
console.log('interpolacao em 250 pontos fora da grade: erro max=' + wI.toFixed(3) + ' erro medio abs=' + (sI / nI).toFixed(4));
for (const r of worstRows) console.log('  A rho beta ell | verdade | interp: ' + r);
