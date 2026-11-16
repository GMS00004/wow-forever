# PregaoForever: design do addon de trading (contrato de implementação)

Data: 2026-11-16. Etapa de design: nenhuma linha de código de addon foi escrita. Este texto passou por revisão adversarial (nove pareceres, 169 achados, todos tratados; a lista está em `MUDANCAS.md`). Ele é o contrato de implementação de uma sessão nova do agente, que o usa só com este arquivo e com a pasta `pesquisa/` do addon (Apêndice D). O texto dirigido ao dono é o `LEIA-ME.md`, na mesma pasta: ele traz o resumo, a linha do tempo, o primeiro dia, as decisões e as telas.

**Como ler.** `(base 2.7)` é o item 2.7 de `pesquisa/base-de-fatos.md`; `(R9 5.1)` e `(R8a ficha 5)` são relatórios da mesma pasta; `(espelho, Arquivo.lua:123)` é o código da interface da Blizzard no commit do Apêndice D; `(strings, linha 1291)` é o arquivo de textos do cliente, também no Apêndice D. `DD3` é a decisão do dono número 3 (seção 18). **H-nn** marca hipótese a medir, listada na seção 2.2. **S-nn** é um passo da sonda (Apêndice A). **[TECLA x]** marca o ponto em que entra a tecla do dono. Todo número de configuração é proposta do projeto, não fato do jogo: os que são política de trading esperam a aprovação do dono (DD10) e os demais são calibrados pela medida que o Apêndice B indica. Itens e valores das telas desenhadas são ilustrativos.

**Como este texto nasceu.** Seis projetos independentes foram comparados e fundidos num só; os pontos em que eles discordavam, e o motivo de cada escolha, estão na última seção ("Decisões de projeto e por quê"). A estrutura parte de invariantes, de um núcleo de risco (o Cofre), de tetos duros, de licença por nível e do estado INCERTO, porque invariante atravessa todo arquivo e não se enxerta depois. A ordem de entrega põe o que mede antes do que age.

## 0. Resumo

**O que o addon é.** Um terminal de leilão com três peças. A **régua** é o livro que mede cobre por ação, por hora e por estratégia, e troca cada estimativa do jogo por número lido. A **fila** mostra até cinco linhas do que vale fazer agora com a banca que existe. A **mão** executa: cada compra, postagem e cancelamento sai de uma tecla do dono, uma por ação, depois de passar pelo **Cofre**, o núcleo de risco, que nega na dúvida.

**De onde pode vir ganho, sem promessa.** O dono tem 50.912 cobre somando quatro personagens (base 4.1), sem banco de conta (base 4.2). A banca do addon é a do personagem que negocia: cerca de 4 ouro se o dono reunir o ouro nele e mantiver o piso pessoal de 1 ouro (DD4), e cerca de 27 prata se não reunir e o ouro estiver dividido por igual. Com 4 ouro de banca e o teto de 50% em estoque, um giro do capital que pode ficar em estoque, a 10% ou 15% de margem líquida, rende de 20 a 30 prata, antes de depósitos perdidos; sem reunir, de 1 a 2 prata. O ouro de cada venda volta pelo correio em cerca de 1 hora (base 1.8), o que limita o giro por melhor que seja a interface. O que aperta é capital e giro, não tecla nem modelo.

Proposta de ordem das fontes de ganho, a aprovar na DD3:

1. **Vender bem o que os personagens já produzem** (base 4.2): leilão ou vendedor, a que preço, por quanto tempo. Só o depósito fica em risco. A venda dos verdes bons é a única linha com fonte de economia já aprovada pelo dono (base 4.5); a venda das sobras de coleta espera a aprovação da fonte (DD3). Postar e cancelar valem em qualquer personagem logado, cada um com o seu Cofre (seção 9.1).
2. **Compra para revenda**, só em **papel** (sinal registrado, sem gastar ouro) até o diário do próprio addon mostrar margem depois de corte, depósito e teclas (seção 3.3).

Fora da lista, como medição de graça e a decidir: arrematar abaixo do preço que o vendedor NPC paga (`piso`). Não tem fonte de estratégia; o que existe é contado desde a onda 2, fora do jogo, sobre as fotos que o addon grava, e a estratégia só liga se o dono aprovar a ideia sem fonte ou indicar uma (DD3).

O que os fatos sustentam dizer ao dono: com 5 ouro o addon não o deixa rico por trading. Ele vende melhor o que os personagens produzem, mede o mercado e prova, com números dele, se e quando comprar para revender paga. Quanto tempo cada degrau de banca demora, e o que mais pesa nisso, está na seção 3.4, como hipótese que a régua troca por medida. Nos primeiros degraus o que mais pesa nessa conta é o ouro que entra de fora do leilão, e isso é uma grandeza que a régua mede, não um conselho.

**Ritmo.** O ritmo de partida é de 10 operações por minuto (postar, comprar ou cancelar, contando o verbo concluído), cerca de 5 minutos para uma bolsa cheia. Não é teto duro: sobe por portão medido (seções 9.2 e 17.1).

**O que ele nunca faz.** Agir sem tecla ou clique do dono; fazer mais de uma ação por tecla; chamar ação de timer, evento ou `OnUpdate`; repetir sozinho uma ação que falhou; simular entrada; ter algo que evite a marca de ausente; contornar função protegida, evento de hardware ou secret value; pegar correio, vender ou comprar no NPC por código; ter configuração, caixa de texto ou fonte na tela; ler código de addon de terceiro; gravar ou mostrar nome de outro jogador; propor preço fora do mercado; ligar estratégia sem fonte aprovada. O addon nunca envia dado para fora do jogo; a mesa guarda os arquivos na máquina, fora do git, e o relatório de sessão leva os números à sessão do agente (seção 12).

**O que o dono decide.** Antes da primeira linha de código: postar e cancelar por tecla (DD1a); comprar por tecla (DD1b); fontes e regra de preço da venda (DD3); negociador, reunir ou não o ouro e piso pessoal (DD4); acesso remoto e os termos (DD9); e a lista de reservas (DD14). O mapa de teclas (DD5) se decide depois da sonda S0 e de ele ver os quadros. O nome (DD6) já tem padrão, PregaoForever, e só pede resposta, antes da onda 1, se ele quiser outro. As demais têm padrão já marcado e podem esperar. As opções e a recomendação de cada uma estão na seção 18.

**Quando cada coisa acontece.** A linha do tempo (o que libera cada degrau e o mais cedo possível) e o roteiro do primeiro dia estão na seção 17.

## 1. Regras que valem para todo arquivo

O `ARQUITETURA.md` do addon abre com estas regras, no formato dos outros addons do projeto (R4a 2). O checador novo confere as que são estáticas (seção 16).

| # | Regra |
|---|---|
| 1 | Lua 5.1, só ASCII, comentários em português sem acento. Nomes de arquivo e de função em português, sem acento; APIs e eventos com o nome do cliente (base 4.8). |
| 2 | Todo arquivo abre com `local _, ns = ...`. Globais só com os prefixos `PregaoForever`, `SLASH_PREGAOFOREVER` e `BINDING_`. As funções ficam em `ns`, não em dezenas de `local` no topo do arquivo (limite de 200 locais por função da linguagem). |
| 3 | Toda função de evento, timer ou clique roda em `xpcall(fn, geterrorhandler())`, pelo embrulho `ns.seguro`. O embrulho chama a função na mesma pilha, sem `C_Timer.After(0)`: a função de ação tem de sair de dentro do clique, antes de qualquer espera. |
| 4 | Quadro da Blizzard só por `hooksecurefunc`, `HookScript`, `EventRegistry` ou `TooltipDataProcessor`. Nenhuma aba no `AuctionHouseFrame`, que causaria taint: a janela é própria (base 4.8; base 7). |
| 5 | Addon de terceiro só por chamada em tempo de execução, com `pcall`, em `Pontes.lua`. Código de terceiro não é lido nem copiado, nem no repositório do autor (base 7). |
| 6 | As oito **funções de ação** só aparecem em `Acoes.lua`, dentro de funções de prefixo `tecla_`, chamadas apenas pelo `OnClick` de botões do addon. `Acoes.lua` não tem `C_Timer`, `OnUpdate` nem `RegisterEvent`; as respostas são tratadas em `Ecos.lua`, que não pode agir. |
| 7 | Uma tecla aceita gera no máximo uma chamada de função de ação. Toda chamada de `PostItem` leva quantidade 1. |
| 8 | Toda chamada de ação vem, no mesmo clique, depois de `Cofre.autoriza` e de `Livro.intencao`. |
| 9 | Nenhuma **consulta** sai sem uma tecla do dono há no máximo `T_pulso` (decisão DD13), e toda consulta pertence a um **fôlego**: uma rodada limitada de consultas que nasce de uma tecla do dono e termina sozinha. Uma consulta em voo por vez, todas por `Pedidos.lua`. Nenhum evento ou timer abre um fôlego, nem o evento de abertura do leilão, e nenhuma consulta sai fora de um fôlego aberto por tecla; dentro do fôlego aberto, a resposta de uma consulta (ou o prazo dela) pode pedir a `Pedidos.lua` a seguinte, dentro do orçamento. Contam como consulta as funções que mandam pedido ao servidor do leilão (R1a 6): `SendBrowseQuery`, `RequestMoreBrowseResults`, `SendSearchQuery`, `SendSellSearchQuery`, `RefreshCommoditySearchResults`, `RefreshItemSearchResults`, `RequestMoreCommoditySearchResults`, `RequestMoreItemSearchResults` e `QueryOwnedAuctions`. `GetItemKeyInfo` e `C_Item.RequestLoadItemDataByID` pedem dados de item ao cliente, não ao leilão: não contam no orçamento do fôlego e ficam em `Itens.lua`. |
| 10 | Proibidos no addon inteiro (o checador compara por trecho de nome, para pegar também as formas com prefixo `C_`): `TakeInboxMoney`, `TakeInboxItem`, `TakeInboxTextItem`, `AutoLootMailItem`, `DeleteInboxItem`, `ReturnInboxItem`, `SetOpeningAll`, `SendMail`, `BuyMerchantItem`, `BuybackItem`, `SellAllJunkItems`, `UseContainerItem`, `DeleteCursorItem`, `SetCVar`, `SetBinding`, `SaveBindings`, `RunScript`, `RunMacro`, `RunMacroText`, `loadstring`, `:Click(`, `EditBox`, `SendChatMessage`, mensagem de addon e tecla `MOUSEWHEEL` em botão de ação. Proibidas também as consultas que o design não usa: `QueryBids`, `SearchForItemKeys`, `SearchForFavorites`, `RequestOwnedAuctionBidderInfo` (devolve nome de jogador) e `ReplicateItems`, esta nas fases 1 e 2; na fase 3 ela só entra depois de um passo de sonda próprio e de decisão do dono (seção 17.1). `CancelSell` não é usada. `SetOverrideBindingClick` só aponta para botão `PregaoForever*`; `SetOverrideBinding` fora da forma `Click` não é usada. |
| 11 | Nada se configura no jogo. `/pregao` abre a janela, mostra o estado e inicia a sonda. A configuração vive no `Config.lua`, escrito pelo agente (base 4.7). |
| 12 | Texto de tela em inglês, sem fonte e sem acento; cada seção mostra no máximo 5 linhas (menos, quando a zona tem altura fixa menor) e `Show N more` para o resto; estado sempre em palavra, nunca só em cor; nada que só exista em tooltip (base 4.7, 8.4). |
| 13 | Só `Tetos.lua` define teto duro, e teto duro é só de dinheiro; a configuração só aperta. Ritmo (ações e buscas por minuto) é do `Config.lua` e sobe por portão medido (seção 9.2). O nível concedido de uma estratégia (licença e evidência) só desce dentro do jogo; subir é edição de arquivo. A suspensão por disjuntor é à parte (seção 9.4). |
| 14 | Todo arquivo que a bancada carrega (o addon inteiro, com o leilão falso) fica no subconjunto comum a Lua 5.1 e 5.3, porque a bancada roda em fengari, que é 5.3 (R4a 4). Proibidos `unpack` global, `loadstring`, `bit`, `//`, operadores de bit e `goto`. Todo número que vira texto (linha do banco, tela) passa por `string.format('%d', math.floor(x))`: na 5.3, `10/2` vira `5.0`. Nenhum desempate depende da ordem do `pairs`. Os arquivos puros (`Estimadores.lua`, `Motor.lua`, `Sombra.lua`) além disso não tocam global do jogo e recebem a hora por argumento. O `checar-pregao.mjs` confere. |
| 15 | Tempo por relógio, nunca por contagem de quadros. Três relógios, cada um com um uso: `GetTimePreciseSec` fatia o trabalho pesado em pedaços de 2 ms (`debugprofilestop` só como reserva, e intervalo negativo encerra a fatia; se nenhum servir, fatia por contagem de linhas); `GetTime` mede intervalo curto dentro da sessão (`T_ver`, janela de repetição, prazo do eco); tudo o que vai ao disco usa `GetServerTime` (base 3.3, 3.8; R9 11.1; R1c 5). A única leitura da hora local da máquina é a do dia de risco (seção 6), por `date('*t')`; o que se grava junto dele leva `GetServerTime`. |
| 16 | Binding e ação só fora de combate e sem restrição de addon ativa (base 3.4, 2.16). Ligar e soltar bindings só com `InCombatLockdown()` falso; se o leilão abre ou fecha em combate, a operação fica pendente e roda em `PLAYER_REGEN_ENABLED`. |
| 17 | Dinheiro em cobre inteiro. Depósito sempre lido de `CalculateItemDeposit` ou `CalculateCommodityDeposit`; preço de vendedor sempre lido de `C_Item.GetItemInfo` na hora, pelo link do item, como a tela da Blizzard faz (base 1.4, 3.2, 6.3; espelho, `Blizzard_AuctionHouseSellFrame.lua:425`). Única exceção: para item que não está na bolsa, `CalculateItemDeposit` não responde (pede um `ItemLocation`, R1a função 2); nesse caso o depósito é estimado pela razão entre depósito e preço de vendedor medida no diário, por duração, aparece na tela com a marca `est.` e não autoriza compra acima do lote de confirmação. |
| 18 | Todos os `.lua` na raiz do addon e no `.toc` desde a onda 1: o `checar-lua.mjs` só lê o primeiro nível (R4a 3) e arquivo novo pede reinício do jogo (R4a 6). TOC com `## Interface: 16001`, `## Author: Bruno`, `## SavedVariables: PregaoForeverDB` e `## SavedVariablesPerCharacter: PregaoForeverCharDB` (base 4.8). |
| 19 | O agente e a mesa nunca escrevem em `WTF` nem direto em `Interface\AddOns`, fora dos scripts do modder (`wtf-sv.ps1` e `dev-link.ps1`), que rodam com o jogo fechado, com backup e com o ok do dono: é o limite 4 do projeto, e são eles que a DD2 e a S13 usam. O agente escreve na pasta de desenvolvimento do addon (`Config.lua`, `Calibrado.lua`, o código e `relatorios/`); a mesa lê as SavedVariables sem alterá-las e grava só o `Calibrado.lua` e o arquivo morto dela, fora do git (seção 12). Quem grava as SavedVariables em `WTF` é o cliente do jogo, na saída e no `/reload`: o addon só preenche as tabelas em memória. A ligação com o jogo é a junction do `dev-link.ps1`, feita uma vez com o jogo fechado; depois, editar na pasta de desenvolvimento e dar `/reload` (base 4.4, 4.9, 4.11). |
| 20 | Nome de outro jogador (vendedor, comprador, licitante) nunca é gravado nem mostrado. Os personagens do dono são chave do banco (`pers[nome]`) e do `Config.lua`. De `owners` grava-se só a contagem de donos distintos e um booleano de que os nomes vieram. É escolha do projeto, não regra da Blizzard nem do dono. |

**Funções de ação** são as 7 que levam `HasRestrictions` (`PostItem`, `PostCommodity`, `ConfirmPostItem`, `ConfirmPostCommodity`, `PlaceBid`, `StartCommoditiesPurchase`, `CancelAuction`; base 2.12) mais `ConfirmCommoditiesPurchase`. A wiki diz que esta última não exige evento de hardware (base 2.13); o design a trata como se exigisse. É a regra de conformidade do projeto: onde a base diz "não se sabe se pode", o addon age como se não pudesse.

## 2. Fatos em que o design se apoia e o que falta medir

### 2.1 Fatos

A tabela reúne os fatos que moldam o desenho inteiro; os demais vêm citados no ponto em que são usados.

| Assunto | Fato usado | Fonte |
|---|---|---|
| Mercado | Um mega-reino por conjunto de regras e região, com mais de 200 mil leilões numa varredura relatada; casa separada por facção é inferência. | base 1.2, 1.3 |
| Taxas | A tabela do cliente tem `DepositRate 5` e `ConsignmentRate 5`; a fórmula é inferência. O **depósito** (pago ao postar) vem das funções de cálculo e o **corte** (a parte da venda que a casa retém), da fatura do correio. | base 1.4 |
| Durações | 2, 8 e 24 horas, índices 1, 2 e 3; quatro faixas de tempo restante (Short é menos de 30 min). | base 1.5, 1.6 |
| Depósito | Mínimo de 1 prata até 17/11, depois 1 cobre. O texto do cancelamento diz que cancelar perde o depósito inicial; a fatura de venda soma o depósito ao recebido; o aviso de postagem diz que, numa manutenção semanal com atualização do leilão, o item volta antes e o depósito se perde. A expiração perder o depósito é regra do Classic, a medir. | base 1.7; strings, linhas 3390 e 4861; espelho, `Blizzard_MailFrame/MailFrame.lua:836` |
| Correio | O ouro da venda chega com cerca de 1 hora de atraso. Ler a caixa usa globais antigas sem documentação. A fatura tem 12 retornos (`invoiceType, itemName, playerName, bid, buyout, deposit, consignment, moneyDelay, etaHour, etaMin, count, commerceAuction`); o recebido é `bid + deposit - consignment`; existe o tipo `seller_temp_invoice`, a carta de venda pendente, que traz a hora prevista da entrega e nenhum dinheiro. | base 1.8, 3.1; espelho, `MailFrame.lua:790, 836, 847 a 856` |
| Consulta resumida | Por chave de item: `minPrice`, `totalQuantity` e `containsOwnerItem`, sem a **escada** (a lista de preços e quantidades à venda); sem limite escrito. | base 2.1, 2.2 |
| Busca por item | 100 por minuto pela documentação, que pede que ela não seja usada para varrer o leilão inteiro. Devolve a escada de uma **commodity** (item empilhável vendido por quantidade), por degrau, ou os leilões de um item, um a um. A resposta pode vir em páginas (`HasFull...SearchResults`, `RequestMore...SearchResults`). | base 2.2 a 2.4; R1a funções 57, 58, 75 e 76 |
| Estado único | Os resultados de consulta são estado único do cliente, dividido entre a tela da Blizzard e os addons: a lista da Blizzard relê tudo a cada evento de resumo, a aba de leilões refaz a consulta a cada cancelamento e o diálogo de compra cancela a cotação ao fechar. | espelho, `Blizzard_AuctionHouseBrowseResultsFrame.lua:7 a 13, 73 a 82`; `Blizzard_AuctionHouseAuctionsFrame.lua:214 a 217`; `Blizzard_AuctionHouseBuyDialog.lua:108 a 119` |
| Compra | Commodity: pedir cotação, receber o total por evento, confirmar; a tela da Blizzard tolera cotação 5% acima e chama `StartCommoditiesPurchase` com três argumentos. Item: `PlaceBid` com o valor do arremate. | base 2.7, 2.8; espelho, `Blizzard_AuctionHouseFrame.lua:847` |
| Postagem | `PostItem` e `PostCommodity` devolvem `needsConfirmation`; há um evento de leilão criado, feito para addons. Em item, quantidade maior que 1 liga o multisell (vários leilões e vários ecos numa chamada). | base 2.9; espelho, `Blizzard_AuctionHouseItemSellFrame.lua:74 a 83, 98 a 116` |
| Leilões próprios | Consulta, estado Active ou Sold, custo e função de cancelar. Avisos de venda e expiração chegam mesmo com o leilão fechado. | base 2.10, 2.11 |
| Ações | As 7 funções restritas não dão erro quando a condição falha: só não fazem nada. A wiki diz que exigem tecla ou clique; nada foi testado no Forever. A tela da Blizzard só as chama de dentro de um clique. | base 2.12, 2.13 |
| Ordem entre preços iguais | O próprio cliente tem o texto `AUCTION_HOUSE_UNDERCUT_TUTORIAL`: "There's no need to undercut! Auctions posted later (at the same price) are sold first." Fontes secundárias dizem o mesmo. Não foi testado no Forever. | strings, linha 1291; base 2.17 |
| Chave de item | `itemID`, `itemLevel`, `itemSuffix`; como um verde com sufixo aparece é incógnita. | base 2.15 |
| Cliente | Preço de vendedor no 11º retorno de `C_Item.GetItemInfo`. Binding de sobreposição liga tecla a botão; soltar é sempre explícito (`ClearOverrideBindings`). Foco em caixa de texto engole as teclas. Em segundo plano, 30 quadros por segundo. SavedVariables só vão ao disco no `/reload`, no logout e ao fechar, e nesta máquina gravam e voltam a carregar. O primeiro `/run` ou `/dump` da conta abre o aviso "Allow custom scripts?" e não roda (espelho, `Blizzard_ChatFrameBase/Shared/SlashCommands.lua`: os dois comandos passam pela mesma guarda). | base 3.2, 3.4, 3.8, 3.9, 8.1; strings, linha 5690 |
| Dono | Quatro personagens da Aliança, sem banco de conta. Em 2026-11-06 proibiu, no outro addon, funções que compram ou gastam por código. Nada configurado no jogo; decide vendo quadro. | base 4.2, 4.6, 4.7 |
| Gameplay | Nenhum agente opina; a única fonte de economia aprovada é o vídeo do Studen Albatroz (verde bom vai ao leilão; não vale vender todo o couro). | base 4.5 |

Um cuidado: a base 6.1 resume a semana 2 como queda de 41% na mediana listada e manda tratar como direção. O relatório por trás mostra os materiais de nível baixo subindo na mesma semana e listando bem acima do vendedor (R5b 2a, 2b). O design não supõe deflação geral nem taxa diária de queda: mede a deriva por classe de item (seção 7.4) e espera que anúncio de material abaixo do vendedor seja raro.

### 2.2 O que falta medir no jogo

Cada hipótese tem a medida da **sonda** (o roteiro de medidas no jogo, Apêndice A) e o que o design faz se ela for negada. Onde o código ou os textos do cliente já respondem uma parte, a linha diz; o que o cliente mostra não é o servidor, e a sonda continua valendo.

| # | Hipótese | Sonda | Se for negada |
|---|---|---|---|
| H-01 | O clique de um botão do addon acionado por binding de sobreposição satisfaz as funções de ação (base 11.1). A Blizzard só as chama de botões comuns e do aceite de popup; se o clique vindo de binding conta igual para código de addon, o código não mostra. | S2 | O dono clica o mesmo botão com o mouse. Se nem isso valer, fica o modo leitura. |
| H-02 | A soltura da tecla gera um clique só, e tecla segurada não repete, local e pelo acesso remoto. A fase do clique é escolha do addon (`RegisterForClicks`, seção 8.2); que a repetição de tecla não gere soltura é inferência. | S2 | As guardas de repetição cobrem os dois casos; a S2 repete com `LeftButtonDown`. |
| H-03 | O `/reload` grava as SavedVariables nesta build. A base 3.9 já conferiu que elas gravam e voltam a carregar nesta máquina; falta só o caso do `/reload`. | S1 | Salva-se no logout: a tecla de salvar some e a tela pede logout. A régua continua. |
| H-04 | Empilháveis são commodity; um verde com sufixo tem chave própria (base 11.2). `GetItemCommodityStatus` pode devolver `Unknown`, que bloqueia. | S0, S3 | O caminho de postagem segue `GetItemCommodityStatus` item a item; verde sem chave separável fica sem referência. |
| H-05 | A consulta resumida inteira custa segundos e poucos pedidos, e pode ser repetida a cada 10 minutos (base 2.6 é relato; base 11.3). | S4 | Resumo por categoria, em rodízio, ou um por sessão. |
| H-06 | Consulta fora de clique funciona (a Blizzard consulta de evento e de `OnUpdate`), e a prontidão do throttle vale para consultas (a Blizzard só a confere no botão de postar; esta metade segue aberta). | S4 | Cada consulta do fôlego sai direto de uma tecla. |
| H-07 | O `minPrice` do resumo, em item que não é commodity, é o menor arremate, e não o lance mínimo. | S4 | Até a S4 responder, a triagem do `piso` só usa chaves commodity: se o `minPrice` for lance, a lista incha e come o orçamento do fôlego. A escada reconfere o preço de qualquer forma. |
| H-08 | A tela da Blizzard e outro addon de leilão abertos interferem nas respostas. O código confirma que há interferência (seção 2.1, "Estado único"); falta medir o tamanho. | S4 | Vale a regra de descarte da seção 5.2. Se houver disputa de throttle com o autoscan do Auctionator, a saída é o dono desligá-lo (DD2). |
| H-09 | O depósito cobrado é o lido; o corte é o da tabela; a expiração perde o depósito (base 11.6). O cliente já afirma que cancelar perde, que a venda devolve e que a manutenção devolve o item e perde o depósito (seção 2.1). | S6 | O medido substitui o de partida; nada no código assume fórmula. |
| H-10 | Item cancelado e item comprado chegam pelo correio, com atraso. O cliente tem os assuntos "Auction canceled: %s" e "Auction won: %s" (base 1.8) e o evento `AUCTION_HOUSE_ITEM_DELIVERY_DELAY_UPDATE` com os dois atrasos (R1a evento 10); falta o valor. | S6, S8 | Se chegam direto à bolsa, cancelar fica mais barato. |
| H-11 | A fatura pode ser lida antes de a carta ser aberta. No espelho a Blizzard só chama `GetInboxInvoiceInfo` depois de `GetInboxText` devolver `isInvoice`, com a carta aberta (`MailFrame.lua:573 a 576, 781 a 790`); ler o texto pode marcar a carta como lida. São duas variantes a medir. | S7 | O `Correio.lua` usa só a forma que não muda o cabeçalho, ou fica nos cabeçalhos e na variação do dinheiro. |
| H-12 | O atraso do correio da venda é de cerca de 1 hora (base 11.10). Mede-se direto: a carta de venda pendente traz `etaHour` e `etaMin`. | S7 | O caixa projetado usa o medido. |
| H-13 | `owners`, `totalNumberOfOwners` e `timeLeftSeconds` vêm preenchidos (base 11.5). | S5 | Nada nas fases 1 e 2 depende dos nomes; sem a contagem de donos, a referência forte usa só a contagem de leilões e de unidades. |
| H-14 | Entre preços iguais vende primeiro o mais novo, como o texto do cliente afirma (strings, linha 1291; base 2.17). | S10 | A regra `igualar` perde o apoio do texto e a DD3 volta ao dono. A conta de fila (seção 7.2) usa o pior caso de qualquer forma. |
| H-15 | `PostItem` aceita o item direto da bolsa por `ItemLocation` (o código da Blizzard faz assim: `ContainerFrame.lua:1555 a 1561`). Quantidade maior que 1 em item liga o multisell, lido no código; o addon nunca a passa. O que o servidor faz com lance `nil` e só arremate é hipótese. | S2 | O dono posta pelo painel da Blizzard e o addon aconselha. |
| H-16 | Deixar um aviso de postagem sem confirmar não deixa nada pendente (a tela da Blizzard não chama nada ao recusar: `Blizzard_AuctionHouseFrame.lua:100 a 117`). O que dispara o aviso está no texto do cliente: manutenção semanal com atualização do leilão, devolução antecipada e depósito perdido (strings, linha 4861); o erro de postagem é o leilão fechado para postagem antes da atualização (strings, linha 1305). Se o servidor do Forever manda o aviso, e em que manutenção, só o jogo diz. | passiva | Cada aviso é gravado, com a data, para descobrir a regra. |
| H-17 | `StartCommoditiesPurchase` funciona com três argumentos, a única forma vista no cliente (`Blizzard_AuctionHouseFrame.lua:847`); a documentação tem dois. A primeira cotação da sonda usa três. | S8 | Repete-se com dois e grava-se a diferença. Sem medida, vale a forma de três. |
| H-18 | A cotação dura o bastante para ler e confirmar pelo acesso remoto (R1b incógnita 6). | S0 (comando 16, de graça) e S8 | Commodity por tecla fica inviável; sobram item e venda. |
| H-19 | `ReloadUI` chamado do clique de um botão do addon é aceito (é função Lua sobre `C_UI.Reload`, sem marca de restrição, e a Blizzard a chama do aceite de um popup comum); o `/reload` é rápido com 1, 3 e 5 MB. Só o tempo segue por medir. | S1 | A tela pede `/reload` digitado; o teto do banco não sobe. |
| H-20 | `GetTimePreciseSec` tem resolução para a fatia de 2 ms (R1c 5). | S1 | `debugprofilestop`, com a guarda de intervalo negativo; por fim, fatia por contagem de linhas. |
| H-21 | O preço de vendedor lido do cliente é o que o NPC paga (base 6.3). | lote de confirmação | O item sai da arbitragem. |
| H-22 | Uma oferta abaixo do vendedor vive mais que o tempo de reação do dono. | papel | A arbitragem de vendedor não liga. |
| H-23 | Personagem de nível baixo usa o leilão (R5a 2.5 não achou restrição; no cliente a única condição é não ser conta de teste). | S0 | Muda a escolha do negociador. |
| H-24 | Tempos de ausência com o leilão aberto (base 11.9). | o dono anota | O addon não mede nem interfere. |
| H-25 | Os eventos de leilão criado, cancelado e comprado chegam ao addon também quando a ação parte de outra tela (são eventos do cliente e chegam a todo quadro registrado). | S9 | A régua só mede o que passa pelo addon e pelo correio. |
| H-26 | `GetCurrentKeyBoardFocus()` diz ao addon que o foco está numa caixa de texto (a função existe e a Blizzard a usa). | S12 | Sem a faixa `Keys paused`; o rodapé `last key` continua mostrando que a tecla não chegou. |
| H-27 | O `timeLeftSeconds` de um leilão próprio com estado Sold é o tempo até o ouro chegar (R1b 10, incógnita 17). | S7 | A linha mostra só `SOLD`; o atraso vem da carta pendente e da fatura. |
| H-28 | A primeira resposta de uma busca vem em ordem crescente de preço, traz pelo menos os 12 primeiros degraus e marca as unidades próprias em `numOwnerItems` (R9, incógnitas 5 e 6). | S5 | O addon pede `RequestMore...` até cobrir a frente, dentro do orçamento, ou ordena o que recebeu; sem frente completa a foto não atualiza nada. |
| H-29 | O erro de postagem de equipamento (base 1.11) compara com o menor preço da chave, e não com o do `itemID` inteiro (a tela da Blizzard busca equipamento pela chave sem nível e sem sufixo, R1b 8). | S3 (lê as duas escadas) e a primeira postagem de equipamento | `igualar`, em equipamento, iguala o menor preço do `itemID`. |
| H-30 | A triagem barata de giro (seção 5.1) ordena as chaves como as escadas medem. | fase 2: correlação de postos em 30 chaves | Abaixo de 0,4, a fórmula é abandonada e fica o filtro declarado. |
| H-31 | Consulta feita pelo addon não mexe na marca de ausente do jogo. | S11 (o dono anota se a marca aparece durante a série densa) | A opção (b) da DD13 volta ao dono com esse fato; até lá vale a tecla por fôlego. |
| H-32 | A compra de commodity leva as unidades mais baratas primeiro (base 2.7), o débito sai na confirmação e ela pula as unidades de outro personagem da conta. A conta de preço da Blizzard só desconta as do próprio personagem (`Blizzard_AuctionHouseUtil.lua:207 a 230`). | S8 | Continua valendo a regra da seção 15: degrau com `containsAccountItem` dentro da profundidade da compra, nenhum sinal. |
| H-33 | Como aparece a venda parcial de um lote de commodity: fatura por parte, campo `count`, devolução proporcional do depósito (R9, incógnita 8). | S6 | O lote fica aberto até o último desfecho e a chance de venda é contada por unidade. |
| H-34 | Arquivos: um arquivo de SavedVariables que não analisa carrega a variável como `nil`; um `.lua` do addon com erro de sintaxe não impede a carga dos seguintes; o cliente guarda uma cópia `.bak`; o gravador escreve com tabulação e comentário de índice (cerca de 8% a mais); o banco real cabe no limite de constantes por função da linguagem. | S1, S13 | Cada resposta ajusta as defesas das seções 6 e 12; nenhuma derruba o desenho. |
| H-35 | O `/reload` com o leilão aberto fecha a casa (chega `AUCTION_HOUSE_CLOSED`) e não deixa mensagem presa no throttle. | S1 | Salvar pede o leilão fechado. |
| H-36 | Uma janela de 520 por 500 unidades cabe à direita do leilão e acima das bolsas na resolução e na escala do dono. | S0 (comando 15) | A bancada redesenha no tamanho medido; colunas que não cabem vão para o `I`. |
| H-37 | A fileira F1 a F5 chega ao jogo pelo acesso remoto, sem Fn. | S0 (o dono aperta F1 a partir do Acer) | As visões vão para `Shift+1` a `Shift+5`; os botões clicáveis valem sempre. |
| H-38 | O menor preço de uma escada de equipamento costuma vender (a frente, em item, não passa pelo filtro de isca). | passiva: vendas próprias com `igualar` | A linha continua mostrando o salto até o segundo preço e o dono julga. |
| H-39 | `CalculateCommodityDeposit` responde para item que não é commodity, o que daria o depósito de item fora da bolsa. | S0 (comando 8) | Vale a estimativa da regra 17. |

## 3. Tese de mercado e estratégias

### 3.1 Tese

O mercado é um só por conjunto de regras, enorme (base 1.2), e os concorrentes chegam com varredura completa, sniper e postagem assistida (base 5.1 a 5.3). O design não disputa a corrida de reflexo, e convém separar nisso o que é fato do que é escolha:

- **Fato do jogo e da operação.** Toda ferramenta depende de uma tecla ou clique por ação (base 2.12, 2.13; a ferramenta mais próxima declara "never trades on its own", base 5.2). O dono opera por acesso remoto, com a latência que isso traz (base 4.11). As ferramentas prontas enxergam mais mercado, pela varredura completa quando ela responde (base 2.5).
- **Escolha do projeto, com custo.** Dois tempos em toda compra (uma tecla a mais), `T_ver` antes da tecla que executa (1 s mais a latência), releitura quando a foto passou de 30 s (uma consulta, cerca de 2 s no ritmo de partida) e a varredura por fôlego. Somadas, custam da ordem de 3 a 5 segundos por compra, número a medir (linha "Tempo por ação" da seção 7.6). A taxa de "já sumiu" por tempo entre a foto e a tecla é gravada para que a DD1b e a DD13 sejam revistas com número.

Sobram três coisas que dependem de dado e de disciplina:

1. **Custo real medido.** A Blizzard não publicou corte, depósito nem devolução (base 1.4). Em item barato é o depósito que decide entre leilão e vendedor. Exemplo com a leitura provável da base 1.4 e 1.7, que é hipótese (H-09): um verde com preço de vendedor de 50 cobre e menor preço de 2 prata, por 24 horas, precisa hoje de 42% de chance de venda para empatar com o vendedor (depósito mínimo de 1 prata) e de 18% depois de 17/11 (depósito de 30 cobre).
2. **Venda calibrada do próprio estoque.** Nenhuma ferramenta vê a venda dos outros (base 5.8). As vendas do próprio dono são o dado mais limpo que existe sobre chance de venda, corte e tempo até o ouro voltar.
3. **Capital que não se perde.** Com 4 ouro de banca, um erro de 40 prata custa 10% dela.

**Construir contra adotar, peça por peça.** O que as ferramentas prontas fazem vem só das páginas públicas (base 5.1 a 5.3 e 5.8; R6a 2.2 e 2.10); o que essas páginas não dizem é incógnita, não defeito.

| Peça | O que já existe pronto | O que justifica a peça própria | O que não justifica |
|---|---|---|---|
| Régua (livro de ações, lotes e sessões) | Contabilidade e análise aparecem na lista de funções da ferramenta mais próxima (base 5.2); há addon de contabilidade que exporta CSV (R6a 2.2) | Mede por estratégia e por origem, inclusive o que é feito por outra tela; o banco tem contrato que a sessão do agente lê e devolve como `Config.lua` e relatório (base 4.7, 4.9). Funciona em `modo = "leitura"` e custa pouco | Não rende ouro por si |
| Fila (até cinco linhas do que fazer) | Listas de ofertas e de postagem existem (base 5.2) | As regras do dono, juntas: configuração só por arquivo escrito pelo agente, até 5 linhas por seção, estratégia com fonte aprovada e nascida desligada. A base não descreve ferramenta que cumpra as três | É conforto e método, não ouro |
| Mão: postar e cancelar por tecla | Postagem e cancelamento assistidos existem (base 5.2); se a postagem de cada ferramenta funciona no Forever, ninguém viu (base 4.3, 5.1) | Cofre, tetos em fração da banca, INCERTO sem reenvio, conciliação pelo correio; teclado e eco imediato para acesso remoto | É a parte cara e a que duplica o que existe. "Rende mais ouro" não é justificativa |
| Mão: comprar por tecla | Sniper e ofertas contra o vendedor e de revenda existem (base 5.2) | A máquina de evidência: papel com portão numérico, licença por estratégia, regra em sombra. Que as prontas não tenham algo parecido é incógnita | As prontas enxergam mais mercado e são mais rápidas por escolha de projeto |
| Visão do mercado | Varredura completa, uma a cada 15 minutos quando responde (base 2.5) | Nenhum dado sai do jogo | Em cobertura o addon próprio perde: 20 chaves por fôlego |

A decisão se toma com número, no fim da onda 2 (DD12): com a régua pronta, o dono compara três sessões pela tela da Blizzard com, se quiser testá-la, três por uma ferramenta pronta. Se a pronta render mais por ação sem ferir nenhuma regra dele, o projeto fica em régua e fila, em modo leitura, e as ondas 3 a 5 não são construídas. Instalar e testar ferramenta é decisão do dono, e a regra de curadoria (base 4.12) diz que dois addons no mesmo papel não entram juntos. A favor de construir, para a conta ficar honesta: a ferramenta mais próxima tem dias de vida e está em beta (base 5.2), e a base não sabe quais módulos da TSM funcionam no Forever (base 5.1). Adotar também é aposta, e sem Cofre.

### 3.2 Estratégias

Todas nascem com `licencas[id] = 0` no `Config.lua`. A fonte fica no `ARQUITETURA.md` e em comentário de `Estrategias.lua`, nunca na tela. Calcular preço e ponto de equilíbrio não é estratégia: é conta sobre o que o dono decidiu vender. Os catálogos são R8a (fichas 1 a 8) e R8b (recomendações R1 a R15).

| Id | Estratégia | Fonte | Sinal mensurável | Regra | Risco | Condição para ligar |
|---|---|---|---|---|---|---|
| `venda_verdes` | Vender no leilão os verdes bons | Vídeo do Studen Albatroz, a única fonte aprovada (base 4.5). Quais verdes são bons é juízo do dono: o addon lista e ele posta ou pula. | Ponto de equilíbrio `P*` contra a frequência de venda medida | Seção 7.2. Equipamento sempre iguala (base 1.11; H-29). | Depósito perdido (base 1.7); erro ao postar (base 1.11); verde sem referência forte (H-04; a onda 2 mede a fração) | DD1a; H-01 confirmada; depósito lido depois de 17/11 |
| `venda_sobras` | Vender sobras de coleta | R8b R4 (vender cru), R7 (lotes e rechecagem), R8 (nunca abaixo do vendedor), R14 (lote em tamanho de receita), R15 (leilão curto para o que gira). Guias de fã ou comerciais, do beta. | O mesmo, mais a quantidade na frente | Seção 7.2. A lista `reservas` (DD14) protege o que alimenta as profissões. Regra de preço e tamanho do lote são escolha do dono (DD3). | Preço em movimento; cobertura em minutos (R8b R7, editorial) | O dono aprova a fonte e escolhe a regra de preço (DD3); sem a escolha, a linha mostra `PICK RULE`, sem tecla |
| `piso` | Arrematar abaixo do preço que o vendedor paga | Nenhuma fonte de estratégia: é ideia dos agentes, com a aritmética da especificação dos modelos (R9 5.4). A ficha 5 do R8a só traz fontes sobre preço de vendedor. | Soma de `(v − p_j) · q_j` nas escadas lidas num fôlego (seção 3.3); taxa de "já sumiu" | Seção 7.3. O addon não vende ao NPC: marca o item e o dono clica. | Preço de vendedor mudado por hotfix (base 6.3); bolsa cheia; concorrentes com o mesmo recurso (R6a) | O dono aprova a ideia sem fonte ou indica fonte (DD3); DD1b; S8; três varreduras de prova em papel; lote de confirmação por item |
| `vao` | Comprar a frente da escada e repostar no vão | R8a ficha 2 (fã e guia genérico; alerta de isca em F23) | Passa no teste da seção 7.4: saída conservadora líquida sobre o preço médio pago de pelo menos `1 + μ_min/η_real` (1,30 com os valores de partida, o que pede cerca de 1,37 no preço bruto com corte de 5%) | Seção 7.4; só commodity, até 2 degraus. A saída é a saída conservadora, não o degrau seguinte menos um tick. | O vão fecha com oferta nova; estoque parado; isca | Portão de papel; corte e devoluções medidos; o ganho previsto da ordem micro vale pelo menos 3 vezes as teclas vezes o tíquete; aprovação |
| `sniper` | Arrematar abaixo do valor medido, por nomeação | R8a ficha 1 (documentação do TSM de 2022, do Classic; nenhuma fonte do Forever) | Preço até `a_max = U_lcb · η/(η + μ_min) − teclas · tiquete/(n · (η + μ_min))`, que dá cerca de 0,77 da saída com os valores de partida | Seção 7.4. O resumo nomeia, uma busca confirma, o teste completo roda antes de armar a tecla. | Valor velho; preço novo confundido com pechincha; outros snipers; "item not found" (base 1.11) | Portão de papel; "já sumiu" até 70% em 30 sinais; aprovação |
| `conversao` | Produzir com receita do personagem logado | R8a ficha 6 (descrição pública do addon Arbitrage; tabelas antigas) | Lucro da receita com insumo e produto lidos das escadas (R9 5.5) | Só receita que `C_TradeSkillUI.GetRecipeSchematic` devolve (base 3.7) e produto que não vincula (R4b 5e). Quem fabrica é o dono. | Produto sem saída; rendimento desconhecido em 526 receitas (base 9.2) | Fase 3 (seção 17.1) |

Na coluna "Sinal", `U_lcb`, `η` (o `η_real`), `μ_min`, `n` e `tiquete` são os da seção 7.4. Os limiares citados saem do teste de compra daquela seção: o sinal de papel nasce e é julgado pela mesma conta.

**Só medição, sem ordem de compra.**

- Hora e dia da semana: nenhuma fonte mede o ciclo no Forever (R8b ficha 1; base 6.5). O addon guarda o último mínimo lido em cada bloco de 4 horas das chaves com anel (campo `blocos`, seção 6) e, com três semanas, a mesa mostra se há ciclo.
- Abertura das raides em 2026-12-09 (base 6.4): só previsão de autor (R8b ficha 3); fica uma lista de observação.
- Vendedor com estoque limitado: sem fonte do Forever (R8a 9.3); quando o dono abre um vendedor, o addon anota `numAvailable` na tabela `npc` do banco (seção 6.1; base 9.3).
- Compra no vendedor para revenda no leilão: de todo item que o dono vê num vendedor o addon anota o preço de compra (`C_MerchantFrame.GetItemInfo`, base 3.7) na tabela `npc`; quantas vezes o menor preço do leilão passa dele com a margem da seção 7.4 é conta feita fora do jogo, sobre `dias` e `npc` (a conta é a do R9 5.4). Sem ordem de compra e sem estratégia até haver fonte aprovada.
- Vãos e arremates que passariam no teste da seção 7.4: contados por fôlego, com quanto duram, sobre as fotos gravadas desde a onda 2. A conta roda fora do jogo, na sessão do agente, por um script de análise sobre o banco lido, a partir da onda 3: é a conta da seção 7.4 sem a classe de saída B, que pede vendas inferidas. Os arquivos puros só ganham essa parte na onda 5, e nenhuma ordem nasce da contagem. É o que diz, antes de construir a onda 5, se o `vao` e o `sniper` têm sinal.

**Fora, com motivo.** Reset: só folclore (R8a ficha 4), valor esperado negativo em item líquido no modelo pessimista (R9 6.3), e é o padrão mais parecido com o sinal da base 1.10. Formação de mercado com spread: sem fonte (R8a ficha 3). Lance em leilão acabando: fonte do retail (R8a ficha 7) e sem teste possível por fotos (R9 10.2). Casa neutra: fonte de fã e taxas de 25 e 15 na tabela (R8a ficha 8; base 1.4). Equipamento para revenda: a fonte desaconselha (R8a F18) e a chave é incerta (base 2.15).

### 3.3 O modo papel: como o dado do addon vira evidência

Cada estratégia tem uma **licença** em quatro níveis: 0 desligada, 1 papel, 2 micro, 3 plena. O **nível concedido** é o menor entre a licença que o dono aprovou no `Config.lua` e o nível que a evidência sustenta: são duas chaves, a do dono e a do dado. Ele é avaliado na carga do addon e, dentro do jogo, só desce. Por cima dele, um disjuntor pode suspender a estratégia por um tempo (seção 9.4): o **nível em vigor** é o concedido menos essa suspensão, e quando o disjuntor destrava a estratégia volta ao nível concedido, nunca acima dele.

**Papel.** O sinal aparece na fila com a marca `PAPER`. A tecla de compra não chama função de ação: relê a escada, grava se a oferta ainda estava lá e registra a ordem de papel, pelo preço listado. `Sombra.lua` calcula o desfecho com preenchimento conservador: a compra só conta se a oferta estava na releitura; a venda só conta pelas **vendas inferidas** com prioridade pior que a do lote de papel.

**Venda inferida.** É a venda dos outros deduzida da diferença entre duas fotos da escada (R9 2.1 a 2.4). Não é limite inferior: é estimativa com viés nos dois sentidos. Subconta em mercado líquido (cerca de 83% recuperado com fotos a 5 minutos e 40% a 60 minutos, R9 0.3) e superconta em mercado de pouca demanda, onde a frente some por expiração e cancelamento. Por isso só conta em **par válido** de fotos:

1. as duas fotos têm a frente completa (seção 5.3) e distam até `Δ_max` (15 minutos de partida, faixa de 5 minutos a 2 horas), nunca entre sessões;
2. o sumiço que casa com repostagem não conta. Sem identidade de vendedor, o casamento é o critério sem nome do R9 2.3: a quantidade que aparece num preço mais baixo difere da que sumiu em até 10% (`tol_rep`), o preço novo fica até 5% abaixo da frente anterior (`g_rep`), e o número de donos cai 1 no degrau antigo e sobe 1 no novo. O R9 dá peso de 0,5 a esse casamento; aqui ele elimina a perda inteira, que é o lado conservador;
3. o sumiço pode ser expiração, e então não conta. Em item, leilão visto por último na faixa Short não conta. Em commodity, só conta o sumiço de coorte com idade conhecida (um degrau que nasceu numa foto desta sessão; até 32 coortes por chave, em memória) cujo intervalo não cruza 2, 8 ou 24 horas de idade; o que já estava na primeira foto da sessão tem idade desconhecida e não conta;
4. sem sobrevivente nos degraus guardados, o par é censurado: não é venda nem testemunha.

As vendas inferidas são calculadas sobre a foto compacta gravada (os 12 degraus e os baldes), a mesma que a mesa lê, e não sobre a escada inteira em memória: é o que permite ao replay dar o mesmo resultado (seção 16).

**Fecho do lote de papel.** O lote acumula **exposição observada**: a soma dos intervalos dos pares válidos da chave enquanto ele está aberto. As chaves com ordem de papel ou lote comprado aberto entram no foco em todo fôlego (seção 5.1).

- Fecha `sold` quando as vendas inferidas da chave o enchem. Lotes de papel abertos na mesma chave consomem a venda inferida em fila, o mais antigo primeiro, uma unidade inferida para uma unidade de papel, com o desconto de reação `π_react` de 0,2 (cada unidade inferida vale 0,8: o lote de papel não aparece na escada e ninguém o cobre, R9 10.2). A soma de papel aberto por chave respeita o teto de volume da seção 9.2.
- Fecha `not sold` ao vencer a duração do lote, ou em `T_fecho` (72 horas), só com 2 horas ou mais de exposição observada. A liquidação é marcada a max(preço de vendedor, saída conservadora de hoje) menos custos.
- Senão fica `inconclusive` e não conta no portão. A ficha de evidência mostra a fração inconclusiva e a exposição média: sem isso o papel mediria a presença do dono, não a estratégia.

**Papel para micro** (`vao`, `sniper`):

- 30 sinais conclusivos (`sold` ou `not sold`), em 10 grupos item-dia ou mais, com nenhum item acima de 20% dos sinais;
- resultado positivo, e ainda positivo sem os 3 melhores sinais e sem o melhor item;
- razão de somas, ganho realizado sobre ganho previsto antes do desconto `η_real`, acima do limiar. O limiar é decisão do dono (DD10), 0,5 de partida, com a nota de que 0,5 reprova metade das estratégias que entregam exatamente 0,5;
- corte e devoluções medidos, e a série densa da sonda (S11) feita, para conhecer a subcontagem na cadência real do dono.

Opção da DD1b, a **micro-sonda**: depois de 30 sinais de papel, lotes reais de até 2% da banca por item, para medir a saída pela fatura em vez de pela inferência.

**Papel para micro no `piso`.** Três varreduras de prova, em blocos de 4 horas distintos, com valor por tecla acima do dobro do tíquete (o valor mínimo por tecla, seção 7.5). Uma varredura de prova é um fôlego com resumo completo; o valor é a soma de `(v − p_j) · q_j` só das escadas lidas nesse fôlego, dividida pelas teclas. O relatório mostra também quantas chaves marcadas pela triagem ficaram sem leitura. Chave que não é commodity só entra depois de a S4 dizer o que é o `minPrice` (H-07). Em micro, cada ordem tem o teto da seção 9.2.

**Micro para plena.** 30 lotes reais; todo lote emitido há mais de `T_fecho` entra na conta, vendido ou não, o aberto marcado a max(preço de vendedor, saída conservadora de hoje) menos custos; razão de somas acima do limiar; resultado positivo; nenhum INCERTO sem solução. Em plena vale só o teto por item.

**Vendas.** Quando o dono aprova uma estratégia de venda, ela sobe de 0 direto para 2 (micro), sem passar por papel, porque não compra: só o depósito fica em risco. Sem aprovação fica em 0. Isso vale em `modo = "vivo"` (seção 4.3).

**Medidas de desvio.** `η_real = Σ ganho realizado / Σ ganho previsto antes do desconto`, razão de somas e nunca média de razões, com os abertos marcados. Grava-se também `δ = 1 − Σ saída realizada / Σ saída prevista`, que é o desvio estável: para o mesmo erro de preço de saída, o `η_real` muda com a margem do sinal (0,70 num sinal de 50% de margem e 0,23 num de 15%, com a saída 10% abaixo da prevista).

**Subir.** A tela mostra `eligible`. Subir é uma linha no `Config.lua`, escrita pelo agente depois do sim do dono, com a data em `aprovadaEm` e o registro em `estado.md`.

**Vieses conhecidos do papel** (R9 10.2, 10.3), para ler a ficha de evidência:

| Engana para cima | Engana para baixo |
|---|---|
| A oferta que ainda está lá na releitura é a que ninguém quis | O lote só "vende" quando há par válido de fotos da chave |
| Ao vivo há cotação, `T_ver` e segunda tecla: o "já sumiu" real é maior que o do papel | A venda inferida subconta em mercado líquido |
| Ao vivo a commodity é comprada pela cotação, que pode vir acima do listado | Chave que sai do foco não fecha (por isso entra em todo fôlego) |
| O lote de papel não é coberto por ninguém (descontado por `π_react`) | Depósito de item fora da bolsa é estimado (regra 17) |

O risco 5 da seção 19 diz o que acontece se o micro divergir do papel.

**Sombra.** Uma regra em sombra é calculada ao lado da regra em uso, sem virar conselho. Rodam em sombra, nas fases 1 e 2, as regras de preço que o dono não escolheu e a regra de cancelar (seção 7.4). O desfecho hipotético tem três valores: `would sell` (a regra em uso, de prioridade pior, vendeu, ou houve venda observada com prioridade pior), `would not sell` (a regra em uso, de prioridade melhor, não vendeu) e `unknown`. Só os dois primeiros entram na comparação: a regra em uso tem o desfecho visto na duração inteira, e a hipotética só nas janelas com foto. O valor de uma regra é a recursão finita

```
A   = p·(1−c) − (1−rs)·du        ganho se vende
L   = (1−rx)·du                  perda se expira
V_0 = v
V_K = P·A + (1−P)·(V_{K−1} − L)  repostar ate K vezes e depois vender ao NPC
```

com `K = 3` (do `Config.lua`) e `P` igual à frequência medida da classe. `K = 1` é o `W1` da seção 7.2; `K` infinito é o valor de liquidação `W` do R9 4.1 sem cliques e sem custo de carregar. A recursão não divide por `P`, e para todo `K` vale `V_K ≥ v` se e só se `P ≥ P*`. Com 50 desfechos conclusivos por classe, o dono decide com a comparação na mão. O `W*` com tabela de probabilidade de venda (R9 4.1) não tem fonte pública, o R9 não passou por revisor (base 10), e ele fica para a fase 3.

### 3.4 Escada de capital

Esta seção existe para o dono ver quanto cada degrau de banca demora e o que mais pesa. Tudo nela é hipótese: nenhum parâmetro tem valor medido hoje, e nenhuma linha é promessa nem conselho de como jogar. A régua mede os cinco parâmetros (seção 10) e a visão Session mostra o ritmo real.

**O modelo.** Por dia de jogo, com uma sessão:

```
voltas   = max(1, piso(horas de sessao / (entrega da compra + tempo ate vender + correio da venda)))
borda    = acerto · margem − (1 − acerto) · perda        por unidade de ouro aplicado, por volta
por volta:  ouro = ouro + fracao · (ouro − piso pessoal) · borda
por dia:    ouro = ouro + entradas de fora
```

`fracao` é a parte da banca aplicada (o teto duro é 50%). `margem` é o ganho líquido de corte e depósito quando o lote fecha com lucro, e `perda` é o que se perde quando não fecha. `acerto` é a fração de lotes com lucro. O correio da venda entra com cerca de 1 hora (base 1.8). `entradas de fora` é uma grandeza que a régua mede: toda variação de ouro que não vem das compras para revenda (o registro `Fora` da seção 10 e a venda do que os personagens coletam).

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

**Dias de jogo de 5,09 ouro até cada degrau** (conta do modelo, com o ouro reunido e piso de 1 ouro). Os dias contam a partir do dia em que a compra para revenda liga com ouro, não de hoje: a seção 17 não a põe antes de meados de dezembro, e até lá só as entradas de fora e a venda do próprio estoque mexem na banca.

| Cenário e variante | 15 ouro | 60 ouro | 250 ouro | 1.000 ouro |
|---|---|---|---|---|
| C1, trading mais entradas de fora | 18 | 79 | 208 | 381 |
| C1, só trading | 177 | 383 | 590 | 789 |
| C1, só entradas de fora | 20 | 110 | 490 | 1.990 |
| C1, com a compra só depois do dia 14 e de 15 ouro (a opção da DD10) | 20 | 81 | 210 | 383 |
| C2, trading mais entradas de fora | 5 | 18 | 36 | 57 |
| C2, só trading | 19 | 42 | 64 | 85 |
| C2, só entradas de fora | 7 | 37 | 164 | 664 |
| C2, com a compra só depois do dia 14 e de 15 ouro | 7 | 23 | 41 | 62 |
| C2, com absorção de 50 ouro por volta | 5 | 18 | 42 | 135 |
| C2, sem reunir o ouro (parte de 1,27 ouro no negociador) | 8 | 20 | 39 | 59 |
| C3, trading mais entradas de fora | 3 | 6 | 11 | 17 |
| C3, só trading | 5 | 10 | 16 | 21 |
| C3, só entradas de fora | 4 | 19 | 82 | 332 |
| C3, com a compra só depois do dia 14 e de 15 ouro | 4 | 15 | 20 | 25 |
| C3, com absorção de 50 ouro por volta | 3 | 6 | 13 | 38 |

Nas variantes "depois do dia 14 e de 15 ouro", os 14 dias são só um atraso de exemplo, para mostrar quanto pesa começar depois; não são a linha do tempo da seção 17. "Absorção" limita a 50 ouro o que o mercado aceita por volta, também hipótese. No C2, a parte do ganho que veio do trading é de 26% até 15 ouro, 54% até 60, 78% até 250 e 92% até 1.000.

**Sensibilidade no C2: dias até 60 e até 250 ouro, mudando um parâmetro.**

| Mudança | 60 ouro | 250 ouro |
|---|---|---|
| Base | 18 | 36 |
| 1 volta por dia (ciclo de 6 h) | 23 | 55 |
| 4 voltas por dia (ciclo de 1,5 h) | 12 | 23 |
| Fração aplicada de 0,25 | 23 | 55 |
| Margem líquida de 6% | 26 | 65 |
| Margem líquida de 18% | 14 | 26 |
| Acerto de 50% | 24 | 58 |
| Acerto de 90% | 14 | 27 |
| Perda no erro de 12% | 20 | 44 |
| Entradas de fora zero (só trading) | 42 | 64 |
| Entradas de fora de 0,5 ouro por dia | 27 | 48 |
| Entradas de fora de 3 ouro por dia | 12 | 28 |
| Entradas de fora de 6 ouro por dia | 8 | 20 |
| Piso pessoal zero em vez de 1 ouro | 17 | 36 |

**Ouro por hora de sessão só do trading, por degrau (hipótese).**

| Banca (ouro) | C1 lento | C2 central | C3 pesado |
|---|---|---|---|
| 5,09 | 0,01 | 0,04 | 0,11 |
| 15 | 0,03 | 0,15 | 0,39 |
| 60 | 0,14 | 0,65 | 1,62 |
| 250 | 0,58 | 2,74 | 6,85 |
| 1.000 | 2,33 | 10,99 | 27,47 |

**O que mais pesa.**

1. **Até cerca de 60 ouro, as entradas de fora.** No C2, tirá-las leva o degrau de 60 ouro de 18 para 42 dias; nenhum outro parâmetro sozinho mexe tanto. A banca de virada, em que o trading de um dia iguala as entradas de fora, é de 72 ouro no C1, 24 no C2 e 12 no C3. É por isso que a régua mede esse termo.
2. **De 60 ouro em diante, a taxa composta**: o produto da fração aplicada, das voltas por dia e da borda. Dobrar a fração ou as voltas dobra a taxa. A borda sobe com a margem e com o acerto, mas não em proporção: no C2, dobrar a margem multiplica a borda por 2,3, e levar o acerto de 70% para 90% a multiplica por 1,5.
3. **As voltas por dia têm teto físico.** O correio de cerca de 1 hora limita a uma volta por hora. Sessão longa compra voltas: 12 horas dão 4 voltas no C2.
4. **Adiar a compra para 15 ouro custa dias.** No C2 atrasa os 60 ouro de 18 para 23 dias, e no C3 de 6 para 15 (é a opção da DD10; o padrão é a condição medida da seção 3.2).
5. **O piso pessoal de 1 ouro quase não pesa** (17 contra 18 dias), desde que o ouro esteja reunido. Sem reunir, o piso deixa ao negociador só cerca de 27 prata de banca; reunido, ele deixa parado cerca de um quinto do capital de hoje.
6. **O topo depende do que o mercado absorve.** Com teto de 50 ouro por volta, os 1.000 ouro do C2 passam de 57 para 135 dias. Só a régua mede a absorção.

O C3 pede 80% de acerto, 15% líquidos e cinco voltas por dia durante semanas, e nenhuma fonte dos relatórios sustenta isso. Uma comparação aparece só como o critério que o risco 2 da seção 19 já usa, com a ressalva de origem: a única estimativa de ouro por hora dos relatórios é de um site que vende ouro, do beta e sem medida, de 3 a 10 ouro por hora de farm no nível 20 a 30 (R5b 2c). Pela conta acima, o trading só passa de 3 ouro por hora de sessão com banca acima de 110 ouro no C3 e de 274 ouro no C2. A régua refaz essa conta com os números do dono.

## 4. Arquitetura

### 4.1 Módulos e ordem de carga

Pasta `wow/modder/addons-proprios/PregaoForever/`, TOC conforme a regra 18, com `## OptionalDeps: Auctionator, Syndicator, Baganator, ElvUI`. Os 28 arquivos nascem como esqueleto na onda 1. A numeração é a ordem de carga; a coluna "Onda" diz quando o arquivo ganha corpo (seção 17).

| # | Arquivo | Responsabilidade | Onda |
|---|---|---|---|
| 1 | `Nucleo.lua` | `ns`, `ns.seguro`, eventos, os três relógios da regra 15, cobre inteiro, anéis, log de 60 linhas, fatiador de 2 ms | 2 |
| 2 | `Tetos.lua` | Tetos duros de dinheiro, como constantes | 1 |
| 3 | `Config.lua` | Do agente: modo, negociador, piso pessoal, teclas, licenças com `aprovadaEm`, regra de preço e lote por classe, limites, ritmo, fôlego e foco, reservas, latência do acesso remoto, destravas de disjuntor (esquema no Apêndice B) | 1 |
| 4 | `Calibrado.lua` | Parâmetros medidos (valor, amostras, data), escrito pelo agente ou pela mesa; nasce neutro. O leitor e a conferência do cabeçalho ficam em `Banco.lua` | 1 (neutro); 2 (leitor) |
| 5 | `Dados.lua` | Gerado das tabelas do cliente, só para triagem (seção 13) | 1 |
| 6 | `Receitas.lua` | Fase 3; esqueleto vazio | fase 3 |
| 7 | `Banco.lua` | Esquema das SavedVariables, gramática das linhas, versão por linha, poda, medidor, sequência, época, recibo, marca de fecho | 2 |
| 8 | `Itens.lua` | Chave de item em texto; cache de item (preço de vendedor ao vivo pelo link, commodity ou item); carga assíncrona de dados de item | 2 |
| 9 | `Pedidos.lua` | Porta única das consultas: fôlego, orçamento, vigia do throttle, descarte de resposta alheia | 2 |
| 10 | `Varredura.lua` | Máquina de varrer | 2 |
| 11 | `Escada.lua` | Resposta em degraus, sem as unidades próprias, com as duas marcas de completude; foto compacta | 2 |
| 12 | `Estimadores.lua` | Puro: referência com filtro de isca, preço robusto, parede, diferença de escadas, frequências, deriva | 3 (venda); 5 (fase 2) |
| 13 | `Motor.lua` | Puro: valor de uma tentativa, ponto de equilíbrio, candidatos, teste de compra, ordem da fila | 3 (venda); 4 e 5 (compra) |
| 14 | `Sombra.lua` | Puro: desfecho hipotético do papel e das regras não escolhidas | 4 |
| 15 | `Estrategias.lua` | Registro, licença em vigor e gerador de sinal de cada estratégia | 3 (vendas); 4 (`piso`); 5 (`vao`, `sniper`) |
| 16 | `Cofre.lua` | Banca por personagem, estados do ouro, tetos, disjuntores, `autoriza(ordem)`, conciliação | 2 (conciliação, em leitura); 3 (tetos, autorização e disjuntores) |
| 17 | `Livro.lua` | Régua: ações, lotes, sinais com desfecho, sessões, registro `Fora`, amostras de calibração | 2 |
| 18 | `Acoes.lua` | Único arquivo que chama as funções de ação; só o lado do clique | 3 (postar, cancelar); 4 (comprar) |
| 19 | `Ecos.lua` | Eventos de resposta e prazos das ações; não pode agir | 2 (observação, origem `outside`); 3 e 4 (máquinas) |
| 20 | `Teclas.lua` | Botões nomeados, bindings com a janela aberta, filtro de repetição, pausa. Liga e solta só com `InCombatLockdown()` falso; solta com `ClearOverrideBindings(janela)` no fechar | 2 (navegação: `L`, `N`, `U`, `I`, `O`, `K`, `H`, visões; e o `Y` só no bilhete de salvar da visão Session, que chama `ReloadUI` e nenhuma função de ação); 3 (botões de ação) |
| 21 | `Correio.lua` | Lê cabeçalhos e faturas de cartas de leilão, concilia; não pega nada; descarta nome de jogador | 2 |
| 22 | `Sonda.lua` | Roteiro de medição, um passo por cartão; a classe `sonda` do Cofre | 2 |
| 23 | `Pontes.lua` | Interoperação com `pcall` (seção 14) | 2 |
| 24 | `Visual.lua` | Cópia do kit `ns.ui` do GuiaForever, que é do dono (base 7.5) | 2 |
| 25 | `Alertas.lua` | Faixa de alertas em quadro próprio, que vive também fora do leilão; `FlashClientIcon`, `PlaySound` (base 3.6) | 3 |
| 26 | `Janela.lua` | Casca da janela do leilão: abre com `AUCTION_HOUSE_SHOW`, fecha com `AUCTION_HOUSE_CLOSED`. O painel do correio é outro quadro, com o ciclo `MAIL_SHOW` e `MAIL_CLOSED` | 2 |
| 27 | `Telas.lua` | As cinco visões, o painel do correio e o cartão da sonda | 2 (Session, Mine, painel do correio, cartão da sonda); 3 (Next, Sell, Risk) |
| 28 | `PregaoForever.lua` | Eventos de vida (`ADDON_LOADED`, `PLAYER_LOGOUT`) e `/pregao` | 2 |

### 4.2 Fluxo dos dados

```
[TECLA L] -> Teclas -> Pedidos (folego) -> Varredura -> Escada (foto) -> Banco
                                               |
                               Estimadores -> Motor -> Estrategias (sinais)
                                                            |
             Telas <- bilhete <- Cofre.autoriza(ordem) <----+
               |
[TECLA B, C]    -> Teclas -> Acoes (OnClick: guardas, Cofre; B cota ou arma, C so arma)
[TECLA P]       -> Teclas -> Acoes (so arma ate a DD5; depois dela, posta: 1 funcao de acao)
[TECLA Y]       -> Teclas -> Acoes (OnClick: Cofre, Livro.intencao, 1 funcao de acao)
[TECLA M]       -> desarma o bilhete; CancelCommoditiesPurchase se havia cotacao
                          evento de eco -> Ecos -> Livro -> Cofre (concilia) -> Telas
                          sem eco no prazo -> INCERTO -> conciliacao (folego curto da tecla; senao, o proximo folego) -> Livro
[caixa de correio aberta pelo dono] -> Correio (so le) -> Livro -> Cofre
[TECLA Y na visao Session, tudo em repouso] -> ReloadUI -> SavedVariables no disco
                          -> agente ou mesa -> Config.lua, Calibrado.lua -> proximo /reload
```

O **bilhete** é o resumo de uma ordem que gasta ou perde depósito (total, teto, fração da banca, saída), mostrado antes da tecla que a executa. O **eco** é o evento do jogo que confirma uma ação. Nenhuma seta sai de `Estimadores`, `Motor` ou `Estrategias` para `Acoes`: o caminho até a API passa sempre por uma tecla e pelo Cofre.

**A ordem.** O Cofre, o Livro, as Telas e a bancada leem o mesmo objeto, com estes campos: `verbo` (postar, comprar, cancelar), `chave`, `quantidade`, `preco` unitário, `total`, `teto`, `fracao` da banca, `saida` (valor e classe), `estrategia`, `nivel`, `motivo` (por exemplo `NEW`, `RESTOCK`, `AGED`), `fotoEm` (hora da foto que a sustenta) e, depois da tecla, `seq`. O estado de cada máquina de ação é de `Acoes.lua`; `Ecos.lua` só pede a transição.

### 4.3 Modos e máquinas de estado

O campo `modo` do `Config.lua` tem três valores.

