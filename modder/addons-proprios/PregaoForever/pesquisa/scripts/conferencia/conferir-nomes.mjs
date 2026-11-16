// Confere se os nomes de API, evento, enum e texto do cliente citados em crase nos documentos existem
// no espelho do código da Blizzard, nas listas oficiais do projeto ou no arquivo de textos do cliente.
// Uso: node conferir-nomes.mjs <espelho/Interface/AddOns> <pasta api-forever> <GlobalStrings.lua> <doc1.md> [doc2.md ...]
import fs from 'node:fs'
import path from 'node:path'
const [, , espelho, apiDir, strings, ...docs] = process.argv
const palavras = new Set()
let arquivos = 0
function engole(texto) { for (const m of texto.matchAll(/[A-Za-z_][A-Za-z0-9_]*/g)) palavras.add(m[0]) }
function anda(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name)
    if (e.isDirectory()) anda(p)
    else if (/\.(lua|xml|toc|txt|json|md)$/i.test(e.name)) { engole(fs.readFileSync(p, 'latin1')); arquivos++ }
  }
}
anda(espelho)
const nEspelho = palavras.size
if (fs.existsSync(apiDir)) anda(apiDir)
if (fs.existsSync(strings)) engole(fs.readFileSync(strings, 'latin1'))
console.log('corpus: ' + arquivos + ' arquivos, ' + palavras.size + ' nomes (' + nEspelho + ' só do espelho)')

const nossos = /^(PregaoForever|ns|Cofre|Livro|Config|Calibrado|Tetos|Dados|Banco|Itens|Pedidos|Varredura|Escada|Estimadores|Motor|Sombra|Estrategias|Acoes|Ecos|Teclas|Correio|Sonda|Pontes|Visual|Alertas|Janela|Telas|Nucleo|Receitas|pers|cofre|folego|ritmo|foco|venda|piso|remoto|post|sonda|licencas|reservas|destravas|teclas)(\.|$)/
for (const doc of docs) {
  const t = fs.readFileSync(doc, 'utf8')
  const faltam = new Map()
  let conferidos = 0
  // crase simples e blocos de código
  const trechos = [...t.matchAll(/`([^`\n]+)`/g)].map(m => m[1]).concat([...t.matchAll(/```[^\n]*\n([\s\S]*?)```/g)].map(m => m[1]))
  for (const tr of trechos) {
    for (const m of tr.matchAll(/[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*/g)) {
      const tok = m[0]
      if (nossos.test(tok)) continue
      const partes = tok.split('.')
      const candidato = partes.some(p => /^[A-Z][a-z]+[A-Z]/.test(p) || /^[A-Z][A-Z0-9]+_[A-Z0-9_]+$/.test(p) || /^C_[A-Z]/.test(p) || /^(Get|Set|Is|Has|Can|Send|Request|Query|Place|Post|Confirm|Cancel|Start|Calculate|Refresh|Register|Clear|Play|Flash|Reload|Run|Take|Delete|Return|Buy|Use|Auto|Sell|Search|Replicate|Supports|Should|Favorites|Make|Close|Create|Does|In)[A-Z]/.test(p))
      if (!candidato) continue
      conferidos++
      const ausentes = partes.filter(p => !palavras.has(p))
      if (ausentes.length) faltam.set(tok, (faltam.get(tok) || 0) + 1)
    }
  }
  console.log('\n' + path.basename(doc) + ': ' + conferidos + ' citações conferidas; nomes não achados no corpus: ' + faltam.size)
  for (const [k, v] of [...faltam.entries()].sort()) console.log('   ' + k + ' x' + v)
}
