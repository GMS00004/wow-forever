> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# J3-dono: parecer pela lente do dono e das regras

Data: 2026-11-16. Juiz J3. Li a base de fatos inteira, os seis projetos inteiros e, para conferir citações, trechos de R1a, R1b, R1c, R4a, R4b, R5a, R6a, R6b, R8a, R8b, R9, R10a e R10b, mais o espelho da Blizzard. Não li R2a, R2b, R3a, R3c, R3d, R7a nem R7b. Nada foi testado no jogo.

Como ler. `D4 7.6` é a seção 7.6 do projeto D4. `base 2.12` é a base de fatos. Notas de 1 a 10; em **risco**, nota alta quer dizer projeto bem protegido. A minha lente pesa mais a aderência e a conformidade do que o teto de lucro.

## 0. Veredito curto

- **Ordem pela lente**: D4, D5, D3, D2, D1, D6.
- **Espinha**: D4 (invariantes, Cofre, tetos duros, licença por nível, bilhete), com a ordem de fases e os critérios de parada do D5, a mão do operador do D2, os contratos de mesa do D3, os portões do D1 e três guardas do D6.
- **A decisão antiga do dono** ("o guia marca e o dono clica", base 4.6): os seis a põem como decisão número 1 do dono, nenhum a trata como pressuposto. Diferem no que sobra se ele disser não, e no que o código toca além das oito funções de leilão (seção 6).
- **Dois achados que valem para a síntese inteira**: (a) a regra de compra do R9 5.1 multiplica a saída inteira por `η_real` 0,5, o que só deixa passar compra com saída de pelo menos o dobro do custo; D1, D2, D4 e D6 herdam isso e só o D3 conserta (D3 4); (b) cinco projetos supõem, sem marcar hipótese, que as faturas do correio são lidas antes de o dono recolher; só o D4 marca (D4 6.3 D).

## 1. Notas

| Projeto | Viabilidade | Lucro | Aderência | Risco | Testabilidade |
|---|---|---|---|---|---|
| D1-quant | 6 | 4 | 7 | 8 | 9 |
| D2-operador | 7 | 6 | 8 | 6 | 9 |
| D3-mesa | 6 | 5 | 8 | 8 | 9 |
| D4-risco | 8 | 5 | 9 | 9 | 9 |
| D5-ouro | 9 | 7 | 8 | 7 | 8 |
| D6-concorrencia | 5 | 5 | 6 | 6 | 7 |

### D1-quant

- **Viabilidade 6.** Cabe na API e marca doze hipóteses (H-01 a H-12), mas são 30 arquivos, mais de cem parâmetros e uma mesa (D1 1.4, 3.2), e tudo depende de a venda alheia ser inferível (D1 11.2).
- **Lucro 4.** O próprio projeto diz que são semanas de coleta e sombra antes da primeira compra e que, nessa escala, "o ouro novo vem do personagem, não do pregão" (D1 1.2, 1.4). Para um dono com 5 ouro o que entrega cedo é só o precificador de venda.
- **Aderência 7.** Decisão D1 posta ao dono, duas chaves por estratégia (aprovação no `Config.lua` e portão da mesa, D1 3.7), nada configurado no jogo, cinco telas dentro do limite de linhas (D1 6.3). Perde por: doze letras como teclas, nenhuma etapa de quadro renderizado para o dono aprovar, trava de leitura só na confirmação (D1 6.5), fila que pode se reordenar sob o cursor, e `BuyMerchantItem` liberado no checador sem fluxo nem decisão (D1 8.3).
- **Risco 8.** Tetos, disjuntores, estado `INCERTO`, duas testemunhas e portões G0 a G5 (D1 4.3, 4.6, 7.1). O risco que sobra é de modelo e de complexidade, e o projeto o declara (D1 11.4).
- **Testabilidade 9.** Bancada com falhas injetadas, propriedades do motor puro, replay progressivo, sombra e portões com número (D1 8.1 a 8.5). Recusa o teste negativo de ação sem tecla (D1 8.4).

### D2-operador