- `leitura`: os botões de ação nem são ligados. A fila aponta, o dono age pela tela da Blizzard e a régua mede.
- `papel`: toda licença fica limitada a papel, inclusive as de venda. `P`, `C`, `B` e `Y` não chamam função de ação: gravam a ordem de papel com a hora da tecla, medem o tempo de decisão e o desfecho em sombra, e a tela mostra `PAPER - nothing posted` (ou `PAPER - no gold moved`). É também o modo de treino.
- `vivo`: valem as licenças de cada estratégia.

O addon cai sozinho para `leitura`, com a faixa correspondente, quando o banco não carregou (`DATABASE NOT LOADED - tell the agent`, seção 6) ou quando o `Config.lua` falta, está quebrado ou é de outro esquema (`CONFIG ERROR - read only`, seção 12).

As máquinas são sete, todas explícitas, sem corrotina: Pedidos, Varrer (seção 5.2), Comprar commodity, Comprar item, Postar, Cancelar e INCERTO (seção 8.3). Uma ação em voo por vez. Timer e evento só mudam estado: nunca chamam ação e nunca abrem fôlego. A única consulta que um evento ou um prazo pode pedir é a seguinte de um fôlego já aberto por tecla (regra 9).

## 5. Coleta

### 5.1 Planos de varredura

| Plano | Consulta | Traz | Quando |
|---|---|---|---|
| A, resumo | `SendBrowseQuery` com texto vazio, a tabela `sorts` e os sete filtros de qualidade, como a tela da Blizzard monta; `RequestMoreBrowseResults` até `HasFullBrowseResults` (base 2.1) | menor preço e quantidade total por chave | Uma vez por fôlego, se o último tem mais de 10 minutos |
| B, próprios | `QueryOwnedAuctions(sorts)` (base 2.10) | estado, quantidade, tempo e preço de cada leilão do dono | Todo fôlego |
| C, foco | `SendSearchQuery(itemKey, sorts, separateOwnerItems)` por chave (base 2.2); em equipamento, também `SendSellSearchQuery` com a chave sem nível e sem sufixo, que traz as variantes do mesmo `itemID` (é como a tela da Blizzard busca equipamento, R1b 8) | escada de commodity ou leilões de item | Até `folego.max_buscas` por ciclo (20 de partida) |
| D, cabeça | `RefreshCommoditySearchResults(itemID)` ou `RefreshItemSearchResults(itemKey)` quando `HasSearchResults(itemKey)` é verdadeiro, como a Blizzard relê; senão uma `SendSearchQuery` | a escada fresca da linha selecionada | Quando uma tecla de ação encontra foto vencida |

Toda consulta leva a tabela `sorts` (vazia ou igual à da Blizzard): `QueryOwnedAuctions` e `SendSearchQuery` não aceitam `nil`.

**O aviso oficial.** A documentação limita `SendSearchQuery` e `SendSellSearchQuery` a 100 chamadas por minuto e pede que elas não sejam usadas para varrer o leilão inteiro (base 2.2). O plano A usa `SendBrowseQuery`, a chamada da própria tela da Blizzard, no máximo a cada 10 minutos; o plano C é foco, não varredura. `ReplicateItems` não é usada nas fases 1 e 2 (base 2.5; regra 10).

**O foco.** As vagas de um ciclo (`folego.max_buscas`, 20 de partida, do `Config.lua`) são preenchidas assim:

1. **Vigília**, até 8 vagas, antes de tudo e em todo fôlego: chaves com ordem de papel aberta, com lote comprado aberto e as fixadas em `Config.foco.vigilia`. Sem a mesma chave em fôlegos seguidos não há par de fotos, e sem par não há venda inferida, testemunha nem fecho de papel. Se passarem de 8, entram as de papel ou de lote mais antigo, e as demais disputam as cotas.
2. **Cotas** para o resto, de partida: 8 para itens vendáveis das bolsas, não reservados; 4 para chaves com leilão próprio ativo; 4 para a triagem do `piso` (chaves cujo `minPrice` ficou abaixo do preço de vendedor de `Dados.lua`; só commodity até a S4, H-07); 4 para chaves de giro, na fase 2. Quando a vigília ocupa vagas, as cotas encolhem na mesma proporção, com mínimo de 1. Vaga ociosa de uma cota passa à seguinte.
3. **Dentro de cada cota**, a prioridade é `peso · (1 − exp(−idade/Δ_foco))` (R9 11.5), em que `idade` é o tempo desde a última foto da chave e `Δ_foco` vale 10 minutos de partida: as mesmas 20 chaves não se repetem enquanto houver outras mais velhas.
4. **Ordem de envio**: vigília e triagem primeiro; as chaves das linhas de ação (venda e compra) por último, para que cheguem mais frescas à tecla.

**Chaves de giro (fase 2).** O filtro declarado é: preço unitário até o teto por item (seção 9.2), mínimo acima do preço de vendedor e quantidade positiva em 2 resumos seguidos, em rodízio. Uma triagem mais fina fica como hipótese (H-30):

```
queda  = 1 se o minimo caiu ate g_cob (3%) entre dois resumos completos, senao 0
tremor = media movel de queda / Δ                 coberturas finas por hora
saida  = media movel de max(0, Q_anterior − Q) / Δ   unidades que saem por hora
giro~  = saida · minimo / (1 + k_t · tremor)
```

`Δ` é o intervalo entre os dois resumos, em horas; a média móvel é exponencial, com peso 0,3 para a leitura nova; `k_t` vale 1 hora de partida (não há valor de origem; ele sai da calibração). Os dois acumuladores por chave ficam no campo `tri` do banco, só na fase 2. Limites já conhecidos da fórmula: `saida` mede queda líquida do estoque listado, não giro (um cancelamento grande pontua mais que um item que vende com reposição); `tremor` nasce zero em preço de poucos cobres, porque um tick só cabe em 3% a partir de 34 ticks de preço; o produto favorece item caro, e por isso o filtro de preço vem antes. Critério de abandono: correlação de postos contra o giro medido nas escadas abaixo de 0,4 em 30 chaves.

### 5.2 A agenda sob throttle

Uma tecla por rodada de consultas é escolha de desenho, não regra: nenhuma fonte oficial nem regra do dono exige tecla por consulta, e a base 8.2 diz que a questão não está respondida por nenhuma fonte lida. A regra do projeto que vale é outra: nada pode evitar a marca de ausente por automação. O gatilho é a decisão DD13, com três opções:

| Opção | Como funciona | Situação |
|---|---|---|
| (a) uma tecla por fôlego | Cada `L` abre um ciclo, que acaba em `folego.max_buscas` ou `folego.max_s` | Padrão das ondas 2 a 4 |
| (b) vigília com presença | O fôlego se renova, ciclo após ciclo, enquanto a última tecla do dono no terminal (qualquer tecla do mapa) tiver até `T_pulso` (90 s de partida, nunca acima de 240 s). Sem tecla, para sozinho e a tela diz `PAUSED - press L`. Cada ciclo respeita `folego.max_buscas` e `folego.max_s` | Recomendada a partir da fase 2: sem ela o modo papel só fecha lotes curtos dentro da sessão. Depende da H-31 |
| (c) contínuo sem presença | Consultas enquanto a janela estiver aberta | Recusada: é o desenho que encosta na regra da ausência |

Em qualquer opção vale o invariante I9: nenhuma consulta sai sem uma tecla do dono há no máximo `T_pulso`.

```
PARADO --[TECLA L]--> PROPRIOS (QueryOwnedAuctions -> OWNED_AUCTIONS_UPDATED; concilia)
PROPRIOS --> RESUMO (plano A, se vencido)
RESUMO --AUCTION_HOUSE_BROWSE_RESULTS_UPDATED--> GetBrowseResults() uma vez; zera o acumulo
RESUMO --AUCTION_HOUSE_BROWSE_RESULTS_ADDED(addedBrowseResults)--> soma o payload ao acumulo
RESUMO --HasFullBrowseResults falso--> RequestMoreBrowseResults -> RESUMO
RESUMO --completo--> TRIAGEM (le o acumulado em fatias de 500 linhas; monta o foco)
RESUMO --AUCTION_HOUSE_BROWSE_FAILURE, 10 s sem resposta ou lista que encolheu--> incompleto -> TRIAGEM
TRIAGEM --> FOCO (plano C, uma chave por vez)
FOCO --frente completa--> grava a foto -> Estimadores -> FOCO (proxima)
FOCO --resposta sem a frente--> ate 2 RequestMore...SearchResults -> FOCO (mesma chave)
FOCO --10 s, ou ainda sem a frente--> foto sem frente (nao atualiza nada) -> FOCO (proxima)
FOCO --folego.max_buscas, folego.max_s ou fim da lista--> PARADO ("Press L")           opcao (a)
FOCO --idem, com tecla do dono ha ate T_pulso--> PROPRIOS (novo ciclo)                   opcao (b)
qualquer --sem tecla do dono ha T_pulso--> PARADO ("Press L"); vale nas opcoes (a) e (b), conferido antes de cada envio
qualquer --TRAVADO ou AUCTION_HOUSE_CLOSED--> PARADO, fila zerada
```

Regras de `Pedidos.lua`:

- **Abertura do leilão.** O evento `AUCTION_HOUSE_SHOW` não dispara consulta. A faixa mostra `Press L to reconcile` e as ações ficam bloqueadas até o primeiro fôlego conciliar leilões próprios, dinheiro e bolsas com o Livro (seção 10).
- **Envio.** Antes de cada envio, `Pedidos.lua` confere a I9: sem tecla do dono nos últimos `T_pulso` segundos, o ciclo para onde está. Depois, só com `IsThrottledMessageSystemReady()` verdadeiro (H-06), uma consulta em voo, até `ritmo.buscas_min` (30 de partida, que são 30% do limite documentado, base 2.2). O ritmo e `folego.max_buscas` contam as buscas por item dos planos C e D, inclusive cada `RequestMore...SearchResults`. As páginas do resumo (`RequestMoreBrowseResults`, plano A) ficam fora dessas duas contas: seguem só o throttle do cliente e o teto de tempo do ciclo (`folego.max_s`), porque o limite documentado é o das buscas por item. O máximo do ritmo é o sustentado na sonda sem mensagem descartada, e nunca passa de 100 (seção 9.2).
- **Vigia** pelos eventos `AUCTION_HOUSE_THROTTLED_*` (base 2.14). "Não pronto" por mais de 30 s vira `TRAVADO`: o addon para de consultar, bloqueia ações e pede ao dono que feche e reabra o leilão. Dois `AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED` encerram o fôlego.
- **De quem é a resposta** (H-08). A resposta de resumo chega como `AUCTION_HOUSE_NEW_RESULTS_RECEIVED` com payload `nil`; com `itemKey` no payload, é resposta de busca. A lista de resumo do cliente também muda quando chega resposta de busca: fora do estado RESUMO, `AUCTION_HOUSE_BROWSE_RESULTS_UPDATED` é ignorado. `COMMODITY_SEARCH_RESULTS_UPDATED(itemID)` e `ITEM_SEARCH_RESULTS_UPDATED(itemKey)` só fecham a espera se a chave for a do pedido em voo; `ITEM_SEARCH_RESULTS_UPDATED` com `newAuctionID` é atualização de um leilão, não resposta. Lista de resumo que encolhe ou muda de ordem entre duas respostas marca o resumo como incompleto.
- **De onde vêm as linhas do resumo.** `GetBrowseResults()` devolve a lista inteira numa chamada que não se fatia: é chamada uma vez, no `..._UPDATED`. As páginas seguintes vêm no payload de `..._ADDED`. Chamá-la a cada página alocaria cerca de 73 mil linhas por resumo, em vez de 8 mil (conta sobre a base 2.6, com páginas de 480 linhas).
- **Fôlego curto de uma tecla de ação.** Uma tecla de ação abre um fôlego de uma consulta antes de agir (plano D) ou de até duas consultas de conciliação depois. Esse fôlego nasce na tecla e acaba quando a ação fecha (eco, falha ou INCERTO conciliado) ou em `T_pulso`, o que vier primeiro. **Foto velha, a tecla atualiza; foto fresca, a tecla age.** A exceção é o `B` em item, que sempre relê o leilão antes de armar, porque a compra é de um leilão específico. A linha mostra a idade da foto (`price from 3m ago`), para o dono saber o que a tecla vai fazer.
- **Custo no tempo.** Um ciclo com resumo leva cerca de 50 s (1 s dos próprios, 8,5 s do resumo relatado na base 2.6 e 20 buscas a 2 s); sem resumo, cerca de 41 s. Por isso a idade máxima para comprar (30 s) é menor que o ciclo, e a primeira tecla numa linha de compra quase sempre relê (seções 7.3 e 7.5).

### 5.3 O que cada foto grava

A **foto** é o registro de uma resposta do leilão, com hora e marcas de completude.

| Foto | Campos |
|---|---|
| Resumo | hora do pedido e da resposta, pedidos gastos, `completa`; por chave, menor preço e quantidade. Guarda-se o último inteiro; por dia de mercado, o mínimo e a quantidade de até 1.500 chaves (`dias`); por bloco de 4 horas, o último mínimo e a quantidade das chaves com anel (`blocos`). Leitura de chave com `containsOwnerItem` não entra em `dias` nem em `blocos`: o mínimo estaria contaminado pelo leilão do próprio dono. |
| Escada de commodity | até 12 degraus `preco:quantidade:donos` (`donos` é `totalNumberOfOwners`, um número); a cauda em 8 baldes de preço; as unidades próprias por degrau (`numOwnerItems`); a marca de conta por degrau (`containsAccountItem`); a quantidade total lida (`qtot`); as marcas `frente` e `escada`. O `timeLeftSeconds` do degrau, se vier, vai só ao cartão da sonda (S5): a regra de expiração usa a idade da coorte (seção 3.3) |
| Leilões de item | os 30 leilões com arremate mais barato: `auctionID`, arremate, lance, faixa de tempo, quantidade, marcas de dono e de conta; a contagem e a soma do resto; a contagem de donos distintos, calculada na hora e gravada como número; o booleano `nomesVieram`. Leilão só de lance fica fora da frente e da contagem. |
| Próprios | `auctionID`, estado, quantidade, tempo, lance, arremate |

**Duas marcas de completude.** `frente`: a primeira página chegou e está em ordem crescente de preço (H-28); vale para referência, fila na frente e fronteira da venda inferida. `escada`: `HasFullCommoditySearchResults(itemID)` ou `HasFullItemSearchResults(itemKey)` é verdadeiro; vale para quantidade total e baldes. Sem a marca `escada`, a quantidade total vem de `GetCommoditySearchResultsQuantity` e a cauda é gravada como `truncada`. Sem a marca `frente`, a foto não atualiza estimador nem gera sinal. Uma escada funda de minério ou de tecido, que vem em páginas, tem foto válida já na primeira página.

**Baldes da cauda.** Os 8 baldes somam a quantidade além do 12º degrau por faixa de preço, com limites em múltiplos do preço do 12º degrau: 1,05; 1,1; 1,2; 1,35; 1,5; 2; 3; e o resto. É escolha de projeto, a rever com as primeiras fotos.

**Nomes.** O texto dos nomes nunca é gravado nem mostrado (regra 20). De `owners` ficam só a contagem de donos distintos e o booleano de que os nomes vieram, para a S5.

Foto sem a frente, vencida ou vazia onde havia oferta não atualiza estimador nem gera sinal (R9 1.5). Zero linhas onde a foto anterior tinha oferta é **vazia suspeita**: é descartada, nunca lida como "tudo vendeu".

## 6. Banco

Uma tabela de conta, `PregaoForeverDB`, com seção por personagem para o que é dinheiro e seção por casa de leilão para o que é mercado, e uma tabela mínima por personagem, `PregaoForeverCharDB`. Linhas em texto compacto no lugar de tabelas aninhadas, para encolher o arquivo (R9 11.3).

```lua
PregaoForeverDB = {
  esquema = 1,
  epoca   = 0,      -- GetServerTime() da criacao do banco: identifica a serie de seq
  seq     = 0,      -- contador monotonico dos registros
  recibo  = 0,      -- ate qual seq o arquivo de fora ja guardou
  calib   = {},     -- [parametro] = linha de calibracao + amostras
  casas   = {},     -- [reino:faccao] = { itens, resumo, dias, blocos, giro, tri, fotos, npc }
  sinais  = {},     -- anel: sinal, nivel, executou, desfecho
  pers    = {},     -- [nome] = { livro, lotes, abertos, proprios, cofre, correio, fora, fecho }
  sessoes = {}, sonda = {}, log = {},
  sobrescritos = {},-- [anel] = { de, ate }: seq que o anel cobriu sem recibo
  salvoEm = 0,      -- gravados so no PLAYER_LOGOUT:
  fim     = 0,      -- igual a seq quando a saida foi limpa
}
PregaoForeverCharDB = { bancoDesde = 0 }   -- prova, por personagem, de que o banco ja existiu
```

**Casa.** As seções de mercado ficam em `casas[GetNormalizedRealmName() .. ':' .. UnitFactionGroup('player')]`. Um personagem de outra facção ou de outro conjunto de regras (o Hardcore anunciado, base 1.2, 6.4) usa a sua própria casa e nunca lê a do negociador: sem isso ele gravaria preços de outro mercado nas mesmas chaves, em silêncio.

**Dois dias.** O **dia de mercado**, usado em `dias`, é a data UTC de `GetServerTime()`. O **dia de risco**, usado nos tetos e disjuntores "do dia", é a data local da máquina (`date('*t')`) com virada às 06:00: pelo relógio UTC o dia viraria às 21:00 de Brasília, no meio das sessões noturnas do dono. Os dois nomes ficam separados no código e na tela.

### 6.1 Gramática das linhas

É contrato entre o Lua, o `ler-pregao.mjs`, o replay e a mesa: fica congelada na onda 1 e é testada por ida e volta no `ler-pregao.mjs`. Toda linha começa pela versão do formato (`1|`); `Banco.lua` converte na leitura, sem migrar em massa, e a mesa recusa só o registro de versão desconhecida. Toda linha que pode ser podada carrega o `seq`. Campos separados por `|`; listas por `;` ou `,`; subcampos por `:`. Números inteiros (regra 14).

```
Texto da chave de item
    linha    itemID para commodity; itemID:itemLevel:itemSuffix para item
    exemplo  2589; 6541:18:845

casas[c].itens[chave]
    linha    1|vend|tipo|pilha|conf (preço de vendedor lido; c ou i; tamanho da pilha; 1 se confirmado no NPC)
    exemplo  1|13|c|20|1

casas[c].resumo
    linha    tabela { t, tr, pedidos, completa, n, dados }; dados é uma string só, 1|chave=min:qtd;...
    exemplo  1|2589=9:3120;2770=54:880

casas[c].dias[chave]
    linha    1|dia:min:qtd;... (dia de mercado em dias desde 1970)
    exemplo  1|20773:9:3120;20774:10:2890

casas[c].blocos[chave]
    linha    1|bloco:min:qtd;... (bloco = piso do tempo do servidor dividido por 14.400)
    exemplo  1|124640:9:3120;124641:9:3300

casas[c].giro[chave] (fase 2)
    linha    1|bloco:vendas:exposicao;... (vendas inferidas e segundos de exposição observada no bloco)
    exemplo  1|124640:38:5400

casas[c].tri[chave] (fase 2, H-30)
    linha    1|saida|tremor|t (em milésimos por hora)
    exemplo  1|4200|0|1794873600

casas[c].fotos[chave], commodity
    linha    1|seq|t|marcas|qtot|degraus|cauda; degrau preco:qtd:donos:proprias:conta; marcas com F (frente) e E (escada); qtot é a quantidade total lida, gravada sempre, para que a foto de cauda truncada ainda sirva à janela `N_ref` e à parede; cauda com os 8 baldes ou T (truncada)
    exemplo  1|8841|1794873600|FE|214|9:14:2:0:0,10:200:5:0:0|0,0,0,0,0,0,0,0

casas[c].fotos[chave], item
    linha    1|seq|t|marcas|donos|nomesVieram|leiloes|resto; leilão id:arremate:lance:faixa:qtd:dono:conta; resto contagem:soma
    exemplo  1|8850|1794873700|F|2|1|771:20000:0:2:1:0:0,774:21500:0:3:1:0:0|0:0

sinais
    linha    1|seq|t|estrategia|nivel|chave|qtd|preco|previsto|motivo|executou|desfecho|realizado|exposicao
    exemplo  1|9002|1794874000|piso|1|2589|14|9|56|NEW|0|sold|52|7400

pers[n].livro (ação)
    linha    1|seq|t|verbo|chave|qtd|preco|estrategia|origem|antes|depois|eco|tEco|erro|bilhete|fotoEm (origem key, mouse ou outside; dinheiro antes e depois; bilhete conforme o verbo: buy total:teto:fracao:saida, post duracao:regra:deposito:fila, cancel deposito:custo:fila, com a fração em milésimos; fotoEm é a hora da foto que sustentou a ordem; os dois vazios em ação de fora)
    exemplo  1|9010|1794874100|post|6541:18:845|1|20000|venda_verdes|key|31200|31170|created|1794874101||24:m:30:0|1794874058

pers[n].lotes, pers[n].abertos
    linha    1|seq|t|chave|qtd|custo|origem|estado|tFecho|resultado (origem comprado ou coletado; estado maos, postado, vendido, npc ou retirado)
    exemplo  1|9011|1794874100|6541:18:845|1|0|coletado|postado|0|0

pers[n].correio (fatura)
    linha    1|seq|t|tipo|chave|bid|buyout|deposit|consignment|moneyDelay|etaHour|etaMin|count|commerce (chave do item, resolvida pelo anexo da carta ou, na venda, pelo nome contra os lotes abertos; o texto do nome não é gravado; vazia se não resolveu, e aí o lote casa por valor e hora)
    exemplo  1|9050|1794880000|seller|6541:18:845|20000|20000|30|1000|0|0|0|1|0

pers[n].fora
    linha    1|seq|t|variacao|janela (play ou between)
    exemplo  1|9060|1794881000|1240|play

pers[n].proprios
    linha    1|auctionID|estado|qtd|tempo|lance|arremate|t
    exemplo  1|771|1|1|3600|0|20000|1794874200

pers[n].cofre
    linha    tabela: contadores do dia de risco e disjuntores[nome] = "1|gatilho|t|seq"
    exemplo  1|perda_dia|1794875000|9031

pers[n].fecho
    linha    tabela { dinheiro, t, seq }, gravada no PLAYER_LOGOUT

calib[parametro]
    linha    1|valor|n|medido|em|build, mais as amostras, uma por item da lista, todas com hora e build: t:build:valor nos parâmetros numéricos; na frequência de venda, t:build:classe:duracao:regra:fila:preco:desfecho (classe c, ou e1 a e4 para equipamento comum, incomum, raro e épico; regra m, u ou f; desfecho s vendeu, x expirou, c cancelado, d downtime); no "já sumiu", t:build:faixa:idade:ficou (faixa de desconto de 1 a 3; segundos entre a foto e a tecla; 1 ou 0); na sombra, t:build:classe:regra:desfecho:valor (desfecho w, n ou u: venderia, não venderia, não se sabe)
    exemplo  1|500|3|1|1794880000|70938

sessoes
    linha    1|seq|tIni|tFim|acoes|resultado|fora|gargalo|parametros (acoes post:buy:cancel:outside; gargalo capital, sinal, vazao, giro ou vazio)
    exemplo  1|9100|1794870000|1794875520|21:14:3:11|1075|2400|capital|

casas[c].npc[itemID] (só medição: o que o dono viu num vendedor)
    linha    1|compra|disponivel|t (preço de compra no vendedor; numAvailable, ou -1 se ilimitado; hora)
    exemplo  1|500|3|1794874300

sonda[passo], log
    linha    sonda: 1|t|build|resultado (texto do passo, sem nome de jogador); log: anel de 60 linhas, 1|t|nivel|texto
```

Texto compacto é só o formato de disco. A foto, que é imutável, é codificada uma vez, ao nascer; `dias`, `blocos`, `itens` e `calib` vivem em tabelas numéricas na memória e são codificados no `PLAYER_LOGOUT`, dentro de `ns.seguro`; os estimadores leem vetores, sem tabela nova por foto (R9 11.3).

### 6.2 Limites e tamanho

Os bytes por registro foram medidos gerando um banco no formato proposto, com chaves reais do cliente; os totais para 60 chaves com anel e quatro personagens são conta sobre essas medidas.

| Chave | Limite | Tamanho |
|---|---|---|
| `resumo` | 1 foto de cerca de 8 mil chaves (ordem de grandeza da base 2.6) × 17,3 bytes | 135 KB |
| `dias` | 1.500 chaves × 14 dias × 13,3 bytes | 305 KB |
| `blocos` | até 60 chaves × 126 blocos (21 dias) × 13 bytes | cerca de 100 KB |
| `fotos` | até 60 chaves com anel; fase 1: 16 fotos por chave; fase 2: 48; foto média medida de 385 bytes na fase 1 e de 360 na fase 2 (arquivo gerado com 40 chaves, levado a 60) | 370 KB; 1.050 KB |
| `giro`, `tri` (fase 2) | 60 chaves × 84 blocos; até 1.500 chaves | cerca de 90 KB |
| `sinais` | anel de 2.000 × 66 bytes | 157 KB |
| `pers` do negociador | anel de 2.000 ações × 123 bytes; 300 lotes; 300 faturas (25 KB) | 307 KB |
| `pers` de cada outro personagem | anel de 500 ações; 100 lotes; 100 faturas | cerca de 80 KB cada |
| `calib`, `sessoes`, `sonda`, `log`, `itens`, `npc` | 100 amostras por parâmetro (a frequência de venda e a sombra, até 200 por classe); 60 sessões; um registro por passo da sonda | cerca de 100 KB |

A coluna Tamanho é a medida no arquivo gerado, que inclui o custo de chave e de índice de cada entrada: por isso `dias` e `sinais` passam do produto simples da coluna Limite.

Total: cerca de 1,7 MB na fase 1 e 2,4 MB na fase 2, no estilo de gravação com comentário de índice (H-34). Cheia, a fase 2 encosta no gatilho de poda (80% de 3 MB): a poda passa a rodar o tempo todo, e é mais um motivo para o teto ou o anel serem decididos pela S1. Teto de 3 MB, que só sobe depois de a sonda medir o `/reload` com 1, 3 e 5 MB (H-19); se não subir, a fase 2 baixa o anel para 32 fotos por chave. O arquivo fica em cerca de 11 mil constantes, longe do limite de 262.143 por função da linguagem (o arquivo de SavedVariables é um bloco só); por segurança o banco não passa de 100 mil entradas de texto, e a S1 mede a carga com 5 MB no formato real. Memória em Lua: cerca de 2 MB. Comprimir com `C_EncodingUtil` reduziria o arquivo a menos da metade, mas tiraria do agente a leitura direta do banco e traria mais uma hipótese; fica como reserva para a parte fria. Os tamanhos por degrau da fase 3 estão na seção 17.1.

**O medidor.** Nenhuma API dá o tamanho do arquivo. O medidor soma, a cada inserção e remoção, o comprimento das strings mais 12 bytes por entrada; a S1 calibra o fator contra o arquivo real.

**O que entra e o que sai.**

- **Anéis de tamanho fixo.** Anel cheio sobrescreve o mais velho mesmo sem recibo e grava em `sobrescritos` o intervalo de `seq` coberto; o recibo só antecipa a poda. Acima de 80% do teto saem primeiro as fotos com `seq` até o `recibo`, depois as mais velhas.
- **Chaves com anel de fotos:** no máximo 60. Entra a chave de foco; sai a de foto mais velha sem lote aberto nem ordem de papel aberta.
- **Foto de item:** os 30 leilões mais baratos e o agregado do resto (seção 5.3).
- **`dias`:** as chaves tocadas (bolsas, leilões próprios, sinais), mais as de maior `minPrice × quantidade` do resumo, até 1.500. Cada chave guarda 14 dias; sai a chave que ficou 14 dias sem atualização.
- **Lotes abertos** ficam fora do anel, na tabela `abertos`, com teto de 300 no negociador e de 100 nos outros personagens, e o alerta `TOO MANY OPEN LOTS`. Lote aberto e ação sem conciliação nunca são podados.
- **`correio`** em anel de 300 no negociador e de 100 nos outros personagens; **`sonda`**, um registro por passo. O enchimento da S1 vai na chave `sonda.lastro`, fora da poda, e é apagado no `/reload` seguinte.

### 6.3 Gravação, queda e arquivo perdido

O banco só vai ao disco no `/reload`, no logout e ao fechar (base 3.9). A visão Session mostra `unsaved N actions, M min` e sugere salvar aos 45 minutos ou 50 ações.

- **Saída limpa.** No `PLAYER_LOGOUT` o addon codifica as tabelas, grava `pers[nome].fecho = { dinheiro, t, seq }` e só então `salvoEm` e `fim = seq`. Como `fim` só é gravado ali, `fim == seq` prova que a saída foi limpa; arquivo cortado no meio nem passa na análise.
- **Queda.** Na entrada, `GetMoney()` diferente de `fecho.dinheiro` indica fim sujo: com o personagem fora do jogo o dinheiro não muda, porque o ouro das vendas vem pelo correio (base 1.8). Nesse caso os contadores do dia de risco começam no teto (só venda) até a sessão do agente; G1 e G2 são refeitos pelos leilões próprios no primeiro fôlego; o custo de cada lote comprado vem da fatura "Auction won" e, sem fatura, o lote fica `cost unknown`, fora do `η_real`. As linhas reconstruídas ficam `unreconciled`. A reconstrução acontece no primeiro fôlego depois da abertura do leilão (`Press L to reconcile`), nunca no evento de abertura. O estado do jogo vale mais que o Livro.
- **Banco que não carregou.** Se `PregaoForeverDB` vier `nil` e `PregaoForeverCharDB.bancoDesde` existir, o arquivo de conta se perdeu ou não analisou (H-34). O addon não recria o banco, entra em `leitura` e mostra `DATABASE NOT LOADED - tell the agent`: recriar faria a saída seguinte gravar por cima do arquivo bom. A mesa arquiva cada cópia que lê (seção 12).
- **Banco novo.** `epoca` é gravada na criação. A mesa identifica cada registro por (`epoca`, `seq`); `epoca` nova abre série nova e o relatório avisa `NEW DATABASE SINCE <data>`. Sem isso, um banco recriado voltaria a `seq = 0` e a mesa descartaria como repetido todo registro novo.

## 7. Motor

### 7.1 Princípios

O motor propõe; quem autoriza é o Cofre. Como o R9 não passou por revisor (base 10), dele só decide o que tem modo de falha limitado. Leitura do cliente (corte, devolução, atraso, cadência) o addon adota sozinho quando a amostra fecha; ajuste estatístico a mesa troca dentro da faixa do Apêndice B; teto, margem, regra de preço e licença só mudam pelo `Config.lua`, com o sim do dono.

Do R9 entram na fase 1 a arbitragem contra o vendedor (5.4), o filtro de isca (1.2), a marca de escada rasa (1.5) e a fila na frente de um preço, como número cru lido da escada (3.1). Na fase 2 entram o teste de compra na escada pós-compra (5.1), com o desconto sobre o ganho; as vendas pela diferença de escadas (2.1), sempre junto com as regras de repostagem, expiração, teto de intervalo e censura (2.3, 2.4); e a calibração por série densa (2.9). A regra de cancelar (4.6) roda só em sombra, na forma por lote da seção 7.4. O valor de liquidação `W*` com tabela de probabilidade de venda (4.1), a sazonalidade, os perfis de concorrente e Kelly ficam fora das fases 1 e 2: pedem fotos densas, identidade de vendedor ou retorno bem estimado.

### 7.2 Venda do próprio estoque (fase 1)

Notação: preços em cobre; `v` é o preço de vendedor lido ao vivo; `c`, o corte; `d`, o depósito do lote lido da API; `n`, as unidades do lote; `du = d/n`; `rs`, `rx` e `rc`, a fração do depósito devolvida na venda, na expiração e no cancelamento.

**A frente.**

- **Commodity.** A frente é o primeiro degrau alheio depois do filtro de **isca**. O filtro só vale em escada com 20 unidades ou mais. A janela é `N_ref = limita(teto(0,15 · Q_tot), 5, 2.000)`, em unidades, enquanto não houver taxa de venda medida (R9 1.2). É isca a quantidade acumulada até `max(1, 0,05 · N_ref)`, olhando no máximo 3 degraus, quando logo depois vem um salto de 15% ou mais e de pelo menos 3 ticks. A condição em ticks existe porque em preço baixo o menor salto possível já passa de 15% (de 9 para 11 cobre são 22%). Degrau com `containsAccountItem` não serve de frente para a regra `cobrir`: seria cobrir outro personagem do dono.
- **Item.** Não há filtro de isca: a frente é o menor arremate alheio. A linha mostra o salto até o segundo preço (`next +50%`), para o dono julgar (H-38). Leilão próprio, de outro personagem da conta e leilão só de lance ficam fora da frente e de toda contagem.

**A referência.**

| Referência | Condição | O que o addon faz |
|---|---|---|
| **Forte** | Commodity: 5 unidades alheias ou mais, de 2 donos ou mais, na janela. Item: 5 arremates alheios ou mais na mesma chave, de 3 donos distintos ou mais (se `owners` vier vazio, H-13, vale só o 5). | Propõe os candidatos |
| **Fraca** | Só existem variantes do mesmo `itemID` (lidas pela `SendSellSearchQuery` do plano C) ou o último mínimo que o Auctionator viu (base 7.1); ou a referência forte difere mais de 3 vezes do mínimo do Auctionator (dado suspeito) | `WEAK REFERENCE`: mostra o mínimo e a mediana das variantes, o mínimo visto e a idade dele. Não propõe preço e a linha não tem tecla |
| **Nenhuma** | O resto | `NO REFERENCE`: mostra o preço de vendedor e o depósito por duração. Sem tecla |

Enquanto o preço de vendedor do item não carregou (dados de item são assíncronos, base 3.2), a linha diz `LOADING` e não tem tecla. A onda 2 mede que fração dos verdes das bolsas tem referência forte: verde de sufixo aleatório pode quase nunca ter 5 leilões da mesma chave, e essa é a única estratégia com fonte aprovada.

**Candidatos.** São as regras que têm fonte; a escolha é do dono, por classe de item, no `Config.lua` (DD3).

