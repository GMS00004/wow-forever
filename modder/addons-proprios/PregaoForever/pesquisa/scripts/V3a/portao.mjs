// portao.mjs - portao de evidencia do design 3.3 (papel -> micro): 30 sinais fechados, soma > 0,
// soma sem os 3 melhores > 0, realizado/previsto >= 0,5. Probabilidade de passar por tipo de estrategia.
// Unidade: fracao do custo do sinal. m = ganho previsto (>= 0,30, porque o teste 7.4 exige margem mu/eta = 0,15/0,5).
function rng(seed) { let s = seed >>> 0; return () => { s = (s + 0x6D2B79F5) >>> 0; let t = s; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
const R = rng(2026);
const gauss = () => Math.sqrt(-2 * Math.log(1 - R())) * Math.cos(2 * Math.PI * R());
const expo = (m) => -m * Math.log(1 - R());
const T90 = { 2: 3.078, 3: 1.886, 4: 1.638, 5: 1.533, 6: 1.476, 7: 1.44, 8: 1.415, 9: 1.397, 10: 1.383, 12: 1.363, 15: 1.345, 30: 1.311 };
const t90 = (k) => T90[k] || 1.31;

// gera n sinais em K grupos (item-dia) com correlacao rho dentro do grupo
function amostra(n, K, k, sigma, rho, tipo) {
  const zc = []; for (let j = 0; j < K; j++) zc.push(gauss());
  const s = [];
  for (let i = 0; i < n; i++) {
    const g = i % K; const m = Math.min(1.0, 0.30 + expo(0.10)); const custo = Math.exp(0.5 * gauss());
    let r;
    if (tipo === 'normal') r = k * m + sigma * (Math.sqrt(rho) * zc[g] + Math.sqrt(1 - rho) * gauss());
    else { // 'cauda': ganha quase sempre o previsto, perde muito de vez em quando (encalhe); k aqui e a prob. de encalhe
      const encalha = R() < k || (rho > 0 && zc[g] < -1.6 && R() < 0.8);
      r = encalha ? -0.7 : m * (0.8 + 0.1 * gauss());
    }
    s.push({ g, m, r, custo });
  }
  return s;
}
const soma = (a, f) => a.reduce((x, y) => x + f(y), 0);
// G0: o portao do design
function G0(s) {
  const tot = soma(s, x => x.r * x.custo); if (!(tot > 0)) return false;
  const top = s.map(x => x.r * x.custo).sort((a, b) => b - a); if (!(tot - top[0] - top[1] - top[2] > 0)) return false;
  return tot / soma(s, x => x.m * x.custo) >= 0.5;
}
// G1: proposto. Por grupo (item-dia): soma > 0 sem o melhor grupo; razao de somas >= 0,5; limite inferior de 90% da media dos retornos por grupo > 0
function G1(s, K) {
  const tot = soma(s, x => x.r * x.custo);
  const gs = []; for (let j = 0; j < K; j++) gs.push({ r: 0, c: 0 });
  for (const x of s) { gs[x.g].r += x.r * x.custo; gs[x.g].c += x.custo; }
  const best = Math.max(...gs.map(g => g.r)); if (!(tot - best > 0)) return false;
  if (!(tot / soma(s, x => x.m * x.custo) >= 0.5)) return false;
  const ret = gs.filter(g => g.c > 0).map(g => g.r / g.c); const k = ret.length; const mu = ret.reduce((a, b) => a + b, 0) / k;
  const sd = Math.sqrt(ret.reduce((a, b) => a + (b - mu) ** 2, 0) / (k - 1));
  return mu - t90(k - 1) * sd / Math.sqrt(k) > 0;
}
// G1b: so a troca "sem os 3 melhores" -> limite inferior de 90% por sinal (ignora grupos)
function G1b(s) {
  const tot = soma(s, x => x.r * x.custo); if (!(tot / soma(s, x => x.m * x.custo) >= 0.5)) return false;
  const n = s.length, mu = soma(s, x => x.r) / n, sd = Math.sqrt(soma(s, x => (x.r - mu) ** 2) / (n - 1));
  return mu - 1.311 * sd / Math.sqrt(n) > 0;
}
const N = 20000;
function taxa(n, K, k, sigma, rho, tipo) { let a = 0, b = 0, c = 0; for (let i = 0; i < N; i++) { const s = amostra(n, K, k, sigma, rho, tipo); if (G0(s)) a++; if (G1(s, K)) b++; if (G1b(s)) c++; } return [a / N, b / N, c / N]; }
const pc = (x) => (100 * x).toFixed(1).padStart(5) + '%';
console.log('== 1. Resultado por sinal normal: realizado = k*previsto + sigma*ruido. 30 sinais. P(passar)');
console.log('k = 0: sem valor | k = -0.25: perde | k = 0.25: vale um quarto do previsto | k = 0.5: vale o que o design supoe (eta_real 0,5) | k = 1: vale o previsto');
for (const [rho, K, rot] of [[0, 30, 'sinais independentes'], [0.5, 6, '6 grupos item-dia de 5 sinais, correlacao 0,5 dentro do grupo'], [0.5, 3, '3 grupos de 10 sinais, correlacao 0,5']]) {
  console.log(`-- ${rot}`);
  console.log('sigma |    k | G0 design | G1 por grupo | G1b limite inferior por sinal');
  for (const sigma of [0.10, 0.20, 0.35, 0.50]) for (const k of [-0.25, 0, 0.25, 0.5, 1.0]) {
    const [a, b, c] = taxa(30, K, k, sigma, rho, 'normal');
    console.log(`${sigma.toFixed(2)}  | ${k.toFixed(2).padStart(5)} | ${pc(a)} | ${pc(b)} | ${pc(c)}`);
  }
}
console.log('\n== 2. Cauda esquerda: ganha 80% do previsto quase sempre, perde 70% do custo quando encalha (prob. q). Media por sinal ~ 0,8*0,40*(1-q) - 0,7*q');
console.log('q | media por sinal | G0 design | G1 por grupo (6 grupos) | G1b');
for (const q of [0.05, 0.10, 0.20, 0.31, 0.40]) { const [a, b, c] = taxa(30, 6, q, 0, 0, 'cauda'); console.log(`${q.toFixed(2)} | ${(0.8 * 0.40 * (1 - q) - 0.7 * q).toFixed(3)} | ${pc(a)} | ${pc(b)} | ${pc(c)}`); }
console.log('\n== 3. Sobrevivencia: o portao so conta sinal FECHADO. Estrategia: 60% dos lotes vendem em 1 a 2 dias com 80% do previsto; 40% encalham e acabam em -50%.');
console.log('   Media verdadeira por sinal = 0,6*0,32 - 0,4*0,5 = -0,008. Os 30 primeiros FECHADOS em 5 dias sao so os que venderam.');
{
  let a = 0, b = 0; const M = 20000;
  for (let i = 0; i < M; i++) {
    const fech = [], todos = [];
    while (fech.length < 30) { const m = Math.min(1.0, 0.30 + expo(0.10)); const custo = Math.exp(0.5 * gauss()); const vende = R() < 0.6; const x = { g: todos.length % 6, m, custo, r: vende ? 0.8 * m : -0.5 }; todos.push(x); if (vende) fech.push(x); }
    if (G0(fech)) a++; if (G0(todos)) b++;
  }
  console.log(`   G0 so com fechados: passa ${pc(a / M)} | G0 com todos os sinais abertos ha mais de 48 h, encalhados marcados a saida conservadora: passa ${pc(b / M)}`);
}
console.log('\n== 4. O limiar 0,5 da razao contra o eta_real = 0,5 de partida: estrategia que entrega exatamente o que o teste 7.4 supoe (k = 0,5)');
for (const sigma of [0.10, 0.20, 0.35]) { const [a] = taxa(30, 30, 0.5, sigma, 0, 'normal'); const [a2] = taxa(30, 30, 0.65, sigma, 0, 'normal'); console.log(`   sigma ${sigma}: k=0,5 passa ${pc(a)} ; k=0,65 passa ${pc(a2)}`); }
console.log('\n== 5. Variante do portao sem esperar mais: razao minima 0,3 (em vez de 0,5) com G1 por grupo');
function G1r(s, K, rmin) { const tot = soma(s, x => x.r * x.custo); if (!(tot / soma(s, x => x.m * x.custo) >= rmin)) return false; const gs = []; for (let j = 0; j < K; j++) gs.push({ r: 0, c: 0 }); for (const x of s) { gs[x.g].r += x.r * x.custo; gs[x.g].c += x.custo; } const best = Math.max(...gs.map(g => g.r)); if (!(tot - best > 0)) return false; const ret = gs.map(g => g.r / g.c); const k = ret.length; const mu = ret.reduce((a, b) => a + b, 0) / k; const sd = Math.sqrt(ret.reduce((a, b) => a + (b - mu) ** 2, 0) / (k - 1)); return mu - t90(k - 1) * sd / Math.sqrt(k) > 0; }
console.log('sigma |    k | rho=0,5 em 6 grupos: G0 design | G1 razao 0,5 | G1 razao 0,3 | 8 grupos: G1 razao 0,3');
for (const sigma of [0.20, 0.35, 0.50]) for (const k of [0, 0.25, 0.5, 1.0]) {
  let a = 0, b = 0, c = 0, d = 0; for (let i = 0; i < N; i++) { const s = amostra(30, 6, k, sigma, 0.5, 'normal'); if (G0(s)) a++; if (G1r(s, 6, 0.5)) b++; if (G1r(s, 6, 0.3)) c++; const s8 = amostra(32, 8, k, sigma, 0.5, 'normal'); if (G1r(s8, 8, 0.3)) d++; }
  console.log(`${sigma.toFixed(2)}  | ${k.toFixed(2).padStart(5)} | ${pc(a / N)} | ${pc(b / N)} | ${pc(c / N)} | ${pc(d / N)}`);
}