- **Viabilidade 7.** Máquinas de estado corretas contra a base 2.7 a 2.10 e citações do espelho conferidas (D2 3.4). Depende de a tecla valer e tem plano B concreto, o cursor estacionado (D2 6.2).
- **Lucro 6.** Baixa o custo por tecla e o erro de dedo, que é real por acesso remoto; mas a tese é vazão, e com 5 ouro a fila pode ficar vazia (o próprio D2 11.2). A escada E2, E1, E3 é sensata (D2 2).
- **Aderência 8.** A melhor tela (um cartão, três zonas fixas, D2 6.1 e 6.3) e a melhor operação remota: `T_ver` somado à latência do `Config.lua`, disjuntor de tecla presa, tecla de pausa, ritmo de volta e bloco (D2 6.5, 6.6). Quadros em HTML para o dono aprovar (D2 8). A leitura mais rigorosa da fronteira de gameplay: a regra `W*` roda em sombra até vencer a regra com fonte que o dono escolheu (D2 5). Perde por: `/pregao train` é um modo trocado dentro do jogo (D2 3.1), a tecla ligada ao `OpenAllMail` da Blizzard (D2 6.4 D), a opção de confirmar commodity sem tecla oferecida ao dono (D2 10.2), e por não ter o que fazer se o dono mantiver a decisão antiga (D2 10.1: "perde o motivo de existir").
- **Risco 6.** Guardas conferidas duas vezes e cabeça fixa (D2 7.1), mas o próprio projeto nomeia o perigo: decisão ruim executada depressa (D2 11.3). Otimizar ações por minuto empurra para volume (D2 1.3).
- **Testabilidade 9.** Casos de operador com seis invariantes e 200 rodadas de teclas aleatórias, modo treino com cartão real e tecla que só registra, replay como regressão (D2 8).

### D3-mesa

- **Viabilidade 6.** Contratos de dados bem especificados (D3 3.6), mas o ângulo depende do `/reload` como canal e de um processo vigia; se a gravação não for confiável o canal some (D3 11.2). Sync a cada 30 a 40 minutos por acesso remoto é atrito de sessão longa (D3 3.7).
- **Lucro 5.** A fase 1 não tem tecla e não arrisca ouro (D3 2); o ganho vem de vender melhor, depois. A pauta do dia e a ficha de evidência economizam atenção, não geram ouro por si.
- **Aderência 8.** É o que melhor respeita a decisão antiga: a fase 1 inteira funciona com o dono clicando na tela da Blizzard (D3 2). Separa o que a mesa troca sozinha (fato do jogo, ajuste dentro de faixa) do que é decisão do dono (D3 4, fim). Melhor registro para a sessão seguinte (D3 3.8). Hash no lugar de nome de vendedor (D3 3.6). Perde por: ritual de sync, vigia rodando no Avell, tecla `M` no `OpenAllMail` sem decisão própria (D3 3.4), sem trava de leitura do tipo "vê e assina", sem etapa de quadro renderizado, e a sonda S1 usa tecla de ação antes da autorização formal (D3 9, onda 2).
- **Risco 8.** Modos `DESK OK`, `DESK STALE` e `NO DESK`, recibo e sentinela, limite de cotação mais duro que o da Blizzard, tetos fixos no lugar de Kelly (D3 3.6, 4, 7). Risco próprio: arquivo velho lido como novo (D3 11.5).
- **Testabilidade 9.** Bandeira de hardware na bancada, replay determinístico, `checar-mesa` com ida e volta, sombra antes de qualquer tecla (D3 8).

### D4-risco

