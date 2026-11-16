# PregaoForever: leia-me do dono

Data: 2026-11-16. Este texto é para você e se sustenta sozinho: diz o que é o addon, o que os fatos dizem hoje, o que você precisa decidir e o que acontece em seguida. O contrato que o agente usa para implementar é o `DESIGN.md`, na mesma pasta; nenhum código de addon foi escrito ainda.

## 1. O que é, em poucas linhas

O PregaoForever é um terminal de leilão em três peças. A régua é um livro que mede tudo o que você faz no leilão (cobre por ação, por hora e por estratégia, inclusive o que você faz pela tela da Blizzard) e troca cada estimativa sobre o jogo por número lido. A fila mostra até cinco linhas do que vale fazer agora com o ouro que existe. A mão executa, e só com a sua tecla: cada compra, postagem e cancelamento sai de uma tecla sua, uma por ação, depois de passar por um núcleo de risco chamado Cofre, que nega na dúvida.

O que ele nunca faz: agir sem tecla ou clique seu, fazer mais de uma ação por tecla, agir por temporizador ou repetir sozinho uma ação que falhou, simular entrada, evitar a marca de ausente, pegar correio, vender ou comprar no vendedor por código, ter configuração ou caixa de texto na tela, gravar ou mostrar nome de outro jogador, propor preço fora do mercado, ligar estratégia sem fonte que você aprovou, e mandar dado para fora do jogo. Um aviso sobre isso: o addon não envia nada e os arquivos de fora ficam na máquina, mas o relatório de sessão leva os números do seu banco à sessão do agente, que roda num serviço de nuvem.

## 2. O que os fatos dizem hoje

O seu capital é de 5 ouro, 9 prata e 12 cobre somando os quatro personagens, sem banco de conta. O addon só conta o ouro do personagem logado, então a banca de quem negocia é de cerca de 4 ouro se você reunir o ouro nele e mantiver 1 ouro de piso pessoal, e de cerca de 27 prata se não reunir. Com 4 ouro e no máximo metade em estoque, um giro a 10% ou 15% de margem líquida rende de 20 a 30 prata, antes de depósitos perdidos, e o ouro de cada venda demora cerca de 1 hora no correio. Dito sem rodeio: com 5 ouro o addon não deixa ninguém rico por trading. Ele vende melhor o que os seus personagens já produzem, mede o mercado e prova, com os seus números, se e quando comprar para revender paga. O que aperta é capital e giro, não tecla.

O mercado é um só para o conjunto de regras inteiro, com mais de 200 mil leilões numa varredura relatada, e os concorrentes já chegam com ferramenta. O TradeSkillMaster anuncia suporte ao Forever (em beta) e o ForeverFlip, um addon novo, lista varredura completa, sniper, postagem, cancelamento e contabilidade; os dois também dependem de uma tecla ou clique por ação, e enxergam mais mercado do que o nosso addon vai enxergar. Você já tem o Auctionator (com preço de cerca de 6.600 itens) e o ForeverGuide, que por padrão compartilha as suas varreduras.

Do cliente do jogo saem, lidos em arquivo: durações de 2, 8 e 24 horas, taxa de depósito 5 e taxa de corte 5 (a leitura provável é corte de 5% da venda e depósito de 5%, 20% e 60% do preço de vendedor conforme a duração; a Blizzard não publicou a fórmula). Fora do cliente, o anúncio da Blizzard diz que o depósito mínimo cai de 1 prata para 1 cobre na manutenção de 17/11, o que só o jogo confirma (comandos 8, 11 e 12). Três textos do próprio jogo respondem dúvidas antigas: cancelar um leilão perde o depósito, uma manutenção com atualização do leilão devolve o item antes da hora e também perde o depósito, e não é preciso cobrir o preço dos outros, porque o leilão postado depois, no mesmo preço, vende primeiro.

Só o jogo responde o resto, e por isso existe a sonda, um roteiro de medidas curtas: se a sua tecla, ligada a um botão do addon, satisfaz as funções de comprar e postar (ninguém testou no Forever; se não valer nem com o mouse, sobram a régua e a fila), quanto são o depósito e o corte de verdade, se a fatura do correio pode ser lida sem abrir a carta, quanto dura uma cotação e o que as letras do teclado fazem hoje.

