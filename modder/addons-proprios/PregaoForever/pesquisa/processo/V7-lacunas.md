> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# V7-lacunas: parecer do revisor pela lente 'o que falta'

Data: 2026-11-16. Revisor V7. Design revisado: `designs/SINTESE.v1.md` (934 linhas, lido inteiro). Linhas citadas como 'SINTESE linha N' são desse arquivo.

**O que li e como.** Inteiros: o design, a base de fatos e os três pareceres (J1, J2, J3). Dos seis projetos: o D1 até a seção 6.3 por inteiro; dos outros cinco, as seções que os juízes apontam como enxerto ou defeito e buscas por tema (falha de API, bolsa, queda, reload, onda 0, postagem-sonda, lote, erros do leilão, banca, negociador, dinheiro sem explicação). Não li os seis por inteiro: o limite de contexto desta sessão não deixou. Onde afirmo que uma ideia caiu, conferi a ausência por busca no texto da síntese. Relatórios abertos para conferir citação: R1a, R1b (seções 4 a 8, 10 a 16 e incógnitas, inteiras), R1c, R4a, R4b, R5a, R5b, R6a, R6b, R8a, R8b, R9, R10a, e o espelho (`Blizzard_MailFrame`). Não li R2a, R2b, R3a, R3c, R3d, R7a, R7b, código de addon de terceiro nem os pareceres dos outros revisores. Nada foi testado no jogo.

**Resumo.** Nenhum achado bloqueante. Treze importantes e sete menores. As citações são boas: de 44 conferidas, 40 sustentam a frase, 2 sustentam em parte e 2 não sustentam. O que falta está no dia de uso, não na teoria.

## 1. Ideias dos projetos que a síntese deixou cair, enfraqueceu ou só declarou

Método: parti da lista de enxertos que cada juiz pediu (seção 3 de J1, J2 e J3) e procurei cada um no texto da síntese; depois busquei nos projetos os temas de falha que a síntese não trata.

### 1.1 Caíram sem justificativa

| Ideia | Onde estava | Quem pediu | Situação na síntese |
|---|---|---|---|
| Pergunta ao dono: junta o ouro dos quatro personagens no negociador? ('Banca de 4 ouro ... se o ouro for reunido') | D4 10, decisão 2 (linha 761) | é da própria espinha | A DD4 ficou só com 'um só negociador' e 'piso de 1 ouro'. Achado V7-02. |
| Tabela de reação por código de `AUCTION_HOUSE_SHOW_ERROR` (`NotEnoughMoney` recalcula a banca; `IsBusy` e `DatabaseError` pedem nova tecla depois de 5 s) | D6 7 (linha 525) | implícito em J1 | A 8.3 manda todo `SHOW_ERROR` para `FALHOU`; só três códigos têm tratamento. Achado V7-11. |
| Hipóteses 'o `/reload` fecha a casa?' e 'um arquivo de dados com erro de sintaxe isola os outros?' | D3 3.6 (linha 265), sonda S6 (linha 553), risco 2 (linha 606) | J1 (D3 enxerto 4: 'incógnitas que só ele levanta') | A H-19 só pergunta se `ReloadUI` é aceito do clique e quanto demora. Achados V7-12 e V7-13. |
| Alarme quando o medido diverge do lido ('Alarme se divergir') | D1 4.5 (linha 352) | J1 (D1 enxerto 5: a tabela do diário) | A 7.6 só diz quando um parâmetro 'vira medido'. Achado V7-14. |
| Tecla de dispensar a recomendação, gravando 'recusou' | D1 6.2 (linha 425) | ninguém | Não há tecla de pular. Achado V7-15. |
| Lote do tamanho da demanda enquanto na frente (`n*`), no lugar do estoque inteiro à mostra | D6 4.4 (linha 304), D3 4 (linha 303); R9 4.5 | J2 (D6 enxerto 6) | A 7.2 posta 'o lote da pilha'. O R8b R14 é citado na 3.2 e não vira regra. Achado V7-17. |
| Postagem-sonda de 1 unidade (quem cobre e em quanto tempo, pelo custo de um depósito) | D6 2 (linha 43) e 4.2 C | J1 (D6 enxerto 3), J2 (D6 enxerto 3) | Não aparece, nem como recusa. O conflito 19 só trata do E7. Achado V7-17. |
| Ouro na mão antes de existir addon, e calendário das ondas | D5 9 (linhas 518 e 526) | J2 (motivo principal da nota 8 de lucro) | A onda 0 da seção 17 só cola comandos e grava decisões; não há data nem duração. Achado V7-18. |
| `SearchForItemKeys` em lote, como hipótese de API | D6, sonda S4 (linha 566) | J1 (D6 enxerto 6) | Não aparece. Sem achado: o plano C vive sem ela. |
| Mapa do que cabe no bolso (itens cujo lote cabe no teto e têm taxa de venda mínima) | D3 3.8, item 5 (linha 288) | J2 cita ao dar a nota | Não está no relatório de sessão da seção 10. Sem achado próprio; cabe numa linha da seção 10. |
| Lote de confirmação de 1 unidade | D4 5 E2 | J1 (D4 enxerto 4), J2 (D4 enxerto 2) | Virou 'até 2% da banca' (7.3 e 9.2). Para conferir a H-21 basta 1 unidade. Sem achado próprio; sugiro 'a primeira compra de cada item é de 1 unidade ou 1 pilha, o que for menor, até 2% da banca'. |
| Bilhete com o pior caso | D4 6.2 e 6.4 | J3 (D4 enxerto 4) | O bilhete mostra total, teto, fração e saída. Sem achado. |

