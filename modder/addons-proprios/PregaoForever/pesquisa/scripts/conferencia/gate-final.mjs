// Conferência mecânica do design final. Uso: node gate-final.mjs <pasta com DESIGN.md, LEIA-ME.md, MUDANCAS.md> <achados-todos.md>
import fs from 'node:fs'
import path from 'node:path'
const [, , pasta, achadosArq] = process.argv
const ler = n => { const p = path.join(pasta, n); return fs.existsSync(p) ? fs.readFileSync(p, 'utf8') : null }
const D = ler('DESIGN.md'), L = ler('LEIA-ME.md'), M = ler('MUDANCAS.md')
const palavras = t => (t.match(/\S+/g) || []).length
const sec = t => console.log('\n=== ' + t)
for (const [n, t] of [['DESIGN.md', D], ['LEIA-ME.md', L], ['MUDANCAS.md', M]]) console.log(n + ': ' + (t === null ? 'AUSENTE' : palavras(t) + ' palavras, ' + t.split('\n').length + ' linhas'))
if (!D) process.exit(1)
const mostra = (rot, linhas, max = 12) => { console.log(rot + ': ' + linhas.length); for (const l of linhas.slice(0, max)) console.log('   ' + l.slice(0, 230)) }
const linhasCom = (t, re) => t.split('\n').map((l, i) => ({ l, i: i + 1 })).filter(x => re.test(x.l)).map(x => x.i + ': ' + x.l.trim())

sec('1. ids dos achados em MUDANCAS.md')
const ids = [...new Set([...fs.readFileSync(achadosArq, 'utf8').matchAll(/\*\*(V[0-9A-Z]+-\d+)\*\*/g)].map(m => m[1]))]
if (M) {
  const faltam = ids.filter(id => !new RegExp('(^|[^0-9A-Za-z])' + id + '([^0-9]|$)', 'm').test(M))
  console.log('achados: ' + ids.length + ' | sem linha em MUDANCAS: ' + faltam.length + (faltam.length ? ' -> ' + faltam.join(', ') : ''))
  const nao = M.split('\n').filter(l => /n[ãa]o aplicad/i.test(l))
  mostra('linhas "não aplicado"', nao.map(l => l.trim()), 40)
  const parc = M.split('\n').filter(l => /parcial/i.test(l))
  mostra('linhas "parcial"', parc.map(l => l.trim()), 40)
}

sec('2. referências a artefatos de processo')
const reProc = /(?<![A-Za-z0-9])(D[1-6]-(quant|operador|mesa|risco|ouro|concorrencia)|J[1-3]-\w+|SINTESE|TRIAGEM|achados-todos)|(?<![A-Za-z0-9-])[DJ][1-6](?![0-9A-Za-z_-])|(?<![A-Za-z0-9])V[1-8][ABab]?-\d+|parecer(es)? (do|da|dos) (juiz|revis)/
mostra('DESIGN', linhasCom(D, reProc))
if (L) mostra('LEIA-ME', linhasCom(L, reProc))

