> Artefato de processo de 2026-11-16, guardado só para rastreio. Não é contrato: vale o `DESIGN.md`.

# Parecer V1-api: a API do jogo no design PregaoForever (SINTESE.v1)

Data: 2026-11-16. Lente: tudo o que o design afirma sobre funções, eventos, estruturas e fluxos confere com o código e a documentação do cliente? Só leitura; nada foi testado no jogo.

**Veredito curto.** Nenhum achado bloqueante. Os nomes de função, evento, enum e campo citados no design existem no build 70938 e as assinaturas conferem. O que falha é a fidelidade dos fluxos: o design não usa cinco coisas que o código e os textos do próprio cliente já dizem (o que é o aviso de postagem, quem mais reage a ele, o ciclo da cotação de commodity, os campos da fatura, a ordem entre preços iguais) e a onda 0 manda o dono medir teclas com comandos que não leem teclas. São 10 achados importantes e 9 menores.

**Abreviações de caminho** (raiz: `<pasta temporária da sessão>/`):

- `AH/` = `espelho/wow-ui-source-forever/Interface/AddOns/Blizzard_AuctionHouseUI/Shared/` (arquivos `Blizzard_AuctionHouse<Nome>.lua`; cito só `<Nome>.lua`)
- `DOC/` = `espelho/wow-ui-source-forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/`; `AD` = `DOC/AuctionHouseDocumentation.lua`
- `UI/` = `espelho/wow-ui-source-forever/Interface/AddOns/`
- `GS` = `dados/GlobalStrings-enUS.lua` (strings do cliente, build 70532; fonte primária da base, cabeçalho e itens 1.5 e 1.8)
- `LISTA` = `C:/GMS/Claude Code Projects/wow/modder/ferramentas/guia/api-forever/GlobalAPI.lua` (lista de nomes, build 70532, a mesma do R1c)

O espelho é o build certo: `espelho/wow-ui-source-forever/version.txt` diz `1.60.1.70938`.

---

## 1. Nomes, assinaturas e payloads (item 1 do Faça)

**Como conferi.** Li direto no `AD` as 7 funções com `HasRestrictions` (linhas 60-62, 94-96, 108-110, 852-854, 864-866, 883-885, 1079-1081), as assinaturas de `IsSellItemValid`, `MakeItemKey`, `PlaceBid`, `PostCommodity`, `PostItem` e `QueryBids` (804-912) e os eventos de 1101 a 1229. A contagem bate (86 funções, 47 eventos, por grep). Para o resto usei as tabelas do R1a e do R1c, que conferem com as amostras lidas. O uso pela Blizzard foi relido no código (seção 2).

| Grupo citado no design | Resultado |
|---|---|
| As 7 funções de ação e `ConfirmCommoditiesPurchase` (seção 1, regra 6 e nota) | Conferem. As 7 têm `HasRestrictions = true`; `ConfirmCommoditiesPurchase` (AD:83) e `CancelCommoditiesPurchase` (AD:71) não têm. O predicado é `Precondition` com `FailureMode = "ReturnNothing"` (`DOC/ActionDocumentation.lua:9-13`). |
| `PostItem(item, duration, quantity, bid?, buyout?)`, `PostCommodity(item, duration, quantity, unitPrice)`, retorno `needsConfirmation` | Conferem (AD:883-900, 864-880). |
| `PlaceBid(auctionID, bidAmount)`, `CancelAuction(ownedAuctionID)`, `CanCancelAuction`, `GetCancelCost` | Conferem (AD:852-861, 60, 45, 225). `CanCancelAuction` existe e a tela da Blizzard não a chama (R1b 10). |
| `StartCommoditiesPurchase(itemID, quantity)` | A documentação tem 2 argumentos (AD:1079-1088); a tela passa 3 (`AH/Frame.lua:847`). Ver V1-11. |
| `SendBrowseQuery`, `RequestMoreBrowseResults`, `HasFullBrowseResults`, `QueryOwnedAuctions`, `SendSearchQuery`, `ReplicateItems` | Existem. `QueryOwnedAuctions(sorts)` e `SendSearchQuery(itemKey, sorts, separateOwnerItems)` exigem a tabela `sorts` (não aceita nil). O design não cita `SendSellSearchQuery`, `RequestMore*SearchResults` nem `HasFull*SearchResults`. Ver V1-09. |
| `IsThrottledMessageSystemReady`, eventos `AUCTION_HOUSE_THROTTLED_*` | Conferem (AD:825; eventos 22 a 26 do R1a). |
| `CalculateItemDeposit(item, duration, quantity)`, `CalculateCommodityDeposit(itemID, duration, quantity)` | Conferem; retorno pode ser nil. A tela da Blizzard não trata o nil (`AH/SellFrame.lua:477`); o design trata, e está certo. |
| `IsSellItemValid(item, displayError)` | Confere (AD:809-823). O segundo argumento tem padrão `true` e mostra erro na tela; a Blizzard passa `false` quando só quer saber (`UI/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua:1555`). Ver V1-18. |
| `GetItemCommodityStatus`, `SupportsCopperValues`, `GetQuoteDurationRemaining` | Conferem. `Unknown` (0) aborta na tela da Blizzard (`AH/Frame.lua:613-616`). |
| Eventos de eco: `COMMODITY_PRICE_UPDATED(unit, total)`, `COMMODITY_PRICE_UNAVAILABLE`, `COMMODITY_PURCHASE_SUCCEEDED`, `COMMODITY_PURCHASE_FAILED`, `AUCTION_HOUSE_PURCHASE_COMPLETED(auctionID)`, `AUCTION_HOUSE_SHOW_ERROR(error)`, `AUCTION_HOUSE_AUCTION_CREATED(auctionID)`, `AUCTION_HOUSE_POST_WARNING`, `AUCTION_HOUSE_POST_ERROR`, `AUCTION_CANCELED(auctionID)`, `OWNED_AUCTIONS_UPDATED`, `AUCTION_HOUSE_BROWSE_FAILURE` | Todos existem com esses payloads (AD:1104-1227, 1357-1384, 1485). Nos diagramas da seção 8.3 e 5.2 o design abrevia quatro nomes (`PRICE_UNAVAILABLE`, `SHOW_ERROR`, `BROWSE_FAILURE`, `FORBIDDEN`): os nomes literais são `COMMODITY_PRICE_UNAVAILABLE`, `AUCTION_HOUSE_SHOW_ERROR`, `AUCTION_HOUSE_BROWSE_FAILURE` e `ADDON_ACTION_FORBIDDEN`. |
| `COMMODITY_SEARCH_RESULTS_UPDATED(itemID)`, `ITEM_SEARCH_RESULTS_UPDATED(itemKey, newAuctionID?)` (seção 5.2) | Conferem (R1a 39 e 44). O segundo payload do evento de item não é usado pelo design. Ver V1-09. |
| `AUCTION_HOUSE_ITEM_DELIVERY_DELAY_UPDATE(purchasedItemDeliveryDelay, cancelledItemDeliveryDelay)` (H-10) | Existe (AD:1175-1184). Nenhum arquivo da Blizzard o escuta (grep em `UI/`). |
| Erros `HasRestriction` (6), `RestrictedAccountTrial` (5), `ItemNotFound` (4), evento `AUCTION_HOUSE_DISABLED` (seção 9.4, 8.3) | Conferem (`AH/Util.lua:634-660`; AD:1163). |
| Campos: `minPrice`, `totalQuantity`, `containsOwnerItem`, `numOwnerItems`, `containsAccountItem`, `owners`, `timeLeftSeconds`, `auctionID`, `itemSuffix`, `isCommodity` | Conferem com as estruturas do R1a 2. |
| Correio: `GetInboxInvoiceInfo`, `TakeInboxMoney`, `TakeInboxItem`, `AutoLootMailItem`, `SendMail`, `MAIL_SHOW`; `Open All Mail` em `MailFrame.xml:444`; `MailFrame.lua` 573-576 e 790 | Conferem (li as linhas). A fatura tem 12 retornos, não 7. Ver V1-07. |
| `C_Item.GetItemInfo` (11o retorno), `GetMoney`, `GetTime`, `GetServerTime`, `MERCHANT_SHOW`, `PLAYER_MONEY`, `FlashClientIcon`, `PlaySound`, `C_TradeSkillUI.GetRecipeSchematic`, `numAvailable` | Conferem. A Blizzard lê o preço de vendedor com `select(11, C_Item.GetItemInfo(itemLink))` (`AH/SellFrame.lua:425`). |
| `SetOverrideBindingClick`, `ClearOverrideBindings` | Existem, sem documentação; assinatura pelo uso (seção 4 deste parecer). |
| `ReloadUI`, `debugprofilestop`, `GetTimePreciseSec` | Existem. Ver a tabela das hipóteses e V1-15. |
| `ADDON_ACTION_BLOCKED`, `ADDON_ACTION_FORBIDDEN` (Apêndice A, S2) | Existem; payload `(isTainted, function)` (`DOC/RestrictedActionsDocumentation.lua:75-95`). |
| Lista proibida da regra 10 | Os nomes existem, mas faltam equivalentes que também gastam, vendem ou mexem no correio. Ver V1-14. |

