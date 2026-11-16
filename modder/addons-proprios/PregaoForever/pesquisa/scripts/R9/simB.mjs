// simB.mjs — inferencia de vendas pela diferenca de escadas (secao 2 do R9).
// Mercado sintetico de uma commodity com prioridade de preco; fotos a cada Delta minutos.
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
function run(cfg, deltaMin, seed) {
  const R = rng(seed);
  const ex = () => -Math.log(1 - R());
  const geo = (mean) => (mean <= 1 ? 1 : 1 + Math.floor(Math.log(1 - R()) / Math.log(1 - 1 / mean)));
  const gauss = () => Math.sqrt(-2 * Math.log(1 - R())) * Math.cos(2 * Math.PI * R());
  const V = 10000, tick = 1;
  let lots = []; // {price, qty, t0, dur, seen, owner}
  let nextId = 1;
  const front = () => { let m = Infinity; for (const l of lots) if (l.price < m) m = l.price; return m; };
  const post = (t, price, qty, owner) => { lots.push({ id: nextId++, price, qty, t0: t, dur: (R() < 0.6 ? 24 : (R() < 0.75 ? 8 : 2)), seen: false, owner }); };
  // semente da escada
  for (let i = 0; i < 40; i++) post(-R() * 12, Math.round(V * Math.exp(0.06 * gauss())), geo(cfg.lotMean), 'o' + (i % 12));
  const snap = () => { const m = new Map(); for (const l of lots) m.set(l.price, (m.get(l.price) || 0) + l.qty); return m; };
  const acc = { S: 0, sTrue: 0, sSeen: 0, lostAbove: 0, cxTrue: 0, cens: 0, n: 0, repAdj: 0 };
  let L0 = null, iv = { sTrue: 0, sSeen: 0, cx: 0, reposts: [] };
  const delta = deltaMin / 60;
  let tSnap = 0, t = 0;
  const T = cfg.hours;
  const expire = (now) => { const keep = []; for (const l of lots) { if (l.t0 + l.dur <= now) { iv.cx += l.qty; } else keep.push(l); } lots = keep; };
  const takeSnap = () => {
    const L1 = snap();
    if (L0) {
      const prices = [...new Set([...L0.keys(), ...L1.keys()])].sort((a, b) => a - b);
      let F = Infinity;
      for (const p of prices) { if (Math.min(L0.get(p) || 0, L1.get(p) || 0) > 0) { F = p; break; } }
      let S = 0, lostAbove = 0;
      for (const p of prices) {
        const q0 = L0.get(p) || 0, q1 = L1.get(p) || 0;
        if (p < F) S += q0;
        else if (p === F) { if (q0 > q1) S += q0 - q1; }
        else if (q0 > q1) lostAbove += q0 - q1;
      }
      // ajuste de repostagem com nome do dono: lote visto que sumiu por cancelamento e reapareceu mais barato
      let rep = 0;
      for (const r of iv.reposts) if (r.oldPrice <= F && r.seen) rep += r.qty;
      acc.S += S; acc.sTrue += iv.sTrue; acc.sSeen += iv.sSeen; acc.lostAbove += lostAbove; acc.cxTrue += iv.cx; acc.n++;
      acc.repAdj += Math.max(0, S - rep);
      if (F === Infinity) acc.cens++;
    }
    L0 = L1;
    for (const l of lots) l.seen = true;
    iv = { sTrue: 0, sSeen: 0, cx: 0, reposts: [] };
  };
  const rOrder = cfg.lam / cfg.orderMean, rPost = cfg.nu / cfg.lotMean;
  while (t < T) {
    const tot = rOrder + rPost + cfg.gamma * Math.max(lots.length, 1);
    const tn = t + ex() / tot;
    while (tSnap <= tn && tSnap <= T) { expire(tSnap); takeSnap(); tSnap += delta; }
    t = tn;
    expire(t);
    const u = R() * tot;
    if (u < rOrder) {
      let b = geo(cfg.orderMean);
      while (b > 0 && lots.length) {
        let best = -1;
        for (let i = 0; i < lots.length; i++) if (best < 0 || lots[i].price < lots[best].price || (lots[i].price === lots[best].price && lots[i].t0 < lots[best].t0)) best = i;
        const l = lots[best];
        if (l.price > V * 1.5) break;
        const k = Math.min(b, l.qty);
        l.qty -= k; b -= k; iv.sTrue += k; if (l.seen) iv.sSeen += k;
        if (l.qty === 0) lots.splice(best, 1);
      }
    } else if (u < rOrder + rPost) {
      const f = lots.length ? front() : V;
      const r = R();
      let price;
      if (r < cfg.uCut) price = Math.max(f - tick, Math.round(0.6 * V));
      else if (r < cfg.uCut + cfg.uMatch) price = f;
      else price = Math.round(V * Math.exp(0.06 * gauss()));
      post(t, price, geo(cfg.lotMean), 'o' + Math.floor(R() * 12));
    } else if (lots.length) {
      const i = Math.floor(R() * lots.length);
      const l = lots[i];
      const f = front();
      if (l.price === f && R() > cfg.frontCancel) continue;
      lots.splice(i, 1);
      iv.cx += l.qty;
      if (R() < cfg.repost) {
        const f2 = lots.length ? front() : V;
        const np = Math.max(f2 - tick, Math.round(0.6 * V));
        iv.reposts.push({ oldPrice: l.price, qty: l.qty, seen: l.seen });
        post(t, np, l.qty, l.owner);
      }
    }
  }
  return acc;
}
const base = { hours: 400, lam: 30, orderMean: 3, nu: 36, lotMean: 6, gamma: 0.05, frontCancel: 0.2, repost: 0.7, uCut: 0.40, uMatch: 0.15 };
const cfgs = [
  ['base (lam=30/h, oferta=36/h, 40% cobre, 15% iguala)', base],
  ['mercado lento (lam=3/h, oferta=4/h)', { ...base, lam: 3, nu: 4, orderMean: 2, lotMean: 3 }],
  ['muita cobertura (70% cobre)', { ...base, uCut: 0.70, uMatch: 0.10 }],
  ['cancelamento alto (gamma=0.2/h, frente cancela igual)', { ...base, gamma: 0.2, frontCancel: 1.0 }],
];
for (const [name, cfg] of cfgs) {
  console.log('--- ' + name);
  console.log('Delta(min) | S_lo/S_verd | vistas/S_verd | (S_lo - vistas)/S_verd | S_lo com ajuste de repostagem/S_verd | sumicos acima de F / (cancel+expira) | intervalos censurados');
  for (const d of [1, 2, 5, 15, 30, 60, 180]) {
    const a = run(cfg, d, 99);
    console.log([
      d,
      (a.S / a.sTrue).toFixed(3),
      (a.sSeen / a.sTrue).toFixed(3),
      ((a.S - a.sSeen) / a.sTrue).toFixed(3),
      (a.repAdj / a.sTrue).toFixed(3),
      (a.lostAbove / Math.max(1, a.cxTrue)).toFixed(3),
      (a.cens / a.n).toFixed(3),
    ].join(' | '));
  }
}
