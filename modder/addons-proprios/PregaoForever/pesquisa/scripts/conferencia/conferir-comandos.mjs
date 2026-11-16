import fs from 'node:fs'
const t = fs.readFileSync(process.argv[2], 'utf8')
const ini = t.indexOf('### Comandos da S0')
const fim = t.indexOf('## Apêndice B')
const bloco = t.slice(ini, fim)
const cmds = [...bloco.matchAll(/```\n(\/(?:run|dump)[^\n]*)\n```/g)].map(m => m[1])
console.log('comandos: ' + cmds.length)
cmds.forEach((c, i) => {
  let par = 0, ok = true
  for (const ch of c) { if (ch === '(') par++; if (ch === ')') par--; if (par < 0) ok = false }
  const aspas = (c.match(/"/g) || []).length
  const blocos = (c.match(/\b(do|then|function)\b/g) || []).length, ends = (c.match(/\bend\b/g) || []).length
  console.log((i + 1) + ': ' + c.length + ' caracteres | parênteses ' + (ok && par === 0 ? 'ok' : 'ERRO') + ' | aspas ' + (aspas % 2 === 0 ? 'ok' : 'ERRO') + ' | do/then/function ' + blocos + ' x end ' + ends + (blocos === ends ? '' : ' DIFERENTE'))
})
