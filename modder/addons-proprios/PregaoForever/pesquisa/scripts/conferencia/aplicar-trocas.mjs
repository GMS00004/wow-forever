// Aplica trocas exatas de texto, cada uma tendo de casar uma única vez. Uso: node aplicar-trocas.mjs <arquivo alvo> <arquivo de trocas> [--aplicar]
// Formato do arquivo de trocas: blocos  <<<\n(texto antigo)\n===\n(texto novo)\n>>>   Tudo fora dos blocos é comentário.
import fs from 'node:fs'
const [, , alvo, trocasArq, flag] = process.argv
let t = fs.readFileSync(alvo, 'utf8').replace(/\r\n/g, '\n')
const bruto = fs.readFileSync(trocasArq, 'utf8').replace(/\r\n/g, '\n')
const blocos = [...bruto.matchAll(/^<<<\n([\s\S]*?)\n===\n([\s\S]*?)\n>>>$/gm)].map(m => [m[1], m[2]])
let ok = 0, ruins = 0
blocos.forEach(([de, para], i) => {
  const n = t.split(de).length - 1
  if (n !== 1) { ruins++; console.log('FALHOU bloco ' + (i + 1) + ' (casou ' + n + ' vezes): ' + de.slice(0, 110).replace(/\n/g, ' / ')); return }
  t = t.replace(de, () => para); ok++
})
console.log('blocos: ' + blocos.length + ' | aplicáveis: ' + ok + ' | com problema: ' + ruins)
if (flag === '--aplicar' && ruins === 0) { fs.writeFileSync(alvo, t, 'utf8'); console.log('GRAVADO ' + alvo) } else console.log(ruins ? 'NADA GRAVADO: corrija os blocos' : 'PRÉVIA (nada gravado)')
