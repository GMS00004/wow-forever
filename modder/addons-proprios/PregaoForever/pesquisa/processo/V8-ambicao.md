> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# V8-ambicao: parecer pela lente "ambição e realismo"

Data: 2026-11-16. Revisor V8. Li por inteiro o design (`SINTESE.v1.md`, 934 linhas), a base de fatos, o parecer J2, os relatórios R5b, R6a, R8a e R8b, e do R9 as seções 2, 5, 6, 7 e 10. Dos seis projetos li a tese, o escopo e as partes de vazão, fase 3 e marcos de banca. Não li código de addon de terceiro, nem os relatórios vetados, nem os pareceres dos outros revisores. As contas estão em `<tmp>/V8-ambicao/escada.mjs` e a saída vai citada no item 2.

Como ler: "linha N" é a linha do `SINTESE.v1.md`. "Script" é a saída do `escada.mjs`. Todo número de cenário é hipótese, e está marcado.

**Resposta curta à pergunta da lente.** O design serve ao dono como fundação e não serve como resposta ao pedido. A fundação está certa: nada age sem tecla, o risco é proporcional à banca, e o que não se sabe é medido antes de gastar. Mas o dono pediu day trading pesado e o extremo, e o documento para exatamente onde isso começaria: a fase 3 é uma linha, não há escada de capital, e quatro escolhas da síntese (tetos de vazão duros, um fôlego por tecla, marco de 15 ouro, esquema de banco para 40 chaves) fecham a porta do modo pesado sem que o dono tenha decidido isso. Não achei nada bloqueante: nada no design é perigoso para o ouro dele. Achei 13 pontos importantes e 3 menores.

## Item 1. A tese está certa para a situação dele?

**O que conferi.** A seção 0 e a 3.1 contra a base 1.2 (mega-reino, mais de 200 mil leilões), 4.1 (50.912 cobre somando quatro personagens), 5.1 a 5.3 (TSM 4.15, ForeverFlip e os demais) e 6.1 (queda de 41% na mediana), mais o R5b 2a a 2c e o J2 seção 0. Refiz a aritmética da frase "50 a 75 prata por giro" com as regras do próprio Cofre.

**Onde a tese está certa.**

1. Com 5 ouro o que aperta é capital e giro. A conta confirma: no primeiro dia, o trading rende de 3 a 112 prata por dia nos três cenários do item 2, ou de 1 a 11 prata por hora de sessão. Nenhuma interface muda essa ordem de grandeza.
2. Vender o que os personagens produzem vem antes de comprar para revender. É a única linha com fonte aprovada (base 4.5) e a única em que só o depósito fica em risco.
3. Não supor deflação geral. A leitura do R5b 2a (materiais de nível baixo subindo na semana em que a mediana caiu) está correta e é mais fiel que o resumo da base 6.1.
4. Dizer ao dono, sem rodeio, que 5 ouro não enriquecem por trading. A frase é verdadeira. O defeito é parar nela (achado V8-10).

**Onde a síntese é tímida demais.** Em cada conflito entre os projetos ela ficou com o valor mais conservador e depois o congelou.

| Ponto | O que a síntese fez | O que os projetos propunham | Achado |
|---|---|---|---|
| Fase 3 | uma linha: "Novo design" (linha 796) | D1, D3, D4 e D6 listam o conteúdo; nenhum desenha a máquina | V8-01 |
| Buscas por minuto | 30, teto duro em `Tetos.lua` (linha 502) | D1: 60; D3: 40; limite documentado: 100 (base 2.2) | V8-02 |
| Ações por minuto | 10, teto duro (linha 502) | D6: 20; D2: meta de 6 a 10, a medir | V8-02 |
| Gatilho da varredura | uma tecla por fôlego de 20 buscas (linha 240) | D1 e D2: presença de 90 s; J1: fôlego que qualquer tecla renova | V8-03 |
| Compra para revenda | banca de 15 ouro, além do portão de papel (linhas 131 e 795) | só o D5 tinha o marco, sem derivação | V8-06 |
| Banco | 40 chaves de foco, 48 fotos por chave (linha 290) | D1: cerca de 150 itens em foco (D1 1.4) | V8-12 |
| Construir contra adotar | decidir na onda 6 (linha 819) | D5: adotar hoje o que existe e medir | V8-11 |

Nenhuma dessas escolhas é exigida pelas regras do dono. A regra 1 fala de compra, lance, postagem e cancelamento, um por tecla. Ela não fala de consultas nem de ritmo, e a base 8.2 diz que a varredura que se repete com o dono presente é questão de política sem resposta em nenhuma fonte.

**Onde a síntese é otimista demais.**

1. **O número de cabeçalho.** "Um giro completo da banca a 10% ou 15% de margem rende de 50 a 75 prata" (linha 13) usa os 5 ouro somados dos quatro personagens. Pelas regras do próprio design (banca do personagem logado, piso de 1 ouro, teto de 50% em estoque), um giro aplica cerca de 2 ouro e rende de 20 a 31 prata se o dono reunir o ouro à mão, e de 1 a 2 prata se não reunir (script; achado V8-07).
2. **O portão de papel.** O design supõe que 30 sinais de papel fecham em cerca de 5 dias. A venda de papel só conta por venda inferida entre duas fotos da mesma chave, e a chave com ordem de papel aberta nem está na ordem do foco (linha 226). O R9 2.1 mede a subcontagem em quase metade com 30 minutos entre fotos e 60% com 60 minutos (achado V8-04).
3. **A linha de ganho número 1 em quatro personagens.** O addon fica em leitura em três dos quatro (linha 811) e os tetos de depósito são fração de uma banca que pode ser quase zero (achado V8-08).
4. **A conciliação num personagem que joga.** Recompensa de quest, conserto e treino mexem no ouro com o leilão fechado; o Livro não tem registro para isso (achado V8-09).
5. **O `vao` como estratégia da fase 2.** O teste da 7.4 pede preço de saída de 1,37 vez o preço pago, em até 2 degraus de uma commodity, num mercado de 200 mil leilões. A 3.2 escreve 1,21. Quantos vãos assim existem ninguém contou, e a onda 2 poderia contar de graça (achado V8-05).

## Item 2. Escada de capital

**O modelo.** Por dia de jogo, com uma sessão:

```
voltas   = max(1, piso(horas de sessao / (entrega da compra + tempo ate vender + correio da venda)))
borda    = acerto * margem - (1 - acerto) * perda          por unidade de ouro aplicado, por volta
por volta:  ouro = ouro + fracao * (ouro - piso pessoal) * borda
por dia:    ouro = ouro + entradas de fora
```

