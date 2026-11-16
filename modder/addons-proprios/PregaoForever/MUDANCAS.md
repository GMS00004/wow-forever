# Mudanças aplicadas ao design (onda 3)

Uma linha por achado dos nove pareceres. Estado: `aplicado`, `aplicado com ajuste da triagem` ou `não aplicado`. O lugar indica o arquivo e a seção em que a correção ficou (`DESIGN` é o `DESIGN.md`; `LEIA-ME` é o `LEIA-ME.md`).

| Id | Estado | Onde ficou | Nota |
|---|---|---|---|
| V1-08 | aplicado | DESIGN 5.1 (plano A com `sorts` e filtros), 5.2 (de quem é a resposta; de onde vêm as linhas) | resposta de resumo identificada por `AUCTION_HOUSE_NEW_RESULTS_RECEIVED` com payload nil; `..._UPDATED` ignorado fora do estado RESUMO |
| V1-09 | aplicado | DESIGN 5.1 (plano C com `SendSellSearchQuery`), 5.2, 5.3 (duas marcas), 7.2 (referência fraca) | `RequestMore...` conta no orçamento; evento com `newAuctionID` não fecha a espera |
| V1-10 | aplicado com ajuste da triagem | DESIGN 2.1, 2.2 (H-14), 7.2, 18 (DD3); LEIA-ME partes 2 e 5 | T11: o texto do cliente vira a fonte de `igualar`; pior caso mantido só na conta de fila |
| V1-14 | aplicado | DESIGN regra 10; 16 (checador por trecho de nome) | lista proibida ampliada |
| V1-15 | aplicado | DESIGN regra 15; 2.2 (H-19, H-20, H-26); 11.5 | `GetTimePreciseSec` fixado; leitura do foco por `GetCurrentKeyBoardFocus()`, com medida na S12 |
| V1-17 | aplicado | DESIGN regra 14; 6.2 (100 mil entradas; constantes); Apêndice A (S1) | junto com o V6-13 |
| V1-19 | aplicado | DESIGN 2.1 (Depósito, Correio), 2.2 (H-09, H-10, H-12), 7.6 | a sonda fica só com os valores |
| V2-01 | aplicado com ajuste da triagem | DESIGN 5.3 (Nomes), regra 20, 16 (checador) | T14: só a contagem de donos distintos e o booleano |
| V2-03 | aplicado | DESIGN 5.2 (Abertura do leilão), 6.3, 8.3 (INCERTO), 9.4, 16 (cenário) | conciliação no primeiro fôlego, `Press L to reconcile` |
| V2-06 | aplicado com ajuste da triagem | DESIGN 5.2 (tabela das três opções), 18 (DD13); LEIA-ME parte 5 | T1: a opção contínua sem presença aparece como recusada; a vigília com presença é a recomendada a partir da fase 2 |
| V2-07 | aplicado com ajuste da triagem | DESIGN 0, 3.2 (`piso`), 18 (DD3) | T18: sai da lista ordenada; fonte declarada como ideia dos agentes |
| V2-08 | aplicado | DESIGN 3.3 (Vendas) | de 0 direto para micro só com aprovação |
| V2-12 | aplicado | DESIGN regra 20 | junto com o V6-19 |
| V2-15 | aplicado | DESIGN 5.1 (O aviso oficial), 2.1 | |
| V3A-01 | aplicado com ajuste da triagem | DESIGN 3.3 (Venda inferida), 7.4 (classe B), Apêndice C | T4 e T5: `Δ_max` de 15 min; classe B com três pares válidos em 2 dias distintos |
| V3A-02 | aplicado com ajuste da triagem | DESIGN 3.3 (fecho do lote; portões), 10, Apêndice B (`T_fecho`) | T6 |
| V3A-03 | aplicado com ajuste da triagem | DESIGN 3.3 (exposição observada; `inconclusive`), 16 (replay) | T6: o lote sem exposição suficiente fica inconclusivo |
| V3A-05 | aplicado | DESIGN 3.2 (linhas `vao` e `sniper`), 7.4 | os limiares da tabela saem do teste da 7.4 |
| V3A-06 | aplicado | DESIGN 3.3 (Medidas de desvio), 7.4, 7.6 | razão de somas; `δ` gravado |
| V3A-07 | aplicado com ajuste da triagem | DESIGN 3.3 (Papel para micro), 18 (DD10), Apêndice B | T6: o limiar da razão é decisão do dono |
| V3A-08 | aplicado | DESIGN 3.3 (fecho do lote), 9.2, 16 (replay) | consumo em fila, o lote mais antigo primeiro |
| V3A-16 | aplicado com ajuste da triagem | DESIGN 3.3 (Sombra) | T8: recursão `V_K` com K = 3; `W*` para a fase 3 |
| V3A-18 | aplicado com ajuste da triagem | DESIGN 0; LEIA-ME parte 2 | T12: conta com a banca do negociador (20 a 30 prata por giro) |
| V3B-02 | aplicado com ajuste da triagem | DESIGN 3.3 (fecho; `π_react`; vieses), Apêndice A (S11), 16, 19 | T6 |
| V3B-03 | aplicado | DESIGN 5.1 (Chaves de giro), 2.2 (H-30), 6 (`tri`) | filtro declarado; a fórmula virou hipótese com critério de abandono |
| V3B-04 | aplicado | DESIGN 5.1 (O foco), 2.2 (H-07) | cotas do V3B-04 com a prioridade por idade do V4-11 |
| V3B-11 | aplicado com ajuste da triagem | DESIGN 3.3 (Sombra), 7.1 | T8: desfecho de três valores |
| V3B-15 | aplicado | DESIGN 2.2 (H-28), 5.3 (Duas marcas) | |
| V3B-16 | aplicado | DESIGN 3.3 (Papel para micro no `piso`), 17 (ondas 2 e 4) | varredura de prova definida |
| V3B-19 | aplicado | DESIGN 2.2 (H-27), 7.6 (Atraso do correio) | junto com o V7-20 |
| V4-01 | aplicado | DESIGN 5.2, 5.3 (Duas marcas), 8.1 (I6) | a primeira página basta quando cobre a frente |
| V4-02 | aplicado | DESIGN 6.2 (anéis; `abertos`), 12 (opção A copia o arquivo e devolve o recibo) | |
| V4-03 | aplicado | DESIGN 6.3 (Queda), 9.4 | marca de fecho por personagem |
| V4-04 | aplicado | DESIGN 6.3 (Saída limpa; Banco que não carregou), 12, Apêndice A (S1, S13) | `PregaoForeverCharDB.bancoDesde`; TOC na regra 18 |
| V4-05 | aplicado | DESIGN 6 (`epoca`), 6.3, 12 | |
| V4-06 | aplicado | DESIGN 6 (Dois dias), 9.4, Apêndice C | dia de risco e dia de mercado |
| V4-07 | aplicado com ajuste da triagem | DESIGN 6.2 (tabela) | T12: como os outros personagens postam, guardam anel de 500 ações, não só 200 `outside` |
| V4-08 | aplicado | DESIGN 5.3 (foto de item), 6.2 (o que entra e o que sai) | |
| V4-09 | aplicado | DESIGN 6 (`blocos`), 6.2, 7.4 (deriva), 3.2 | junto com o V3B-13 e o V8-12 |
| V4-11 | aplicado | DESIGN 5.1 (O foco) | prioridade `peso · (1 − exp(−idade/Δ_foco))` dentro de cada cota |
| V4-12 | aplicado | DESIGN 5.2 (máquina RESUMO; de onde vêm as linhas) | |
| V4-13 | aplicado | DESIGN 6 (Casa) | |
| V4-14 | aplicado | DESIGN regra 15 | três relógios |
| V4-15 | aplicado | DESIGN 6.1 (último parágrafo) | texto compacto só no disco |
| V4-18 | aplicado | DESIGN 6.1, 12 | versão por linha |
| V4-20 | aplicado | DESIGN 6.2 (O medidor), Apêndice A (S1) | |
| V6-04 | aplicado | DESIGN regra 9 (lista do que é consulta), 5.2, 6.3, 8.3 | junto com o V2-03 |
| V6-05 | aplicado | DESIGN 6.1 | gramática por chave, congelada na onda 1 |
| V6-13 | aplicado | DESIGN regra 14, 16 (checador) | |
| V6-18 | aplicado com ajuste da triagem | DESIGN regra 10, 17.1 | T17 |
| V6-19 | aplicado com ajuste da triagem | DESIGN regras 19 e 20 | T14 |
| V6-20 | aplicado com ajuste da triagem | DESIGN 2.2 (H-14, H-26), Apêndice A (coluna Onda; S12) | T11 mudou a redação da H-14 |
| V7-16 | aplicado | DESIGN 4.3 (modo `papel`), 3.3 (Vendas) | |
| V7-20 | aplicado | DESIGN 2.2 (H-03, H-27), 0, 19 | a H-03 saiu do que derruba o design |
| V8-04 | aplicado com ajuste da triagem | DESIGN 3.3, 5.1 (Vigília), 18 (DD1b, micro-sonda) | T6 |
| V8-05 | aplicado | DESIGN 3.2 (`vao`; Só medição), 17 (ondas 2 e 5) | |
| V8-06 | aplicado com ajuste da triagem | DESIGN 3.2, 17 (onda 5), 18 (DD10), Apêndice B | T13 |
| V8-07 | aplicado com ajuste da triagem | DESIGN 0, 17 (onda 0), 18 (DD4); LEIA-ME partes 2, 4 e 5 | T12 |
| V8-10 | aplicado com ajuste da triagem | DESIGN 3.4, 10 (Medidas), 11.3 (Session); LEIA-ME parte 7 | ajuste 1 da triagem: sem conselho de como jogar |
| V8-11 | aplicado | DESIGN 3.1 (tabela), 18 (DD12 no fim da onda 2), 19 (risco 3); LEIA-ME parte 8 | |
| V8-12 | aplicado | DESIGN 6 (`blocos`, `giro`), 6.2, 17.1 (Banco por degrau) | |
| V8-15 | aplicado | DESIGN 3.1, 7.6 | |
| V8-16 | aplicado | DESIGN 3.2 (Só medição) | |
| V1-01 | aplicado | DESIGN 8.3 (Postar; "O que o aviso é"), 2.2 (H-16), 11.4 B | estado AVISO com `MAINTENANCE: may return early, deposit lost`; `POSTING CLOSED` não é falha |
| V1-02 | aplicado | DESIGN 8.3 (Comprar commodity), 8.2 (guarda do diálogo da Blizzard) | `CancelCommoditiesPurchase` em toda saída, menos em INCERTO; segunda cotação em COTADO |
| V1-03 | aplicado | DESIGN 7.3, 7.4, 15, 2.2 (H-32), Apêndice A (S8) | regra da profundidade da compra em commodity |
| V1-04 | aplicado com ajuste da triagem | DESIGN Apêndice A (comandos da S0), 17 (onda 0; roteiro do primeiro dia); LEIA-ME parte 4 | ajuste 5 da triagem: comandos por extenso, renumerados de 1 a 16, com K e M no comando das teclas e o aviso "Allow custom scripts?" |
| V1-05 | aplicado | DESIGN 8.2 (como o botão e o binding são feitos), 2.2 (H-02), Apêndice A (S2) | `RegisterForClicks("LeftButtonUp")`; `down` verdadeiro ignorado |
| V1-06 | aplicado | DESIGN regra 16, 4.1 (`Teclas.lua`), 8.2, Apêndice A (S2) | ligar e soltar fora de combate; `OnClick` inerte com a janela fechada |
| V1-07 | aplicado | DESIGN 2.1 (Correio), 10 (registro Fatura; "A fatura"), 7.6 (corte) | 12 retornos; carta pendente fora da soma |
| V1-11 | aplicado | DESIGN 2.2 (H-17), 8.3 (Comprar commodity), Apêndice A (S8) | primeira cotação com três argumentos |
| V1-12 | aplicado | DESIGN regra 7, 8.3 (Postar), 2.2 (H-15), Apêndice A (S2, S8) | quantidade 1 em `PostItem`; `AUCTION_MULTISELL_START` vai a INCERTO |
| V1-13 | aplicado | DESIGN 8.3 (tabela "Código de erro, reação") | junto com o V7-11 |
| V1-16 | aplicado | DESIGN 2.2 (H-11), Apêndice A (S7), 10 (Conciliação), 11.3 (Mail) | `MORE MAIL WAITING` |
| V1-18 | aplicado | DESIGN 8.3 (pré-checagens; nomes por extenso), 5.1 (`sorts`; plano D com `Refresh...`), regra 17 | |
| V2-02 | aplicado | DESIGN 10 ("O que o correio não grava"), 4.1 (`Correio.lua`), 16 (checador; fatura com nome) | |
| V2-04 | aplicado | DESIGN 8.2 (Troca de visão; Salvar), 11.3 (Session), 11.4 E, 16 (cenários) | `SAVE BLOCKED - finish or cancel first` |
| V2-05 | aplicado com ajuste da triagem | DESIGN 18 (DD10 ampliada), 0 (proposta de ordem), 9.2, 9.3, Apêndice B; LEIA-ME parte 5 | ajuste 3 da triagem: a DD10 lista todos os números de política sem fonte |
| V2-09 | aplicado | DESIGN 11.5 (Botões para o mouse) | um botão por verbo, `Y` longe |
| V2-10 | aplicado com ajuste da triagem | DESIGN 14 | T15: pontes a definir na onda 2 por `/dump`; nenhuma função interna nomeada |
| V2-11 | aplicado | DESIGN 0, 12 (arquivo morto; "O que sai da máquina"), 17 (onda 1: `.gitignore`) | |
| V2-13 | aplicado | DESIGN 15 (tabela de recusas; regra ou escolha), 18 (DD1c) | |
| V2-14 | aplicado | DESIGN 12 (Dados externos), 18 (DD8) | arquivo separado, apagado com 30 dias |
| V2-16 | aplicado | DESIGN 7.2 (tabela da referência), 15 | referência fraca não propõe preço nem tem tecla |
| V3A-04 | aplicado com ajuste da triagem | DESIGN 7.4 (Cancelar, fórmula por lote em sombra), 11.3 (Mine), 3.3 (Sombra) | T7: nenhum ganho de cancelar na tela; sem termo de tempo |
| V3A-09 | aplicado com ajuste da triagem | DESIGN 9.1, 9.2 (piso absoluto; tabela em cobre), 18 (DD4, DD10) | T12 |
| V3A-10 | aplicado | DESIGN 7.2 (piso de preço; `P*` por lote; casos-limite), 9.2 | |
| V3A-11 | aplicado | DESIGN 7.2 (A frente), 7.4 (Preço robusto), Apêndice B, 16 | `N_ef`; casos de 1, 2 e 5 unidades na bancada |
| V3A-12 | aplicado | DESIGN 7.3 (teto da cotação; `custo_ida`), 11.3 (bilhete) | o exemplo passou a Linen Cloth x16, para fechar com 4 teclas e o tíquete de 15 cobre |
| V3A-13 | aplicado | DESIGN 7.4 (Deriva), 9.3 | a fórmula de custo de carregar ficou registrada para a fase 3, porque o V3B-13 tira a deriva do `EV` |
| V3A-14 | aplicado | DESIGN 7.2 (Veredito; Classe e desfecho), 7.6 | Wilson de 80%; cancelado censurado |
| V3A-15 | aplicado | DESIGN 7.2 (A frente), 2.2 (H-38) | filtro só em escada com 20 unidades ou mais; `next +50%` |
| V3A-17 | aplicado | DESIGN 11.3 (cabeçalho que fecha; `budget used` definido), 10 e 9.4 (gatilho único de 1%), 11.5 (exemplo de 5s 10c) | |
| V3A-19 | aplicado | DESIGN 7.4 (Sobrevivência) | junto com o V3B-12 |
| V3B-01 | aplicado com ajuste da triagem | DESIGN 3.3 (Venda inferida), 7.4 (Classe da saída), Apêndice B (`Δ_max`) | T4 e T5: 2 dias distintos no lugar de 2 blocos de 30 min |
| V3B-05 | aplicado | DESIGN 7.2 (A frente), Apêndice B | condição em ticks; filtro só em commodity |
| V3B-06 | aplicado | DESIGN 7.2 (tabela da referência; A frente), 5.3 | contagem de donos distintos gravada como número |
| V3B-07 | aplicado | DESIGN 7.2 (referência fraca), 5.1 (plano C), 2.2 (H-29), 17 (onda 2, medida) | |
| V3B-08 | aplicado com ajuste da triagem | DESIGN 7.4 (Cancelar), 11.3 (Mine), 11.4 C | T7: só fatos e `STAND DOWN`; sem `KEEP` nem `LET EXPIRE` nas fases 1 e 2 |
| V3B-09 | aplicado | DESIGN regra 17, 7.4 (Saída conservadora), 2.2 (H-39), Apêndice A (comando 8) | |
| V3B-10 | aplicado | DESIGN 7.2 (Veredito; Classe e desfecho; Fila na frente), 7.6 | nível do intervalo: 80% (o V3A-14 traz a conta) |
| V3B-12 | aplicado | DESIGN 7.4 (Sobrevivência), 7.6, Apêndice B | |
| V3B-13 | aplicado | DESIGN 5.3 (`dias`, `blocos`), 6, 7.4 (Deriva), 9.3 | `dias` mantido para a mediana dos mínimos; `blocos` novo |
| V3B-14 | aplicado | DESIGN 9.3 (Parede), 7.4 (Guarda de regime), Apêndice B | |
| V3B-17 | aplicado | DESIGN Apêndice B (unidade, faixa, como calibrar), 7.5 (`T_caixa`), 9.2 (volume), 11.5 | |
| V3B-18 | aplicado com ajuste da triagem | DESIGN regra 20, 5.3, 18 (DD15), 17.1 | T14: assinatura só na fase 3, com recomendação de não ligar agora |
| V3B-20 | aplicado | DESIGN 9.3 (G2), Apêndice B | |
| V4-10 | aplicado | DESIGN 7.3 (3 teclas por compra), 7.5, 5.1 (ordem de envio), 5.2 (idade na linha; custo no tempo) | |
| V4-16 | aplicado | DESIGN 13 | `ns.vend` numérico |
| V4-17 | aplicado | DESIGN 12 (contrato das SavedVariables) | `encodingMode: 'pseudo-latin1'` |
| V4-19 | aplicado | DESIGN 10 (Conciliação) | `BAG_UPDATE_DELAYED` e bandeira suja |
| V5-01 | aplicado com ajuste da triagem | DESIGN 0, 9.1, 11.3 (`ON OTHER CHARACTERS`), 18 (DD4), 17 (roteiro); LEIA-ME partes 2, 4 e 5 | T12 |
| V5-02 | aplicado com ajuste da triagem | DESIGN 11.2 (regras do mapa; desenho do teclado), 8.2; LEIA-ME parte 6 | T2: `C` sempre arma; `P` arma até a S0 e a DD5 |
| V5-03 | aplicado com ajuste da triagem | DESIGN Apêndice A (comando 10; passos por extenso), 17 (onda 0) | T2 e ajuste 5: lista de teclas com K e M |
| V5-04 | aplicado com ajuste da triagem | DESIGN 7.2 (Candidatos), 18 (DD3), 11.3 (`MATCH`, `PICK RULE`) | T11: recomendação de `igualar` com o texto do cliente como fonte |
| V5-05 | aplicado com ajuste da triagem | DESIGN 18 (DD14), 9.1, 11.3 (`KEPT` com motivo); LEIA-ME parte 5 | ajuste 4 da triagem; a decisão ficou com o número DD14 |
| V5-06 | aplicado com ajuste da triagem | DESIGN 8.3 (pré-checagem 6), Apêndice B (`A_post`) | T9: 5 min de partida, faixa até 10 |
| V5-07 | aplicado com ajuste da triagem | DESIGN 9.2 (Ritmo não é teto duro), 0 (Ritmo) | T10: sem teto duro de 20; ação conta verbo concluído |
| V5-08 | aplicado com ajuste da triagem | DESIGN 8.2, 8.1 (I8), 11.2, 11.5 (Latência; Alertas) | T2 e T3: `N` só navega; `M` desarma; alerta some em 10 s |
| V5-09 | aplicado com ajuste da triagem | DESIGN 8.2 (Cursor depois de uma ação), 16 | T3 |
| V5-10 | aplicado com ajuste da triagem | DESIGN 11.1 (Tamanho e posição), 2.2 (H-36), Apêndice A (comando 15) | ajuste 2 da triagem: tamanho como hipótese até a S0 |
| V5-11 | aplicado | DESIGN 0 (O que o dono decide), 18 (coluna Quando), 11.1; LEIA-ME partes 5 e 6 | a página renderizada fica em `pesquisa/telas/`, feita pela sessão principal |
| V5-12 | aplicado | DESIGN 17 (Linha do tempo; Roteiro do primeiro dia), 0; LEIA-ME partes 3 e 4 | |
| V5-13 | aplicado | DESIGN 11.3 (Risk), 9.4 | |
| V5-14 | aplicado | DESIGN 11.3 (todas as telas); LEIA-ME parte 6 | `pays if 1 in 5 sells` (arredonda contra o leilão) no lugar de `1 in 6` |
| V5-15 | aplicado com ajuste da triagem | DESIGN 11.2, 11.3 (Mail), 4.1 | T2: sem binding fora do leilão; botões `Dismiss` e `Save now` |
| V5-16 | aplicado | DESIGN 18 (DD2), 14, 17 (lista da onda 0) | |
| V5-17 | aplicado com ajuste da triagem | DESIGN 11.2 (Visões), 2.2 (H-37), 17 (roteiro, passo 8) | T2: `Shift+1` a `Shift+5` como reserva |
| V5-18 | aplicado | DESIGN 18 (DD9), 11.5 | |
| V5-19 | aplicado com ajuste da triagem | LEIA-ME inteiro; DESIGN preâmbulo e "Decisões de projeto e por quê" | seção 2 da triagem: dois arquivos |
| V6-01 | aplicado com ajuste da triagem | DESIGN Apêndice D, Apêndice A (comandos), 7.4 (fórmulas), 5.1 (triagem), Apêndice B (faixas), 13 | ajuste 6 e seção 6 da triagem |
| V6-02 | aplicado | DESIGN 17 (onda 2), 4.1 (coluna Onda) | |
| V6-03 | aplicado | DESIGN 4.1 (coluna Onda), 17 | |
| V6-06 | aplicado | DESIGN 9.2 (classe `sonda`), Apêndice A (preâmbulo; S1), 6.2 (`sonda.lastro`) | |
| V6-07 | aplicado | DESIGN Apêndice A (comandos 10 e 16), 2.2 (H-18) | |
| V6-08 | aplicado com ajuste da triagem | DESIGN 11.2, 8.2 | T2: a tecla de desistir é `M`; `K` é pular |
| V6-09 | aplicado com ajuste da triagem | DESIGN 4.1 (`Alertas`, `Janela`), 11.2, 11.3 (Mail) | T2: nenhuma tecla fora do leilão |
| V6-10 | aplicado com ajuste da triagem | DESIGN 8.2 (Repetição; Cursor depois de uma ação), 16 | T3: a linha seguinte sobe com `NEXT`, em vez de seleção vazia |
| V6-11 | aplicado | DESIGN 17 (rota; duas tabelas) | |
| V6-12 | aplicado | DESIGN 16 (itens 1 a 9; tabela de chamadas; cenários) | |
| V6-14 | aplicado | DESIGN 16 (Onde ficam) | |
| V6-15 | aplicado | DESIGN Apêndice A (S6), 16 (critério de aceite) | |
| V6-16 | aplicado | DESIGN 17 (onda 1; pronto das ondas 2 e 3), 11.1 | |
| V6-17 | aplicado | DESIGN 11.5, 10, 9.4 | 45 min ou 50 ações; 1% de `B`; 24 horas |
| V7-01 | aplicado | DESIGN 8.3 (pré-checagem 3), 8.1 (I8), 16 | `BAG CHANGED` |
| V7-02 | aplicado com ajuste da triagem | DESIGN 9.1, 18 (DD4), 0; LEIA-ME partes 2 e 5 | T12 |
| V7-03 | aplicado | DESIGN 10 (A janela; registro `Fora`), 9.4, 16 | junto com o V8-09 |
| V7-04 | aplicado com ajuste da triagem | DESIGN 7.4 (Cancelar), 11.3 (Mine), 11.4 C, 18 (DD3) | T7 |
| V7-05 | aplicado com ajuste da triagem | DESIGN 8.3 (Postar), Apêndice B (`A_post`), 11.3 | T9: 5 min de partida |
| V7-06 | aplicado | DESIGN 11.2, Apêndice A (S0), 17 (roteiro, passo 7) | |
| V7-07 | aplicado | DESIGN 9.4, 12 (`Config.lua`), Apêndice B (`destravas`) | |
| V7-08 | aplicado | DESIGN Apêndice D, Apêndice A | junto com o V6-01 |
| V7-09 | aplicado com ajuste da triagem | DESIGN 18 (DD3), 7.2, 2.2 (H-14) | T11 |
| V7-10 | aplicado | DESIGN 7.3 (lote de confirmação), 10 (Fechamento de lote), 14 (Leatrix Plus), 16 | |
| V7-11 | aplicado | DESIGN 8.3 (tabela "Código de erro, reação", os 27 códigos) | |
| V7-12 | aplicado | DESIGN 8.3 (`AUCTION_HOUSE_CLOSED` em cada máquina), 8.2 (Salvar), 11.4 E, 2.2 (H-35), Apêndice A (S1) | |
| V7-13 | aplicado | DESIGN 12 (Modos diante dos arquivos), 4.3, Apêndice A (S13), 16 | |
| V7-14 | aplicado | DESIGN 7.6 (parágrafo de abertura), 9.4 | `GAME NUMBER CHANGED` |
| V7-15 | aplicado | DESIGN 11.2 (`K`), 10 (relatório de sessão), 7.5 | |
| V7-17 | aplicado | DESIGN 7.2 (Duração e lote), "Decisões de projeto e por quê" (22 e 23) | |
| V7-18 | aplicado | DESIGN 17 (lista da onda 0; coluna de duração; linha do tempo); LEIA-ME partes 3 e 9 | |
| V7-19 | aplicado com ajuste da triagem | DESIGN 8.2 (Rajada), 11.2, 16 | T2: `N` só navega, então não há ordem de papéis a fixar |
| V8-01 | aplicado com ajuste da triagem | DESIGN 17.1, 17 (onda 6), 18 (DD12) | T16: os degraus passaram a se chamar degrau 0 a 3 |
| V8-02 | aplicado com ajuste da triagem | DESIGN 9.2 (Ritmo não é teto duro), regra 13, 5.2 | T10 |
| V8-03 | aplicado com ajuste da triagem | DESIGN 5.2, 8.1 (I9), regra 9, 18 (DD13) | T1 |
| V8-08 | aplicado com ajuste da triagem | DESIGN 9.1, 9.2 (piso absoluto), 18 (DD4, DD10) | T12 |
| V8-09 | aplicado | DESIGN 10 (registro `Fora`), 9.4, 11.3 (Session) | |
| V8-13 | aplicado com ajuste da triagem | DESIGN 8.2, 8.1 (I8), 11.4 (A6, B5, C2) | T3 |
| V8-14 | aplicado | DESIGN 17 (tabela "O que o dono já pode fazer"); LEIA-ME parte 9 | |

