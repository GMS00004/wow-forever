> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# Triagem da onda 3: decisões da sessão principal

Data: 2026-11-16. A sessão principal leu os 169 achados dos nove pareceres (5 bloqueantes, 109 importantes, 55 menores), conferiu por amostra na fonte primária os que criam fato novo e decidiu os conflitos. Este arquivo manda sobre os pareceres: onde ele decide diferente de um achado, vale o que está aqui.

## 1. Regra geral

Todo achado dos nove pareceres está ACEITO e deve ser aplicado como a coluna "correção" manda, com o detalhe que estiver no corpo do parecer, salvo os casos da seção 3 (conflitos decididos) e da seção 4 (ajustes). Achado duplicado entre pareceres se aplica uma vez só, pela versão mais completa. Os "pontos fortes" que cada parecer lista não podem ser perdidos na reescrita.

## 2. O entregável passa a ser dois arquivos

O texto único mistura o que o dono precisa ver com o contrato do agente (achados V5-19, V5-11, V5-12). Vira dois arquivos, na pasta de saída indicada no brief:

**`LEIA-ME.md`, para o dono (de 2.500 a 3.800 palavras).** Estilo do projeto para texto dirigido ao dono: português, prosa densa com vírgulas e parênteses, SEM bullet points, SEM negrito e SEM travessão; tabela só para lista e lista numerada só para passo a passo. Nenhuma referência a projetos ou pareceres do processo (D1 a D6, J1 a J3, V1 a V8). Conteúdo, nesta ordem:
1. O que é, em poucas linhas (régua, fila, mão), e o que nunca faz.
2. O que os fatos dizem hoje: capital, tamanho do mercado, ferramentas que já existem, taxas e durações lidas no cliente, e o que só o jogo responde.
3. Linha do tempo: cada degrau (ler e decidir; onda 0; primeira postagem por tecla; primeira compra; compra para revenda; escala), o que o libera e o mais cedo possível, com a duração marcada como hipótese (V5-12, V7-18).
4. Primeiro dia, em passos numerados e curtos (V5-12): ler, decidir os pontos da tabela, juntar ouro e itens se quiser, esperar a manutenção de 17/11 para o que paga depósito, colar os comandos da sonda, ver os quadros.
5. As suas decisões: tabela com cada decisão que precisa ser tomada antes do código, o padrão já marcado e o que muda se escolher o outro; depois, numa frase, as que ficam para mais tarde.
6. As telas: as cinco visões desenhadas em blocos de caracteres, com a redação nova (V5-14), e o mapa de teclas num desenho de teclado em caracteres. Dizer que há uma página com os quadros renderizados em `pesquisa/telas/` (a sessão principal a produz).
7. A escada de capital: o modelo em uma frase, a tabela dos três cenários e o que mais pesa, tudo marcado como hipótese, sem promessa e sem conselho de como jogar (V8-10).
8. Construir ou adotar: o que justifica o addon próprio e o que não justifica, e quando isso se decide com número (V8-11).
9. O que dá para fazer já pela tela da Blizzard, com a fonte de cada linha e a marca do que pede a aprovação dele (V8-14).
10. Glossário de 10 termos e onde está o resto.

**`DESIGN.md`, o contrato do agente (o texto atual corrigido e completado).** Mantém o estilo de documento técnico do projeto (tabelas, blocos de código, listas). Uma sessão nova tem de conseguir implementar só com ele e com a pasta `pesquisa/`. Índice: o do texto atual (seções 0 a 19 e apêndices), mais as seções novas da seção 5 desta triagem. Tirar toda referência a D1 a D6 e J1 a J3: a seção final "Conflitos abertos" vira "Decisões de projeto e por quê", com os mesmos pontos, descritos pelas alternativas e não por quem as propôs.

Um terceiro arquivo, `MUDANCAS.md`: tabela com uma linha por achado (id, aplicado em qual arquivo e seção, ou "não aplicado" com o motivo). É o que a conferência final usa.

## 3. Conflitos decididos

