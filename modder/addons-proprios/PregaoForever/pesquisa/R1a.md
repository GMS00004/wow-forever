> Relatório de pesquisa de 2026-11-16, da onda 1 do design do PregaoForever, gravado como estava (foto do dia). `<espelho>`, `<dados>` e `<tmp>` eram pastas temporárias da sessão; o Apêndice D do `DESIGN.md` diz como refazê-las. Onde este relatório e o `DESIGN.md` divergem, vale o `DESIGN.md`.

# R1a - Contrato da API C_AuctionHouse no Forever (cliente 1.60.1, build 70938)

Data: 2026-11-16. Todas as marcas abaixo sao `local` (lido nesta maquina) salvo indicacao. Abreviacoes de caminho:
- DOC = .../scratchpad/espelho/wow-ui-source-forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua
- ENUM = mesma pasta, AuctionHouseEnumsDocumentation.lua
- CONST = mesma pasta, AuctionHouseConstantsDocumentation.lua
- GAPI = C:/GMS/Claude Code Projects/wow/modder/ferramentas/guia/api-forever/GlobalAPI.lua (build 70532)
- EVT = C:/GMS/Claude Code Projects/wow/modder/ferramentas/guia/api-forever/Events.lua (build 70532)

Cabecalho do sistema (DOC linhas 1-6): Name = "AuctionHouse", Type = "System", Namespace = "C_AuctionHouse", Environment = "All". [local]

## Resultado da contagem

**C_AuctionHouse tem 86 funcoes e 47 eventos na documentacao (DOC).** Contagem por Grep de `Type = "Function"` (86) e `Type = "Event"` (47) em DOC. [local]

## 1. Funcoes (86)

Campos extras observados na documentacao, copiados literalmente: `SecretArguments = "AllowedWhenUntainted"`, `HasRestrictions = true`, `MayReturnNothing = true`, `Documentation = { ... }`. Dentro de argumentos/retornos: `Mixin = "ItemLocationMixin"`, `Default = ...`, `InnerType = ...`.

Hardware event: **a documentacao nao informa quais funcoes exigem evento de hardware** (Grep por Hardware em toda a pasta Blizzard_APIDocumentationGenerated: 0 ocorrencias). Existe `HasRestrictions = true` em 7 funcoes de C_AuctionHouse (CancelAuction, ConfirmPostCommodity, ConfirmPostItem, PlaceBid, PostCommodity, PostItem, StartCommoditiesPurchase), mas a documentacao nao define o que o campo significa (Grep em Blizzard_APIDocumentation: 0 ocorrencias); ler como "tem restricoes" e inferencia. ConfirmCommoditiesPurchase NAO tem HasRestrictions. [local; leitura = inferencia]

Legenda da coluna Extras: S = `SecretArguments = "AllowedWhenUntainted"`; R = `HasRestrictions = true`; N = `MayReturnNothing = true`; D = `Documentation` (texto abaixo da tabela). "-" = sem extras. Tipos: BigUInteger e luaIndex sao tipos da documentacao. Argumentos "?" = Nilable = true.