## Conferência final (onda 4)

Três conferentes leram o texto corrigido achado por achado: 167 dos 169 estavam aplicados, 2 parciais, e eles apontaram contradições novas, nascidas da reescrita. A sessão principal conferiu cada ponto no texto e corrigiu assim:

| Ponto | Onde ficou | O que mudou |
|---|---|---|
| V8-13 (parcial) | DESIGN 11.4, fluxo C, passo 2 | Depois de `CANCELLED` a linha sai, a seguinte sobe com a marca `NEXT` e `T_ver` recomeça, como nos fluxos A e B |
| V4-07 (parcial) | DESIGN 6.2 | Mantido o anel de 500 ações, 100 lotes e 100 faturas nos personagens que não compram: como eles postam e cancelam, o anel de 200 ações `outside` do parecer não bastava |
| Ritmo com cara de teto | DESIGN 9.2; Apêndice B (`ritmo.acoes_min`) | A faixa "1 a 20" saiu: 10, 15 e 20 são os degraus previstos e o máximo é o que o portão de máquina liberar |
| Tecla de salvar sem onda | DESIGN 4.1 (linha 20); 17 (onda 2) | O `Y` de salvar da visão Session entra na onda 2; ele chama `ReloadUI`, nenhuma função de ação |
| Padrão da regra de preço | DESIGN 18 (abertura, DD3); Apêndice B; LEIA-ME parte 5 | "Recomendado" é o que o agente grava se o dono disser "pode seguir"; antes da resposta vale o valor de partida, que é `PICK RULE` em commodity |
| Dois sentidos na tecla `H` | DESIGN 9.4 | `H` é um alternador entre `KEYS ON` e `KEYS HELD`; a rajada só põe em `KEYS HELD` |
| S11 antes da DD13 | DESIGN Apêndice A (S11) | A série densa não decide o gatilho: roda com um sim do dono só para o passo, ou com `L` a cada ciclo |
| Duas réguas de sobrevivência | DESIGN 7.4; Apêndice B | O portão de 70% olha a estratégia inteira; o limiar de 0,5 vale depois, faixa por faixa |
| Piso absoluto fora do `Tetos.lua` | DESIGN 9.2; Apêndice B | Os pisos de 20 e de 8 prata passam a ser constantes de `Tetos.lua`; o `Config.lua` só os baixa |
| Regra 19 contra o banco e a mesa | DESIGN 1 (regra 19) | Quem grava as SavedVariables é o cliente do jogo; a mesa grava só o `Calibrado.lua` e o arquivo morto |
| Nome antes do código | DESIGN 0, 17 (portões), 18 (DD6); LEIA-ME parte 5 | O nome tem padrão (PregaoForever) e só pede resposta se o dono quiser outro |
| Contagem dos tetos na visão Risk | DESIGN 11.3; LEIA-ME parte 6 | `Show 7 more`: são 10 tetos de consumo e 3 aparecem |
| Fotos por chave na fase 3 | DESIGN 17.1 (tabela do banco) | Degraus 0 e 1 com 16 fotos na fase 1 e 48 na fase 2, como na seção 6.2 |
| INCERTO e o correio | DESIGN 8.3 | A conciliação pelo correio usa a leitura que o painel já faz, sem tecla; a faixa `Press L to reconcile` só existe com o leilão aberto |
| Um número da escada | DESIGN 3.4 | "C1, só trading, 250 ouro" passou de 589 para 590 dias (conta refeita à parte) |