- **Viabilidade 8.** Usa só o que a base sustenta e trata o que é incógnita como proibido (D4 3.1). Motor reduzido a peças de falha limitada (D4 4.1). Custo: duas teclas por ação e muita máquina de conciliação (D4 11.4).
- **Lucro 5.** Protege o capital, mas com 2% da banca por ordem em micro (cerca de 8 prata) pode "não fazer quase nada" (D4 11.1). O ganho real é a venda do estoque próprio e o vendedor em lote de confirmação (D4 5 E1, E2).
- **Aderência 9.** Invariantes I1 a I7, tetos que a configuração só aperta, nível que só desce dentro do jogo (D4 3.1, 7.2), correio só por leitura e venda ao NPC por clique do dono (D4 6.3 D, 7.6), lista de itens reservados pela decisão do dono sobre o couro (D4 5 E1), recusa explícita da confirmação sem tecla como zona cinzenta (D4 7.6), quadros aprovados pelo dono (D4 9, T2.3). Tira um ponto: duas teclas em tudo custam atenção em sessão longa, e não há desenho de ritmo de sessão.
- **Risco 9.** Cofre, disjuntores com destrava por arquivo, estado `INCERTO` sem reenvio, isca e parede, piso pessoal (D4 7.1 a 7.5). O risco que sobra é o dono operar por fora por frustração (D4 11.1).
- **Testabilidade 9.** 24 cenários, 10.000 roteiros ao acaso, papel do addon igual ao papel do replay, e escada papel, micro, plena com portão numérico (D4 5, 8.1, 8.2, 8.5).

### D5-ouro

- **Viabilidade 9.** A fatia mais fina: sem varredura completa, sem mesa, banco de 1,1 MB, quatro teclas (D5 3.4, 3.5, 6.1). Lê tudo ao vivo e não assume parâmetro do jogo (D5 4.2, 4.3).
- **Lucro 7.** É o único que mede ouro por tecla desde a primeira sessão e que aceita adotar ferramenta pronta se o número mandar (D5 1.2, 9). Teto baixo e piso possivelmente já varrido, o que o projeto admite (D5 1.5, 11.1). Não é o "day trading pesado" pedido; é a escada até ele.
- **Aderência 8.** Correio e vendedor por clique do dono (D5 10.7, 6.3 B), plano claro se a decisão 1 for negada (régua e conselheiro, D5 9 onda 1), fronteira "leitura do cliente o addon adota, juízo só pelo `Config.lua`" (D5 3.5), tela de 440 px com cinco linhas (D5 6.2). Perde por: nenhuma trava de leitura além de 250 ms numa tecla única que muda de verbo e avança sozinha de linha (D5 3.3, 6.3 A), nenhuma etapa de quadro renderizado, prior de chance de venda inventado (0,25, 0,45, 0,65, marcado como hipótese, D5 4.3) alimentando o veredito `AUCTION` ou `VENDOR`, regra de preço `commodity = "cobrir"` já escrita no `Config.lua` (D5 3.5), e "aproveitar código MIT" na fase 3 (D5 2), que encosta na regra 5.
- **Risco 7.** Ficha de tecla, teto de cotação do motor, lote de sondagem de 2%, disjuntores (D5 7). Perda diária de 10% abaixo de 15 ouro é o dobro dos outros (D5 4.3). Falta estado `INCERTO` com bloqueio: ação sem resposta só vira linha no diário (D5 3.3).
- **Testabilidade 8.** Marcador de tecla na bancada, replay, checador novo, sonda na ordem da base 11 e uma coluna "para se" em cada onda (D5 8, 9). A estratégia de entrada vai ao vivo com menos prova que nos outros (três varreduras e lote de sondagem).

### D6-concorrencia

- **Viabilidade 5.** O valor do projeto depende de `owners` vir preenchido, que é incógnita (base 2.4, 11.5; D6 11.1), e de cadência de foto suficiente para medir reação (D6 11.2). São 29 arquivos.
- **Lucro 5.** Nicho é a escala que 5 ouro ocupam (D6 1), mas cada nicho pede dias de observação e postagens-sonda pagas em depósito (D6 4.2).
- **Aderência 6.** Boas guardas ("o que você vê é o que você assina", D6 6.4), decisões gravadas em `estado.md` (D6 9, T0.1), checador que cobra as cinco linhas (D6 8). Perde por: o produto central (ficha de terreno, vetos, `GO` e `AVOID`) é juízo de mercado feito com limiares do projetista e sem fonte pública (D6 4.3, 4.6: "meus, a calibrar"); guarda e mostra nome de jogador com presença por hora (D6 3.4, 6.2); alterna estilos de preço como experimento com o depósito do dono (D6 5 E7); guarda de postagem sem referência em 20 vezes o preço de vendedor (D6 7); troca de nome do addon.
- **Risco 6.** Antiguerra G1 a G5 e trégua são bons (D6 4.4). `w_item` de 25% é o teto mais frouxo dos seis (D6 4.6), e a seleção por índice ruidoso sofre da maldição do vencedor (D6 11.4).
- **Testabilidade 7.** Agentes plantados na bancada e critérios numéricos de aceite (D6 8). A hipótese central só se prova no jogo e com gasto de depósito.