| Regra | Preço | Fonte |
|---|---|---|
| `igualar` | o da frente | O texto do próprio cliente: "There's no need to undercut! Auctions posted later (at the same price) are sold first." (strings, linha 1291); em equipamento, também o contorno do erro de postagem (base 1.11), e por isso é a única regra em equipamento |
| `cobrir` | a frente menos um tick | R8a ficha 2, F5 (guia de fã) |
| `folga` | a frente menos a folga do `Config.lua` | R8b R6 (guia de fã); a fonte não dá o tamanho da folga, que o dono escolhe junto com a regra |

O **tick**, o menor passo de preço, é 1 cobre se `SupportsCopperValues()` for verdadeiro, senão 1 prata (R1b 7). Nenhum candidato fica abaixo do piso de preço, `teto((v + (1−rs)·du)/(1−c))` arredondado para cima no tick (R8b R8; a forma com `rs` vale para qualquer devolução medida), nem acima de 3 vezes a referência. As fontes de fã se contradizem sobre cobrir (R8a F5 contra R8b R6 e R12), e o texto do cliente diz que não é preciso cobrir. A recomendação da DD3 é `igualar`, citando esse texto, com a S10 conferindo no Forever (H-14). Continua sendo decisão do dono: sem a escolha dele, a linha de commodity mostra `PICK RULE`, sem tecla.

**Fila na frente.** Para cada candidato a linha mostra quantas unidades alheias estão a preço menor e, no mesmo preço, as que o pior caso de ordem poria na frente (`340 cheaper ahead`). É leitura da escada, não modelo. Nada é proposto acima de uma parede (seção 9.3).

**Ponto de equilíbrio.** Para o candidato `p`, a duração `D` e a chance de venda `P` por unidade:

```
W1(p, D) = P · ( p·(1−c) − (1−rs)·du ) + (1−P) · ( v − (1−rx)·du )
P*       = (1−rx)·d / ( n·p·(1−c) − n·v + (rs−rx)·d )        por lote, em inteiros
```

`P*` é a chance de venda a partir da qual o leilão paga mais que vender ao NPC agora; é o mesmo ponto para qualquer número de repostagens. Casos-limite: denominador menor ou igual a zero, ou `P*` maior ou igual a 1, dão veredito `VENDOR`, sem número; depósito zero dá `pays even if it never sells`. A tela mostra o `P*` em palavras que o dono consegue julgar: `pays if 1 in N sells`, com `N = piso(1/P*)` (arredonda contra o leilão); com `P*` acima de 50%, `pays if NN% sell`. O addon não inventa chance de venda: ao lado aparece a frequência medida das vendas próprias (`you sold 4 of 10`), quando houver 10 desfechos.

**Classe e desfecho.** A frequência é contada por classe, duração e regra de preço. As classes são: commodity; equipamento por qualidade (comum, incomum, raro, épico). O desfecho é "vendeu" ou "expirou". Leilão cancelado pelo dono e leilão que atravessou uma manutenção (`downtime`) saem do numerador e do denominador. Commodity conta por unidade; a devolução do depósito em venda parcial é medida na S6 (H-33).

**Veredito.** `VENDOR` quando nenhum candidato fica acima do piso de preço ou o `P*` não tem solução. `AUCTION` quando o limite inferior do intervalo de Wilson de 80% da frequência supera o `P*` (com 4 vendas em 10, o intervalo vai de 23% a 60%). Senão `YOUR CALL`: `no sales yet: your call` sem desfechos, ou a contagem quando a frequência está perto do `P*`. Em verde, a fonte aprovada já diz leilão (base 4.5), e o `P*` serve para o dono pesar o depósito.

**Duração e lote.** A duração por classe é escolha do dono (R8b R15 é a fonte que existe); a linha mostra o `P*` das três. O tamanho do lote de commodity também é campo do `Config.lua` por classe: pilha inteira, tamanho de receita (R8b R14) ou quantidade fixa. As três escolhas (regra, duração e lote) entram na DD3, e sem elas a linha fica em `PICK RULE`. Commodity posta o lote numa chamada; item posta 1 unidade por tecla, sempre com quantidade 1, lance `nil` e só arremate (H-15).

### 7.3 Piso do vendedor

Sobre a escada fresca, comprar os degraus enquanto `p_j <= v − 1 tick`:

```
EV     = soma( (v − p_j) · q_j ) − custo_ida        sem corte, sem deposito
teclas = 3 por compra (rele, cota, confirma), ou 2 com foto fresca, + 1 clique de venda por pilha no NPC
aceita se  EV / teclas >= tiquete  e  Cofre.autoriza
teto da cotacao = min( n · (v − 1 tick) , n · v − teclas · tiquete )
```

O teto é o do motor, não os 5% que a tela da Blizzard tolera (base 2.7): aqui qualquer alta come o lucro, e acima do teto a confirmação é recusada. O segundo termo do `min` impede que uma cotação dentro do teto deixe a compra abaixo do tíquete. `custo_ida` é um custo fixo por ida ao vendedor, do `Config.lua`, zero de partida e medido pelo tempo por ação (seção 7.6). A releitura entra na conta porque o ciclo de foco dura mais que os 30 s de validade da foto (seção 5.2).

Em commodity a compra leva as unidades mais baratas sem escolher leilão (base 2.7): se algum degrau dentro da profundidade da compra tiver `containsAccountItem`, não há sinal nem cotação, e a releitura antes da tecla `B` confere de novo (H-32). Sem isso o addon poderia comprar do próprio dono.

A primeira compra de cada item é o **lote de confirmação**: 1 unidade ou 1 pilha, o que for menor, até 2% da banca. O dono vende ao NPC com o próprio clique e o addon confere se o recebido bate com o lido (H-21): cada venda ao NPC casa a saída do item da bolsa (`BAG_UPDATE`) com o `PLAYER_MONEY` seguinte; variação sem item do Livro saindo (lixo vendido ou conserto feito por outro addon ao abrir o vendedor) é `outside` e não entra na conferência. Só então o item aceita lote maior.

### 7.4 Compra para revenda (fase 2, em papel primeiro)

```
U_lcb = max( saida conservadora por unidade na escada que sobra depois da compra , v )
EV    = η_real · ( n · U_lcb − Custo ) − teclas · tiquete
comprar se  EV >= μ_min · Custo  e  Cofre.autoriza  e  foto com ate 30 s
```

O desconto `η_real` incide sobre o ganho, não sobre a saída inteira: multiplicar a saída por 0,5 só deixaria passar compra com saída maior que 2,3 vezes o custo. `η_real` vale 1,0 no `piso` e 0,5 no resto, até o Livro medir (seção 3.3). `teclas` é 5 de partida numa compra para revenda: três da compra e duas da postagem. Depois de 30 lotes medidos, o teste passa a usar o desvio da saída, que não depende da margem do sinal: `n · U_lcb · (1−δ) − Custo − teclas · tiquete >= μ_min · Custo` (com `δ = 0,115` o limiar é o de hoje). Os limiares do `vao` e do `sniper` na seção 3.2 saem desta conta; a saída do `vao` é a saída conservadora, não o degrau seguinte menos um tick.

- **Saída conservadora**: o menor entre a mediana dos mínimos diários (campo `dias`, com 5 dias ou mais) e o preço robusto da última foto (ideias públicas, base 5.8), líquido de corte e de um depósito. O depósito é lido para commodity e para item na bolsa; para item fora da bolsa vale a estimativa da regra 17, com a marca `est.`. Com menos de 5 dias em `dias` não há saída conservadora e o sinal fica em papel.
- **Preço robusto** (R9 1.3): média aparada, em logaritmo e ponderada por unidade, das `N_ef` unidades mais baratas depois da isca, descartando 20% de cada ponta (`α_ap`). `N_ef = min(N_ref, unidades depois da isca)`. Com `N_ef = 0` ou peso zero o estimador devolve "sem preço", nunca uma divisão de zero por zero; a bancada tem os casos de 1, 2 e 5 unidades.
- **Classe da saída**: A, o vendedor paga mais que o custo; B, houve venda inferida no preço de saída ou acima em três pares válidos de fotos (seção 3.3), em pelo menos 2 dias distintos; C, o resto. Classe C nunca é executável: aparece como `UNPROVEN`, só em papel.
- **Sobrevivência**: a fração de sinais ainda presentes na releitura da tecla `B`, em três faixas de desconto (até 10%, de 10% a 30%, acima de 30%), gravada também pelo tempo entre a foto e a tecla. Em papel o sinal sempre aparece. Em micro, a faixa só gera sinal executável com 15 releituras ou mais e sobrevivência acima de 0,5. São duas réguas, uma dentro da outra: o portão que tira o `sniper` do papel olha a estratégia inteira (até 70% de "já sumiu" nos 30 sinais, seção 3.2), e o limiar de 0,5 vale depois, faixa por faixa, para decidir quais geram sinal executável. Uma estratégia pode passar no portão e ter uma única faixa executável. Fotos a minutos de distância não medem vida de oferta de segundos; a releitura mede.
- **Guarda de regime**: se depois da compra ainda sobra, abaixo do preço de entrada, mais que 3 vezes o lote, a oferta é preço novo e não pechincha (R9 5.2): compra-se só o lote de confirmação.
- **Conta própria**: a regra de `containsAccountItem` da seção 7.3 vale igual.
- **Deriva**: `deriva_dia` é a mediana, por classe de item, de `ln(min_b/min_a)/(t_b − t_a)`, com o tempo em dias, sobre pares de leituras da mesma chave separadas por 6 a 48 horas: o mesmo bloco de 4 horas em dois dias seguidos (campo `blocos`) e, para as chaves sem anel, dois dias seguidos de `dias`. Exige 30 chaves ou mais na classe; sem isso a deriva é desconhecida e não suspende nada. Ela só suspende compra (seção 9.3) e não entra no `EV`: é alarme grosso, sujeito a efeito de hora. A fórmula de custo de carregar, `U_lcb · (1 − exp(min(0, deriva_dia) · T_caixa))`, fica registrada para a fase 3.
- **Volume**: a compra diária de um item fica em até 10% das vendas inferidas na exposição observada do dia; sem 2 horas de exposição, só o lote de confirmação (seção 9.2).

**Cancelar.** Nas fases 1 e 2 o addon não calcula nem mostra ganho de cancelar. A visão Mine mostra fatos lidos (quantas unidades mais baratas na frente, tempo restante, depósito em risco) e a palavra `STAND DOWN` quando a regra antiguerra vale (seção 9.3). A regra de cancelar roda em sombra, por lote, só com o que se mede:

```
Δ = W1_lote(p', D', f_novo) + rc·d
    − [ f_fica · ( n·p·(1−c) + rs·d ) + (1−f_fica) · ( n·v + rx·d ) ]
    − tiquete · acoes

W1_lote(p', D', f) = f · ( n·p'·(1−c) − (1−rs)·d' ) + (1−f) · ( n·v − (1−rx)·d' )
```

`f_fica` e `f_novo` são as frequências próprias de venda por faixa de fila na frente (na frente; fila até o tamanho do próprio lote; fila maior), para a posição atual e para a posição depois de repostar; `d'` é o depósito da repostagem; `acoes` são as teclas do ciclo (cancelar, repostar e a ida ao correio, se a H-10 valer). Não há termo de tempo: o custo de capital não é parâmetro deste design. Sem as duas frequências a sombra não grava valor. Virar conselho na tela é decisão do dono, com fonte (DD3).

### 7.5 Ordem da fila e custo da atenção

Entram as linhas que passam no **tíquete**, o valor mínimo por tecla (15 cobre de partida, DD10). O valor por tecla conta todas as teclas do verbo, inclusive a releitura quando a foto já passou da idade máxima.

1. Postagens primeiro, por valor por tecla, porque liberam capital.
2. Depois as compras: por `EV / Custo` enquanto o gargalo medido for capital (banca livre média abaixo de 20% da banca, seção 17.1), e por valor por tecla quando não for. `T_caixa`, o tempo até o dinheiro voltar, é o atraso medido do correio; enquanto for uma constante igual para todo item ele não entra na ordem.
3. Cancelamentos não entram na fila nas fases 1 e 2: o dono os decide na visão Mine, pelos fatos.
4. Linhas sem tecla (`VENDOR`, `PICK RULE`) entram no fim da fila, depois das executáveis, como lembrete do que está parado nas bolsas. Não passam pelo tíquete e contam no número do título.

Linha pulada com `K` sai da fila até o fim da sessão (seção 11.2). Cada linha carrega um `motivo` (`NEW`, `RESTOCK`, `AGED`), que as telas da fase 3 usam. A lista só reordena no `L` ou na troca de visão (seção 8.2). Depois de 3 a 5 sessões, o agente propõe trocar o tíquete pelo lucro por hora realizado vezes o tempo medido por ação.

### 7.6 Diário de calibração

Padrão do projeto (base 4.9): o addon grava o sinal cru e o número medido substitui a estimativa. Cada amostra leva o `GetBuildInfo()` do momento. **Um parâmetro medido deixa de valer** quando a leitura nova diverge do adotado além da tolerância (10%, ou 1 cobre em valor pequeno) em 2 amostras seguidas, ou quando o build gravado muda: ele volta ao valor de partida, a faixa diz `GAME NUMBER CHANGED` e as licenças que dependem dele caem para papel até nova medida. Hotfix de servidor muda regra sem mudar o cliente, como o depósito de 17/11.

| Parâmetro | Partida | Sinal gravado | Vira medido com |
|---|---|---|---|
| Corte `c` | 0,05 (base 1.4, inferência) | `consignment / bid`, na fatura | 3 faturas |
| Depósito | nenhuma: sempre lido | valor lido nas três durações; variação do dinheiro ao postar; razão entre depósito e preço de vendedor, por duração (serve à regra 17) | 5 itens |
| Devolução `rs`, `rx`, `rc` | 1, 0 e 0 (o cliente afirma a venda e o cancelamento, seção 2.1; a expiração é regra do Classic); no Cofre todo depósito conta como em risco | fatura e dinheiro em cada desfecho; venda parcial de lote (H-33) | 1 de cada |
| Atraso do correio | 60 min (base 1.8) | `etaHour` e `etaMin` da carta de venda pendente; `timeLeftSeconds` do leilão vendido na primeira leitura depois do aviso, mais o tempo decorrido (H-27); a hora da fatura fica como limite superior, porque o addon só a vê quando o dono abre a caixa | 5 vendas |
| Entrega de compra e de cancelamento | pelo correio (H-10) | evento de atraso e chegada real | 3 de cada |
| Cadência e custo do fôlego | 30 buscas por minuto | carimbos dos eventos de throttle | 5 fôlegos |
| Frequência de venda | nenhuma | preço, regra, fila na frente, duração e desfecho de cada postagem; cancelado e `downtime` ficam censurados | 10 por classe, duração e regra |
| "Já sumiu" e sobrevivência | nenhuma | sinais que sumiram entre a foto e a tecla, por faixa de desconto e pelo tempo entre a foto e a tecla | 30 sinais; 15 releituras por faixa |
| `η_real` e `δ` | 1,0 no `piso`; 0,5 no resto | previsto e realizado por lote, razão de somas, abertos marcados | 30 lotes |
| Subcontagem da venda inferida | nenhuma | série densa da S11, subamostrada na cadência real do dono | 1 série de 30 min em 5 chaves |
| Ordem entre preços iguais | o mais novo primeiro (texto do cliente); pior caso na conta de fila | quantidade própria contra a do degrau em fotos seguidas | 5 observações concordantes |
| Tempo por ação | nenhuma; o tíquete parte de 15 cobre | segundos entre a seleção da linha e a tecla, e entre a tecla e o eco; mediana, com teto de 60 s por amostra | 3 sessões |
| Latência do acesso remoto | 150 ms | o jogo não a enxerga: o dono lê o número no overlay da ferramenta de acesso remoto (R10a 1.1) e o agente grava em `Config.remoto.latencia_ms` | 1 leitura por sessão longa |

As leituras do jogo desta tabela (corte, devoluções, atraso do correio, cadência) o addon adota sozinho, em `calib`, e elas não passam pelo `Calibrado.lua`. Cada uma tem uma faixa de sanidade, proposta do projeto: corte de 0 a 0,25; devolução de 0 a 1; atraso do correio de 0 a 180 minutos; cadência de 5 a 100 buscas por minuto. Leitura fora da faixa não é adotada: fica como amostra, e a faixa `GAME NUMBER CHANGED` aparece.

## 8. Execução

### 8.1 Invariantes

São o contrato de `Acoes.lua`, `Ecos.lua`, `Pedidos.lua` e `Cofre.lua`; o checador e a bancada conferem cada um (seção 16).

| # | Invariante |
|---|---|
| I1 | Uma tecla aceita gera no máximo uma chamada de função de ação. |
| I2 | Função de ação só é chamada de dentro do `OnClick` de um botão do addon, em `Acoes.lua`. |
| I3 | Toda chamada vem depois de `Cofre.autoriza` no mesmo clique e entra no Livro antes (intenção) e depois (eco). |
| I4 | Nenhuma ordem passa dos tetos de `Tetos.lua`. |
| I5 | Ação sem eco vira INCERTO e bloqueia. Nunca há reenvio. A exceção é a cotação (`StartCommoditiesPurchase`), que não gasta: sem resposta em 5 s o addon cancela a cotação e volta ao sinal (`PRICE MOVED`), e outra cotação só sai com outra tecla. |
| I6 | Foto sem a frente completa, vencida ou vazia suspeita não atualiza estimador nem gera sinal. |
| I7 | O nível concedido de uma estratégia (licença e evidência) só desce dentro do jogo. A suspensão por disjuntor é à parte e, ao destravar, devolve no máximo o nível concedido. |
| I8 | Nenhuma tecla age sobre o que o dono não teve tempo de ver: a linha ou o bilhete precisa estar na tela, sem mudar, há pelo menos `T_ver`, contado da última mudança de seleção e de conteúdo. A posição do cursor nunca muda sozinha; linha nova sob o cursor reinicia `T_ver`; mudança de bolsa (`BAG_UPDATE_DELAYED`) reinicia `T_ver` nas linhas de venda. |
| I9 | Nenhuma consulta sai sem uma tecla do dono há no máximo `T_pulso`, nem fora de um fôlego aberto por tecla. Nenhum evento ou timer abre fôlego. |

### 8.2 O caminho da tecla

Cada verbo tem um botão do addon (`PregaoForeverBotaoComprar`, `...Postar`, `...Cancelar`, `...Sim`, `...Desiste`, `...Pular` e os de navegação) e uma tecla ligada a ele enquanto a janela está aberta (base 3.4, 8.1). O clique do mouse no mesmo botão percorre o mesmo código. A tecla do dono é o evento de hardware (H-01).

**Como o botão e o binding são feitos** (assinaturas pelo uso da Blizzard, R10b 1.1):

- `SetOverrideBindingClick(janela, true, tecla, nomeDoBotao, "LeftButton")`: dono dos bindings, prioridade, tecla, botão e botão do mouse.
- O botão registra só a soltura, uma vez, na criação e fora de combate: `RegisterForClicks("LeftButtonUp")`. O `OnClick` recebe `(self, botao, down)` e ignora `down` verdadeiro. Registrar as duas fases geraria dois `OnClick` por tecla e feriria a I1. A CVar `ActionButtonUseKeyDown` só vale para botão seguro de ação e não muda nada aqui.
- Soltar é sempre explícito: `ClearOverrideBindings(janela)` ao fechar. O binding não cai sozinho quando a janela some.
- Ligar e soltar só com `InCombatLockdown()` falso (regra 16). Se o leilão abre ou fecha em combate, a operação fica pendente e roda em `PLAYER_REGEN_ENABLED`. Como a soltura pode atrasar, todo `OnClick` começa conferindo que a janela e o leilão estão abertos; fora disso é inerte.

Dentro do `OnClick`, nesta ordem: guardas, `Cofre.autoriza`, `Livro.intencao`, uma função de ação, estado `ENVIANDO` (`COTANDO` ou `CONFIRMANDO`, nas máquinas de commodity). Tudo na mesma pilha (regra 3).

**Uma tecla faz uma coisa só** (seção 11.2). `P`, `B` e `C` preparam; `Y` executa o bilhete que está na tela; `M` desiste. Até a S0 e a DD5, `P` só arma e `Y` executa, como `C`; depois da DD5, se o dono aprovar, `P` posta num tempo só.

Guardas de dedo, pensadas para o acesso remoto:

- **Vê e assina**: `T_ver` de 1 segundo mais a latência de `Config.remoto.latencia_ms`. A contagem reinicia a cada mudança de seleção e a cada mudança de conteúdo da linha ou do bilhete; linha que mudou mostra `UPDATED`.
- **Repetição**: a mesma tecla de ação em menos de 400 ms é ignorada. A janela conta da última pressão recebida, aceita ou não, e se renova a cada repetição: tecla presa nunca passa. Tecla com máquina ocupada é descartada, nunca enfileirada (H-02).
- **Rajada**: 6 teclas de ação recebidas em 2 segundos, aceitas ou não, soltam os bindings de ação e pedem `H` para rearmar.
- **Cursor depois de uma ação**: a posição do cursor não muda. A linha concluída sai, a seguinte sobe para a posição do cursor com a marca `NEXT` e `T_ver` recomeça: uma tecla por lote, e nunca sem a espera. Subir de posição sem mudar de conteúdo, em outra linha da lista, não conta como "mudou". A lista só reordena no `L` ou na troca de visão. Resultado esperado do cenário de tecla presa: exatamente uma ação.
- **Troca de visão** desarma o bilhete, com `CancelCommoditiesPurchase` se havia cotação.
- **Salvar** (o `Y` da visão Session) só vale com todas as máquinas em repouso, sem INCERTO pendente e com o fôlego fechado; senão a tela diz `SAVE BLOCKED - finish or cancel first`.
- **Throttle não pronto** numa postagem consome a tecla sem agir; quando o sistema fica pronto, o addon não dispara sozinho.
- **Validade**: bilhete armado expira em 20 s; a confirmação de commodity desliga com menos de 5 s de cotação.
- **Tela da Blizzard**: o addon não cota nem confirma com o diálogo de compra da Blizzard visível (`AuctionHouseFrame.BuyDialog`): a cotação é estado único do cliente e o diálogo a cancela ao fechar. A faixa diz `Close the Blizzard buy window`.

### 8.3 Máquinas de ação

Os nomes de evento estão por extenso: são os literais do cliente (R1a 4).

**Comprar commodity** (duas teclas: cotar e confirmar; base 2.7).

```
SINAL --[TECLA B], foto com mais de 30 s--> releitura -> SINAL ("REFRESHED")
SINAL --[TECLA B], foto fresca, nenhum degrau da conta na profundidade, Cofre autoriza-->
        COTANDO: StartCommoditiesPurchase(itemID, n, unitario)
COTANDO --COMMODITY_PRICE_UPDATED(unitario, total), total <= teto--> COTADO
        (bilhete: total, teto, validade lida de GetQuoteDurationRemaining)
COTANDO --total > teto, COMMODITY_PRICE_UNAVAILABLE ou 5 s--> CancelCommoditiesPurchase -> SINAL ("PRICE MOVED")
COTADO --COMMODITY_PRICE_UPDATED de novo, total <= teto--> COTADO ("UPDATED"; T_ver reinicia)
COTADO --COMMODITY_PRICE_UPDATED de novo, total > teto--> CancelCommoditiesPurchase -> SINAL ("PRICE MOVED")
COTADO --COMMODITY_PRICE_UNAVAILABLE--> CancelCommoditiesPurchase -> SINAL ("PRICE MOVED")
COTADO --[TECLA Y], depois de T_ver, cotacao com 5 s ou mais--> CONFIRMANDO: ConfirmCommoditiesPurchase(itemID, n)
COTADO --[TECLA M], troca de visao, cotacao vencida ou AUCTION_HOUSE_CLOSED--> CancelCommoditiesPurchase -> SINAL
CONFIRMANDO --COMMODITY_PURCHASE_SUCCEEDED--> CancelCommoditiesPurchase -> FEITO
CONFIRMANDO --COMMODITY_PURCHASE_FAILED--> CancelCommoditiesPurchase -> FALHOU (sem gasto) -> SINAL
CONFIRMANDO --prazo do eco ou AUCTION_HOUSE_CLOSED--> INCERTO (a cotacao nao e cancelada)
COTANDO, CONFIRMANDO --AUCTION_HOUSE_SHOW_ERROR(codigo)--> conforme a tabela de codigos
```

- A primeira forma de `StartCommoditiesPurchase` é a da tela da Blizzard, com três argumentos, o unitário da escada arredondado pelo tick (H-17). A função falha em silêncio: um teste de dois argumentos sem resposta não distinguiria "faltou o terceiro" de "a tecla não vale".
- `CancelCommoditiesPurchase` é chamada em toda saída de COTANDO, COTADO e CONFIRMANDO, inclusive depois do sucesso, como a Blizzard faz em todo fechamento do diálogo (espelho, `Blizzard_AuctionHouseBuyDialog.lua:108 a 119`); só não durante INCERTO. Cotação esquecida trava o leilão de quem vende: o cliente tem o erro `ItemHasQuote`, "This auction can't be canceled because a transaction is pending" (strings, linha 7836). A função não leva a marca de restrição e a própria Blizzard a chama de evento e de temporizador (base 2.12; R1b 14): por isso sai sem tecla.
- A validade só é lida depois de a cotação chegar. Os eventos de cotação não trazem o item: valem para a única cotação aberta, a do addon, e por isso a guarda do diálogo da Blizzard (seção 8.2).
- O custo da compra é a variação do dinheiro (supõe débito na confirmação, H-32). `COMMODITY_PURCHASED(itemID, quantity)`, se chegar, confere item e quantidade.
- A confirmação nunca sai sem tecla, mesmo que a API permita (base 2.13): seria o addon gastando sozinho.

**Comprar item** (duas teclas: armar e executar; base 2.8). É o ritmo da tela da Blizzard, que só chama `PlaceBid` no aceite de um popup (R1b 14).

```
SINAL --[TECLA B]--> RELENDO (so consulta: confere auctionID e arremate)
RELENDO --mesmo leilao e preco, Cofre autoriza--> ARMADO (bilhete)
RELENDO --sumiu ou mudou--> SINAL ("GONE")
ARMADO --[TECLA Y], depois de T_ver--> ENVIANDO: PlaceBid(auctionID, arremate)
ARMADO --[TECLA M], troca de visao, 20 s ou AUCTION_HOUSE_CLOSED--> SINAL
ENVIANDO --AUCTION_HOUSE_PURCHASE_COMPLETED(auctionID)--> FEITO
ENVIANDO --AUCTION_HOUSE_SHOW_ERROR(codigo)--> conforme a tabela de codigos
ENVIANDO --prazo do eco ou AUCTION_HOUSE_CLOSED--> INCERTO
```

**Postar** (base 2.9). Até a DD5, duas teclas: `P` arma e `Y` posta. Depois dela, se o dono aprovar, `P` posta direto.

```
ITEM --[TECLA P], foto da chave com mais de A_post--> releitura -> ITEM ("REFRESHED")
ITEM --[TECLA P], foto valida--> pre-checagens -> ARMADO (bilhete: preco, duracao, deposito, idade da foto)
ARMADO --[TECLA Y], depois de T_ver--> pre-checagens de novo ->
        ENVIANDO: PostCommodity(item, duracao, n, unitario) ou PostItem(item, duracao, 1, nil, arremate)
ARMADO --[TECLA M], troca de visao, 20 s ou AUCTION_HOUSE_CLOSED--> ITEM
ITEM --[TECLA P], so depois da DD5: foto valida, linha ha T_ver na tela--> pre-checagens -> ENVIANDO
ENVIANDO --needsConfirmation falso e AUCTION_HOUSE_AUCTION_CREATED(id)--> FEITO
ENVIANDO --needsConfirmation verdadeiro e AUCTION_HOUSE_POST_WARNING--> AVISO
AVISO --[TECLA Y], depois de T_ver--> ConfirmPostCommodity ou ConfirmPostItem -> ENVIANDO
AVISO --[TECLA M], 20 s ou AUCTION_HOUSE_CLOSED--> ABORTADO (nada e chamado; H-16)
ENVIANDO --AUCTION_HOUSE_POST_ERROR--> ITEM ("POSTING CLOSED"; nao e falha nem INCERTO)
ENVIANDO --AUCTION_MULTISELL_START--> INCERTO (inesperado: a quantidade e sempre 1)
ENVIANDO --AUCTION_HOUSE_SHOW_ERROR(codigo)--> conforme a tabela de codigos
ENVIANDO --prazo do eco ou AUCTION_HOUSE_CLOSED--> INCERTO
```

Pré-checagens, todas no clique:

1. `IsSellItemValid(item, false)`: o segundo argumento falso evita que o jogo mostre erro na tela (R1a função 63).
2. `GetItemCommodityStatus(item)` decide o caminho; `Unknown` bloqueia com `Item data not loaded`.
3. `itemID`, link e quantidade lidos do `ItemLocation` no clique são iguais aos da linha. Se a bolsa mudou entre a linha e a tecla (saque, arrumação por outro addon), a tecla só refaz a linha e mostra `BAG CHANGED`: sem isso se postaria outro item pelo preço calculado para o primeiro.
4. Depósito lido e coberto pelo dinheiro; função de depósito que devolve nada bloqueia (`Deposit unknown`).
5. `IsThrottledMessageSystemReady()`.
6. Foto da chave com até `A_post` (5 minutos de partida, faixa até 10) e preço ainda dentro da faixa da seção 9.2. A linha mostra a idade (`price from 3m ago`). Comprar continua em 30 s.
7. `Cofre.autoriza`.

O que o aviso é: o texto do cliente diz que há uma manutenção semanal com atualização do leilão, que o item pode voltar antes e que o depósito se perde (strings, linha 4861). No estado AVISO a tela mostra `MAINTENANCE: may return early, deposit lost`, a conta trata o depósito como perdido e o padrão é não confirmar (`M`, ou os 20 s). `AUCTION_HOUSE_POST_ERROR` é o leilão fechado para postagem antes da atualização (strings, linha 1305). O popup da própria Blizzard abre junto nos dois casos, porque o `AuctionHouseFrame` ouve esses eventos desde a carga (espelho, `Blizzard_AuctionHouseFrame.lua:370 a 372`); o Aceitar dele não confirma a postagem do addon, e ele não rouba o teclado.

**Cancelar** (sempre duas teclas: `C` arma, `Y` executa; base 2.10). Cancelar perde o depósito (strings, linha 3390), e a tela da Blizzard também sempre confirma.

```
LEILAO --[TECLA C], CanCancelAuction, teto antiguerra livre-->
        ARMADO (bilhete: deposito que se perde, custo de GetCancelCost, unidades mais baratas na frente)
ARMADO --[TECLA Y], depois de T_ver--> ENVIANDO: CancelAuction(id)
ARMADO --[TECLA M], troca de visao, 20 s ou AUCTION_HOUSE_CLOSED--> LEILAO
ENVIANDO --AUCTION_CANCELED(id)--> FEITO
ENVIANDO --AUCTION_HOUSE_SHOW_ERROR(ItemHasQuote)--> LEILAO ("KEEP - buyer pending"), sem nova tentativa
ENVIANDO --AUCTION_HOUSE_SHOW_ERROR(outro codigo)--> conforme a tabela de codigos
ENVIANDO --prazo do eco ou AUCTION_HOUSE_CLOSED--> INCERTO
```

Cancelar usa a foto do próprio leilão no último fôlego. Repostar não é uma ação: é cancelar, receber o item de volta (bolsa ou correio, H-10) e postar, cada passo com as suas teclas.

**INCERTO.** As funções de ação falham em silêncio (base 2.12), a cadência do throttle é desconhecida (base 2.14) e a própria Blizzard mostra um aguarde depois de 2 s (R1b 4). Por isso prazo estourado nunca vira "falhou, aperte de novo". O estado bloqueia toda ação nova enquanto concilia: `QueryOwnedAuctions`, dinheiro e bolsas decidem entre `FEITO (eco perdido)` e `NAO EXECUTADA`. A conciliação usa as até duas consultas do fôlego curto que a própria tecla da ação abriu (seção 5.2); se não decidir, o item fica bloqueado até aparecer evidência, e as outras linhas voltam. A evidência vem de dois lugares: no leilão, do fôlego seguinte, que só uma tecla abre (a faixa `Press L to reconcile` só existe com o leilão aberto); no correio, da leitura que o painel já faz quando o dono abre a caixa (a carta com o item, o ouro ou a fatura), sem tecla e sem consulta ao leilão. Três INCERTO na sessão ligam o disjuntor de ação muda.

**Código de erro, reação.** `AUCTION_HOUSE_SHOW_ERROR` só traz o código, sem o leilão (R1a evento; o enum `AuctionHouseError` tem 27 valores). Com uma ação em voo, o erro é atribuído a ela, como a Blizzard faz; como a tela da Blizzard aberta ao lado pode causar um erro alheio, toda FALHOU é seguida da conciliação curta. Erro que chega sem ação em voo só é registrado, com origem `outside`. O código vai gravado em toda FALHOU.

| Grupo | Códigos | Reação |
|---|---|---|
| Dinheiro | `NotEnoughMoney` | FALHOU (`NOT ENOUGH GOLD`); relê `GetMoney`, recalcula a banca e concilia |
| Não se sabe se executou | `IsBusy`, `Unavailable`, `DatabaseError` | INCERTO. Exceção: `DatabaseError` ao postar equipamento é o "Internal auction error" da base 1.11: FALHOU com `MATCH THE LOWEST PRICE`, e a linha é refeita (H-29) |
| Transação pendente | `ItemHasQuote` | Em Cancelar: `KEEP - buyer pending`, sem nova tentativa. Nas outras máquinas: `CancelCommoditiesPurchase` e FALHOU |
| Já sumiu | `ItemNotFound`, `ItemNotAvailable` | FALHOU (`GONE`), contado na taxa de "já sumiu" (base 1.11; o sentido de `ItemNotAvailable` é inferência pelo nome) |
| Restrição de conta | `HasRestriction`, `RestrictedAccountTrial` | Disjuntor de restrição de conta (seção 9.4): tudo para |
| Lance | `HigherBid`, `BidIncrement`, `BidOwn`, `MinBid`, `DoubleBid` | FALHOU com o texto. O addon não dá lance; só chegam por ação de outra tela ou por leilão que mudou |
| Item que não pode ser postado | `NotEnoughItems`, `RepairItem`, `UsedCharges`, `QuestItem`, `BoundItem`, `ConjuredItem`, `LimitedDurationItem`, `IsBag`, `EquippedBag`, `WrappedItem`, `LootItem`, `ItemBoundToAccountUntilEquip` | FALHOU com o texto; o item sai da lista de venda até a bolsa mudar |
| Favoritos | `FavoritesMaxed` | Só registrado: o addon não usa favoritos |