Conferências por script, feitas sobre o texto final: os 169 ids estão nesta tabela; os 498 nomes de função, evento, enum e texto do cliente citados no `DESIGN.md` existem no espelho da interface, nas listas oficiais do projeto ou no arquivo de textos; os 16 comandos da sonda têm de 54 a 245 caracteres e parênteses, aspas e blocos fechados; toda hipótese, decisão, passo de sonda e invariante citado tem definição; as tabelas da seção 3.4 foram recalculadas por um script independente.

## Varredura de consistência (onda 5)

Depois da conferência, sete leitores só-leitura releram o `DESIGN.md` e o `LEIA-ME.md` inteiros, cada um por uma lente (parâmetros; teclas, telas e fluxos; ondas, decisões e sonda; regras e invariantes; contas; banco e contratos; o LEIA-ME contra o contrato). Voltaram 58 achados, 53 distintos. A sessão principal conferiu cada um no texto: 52 viraram mudança e 1 virou só explicação, porque o número estava certo.

| Tema | Onde ficou | O que mudou |
|---|---|---|
| Consulta dentro do fôlego (o achado mais grave) | DESIGN 1 (regra 9), 4.3, 5.2, 8.1 (I9), 15, 16 | A regra dizia "nenhum evento dispara consulta", e a máquina de varredura pede a consulta seguinte na resposta da anterior. Agora: nenhum evento ou timer abre fôlego nem consulta fora de fôlego aberto por tecla; dentro dele, a resposta pede a seguinte. O checador confere que a consulta só existe em `Pedidos.lua`; o resto é da bancada |
| Conciliação depois de uma ação | DESIGN 4.2, 5.2, 8.3 | O fôlego curto nasce na tecla da ação e dura até ela fechar ou até `T_pulso`; as duas consultas de conciliação saem dentro dele |
| Nível concedido e suspensão | DESIGN 1 (regra 13), 3.3, 8.1 (I7), 16 | "Só desce dentro do jogo" vale para o nível concedido (licença e evidência). Disjuntor suspende e, ao destravar, devolve no máximo o concedido |
| Tetos duros contra a tabela de parâmetros | DESIGN Apêndice B | Preço de postagem (até 3 vezes) e volume diário (até 10%; 2 horas mínimas) deixaram de ter faixa acima do duro |
| Escrita em `WTF` | DESIGN 1 (regra 19) | Exceção escrita: os scripts do modder, com o jogo fechado, backup e ok do dono (DD2 e S13) |
| Recusas que são padrão, não regra | DESIGN 15 | Tecla em botão da Blizzard e correio por tecla são padrão que o dono pode rever na DD1c; `:Click()` e macro continuam recusa |
| Sonda de compra | DESIGN 16; Apêndice A | A S8 só roda com a DD1b em sim; S2 e S6, com a DD1a |
| Checagem das regras | DESIGN 16 | Cada regra passou a ter dono: checador novo, checadores do projeto ou revisão no portão |
| O que a onda 2 mede | DESIGN 0, 3.2, 17 | O addon grava as fotos; as medidas da linha de base são conta do agente fora do jogo, e a contagem de vãos e arremates começa na onda 3 |
| Três sessões para construir ou adotar | DESIGN 17 (portão da onda 2) | A linha de base passou de uma para três sessões, que é o que a DD12 pede |
| Módulos sem onda | DESIGN 4.1, 17 | Disjuntores do Cofre na onda 3; `Motor` nas ondas 4 e 5; visão Mine da onda 2 sem `LIMITS` nem `STAND DOWN`; grupos de cenário `venda` e `papel` na onda que constrói o módulo |
| Linha do tempo | DESIGN 17; LEIA-ME partes 3 e 4 | Uma etapa a cada 1 a 4 dias; primeira postagem de 25 a 28/11; os quadros do primeiro dia são a primeira versão, e a aprovação final fecha na onda 1 |
| Escada de capital | DESIGN 3.4; LEIA-ME parte 7 | Os dias contam a partir da compra ligada com ouro, não de hoje; a taxa composta é o produto da fração, das voltas e da borda, e não de "quatro fatores de mesmo peso" |
| Banco | DESIGN 5.3, 6, 6.1, 6.2, 10 | Quantidade total na foto de commodity; chave do item na fatura; bilhete na linha da ação; gargalo na sessão; formato das amostras; tabela `npc`; um nome por estado de lote; o tempo restante de commodity saiu da foto |
| Tamanhos do banco | DESIGN 6.2, 17.1 | Só explicação: 370 e 1.050 KB são medidas de um arquivo gerado (foto média de 385 bytes na fase 1 e de 360 na fase 2), não o produto simples |
| Estados do ouro | DESIGN 9.1 | Quatro estados, como no cabeçalho; o ouro de uma cotação aberta fica reservado dentro do livre |
| Palavras de estado | DESIGN 8.3 | `READY` no bilhete armado; `PRICE MOVED` e `POSTING CLOSED` saíram de "falhou" para "volta sem falha" |
| Telas | DESIGN 11.3; LEIA-ME parte 6; quadros | Exemplo de `PICK RULE` em outra classe de item; os três limites em ordem de proximidade; 11 cartas no painel do correio; a Next do LEIA-ME igual à do contrato; linhas sem tecla no fim da fila (7.5); regra das 5 linhas com a exceção de altura |
| Fase 3 | DESIGN 17.1; Apêndice B | `VENDOR` e `LET EXPIRE` sem tecla; parâmetros de degrau e de gargalo na tabela |
| O LEIA-ME contra o contrato | LEIA-ME partes 1, 3, 4, 5, 6 e 8 | O relatório de sessão vai a um serviço de nuvem; a compra depende também da aprovação da compra abaixo do vendedor; o comando 16 pede preparo; nem toda decisão tem padrão; a justificativa da fila e a da mão voltaram ao lugar |

