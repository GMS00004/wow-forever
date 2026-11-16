> Relatório de pesquisa de 2026-11-16, da onda 1 do design do PregaoForever, gravado como estava (foto do dia). `<espelho>`, `<dados>` e `<tmp>` eram pastas temporárias da sessão; o Apêndice D do `DESIGN.md` diz como refazê-las. Onde este relatório e o `DESIGN.md` divergem, vale o `DESIGN.md`.

# R1b: o UI da Blizzard e a API de leilão no Forever

Data de leitura: 2026-11-16. Tudo abaixo é leitura de arquivo local (marca `local`), salvo quando marcado `inferencia`. Nada foi testado no jogo e nada foi buscado na web.

## Convenções

- Raiz do espelho: `<espelho>/Interface/AddOns/`. Abaixo, `AHUI/` = `Blizzard_AuctionHouseUI/`; `DOC/` = `Blizzard_APIDocumentationGenerated/`.
- Siglas de arquivo (todas dentro de `AHUI/Shared/`, prefixo `Blizzard_AuctionHouse`): F = `Frame.lua`, S = `SellFrame.lua`, IS = `ItemSellFrame.lua`, CS = `CommoditiesSellFrame.lua`, CB = `CommoditiesBuyFrame.lua`, D = `BuyDialog.lua`, IB = `ItemBuyFrame.lua`, BR = `BrowseResultsFrame.lua`, SB = `SearchBar.lua`, IL = `ItemList.lua`, A = `AuctionsFrame.lua`, T = `TableBuilder.lua`, U = `Util.lua`, ST = `SharedTemplates.lua`, MS = `Multisell.lua`. `CA` = `AHUI/Camelot/Blizzard_AuctionData.lua`. `AD` = `DOC/AuctionHouseDocumentation.lua`. `ENUM` = `DOC/AuctionHouseEnumsDocumentation.lua`.
- O espelho é "build 70938" pelo brief; o arquivo `version.txt` não existe na pasta, então a versão do espelho não foi confirmada por mim. Uma nota antiga do projeto (`C:/GMS/Claude Code Projects/wow/comum/referencia/api-forever.md`:57) fala em espelho do build 70009. Tratar tudo como "o espelho", não como o cliente vivo.
- Textos de interface (`AUCTION_DURATION_*`, `AUCTION_CATEGORY_*`, `ERR_AUCTION_*`) são GlobalStrings e NÃO estão no espelho. Onde o texto importa, virou incógnita.

---

## 1. TOC: o que carrega no tipo de jogo camelot

Arquivo: `AHUI/Blizzard_AuctionHouseUI.toc`.

### Regra das marcações (inferência, a partir de padrões repetidos em vários TOCs)

| Marcação | Leitura | Evidência | Marca |
|---|---|---|---|
| `Shared\x` sem sufixo | Carrega em todo tipo de jogo permitido pelo cabeçalho | toc:11, 13, 16... | local |
| `[Family]\x` | `[Family]` é trocado pela pasta da "família" do tipo de jogo. Para camelot a família é `Mainline` (a pasta `Classic` NÃO carrega) | toc:12, 14, 17...; a nota do projeto `api-forever.md`:59-60 diz o mesmo para StatusTrackingBar e QuestInfo | inferencia |
| `[Game]\x [AllowLoadGameType camelot]` | `[Game]` vira a pasta do próprio tipo (`Camelot`); só carrega em camelot | toc:15; mesmo padrão em `Blizzard_Game/Blizzard_Game.toc`:16-20 | local (padrão) / inferencia (semântica) |
| `[ExcludeLoadGameType camelot]` | A linha é pulada em camelot | toc:14 | local |
| `[Bootstrap]` | Marca o arquivo que roda mesmo com `LoadOnDemand: 1`, para registrar a abertura do leilão e carregar o resto sob demanda | toc:10 + `Shared/Blizzard_AuctionHouseUI_Bootstrap.lua`:1-43 (`AuctionHouseFrame_LoadUI` chama `LoadAddOnWithErrorHandling`) | inferencia |
| `## AllowLoadGameType:` no cabeçalho | Lista de tipos que podem carregar o addon | toc:9 diz `mainline, cata, mists`, SEM camelot | local |

Ponto de atenção: o cabeçalho (toc:9) não lista camelot, mas as linhas 14 e 15 falam de camelot. Não é exceção: `Blizzard_FriendsFrame.toc` tem cabeçalho `mainline` e `Blizzard_AchievementUI.toc` tem `mainline, tbc, wrath, cata, mists`, e os dois têm linhas camelot (varredura com grep nos TOCs). Minha leitura é que camelot é aceito onde o cabeçalho lista `mainline`. Isso é inferência; vira incógnita 1 (conferir no jogo).

### Arquivos que carregam em camelot (assumindo `[Family]` = Mainline)

| Ordem (toc) | Arquivo | Linha toc |
|---|---|---|
| 1 | `Shared/..._UI_Bootstrap.lua` | 10 |
| 2-3 | `Shared/Util.lua`, `Mainline/Util.lua` | 11-12 |
| 4 | `Shared/Blizzard_AuctionData.lua` (constantes e `AuctionCategoryMixin`) | 13 |
| (pulado) | `Mainline/Blizzard_AuctionData.lua` | 14 (Exclude camelot) |
| 5 | **`Camelot/Blizzard_AuctionData.lua`** (a árvore de categorias do Forever) | 15 |
| 6-9 | `Shared/SharedTemplates.lua`/`.xml`, `Mainline/SharedTemplates.lua`/`.xml` | 16-19 |
| 10-13 | `Shared/TableBuilder.lua`/`.xml`, `Shared/Tab.lua`, `Mainline/Tab.xml` | 20-23 |
| 14-15 | `Shared/ItemList.lua`, `Mainline/ItemList.xml` | 24-25 |
| 16-18 | `Shared/CategoriesList.lua`, `Mainline/CategoriesList.lua`/`.xml` | 26-28 |
| 19-30 | `Shared/` SearchBar, BrowseResultsFrame, CommoditiesList, ItemBuyFrame, SellFrame, CommoditiesSellFrame, CommoditiesBuyFrame, ItemSellFrame | 29-44 |
| 31-32 | `Shared/AuctionsFrame.lua`, `Mainline/AuctionsFrame.xml` | 45-46 |
| 33-34 | `Shared/WoWTokenFrame.lua`/`.xml` | 47-48 |
| 35-38 | `Shared/BuyDialog.lua`/`.xml`, `Shared/Multisell.lua`, `Mainline/Multisell.xml` | 49-52 |
| 39-41 | `Shared/Frame.lua`/`.xml`, `Localization.lua` | 53-55 |

Resposta direta: o Forever carrega `Camelot/Blizzard_AuctionData.lua` (toc:15) e, da pasta `Mainline`, os arquivos Util, SharedTemplates (lua e xml), Tab.xml, ItemList.xml, CategoriesList (lua e xml), AuctionsFrame.xml e Multisell.xml. Nada da pasta `Classic`. Marca: inferencia (depende de Family = Mainline).

Reforços de que Family = Mainline para o leilão do Forever (todos local, leitura de código):
- `Mainline/Util.lua`:7-19 lista os filtros `CurrentExpansionOnly`, `UpgradesOnly` e `LegendaryCraftedItemOnly`; `Classic/Util.lua`:7-15 não tem (usa `Enum.ItemQuality.Standard/Good`).
- `Blizzard_Game/Mainline/EventRouting.lua`:12-16 roteia `AUCTION_HOUSE_SHOW/CLOSED/DISABLED` e as duas notificações; `Camelot/` e `Hardcore/` do `Blizzard_Game` não têm nada de leilão (grep "auction" vazio), e o `Classic` chamaria `IsUsingLegacyAuctionClient()` (`Classic/EventImplementation.lua`:100-114).
- O brief informa que o UI é o do retail 12.1.5 com `AuctionHouseFrame`.

Efeitos que importam do `Mainline` (local): categorias de gemas, glifos, pets e "Item Enhancement" de topo não existem no Forever porque o `CA` não as cria (ver item 9), mesmo que `U`:178-201 saiba convertê-las.

---

## 2. Durações de leilão