| # | Assunto | Achados em conflito | Decisão |
|---|---|---|---|
| T1 | Gatilho da varredura | V2-06, V8-03, V6-04, V2-03, I9 | A tecla por fôlego é escolha de desenho, não regra. Vira a decisão DD13, com três opções: (a) uma tecla por fôlego, com teto de buscas e de tempo, que é o padrão das ondas 2 a 4; (b) vigília com presença: o fôlego se renova com qualquer tecla do terminal enquanto a última tecla do dono tiver até `T_pulso` (90 s de partida, nunca acima de 240 s) e para sozinho sem tecla, com tetos `folego.max_s` e `folego.max_buscas` por ciclo: é a recomendação a partir da fase 2, porque sem ela o modo papel só fecha lotes curtos dentro da sessão; (c) contínuo sem presença: recusado. A I9 passa a ser: nenhuma consulta sai sem uma tecla do dono há no máximo `T_pulso`. A conciliação depois de abrir o leilão acontece no primeiro fôlego (`Press L to reconcile`), nunca no evento de abertura. Nova hipótese a medir: consulta do addon não mexe na marca de ausente. |
| T2 | Teclas | V5-02, V5-08, V6-08, V7-15, V7-19, V5-15, V6-09, V5-17 | Mapa proposto, a confirmar na S0 e a aprovar pelo dono vendo o desenho (DD5): `L` Look (abre ou renova o fôlego); `N` próxima e `U` anterior, só navegação; `I` Info e `O` Show N more; `K` Skip (tira a linha da fila até o fim da sessão e grava `skipped`; item pulado três vezes vira candidato a reserva no relatório); `P` Post; `B` Buy (relê, cota a commodity ou arma o item); `C` Cancel, que sempre só arma o bilhete; `Y` Yes, que executa o bilhete que está na tela; `M` Never mind, que desarma o bilhete e cancela a cotação; `H` Hold; `F1` a `F5` visões, com botões clicáveis e, se a S0 mostrar que a fileira F não chega pelo acesso remoto, `Shift+1` a `Shift+5`. Uma tecla faz uma coisa só. Até a S0 e a DD5, `P` também só arma e `Y` executa. Alerta não pede tecla: fica 10 s e passa para a linha `LAST ALERT`. Fora do leilão não há binding: o painel do correio tem só botões clicáveis (`Dismiss` e `Save now`). O comando T da sonda inclui K e M na lista de teclas. Regra do V5-02 mantida: verbo que gasta ou perde depósito não fica em tecla cujo padrão abre painel usado no leilão, e a S0 decide. |
| T3 | Cursor depois de uma ação | V6-10, V8-13, V5-09, V5-08 | A posição do cursor não muda sozinha; a linha concluída sai e a seguinte sobe para a posição do cursor com a marca `NEXT`, e `T_ver` recomeça (uma tecla por lote). `T_ver` reinicia a cada mudança de seleção e de conteúdo da linha. A janela de repetição de 400 ms conta da última pressão RECEBIDA e se renova a cada repetição. A lista só reordena no `L` ou na troca de visão. Resultado esperado do cenário de tecla presa: exatamente uma ação. A rajada conta teclas recebidas. |
| T4 | Intervalo máximo entre fotos | V3A-01 (2 h), V3B-01 (15 min) | `Δ_max` de partida 15 min, faixa de 5 min a 2 h, nunca entre sessões. |
| T5 | Classe B (saída com testemunha) | V3A-01, V3B-01 | Três pares de fotos válidos, em pelo menos 2 dias distintos. Par válido: duas fotos com frente completa, separadas por até `Δ_max`; sumiço que casa com repostagem não conta; em item, leilão visto por último na faixa Short não conta; sem sobrevivente nos degraus guardados o par é censurado. |
| T6 | Fecho do lote de papel e portões | V3A-02, V3A-03, V3A-07, V3A-08, V3B-02, V8-04 | Juntar: o lote de papel acumula exposição observada; fecha "vendeu" quando as vendas inferidas da chave, consumidas em fila pelo lote mais antigo, o enchem; fecha "não vendeu" só com 2 h ou mais de exposição observada; senão fica "inconclusivo" e não conta. Todo sinal ou lote emitido há mais de `T_fecho` (72 h) entra na conta, o aberto marcado a max(preço de vendedor, saída conservadora de hoje) menos custos. Portão: 30 sinais conclusivos em 10 grupos item-dia ou mais, nenhum item com mais de 20% dos sinais, resultado positivo, ainda positivo sem os 3 melhores sinais e sem o melhor item, e razão de somas (realizado sobre previsto antes do desconto) acima do limiar, que é decisão do dono (0,5 de partida, com a nota de que 0,5 reprova metade das estratégias que entregam 0,5). Opção nova na DD1b: micro-sonda (depois de 30 sinais de papel, lotes reais de até 2% por item para medir a saída pela fatura). As chaves com ordem de papel ou lote comprado aberto entram no foco em todo fôlego. Passo novo de sonda: série densa de 30 min em 5 chaves, para calibrar a subcontagem. |
| T7 | Conselho de cancelar | V3A-04, V3B-08, V7-04 | Nas fases 1 e 2 a visão Mine mostra só fatos (quantas unidades mais baratas na frente, tempo restante, depósito em risco) e a palavra `STAND DOWN` quando a regra antiguerra vale. Nenhum ganho de cancelar é calculado nem mostrado. A regra de cancelar fica em sombra, na forma por lote do V3A-04, com as frequências próprias; virar conselho é decisão do dono com fonte. |
| T8 | `W*` | V3B-11, V3A-16 | O `W*` com tabela de probabilidade vai para a fase 3. A comparação de regras em sombra usa desfecho de três valores (venderia, não venderia, desconhecido) e o valor de uma regra pela recursão finita `V_K` com K = 3 e a frequência medida. |
| T9 | Idade da foto para postar | V5-06 (5 min), V7-05 (10 min) | `A_post` de partida 5 min, faixa até 10 min, desde que o preço continue na faixa da 9.2; a linha mostra a idade (`price from 3m ago`). Comprar continua em 30 s. Cancelar usa a foto do próprio leilão no último fôlego. |
| T10 | Ritmo de ações e de buscas | V5-07 (duro 20), V8-02 (sem teto duro) | Vale o V8-02: ritmo não é teto duro. `Config.ritmo.acoes_min` (partida 10, contando verbo concluído, não chamada de função) e `Config.ritmo.buscas_min` (partida 30), com máximo igual ao ritmo sustentado na sonda sem mensagem descartada e nunca acima de 100 buscas. `Tetos.lua` só tem teto de dinheiro. |
| T11 | Regra de preço em commodity | V5-04, V7-09, V1-10 | O V1-10 mudou o quadro: o próprio cliente tem o texto "There's no need to undercut! Auctions posted later (at the same price) are sold first." (conferido pela sessão principal). `igualar` passa a ter fonte que não é opinião de agente: o texto do jogo, mais o contorno do erro de postagem em equipamento. A DD3 mostra as três regras com a fonte de cada uma (igualar: texto do cliente; cobrir: guia de fã; folga: guia de fã) e recomenda `igualar` para equipamento e commodity, citando o texto do cliente; a S10 confirma no Forever. A H-14 muda para: o mais novo vende primeiro, segundo o texto do cliente; a medir. Continua decisão do dono, e sem a escolha dele a linha de commodity mostra `PICK RULE` sem tecla. |
| T12 | Banca e personagens | V5-01, V7-02, V8-07, V8-08, V3A-09, V3A-18 | Postar e cancelar valem em qualquer personagem logado, cada um com o seu Cofre (tetos de depósito sobre o ouro dele, com piso absoluto de teto: o maior entre 5% da banca e um valor do `Config.lua`, 20 prata de partida, decisão do dono). Comprar só no negociador. Decisão nova dentro da DD4: reunir ou não o ouro no negociador, pelo correio, com o clique do dono; piso pessoal de 1 ouro como recomendação, com a nota de que ele deixa parado cerca de um quinto do capital e de que zero é opção. Toda conta de exemplo usa a banca do negociador (cerca de 4 ouro se reunir; 20 a 30 prata por giro com teto de 50% em estoque). Banca zero ou negativa: venda segue, compra para. |
| T13 | Marco de 15 ouro | V8-06 | Sai como condição. Entra a condição medida: o ganho previsto da ordem micro vale pelo menos 3 vezes as teclas vezes o tíquete. Os 15 ouro ficam como opção da DD10, com o custo em dias ao lado. |
| T14 | Identidade de vendedor | V2-01, V2-12, V6-19, V3B-18 | Regra 20: nome de outro jogador nunca é gravado nem mostrado; os personagens do dono são chave do banco. De `owners` grava-se só a contagem de donos distintos e um booleano de que os nomes vieram. A assinatura numérica com sal por sessão (V3B-18) vira decisão do dono para a fase 3, com recomendação de não ligar agora. |
| T15 | Pontes com addons instalados | V2-10 | A seção 14 não nomeia função interna de addon de terceiro. Cada ponte fica "a definir na onda 2, com a assinatura lida no jogo por `/dump` (por exemplo `/dump Auctionator.API.v1`), nunca no código do addon", e o que a base 7 já diz que cada uma oferece. |
| T16 | Fase 3 | V8-01 | Entra a seção 17.1 "Fase 3: a mesa em escala", com o texto proposto no item 4 do parecer V8, ajustado à numeração final das decisões. A linha da onda 6 passa a apontar para ela. |
| T17 | `ReplicateItems` | V6-18, V8-01 | Proibida nas fases 1 e 2 (regra 10); na fase 3, só depois de um passo de sonda próprio e de decisão do dono. |
| T18 | Estratégia `piso` | V2-07 | Fonte: nenhuma fonte de estratégia; ideia dos agentes, com a aritmética da especificação dos modelos. Fica como medição de graça desde a onda 2 e só liga se o dono aprovar a ideia sem fonte ou indicar fonte (entra na DD3). Sai da lista ordenada de fontes de ganho da seção 0. |

