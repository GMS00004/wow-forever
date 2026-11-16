> Relatório de pesquisa de 2026-11-16, da onda 1 do design do PregaoForever, gravado como estava (foto do dia). `<espelho>`, `<dados>` e `<tmp>` eram pastas temporárias da sessão; o Apêndice D do `DESIGN.md` diz como refazê-las. Onde este relatório e o `DESIGN.md` divergem, vale o `DESIGN.md`.

# R1c - Existencia e assinatura das APIs vizinhas ao leilao (WoW Forever 1.60.1 build 70938)

Data da leitura: 2026-11-16. Tudo abaixo foi lido nesta maquina (marca `local`). Nenhuma pagina web foi aberta. Nada foi escrito fora deste relatorio e da pasta de temporarios.

## Legenda de caminhos

- `LISTA/` = `C:/GMS/Claude Code Projects/wow/modder/ferramentas/guia/api-forever/` (listas oficiais, build 70532, pelo brief).
- `DOC/` = `<espelho>/Interface/AddOns/Blizzard_APIDocumentationGenerated/` (documentacao gerada, build 70938).
- `UI/` = `<espelho>/Interface/AddOns/` (codigo da Blizzard, build 70938).
- Versao do espelho confirmada em `<espelho>/version.txt`: `1.60.1.70938`.

Convencoes das tabelas: "na lista" diz se o nome aparece entre aspas numa linha de `LISTA/*.lua` (arquivo:linha). "Assinatura" vem da documentacao gerada (`DOC/`) quando ha; sem documentacao, "sem doc" e o uso no codigo da Blizzard (`UI/`) fica na ultima coluna. Retornos sem documentacao foram inferidos pelas variaveis que a propria Blizzard recebe (inferencia de uso, nao contrato).

Nota sobre restricao: as entradas `SecretArguments = "AllowedWhenUntainted"` aparecem em quase toda funcao documentada. O significado exato disso nao esta definido no espelho (ver Incognitas).

---

## 1. Correio

`C_Mail` na lista tem 5 funcoes, todas documentadas. Nao existe funcao `C_Mail` para ler a caixa, pegar dinheiro/item ou enviar. Essas operacoes usam globais antigas, sem documentacao no build 70938.

| Nome | Na lista | Assinatura | Restricao | Uso na Blizzard (quando sem doc) |
|---|---|---|---|---|
| C_Mail.CanCheckInbox | sim, `LISTA/GlobalAPI.lua:2824` | `()` -> `canCheckInbox:bool, secondsUntilAllowed:number` (`DOC/MailInfoDocumentation.lua:11`) | nenhuma | - |
| C_Mail.GetCraftingOrderMailInfo | sim, `GlobalAPI.lua:2825` | `(inboxIndex:luaIndex)` -> `info:CraftingOrderMailInfo?` (`MailInfoDocumentation.lua:21`) | AllowedWhenUntainted | - |
| C_Mail.HasInboxMoney | sim, `GlobalAPI.lua:2826` | `(inboxIndex:luaIndex)` -> `inboxItemHasMoneyAttached:bool` (`MailInfoDocumentation.lua:36`) | AllowedWhenUntainted | - |
| C_Mail.IsCommandPending | sim, `GlobalAPI.lua:2827` | `()` -> `isCommandPending:bool` (`MailInfoDocumentation.lua:51`) | nenhuma | - |
| C_Mail.SetOpeningAll | sim, `GlobalAPI.lua:2828` | `(openingAll:bool)` (`MailInfoDocumentation.lua:60`) | AllowedWhenUntainted | - |
| GetInboxNumItems | sim, `GlobalAPI.lua:5484` | sem doc | - | `UI/Blizzard_MailFrame/MailFrame.lua:317`: `local numItems, totalItems = GetInboxNumItems();` |
| GetInboxHeaderInfo | sim, `GlobalAPI.lua:5480` | sem doc | - | `MailFrame.lua:340`: atribui 15 valores (packageIcon ... firstItemLink) |
| GetInboxInvoiceInfo | sim, `GlobalAPI.lua:5481` | sem doc | - | `MailFrame.lua:576` e `:790`: 10 a 12 valores |
| GetInboxText | sim, `GlobalAPI.lua:5485` | sem doc | - | `MailFrame.lua:781`: `bodyText, stationeryID1, stationeryID2, isTakeable, isInvoice, isConsortium` |
| GetInboxItem | sim, `GlobalAPI.lua:5482` | sem doc | - | `MailFrame.lua:712`: `name, id, itemTexture, count, quality, canUse, isCurrency` |
| GetInboxItemLink | sim, `GlobalAPI.lua:5483` | sem doc | - | nenhum uso encontrado |
| TakeInboxMoney | sim, `GlobalAPI.lua:6604` | sem doc | - | `MailFrame.lua:1648`: `TakeInboxMoney(self.mailIndex)` |
| TakeInboxItem | sim, `GlobalAPI.lua:6603` | sem doc | - | `MailFrame.lua:1651`: `TakeInboxItem(self.mailIndex, self.attachmentIndex)` |
| AutoLootMailItem | sim, `GlobalAPI.lua:34` | sem doc | - | `MailFrame.lua:478`: `AutoLootMailItem(index)` |
| CheckInbox | sim, `GlobalAPI.lua:5079` | sem doc | - | `MailFrame.lua:486`: `CheckInbox()` |
| DeleteInboxItem | sim, `GlobalAPI.lua:5169` | sem doc | - | `MailFrame.lua:585`: `DeleteInboxItem(InboxFrame.openMailID)` |
| SendMail | sim, `GlobalAPI.lua:6412` | sem doc | - | `MailFrame.lua:1278`: `SendMail(to, subject, body, replyMailID)` |
| HasNewMail | sim, `GlobalAPI.lua:6011` | sem doc | - | `UI/Blizzard_Minimap/Mainline/Minimap.lua:510`: `if ( HasNewMail() )` |