**Estado, palavra de tela.**

| Estado | Palavra |
|---|---|
| PARADO; PARADO depois de abrir o leilão; vigília parada | `Press L`; `Press L to reconcile`; `PAUSED - press L` |
| TRAVADO | `API STALLED - close and reopen the auction house` |
| RELENDO; releitura feita | `CHECKING`; `REFRESHED` |
| COTANDO; COTADO | `QUOTING`; `QUOTE OK` |
| ARMADO | `READY` (o botão do bilhete diz a tecla: `[Y] POST NOW`) |
| AVISO; ABORTADO | `GAME ASKS TO CONFIRM`; `NOT POSTED` |
| ENVIANDO, CONFIRMANDO | `SENT` |
| FEITO | `BOUGHT`, `POSTED` ou `CANCELLED` |
| FALHOU | `FAILED` com o motivo, ou a palavra própria (`GONE`, `NOT ENOUGH GOLD`, `MATCH THE LOWEST PRICE`) |
| Volta sem falha (não conta como FALHOU nem como INCERTO) | `PRICE MOVED`; `POSTING CLOSED`; `KEEP - buyer pending`; e `GONE` quando vem da releitura, sem ação enviada (conta na taxa de "já sumiu") |
| INCERTO | `UNKNOWN - checking` |
| Linha que mudou; linha que subiu; bolsa mudou | `UPDATED`; `NEXT`; `BAG CHANGED` |
| Em modo papel | `PAPER - nothing posted`; `PAPER - no gold moved` |

## 9. Risco e carteira

### 9.1 A banca

- Cada personagem do dono tem o seu Cofre (`pers[nome].cofre`). A **banca** `B` é a do personagem logado: `GetMoney()` menos o **piso pessoal** dele no `Config.lua` (ouro que o addon trata como inexistente), mais o ouro de vendas já confirmadas a caminho do correio, mais os depósitos pagos em leilões ativos (que voltam na venda e contam como em risco), mais o estoque comprado, marcado a valor de saída conservador e nunca a custo (R9 7.1). Ela é relida a cada abertura do leilão.
- **Postar e cancelar valem em qualquer personagem logado**, com os tetos de depósito calculados sobre o ouro dele. É o que permite vender o que os quatro personagens produzem (base 4.2). **Comprar só no negociador** (`Config.negociador`).
- O ouro dos outros personagens e o do banco da guilda nunca entram na banca: não há banco de conta (base 4.1, 4.2). Reunir ou não o ouro no negociador é decisão do dono (DD4), feita pelo correio do jogo, com o clique dele; o addon não envia nada. A visão Sell mostra a linha `ON OTHER CHARACTERS` com o que o Syndicator diz estar nos outros (seção 14).
- O piso pessoal recomendado é de 1 ouro no negociador e zero nos outros. Ele deixa parado cerca de um quinto do capital de hoje; zero é opção (DD4).
- **Banca zero ou negativa:** a venda segue, dentro do piso absoluto dos tetos de depósito (seção 9.2); a compra para.
- Estados do ouro: livre; em estoque comprado; em depósito em risco; em correio. A soma deles é a banca, e o cabeçalho das telas fecha essa soma. O ouro de uma cotação aberta continua contado como livre, porque a cotação não debita (H-32), mas fica reservado: o Cofre não autoriza outra ordem com ele enquanto a cotação estiver aberta.
- Lotes saem por ordem de entrada. Item da lista `reservas` (DD14) nunca vira linha de venda: aparece em `KEPT`, com o motivo.

Toda conta de exemplo deste texto usa a banca do negociador com o ouro reunido: cerca de 4 ouro (40.000 cobre).

### 9.2 Tetos

Constantes de `Tetos.lua`, em fração de `B`. O `Config.lua` pode baixar cada um, nunca subir. Todos os números desta seção são proposta do projeto, sem fonte de economia: o dono aprova, troca ou manda buscar fonte (DD10).

| Teto | Duro | De partida | Com `B` = 4 ouro |
|---|---|---|---|
| Lote de confirmação (primeira compra de um item): 1 unidade ou 1 pilha, até | 2% | 2% | 8 prata |
| Custo por ordem em micro | 10% | 5% | 20 prata (duro: 40) |
| Custo acumulado por item | 20% | 10% | 40 prata (duro: 80) |
| Estoque com risco de preço, total | 50% | 50% | 2 ouro |
| Depósito em risco ao mesmo tempo | o maior entre 5% e o piso absoluto | igual | 20 prata |
| Depósito perdido no dia de risco | o maior entre 2% e o piso absoluto do dia | igual | 8 prata |
| Perda do dia de risco | 5% | 5% | 20 prata |
| Perda num item no dia, contando depósito perdido | 1% | 1% | 4 prata |
| Compra diária de um item (fase 2) | 10% das vendas inferidas na exposição observada do dia; sem 2 horas de exposição, só o lote de confirmação | igual | |
| Papel aberto por chave | o mesmo teto de volume da linha acima | igual | |
| Preço de postagem | entre o piso de preço da seção 7.2 e 3 vezes a referência | igual | |
| Classe `sonda` (só com o cartão da sonda aberto) | postagem com depósito de até 30 cobre; compra de até 20 cobre por ordem; só as ordens que o passo prevê, uma por tecla | igual | |

**Piso absoluto dos tetos de depósito.** Os tetos de depósito são fração de uma banca que pode ser quase zero num personagem que só vende. Por isso valem o maior entre a fração e um piso absoluto, que é constante de `Tetos.lua` como todo teto duro (regra 13): 20 prata para o depósito em risco e 8 prata para o perdido no dia. O `Config.lua` só pode baixá-los (`cofre.piso_teto_deposito` e `cofre.piso_teto_perdido`, de zero até o valor de `Tetos.lua`); subir é editar `Tetos.lua`, com registro (DD10). O depósito nunca passa do dinheiro do personagem. O Cofre nega a postagem cujo depósito, somado ao já perdido no dia, passaria do teto do dia.

O que os tetos de depósito deixam passar, pela leitura provável da base 1.4 (depósito de 24 horas igual a 60% do preço de vendedor, hipótese H-09), com `B` de 4 ouro:

| Preço de vendedor | Depósito de 24 h | Leilões simultâneos (teto de 20 prata) | Expirações por dia (teto de 8 prata) | Uma expiração bloqueia o item (1%)? |
|---|---|---|---|---|
| 50 cobre | 30 cobre | 66 | 26 | não |
| 2 prata | 1 prata 20 cobre | 16 | 6 | não |
| 5 prata | 3 prata | 6 | 2 | não |
| 10 prata | 6 prata | 3 | 1 | sim |
| 20 prata | 12 prata | 1 | 0 | sim |

Até 17/11, com o mínimo de 1 prata, um item de 50 cobre cai para 20 simultâneos e 8 expirações. O teto do perdido no dia é o que segura a calibração: um verde de 5 prata com chance de venda de 0,4 permite cerca de 3 postagens por dia, e os 10 desfechos da seção 7.6 levam uns 3 dias. Sem reunir o ouro, um personagem com 27 prata de banca fica com os mesmos 20 e 8 prata pelos pisos absolutos (as frações dariam 1 prata 35 cobre e 54 cobre, e um verde de 2 prata ocuparia o teto sozinho).

**Ritmo não é teto duro.** `Tetos.lua` só tem teto de dinheiro (regra 13). O ritmo vive no `Config.lua`: `ritmo.acoes_min` (10 de partida, contando verbo concluído: postar, comprar, cancelar; não chamada de função) e `ritmo.buscas_min` (30 de partida). O máximo das buscas é o ritmo sustentado na S4 sem mensagem descartada, nunca acima de 100 por minuto (base 2.2). O das ações é o que os portões de máquina da seção 17.1 liberarem: os degraus previstos são 10, 15 e 20, e 20 é o último previsto, não um teto; passar dele é uma linha nova no `Config.lua`, com o mesmo portão. Subir é sempre portão medido (seção 17.1), com linha datada no `Config.lua`.

Compra de classe A já confirmada não conta no teto de risco de preço, mas conta no teto por item. Se a H-10 for negada e o item comprado vier direto para a bolsa, o Cofre nega a compra sem espaço livre. Kelly (R9 7.2) não dimensiona nada: com retorno sem medir ele é sensível demais (R9 7.7).

### 9.3 Antiguerra e mercado adverso

- **G1**: no máximo 2 cancelamentos com repostagem por item em 4 horas.
- **G2**: conta-se uma cobertura quando uma foto mostra oferta alheia nova abaixo do leilão próprio, com a hora da foto. Duas coberturas de postagens próprias do mesmo item em 60 minutos, cada uma vista até 10 minutos depois da postagem, tiram o candidato `cobrir`, põem o item em trégua por 4 horas e a linha diz `STAND DOWN`. A contagem é só dos próprios leilões; não usa nome de vendedor. A janela é de 60 minutos porque a cobertura só se vê numa foto, e porque, se o item cancelado volta pelo correio (H-10), o ciclo de cancelar, receber e repostar não cabe em 10 minutos.
- **Parede**: degrau de commodity com 25% ou mais da quantidade da escada e até 2 donos. O addon nunca propõe preço acima dela e nunca a compra. Em item não se marca parede (pediria identidade de vendedor). A isca nunca serve de âncora.
- **Deriva**: a compra para revenda numa classe é suspensa quando `2 · deriva_dia <= ln(0,9)`, isto é, queda de 10% em dois dias (seção 7.4).

G1, G2, a parede e o limiar da deriva são números do projeto, sem fonte de economia (DD10). Apoiam-se só em relatos de guia sobre isca e cobertura em minutos (R8a F23; R8b R7) e no modelo do R9 9.3: nenhuma fonte propõe teto de cancelamentos. São guarda de depósito, não estratégia.

### 9.4 Disjuntores

O **disjuntor** é uma trava automática que suspende um tipo de ação até a condição de destrava. Todo disjuntor grava em `pers[nome].cofre` o gatilho, a hora e o `seq`: o estado sobrevive a `/reload` e a logout. Disjuntor ligado aparece na linha de estado de toda visão.

| Disjuntor | Gatilho | Efeito | Destrava |
|---|---|---|---|
| Perda do dia | resultado do dia de risco em −5% de `B` | só venda | virada do dia de risco (06:00, seção 6) |
| Perda num item | −1% de `B` num item, contando depósito perdido | item bloqueado | 24 horas |
| Ação muda | 3 INCERTO na sessão | ações bloqueadas | fechar e reabrir o leilão; conciliar no primeiro fôlego |
| Dado ruim | 2 fôlegos incompletos seguidos ou foto vazia suspeita | compra suspensa | fôlego limpo |
| Compras perdidas | 3 "já sumiu" seguidas | compra suspensa | próximo fôlego |
| Throttle travado | "não pronto" por 30 s (base 2.14) | consultas e ações param | fechar e reabrir o leilão |
| Restrição de conta | `AUCTION_HOUSE_SHOW_ERROR` com `HasRestriction` ou `RestrictedAccountTrial`, ou `AUCTION_HOUSE_DISABLED` (R1a 3; R1b 15) | tudo para, faixa fixa, nenhuma nova tentativa | sessão do agente |
| Dinheiro sem explicação | desvio da conciliação acima de 1% de `B`, medido só dentro de uma janela de leilão ou de correio (seção 10) | compra cai para papel | sessão do agente |
| Fim sujo | na entrada, `GetMoney()` diferente do dinheiro do último fecho (seção 6.3) | contadores do dia no teto: só venda | sessão do agente |
| Número do jogo mudou | parâmetro medido divergiu ou o build mudou (seção 7.6) | licenças que dependem dele caem para papel | nova medida |
| Rajada; Halt | 6 teclas de ação recebidas em 2 s; tecla `H` | bindings de ação soltos | tecla `H` |

**A tecla `H`.** É um alternador de um estado só, que a linha de estado mostra em palavra: `KEYS ON` ou `KEYS HELD`. Com as teclas de ação ligadas, `H` as solta; com elas soltas, pelo próprio `H` ou pela rajada (`KEYS HELD - burst`), `H` as rearma. `H` nunca chama função de ação, e não rearma enquanto outro disjuntor que bloqueia ações estiver ligado: nesse caso a linha de estado diz qual.

**Destrava pela sessão do agente.** O agente não escreve nas SavedVariables (regra 19). A destrava é uma linha `Config.destravas[disjuntor] = seq`, escrita com o sim do dono; depois do `/reload`, o addon solta o disjuntor se o `seq` for o do disparo.

O disjuntor de restrição responde ao Temporary Economy Hold (base 1.10); se é assim que ele aparece não há como testar. O próprio anúncio do hold admite falsos positivos (R5a 3.2): o Livro, com a hora da tecla, o bilhete e o eco de cada ação, é o registro para mostrar ao suporte.

## 10. Contabilidade

O `Livro.lua` é a régua. Ele mede o que o dono faz por qualquer caminho: os eventos de criação, cancelamento e compra e os avisos de venda são do cliente (base 2.9 a 2.11), então a ação feita pela tela da Blizzard ou por outro addon também vira linha, marcada `outside` (H-25). É o que dá a linha de base antes de existir tecla própria e o que permite comparar construir com adotar. A parte de observação do `Ecos.lua` nasce na onda 2 para isso.

| Registro | Campos |
|---|---|
| Ação | `seq`, hora da tecla, verbo, chave, quantidade, preço, estratégia, bilhete, dinheiro antes e depois, eco e hora do eco, código de erro, origem (`key`, `mouse` ou `outside`) |
| Lote | chave, quantidade, custo (ou `cost unknown`), origem (comprado, coletado), estado (`maos`, `postado`, `vendido`, `npc` ou `retirado`), fechamento |
| Sinal | estratégia, nível, previsto, motivo, se executou, desfecho real ou de papel (`sold`, `not sold`, `inconclusive`, `skipped`), exposição observada |
| Fatura | tipo (`buyer`, `seller` ou `seller_temp_invoice`), chave do item (resolvida pelo anexo da carta ou, na venda, pelo nome contra os lotes abertos; o texto do nome não é gravado), `bid`, `buyout`, `deposit`, `consignment`, `moneyDelay`, `etaHour`, `etaMin`, `count`, `commerceAuction` (espelho, `Blizzard_MailFrame/MailFrame.lua:790 a 866`) |
| Fora | variação de dinheiro que não vem do leilão, do correio nem de venda conferida no NPC; janela (`play`, dentro da sessão, ou `between`, entre sessões) |
| Sessão | duração, ações por verbo, resultado, `fora` (a soma do registro `Fora` na sessão), gargalo, parâmetros em vigor |

**A fatura.** O valor da venda está em `bid`, não no arremate; o recebido é `bid + deposit - consignment`; o corte é `consignment / bid`. `count` e `commerceAuction` marcam a venda de várias unidades. A carta de venda pendente (`seller_temp_invoice`) não traz dinheiro: não entra na soma e alimenta o ouro a caminho e o atraso do correio (H-12).

**O que o correio não grava.** `Correio.lua` só registra cartas cujo `invoiceType` é de leilão. De `GetInboxInvoiceInfo` descarta `playerName`; de cabeçalho não grava remetente nem assunto de carta que não seja do leilão (regra 20). O checador e a bancada (fatura com nome) conferem.

**Fechamento de lote.** Venda no leilão fecha pela fatura. Venda ao NPC fecha casando a saída do item da bolsa com o `PLAYER_MONEY` seguinte, com o vendedor aberto (`MERCHANT_SHOW`, R1c); o que outro addon vende ou conserta ao abrir o vendedor é `outside` (seção 7.3). Item que o dono usa ou guarda fecha como `retirado`, sem resultado. Lote que não vendeu não some da conta: os portões da seção 3.3 contam todo lote emitido há mais de `T_fecho`, o aberto marcado. Lote de commodity vendido em parte fica aberto até o último desfecho (H-33).

**Medidas.** Resultado realizado e estoque marcado; cobre por ação e por hora; depósitos perdidos; fração vendida por classe, duração e regra; taxa de "já sumiu"; tudo por estratégia e por origem. Mais os cinco parâmetros da escada de capital (seção 3.4): fração aplicada da banca, margem líquida por volta, acerto, horas por volta e entradas de fora por dia (a soma do registro `Fora` mais o resultado dos lotes de origem `coletado` fechados no dia: é conta da régua, não campo gravado). E o gargalo de cada sessão (capital, sinal, vazão ou giro, seção 17.1).

**Conciliação.**

- No leilão: dinheiro, leilões próprios e bolsas contra o Livro, a cada fôlego, a começar pelo primeiro depois da abertura.
- No correio: a soma das faturas contra a variação do dinheiro. `GetInboxNumItems` devolve dois números, as cartas mostradas e o total; quando o total passa do mostrado, o painel diz `MORE MAIL WAITING` e a conciliação não fecha.
- **A janela.** `PLAYER_MONEY` é acompanhado sempre. Variação com o leilão, o correio e o vendedor fechados, ou entre sessões, vira registro `Fora`, explicada por definição: o negociador é um personagem que joga, e quest, saque, conserto e treino mexem no ouro. O **desvio** é só a diferença entre o esperado e o lido dentro de uma janela de leilão ou de correio.
- O resultado é `RECONCILED 12 of 12` ou `UNEXPLAINED 5s 10c`. Desvio acima de 1% de `B` liga o disjuntor de dinheiro sem explicação (seção 9.4); abaixo disso fica só registrado.
- Recolher o correio dispara uma rajada de eventos (por carta, `MAIL_INBOX_UPDATE`, `BAG_UPDATE` e `PLAYER_MONEY`). A conciliação e o redesenho rodam no `BAG_UPDATE_DELAYED` e por bandeira suja, no máximo uma vez por quadro; `PLAYER_MONEY` só acumula a variação.

**Relatório de sessão.** Depois do `/reload` de fecho, o agente lê o banco e escreve o relatório que o projeto pede (base 4.7), em `wow/modder/addons-proprios/PregaoForever/relatorios/`, um arquivo por sessão: resultado; o que vendeu e expirou; as entradas de fora e o ritmo da escada; a ficha de evidência de cada estratégia (sinal medido, papel com a fração inconclusiva e a exposição, condição de ligar cumprida ou não); a autópsia de cada lote perdedor; os itens cujo lote cabe nos tetos de hoje; os itens pulados três vezes com `K`, como candidatos à lista de reservas; e a pauta da próxima sessão.

## 11. Interface

### 11.1 Princípios

Janela própria ao lado do leilão da Blizzard, que continua intacto. Três zonas fixas: estado em cima, lista no meio, bilhete embaixo. Linhas de 28 px, botões de 32 px, contraste de 4,5:1, sem animação (base 8.4). Sem caixa de texto: com o foco numa caixa as teclas não disparam (base 3.4). Disjuntor ligado aparece na linha de estado de toda visão.

**Tamanho e posição.** O leilão da Blizzard é um painel de 800 por 538 unidades, ancorado à esquerda com recuo de 20, e abre as bolsas sozinho (espelho, `Blizzard_AuctionHouseFrame.xml:5`; `Blizzard_AuctionHouseFrame.lua:8` e `:402`). Em 16:9 com escala 1 sobram cerca de 545 unidades à direita, divididas com as bolsas. A janela do addon parte de 520 por 500 unidades, ancorada à direita do leilão e acima das bolsas; as colunas que não cabem vão para o `I`. Esse tamanho é hipótese até a S0 ler a resolução e a escala do dono (H-36, comando 15 do Apêndice A). Os desenhos abaixo têm 78 colunas de texto, o que cabe nessa largura com a fonte padrão.

**Quadros antes do jogo.** O dono decide vendo quadro (base 4.7). A bancada desenha cada visão e cada estado em HTML, no tamanho medido, com o leilão e as bolsas ao lado, e também na resolução da tela do Acer; o dono aprova antes do jogo. Na onda 1 esses quadros são maquetes das telas desta seção; nas ondas 2 e 3 a tela desenhada pelo código tem de trazer os mesmos rótulos e as mesmas seções do quadro aprovado. A página com os quadros renderizados fica em `pesquisa/telas/`.

### 11.2 Teclas

O mapa é proposta, a confirmar na S0 e a aprovar pelo dono vendo o desenho (DD5). Todas as teclas saem da lista livre da base 4.10, que só diz que o UIForever não as usa: os padrões do cliente ninguém conferiu. A S0 lê a que ação cada tecla está ligada hoje (comando 10 do Apêndice A) e o dono confere em Options > Keybindings (R4b, incógnita 4). Valem só com a janela do leilão aberta.

| Tecla | Faz | Função de ação |
|---|---|---|
| `L` | Look: abre um fôlego de varredura, ou o renova | nenhuma (consultas) |
| `N` / `U` | Próxima linha / anterior. Só navegação | nenhuma |
| `I` / `O` | Info, a conta da linha / Show N more | nenhuma |
| `K` | Skip: tira a linha da fila até o fim da sessão e grava `skipped` no Sinal. Item pulado três vezes vira candidato a reserva no relatório | nenhuma |
| `P` | Post: relê, ou arma o bilhete de postagem. Depois da DD5, com aprovação, posta num tempo só | nenhuma até a DD5; depois, `PostItem` ou `PostCommodity` |
| `B` | Buy: relê; cota a commodity; arma o item | `StartCommoditiesPurchase`, só em commodity |
| `C` | Cancel: sempre só arma o bilhete de cancelamento | nenhuma |
| `Y` | Yes: executa o bilhete que está na tela | `ConfirmCommoditiesPurchase`, `PlaceBid`, `PostItem`, `PostCommodity`, `ConfirmPost*`, `CancelAuction`; na visão Session, salvar |
| `M` | Never mind: desarma o bilhete e cancela a cotação | nenhuma |
| `H` | Hold: solta ou rearma as teclas de ação | nenhuma |
| `F1` a `F5` | Visões Next, Sell, Mine, Risk, Session | nenhuma |

```
 [F1 NEXT] [F2 SELL] [F3 MINE] [F4 RISK] [F5 SESSION]

 [Q] [W] [E] [R] [T] [Y yes] [U back] [I why] [O more] [P post]
  [A] [S] [D] [F] [G] [H hold] [J] [K skip] [L look]
   [Z] [X] [C cancel] [V] [B buy] [N next] [M never mind]
```

Regras do mapa:

- **Uma tecla faz uma coisa só.** `N` e `U` só movem a seleção; desistir é `M`; pular é `K`; confirmar é `Y`. Comprar, postar e cancelar ficam em teclas diferentes, para a memória do dedo não trocar um verbo por outro.
- **A tecla perde a função do jogo com a janela aberta.** O binding de sobreposição cala o que a tecla faz no jogo enquanto o leilão está aberto. Pelo padrão habitual do WoW essas letras costumam abrir painéis (bolsas em `B`, personagem em `C`, magias em `P`, mapa em `M`); isso é inferência, e a S0 confere. O dono decide na DD5 sabendo o que cada tecla deixa de fazer.
- **Verbo que gasta ou perde depósito não fica em tecla cujo padrão do cliente abre painel usado no leilão** (bolsas, personagem, magias): apertar por hábito não pode custar depósito. Por isso `C` sempre só arma, e `P` só arma até a S0 e a DD5; quem executa é `Y`. Se a S0 mostrar colisão, os candidatos de troca são `7`, `8`, `9` e `0` ou uma letra livre com Shift.
- **Alerta não pede tecla**: fica 10 s e passa para a linha `LAST ALERT`.
- **Fora do leilão não há binding.** O painel do correio e a faixa de alertas têm só botões clicáveis (`Dismiss` e `Save now`).
- **Visões**: `F1` a `F5`, sempre também com botões clicáveis. Se a S0 mostrar que a fileira F não chega pelo acesso remoto (H-37), as visões vão para `Shift+1` a `Shift+5`.
- A roda do mouse não é ligada a nada, por escolha de desenho: um gesto solto nunca vira ação. Toda tecla tem botão clicável com o rótulo dela.

### 11.3 Telas

Itens e valores são ilustrativos. O cabeçalho fecha a conta: `BUDGET` é a soma de `FREE`, `STOCK`, `DEPOSITS` e `IN MAIL`. `AT RISK` é o estoque com risco de preço mais os depósitos em risco, sobre a banca.

Visão **Next** (F1), a que abre:

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

`pays if 1 in 5 sells` é o ponto de equilíbrio `P*` em palavras (seção 7.2). A linha `PICK RULE` aparece enquanto o dono não escolheu regra, duração e lote para a classe (DD3), e não tem tecla; no exemplo é um item raro, de uma classe ainda sem duração escolhida, enquanto a classe das commodities já tem as três escolhas.

A linha de estado (as três primeiras linhas da Next) e a zona `TICKET` são as mesmas nas cinco visões. Os desenhos de Sell, Mine, Risk e Session as omitem por abreviação; os quadros de `pesquisa/telas/` as mostram.

O bilhete, depois de `B` numa commodity ao vivo (em papel ele diz `PAPER - no gold moved`):

```
| TICKET  QUOTE OK   BUY Linen Cloth x16                                     |
|   pay 1s 44c total (9c each)   max 1s 48c   0.4% of budget                 |
|   vendor pays 2s 08c (safe exit)                                           |
|   [Y] BUY NOW (quote valid 12 s)            [M] never mind                 |
```

O bilhete de postagem (até a DD5, `P` arma e `Y` posta) e o de cancelamento:

```
| TICKET  READY   POST Bandit Cloak x1   24h                                 |
|   price 2s 00c (match)   deposit 30c   price from 42s ago                  |
|   [Y] POST NOW                              [M] never mind                 |
```

```
| TICKET  READY   CANCEL Tin Ore x20                                         |
|   you lose the deposit 12c   cancel fee 0c   340 cheaper ahead             |
|   [Y] CANCEL NOW                            [M] never mind                 |
```

A conta da linha, com `I`:

```
| WHY  Bandit Cloak x1                                                       |
|   lowest 2s 00c, next +50%   5 auctions, 3 sellers   strong reference      |
|   vendor pays 50c   deposit 2h 2c, 8h 10c, 24h 30c                         |
|   24h: pays if 1 in 5 sells   sold 4 of 10 (uncommon gear, 24h, match)     |
|   0 cheaper ahead                                                          |
```

Visão **Sell** (F2):

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

A coluna `your sales` é a frequência medida das vendas próprias na classe. `KEPT` diz o motivo da reserva. `ON OTHER CHARACTERS` vem do Syndicator e é só informação.

Visão **Mine** (F3). Só fatos: preço, tempo restante, quantas unidades mais baratas na frente, depósito em risco. Nenhum ganho de cancelar é mostrado (seção 7.4); `STAND DOWN` aparece quando a regra antiguerra vale. A hora do ouro de um leilão vendido depende da H-27.

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

Visão **Risk** (F4). `EXPOSURE` mostra os 3 mais próximos do limite entre os 10 tetos de consumo da seção 9.2 (a faixa de preço de postagem e a classe `sonda` não são consumo e ficam fora), do mais próximo para o mais distante; `BREAKERS` mostra só os ligados, cada um em palavra (por exemplo `BUYING HALTED - 3 items gone in a row`), ou uma linha dizendo que estão todos livres; `LICENCES` mostra, por estratégia, a permitida, a conquistada, a que vale e o que falta.

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

Visão **Session** (F5). `budget used` é o custo do que foi comprado e vendido na sessão dividido pelo estoque médio a custo. `PACE` e `OUTSIDE` só aparecem com número medido. `OUTSIDE` é o registro `Fora` da seção 10; as entradas de fora da seção 3.4 somam a ele o resultado da venda do que os personagens coletam.

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

Com uma máquina fora do repouso, INCERTO pendente ou fôlego aberto, o bilhete da Session diz `SAVE BLOCKED - finish or cancel first`.

Painel **Mail**, em quadro próprio, aberto com `MAIL_SHOW` e fechado com `MAIL_CLOSED` (R1c 1). Não tem teclas:

```
+- PregaoForever MAIL -------------------------------------------------------+
| STATE    READY - 11 letters read. Take your mail now.                      |
| SOLD (5)      +14s 20c    cut 75c    deposits back 10c                     |
| EXPIRED (2)   2 items back           deposits lost 4c                      |
| BOUGHT (3)    3 items to collect     2 lots for the vendor                 |
| PENDING (1)   sale pending, gold arrives at 21:40                          |
| CHECK    waiting for you to take the mail                                  |
+----------------------------------------------------------------------------+
| [ Dismiss ]   [ Save now ]                  (click: no keys here)          |
+----------------------------------------------------------------------------+
```

Quando o total de cartas passa do que a caixa mostra, o estado diz `MORE MAIL WAITING` e a conferência não fecha.

### 11.4 Fluxos, tecla por tecla

**A. Varrer, decidir e comprar.**
1. O dono fala com o leiloeiro. A janela abre, as teclas ligam (fora de combate) e a faixa diz `Press L to reconcile`.
2. **[TECLA L]**: um fôlego (consultas). O primeiro concilia. A linha `PRICES` mostra idade e completude.
3. `N` ou `U` até a linha; `I` mostra a conta; `K` tira a linha da fila.
4. **[TECLA B]**. Commodity com foto de mais de 30 s: só relê (`REFRESHED`). Commodity com foto fresca: chama `StartCommoditiesPurchase`, e o bilhete mostra total, teto, fração da banca, saída e validade. Item: sempre relê o leilão e, se o leilão e o preço forem os mesmos, arma o bilhete.
5. **[TECLA Y]**, depois de `T_ver`: `ConfirmCommoditiesPurchase` ou `PlaceBid`. `M` desiste.
6. Resultado em uma palavra: `BOUGHT`, `GONE`, `FAILED` ou `UNKNOWN - checking`. A posição do cursor não muda; a linha seguinte sobe com a marca `NEXT`.

**B. Postar.**
1. `F2`. A lista vem das bolsas; os reservados ficam em `KEPT`, com o motivo.
2. **[TECLA P]** na linha: relê, se a foto da chave passou de `A_post`; senão arma o bilhete com o preço, a duração, o depósito e a idade da foto.
3. **[TECLA Y]**, depois de `T_ver`: `PostCommodity` ou `PostItem`. `M` desiste. Depois da DD5, se o dono aprovar, o passo 2 já posta.
4. Se o jogo pedir confirmação, a faixa diz `GAME ASKS TO CONFIRM` e `MAINTENANCE: may return early, deposit lost`, e repete os números. **[TECLA Y]** chama `ConfirmPost*`; `M`, ou 20 s, aborta. O popup da própria Blizzard aparece junto e não confirma nada do addon: o dono pode fechá-lo.
5. `POSTED`. A linha sai, a seguinte sobe para a posição do cursor com a marca `NEXT`, e `T_ver` recomeça. Linhas `VENDOR`, `KEPT`, `WEAK REFERENCE`, `NO REFERENCE` e `PICK RULE` não têm tecla de ação: o addon marca o item na bolsa e o dono vende, guarda ou posta pela tela da Blizzard.

**C. Cancelar e repostar.**
1. `F3`. Cada leilão traz os fatos; `STAND DOWN` quando a antiguerra vale.
2. **[TECLA C]** arma o bilhete, que diz o depósito que se perde. **[TECLA Y]**, depois de `T_ver`: `CancelAuction`. Com `CANCELLED`, a linha sai, a seguinte sobe para a posição do cursor com a marca `NEXT`, e `T_ver` recomeça.
3. Quando o item volta (bolsa ou correio, H-10), aparece na visão Sell com a marca `returned`. Repostar é o fluxo B.

**D. Recolher o correio.**
1. O dono abre a caixa. O painel mostra `WAIT - reading (7 of 11)` e depois `READY`; se a H-11 não valer, `READY - headers only`.
2. **[CLIQUE DO DONO]** no `Open All Mail` da própria Blizzard (espelho, `Blizzard_MailFrame/MailFrame.xml:444`), ou carta por carta. O addon não pega ouro nem item.
3. O addon compara a variação do dinheiro e das bolsas com o que leu e fecha os lotes. `Dismiss` e `Save now` são botões, sem tecla.

**E. Fechar a sessão.**
1. `F5`: resumo, pendências (INCERTO, depósitos em risco, ouro no correio) e o que foi medido.
2. **[TECLA Y]**, só com tudo em repouso: grava o registro e recarrega a interface, o que leva o banco ao disco (base 3.9). Se a H-19 falhar, a tela pede `/reload` digitado; se a H-35 mostrar que recarregar com o leilão aberto deixa algo pendente, salvar pede o leilão fechado. No meio de uma sessão longa, a mesma tecla é o ponto de salvamento.

### 11.5 Operação remota, ritmo e alertas

- **Eco imediato.** A tecla aceita muda a palavra de estado no mesmo quadro (`SENT`; `QUOTING` na cotação), e o rodapé mostra a última tecla recebida: é o que evita a segunda tecla por dúvida.
- **Foco e combate.** Com o foco numa caixa de texto da Blizzard ou de outro addon as teclas não disparam (base 3.4). O addon lê o foco com `GetCurrentKeyBoardFocus()` e a faixa diz `Keys paused: click outside the search box` (H-26, medida na S12). Em combate, a faixa diz `IN COMBAT - trading paused`. Com o leilão aberto, o clique direito num item da bolsa manda o item ao painel de venda da Blizzard: não afeta o addon, mas o dono vê a tela da Blizzard mudar.
- **Botões para o mouse.** Se a H-01 falhar para a tecla e valer para o mouse, os botões de ação ficam em posições fixas, lado a lado, um por verbo, com o `Y` separado deles por um vão da largura de um botão: nenhuma viagem longa de ponteiro e nenhum ponto que acumule dois verbos.
- **Ausência.** Sem tecla, o fôlego acaba e nada mais roda. A marca de ausente e a saída por inatividade seguem o curso do jogo (base 8.2; H-31).
- **Suspensão da máquina.** Se o stream cair e o Avell entrar em suspensão, perde-se o que não foi salvo. O preparo fica fora do jogo, na DD9; no addon nada muda, porque CVar é proibida (regra 10).
- **Ritmo.** Uma volta é a perna do leilão (varrer, postar, comprar, cancelar por último) mais a perna do correio. Aos 45 minutos ou 50 ações sem salvar, a visão Session sugere salvar; nada é imposto.
- **Latência.** `T_ver` soma a latência de `Config.remoto.latencia_ms`. O jogo não a enxerga: o dono lê o número no overlay da ferramenta de acesso remoto (R10a 1.1) e o agente o grava.
- **Alertas.** Todo alerta é uma faixa de texto que fica 10 s e passa para a linha `LAST ALERT`; nenhum pede tecla. Fora do leilão a faixa é um quadro próprio, com o botão `Dismiss`. `FlashClientIcon` e `PlaySound` (base 3.6) são reforço, porque o som pode não atravessar o stream (R10a 4, inferência). São eles: `SOLD`, `EXPIRED` e `OUTBID` (avisos do jogo, que chegam com o leilão fechado, base 2.11); `BUYING HALTED` com o motivo; `API STALLED - close and reopen the auction house`; `AUCTION HOUSE RESTRICTED - actions paused`; `UNEXPLAINED 5s 10c - paper mode until reviewed`; `SAVE SOON`; `TOO MANY OPEN LOTS`; `GAME NUMBER CHANGED`; `DATABASE NOT LOADED - tell the agent`; `CONFIG ERROR - read only`.