## 2. Conferência de fatos contra a base

O que conferi e bate: as citações do espelho (`Blizzard_MailFrame/MailFrame.xml:444`; `MailFrame.lua:271`, `:576`, `:790`, `:1631-1634`; `Blizzard_AuctionHouseBuyDialog.lua:3`; `Shared/Blizzard_AuctionHouseUtil.lua:391-400`; `Blizzard_AuctionHouseTableBuilder.lua:1095` e `:1144`); os parâmetros citados da tabela C do R9 e os números de R9 0.3 e 7.2; os ids de fonte de R8a e R8b; as funções 63 e 79 e o evento 10 do R1a; `ReloadUI` e `C_UI.Reload` no R1c 13; `GetTimePreciseSec` no R1c 5; R4a 3, 4 e 6; R4b 2, 4, 5e e 6.

Contradições, fatos sem lastro e extrapolações, por projeto:

**Comum a D1, D2, D3, D5 e D6.** Ler todas as faturas antes da coleta é tratado como dado (D1 6.4 D: "Read 7 of 7, safe to collect"; D2 6.4 D; D3 3.4; D5 6.3 D; D6 6.3). A base 3.1 diz o que a fatura traz, não que ela se lê sem abrir a carta; no espelho a Blizzard só chama `GetInboxInvoiceInfo` com a carta aberta (`MailFrame.lua:576` e `:790`). Só o D4 escreve isso como hipótese com plano alternativo (D4 6.3 D). Pesa, porque o `Open All` apaga a carta de venda ao tirar o ouro.

**Comum a D1, D2, D4 e D6.** Adotam a regra de compra do R9 5.1 como está (D1 4.1; D2 4.1; D4 4.3; D6 4.5). Nela `η_real` 0,5 multiplica a saída inteira, o que exige saída de pelo menos duas vezes o custo; o R9 5.7 define `η_real` como realizado sobre previsto do ganho. Não é fato do jogo, é defeito de modelo herdado; só o D3 4 o aponta e conserta.

**D1.**
- D1 3.6: afirma que `PLAYER_LOGOUT` está na lista `api-forever/Events.lua` do projeto. Não está na base nem em relatório (R4a 4 só cita `ADDON_LOADED` e a existência da lista). Sem lastro.
- D1 5 E1: cita "R8b R8" como fonte de comprar abaixo do vendedor. R8b R8 é regra de postagem ("never list below vendor price"); o R8a ficha 5 diz que não há fonte do fluxo no Forever. Citação esticada.

**D2.**
- D2 1.1: "a informação não é vantagem; todos leem a mesma API sob a mesma exigência de uma ação por tecla". Vem marcado como inferência, mas choca com a base 5.5 e 5.8 (não há histórico público e ninguém vê a venda alheia, logo dado próprio é vantagem) e com a base 2.13 (a exigência não foi testada no Forever). É a premissa da tese.
- D2 5 E1: mesma citação esticada de R8b R8 ("indica que essas ofertas existem").

**D3.**
- D3 1, item 1: "o erro de preço óbvio dura segundos". Sem citação; a base não mede a vida de uma oferta (D2 1.1 e R9 10.2 tratam como coisa a medir). Fato inventado.
- D3 3.4, 4 e 6.3: item cancelado volta pelo correio tratado como fato, e o custo de três teclas mais caminhada entra no motor. A base 1.8 só tem o assunto "Auction canceled"; D1, D2, D4 e D6 marcam hipótese.
- D3 7 (Banca): soma o ouro dos quatro personagens pelo Syndicator. A base 4.2 diz que não há banco de conta: só o ouro do personagem logado compra.

