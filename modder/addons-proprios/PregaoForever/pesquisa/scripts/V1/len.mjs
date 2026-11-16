// mede o tamanho de cada comando (limite da caixa de chat: 255) e procura nomes de acao
import fs from 'node:fs';
const p = '<tmp>/V1-api/cmds.txt';
const acao = /PostItem|PostCommodity|ConfirmPost|PlaceBid|StartCommoditiesPurchase|ConfirmCommoditiesPurchase|CancelAuction|CancelSell|SetCVar|SetBinding|TakeInbox|SendMail|ReplicateItems|SendBrowseQuery|SendSearchQuery|QueryOwnedAuctions/;
for (const line of fs.readFileSync(p, 'utf8').split(/\r?\n/)) {
  if (!line.trim()) continue;
  const i = line.indexOf('|');
  const id = line.slice(0, i), cmd = line.slice(i + 1);
  const bytes = Buffer.byteLength(cmd, 'utf8');
  console.log(id.padEnd(4), String(cmd.length).padStart(4), bytes === cmd.length ? 'ascii' : 'NAO-ASCII', cmd.length <= 255 ? 'ok' : 'ESTOURA', acao.test(cmd) ? 'TEM-ACAO-OU-CONSULTA' : 'so-leitura');
}