Eventos (todos na lista e documentados em `DOC/MailInfoDocumentation.lua`):

| Evento | Na lista | Documentacao | Payload |
|---|---|---|---|
| MAIL_SHOW | sim, `LISTA/Events.lua:1304` | `MailInfoDocumentation.lua:137` | nenhum |
| MAIL_CLOSED | sim, `Events.lua:1297` | `:84` | nenhum |
| MAIL_INBOX_UPDATE | sim, `Events.lua:1299` | `:100` (UniqueEvent) | nenhum |
| MAIL_SUCCESS | sim, `Events.lua:1305` | `:143` | `itemID:number?` |
| MAIL_FAILED | sim, `Events.lua:1298` | `:90` | `itemID:number?` |
| UPDATE_PENDING_MAIL | sim, `Events.lua:1309` | `:171` | nenhum |

---

## 2. Bolsas

| Nome | Na lista | Assinatura | Restricao | Uso / observacao |
|---|---|---|---|---|
| C_Container.GetContainerNumSlots | sim, `LISTA/GlobalAPI.lua:1232` | `(containerIndex:BagIndex)` -> `numSlots:number` (`DOC/ContainerDocumentation.lua:313`) | AllowedWhenUntainted | - |
| C_Container.GetContainerItemInfo | sim, `GlobalAPI.lua:1225` | `(containerIndex, slotIndex)` -> `containerInfo:ContainerItemInfo` (`ContainerDocumentation.lua:192`) | MayReturnNothing; AllowedWhenUntainted | tabela `ContainerItemInfo` (`:766-783`): iconFileID, stackCount, isLocked, quality?, isReadable, hasLoot, hyperlink, isFiltered, hasNoValue, itemID, isBound, itemName. Sem preco de venda. |
| C_Container.GetContainerItemLink | sim, `GlobalAPI.lua:1226` | `(containerIndex, slotIndex)` -> `itemLink:cstring` (`ContainerDocumentation.lua:209`) | AllowedWhenUntainted | - |
| C_Container.GetContainerItemID | sim, `GlobalAPI.lua:1224` | `(containerIndex, slotIndex)` -> `containerID:number` (`ContainerDocumentation.lua:175`) | MayReturnNothing; AllowedWhenUntainted | - |
| C_Container.UseContainerItem | sim, `GlobalAPI.lua:1257` | `(containerIndex, slotIndex, unitToken?, bankType?, reagentBankOpen=false)` (`ContainerDocumentation.lua:584`) | AllowedWhenUntainted | - |
| C_Container.PickupContainerItem | sim, `GlobalAPI.lua:1240` | `(containerIndex, slotIndex)` (`ContainerDocumentation.lua:420`) | AllowedWhenUntainted | - |
| C_Item.GetItemCount | sim, `GlobalAPI.lua:2514` | `(itemInfo, includeBank=false, includeUses=false, includeReagentBank=false, includeAccountBank=false)` -> `count:number` (`DOC/ItemDocumentation.lua:451`) | AllowedWhenUntainted | `UI/Blizzard_FrameXMLUtil/ItemUtil.lua:320` usa a versao C_. |
| GetItemCount (global) | nao, nenhuma entrada quotada | - | - | 0 chamadas de funcao global na UI. |
| BAG_UPDATE | sim, `LISTA/Events.lua:518` | `DOC/ContainerDocumentation.lua:659` (SynchronousEvent) | `bagID:BagIndex` | - |
| BAG_UPDATE_DELAYED | sim, `Events.lua:520` | `ContainerDocumentation.lua:675` (UniqueEvent) | nenhum | - |

---

## 3. Item

| Nome | Na lista | Assinatura | Restricao | Uso / observacao |
|---|---|---|---|---|
| C_Item.GetItemInfo | sim, `LISTA/GlobalAPI.lua:2525` | `(itemInfo:ItemInfo)` -> 18 retornos, na ordem: 1 itemName, 2 itemLink, 3 itemQuality, 4 itemLevel, 5 itemMinLevel, 6 itemType, 7 itemSubType, 8 itemStackCount, 9 itemEquipLoc, 10 itemTexture, **11 sellPrice**, 12 classID, 13 subclassID, 14 bindType, 15 expansionID, 16 setID?, 17 isCraftingReagent, 18 itemDescription (`DOC/ItemDocumentation.lua:626-657`) | MayReturnNothing; AllowedWhenUntainted | - |
| GetItemInfo (global) | nao | - | - | 0 chamadas de funcao global na UI. Os 68 arquivos que contem a palavra usam metodos proprios (`self:GetItemInfo()`). |
| C_Item.GetItemInfoInstant | sim, `GlobalAPI.lua:2526` | `(itemInfo)` -> `itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID` (`ItemDocumentation.lua:659`) | MayReturnNothing; AllowedWhenUntainted | - |
| C_Item.RequestLoadItemDataByID | sim, `GlobalAPI.lua:2597` | `(itemInfo)` -> nada (`ItemDocumentation.lua:1710`) | AllowedWhenUntainted | - |
| C_Item.GetItemNameByID | sim, `GlobalAPI.lua:2538` | `(itemInfo)` -> `itemName:string?` (`ItemDocumentation.lua:846`) | AllowedWhenUntainted | - |
| C_Item.GetItemQualityByID | sim, `GlobalAPI.lua:2542` | `(itemInfo)` -> `itemQuality:ItemQuality?` (`ItemDocumentation.lua:906`) | AllowedWhenUntainted | - |
| C_Item.GetItemMaxStackSizeByID | sim, `GlobalAPI.lua:2536` | `(itemInfo)` -> `stackSize:number?` (`ItemDocumentation.lua:816`) | AllowedWhenUntainted | - |
| ItemLocation (global) | nao, sem entrada quotada | - | - | Existe como tabela Lua: `UI/Blizzard_ObjectAPI/Mainline/ItemLocation.lua:1-2` (`ItemLocation = {}; ItemLocationMixin = {};`). Uso: `UI/Blizzard_FrameXMLUtil/ItemUtil.lua:326` (`ItemLocation:CreateFromBagAndSlot`). |
| ItemLocationMixin | sim, `LISTA/Mixins.lua:1782` | - | - | - |
| ItemMixin | sim, `LISTA/Mixins.lua:1783` | - | - | - |
| Item:CreateFromItemID (mixin, estatico) | nao, sem entrada quotada | Lua: `UI/Blizzard_ObjectAPI/Mainline/Item.lua:40`: `(itemID)` -> `ItemMixin` | - | Chamado em 44 arquivos da UI. |
| ItemMixin:ContinueOnItemLoad | nao, sem entrada quotada | Lua: `UI/Blizzard_ObjectAPI/Mainline/Item.lua:330`: `(callbackFunction)`; executa na hora se o item ja estiver carregado | - | 24 arquivos da UI. |
| GET_ITEM_INFO_RECEIVED | sim, `LISTA/Events.lua:1119` | `DOC/ItemDocumentation.lua:1813` (SynchronousEvent) | `itemID:number, success:bool` | - |
| ITEM_DATA_LOAD_RESULT | sim, `LISTA/Events.lua:1123` | `DOC/ItemDocumentation.lua:1855` (SynchronousEvent) | `itemID:number, success:bool` | - |