**D4.**
- D4 1, 4.2 e 11.5: "cerca de 7% por dia composto" e "parte devendo perto de 12%" em 24 horas. A base 6.1 dá queda semanal de mediana de preço listado, de sites que vendem ouro, e manda tratar como direção. A conta é aritmética certa sobre um número que não autoriza taxa diária, e ela justifica `H_max` de 24 h e `μ_min` de 0,15.
- D4 5 E1: "por decisão do dono (base 4.5)" sobre o couro do Hexumlite. A decisão está no R4b 4; a base 4.5 só diz que não vale vender todo o couro. Citação imprecisa, fato correto.

**D5.**
- D5 6.3 C: "o item volta pelo correio (base 1.8)" como fato (ver D3). E há incoerência interna: D5 1.1 e a linha "To do: mailbox 5 items" (D5 6.2) supõem compra entregue pelo correio, enquanto D5 4.3 põe "entrega imediata" como hipótese.
- D5 1.2: lista o TSM 4.15 entre as ferramentas prontas para postar e cancelar no Forever. A base 5.1 diz que o post não informa quais módulos funcionam no Forever.
- D5 9, onda 0: "posta os verdes pelo Auctionator instalado". A base 7.1 diz que ele roda e a base 4.3 que nunca houve postagem registrada; a postagem por ele no Forever não foi vista. É hipótese, não caminho garantido.

**D6.**
- D6 11.5: "o ForeverFlip já cancela quando coberto, base 5.2". A base 5.2 só lista "cancelamento" e a regra "never trades on its own"; o detalhe ("cancel de undercut") é do R6a. A frase sugere automação que a fonte não afirma.
- D6 4.3 e 4.6: os limiares de veto (`RR` 0,3, `ρ` 1,5, guerra 3 em 30 min) não são fato nem têm fonte; o projeto os marca como "meus", o que é honesto, mas são eles que produzem o veredito.

Nenhum projeto contradiz a base em taxa, duração, throttle, evento ou assinatura de função: todos leem depósito e preço de vendedor na hora e tratam corte, devolução e ordem de empate como coisa a medir.

## 3. Defeito mais grave e enxertos

### D1-quant
**Defeito mais grave.** Tempo e peso: semanas sem ouro e mais de cem parâmetros para um dono com 5 ouro que pediu trading, com a mesa podendo abrir portão de estratégia (D1 3.7, 4.6). Pela lente, é o projeto que mais demora a devolver algo que o dono acompanhe.

**Enxertos.**
1. Duas chaves por estratégia: aprovação do dono no `Config.lua` e portão de calibração (D1 3.7, 4.6). É a regra 3 em forma executável.
2. Escada de portões G0 a G5 com condição conferível (D1 4.6), no lugar de "liga quando parecer bom".
3. Teclas de ação distintas para comprar, postar e cancelar, e confirmar em tecla própria (D1 6.2): evita erro de modo, que por acesso remoto é o erro provável.
4. Deriva por categoria no custo de carregar (D1 4.3 item 1), medida no painel, no lugar do número fixo do D4.
5. Duas testemunhas: sinal de compra só executável com venda inferida recente no preço de saída (D1 4.3 item 4).
6. `checar-acoes` proibindo construção que divirja entre Lua 5.1 e 5.3 no motor puro (D1 8.3).

### D2-operador
**Defeito mais grave.** A tese é vazão. Meta de 6 a 10 ações por minuto com uma tecla única (D2 1.2) é o desenho que mais se aproxima de cadência de robô e o que menos tem a oferecer com 5 ouro; e se o dono mantiver a decisão antiga o projeto declara que perde o motivo de existir (D2 10.1).

**Enxertos.**
1. `T_ver` com a latência do acesso remoto vinda do `Config.lua` (D2 3.4, 6.6): a tecla nunca age sobre o que o dono ainda não viu.
2. Disjuntor de tecla presa (seis `K` em dois segundos soltam as teclas) e tecla de pausa que solta todos os bindings (D2 6.2, 6.6).
3. Regra `W*` só em sombra até vencer, no registro, a regra de preço com fonte que o dono escolheu (D2 5, fim).
4. Quadros de cada tela e de cada estado em HTML, aprovados pelo dono antes do jogo (D2 8, 9 onda 2).
5. Modo treino: cartão real, tecla que só registra, medindo "já sumiu" e tempo de decisão antes de ouro (D2 2, 8).
6. Ritmo de sessão longa: volta, orçamento por volta, bloco de 50 minutos com pausa sugerida e nunca imposta (D2 6.5).