`fracao` é a parte da banca aplicada (o teto duro do design é 50%). `margem` é o ganho líquido de corte e depósito quando o lote fecha com lucro, e `perda` é o que se perde quando não fecha. `acerto` é a fração de lotes com lucro. O correio da venda entra com cerca de 1 hora (base 1.8). `entradas de fora` é o ouro que não vem do trading: quest, saque e a venda do que os personagens coletam. Os cinco são números que a régua do addon mede; nenhum tem valor medido hoje.

**Os três cenários, todos hipótese.**

| Parâmetro | C1 lento | C2 central | C3 pesado |
|---|---|---|---|
| Fração aplicada | 0,25 | 0,50 | 0,50 |
| Margem líquida por volta | 10% | 12% | 15% |
| Acerto; perda no erro | 60%; 8% | 70%; 6% | 80%; 5% |
| Sessão; duração da volta | 3 h; 8 h | 6 h; 2,75 h | 10 h; 2 h |
| Voltas por dia | 1 | 2 | 5 |
| Entradas de fora | 0,5 ouro por dia | 1,5 ouro por dia | 3 ouro por dia |
| Borda por volta | 2,8% | 6,6% | 11,0% |
| Crescimento do trading por dia, sobre a banca | 0,7% | 6,6% | 27,5% |

**Dias de jogo de 5,09 ouro até cada degrau** (saída do script):

| Cenário e variante | 15 ouro | 60 ouro | 250 ouro | 1.000 ouro |
|---|---|---|---|---|
| C1, trading mais entradas de fora | 18 | 79 | 208 | 381 |
| C1, só trading | 177 | 383 | 589 | 789 |
| C1, só entradas de fora | 20 | 110 | 490 | 1.990 |
| C1, como escrito (compra só depois do dia 14 e de 15 ouro) | 20 | 81 | 210 | 383 |
| C2, trading mais entradas de fora | 5 | 18 | 36 | 57 |
| C2, só trading | 19 | 42 | 64 | 85 |
| C2, só entradas de fora | 7 | 37 | 164 | 664 |
| C2, como escrito | 7 | 23 | 41 | 62 |
| C2, com absorção de 50 ouro por volta | 5 | 18 | 42 | 135 |
| C3, trading mais entradas de fora | 3 | 6 | 11 | 17 |
| C3, só trading | 5 | 10 | 16 | 21 |
| C3, só entradas de fora | 4 | 19 | 82 | 332 |
| C3, como escrito | 4 | 15 | 20 | 25 |
| C3, com absorção de 50 ouro por volta | 3 | 6 | 13 | 38 |

"Como escrito" aplica o que o design manda hoje: nenhuma compra para revenda antes do portão de papel (pus o dia 14, que é hipótese minha para ondas 1 a 5 mais 5 dias de papel) e antes de 15 ouro. "Absorção" limita a 50 ouro o que o mercado aceita por volta, também hipótese.

Trecho da saída do script:

```
== C2 central (HIPOTESE) ==
  fracao aplicada 0.5  margem liquida 0.12  acerto 0.7  perda no erro 0.06
  sessao 6 h  ciclo 2.75 h  voltas/dia 2  entradas de fora 1.5 ouro/dia  piso 1 ouro
  borda por volta 6.60% do aplicado; crescimento do trading 6.60% ao dia sobre (ouro - piso); acerto de empate 33%
  banca de virada (ganho diario do trading = entradas de fora): 23.7 ouro
  trading no dia 1: 27.0 prata/dia = 4.5 prata por hora de sessao
  variante                                                      15     60    250   1000   (dias)
  a) trading + entradas de fora                                  5     18     36     57
  b) so trading (entradas = 0)                                  19     42     64     85
  c) so entradas de fora (sem trading)                           7     37    164    664
  d) como escrito: compra so apos dia 14 e 15 ouro               7     23     41     62
  e) (a) com absorcao de 50 ouro por volta                       5     18     42    135
  f) (a) sem consolidar: parte de 1,27 ouro no negociador        8     20     39     59
  parte do ganho que veio do trading em (a)                    26%    54%    78%    92%

== SENSIBILIDADE no C2 central: dias ate 60 e ate 250 ouro, mudando UM parametro ==
  base                                         60:    18   250:    36
  voltas/dia 1 (ciclo de 6 h)                  60:    23   250:    55   (voltas 1, taxa 3.3%/dia)
  voltas/dia 4 (ciclo de 1,5 h)                60:    12   250:    23   (voltas 4, taxa 13.2%/dia)
  fracao aplicada 0,25                         60:    23   250:    55   (voltas 2, taxa 3.3%/dia)
  margem liquida 0,06                          60:    26   250:    65   (voltas 2, taxa 2.4%/dia)
  margem liquida 0,18                          60:    14   250:    26   (voltas 2, taxa 10.8%/dia)
  acerto 0,50                                  60:    24   250:    58   (voltas 2, taxa 3.0%/dia)
  acerto 0,90                                  60:    14   250:    27   (voltas 2, taxa 10.2%/dia)
  perda no erro 0,12                           60:    20   250:    44   (voltas 2, taxa 4.8%/dia)
  entradas de fora 0 (so trading)              60:    42   250:    64   (voltas 2, taxa 6.6%/dia)
  entradas de fora 0,5 ouro/dia                60:    27   250:    48   (voltas 2, taxa 6.6%/dia)
  entradas de fora 3 ouro/dia                  60:    12   250:    28   (voltas 2, taxa 6.6%/dia)
  entradas de fora 6 ouro/dia                  60:     8   250:    20   (voltas 2, taxa 6.6%/dia)
  piso pessoal 0 em vez de 1 ouro              60:    17   250:    36

== OURO POR HORA DE SESSAO SO DO TRADING, por degrau (HIPOTESE) ==
  banca        C1 lento    C2 central    C3 pesado
     5.09       0.01          0.04          0.11   ouro/h
       15       0.03          0.15          0.39   ouro/h
       60       0.14          0.65          1.62   ouro/h
      250       0.58          2.74          6.85   ouro/h
     1000       2.33         10.99         27.47   ouro/h
```

**O que mais pesa.**

1. **Até cerca de 60 ouro, o ouro de fora.** No C2, tirar as entradas de fora leva o degrau de 60 ouro de 18 para 42 dias; nenhum outro parâmetro sozinho mexe tanto. A "banca de virada", em que o trading de um dia iguala as entradas de fora, é de 72 ouro no C1, 24 no C2 e 12 no C3. Abaixo dela, a escada sobe pelo que os personagens produzem e ganham jogando. A régua do design não mede esse termo (achado V8-09).
2. **De 60 ouro em diante, a taxa composta**, que é o produto de quatro fatores de mesmo peso: fração aplicada, voltas por dia, margem e acerto. Dobrar qualquer um dobra a taxa. No C2, uma volta por dia em vez de duas leva o degrau de 250 ouro de 36 para 55 dias, e o mesmo acontece com a fração aplicada de 0,25.
3. **As voltas por dia têm teto físico.** O correio de cerca de 1 hora limita a uma volta por hora, por melhor que seja a interface. Sessão longa compra voltas: 12 horas dão 4 voltas no C2. É aqui que a sessão "igual psicopata" paga, e só aqui.
4. **O marco de 15 ouro custa dias.** No C2 atrasa os 60 ouro de 18 para 23 dias, e no C3 de 6 para 15.
5. **O piso pessoal de 1 ouro quase não pesa** (17 contra 18 dias), desde que o ouro esteja reunido. Sem reunir, o piso zera a banca.
6. **O topo depende do que o mercado absorve.** Com teto de 50 ouro por volta, os 1.000 ouro do C2 passam de 57 para 135 dias. Só a régua mede a absorção.