| # | Funcao (linha em DOC) | Argumentos | Retornos | Extras |
|---|---|---|---|---|
| 1 | CalculateCommodityDeposit (11) | itemID number; duration luaIndex; quantity number | depositCost number? | S |
| 2 | CalculateItemDeposit (28) | item ItemLocation(Mixin ItemLocationMixin); duration luaIndex; quantity number | depositCost number? | S |
| 3 | CanCancelAuction (45) | ownedAuctionID number | canCancelAuction bool | S |
| 4 | CancelAuction (60) | ownedAuctionID number | - | R, S |
| 5 | CancelCommoditiesPurchase (71) | - | - | - |
| 6 | CancelSell (75) | - | - | - |
| 7 | CloseAuctionHouse (79) | - | - | - |
| 8 | ConfirmCommoditiesPurchase (83) | itemID number; quantity number | - | S |
| 9 | ConfirmPostCommodity (94) | item ItemLocation; duration luaIndex; quantity number; unitPrice BigUInteger | - | R, S |
| 10 | ConfirmPostItem (108) | item ItemLocation; duration luaIndex; quantity number; bid BigUInteger?; buyout BigUInteger? | - | R, S |
| 11 | FavoritesAreAvailable (123) | - | favoritesAreAvailable bool | - |
| 12 | GetAuctionInfoByID (132) | auctionID number | priceInfo AuctionInfo? | S |
| 13 | GetAuctionItemSubClasses (147) | classID number | subClasses table<number> | S |
| 14 | GetAvailablePostCount (162) | item ItemLocation | listCount number | S |
| 15 | GetBidInfo (177) | bidIndex luaIndex | bid BidInfo? | S |
| 16 | GetBidType (192) | bidTypeIndex luaIndex | typeItemKey ItemKey? | S |
| 17 | GetBids (207) | - | bids table<BidInfo> | - |
| 18 | GetBrowseResults (216) | - | browseResults table<BrowseResultInfo> | - |
| 19 | GetCancelCost (225) | ownedAuctionID number | cancelCost BigUInteger | S |
| 20 | GetCommoditySearchResultInfo (240) | itemID number; commoditySearchResultIndex luaIndex | result CommoditySearchResultInfo? | S |
| 21 | GetCommoditySearchResultsQuantity (256) | itemID number | totalQuantity number | S |
| 22 | GetExtraBrowseInfo (271) | itemKey ItemKey | extraInfo number | N, S |
| 23 | GetFilterGroups (287) | - | filterGroups table<AuctionHouseFilterGroup> | - |
| 24 | GetItemCommodityStatus (296) | item ItemLocation | isCommodity ItemCommodityStatus | S |
| 25 | GetItemKeyFromItem (311) | item ItemLocation | itemKey ItemKey | S |
| 26 | GetItemKeyInfo (326) | itemKey ItemKey; restrictQualityToFilter bool (Default = false) | itemKeyInfo ItemKeyInfo? | S |
| 27 | GetItemKeyRequiredLevel (342) | itemKey ItemKey | requiredLevel number | N, S |
| 28 | GetItemKeySampleLink (358) | itemKey ItemKey | sampleItemLink string? | S, D |
| 29 | GetItemSearchResultInfo (374) | itemKey ItemKey; itemSearchResultIndex luaIndex | result ItemSearchResultInfo? | S |
| 30 | GetItemSearchResultsQuantity (390) | itemKey ItemKey | totalQuantity number | S |
| 31 | GetMaxBidItemBid (405) | - | maxBid BigUInteger? | - |
| 32 | GetMaxBidItemBuyout (414) | - | maxBuyout BigUInteger? | - |
| 33 | GetMaxCommoditySearchResultPrice (423) | itemID number | maxUnitPrice BigUInteger? | S |
| 34 | GetMaxItemSearchResultBid (438) | itemKey ItemKey | maxBid BigUInteger? | S |
| 35 | GetMaxItemSearchResultBuyout (453) | itemKey ItemKey | maxBuyout BigUInteger? | S |
| 36 | GetMaxOwnedAuctionBid (468) | - | maxBid BigUInteger? | - |
| 37 | GetMaxOwnedAuctionBuyout (477) | - | maxBuyout BigUInteger? | - |
| 38 | GetNumBidTypes (486) | - | numBidTypes number | - |
| 39 | GetNumBids (495) | - | numBids number | - |
| 40 | GetNumCommoditySearchResults (504) | itemID number | numSearchResults number | S |
| 41 | GetNumItemSearchResults (519) | itemKey ItemKey | numItemSearchResults number | S |
| 42 | GetNumOwnedAuctionTypes (534) | - | numOwnedAuctionTypes number | - |
| 43 | GetNumOwnedAuctions (543) | - | numOwnedAuctions number | - |
| 44 | GetNumReplicateItems (552) | - | numReplicateItems number | - |
| 45 | GetOwnedAuctionInfo (561) | ownedAuctionIndex luaIndex | ownedAuction OwnedAuctionInfo? | S |
| 46 | GetOwnedAuctionType (576) | ownedAuctionTypeIndex luaIndex | typeItemKey ItemKey? | S |
| 47 | GetOwnedAuctions (591) | - | ownedAuctions table<OwnedAuctionInfo> | - |
| 48 | GetQuoteDurationRemaining (600) | - | quoteDurationSeconds number | - |
| 49 | GetReplicateItemBattlePetInfo (609) | index number | creatureID number; displayID number | N, S |
| 50 | GetReplicateItemInfo (626) | index number | name string?; texture fileID?; count number; qualityID number; usable bool?; level number; levelType string?; minBid BigUInteger; minIncrement BigUInteger; buyoutPrice BigUInteger; bidAmount BigUInteger; highBidder string?; bidderFullName string?; owner string?; ownerFullName string?; saleStatus number; itemID number; hasAllInfo bool? | S |
| 51 | GetReplicateItemLink (658) | index number | itemLink string? | S |
| 52 | GetReplicateItemTimeLeft (673) | index number | timeLeft number | S |
| 53 | GetTimeLeftBandInfo (688) | timeLeftBand AuctionHouseTimeLeftBand | timeLeftMinSeconds number; timeLeftMaxSeconds number | S |
| 54 | HasFavorites (704) | - | hasFavorites bool | - |
| 55 | HasFullBidResults (713) | - | hasFullBidResults bool | - |
| 56 | HasFullBrowseResults (722) | - | hasFullBrowseResults bool | - |
| 57 | HasFullCommoditySearchResults (731) | itemID number | hasFullResults bool | S |
| 58 | HasFullItemSearchResults (746) | itemKey ItemKey | hasFullResults bool | S |
| 59 | HasFullOwnedAuctionResults (761) | - | hasFullOwnedAuctionResults bool | - |
| 60 | HasMaxFavorites (770) | - | hasMaxFavorites bool | - |
| 61 | HasSearchResults (779) | itemKey ItemKey | hasSearchResults bool | S |
| 62 | IsFavoriteItem (794) | itemKey ItemKey | isFavorite bool | S |
| 63 | IsSellItemValid (809) | item ItemLocation; displayError bool (Default = true) | valid bool | S |
| 64 | IsThrottledMessageSystemReady (825) | - | canSendThrottledMessage bool | - |
| 65 | MakeItemKey (834) | itemID number; itemLevel number (Default 0); itemSuffix number (Default 0); battlePetSpeciesID number (Default 0) | itemKey ItemKey | S |
| 66 | PlaceBid (852) | auctionID number; bidAmount BigUInteger | - | R, S |
| 67 | PostCommodity (864) | item ItemLocation; duration luaIndex; quantity number; unitPrice BigUInteger | needsConfirmation bool | R, S |
| 68 | PostItem (883) | item ItemLocation; duration luaIndex; quantity number; bid BigUInteger?; buyout BigUInteger? | needsConfirmation bool | R, S |
| 69 | QueryBids (903) | sorts table<AuctionHouseSortType>; auctionIDs table<number> | - | S |
| 70 | QueryOwnedAuctions (914) | sorts table<AuctionHouseSortType> | - | S |
| 71 | RefreshCommoditySearchResults (924) | itemID number | - | S |
| 72 | RefreshItemSearchResults (934) | itemKey ItemKey; minLevelFilter number?; maxLevelFilter number? | - | S |
| 73 | ReplicateItems (946) | - | - | D |
| 74 | RequestMoreBrowseResults (951) | - | - | - |
| 75 | RequestMoreCommoditySearchResults (955) | itemID number | hasFullResults bool | S |
| 76 | RequestMoreItemSearchResults (970) | itemKey ItemKey | hasFullResults bool | S |
| 77 | RequestOwnedAuctionBidderInfo (985) | auctionID number | bidderName cstring | S |
| 78 | SearchForFavorites (1000) | sorts table<AuctionHouseSortType> | - | S |
| 79 | SearchForItemKeys (1010) | itemKeys table<ItemKey>; sorts table<AuctionHouseSortType> | - | S |
| 80 | SendBrowseQuery (1021) | query AuctionHouseBrowseQuery | - | S |
| 81 | SendSearchQuery (1031) | itemKey ItemKey; sorts table<AuctionHouseSortType>; separateOwnerItems bool; minLevelFilter number (Default 0); maxLevelFilter number (Default 0) | - | S, D |
| 82 | SendSellSearchQuery (1046) | itemKey ItemKey; sorts table<AuctionHouseSortType>; separateOwnerItems bool | - | S, D |
| 83 | SetFavoriteItem (1059) | itemKey ItemKey; setFavorite bool | - | S |
| 84 | ShouldAutoPopulatePrice (1070) | - | shouldAutoPopulatePrice bool | - |
| 85 | StartCommoditiesPurchase (1079) | itemID number; quantity number | - | R, S |
| 86 | SupportsCopperValues (1091) | - | supportsCopperValues bool | - |