### D3-mesa
**Defeito mais grave.** O ritual: sync com `/reload` a cada 30 a 40 minutos, sync duplo na abertura e um vigia rodando no Avell (D3 3.7). Por acesso remoto, em sessão longa, é a peça que o dono mais vai sentir, e o próprio projeto a lista como o que pode derrubá-lo (D3 11.2, 11.5).

**Enxertos.**
1. Fase 1 sem tecla de ação: sensor, livro e sombra, com o dono agindo pela tela da Blizzard (D3 2). É a forma de respeitar a decisão antiga enquanto ele decide.
2. Correção do `η_real`: desconta o ganho, não a saída inteira (D3 4).
3. Fronteira escrita do que a mesa troca sozinha e do que só o dono troca (D3 4, tabela de calibração).
4. Recibo, sentinela e os três modos de degradação dos arquivos gerados (D3 3.6).
5. Ficha de evidência por estratégia e pauta do dia como registro para a sessão seguinte (D3 3.8).
6. Hash no lugar do nome de vendedor, e `checar-pregao` cobrando texto de tela sem "Source" (D3 3.6, 8).

### D4-risco
**Defeito mais grave.** Pode não fazer quase nada: 2% da banca por ordem, duas teclas por ação e semanas de papel (D4 11.1). O risco de conformidade que isso cria é o dono operar por fora, onde nenhuma guarda vale.

**Enxertos.**
1. Invariantes I1 a I7 como contrato conferido por checador e bancada (D4 3.1, 8.3).
2. `Tetos.lua` como constante que a configuração só aperta, e nível de estratégia que só desce dentro do jogo (D4 3.1 I4 e I7, 7.2).
3. Licença por nível (desligada, papel, micro, plena) com portão numérico e lote de confirmação por item (D4 5).
4. Bilhete com total, limite, fração da banca e pior caso antes da tecla que gasta, com validade de 20 s (D4 6.2, 6.4).
5. Estado `INCERTO`: ação sem eco bloqueia o item e nunca reenvia (D4 3.5).
6. Lista de recusas com o porquê, incluindo a confirmação de commodity sem tecla, `:Click()` e o teste negativo (D4 7.6), e a lista de itens reservados do dono (D4 5 E1).

### D5-ouro
**Defeito mais grave.** A mão remota: uma tecla só (`F6`) compra, posta e cancela conforme a linha em destaque, o destaque avança sozinho e a única proteção é ignorar toques a menos de 250 ms (D5 3.3, 6.3). Com latência de stream é o projeto em que é mais fácil arrematar a linha que o dono não leu.

**Enxertos.**
1. Régua antes do motor: razão por estratégia, por tecla e por ferramenta, medindo também o que o dono faz pelo Auctionator (D5 1.1, 1.2, 9 onda 2).
2. Coluna "para se" em cada onda, com limiar de parada escrito (D5 9).
3. Ordenar a fila pelo tempo até o dinheiro voltar, não pela margem (D5 1.1, 4.2).
4. Ponto de equilíbrio em palavras na tela (`needs 18%`), o número que o dono consegue julgar (D5 4.2).
5. "Leitura do cliente o addon adota sozinho; juízo só muda pelo `Config.lua`" (D5 3.5), e a lista `reservas` (D5 5 E2b).
6. Poucas teclas, sem modificador, em teclas de função (D5 6.1), e a hipótese da lista da Blizzard sendo sobrescrita pela nossa varredura (D5 3.2).

### D6-concorrencia
**Defeito mais grave.** O núcleo é opinião de mercado sem fonte: a ficha de terreno e os vetos decidem onde o dono joga com limiares do projetista (D6 4.3), em cima de um campo (`owners`) que pode vir vazio (D6 11.1), guardando e exibindo nome de jogador com hora de presença (D6 3.4, 6.2).