Não achei nome inexistente nem argumento trocado. Os defeitos estão nos fluxos (seção 2) e no que o design deixa de usar.

---

## 2. Os quatro fluxos de ação contra o código da Blizzard (item 2)

### 2.1 Comprar commodity

Blizzard (`AH/CommoditiesBuyFrame.lua:132-142`, `AH/Frame.lua:844-848`, `AH/BuyDialog.lua`):

1. Clique: `StartCommoditiesPurchase(itemID, quantity, unitPrice)`, com três argumentos (`Frame.lua:847`).
2. O diálogo só registra os quatro eventos de commodity enquanto está aberto (`BuyDialog.lua:87-92, 103-104`).
3. `COMMODITY_PRICE_UPDATED` é tratado em qualquer estado, não só no de espera: o código não confere o estado antes de recalcular (`BuyDialog.lua:139-155`). Acima de 5% do unitário vira indisponível; entre 0 e 5% atualiza o total e segue; igual ou menor, confirma.
4. A validade só é lida depois de a cotação chegar: o `OnUpdate` com `GetQuoteDurationRemaining()` só é ligado nos estados `PriceConfirmed` e `PriceUpdated` (`BuyDialog.lua:237-238`); em 0 o diálogo fecha (`:121-126`).
5. Clique em comprar: `ConfirmCommoditiesPurchase(itemID, quantity)` e um timer de 2 s que só troca a tela (`:263-270`).
6. **O que cancela a cotação:** todo fechamento do diálogo chama `CancelCommoditiesPurchase()` e refaz a busca (`:108-119`). Isso inclui o sucesso (`:158-160`), o cancelar, o Ok do indisponível, a validade em zero e a troca de aba (`Frame.lua:590-592`).
7. `COMMODITY_PURCHASE_FAILED` vira indisponível (`:161-162`); a tela não distingue o motivo.

Design (seção 8.3) contra isso:

- A ordem das chamadas e os ecos conferem.
- O design só chama `CancelCommoditiesPurchase` em três transições (teto, tecla N, validade). Depois de `SUCCEEDED`, de `FAILED` e na ida para INCERTO não chama. A Blizzard chama sempre. O cliente tem o erro `ItemHasQuote`, com o texto "This auction can't be canceled because a transaction is pending" (`AH/Util.lua:644`; `GS:7836`): cotação aberta trava o leilão de quem vende. V1-02.
- Falta a transição de `COTADO` para um segundo `COMMODITY_PRICE_UPDATED` ou para `COMMODITY_PRICE_UNAVAILABLE`. V1-02.
- Os eventos de cotação não trazem `itemID` (AD:1357-1372) e a cotação é estado do cliente, dividido com o diálogo da Blizzard. V1-02.
- Dois argumentos em vez de três: H-17 existe, mas a ordem do teste confunde a leitura da S8. V1-11.
- Existe um segundo eco, que a tela da Blizzard não usa e o design não cita: `COMMODITY_PURCHASED(itemID, quantity)` (AD:1386-1395), o único evento de compra de commodity que traz item e quantidade. Quando ele dispara não está no código. Vale gravá-lo na S8 e, se chegar, usá-lo para conferir a quantidade comprada. Entra no V1-12.

### 2.2 Comprar item

Blizzard: `PlaceBid(auctionID, buyout)` dentro do `OnAccept` do popup `BUYOUT_AUCTION` (`AH/Frame.lua:10-12, 26-40`); o popup espera `AUCTION_HOUSE_PURCHASE_COMPLETED` com o mesmo `auctionID` ou qualquer `AUCTION_HOUSE_SHOW_ERROR`, e mostra o aguarde depois de 2 s (`:14-24, 31`; `UI/Blizzard_StaticPopup/StaticPopup.lua:1003-1048`). A chamada sai no próprio clique (`StaticPopup.lua:1004`), não do timer.

Design: confere em ordem, eco e erro. Uma ressalva: `AUCTION_HOUSE_SHOW_ERROR` não traz `auctionID` (AD:1252-1260), então o erro é atribuído à ação em voo por suposição, como a Blizzard faz. Com a tela da Blizzard aberta ao lado, um erro de outra origem derruba a ação do addon para FALHOU sem ela ter falhado. V1-13.

### 2.3 Postar

Blizzard (`AH/SellFrame.lua:206-209, 471-492`; `AH/ItemSellFrame.lua:480-525`; `AH/CommoditiesSellFrame.lua:108-151`; `AH/Frame.lua:100-129, 370-372, 441-444, 914-917`):

1. Pré-checagens: item válido, depósito menor ou igual ao dinheiro, quantidade maior ou igual a 1, `IsThrottledMessageSystemReady()`, preço maior que 0.
2. `PostItem(...)` ou `PostCommodity(...)`. Retorno falso: limpa a tela e não espera nada. Retorno verdadeiro: guarda os argumentos.
3. `AUCTION_HOUSE_POST_WARNING` abre o popup; aceitar chama `ConfirmPost*` com os argumentos guardados; cancelar não chama nada (o popup não tem `OnCancel`).
4. `AUCTION_HOUSE_POST_ERROR` abre um popup só com Ok.
5. `AUCTION_HOUSE_AUCTION_CREATED` só imprime "Auction created." (`Frame.lua:433-434`; `GS:7846`). A tela da Blizzard não o usa como eco.
6. Item com quantidade maior que 1 dispara o multisell: `AUCTION_MULTISELL_START`, `_UPDATE(criados, total)`, `_FAILURE`, e `CancelSell()` para abortar (`ItemSellFrame.lua:74-83, 98-116`).