Textos de Documentation (literais):
- GetItemKeySampleLink (361): "Returns a link for an item in this key's results with player-applied enchants, gems and reforges stripped"
- ReplicateItems (948): "This function should be used in place of an 'allItem' QueryAuctionItems call to query the entire auction house."
- SendSearchQuery (1034): "Search queries are restricted to 100 calls per minute. These should not be used to query the entire auction house. See ReplicateItems"
- SendSellSearchQuery (1049): "Search queries are restricted to 100 calls per minute. These should not be used to query the entire auction house. See ReplicateItems. ItemKey should have its iLVL and suffix cleared before calling."

Observacoes (inferencia): nao existe funcao dedicada a busca de commodity; commodity usa SendSearchQuery/SendSellSearchQuery com um ItemKey e depois as funcoes *CommoditySearchResult* com itemID. A funcao de arremate de item e PlaceBid (item) ou StartCommoditiesPurchase + ConfirmCommoditiesPurchase (commodity); nao ha "BuyoutItem" separado, o buyout e um PlaceBid com bidAmount = buyoutAmount (inferencia, padrao conhecido do retail; nao confirmado no Forever).

## 2. Estruturas (Type = "Structure"), DOC linhas 1538-1727

Todos os campos: nome, tipo, Nilable (N? = Nilable true; sem marca = false). Marca: local.