---

## 4. Dinheiro

| Nome | Na lista | Assinatura | Restricao | Uso / observacao |
|---|---|---|---|---|
| GetMoney (global) | sim, `LISTA/GlobalAPI.lua:5611` | `()` -> `result:number` (`DOC/PlayerScriptDocumentation.lua:642`) | nenhuma | 37 arquivos na UI (ex.: `UI/Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseSellFrame.lua:477`). |
| GetMoneyString (global) | sim, `LISTA/FrameXML.lua:2057` | sem doc da API; funcao Lua: `UI/Blizzard_SharedXML/FormattingUtil.lua:72`: `(money, separateThousands, checkGoldThreshold, showZeroAsGold, color)` | - | 43 chamadas (linhas) na UI. |
| GetCoinTextureString (global) | nao | - | - | 0 usos. |
| C_CurrencyInfo.GetCoinTextureString | sim, `LISTA/GlobalAPI.lua:1380` | `(amount:WOWMONEY, fontHeight:number=14)` -> `result:cstring` (`DOC/CurrencyInfoDocumentation.lua:161`) | AllowedWhenUntainted | - |
| PLAYER_MONEY | sim, `LISTA/Events.lua:596` | `DOC/CurrencyInfoDocumentation.lua:637` (namespace C_CurrencyInfo) | nenhum | - |

---

## 5. Tempo e timers

| Nome | Na lista | Assinatura | Restricao | Uso / observacao |
|---|---|---|---|---|
| GetServerTime | sim, `LISTA/GlobalAPI.lua:5867` | `()` -> `time:number` (`DOC/SystemTimeDocumentation.lua:30`) | nenhuma | - |
| time (global) | sim, `GlobalAPI.lua:7083` | sem doc | - | 22 chamadas na UI (ex.: `UI/Blizzard_ChatFrameBase/Mainline/ChatFrameOverrides.lua:556`). |
| date (global) | sim, `GlobalAPI.lua:6937` | sem doc | - | 18 chamadas na UI. |
| GetTime | sim, `GlobalAPI.lua:5921` (tambem `LISTA/ScriptObjectAPI.lua:151`) | `()` -> `time:number` (`DOC/SystemTimeDocumentation.lua:57`) | nenhuma | 106 arquivos na UI. |
| GetTimePreciseSec | sim, `GlobalAPI.lua:5922` | `()` -> `time:number` (`DOC/OsDocumentation.lua:27`) | nenhuma | 3 arquivos. |
| debugprofilestop | sim, `GlobalAPI.lua:6874` | `()` -> `elapsedMilliseconds:number`; doc: "Returns the time in milliseconds since the last debugprofilestart call." (`DOC/FrameScriptDocumentation.lua:533`) | nenhuma | 1 arquivo. Nao e relogio de parede: mede desde `debugprofilestart`. |
| C_DateAndTime.GetCurrentCalendarTime | sim, `GlobalAPI.lua:1431` | `()` -> `date:CalendarTime` (`DOC/DateAndTimeDocumentation.lua:90`) | nenhuma | - |
| C_Timer.After | sim, `GlobalAPI.lua:4174` | sem doc (nao existe arquivo de documentacao para C_Timer) | - | Os tres (After, NewTicker, NewTimer) somam 297 linhas na UI. |
| C_Timer.NewTicker | sim, `GlobalAPI.lua:4175` | sem doc | - | ver acima |
| C_Timer.NewTimer | sim, `GlobalAPI.lua:4177` | sem doc | - | ver acima |

---

## 6. Codificacao (C_EncodingUtil, todas as 10 funcoes)

Os 10 nomes estao na lista em `LISTA/GlobalAPI.lua:1538-1547`. Todos estao documentados em `DOC/EncodingUtilDocumentation.lua`. Todos tem `SecretArguments = "AllowedWhenUntainted"`. Os que tem `MayReturnNothing` estao marcados.