| Fato | Evidência | Marca |
|---|---|---|
| O UI oferece exatamente 3 durações, como radio num dropdown, com os textos `AUCTION_DURATION_ONE`, `_TWO`, `_THREE`. O valor passado à API é o ÍNDICE (1, 2 ou 3), não horas | `S`:163-172 (loop `ipairs({AUCTION_DURATION_ONE, AUCTION_DURATION_TWO, AUCTION_DURATION_THREE})`; `SetSelected(index)`) | local |
| Os tipos nas assinaturas são `luaIndex` | `AD`:18 (CalculateCommodityDeposit), :35 (CalculateItemDeposit), :102/:116 (ConfirmPost*), :872/:891 (PostCommodity/PostItem) | local |
| A escolha fica no CVar `auctionHouseDurationDropdown`, padrão `"2"` (segundo item), gravado a cada troca | `S`:176-190; `C:/GMS/Claude Code Projects/wow/modder/ferramentas/guia/api-forever/CVars.lua`:76 | local |
| `GetDuration()` do sell frame devolve esse índice e vai para PostItem/PostCommodity e para as calculadoras de depósito | `S`:435-437; `IS`:432-434, :480-487; `CS`:84-86, :108-115 | local |
| As horas de cada índice NÃO estão no espelho (GlobalStrings ausentes). A hipótese 2h/8h/24h não pôde ser confirmada nem negada | grep `AUCTION_DURATION_ONE` só acha o uso em `S`:166 | local (ausência) |
| Há 4 faixas de tempo restante na leitura (Short, Medium, Long, VeryLong); `GetTimeLeftBandInfo(band)` devolve min e máx em segundos | `ENUM`:138-148; `AD`:687-702; `U`:249-261 | local |

Sequência no UI: clique em "Postar" -> `PostItem()` -> `StartPost(self:GetPostDetails())` -> `C_AuctionHouse.PostItem(item, duration, quantity, bid, buyout)` ou `PostCommodity(item, duration, quantity, unitPrice)` (ver item 6).

Incógnita 2 (horas por índice) e incógnita 3 (CVar/duração no PostItem coincidem com o dropdown).

---

## 3. Commodities

| Fato | Evidência | Marca |
|---|---|---|
| O UI tem os dois caminhos completos (commodity e item). A decisão é feita ao colocar o item no painel de venda, por `C_AuctionHouse.GetItemCommodityStatus(itemLocation)`: `Unknown` aborta (sem dados do item); `Commodity` abre `CommoditiesSellFrame` e `CommoditiesSellList` (por itemID); `Item` abre `ItemSellFrame` | `F`:608-631 (status em :613; Unknown :614-616; Commodity :623-626; Item :627-630) | local |
| `ItemCommodityStatus`: Unknown 0, Item 1, Commodity 2 | `AD`:1526-1537 | local |
| Na compra a decisão vem do resultado de busca: `itemKeyInfo.isCommodity` (de `GetItemKeyInfo`) escolhe `CommoditiesBuyFrame` ou `ItemBuyFrame` | `F`:683-695 (:685-686) | local |
| O servidor do Forever marca algum item como commodity? O código suporta, mas o espelho não diz quais itens | só se pode conferir no jogo | incógnita 4 |
| O `CA` é de categorias "Classic" (projétil, aljavas, receitas por perícia). Ele não tem `Gems`, `Glyphs`, `BattlePets` | `CA`:17-222 | local |
| Para commodity o UI trata o preço como "preço unitário" e o total é soma sobre os lotes: `AggregateSearchResultsByQuantity` desconta `numOwnerItems` (não compra os próprios lotes) | `U`:207-230 (:217) | local |
| Listas de commodity não têm coluna ordenável (sort `nil`); as ordens padrão só existem para contextos de browse, item e owned; commodity manda `sorts = {}` | `T`:1031-1034, :1076-1078, :1084-1092; `F`:166-208 (os contextos `BuyCommodities`, `SellCommodities`, `AuctionsCommodities` ficam com tabela vazia no loop de :195-196) | local / inferencia |

---

## 4. Compra de commodity: sequência exata

Fluxo com linhas (tudo local, leitura de código):

1. Usuário escolhe quantidade em `CommoditiesBuyFrame`; o total vem de `AggregateSearchResultsByQuantity` (`CB`:103-126, `U`:207-230). O preço unitário é "saneado" por `SanitizeAuctionHousePrice` (`CB`:124, `U`:618-624).
2. Clique em Comprar -> `CB`:10-15 -> `CB`:132-142 `StartCommoditiesPurchase()` lê itemID, quantidade, unitPrice e totalPrice da tela -> `F`:844-848:
   ```lua
   self.BuyDialog:SetItemID(itemID, quantity, unitPrice, totalPrice);
   self.BuyDialog:Show();
   C_AuctionHouse.StartCommoditiesPurchase(itemID, quantity, unitPrice);
   ```
   Divergência: o UI passa 3 argumentos (o terceiro, `unitPrice`), mas `AD`:1084-1088 documenta só 2 (`itemID`, `quantity`). O terceiro é ignorado ou a documentação está defasada (incógnita 5).
3. Diálogo (`D`): estado `WaitingForQuote` (`D`:178-180, :260) com preview do total da tela. Registra `COMMODITY_PRICE_UPDATED`, `COMMODITY_PRICE_UNAVAILABLE`, `COMMODITY_PURCHASE_SUCCEEDED`, `COMMODITY_PURCHASE_FAILED` (`D`:87-92).
4. `COMMODITY_PRICE_UPDATED(updatedUnitPrice, updatedTotalPrice)` (`AD`:1362-1372), tratado em `D`:140-155:
   - novo unitário > preço atual x 1,05 (`MAXIMUM_PREVIEW_PRICE_DIFFERENTIAL = 1.05`, `D`:3) -> estado `PriceUnavailable` (botão só "Ok", texto `AUCTION_HOUSE_DIALOG_PRICE_UNAVAILABLE`);
   - novo unitário > atual, mas dentro de 5% -> estado `PriceUpdated`: o total na tela passa ao novo valor, aparece o aviso `AUCTION_HOUSE_DIALOG_PRICE_UPDATED` com tooltip de aumento por unidade e total (`D`:20-27, :32-44), e o botão Comprar continua habilitado;
   - igual ou menor -> `PriceConfirmed`, botão habilitado. Observação (inferência): se o preço baixou, o diálogo NÃO atualiza o total na tela para o valor menor (só atualiza no caso de aumento).
5. Enquanto o estado é `PriceConfirmed` ou `PriceUpdated`, o `OnUpdate` chama `GetQuoteDurationRemaining()` a cada frame (`D`:121-129, :237-238). Os segundos só aparecem na tela quando <= 10 (`REMAINING_QUOTE_DURATION_THRESHOLD`, `D`:2, :131-137). Quando chega a 0, o diálogo se fecha sozinho. Quanto vale a cotação total (45 s?) não está no espelho (incógnita 6).
6. Clique em Comprar agora -> `D`:63-66 -> `BuyNow()` (`D`:263-270): estado `Purchasing`, chama `C_AuctionHouse.ConfirmCommoditiesPurchase(itemID, quantity)` e arma `C_Timer.NewTimer(2, ...)` que, se ainda não houve resposta, coloca o estado `Waiting` (spinner e overlay escuro).
7. Resultado: `COMMODITY_PURCHASE_SUCCEEDED` -> toca som e `self:Hide()` (`D`:158-160). `COMMODITY_PURCHASE_FAILED` -> estado `PriceUnavailable` (`D`:161-162), ou seja, o UI não distingue falha por preço de outras falhas.
8. `OnHide` do diálogo SEMPRE chama `C_AuctionHouse.CancelCommoditiesPurchase()`, refaz a busca (`RefreshSearchResults(BuyCommodities, MakeItemKey(itemID))`) e cancela o timer (`D`:108-119). Isto vale também após sucesso.
9. Após sucesso, `CB`:94-97 zera a quantidade para 1. Chat: `AUCTION_HOUSE_SHOW_COMMODITY_WON_NOTIFICATION(commodityName, commodityQuantity)` imprime `ERR_AUCTION_COMMODITY_WON_S` (`F`:438-440).
10. O botão Comprar fica desabilitado se o total > dinheiro (`D`:229-235, `CB`:54-62).