Design contra isso:

- Ordem, pré-checagens e ecos conferem.
- **O que `needsConfirmation` dispara:** o design diz que é desconhecido (H-16). Os textos do cliente dizem: o aviso é de manutenção semanal com atualização do leilão, com perda do depósito; o erro é o leilão fechado para postagem antes da atualização (`GS:4861`, `GS:1305`). O texto é o do cliente; se o servidor do Forever chega a mandar o aviso, e em que manutenção, só o jogo diz. Há uma manutenção em 17/11 que mexe no depósito (base 1.7): se o aviso aparecer, é nessa véspera. V1-01.
- O `AuctionHouseFrame` registra `AUCTION_HOUSE_POST_WARNING` e `AUCTION_HOUSE_POST_ERROR` no `OnLoad`, não no `OnShow` (`Frame.lua:370-372`): o popup da Blizzard abre também quando quem postou foi o addon, e o Aceitar dele não confirma nada do addon. V1-01.
- O eco de `PostCommodity` não aparece em nenhum uso da Blizzard, e o multisell não está na máquina. V1-12.

### 2.4 Cancelar

Blizzard: botão, popup `CANCEL_AUCTION` (sempre, com ou sem custo), `OnAccept` chama `CancelAuction(auctionID)` (`AH/Frame.lua:77-98`; `AH/AuctionsFrame.lua:119-125`). `AUCTION_CANCELED` faz a aba de leilões refazer `QueryOwnedAuctions` (`AuctionsFrame.lua:214-215`). O texto do popup é "You will lose your initial deposit by canceling this auction." (`GS:3390`).

Design: confere. Uma tecla sem custo é mais curto que a Blizzard, que sempre confirma; é escolha de desenho já registrada (conflito 2). Falta tratar o erro `ItemHasQuote`. V1-13.

---

## 3. Hipóteses H-01 a H-25 diante do código (item 3)

Legenda: **confirmada** ou **negada** = o código ou o texto do cliente responde; **enfraquecida** = o código reduz a dúvida, num sentido; **aberta** = o código não diz. Nada aqui substitui a sonda: o que o código mostra é o cliente, não o servidor.

| # | Estado | O que o código ou o texto do cliente diz | Evidência |
|---|---|---|---|
| H-01 | aberta | As 7 funções só são chamadas de clique na tela da Blizzard; o predicado `HasRestrictions` falha em silêncio. O mesmo predicado marca funções como `SendChatMessage`, `DeleteCursorItem`, `CopyToClipboard` e `JoinBattlefield`, o que é coerente com exigir tecla ou clique, mas não define a condição. | `DOC/ActionDocumentation.lua:9-13`; varredura de `HasRestrictions` em `DOC/` (288 marcas) |
| H-02 | enfraquecida | Em que fase o clique chega não é incógnita: é o que o botão registrar em `RegisterForClicks`, e o `OnClick` recebe `down`. Registrando só a soltura, tecla segurada não repete por construção. Ver V1-05. | `UI/Blizzard_GamepadSharedUtility/InputHandlers/InputButtonUtility.lua:24, 33-40` |
| H-03 | aberta | Fora do código. A base 3.9 já mostra gravação e releitura nesta máquina; falta só o caso do `/reload`. | base 3.9 |
| H-04 | aberta | O cliente tem os dois caminhos e decide por `GetItemCommodityStatus`; `Unknown` aborta. Quais itens são commodity é do servidor. | `AH/Frame.lua:608-631` |
| H-05 | aberta | O código não mede. | sem evidência no espelho |
| H-06 | enfraquecida (a favor), metade | A Blizzard consulta de evento e de `OnUpdate`: `QueryOwnedAuctions` em `AUCTION_CANCELED`, `QueryBids` em `ADDON_LOADED`, releitura no fechar do diálogo. Mas ela não confere a prontidão do throttle em consulta nenhuma, só no botão de postar. A segunda metade segue aberta, e código de addon não é código seguro. | `AH/AuctionsFrame.lua:214-217`; `AH/Frame.lua:410-421`; `AH/BuyDialog.lua:108-126`; `AH/SellFrame.lua:487-489` |
| H-07 | aberta | A tela usa `minPrice` como preço unitário inicial da commodity. Para item o código não diz se é lance ou arremate. | `AH/Frame.lua:688` |
| H-08 | confirmada (há interferência) | Os resultados são estado único do cliente. A lista da Blizzard registra os eventos de resumo no `OnLoad` e relê tudo a cada um; a aba de leilões, quando aberta, refaz a consulta a cada `AUCTION_CANCELED`; o diálogo de compra cancela a cotação ao fechar. Falta medir o tamanho do efeito. | `AH/BrowseResultsFrame.lua:7-13, 21-22, 73-82`; `AH/AuctionsFrame.lua:214-217`; `AH/BuyDialog.lua:112` |
| H-09 | parte confirmada | Cancelar perde o depósito (texto do popup). A venda devolve o depósito: a fatura soma `bid + deposit - consignment`. Leilão devolvido por manutenção perde o depósito. O valor do corte e a expiração seguem abertos. | `GS:3390`; `UI/Blizzard_MailFrame/MailFrame.lua:836`; `GS:4861` |
| H-10 | enfraquecida (a favor) | Existem os assuntos de correio "Auction canceled: %s" e "Auction won: %s" e o evento com os dois atrasos de entrega. O valor do atraso segue aberto. | `GS:1309`, `GS:1338`; AD:1175-1184 |
| H-11 | aberta | A Blizzard só chama `GetInboxInvoiceInfo` depois de `GetInboxText` devolver `isInvoice`, com a carta aberta. Não há uso com a carta fechada. A sonda precisa de duas variantes. Ver V1-16. | `MailFrame.lua:573-576, 781-790` |
| H-12 | aberta, com medida melhor | O cliente tem a carta "Sale Pending: %s", cuja fatura (`seller_temp_invoice`) traz a hora prevista da entrega (`etaHour`, `etaMin`); o leilão vendido mostra "Delivered in". Mede-se direto, sem cronometrar. | `MailFrame.lua:847-856`; `GS:1295`, `GS:1293`, `GS:1278` |
| H-13 | aberta | A tela trata a lista de donos vazia e o tempo em segundos ausente, o que mostra que os dois casos existem. | `AH/Util.lua:391-399`; `AH/TableBuilder.lua:413-414` |
| H-14 | enfraquecida (contra o pior caso do design) | O texto do próprio cliente, mostrado pelo painel de venda quando o preço é o menor menos 1 prata: "There's no need to undercut! Auctions posted later (at the same price) are sold first." Ver V1-10. | `GS:1291`; `AH/SellFrame.lua:346-351, 507-518` |
| H-15 | primeira metade confirmada; segunda quase resolvida | O clique num item da bolsa leva o `ItemLocation` da bolsa ao painel, e é esse objeto que vai a `PostItem`. Quantidade maior que 1 em item liga o multisell: uma chamada, vários leilões criados em sequência, com eventos próprios e `CancelSell`. | `UI/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua:1555-1561`; `AH/ItemSellFrame.lua:74-83, 98-116, 480-525` |
| H-16 | primeira metade enfraquecida (a favor); segunda respondida | Ao recusar o aviso, a tela da Blizzard não chama nada. O que dispara: o texto do aviso fala de manutenção semanal com atualização do leilão, devolução antecipada e perda do depósito. Ver V1-01. | `AH/Frame.lua:100-117`; `GS:4861`; `GS:1305` |
| H-17 | aberta; a ordem do teste deve inverter | A única forma de chamada vista no cliente tem três argumentos; a documentação tem dois. Ver V1-11. | `AH/Frame.lua:847`; AD:1079-1088 |
| H-18 | aberta | O código só mostra a contagem a partir de 10 s e o fechamento em 0. | `AH/BuyDialog.lua:2, 121-137` |
| H-19 | primeira metade enfraquecida (a favor) | `ReloadUI` é função Lua que chama `C_UI.Reload`; a documentação não põe restrição nela, e a Blizzard a chama do aceite de um popup comum. O tempo com 1, 3 e 5 MB segue aberto. | `UI/Blizzard_SharedXML/InterfaceUtil.lua:1-3`; `DOC/UIManagerDocumentation.lua:65-67`; `UI/Blizzard_AddOnPerformance/AddOnPerformance.lua:6-8` |
| H-20 | confirmada quanto à existência | As duas funções existem. `debugprofilestop` conta desde o último `debugprofilestart`, que qualquer addon pode reiniciar; `GetTimePreciseSec` não depende disso. Falta só a resolução real. Ver V1-15. | `DOC/FrameScriptDocumentation.lua:533-540`; `DOC/OsDocumentation.lua:27-34` |
| H-21 | aberta | A Blizzard usa o mesmo 11o retorno como preço de vendedor, lido pelo link do item. | `AH/SellFrame.lua:422-426` |
| H-22 | aberta | Fora do código. | sem evidência no espelho |
| H-23 | enfraquecida (a favor) | A única condição para abrir o leilão no cliente é não ser conta de teste. Não há nível mínimo na interface. | `AH/UI_Bootstrap.lua:29-40` |
| H-24 | aberta | Fora do código. | sem evidência no espelho |
| H-25 | enfraquecida (a favor) | Os eventos são do cliente e chegam a todo quadro registrado: o `AuctionHouseFrame` imprime "Auction created." para qualquer criação. Avisos de venda são roteados com o leilão fechado. | `AH/Frame.lua:319, 433-434`; `UI/Blizzard_Game/Mainline/EventRouting.lua:12-16` |