| Nome | Assinatura | Documentacao | Flag |
|---|---|---|---|
| CompressString | `(source:stringView, method:CompressionMethod="Deflate", level:CompressionLevel="Default")` -> `output:string` | `:11` | MayReturnNothing |
| DecompressString | `(source:stringView, method="Deflate")` -> `output:string` | `:62` | MayReturnNothing |
| EncodeBase64 | `(source:stringView, variant:Base64Variant="Standard")` -> `output:string` | `:109` | MayReturnNothing |
| DecodeBase64 | `(source:stringView, variant="Standard")` -> `output:string` | `:29` | MayReturnNothing |
| EncodeHex | `(source:stringView)` -> `output:string` | `:126` | MayReturnNothing |
| DecodeHex | `(source:string)` -> `output:string` | `:46` | MayReturnNothing |
| SerializeJSON | `(value:LuaValueVariant?, options:JSONSerializationOptions?)` -> `output:string` | `:158` | - |
| DeserializeJSON | `(source:string)` -> `value:LuaValueVariant?` | `:94` | - |
| SerializeCBOR | `(value:LuaValueVariant?, options:CBORSerializationOptions?)` -> `output:string` | `:142` | - |
| DeserializeCBOR | `(source:stringView)` -> `value:LuaValueVariant?` | `:79` | - |

Enumeracoes: `Base64Variant` = Standard, StandardUrlSafe; `CompressionMethod` = Deflate, Zlib, Gzip; `CompressionLevel` = Default, OptimizeForSpeed, OptimizeForSize (`DOC/EncodingUtilDocumentation.lua:181-218`).

---

## 7. Som e alerta

| Nome | Na lista | Assinatura | Restricao | Uso / observacao |
|---|---|---|---|---|
| PlaySound (global) | sim, `GlobalAPI.lua:6291` | sem doc propria. A versao documentada e `C_Sound.PlaySound` (`DOC/SoundDocumentation.lua:52`): `(soundKitID:number, uiSoundSubType=..., forceNoDuplicates=false, runFinishCallback=false, overridePriority?, volumeOverride?)` -> `success:bool, soundHandle:SoundHandle` | MayReturnNothing; AllowedWhenUntainted | 473 arquivos na UI. C_Sound.PlaySound na lista: `GlobalAPI.lua:3885`. |
| PlaySoundFile | sim, `GlobalAPI.lua:6292` | sem doc | - | 0 usos na UI. |
| FlashClientIcon | sim, `GlobalAPI.lua:5230` | `(briefly:bool=false)` (`DOC/ClientDocumentation.lua:10`) | AllowedWhenUntainted | 13 arquivos na UI. |
| RaidNotice_AddMessage | nao | sem doc; so existe no codigo `UI/Blizzard_DeprecatedRaidWarning/Deprecated_RaidWarning.lua:8` (wrapper de `RaidWarningUtil.AddMessage`). Esse arquivo so carrega se a CVar `loadDeprecationFallbacks` estiver ativa (`:4-5`). | - | 0 chamadas. A CVar esta na lista em `LISTA/CVars.lua:1016` com valor `"1"`. Substituto: `RaidWarningUtil.AddMessage(textString, colorInfo, displayTime, messageType)` (`UI/Blizzard_RaidWarning/RaidWarningUtil.lua:28`). |
| UIErrorsFrame | sim, `LISTA/Frames.lua:361` | frame global, sem doc de API | - | 109 chamadas `UIErrorsFrame:AddMessage` na UI. |
| Screenshot | sim, `GlobalAPI.lua:6397` | `()` -> nada (`DOC/ClientDocumentation.lua:95`) | nenhuma flag de restricao | 10 arquivos. |
| LoggingChat | sim, `GlobalAPI.lua:6211` | sem doc | - | Uso: `UI/Blizzard_ChatFrameBase/Shared/SlashCommands.lua:847-851` (consulta sem argumento e liga/desliga com booleano). |
| LoggingCombat | sim, `GlobalAPI.lua:6212` | sem doc | - | Uso: `SlashCommands.lua:858-859`. |

---

## 8. Teclas

| Nome | Na lista | Assinatura | Restricao | Uso / observacao |
|---|---|---|---|---|
| SetOverrideBindingClick | sim, `GlobalAPI.lua:6490` | sem doc | - | 3 arquivos (ex.: `UI/Blizzard_RestrictedAddOnEnvironment/RestrictedFrames.lua`, alias local). |
| SetOverrideBinding | sim, `GlobalAPI.lua:6489` | sem doc | - | 3 arquivos; ex.: `UI/Blizzard_GamepadSharedUtility/InputBindingStack/InputActionBinding.lua:22`: `SetOverrideBinding(UIParent, true, self.key, self.action)`. |
| ClearOverrideBindings | sim, `GlobalAPI.lua:5098` | sem doc | - | 1 arquivo: `RestrictedFrames.lua:538`. |
| SetBindingClick | sim, `GlobalAPI.lua:6425` | sem doc | - | 1 arquivo. |
| SetBinding | sim, `GlobalAPI.lua:6424` | sem doc | - | 5 arquivos. |
| GetBindingKey | sim, `GlobalAPI.lua:5319` | sem doc | - | 28 arquivos (ex.: `UI/Blizzard_ActionBar/Shared/ActionButton.lua:498`). |
| InCombatLockdown | sim, `GlobalAPI.lua:6023` | `()` -> `inCombatLockdown:bool`, documentada no sistema RestrictedActions com `Namespace = ""` (`DOC/RestrictedActionsDocumentation.lua:45-53`) | nenhuma flag | 9 arquivos. |
| C_RestrictedActions.InCombatLockdown | nao | - | - | Nao existe na lista. A funcao e global. |
| SecureActionButtonTemplate | sim, `LISTA/Templates.lua:3042` (tabela: `type="Button", mixin="SecureActionButtonMixin", inherits="SecureFrameTemplate"`) | - | - | 4 arquivos na UI referenciam o nome. |
| UIPanelButtonTemplate | sim, `LISTA/Templates.lua:230` (e mais 16 linhas, ex. `:250`, `:353`) | - | - | Definido em `UI/Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:315`: `<Button name="UIPanelButtonTemplate" inherits="UIPanelButtonNoTooltipTemplate" mixin="UIPanelButtonMixin" virtual="true">`. |