Eventos `COMMODITY_PURCHASED(itemID, quantity)` e `ITEM_PURCHASED(itemID)` existem (`AD`:1385-1395, :1442-1451), mas o UI da Blizzard não os usa (grep sem resultado fora do `AD`).

---

## 5. Compra de item (lance e arremate)

| Etapa | Evidência | Marca |
|---|---|---|
| Lance (`BidFrame`) e arremate (`BuyoutFrame`) chamam `PlaceBid()`/`BuyoutItem()` de `AuctionHouseBuySystemMixin`. Se o valor do lance é >= buyout (e há buyout), vira arremate; se < `minBid` mostra `AUCTION_HOUSE_BID_AMOUNT_IS_TOO_LOW`; senão `StartItemBid` | `U`:117-136 | local |
| `StartItemBid` -> popup `BID_AUCTION` (`StaticPopup_Show`), `OnAccept` = `C_AuctionHouse.PlaceBid(data.auctionID, data.bid)` | `F`:42-57 (:47), :850-857 | local |
| `StartItemBuyout` -> popup `BUYOUT_AUCTION`, `OnAccept` = `PlaceBid(data.auctionID, data.buyout)`. O arremate é um PlaceBid com o valor do buyout | `F`:10-12, :26-40, :859-866 | local |
| O popup de arremate usa spinner: espera `AUCTION_HOUSE_PURCHASE_COMPLETED(auctionID)` do mesmo leilão (conclui) ou `AUCTION_HOUSE_SHOW_ERROR` (fecha); o spinner aparece depois de 2 s | `F`:14-24, :31; `Blizzard_StaticPopup/StaticPopup.lua`:1003-1044 | local |
| O popup de lance (`BID_AUCTION`) NÃO tem spinner; o resultado vem por `BIDS_UPDATED`/`BID_ADDED` e a notificação `BidPlaced` | `F`:42-57; `F`:315-318; `ChatFrameUtil`:5-6 | local / inferencia |
| Existe um popup extra `PURCHASE_AUCTION_UNIQUE` (aceitar após 3 s) para itens craftados únicos de Shadowlands (limit category 481). Em Forever tende a ser irrelevante | `F`:59-75, :868-876; `U`:666-678 | local |
| Erros de leilão chegam por `AUCTION_HOUSE_SHOW_ERROR(error)` e viram texto de `UIErrorsFrame` via `AuctionHouseUtil.GetErrorText` (27 códigos, de NotEnoughMoney a ItemBoundToAccountUntilEquip) | `F`:435-437; `U`:634-664; `ENUM`:18-51 | local |
| Lista de leilões de item: carrega mais resultados ao rolar, quando faltam menos de 30 linhas (`RequestMoreItemSearchResults(itemKey)` devolve `hasFullResults`) | `IB`:2, :102-111 | local |
| Campos de cada linha: `auctionID`, `minBid`, `bidAmount`, `buyoutAmount`, `bidder` (GUID), `timeLeft` (faixa), `timeLeftSeconds`, `owners`, `containsOwnerItem`, `containsAccountItem`, `quantity`, `itemLink` | `AD`:1664-1685 | local |
| Não se pode dar lance no próprio leilão nem com dinheiro insuficiente (campo desabilitado com tooltip) | `ST`:676-693 | local |

---

## 6. Venda

### Argumentos que o UI passa

| Chamada | Argumentos | Onde | Marca |
|---|---|---|---|
| `PostItem` | `(itemLocation, duration(índice), quantity, bid|nil, buyout|nil)`. Lance e buyout valem `nil` quando o campo é 0 | `IS`:443-456, :480-487, :494 | local |
| `PostCommodity` | `(itemLocation, duration(índice), quantity, unitPrice)` | `CS`:108-115, :122 | local |
| Retorno de ambos: `needsConfirmation` (bool) | `AD`:877-880, :897-900 | local |
| `ConfirmPostItem(item, duration, quantity, bid, buyout)`; `ConfirmPostCommodity(item, duration, quantity, unitPrice)` | `AD`:93-121 | local |

Regras do UI antes de postar: precisa de item válido, depósito <= dinheiro, quantidade >= 1, `IsThrottledMessageSystemReady()` verdadeiro (senão tooltip `ERR_GENERIC_THROTTLE`), preço > 0; no item, buyout > lance quando ambos existem (`S`:471-492; `IS`:458-478; `CS`:94-106).

### Fluxo de confirmação

1. `StartPost(...)`: se `C_AuctionHouse.PostItem(...)`/`PostCommodity(...)` devolve verdadeiro, o UI guarda os argumentos (`CachePendingPost`) e espera; se devolve falso, limpa (`ClearPost`) (`IS`:489-499; `CS`:117-127).
2. O evento `AUCTION_HOUSE_POST_WARNING` mostra o popup `AUCTION_HOUSE_POST_WARNING` com texto `CONFIRM_AUCTION_POSTING_TEXT` e overlay (`F`:100-117, :371, :441-442, :914-917). Ao aceitar: `CommoditiesSellFrame:ConfirmPost()` e, se não houver pendência, `ItemSellFrame:ConfirmPost()` (`F`:104-108), que chamam `ConfirmPostCommodity/ConfirmPostItem(SafeUnpack(pendingPost))` (`CS`:133-139; `IS`:505-511).
3. `AUCTION_HOUSE_POST_ERROR` mostra o popup de erro `AUCTION_POSTING_ERROR_TEXT` (`F`:119-129, :372, :443-444).
4. `AUCTION_HOUSE_AUCTION_CREATED(auctionID)` imprime `ERR_AUCTION_STARTED` no chat; o `AD`:1118 diz que o sinal "não é usado no UI base, mas incluído para addons" (o `F`:433-434 o usa só para a mensagem). Marca: local.
5. O que dispara o `POST_WARNING` (preço fora da curva? depósito alto?) e o texto do aviso não estão no espelho (incógnita 7).

### Multisell

- Eventos `AUCTION_MULTISELL_START(numRepetitions)`, `AUCTION_MULTISELL_UPDATE(createdCount, totalToCreate)`, `AUCTION_MULTISELL_FAILURE` (`AD`:1313-1339).
- No `IS`:98-116 o UI mostra a barra de progresso `AuctionHouseMultisellProgressFrame`, bloqueia o painel (`DisabledOverlay`) e trava novo post enquanto `multisellInProgress` (`IS`:119-128, :458-461). `MS`:15-30 é só a barra (usa `AUCTION_CREATING`). O 0.05 em `MS`:2 é passo de transparência, NÃO é taxa.
- Fechar a janela no meio chama `C_AuctionHouse.CancelSell()` (`IS`:74-86); `F`:608-610 recusa nova venda enquanto a barra existe.
- Multisell é só do caminho de ITEM (nenhum assinante no `CS`). Marca: local.

### Depósito

| Fato | Evidência | Marca |
|---|---|---|
| Item: `C_AuctionHouse.CalculateItemDeposit(itemLocation, duration, quantity)`. Commodity: `CalculateCommodityDeposit(itemID, duration, quantity)`. Ambos devolvem `depositCost` (pode ser nil na assinatura) | `IS`:426-436; `CS`:78-88; `AD`:10-43 | local |
| O depósito é exibido no campo "Depósito" e recalculado a cada mudança de quantidade, duração ou preço | `S`:338-353, :494-501 | local |
| Se NÃO `SupportsCopperValues()`, o UI arredonda o depósito exibido para cima, em prata | `S`:497-499 | local |
| `CanPostItem` exige `GetMoney() >= depósito` | `S`:477-480 | local |
| O depósito depende de duração e quantidade, mas NÃO de preço, pelas assinaturas (nenhum argumento de preço nas calculadoras) | `AD`:10-43 | local |

### Corte da casa (comissão na venda)