## 3. Linha do tempo

As datas são o mais cedo possível e são hipótese, não compromisso: supõem uma etapa de código a cada 1 a 4 dias e você jogando todo dia. Entre a primeira postagem e a compra para revenda há uma espera que código não encurta, porque o addon precisa ver vendas e expirações reais.

| Degrau | O que o libera | Mais cedo possível (hipótese) |
|---|---|---|
| Ler e decidir | Este texto e as seis decisões da parte 5 | 16/11 |
| Preparação, sem código | Leilão aberto, comandos colados, depósito relido depois da manutenção | 16 a 18/11 |
| Régua em modo leitura | Contrato, bancada de testes, quadros aprovados por você e a versão que só mede | 20 a 22/11 |
| Construir a mão ou adotar ferramenta pronta | Três sessões medidas pela régua | 23 a 25/11 |
| Primeira postagem por tecla | Teste da tecla positivo no jogo, sua decisão de postar por tecla e os números de política aprovados | 25 a 28/11 |
| Primeira compra por tecla | Testes de compra, corte e devoluções medidos, duas sessões limpas, sua decisão de comprar por tecla e a sua aprovação da ideia de arrematar abaixo do preço que o vendedor paga, que não tem fonte | 28/11 a 2/12 |
| Compra para revenda, só em papel | Fotos repetidas do mercado e uma série densa de medida | começo de dezembro |
| Compra para revenda com ouro | 30 sinais de papel conclusivos, em 10 grupos de item e dia, com resultado positivo | não antes de meados de dezembro |
| Escala | Banca maior e os degraus de máquina descritos no contrato | depende da banca (parte 7) |

O ritmo de partida é de 10 operações por minuto, cerca de 5 minutos para uma bolsa cheia; não é teto fixo e sobe quando as sessões mostrarem que não há erro de dedo.

## 4. Primeiro dia

1. Ler este texto até o fim.
2. Decidir os seis pontos da tabela da parte 5. Quase todos têm padrão marcado; qual personagem compra, reunir ou não o ouro e a duração e o lote das sobras só você escolhe.
3. Anotar o ouro de cada personagem e, se decidir reunir, mandá-lo ao negociador pelo correio do jogo; os itens podem ir junto ou ser vendidos em cada personagem.
4. Se quiser ouro já, vender pela tela da Blizzard o que a parte 9 permite. O que paga depósito em item barato espera a manutenção de 17/11.
5. Abrir o leilão e colar o primeiro comando da sonda (os 16 estão no Apêndice A do `DESIGN.md`, prontos para colar). O jogo pergunta "Allow custom scripts?": responder Yes e colar o mesmo comando outra vez.
6. Colar os outros 15 comandos, um por vez, e guardar a resposta de cada um (captura de tela serve). Nenhum compra, posta ou cancela. O comando 16 pede um preparo, descrito junto dele: abrir antes, pela tela da Blizzard, a janela de compra de um material e cancelá-la depois de ler o número, sem comprar.
7. Abrir Options, Keybindings, e anotar o que as letras B, C, H, I, K, L, M, N, O, P, U e Y fazem hoje.
8. A partir do Acer, apertar F1 no jogo e dizer se o jogo reagiu.
9. Depois da manutenção de 17/11, repetir os três comandos que leem o depósito (os de número 8, 11 e 12).
10. Ver a primeira versão dos quadros das telas e do teclado e dizer o que mudar. A aprovação final dos quadros e o mapa de teclas fecham na etapa seguinte, com as medidas da sua tela.

## 5. As suas decisões

Estas seis precisam de resposta antes da primeira linha de código. O padrão é o que o agente grava se você só disser "pode seguir"; onde a tabela diz que não há padrão, o ponto fica em aberto até você escolher.