### 1.2 Declaradas como enxertadas, mas não desenhadas

| Ideia | O que a síntese diz | O que falta |
|---|---|---|
| Regra de cancelar do R9 4.6 | 7.1 e 7.4: entra na fase 2; a visão Mine já dá `CANCEL +36c` | A regra usa `P` e `W*`, que a 7.1 deixa fora ou em sombra. Não há regra para o conselho na fase 1. Achado V7-04. |
| Postar em uma tecla (conflito 2) | 'Postar e cancelar em uma tecla' | A foto de até 30 s exigida na 8.3 transforma quase toda postagem em duas teclas. Achado V7-05. |
| Conferência dos padrões de tecla pela sonda | 11.2: 'a sonda S0 confere' | Os comandos indicados não leem binding. Achado V7-06. |
| Modo treino do D2 | Conflito 19: 'vira `modo = "papel"`' | O papel só está descrito para a tecla de compra. Achado V7-16. |
| Disjuntor de rajada do D2 | 8.2: 6 teclas de ação em 2 s | Com a repetição de 400 ms e o `T_ver`, 6 teclas aceitas em 2 s não acontecem. Achado V7-19. |
| Destrava de disjuntor por arquivo (D4) | 9.4: 'destrava: sessão do agente' | Não há campo no `Config.lua` nem canal para isso. Achado V7-07. |
| Bordas lentas do D1 | 7.4: vida medida das ofertas contra o tempo de reação | A vida das ofertas pede fotos seguidas da mesma chave, e o fôlego nasce de tecla. Já está no risco 5 da seção 19. Sem achado. |

### 1.3 Enxertos conferidos e presentes

Invariantes e Cofre (D4), licença em quatro níveis, `Tetos.lua`, INCERTO, correção do `η_real` (D3), recibo e sentinela (D3), modos `DESK OK`, `STALE` e `NO DESK`, `T_ver` com latência (D2), cursor estacionado (D2), `W*` em sombra (D2), quadros em HTML (D2), `P*` em palavras (D5), colunas 'Mede' e 'Para se' (D5), régua que mede o que é feito por fora (D5), preço-sombra do capital, deriva por categoria e duas testemunhas (D1), G1 e G2 sem nome (D6), mercado sintético com agentes plantados (D6), ordem entre preços iguais só por medida passiva, DD1 partida em três perguntas (J3), ficha de evidência, autópsia e pauta (D3).

## 2. Citações conferidas (44)

Veredito: **sim** = a fonte diz aquilo; **em parte** = diz menos do que a frase; **não** = não diz.

