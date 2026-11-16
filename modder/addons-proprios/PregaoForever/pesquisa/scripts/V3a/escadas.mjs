// escadas.mjs - venda inferida pela diferenca de escadas (R9 2.1) e preenchimento do modo papel (R9 10.2),
// com fotos esparsas e em mercado de pouca demanda. Mercado sintetico no molde do simB.mjs do autor do R9.
function rng(seed) { let s = seed >>> 0; return () => { s = (s + 0x6D2B79F5) >>> 0; let t = s; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
const DUR = [2, 8, 24];

function run(cfg, photos, seed, ghostCfg) {
  const R = rng(seed);
  const ex = () => -Math.log(1 - R());
  const geo = (mean) => (mean <= 1 ? 1 : 1 + Math.floor(Math.log(1 - R()) / Math.log(1 - 1 / mean)));
  const gauss = () => Math.sqrt(-2 * Math.log(1 - R())) * Math.cos(2 * Math.PI * R());
  const V = 10000, tick = 1;
  let lots = [], nextId = 1;
  const front = () => { let m = Infinity; for (const l of lots) if (l.price < m) m = l.price; return m; };
  const post = (t, price, qty) => { lots.push({ id: nextId++, price, qty, t0: t, dur: (R() < 0.6 ? 24 : (R() < 0.75 ? 8 : 2)), lo: null, hi: null }); };
  for (let i = 0; i < 40; i++) post(-R() * 2, Math.round(V * Math.exp(0.06 * gauss())), geo(cfg.lotMean));
  let ev = new Map(); // id -> {sale, non} no intervalo corrente
  const log = (id, kind, q) => { let e = ev.get(id); if (!e) { e = { sale: 0, non: 0 }; ev.set(id, e); } e[kind] += q; };
  let sTrueIv = 0;
  const acc = { S: 0, sTrue: 0, falso: 0, Scoh: 0, n: 0, ivComS: 0, ivComVenda: 0, janB: 0, janN: 0 };
  const ghosts = [], closed = [];
  let prev = null, prevT = null, hist = []; // hist: [{t, pmax vendido inferido}]
  const expire = (now) => { const keep = []; for (const l of lots) { if (l.t0 + l.dur <= now) log(l.id, 'non', l.qty); else keep.push(l); } lots = keep; };
  const takePhoto = (t) => {
    const cur = { byP: new Map(), byId: new Map() };
    for (const l of lots) { cur.byP.set(l.price, (cur.byP.get(l.price) || 0) + l.qty); cur.byId.set(l.id, { price: l.price, qty: l.qty, lo: l.lo, hi: l.hi }); }
    const gapOk = prev && (t - prevT) <= (cfg.deltaMax || Infinity);
    if (prev && t > cfg.burn) {
      const prices = [...new Set([...prev.byP.keys(), ...cur.byP.keys()])].sort((a, b) => a - b);
      let F = Infinity;
      for (const p of prices) if (Math.min(prev.byP.get(p) || 0, cur.byP.get(p) || 0) > 0) { F = p; break; }
      const perF = F < Infinity ? Math.max(0, (prev.byP.get(F) || 0) - (cur.byP.get(F) || 0)) : 0;
      let S = 0; const vend = []; // vendas inferidas (preco, qtd)
      for (const p of prices) { const q0 = prev.byP.get(p) || 0; if (p < F && q0 > 0) { S += q0; vend.push([p, q0]); } else if (p === F && perF > 0) { S += perF; vend.push([p, perF]); } }
      // verdade por lote: unidades contadas em S que nao foram venda; e estimador com coortes (exclui o que pode ser expiracao e o de idade desconhecida)
      let falso = 0, falsoF = 0, coh = 0, cohF = 0;
      for (const [id, a] of prev.byId) {
        const b = cur.byId.get(id); const lost = a.qty - (b ? b.qty : 0); if (lost <= 0 || a.price > F) continue;
        const e = ev.get(id) || { sale: 0, non: 0 };
        let compat = (a.lo === null); // idade desconhecida
        if (!compat) for (const D of DUR) if (a.lo + D < t && a.hi + D > prevT) compat = true;
        if (a.price < F) { falso += e.non; if (!compat) coh += lost; } else { falsoF += e.non; if (!compat) cohF += lost; }
      }
      falso += Math.min(perF, falsoF); coh += Math.min(perF, cohF);
      if (gapOk) {
        acc.S += S; acc.sTrue += sTrueIv; acc.falso += falso; acc.Scoh += coh; acc.n++;
        if (S > 0) acc.ivComS++; if (sTrueIv > 0) acc.ivComVenda++;
        hist.push({ t, pmax: vend.length ? vend[vend.length - 1][0] : -1 });
        // testemunha da classe B: 3 intervalos nas ultimas 24 h com venda inferida a preco >= frente atual
        const fr = prices.find(p => (cur.byP.get(p) || 0) > 0);
        if (fr !== undefined) { let k = 0; for (let i = hist.length - 1; i >= 0 && hist[i].t > t - 24; i--) if (hist[i].pmax >= fr) k++; acc.janN++; if (k >= 3) acc.janB++; }
      }
      // papel: preenche fantasmas com as vendas inferidas a preco pior que o do lote
      for (const g of ghosts) {
        if (g.done) continue;
        const dentro = prevT >= g.t && t <= g.t + g.D;
        if (dentro && (gapOk || ghostCfg.contaBuraco)) {
          let s = 0; for (const [p, q] of vend) if (p > g.p) s += q;
          g.papel = Math.min(g.n, g.papel + s);
        }
      }
    }
    for (const g of ghosts) if (!g.done && t >= g.t + g.D) { g.done = true; closed.push(g); }
    // cria fantasma nesta foto
    if (ghostCfg && t > cfg.burn && lots.length && R() < ghostCfg.prob) {
      const f = front(); ghosts.push({ t, p: f - tick, n: ghostCfg.n, D: ghostCfg.D, real: 0, papel: 0, done: false });
    }
    for (const l of lots) { if (l.hi === null) { l.lo = prevT; l.hi = t; } }
    prev = cur; prevT = t; ev = new Map(); sTrueIv = 0;
  };
  const rOrder = cfg.lam / cfg.orderMean, rPost = cfg.nu / cfg.lotMean;
  let t = 0, ip = 0;
  const T = photos[photos.length - 1];
  while (t < T) {
    const tot = rOrder + rPost + cfg.gamma * Math.max(lots.length, 1);
    const tn = t + ex() / tot;
    while (ip < photos.length && photos[ip] <= tn) { expire(photos[ip]); takePhoto(photos[ip]); ip++; }
    t = tn; expire(t);
    const u = R() * tot;
    if (u < rOrder) {
      let b = geo(cfg.orderMean); const b0 = b;
      for (const g of ghosts) { if (g.done || t < g.t || t >= g.t + g.D || g.real >= g.n) continue; let below = 0; for (const l of lots) if (l.price < g.p) below += l.qty; g.real = Math.min(g.n, g.real + Math.max(0, b0 - below)); }
      while (b > 0 && lots.length) {
        let best = -1;
        for (let i = 0; i < lots.length; i++) if (best < 0 || lots[i].price < lots[best].price || (lots[i].price === lots[best].price && lots[i].t0 < lots[best].t0)) best = i;
        const l = lots[best]; if (l.price > V * 1.5) break;
        const k = Math.min(b, l.qty); l.qty -= k; b -= k; sTrueIv += k; log(l.id, 'sale', k);
        if (l.qty === 0) lots.splice(best, 1);
      }
    } else if (u < rOrder + rPost) {
      const f = lots.length ? front() : V; const r = R(); let price;
      if (r < cfg.uCut) price = Math.max(f - tick, Math.round(0.6 * V)); else if (r < cfg.uCut + cfg.uMatch) price = f; else price = Math.round(V * Math.exp(0.06 * gauss()));
      post(t, price, geo(cfg.lotMean));
    } else if (lots.length) {
      const i = Math.floor(R() * lots.length); const l = lots[i]; const f = front();
      if (l.price === f && R() > cfg.frontCancel) continue;
      lots.splice(i, 1); log(l.id, 'non', l.qty);
      if (R() < cfg.repost) { const f2 = lots.length ? front() : V; post(t, Math.max(f2 - tick, Math.round(0.6 * V)), l.qty); }
    }
  }
  return { acc, closed };
}
const regular = (deltaMin, hours) => { const a = []; for (let t = 0; t <= hours; t += deltaMin / 60) a.push(t); return a; };
const sessoes = (deltaMin, hSessao, dias) => { const a = []; for (let d = 0; d < dias; d++) for (let t = 0; t <= hSessao + 1e-9; t += deltaMin / 60) a.push(d * 24 + t); return a; };
const base = { burn: 30, hours: 1500, lam: 30, orderMean: 3, nu: 36, lotMean: 6, gamma: 0.05, frontCancel: 0.2, repost: 0.7, uCut: 0.40, uMatch: 0.15 };
const mercados = [
  ['liquido (30 un/h de demanda, 36 de oferta)', base],
  ['lento (3 un/h, 4 de oferta)', { ...base, lam: 3, nu: 4, orderMean: 2, lotMean: 3 }],
  ['ralo (0,3 un/h de demanda, 1,5 de oferta)', { ...base, lam: 0.3, nu: 1.5, orderMean: 1, lotMean: 2 }],
  ['quase morto (0,03 un/h, 1 de oferta)', { ...base, lam: 0.03, nu: 1, orderMean: 1, lotMean: 2 }],
  ['morto (0 de demanda, 1 de oferta)', { ...base, lam: 0, nu: 1, orderMean: 1, lotMean: 2 }],
];
console.log('== A. S_lo contra a verdade, fotos regulares (S_lo = R9 2.1 sem R_frente; coortes = so o que nao pode ser expiracao e tem idade conhecida)');
console.log('mercado | Delta | S_lo/vendas reais | parte de S_lo que NAO foi venda | S_coortes/vendas reais | intervalos com S_lo>0 | intervalos com venda real | P(classe B: 3 intervalos em 24 h)');
for (const [nome, cfg] of mercados) for (const d of [5, 15, 60]) {
  const { acc: a } = run(cfg, regular(d, cfg.hours), 7);
  console.log([nome, d + ' min', a.sTrue ? (a.S / a.sTrue).toFixed(2) : `S_lo=${a.S} (vendas reais 0)`, a.S ? (a.falso / a.S).toFixed(2) : '-', a.sTrue ? (a.Scoh / a.sTrue).toFixed(2) : `S_coortes=${a.Scoh}`, (a.ivComS / a.n).toFixed(3), (a.ivComVenda / a.n).toFixed(3), (a.janB / Math.max(1, a.janN)).toFixed(2)].join(' | '));
}
console.log('\n== B. Papel contra a verdade: lote fantasma de n unidades a (frente - 1 tick), FIFO, sem impacto. fracao vendida media e P(vendeu tudo)');
console.log('mercado | fotos | n | D | real: fracao, P(tudo) | papel: fracao, P(tudo) | papel/real');
const linhaB = (nome, cfg, rot, photos, g) => {
  const { closed } = run(cfg, photos, 11, g);
  if (!closed.length) { console.log([nome, rot, g.n, g.D, 'sem lotes'].join(' | ')); return; }
  let fr = 0, fp = 0, ar = 0, ap = 0; for (const c of closed) { fr += c.real / c.n; fp += c.papel / c.n; if (c.real >= c.n) ar++; if (c.papel >= c.n) ap++; }
  const N = closed.length;
  console.log([nome, rot, g.n, g.D + ' h', `${(fr / N).toFixed(2)}, ${(ar / N).toFixed(2)}`, `${(fp / N).toFixed(2)}, ${(ap / N).toFixed(2)}`, (fp / Math.max(fr, 1e-9)).toFixed(2), `(${N} lotes)`].join(' | '));
};
for (const [nome, cfg] of mercados.slice(0, 4)) for (const d of [5, 15, 60]) for (const n of [5, 40]) linhaB(nome, cfg, `regulares ${d} min`, regular(d, cfg.hours), { prob: d / 60 / 3, n, D: 24 });
console.log('\n== C. Papel com fotos so durante a sessao (4 h por dia, uma foto a cada 10 min), lote de 24 h');
for (const [nome, cfg] of mercados.slice(0, 4)) for (const n of [5, 40]) {
  linhaB(nome, { ...cfg, deltaMax: 2 }, 'sessao 4h/dia; buraco descartado (Delta_max 2 h)', sessoes(10, 4, 62), { prob: 0.05, n, D: 24, contaBuraco: false });
  linhaB(nome, cfg, 'sessao 4h/dia; buraco contado', sessoes(10, 4, 62), { prob: 0.05, n, D: 24, contaBuraco: true });
}
