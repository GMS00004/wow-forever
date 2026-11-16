// Confere dados/pregao/receitas-lw.json contra o contrato (secao 3). Uso: node testes/checar-receitas.mjs
import { ARQ_RECEITAS, lerJson } from '../comum.mjs';

const r = await lerJson(ARQ_RECEITAS);
const erros = [];
const exige = (cond, msg) => { if (!cond) erros.push(msg); };

exige(r.esquema === 1 && r.build === '1.60.1.70938', 'esquema ou build');
exige(r.profissao && r.profissao.id === 165, 'profissao');
// 592 magias criam item; 110 delas tem produto fora do ItemSparse neste build (contrato, secao 3).
exige(Array.isArray(r.receitas) && r.receitas.length >= 470 && r.receitas.length <= 592, `receitas: ${r.receitas && r.receitas.length} (esperado 470 a 592)`);
exige(r.contagem && r.contagem.receitas === r.receitas.length, 'contagem.receitas');
exige(r.contagem && r.contagem.receitas + r.contagem.semItem + r.contagem.semReagente + r.contagem.semItemSparse === 616, `contagens nao somam 616: ${JSON.stringify(r.contagem)}`);
exige(r.contagem && r.contagem.comItemReceita >= 380, `comItemReceita: ${r.contagem && r.contagem.comItemReceita} (esperado 380 ou mais)`);

const b = r.receitas.find(x => x.magia === 7149);
exige(!!b, 'receita 7149 ausente');
if (b) {
  exige(b.nome === 'Barbaric Leggings', `7149 nome: ${b.nome}`);
  exige(b.produto.id === 5963 && b.produto.qtd === 1, '7149 produto');
  exige(JSON.stringify(b.reagentes) === JSON.stringify([{ id: 4234, qtd: 10 }, { id: 2321, qtd: 2 }, { id: 1206, qtd: 1 }]), `7149 reagentes: ${JSON.stringify(b.reagentes)}`);
  exige(b.amarela === 165 && b.cinza === 185 && b.pontos === 1, '7149 faixas');
  exige(b.itemReceita && b.itemReceita.id === 5973 && b.itemReceita.periciaExigida === 145 && b.itemReceita.compra === 650, `7149 itemReceita: ${JSON.stringify(b.itemReceita)}`);
}
const it = r.itens || {};
exige(it['5963'] && it['5963'].vende === 3151 && it['5963'].vinculo === 2 && it['5963'].nome === 'Barbaric Leggings', `item 5963: ${JSON.stringify(it['5963'])}`);
exige(it['4234'] && it['4234'].vende === 150 && it['4234'].compra === 600, `item 4234: ${JSON.stringify(it['4234'])}`);

let faltam = 0, tipos = 0, ordem = 0, magias = new Set();
for (let i = 0; i < r.receitas.length; i++) {
  const x = r.receitas[i];
  for (const id of [x.produto.id, ...x.reagentes.map(g => g.id)]) if (!it[String(id)]) faltam++;
  if (![x.magia, x.produto.id, x.produto.qtd, x.amarela, x.cinza, x.pontos].every(Number.isInteger) || !x.reagentes.length || !x.reagentes.every(g => Number.isInteger(g.id) && Number.isInteger(g.qtd) && g.qtd > 0) || typeof x.nome !== 'string' || !x.nome) tipos++;
  if (i && (r.receitas[i - 1].amarela > x.amarela || (r.receitas[i - 1].amarela === x.amarela && r.receitas[i - 1].nome > x.nome))) ordem++;
  magias.add(x.magia);
}
exige(faltam === 0, `itens ausentes de "itens": ${faltam}`);
exige(tipos === 0, `receitas com campo de tipo errado: ${tipos}`);
exige(ordem === 0, `receitas fora de ordem (amarela, nome): ${ordem}`);
exige(magias.size === r.receitas.length, 'magia repetida');
for (const v of Object.values(it)) { if (![v.vende, v.compra, v.pilha, v.vinculo, v.qualidade].every(Number.isInteger)) { erros.push(`item com campo nao inteiro: ${JSON.stringify(v)}`); break; } }

for (const e of erros) console.log('ERRO', e);
console.log(`receitas=${r.receitas.length} itens=${Object.keys(it).length} contagem=${JSON.stringify(r.contagem)} erros=${erros.length}`);
process.exit(erros.length ? 1 : 0);