Uma comparação que o dono merece ver, com a ressalva escrita: o R5b 2c traz a única estimativa de ouro por hora dos relatórios, de um site que vende ouro, da beta e sem medida: 3 a 10 ouro por hora de farm no nível 20 a 30. Pela aritmética acima, o trading só passa de 3 ouro por hora de sessão com banca acima de 110 ouro no C3 e de 274 ouro no C2. Não é conselho de gameplay: é a conta que a régua vai refazer com os números dele, e é o critério que o risco 2 do design já usa (linha 824).

Nada aqui é promessa. O C3 pede 80% de acerto, 15% líquidos e cinco voltas por dia durante semanas, e nenhuma fonte dos relatórios sustenta isso.

## Item 3. O que é day trading pesado em cada degrau, e se a arquitetura aguenta

**O que conferi.** Calculei a carga de uma volta em cada degrau com os tetos do próprio design (50% da banca em estoque, 20% por item, 10 ações e 30 buscas por minuto, fôlego de 20 buscas) e com a cadência de vigília que o R9 2.2 pede para a venda inferida (uma foto a cada 5 minutos num item de 30 unidades por hora). A incógnita é a absorção: quanto ouro um item aceita por volta sem mover o preço. Usei dois valores, 1 e 5 ouro, ambos hipótese; o design a limita a 10% do volume diário medido (linha 501).

Por item e por volta contei 3 chamadas de ação (cotar, confirmar, postar) e 6 teclas (`N`, `B` que relê, `B` que cota, `Y`, `N`, `P`). Saída do script:

| Banca | Aplicado | Itens (absorção 1 / 5) | Ações por volta | Minutos no teto de 10 por minuto | Teclas por volta | Buscas por minuto de vigília | Teclas `L` por passada |
|---|---|---|---|---|---|---|---|
| 5 | 2,0 | 3 / 3 | 9 | 0,9 | 18 | 0,6 | 1 |
| 15 | 7,0 | 7 / 3 | 21 / 9 | 2,1 / 0,9 | 42 / 18 | 1,4 / 0,6 | 1 |
| 60 | 29,5 | 30 / 6 | 90 / 18 | 9,0 / 1,8 | 180 / 36 | 6,0 / 1,2 | 2 / 1 |
| 250 | 124,5 | 125 / 25 | 375 / 75 | 37,5 / 7,5 | 750 / 150 | 25,0 / 5,0 | 7 / 2 |
| 1.000 | 499,5 | 500 / 100 | 1.500 / 300 | 150 / 30 | 3.000 / 600 | 100 / 20 | 25 / 5 |

**Leitura por degrau.**

- **5 a 15 ouro.** Três itens, 9 ações por volta. Não é day trading: é esperar o correio. A máquina sobra, e o que aperta é o capital. O addon precisa do que as fases 1 e 2 já têm.
- **15 a 60 ouro.** De 3 a 30 itens, até 90 ações por volta (9 minutos no teto) e 6 buscas por minuto de vigília. O design aguenta, com duas condições: as chaves com posição aberta entram no foco (achado V8-04) e o foco pode passar de 20 chaves.
- **60 a 250 ouro.** De 25 a 125 itens, 75 a 375 ações por volta. O teto de 10 ações por minuto come de 7 a 37 minutos de uma volta que o correio limita a cerca de 60. A vigília pede de 5 a 25 buscas por minuto, contra o teto de 30, e de 2 a 7 teclas `L` por passada. É aqui que o day trading fica pesado e é aqui que os tetos do design passam a mandar. Coincide com o marco de 60 ouro que o próprio design dá à fase 3.
- **250 a 1.000 ouro.** Com absorção de 1 ouro por item não fecha: 500 itens são 150 minutos de ações por volta e 100 buscas por minuto, o limite documentado inteiro (base 2.2). A carteira satura em cerca de 150 chaves a 30 buscas por minuto e em 500 a 100. O degrau de cima só existe com lote maior por item, em commodity líquida, e isso é a absorção que a régua tem de medir antes.

**O que o modo pesado pede do addon.**

| Capacidade | O que o design tem | O que falta |
|---|---|---|
| Vazão de ações | uma tecla por ação, `T_ver`, teto duro de 10 por minuto | ritmo no `Config.lua`, subindo por portão medido (V8-02) |
| Buscas por minuto | 30, teto duro; uma em voo | o mesmo; a S4 mede o sustentável (V8-02) |
| Itens em foco | até 20 por fôlego; anel para 40 chaves | foco em anéis (quente, morno, frio), tamanho no `Config.lua`; banco para 150 (V8-12) |
| Vigília contínua | uma tecla `L` por fôlego de 60 s; opção de renovar até 180 s | decisão própria do dono sobre o gatilho; renovação com orçamento definido (V8-03) |
| Carteira de muitos itens | tetos por item e total; lotes por ordem de entrada | tabela de posições por item com idade e conselho; teto por categoria (R9 7.3) |
| Postar muitos lotes | uma tecla por lote, linha a linha | regra do cursor depois da ação; contador `POST 12 of 37` (V8-13) |
| Cancelar muitos leilões | uma tecla por leilão, agrupados no fim | a mesma regra do cursor; G1 e G2 já limitam |
| Reposição | não existe | rótulo `RESTOCK`: item vendido volta à fila de compra só se o sinal passar de novo na foto fresca |
| Correio em escala | só leitura; o dono clica no Open All da Blizzard | nada novo; rever a DD1c com a sonda na mão |

**A arquitetura aguenta sem ser refeita?** A espinha aguenta, e é mérito dela. `Pedidos.lua` como porta única das consultas, `Acoes.lua` como único arquivo que age, tetos de dinheiro em fração da banca (crescem sozinhos com ela), motor em arquivos puros, licença por estratégia e fila que troca de ordenação quando a banca cresce: nada disso muda no modo pesado. O que não aguenta são cinco escolhas pontuais, todas baratas de corrigir agora e caras depois:

1. Ritmo de ações e de buscas como teto duro em `Tetos.lua` (V8-02).
2. Gatilho da vigília fixado como invariante I9, com renovação ambígua (V8-03).
3. Esquema do banco sem bloco de 4 horas, sem agregado de venda inferida e dimensionado para 40 chaves (V8-12).
4. Regra do cursor depois da ação, que decide se o lote custa uma tecla ou duas (V8-13).
5. "Até 20 chaves por fôlego" escrito como número no texto da 5.1, e não como parâmetro do `Config.lua`.

**O que prever já, para não fechar a porta.** Além dos cinco pontos: o registro "Fora" e os parâmetros da escada na régua (V8-09, V8-10), porque a fase 3 decide pelo que as fases 1 e 2 mediram; a contagem passiva de sinais desde a onda 2 (V8-05); e o campo `motivo` em cada linha da fila (por exemplo `RESTOCK`, `AGED`, `NEW`), que custa uma coluna e evita reescrever `Telas.lua`.

## Item 4. A fase 3 que deveria estar neste documento

**O que conferi.** A linha da onda 6 (linha 796), a DD12 (linha 819), o escopo de fase 3 dos projetos D1, D3, D4, D5 e D6, e o R9 7.3 e 7.4. Nenhum dos seis projetos desenhou a máquina de escala: todos listam conteúdo (conversão, sazonalidade, dados externos). A síntese herdou a lista e a encolheu para "Novo design".

**O que falta para merecer o nome de extremo.** Não é estratégia nova, que só entraria sem fonte. É a máquina que deixa as estratégias já licenciadas rodarem com muitos itens e muito ouro; as medidas que dizem quando a máquina é o gargalo; e os portões que a soltam aos poucos. O texto abaixo é o que proponho inserir como seção 17.1. Os números são de partida, do `Config.lua`.

> ### 17.1 Fase 3: a mesa em escala
>
> A fase 3 não cria estratégia. Toda estratégia continua nascendo com licença 0, com fonte aprovada pelo dono, e subindo pelo portão da seção 3.3. O que a fase 3 acrescenta é a máquina que opera muitos itens e muito ouro sem mudar nenhuma regra da seção 1: cada ação sai de uma tecla do dono, uma por ação; nada age por timer ou evento; nada se configura no jogo.
>
> **O gargalo medido.** A cada sessão, a régua classifica o que limitou o resultado. A máquina só cresce no ponto que aperta.
>
> | Gargalo | Como a régua o reconhece | O que fazer |
> |---|---|---|
> | Capital | banca livre média abaixo de 20% da banca, com linhas executáveis na fila | nada a construir: a escada está subindo |
> | Sinal | banca livre acima de 50% e fila de compra vazia em mais da metade dos fôlegos | ampliar a vigília (mais chaves em foco) |
> | Vazão | linhas executáveis que venceram sem tecla, com banca livre | subir o ritmo e ligar as esteiras |
> | Giro | estoque com idade acima de 2 vezes o tempo de venda medido | rever preço e saída da estratégia, não a máquina |
>
> **Degraus.** O degrau em vigor vem do `Config.lua`, escrito pelo agente depois do sim do dono. Dentro do jogo ele só desce.
>
> | Degrau | Banca de referência | Chaves em foco | Ritmo (ações; buscas por minuto) | Abre com |
> |---|---|---|---|---|
> | D0 | abaixo de 15 ouro | 20 | 10; 30 | fases 1 e 2 |
> | D1 | 15 a 60 ouro | 40 | 10; 30 | banca acima de 15 ouro em 3 aberturas seguidas; 5 sessões com conciliação exata |
> | D2 | 60 a 250 ouro | 150 | 15; 60 | uma estratégia de compra em plena; gargalo de sinal ou de vazão em 3 de 5 sessões; portões de máquina cumpridos |
> | D3 | acima de 250 ouro | até 500 | 20; até 100 | absorção medida por item; tempo de `/reload` medido com o banco do degrau; gargalo de sinal ou de vazão em 3 de 5 sessões |
>
> **Vigília.** O foco passa a ter três anéis. Quente: chaves com posição, leilão próprio ou ordem de papel aberta, relidas em todo ciclo. Morno: candidatas da triagem, em rodízio. Frio: só o resumo. A cadência de cada chave quente é o intervalo do R9 2.2, calculado da taxa de venda medida, dentro do orçamento de buscas. O gatilho é o da decisão DD13. A linha de estado mostra `WATCH 84 keys   cycle 4m 10s   22 of 30 searches a min`. Sem tecla do dono dentro do prazo do gatilho, a vigília para e a tela diz `PAUSED`.
>
> **Carteira.** O Cofre ganha a tabela de posições: por item, quantidade, custo, valor de saída conservador, idade e teto. Entra o teto por categoria (R9 7.3), porque patch e abertura de raide atingem a categoria inteira. Lote com idade acima de 2 vezes o tempo de venda medido vira linha de conselho (`REPRICE`, `LET EXPIRE` ou `VENDOR`), cada um com a sua tecla; nada é liquidado sozinho.
>
> **Esteira de postagem e de cancelamento.** A lista de lotes a postar, ou de leilões a cancelar, com um contador (`POST 12 of 37`). Uma tecla por lote: a linha concluída sai, a seguinte sobe para a posição do cursor e `T_ver` recomeça. Cada linha passa pelo Cofre. A esteira para no primeiro `FAILED` ou `UNKNOWN`. G1 e G2 valem por item.
>
> **Reposição.** Quando um lote vende, o item volta como candidato com o rótulo `RESTOCK`. Só vira linha de compra se o sinal passar de novo no teste da 7.4, com foto fresca. Não existe recompra automática.
>
> **Conversão** (R8a ficha 6; R9 5.5). `Receitas.lua`, só receita que o personagem logado conhece e produto que não vincula. O custo recursivo é ideia pública (base 5.8) e roda na mesa. Nasce em papel; o rendimento de cada receita é medido em 10 execuções do dono antes de qualquer sinal.
>
> **Hora e dia** (R8b ficha 1; base 6.5). Com três semanas do campo `blocos`, a mesa mostra o fator de cada bloco de 4 horas com intervalo de confiança. Só aparece na tela, como uma linha no conselho de postagem, o bloco cujo intervalo exclui 1. Não vira ordem de compra sem fonte aprovada.
>
> **Dados externos e varredura completa.** Decisões DD8 e, para `ReplicateItems`, só depois de um passo de sonda próprio (base 2.5).
>
> **Banco.** Tabela de tamanho por degrau (40, 150 e 500 chaves). Dentro da sessão, as fotos viram agregados em `blocos` e `giro`, para o anel girar sem perder a medida. O teto do banco de cada degrau só vale depois de medido o `/reload` com aquele tamanho (H-19). Mesa na opção B a partir do D2.
>
> **Portões de máquina.** São separados das licenças de estratégia. Cada subida é uma linha no `Config.lua`, com data.
>
> | O que sobe | Exige |
> |---|---|
> | Ações por minuto, de 10 para 15 e para 20 | 5 sessões sem INCERTO pendente; nenhum evento `_DROPPED`; ação desfeita em menos de 60 s (postar e cancelar o mesmo lote) abaixo de 1% das ações |
> | Buscas por minuto, de 30 para 60 e para 100 | a S4 repetida no novo ritmo, por 10 minutos, sem `TRAVADO` e sem `_DROPPED`; nunca acima do limite documentado (base 2.2) |
> | Chaves em foco | banco dentro do teto do degrau; `/reload` medido; ciclo da vigília dentro do intervalo pedido pelas chaves quentes |
> | Gatilho da vigília | só pela decisão DD13 |
>
> **Para se.** Três sessões no degrau com cobre por hora de trading abaixo do que o dono declara ganhar jogando: não sobe de degrau. Taxa de "já sumiu" acima de 70% com a vigília do D2: a vigília não paga e o foco volta a 40 chaves. A régua mostrar que uma ferramenta pronta rende mais por ação do que a fila própria: vale a decisão DD12.
>
> **O que a fase 3 continua recusando.** Tudo o que a seção 15 recusa. Reset, formação de mercado, lance e casa neutra seguem fora enquanto não houver fonte aprovada.

