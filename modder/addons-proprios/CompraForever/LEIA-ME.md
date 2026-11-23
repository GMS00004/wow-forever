# CompraForever 0.2.1

Um fluxo só: na AH, clicar Scan e seguir o botão grande. O painel diz quanto comprar de cada material, com o dinheiro e
o espaço de bolsa que você tem agora, para craftar receitas de Leatherworking que você conhece e vender no vendedor
com lucro. Desde a 0.2.0, o mesmo botão também compra quando um item vigiado cai no teto (WATCH) e posta no leilão
(SELL). Substitui o PregaoForever, que saiu do jogo em 2026-11-17 (o código continua no git).

## Uso

1. Abra uma vez a janela de Leatherworking (o addon grava as receitas que você conhece).
2. Abra a AH. O painel aparece à direita. Clique Scan (busca só os materiais das suas receitas, menos de 1 minuto).
   Full scan busca a AH inteira (recarga de 15 min) e acha também item anunciado abaixo do preço de vendedor.
3. Clique o botão grande quantas vezes ele pedir. Cada clique faz uma coisa: "Buy" cota, "Confirm" compra;
   lote de item é um clique por lote. Compra primeiro o material mais caro da leva. Se o preço subiu um pouco e a leva
   ainda paga, pede Confirm com o total novo; se subiu demais, cancela, busca de novo só aquele item e refaz o plano
   contando o que você já comprou.
4. O que a AH vende chega pelo correio: pegue na caixa de correio (o painel mostra quantos itens faltam).
5. No vendedor (linha, tinta, sal): o botão compra os reagentes de vendedor do plano.
6. Na janela de Leatherworking: o botão crafta, uma receita por clique (intermediários primeiro, como curar hide).
7. No vendedor: o botão vende só o que você craftou nesta sessão pelo plano. Nada mais sai da bolsa.

## Categorias

Cada linha do plano tem cor e etiqueta. Cor pelo lucro: BIG (verde, 1g ou mais), small (amarelo, 30s a 1g), skip
(cinza, abaixo de 30s: "not worth it"). Etiqueta pelo tipo: [CRAFT] crafta com material comprado, [BAGS] usa material
que já está na bolsa (sobra de leva anterior), [RESALE] compra e vende direto no vendedor (só com full scan).

## Vigia de preços (WATCH)

Você diz o item e o teto. Com a AH aberta, o addon busca o preço do item de tempos em tempos e avisa quando o menor
preço chega ao teto ou abaixo dele.

1. Na AH, cole o item no chat com shift-clique (ou digite o número do item) e o teto: `/compra watch <item> <teto> [qtd]`.
   Exemplo: `/compra watch 4304 4s90c` (Thick Leather, teto 4s90c). Sem qtd, a vigia compra 20.
2. Quando o menor preço fica no teto ou abaixo, o addon toca um som e mostra um aviso na tela. Ele avisa uma vez por
   queda: se o preço subir acima do teto e cair de novo, avisa de novo.
3. O botão grande mostra `Buy ... [WATCH]`, antes do plano. Em commodity são dois cliques (cotar, depois confirmar).
   O teto vale por unidade, sem folga: se a cotação passar do teto, cancela e mostra "Price rose above watch".
   Item de leilão inteiro é um clique por lote.
4. O painel tem a seção WATCH: uma linha por item, em verde com BUY quando o menor preço está no teto ou abaixo, com o
   preço atual e as unidades à venda.

Outros comandos:

- `/compra watch` lista os itens vigiados, com o último preço visto.
- `/compra watch <item> <teto> [qtd]` de novo, com o mesmo item, troca o teto ou a quantidade.
- `/compra unwatch <item>` tira o item da vigia.
- `/compra watch every <s>` muda o intervalo da busca, de 10 a 300 s (padrão 30). Cada busca leva só os itens cujo
  intervalo venceu. Com muitos itens, o intervalo sobe sozinho (0,6 s por item) para ficar abaixo de 100 buscas por
  minuto.

A vigia espera enquanto um Scan ou uma compra está em andamento. Ao abrir a AH, ela esquece os preços e os avisos e busca
de novo.

Histórico: cada busca grava, por item, o menor preço e o preço no 25% das unidades à venda (da mais barata para a mais
cara), mais a quantidade. Os registros ficam em `CompraForeverDB.vigia.historico` (SavedVariables), até 2.000 por item;
os mais antigos saem. O jogo grava a SavedVariables ao sair ou dar `/reload`. Para ver a curva fora do jogo:
`node ferramentas\pregao\tendencia.mjs --vigia`.

A busca da vigia roda sozinha enquanto a AH está aberta, sem tecla sua. Não há pausa automática por enquanto (ver
`CONTRATO.md`, seção 10).

## Revenda no leilão (SELL)

Posta no leilão o que está na bolsa, pelo botão grande ou por comando.