Buscas por `Cut`, `consignment`, `deposit`, `0.05`, `fee` em `AHUI/` e em `Blizzard_MoneyFrame/`: o UI NÃO calcula nem mostra comissão de venda. Só há:
- `AUCTION_CANCEL_COST = 5 --5% of the current bid` em `SA`:11 (`Shared/Blizzard_AuctionData.lua`). A constante não é usada em nenhum outro arquivo (grep); o custo real vem de `GetCancelCost` (item 10). É lixo herdado do UI Classic, mas dá uma pista de 5% do lance atual no cancelamento (inferencia, fraca).
- `AUCTION_HOUSE_INCOMING_AMOUNT` ("valor a receber") na coluna de lance de leilões vendidos (`T`:487-495), sem número.
- `Constants.AuctionConstants.DEFAULT_AUCTION_PRICE_MULTIPLIER = 1.5` (preço padrão sugerido = preço de venda ao NPC x 1,5, arredondado para cima em prata, mínimo 1 prata) (`DOC/AuctionHouseConstantsDocumentation.lua`:10; `S`:415-433).
- O corte de 5%/15%/etc. NÃO é derivável do UI. Conferir pelo valor recebido no correio (incógnita 8).

Dica de UI: se o preço digitado = menor preço do mercado menos 1 prata, aparece o tutorial "undercut" (`S`:346-351).

---

## 7. SupportsCopperValues

`C_AuctionHouse.SupportsCopperValues()` (`AD`:1090-1098) muda, no UI:

| Verdadeiro | Falso | Evidência | Marca |
|---|---|---|---|
| Mostra cobre nos campos de dinheiro do leilão (frames com `useAuctionHouseCopperValue = true`: caixas de preço da venda, do diálogo de compra, do frame principal e das células) | Esconde cobre (`hideCopper = true`) | `Blizzard_MoneyFrame/Shared/MoneyFrame.lua`:480-482; `MoneyInputFrame.lua`:44-46, :70-72; XMLs: `D.xml`:76, `F.xml`:194, `SellFrame.xml`:78, :146, `T.xml`:41 | local |
| Preços e depósitos usados como estão (`math.ceil(rawPrice)`) | Preço "saneado" para cima em prata inteira (`SanitizeAuctionHousePrice`) | `U`:618-624 | local |
| Depósito exibido exato | Depósito exibido arredondado para cima em prata | `S`:497-499 | local |
| Colunas de preço mais largas (browse 168 e quantidade 60; padding do buyout 20) | Larguras menores (146/83; padding 0) | `T`:1049-1052, :1127-1130 | local |
| Posição do rótulo "por item" ajustada (`PerItemPostfix`) | Posição original | `S`:88-91 | local |
| Campo de lance mostra cobre (`MoneyInputFrame_SetCopperShown`) | Esconde | `ST`:668-672 | local |

Implicação: o UI sempre assume que o preço mínimo é 1 prata quando falso (`GetDefaultPrice` arredonda para prata, `S`:427). O valor real em Forever é incógnita 9 (`/dump C_AuctionHouse.SupportsCopperValues()`).

---

## 8. Consulta, paginação e throttle

### Campos da consulta (`SendBrowseQuery`)

Montada em `F`:816-823 e definida em `AD`:1538-1550 (`AuctionHouseBrowseQuery`):

| Campo | Origem no UI | Evidência |
|---|---|---|
| `searchString` | texto da caixa de busca | `SB`:202-207 |
| `minLevel`, `maxLevel` | filtro de nível salvo (padrão 0 e 0), gravado em `g_auctionHouseFilters` (SavedVariablesPerCharacter) | `SB`:1-18, :198-207; toc:4 |
| `filters` | lista de `Enum.AuctionHouseFilter` marcados (padrão: as qualidades Poor...Artifact ligadas; `UncollectedOnly`, `UsableOnly`, `CurrentExpansionOnly`, `UpgradesOnly` desligados) + o filtro implícito da categoria | `Mainline/Util.lua`:21-33; `SB`:98-106; `F`:807-809 |
| `itemClassFilters` | lista `{classID, subClassID, inventoryType}` da categoria/subcategoria selecionada | `CategoriesList.lua`:169-187; `F`:804; `AD`:1560-1569 |
| `sorts` | até 2 `{sortOrder, reverseSort}` do contexto de busca | `F`:140-141 (`MaxNumAuctionHouseSortTypes = 2`), :213-235, :822 |

Um clique numa categoria NÃO dispara consulta; só a muda (`CategoriesList.lua`:148-163, sem chamada à API). A consulta sai no botão Buscar, no Enter da caixa, ou ao clicar no cabeçalho de ordenação (`F`:701-721).

Outras consultas:

| API | Quando o UI chama | Evidência |
|---|---|---|
| `SendSearchQuery(itemKey, sorts, separateOwnerItems [, minLevel, maxLevel])` | `QueryItem` quando o contexto não é por itemID; com níveis só em `BuyItems` | `F`:737-758 |
| `SendSellSearchQuery(itemKey, sorts, separateOwnerItems)` | `QueryItem` com `byItemID` verdadeiro; no `IS`:391-393 isso vale para equipamento (`isEquipment`), com a itemKey sem ilvl/sufixo (`U`:484-498) | `F`:748-749; `AD`:1049 |
| `separateOwnerItems` | verdadeiro só nos contextos `AuctionsItems` e `AuctionsCommodities` | `F`:747 |
| `RefreshCommoditySearchResults(itemID)` / `RefreshItemSearchResults(itemKey[, min, max])` | `RefreshSearchResults`: se já há resultados (`HasSearchResults`), refaz; senão faz `QueryItem` | `F`:828-842 |
| `RequestMoreBrowseResults()` | rolagem com menos de 30 linhas restantes e `HasFullBrowseResults()` falso | `BR`:2, :117-129 |
| `RequestMoreItemSearchResults(itemKey)` / `RequestMoreCommoditySearchResults(itemID)` | idem, limite 30 | `IB`:102-111; `IS`:376-386; `CommoditiesList.lua`:95-107 |
| `HasFullBrowseResults` e `HasFullItemSearchResults` | decide entre spinner ("resultados pendentes") e "Sem resultados" quando a lista está vazia | `IL`:346-351 |
| `SearchForFavorites(sorts)` | Ao abrir o leilão (se `HasFavorites()`) e no botão de favoritos | `F`:398-400, :771-775; `SB`:209-212 |

Resultados chegam por eventos: `AUCTION_HOUSE_BROWSE_RESULTS_ADDED(addedBrowseResults)` (acrescenta), `AUCTION_HOUSE_BROWSE_RESULTS_UPDATED` (relê `GetBrowseResults()`), `AUCTION_HOUSE_BROWSE_FAILURE` (mostra `ERR_AUCTION_DATABASE_ERROR`) (`BR`:73-82, :103-136); `ITEM_SEARCH_RESULTS_ADDED/UPDATED`, `COMMODITY_SEARCH_RESULTS_ADDED/UPDATED/RECEIVED` (`F`:310-322, :422-432; `CB`:94-101). `AD`:1196-1205: `AUCTION_HOUSE_NEW_RESULTS_RECEIVED(itemKey)` "não usado no UI base" e o payload é nil para browse.

### Throttle

| Fato | Evidência | Marca |
|---|---|---|
| A API documenta limite de 100 chamadas por minuto para `SendSearchQuery` e `SendSellSearchQuery` e manda usar `ReplicateItems` para varrer o leilão inteiro | `AD`:1034, :1049 | local |
| O UI usa `IsThrottledMessageSystemReady()` em UM lugar: `CanPostItem` do painel de venda (botão Postar desabilitado, tooltip `ERR_GENERIC_THROTTLE`) | `S`:487-489 | local |
| Os eventos `AUCTION_HOUSE_THROTTLED_SYSTEM_READY` e `AUCTION_HOUSE_THROTTLED_MESSAGE_SENT` só servem para reavaliar esse botão (`UpdatePostButtonState`) | `S`:259-263, :321-322 | local |
| `THROTTLED_MESSAGE_QUEUED`, `_DROPPED` e `_RESPONSE_RECEIVED` existem na API mas o UI não os escuta | `AD`:1283-1306; grep: nenhum uso | local |
| Buscas e atualizações NÃO verificam throttle no UI. O botão Atualizar (`RefreshButton`) só desabilita enquanto os resultados estão pendentes (`Deactivate`) | `ST`:635-652; `IL`:310-324 | local |
| Portanto o UI "espera" assim: para venda, desabilita o botão até chegar `SYSTEM_READY`; para compra e busca, não espera nada (a Blizzard confia no motor para enfileirar ou descartar) | `S`:316-324 | inferencia |
| Que a fila interna enfileira e quanto tempo dura cada espera é desconhecido (incógnita 10) | | |