---

## 4. O caminho da tecla (item 4)

**Assinaturas, pelo uso da Blizzard** (não há documentação gerada para estas funções; R10b 1.1):

- `SetOverrideBindingClick(dono, prioridade, tecla, nomeDoBotao, botaoDoMouse)`: `UI/Blizzard_GamepadSharedUtility/InputBindingStack/InputButtonBinding.lua:28` e `InputFunctionBinding.lua:49`. A Blizzard passa `UIParent` como dono, `true` na prioridade e `"LeftButton"` como botão padrão (`InputButtonBinding.lua:11-13`).
- `ClearOverrideBindings(dono)`: `UI/Blizzard_RestrictedAddOnEnvironment/RestrictedFrames.lua:538`. Para soltar uma tecla só, a Blizzard usa `SetOverrideBinding(UIParent, false, tecla, "")` (`InputBindingManager.lua:29, 102`).
- **Soltar é sempre explícito.** Em nenhum uso do espelho o binding cai porque uma janela escondeu: o dono serve para dizer de quem são os bindings na hora de limpar. A base 4.10 e a 8.1 descrevem o efeito ('só vale enquanto a janela dona está aberta'); o mecanismo que o design precisa escrever é `ClearOverrideBindings(janela)` no fechar. Entra no V1-06.

**O `OnClick` de um botão comum é o lugar certo?** É onde a Blizzard chama as 7 funções: botões comuns do painel (`AH/SellFrame.lua:206-209`, `AH/CommoditiesBuyFrame.lua:12-15`, `AH/AuctionsFrame.lua:121-125`) e o `OnAccept` de popup, que roda dentro do clique do botão do popup (`UI/Blizzard_StaticPopup/StaticPopup.lua:1003-1004`). Nenhum deles é botão seguro. O que o código não mostra é se o clique vindo de binding conta igual ao do mouse para código de addon: é a H-01, e segue aberta. Duas condições que o design já cumpre e não pode perder: o embrulho `ns.seguro` tem de chamar a função na mesma pilha (um `xpcall` direto, sem `C_Timer.After(0)`), e a função de ação tem de sair antes de qualquer espera.

**Em combate.** A base 3.4 diz que mudar binding em combate falha. No espelho a regra só aparece escrita para o ambiente restrito (`RestrictedFrames.lua:79-99`, erro `Invalid frame handle`; R10b 2); para addon comum não há linha que a mostre. O design tem a regra 16, mas não diz o que fazer quando o leilão abre ou fecha em combate: V1-06.

**Ao apertar ou ao soltar.** Não é propriedade do binding: é o que o botão registrou.

- `RegisterForClicks` decide as fases; o `OnClick` recebe `(self, botao, down)` (`UI/Blizzard_GamepadSharedUtility/InputHandlers/InputButtonUtility.lua:33-40`). A Blizzard cria esses botões com `GAMEPAD_BUTTON_ANY_DOWN` por padrão (`:24`) e aceita `AnyUp` e `AnyDown` juntos (`:8`), caso em que cada tecla gera dois `OnClick`.
- A CVar `ActionButtonUseKeyDown` só é lida por botão seguro de ação (`UI/Blizzard_FrameXML/SecureTemplates.lua:792-811`) e pela barra de pet. Não muda nada num botão comum.
- `RegisterForClicks` leva a marca `IsProtectedFunction` (`DOC/SimpleButtonAPIDocumentation.lua:271-273`). O que a marca restringe num botão comum não está no espelho (R10b 1.3 registra a mesma dúvida para `EnableKeyboard`). O caminho sem risco é configurar uma vez, na criação do botão, fora de combate.
- Que a soltura da tecla gere um clique só, mesmo com a tecla segurada, é inferência (repetição de tecla não gera soltura): a S2 confirma.
- Consequência para o design: V1-05.

**Outras leituras úteis.**

- O popup da Blizzard não rouba o teclado: `OnKeyDown` só é ligado na tela de login ou com `enterClicksFirstButton` (`StaticPopup.lua:616-617`), e nenhum popup do leilão usa isso (`AH/Frame.lua:26-129`). Com o popup do aviso de postagem aberto, as teclas Y e N do addon continuam chegando.
- `Button:Click()` tem a marca `ChecksForbiddenAspects` com `ScriptedInput` (`DOC/SimpleButtonAPIDocumentation.lua:42-45`): o cliente trata clique por código como entrada roteirizada. Reforça a recusa de `:Click(` da regra 10.
- Com o leilão aberto, o clique direito num item da bolsa manda o item ao painel de venda da Blizzard (`ContainerFrame.lua:1555-1561`). Não afeta o addon, mas o dono vai ver a tela da Blizzard mudar se clicar na bolsa.

---

## 5. Comandos de conferência do R1b 16 (item 5)

**Como conferi.** Medi o tamanho de cada comando com um script (`tmp/V1-api/len.mjs`), procurei nomes de ação ou de consulta ao servidor e conferi cada nome no espelho.