| # | Onde no design | Citação | Veredito e o que a fonte diz |
|---|---|---|---|
| 1 | 0 | (base 4.1) 50.912 cobre somando quatro personagens | sim |
| 2 | 0 | (base 1.8) ouro volta em cerca de 1 hora | sim |
| 3 | 0, item 1 | (base 4.5) 'única linha com fonte de economia já aprovada' | em parte: a base 4.5 aprova vender verdes bons; a venda das sobras dos quatro personagens espera a DD3 (linha 129 do próprio design) |
| 4 | regra 14 | (R4a 4) bancada em fengari, Lua 5.3 | sim (R4a linha 138) |
| 5 | regra 15 | (R9 11.1) fatia por tempo | sim (seção 'Fatia por quadro') |
| 6 | regra 18 | (R4a 3; R4a 6) primeiro nível; reinício para arquivo novo | sim (R4a linhas 124 e 214) |
| 7 | 2.1, cuidado | (R5b 2a, 2b) materiais de nível baixo subindo | sim (R5b linha 75: Copper Ore +41%, Light Leather +19%) |
| 8 | H-03 | (R6b incógnita 4) relatos contrários de builds antigas | sim; mas a base 3.9 `[gate]` já conferiu a gravação nesta máquina (achado V7-20) |
| 9 | H-06 | (R1b 14) a Blizzard chama consultas de evento | sim (R1b linhas 365 a 373; o relatório marca como inferência) |
| 10 | H-08 | (R1b 8) a lista relê os resultados a cada evento | sim (R1b linha 233) |
| 11 | H-10 | (R1a evento 10) `AUCTION_HOUSE_ITEM_DELIVERY_DELAY_UPDATE` | sim (R1a linha 188: traz atraso de item comprado e de item cancelado) |
| 12 | H-11 | `MailFrame.lua` 573 a 576 e 790 | sim (espelho, linhas 576 e 790: `GetInboxInvoiceInfo(InboxFrame.openMailID)`) |
| 13 | H-14 | (base 2.17) 'vende primeiro o mais antigo' | não: a base 2.17 diz que as fontes relatam o contrário (o mais novo vende primeiro); R8a linha 56 repete ('Last-In-First-Out'). A citação só sustenta 'é parâmetro a medir' (achado V7-09) |
| 14 | H-15 | (R1b 6) multisell | sim (R1b linhas 158 a 163) |
| 15 | H-16 | (R1b incógnita 7) o que dispara o aviso | sim (R1b linha 431) |
| 16 | H-17 | (R1b 4) terceiro argumento | sim (R1b linhas 101 a 103) |
| 17 | H-18 | (R1b incógnita 6) duração da cotação | sim (R1b linha 430) |
| 18 | H-19 | (R1c 13) `ReloadUI` existe | sim (R1c linha 269) |
| 19 | H-20 | (R1c 5) `GetTimePreciseSec` | sim (R1c linha 114) |
| 20 | H-23 | (R5a 2.5) sem restrição de nível achada | sim (R5a linha 110) |
| 21 | 3.1 | 42% hoje e 18% depois de 17/11 | sim, conta refeita: `P* = d/(190 − 50 + d)`; d = 100 dá 41,7%; d = 30 dá 17,6% |
| 22 | 3.2 `venda_sobras` | (R8b R4, R7, R8, R14, R15; R4b 4) | sim (R8b linhas 177 a 188; R4b linha 53) |
| 23 | 3.2 fora | (R9 6.3) reset com valor esperado negativo | sim (R9 linha 1404, QNT-10) |
| 24 | 3.2 fora | (R9 10.2) lance sem teste por fotos | sim (R9 linha 1108) |
| 25 | 3.2 fora | (R8a F18) a fonte desaconselha equipamento | sim (R8a linha 90) |
| 26 | 3.2 `conversao` | (R4b 5e) produto que não vincula | sim (R4b linha 118: equipamento fabricado é BoP) |
| 27 | 5.2 | (R1a eventos 39 e 44) o evento traz chave ou `itemID` | sim (R1a linhas 217 e 222) |
| 28 | 7.2 | (R9 1.2) isca: 5% e salto de 15% | sim (R9 linha 1299) |
| 29 | 7.2 | (R1b 7) tick de 1 cobre ou 1 prata | sim (R1b linhas 189 a 200; o valor no Forever é incógnita 9) |
| 30 | 7.2 | (R8a ficha 2, F5) cobrir; (R8b R6) folga | sim (R8a linha 85; R8b linha 179) |
| 31 | 7.4 | (R9 4.6) regra `Δ_canc` | sim, a regra existe; ela usa `P` e `W*` (achado V7-04) |
| 32 | 8.3 | (R1b 4) aguarde depois de 2 s | sim (R1b linha 110) |
| 33 | 8.3 | (R1b 14) `CancelCommoditiesPurchase` de evento e timer; `PlaceBid` só em popup | sim (R1b linhas 358 a 362) |
| 34 | 8.3 | (R1a função 63) `IsSellItemValid` | sim (R1a linha 88). Nota: o segundo argumento, `displayError`, vale `true` por padrão; o contrato deve passar `false` |
| 35 | 9.2 | (R9 7.7) Kelly sensível | sim (R9 linha 905) |
| 36 | 9.3 | (R8a F23; R8b R7) apoio de G1 e G2 | em parte: F23 fala de isca e de corte até lucro zero; R7 diz 'undercuts land within minutes ... recheck each session'. Nenhuma fonte propõe teto de cancelamentos; os números são do projeto |
| 37 | 9.4 | (R1a 3; R1b 15) `AUCTION_HOUSE_DISABLED`, restrição | sim (R1a linha 159; R1b linhas 391 e 392) |
| 38 | 10 | (R1c) `MERCHANT_SHOW` e `PLAYER_MONEY` | sim (R1c linhas 220 e 102) |
| 39 | 11.4 D | `MailFrame.xml:444` Open All Mail | sim (espelho, linha 444) |
| 40 | 11.5 | (R10a 4, inferência) som pode não atravessar | sim (R10a linha 111) |
| 41 | 14 | (R4b 2) BugGrabber instalado | sim (R4b linha 25) |
| 42 | Apêndice A, S0; 17, onda 0 | comandos 1 a 8 e 12 do R1b 16 medem 'padrões das teclas' e 'teclas livres' | não: nenhum desses comandos lê binding (R1b linhas 403 a 414). O jeito de conferir está no R4b, incógnita 4 (achado V7-06) |
| 43 | Apêndice B | (R9 12-C) `A_exec` de 30 s; `R_fast` | sim (R9 linhas 1310 e 1360) |
| 44 | 19, risco 2 | (R6a) piso provavelmente já varrido | sim como inferência: o R6a linha 87 diz que o ForeverFlip tem 'deals (vendor e resale)' |

Não achei função, evento ou linha inventada.

## 3. Modos de falha sem tratamento (um dia de uso)

**Abrir o leilão.** As teclas B, C, H, I, L, N, O, P, U, Y e F1 a F5 ganham sobreposição. O que elas fazem hoje no cliente não foi conferido, e a sonda indicada não confere (V7-06). Se outro personagem estiver logado, o addon fica em leitura (DD4), e é nele que está o material a vender (V7-02).

**Varrer.** Bem coberto: fôlego, throttle, resumo incompleto, foto vazia suspeita. Falta um detalhe: `C_Item.GetItemInfo` pode devolver nada para item fora do cache (R1c, resumo 3 e incógnita 2). A 8.3 bloqueia a postagem com depósito nulo, mas não diz o que a linha faz com preço de vendedor nulo. Sugestão, sem achado: linha `LOADING`, sem tecla, até `ITEM_DATA_LOAD_RESULT`.

**Postar.** A posição de bolsa pode ter mudado entre a linha e a tecla (V7-01). A foto de 30 s dobra as teclas (V7-05). O design não diz que lance passa a `PostItem` (a base 2.9 lista 'lance ou nil'); convém escrever 'lance nil, só arremate' e marcar como hipótese o que o servidor faz com isso.

**Comprar.** Ouro insuficiente no meio da ação chega como `NotEnoughMoney` num evento que só traz o código (V7-11). Bolsa cheia: o enum de erros não tem código de bolsa (R1a linha 159), o que combina com entrega pelo correio (H-10); o 'espaço de bolsa' que a 9.2 diz contar não tem definição. Sem achado.

**Cancelar.** O conselho de cancelar não tem regra desenhada para a fase 1 (V7-04).

**Correio.** A leitura está bem tratada (H-11, H-10). Carta que não é de leilão (ouro mandado por outro personagem do dono) cai na mesma lacuna do ouro de jogo (V7-03).