---

## 9. Ordenações, filtros e a árvore de categorias do Forever

### Ordenações

`Enum.AuctionHouseSortOrder`: Price 0, Name 1, Level 2, Bid 3, Buyout 4, TimeRemaining 5 (`ENUM`:122-134). `AuctionHouseItemSortOrder`: Bid 0, Buyout 1 (`ENUM`:94-103). `AuctionHouseCommoditySortOrder`: UnitPrice 0, Quantity 1 (`ENUM`:6-15), mas o UI NÃO as usa.

Padrões (primário depois secundário) (`F`:198-206):
- Browse e Favoritos: Price, depois Name.
- Item (BuyItems, SellItems, AuctionsItems, BidItems): Buyout, depois Bid.
- Owned (AllAuctions, AllBids): Name, depois Price.
- Clicar num cabeçalho: coloca o novo no topo; se já era o primário, inverte; mantém no máximo 2 (`F`:213-235). As ordenações ficam em `g_auctionHouseSortsBySearchContext` (SavedVariables, toc:3), versão 2 (`F`:140).

Colunas com ordenação no UI: browse (Price, Name, Level), item (Bid, Buyout), leilões próprios (Name, Bid, Buyout, TimeRemaining) (`T`:976-1150).

### Filtros disponíveis

`Enum.AuctionHouseFilter` (`ENUM`:70-90): None, UncollectedOnly, UsableOnly, CurrentExpansionOnly, UpgradesOnly, ExactMatch, Poor/Common/Uncommon/Rare/Epic/Legendary/ArtifactQuality, LegendaryCraftedItemOnly. O menu lista o que `C_AuctionHouse.GetFilterGroups()` devolve (`SB`:165-173) com categorias Uncategorized, Equipment, Rarity (`AD`:1500-1512). Quais filtros o Forever devolve é incógnita 11. Há também faixa de nível (min e max) e `ExactMatch` na API (não ligado no menu do UI; marca: inferência por ausência de uso).

### Árvore de categorias (`CA`)

Constantes do `CA`: `AuctionHouse_ShouldUseRequiredLevel()` devolve verdadeiro (coluna "Nível requerido" no lugar de nível do item) (`CA`:4-6).

| # | Categoria (constante do texto) | Subcategorias | Linhas do CA |
|---|---|---|---|
| 1 | Armas (`AUCTION_CATEGORY_WEAPONS`), detalhe: nível requerido | **Uma mão**: Machado 1M, Maça 1M, Espada 1M, Adaga, Desarmado, Varinha. **Duas mãos**: Machado 2M, Maça 2M, Espada 2M, Haste, Cajado. **À distância**: Arcos, Bestas, Armas de fogo, Arremesso. **Diversos**: Vara de pescar; subcategoria "Outro" (filtra `Weapon.Generic`) | 17-49 |
| 2 | Armadura (`AUCTION_CATEGORY_ARMOR`) | **Placa, Malha, Couro, Tecido**: cada um com subcategorias por posição: Cabeça, Ombros, Peito (inclui Robe), Cintura, Pernas, Pés, Pulsos, Mãos, Relíquia. **Relíquia**: Ídolo, Livro (Libram), Totem. **Diversos** (subclasse Generic): Pescoço, Capa, Dedo, Trinket, Mão secundária (Holdable), Escudo, Camisa (Body) | 51-113 |
| 3 | Recipientes (`AUCTION_CATEGORY_CONTAINERS`), detalhe: espaços | **Padrão**: Bolsa, Alma (Soul). **Munição**: Aljava, Bolsa de munição. **Reagente**: Ervas, Encantamento, Engenharia, Mineração, Couro, Caixa de pesca, Culinária, Reagente | 115-162 |
| 4 | Consumíveis (`AUCTION_CATEGORY_CONSUMABLES`) | Gerado de `C_AuctionHouse.GetAuctionItemSubClasses(Consumable)`, exceto os dois de "Melhoria de item"; logo depois de Bandagem entra **Melhoria de item** com `ItemEnhancement` e `ItemEnhancementTemporary`. A lista real vem do servidor | 164-181 |
| 5 | Bens de comércio (`AUCTION_CATEGORY_TRADE_GOODS`) | Gerado de `GetAuctionItemSubClasses(Tradegoods)` | 183-186 |
| 6 | Projétil (`AUCTION_CATEGORY_PROJECTILE`) | Gerado de `GetAuctionItemSubClasses(Projectile)` | 188-191 |
| 7 | Receitas (`AUCTION_CATEGORY_RECIPES`), detalhe: perícia (`AUCTION_HOUSE_BROWSE_HEADER_RECIPE_SKILL`) | Gerado de `GetAuctionItemSubClasses(Recipe)`; "Livro" vai para o fim (sortIndex 100) | 193-205 |
| 8 | Itens de missão (`AUCTION_CATEGORY_QUEST_ITEMS`) | nenhuma (filtro `Questitem`) | 207-210 |
| 9 | Diversos (`AUCTION_CATEGORY_MISCELLANEOUS`) | Gerado de `GetAuctionItemSubClasses(Miscellaneous)` | 212-216 |
| 10 | Ficha WoW (`TOKEN_FILTER_LABEL`) | nenhuma; escondida a menos que `C_WowTokenUI.ShouldDisplayInAuctionHouse()` (`CategoriesList.lua`:19) | 218-222 |

Marca: local. Diferenças para o Mainline (`Mainline/Blizzard_AuctionData.lua`, 214 linhas): o Forever não tem Warglaive nem as categorias de gemas, glifos e pets; tem Projétil e armadura com Relíquia por posição. Os nomes exatos dos subitens (e a ordem dos gerados) dependem do servidor e das GlobalStrings: incógnita 12 (`/run` do item 16 lista as categorias reais).

---

## 10. Leilões próprios e lances

| Fato | Evidência | Marca |
|---|---|---|
| `QueryOwnedAuctions(sorts)` é chamado por `QueryAll(AllAuctions)`; `QueryBids(sorts, auctionIDs)` por `QueryAll(AllBids)`, passando a lista de IDs de lances ativos (guardados em `g_activeBidAuctionIDs`, SavedVariablesPerCharacter, máximo 100) | `F`:760-781, :6, :265-298; toc:5 | local |
| `QueryAll(AllBids)` é disparado sozinho ao carregar o addon, para marcar "superado" | `F`:410-421 | local |
| Lista de leilões próprios: `GetNumOwnedAuctions`, `GetOwnedAuctionInfo(i)`, `HasFullOwnedAuctionResults` | `A`:236 | local |
| Campos de `OwnedAuctionInfo`: `auctionID`, `itemKey`, `itemLink`, `status`, `quantity`, `timeLeftSeconds`, `timeLeft` (faixa), `bidAmount`, `buyoutAmount`, `bidder` | `AD`:1686-1702 | local |
| "Vendido" aparece como `status == Enum.AuctionStatus.Sold` (Active 0, Sold 1). O UI mostra: prefixo "Vendido" no nome, ícone esmaecido, texto "valor a receber" no lugar do lance, nome do comprador (`bidder`) no tooltip, preço em cinza e botão Cancelar desabilitado | `AD`:1513-1524; `T`:487-495, :564-571, :593-596, :612, :741-775; `U`:348-351; `A`:461-463 | local |
| Para vendidos, `timeLeftSeconds` é o tempo até o pagamento chegar (formato `AUCTION_HOUSE_TIME_LEFT_FORMAT_SOLD`) | `U`:405-411 (vale notar que a função usa uma variável `sold` não declarada, então o formato "vendido" nunca é escolhido; defeito inofensivo da Blizzard) | local / inferencia |
| Nome do licitante de um leilão próprio vem por `RequestOwnedAuctionBidderInfo(auctionID)` e o evento `OWNED_AUCTION_BIDDER_INFO_RECEIVED(auctionID, bidderName)` | `T`:528-532; `AD`:984-998, :1473-1482 | local |
| Cancelar: botão -> `StaticPopup_Show("CANCEL_AUCTION", ..., { auctionID })` -> `OnAccept` = `C_AuctionHouse.CancelAuction(data.auctionID)`. O popup lê `GetCancelCost(auctionID)` e, se > 0, troca o texto para `CANCEL_AUCTION_CONFIRMATION_MONEY` com o valor | `A`:119-125, :500-502; `F`:77-98 | local |
| `CanCancelAuction(ownedAuctionID)` existe na API mas o UI não chama | `AD`:44-57; grep sem uso | local |
| Depois de `AUCTION_CANCELED(auctionID)`, o UI relê a lista (`RefreshSearchResults` -> `QueryOwnedAuctions`). O mesmo ocorre em `AUCTION_HOUSE_NEW_BID_RECEIVED(auctionID)` | `A`:214-217; `AD`:1104-1111, :1185-1194 | local |
| Resultado de lance atualiza por `BIDS_UPDATED` e `BID_ADDED(bidID)`. "Superado" = o jogador tinha lance ativo na lista anterior e o `bidder` atual não é ele | `F`:270-294, :898-908 | local |
| `AUCTION_HOUSE_AUCTIONS_EXPIRED(auctionID)` existe; o UI não o escuta (notificação de expirado vem por `AuctionExpired`) | `AD`:1124-1132 | local |