## 12. Mesa externa (opcional enquanto o dono não decidir)

A **mesa** é o que roda fora do jogo. A decisão DD7 escolhe entre três tamanhos; o addon funciona igual nos três, porque só conhece dois arquivos.

| Opção | O que roda | Quando |
|---|---|---|
| A, padrão | A sessão do agente, depois do `/reload` de fecho: `ler-pregao.mjs` copia o arquivo de SavedVariables cru para o arquivo morto, converte o banco em JSON e devolve o `recibo` no cabeçalho do `Calibrado.lua`; o agente escreve o relatório e, com o sim do dono, o `Config.lua` e o `Calibrado.lua` | Fases 1 e 2 |
| B | `mesa.mjs`, rodada pelo agente no fecho: arquiva as fotos, roda o replay, calibra, gera o relatório | Fase 2; no degrau 2 da fase 3 passa a ser o padrão |
| C | Um vigia no Avell que roda a opção B a cada `/reload`, com o jogo aberto | Só se o dono pedir. É o padrão dos aplicativos companheiros (base 5.6), sem posição oficial da Blizzard |

**Contratos de dados.**

| Arquivo | Quem escreve | Defesa |
|---|---|---|
| SavedVariables `PregaoForever.lua` | o addon | A mesa só lê, sem executar, com `luaparse.parse(texto, { luaVersion: '5.1', encodingMode: 'pseudo-latin1' })`: no modo padrão o `luaparse` devolve `null` no valor de toda string. O leitor confere que `esquema` e uma string conhecida voltam não nulos antes de seguir; confere `fim == seq` (saída limpa); identifica cada registro por (`epoca`, `seq`); lê todas as versões de linha conhecidas e recusa só o registro de versão desconhecida, contando-o no relatório; arquiva cada cópia que lê |
| `Calibrado.lua` | agente ou mesa | Cabeçalho (`esquema`, `geradoEm`, `recibo`, `epoca`) e sentinela; gravação por arquivo temporário e renomeação; cada valor tem faixa (Apêndice B) e, fora dela, vale o de partida; nenhum valor alcança `Tetos.lua` |
| `Config.lua` | o agente, com o sim do dono | Licença acima do que a evidência sustenta e teto acima do duro não têm efeito. Traz o campo `destravas` (seção 9.4). O agente roda `node checar-lua.mjs` no arquivo antes de pedir `/reload` ao dono |
| `Dados.lua` | gerado na onda 1 | Conferido pelo `checar-dados-pregao.mjs` |
| arquivo morto em `wow/modder/dados/pregao/` | a mesa | A cópia crua de cada SavedVariables lido e, na opção B, uma foto por linha, por dia. Fora do git: a onda 1 cria a entrada do `.gitignore` para `wow/modder/dados/` e para a saída JSON do `ler-pregao.mjs`, conferida por `git check-ignore`. O repositório raiz recebe commits automáticos de sincronização; sem essa entrada os dados subiriam ao remoto |

O `recibo` diz até qual `seq` o arquivo de fora já guardou; o addon poda primeiro o que tem `seq` até ele. A entrega é "pelo menos uma vez" enquanto o anel não enche; o que um anel cheio cobriu sem recibo fica registrado em `sobrescritos` (seção 6.2), para o relatório dizer o que se perdeu.

**Modos diante dos arquivos.**

| Situação | Modo | Efeito |
|---|---|---|
| `Calibrado.lua` com cabeçalho e sentinela certos e idade de até 7 dias | `DESK OK` | tudo vale |
| `Calibrado.lua` mais velho | `DESK STALE` | toda compra cai para papel |
| `Calibrado.lua` ausente, truncado ou de outro esquema | `NO DESK` | valem os números de partida e as leituras do jogo já adotadas em `calib`; só as vendas e o papel funcionam |
| `Config.lua` ausente, quebrado ou de outro esquema | `CONFIG ERROR - read only` | o addon entra em `leitura`; os leilões abertos seguem o curso do jogo |
| `Dados.lua` ausente | sem faixa | sem triagem do `piso` |
| `PregaoForeverDB` não carregou | `DATABASE NOT LOADED - tell the agent` | `leitura`, sem recriar o banco (seção 6.3) |

Se um arquivo `.lua` com erro de sintaxe impede a carga dos seguintes é hipótese (H-34), medida na S13.

**O que sai da máquina.** O addon não envia nada para fora do jogo. A mesa guarda os arquivos localmente, fora do git. O relatório de sessão (opção A) põe os números do banco no contexto da sessão do agente, que roda num serviço de nuvem: o dono deve saber disso.

**Dados externos.** Há relato de rotas da API oficial de dados com leilões por conjunto de regras, que pedem credencial de desenvolvedor do dono e que a Blizzard não documenta em página aberta (base 5.4). Ficam fora até a decisão DD8. Se ela for aprovada, o dado da API fica num arquivo separado, apagado com 30 dias (os termos da API de desenvolvedor impõem um prazo máximo de guarda, a conferir na leitura integral dos termos que a DD8 pede), fora do arquivo morto e fora do git; nada dele vai ao addon.

## 13. Dados estáticos

- **`Dados.lua`** (onda 1). `gerar-dados-pregao.mjs` lê o `ItemSparse` em CSV do build 70938 (base 9.1; origem no Apêndice D) e grava `ns.vend[itemID] = SellPrice`, numérico, para os 11.967 itens com preço de venda maior que zero (de 19.325), e `ns.pilha[itemID]` só para os itens com `Stackable` maior que 1. Qualidade e classe só entram se uma tela pedir, em tabela à parte. Tamanho medido de `ns.vend`: 154 KB e cerca de 14,7 mil constantes, longe do limite da linguagem. O formato numérico resolve a triagem do resumo com uma leitura de tabela, sem partir string. O cabeçalho gerado registra a origem do dado (wago.tools, build e data). Serve só à triagem; o preço que decide é o lido ao vivo (regra 17).
- **`checar-dados-pregao.mjs`** confere contagem, faixas e ASCII; a sonda S0 confere 20 itens contra o jogo (comando 13 do Apêndice A, um item por vez).
- **`Receitas.lua`** (fase 3). Grafo de `SpellReagents`, `SpellEffect` e `SkillLineAbility`, cerca de 130 KB; as 526 linhas com quantidade zero pedem regra própria (base 9.2).
- **Fora do cliente**: rendimento de desencanto e estoque limitado de vendedores (base 9.3). O addon só os conhece medindo.

## 14. Interoperação com os addons instalados

Tudo em `Pontes.lua`, em tempo de execução, com `pcall`; com o addon ausente, a peça desliga e o resto segue (base 7). Este design não nomeia função interna de addon de terceiro. A assinatura de cada ponte é definida na onda 2, com o dono, lida no jogo por `/dump` (por exemplo `/dump Auctionator.API.v1`), nunca no código do addon nem no repositório do autor: os autores de três deles pedem que agentes de IA não usem o código como referência (base 7).

| Addon | O que a base diz que ele oferece | Para quê |
|---|---|---|
| Auctionator 341 | Uma API pública (`Auctionator.API.v1`) com preço por item (o último mínimo visto), idade do preço, preço de vendedor e aviso de que o banco mudou (base 7.1) | Referência fraca; segunda opinião (diferença de mais de 3 vezes rebaixa a referência para fraca) |
| Syndicator | Contagem de um item por personagem e dinheiro por personagem (base 7.2) | A linha `ON OTHER CHARACTERS`; dizer em qual personagem o item está |
| Baganator | Outro addon pode pôr uma marca no canto do item da bolsa (base 7.2) | Marcar o que vai ao NPC e o que vai ao leilão |
| ElvUI | Módulo de skins pedido em tempo de execução (base 7.5) | Vestir a janela; o kit `Visual.lua` tem plano próprio se ele faltar |
| ForeverGuide, Naowh Forever | Nada é usado | Do primeiro, só o aviso de privacidade ao dono: por padrão ele compartilha as varreduras (base 7.3). Desligar é a DD2 |
| Leatrix Plus | Nada é usado | Aviso: com a venda de lixo e o conserto automáticos ligados (R4b), o dinheiro muda ao abrir o vendedor. O addon trata essa variação como `outside` (seção 7.3) |

O BugGrabber, já instalado (R4b 2), é o juiz de "sessão sem erro de Lua". Se a S4 mostrar disputa de throttle com a varredura automática do Auctionator (H-08), a saída é o dono desligá-la (DD2).

## 15. Conformidade

**Política.** Só a API oficial de addons (base 4.4). O suporte disse que o uso normal do leilão é sempre permitido e que os sinais suspeitos são item barato por muito ouro e preço muito fora do mercado (base 1.10); não foi achado relato de punição por addon de leilão dentro das regras (base 5.7). A documentação do cliente limita a busca por item a 100 por minuto e pede que ela não varra o leilão inteiro (base 2.2): o design fica aquém (seção 5.1). O acesso remoto ao próprio PC não tem posição oficial (base 8.3): fica fora do addon e é a decisão DD9.

**Limites que afastam os dois sinais.** Preço de postagem sempre dentro da faixa da seção 9.2; sem referência forte, nenhum preço proposto (referência fraca não gera candidato). Nenhuma compra acima da referência. Leilão marcado `containsOwnerItem` ou `containsAccountItem` nunca vira linha (base 2.3, 2.4). Em commodity, em que a compra leva as unidades mais baratas sem escolher leilão, a regra é outra: se algum degrau dentro da profundidade da compra tiver `containsAccountItem`, não há sinal nem cotação (seção 7.3). Uma tecla por ação. O Livro guarda cada ação com a hora da tecla, o bilhete e o eco: é o registro para mostrar ao suporte, se preciso, inclusive num falso positivo.

| O addon se recusa a | Por quê |
|---|---|
| Agir por timer, evento ou em cadeia; reenviar ação sem eco | Regra do dono (base 4.4, 4.6); a falha silenciosa é documentada (base 2.12) |
| Confirmar compra de commodity sem tecla | A API talvez permita (base 2.13), e por isso mesmo seria gasto sem o dono. Não é oferecido nem como opção |
| Chamar `:Click()` ou usar macro | Simula entrada: o cliente marca o clique por código como entrada roteirizada |
| Ligar tecla a botão da Blizzard | Regra 10 e recomendação da DD1c: o risco de taint e a leitura da H-11 não foram medidos. É padrão que o dono pode rever na DD1c, não recusa permanente |
| Pegar correio por código ou por tecla | Por código, nunca. Por tecla, é recomendação da DD1c (padrão: não), pelas incógnitas da H-11, e não pela decisão de 2026-11-06, que fala de comprar ou gastar |
| Vender ou comprar no NPC por código ou por tecla | A decisão de 2026-11-06 proibiu, no outro addon, funções que compram ou gastam por código (base 4.6); aqui ela vale por padrão. A DD1c traz a opção de vender ao NPC por tecla, com recomendação de não |
| Testar na sonda uma ação fora de clique | O resultado não muda o desenho, e o teste encosta na regra de não contornar evento de hardware |
| Abrir fôlego por evento ou timer, consultar fora de fôlego aberto por tecla ou sem tecla recente | Regra 9 e I9; a opção contínua da DD13 foi recusada |
| Chamar `ReplicateItems` nas fases 1 e 2 | Base 2.5; na fase 3 só com passo de sonda próprio e decisão do dono |
| Reset, formação de mercado, lance, casa neutra, equipamento para revenda | Sem fonte ou com fonte fraca (seção 3.2) |
| Gravar ou mostrar nome de outro jogador; ler ou reusar código de terceiro | Escolha do projeto (regra 20); base 7 |
| Mexer na marca de ausente, em CVar ou em binding salvo; enviar dado para fora do jogo | Base 8.2, 4.7 |
| Continuar depois de um sinal de restrição de conta | Base 1.10 |

**O que é regra e o que é escolha.** Para o dono saber o que pode rever:

| Cautela | Natureza | Custo | Onde se decide |
|---|---|---|---|
| Uma tecla por fôlego | Escolha (a base 8.2 deixa em aberto) | Alto na fase 2: a inferência de vendas fica rala | DD13 |
| Não gravar identificação de vendedor | Escolha | Baixo hoje; na fase 3 tira o casamento de repostagem em item | DD15 |
| Não usar a roda do mouse | Escolha | Quase nenhum | fixo |
| Sem tecla para recolher o correio | Escolha | Quase nenhum: o `Open All Mail` da Blizzard existe | DD1c |
| Nada de vendedor NPC por código ou tecla | Regra do dono no outro addon, estendida a este | Um clique de venda por pilha no `piso` | DD1c |
| Confirmar commodity só com tecla | Regra do dono (uma tecla por ação) | Nenhum | fixo |
| Não testar ação fora de clique | Regra do projeto | Nenhum | fixo |

## 16. Testes

**Onde ficam.** Todos os scripts novos vão para `wow/modder/ferramentas/guia/`, nas pastas `pregao/` e `casos-pregao/`: é ali que `luaparse` 0.3.1 e `fengari` já estão instalados (R4a 3), e as tarefas não instalam nada. Os comandos são escritos a partir dessa pasta: `node pregao/bancada-pregao.mjs`, `node pregao/rodar-casos-pregao.mjs`, `node pregao/checar-pregao.mjs <pasta>`, `node pregao/ler-pregao.mjs`, `node pregao/replay-pregao.mjs`, `node pregao/gerar-dados-pregao.mjs` e `node pregao/checar-dados-pregao.mjs`.

**Bancada com leilão falso.** A bancada atual não simula leilão, dinheiro nem ticker repetido (base 4.9). Nasce `bancada-pregao.mjs`, em fengari, que carrega o addon inteiro contra um `C_AuctionHouse` falso (funções e eventos do contrato, R1a), throttle com fila que pode travar, dinheiro, bolsas, correio com fatura, vendedor, relógio controlado, ticker que repete e bindings. O que ela precisa ter, além do contrato:

1. **A sequência de eventos por chamada.** A documentação não diz o que dispara cada evento (R1a 4); a tabela abaixo é a sequência nominal, por inferência (R1a 6), e as sondas S2, S4 e S8 gravam a real, que corrige a tabela.
2. **Paginação.** Tamanho de página do resumo (cerca de 480 linhas por pedido, pela base 2.6) e da escada como parâmetros; `HasFull...` e `RequestMore...` com a semântica da seção 5.
3. **Correio falso.** `GetInboxNumItems()` devolve as cartas mostradas e o total; `GetInboxHeaderInfo(i)` devolve o cabeçalho, com `wasRead` e `textCreated`; `GetInboxText(i)` devolve o texto e `isInvoice`; `GetInboxInvoiceInfo(i)` devolve os 12 retornos da seção 2.1. As assinaturas completas estão no R1c.
4. **`ItemLocation` falso.** Um objeto com bolsa e slot, criado por `ItemLocation:CreateFromBagAndSlot(bolsa, slot)`, aceito por `C_Item.DoesItemExist`, `GetItemID`, `GetItemLink`, `GetItemName` e `GetStackCount` e pelas funções de postagem e de depósito.
5. **Processo de venda.** Quem compra o leilão do dono no simulador: uma probabilidade por hora, como parâmetro, que gera `SOLD`, `EXPIRED` e faturas.
6. **Dinheiro.** Depósito, corte, devolução e atraso do correio como parâmetros do simulador, independentes do `Calibrado.lua`.
7. **Cenários.** Um arquivo por cenário em `casos-pregao/cenarios/`, com as teclas, as falhas injetadas e o estado final esperado. `--auto-teste` só confere o próprio falso (é o que a onda 1 pode passar); `--cenarios <grupo>` roda um grupo (`folego`, `fatura`, `dados`, `venda`, `postar`, `cancelar`, `operador`, `comprar`, `papel`), e cada tarefa de onda tem o seu comando: o grupo segue a onda que constrói o módulo testado. A "verdade do simulador" é comparada com o Livro no formato da seção 6.1.
8. **Ganchos de tela.** `ns.__tela` expõe a linha selecionada e o texto exibido, para conferir a I8.
9. **Banca do simulador.** Para conferir a I4 sem circularidade, a bancada usa uma banca própria, sem estoque marcado pelo motor: dinheiro menos piso, mais correio a receber, mais depósitos em leilões ativos, mais estoque a custo.

| Chamada | Eventos nominais, em ordem | Variantes injetadas |
|---|---|---|
| `SendBrowseQuery` | `AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED`, `..._SENT`, `..._RESPONSE_RECEIVED`, `AUCTION_HOUSE_NEW_RESULTS_RECEIVED` (payload `nil`), `AUCTION_HOUSE_BROWSE_RESULTS_UPDATED`, `AUCTION_HOUSE_THROTTLED_SYSTEM_READY` | `AUCTION_HOUSE_BROWSE_FAILURE`; resposta que não chega; `..._DROPPED`; lista que encolhe |
| `RequestMoreBrowseResults` | os de throttle, `AUCTION_HOUSE_BROWSE_RESULTS_ADDED(addedBrowseResults)` | página que não chega |
| `SendSearchQuery`, commodity | os de throttle, `AUCTION_HOUSE_NEW_RESULTS_RECEIVED(itemKey)`, `COMMODITY_SEARCH_RESULTS_UPDATED(itemID)`; também um `AUCTION_HOUSE_BROWSE_RESULTS_UPDATED` espúrio | primeira página sem a frente; resposta de outra chave; resposta vazia onde havia oferta |
| `SendSearchQuery` e `SendSellSearchQuery`, item | os de throttle, `ITEM_SEARCH_RESULTS_UPDATED(itemKey)` | o mesmo evento com `newAuctionID` (atualização de um leilão, não resposta) |
| `QueryOwnedAuctions` | os de throttle, `OWNED_AUCTIONS_UPDATED` | resposta que não chega |
| `PostCommodity`, `PostItem` | retorno `needsConfirmation` falso, `AUCTION_HOUSE_AUCTION_CREATED(auctionID)`, `OWNED_AUCTIONS_UPDATED` | `needsConfirmation` verdadeiro com `AUCTION_HOUSE_POST_WARNING`; `AUCTION_HOUSE_POST_ERROR`; `AUCTION_MULTISELL_START`; cada código de `AUCTION_HOUSE_SHOW_ERROR`; nenhum eco; função que devolve nada |
| `StartCommoditiesPurchase` | `COMMODITY_PRICE_UPDATED(unitario, total)` | `COMMODITY_PRICE_UNAVAILABLE`; total acima do teto; segunda cotação em COTADO; nenhuma resposta |
| `ConfirmCommoditiesPurchase` | `COMMODITY_PURCHASE_SUCCEEDED`, `COMMODITY_PURCHASED(itemID, quantity)` | `COMMODITY_PURCHASE_FAILED`; nenhum eco |
| `PlaceBid` | `AUCTION_HOUSE_PURCHASE_COMPLETED(auctionID)` | `AUCTION_HOUSE_SHOW_ERROR(ItemNotFound)` e os outros códigos; nenhum eco |
| `CancelAuction` | `AUCTION_CANCELED(auctionID)`, `OWNED_AUCTIONS_UPDATED` | `AUCTION_HOUSE_SHOW_ERROR(ItemHasQuote)`; nenhum eco |

- **Bandeira de hardware.** As funções de ação só funcionam enquanto a bancada despacha um clique simulado, vindo de botão com prefixo `PregaoForever`; fora dela não fazem nada, como no cliente (base 2.12), e a bancada conta a violação.
- **Falhas injetadas**, além das da tabela: throttle travado, leilão fechado no meio de cada estado, depósito nulo, erro alheio sem ação em voo, bolsa trocada entre a linha e a tecla, fatura com nome de jogador, dinheiro que muda fora da janela de leilão, lixo vendido por outro addon ao abrir o vendedor, leilão que abre ou fecha em combate, `Calibrado.lua` truncado, `Config.lua` com erro de sintaxe, banco que não carregou, fim sujo.
- **Cenários.** Cada transição da seção 8.3 (cerca de 40); ação muda de cada uma das 8 funções de ação (na cotação, o esperado é `PRICE MOVED`, não INCERTO); um por grupo da tabela de códigos de erro; e os casos de operador: duplo toque; tecla presa a 30 repetições por segundo (resultado esperado: exatamente uma ação); `Y` antes de `T_ver`; `Y` durante `ENVIANDO`; teclas alternadas às cegas; rajada de teclas não aceitas; alerta que chega com uma linha selecionada (nada se move); linha que sobe depois de uma ação (`T_ver` recomeça); troca de visão com bilhete armado; `Y` na visão Session com `ENVIANDO`, AVISO, INCERTO ou fôlego aberto (salvar bloqueado); troca para a Session com bilhete armado (o bilhete desarma e o salvar segue). Os mesmos casos com cotação aberta, em que a troca também cancela a cotação, ficam no grupo `comprar`, da onda 4. Mais os casos sem tecla de ação, por grupo: `dados`, abertura do leilão (nenhuma consulta antes do `L`; ações bloqueadas até conciliar) e ida e volta da gramática; `venda`, preço robusto com 1, 2 e 5 unidades e `P*` nos casos-limite; `papel`, lotes de papel em fila na mesma chave.
- **Conferências.** As da tabela abaixo; chamadas de ação em número menor ou igual ao de teclas aceitas; gasto dentro dos tetos; Livro igual à verdade do simulador; estado final seguro. Mais 10.000 roteiros aleatórios com semente.
- **Fase 2.** Mercado sintético com agentes plantados (cobridor rápido, estoque fundo, parede, isca) e mercados de pouca demanda, para testar os estimadores contra verdade conhecida.

| Invariante | Como a máquina confere |
|---|---|
| I1 | Cada despacho de tecla ganha um id; os falsos das 8 funções contam chamadas por id; falha se alguma contagem passar de 1 |
| I2 | Estático: o `checar-pregao.mjs` acha os 8 nomes só em `Acoes.lua`, dentro de `tecla_`. Dinâmico: a bandeira de hardware e o botão de origem |
| I3 | Espiões em `Cofre.autoriza` e `Livro.intencao` registram a ordem dentro do despacho; depois, um registro de eco ou de INCERTO no Livro |
| I4 | Custo da ordem contra `Tetos` vezes a banca do simulador |
| I5 | Injetar "sem eco": estado INCERTO, zero chamadas novas com os mesmos argumentos, bloqueio até a conciliação (na cotação, o esperado é `PRICE MOVED` e zero chamadas novas sem tecla) |
| I6 | Estado dos estimadores igual antes e depois de uma foto sem frente, vencida ou vazia suspeita; nenhum sinal novo |
| I7 | Nível concedido de cada estratégia ao longo do roteiro: falha se subir sem recarga, ou se o nível em vigor passar do concedido depois de um disjuntor destravar |
| I8 | Pelos ganchos de tela: hora da última mudança de seleção e de conteúdo contra a hora da tecla aceita |
| I9 | Toda chamada das funções de consulta da regra 9 tem uma tecla nos `T_pulso` anteriores; nenhuma nasce dentro de um tratador de evento sem fôlego aberto |

**Replay.** `replay-pregao.mjs` repassa as fotos gravadas, em ordem de tempo, pelos mesmos arquivos puros do addon, enxergando só o passado, com preenchimento conservador (R9 10.1, 10.2): os mesmos pares válidos, a mesma fila de lotes de papel por chave e o mesmo desconto de reação da seção 3.3, calculados sobre a foto compacta. O papel do replay tem de ser igual ao que o addon gravou na mesma janela; por isso nenhum desempate depende da ordem do `pairs` e todo número que vira texto é inteiro (regra 14). Linhas de base: não fazer nada, e entrada ao acaso com os mesmos tetos (R9 10.4).

**Checadores estáticos.** `node checar-lua.mjs <pasta>` e `node checar-combate.mjs <pasta> --toc --prefixos PregaoForever,SLASH_PREGAOFOREVER,BINDING_` (base 4.9). Novo `checar-pregao.mjs`, porque a lista proibida do projeto não tem função de leilão (R4a 3). Confere as regras 3 (todo tratador registrado passa por `ns.seguro`), 4 (nenhum `SetScript` nem atribuição em quadro da Blizzard; só os quatro ganchos), 5 (nome de addon de terceiro só em `Pontes.lua`, dentro de `pcall`), 6, 7 (quantidade 1 em `PostItem`), 8, 9 (função de consulta só em `Pedidos.lua`), 10 (por trecho de nome), 12, 13, 14 (construções que só existem numa das duas versões de Lua), 15 (nada que vai ao banco usa `GetTime`) e 20 (nenhum `owners[` atribuído ao banco; `playerName` nunca gravado), e que nenhuma função alcançada por timer, `OnUpdate` ou evento chega a uma `tecla_`. Que a consulta só sai com fôlego aberto por tecla é conferência dinâmica, da bancada (I9). As regras 1, 2, 16 e 18 ficam com os dois checadores que o projeto já tem (sintaxe, ASCII e globais; guarda de combate e `.toc` igual aos arquivos). As regras 11, 17 e 19 não têm conferência automática: são revisão da sessão principal em cada portão. Um caso bom e um ruim por regra em `casos-pregao/`, rodados por `rodar-casos-pregao.mjs`.

**Sonda no jogo.** Apêndice A. Nenhum passo testa o caminho sem tecla. Os passos com tecla de ação rodam pela classe `sonda` do Cofre: os de postar e cancelar (S2 e S6) só depois da DD1a em sim, e a S8, que compra, só com a DD1b em sim. Com a DD1b em "só papel" ou "não", a S8 fica de fora e a compra segue sem medida.

**Critério de aceite.**

| Degrau | Exige |
|---|---|
| Instalar | Checadores com saída 0; bancada com `RESUMO erros=0` nos cenários e nos roteiros; quadros aprovados pelo dono |
| Primeira postagem fora da sonda | S1 a S4 gravadas; S2 positiva; decisão DD1a; números de política aprovados (DD10) |
| Primeira compra fora da sonda | S6 a S8 gravadas (a S6 e a S7 fecham com as amostras que houver); corte e devoluções medidos; duas sessões sem INCERTO pendente e com conciliação exata; decisão DD1b |
| Toda sessão | Zero erro no BugGrabber; toda ação do Livro com a tecla que a originou; desvio da conciliação dentro do limite |
| Subir de nível | Portão da seção 3.3 e a linha do dono no `Config.lua` |

## 17. Entrega em ondas

Padrão do projeto: contrato e esqueletos na sessão principal, tarefas em subagentes, checador ou bancada como critério de pronto e um portão da sessão principal por onda (base 4.9). Cada onda depende da anterior. Um subagente não joga: o "pronto" de cada tarefa é um comando que passa, e o que depende do jogo é um portão do dono, depois do portão da sessão principal. A rota é sugestão de modelo e esforço, pela regra do projeto: o modelo mais barato quando a tarefa tem especificação e pronto por comando; esforço alto só em escalonamento ou depuração; julgamento e portão na sessão principal. A tabela do `executar-plano` decide.

**Tarefas, rota e pronto por comando.** Os comandos rodam a partir de `wow/modder/ferramentas/guia/` (seção 16).

| Onda | Tarefas | Rota | Pronto (comando) |
|---|---|---|---|
| 0, sem código | A sessão principal copia a pesquisa para `pesquisa/` (Apêndice D). O dono segue o roteiro do primeiro dia, abaixo | dono e sessão principal | respostas dos comandos e decisões gravadas em `estado.md` |
| 1, contrato | `ARQUITETURA.md` com as regras, a tabela "API, Contrato" por módulo e as assinaturas públicas congeladas; a gramática do banco (seção 6.1) congelada; `.toc` e 28 esqueletos; `Tetos.lua`; `Config.lua` com tudo desligado; `Calibrado.lua` neutro; `gerar-dados-pregao.mjs`, `checar-dados-pregao.mjs` e `Dados.lua`; `checar-pregao.mjs` e os casos; o leilão falso da bancada; maquetes HTML das telas da seção 11.3 e de cada estado; entrada do `.gitignore` (seção 12); `dev-link.ps1` com o jogo fechado | contrato e maquetes na sessão principal; `checar-pregao.mjs` e casos em `haiku/high`; scripts de dados em `haiku/medium`; bancada em `sonnet/medium` | `checar-lua.mjs` e `checar-combate.mjs` com 0 erro; `node pregao/rodar-casos-pregao.mjs` e `node pregao/bancada-pregao.mjs --auto-teste` (só confere o falso) com `RESUMO erros=0`; `node pregao/checar-dados-pregao.mjs`; `git check-ignore` acha a regra |
| 2, régua | `Nucleo`, `Banco` (com o leitor do `Calibrado`), `Itens`, `Pedidos`, `Varredura`, `Escada`, `Livro`, `Correio`, `Sonda`, `Pontes`, `Visual`, `Janela`, `PregaoForever.lua`; `Teclas` só de navegação (`L`, `N`, `U`, `I`, `O`, `K`, `H`, visões) mais o `Y` de salvar da visão Session (chama `ReloadUI`, nenhuma função de ação), sem botões de ação; a parte de observação do `Ecos` (leilão criado, cancelado e comprado, origem `outside`); a conciliação do `Cofre`, em leitura; visões Session e Mine (a Mine ainda sem a seção `LIMITS` e sem `STAND DOWN`, que entram na onda 3 com o Cofre), painel do correio e cartão da sonda; `ler-pregao.mjs`, que também calcula fora do jogo as medidas da linha de base; `modo = "leitura"` | `haiku/medium` para `Itens`, `Escada`, `Banco`, `Correio`, `Pontes`, `Visual` e `ler-pregao.mjs`; `sonnet/medium` para `Nucleo`, `Pedidos`, `Varredura`, `Livro`, `Sonda`, `Janela`, `Teclas`, `Ecos`, `Cofre`, `PregaoForever.lua` e as telas | `--cenarios folego`, `--cenarios fatura` e `--cenarios dados` com `erros=0`; ida e volta da gramática no `ler-pregao.mjs`; a tela da bancada com os mesmos rótulos e seções do quadro aprovado |
| 3, vender | `Estimadores` e `Motor` (venda), `Estrategias` (vendas), `Cofre` (tetos, autorização, disjuntores), `Acoes` e `Ecos` de postar e cancelar (uma tarefa só: dividem o estado das máquinas), botões de ação do `Teclas`, `Alertas`, visões Next, Sell e Risk | `Acoes` com `Ecos`, e `Cofre`, em `sonnet/medium` com portão na sessão principal; `Alertas` em `haiku/medium`; o resto em `sonnet/medium` | `--cenarios venda`, `--cenarios postar`, `--cenarios cancelar`, `--cenarios operador` e os 10.000 roteiros com `erros=0`; telas iguais aos quadros |
| 4, piso | `Acoes` e `Ecos` de comprar, `Motor` (a conta do `piso`), `Sombra`, `Estrategias` (`piso`), em papel e depois micro | `sonnet/medium`, portão na sessão principal | `--cenarios comprar` e `--cenarios papel` com `erros=0` |
| 5, fase 2 | Anel de 48 fotos (ou de 32, se a S1 não liberar teto maior), `giro`, `Estimadores` e `Motor` da fase 2 (o teste de compra da seção 7.4), diferença de escadas com pares válidos, deriva, `vao` e `sniper` em papel, `replay-pregao.mjs`, `mesa.mjs`, mercado sintético | `sonnet/medium`; revisão do motor na sessão principal | replay igual ao papel do addon; estimadores contra o mercado sintético dentro da tolerância |
| 6, fase 3 | Seção 17.1; estratégia nova segue a seção 3.3 | a definir | a definir, por degrau |

**Portão do dono, medida e parada.**

| Onda | Portão do dono (jogo) | Pede | Mede | Para se | Duração estimada (hipótese) |
|---|---|---|---|---|---|
| 0 | S0 feita; depósito relido depois da manutenção de 17/11 | DD1a, DD1b, DD3, DD4, DD9, DD14; a DD6 só se ele quiser outro nome | depósito por duração, commodity ou item, teclas, tela, cotação | `/run` bloqueado mesmo depois do aviso "Allow custom scripts?", ou colar pelo acesso remoto não funciona: a leitura passa para o cartão da sonda, na onda 2 | 1 sessão do dono; a parte do depósito espera 17/11 |
| 1 | quadros aprovados | DD5 (com a S0 e os quadros) | nada no jogo | o dono reprova os quadros: redesenhar antes de codar | 1 a 2 dias |
| 2 | S1, S3, S4, S5, S9, S12 e S13 gravadas; três sessões de linha de base | DD2; no fim, DD12 | linha de base: três sessões em que o dono vende pela tela que já usa, em cobre por ação e por hora (são as da DD12); entradas de fora; cobre disponível abaixo do vendedor nas escadas lidas e fração dos verdes com referência forte, contas do agente sobre o banco lido; as fotos para a contagem de vãos e arremates, que é feita a partir da onda 3 | o banco não grava de modo nenhum: parar e investigar. A DD12 decide se as ondas 3 a 5 são construídas | 2 a 3 dias de código, mais 3 sessões de jogo |
| 3 | S2 positiva; S6, S7 e S10 em andamento; 10 postagens por tecla com Livro conciliado | DD1a, DD3, DD10 | líquido das vendas contra o que o vendedor pagaria; fração vendida por duração; segundos por ação | S2 negativa também no mouse: fica o modo leitura. Líquido abaixo do vendedor depois de 30 postagens: a regra de venda volta ao dono | 2 a 3 dias; os 10 desfechos por classe levam cerca de 3 dias de jogo |
| 4 | S8; uma compra completa com lote fechado no NPC e diferença zero no Livro | DD1b; aprovação do `piso` na DD3 | valor por tecla do `piso`; taxa de "já sumiu" | três varreduras de prova abaixo do dobro do tíquete, ou `piso` não aprovado: a estratégia fica desligada e a onda entrega só a máquina de compra e o papel | 1 a 2 dias, mais duas sessões limpas |
| 5 | S11; 30 sinais de papel conclusivos | DD13; para micro, o portão da seção 3.3 e a condição medida da seção 3.2 | realizado sobre previsto em papel; fração inconclusiva; subcontagem | razão abaixo do limiar: as compras para revenda não ligam. Menos de 3 sinais por sessão: a onda para | 3 a 4 dias de código; os 30 sinais em 10 grupos item-dia levam de 1 a 3 semanas de jogo |
| 6 | por degrau (seção 17.1) | decisão do dono com os números da régua | comparação pela régua | seção 17.1 | a definir |

