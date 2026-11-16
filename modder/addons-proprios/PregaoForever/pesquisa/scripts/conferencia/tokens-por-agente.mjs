// Soma tokens por agente de um workflow (deduplicando por message.id) e cruza com os rótulos do journal.
// Uso: node tokens-por-agente.mjs <pasta do workflow> [--json <arquivo de saída>]
import fs from 'node:fs'
import path from 'node:path'
const [, , pasta, flag, saida] = process.argv
const rot = {}
for (const l of fs.readFileSync(path.join(pasta, 'journal.jsonl'), 'utf8').split('\n').filter(Boolean)) {
  let o
  try { o = JSON.parse(l) } catch { continue }
  if (o.type === 'started') rot[o.agentId] = o.label
}
const linhas = []
const tot = { inp: 0, out: 0, cc: 0, cr: 0 }
for (const f of fs.readdirSync(pasta).filter(n => /^agent-.*\.jsonl$/.test(n))) {
  const id = f.replace(/^agent-/, '').replace(/\.jsonl$/, '')
  const vistos = new Map()
  let modelo = ''
  for (const l of fs.readFileSync(path.join(pasta, f), 'utf8').split('\n').filter(Boolean)) {
    let o
    try { o = JSON.parse(l) } catch { continue }
    const m = o.message
    if (!m || m.role !== 'assistant' || !m.usage || !m.id) continue
    vistos.set(m.id, m.usage) // a última linha do mesmo id tem o uso final
    if (m.model) modelo = m.model
  }
  const s = { inp: 0, out: 0, cc: 0, cr: 0 }
  for (const u of vistos.values()) {
    s.inp += u.input_tokens || 0
    s.out += u.output_tokens || 0
    s.cc += u.cache_creation_input_tokens || 0
    s.cr += u.cache_read_input_tokens || 0
  }
  for (const k of Object.keys(tot)) tot[k] += s[k]
  linhas.push({ id, label: rot[id] || '?', modelo, turnos: vistos.size, ...s, semLeituraDeCache: s.inp + s.out + s.cc, tudo: s.inp + s.out + s.cc + s.cr })
}
linhas.sort((a, b) => a.label.localeCompare(b.label))
for (const x of linhas) console.log([x.label.padEnd(16), x.modelo.padEnd(22), String(x.turnos).padStart(4) + ' turnos', 'in+out+criacao=' + String(x.semLeituraDeCache).padStart(8), 'saida=' + String(x.out).padStart(7), 'tudo=' + String(x.tudo).padStart(9)].join(' | '))
console.log('TOTAL: in=' + tot.inp + ' out=' + tot.out + ' criacao=' + tot.cc + ' leitura=' + tot.cr + ' | in+out+criacao=' + (tot.inp + tot.out + tot.cc) + ' | in+out=' + (tot.inp + tot.out) + ' | tudo=' + (tot.inp + tot.out + tot.cc + tot.cr))
if (flag === '--json' && saida) fs.writeFileSync(saida, JSON.stringify(linhas, null, 1), 'utf8')