**Enxertos.**
1. "O que você vê é o que você assina": a tecla só vale se a ordem em destaque está na tela, sem mudar, há pelo menos 1 segundo (D6 6.4).
2. Teto de cancelamentos com repostagem por item e trégua (D6 4.4, G1 e G2), como guarda de depósito.
3. Decisões do dono gravadas em `estado.md` com data, e `aprovadaEm` no `Config.lua` (D6 9 T0.1, 3.1).
4. Checador que reprova seção com mais de cinco linhas sem `Show N more` e binding que aponte para botão que não seja do addon (D6 8).
5. Confirmação de commodity desligada com menos de 5 s de cotação (D6 3.3, 6.4).
6. Medição passiva da ordem entre preços iguais, sem comprador combinado (D6 4.7).

## 4. Ordem, do melhor ao pior pela lente

1. **D4-risco.** O mais fiel aos limites e o único sem zona cinzenta: onde a base diz "não se sabe", age como se não pudesse.
2. **D5-ouro.** O que cabe em 5 ouro, mede antes de construir e funciona com ou sem a tecla. Falha na proteção da mão remota.
3. **D3-mesa.** O que melhor trata a decisão antiga e o registro entre sessões. Falha no ritual.
4. **D2-operador.** A melhor tela e a melhor ergonomia remota. Falha na tese e no que fica se o dono disser não.
5. **D1-quant.** O motor mais completo e os melhores portões. Falha em tempo e peso para este dono.
6. **D6-concorrencia.** Ideia original, mas o centro é juízo sem fonte sobre um dado que pode não existir.

## 5. Espinha recomendada

**Base: D4.** Invariantes I1 a I7, Cofre, `Tetos.lua`, licença por nível, bilhete, `INCERTO`, correio só por leitura, lista de recusas. É a camada que garante as regras 1, 2, 3 e 4 por construção e por checador.

**Do D5:** a ordem das fases (régua, venda do estoque próprio, piso do vendedor, depois o vão), a coluna "para se", a fila por tempo de caixa, o ponto de equilíbrio em palavras, poucas teclas, e a comparação medida entre construir e adotar. Sem a parte de "aproveitar código MIT".

**Do D2:** o cartão único com zonas fixas, `T_ver` com latência, disjuntor de tecla presa e tecla de pausa, quadros em HTML aprovados pelo dono, modo treino, ritmo de volta e bloco, e a regra `W*` em sombra contra a regra com fonte.

**Do D3:** fase 1 sem tecla de ação, contratos da mesa (recibo, sentinela, modos de degradação), ficha de evidência, pauta do dia, a correção do `η_real`, hash de vendedor. Sem o vigia e sem o sync de meia em meia hora na fase 1.

**Do D1:** portões G0 a G5 e duas chaves por estratégia, deriva por categoria medida, duas testemunhas, teclas de verbo distintas.

**Do D6:** "vê e assina", teto de cancelamentos com trégua, decisões em `estado.md`, checador das cinco linhas. A ficha de terreno fica como relatório da mesa, nunca como veredito na tela, até haver fonte ou evidência própria que o dono aprove.

### Conflitos que a síntese precisa decidir, com a minha posição