---

## 11. Favoritos

| Fato | Evidência | Marca |
|---|---|---|
| API: `FavoritesAreAvailable()`, `HasFavorites()`, `HasMaxFavorites()`, `IsFavoriteItem(itemKey)`, `SetFavoriteItem(itemKey, setFavorite)`, `SearchForFavorites(sorts)`, evento `AUCTION_HOUSE_FAVORITES_UPDATED` | `AD`:122-130, :703-711, :769-777, :793-807, :999-1008, :1058-1068, :1168-1173 | local |
| O UI só deixa favoritar se `FavoritesAreAvailable()` e (já é favorito ou não está no máximo); no máximo mostra `AUCTION_HOUSE_FAVORITES_MAXED_TOOLTIP` | `ST`:5-20 (menu de contexto), :745-777 | local |
| Existe erro `FavoritesMaxed` (24) | `ENUM`:49 | local |
| O NÚMERO do limite não está em nenhum arquivo do espelho (nenhuma constante nem função de contagem). Retail usa um valor próprio; não vale presumir | grep `MaxFavorites`, `FAVORITES` | local (ausência) |
| Uso: botão de estrela na lista de browse (menu de clique direito) e no detalhe do item; o botão "Favoritos" faz `SearchForFavorites`; ao abrir o leilão, se há favoritos, a busca é automática | `BR`:26, :55-58; `SB`:28-70, :209-212; `F`:398-400 | local |

---

## 12. ReplicateItems

| Fato | Evidência | Marca |
|---|---|---|
| O UI da Blizzard NÃO chama `ReplicateItems` (nem `GetNumReplicateItems`, `GetReplicateItem*`) | grep em `AddOns/` (fora do `AD`): zero usos | local |
| Documentação: "Esta função deve ser usada no lugar de uma chamada QueryAuctionItems 'allItem' para consultar o leilão inteiro" | `AD`:945-949 (:948) | local |
| Resultado: evento `REPLICATE_ITEM_LIST_UPDATE`; leitura por `GetNumReplicateItems()` e `GetReplicateItemInfo(index)` (campos em `ReplicateItemInfo`: name, count, qualityID, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner, saleStatus, itemID, hasAllInfo), `GetReplicateItemLink`, `GetReplicateItemTimeLeft`, `GetReplicateItemBattlePetInfo` | `AD`:551-686, :1490-1495, :1703-1727 | local |
| Intervalo mínimo entre chamadas: NENHUMA menção (nem em comentário, nem em `HasRestrictions`) | `AD`:945-949 não tem flag `HasRestrictions` | local |
| A documentação apenas manda usá-la em vez de buscas amplas, e diz que `SendSearchQuery` tem teto de 100 por minuto. Se existe cooldown de 15 min como no retail, não se pode afirmar | | incógnita 13 |
| Sem `HasRestrictions`, a chamada não é marcada como restrita (mas isso não prova que o motor aceite fora de clique; ver item 14) | `AD`:945-949 | local / inferencia |

---

## 13. Notificações

Roteamento (local): `Blizzard_Game/Mainline/EventRouting.lua`:15-16 manda `AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION` e `AUCTION_HOUSE_SHOW_NOTIFICATION` para `GameEvent.HandleAuctionHouseNotification(_, _, notification, formatArg)` (`Mainline/EventImplementation.lua`:471-473), que imprime `ChatFrameUtil.GetAuctionHouseNotificationText(notification, formatArg)` como mensagem de sistema (`Blizzard_ChatFrameUtil/Blizzard_ChatFrameUtil.lua`:4-18). Funciona com o leilão fechado (comentário em :3). Camelot carrega esse roteamento via `[Family]` Mainline (`Blizzard_Game.toc`:11-13), inferência.

| Evento | Payload (`AD`) | Casos |
|---|---|---|
| `AUCTION_HOUSE_SHOW_NOTIFICATION` | `notification` (enum `AuctionHouseNotification`) | Sem texto extra. Pelo código, os dois sem argumento de formato são `BidPlaced` (`ERR_AUCTION_BID_PLACED`) e `AuctionRemoved` (`ERR_AUCTION_REMOVED`) |
| `AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION` | `notification`, `text` (string), `auctionID` (opcional) | `AuctionWon` (`ERR_AUCTION_WON_S`), `AuctionOutbid` (`ERR_AUCTION_OUTBID_S`), `AuctionSold` (`ERR_AUCTION_SOLD_S`), `AuctionExpired` (`ERR_AUCTION_EXPIRED_S`); o `text` é o argumento do `:format` (nome do item) |
| `AUCTION_HOUSE_SHOW_COMMODITY_WON_NOTIFICATION` | `commodityName`, `commodityQuantity` | Só o `F` trata, quando o frame está aberto: `ERR_AUCTION_COMMODITY_WON_S` (`F`:438-440). Se o frame está fechado não há tratador na Blizzard (ele só registra o evento em `OnShow`, `F`:310-322, :390) |
| `AUCTION_HOUSE_SHOW_ERROR` | `error` (enum `AuctionHouseError`, 27 valores) | `UIErrorsFrame:AddExternalErrorMessage(GetErrorText(error))` (`F`:435-437; `U`:634-664) |

Enum `AuctionHouseNotification`: BidPlaced 0, AuctionRemoved 1, AuctionWon 2, AuctionOutbid 3, AuctionSold 4, AuctionExpired 5 (`ENUM`:106-118). Eventos em `AD`:1240-1282. Marca: local para tudo acima; a divisão "quais casos vêm em qual evento" é inferencia (se `:format(nil)` ocorresse, daria erro, então os casos com `_S` só podem vir no evento formatado). Conferir em jogo por incógnita 14.

Para o addon: o dono não precisa de tela do leilão para saber de venda, expiração e perda de lance; basta escutar `FORMATTED_NOTIFICATION` (traz o `auctionID`).

---

## 14. Evento de hardware (de onde o UI chama cada função)

Não há NENHUM comentário no código do UI sobre "hardware event", "clique" ou "protegido" (grep em `AHUI/` por `hardware`, `protected`, `click` só acha comentários de estética). A única marca de restrição está no `AD`: `HasRestrictions = true` em exatamente 7 funções: `CancelAuction` (:62), `ConfirmPostCommodity` (:96), `ConfirmPostItem` (:110), `PlaceBid` (:854), `PostCommodity` (:866), `PostItem` (:885), `StartCommoditiesPurchase` (:1081). O significado do flag NÃO está documentado no espelho (`Blizzard_APIDocumentation` não o define). O que se sabe do retail é só memória e vira pista, não fato: incógnita 15.