---

## 9. Profissoes

Campos de `CraftingRecipeSchematic` (retorno de `C_TradeSkillUI.GetRecipeSchematic`), em `DOC/TradeSkillUITypesDocumentation.lua:281-297`:
- `recipeID, icon, quantityMin, quantityMax, name, recipeType, productQuality?, outputItemID?, isRecraft, hasCraftingOperationInfo`
- `reagentSlotSchematics` (tabela de `CraftingReagentSlotSchematic`, `:243-259`). Cada um tem:
  - `reagents` (tabela de `CraftingReagent` = `{itemID?, currencyID?}`, `:214-220`)
  - `quantityRequired:number` (quantidade exigida)
  - `reagentType`, `variableQuantities` (tabela de `{reagent, quantity}`, `:328-335`), `required:bool`, `hiddenInCraftingForm:bool`, `slotInfo?`, `dataSlotType`, `dataSlotIndex`, `slotIndex`, `orderSource?`

Estrutura `CraftingReagentInfo` (usada como entrada de craft e de `GetRecipeOutputItemData`): `reagent:CraftingReagent`, `dataSlotIndex`, `quantity` (`:223-230`).

| Nome | Na lista | Assinatura | Restricao | Uso / observacao |
|---|---|---|---|---|
| C_TradeSkillUI.GetRecipeSchematic | sim, `LISTA/GlobalAPI.lua:4382` | `(recipeSpellID:number, isRecraft:bool, recipeLevel:luaIndex?)` -> `schematic:CraftingRecipeSchematic` (`DOC/TradeSkillUIDocumentation.lua:753`) | AllowedWhenUntainted | - |
| C_TradeSkillUI.GetAllRecipeIDs | sim, `GlobalAPI.lua:4323` | sem doc | - | 0 usos. A forma global `GetAllRecipeIDs` nao existe na lista. |
| C_TradeSkillUI.GetRecipeInfo | sim, `GlobalAPI.lua:4371` | `(recipeSpellID:number, recipeLevel:luaIndex?)` -> `recipeInfo:TradeSkillRecipeInfo?` (`TradeSkillUIDocumentation.lua:639`) | AllowedWhenUntainted | - |
| C_TradeSkillUI.GetRecipeItemLink | sim, `GlobalAPI.lua:4374` | sem doc | - | 0 usos. |
| C_TradeSkillUI.GetRecipeOutputItemData | sim, `GlobalAPI.lua:4378` | `(recipeSpellID, reagents:table<CraftingReagentInfo>?, allocationItemGUID?, overrideQualityID?, recraftOrderID?)` -> `outputInfo:CraftingRecipeOutputInfo` (`TradeSkillUIDocumentation.lua:687`) | AllowedWhenUntainted | - |
| C_TradeSkillUI.IsTradeSkillReady | sim, `GlobalAPI.lua:4423` | sem doc | - | 1 arquivo: `UI/Blizzard_ProfessionsTemplates/Blizzard_Professions.lua:285`. Forma global `IsTradeSkillReady`: nao existe na lista. |
| GetTradeSkillInfo | nao | - | - | 0 usos. |
| GetNumTradeSkills | nao | - | - | 0 usos. |
| GetTradeSkillReagentInfo | nao | - | - | 0 usos. |
| GetCraftInfo | nao | - | - | 0 usos. |
| TRADE_SKILL_SHOW | sim, `LISTA/Events.lua:1900` | `DOC/TradeSkillUIDocumentation.lua:1400` (TradeSkillShow) | nenhuma | - |
| TRADE_SKILL_LIST_UPDATE | sim, `Events.lua:1898` | `TradeSkillUIDocumentation.lua:1388` | nenhuma | - |
| NEW_RECIPE_LEARNED | sim, `Events.lua:1883` | `TradeSkillUIDocumentation.lua:1252` | nenhuma | - |

---

## 10. Vendedor

