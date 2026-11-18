# CompraForever 0.1.0

Um fluxo só: na AH, clicar Scan e seguir o botão grande. O painel diz quanto comprar de cada material, com o dinheiro e
o espaço de bolsa que você tem agora, para craftar receitas de Leatherworking que você conhece e vender no vendedor
com lucro. Substitui o PregaoForever, que saiu do jogo em 2026-11-17 (o código continua no git).

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

## Para desfazer

Com o jogo fechado: `powershell -NoProfile -ExecutionPolicy Bypass -File ferramentas\dev-link.ps1 -Pasta addons-proprios\CompraForever -Remover -Aplicar`.
Para voltar o PregaoForever: o mesmo comando com `-Pasta addons-proprios\PregaoForever`, sem `-Remover`.

Contrato técnico: `CONTRATO.md`. Bancada: `node ferramentas\guia\pregao\bancada-pregao.mjs --addon addons-proprios\CompraForever --cenarios compra`.
Dados: `node ferramentas\compra\gerar-dados.mjs` refaz o `Dados.lua` a partir de `dados\pregao\receitas-lw.json`.