**Vendedor.** O Leatrix Plus vende lixo e conserta sozinho ao abrir o vendedor, e isso entra na variação de dinheiro que a 7.3 e a 10 usam como prova (V7-10).

**Jogar entre duas idas ao leilão.** Quest, saque, conserto e treino mudam o `GetMoney` e as bolsas. A conciliação não tem janela definida e o disjuntor de dinheiro vai disparar (V7-03).

**Fechar e salvar.** O `Y` da visão Session recarrega a interface sem guarda de máquina em repouso (V7-12). Disjuntor que só o agente destrava não tem canal, e não está dito que ele sobrevive ao `/reload` (V7-07). `Config.lua` quebrado não tem tratamento (V7-13).

**Trocar de personagem.** Ver V7-02. Fora isso, a seção por personagem do banco resolve.

**Cair a conexão ou o cliente.** Coberto em nível alto (6, 'Gravação'): o estado do jogo vale mais que o Livro e as linhas ficam `unreconciled`. O R10a (linha 52) traz relato de desconexão a cada 5 a 15 minutos depois de um patch; a sugestão de salvar aos 45 minutos pode ser longa demais nesse cenário. Sem achado: é número de configuração.

**Sair do alcance do leiloeiro.** Só a máquina de varrer trata `AUCTION_HOUSE_CLOSED` (V7-12).

**Patch do jogo e hotfix.** Nenhum parâmetro medido perde a validade, e não há carimbo de build (V7-14). Se o número de interface mudar, o `.toc` com `16001` fica desatualizado; o design não diz o que o dono faz com leilões abertos e o addon sem carregar. Cabe numa linha do risco 6: 'os leilões seguem o curso do jogo; o dono recolhe pela tela da Blizzard'.

**Manutenção de 17/11.** Tratada: depósito sempre lido, sonda paga depois dela, onda 0 relê. Fica uma pergunta sem resposta: leilão que atravessa uma manutenção conta como 'não vendeu' na frequência por duração? Sugestão, sem achado: marcar o desfecho como `downtime` e não contá-lo.

**Virada do dia.** Os tetos do dia e o disjuntor de perda se destravam na 'virada do dia', sem dizer por qual relógio. Em sessão que atravessa a meia-noite isso importa. Sugestão, sem achado: 'dia do servidor, por `GetServerTime`'.

**Acesso remoto.** Bem coberto: nada age sem tecla, bilhete e cotação vencem sozinhos, tecla presa é limitada por `T_ver`, por 10 ações por minuto e pelos tetos. Resta a contagem da rajada (V7-19).

## 4. Perguntas que o dono vai fazer e o design não responde

1. **'Qual personagem negocia, e como o minério, a erva e o pano dos outros três chegam ao leilão? Preciso juntar o ouro?'** (V7-02)
2. **'B abre as bolsas e C abre o personagem. Com a janela aberta eu perco essas teclas?'** (V7-06)
3. **'O que eu faço hoje, ao acordar?'** A onda 0 manda colar comandos que estão num relatório em pasta temporária (V7-08).
4. **'Quando fica pronto? Quantas sessões?'** Não há data nem duração por onda (V7-18).
5. **'Quanto tempo até os 15 ouro da fase 2?'** O design diz que o ganho é de pratas e que a compra para revenda pede banca de 15 ouro, mas não diz de onde ela vem nem que a resposta honesta é 'do jogo, não do leilão'. O D1 dizia ('o ouro novo vem do personagem, não do pregão'). Cabe uma frase na seção 0.
6. **'Tem coisa que eu não quero vender. Como tiro da lista sem chamar o agente?'** (V7-15)
7. **'Por que apertei P e ele só disse REFRESHED?'** (V7-05)
8. **'O addon travou em papel por dinheiro sem explicação. Eu só fiz uma quest.'** (V7-03)
9. **'O autoscan do Auctionator atrapalha?'** O R4b (linha 172) registra `autoscan_interval` 15 e `auto_list_search` ligado. A H-08 e a S4 cobrem o convívio em geral; a DD2 não avisa o dono de que, se a S4 mostrar disputa de throttle, a saída é ele desligar o autoscan.
10. **'Onde eu leio o relatório da sessão e a pauta?'** A seção 10 não dá o caminho do arquivo.
11. **'Se o jogo atualizar e o addon parar, o que acontece com meus leilões?'** (seção 3, patch)

## 5. Afirmações que não são fato da base nem hipótese marcada

| Onde | Afirmação | Situação |
|---|---|---|
| 11.3, visão Mine | `SOLD gold arrives in about 41 min` | Depende de `timeLeftSeconds` de leilão vendido ser o tempo até o pagamento: R1b incógnita 17 (linha 441). Não está na lista H (V7-20) |
| 2.2, H-03; 19 | 'O projeto para' se a gravação falhar | A base 3.9 `[gate]` já conferiu que grava e recarrega nesta máquina; resta só o `/reload` em si (V7-20) |
| 2.2, H-14 | 'vende primeiro o mais antigo (base 2.17)' | A base diz o contrário como relato; o pior caso é escolha do design (V7-09) |
| 0, item 1 | 'única linha com fonte de economia já aprovada' para a venda dos quatro personagens | Só os verdes têm fonte aprovada (V7-20) |
| 18, DD3 | `igualar` para commodity como recomendação e padrão | Sem fonte citada para commodity (V7-09) |
| 0 | 'Um giro completo da banca ... rende de 50 a 75 prata' | A conta usa os 5 ouro dos quatro personagens; a banca da 9.1 é a do logado menos 1 ouro (V7-02) |
| 8.3; 10 | custo da compra 'pela variação do dinheiro' | Supõe débito na hora da confirmação. Provável, mas não está na base. Cabe na S8 |
| 11.5 | 'se o addon conseguir ler onde está o foco (hipótese, a conferir na S2)' | A S2 do Apêndice A não lista essa medida |
| Apêndice B | `μ_min` de 0,15, origem 'D4, D5' | No D4 o valor vinha da deriva de 7% ao dia, que o conflito 10 removeu. A justificativa que sobra é a do D1 4.4 ('corte e depósito ainda são pista'). Trocar a origem |
| regra 20 | 'Nome de jogador nunca é gravado' | O banco tem `pers[nome]` com o nome dos personagens do dono. Escrever 'nome de outro jogador' |
| 16, critério de aceite | 'Primeira compra real: S6 a S8 gravadas' | A S8 já é uma compra real. Escrever 'primeira compra fora da sonda', como na linha da postagem |