| Decisão | Padrão já marcado | O que muda se escolher o outro |
|---|---|---|
| Postar e cancelar por tecla (em 6/11 você proibiu, no outro addon, funções que gastam por código) | Sim, só neste addon, uma tecla por ação, dentro de tetos | Não: o addon fica em modo leitura, aponta e mede, e você age pela tela da Blizzard |
| Comprar por tecla | Sim, em dois tempos (uma tecla prepara, outra confirma), depois dos testes no jogo e só nas estratégias que você ligar | Só papel: ele registra o que compraria, sem gastar. Não: nenhuma tecla de compra |
| Fontes e regra de preço da venda | Ligar a venda dos verdes, a fonte que você já aprovou. Regra: igualar o menor preço, porque o texto do próprio jogo diz que não é preciso cobrir | Aprovar também os guias de fã para as sobras de coleta; cobrir por um cobre ou deixar folga. Enquanto a fonte das sobras, a duração e o tamanho do lote não forem escolhidos por você, a linha de material mostra PICK RULE, sem tecla |
| Negociador, ouro e piso | Um personagem compra (você diz qual) e todos vendem, cada um com os seus limites. Piso pessoal de 1 ouro em quem compra. Reunir ou não o ouro fica sem padrão: é escolha sua | Reunido, a banca é de cerca de 4 ouro; sem reunir, de cerca de 27 prata. Piso zero libera o quinto do capital que o piso deixa parado |
| Acesso remoto e os termos | Perguntar ao suporte por escrito antes de sessões longas, e deixar o Avell sem suspensão na tomada | Operar sem perguntar: não existe posição oficial sobre acesso remoto ao próprio PC |
| Reservas, o que não vai à venda porque alimenta as suas profissões | O agente propõe a lista a partir dos roteiros de profissão que você aprovou, e você aprova. Sem lista, toda sobra de coleta aparece como guardada | Uma lista sua, item a item |

Ficam para mais tarde, todas com padrão: o mapa de teclas (depois da sonda e dos quadros), o nome (fica PregaoForever, a menos que você peça outro antes de o código começar), a convivência com o Auctionator e o ForeverGuide, a mesa de fora do jogo, a credencial da API de dados, os números de política como tetos e margem mínima (antes de começar o código da postagem por tecla; são proposta do projeto, sem fonte, e você aprova, troca ou manda buscar fonte), construir ou adotar (parte 8), aprovar ou não a compra abaixo do preço que o vendedor paga, que não tem fonte (na etapa da compra), o gatilho da varredura, correio e vendedor por tecla, postar mais de uma unidade de um item por tecla, e a assinatura numérica de vendedor, que só interessa na escala.

## 6. As telas e as teclas

A janela é própria, fica ao lado do leilão da Blizzard e tem cinco visões. Itens e valores abaixo são ilustrativos; a página com os quadros renderizados fica em `pesquisa/telas/`, e é nela que você aprova o desenho. No cabeçalho, BUDGET (a banca) é a soma do que está livre, em estoque, em depósitos e no correio.

Next é a visão que abre, com a fila. "Pays if 1 in 5 sells" quer dizer que o leilão paga mais que o vendedor se uma em cada cinco postagens daquele tipo vender. PICK RULE marca um item de uma classe em que você ainda não escolheu regra, duração ou lote; a linha não tem tecla.

```
+- PregaoForever [F1 NEXT] F2 SELL F3 MINE F4 RISK F5 SESSION ---------------+
| BUDGET 4g 00s   FREE 3g 12s 86c   STOCK 64s   DEPOSITS 14c   IN MAIL 23s   |
| MODE LIVE   AT RISK 16% of budget   KEYS ON                                |
| PRICES 42s old, full read                              [L] look again      |
+----------------------------------------------------------------------------+
| NEXT (7)                                                                   |
| > POST    Bandit Cloak x1   24h  2s 00c     pays if 1 in 5 sells           |
|   POST    Copper Ore x20     8h  1s 08c ea  pays if 1 in 98 sells          |
|   BUY     Linen Cloth x16   9c ea   vendor pays 13c   +64c     PAPER       |
|   POST    Shadowfang x1     PICK RULE                                      |
|   VENDOR  Ruined Pelt x5    25c ea  auction pays less                      |
|   Show 2 more                                                              |
+----------------------------------------------------------------------------+
| TICKET  none             [P] post   [B] buy   [K] skip   [I] why           |
+----------------------------------------------------------------------------+
| L look   N next   U back   I why   O more   K skip   H hold                |
| P post   B buy    C cancel   Y yes   M never mind      last key: N         |
| LAST ALERT  SOLD Linen Bag x1 (19 min ago)                                 |
+----------------------------------------------------------------------------+
```

