// lista as funcoes com HasRestrictions = true em toda a documentacao gerada, por arquivo
import fs from 'node:fs';
import path from 'node:path';
const DOC = '<espelho>/Interface/AddOns/Blizzard_APIDocumentationGenerated';
let total = 0;
for (const f of fs.readdirSync(DOC)) {
  if (!f.endsWith('.lua')) continue;
  const lines = fs.readFileSync(path.join(DOC, f), 'utf8').split(/\r?\n/);
  const names = [];
  for (let i = 0; i < lines.length; i++) {
    if (/^\s*HasRestrictions = true/.test(lines[i])) {
      let nm = '?';
      for (let j = i; j >= Math.max(0, i - 6); j--) { const m = lines[j].match(/Name = "([^"]+)"/); if (m) { nm = m[1]; break; } }
      names.push(nm);
    }
  }
  if (names.length) { total += names.length; console.log(f.replace('Documentation.lua', '') + ' (' + names.length + '): ' + names.slice(0, 14).join(', ') + (names.length > 14 ? ', ...' : '')); }
}
console.log('total', total);