| Estrutura (linha) | Campos |
|---|---|
| AuctionHouseBrowseQuery (1539) | searchString string; sorts table<AuctionHouseSortType>; minLevel number?; maxLevel number?; filters table<AuctionHouseFilter>?; itemClassFilters table<AuctionHouseItemClassFilter>? |
| AuctionHouseFilterGroup (1552) | category AuctionHouseFilterCategory; filters table<AuctionHouseFilter> |
| AuctionHouseItemClassFilter (1561) | classID number; subClassID number?; inventoryType InventoryType? |
| AuctionHouseSortType (1571) | sortOrder AuctionHouseSortOrder; reverseSort bool |
| AuctionInfo (1580) | itemKey ItemKey; itemLink string?; minBid WOWMONEY?; bidAmount WOWMONEY?; buyoutAmount WOWMONEY?; bidder WOWGUID? |
| BidInfo (1593) | auctionID number; itemKey ItemKey; itemLink string?; timeLeft AuctionHouseTimeLeftBand; minBid BigUInteger?; bidAmount BigUInteger?; buyoutAmount BigUInteger?; bidder WOWGUID? |
| BrowseResultInfo (1608) | itemKey ItemKey; appearanceLink string?; totalQuantity number; minPrice BigUInteger; containsOwnerItem bool |
| CommoditySearchResultInfo (1620) | itemID number; quantity number; unitPrice BigUInteger; auctionID number; owners table<string>; totalNumberOfOwners number; timeLeftSeconds number?; numOwnerItems number; containsOwnerItem bool; containsAccountItem bool |
| ItemKey (1637) | itemID number; itemLevel number (Default 0); itemSuffix number (Default 0); battlePetSpeciesID number (Default 0) |
| ItemKeyInfo (1648) | itemID number; battlePetSpeciesID number; itemName string; battlePetLink string?; appearanceLink string?; quality ItemQuality; iconFileID number; isPet bool; isCommodity bool; isEquipment bool |
| ItemSearchResultInfo (1665) | itemKey ItemKey; owners table<string>; totalNumberOfOwners number; timeLeft AuctionHouseTimeLeftBand; auctionID number; quantity number; itemLink string?; containsOwnerItem bool; containsAccountItem bool; containsSocketedItem bool; bidder WOWGUID?; minBid BigUInteger?; bidAmount BigUInteger?; buyoutAmount BigUInteger?; timeLeftSeconds number? |
| OwnedAuctionInfo (1687) | auctionID number; itemKey ItemKey; itemLink string?; status AuctionStatus; quantity number; timeLeftSeconds number?; timeLeft AuctionHouseTimeLeftBand?; bidAmount BigUInteger?; buyoutAmount BigUInteger?; bidder string? |
| ReplicateItemInfo (1704) | name string?; texture fileID?; count number; qualityID number; usable bool?; level number; levelType string?; minBid BigUInteger; minIncrement BigUInteger; buyoutPrice BigUInteger; bidAmount BigUInteger; highBidder string?; bidderFullName string?; owner string?; ownerFullName string?; saleStatus number; itemID number; hasAllInfo bool? |

Notas (local): AuctionInfo usa WOWMONEY, as demais usam BigUInteger. CommoditySearchResultInfo nao tem campo de tempo restante em banda, so timeLeftSeconds?. ReplicateItemInfo e declarada como estrutura mas GetReplicateItemInfo devolve os mesmos 18 valores como retornos soltos, nao como tabela (DOC 626-656).

ItemKey e ItemLocation fora da documentacao de leilao:
- ItemKey nao e definido em ItemDocumentation.lua (Grep por ItemKey nesse arquivo: so IsItemKeystoneByID, linha 1566, sem relacao). Sua unica definicao esta em DOC 1637. [local]
- ItemLocation aparece em ItemDocumentation.lua como tipo de argumento com `Mixin = "ItemLocationMixin"` (ex. linhas 25, 40, 56, 71, 167, 182...). Nao ha tabela Structure chamada ItemLocation nesse arquivo; a forma do mixin nao esta na documentacao. Um caso aceita nulo: linha 137 usa `EmptiableItemLocation`. [local]

Tipos nao definidos nos 3 arquivos de leilao, referenciados: InventoryType, ItemQuality, WOWGUID, WOWMONEY, BigUInteger, luaIndex, fileID, cstring. Valores de InventoryType e ItemQuality ficam fora do escopo. [local; incognita]

## 3. Enums e constantes

Enums em DOC (1500-1536) e ENUM; constante em CONST. Marca: local.

| Enum (fonte, linha) | Valores |
|---|---|
| AuctionHouseFilterCategory (DOC 1501) | Uncategorized 0; Equipment 1; Rarity 2 |
| AuctionStatus (DOC 1514) | Active 0; Sold 1 |
| ItemCommodityStatus (DOC 1526) | Unknown 0; Item 1; Commodity 2 |
| AuctionHouseCommoditySortOrder (ENUM 6) | UnitPrice 0; Quantity 1 |
| AuctionHouseError (ENUM 18), 27 valores | NotEnoughMoney 0; HigherBid 1; BidIncrement 2; BidOwn 3; ItemNotFound 4; RestrictedAccountTrial 5; HasRestriction 6; IsBusy 7; Unavailable 8; ItemHasQuote 9; DatabaseError 10; MinBid 11; NotEnoughItems 12; RepairItem 13; UsedCharges 14; QuestItem 15; BoundItem 16; ConjuredItem 17; LimitedDurationItem 18; IsBag 19; EquippedBag 20; WrappedItem 21; LootItem 22; DoubleBid 23; FavoritesMaxed 24; ItemNotAvailable 25; ItemBoundToAccountUntilEquip 26 |
| AuctionHouseExtraColumn (ENUM 55) | None 0; Ilvl 1; Slots 2; Level 3; Skill 4 |
| AuctionHouseFilter (ENUM 70), 14 valores | None 0; UncollectedOnly 1; UsableOnly 2; CurrentExpansionOnly 3; UpgradesOnly 4; ExactMatch 5; PoorQuality 6; CommonQuality 7; UncommonQuality 8; RareQuality 9; EpicQuality 10; LegendaryQuality 11; ArtifactQuality 12; LegendaryCraftedItemOnly 13 |
| AuctionHouseItemSortOrder (ENUM 94) | Bid 0; Buyout 1 |
| AuctionHouseNotification (ENUM 106) | BidPlaced 0; AuctionRemoved 1; AuctionWon 2; AuctionOutbid 3; AuctionSold 4; AuctionExpired 5 |
| AuctionHouseSortOrder (ENUM 122) | Price 0; Name 1; Level 2; Bid 3; Buyout 4; TimeRemaining 5 |
| AuctionHouseTimeLeftBand (ENUM 138) | Short 0; Medium 1; Long 2; VeryLong 3 |

