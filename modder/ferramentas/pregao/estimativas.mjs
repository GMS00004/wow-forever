// Atualiza as estimativas de custo das profissoes num comando so (CONTRATO.md, secao 10.8): baixa a foto publica da
// hora, le a exportacao do scan do Auctionator (se houver) e refaz a conta do legado.mjs.
// Uso: node estimativas.mjs [opcoes do legado.mjs]     sem opcoes: --ate 225 --marcos 150
//      node estimativas.mjs --treino-ate 200           a variante segura (treinador so ate o 200)
//      node estimativas.mjs --sem-baixar               refaz a conta sem baixar precos (usa o precos.json atual)
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { ARQ_PRECOS, lerJson } from './comum.mjs';

const AQUI = path.dirname(fileURLToPath(import.meta.url));
const JANELA_AUCTIONATOR = 21600; // a exportacao do scan vale 6 horas, como no crafts.mjs e no legado.mjs
const PADRAO = ['--ate', '225', '--marcos', '150'];

const rodar = (script, args) => {
  const r = spawnSync(process.execPath, [path.join(AQUI, script), ...args], { cwd: AQUI, encoding: 'utf8' });
  if (r.stdout) process.stdout.write(r.stdout);
  if (r.stderr) process.stderr.write(r.stderr);
  return r.status ?? 1;
};

const p2 = (v) => String(v).padStart(2, '0');
const hora = (s) => { const d = new Date(s * 1000); return `${p2(d.getDate())}/${p2(d.getMonth() + 1)} ${p2(d.getHours())}:${p2(d.getMinutes())}`; };

// --sem-baixar: refaz a conta com o precos.json que ja esta no disco (sem rede).
const semBaixar = process.argv.includes('--sem-baixar');
if (semBaixar) console.log('1) precos: os do precos.json atual (--sem-baixar)');
else {
  console.log('1) precos: foto publica da hora e exportacao do Auctionator');
  const c1 = rodar('baixar-precos.mjs', []);
  if (c1 !== 0) console.error('baixar-precos falhou: a conta segue com o precos.json anterior');
}
const precos = await lerJson(ARQ_PRECOS);
const agora = Math.floor(Date.now() / 1000);
const auc = precos.auctionator;
const full = precos.fullCompra;
if (full && full.n && agora - full.em <= JANELA_AUCTIONATOR) {
  console.log(`full scan do CompraForever de ${hora(full.em)} (${full.n} itens): vale no lugar da foto publica e do Auctionator (ate 6 horas)`);
} else {
  if (full && full.n) console.log(`full scan do CompraForever de ${hora(full.em)}: velho, nao entra`);
  if (auc && agora - auc.em <= JANELA_AUCTIONATOR) console.log(`scan do Auctionator de ${hora(auc.em)}: entra no preco minimo (vale ate 6 horas)`);
  else if (auc) console.log(`scan do Auctionator de ${hora(auc.em)}: velho, nao entra; vale so a foto publica de ${hora(precos.publico.foto)}`);
  else console.log(`sem scan exportado; vale so a foto publica de ${hora(precos.publico.foto)}`);
}

const extra = process.argv.slice(2).filter((a) => a !== '--sem-baixar');
// Opcao dada na linha de comando substitui a do padrao (a opcao e o valor dela).
const args = [...PADRAO.filter((a, i, l) => !extra.includes(i % 2 === 0 ? a : l[i - 1])), ...extra];
console.log(`2) conta: node legado.mjs ${args.join(' ')}`);
process.exit(rodar('legado.mjs', args));
