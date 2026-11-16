// confere a tabela dos achados: numero de colunas, palavras do achado (<=60) e da correcao (<=80), aspas duplas e barra invertida
import fs from 'node:fs';
const p = 'pesquisa/processo/V1-api.md';
const txt = fs.readFileSync(p, 'utf8');
const ini = txt.indexOf('## Tabela dos achados');
const linhas = txt.slice(ini).split(/\r?\n/).filter(l => /^\| V1-\d\d /.test(l));
const palavras = s => s.trim().split(/\s+/).filter(Boolean).length;
const out = [];
for (const l of linhas) {
  const c = l.split('|').slice(1, -1).map(x => x.trim());
  const [id, secao, gravidade, tipo, achado, evidencia, correcao] = c;
  console.log(id, 'cols=' + c.length, gravidade.padEnd(10), tipo.padEnd(20), 'achado=' + palavras(achado), 'corr=' + palavras(correcao),
    /"/.test(l) ? 'TEM-ASPAS-DUPLAS' : '', /\\/.test(l) ? 'TEM-BARRA-INVERTIDA' : '');
  out.push({ id, secao, gravidade, tipo, achado, evidencia, correcao });
}
fs.writeFileSync('<tmp>/V1-api/achados.json', JSON.stringify(out, null, 1));
console.log('total', linhas.length);
// titulos exigidos
for (const t of ['## Tabela dos achados', '## Comandos da sonda (corrigidos)', '| H-01 |', '| H-25 |']) console.log(t, txt.includes(t));