Constante (CONST 6-11): AuctionConstants (Type = "Constants"): DEFAULT_AUCTION_PRICE_MULTIPLIER, number, 1.5. E a unica constante. [local]

Observacao (inferencia): AuctionHouseSortType usa AuctionHouseSortOrder (6 valores); AuctionHouseCommoditySortOrder e AuctionHouseItemSortOrder existem como enums mas nenhuma funcao ou estrutura do namespace os referencia na documentacao (nao procurado fora dos 3 arquivos).

Duracao: o argumento `duration` e `luaIndex` sem enum no arquivo; o mapeamento do indice para horas nao esta na documentacao. [incognita]

## 4. Eventos (47), DOC 1101-1495

Todos tem `SynchronousEvent = true`, exceto CommoditySearchResultsReceived, CommoditySearchResultsUpdated e ItemSearchResultsUpdated, que tem `UniqueEvent = true`. Nenhum evento tem LiteralName diferente do esperado. Marca: local.

| # | Evento literal (linha do Name) | Payload | Extras |
|---|---|---|---|
| 1 | AUCTION_CANCELED (1104) | auctionID number | - |
| 2 | AUCTION_HOUSE_AUCTION_CREATED (1114) | auctionID number | D: "This signal is not used in the base UI but is included for AddOn ease-of-use." |
| 3 | AUCTION_HOUSE_AUCTIONS_EXPIRED (1125) | auctionID number | - |
| 4 | AUCTION_HOUSE_BROWSE_FAILURE (1135) | - | - |
| 5 | AUCTION_HOUSE_BROWSE_RESULTS_ADDED (1141) | addedBrowseResults table<BrowseResultInfo> | - |
| 6 | AUCTION_HOUSE_BROWSE_RESULTS_UPDATED (1151) | - | - |
| 7 | AUCTION_HOUSE_CLOSED (1157) | - | - |
| 8 | AUCTION_HOUSE_DISABLED (1163) | - | - |
| 9 | AUCTION_HOUSE_FAVORITES_UPDATED (1169) | - | - |
| 10 | AUCTION_HOUSE_ITEM_DELIVERY_DELAY_UPDATE (1175) | purchasedItemDeliveryDelay number; cancelledItemDeliveryDelay number | - |
| 11 | AUCTION_HOUSE_NEW_BID_RECEIVED (1186) | auctionID number | - |
| 12 | AUCTION_HOUSE_NEW_RESULTS_RECEIVED (1196) | itemKey ItemKey? | D: "This signal is not used in the base UI but is included for AddOn ease-of-use. Payload is nil for browse queries." |
| 13 | AUCTION_HOUSE_POST_ERROR (1207) | - | - |
| 14 | AUCTION_HOUSE_POST_WARNING (1213) | - | - |
| 15 | AUCTION_HOUSE_PURCHASE_COMPLETED (1219) | auctionID number | - |
| 16 | AUCTION_HOUSE_SCRIPT_DEPRECATED (1229) | - | - |
| 17 | AUCTION_HOUSE_SHOW (1235) | - | - |
| 18 | AUCTION_HOUSE_SHOW_COMMODITY_WON_NOTIFICATION (1241) | commodityName string; commodityQuantity number | - |
| 19 | AUCTION_HOUSE_SHOW_ERROR (1252) | error AuctionHouseError | - |
| 20 | AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION (1262) | notification AuctionHouseNotification; text string; auctionID number? | - |
| 21 | AUCTION_HOUSE_SHOW_NOTIFICATION (1274) | notification AuctionHouseNotification | - |
| 22 | AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED (1284) | - | - |
| 23 | AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED (1290) | - | - |
| 24 | AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED (1296) | - | - |
| 25 | AUCTION_HOUSE_THROTTLED_MESSAGE_SENT (1302) | - | - |
| 26 | AUCTION_HOUSE_THROTTLED_SYSTEM_READY (1308) | - | - |
| 27 | AUCTION_MULTISELL_FAILURE (1314) | - | - |
| 28 | AUCTION_MULTISELL_START (1320) | numRepetitions number | - |
| 29 | AUCTION_MULTISELL_UPDATE (1330) | createdCount number; totalToCreate number | - |
| 30 | BID_ADDED (1341) | bidID number | - |
| 31 | BIDS_UPDATED (1351) | - | - |
| 32 | COMMODITY_PRICE_UNAVAILABLE (1357) | - | - |
| 33 | COMMODITY_PRICE_UPDATED (1363) | updatedUnitPrice BigUInteger; updatedTotalPrice BigUInteger | - |
| 34 | COMMODITY_PURCHASE_FAILED (1374) | - | - |
| 35 | COMMODITY_PURCHASE_SUCCEEDED (1380) | - | - |
| 36 | COMMODITY_PURCHASED (1386) | itemID number; quantity number | - |
| 37 | COMMODITY_SEARCH_RESULTS_ADDED (1397) | itemID number | - |
| 38 | COMMODITY_SEARCH_RESULTS_RECEIVED (1407) | - | UniqueEvent |
| 39 | COMMODITY_SEARCH_RESULTS_UPDATED (1413) | itemID number | UniqueEvent |
| 40 | EXTRA_BROWSE_INFO_RECEIVED (1423) | itemID number | - |
| 41 | ITEM_KEY_ITEM_INFO_RECEIVED (1433) | itemID number | - |
| 42 | ITEM_PURCHASED (1443) | itemID number | - |
| 43 | ITEM_SEARCH_RESULTS_ADDED (1453) | itemKey ItemKey | - |
| 44 | ITEM_SEARCH_RESULTS_UPDATED (1463) | itemKey ItemKey; newAuctionID number? | UniqueEvent |
| 45 | OWNED_AUCTION_BIDDER_INFO_RECEIVED (1474) | auctionID number; bidderName cstring | - |
| 46 | OWNED_AUCTIONS_UPDATED (1485) | - | - |
| 47 | REPLICATE_ITEM_LIST_UPDATE (1491) | - | - |