| Nome | Na lista | Assinatura | Restricao | Uso / observacao |
|---|---|---|---|---|
| C_MerchantFrame.GetBuybackItemID | sim, `LISTA/GlobalAPI.lua:2885` | `(buybackSlotIndex:luaIndex)` -> `buybackItemID:number` (`DOC/MerchantFrameDocumentation.lua:11`) | MayReturnNothing; AllowedWhenUntainted | - |
| C_MerchantFrame.GetItemInfo | sim, `GlobalAPI.lua:2886` | `(index:luaIndex)` -> `info:MerchantItemInfo` (`MerchantFrameDocumentation.lua:27`) | MayReturnNothing; AllowedWhenUntainted | Tabela `MerchantItemInfo` (`:126-142`): name?, texture, price, stackCount, numAvailable, isPurchasable, isUsable, hasExtendedCost, currencyID?, spellID?, isQuestStartItem. |
| C_MerchantFrame.GetMerchantCurrencies | sim, `GlobalAPI.lua:2887` | `()` -> `currencies:table<number>` (`:43`) | MayReturnNothing | - |
| C_MerchantFrame.GetNumJunkItems | sim, `GlobalAPI.lua:2888` | `()` -> `numJunkItems:number` (`:53`) | nenhuma | - |
| C_MerchantFrame.IsMerchantItemRefundable | sim, `GlobalAPI.lua:2889` | `(index:luaIndex)` -> `refundable:bool` (`:62`) | AllowedWhenUntainted | - |
| C_MerchantFrame.IsSellAllJunkEnabled | sim, `GlobalAPI.lua:2890` | `()` -> `enabled:bool` (`:77`) | nenhuma | - |
| C_MerchantFrame.SellAllJunkItems | sim, `GlobalAPI.lua:2891` | `()` (`:86`) | nenhuma | - |
| GetMerchantNumItems | sim, `GlobalAPI.lua:5602` | sem doc | - | Uso: `UI/Blizzard_UIPanels_Game/Mainline/MerchantFrame.lua:253`. |
| GetMerchantItemInfo (global) | nao | - | - | Uso so na variante `UI/Blizzard_UIPanels_Game/Vanilla/MerchantFrame.lua:200` e `:586`. A variante Mainline usa `C_MerchantFrame.GetItemInfo(index)` (`Mainline/MerchantFrame.lua:290`). |
| GetMerchantItemLink | sim, `GlobalAPI.lua:5600` | sem doc | - | Uso: `Mainline/MerchantFrame.lua:258`. |
| BuyMerchantItem | sim, `GlobalAPI.lua:76` | sem doc | - | 16 chamadas. Nao ha `C_MerchantFrame.BuyMerchantItem`: a compra e global. |
| MERCHANT_SHOW | sim, `LISTA/Events.lua:1332` | `DOC/MerchantFrameDocumentation.lua:110` | nenhuma | - |
| MERCHANT_CLOSED | sim, `Events.lua:1330` | `:94` | nenhuma | - |
| MERCHANT_UPDATE | sim, `Events.lua:1333` | `:116` | nenhuma | - |

---

## 11. Tooltip

| Nome | Na lista | Assinatura | Restricao | Uso / observacao |
|---|---|---|---|---|
| TooltipDataProcessor | nao | Lua global: `UI/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua:177`. Metodos: `AddTooltipPreCall(tooltipType, func)` (`:195`), `AddTooltipPostCall(tooltipType, func)` (`:199`), `AddLinePreCall(lineType, func)` (`:203`), `AddLinePostCall(lineType, func)` (`:207`). | - | Ausente das listas, mas definida no codigo do build 70938. |
| Enum.TooltipDataType | sim, `LISTA/LuaEnum.lua:7778` | Valores: Item=0, Spell=1, Unit=2, Corpse=3, Object=4, Currency=5, BattlePet=6, UnitAura=7, AzeriteEssence=8, CompanionPet=9, Mount=10, PetAction=11, Achievement=12, EnhancedConduit=13, EquipmentSet=14, InstanceLock=15, PvPBrawl=16, RecipeRankInfo=17, Totem=18, Toy=19, CorruptionCleanser=20, MinimapMouseover=21, Flyout=22, Quest=23, QuestPartyProgress=24, Macro=25, Debug=26, Outfit=27 | - | `Item` = 0 (`LuaEnum.lua:7779`). |
| C_TooltipInfo.GetItemByID | sim, `GlobalAPI.lua:4208` | `(itemID:number, quality:number?, itemContext:number?, treasureContextLevel:number?)` -> `data:TooltipData` (`DOC/TooltipInfoDocumentation.lua:439`) | MayReturnNothing; AllowedWhenUntainted | - |
| C_TooltipInfo.GetHyperlink | sim, `GlobalAPI.lua:4202` | `(hyperlink:cstring, optionalArg1:number?, optionalArg2:number?, hideVendorPrice:bool?)` -> `data:TooltipData` (`TooltipInfoDocumentation.lua:337`) | MayReturnNothing; AllowedWhenUntainted | - |

---

## 12. Listas e desenho

| Nome | Na lista | Assinatura / definicao | Restricao | Uso / observacao |
|---|---|---|---|---|
| ScrollUtil | nao | Lua: `UI/Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua:11` (`ScrollUtil = {};`) | - | Ausente das listas. Ex.: `AddInitializedFrameCallback` (`:21`), `RegisterTableBuilder` (`:1661`). |
| CreateDataProvider | sim, `LISTA/FrameXML.lua:1186` | Lua: `UI/Blizzard_SharedXML/DataProvider.lua:277`: `(tbl)` | - | - |
| CreateScrollBoxListLinearView | sim, `LISTA/FrameXML.lua:1222` | Lua: `UI/Blizzard_SharedXML/Shared/Scroll/ScrollBoxLinearView.lua:246`: `(top, bottom, left, right, spacing)` | - | - |
| WowScrollBoxList | sim, `LISTA/Templates.lua:4043` | XML: `UI/Blizzard_SharedXML/Shared/Scroll/ScrollTemplates.xml:4` (`inherits="ScrollBoxBaseTemplate"`, `mixin="ScrollBoxListMixin"`) | - | - |
| WowTrimScrollBar | sim, `LISTA/Templates.lua:4053` | XML: `UI/Blizzard_SharedXML/Shared/Scroll/TrimScrollBar.xml:25` (EventFrame) | - | - |
| MinimalScrollBar | sim, `LISTA/Templates.lua:1069` (e mais 2) | XML: `UI/Blizzard_SharedXML/Shared/Scroll/MinimalScrollBar.xml:15` | - | - |
| CreateFramePool | sim, `LISTA/FrameXML.lua:1194` | Lua: `UI/Blizzard_SharedXMLBase/Pools.lua:857`: `CreateFramePool = CreateSecureFramePool;` (funcao em `Pools.lua:736`) | - | 201 arquivos na UI. |
| EventRegistry | nao | Lua: `UI/Blizzard_SharedXMLBase/GlobalCallbackRegistry.lua:1`: `EventRegistry = CreateFromMixins(CallbackRegistryMixin);` | - | Ausente das listas. |
| CallbackRegistryMixin | sim, `LISTA/Mixins.lua:456` | Lua: `UI/Blizzard_SharedXMLBase/CallbackRegistry.lua:52` | - | - |
| CreateLine | sim, `LISTA/WidgetAPI.lua:553` | `(name?, drawLayer?, templateName?, subLevel?)` -> `line:SimpleLine` (`DOC/SimpleFrameAPIDocumentation.lua:95`) | `SecretArguments = "NotAllowed"` | 5 arquivos. |
| SetStartPoint | sim, `LISTA/WidgetAPI.lua:307` | `(relativePoint:FramePoint, relativeTo:ScriptRegion, offsetX=0, offsetY=0)` (`DOC/SimpleLineAPIDocumentation.lua:100`) | AllowedWhenUntainted | 10 arquivos. |
| SetEndPoint | sim, `LISTA/WidgetAPI.lua:305` | mesma assinatura (`DOC/SimpleLineAPIDocumentation.lua:77`) | AllowedWhenUntainted | - |
| SetThickness | sim, `LISTA/WidgetAPI.lua:308` | `(thickness:uiUnit)` (`DOC/SimpleLineAPIDocumentation.lua:113`) | AllowedWhenUntainted | - |
| SetColorTexture | sim, `LISTA/WidgetAPI.lua:261` | `(colorR, colorG, colorB, a:SingleColorValue?)` (`DOC/SimpleTextureBaseAPIDocumentation.lua:403`) | **AllowedWhenTainted** (diferente das outras) | 48 arquivos. |
| SetGradient | sim, `LISTA/WidgetAPI.lua:264` | `(orientation:Orientation, minColor:colorRGBA, maxColor:colorRGBA)` (`DOC/SimpleTextureBaseAPIDocumentation.lua:439`) | AllowedWhenUntainted | Uso: `UI/Blizzard_NamePlates/Blizzard_NamePlates.lua:657`: `SetGradient("VERTICAL", CreateColor(...), CreateColor(...))`. |