| Função | Quem chama no UI | Contexto | Evidência | Marca |
|---|---|---|---|---|
| `PostItem` | botão Postar | clique | `S`:204-209 -> `IS`:501-503 -> :489-499 | local |
| `PostCommodity` | botão Postar | clique | `S`:204-209 -> `CS`:129-131 -> :117-127 | local |
| `ConfirmPostItem` / `ConfirmPostCommodity` | `OnAccept` do popup `AUCTION_HOUSE_POST_WARNING` | clique no botão Aceitar do popup (cuja existência depende do evento `AUCTION_HOUSE_POST_WARNING`) | `F`:100-117; `IS`:505-511; `CS`:133-139 | local |
| `PlaceBid` (lance) | `OnAccept` do popup `BID_AUCTION` | clique no Aceitar | `F`:42-57 | local |
| `PlaceBid` (arremate) | `OnAccept` do popup `BUYOUT_AUCTION` (com spinner) | clique no Aceitar | `F`:10-12, :26-40 | local |
| `StartCommoditiesPurchase` | botão Comprar de commodity | clique | `CB`:10-15, :132-142; `F`:844-848 | local |
| `ConfirmCommoditiesPurchase` | botão Comprar agora do diálogo | clique (a API não tem `HasRestrictions`) | `D`:63-66, :263-270 | local |
| `CancelCommoditiesPurchase` | `OnHide` do diálogo (também por temporizador de cotação, evento de sucesso ou Escape) | evento, `OnUpdate` ou clique, indiferente | `D`:108-119 | local |
| `CancelAuction` | `OnAccept` do popup `CANCEL_AUCTION` | clique no Aceitar | `F`:77-83; `A`:119-125, :500-502 | local |
| `SendBrowseQuery` | botão Buscar, Enter da caixa, clique em cabeçalho de ordenação | clique ou Enter | `SB`:22-24, :114-117; `F`:701-721, :783-823 | local |
| `SendSearchQuery` / `SendSellSearchQuery` | clique numa linha de browse; ao arrastar/clicar item para vender; botão Atualizar; ordenação; seleção na lista de leilões próprios; `OnShow` da `ItemList` | clique na maior parte; `ItemList:OnShow` roda `refreshResultsFunc` ao mostrar o painel (:238-240), o que pode acontecer sem clique direto | `F`:737-758; `BR`:28-31; `IS`:391-393; `CS`:166-168; `IL`:233-241 | local |
| `RefreshCommoditySearchResults` / `RefreshItemSearchResults` | botão Atualizar; `ItemList:OnShow`; `OnHide` do diálogo de compra (após sucesso, expirar da cotação ou cancelar) | clique, evento ou `OnUpdate` | `F`:828-842; `IL`:238-240; `D`:114 | local |
| `RequestMore*` | rolagem (`OnScroll` do `ScrollBox`), ao exibir lista | evento de rolagem | `IL`:361-370; `BR`:117-129 | local |
| `QueryOwnedAuctions` | `QueryAll(AllAuctions)`: abrir a aba Leilões, botão Atualizar, ordenação, E `AUCTION_CANCELED` e `AUCTION_HOUSE_NEW_BID_RECEIVED` | clique E evento | `F`:776-777; `A`:164-184, :214-217 | local |
| `QueryBids` | `QueryAll(AllBids)`: carregar o addon (`ADDON_LOADED`), aba Lances, Atualizar | evento e clique | `F`:410-421, :778-779; `A`:175-184 | local |
| `SearchForFavorites` | `OnShow` do `AuctionHouseFrame` (abrir leilão) e botão | evento de abertura (`AUCTION_HOUSE_SHOW`) e clique | `F`:389-400, :771-775 | local |
| `ReplicateItems` | NÃO chamado | não se aplica | grep vazio | local |

Em suma: as 7 funções "restritas" são sempre chamadas dentro de um clique do usuário (botão ou botão de popup) no UI da Blizzard. As consultas de leitura (queries) também são chamadas de eventos e de `OnShow`, ou seja, fora de clique. A conclusão de que as consultas podem ser feitas por timer é inferência (consistente com o código, mas não provada). Já para as restritas, "tudo em clique" é um fato do UI e não prova que o motor EXIGE clique; em retail isso é regra do motor para essas funções. Pista de memória, não fato do Forever.

Efeito para o design (inferencia): o laço de day trading automático por timer só é possível nas consultas; as ordens (postar, lance, comprar, cancelar) provavelmente exigem um clique por ordem, o que determina o fluxo "addon propõe, pessoa confirma com um clique".

---

## 15. Regras de jogo e CVars que mexem com o leilão

CVar (local):
- `auctionHouseDurationDropdown`: padrão `"2"`, descrição "índice de duração selecionado por último" (`CVars.lua`:76). É o único CVar com "auction" no nome. Não existe CVar de throttle nem de intervalo.

Regras de jogo (`C_GameRules`, `Enum.GameRule`):
- NÃO existe regra de jogo com nome de leilão no espelho: busca por `auction`, `market`, `trade`, `commod` em `GameRulesDocumentation.lua` e nos usos de `Enum.GameRule.` em `AddOns/` não acha nenhuma ligada ao leilão (local, ausência). O espelho não traz a lista completa de valores do enum `GameRule` (só os usados).
- Regras que mexem no que o addon pode fazer:
  - `UserAddonsDisabled`: se ativa, o jogo não carrega addons de usuário (`Blizzard_SharedXML/GameRulesUtil.lua`:60-67; `Blizzard_Minimap/Mainline/AddonCompartment.lua`:170).
  - `UserScriptsDisabled`: se ativa, `/run`, `/script` e `/dump` não rodam (`Blizzard_ChatFrameBase/Shared/SlashCommands.lua`:1229, :1400, :1430).
  - `MacrosDisabled` (`SlashCommands.lua`:1264, `GameMenuFrame.lua`:252).
- Outros: `C_GameRules.GetForeverExperiencePreset()` devolve `Classic` (0) ou `Enhanced` (1) (`GameRulesDocumentation.lua`:407-416; usos em `Blizzard_SettingsDefinitions_Shared/Preset.lua`:40, :63). Se o preset altera o leilão é incógnita 16.
- `GameLimitedMode_IsActive()` (conta de teste) bloqueia o leilão com `ERR_FEATURE_RESTRICTED_TRIAL` e chama `CloseAuctionHouse` (`AHUI/Shared/..._UI_Bootstrap.lua`:29-40); mapeia no erro `RestrictedAccountTrial` (5).
- `AUCTION_HOUSE_DISABLED` mostra um popup (`Mainline/EventImplementation.lua`:467-469).
- `AUCTION_HOUSE_SCRIPT_DEPRECATED` mostra o popup `AUCTION_HOUSE_DEPRECATED` (`Blizzard_Game/Shared/EventImplementation.lua`:94-96; `Shared/EventRouting.lua`:44). Isto indica que APIs antigas do leilão (`QueryAuctionItems` etc.) estão descontinuadas e que scripts que as usam disparam o aviso. Marca: local; a leitura é inferencia.

---

## 16. Comandos de conferência (somente leitura)

Todos têm 255 caracteres ou menos (maior: 243). Rodar com o leilão ABERTO, de preferência depois de abrir uma vez as abas Comprar, Vender e Leilões. Cada comando é cola-e-enter no chat. Se `/run` ou `/dump` não funcionarem, veja a regra `UserScriptsDisabled` (comando 12, que também precisa de `/run`; nesse caso o item 15 explica o bloqueio). Nenhum compra, posta, cancela ou dá lance. Os comandos 9 e 10 só criam um ouvinte de eventos que imprime no chat; o 11 lê a lista de leilões próprios que o UI já carregou ao abrir a aba Leilões.