Sell mostra as bolsas. KEPT é o que está reservado, com o motivo; a última linha diz o que está nos outros personagens.

```
+- PregaoForever F1 NEXT [F2 SELL] F3 MINE F4 RISK F5 SESSION ---------------+
| BAGS TO SELL (6)       rule    price      time  deposit  your sales        |
| > Bandit Cloak x1      MATCH   2s 00c     24h   30c      4 of 10           |
|   Copper Ore x20       MATCH   1s 08c ea  8h    20c      no sales yet      |
|   Shadowfang x1        PICK RULE                                           |
|   Wolf Meat x7         VENDOR  3c ea      auction pays less                |
|   Ring of the Monkey   NO REFERENCE   vendor pays 45c   [I] deposits       |
|   Show 1 more                                                              |
+----------------------------------------------------------------------------+
| KEPT (2)   Light Leather x18: reserved for Leatherworking   Show 1 more    |
| ON OTHER CHARACTERS (3)   Peacebloom x40 on Rurik           Show 2 more    |
+----------------------------------------------------------------------------+
```

Mine mostra os seus leilões, só com fatos; não calcula ganho de cancelar, e STAND DOWN aparece quando a regra contra guerra de preço manda parar.

```
+- PregaoForever F1 NEXT F2 SELL [F3 MINE] F4 RISK F5 SESSION ---------------+
| MY AUCTIONS (5)   deposits at risk 14c   price      left    cheaper ahead  |
| > Tin Ore x20                            1s 76c ea  2-12h   340            |
|   Linen Bag x1                           SOLD   gold in about 41 min       |
|   Copper Bar x10                         90c ea     12h+    0   STAND DOWN |
|   Show 2 more                                                              |
+----------------------------------------------------------------------------+
| LIMITS   Tin Ore: 1 of 2 cancels (4h)      deposits lost today 3c of 8s    |
+----------------------------------------------------------------------------+
```

Risk mostra a banca, os três limites mais perto de estourar, as travas ligadas e o nível de cada estratégia. Vendor floor é a estratégia de arrematar abaixo do preço que o vendedor paga.

```
+- PregaoForever F1 NEXT F2 SELL F3 MINE [F4 RISK] F5 SESSION ---------------+
| BUDGET    4g 00s   personal floor 1g 00s   today +10s 75c                  |
+----------------------------------------------------------------------------+
| EXPOSURE  closest to the limit                                             |
|   cost in one item         38s of 40s                                      |
|   stock at price risk      64s of 2g 00s                                   |
|   deposits at risk         14c of 20s                                      |
|   Show 7 more                                                              |
+----------------------------------------------------------------------------+
| BREAKERS  all 11 clear                                                     |
+----------------------------------------------------------------------------+
| LICENCES  allowed / earned / in force                                      |
|   Sell greens     micro / micro / micro                                    |
|   Sell extras     micro / micro / micro                                    |
|   Vendor floor    paper / paper / paper    2 of 3 proof scans              |
|   Show 3 more                                                              |
+----------------------------------------------------------------------------+
```

Session fecha a sessão. OUTSIDE é o ouro que entrou ou saiu fora do leilão (quest, saque, conserto), registrado para não se confundir com trading.

```
+- PregaoForever F1 NEXT F2 SELL F3 MINE F4 RISK [F5 SESSION] ---------------+
| SESSION  1h 32m   actions 49 (post 21, buy 14, cancel 3,                   |
|          done in Blizzard UI 11)   unconfirmed 0                           |
| RESULT   realized +10s 75c   per action +22c   per hour +7s 01c            |
|          budget used 0.4 times                                             |
| OUTSIDE  +24s today (not trading)                                          |
| PACE     +32s a day (trade 8s, outside 24s)   applied 16% of budget        |
| BY PLAN  Sell greens +5s 80c (sold 2 of 5)   Sell extras -45c              |
|          Show 2 more                                                       |
| CHECKS   measured 7 of 12 game numbers                    Show 5 more      |
| STORAGE  1.7 MB of 3 MB     unsaved 49 actions, 52 min                     |
+----------------------------------------------------------------------------+
| TICKET   [Y] save now (reloads the interface)                              |
+----------------------------------------------------------------------------+
```