Junto com o texto, três edições pequenas: na linha da onda 6, trocar "Novo design" por "Seção 17.1"; na DD12, trocar "Fase 3: construir, adotar ferramenta pronta ou parar" por "Subir de degrau (seção 17.1), adotar ferramenta pronta ou parar"; e na lista final "Continua aberto", trocar "o que fazer quando a banca chegar a 60 ouro" por "a absorção por item, que decide se o degrau D3 existe".

## Item 5. O que o dono pode fazer já, sem addon novo

**O que conferi.** Cada item abaixo contra o R8a, o R8b, o R5b ou a base. O que não tem fonte nesses arquivos ficou de fora. Só o item 1 e o item 2 vêm da fonte que o dono já aprovou (base 4.5). Os demais vêm de guias de fã ou comerciais, vários da beta, e pela regra de gameplay do projeto só valem depois que ele aprovar a fonte (DD3). Não são conselho meu: são o que as fontes dizem.

| # | O que fazer | Com o quê | Fonte | Situação |
|---|---|---|---|---|
| 1 | Vender no leilão os verdes bons. Em equipamento, igualar o menor preço, porque postar abaixo dele dá "Internal Auction Error". | Tela de venda da Blizzard | Base 4.5 (vídeo do Studen Albatroz); base 1.11 | Fonte aprovada |
| 2 | Não vender todo o couro. | — | Base 4.5 | Fonte aprovada |
| 3 | Esperar a manutenção de 17/11 para postar item barato, e ler o depósito na aba de venda antes de postar. O depósito mínimo cai de 1 prata para 1 cobre. | Tela de venda da Blizzard | Base 1.7; R5b 2f (a data aparece como 17 ou 18, conforme a fonte); R8b incógnita 1 | Fato do jogo, a conferir na hora |
| 4 | Vender cru o que os coletores trazem (minério, erva, couro), em vez de fabricar. Entre 7 e 12/11, Copper Ore subiu 41%, Copper Bar 93%, Peacebloom 80%, Earthroot 73% e Light Leather 19%, em preço listado. | Tela da Blizzard; preço do Auctionator | R8b R4 e ficha 2 (guia de ouro, beta); R5b 2a e 2b (site que vende ouro; preço listado, não venda) | Pede aprovação (DD3) |
| 5 | Nunca listar abaixo do preço de vendedor, e conferir o leilão antes de vender ao NPC um item fabricado: a Blizzard baixou o preço de vendedor de armaduras fabricadas. | Tooltip; Auctionator | R8b R8 e R9; base 6.3 | Pede aprovação (DD3) |
| 6 | Postar em lotes e rechecar a cada sessão; lote no tamanho da receita; leilão curto para o que gira e 24 horas só para item raro. | Tela da Blizzard | R8b R7, R14 e R15 (editorial, sem dado) | Pede aprovação (DD3) |
| 7 | Guardar todo azul que vincula ao equipar para o leilão, em vez de vender ao NPC. | — | R8b R2 e R3 (guia de ouro, beta) | Pede aprovação (DD3) |
| 8 | Escolher a regra de preço em commodity, sabendo que as fontes se contradizem: cobrir por 1 cobre (R8a F5), deixar folga real (R8b R6) ou nenhuma das duas resolve em commodity (R8b R12). | — | R8a ficha 2; R8b R6 e R12 | Decisão do dono (DD3) |
| 9 | Usar o Auctionator para o que ele já faz: o último mínimo visto de cerca de 6.600 itens e a comparação do custo dos materiais com o item final. Se a tela de venda dele posta no Forever ninguém viu; postar pela tela da Blizzard. | Auctionator 341 | Base 7.1 e 4.3; R8b R13 | Leitura, sem risco |
| 10 | Anotar o ouro de cada personagem e decidir se o reúne em quem vai vender. Não há banco de conta. | Correio do jogo, à mão | Base 4.1 e 4.2 | Logística, não estratégia |
| 11 | Colar os comandos de leitura da onda 0 com o leilão aberto: depósito por duração, commodity ou item, teclas livres. | Chat do jogo | Base 11; R1b 16 (citado pela base) | Leitura, custo zero |
| 12 | Desligar no ForeverGuide o compartilhamento das varreduras. Não dá ouro; é privacidade. | ForeverGuide | Base 7.3 | Decisão do dono (DD2) |

Duas notas de escala, que também são só o que as fontes dizem. Primeira: o R8b R1 desaconselha comprar no leilão na semana de lançamento ("everything is overpriced", guia da beta), e o R5b 2b registra materiais de nível 30 a 45 caindo pela metade na semana; isso pesa contra comprar para revender agora, com ou sem addon. Segunda: a única estimativa de ganho por hora dos relatórios (R5b 2c, de quem vende ouro, da beta) é de 3 a 10 ouro por hora no nível 20 a 30, e o R8b seção 5 cita mineração e herborismo como as profissões que mais rendem enquanto se sobe de nível. O dono tem as duas (base 4.2). Pelo item 2, é esse ouro de fora que carrega a escada até a banca de virada.

O que o design deve fazer com esta lista está no achado V8-14: pô-la na onda 0, com a fonte de cada linha, para o dono aprovar ou não.

## Item 6. Construir contra adotar

**O que conferi.** A base 5.1 a 5.3 e 5.8, o R6a seções 1, 2.2, 2.3 e 2.10, o D5 seção 1.2, e no design a DD2, a DD12, o risco 3 e o conflito 20. Não li código de nenhuma ferramenta; o que sei delas é o que a base e o R6a citam das páginas públicas, e o que essas páginas não dizem é incógnita, não defeito.