---

## 13. Sistema

| Nome | Na lista | Assinatura | Restricao | Uso / observacao |
|---|---|---|---|---|
| C_AddOns.IsAddOnLoaded | sim, `LISTA/GlobalAPI.lua:216` | `(name:uiAddon)` -> `loadedOrLoading:bool, loaded:bool` (`DOC/AddOnsDocumentation.lua:322`) | AllowedWhenUntainted | - |
| C_AddOns.GetAddOnMetadata | sim, `GlobalAPI.lua:205` | `(name:uiAddon, variable:cstring)` -> `value:cstring` (`AddOnsDocumentation.lua:165`) | AllowedWhenUntainted | - |
| GetBuildInfo | sim, `GlobalAPI.lua:5322` | `()` -> `buildVersion, buildNumber, buildDate, interfaceVersion:number, localizedVersion, buildInfo` (`DOC/BuildDocumentation.lua:10`) | nenhuma | - |
| GetRealmName | sim, `GlobalAPI.lua:5822` | `()` -> `realmName:cstring` (`DOC/ConnectionDocumentation.lua:69`) | nenhuma | - |
| GetNormalizedRealmName | sim, `GlobalAPI.lua:5628` | `()` -> `result:cstring` (`DOC/PlayerScriptDocumentation.lua:651`) | nenhuma | - |
| UnitFactionGroup | sim, `GlobalAPI.lua:6687` | `(unitName:cstring, checkDisplayRace=false)` -> `factionGroupTag:cstring, localized:cstring` (`DOC/UnitDocumentation.lua:1207`) | AllowedWhenUntainted | - |
| ReloadUI | sim, `LISTA/FrameXML.lua:3571` | sem doc | - | 7 arquivos: `UI/Blizzard_AddOnList/AddonList.lua:618`, `UI/Blizzard_ChatFrameBase/Shared/SlashCommands.lua:1297`. |
| C_UI.Reload | sim, `GlobalAPI.lua:4720` | sem doc com esse nome. A doc tem `UIReload` no sistema `Client` (`DOC/ClientDocumentation.lua:99`, sem namespace). | - | Uso: `UI/Blizzard_SharedXML/InterfaceUtil.lua:2`: `C_UI.Reload();`. |

---

## Extra fora das 13 familias, mas com restricao de design

O brief nao pediu, mas estes nomes mudam o desenho (cito em uma linha cada):

- `C_RestrictedActions.IsAddOnRestrictionActive(type)` -> `active:bool`; `GetAddOnRestrictionState(type)`; `CheckAllowProtectedFunctions(object, silent=false)` (`LISTA/GlobalAPI.lua:3733-3735`; `DOC/RestrictedActionsDocumentation.lua:11-70`). Tipos (`DOC/RestrictedActionsConstantsDocumentation.lua:19-31`): Combat, Encounter, ChallengeMode, PvPMatch, Map, Chat. Estados: Inactive, Activating, Active (`:6-16`). Eventos: ADDON_ACTION_BLOCKED, ADDON_ACTION_FORBIDDEN, ADDON_RESTRICTION_STATE_CHANGED (`RestrictedActionsDocumentation.lua:75-104`).
- `C_Secrets.HasSecretRestrictions()` -> `bool` e outros `Should*BeSecret` (`LISTA/GlobalAPI.lua:3778-3787`; `DOC/SecretPredicateAPIDocumentation.lua`). `SecrecyLevel`: NeverSecret, AlwaysSecret, ContextuallySecret ("may yield secret values ... depending upon factors such as addon restriction states") (`DOC/SecretWrapperConstantsDocumentation.lua:6-16`).
- `HasRestrictions = true` aparece em funcoes do `C_AuctionHouse` (ex. `DOC/AuctionHouseDocumentation.lua:62`). Para o nosso escopo, so `C_Item.DeleteItem` e `C_Item.ConfirmDeleteItem` tem essa flag (`DOC/ItemDocumentation.lua:86`, `:105`).