1. **Teclas por ação.** D4 arma e executa em duas teclas sempre; D1, D2, D3, D5 e D6 compram item, postam e cancelam com uma. Posição: toda tecla que gasta ouro tem dois tempos (cotar e confirmar na commodity; armar e executar no item); postar e cancelar com uma tecla e a guarda "vê e assina" de 1 segundo, mais a segunda quando o jogo pedir. Rever com a taxa de erro medida no modo treino.
2. **Tecla única contextual ou teclas de verbo.** D2 e D5 usam uma tecla que muda de verbo; D1, D3, D4 e D6 separam. Posição: teclas de verbo e uma só tecla de confirmar. O mapa final só depois de a sonda ler os padrões do cliente (base 4.10 não os conferiu) e de o dono aprovar vendo quadro.
3. **Correio.** D4 e D5 só leem e o dono clica no `Open All`; D2 e D3 ligam uma tecla ao botão da Blizzard; D1 e D6 oferecem uma tecla por carta. Posição: só leitura, clique do dono. Tecla no botão da Blizzard ou por carta só como decisão posterior dele, depois da sonda. E marcar como hipótese a leitura da fatura antes da coleta.
4. **Confirmação de commodity sem tecla.** D2, D3 e D5 a oferecem como opção ao dono (recomendando duas teclas); D4 a recusa. Posição: recusar e não oferecer. A base 2.13 diz que a API permitiria, e é exatamente por isso que é zona cinzenta: gasto dentro de um evento.
5. **Varredura.** D3, D4, D5 e D6 varrem por fôlego, uma tecla por rodada que termina sozinha; D1 e D2 varrem enquanto houver tecla nos últimos 90 s. Posição: fôlego por tecla, com orçamento. A releitura automática fica só para o bilhete armado ou o cartão da cabeça.
6. **Preço de postagem.** D1, D3, D4 e D6 deixam o `W*` decidir desde o primeiro dia, por ser "cálculo, não estratégia"; D2 põe o `W*` em sombra e posta pela regra com fonte que o dono escolheu; D5 usa uma conta reduzida com prior inventado. Posição: a do D2. O R9 não tem revisor (base 10) e as fontes públicas se contradizem; enquanto não houver desfecho próprio, a tela mostra a regra com fonte e o `W*` ao lado, marcado como estimativa.
7. **Mesa e `/reload`.** D3 quer vigia e sync a cada bloco; D1, D2 e D4 rodam a mesa pelo agente ao fim da sessão; D5 não tem mesa. Posição: sem processo de fundo na fase 1; o agente roda a mesa no fecho, e o `/reload` no meio da sessão é só ponto de salvamento pedido pelo dono. Os contratos do D3 valem desde já.
8. **Nome de vendedor e banca.** D6 guarda e mostra nomes; D3 guarda hash; D4 e D5 não guardam. D3 soma o ouro dos quatro personagens; D1 e D4 contam só o logado. Posição: hash, só na fase 3 e por decisão do dono; banca só do personagem logado, com piso pessoal.

Conflitos menores, com posição em uma linha cada: teste da ordem entre preços iguais só com lotes próprios ou passivo, sem comprador combinado (D2 e D4 o propõem); nome PregaoForever; marca de ausente anotada pelo dono, não medida pelo addon; guarda de postagem sem referência é não propor preço (D1, D4, D5), nunca 20 vezes o vendedor (D6); `/pregao train` vira campo do `Config.lua`.

## 6. A decisão antiga do dono, projeto a projeto

| Projeto | Põe como decisão dele | O que funciona se ele mantiver "marca e clica" | O que o código toca além das oito funções de leilão |
|---|---|---|---|
| D1 | Sim (D1 10, D1) | "Vira só leitura": precificador na tela | Tecla por carta opcional (D1 10, D6); `BuyMerchantItem` aceito pelo checador sem decisão (D1 8.3) |
| D2 | Sim (D2 10.1) | Nada previsto: "perde o motivo de existir" | Tecla ligada ao `OpenAllMail` da Blizzard (D2 10.3) |
| D3 | Sim, por etapas (D3 10.1) | A fase 1 inteira: sensor, livro, sombra, relatório | Tecla ligada ao `OpenAllMail`, sem decisão própria (D3 3.4) |
| D4 | Sim, com condições (D4 10.1) | Níveis desligada e papel; plano B por clique (D4 6.4) | Nada: correio e NPC por clique do dono (D4 7.6) |
| D5 | Sim (D5 10.1) | Régua e conselheiro, sem `Acoes.lua` (D5 9, onda 1) | Nada (D5 10.7) |
| D6 | Sim, postar antes e comprar depois (D6 10.1) | Radar e fichas; sem postar perde a postagem-sonda | Tecla por carta opcional e desligada (D6 10.7) |

Recomendação para a síntese: escrever a decisão 1 como três perguntas separadas (postar e cancelar; comprar; recolher correio), com o addon útil em cada resposta, e manter fora de qualquer tecla a venda e a compra no NPC.