| Comando original | Tamanho | Só leitura | Nomes existem | Problema |
|---|---|---|---|---|
| 1 | 129 | sim | sim | A chave `AllowLoadGameType` pode devolver nil (o próprio R1b avisa). Troco o segundo valor pelo build, que responde à incógnita 19 do R1b. |
| 2 | 148 | sim | sim (`AUCTION_HOUSE_FILTER_STRINGS` em `UI/Blizzard_AuctionHouseUI/Mainline/Blizzard_AuctionHouseUtil.lua:6`; `AuctionCategories` em `UI/Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionData.lua:19`) | nenhum |
| 3 | 106 | sim | sim (`name`, `subCategories`: `UI/Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionData.lua:54, 103-109`) | nenhum |
| 4 | 128 | sim | sim (`GetCVar` é função Lua: `UI/Blizzard_SharedXMLBase/CvarUtil.lua:17`) | nenhum |
| 5 | 127 | sim | sim (`GS:1328, 1334`) | nenhum |
| 6 | 209 | sim | sim | nenhum |
| 7 | 229 | sim | sim (`C_Item.DoesItemExist` aceita slot vazio: `DOC/ItemDocumentation.lua:131-144`) | nenhum |
| 8 | 186 | sim | sim | Com o slot vazio, `C_Item.GetItemID` recebe um local sem item e o comando para com erro. Se uma das duas funções de depósito der erro para o tipo errado de item, as três durações se perdem. Reescrito com guarda e `pcall`. |
| 12 | 243 | sim | sim (`DOC/GameRulesDocumentation.lua:96, 225, 240, 286`; `SlashCommands.lua:1229`) | nenhum (o primeiro valor só pode sair `false`: se a regra estivesse ativa o comando não rodaria) |

Três coisas que a lista do design não cobre:

1. **O primeiro `/run` ou `/dump` abre um popup e não roda.** `AreDangerousScriptsAllowed()` falso mostra `DANGEROUS_SCRIPTS_WARNING` ("Allow custom scripts?") e retorna (`SlashCommands.lua:1229-1235, 1430-1437`; `GameDialogDefs.lua:3209-3219`; `GS:5690`). O dono responde Yes e cola de novo.
2. **Nenhum dos nove lê teclas**, e a S0 promete os 'padrões das teclas'. Acrescento o comando T.
3. O comando 8 lê um slot só, e a onda 0 fala em depósito de 10 itens. Acrescento D1 e D2, que varrem a mochila.

## Comandos da sonda (corrigidos)

Com o leilão aberto. No primeiro comando o jogo pergunta "Allow custom scripts?": responder Yes e colar o mesmo comando outra vez. Todos têm 254 caracteres ou menos, são só leitura (nenhum compra, posta, cancela nem consulta o servidor do leilão) e usam nomes conferidos no espelho. Um comando por linha.

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

8. Depósito do item da mochila, slot 1, nas três durações: para cada duração, uma linha da função de item e uma da função de commodity. `true` e um número = depósito em cobre; `true nil` = a função não devolveu depósito para esse item; `false` = erro, com o texto. Para outro slot, trocar o `(0,1)`.

```
/run local A,l=C_AuctionHouse,ItemLocation:CreateFromBagAndSlot(0,1) if C_Item.DoesItemExist(l) then for d=1,3 do print(d,pcall(A.CalculateItemDeposit,l,d,1)) print(d,pcall(A.CalculateCommodityDeposit,C_Item.GetItemID(l),d,1)) end end
```

12. Regras de jogo: scripts desligados, addons desligados, preset (0 Classic, 1 Enhanced), Hardcore, Self-Found permitido.

```
/run print(C_GameRules.IsGameRuleActive(Enum.GameRule.UserScriptsDisabled),C_GameRules.IsGameRuleActive(Enum.GameRule.UserAddonsDisabled),C_GameRules.GetForeverExperiencePreset(),C_GameRules.IsHardcoreActive(),C_GameRules.IsSelfFoundAllowed())
```

**Acrescentados** (o design promete estas medidas na S0 e os nove acima não as dão):

T. A que ação cada tecla do mapa proposto está ligada hoje (linha com a tecla e nada depois = livre). É o que decide a DD5.

```
/run for _,k in ipairs({"B","C","H","I","L","N","O","P","U","Y","F1","F2","F3","F4","F5"}) do print(k,GetBindingAction(k)) end
```

D1. Depósito de 24 horas, 1 unidade, de cada item da mochila pela função de item: slot, `true` e o depósito em cobre.

```
/run local A=C_AuctionHouse for s=1,C_Container.GetContainerNumSlots(0) do local l=ItemLocation:CreateFromBagAndSlot(0,s) if C_Item.DoesItemExist(l) then print(s,pcall(A.CalculateItemDeposit,l,3,1)) end end
```

D2. Depósito de 24 horas da pilha inteira de cada item da mochila pela função de commodity: slot, `true` e o depósito em cobre.

```
/run local A,I=C_AuctionHouse,C_Item for s=1,C_Container.GetContainerNumSlots(0) do local l=ItemLocation:CreateFromBagAndSlot(0,s) if I.DoesItemExist(l) then print(s,pcall(A.CalculateCommodityDeposit,I.GetItemID(l),3,I.GetStackCount(l))) end end
```

K. Chave de leilão do item da mochila, slot 1 (`itemID`, nível, sufixo) e o preço de vendedor lido do cliente. Num verde com sufixo, responde à segunda parte da H-04; serve também à conferência de 20 itens da seção 13.

```
/run local l=ItemLocation:CreateFromBagAndSlot(0,1) if C_Item.DoesItemExist(l) then local k=C_AuctionHouse.GetItemKeyFromItem(l) print(k.itemID,k.itemLevel,k.itemSuffix,select(11,C_Item.GetItemInfo(C_Item.GetItemLink(l)))) end
```

A. Os três textos do cliente em que os achados V1-01 e V1-10 se apoiam, no build do jogo (o arquivo lido é do build 70532): o aviso de postagem, o erro de postagem e a dica sobre igualar o preço.

```
/run print(CONFIRM_AUCTION_POSTING_TEXT) print(AUCTION_POSTING_ERROR_TEXT) print(AUCTION_HOUSE_UNDERCUT_TUTORIAL)
```

Tamanhos medidos: 71, 148, 106, 128, 127, 209, 229, 234, 243; T 126, D1 206, D2 245, K 226, A 113.

---

## 6. Lua 5.1 e cliente (item 6)