## 4. Ajustes a achados aceitos

1. V8-10 e a escada de capital: a seção nova traz o modelo, os três cenários e a sensibilidade do parecer V8, tudo marcado como hipótese. Não aconselha como jogar: o termo "entradas de fora" é só uma grandeza que a régua mede. A comparação com "ouro por hora de farm" de site que vende ouro pode aparecer, com a ressalva de origem, só como o critério que o risco 2 já usa.
2. V5-10: tamanho e posição da janela são hipótese até a S0 ler a resolução; o número proposto vale como partida.
3. V2-05: a DD10 ampliada lista todos os números de política sem fonte (tetos, antiguerra, deriva, ordem da fila, margem mínima, tíquete, limiar do portão) como proposta dos agentes, que o dono aprova, troca ou manda buscar fonte.
4. V5-05: decisão nova de reservas (o agente propõe a lista por personagem a partir dos roteiros de profissão que o dono aprovou; sem aprovação, toda sobra de coleta fica em `KEPT`, com o motivo na linha).
5. V1-04, V5-03, V6-07, V7-06: o Apêndice A traz, por extenso e prontos para colar, os comandos da seção "Comandos da sonda (corrigidos)" do parecer V1 (a sessão principal conferiu que todo nome existe na lista oficial e que o maior tem 245 caracteres), com K e M acrescentados à lista do comando T, e a instrução do aviso "Allow custom scripts?".
6. V6-01 e V7-08: ver a seção 6 desta triagem (pasta permanente e Apêndice D). As fórmulas e tabelas que o texto só citava entram por extenso: regra de cancelar em sombra, preço robusto, filtro de isca, triagem, faixas dos parâmetros.