**O que não justifica o addon próprio.**

1. **Funções.** Varredura, sniper, ofertas contra o vendedor e de revenda, postagem, cancelamento quando coberto, contabilidade e análise: tudo isso está na lista do ForeverFlip (base 5.2; R6a 2.10). Toda função das fases 1 e 2 do design tem par nessa lista. O próprio risco 3 admite.
2. **Visão do mercado.** As ferramentas prontas usam a varredura completa, uma a cada 15 minutos, quando responde (base 2.5). O design vê 20 chaves por tecla `L`. Em cobertura, o addon próprio perde.
3. **Velocidade.** As prontas também dependem de uma tecla ou clique por ação (base 2.13), e o ForeverFlip declara "never trades on its own" (base 5.2). O addon próprio é mais lento por escolha: dois tempos em toda compra, `T_ver`, fôlego por tecla.
4. **Ouro.** Com 5 ouro nenhuma ferramenta enriquece o dono, e construir também não. O que muda é quando chega a primeira ação por tecla: na onda 3 com o addon próprio; no mesmo dia com uma ferramenta pronta, se a postagem dela funcionar no Forever, o que só o dono testando responde.
5. **Custo.** São 28 arquivos, uma bancada com leilão falso, um checador novo com os seus casos, uma sonda de 11 passos e semanas de espera por desfechos. A TSM 4.15 e o ForeverFlip já existem e são mantidos por outros.

**O que justifica, e só isto.**

1. **As regras do dono, juntas.** Configuração só por arquivo escrito pelo agente, tela de até 5 linhas por seção, estratégia com fonte aprovada e nascida desligada. A base não descreve ferramenta que cumpra as três; a TSM pede do jogador expressões de preço por grupo de itens (base 5.8). É justificativa real, mas é de conforto e de método, não de ouro.
2. **A máquina de evidência.** Modo papel com portão numérico, licença por estratégia, regra alternativa em sombra e a régua que mede por estratégia e por origem, inclusive o que é feito por outra ferramenta. É a peça mais original do design. Ressalva: que as prontas não tenham algo parecido é incógnita.
3. **O risco proporcional à banca.** Cofre, tetos em fração da banca, estado INCERTO sem reenvio, conciliação pelo correio. Com 5 ouro protege pratas; passa a valer de verdade a partir do degrau de 60 ouro.
4. **O laço com o agente.** Um banco em esquema próprio, que a sessão do agente lê, calibra e devolve como `Config.lua` e relatório (base 4.7 e 4.9). É o modo de trabalho do projeto, e uma ferramenta de terceiro não o oferece: os dados dela não têm contrato.

Fora da lista, com peso menor: a ergonomia para acesso remoto (teclado, eco imediato, alvos grandes) e o fato de nenhum dado sair do jogo.

**O veredito duro.** Das três peças do design, a **régua** e a **fila** se justificam sozinhas: nenhuma fonte descreve coisa igual, custam pouco e funcionam em `modo = "leitura"`, que o design já tem. A **mão** (postar, cancelar e comprar por tecla, ondas 3 a 5) é a parte cara e é a que duplica o que existe. Ela só se justifica pelas quatro razões acima, e nenhuma delas é "rende mais ouro". O design sabe disso e adia a conta para a onda 6 (DD12: "Decidir com três semanas de régua, não hoje"). Está tarde demais: quando a decisão chegar, as ondas 3 a 5 já estarão pagas.

O conserto é barato e está no achado V8-11. A régua da onda 2 mede qualquer caminho. Antes de construir a mão, o dono decide com número: três sessões pela tela da Blizzard contra, se ele quiser testá-la, três por uma ferramenta pronta. Se a pronta render mais por ação sem ferir nenhuma regra dele, o projeto fica em régua e fila, em modo leitura, e as ondas 3 a 5 não são construídas. Se não render, ou se ele não quiser uma ferramenta que se configura dentro do jogo, a mão está justificada pelas regras dele e não por promessa de ouro. Instalar e testar ferramenta é decisão do dono, e a regra de curadoria (base 4.12) já diz que dois addons no mesmo papel não entram juntos.

Uma ressalva a favor de construir, para a conta ficar honesta: o ForeverFlip tem 5 dias de vida e está em beta (base 5.2), e a base não sabe quais módulos da TSM funcionam no Forever nem se o app dela tem preço do Forever (base 5.1; R6a seção 1). Adotar também é aposta, e sem Cofre.

## Tabela dos achados