O que esta rodada mostra: a reescrita ainda tinha emendas soltas, e a varredura não voltou vazia. Por isso houve uma segunda, abaixo.

## Segunda varredura de consistência (onda 6)

As mesmas sete lentes releram o texto já corrigido. Voltaram 30 achados, 28 distintos, nenhum bloqueante e 12 importantes (na primeira tinham sido 58, com 1 bloqueante). A sessão principal conferiu cada um e mudou o texto nos 28.

| Tema | Onde ficou | O que mudou |
|---|---|---|
| O ciclo e a tecla recente | DESIGN 5.2 (máquina e envio); Apêndice B | `Pedidos.lua` confere antes de cada envio se há tecla nos últimos `T_pulso` segundos; sem ela o ciclo para, em qualquer opção de gatilho |
| O que conta no ritmo | DESIGN 5.2 | O ritmo e o teto de buscas contam as buscas por item; as páginas do resumo seguem só o throttle do cliente e o tempo do ciclo. Era o que faltava para o "ciclo de cerca de 50 s" fechar |
| A cotação e o INCERTO | DESIGN 8.1 (I5), 8.2, 11.5, 16 | Cotação sem resposta volta ao sinal com `PRICE MOVED`: é a exceção declarada da regra "ação sem eco vira INCERTO". A tecla da cotação mostra `QUOTING`, não `SENT` |
| Classe `sonda` | DESIGN 9.2; Apêndices A e B | "Uma ordem por passo" impedia os passos que postam e cancelam: passou a "só as ordens que o passo prevê, uma por tecla" |
| Onde vivem as leituras do jogo | DESIGN 7.6, 12; Apêndice B | Corte, devoluções, atraso e cadência são adotados pelo addon em `calib`, com faixa de sanidade, e não passam pelo `Calibrado.lua` |
| Banco | DESIGN 6.1, 6.2, 10 | Hora da foto na linha da ação; amostras de "já sumiu" e de sombra com formato; build em toda amostra; classes de equipamento de e1 a e4; anéis menores nos personagens que só vendem; dois exemplos da gramática corrigidos; o campo `fora` da sessão |
| Quem conta vãos e arremates | DESIGN 3.2 | Um script de análise do agente, a partir da onda 3; os arquivos puros só ganham essa parte na onda 5 |
| Cenários com cotação | DESIGN 16 | Saíram do grupo da onda 3 e foram para o grupo `comprar`, da onda 4 |
| Relógio do dia de risco | DESIGN 1 (regra 15) | A hora local da máquina é a única exceção ao relógio do servidor, e só para o dia de risco |
| Vigília e política | DESIGN 5.1, 18 (DD10); Apêndice B | Vigília acima de 8 chaves; quem decide o ritmo de partida; disjuntores e dia de risco na lista da DD10 |
| Contas | DESIGN 3.4, 17.1 | Sem reunir o ouro a banca é de cerca de 27 prata, não zero; uma volta na fase 3 são 250 ações e 625 teclas, não 375 ações |
| Botões para o mouse | DESIGN 11.5 | "Vizinhos" e "o Y longe" não cabiam juntos: lado a lado, com o `Y` separado por um vão |
| O aviso de scripts | DESIGN 2.1 | Vale para `/run` e para `/dump`, conferido no código da Blizzard: o roteiro do primeiro dia já estava certo |
| O LEIA-ME contra o contrato | LEIA-ME partes 2, 4, 5 e 7; DESIGN 17, 18 | Qual personagem compra não tem padrão; os números de política vêm antes do código da postagem; o depósito mínimo é anúncio da Blizzard, não leitura do cliente; a escada parte dos 5 ouro e 9 prata de hoje; a lista do que fica para depois ganhou a postagem de várias unidades por tecla |

A segunda rodada trouxe metade dos achados da primeira e nenhum bloqueante. Não houve terceira: o que sobrar aparece na onda 1, quando o contrato vira `ARQUITETURA.md` e a gramática do banco é congelada.