A documentacao nao diz o que dispara cada evento (so os 2 textos de Documentation acima). As ligacoes pedido->evento da secao 6 sao inferencia, a partir dos nomes e do padrao do retail.

## 5. Diferencas entre a lista local (build 70532) e a documentacao (build 70938)

Resultado: nenhuma diferenca de nomes.
- Funcoes: GAPI linhas 331-416 lista 86 nomes C_AuctionHouse.*; DOC tem 86 funcoes. Os nomes e a ordem alfabetica coincidem na leitura lado a lado (conferencia visual, nao por script). [local]
- Eventos: EVT linhas 95-141 lista 47 eventos de leilao (do AUCTION_CANCELED ao REPLICATE_ITEM_LIST_UPDATE); DOC tem 47 eventos. Coincidem na leitura. [local]
- Fora do namespace: GAPI nao tem nenhuma funcao global antiga de leilao (GetAuctionItemInfo etc.): o Grep por "Auction" so acha C_AuctionHouse.*, C_WowTokenPublic.* (GetListedAuctionableTokenInfo, GetNumListedAuctionableTokens, IsAuctionableWowToken, UpdateListedAuctionableTokens) e C_WowTokenUI.ShouldDisplayInAuctionHouse (linhas 4985-4992). EVT tem tambem BLACK_MARKET_BID_RESULT (212) e TOKEN_AUCTION_SOLD (2236), que nao estao na documentacao de C_AuctionHouse. [local]
- Limite: as listas comparam so nomes; assinaturas e payloads do build 70532 nao existem nas listas, entao mudancas de argumentos entre os builds nao sao detectaveis. [inferencia]

## 6. Agrupamento por uso no trading

Formato: pede -> avisa -> le. O encadeamento e inferencia a partir de nomes, tipos e padrao do retail; a documentacao nao descreve a ordem. Conferir no jogo (ver Incognitas). Todas as funcoes e eventos citados existem em DOC (marca local para a existencia).