| id | seção | gravidade | tipo | achado | evidência | correção |
|---|---|---|---|---|---|---|
| V8-01 | 17 (onda 6), 18 DD12 | importante | lacuna | A fase 3 é uma linha ("Novo design"). É nela que mora o que o dono pediu, o day trading pesado. A sessão que implementar não recebe máquina, medida nem portão para o modo de escala, e as fases 1 e 2 fecham portas (tetos de vazão, esquema do banco) sem saber. | Linha 796: "Novo design: conversão, hora e dia, dados externos, ou adotar ferramenta pronta. Pede banca de 60 ouro e três semanas de régua", com rota, pronto e parada "a definir". Script: com 250 ouro e absorção de 1 ouro por item, uma volta são 375 ações, 37,5 min no teto de 10 por minuto. | Inserir a seção 17.1 "Fase 3: a mesa em escala" com o texto do item 4 deste parecer (gargalo medido, degraus, vigília, esteiras, portões de máquina). Na linha da onda 6, trocar "Novo design" por "Seção 17.1; estratégia nova segue a seção 3.3". |
| V8-02 | 9.2, regra 13, 5.2, 7.6 | importante | contradicao_interna | Ações por minuto (10) e buscas por minuto (30) são tetos duros de `Tetos.lua`, que a configuração só aperta. Mas a 5.2 e a 7.6 dizem que o medido na sonda troca esses números. Não têm fonte e travam o degrau de 250 ouro. | Linha 502 (10 e 30 na coluna "Duro"); linha 490 ("pode baixar cada um, nunca subir"); linha 246 ("O medido na sonda troca esses números"); linha 383. Base 2.2: 100 buscas por minuto; base 1.10: os sinais suspeitos são de preço, não de ritmo. D1 usava 60 buscas, D3 40, D6 20 ações. | Na 9.2, tirar a linha de ações e buscas dos tetos duros. Criar no `Config.lua` `ritmo.acoes_min` (partida 10) e `ritmo.buscas_min` (partida 30), com máximo igual ao ritmo sustentado na S4 sem evento `_DROPPED`, nunca acima de 100 buscas. Na regra 13, dizer que teto duro é só de dinheiro. |
| V8-03 | 5.2, 8.1 (I9), regra 9, 18 DD10 | importante | lacuna | Medir venda dos outros pede foto a cada poucos minutos, mas o fôlego dá 20 buscas por tecla `L`: vigiar 150 chaves são 8 teclas `L` por passada, sem fim. A opção `renova_com_tecla` não diz se estende as 20 buscas. A escolha está enterrada na DD10, e a base 8.2 diz que é política sem resposta. | Linha 240 ("20 buscas, 60 s ou fim da lista"); linha 250; linha 406; linha 817. R9 2.2: intervalo de 5 min para item de 30 un/h. Base 8.2. D1 ("portão de presença", 90 s) e D2 ("pulso", 90 s). Script: 150 chaves a cada 5 min = 30 buscas por minuto. | Criar a DD13 "gatilho da vigília", com três opções (uma tecla por fôlego; fôlego renovado por qualquer tecla do terminal; presença de 90 s), padrão a primeira. Na 5.2, dizer que renovar estende tempo e buscas até `folego.max_s` e `folego.max_buscas`. Reescrever I9: nenhuma consulta sem tecla do dono há mais de `T_pulso`. |
| V8-04 | 3.3, 5.1, 9.2, 19 (risco 5) | importante | risco | O portão de papel pode nunca fechar. A venda de papel só conta por venda inferida entre duas fotos da mesma chave, mas a chave com ordem de papel aberta não está no foco, e o viés de subcontagem só seria visto em micro, aonde o papel enviesado para baixo não deixa chegar. | Linha 226 (ordem do foco: bolsas, leilões próprios, triagem do piso, giro); linha 143; linha 501 (teto pelo "volume diário mínimo medido", que sai da mesma inferência); linha 827. R9 2.1: a subcontagem "chega a quase metade com 30 minutos e a 60% com 60 minutos". | Na 5.1, pôr "chaves com ordem de papel ou lote comprado aberto" como segunda prioridade do foco, em todo fôlego. Na 3.3, definir o fecho do sinal de papel (vendeu, ou venceu no prazo D) e acrescentar à DD1b a opção micro-sonda: depois de 30 sinais de papel, lote real de até 2% por item, para medir a saída pela fatura. |
| V8-05 | 3.2 (`vao`), 7.4, 17 (ondas 2 e 5) | importante | contradicao_interna | O `vao` tem dois limiares. A 3.2 pede razão acima de (1 + margem)/(1 − c), que dá 1,21. A 7.4, com `η_real` de 0,5 sobre o ganho e `μ_min` de 0,15, pede saída líquida de 1,30 vez o custo, 1,37 no preço. Ninguém conta quantos vãos assim existem antes de construir a onda 5. | Linha 131; linhas 354 a 356 e 359. Script: 1,211 contra 1,368. Linha 792: a onda 2 mede "cobre disponível abaixo do vendedor" e nada do `vao`. | Na 3.2, trocar o sinal do `vao` por "passa no teste da 7.4" e escrever o limiar implícito, (1 + `μ_min`/`η_real`)/(1 − c). Na onda 2, coluna "Mede", acrescentar: vãos e arremates que passam no teste da 7.4, por fôlego, e quanto duram, gravados sem ordem. Na onda 5, "Para se": menos de 3 sinais por sessão. |
| V8-06 | 3.2, 17 (onda 5), Apêndice B | importante | lacuna | O marco de 15 ouro para a compra em micro não deriva de número nenhum e se soma ao portão de evidência. Os tetos já são fração da banca: com 4 ouro a ordem de 5% é de 20 prata e o ganho previsto de 3 prata cobre as 4 teclas (60 cobre). O marco só atrasa a escada. | Linha 874 ("Marcos de banca: 15 ouro; 60 ouro", origem D5); D5 linha 46, sem derivação. Script: a ordem mínima que paga 4 teclas pede banca de 0,8 ouro; "como escrito" leva o C2 a 60 ouro em 23 dias contra 18, e o C3 em 15 contra 6. | Na 3.2 e na onda 5, trocar "banca de 15 ouro" por condição medida: o ganho previsto da ordem micro (5% da banca) vale pelo menos 3 vezes as teclas vezes o tíquete. Deixar os 15 ouro como opção da DD10, com o custo em dias do item 2 deste parecer escrito ao lado. |
| V8-07 | 0, 9.1, 17 (onda 0), 18 DD4 | importante | contradicao_interna | O resumo promete 50 a 75 prata por giro sobre 5 ouro somados de quatro personagens. Pelo próprio Cofre a banca é só a do personagem logado, menos 1 ouro de piso, com teto de 50%: 20 a 31 prata se o ouro for reunido à mão, e 1 a 2 prata se não for. Não há passo de reunir. | Linha 13; linhas 483 e 484; linha 497; linha 811. Base 4.1 ("somando os quatro personagens") e 4.2 (sem banco de conta). Script: banca de 4,09 ouro reunida e de 0,27 ouro sem reunir. | Na seção 0, trocar a frase por: "com o ouro reunido no negociador, piso de 1 ouro e teto de 50%, um giro aplica cerca de 2 ouro e rende de 20 a 31 prata". Na onda 0, acrescentar: o dono anota o ouro de cada personagem e decide se o reúne pelo correio, à mão. Na DD4, oferecer piso zero até a banca passar de 15 ouro. |
| V8-08 | 0, 9.2, 18 DD4 | importante | contradicao_interna | A fonte de ganho número 1 é vender o que os quatro personagens produzem, mas a DD4 põe o addon em leitura nos três que não são o negociador. E os tetos de depósito são fração de uma banca que pode ser quase zero: com 1,27 ouro e piso de 1, cabe 1 leilão até 17/11. | Linha 15; linha 811 ("com outro personagem logado o addon fica em leitura"); linhas 498 e 499 (5% e 2%); linha 146 ("As vendas entram direto em micro"). Script: 1,36 prata em risco e 0,55 prata perdida por dia sem reunir; 1 leilão com depósito mínimo de 1 prata (base 1.7). | Na DD4, separar: comprar só no negociador; postar e cancelar em qualquer personagem, com Cofre próprio (a seção `pers` já existe na linha 280). Na 9.2, dar aos dois tetos de depósito um mínimo absoluto no `Config.lua` (DD10) e escrever o que vale com banca zero ou negativa: venda segue, compra para. |
| V8-09 | 10, 9.4 | importante | lacuna | O negociador é um personagem que joga: quest, saque, conserto e treino mexem no ouro com o leilão fechado. O Livro não tem registro para isso, e o disjuntor de dinheiro sem explicação dispara com 1% da banca (4 prata). É também o maior termo da escada abaixo de 24 a 72 ouro, e a régua não o mede. | Linhas 537 a 543 (registros: Ação, Lote, Sinal, Fatura, Sessão); linha 549; linha 528. Script: banca de virada de 72, 24 e 12 ouro; parte do trading no ganho até 15 ouro de 11%, 26% e 47%. | Na seção 10, criar o registro "Fora": variação de dinheiro com leilão, correio e vendedor fechados, ou entre sessões, fecha como `outside`, explicada por definição, e não conta no disjuntor. A banca é relida a cada abertura do leilão. Na visão Session, a linha `OUTSIDE +1g 20s today`. |
| V8-10 | 0, 10 (Medidas), 11.3 (Session) | importante | lacuna | O design diz que 5 ouro não enriquecem e para aí. Não mostra quanto cada degrau demora nem o que mais pesa, e a régua não mede os parâmetros da escada: fração aplicada, margem líquida por volta, acerto, horas por volta e ouro de fora. O dono não tem como saber se está subindo. | Linha 19; linha 547 (medidas: resultado, cobre por ação e por hora, voltas do capital, depósitos perdidos, fração vendida, "já sumiu"); linhas 636 a 641. Script: no cenário central, 60 ouro em 18 dias e 250 em 36; só com trading, 42 e 64. | Criar a seção 3.4 "Escada de capital", com a fórmula e a tabela do item 2 deste parecer, marcadas como hipótese. Na seção 10, Medidas, acrescentar os cinco parâmetros. Na visão Session, a linha `PACE +32s a day (trade 8s, outside 24s)   applied 31% of bank`, só com número medido. |
| V8-11 | 18 (DD2, DD12), 19 (risco 3) | importante | lacuna | Construir contra adotar só se decide na onda 6, depois de semanas de código, e o risco 3 não tem número. O ForeverFlip já lista varredura completa, sniper, ofertas, postagem, cancelamento e contabilidade. O design não diz o que o addon próprio tem que nenhuma ferramenta pronta tem. | Linha 819 ("Decidir com três semanas de régua, não hoje"); linha 825; linha 931 (conflito 20). Base 5.1 e 5.2; R6a 2.2 (Journalator, MIT, exporta CSV) e 2.10. D5 1.2 trazia a tabela peça por peça, que não entrou. | Na 3.1, acrescentar a tabela "construir contra adotar, peça por peça", com as justificativas do item 6 deste parecer. Antecipar a DD12 para o fim da onda 2: com a régua pronta, o dono compara três sessões pela tela da Blizzard com três por ferramenta pronta, se quiser testá-la. No risco 3, escrever o número que derruba. |
| V8-12 | 3.2, 6 | importante | contradicao_interna | A 3.2 promete o menor preço por bloco de 4 horas por três semanas, mas o esquema só tem `dias`: um ponto por dia, 14 dias. Também não há onde guardar venda inferida por chave depois que o anel de 48 fotos gira, o que em vigília de 5 minutos acontece em 4 horas. A fase 3 nasceria sem dado. | Linha 135; linhas 277 e 289; linha 290; linha 362 (classe B: "3 intervalos das últimas 24 horas"). Script: 126 pontos por chave em três semanas contra 14 guardados; anel cobre 4 h; 150 chaves pedem 2,16 MB de fotos, e o teto do banco é 3 MB. | Na seção 6, acrescentar `blocos[chave]` (mínimo e quantidade por bloco de 4 horas, 21 dias, só chaves de foco: cerca de 190 KB para 150 chaves) e `giro[chave]` (vendas inferidas e exposição por bloco, 14 dias). Refazer a tabela de tamanho para 40, 150 e 500 chaves, com o teto de banco que cada uma pede. |
| V8-13 | 8.1 (I8), 11.4 (fluxos A, B e C) | importante | lacuna | Não está escrito onde fica o cursor quando a linha postada ou cancelada sai da lista. Se a seguinte entra sob o cursor, postar 40 lotes custa 40 teclas; se a seleção fica vazia, 80. I8 diz que a seleção nunca muda sozinha, e a linha some sozinha. Em escala, isso decide a vazão. | Linha 405 ("A seleção nunca muda sozinha"); linha 662; linha 668 ("POSTED; a linha vai para a visão Mine"). Script: 40 ou 80 teclas para 40 lotes. | Na 11.4, depois de B.4 e de C.2, escrever: a linha concluída sai, a seguinte sobe para a posição do cursor com a marca `NEXT` e `T_ver` recomeça; uma tecla por lote. Em I8, trocar a última frase por "a posição do cursor nunca muda sozinha; linha nova sob o cursor reinicia `T_ver`". Acrescentar o cenário à bancada. |
| V8-14 | 17 (onda 0) | menor | melhoria | A onda 0 só mede. O que deu ao D5 a melhor nota do juiz do dinheiro, ouro antes de existir addon, saiu na síntese. A fonte já aprovada manda vender verdes bons, o depósito mínimo cai em 17/11 e o dono disse que precisa de dinheiro. | Linha 790; linha 931 (conflito 20); J2 linha 63 ("É o único que põe ouro na mão antes de existir addon"). Base 4.1, 4.5 e 1.7. | Na onda 0, acrescentar a tarefa "o que o dono já pode fazer pela tela da Blizzard", com a lista do item 5 deste parecer: cada linha com a fonte, e as que não vêm da fonte aprovada marcadas "pede aprovação (DD3)". |
| V8-15 | 3.1 | menor | melhoria | "A corrida de reflexo está perdida por construção" mistura fato e escolha. Fato: a latência do acesso remoto. Escolha da síntese: `T_ver`, dois tempos em toda compra e fôlego por tecla. Os concorrentes também dependem de uma tecla por ação. O dono não vê o que está cedendo. | Linha 116; linhas 414 e 438; linha 913 (conflito 2). Base 2.12 e 2.13; base 5.2 (ForeverFlip: "never trades on its own"); base 4.11. | Na 3.1, reescrever a frase separando o que é fato do jogo do que é escolha do projeto, com o custo de cada escolha em segundos por compra. Na 7.6, gravar a taxa de "já sumiu" por tempo entre a foto e a tecla, para a DD1b e a DD13 serem revistas com número. |
| V8-16 | 3.2 ("Só medição") | menor | lacuna | A compra no vendedor para revenda no leilão, com estoque ilimitado, não aparece nem na lista de só medição: a 3.2 trata apenas do estoque limitado. O R9 5.4 tem a conta, e o resumo já traz o menor preço: contar custa zero. | Linha 135; R9 linha 657 ("NPC para leilão"); base 3.7 (`C_MerchantFrame.GetItemInfo`); R8a ficha 5 (o recurso "vendor flips" do AHledger, só por busca). | Na 3.2, lista "Só medição", acrescentar: de todo item que o dono vê num vendedor o addon anota o preço de compra e conta, a cada resumo, quantas vezes o menor preço do leilão passa dele com a margem da 7.4. Sem ordem de compra e sem estratégia até haver fonte aprovada. |