| # | Comando | O que confirma (incógnita) |
|---|---|---|
| 1 | `/dump C_AddOns.IsAddOnLoaded("Blizzard_AuctionHouseUI"), C_AddOns.GetAddOnMetadata("Blizzard_AuctionHouseUI","AllowLoadGameType")` | Se o addon carregou e o que o cabeçalho diz (incógnita 1) |
| 2 | `/run print(AUCTION_HOUSE_FILTER_STRINGS[Enum.AuctionHouseFilter.CurrentExpansionOnly] ~= nil, #C_AuctionHouse.GetFilterGroups(), #AuctionCategories)` | `true` = família Mainline carregada; quantos grupos de filtro e quantas categorias (incógnitas 1 e 11) |
| 3 | `/run for i,c in ipairs(AuctionCategories) do print(i,c.name,c.subCategories and #c.subCategories or 0) end` | Árvore de categorias real do Forever, com nomes e contagem (incógnita 12) |
| 4 | `/run print(AUCTION_DURATION_ONE,";",AUCTION_DURATION_TWO,";",AUCTION_DURATION_THREE,";",GetCVar("auctionHouseDurationDropdown"))` | Horas de cada duração e a duração padrão (incógnitas 2 e 3) |
| 5 | `/run for i=0,3 do print(i,C_AuctionHouse.GetTimeLeftBandInfo(i)) end print(AUCTION_TIME_LEFT1_DETAIL,AUCTION_TIME_LEFT4_DETAIL)` | Faixas de tempo restante em segundos e os textos de tempo (apoia a incógnita 2) |
| 6 | `/run print(C_AuctionHouse.SupportsCopperValues(),C_AuctionHouse.ShouldAutoPopulatePrice(),C_AuctionHouse.FavoritesAreAvailable(),C_AuctionHouse.HasMaxFavorites(),C_AuctionHouse.IsThrottledMessageSystemReady())` | Cobre, preço automático, favoritos e throttle de uma vez (incógnitas 9 e 10) |
| 7 | `/run for b=0,4 do for s=1,C_Container.GetContainerNumSlots(b) do local l=ItemLocation:CreateFromBagAndSlot(b,s) if C_Item.DoesItemExist(l) then print(b,s,C_Item.GetItemName(l),C_AuctionHouse.GetItemCommodityStatus(l)) end end end` | Status de commodity de cada item da mochila: 1 = item, 2 = commodity (incógnita 4). Pode imprimir muitas linhas |
| 8 | `/run local l=ItemLocation:CreateFromBagAndSlot(0,1) for d=1,3 do print(d,C_AuctionHouse.CalculateItemDeposit(l,d,1),C_AuctionHouse.CalculateCommodityDeposit(C_Item.GetItemID(l),d,1)) end` | Depósito por índice de duração para o item da bolsa 0, slot 1 (precisa existir um item lá) (incógnita 8) |
| 9 | `/run AHL=CreateFrame("Frame") AHL:SetScript("OnEvent",function(_,e,...) print(GetTime(),e,...) end)` | Cria um ouvinte de eventos (passo 1 do 10) |
| 10 | `/run for _,e in pairs({"AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED","AUCTION_HOUSE_THROTTLED_MESSAGE_SENT","AUCTION_HOUSE_THROTTLED_SYSTEM_READY","AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED"}) do AHL:RegisterEvent(e) end` | Registra os eventos de throttle; depois use o UI normalmente (buscar várias vezes) e veja os tempos impressos (incógnita 10) |
| 11 | `/run for i=1,C_AuctionHouse.GetNumOwnedAuctions() do local a=C_AuctionHouse.GetOwnedAuctionInfo(i) print(i,a.auctionID,a.status,a.quantity,a.timeLeftSeconds,a.timeLeft,a.bidAmount,a.buyoutAmount,a.bidder) end` | Campos dos leilões próprios (status 1 = vendido). Abra a aba Leilões antes (incógnita 17) |
| 12 | `/run print(C_GameRules.IsGameRuleActive(Enum.GameRule.UserScriptsDisabled),C_GameRules.IsGameRuleActive(Enum.GameRule.UserAddonsDisabled),C_GameRules.GetForeverExperiencePreset(),C_GameRules.IsHardcoreActive(),C_GameRules.IsSelfFoundAllowed())` | Regras que limitam addons e scripts e o preset (0 Classic, 1 Enhanced) (incógnita 16) |
| 13 | `/run print(C_AuctionHouse.GetQuoteDurationRemaining(), C_AuctionHouse.GetNumReplicateItems(), C_AuctionHouse.HasFavorites())` | Com o diálogo de compra de commodity aberto (abra e depois cancele pelo próprio UI), mostra os segundos de cotação (incógnita 6). Sem o diálogo, 0 |

Observação sobre o nº 1 e o nº 12: `C_AddOns.GetAddOnMetadata` com chave `AllowLoadGameType` pode devolver nil (a chave pode não ser exposta); nesse caso só o primeiro valor importa.

---

## Incógnitas (e como conferir no jogo)

| # | Incógnita | Como conferir |
|---|---|---|
| 1 | O cabeçalho `AllowLoadGameType: mainline, cata, mists` (toc:9) admite camelot? A família de camelot é mesmo Mainline para o leilão? | Comandos 1 e 2 do item 16 |
| 2 | Horas de cada duração (índices 1, 2, 3). A hipótese 2h/8h/24h do brief | Comandos 4 e 5; o texto do dropdown de duração na aba Vender |
| 3 | Se o CVar `auctionHouseDurationDropdown` (padrão "2") mapeia para o mesmo índice do `PostItem` | Comando 4 e conferir o índice marcado no dropdown |
| 4 | O Forever tem commodities? Quais itens | Comando 7, e abrir um item de bolsa na aba Vender: se aparecer "Quantidade" e "Preço unitário" sem lance, é commodity |
| 5 | O 3º argumento (`unitPrice`) de `StartCommoditiesPurchase` (o `AD` mostra só 2) | Abrir o diálogo de compra e ver se o botão funciona; ou `/dump C_AuctionHouse.StartCommoditiesPurchase` (só mostra a função). Teste só de leitura não resolve; observar se há erro de LUA ao comprar pelo UI |
| 6 | Duração da cotação de commodity (padrão do retail pode ser 45 s, mas é pista de memória) | Comando 13 com o diálogo aberto |
| 7 | O que dispara `AUCTION_HOUSE_POST_WARNING` e o texto `CONFIRM_AUCTION_POSTING_TEXT` | `/dump CONFIRM_AUCTION_POSTING_TEXT`; e tentar postar um item muito barato pelo UI e observar |
| 8 | Comissão da casa na venda e fórmula do depósito | Depósito: comando 8; comissão: vender um item barato e comparar preço de venda com o valor que chega no correio |
| 9 | `SupportsCopperValues()` real | Comando 6 |
| 10 | Como o throttle se comporta (intervalos e fila) | Comandos 6, 9 e 10, e fazer buscas seguidas |
| 11 | Quais filtros o menu de busca lista | Comando 2 (`#GetFilterGroups()`) e abrir o menu de filtros |
| 12 | Nomes e ordem exata das categorias e subcategorias geradas por servidor | Comando 3 |
| 13 | `ReplicateItems`: existe intervalo mínimo no servidor do Forever? | Não há comando só de leitura que ateste isso; a Blizzard documenta o limite apenas para `SendSearchQuery` (100/min). Teste controlado depois (uma chamada, ver se os eventos chegam e quanto tempo até outra) |
| 14 | Quais casos chegam por `SHOW_NOTIFICATION` e por `SHOW_FORMATTED_NOTIFICATION` | Registrar os dois eventos com o ouvinte do comando 9 (trocando os nomes), e fazer uma venda barata |
| 15 | O que `HasRestrictions` exige (clique ou outra coisa) e se aplica a addon em timer | Teste de desenvolvimento do addon: tentar `PostItem` fora de clique com um item barato e ver o erro; não há comando seguro de leitura |
| 16 | Se `UserScriptsDisabled` e o preset Classic/Enhanced mudam o leilão | Comando 12 |
| 17 | Se `timeLeftSeconds` de vendido é o tempo até o pagamento | Comando 11 em um leilão vendido (a aba Leilões mostra o "vendido") |
| 18 | O limite de favoritos | Favoritar itens até o botão bloquear; o aviso mostra `FavoritesMaxed`; ou `/dump C_AuctionHouse.HasMaxFavorites()` a cada favorito |
| 19 | O build do espelho é mesmo o 70938 | `/dump (GetBuildInfo())` no jogo, comparar com a pasta |

---

## Achados fora do escopo

- `U`:405-411 usa uma variável `sold` que não existe: o formato "vendido" do tooltip nunca é usado (defeito da Blizzard, sem impacto no design).
- A API tem `RequestMoreCommoditySearchResults`, `HasFullCommoditySearchResults`, `HasFullBidResults`, `SearchForItemKeys`, `GetAuctionInfoByID` e `GetExtraBrowseInfo` que o design pode aproveitar; o UI usa só alguns (`AD`:731-768, :1009-1019).