| Grupo | Pede | Avisa | Le |
|---|---|---|---|
| Browse e paginacao | SendBrowseQuery(AuctionHouseBrowseQuery); RequestMoreBrowseResults() | AUCTION_HOUSE_BROWSE_RESULTS_UPDATED (lista inteira mudou); AUCTION_HOUSE_BROWSE_RESULTS_ADDED(addedBrowseResults); AUCTION_HOUSE_BROWSE_FAILURE; AUCTION_HOUSE_NEW_RESULTS_RECEIVED (payload nil no browse, DOC 1200) | GetBrowseResults(); HasFullBrowseResults(); GetFilterGroups(); GetAuctionItemSubClasses(classID); GetExtraBrowseInfo(itemKey) com EXTRA_BROWSE_INFO_RECEIVED(itemID) |
| Busca por commodity | SendSearchQuery(itemKey, sorts, separateOwnerItems[, min, max]) ou SendSellSearchQuery; depois RefreshCommoditySearchResults(itemID); RequestMoreCommoditySearchResults(itemID) | COMMODITY_SEARCH_RESULTS_RECEIVED (sem payload, UniqueEvent); COMMODITY_SEARCH_RESULTS_UPDATED(itemID); COMMODITY_SEARCH_RESULTS_ADDED(itemID); AUCTION_HOUSE_NEW_RESULTS_RECEIVED(itemKey) | GetNumCommoditySearchResults(itemID); GetCommoditySearchResultInfo(itemID, index); GetCommoditySearchResultsQuantity(itemID); GetMaxCommoditySearchResultPrice(itemID); HasFullCommoditySearchResults(itemID); HasSearchResults(itemKey) |
| Busca por item (nao commodity) | SendSearchQuery / SendSellSearchQuery / SearchForItemKeys(itemKeys, sorts); RefreshItemSearchResults(itemKey, min?, max?); RequestMoreItemSearchResults(itemKey) | ITEM_SEARCH_RESULTS_UPDATED(itemKey, newAuctionID?); ITEM_SEARCH_RESULTS_ADDED(itemKey); AUCTION_HOUSE_NEW_RESULTS_RECEIVED(itemKey) | GetNumItemSearchResults(itemKey); GetItemSearchResultInfo(itemKey, index); GetItemSearchResultsQuantity(itemKey); GetMaxItemSearchResultBid/Buyout(itemKey); HasFullItemSearchResults(itemKey); GetItemKeyInfo(itemKey) com ITEM_KEY_ITEM_INFO_RECEIVED(itemID) quando nao ha cache |
| Compra de commodity | StartCommoditiesPurchase(itemID, quantity) [R]; ConfirmCommoditiesPurchase(itemID, quantity); CancelCommoditiesPurchase() | COMMODITY_PRICE_UPDATED(updatedUnitPrice, updatedTotalPrice); COMMODITY_PRICE_UNAVAILABLE; COMMODITY_PURCHASE_SUCCEEDED; COMMODITY_PURCHASE_FAILED; COMMODITY_PURCHASED(itemID, quantity); AUCTION_HOUSE_SHOW_COMMODITY_WON_NOTIFICATION(name, qty); AUCTION_HOUSE_SHOW_ERROR(error) | GetQuoteDurationRemaining(); (cotacao fica no payload de COMMODITY_PRICE_UPDATED) |
| Lance e arremate (item) | PlaceBid(auctionID, bidAmount) [R] | BID_ADDED(bidID); ITEM_PURCHASED(itemID); AUCTION_HOUSE_PURCHASE_COMPLETED(auctionID); AUCTION_HOUSE_SHOW_NOTIFICATION/FORMATTED_NOTIFICATION; AUCTION_HOUSE_SHOW_ERROR (ex. HigherBid, BidIncrement, BidOwn, DoubleBid, NotEnoughMoney); AUCTION_HOUSE_NEW_BID_RECEIVED(auctionID) | GetAuctionInfoByID(auctionID); GetMaxBidItemBid(); GetMaxBidItemBuyout() |
| Postagem | IsSellItemValid(item, displayError); GetItemKeyFromItem(item); GetItemCommodityStatus(item); GetAvailablePostCount(item); CalculateCommodityDeposit / CalculateItemDeposit; PostCommodity / PostItem [R] (devolvem needsConfirmation); se true, ConfirmPostCommodity / ConfirmPostItem [R]; CancelSell() | AUCTION_HOUSE_AUCTION_CREATED(auctionID); AUCTION_HOUSE_POST_WARNING; AUCTION_HOUSE_POST_ERROR; AUCTION_MULTISELL_START/UPDATE/FAILURE; OWNED_AUCTIONS_UPDATED; AUCTION_HOUSE_SHOW_ERROR | ShouldAutoPopulatePrice(); SupportsCopperValues(); GetOwnedAuctions() |
| Cancelamento | CanCancelAuction(ownedAuctionID); GetCancelCost(ownedAuctionID); CancelAuction(ownedAuctionID) [R] | AUCTION_CANCELED(auctionID); OWNED_AUCTIONS_UPDATED; AUCTION_HOUSE_SHOW_NOTIFICATION(AuctionRemoved) | GetOwnedAuctions(); AUCTION_HOUSE_ITEM_DELIVERY_DELAY_UPDATE traz atrasos de entrega de compra e cancelamento |
| Leiloes proprios | QueryOwnedAuctions(sorts); RequestOwnedAuctionBidderInfo(auctionID) | OWNED_AUCTIONS_UPDATED; OWNED_AUCTION_BIDDER_INFO_RECEIVED(auctionID, bidderName); AUCTION_HOUSE_AUCTIONS_EXPIRED(auctionID); AUCTION_HOUSE_SHOW_NOTIFICATION(AuctionSold/AuctionExpired) | GetNumOwnedAuctions(); GetOwnedAuctionInfo(index); GetOwnedAuctions(); HasFullOwnedAuctionResults(); GetNumOwnedAuctionTypes(); GetOwnedAuctionType(index); GetMaxOwnedAuctionBid/Buyout() |
| Lances feitos | QueryBids(sorts, auctionIDs) | BIDS_UPDATED; BID_ADDED(bidID) | GetNumBids(); GetBidInfo(index); GetBids(); HasFullBidResults(); GetNumBidTypes(); GetBidType(index) |
| Favoritos | SetFavoriteItem(itemKey, setFavorite); SearchForFavorites(sorts) | AUCTION_HOUSE_FAVORITES_UPDATED; AUCTION_HOUSE_SHOW_ERROR(FavoritesMaxed) | FavoritesAreAvailable(); HasFavorites(); HasMaxFavorites(); IsFavoriteItem(itemKey); resultados vem pelo fluxo de browse |
| Replicate (varredura total) | ReplicateItems() | REPLICATE_ITEM_LIST_UPDATE | GetNumReplicateItems(); GetReplicateItemInfo(index) (18 retornos); GetReplicateItemLink(index); GetReplicateItemTimeLeft(index); GetReplicateItemBattlePetInfo(index) |
| Throttle | (sem pedido: o sistema enfileira as mensagens) | AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED; ..._SENT; ..._RESPONSE_RECEIVED; ..._DROPPED; AUCTION_HOUSE_THROTTLED_SYSTEM_READY | IsThrottledMessageSystemReady(). Limite explicito na documentacao: SendSearchQuery e SendSellSearchQuery "restricted to 100 calls per minute" (DOC 1034, 1049) |
| Deposito | CalculateCommodityDeposit(itemID, duration, quantity); CalculateItemDeposit(item, duration, quantity) | (retorno direto, sem evento) | depositCost number? (pode ser nil) |
| Chave de item | MakeItemKey(itemID, itemLevel, itemSuffix, battlePetSpeciesID); GetItemKeyFromItem(item) | ITEM_KEY_ITEM_INFO_RECEIVED(itemID) | GetItemKeyInfo(itemKey, restrictQualityToFilter); GetItemKeySampleLink(itemKey); GetItemKeyRequiredLevel(itemKey, MayReturnNothing); GetTimeLeftBandInfo(band) |