sec('3. LEIA-ME: estilo e partes')
if (L) {
  mostra('bullets', linhasCom(L, /^\s*[-*+] /))
  mostra('negrito', linhasCom(L, /\*\*|__[^_]/))
  mostra('travessão', linhasCom(L, /—| – /))
  console.log('palavras: ' + palavras(L) + ' (meta 2.500 a 3.800)')
  mostra('títulos', linhasCom(L, /^#{1,3} /), 40)
  const fora = L.split('\n').filter(l => l.length > 0 && !/^\s*```/.test(l))
  const larg = L.split('```').filter((_, i) => i % 2 === 1).flatMap(b => b.split('\n')).reduce((m, l) => Math.max(m, [...l].length), 0)
  console.log('linha mais larga dentro de bloco de código: ' + larg + ' caracteres')
}

sec('4. relatórios citados')
const permit = new Set(['R1a', 'R1b', 'R1c', 'R4a', 'R4b', 'R5a', 'R5b', 'R6a', 'R6b', 'R8a', 'R8b', 'R9', 'R10a', 'R10b', 'R11a', 'R11b'])
for (const [n, t] of [['DESIGN', D], ['LEIA-ME', L]]) {
  if (!t) continue
  const cont = {}
  for (const m of t.matchAll(/(?<![A-Za-z0-9_])R(\d{1,2})([a-d])?(?![0-9A-Za-z_])/g)) { const k = 'R' + m[1] + (m[2] || ''); cont[k] = (cont[k] || 0) + 1 }
  const proib = new Set(['R2a', 'R2b', 'R2c', 'R3a', 'R3b', 'R3c', 'R3d', 'R7a', 'R7b'])
  const ruins = Object.entries(cont).filter(([k]) => proib.has(k))
  const outros = Object.entries(cont).filter(([k]) => !permit.has(k) && !proib.has(k))
  console.log(n + ': citados ' + Object.keys(cont).length + ' | relatórios não gravados citados: ' + (ruins.map(([k, v]) => k + 'x' + v).join(', ') || 'nenhum') + ' | outros rótulos R (regras internas do R8b, por exemplo): ' + (outros.map(([k, v]) => k + 'x' + v).join(', ') || 'nenhum'))
  for (const [k] of ruins.slice(0, 9)) mostra('   ' + k, linhasCom(t, new RegExp('(?<![A-Za-z0-9_])' + k + '(?![0-9A-Za-z_])')), 3)
}

sec('5. resíduos proibidos')
const TOK = /Auctionator\/|AUC\/|AUC = |Source_ModernAH|Source_LegacyAH|LOCAL-FG|LOCAL-AUC|ForeverGuide\/[A-Za-z]+\.lua|Auctionator\.(Utilities|Constants)/
for (const [n, t] of [['DESIGN', D], ['LEIA-ME', L], ['MUDANCAS', M]]) {
  if (!t) continue
  mostra(n + ' código de terceiro', linhasCom(t, TOK), 6)
  mostra(n + ' caminho temporário', linhasCom(t, /AppData|scratchpad|Temp[\\/]+claude/i), 6)
  mostra(n + ' conta ou e-mail', linhasCom(t, /@gmail|WTF[\\/]+Account[\\/]+[A-Z0-9#]{4,}/), 6)
}

sec('6. ids internos: citados contra definidos (DESIGN)')
const defs = (re) => new Set([...D.matchAll(re)].map(m => m[1]))
const cita = (re) => { const c = {}; for (const m of D.matchAll(re)) c[m[1]] = (c[m[1]] || 0) + 1; return c }
const confere = (rot, citados, definidos) => {
  const semDef = Object.keys(citados).filter(k => !definidos.has(k))
  const semUso = [...definidos].filter(k => (citados[k] || 0) <= 1)
  console.log(rot + ': definidos ' + definidos.size + ' | citados ' + Object.keys(citados).length + ' | citados sem definição: ' + (semDef.join(', ') || 'nenhum') + ' | definidos e citados uma vez só: ' + (semUso.join(', ') || 'nenhum'))
}
confere('hipóteses H-NN', cita(/(?<![A-Za-z0-9])(H-\d{2})(?![0-9])/g), defs(/^\|\s*(H-\d{2})\s*\|/gm))
confere('decisões DD', cita(/(?<![A-Za-z0-9])(DD\d{1,2}[a-c]?)(?![0-9A-Za-z])/g), defs(/^\|\s*(DD\d{1,2}[a-c]?)\s*\|/gm))
confere('sonda S', cita(/(?<![A-Za-z0-9_-])(S\d{1,2})(?![0-9A-Za-z_])/g), defs(/^\|\s*(S\d{1,2})\s*\|/gm))
confere('invariantes I', cita(/(?<![A-Za-z0-9_-])(I\d)(?![0-9A-Za-z_])/g), defs(/^\|\s*(I\d)\s*\|/gm))
confere('regras 1..N', {}, defs(/^(\d{1,2})\. /gm))

sec('7. seções citadas que não existem (DESIGN)')
const tit = new Set([...D.matchAll(/^#{2,4}\s+(\d{1,2}(?:\.\d{1,2}){0,2})\.?\s/gm)].map(m => m[1]))
const citSec = {}
// "base 3.4, 2.16" e "R9 5.1" apontam para a base de fatos e para os relatórios, não para seções deste texto
const Dsec = D.replace(/(?<![A-Za-z0-9])(base|R\d{1,2}[a-d]?)\s+\d{1,2}(\.\d{1,2})*((,| e|;)\s*\d{1,2}(\.\d{1,2})+)*/g, '')
for (const m of Dsec.matchAll(/(?:seç(?:ão|ões)|Seç(?:ão|ões)|\bna|\bda|\bver|\bem|\be|\bou|,|\(|\ba)\s+(\d{1,2}\.\d{1,2}(?:\.\d{1,2})?)(?![0-9.]*\d|[0-9]| %| ?%|\s?(g|s|c|ouro|prata|cobre|h|min|x|vez|ms|KB|MB|K|M|mil|dia|hora)\b)/g)) { const k = m[1]; const topo = Number(k.split('.')[0]); if (topo >= 1 && topo <= 19) citSec[k] = (citSec[k] || 0) + 1 }
const faltamSec = Object.keys(citSec).filter(k => !tit.has(k))
console.log('títulos numerados: ' + tit.size + ' | seções citadas: ' + Object.keys(citSec).length + ' | sem título: ' + (faltamSec.join(', ') || 'nenhuma'))
for (const k of faltamSec.slice(0, 12)) mostra('   ' + k, linhasCom(D, new RegExp('(?<![0-9.])' + k.replace(/\./g, '\\.') + '(?![0-9.]*\\d)')), 2)
for (const ap of ['Apêndice A', 'Apêndice B', 'Apêndice C', 'Apêndice D']) console.log(ap + ': ' + (new RegExp('^#{1,3} ' + ap, 'm').test(D) ? 'existe' : 'AUSENTE') + ' | citado ' + (D.split(ap).length - 1) + 'x')

sec('8. parâmetros em crase que não aparecem no Apêndice B')
const iB = D.search(/^#{1,3} Apêndice B/m)
const fimB = iB >= 0 ? (() => { const r = D.slice(iB + 5).search(/^#{1,2} /m); return r < 0 ? D.length : iB + 5 + r })() : -1
const apB = iB >= 0 ? D.slice(iB, fimB) : ''
const params = {}
for (const m of D.matchAll(/`([A-Za-zΔηθαβλτσμ][A-Za-z0-9]*_[A-Za-z0-9_*]+|W\*|P\*|W1)`/g)) params[m[1]] = (params[m[1]] || 0) + 1
const semB = Object.entries(params).filter(([k]) => !apB.includes(k) && !/^(C_|AUCTION_|ERR_|CONFIRM_|CANCEL_|UI_|LE_|NUM_|MAX_|GetBinding|seller_|commerce|ITEM_|BIND_|SLASH_)/.test(k) && !/[a-z]_[a-z]/.test(k) === false ? true : false)
console.log('tokens com sublinhado: ' + Object.keys(params).length + ' | Apêndice B: ' + (apB ? palavras(apB) + ' palavras' : 'AUSENTE'))
const candidatos = Object.entries(params).filter(([k]) => /^[A-Za-zΔη][A-Za-z]{0,6}_[a-z0-9_*]+$/.test(k) && !/^(C_|seller_|commerce|venda_|pers|conta|item|preco|qtd|hora|dia|seq|tipo|nome|id_|n_|t_)/.test(k) && !apB.includes(k))
mostra('prováveis parâmetros fora do Apêndice B', candidatos.map(([k, v]) => k + ' x' + v), 40)