## Tabela dos achados

| id | seção | gravidade | tipo | achado | evidência | correção |
|---|---|---|---|---|---|---|
| V7-01 | 8.3 Postar; 8.1 | importante | lacuna | As pré-checagens de postar não conferem se o item da posição de bolsa ainda é o da linha. `PostItem` e `PostCommodity` recebem `ItemLocation`; se a bolsa mudou entre a linha e a tecla (saque, arrumação do Baganator), posta-se outro item pelo preço calculado para o primeiro. | SINTESE linhas 453 a 456 (lista das pré-checagens); base 2.9 (`PostItem(itemLocation, ...)`); base 7.2 (Baganator instalado); a faixa de preço da 9.2 é a do item da linha. | Na 8.3 Postar, acrescentar às pré-checagens: 'itemID, link e quantidade lidos de `ItemLocation` no clique iguais aos da linha; senão a tecla só refaz a linha (`BAG CHANGED`)'. Na 8.1, estender a I8: mudança de bolsa (`BAG_UPDATE_DELAYED`, R1c 2) reinicia `T_ver`. Acrescentar o cenário 'bolsa trocada entre a linha e a tecla' à seção 16. |
| V7-02 | 0; 9.1; 18 DD4 | importante | contradicao_interna | A primeira fonte de ganho é vender o que os quatro personagens produzem, mas a DD4 deixa três deles em leitura. A banca é o `GetMoney` do logado menos 1 ouro, e os 5 ouro são a soma dos quatro. O D4 perguntava se o ouro seria reunido; a síntese cortou a pergunta. | SINTESE linhas 13 e 15, 483, 811; D4 linha 761 ('se junta o ouro dos quatro nele'; 'Banca de 4 ouro ... se o ouro for reunido'); base 4.1 e 4.2 (sem banco de conta; uma profissão de coleta por personagem). | Na DD4, separar: (a) vendas (postar e cancelar) valem em qualquer personagem, com tetos de depósito sobre o `GetMoney` dele (`pers[nome].cofre` já existe); (b) compras só no negociador; (c) pergunta nova: reunir o ouro no negociador ou não. Na seção 0, refazer a conta do giro com a banca do negociador, marcada como desconhecida até o dono responder. |
| V7-03 | 9.4; 10 | importante | lacuna | A conciliação compara dinheiro e bolsas com o Livro, mas o design não diz o que fazer com ouro que muda fora do leilão e do correio: quest, saque, conserto, treino. Em personagem que está subindo de nível, o disjuntor 'dinheiro sem explicação' (1% da banca, cerca de 4 prata) dispara todo dia e só o agente destrava. | SINTESE linhas 528 e 549; base 4.2 (nível 19 a 21) e 6.2 (treino e montaria); R4b linha 176 (Leatrix Plus vende lixo e conserta sozinho); D4 linha 781 só previa as incógnitas do correio. | Na seção 10, definir a janela da conciliação: `PLAYER_MONEY` é acompanhado sempre; variação com leilão, correio e vendedor fechados entra no Livro como `outside play` e não conta como desvio. O desvio é só a diferença entre o esperado e o lido dentro de uma janela de leilão ou de correio. Na 9.4, trocar o gatilho para esse desvio. Cenário novo na seção 16. |
| V7-04 | 7.1; 7.4; 11.3; 11.4 C | importante | contradicao_interna | A visão Mine dá o conselho `CANCEL +36c` desde a fase 1, mas a regra de cancelar adotada (R9 4.6) usa `P` e `W*`, justamente o que a 7.1 tira das fases 1 e 2 (tabela de P fora; `W*` em sombra). Não há regra desenhada para o conselho na fase 1 nem fonte pública para ele. | SINTESE linhas 307, 366, 590, 625, 671 e 793; R9 linhas 556 a 565 (`Δ_canc = P·(W* − p·(1−c)) + ...`); R8b R12, linha 185 ('isn't automatically useful anymore'). | Na 11.3 e na 11.4 C, tirar `CANCEL +Xc` e `LET EXPIRE` da fase 1: a visão Mine mostra só fatos (quantidade na frente, distância para a frente, tempo, depósito em risco) e `STAND DOWN`. Na 7.4, dizer que `Δ_canc` roda em sombra, como o `W*`, até 50 desfechos, e que virar conselho é decisão DD3, com a fonte que o dono aprovar. |
| V7-05 | 8.3 Postar; 5.2; conflito 2 | importante | contradicao_interna | O conflito 2 decide 'postar em uma tecla', mas a 8.3 exige foto de até 30 s também para postar. Um fôlego leva até 60 s e cobre 20 chaves; quando o dono chega à linha a foto venceu, e quase toda postagem vira duas teclas (`REFRESHED` e de novo `P`), com `T_ver` no meio. | SINTESE linhas 240, 453, 829, 864 e 913; R9 linha 1310 (`A_exec` de 30 s é a idade máxima para executar, calibrada por 'já tinha sumido'; `A_fresh` é de 10 min). | Na 8.3 Postar e no Apêndice B, criar `A_post`, separado do `A_exec`: valor inicial de 10 min (o `A_fresh` do R9 12-C), porque na postagem só o depósito fica em risco; manter 30 s para `B`. Na 11.3, a linha de postagem mostra a idade da foto. Rever o `A_post` pela fração de postagens cobertas em menos de 10 min. |
| V7-06 | 11.2; Apêndice A S0; 17 onda 0 | importante | fato_errado | A 11.2 diz que a sonda S0 confere os padrões de tecla do cliente, e a S0 manda usar os comandos 1 a 8 e 12 do R1b 16. Nenhum deles lê binding. O design também não diz que a sobreposição cala a função que a tecla tem no jogo enquanto a janela está aberta. | R1b linhas 403 a 414 (os comandos leem addon, filtros, categorias, durações, cobre, commodity, depósito e regras); R4b linhas 161 e 185 ('bolsas, personagem, mapa'; conferir em Options > Keybindings ou `/guia keys`); SINTESE linhas 561, 790 e 839. | Na S0 e na onda 0, trocar 'padrões das teclas' por: 'o dono abre Options > Keybindings ou `/guia keys` (R4b incógnita 4) e anota o que B, C, H, I, L, N, O, P, U, Y e F1 a F5 fazem hoje'. Na 11.2, dizer que a tecla perde a função do jogo com a janela aberta, e levar isso à DD5. |
| V7-07 | 9.4; regra 19; 12 | importante | lacuna | Dois disjuntores se destravam por 'sessão do agente', mas o estado deles só pode viver nas SavedVariables, que nem o agente nem a mesa escrevem (regra 19). Não há canal de destrava. Também não está escrito que o disjuntor sobrevive ao `/reload`: a tecla de salvar poderia zerá-lo. | SINTESE linhas 527 e 528 (destrava: sessão do agente), 49 (regra 19), 707 a 709 (o agente só escreve `Config.lua` e `Calibrado.lua`), 141 e 682. | Na 9.4, acrescentar: 'todo disjuntor grava em `pers[nome].cofre` o gatilho, a hora e o `seq`; o estado sobrevive a `/reload` e a logout. A destrava do agente é uma linha `Config.destravas[disjuntor] = seq`, escrita com o sim do dono; o addon solta o disjuntor se o `seq` for o do disparo'. Incluir o campo na linha do `Config.lua` da seção 12. |
| V7-08 | cabeçalho; 17 onda 0; Apêndice A | importante | lacuna | O design se declara contrato para uma sessão 'sem nenhum outro contexto', mas depende de arquivos que só existem na pasta temporária desta sessão: os comandos do R1b 16 (o primeiro passo do dono), a tabela R9 12-C, o contrato R1a da bancada, as fichas R8a e R8b e o espelho. Nenhum caminho é dado. | SINTESE linhas 3 e 5 (como ler, sem caminho), 305 (faixa do R9 12-C), 760 (contrato R1a), 790 e 839 (comandos do R1b 16); base linha 137 ('pasta <scratchpad>/pesquisa/'); a pasta fica em AppData/Local/Temp. | Acrescentar o 'Apêndice D: fontes', com o caminho permanente, no repositório, da base de fatos, dos relatórios citados e do commit do espelho, e a instrução de copiá-los para lá antes da onda 0. Transcrever no Apêndice A os nove comandos da onda 0 (R1b 16, 1 a 8 e 12), prontos para colar. |
| V7-09 | 18 DD3; 7.2; 2.2 H-14 | importante | lacuna | A DD3 recomenda `igualar` para commodity, e a recomendação vira o padrão do `Config.lua`; a tabela de candidatos só dá fonte de `igualar` para equipamento. A H-14 cita a base 2.17 para 'o mais antigo vende primeiro', e a base relata o contrário. Sob a H-14, igualar é a pior regra. | SINTESE linhas 99, 319, 802 ('a opção recomendada é o padrão do `Config.lua`') e 810; base 2.17 ('o mais novo vende primeiro'); R8a linhas 56 (F23: 'Last-In-First-Out') e 85 (F5: 'Undercut by a copper'); R8b R6 e R12. | Na DD3, tirar a recomendação de regra para commodity: listar as três com o que cada fonte diz (F5 cobrir; R8b R6 folga; R8b R12; base 2.17 e F23 a favor de igualar) e deixar `venda_sobras` sem regra padrão até o dono escolher. Na H-14, escrever: 'as fontes dizem que o mais novo vende primeiro (base 2.17); o design supõe o contrário, por ser o pior caso'. |
| V7-10 | 7.3; 10; 14 | importante | risco | O lote de confirmação do `piso` e o fechamento de lote no NPC conferem a venda 'pela variação do dinheiro' com o vendedor aberto. O Leatrix Plus do dono vende lixo e conserta sozinho ao abrir o vendedor: a variação não bate, e o item sai da arbitragem ou o disjuntor de dinheiro liga. | SINTESE linhas 349 e 545; R4b linha 176 ('Leatrix Plus ... Vender lixo e consertar automático ligados'); H-21, linha 106 (se negada, 'o item sai da arbitragem'). | Na 7.3 e na 10, trocar a conferência por: 'cada venda ao NPC casa a saída do item da bolsa (`BAG_UPDATE`) com o `PLAYER_MONEY` seguinte; variação sem item do Livro saindo (lixo, conserto) é `outside` e não entra na conferência da H-21'. Na seção 14, acrescentar a linha do Leatrix Plus com esse aviso. Cenário novo na seção 16. |
| V7-11 | 8.3 | importante | lacuna | Todo `AUCTION_HOUSE_SHOW_ERROR` leva a `FALHOU`. O evento só traz o código, sem leilão, e o enum tem 27 valores. Só três têm tratamento. Faltam `NotEnoughMoney` (ouro acabou no meio), `IsBusy`, `DatabaseError`, `ItemHasQuote` e `Unavailable`, e o erro causado por outra tela enquanto a ação do addon está em voo. O D6 tinha a tabela. | SINTESE linhas 446, 461, 472 e 527; R1a linhas 159 (enum) e 197 (evento só com `error`); D6 linha 525 ('`NotEnoughMoney` recalcula a banca; `IsBusy` e `DatabaseError` pedem nova tecla depois de 5 s'). | Na 8.3, depois das máquinas, acrescentar a tabela 'código, reação': `NotEnoughMoney` relê `GetMoney`, recalcula a banca e concilia; `IsBusy`, `DatabaseError` e `Unavailable` vão para INCERTO (não se sabe se executou); `ItemHasQuote` cancela a cotação; os demais, `FALHOU` com o texto. Erro que chega sem ação em voo só é registrado. Um cenário de bancada por código. |
| V7-12 | 8.3; 11.4 E; 2.2 H-19 | importante | lacuna | Só a máquina de varrer trata `AUCTION_HOUSE_CLOSED`. Faltam as transições das máquinas de ação quando o dono sai do alcance, e a guarda do `Y` de salvar: recarregar com cotação aberta, bilhete armado ou ação em `ENVIANDO` perde o estado antes do eco. A hipótese do D3, de o `/reload` fechar a casa, caiu. | SINTESE linhas 241 (só Varrer), 425 a 472 (nenhuma transição de fechamento), 682 (`Y` recarrega), 104 (a H-19 só mede aceitação e tempo), 763 ('leilão fechado no meio' injetado sem comportamento definido); D3 linhas 553 e 606. | Na 8.3, acrescentar: '`AUCTION_HOUSE_CLOSED` em COTADO, ARMADO ou AVISO desarma e chama `CancelCommoditiesPurchase`; em ENVIANDO ou CONFIRMANDO vira INCERTO na hora'. Na 11.4 E, o `Y` de salvar só vale com todas as máquinas em repouso e o fôlego fechado. Na H-19 e na S1, medir se o `/reload` fecha a casa e o que sobra do throttle. |
| V7-13 | 12; 4.1 | importante | lacuna | `Calibrado.lua` truncado tem tratamento (`NO DESK`); `Config.lua` e `Dados.lua` não têm. O agente edita o `Config.lua` com o jogo aberto e o dono dá `/reload`: um erro de sintaxe deixa o addon sem configuração, com leilões abertos. O D3 tinha a hipótese de um arquivo quebrado isolar os outros. | SINTESE linhas 161, 163, 708, 709 e 714 (defesas só do `Calibrado.lua`); D3 linha 265 ('um arquivo de dados com erro de sintaxe não impede a carga dos seguintes', a medir) e linha 553. | Na seção 12, estender os modos: '`Config.lua` ausente, quebrado ou de outro esquema: o addon entra em `leitura`, com a faixa `CONFIG ERROR - read only`; `Dados.lua` ausente: sem triagem do piso'. Na mesma seção, o agente roda `checar-lua.mjs` no `Config.lua` antes de pedir `/reload`. Acrescentar a hipótese do arquivo quebrado à S1 e um cenário à seção 16. |
| V7-14 | 7.6; 19 | menor | lacuna | Parâmetro medido nunca volta a ser estimativa. Não há carimbo de build nas amostras nem alarme quando uma leitura nova diverge do valor adotado. Hotfix de servidor muda regra sem mudar o cliente, como o depósito de 17/11. O D1 tinha 'alarme se divergir'. | SINTESE linhas 376 a 388 (só 'vira medido com N') e 828 (risco 6, sem detecção); D1 linha 352 ('Alarme se divergir'); base 1.7 e 6.3 (mudanças por manutenção e hotfix). | Na 7.6, acrescentar a coluna 'Deixa de valer quando': a leitura nova diverge do adotado além da tolerância em 2 amostras seguidas, ou o `GetBuildInfo()` gravado em `calib` muda. O parâmetro volta ao valor de partida, a faixa diz `GAME NUMBER CHANGED` e as licenças que dependem dele caem para papel até nova medida. |
| V7-15 | 11.2; 9.1 | menor | lacuna | Não há tecla para dispensar uma linha. O que o dono não quer vender (peça para outro personagem, item de missão) só sai da fila pela lista `reservas`, escrita pelo agente. Com cinco linhas visíveis, o topo fica ocupado pelo que ele já recusou. O D1 tinha a tecla que grava 'recusou'. | SINTESE linhas 563 a 573 (sem tecla de dispensar), 486 (`reservas` só no `Config.lua`) e 128; D1 linha 425 (tecla `H`: 'Dispensar a recomendação'); base 4.10 (`K` e `M` livres). | Na 11.2, acrescentar a tecla `K` (livre na base 4.10): 'Skip: tira a linha da fila até o fim da sessão e grava `skipped` no Sinal'. Não é configuração: o estado é da sessão. No relatório de sessão (seção 10), listar os itens pulados três vezes como candidatos a `reservas`, para o dono confirmar. |
| V7-16 | 4.3; 3.3; conflito 19 | menor | lacuna | O conflito 19 diz que o treino do D2 virou `modo = "papel"`, mas o papel só está descrito para a tecla de compra. O que `P` e `C` fazem em modo papel não está escrito, e a 3.3 diz que as vendas entram direto em micro. | SINTESE linhas 143 ('a tecla de compra não chama função de ação'), 146 ('as vendas entram direto em micro'), 209 ('em `papel`, toda licença fica limitada a papel') e 930. | Na 4.3, completar: 'em `modo = papel`, `P`, `C` e `Y` não chamam função de ação: gravam a ordem de papel com a hora da tecla, medem o tempo de decisão e o desfecho em sombra, e a tela mostra `PAPER - nothing posted`'. Na 3.3, ressalvar que 'as vendas entram direto em micro' vale só em `modo = vivo`. |
| V7-17 | 7.2; 3.2; conflitos abertos | menor | lacuna | Duas ideias pedidas pelos juízes caíram sem registro: o lote do tamanho da demanda (D6 4.4; R9 4.5) e a postagem-sonda de 1 unidade (D6 4.2 C). O R8b R14, lote em tamanho de receita, é citado como fonte de `venda_sobras` e não vira regra: a 7.2 posta a pilha inteira. | SINTESE linhas 129 (R14 citado) e 336 ('Commodity posta o lote da pilha numa chamada'); D6 linhas 43 e 304; J1 (D6 enxerto 3) e J2 (D6 enxertos 3 e 6); R8b linha 187 ('list in recipe sizes'). | Na 7.2, 'Duração e lote', acrescentar: 'o tamanho do lote de commodity é campo do `Config.lua` por classe (pilha inteira, tamanho de receita do R8b R14 ou quantidade fixa), escolhido na DD3'. Na tabela 'Conflitos abertos', acrescentar a linha da postagem-sonda e do lote `n*` do D6, com a decisão e o motivo. |
| V7-18 | 17 onda 0; conflito 20 | menor | lacuna | O conflito 20 diz que 'a onda 0 fala só da tela da Blizzard', mas a onda 0 da seção 17 não manda vender nada: a venda pela tela que o dono já usa só aparece na onda 2. O calendário do D5 também caiu, e o design não diz quando cada onda fica pronta. | SINTESE linhas 790, 792 e 931; D5 linhas 518 ('se quiser ouro já, posta os verdes') e 526 (calendário de 16 a 20/11); J2 (D5, lucro 8: 'único que põe ouro na mão antes de existir addon'). | Na linha da onda 0, acrescentar: 'se quiser, o dono já vende pela tela da Blizzard os verdes que a fonte aprovada cobre, anotando preço, duração e desfecho: são as primeiras amostras da régua'. Acrescentar a coluna 'Duração estimada' por onda, marcada como hipótese, com a espera de desfechos entre as ondas 3 e 5. |
| V7-19 | 8.2; 11.2 | menor | contradicao_interna | O disjuntor de rajada (6 teclas de ação em 2 s) nunca dispara se contar teclas aceitas: a repetição em menos de 400 ms é ignorada e o `T_ver` exige mais de 1 s entre ações. A tecla `N` tem três papéis (próxima linha, desarmar o bilhete, dispensar alerta) sem ordem definida. | SINTESE linhas 414 a 416 (`T_ver` de 1 s mais latência; repetição de 400 ms; rajada de 6 em 2 s) e 566; conta: 2 s divididos por 0,4 s dão 5 teclas aceitas no máximo. | Na 8.2, escrever: 'a rajada conta teclas de ação recebidas, aceitas ou não'. Na 11.2, fixar a ordem do `N`: 'com bilhete na tela, só desarma; sem bilhete e com alerta, só dispensa o alerta; senão, anda uma linha. Uma pressão faz uma coisa só'. Acrescentar os dois casos aos cenários de operador da seção 16. |
| V7-20 | 2.2 H-03; 19; 11.3; 0 | menor | fato_errado | Três marcas a acertar. A H-03 diz 'o projeto para', mas a base 3.9 já conferiu que as SavedVariables gravam e recarregam nesta máquina. `gold arrives in about 41 min` depende de incógnita não listada. A seção 0 dá a venda dos quatro personagens como linha com fonte aprovada; só os verdes têm. | base 3.9 ('[gate] local': gravam e voltam a carregar); SINTESE linhas 88, 831 e 933; linha 626 com R1b linhas 297 e 441 (incógnita 17: `timeLeftSeconds` de vendido); linha 15 contra linha 129 (`venda_sobras` espera a DD3). | Na H-03, trocar 'O projeto para' por 'salva-se no logout, que a base 3.9 já conferiu; a tecla de salvar some', e tirar a H-03 do que 'derrubaria o design inteiro'. Acrescentar a H-26: '`timeLeftSeconds` de leilão vendido é o tempo até o pagamento (R1b incógnita 17)', medida na S7. Na seção 0, item 1, escrever 'a venda dos verdes é a única linha com fonte já aprovada'. |

## Pontos fortes que a revisão não deve estragar

1. INCERTO sem reenvio, as invariantes I1 a I9 e a separação entre `Acoes.lua` (só o lado do clique) e `Ecos.lua` (que não pode agir).
2. A regra de conformidade 'onde a base não sabe se pode, o addon age como se não pudesse', com a confirmação de commodity sempre por tecla e a recusa do teste sem clique.
3. As 25 hipóteses, cada uma com sonda e saída, e a disciplina de citação: não achei função, evento ou linha inventada.
4. Preço por regra com fonte escolhida pelo dono, `P*` em palavras e `W*` em sombra; toda estratégia nasce com licença 0.
5. A franqueza do resumo ('com 5 ouro o addon não o deixa rico por trading') e as colunas 'Mede' e 'Para se' em cada onda.