O mapa de teclas é proposta, e você decide depois que a sonda disser o que cada letra faz hoje, porque com a janela aberta a letra perde a função que tem no jogo. Uma tecla faz uma coisa só: P, B e C preparam (C sempre, e P até a sua decisão sobre o mapa), Y executa o bilhete, M desiste, K tira a linha da fila até o fim da sessão, N e U andam na lista, L faz uma rodada de consultas, H solta ou rearma as teclas de ação. Só valem com a janela do leilão aberta; no correio há apenas botões.

```
 [F1 NEXT] [F2 SELL] [F3 MINE] [F4 RISK] [F5 SESSION]

 [Q] [W] [E] [R] [T] [Y yes] [U back] [I why] [O more] [P post]
  [A] [S] [D] [F] [G] [H hold] [J] [K skip] [L look]
   [Z] [X] [C cancel] [V] [B buy] [N next] [M never mind]
```

## 7. A escada de capital

O modelo, em uma frase: a cada volta (comprar, vender e esperar o correio) o ouro aplicado cresce pela margem das vendas que deram certo menos a perda das que deram errado, e a cada dia entra o ouro que vem de fora do leilão. Tudo abaixo é hipótese, sem número medido, e nada é promessa nem conselho de como jogar. Os dias contam a partir do momento em que a compra para revenda estiver ligada com ouro, o que a linha do tempo não põe antes de meados de dezembro; até lá só as entradas de fora e a venda do seu próprio estoque mexem na banca. Eles partem dos 5 ouro e 9 prata de hoje, com o ouro reunido num personagem e piso pessoal de 1 ouro, e os degraus são de ouro total, não de banca. "Entradas de fora" é só uma grandeza que a régua mede: toda variação de ouro que não vem de compra para revenda, isto é, o ouro de quest, saque e conserto (que a tela Session chama de OUTSIDE) e também o da venda do que os seus personagens coletam.

| | Lento | Central | Pesado |
|---|---|---|---|
| Parte da banca aplicada | 25% | 50% | 50% |
| Margem líquida por volta | 10% | 12% | 15% |
| Lotes que fecham com lucro; perda nos outros | 60%; 8% | 70%; 6% | 80%; 5% |
| Sessão por dia; voltas por dia | 3 h; 1 | 6 h; 2 | 10 h; 5 |
| Entradas de fora por dia | 0,5 ouro | 1,5 ouro | 3 ouro |
| Dias até 15 ouro | 18 | 5 | 3 |
| Dias até 60 ouro | 79 | 18 | 6 |
| Dias até 250 ouro | 208 | 36 | 11 |
| Dias até 1.000 ouro | 381 | 57 | 17 |
| Dias até 60 ouro só com trading, sem entradas de fora | 383 | 42 | 10 |

O que mais pesa: até cerca de 60 ouro, as entradas de fora (no cenário central, tirá-las leva os 60 ouro de 18 para 42 dias, e nenhum outro número sozinho mexe tanto); de 60 ouro em diante, a taxa composta, que é o produto da parte aplicada, das voltas por dia e do ganho médio por volta (dobrar a parte aplicada ou as voltas dobra a taxa; o ganho médio sobe com a margem e com o acerto, mas não em proporção). As voltas têm teto físico, porque o correio demora cerca de 1 hora. O piso pessoal de 1 ouro quase não pesa, desde que o ouro esteja reunido. O topo depende de quanto o mercado absorve por item, que só a régua mede. O cenário pesado pede 80% de acerto e cinco voltas por dia durante semanas, e nenhuma fonte sustenta isso.

## 8. Construir ou adotar

Das três peças, a régua e a fila se justificam sozinhas. A régua, porque nenhuma fonte descreve ferramenta que meça por estratégia e por origem com um livro que o agente lê e devolve como configuração e relatório. A fila, porque junta as suas regras (nada configurado no jogo, até cinco linhas por seção, estratégia só com fonte aprovada), e a pesquisa não achou ferramenta que cumpra as três. As duas funcionam em modo leitura e custam pouco. A mão (postar, cancelar e comprar por tecla) é a parte cara e a que duplica o que já existe. O que a justifica são o núcleo de risco proporcional à banca, a regra de nunca repetir sozinha uma ação que ficou sem resposta, a prova em papel antes de gastar e o teclado pensado para acesso remoto. Render mais ouro não é justificativa: as ferramentas prontas enxergam mais mercado.