| Ponto | Situação no design | Leitura |
|---|---|---|
| Bibliotecas | O design não pede biblioteca externa. | Sem problema. `require`, `io` e `os` não existem no cliente; os arquivos puros recebem a hora por argumento, o que a regra 14 já força. |
| `goto`, `//`, operadores de bit | Não pedidos. | A bancada (fengari, 5.3) aceita os três e o jogo (5.1) não: um arquivo puro pode passar na bancada e quebrar no jogo. O `checar-lua.mjs` precisa barrar. Entra no V1-17. |
| Inteiros de 64 bits | Dinheiro em cobre inteiro (regra 17). | No jogo todo número é double: inteiro exato até 2^53, de sobra para cobre. O risco é o inverso: na 5.3 há inteiro e float separados, e o mesmo cálculo imprime texto diferente (`5` e `5.0`). Entra no V1-17. |
| Ordem do `pairs` | 'O papel do replay tem de ser igual ao que o addon gravou' (seção 16). | A ordem do `pairs` na parte de hash não é a mesma entre o Lua do jogo e o fengari. Qualquer desempate que dependa dela faz o replay divergir. Entra no V1-17. |
| Limite de locais (200 por função) e de upvalues (60 por função) | 28 arquivos, todos com `local _, ns = ...`. | Sem problema enquanto as funções ficarem em `ns`, como a regra 2 pede. O risco está em `Telas.lua` e `Dados.lua` se forem escritos com dezenas de `local` no topo. |
| Constantes por função | `Dados.lua` com uma linha por item (até 19.325 itens, base 9.1); banco de 1,1 a 1,6 MB. | O teto da linguagem é de 2^18 constantes por função, e arquivo de dados e SavedVariables são uma função só. `Dados.lua` fica em cerca de 40 mil (chave e texto); o banco estimado, abaixo de 20 mil textos. Cabe com folga, mas o design não fixa o número e a fase 2 cresce. É fato da linguagem, fora da base: medir na S1. Entra no V1-17. |
| Tamanho do arquivo de dados | 150 a 250 KB (hipótese do design). | Sem limite conhecido nessa ordem de grandeza. |
| `xpcall` | Regra 3: `xpcall(fn, geterrorhandler())`. | Sem problema na forma de dois argumentos, que vale nas duas versões. |

Resumo: nenhuma construção pedida pelo design falta no cliente. O que precisa entrar no texto é a disciplina entre 5.1 e 5.3 nos arquivos puros.

---

## 7. O que a correção não deve estragar

1. A regra 6 com as respostas em `Ecos.lua`, que não pode agir: é a mesma separação que o código da Blizzard tem (ação só em clique, resposta em evento).
2. O estado INCERTO sem reenvio: casa com a falha em silêncio do predicado `HasRestrictions` (`DOC/ActionDocumentation.lua:9-13`) e com o aguarde de 2 s da Blizzard.
3. Tratar `ConfirmCommoditiesPurchase` como função de ação, embora não tenha a marca (AD:83).
4. Depósito e preço de vendedor sempre lidos na hora, e depósito nulo bloqueando a postagem: a tela da Blizzard não trata o nulo.
5. Janela própria, sem aba no `AuctionHouseFrame`, e correio só de leitura: o `Open All Mail` da Blizzard já pula carta de GM e cobrança, e para com a bolsa cheia (`UI/Blizzard_MailFrame/MailFrame.lua:1552-1566, 1632-1635`).

---

## Tabela dos achados