## 5. Seções novas do `DESIGN.md`

| Seção | Conteúdo | Origem |
|---|---|---|
| 3.4 Escada de capital | modelo, cenários, sensibilidade, o que a régua mede | V8 item 2; V8-10 |
| tabela em 3.1 | construir contra adotar, peça por peça | V8 item 6; V8-11 |
| 8.3, tabela "código de erro, reação" | os 27 códigos agrupados | V7-11, V1-13 |
| 17, onda 0 | o que o dono já pode fazer pela tela da Blizzard, com fonte e situação | V8 item 5; V8-14; V7-18 |
| 17.1 Fase 3: a mesa em escala | gargalo medido, degraus, vigília, carteira, esteiras, portões de máquina | V8 item 4; T16 |
| Apêndice A | coluna "Onda"; comandos por extenso; passos novos (série densa; foco de teclado; arquivo quebrado) | V1, V6, V3B |
| Apêndice B | colunas unidade, faixa e como calibrar; todos os parâmetros usados no texto | V3B-17 e item 6 do parecer V3b |
| Apêndice D: fontes | caminhos permanentes da base e dos relatórios, commit do espelho, origem das tabelas do cliente | V6-01, V7-08 |

## 6. Fontes permanentes (para o Apêndice D e para toda citação)

A sessão principal copia a pesquisa para dentro do projeto. O design cita só estes arquivos:

- Pasta do addon: `C:\GMS\Claude Code Projects\wow\modder\addons-proprios\PregaoForever\` (no texto, `wow/modder/addons-proprios/PregaoForever/`).
- Base de fatos: `pesquisa/base-de-fatos.md` (citada como `base 2.7`).
- Relatórios: `pesquisa/R1a.md`, `R1b.md`, `R1c.md`, `R4a.md`, `R4b.md`, `R5a.md`, `R5b.md`, `R6a.md`, `R6b.md`, `R8a.md`, `R8b.md`, `R9.md`, `R10a.md`, `R10b.md`, `R11a.md`, `R11b.md` (citados como `R9 5.1`).
- Nenhum outro relatório é citado. O texto não descreve nem cita o código interno de addons de terceiros.
- Espelho do código da Blizzard: repositório `Ketho/wow-ui-source-forever`, branch `forever`, commit `bebcb6bf309cf41b41bd74f8ca651e6a105b2676` (mensagem `1.60.1 (70938)`, de 2026-11-13). Para reler: `git clone --depth 1 --branch forever https://github.com/Ketho/wow-ui-source-forever`.
- Strings do cliente: `Ketho/BlizzardInterfaceResources`, branch `forever`, `Resources/GlobalStrings/enUS.lua` (build 70532).
- Tabelas do cliente: `https://wago.tools/db2/<Tabela>/csv?build=1.60.1.70938`.
- Listas oficiais de nomes da API: `wow/modder/ferramentas/guia/api-forever/` (build 70532).

## 7. Fatos novos conferidos pela sessão principal nesta triagem

| Fato | Onde está |
|---|---|
| Texto do cliente: `AUCTION_HOUSE_UNDERCUT_TUTORIAL = "There's no need to undercut!|n|nAuctions posted later (at the same price) are sold first."` | strings do cliente, linha 1291 |
| Texto do aviso de postagem: `CONFIRM_AUCTION_POSTING_TEXT`, manutenção semanal: o item volta antes e o depósito se perde | linha 4861 |
| Texto do cancelamento: `CANCEL_AUCTION_CONFIRMATION = "You will lose your initial deposit by canceling this auction."` | linha 3390 |
| `ERR_AUCTION_DATABASE_ERROR = "Internal auction error."`; `ERR_AUCTION_ITEM_HAS_QUOTE = "This auction can't be canceled because a transaction is pending"` | linhas 7827 e 7836 |
| O primeiro `/run` da conta abre o aviso "Allow custom scripts?" | `DANGEROUS_SCRIPTS_WARNING`, linha 5690 |
| A fatura do correio tem 12 retornos (`invoiceType, itemName, playerName, bid, buyout, deposit, consignment, moneyDelay, etaHour, etaMin, count, commerceAuction`); o recebido é `bid + deposit - consignment`; existe o tipo `seller_temp_invoice`, a carta de venda pendente | espelho, `Blizzard_MailFrame/MailFrame.lua`, linhas 790, 836 e 847 a 856 |
| As SavedVariables gravam e voltam a carregar na máquina do dono | base 3.9 |
| Todos os nomes usados nos comandos corrigidos da sonda existem na lista oficial; o maior comando tem 245 caracteres | conferência por script |

## 8. O que a reescrita não pode fazer

1. Opinião de gameplay: toda estratégia tem fonte e nasce desligada; todo número de política aparece como proposta a aprovar.
2. Promessa de lucro.
3. Descrever ou citar o código interno de addon de terceiro.
4. Perder conteúdo bom do texto atual para encurtar: o contrato pode crescer.
5. Deixar referência a arquivo que não esteja na lista da seção 6.
