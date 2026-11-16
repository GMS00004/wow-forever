// Refaz, de forma independente, as tabelas da seção 3.4 (escada de capital) do DESIGN.md.
const C = {
  C1: { f: 0.25, m: 0.10, a: 0.60, l: 0.08, voltas: 1, fora: 0.5 },
  C2: { f: 0.50, m: 0.12, a: 0.70, l: 0.06, voltas: 2, fora: 1.5 },
  C3: { f: 0.50, m: 0.15, a: 0.80, l: 0.05, voltas: 5, fora: 3.0 },
}
const alvos = [15, 60, 250, 1000]
function dias(p, o = {}) {
  const piso = o.piso ?? 1
  let ouro = o.inicio ?? 5.09
  const borda = p.a * p.m - (1 - p.a) * p.l
  const res = []
  let ganhoTrading = 0, ganhoTotal = 0
  const partes = []
  for (let d = 1; d <= 5000 && res.length < alvos.length; d++) {
    const antes = ouro
    const tradingLigado = !o.soFora && (!o.adiar || (d > 14 && ouro >= 15))
    if (tradingLigado) for (let v = 0; v < p.voltas; v++) {
      let base = Math.max(0, p.f * (ouro - piso))
      if (o.absorcao) base = Math.min(base, o.absorcao)
      const g = base * borda
      ouro += g; ganhoTrading += g
    }
    if (!o.soTrading) ouro += p.fora
    ganhoTotal += ouro - antes
    while (res.length < alvos.length && ouro >= alvos[res.length]) { res.push(d); partes.push(Math.round(100 * ganhoTrading / ganhoTotal)) }
  }
  return { res, partes }
}
for (const [n, p] of Object.entries(C)) {
  const borda = p.a * p.m - (1 - p.a) * p.l
  console.log(n + ' borda ' + (100 * borda).toFixed(1) + '% | cresc/dia ' + (100 * p.f * borda * p.voltas).toFixed(1) + '% | virada ' + (1 + p.fora / (p.f * borda * p.voltas)).toFixed(0) + ' ouro')
  console.log('  trading+fora   ' + dias(p).res.join(' '))
  console.log('  só trading     ' + dias(p, { soTrading: true }).res.join(' '))
  console.log('  só fora        ' + dias(p, { soFora: true }).res.join(' '))
  console.log('  adiar (d14,15) ' + dias(p, { adiar: true }).res.join(' '))
  if (n !== 'C1') console.log('  absorção 50    ' + dias(p, { absorcao: 50 }).res.join(' '))
  if (n === 'C2') { console.log('  sem reunir     ' + dias(p, { inicio: 1.27 }).res.join(' ')); console.log('  parte do trading (%) ' + dias(p).partes.join(' ')) }
}
const s = (mud) => dias({ ...C.C2, ...mud }).res.slice(1, 3).join(' ')
console.log('sens C2: base ' + s({}) + ' | 1 volta ' + s({ voltas: 1 }) + ' | 4 voltas ' + s({ voltas: 4 }) + ' | f 0,25 ' + s({ f: 0.25 }) + ' | m 6% ' + s({ m: 0.06 }) + ' | m 18% ' + s({ m: 0.18 }) + ' | a 50% ' + s({ a: 0.5 }) + ' | a 90% ' + s({ a: 0.9 }) + ' | l 12% ' + s({ l: 0.12 }) + ' | fora 0 ' + s({ fora: 0 }) + ' | fora 0,5 ' + s({ fora: 0.5 }) + ' | fora 3 ' + s({ fora: 3 }) + ' | fora 6 ' + s({ fora: 6 }))
console.log('piso zero C2: ' + dias(C.C2, { piso: 0 }).res.slice(1, 3).join(' '))
const horas = { C1: 3, C2: 6, C3: 10 }
for (const b of [5.09, 15, 60, 250, 1000]) console.log('ouro/h banca ' + b + ': ' + Object.entries(C).map(([n, p]) => { const borda = p.a * p.m - (1 - p.a) * p.l; let o = b, g = 0; for (let v = 0; v < p.voltas; v++) { const x = p.f * (o - 1) * borda; o += x; g += x } return (g / horas[n]).toFixed(2) }).join(' '))