| id | seção | gravidade | tipo | achado | evidência | correção |
|---|---|---|---|---|---|---|
| V1-01 | 8.3 Postar; 2.2 H-16; 11.4 B | importante | fato_errado | O design trata o aviso de postagem como de causa desconhecida e só repete os números. O texto do cliente diz o que é: manutenção com atualização do leilão, devolução antecipada e depósito perdido. E o popup da Blizzard abre junto, porque o `AuctionHouseFrame` ouve o evento desde o `OnLoad`; o Aceitar dele não confirma a postagem do addon. | `GS:4861` (CONFIRM_AUCTION_POSTING_TEXT); `GS:1305` (AUCTION_POSTING_ERROR_TEXT); `AH/Frame.lua:100-117, 370-372, 441-444, 914-917`; `AH/ItemSellFrame.lua:505-511` | Na seção 8.3, no estado AVISO, mostrar `MAINTENANCE: may return early, deposit lost`, tratar o depósito como perdido na conta e pôr N como padrão. `AUCTION_HOUSE_POST_ERROR` vira estado `POSTING CLOSED`, sem contar como falha nem INCERTO. Na 11.4 B, dizer que o popup da Blizzard aparece junto e não confirma nada. Na H-16, trocar 'desconhecido' pela citação. |
| V1-02 | 8.3 Comprar commodity | importante | lacuna | A máquina só cancela a cotação em três saídas; a Blizzard cancela em todo fechamento, inclusive depois do sucesso. Falta a transição de COTADO para nova cotação ou indisponível. Os eventos de cotação não trazem item, e a cotação é dividida com o diálogo da Blizzard. | `AH/BuyDialog.lua:108-119, 139-163, 237-238`; `AH/Frame.lua:590-592`; AD:1357-1372; `AH/Util.lua:644`; `GS:7836` | Na 8.3, chamar `CancelCommoditiesPurchase` em toda saída de COTANDO, COTADO e CONFIRMANDO (FEITO, FALHOU, leilão fechado), menos durante INCERTO. Acrescentar: COTADO com `COMMODITY_PRICE_UPDATED` reconfere o teto e reinicia `T_ver`; com `COMMODITY_PRICE_UNAVAILABLE` volta a SINAL. Não cotar nem confirmar com `AuctionHouseFrame.BuyDialog` visível. Ler a validade só depois da cotação. |
| V1-03 | 15; 7.3; 7.4 | importante | contradicao_interna | O limite 'leilão com `containsAccountItem` nunca vira linha' não se aplica a commodity: a compra leva as unidades mais baratas sem escolher leilão, e a conta da Blizzard só desconta as do próprio personagem. Com quatro personagens postando, o addon pode comprar do próprio dono. | `AH/Util.lua:207-230` (só `numOwnerItems`); base 2.7; base 4.2; design seção 15 | Na seção 15 e nas 7.3 e 7.4, escrever: em commodity, se algum degrau dentro da profundidade da compra tiver `containsAccountItem`, não há sinal nem cotação; a releitura antes da tecla B confere de novo. Acrescentar à S8 a medida: a compra de commodity pula ou não as unidades da conta. |
| V1-04 | 17 onda 0; Apêndice A S0 | importante | fato_errado | A S0 diz medir 'padrões das teclas' com os comandos 1 a 8 e 12 do R1b; nenhum deles lê binding. O primeiro `/run` da conta abre um popup de confirmação e não roda, o que pode ser lido como '/run bloqueado'. O comando 8 quebra com o slot vazio. | R1b 16 (comandos 1-8 e 12); `UI/Blizzard_ChatFrameBase/Shared/SlashCommands.lua:1229-1235, 1430-1437`; `UI/Blizzard_StaticPopup_Game/GameDialogDefs.lua:3209-3219`; `GS:5690`; `LISTA:5318` | Na onda 0 e na S0, trocar 'comandos 1 a 8 e 12 do R1b 16' pela lista da seção 'Comandos da sonda (corrigidos)' deste parecer, que inclui o comando das teclas. Acrescentar a instrução: no primeiro comando o jogo pergunta 'Allow custom scripts?'; responder Yes e colar de novo. Só depois disso vale o critério '/run bloqueado'. |
| V1-05 | 8.2; Apêndice A S2 | importante | lacuna | O design deixa para a sonda descobrir se o clique sai ao apertar, ao soltar ou nos dois. Isso é escolha do addon: depende de `RegisterForClicks`, e o `OnClick` recebe `down`. Registrar as duas fases gera dois `OnClick` por tecla e fere o invariante I1. | `UI/Blizzard_GamepadSharedUtility/InputHandlers/InputButtonUtility.lua:24, 33-40`; `UI/Blizzard_GamepadSharedUtility/InputBindingStack/InputFunctionBinding.lua:28-50`; `UI/Blizzard_FrameXML/SecureTemplates.lua:792-811` | Na 8.2, fixar: botões de ação com `RegisterForClicks('LeftButtonUp')` na criação, quinto argumento do binding `'LeftButton'`, e `OnClick(self, botao, down)` que ignora `down` verdadeiro. Na S2, trocar 'ao apertar, ao soltar ou nos dois' por: 'a soltura satisfaz a função de ação e tecla segurada gera um clique só; se não, repetir com `LeftButtonDown`'. Registrar que a CVar `ActionButtonUseKeyDown` só vale para botão seguro. |
| V1-06 | regra 16; 4.1 (Teclas, Janela); 11.5 | importante | lacuna | A regra 16 proíbe mexer em binding em combate, mas o design não diz o que acontece se o leilão abrir ou fechar em combate. Se soltar os bindings falhar, B, C, N, L, P e as outras ficam presas aos botões do addon depois de a janela fechar. | base 3.4 ('Em combate, mudar binding falha'); R10b 2 e incógnita 2; `UI/Blizzard_RestrictedAddOnEnvironment/RestrictedFrames.lua:79-99, 537-561`; design 4.1 linhas 20 e 26 | Em `Teclas.lua` (4.1 e 8.2), acrescentar: ligar e soltar só com `InCombatLockdown()` falso; se o evento chegar em combate, marcar pendente e executar em `PLAYER_REGEN_ENABLED`. Todo `OnClick` começa conferindo janela aberta e leilão aberto; fora disso é inerte. Acrescentar à S2: abrir e fechar o leilão em combate e anotar o que acontece. |
| V1-07 | 10 (registro Fatura, conciliação); 7.6; 5.3 | importante | fato_errado | A fatura tem 12 retornos e três tipos. O valor da venda está em `bid`, não no arremate; o recebido é `bid + deposit - consignment`. O tipo `seller_temp_invoice` é a carta de venda pendente, sem dinheiro. `count` e `commerceAuction` marcam venda de várias unidades. O design não tem nada disso. | `UI/Blizzard_MailFrame/MailFrame.lua:790-866` (836 e 852 para a soma; 832 para `bid / count`); `GS:1295` | Na seção 10, trocar os campos da Fatura por: tipo (`buyer`, `seller`, `seller_temp_invoice`), `bid`, `buyout`, `deposit`, `consignment`, `moneyDelay`, `etaHour`, `etaMin`, `count`, `commerceAuction`. Na 7.6, corte = `consignment / bid`. Na conciliação, a carta pendente não entra na soma e alimenta o ouro a caminho e o atraso. O nome do jogador não é gravado. |
| V1-08 | 5.2; 5.1 plano A | importante | lacuna | Os resultados do resumo também mudam quando chega resposta de busca de item ou commodity, segundo o comentário da Blizzard: na fase FOCO o addon pode receber `AUCTION_HOUSE_BROWSE_RESULTS_UPDATED` sem ter pedido resumo. O design diz que o resumo 'não traz identificação' e ignora o evento, feito para addons, que diz de que consulta é a resposta. | `AH/BrowseResultsFrame.lua:7-13, 103-136`; `AH/ItemBuyFrame.lua:11, 78-79`; AD:1196-1204; AD:1141-1148 | Na 5.2, escrever: resposta de resumo é `AUCTION_HOUSE_NEW_RESULTS_RECEIVED` com payload nil; com `itemKey` é resposta de busca. Fora do estado RESUMO, `..._BROWSE_RESULTS_UPDATED` é ignorado. Páginas seguintes vêm no payload de `..._BROWSE_RESULTS_ADDED`; `GetBrowseResults()` só no primeiro. Na 5.1, a consulta leva `sorts` e os sete filtros de qualidade, como a Blizzard. |
| V1-09 | 5.1 plano C; 5.3; 7.2 | importante | lacuna | 'Resposta completa' não está ligada a nenhuma função. A escada vem em páginas (`HasFull...SearchResults`, `RequestMore...`). A referência fraca por 'outras variantes do mesmo itemID' pede `SendSellSearchQuery` com nível e sufixo zerados, que o design não cita. `ITEM_SEARCH_RESULTS_UPDATED` com `newAuctionID` é atualização de um leilão, não resposta. | `AH/CommoditiesList.lua:78-80, 100-107`; `AH/ItemBuyFrame.lua:60-73, 98-110`; `AH/ItemSellFrame.lua:362-393`; `AH/Util.lua:484-498`; `AH/Frame.lua:748-749`; AD:1046-1049 | Na 5.1 e na 5.3, definir: foto completa é `HasFullCommoditySearchResults(itemID)` ou `HasFullItemSearchResults(itemKey)` verdadeiro; senão a foto vale só para a frente lida e a cauda vem de `GetCommoditySearchResultsQuantity`. Cada `RequestMore...` conta no orçamento. Na 7.2, a referência fraca usa `SendSellSearchQuery` com a chave sem nível e sem sufixo. Evento com `newAuctionID` não fecha a espera. |
| V1-10 | 2.2 H-14; 7.2; 18 DD3 | importante | fato_errado | O design diz que a ordem entre preços iguais é incógnita sem nada oficial e modela o mais antigo vendendo primeiro. O cliente tem texto próprio, usado pelo painel de venda: o leilão postado depois, no mesmo preço, vende primeiro. | `GS:1291` (AUCTION_HOUSE_UNDERCUT_TUTORIAL); `AH/SellFrame.lua:346-351, 507-518`; `AH/ItemSellFrame.lua:326`; `AH/CommoditiesSellFrame.lua:70`; base 2.17; design 7.2 | Na H-14, trocar a hipótese por: 'o mais novo vende primeiro, como o texto do cliente afirma; a S10 confirma'. Na 7.2, citar o texto como fonte da regra `igualar` e tirar 'a ordem é incógnita' do motivo de não escolher. Manter o pior caso só na conta de fila. Levar o texto ao dono na DD3. |
| V1-11 | 2.2 H-17; 8.3; Apêndice A S8 | menor | risco | O design testa primeiro `StartCommoditiesPurchase` com dois argumentos e só depois com três. A única chamada que existe no cliente tem três. Como a função falha em silêncio, um teste de dois argumentos sem cotação não distingue 'faltou o terceiro' de 'a tecla não vale'. | `AH/Frame.lua:844-848`; `AH/CommoditiesBuyFrame.lua:132-142`; AD:1079-1088; base 2.12 | Na S8 e na H-17, inverter a ordem: a primeira cotação usa a forma da tela da Blizzard, `StartCommoditiesPurchase(itemID, n, unitario)`, com o unitário da escada arredondado pelo tick. Se a cotação chegar, repetir com dois argumentos e gravar a diferença. O `Acoes.lua` adota a forma que a S8 mostrar; sem medida, vale a de três. |
| V1-12 | 8.3 Postar e Comprar commodity; 2.2 H-15; Apêndice A S2, S8 | menor | lacuna | A máquina não conhece o multisell: `PostItem` com quantidade maior que 1 cria vários leilões e vários ecos numa chamada. O eco de `PostCommodity` não aparece em nenhum uso da Blizzard, e a S2 posta um item só. `COMMODITY_PURCHASED(itemID, quantity)` existe e o design não o grava. | `AH/ItemSellFrame.lua:74-83, 98-116, 517-525`; AD:1313-1339, 1386-1395; `AH/Frame.lua:433-434` | Na 8.3, fixar `quantity = 1` em toda chamada de `PostItem` e tratar `AUCTION_MULTISELL_START` como estado inesperado, que vai a INCERTO. Na S2, postar um item e uma commodity e gravar todos os eventos entre a tecla e o eco. Na S8, gravar também `COMMODITY_PURCHASED` e `AUCTION_HOUSE_SHOW_COMMODITY_WON_NOTIFICATION`. Na H-15, citar o multisell como lido no código. |
| V1-13 | 8.3 Cancelar e Comprar item; 9.4 | menor | lacuna | `AUCTION_HOUSE_SHOW_ERROR` não traz o leilão: com a tela da Blizzard aberta, erro alheio derruba a ação do addon. E dois códigos têm sentido próprio que o design não usa: `ItemHasQuote` (comprador com transação pendente) e `DatabaseError` (o 'Internal auction error' da base 1.11). | AD:1252-1260; `AH/Util.lua:634-660`; `GS:7836`; `GS:7827`; base 1.11 | Na 8.3, gravar o código do erro em toda FALHOU. Em Cancelar, `ItemHasQuote` vira `KEEP - buyer pending`, sem nova tentativa. Em Postar equipamento, `DatabaseError` mostra `MATCH THE LOWEST PRICE`. Erro que chega sem ação em voo é só registrado como `outside`. |
| V1-14 | regra 10; 16 (checador) | menor | lacuna | A lista proibida não cobre funções que existem no cliente e fazem o que a seção 0 proíbe: vender ao NPC, recomprar, apagar ou devolver carta, abrir tudo, rodar macro. | `LISTA:78, 2823, 2891, 5169, 6389, 6392, 6605`; `DOC/MerchantFrameDocumentation.lua:86` (R1c 10); R1c 1 (`C_Mail.SetOpeningAll`) | Na regra 10, acrescentar: `SellAllJunkItems`, `BuybackItem`, `DeleteInboxItem`, `ReturnInboxItem`, `TakeInboxTextItem`, `SetOpeningAll`, `RunMacro`, `RunMacroText`, `DeleteCursorItem`, `SetOverrideBinding` fora da forma `Click` e `CancelSell` fora de `Acoes.lua`. O `checar-pregao.mjs` compara por trecho de nome, para pegar as formas com prefixo `C_`. |
| V1-15 | 2.2 H-19, H-20; 11.5 | menor | melhoria | Três pontos tratados como hipótese já têm resposta no código: `GetCurrentKeyBoardFocus` existe e a Blizzard a usa; `GetTimePreciseSec` é melhor que `debugprofilestop`, que zera com `debugprofilestart` de qualquer addon; `ReloadUI` é Lua sobre `C_UI.Reload`, sem marca de restrição. | `UI/Blizzard_Game/Mainline/EventImplementation.lua:117-136`; `LISTA:5375`; `DOC/FrameScriptDocumentation.lua:533-540`; `DOC/OsDocumentation.lua:27-34`; `UI/Blizzard_SharedXML/InterfaceUtil.lua:1-3` | Na 11.5, trocar 'se o addon conseguir ler onde está o foco (hipótese)' por 'lê o foco com `GetCurrentKeyBoardFocus()`'. Na H-20 e na regra 15, fixar `GetTimePreciseSec` e deixar a contagem de linhas como reserva. Na H-19, registrar que só o tempo do reload segue por medir. |
| V1-16 | 2.2 H-11; Apêndice A S7; 11.3 Mail | menor | lacuna | A S7 testa 'fatura antes de abrir a carta' como uma coisa só. No código há dois passos: `GetInboxText` devolve `isInvoice` e só então vem `GetInboxInvoiceInfo`. O cabeçalho tem `wasRead` e `textCreated`: ler o texto pode marcar a carta. E `GetInboxNumItems` devolve dois números: cartas mostradas e total. | `UI/Blizzard_MailFrame/MailFrame.lua:18, 317-335, 573-576, 583-585, 766, 781-790` | Na S7, medir em ordem: `GetInboxInvoiceInfo(i)` direto; depois `GetInboxText(i)` seguido da fatura; gravar `wasRead` e `textCreated` antes e depois de cada um. Se ler o texto mudar o cabeçalho, o `Correio.lua` usa só a primeira forma ou fica nos cabeçalhos. No painel Mail, quando o total passar do mostrado, dizer `MORE MAIL WAITING` e não fechar a conciliação. |
| V1-17 | regra 14; 6; 13 | menor | risco | Os arquivos puros rodam em Lua 5.1 no jogo e 5.3 na bancada. Divisão e `tostring` diferem: 10/2 vira '5' numa e '5.0' na outra, e `%d` com fração dá erro na 5.3. Isso quebra 'replay igual ao papel'. Arquivo Lua, inclusive o SavedVariables, tem teto de cerca de 262 mil constantes por função. | regra 14 do design; seção 16 (replay); R4a 4 (fengari 5.3); limite da linguagem Lua 5.1 (fora da base: tratar como hipótese a medir na S1) | Na regra 14, acrescentar: nos arquivos puros, todo número que vira texto passa por `math.floor` e `string.format('%d')`; proibidos `unpack`, `loadstring`, `bit`, `//`, operadores de bit e `goto`. Na seção 6, limitar o banco a 100 mil entradas de texto e medir na S1 a carga com 5 MB no formato real. |
| V1-18 | 8.3; 5.1; regra 17 | menor | melhoria | Detalhes de contrato que o implementador sem contexto vai errar: `IsSellItemValid` mostra erro na tela se o segundo argumento faltar; `GetItemCommodityStatus` pode devolver `Unknown`; `sorts` é obrigatório; a Blizzard relê com `Refresh...`, não com nova busca; quatro eventos estão abreviados nos diagramas. | AD:809-823; `ContainerFrame.lua:1555`; `AH/Frame.lua:613-616, 746-757, 828-842`; AD:914-921 | Na 8.3, escrever `IsSellItemValid(item, false)`, `Unknown` bloqueia com `Item data not loaded`, e os nomes de evento por extenso. Na 5.1, `sorts = {}` ou os da Blizzard em toda consulta, e o plano D usa `RefreshCommoditySearchResults` ou `RefreshItemSearchResults` quando `HasSearchResults` for verdadeiro. Na regra 17, ler o preço de vendedor pelo link do item. |
| V1-19 | 2.2 H-09, H-10, H-12; 7.6 | menor | melhoria | Os textos do cliente e a tela do correio já respondem partes que o design lista como a medir: cancelar perde o depósito, a venda devolve, o item cancelado e o comprado têm assunto de correio próprio, e a venda pendente traz a hora da entrega. | `GS:3390`; `MailFrame.lua:836, 847-856`; `GS:1309`, `GS:1338`, `GS:1295`, `GS:1278` | Na 2.2, reescrever H-09, H-10 e H-12 com o que o cliente já afirma e deixar para a sonda só o valor (corte, expiração, minutos de atraso). Na 7.6, a linha 'Atraso do correio' passa a ler `etaHour` e `etaMin` da carta pendente e o `timeLeftSeconds` do leilão vendido. |