A manutenção de 17/11 muda o depósito mínimo (base 1.7): a onda 0 relê o depósito depois dela. Entre as ondas 3 e 5 há uma espera que código não encurta: o diário precisa de desfechos reais. Se o número de interface do jogo mudar e o addon deixar de carregar, os leilões abertos seguem o curso do jogo e o dono recolhe pela tela da Blizzard.

**Linha do tempo.** O que libera cada degrau e o mais cedo possível. Toda data é hipótese, não compromisso: supõe uma onda a cada 1 a 4 dias e o dono jogando todo dia.

| Degrau | O que o libera | Mais cedo possível (hipótese) |
|---|---|---|
| Ler e decidir | O `LEIA-ME.md`; as seis decisões de antes do código | 16/11 |
| Onda 0 | Leilão aberto; comandos colados; depósito relido depois da manutenção | 16 a 18/11 |
| Régua em modo leitura | Ondas 1 e 2; quadros aprovados; DD5; `dev-link.ps1` com o jogo fechado | 20 a 22/11 |
| Construir ou adotar | Três sessões medidas pela régua (DD12) | 23 a 25/11 |
| Primeira postagem por tecla | Onda 3; S1 a S4; S2 positiva; DD1a; DD10 | 25 a 28/11 |
| Primeira compra por tecla | Onda 4; S6 a S8; duas sessões limpas; DD1b; `piso` aprovado | 28/11 a 2/12 |
| Compra para revenda em papel | Onda 5; S11; DD13 | começo de dezembro |
| Compra para revenda com ouro | Portão de papel (30 sinais conclusivos em 10 grupos item-dia) e a condição medida | não antes de meados de dezembro; depende do mercado |
| Escala | Os degraus da seção 17.1 | depende da banca (seção 3.4) |

**Roteiro do primeiro dia** (onda 0), em passos para o dono:

1. Ler o `LEIA-ME.md`.
2. Decidir os seis pontos da tabela de decisões (DD1a, DD1b, DD3, DD4, DD9, DD14). Quase todos têm padrão marcado; qual personagem compra e reunir ou não o ouro (DD4), e a duração e o lote das sobras (DD3), só o dono escolhe.
3. Anotar o ouro de cada personagem. Se decidir reunir (DD4), mandar o ouro ao negociador pelo correio do jogo, com o próprio clique; os itens a vender podem ir junto ou ser vendidos em cada personagem.
4. Se quiser, vender já pela tela da Blizzard o que a tabela "o que dá para fazer já" permite. O que paga depósito em item barato espera a manutenção de 17/11.
5. Abrir o leilão, colar o comando 1 do Apêndice A. O jogo pergunta "Allow custom scripts?": responder Yes e colar o mesmo comando outra vez.
6. Colar os comandos 2 a 16, um por vez, e guardar a resposta de cada um (captura de tela serve). O 16 pede o preparo descrito junto dele.
7. Abrir Options > Keybindings e anotar o que `B`, `C`, `H`, `I`, `K`, `L`, `M`, `N`, `O`, `P`, `U` e `Y` fazem hoje.
8. A partir do Acer, apertar `F1` no jogo e dizer se o jogo reagiu (H-37).
9. Depois da manutenção de 17/11, repetir os comandos 8, 11 e 12, que leem o depósito.
10. Ver a primeira versão dos quadros das telas e do teclado (`pesquisa/telas/`) e dizer o que mudar. A aprovação dos quadros no tamanho medido e o mapa de teclas (DD5) fecham no portão da onda 1.

**O que o dono já pode fazer pela tela da Blizzard, sem addon novo.** Cada linha é o que a fonte diz, não conselho do agente. Só as duas primeiras vêm da fonte que o dono já aprovou (base 4.5); as demais vêm de guias de fã ou comerciais, vários do beta, e pela regra de gameplay do projeto só valem depois que ele aprovar a fonte (DD3). O que ele vender assim, anotando preço, duração e desfecho, são as primeiras amostras da régua.

| # | O que fazer | Com o quê | Fonte | Situação |
|---|---|---|---|---|
| 1 | Vender no leilão os verdes bons. Em equipamento, igualar o menor preço, porque postar abaixo dele dá "Internal Auction Error" | Tela de venda da Blizzard | Base 4.5; base 1.11 | Fonte aprovada |
| 2 | Não vender todo o couro | | Base 4.5 | Fonte aprovada |
| 3 | Esperar a manutenção de 17/11 para postar item barato, e ler o depósito na aba de venda antes de postar: o depósito mínimo cai de 1 prata para 1 cobre | Tela de venda da Blizzard | Base 1.7; R5b 2f (a data aparece como 17 ou 18, conforme a fonte) | Fato do jogo, a conferir na hora |
| 4 | Vender cru o que os coletores trazem (minério, erva, couro), em vez de fabricar. Entre 7 e 12/11, Copper Ore subiu 41%, Copper Bar 93%, Peacebloom 80%, Earthroot 73% e Light Leather 19%, em preço listado | Tela da Blizzard; preço do Auctionator | R8b R4 e ficha 2 (guia de ouro, beta); R5b 2a e 2b (site que vende ouro; preço listado, não venda) | Pede aprovação (DD3) |
| 5 | Nunca listar abaixo do preço de vendedor, e conferir o leilão antes de vender ao NPC um item fabricado: a Blizzard baixou o preço de vendedor de armaduras fabricadas | Tooltip; Auctionator | R8b R8 e R9; base 6.3 | Pede aprovação (DD3) |
| 6 | Postar em lotes e rechecar a cada sessão; lote no tamanho da receita; leilão curto para o que gira e 24 horas só para item raro | Tela da Blizzard | R8b R7, R14 e R15 (editorial, sem dado) | Pede aprovação (DD3) |
| 7 | Guardar todo azul que vincula ao equipar para o leilão, em vez de vender ao NPC | | R8b R2 e R3 (guia de ouro, beta) | Pede aprovação (DD3) |
| 8 | Escolher a regra de preço em commodity. O texto do próprio jogo diz que não é preciso cobrir: o leilão postado depois, no mesmo preço, vende primeiro. As fontes de fã se dividem entre cobrir por 1 cobre (R8a F5), deixar folga real (R8b R6) e nenhuma das duas resolver (R8b R12) | | Strings, linha 1291; R8a ficha 2; R8b R6 e R12 | Decisão do dono (DD3) |
| 9 | Usar o Auctionator para o que ele já faz: o último mínimo visto de cerca de 6.600 itens. Se a tela de venda dele posta no Forever ninguém viu; postar pela tela da Blizzard | Auctionator 341 | Base 7.1 e 4.3 | Leitura, sem risco |
| 10 | Anotar o ouro de cada personagem e decidir se o reúne em quem vai vender. Não há banco de conta | Correio do jogo, à mão | Base 4.1 e 4.2 | Logística (DD4) |
| 11 | Colar os comandos de leitura do Apêndice A com o leilão aberto | Chat do jogo | Apêndice A | Leitura, custo zero |
| 12 | Desligar no ForeverGuide o compartilhamento das varreduras. Não dá ouro; é privacidade | Pelo `wtf-sv.ps1`, com o jogo fechado | Base 7.3 | Decisão do dono (DD2) |

Duas notas, que também são só o que as fontes dizem: um guia do beta desaconselha comprar no leilão na semana de lançamento (R8b R1), e o R5b 2b registra materiais de nível 30 a 45 caindo pela metade na semana; isso pesa contra comprar para revender agora, com ou sem addon.

### 17.1 Fase 3: a mesa em escala

A fase 3 não cria estratégia. Toda estratégia continua nascendo com licença 0, com fonte aprovada pelo dono, e subindo pelo portão da seção 3.3. O que a fase 3 acrescenta é a máquina que opera muitos itens e muito ouro sem mudar nenhuma regra da seção 1: cada ação sai de uma tecla do dono, uma por ação; nada age por timer ou evento; nada se configura no jogo. Os números são de partida, do `Config.lua`, e são proposta a aprovar.

**Por que ela existe.** Com 250 ouro de banca e um mercado que absorva 1 ouro por item por volta, uma volta são cerca de 125 itens e 250 ações (uma compra e uma postagem por item): 25 minutos no ritmo de 10 ações por minuto, e 625 teclas, numa volta que o correio limita a cerca de 60 minutos. A vigília de 150 chaves a cada 5 minutos pede 30 buscas por minuto. É nessa faixa que o ritmo e o foco das fases 1 e 2 passam a mandar (conta sobre os tetos do próprio design; a absorção é hipótese).

**O gargalo medido.** A cada sessão, a régua classifica o que limitou o resultado. A máquina só cresce no ponto que aperta.

| Gargalo | Como a régua o reconhece | O que fazer |
|---|---|---|
| Capital | banca livre média abaixo de 20% da banca, com linhas executáveis na fila | nada a construir: a escada está subindo |
| Sinal | banca livre acima de 50% e fila de compra vazia em mais da metade dos fôlegos | ampliar a vigília (mais chaves em foco) |
| Vazão | linhas executáveis que venceram sem tecla, com banca livre | subir o ritmo e ligar as esteiras |
| Giro | estoque com idade acima de 2 vezes o tempo de venda medido | rever preço e saída da estratégia, não a máquina |

**Degraus.** O degrau em vigor vem do `Config.lua`, escrito pelo agente depois do sim do dono. Dentro do jogo ele só desce.

| Degrau | Banca de referência | Chaves em foco | Ritmo (ações; buscas por minuto) | Abre com |
|---|---|---|---|---|
| 0 | abaixo de 15 ouro | 20 | 10; 30 | fases 1 e 2 |
| 1 | 15 a 60 ouro | 40 | 10; 30 | banca acima de 15 ouro em 3 aberturas seguidas; 5 sessões com conciliação exata |
| 2 | 60 a 250 ouro | 150 | 15; 60 | uma estratégia de compra em plena; gargalo de sinal ou de vazão em 3 de 5 sessões; portões de máquina cumpridos |
| 3 | acima de 250 ouro | até 500 | 20; até 100 | absorção medida por item; tempo de `/reload` medido com o banco do degrau; gargalo de sinal ou de vazão em 3 de 5 sessões |

**Vigília.** O foco passa a ter três anéis. Quente: chaves com posição, leilão próprio ou ordem de papel aberta, relidas em todo ciclo. Morno: candidatas da triagem, em rodízio. Frio: só o resumo. A cadência de cada chave quente é o intervalo do R9 2.2, calculado da taxa de venda medida, dentro do orçamento de buscas. O gatilho é o da decisão DD13. A linha de estado mostra `WATCH 84 keys   cycle 4m 10s   22 of 30 searches a min`. Sem tecla do dono dentro de `T_pulso`, a vigília para e a tela diz `PAUSED - press L`.

**Carteira.** O Cofre ganha a tabela de posições: por item, quantidade, custo, valor de saída conservador, idade e teto. Entra o teto por categoria (R9 7.3), porque patch e abertura de raide atingem a categoria inteira. Lote com idade acima de 2 vezes o tempo de venda medido vira linha de conselho (`REPRICE`, `LET EXPIRE` ou `VENDOR`). `REPRICE` usa as teclas de cancelar e de postar que já existem; `LET EXPIRE` e `VENDOR` não têm tecla (o addon marca o item e o dono age). Nada é liquidado sozinho. Esses conselhos só entram com fonte aprovada (DD3).

**Esteira de postagem e de cancelamento.** A lista de lotes a postar, ou de leilões a cancelar, com um contador (`POST 12 of 37`). Uma tecla por lote: a linha concluída sai, a seguinte sobe para a posição do cursor e `T_ver` recomeça (seção 8.2). Cada linha passa pelo Cofre. A esteira para no primeiro `FAILED` ou `UNKNOWN`. G1 e G2 valem por item.

**Reposição.** Quando um lote vende, o item volta como candidato com o motivo `RESTOCK`. Só vira linha de compra se o sinal passar de novo no teste da seção 7.4, com foto fresca. Não existe recompra automática.

**Conversão** (R8a ficha 6; R9 5.5). `Receitas.lua`, só receita que o personagem logado conhece e produto que não vincula. O custo recursivo é ideia pública (base 5.8) e roda na mesa. Nasce em papel; o rendimento de cada receita é medido em 10 execuções do dono antes de qualquer sinal.

**Hora e dia** (R8b ficha 1; base 6.5). Com três semanas do campo `blocos`, a mesa mostra o fator de cada bloco de 4 horas com intervalo de confiança. Só aparece na tela, como uma linha no conselho de postagem, o bloco cujo intervalo exclui 1. Não vira ordem de compra sem fonte aprovada.

**Preço de liquidação e identidade.** O `W*` com tabela de probabilidade de venda (R9 4.1) e a assinatura numérica de vendedor (DD15) só entram aqui, por decisão do dono.

**Dados externos e varredura completa.** Decisão DD8 para a API de dados. `ReplicateItems` continua proibida até um passo de sonda próprio (responde? em quanto tempo? com que intervalo? base 2.5, 11.4) e uma decisão do dono.

**Banco.** O tamanho cresce com as chaves com anel. Dentro da sessão, as fotos viram agregados em `blocos` e `giro`, para o anel girar sem perder a medida. As linhas abaixo são conta sobre a foto média medida (385 bytes na fase 1 e 360 na fase 2); o teto de cada degrau só vale depois de medido o `/reload` com aquele tamanho (H-19). A mesa na opção B passa a ser o padrão a partir do degrau 2.

| Degrau | Chaves com anel | Fotos por chave | `fotos` | `blocos` e `giro` | Teto do banco |
|---|---|---|---|---|---|
| 0 e 1 | 60 | 16 na fase 1; 48 na fase 2 (seção 6.2) | cerca de 0,37 MB; 1,05 MB | cerca de 160 KB | 3 MB |
| 2 | 150 | 16 | cerca de 0,9 MB | cerca de 400 KB | 3 MB, ou 5 MB se medido |
| 3 | 500 | 8 | cerca de 1,5 MB | cerca de 1,3 MB | a medir |

**Portões de máquina.** São separados das licenças de estratégia. Cada subida é uma linha no `Config.lua`, com data.

| O que sobe | Exige |
|---|---|
| Ações por minuto, de 10 para 15 e para 20 | 5 sessões sem INCERTO pendente; nenhum evento `AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED`; ação desfeita em menos de 60 s (postar e cancelar o mesmo lote) abaixo de 1% das ações |
| Buscas por minuto, de 30 para 60 e para 100 | a S4 repetida no novo ritmo, por 10 minutos, sem `TRAVADO` e sem mensagem descartada; nunca acima do limite documentado (base 2.2) |
| Chaves em foco | banco dentro do teto do degrau; `/reload` medido; ciclo da vigília dentro do intervalo pedido pelas chaves quentes |
| Gatilho da vigília | só pela decisão DD13 |

**Para se.** Três sessões no degrau com cobre por hora de trading abaixo do que o dono declara ganhar jogando: não sobe de degrau. Taxa de "já sumiu" acima de 70% com a vigília do degrau 2: a vigília não paga e o foco volta a 40 chaves. A régua mostrar que uma ferramenta pronta rende mais por ação do que a fila própria: vale a decisão DD12.

**O que a fase 3 continua recusando.** Tudo o que a seção 15 recusa. Reset, formação de mercado, lance e casa neutra seguem fora enquanto não houver fonte aprovada.

## 18. Decisões do dono

Em todas, a opção recomendada é a que o agente grava no `Config.lua` se o dono responder só "pode seguir", e a outra continua possível sem reescrever o addon. Antes da resposta vale o valor de partida do Apêndice B, que é sempre o mais fechado: licença 0, e regra de preço de commodity sem valor, com a linha em `PICK RULE`. A coluna "Quando" separa o que precisa de resposta antes do código do que pode esperar. O `LEIA-ME.md` traz, em linguagem do dono, a tabela das seis decisões de antes do código e uma lista das demais.

| # | Decisão e opções | Recomendação (padrão) | Como a outra opção fica possível | Quando |
|---|---|---|---|---|
| DD1a | Postar e cancelar por tecla, sim ou não. Em 2026-11-06 ele proibiu, no outro addon, funções que compram ou gastam por código (base 4.6). | Sim, só aqui, uma tecla por ação, com os tetos e o checador | `modo = "leitura"`: fila e régua, e ele age pela tela da Blizzard | antes do código |
| DD1b | Comprar por tecla: sim, só papel, ou não. Opção extra, a micro-sonda: depois de 30 sinais de papel, lotes reais de até 2% da banca por item, para medir a saída pela fatura | Sim, em dois tempos, depois da sonda, só nas estratégias que ele ligar. A micro-sonda se decide quando houver os 30 sinais | Licenças de compra limitadas a papel | antes do código |
| DD1c | Correio: o addon só lê; uma tecla por carta; ou tecla no botão da Blizzard. Vendedor NPC: vender por tecla, uma pilha por tecla, ou não | Correio: só ler; fatura sem abrir a carta e binding em botão da Blizzard são incógnitas (H-11). NPC: não; custa um clique de venda por pilha no `piso` | Tecla por carta ou venda ao NPC por tecla exigem tirar nomes da regra 10: decisão posterior, com a sonda na mão | pode esperar |
| DD2 | Coexistência: Auctionator e ForeverGuide já ocupam o papel de leilão (base 4.12) | Manter o Auctionator (tooltip, segunda opinião) e tratar o PregaoForever como papel novo, de mesa de operação. Desligar no ForeverGuide o compartilhamento de varreduras (base 7.3) pelo `wtf-sv.ps1`, com o jogo fechado, depois do ok do dono; nunca pelo menu do jogo. Se a S4 mostrar disputa de throttle, desligar do mesmo jeito a varredura automática do Auctionator. Rever no fim da onda 4 | `Pontes.lua` desliga sozinho se o addon faltar | onda 2 |
| DD3 | Fontes e regras de venda e de compra, por estratégia: (1) ligar `venda_verdes`; (2) aprovar ou não as recomendações do R8b para `venda_sobras`; (3) regra de preço por classe, entre `igualar` (fonte: o texto do próprio cliente, strings linha 1291), `cobrir` (guia de fã, R8a F5) e `folga` (guia de fã, R8b R6; outro trecho do mesmo guia, R12, diz que nenhuma das duas resolve em commodity); (4) duração e tamanho do lote por classe (R8b R15, R14); (5) aprovar o `piso`, que não tem fonte, ou indicar fonte; (6) a ordem das fontes de ganho da seção 0; (7) mais tarde, se a regra de cancelar em sombra vira conselho | (1) Ligar: é a fonte já aprovada. (3) `igualar` para equipamento e commodity, citando o texto do cliente; a S10 confere no Forever. (5) Deixar o `piso` só medindo e decidir na onda 4. Os itens (2) e (4) são dele, sem recomendação: enquanto a fonte das sobras, a duração e o lote não estiverem escolhidos, a linha de commodity mostra `PICK RULE`, sem tecla, mesmo com `igualar` gravada | Cada licença e cada regra é uma linha do `Config.lua` | antes do código (1, 2, 3, 4); onda 4 (5); fase 2 (7) |
| DD4 | Negociador, banca e piso: (a) qual personagem compra; (b) reunir ou não o ouro nele, pelo correio do jogo, com o próprio clique; (c) piso pessoal | (a) Um só negociador para comprar; postar e cancelar valem em qualquer personagem. Qual personagem é escolha de jogo e fica com ele. (b) Sem recomendação: reunido, a banca do negociador é de cerca de 4 ouro; sem reunir, de cerca de 27 prata, e cada personagem vende com o seu Cofre. (c) 1 ouro no negociador, com a nota de que isso deixa parado cerca de um quinto do capital; zero é opção | `Config.negociador` e `Config.piso_pessoal` | antes do código |
| DD5 | Teclas: o mapa da seção 11.2, outro mapa, e se `P` posta num tempo ou em dois | O mapa proposto, depois de a S0 conferir o que cada tecla faz hoje e de ele ver o desenho. `P` em dois tempos até lá | Todas as teclas vêm do `Config.lua` | depois da S0 e dos quadros |
| DD6 | Nome: PregaoForever ou NichoForever | PregaoForever: o nicho seria um módulo, não o produto | Trocar antes da onda 1 não custa nada | antes da onda 1; sem resposta, vale PregaoForever |
| DD7 | Mesa externa: A, B ou C (seção 12) | A agora; B na fase 2; C só se ele pedir. A opção C roda com o jogo aberto, como os aplicativos companheiros conhecidos, sem posição oficial da Blizzard | Os contratos são os mesmos nas três | pode esperar |
| DD8 | Credencial da API oficial de dados (base 5.4) | Não agora; ler os termos na íntegra antes de qualquer chamada; reavaliar na fase 3. Se aprovada, o dado fica em arquivo separado, apagado com 30 dias, fora do git, e nada dele vai ao addon | A mesa aceita fotos de outra origem como arquivo à parte | fase 3 |
| DD9 | Acesso remoto e os termos (base 8.3) | Perguntar ao suporte por escrito antes de sessões longas; a comparação de ferramentas está no R10a. Preparo fora do jogo: plano de energia do Avell sem suspensão na tomada durante as sessões de leilão, e o teste da incógnita 5 do R10a | Fora do addon | antes do código |
| DD10 | Números de política, todos proposta do projeto, sem fonte de economia: tetos duros e de partida e pisos absolutos de depósito (seção 9.2); antiguerra, parede e limiar da deriva (seção 9.3); ordem da fila e tíquete (seção 7.5); margem mínima `μ_min` (seção 7.4); limiar da razão do portão (seção 3.3); ritmo de partida; disjuntores e dia de risco (seção 9.4). Vale para tudo o que o Apêndice B marca com DD10. Opção: só comprar para revenda com ouro depois de 15 ouro de banca | Os valores propostos. O dono aprova, troca ou manda buscar fonte. Limiar do portão em 0,5, sabendo que 0,5 reprova metade das estratégias que entregam exatamente 0,5. Sem a espera dos 15 ouro: no cenário central da seção 3.4 ela atrasa os 60 ouro de 18 para 23 dias, e no pesado de 6 para 15 | Linhas do `Config.lua`, dentro dos tetos duros; mudar teto duro é editar `Tetos.lua`, com registro | antes da onda 3 |
| DD11 | Quantidade maior que 1 numa tecla, em item (multisell) | 1 por tecla: uma chamada criaria vários leilões e vários ecos (H-15), e a máquina de postar não trata isso | `Config.venda.lote_item`, com uma máquina de multisell nova e passo de sonda | pode esperar |
| DD12 | Construir a mão, adotar ferramenta pronta ou ficar em régua e fila. Na fase 3: subir de degrau (seção 17.1), adotar ou parar | Decidir com número no fim da onda 2: três sessões pela tela da Blizzard contra, se ele quiser testá-la, três por uma ferramenta pronta (seção 3.1) | A régua mede qualquer ferramenta; em `modo = "leitura"` o addon não tem mão | fim da onda 2 |
| DD13 | Gatilho da varredura: (a) uma tecla por fôlego; (b) vigília com presença, renovada por qualquer tecla do terminal enquanto a última tiver até `T_pulso`; (c) contínuo sem presença | (a) nas ondas 2 a 4. (b) a partir da fase 2, se a H-31 se confirmar: sem ela o modo papel só fecha lotes curtos dentro da sessão. (c) recusado | `Config.folego.gatilho` e `T_pulso` (90 s, nunca acima de 240 s) | onda 5 |
| DD14 | Reservas: o que não vai à venda porque alimenta as profissões dos próprios personagens | O agente propõe a lista por personagem a partir dos roteiros de profissão que o dono aprovou, e o dono aprova. Sem aprovação, toda sobra de coleta fica em `KEPT`, com o motivo na linha | `Config.reservas[nome]` | antes do código |
| DD15 | Assinatura numérica de vendedor: um número de 16 bits calculado do nome com um sal sorteado a cada sessão e nunca gravado, usado só para reconhecer o mesmo vendedor entre fotos da sessão. Cerca de 55 personagens do reino caem em cada valor, então o número não identifica ninguém | Não ligar agora. Muda a regra 20 e depende de os nomes virem preenchidos (H-13). Recupera o casamento de repostagem em item e o tempo de reação por rival, que só a fase 3 usa | Campo novo no `Config.lua` e na foto de item | fase 3 |

## 19. Riscos e o que derrubaria o design

1. **A tecla não vale.** A mão depende da H-01, que ninguém testou no Forever (base 2.13, 11.1). *Derruba a mão*: S2 negativa também com o clique do mouse. Sobram a fila e a régua.
2. **Pouco ouro por hora.** Com cerca de 4 ouro de banca o ganho é de pratas, e o piso provavelmente já está varrido por quem tem ferramenta (R6a). *Derruba a compra*: três sessões com cobre por hora abaixo do que o dono declara ganhar jogando. O addon continua como assistente de venda e livro-caixa.
3. **As ferramentas prontas podem render mais.** *Derruba a mão*: na comparação da DD12, no fim da onda 2, uma ferramenta pronta render mais cobre por ação do que a tela da Blizzard em três sessões, sem ferir nenhuma regra do dono. Aí o projeto fica em régua e fila, e as ondas 3 a 5 não são construídas.
4. **A conciliação pode travar ou errar calada.** Atraso do correio, devoluções e entrega de compra são incógnitas (base 11.6, 11.10), e o negociador é um personagem que joga. *Derruba*: três sessões seguidas com dinheiro sem explicação dentro da janela de leilão, depois da sonda completa.
5. **Evidência de papel que engana.** A venda inferida tem viés nos dois sentidos e o papel depende da presença do dono (seção 3.3). As regras de par válido, a exposição observada, a série densa (S11) e a micro-sonda (DD1b) existem para ver o erro antes de gastar ouro. *Derruba a fase 2*: realizado em micro divergindo do papel por mais de 2 vezes, em qualquer direção, ou fração inconclusiva tão alta que o portão não fecha em três semanas.
6. **O chão muda.** Depósito novo em 17/11 (base 1.7), erros ativos (base 1.11), hotfix de preço de vendedor (base 6.3), throttle desconhecido (base 2.14), número de interface que muda e deixa o addon sem carregar, e um bloqueio de economia por engano, que congelaria leilão e correio com capital em trânsito (base 1.10). Cada mudança custa uma rodada de sonda; o alarme da seção 7.6 avisa quando um número medido deixou de valer.
7. **O dono operar por fora por frustração.** Guardas demais levam a agir pela tela da Blizzard, onde nenhuma vale. Por isso a foto para postar vale 5 minutos e não 30 segundos, a esteira sobe a linha seguinte para o cursor, `P` pode virar um tempo só na DD5, e a régua mede também o que é feito por fora.
8. **A cadência do dono não sustenta a inferência.** Com uma tecla por fôlego, a mesma chave é relida a cada vários minutos e só nas horas de sessão. *Derruba a compra para revenda por inferência*: a S11 mostrar que a cadência real recupera menos da metade das vendas, com a opção (b) da DD13 negada. Sobra a micro-sonda.

**O que derrubaria o design inteiro:** o banco não gravar de modo nenhum (a base 3.9 já mostra que grava); o dono negar DD1a e DD1b e também não querer um conselheiro sem tecla; a consulta resumida ser tão limitada que um fôlego por sessão seja o máximo; ou uma resposta do suporte contrária ao acesso remoto, que derruba a operação, não o addon.

## Apêndice A: a sonda

Cada passo é leitura ou uma ação barata com tecla do dono. O que paga depósito espera a manutenção de 17/11. Os passos rodam na onda indicada, não na ordem dos números. Os passos com ação passam pelo Cofre na classe `sonda`, que só vale com o cartão da sonda aberto: postagem com depósito de até 30 cobre, compra de até 20 cobre por ordem, só as ordens que a coluna Custo do passo prevê, uma por tecla (seção 9.2). Sem essa classe não haveria caminho, porque todas as licenças nascem em 0. A S2 e a S6 dependem da DD1a em sim; a S8, que compra, da DD1b em sim.

| # | Onda | Mede | Como | Custo | O que decide |
|---|---|---|---|---|---|
| S0 | 0 | Build, durações, cobre, commodity por item da bolsa, depósito por duração, a que ação cada tecla está ligada, resolução e escala, duração da cotação, uso do leilão pelo personagem (H-04, H-18, H-23, H-36, H-37, H-39) | Os 16 comandos abaixo, colados pelo dono; Options > Keybindings; `F1` apertado a partir do Acer | 15 minutos | Caminho de postagem; mapa de teclas (DD5); tamanho da janela |
| S1 | 2 | O banco grava no `/reload`; tempo com 1, 3 e 5 MB; `ReloadUI` por botão; relógio fino; se o `/reload` fecha a casa; fator do medidor; estilo do gravador; cópia `.bak`; carga de 5 MB no formato real (H-03, H-19, H-20, H-34, H-35) | Carimbo de `GetServerTime` no clique e em `ADDON_LOADED`; conferir o arquivo. O enchimento vai na chave `sonda.lastro`, fora da poda, e é apagado no `/reload` seguinte | 4 reloads | Tecla de salvar; teto do banco |
| S2 | 3 | A tecla satisfaz a ação; a soltura gera um clique só e tecla segurada não repete, local e remoto; `PostItem` da bolsa; os eventos entre a tecla e o eco de um item e de uma commodity; abrir e fechar o leilão em combate (H-01, H-02, H-15) | Postar 1 item e 1 commodity baratos (`P`, `Y`) e cancelar (`C`, `Y`), gravando todos os eventos; ouvir `ADDON_ACTION_BLOCKED` e `ADDON_ACTION_FORBIDDEN`; segurar uma tecla de navegação por 3 s. Se a soltura não valer, repetir com `LeftButtonDown`. Se a tecla falhar, fechar e reabrir o leilão (a ação ficou INCERTO) e repetir com o mouse. Abrir e fechar o leilão em combate e anotar o que acontece com as teclas | 2 depósitos | Tecla, botões para o mouse ou leitura |
| S3 | 2 | Chave de um verde com sufixo; `isCommodity` das chaves; as duas escadas de um equipamento, a da chave e a do `itemID` (H-04, H-29) | Passivo, no primeiro fôlego | zero | Referência de equipamento |
| S4 | 2 | Tempo e pedidos do resumo; repetição; cadência do throttle; convívio (H-05 a H-08) | 5 fôlegos cronometrados: com e sem o Auctionator carregado; com a aba Comprar e com a aba Leilões da tela da Blizzard | zero | Orçamento do fôlego; `ritmo.buscas_min` |
| S5 | 2 | `owners`, `totalNumberOfOwners` e `timeLeftSeconds` preenchidos; ordem e completude da primeira página; unidades próprias marcadas (H-13, H-28) | Leitura de 20 escadas | zero | Referência forte; marca `frente` |
| S6 | 3 | Depósito cobrado, corte, devolução em cada desfecho, destino do item cancelado, venda parcial de lote (H-09, H-10, H-33) | Postagens ao preço da frente até 3 faturas de venda; um leilão de 2 horas a 3 vezes a referência, para expirar dentro da faixa de preço; um cancelado ao preço da frente. Sem comprador combinado: fecha com as amostras que houver | até 5 depósitos | Custos da seção 7 |
| S7 | 3 | Fatura lida antes de abrir a carta, em duas variantes; atraso do correio; tempo até o ouro de um leilão vendido (H-11, H-12, H-27) | Em ordem: `GetInboxInvoiceInfo(i)` direto; depois `GetInboxText(i)` seguido da fatura; gravar `wasRead` e `textCreated` antes e depois de cada um; ler `etaHour` e `etaMin` da carta pendente e o `timeLeftSeconds` do leilão vendido | zero | Conciliação do correio |
| S8 | 4 | Compra: argumentos, duração da cotação, ecos, entrega, momento do débito, unidades da conta (H-17, H-18, H-10, H-32) | Uma commodity e um item de até 20 cobre cada. A primeira cotação usa três argumentos; se chegar, repetir com dois e gravar a diferença. Gravar também `COMMODITY_PURCHASED` e `AUCTION_HOUSE_SHOW_COMMODITY_WON_NOTIFICATION`. Com unidades de outro personagem do dono na escada, ver se a compra as pula | até 40 cobre | Viabilidade da compra por tecla |
| S9 | 2 | Eventos de ação feita por fora chegam ao addon (H-25) | O dono posta e cancela pela tela da Blizzard | 1 depósito | Linha de base da régua |
| S10 | 3 em diante | Ordem entre preços iguais (H-14) | Passivo: quantidade própria contra a do degrau em fotos seguidas. Sem comprador combinado | zero | Regra de preço (DD3) |
| S11 | 5 (pode rodar desde a onda 2) | Quanto a cadência real do dono recupera das vendas; se consulta mexe na marca de ausente (H-31) | Série densa de 30 minutos em 5 chaves. O passo não decide a DD13: com um sim do dono só para ele, registrado em `estado.md`, a vigília com presença fica ligada enquanto o cartão da sonda estiver aberto (`folego.gatilho` continua `tecla`; quem libera é a classe `sonda`); sem esse sim, o dono aperta `L` a cada ciclo e a medida da H-31 espera a DD13. A mesa subamostra a série na cadência real. O dono anota se a marca de ausente apareceu | zero | `Δ_max`; opção (b) da DD13; portão de papel |
| S12 | 2 | O addon enxerga o foco numa caixa de texto (H-26) | Com o foco na caixa de busca da Blizzard e na do Auctionator, apertar `N` e ver a faixa | zero | Faixa `Keys paused` |
| S13 | 2 | Arquivo quebrado (H-34) | O agente põe um erro de sintaxe no `Config.lua`, o dono dá `/reload` e anota se os arquivos seguintes carregaram e se a faixa `CONFIG ERROR` apareceu; o agente restaura. Com o jogo fechado, pelo script do projeto e com backup, troca-se o arquivo de SavedVariables por uma cópia truncada e vê-se se o banco carrega `nil` e se o marcador por personagem o protege | 2 reloads | Defesas das seções 6.3 e 12 |