Ciclo de vida: AUCTION_HOUSE_SHOW, AUCTION_HOUSE_CLOSED, AUCTION_HOUSE_DISABLED, AUCTION_HOUSE_SCRIPT_DEPRECATED e CloseAuctionHouse(). [local para existencia]

## Fora do escopo (uma linha)

- A documentacao nao traz a lista de tipos/valores de InventoryType, ItemQuality, WOWMONEY, nem o conteudo do mixin ItemLocationMixin; e outros arquivos da pasta Blizzard_APIDocumentationGenerated podem ter.

## Incognitas

1. Quais funcoes exigem evento de hardware (clique/tecla). A documentacao nao informa. Como conferir: no jogo, chamar sem clique, por macro/timer, uma funcao por vez e ler o erro (ADDON_ACTION_FORBIDDEN ou mensagem de acao bloqueada), comecando por PlaceBid, PostItem, StartCommoditiesPurchase e CancelAuction. Sem automatizar a compra: testar com consulta, nao com compra real.
2. O que `HasRestrictions = true` significa em runtime (hardware, combate, protegida, ou outra). Conferir como em 1, e olhar o codigo Blizzard_AuctionHouseUI do espelho para ver quem chama essas 7 funcoes.
3. Quais funcoes de leitura devolvem dados "secretos" ou nulos para addons; o campo `SecretArguments = "AllowedWhenUntainted"` aparece em quase todas as funcoes com argumento, mas seu efeito pratico nao esta na documentacao. Conferir: chamar GetItemSearchResultInfo de um addon e ver se os valores vem utilizaveis.
4. A ordem exata de eventos em cada fluxo (secao 6 e inferencia). Conferir com um addon de log de eventos (so leitura) abrindo a casa de leiloes e fazendo uma busca, e anotando a ordem.
5. Existencia real de commodities no Forever. A API tem fluxo commodity, mas se o Forever usa essa separacao ou so o fluxo de item nao esta na documentacao. Conferir: GetItemCommodityStatus(item) para itens de bolsa, ou ItemKeyInfo.isCommodity no GetItemKeyInfo.
6. Limite real de pedidos fora de SendSearchQuery/SendSellSearchQuery (100 por minuto, DOC) e fora do throttle; browse e Replicate nao tem limite documentado, e o intervalo entre ReplicateItems repetidos tambem nao. Conferir observando AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED e IsThrottledMessageSystemReady.
7. Mapeamento do indice `duration` (luaIndex) para horas, e se BigUInteger tem limite de precisao. Conferir com CalculateItemDeposit para indices 1 a 3 e comparar com a UI.
8. Se mudou algo de assinatura entre os builds 70532 e 70938: so ha lista de nomes do 70532. Conferir comparando com uma copia da documentacao do 70532, se existir.
9. Se `Environment = "All"` implica uso em qualquer ambiente de script ou so no Lua da UI (DOC linha 6). Conferir no jogo chamando C_AuctionHouse de um addon.