---

## Resumo: o que NAO existe ou tem restricao

1. Nao existe API `C_Mail` para ler a caixa, pegar item/dinheiro ou enviar. Tudo e global sem documentacao (secao 1).
2. Nao existem as globais `GetItemInfo`, `GetItemCount`, `GetCoinTextureString`, `GetTradeSkillInfo`, `GetNumTradeSkills`, `GetTradeSkillReagentInfo`, `GetCraftInfo`, `GetMerchantItemInfo` (no uso da Mainline). Usar a forma `C_` (secoes 3, 4, 9, 10).
3. `C_Item.GetItemInfo` tem `MayReturnNothing` e o preco de venda e o 11o retorno (secao 3).
4. Itens nao carregados exigem `RequestLoadItemDataByID` e evento (`ITEM_DATA_LOAD_RESULT` ou `GET_ITEM_INFO_RECEIVED`), ou `ContinueOnItemLoad`.
5. Quase toda API de dados tem `SecretArguments = "AllowedWhenUntainted"`, e `C_Secrets` e `ContextuallySecret` existem (extra).
6. `C_RestrictedActions` expoe restricoes por contexto (combate, encontro, masmorra de desafio, PvP, mapa, chat) (extra).
7. `PlaySoundFile` nao tem uso na UI. `RaidNotice_AddMessage` so existe via CVar de fallback deprecado.
8. Keybinding (`SetOverrideBinding*`, `SetBinding*`, `GetBindingKey`) nao tem documentacao: assinatura so por uso.
9. `C_RestrictedActions.InCombatLockdown` nao existe na lista; a funcao e o global `InCombatLockdown`.
10. Listas nao sao completas para globais em Lua (`ScrollUtil`, `EventRegistry`, `TooltipDataProcessor` estao so no codigo). Ausencia na lista nao prova ausencia no jogo.

---

## Incognitas (e como conferir no jogo, a mao)

Nada abaixo foi automatizado. A conferencia e manual, com o dono no jogo, e cada passo e so leitura.

1. Retornos reais de `GetInboxHeaderInfo`, `GetInboxItem`, `GetInboxText`, `GetInboxInvoiceInfo`: nao ha doc. Conferir com um `/run` simples, por exemplo `/run print(select('#', GetInboxHeaderInfo(1)))`, com a caixa aberta (MAIL_SHOW).
2. Se `C_Item.GetItemInfo` devolve `nil` para item nao cacheado, e por quanto tempo. Conferir com um item raro que nunca foi visto (`/run print(C_Item.GetItemInfo(ID))`).
3. Se `SecretArguments = "AllowedWhenUntainted"` faz addon receber valor secreto ou erro no leilao e em combate. Conferir com `/run print(C_Secrets.HasSecretRestrictions())` e, dentro e fora de combate, uma chamada de `C_AuctionHouse` (outra tarefa).
4. Se `C_RestrictedActions.IsAddOnRestrictionActive(Combat)` muda ao entrar e sair de combate, e se o evento `ADDON_RESTRICTION_STATE_CHANGED` dispara antes. Conferir com `/run print(C_RestrictedActions.IsAddOnRestrictionActive(0))` (0 = Combat).
5. Se `SetOverrideBinding` e `SetOverrideBindingClick` funcionam para addon, fora e dentro de combate, e se ha erro de acao bloqueada (`ADDON_ACTION_BLOCKED`). Conferir com um bind de teste no proprio addon.
6. Se `C_Timer.NewTicker` continua disparando durante restricoes de Combat, Chat e Map. Conferir com um ticker de 1 segundo registrando `GetServerTime()` em uma sessao longa.
7. Se `RaidNotice_AddMessage` existe no cliente com a CVar `loadDeprecationFallbacks` no padrao. Conferir com `/run print(RaidNotice_AddMessage)`.
8. Se `PlaySoundFile` funciona (zero uso na UI). Conferir com `/run PlaySoundFile("Sound\\Interface\\...")` com um caminho valido.
9. Se as listas de 70532 batem com o build 70938 do jogo. Conferir com `/run print(select(2, GetBuildInfo()))` no jogo (e o espelho ja diz 70938).

---

## Desvios do brief

- As listas sao de build 70532 e a documentacao de 70938. Usei a documentacao para assinatura e as listas para existencia, e marquei isso nas tabelas.
- Funcoes Lua da Blizzard (ex.: `GetMoneyString`, `ScrollUtil`, `EventRegistry`, `TooltipDataProcessor`) nao estao todas nas listas. Para os nomes "nao" que sao Lua, usei o codigo da UI 70938 como prova de existencia.
- Retornos de funcoes antigas sem documentacao (mail, merchant global) foram inferidos pelo uso da propria Blizzard. Isso e inferencia, nao contrato.
- O brief citou `GetAllRecipeIDs`, `GetRecipeInfo`, `GetRecipeItemLink`, `GetRecipeOutputItemData` e `IsTradeSkillReady` sem o prefixo `C_TradeSkillUI`. Testei a forma `C_TradeSkillUI.*`, que e a que existe na lista. A forma global nao existe.
- A flag `SecretArguments` nao tem definicao no espelho. A leitura de que addon nao consegue usar `AllowedWhenUntainted` em certos contextos e inferencia, a conferir no jogo.
- Forever usa a variante `Mainline` do `MerchantFrame` (inferencia: a pasta `Camelot` nao tem `MerchantFrame.lua`, e a `Mainline` chama `C_MerchantFrame.GetItemInfo`).