1. Pedido: `/compra post <item> <preço|auto> [qtd]`. Preço sem espaço, como `6s09c`. `auto` usa o menor preço visto do
   item (no último Scan ou na vigia). Sem qtd, posta tudo que está na bolsa. Sem preço visto, recusa: "Scan or watch it
   first".
2. Regra de igualar: o pedido posta no menor preço atual, sem baixar dele. Leilão posto depois ao mesmo preço vende
   primeiro no Forever, então o addon não tenta ficar abaixo.
3. Piso: `/compra sell <item> <piso|off>` (só item vigiado). Com piso, o addon sugere sozinho `Post ... [SELL]` quando o
   menor preço está no piso ou acima dele. Sugestão não entra na fila.
4. Fila: `/compra post` lista os pedidos e as sugestões. `/compra post clear` esvazia a fila.
5. Duração: `/compra duration <1-3>` (padrão 3). A correspondência com 2 h, 8 h e 24 h ainda não foi confirmada no jogo.
6. Um clique por pilha. O botão mostra `Post <qtd> <nome> @ <preço> (dep <depósito>) [SELL]`. Se o cliente pedir
   confirmação, o botão vira `Confirm post <qtd> <nome>`, e o clique seguinte confirma.
7. A postagem conta como feita quando a pilha sai da bolsa ou encolhe. Sem resposta em 15 s, mostra "No answer: try
   again". Sem dinheiro para o depósito, mostra "Not enough money for deposit".
8. O painel tem a seção SELL: pedidos, sugestões (marcadas com `(auto)`) e, depois, `[x] posted <qtd> <nome>` para o que
   já foi postado nesta sessão.

## Comandos

| Comando | O que faz |
|---|---|
| `/compra` | mostra ou esconde o painel |
| `/compra reserva 1g` | dinheiro que o plano nunca gasta (padrão 0) |
| `/compra desconto 10` | desconto de reputação no vendedor, em % (padrão 10, o de Darnassus) |
| `/compra lucro 50c` | lucro mínimo por craft (padrão 50c; e 5% do custo) |
| `/compra grande 1g` | a partir de quanto a leva é BIG, em verde (padrão 1g) |
| `/compra pequena 30s` | a partir de quanto é small, em amarelo; abaixo é skip, em cinza (padrão 30s) |
| `/compra sonda` | diagnóstico do leilão (commodity ou item, tempo das buscas) |
| `/compra watch <item> <teto> [qtd]` | vigia o item; avisa e mostra [WATCH] quando o menor preço chega ao teto (qtd padrão 20) |
| `/compra watch` | lista os itens vigiados, com o último preço |
| `/compra watch every <s>` | intervalo da busca da vigia, de 10 a 300 s (padrão 30) |
| `/compra unwatch <item>` | tira o item da vigia |
| `/compra sell <item> <piso\|off>` | piso de venda de item vigiado; sugere a postagem quando o menor preço está no piso ou acima |
| `/compra post <item> <preço\|auto> [qtd]` | põe o item na fila de postagem |
| `/compra post` | lista a fila e as sugestões |
| `/compra post clear` | esvazia a fila |
| `/compra duration <1-3>` | duração do leilão postado (padrão 3; ver a nota na seção SELL) |

## Full scan no disco (0.2.1)

Desde a 0.2.1 (2026-11-23), ao terminar o botão Full, o addon guarda o livro de cada item (unidades, anúncios e os 40
preços mais baratos, com a quantidade de cada um) em `CompraForeverDB.full`. O arquivo só vai ao disco no `/reload` ou
ao sair do jogo. A ferramenta de estimativas (`ferramentas\pregao\estimativas.mjs`) usa esse livro por 6 horas, no
lugar da foto pública e do scan do Auctionator. Fluxo: Full, esperar terminar, `/reload`, e pedir "atualiza" ao agente.
Vale com `/reload` (nenhum arquivo novo no TOC).

## Para desfazer

Com o jogo fechado: `powershell -NoProfile -ExecutionPolicy Bypass -File ferramentas\dev-link.ps1 -Pasta addons-proprios\CompraForever -Remover -Aplicar`.
Para voltar o PregaoForever: o mesmo comando com `-Pasta addons-proprios\PregaoForever`, sem `-Remover`.

O TOC da 0.2.0 ganhou dois arquivos novos (`Vigia.lua` e `Venda.lua`). Na primeira vez com essa versão, reinicie o jogo
(sair e entrar). `/reload` não basta.

Contrato técnico: `CONTRATO.md`. Bancada: `node ferramentas\guia\pregao\bancada-pregao.mjs --addon addons-proprios\CompraForever --cenarios compra`.
Dados: `node ferramentas\compra\gerar-dados.mjs` refaz o `Dados.lua` a partir de `dados\pregao\receitas-lw.json`.