Por isso a decisão sai com número, no fim da etapa da régua, antes de construir a mão: você compara três sessões pela tela da Blizzard com, se quiser testar, três por uma ferramenta pronta. Se a pronta render mais por ação sem ferir nenhuma regra sua, o projeto fica em régua e fila. A favor de construir: o ForeverFlip tem dias de vida e está em beta, ninguém sabe quais módulos do TradeSkillMaster funcionam no Forever, e adotar também é aposta, sem Cofre.

## 9. O que dá para fazer já pela tela da Blizzard

Cada linha é o que a fonte diz, não opinião do agente. Só as duas primeiras vêm da fonte que você já aprovou; as marcadas "pede aprovação" vêm de guias de fã ou comerciais, vários do beta, e só valem depois do seu sim.

| O que fazer | Fonte | Situação |
|---|---|---|
| Vender no leilão os verdes bons; em equipamento, igualar o menor preço, porque postar abaixo dele dá erro | Vídeo do Studen Albatroz (base de fatos 4.5); erro relatado (base 1.11) | Fonte aprovada |
| Não vender todo o couro | Vídeo do Studen Albatroz (base 4.5) | Fonte aprovada |
| Esperar a manutenção de 17/11 para postar item barato e ler o depósito na aba de venda antes de postar | Anúncio da Blizzard (base 1.7) | Fato do jogo, a conferir na hora |
| Vender cru o que os coletores trazem, em vez de fabricar; entre 7 e 12/11 o preço listado de Copper Ore subiu 41% e o de Light Leather, 19% | Guia de ouro do beta (relatório R8b) e site de preços que vende ouro (relatório R5b) | Pede aprovação |
| Nunca listar abaixo do preço de vendedor, e olhar o leilão antes de vender ao vendedor um item fabricado | Guia de ouro (R8b); correção de preços da Blizzard (base 6.3) | Pede aprovação |
| Postar em lotes e rechecar a cada sessão; leilão curto para o que gira; guardar para o leilão todo azul que vincula ao equipar | Guia de ouro do beta (R8b), editorial, sem dado | Pede aprovação |
| Usar o Auctionator para ver o último menor preço; postar pela tela da Blizzard | Base 7.1 e 4.3 | Leitura, sem risco |
| Desligar no ForeverGuide o compartilhamento das varreduras, pelo script do projeto, com o jogo fechado | Base 7.3 | Sua decisão; é privacidade, não ouro |

O que você vender assim, anotando preço, duração e desfecho, já vira amostra para a régua.

## 10. Glossário e onde está o resto

| Termo | Sentido |
|---|---|
| Régua | O livro de ações, lotes e sessões, e as medidas que saem dele |
| Fila | Até cinco linhas do que vale fazer agora |
| Mão | A parte que executa, só por tecla sua |
| Cofre | O núcleo de risco, um por personagem, que autoriza ou nega cada ordem |
| Banca e piso pessoal | O ouro que o addon pode arriscar no personagem logado, e o ouro em que ele não toca |
| Bilhete | O resumo de uma ordem, mostrado antes da tecla que a executa |
| Fôlego | Uma rodada limitada de consultas ao leilão, aberta por uma tecla sua |
| Papel | Sinal registrado sem gastar ouro, para provar uma estratégia antes de ligá-la |
| Sonda | O roteiro de medidas feitas no jogo |
| Commodity | Item empilhável que o leilão vende por quantidade, como minério e tecido |

O resto está em três lugares. O `DESIGN.md` é o contrato do agente, com as regras, as hipóteses a medir, o motor, os riscos, os testes, as etapas de entrega e a tabela completa das decisões. O `MUDANCAS.md` lista os 169 pontos levantados na revisão e onde cada correção ficou. A pasta `pesquisa/` guarda a base de fatos e os relatórios.