Ficam sem medida pelo addon: `ReplicateItems` (só na fase 3, com passo próprio), a visão entre facções (base 11.4, 11.8) e os tempos de ausência, que o dono anota (H-24).

### Comandos da S0, prontos para colar

Com o leilão aberto. No primeiro comando o jogo pergunta "Allow custom scripts?": responder Yes e colar o mesmo comando outra vez. Só depois disso vale concluir que `/run` está bloqueado. Todos têm até 245 caracteres, são só leitura (nenhum compra, posta, cancela nem consulta o servidor do leilão) e usam nomes que existem na lista oficial da API (Apêndice D). Um comando por linha.

1. Se a tela de leilão da Blizzard carregou e qual é o build do cliente (versão, número, data, interface).

```
/dump C_AddOns.IsAddOnLoaded("Blizzard_AuctionHouseUI"), GetBuildInfo()
```

2. `true` = o leilão usa a família Mainline; quantos grupos de filtro; quantas categorias.

```
/run print(AUCTION_HOUSE_FILTER_STRINGS[Enum.AuctionHouseFilter.CurrentExpansionOnly] ~= nil, #C_AuctionHouse.GetFilterGroups(), #AuctionCategories)
```

3. A árvore de categorias do Forever: índice, nome e número de subcategorias.

```
/run for i,c in ipairs(AuctionCategories) do print(i,c.name,c.subCategories and #c.subCategories or 0) end
```

4. O texto das três durações e o índice de duração gravado (1, 2 ou 3).

```
/run print(AUCTION_DURATION_ONE,";",AUCTION_DURATION_TWO,";",AUCTION_DURATION_THREE,";",GetCVar("auctionHouseDurationDropdown"))
```

5. As quatro faixas de tempo restante, em segundos (mínimo e máximo), e o texto da primeira e da última.

```
/run for i=0,3 do print(i,C_AuctionHouse.GetTimeLeftBandInfo(i)) end print(AUCTION_TIME_LEFT1_DETAIL,AUCTION_TIME_LEFT4_DETAIL)
```

6. Nesta ordem: o leilão aceita cobre (define o tick); preço automático; favoritos disponíveis; favoritos no máximo; throttle pronto.

```
/run print(C_AuctionHouse.SupportsCopperValues(),C_AuctionHouse.ShouldAutoPopulatePrice(),C_AuctionHouse.FavoritesAreAvailable(),C_AuctionHouse.HasMaxFavorites(),C_AuctionHouse.IsThrottledMessageSystemReady())
```

7. Cada item das bolsas: bolsa, slot, nome e tipo no leilão (1 = item, 2 = commodity, 0 = sem dados). Responde à H-04. Pode imprimir muitas linhas.

```
/run for b=0,4 do for s=1,C_Container.GetContainerNumSlots(b) do local l=ItemLocation:CreateFromBagAndSlot(b,s) if C_Item.DoesItemExist(l) then print(b,s,C_Item.GetItemName(l),C_AuctionHouse.GetItemCommodityStatus(l)) end end end
```

8. Depósito do item da mochila, slot 1, nas três durações: para cada duração, uma linha da função de item e uma da função de commodity. `true` e um número = depósito em cobre; `true nil` = a função não devolveu depósito para esse item; `false` = erro, com o texto. Para outro slot, trocar o `(0,1)`. Com um item que não é commodity no slot, responde também à H-39.

```
/run local A,l=C_AuctionHouse,ItemLocation:CreateFromBagAndSlot(0,1) if C_Item.DoesItemExist(l) then for d=1,3 do print(d,pcall(A.CalculateItemDeposit,l,d,1)) print(d,pcall(A.CalculateCommodityDeposit,C_Item.GetItemID(l),d,1)) end end
```

9. Regras de jogo: scripts desligados, addons desligados, preset (0 Classic, 1 Enhanced), Hardcore, Self-Found permitido.

```
/run print(C_GameRules.IsGameRuleActive(Enum.GameRule.UserScriptsDisabled),C_GameRules.IsGameRuleActive(Enum.GameRule.UserAddonsDisabled),C_GameRules.GetForeverExperiencePreset(),C_GameRules.IsHardcoreActive(),C_GameRules.IsSelfFoundAllowed())
```

10. A que ação cada tecla do mapa proposto está ligada hoje (linha com a tecla e nada depois = livre). É o que decide a DD5.

```
/run for _,k in ipairs({"B","C","H","I","K","L","M","N","O","P","U","Y","F1","F2","F3","F4","F5"}) do print(k,GetBindingAction(k)) end
```

11. Depósito de 24 horas, 1 unidade, de cada item da mochila pela função de item: slot, `true` e o depósito em cobre.

```
/run local A=C_AuctionHouse for s=1,C_Container.GetContainerNumSlots(0) do local l=ItemLocation:CreateFromBagAndSlot(0,s) if C_Item.DoesItemExist(l) then print(s,pcall(A.CalculateItemDeposit,l,3,1)) end end
```

12. Depósito de 24 horas da pilha inteira de cada item da mochila pela função de commodity: slot, `true` e o depósito em cobre.

```
/run local A,I=C_AuctionHouse,C_Item for s=1,C_Container.GetContainerNumSlots(0) do local l=ItemLocation:CreateFromBagAndSlot(0,s) if I.DoesItemExist(l) then print(s,pcall(A.CalculateCommodityDeposit,I.GetItemID(l),3,I.GetStackCount(l))) end end
```

13. Chave de leilão do item da mochila, slot 1 (`itemID`, nível, sufixo) e o preço de vendedor lido do cliente. Num verde com sufixo, responde à segunda parte da H-04; serve também à conferência de 20 itens da seção 13.

```
/run local l=ItemLocation:CreateFromBagAndSlot(0,1) if C_Item.DoesItemExist(l) then local k=C_AuctionHouse.GetItemKeyFromItem(l) print(k.itemID,k.itemLevel,k.itemSuffix,select(11,C_Item.GetItemInfo(C_Item.GetItemLink(l)))) end
```

14. Os três textos do cliente em que o design se apoia, no build do jogo (o arquivo lido é do build 70532): o aviso de postagem, o erro de postagem e a dica sobre igualar o preço.

```
/run print(CONFIRM_AUCTION_POSTING_TEXT) print(AUCTION_POSTING_ERROR_TEXT) print(AUCTION_HOUSE_UNDERCUT_TUTORIAL)
```

15. Largura e altura da interface, escala e tamanho físico da tela. Decide o tamanho da janela (H-36).

```
/run print(GetScreenWidth(),GetScreenHeight(),UIParent:GetEffectiveScale(),GetPhysicalScreenSize())
```

16. Segundos de validade de uma cotação. Antes de colar, abrir pela tela da Blizzard o diálogo de compra de uma commodity; depois de ler o número, cancelar o diálogo pela própria tela, sem comprar. Sem o diálogo aberto, o comando imprime 0.

```
/run print(C_AuctionHouse.GetQuoteDurationRemaining())
```

Se colar pelo acesso remoto não funcionar, a leitura passa para o cartão da sonda dentro do addon, na onda 2.

## Apêndice B: tabela de parâmetros

Todos vivem no `Config.lua` (escolha do dono ou do projeto) ou no `Calibrado.lua` (medidos). O `Calibrado.lua` valida cada valor pela faixa desta tabela; fora dela vale o de partida. Os parâmetros lidos do jogo (corte, devoluções, atraso do correio, cadência) estão na seção 7.6, com as faixas de sanidade: o addon os adota sozinho, em `calib`, sem passar pelo `Calibrado.lua`. Os tetos de dinheiro estão na seção 9.2. "DD" na última coluna quer dizer que o número é política e espera o dono.

**Modo, banca e pessoas** (campos do `Config.lua`)

| Parâmetro | Partida | Unidade | Faixa | Como calibrar ou quem decide |
|---|---|---|---|---|
| `modo` | `leitura` na onda 2; `vivo` se a DD1a for sim | texto | `leitura`, `papel`, `vivo` | DD1a |
| `negociador` | sem valor | nome de personagem | os quatro do dono | DD4 |
| `piso_pessoal[nome]` | 1 ouro no negociador; 0 nos outros | cobre | 0 em diante | DD4 |
| `cofre.piso_teto_deposito`; `cofre.piso_teto_perdido` | 20 prata; 8 prata (os valores de `Tetos.lua`) | cobre | de 0 até o valor de `Tetos.lua`: o `Config.lua` só baixa | DD10; subir é editar `Tetos.lua`, com registro |
| `reservas[nome]` | vazia: toda sobra de coleta em `KEPT` | lista de itens | | DD14 |
| `licencas[estrategia]`, com `aprovadaEm` | 0 em todas | 0 a 3 | | DD3; portões da seção 3.3 |
| `destravas[disjuntor]` | vazio | `seq` | | sessão do agente, com o sim do dono |
| `folego.gatilho` | `tecla` | texto | `tecla`, `presenca` | DD13 |

**Teclas e guardas**

| Parâmetro | Partida | Unidade | Faixa | Como calibrar ou quem decide |
|---|---|---|---|---|
| `teclas` (mapa) | o da seção 11.2 | | teclas livres na S0 | DD5 |
| `T_ver` | 1 mais a latência | segundos | 0,5 a 3 | erros de dedo medidos em `modo = "papel"` |
| `remoto.latencia_ms` | 150 | milissegundos | 0 a 1.000 | o dono lê no overlay do acesso remoto |
| Repetição ignorada | 400 | milissegundos | 200 a 1.000 | S2 (tecla segurada); cenário de tecla presa |
| Rajada | 6 teclas recebidas em 2 s | teclas; segundos | 4 a 10; 1 a 5 | disparos falsos por sessão |
| Validade do bilhete | 20 | segundos | 10 a 60 | bilhetes vencidos por sessão |
| Prazo da cotação (estado COTANDO) | 5 | segundos | 2 a 15 | S8 |
| Corte da confirmação | menos de 5 s de cotação | segundos | 3 a 15 | S8 (duração da cotação) |
| Prazo do eco; prazo de consulta | 10; 10 | segundos | 3 a 30 | S2, S4, S8: o dobro do maior tempo medido |
| Throttle travado | 30 | segundos | 10 a 120 | S4 |
| Duração do alerta | 10 | segundos | 5 a 30 | pedido do dono |

**Idades de foto**

| Parâmetro | Partida | Unidade | Faixa | Como calibrar ou quem decide |
|---|---|---|---|---|
| `A_exec`, idade máxima para comprar | 30 | segundos | 5 a 120 | taxa de "já sumiu" por tempo entre a foto e a tecla |
| `A_post` (`post.idade_max`), idade máxima para postar | 5 | minutos | 0,5 a 10 | fração de postagens cobertas em menos de 10 minutos |
| Idade para cancelar | a foto do próprio leilão no último fôlego | | | |
| Resumo vencido | 10 | minutos | 2 a 30 | S4 (custo do resumo) |

**Fôlego, foco e ritmo**

| Parâmetro | Partida | Unidade | Faixa | Como calibrar ou quem decide |
|---|---|---|---|---|
| `folego.max_buscas` | 20 | buscas por ciclo | 5 a 100 nas fases 1 e 2; na fase 3 acompanha as chaves em foco do degrau (40, 150, até 500) | S4; degraus da seção 17.1 |
| `folego.max_s` | 60 | segundos por ciclo | 20 a 180 nas fases 1 e 2; na fase 3, o ciclo da vigília do degrau. Em qualquer fase o ciclo também é cortado quando passam `T_pulso` segundos da última tecla | S4; degraus da seção 17.1 |
| `T_pulso` | 90 | segundos | 30 a 240 | DD13 |
| `ritmo.buscas_min` | 30 | buscas por minuto | 5 a 100; máximo igual ao sustentado na S4 sem mensagem descartada | DD10 (partida); S4 e portão da seção 17.1 (subida) |
| `ritmo.acoes_min` | 10 | verbos concluídos por minuto | 1 em diante; o máximo é o degrau que o portão de máquina liberou (10, 15 e 20 são os previstos; 20 não é teto) | DD10 (partida); portão da seção 17.1 (subida) |
| `foco.vigilia` (lista) e máximo de vigília | vazia; 8 | chaves | 0 a 20 nas fases 1 e 2; na fase 3, o anel quente do degrau | chaves com papel aberto por sessão |
| `foco.cotas` | 8 bolsas, 4 próprios, 4 `piso`, 4 giro | vagas | soma igual a `folego.max_buscas` | vagas ociosas por fôlego |
| `Δ_foco` | 10 | minutos | 2 a 60 | idade média das fotos na hora da tecla |
| Fatia de trabalho; linhas do resumo por fatia | 2; 500 | milissegundos; linhas | 1 a 5; 100 a 2.000 | quadros por segundo medidos |
| Triagem de giro (H-30): `g_cob`; peso da média móvel; `k_t` | 3%; 0,3; 1 hora | | 1 a 10%; 0,1 a 0,5; 0,1 a 10 horas | correlação de postos em 30 chaves; abandono abaixo de 0,4 |

**Fotos e banco**

| Parâmetro | Partida | Unidade | Faixa | Como calibrar ou quem decide |
|---|---|---|---|---|
| Degraus guardados | 12 | degraus | 6 a 40 | tamanho do banco |
| Baldes da cauda | 8, com os limites da seção 5.3 | | | primeiras fotos |
| Leilões por foto de item | 30 | leilões | 10 a 60 | tamanho do banco |
| Chaves com anel; fotos por chave | 60; 16 na fase 1 e 48 na fase 2 (32, se a S1 não liberar teto maior) | | por degrau (seção 17.1); 8 a 64 | S1 (tempo do `/reload`) |
| `dias`: chaves; dias | 1.500; 14 | | 500 a 3.000; 7 a 30 | tamanho do banco |
| `blocos` | 126 blocos de 4 horas | | 42 a 180 | três semanas para o ciclo de hora e dia |
| Teto do banco; gatilho da poda | 3 MB; 80% | | 1 a 5 MB | S1 (H-19) |
| Sugestão de salvar | 45 minutos ou 50 ações | | 15 a 90 minutos | quedas de conexão por sessão |
| `DESK STALE` | 7 | dias | 3 a 30 | |
| Tolerância de divergência (seção 7.6) | 10%, ou 1 cobre | | 5 a 25% | alarmes falsos |

**Venda**

| Parâmetro | Partida | Unidade | Faixa | Como calibrar ou quem decide |
|---|---|---|---|---|
| Regra de preço, duração e lote por classe | sem valor até a resposta à DD3: `PICK RULE`. Com "pode seguir", a regra vira `igualar`; duração e lote de commodity seguem sem valor até o dono escolher | | `igualar`, `cobrir`, `folga`; 2, 8 ou 24 horas; pilha, receita ou fixo | DD3 (recomendação: `igualar`; em equipamento é a única regra) |
| `venda.folga` | sem valor | ticks | | o dono dá, se escolher `folga` |
| `venda.lote_item` | 1 | unidades por tecla | fixo em 1 | DD11 |
| Filtro de isca: fração da janela; salto; degraus; salto mínimo; escada mínima | 0,05; 15%; 3; 3 ticks; 20 unidades | | 0,01 a 0,15; 5 a 40%; 1 a 5; 1 a 10; 5 a 100 | 50 fotos rotuladas à mão (R9 1.7) |
| Janela `N_ref`: fração da escada; mínimo; máximo | 0,15; 5; 2.000 | unidades | 0,05 a 0,5; 1 a 20; 200 a 10.000 | erro contra as vendas próprias |
| Referência forte | commodity: 5 unidades de 2 donos; item: 5 arremates de 3 donos | | 3 a 20; 1 a 5 | fração dos verdes com referência forte (onda 2) |
| Dado suspeito pelo Auctionator | diferença de mais de 3 vezes | | 2 a 5 | |
| Teto de preço de postagem | 3 vezes a referência | | 1,5 a 3: o `Config.lua` só baixa | DD10; subir é editar `Tetos.lua` |
| Intervalo de Wilson do veredito | 80% | | 80 a 95% | vereditos `AUCTION` que não venderam |
| Desfechos para mostrar a frequência | 10 por classe, duração e regra | | 5 a 30 | |
| Recursão da sombra: `K`; desfechos para comparar | 3; 50 por classe | | 1 a 6; 30 a 200 | |

**Compra**

| Parâmetro | Partida | Unidade | Faixa | Como calibrar ou quem decide |
|---|---|---|---|---|
| `tiquete` | 15 | cobre por tecla | 1 a 200 | lucro por hora realizado vezes o tempo medido por ação; DD10 |
| `μ_min`, a margem mínima de compra | 0,15 | fração do custo | 0,03 a 0,3 | lucro por tecla alvo; parte acima do 0,10 do R9 porque corte e depósito ainda são estimativa; DD10 |
| `η_real` | 1,0 no `piso`; 0,5 no resto | razão | 0,3 a 1 | `Σ` realizado sobre `Σ` previsto, 30 lotes |
| Teclas de uma compra para revenda | 5 | teclas | 3 a 6 | medido no Livro |
| `piso.custo_ida` | 0 | cobre | 0 a 500 | tempo por ação |
| Apara do preço robusto (`α_ap`); dias mínimos para a mediana dos mínimos | 0,2; 5 | | 0,1 a 0,3; 3 a 14 | erro contra as vendas próprias |
| `Δ_max`, intervalo máximo de um par de fotos | 15 | minutos | 5 a 120; nunca entre sessões | S11 |
| Casamento de repostagem: `tol_rep`; `g_rep`; coortes por chave | 0,10; 0,05; 32 | | 0 a 0,25; 0,01 a 0,15; 8 a 64 | mercado sintético da bancada |
| Classe B | 3 pares válidos em 2 dias distintos | | 2 a 6; 1 a 3 | testemunhas falsas no mercado sintético |
| Sobrevivência: faixas de desconto; releituras; mínimo | até 10%, 10 a 30%, acima de 30%; 15; 0,5 | | 10 a 30; 0,3 a 0,7 | releituras da tecla `B` |
| "Já sumiu" para ligar o `sniper` (portão da estratégia inteira; o limiar por faixa é o da linha de cima) | até 70% em 30 sinais | | 50 a 80% | |
| Guarda de regime | sobra abaixo da entrada maior que 3 vezes o lote | | 1 a 8 | pechinchas que viraram preço novo |
| Volume diário por item | 10% das vendas inferidas na exposição do dia; 2 horas mínimas | | 1 a 10%; 2 a 6 horas: o `Config.lua` só aperta | vendas próprias contra as inferidas; subir é editar `Tetos.lua` |
| `π_react`, desconto de reação do papel | 0,2 | | 0 a 0,5 | papel contra micro |
| Exposição mínima para `not sold` | 2 | horas | 1 a 6 | fração inconclusiva |
| `T_fecho` | 72 | horas | 24 a 240 | |
| Portão de papel: sinais; grupos item-dia; máximo por item; limiar da razão | 30; 10; 20%; 0,5 | | 20 a 60; 5 a 20; 10 a 34%; 0,3 a 1 | DD10 |
| Portão de micro para plena | 30 lotes | | 20 a 60 | DD10 |
| Prova do `piso` | 3 varreduras em blocos de 4 horas distintos; dobro do tíquete | | | DD10 |
| Condição para a ordem micro de revenda | ganho previsto de 3 vezes as teclas vezes o tíquete | | 1 a 10 | DD10 (alternativa: esperar 15 ouro) |

**Antiguerra, disjuntores e sonda**

| Parâmetro | Partida | Unidade | Faixa | Como calibrar ou quem decide |
|---|---|---|---|---|
| G1 | 2 cancelamentos com repostagem por item em 4 horas | | 1 a 4; 1 a 12 horas | DD10 |
| G2 | 2 coberturas em 60 minutos, cada uma vista até 10 minutos depois da postagem; trégua de 4 horas | | 30 a 120 minutos; 3 a 30 minutos; 1 a 12 horas | DD10 |
| Parede | 25% da escada, até 2 donos | | 10 a 50%; 1 a 3 | DD10 |
| Deriva | pares de 6 a 48 horas; 30 chaves por classe; suspende em −10% em dois dias | | | DD10 |
| Ação muda; dado ruim; compras perdidas | 3 INCERTO; 2 fôlegos incompletos; 3 "já sumiu" seguidas | | 2 a 5 | DD10 |
| Dinheiro sem explicação | 1% da banca, dentro da janela de leilão ou de correio | | 0,5 a 3% | DD10 |
| Dia de risco | vira às 06:00, hora local | | 00:00 a 12:00 | DD10 |
| Classe `sonda` | depósito de até 30 cobre; compra de até 20 cobre; só as ordens previstas no passo, uma por tecla | cobre | | fixo |
| Destrava do disjuntor de perda num item | 24 | horas | 12 a 72 | DD10 |
| Degraus comprados pelo `vao` | até 2 | degraus | 1 a 3 | DD10 |

**Fase 3 e gargalo** (seção 17.1)

| Parâmetro | Partida | Unidade | Faixa | Como calibrar ou quem decide |
|---|---|---|---|---|
| `degrau` | 0 | | 0 a 3; dentro do jogo só desce | portões da seção 17.1, com o sim do dono |
| Banca que abre os degraus 1, 2 e 3 | 15, 60 e 250 | ouro | | proposta do projeto; decisão do dono com os números da régua |
| Gargalo de capital; de sinal | banca livre abaixo de 20%; acima de 50%, com a fila de compra vazia em mais da metade dos fôlegos | fração da banca | 10 a 30%; 40 a 70% | sessões classificadas à mão no relatório |
| Gargalo de giro e conselho de carteira | estoque com idade acima de 2 vezes o tempo de venda medido | vezes | 1,5 a 4 | DD10 |

## Apêndice C: glossário

| Termo | Sentido neste design |
|---|---|
| Ação | Uma das oito chamadas que compram, postam, confirmam ou cancelam |
| Banca; piso pessoal | O ouro que o addon pode arriscar, por personagem; o ouro que ele não toca |
| Bilhete | O resumo de uma ordem que gasta ou perde depósito, mostrado antes da tecla `Y` |
| Cofre | O módulo de risco que autoriza ou nega cada ordem; há um por personagem |
| Commodity | Item empilhável que o leilão vende por quantidade |
| Corte; depósito | A parte da venda que a casa retém; o valor pago ao postar |
| Degrau (da escada); degrau (da fase 3) | Cada preço da escada; cada nível de escala da seção 17.1 |
| Dia de risco; dia de mercado | A data local com virada às 06:00, usada nos tetos do dia; a data UTC, usada no histórico de preço |
| Disjuntor | Trava automática que suspende um tipo de ação |
| Eco | O evento do jogo que confirma uma ação |
| Entradas de fora | Toda variação de ouro que não vem das compras para revenda; grandeza medida, não conselho |
| Escada; frente; vão | A lista de preços à venda de um item; o primeiro preço alheio que vale; a distância entre dois degraus |
| Exposição observada | A soma dos intervalos em que a chave de um lote de papel teve par válido de fotos |
| Fôlego; ciclo | Uma rodada limitada de consultas, aberta por uma tecla; uma passada pelo foco |
| Foto | O registro de uma resposta do leilão, com hora e marcas de completude |
| INCERTO | Estado de uma ação sem eco: bloqueia e concilia, nunca reenvia |
| Isca; parede | Degrau pequeno e barato seguido de salto; degrau grande, de poucos donos |
| Licença | O nível de uma estratégia: desligada, papel, micro ou plena |
| Livro, régua | O registro de ações, lotes e sessões, e as medidas que saem dele |
| Mesa | O que roda fora do jogo |
| Papel; sombra | Sinal registrado sem gastar ouro; regra alternativa calculada ao lado, sem virar conselho |
| Par válido | Duas fotos da mesma chave, com a frente completa, separadas por até `Δ_max`, na mesma sessão |
| Piso (estratégia) | Arrematar abaixo do preço que o vendedor NPC paga |
| `P*` | A chance de venda a partir da qual o leilão paga mais que o vendedor |
| Referência | O preço de mercado que o addon aceita como base: forte, fraca ou nenhuma |
| Sonda | O roteiro de medidas feitas no jogo |
| Tíquete | O valor mínimo que uma tecla precisa render para a linha entrar na fila |
| Venda inferida | Venda dos outros deduzida da diferença entre duas fotos da escada; é estimativa com viés nos dois sentidos, e só conta em par válido |
| Vigília | As chaves que entram em todo fôlego; na opção (b) da DD13, a varredura que se renova enquanto o dono tecla |

## Apêndice D: fontes

O design cita só estes arquivos. Uma sessão nova lê este texto e a pasta `pesquisa/`.

| Fonte | Onde está | Como é citada |
|---|---|---|
| Pasta do addon | `C:\GMS\Claude Code Projects\wow\modder\addons-proprios\PregaoForever\` (no texto, `wow/modder/addons-proprios/PregaoForever/`) | |
| Base de fatos | `pesquisa/base-de-fatos.md`, dentro da pasta do addon | `base 2.7` |
| Relatórios | `pesquisa/R1a.md` (contrato da API), `R1b.md` (uso pela Blizzard), `R1c.md` (APIs vizinhas), `R4a.md` (regras e ativos do projeto), `R4b.md` (estado do dono), `R5a.md` (regras do leilão), `R5b.md` (economia), `R6a.md` e `R6b.md` (ecossistema e dados externos), `R8a.md` e `R8b.md` (estratégias com fonte), `R9.md` (modelos), `R10a.md` (acesso remoto), `R10b.md` (engenharia de interface), `R11a.md` e `R11b.md` (dados estáticos e chave de item) | `R9 5.1` |
| Quadros das telas | `pesquisa/telas/`, página renderizada | |
| Código da interface da Blizzard (espelho) | Repositório `Ketho/wow-ui-source-forever`, branch `forever`, commit `bebcb6bf309cf41b41bd74f8ca651e6a105b2676` (mensagem `1.60.1 (70938)`, de 2026-11-13). Para reler: `git clone --depth 1 --branch forever https://github.com/Ketho/wow-ui-source-forever` | `espelho, Arquivo.lua:123`; os arquivos do leilão ficam em `Interface/AddOns/Blizzard_AuctionHouseUI/Shared/` e a documentação gerada, em `Interface/AddOns/Blizzard_APIDocumentationGenerated/` |
| Textos do cliente | `Ketho/BlizzardInterfaceResources`, branch `forever`, `Resources/GlobalStrings/enUS.lua` (build 70532) | `strings, linha 1291` |
| Tabelas do cliente | `https://wago.tools/db2/<Tabela>/csv?build=1.60.1.70938` (por exemplo `ItemSparse`, para o `Dados.lua`) | `base 9.1` |
| Listas oficiais de nomes da API | `wow/modder/ferramentas/guia/api-forever/` (build 70532) | |

Textos do cliente usados como fato: `AUCTION_HOUSE_UNDERCUT_TUTORIAL` (linha 1291), `AUCTION_POSTING_ERROR_TEXT` (linha 1305), `CANCEL_AUCTION_CONFIRMATION` (linha 3390), `CONFIRM_AUCTION_POSTING_TEXT` (linha 4861), `DANGEROUS_SCRIPTS_WARNING` (linha 5690), `ERR_AUCTION_DATABASE_ERROR` (linha 7827) e `ERR_AUCTION_ITEM_HAS_QUOTE` (linha 7836). O comando 14 do Apêndice A os confere no build do jogo.

Nenhum outro relatório é citado. O texto não descreve nem cita o código interno de addons de terceiros.

## Decisões de projeto e por quê

Os pontos em que havia mais de um desenho possível, descritos pelas alternativas, e a escolha feita. O que é do dono está na seção 18; aqui fica o que o projeto decidiu.

| # | Ponto | Alternativas | Decisão e por quê |
|---|---|---|---|
| 1 | Espinha do design | Partir dos invariantes e do núcleo de risco; ou partir da ordem de entrega, com o que rende primeiro | Invariantes e Cofre na estrutura, e a ordem de entrega que mede antes de agir. Invariante não se enxerta depois; a ordem de entrega, sim. |
| 2 | Teclas por compra | Uma tecla para item abaixo de um teto; segunda tecla só com bilhete grande; dois tempos sempre | Dois tempos em toda compra: a regra do dono pesa mais que a vazão, e com cerca de 4 ouro a tecla não é o gargalo. Rever com a taxa de erro medida em papel. |
| 3 | Teclas por postagem e por cancelamento | Uma tecla; duas teclas | Cancelar sempre em duas (`C` arma, `Y` executa): perde depósito, e a tela da Blizzard também confirma. Postar em duas até a S0 e a DD5, porque a letra pode ser tecla de painel por hábito; depois, uma, se o dono aprovar. |
| 4 | Tecla única ou por verbo | Uma tecla para tudo; uma por verbo | Por verbo, com uma só tecla de confirmar, e cada tecla com um sentido só. |
| 5 | Ação sem resposta | Tratar como falha e rearmar a tecla; estado INCERTO | INCERTO: rearmar com falha muda e throttle desconhecido leva a ação em dobro. |
| 6 | Gatilho da varredura | Presença de 90 s; uma tecla por rodada; fôlego que qualquer tecla renova; contínuo | Virou decisão do dono (DD13), porque é escolha e não regra: tecla por fôlego nas ondas 2 a 4, vigília com presença recomendada na fase 2, contínuo recusado. |
| 7 | Correio | Tecla no botão da Blizzard; tecla por carta; só leitura | Só leitura, como recomendação da DD1c. O motivo são as incógnitas da H-11, não a decisão de 2026-11-06. |
| 8 | Confirmar commodity sem tecla | Oferecer, porque a API talvez permita; recusar | Recusada e não oferecida. |
| 9 | Conta de compra | Desconto `η_real` sobre a saída inteira; sobre o ganho | Sobre o ganho; a outra reprova tudo abaixo de 130% de margem. Depois de 30 lotes, o desvio `δ` da saída. |
| 10 | Preço de postagem | Valor de liquidação `W*` decide; regra com fonte; chance de venda estimada | Regra com fonte escolhida pelo dono, `P*` na tela, recursão `V_K` em sombra; o `W*` com tabela de probabilidade fica para a fase 3. Nenhuma chance de venda sem medida aparece. |
| 11 | Queda diária fixa de preço | Prazos presos a uma queda de 7% ao dia; deriva medida | Removida: a base 6.1 não autoriza taxa fixa. A deriva é medida por classe e só suspende compra. |
| 12 | Banca | A soma dos quatro personagens; só o personagem logado | Só o logado (base 4.2), com um Cofre por personagem: postar e cancelar em qualquer um, comprar só no negociador. |
| 13 | Tamanho da ordem | 2% por ordem; 25% por nicho; 20% por linha depois de sondagem de 2% | Duro de 20% por item e 10% por ordem; partida de 10% e 5%; confirmação de 1 unidade ou 1 pilha, até 2%. Proposta a aprovar (DD10). |
| 14 | Arbitragem de vendedor | Estratégia de entrada; só medir | Medida de graça desde a onda 2; não tem fonte de estratégia e só liga se o dono aprovar (DD3). |
| 15 | Mesa e `/reload` | Vigia e sincronização a cada bloco; sem processo de fundo | Sem processo de fundo; `/reload` é ponto de salvamento. Os contratos de dados valem desde já. |
| 16 | Nomes de vendedor e ficha de terreno | Guardar, mostrar e dar veredito por nicho; não guardar | Nada gravado nem mostrado; só a contagem de donos distintos. G1 e G2 entram sem nome. A assinatura numérica é decisão do dono para a fase 3 (DD15). |
| 17 | Ordem entre preços iguais | Teste com segundo jogador; medida passiva | Só passivo: compra combinada é o desenho que a base 1.10 manda evitar. O texto do cliente já diz qual é a ordem (H-14). |
| 18 | Roda do mouse | Usar; não usar | Não usar, como escolha de desenho: nenhuma fonte a proíbe. |
| 19 | Fatura antes de abrir a carta; item cancelado no correio | Tratar como fato; tratar como hipótese | Hipóteses H-11 e H-10, com caminho alternativo. |
| 20 | Treino dentro do jogo; exploração com o depósito do dono; alternância de passos de preço | Modo de treino; experimentos pagos | Treino é `modo = "papel"`. Experimento com o depósito do dono fica fora: as regras são comparadas em sombra. |
| 21 | Postar por addon de terceiro na onda 0; reusar código de licença aberta na fase 3 | Usar; não usar | A postagem por terceiro no Forever não foi vista (base 4.3): a onda 0 fala só da tela da Blizzard. Reusar código de terceiro fica fora; adotar a ferramenta inteira é a DD12. |
| 22 | Postagem-sonda de 1 unidade, para medir quem cobre e em quanto tempo | Fazer; não fazer | Não fazer: é experimento pago com o depósito do dono, sem fonte. A cobertura é medida de graça nas postagens reais (G2 e a seção 7.6). |
| 23 | Tamanho do lote de commodity | A pilha inteira; o tamanho da demanda enquanto na frente; o tamanho de receita | Campo do `Config.lua` por classe, escolhido pelo dono (DD3). O lote do tamanho da demanda pede taxa de venda, que só a fase 2 mede. |
| 24 | Ritmo de ações e de buscas | Teto duro; número de configuração | Configuração com portão medido: teto duro é só de dinheiro. |
| 25 | Conselho de cancelar | Mostrar o ganho esperado; mostrar só fatos | Só fatos nas fases 1 e 2: a regra pede chance de venda que o design não inventa. A regra roda em sombra. |
| 26 | Marco de banca para a compra de revenda | Esperar 15 ouro; condição medida | Condição medida (o ganho previsto paga as teclas); os 15 ouro ficam como opção da DD10, com o custo em dias. |

**Continua aberto, e só o jogo ou o dono fecha:** a H-01 (a tecla), a H-11 (a fatura), a regra de preço em commodity (DD3), o valor do tempo do dono, e a absorção por item, que decide se o degrau 3 da fase 3 existe. O R9 segue sem revisor matemático independente além desta revisão: nada dele decide gasto antes de vencer, no registro do próprio addon, a regra com fonte.
