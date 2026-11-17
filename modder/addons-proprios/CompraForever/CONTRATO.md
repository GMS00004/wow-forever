# CompraForever: contrato (v0.1, 2026-11-17)

Addon de um fluxo só: na AH, o dono clica Scan e um painel colado na AH mostra, com o dinheiro e o espaço de bolsa de
agora, quanto comprar de cada material para craftar receitas conhecidas de Leatherworking e vender o produto no
vendedor com lucro. Um botão de ação faz uma coisa por clique: comprar, craftar, vender. Substitui o PregaoForever.

Regras fixas (de `..\..\..\CLAUDE.md` e do dono):
- Só API oficial. Nada de automação: toda compra, craft e venda parte de um clique do dono num botão do addon.
- Um clique = no máximo uma função de ação do leilão (`StartCommoditiesPurchase`, `ConfirmCommoditiesPurchase`,
  `PlaceBid`). Compra de commodity leva dois cliques (cotar, depois confirmar). A bancada reprova o contrário (I1).
- Busca no leilão (`SendSearchQuery`, `ReplicateItems`) não é ação: pode ser encadeada depois de um clique.
- Sem código de addon de terceiro como referência. API: documentação gerada do Forever (espelho
  `Ketho/wow-ui-source-forever`, branch `forever`, build 70938) e pesquisa do PregaoForever (R1, R6).
- Fonte Lua só ASCII (o `checar-lua.mjs` exige). Texto na tela em inglês curto, como no GuiaForever.
- Nome de todo botão do addon começa com `CompraForever` (a bancada só aceita clique de hardware nesses botões).

## 1. Arquivos

| Arquivo | Papel |
|---|---|
| `CompraForever.toc` | Interface lida do cliente (16001 hoje), `## SavedVariables: CompraForeverDB`, `## SavedVariablesPerCharacter: CompraForeverCharDB`, `## OptionalDeps: Auctionator`, ordem: Dados, Nucleo, Planejador, Scanner, Compra, Painel |
| `Dados.lua` | gerado por `ferramentas\compra\gerar-dados.mjs`; não editar à mão (seção 2) |
| `Nucleo.lua` | namespace, eventos, SavedVariables, config, receitas conhecidas, dinheiro e bolsas, `/compra` (seção 3) |
| `Planejador.lua` | função pura `ns.planejar(entrada)` (seção 4); sem chamada ao WoW |
| `Scanner.lua` | busca dirigida e full scan, monta as escadas (seção 5) |
| `Compra.lua` | ações de um clique: comprar no leilão, comprar no vendedor, craftar, vender (seção 6) |
| `Painel.lua` | o painel e o botão de ação (seção 7) |

Todos os `.lua` começam com `local addon, ns = ...` e não criam global além de `CompraForeverDados`, das duas SVs e
de `SLASH_COMPRAFOREVER1`/`SlashCmdList.COMPRAFOREVER`. Os módulos falam por `ns`.

## 2. `Dados.lua` (gerado)

```lua
CompraForeverDados = {
  build = "1.60.1.70938", geradoEm = "2026-11-17 16:00",
  receitas = {
    -- chave: magia (spell ID da receita, igual a C_TradeSkillUI recipeID)
    [4096] = { nome = "Raptor Hide Harness", produto = 4455, qtd = 1,
               reagentes = { { 4461, 6 }, { 4234, 4 }, { 2321, 2 } } },
  },
  itens = {
    -- todo item que aparece como produto ou reagente
    [4455] = { nome = "Raptor Hide Harness", vende = 3096, pilha = 1 },
    [2321] = { nome = "Fine Thread", vende = 25, pilha = 20, vendedor = 100 },
  },
  fabrica = { [4233] = 3816 },  -- exemplo: reagente -> magia de Leatherworking que o produz (se houver mais de uma, a de menor magia; um nível)
}
```

- `vende`: preço de venda ao vendedor, em cobre, por unidade (`itens.vende` do `receitas-lw.json`); 0 ou ausente = não
  vende.
- `vendedor`: preço de compra no vendedor, cheio, por unidade, só para suprimento comum (nome terminado em " Thread"
  ou " Dye", ou Bleach, ou Salt) que está na lista pública de vendedor (`precos.vendedor`). Couro e os outros itens da
  lista são de estoque limitado e caros, e ficam só no leilão (decisão de 2026-11-17). O desconto de reputação é
  aplicado em jogo (config `desconto`).
- `pilha`: tamanho da pilha (`itens.pilha`; ausente = 1).
- Entram todas as receitas de `dados\pregao\receitas-lw.json` cujo produto tem `vende > 0`.

## 3. `Nucleo.lua`

- `ns.ao(evento, fn)`: um frame só para eventos; vários ouvintes por evento.
- SVs, criadas no `ADDON_LOADED`:
  - `CompraForeverDB = { config = { reserva = 0, desconto = 10, lucroMin = 50, margemMin = 5 }, ultimoFull = 0 }`
    (cobre; `desconto` e `margemMin` em %).
  - `CompraForeverCharDB = { conhecidas = { quem, em, pericia, ids = { [magia] = true }, n }, plano = <último plano> }`.
- Receitas conhecidas: em `TRADE_SKILL_SHOW`, `TRADE_SKILL_LIST_UPDATE` e `TRADE_SKILL_DATA_SOURCE_CHANGED`, 0,5 s
  depois, a mesma leitura do GuiaForever (`GuiaForever\Crafts.lua:56-95`: `C_TradeSkillUI.GetAllRecipeIDs` +
  `GetRecipeInfo(id).learned`, só a janela do próprio personagem e só Leatherworking). Sem gravação ainda: procurar em
  `GuiaForeverDB.personagens[*].receitasLW` a entrada com `quem == UnitName("player")` e `em` mais novo.
- `ns.dinheiro()` = `GetMoney() - config.reserva` (mínimo 0). `ns.espacosLivres()` = soma de
  `C_Container.GetContainerNumFreeSlots(b)` para `b = 0..4`. `ns.estoque(id)` = `C_Item.GetItemCount(id)` (só bolsas).
- `/compra` sem argumento: mostra/esconde o painel. `/compra reserva <valor>`, `/compra desconto <0-99>`,
  `/compra lucro <valor>` (valor em cobre, ou `1g20s`, `50s`, `30c`), `/compra sonda` (seção 8).

## 4. `Planejador.lua`: `ns.planejar(entrada) -> plano`

Entrada:
```lua
{ dinheiro = 51400, espacos = 30, conhecidas = { [4096] = true }, dados = CompraForeverDados,
  desconto = 10, lucroMin = 50, margemMin = 5,
  escadas = { [4461] = { { preco = 255, qtd = 20, leilao = 123, inteiro = false }, ... } },  -- crescente por preco
  estoque = { [4234] = 10, [2321] = 6 },
  revenda = nil }  -- ou { [itemID] = vendePorUnidade } (só com full scan, seção 5)
```
- `preco` é por unidade. `inteiro = true` = leilão de item, comprado inteiro (`qtd` unidades de uma vez, custo
  `preco * qtd`); `false` = commodity, compra por quantidade.

Algoritmo (guloso pelo lucro do próximo craft):
1. Custo de uma unidade de reagente, na ordem: estoque do dono (não gasta dinheiro; vale o preço do degrau mais barato
   da escada, ou o de vendedor, como custo de oportunidade), escada do leilão a partir do ponteiro, vendedor
   (`vendedor * (100 - desconto) / 100`, oferta sem fim), fabricar (`fabrica[id]` se a magia é conhecida: custo dos
   reagentes dela dividido pelo `qtd` do produto; um nível só). Para cada unidade, o mais barato entre as fontes que
   ainda têm unidade.
2. A cada passo, para cada receita conhecida com `vende > 0`, o custo do próximo craft (soma acima, consumindo
   virtualmente). Lucro = `vende * qtd - custo`. Candidata se `lucro >= lucroMin`, `lucro * 100 >= margemMin * custo`,
   o dinheiro cobre o gasto em dinheiro do craft (degrau inteiro aberto cobra o leilão todo) e as bolsas cabem
   (seção 4.1).
3. Escolhe a candidata de maior lucro, efetiva o consumo, repete. Para quando não há candidata ou após 5.000 crafts.
   `motivo` = "dinheiro" | "espaco" | "lucro" | "limite".
4. Revenda (se `entrada.revenda`): pseudo-receita "comprar e vender" para cada item com escada e `revenda[id]`, um
   reagente (o próprio item) e produto ele mesmo; entra na mesma disputa gulosa.

4.1 Bolsas: espaço usado = para cada item comprado, `ceil(qtd / pilha)`; para cada produto, `ceil(n * qtd / pilha)`.
Soma conservadora; não pode passar de `entrada.espacos`.

Saída:
```lua
{ crafts = { { magia, nome, n, custo, venda, lucro } },          -- maior lucro primeiro
  fabricar = { { magia, nome, n } },                              -- intermediários, craftar antes
  leilao = { { id, nome, qtd, precoMax, custo, inteiro, lotes = { { leilao, qtd, preco } } } },
  vendedor = { { id, nome, qtd, custo } },
  doEstoque = { { id, nome, qtd } },
  revenda = { { id, nome, qtd, precoMax, custo, venda, lucro } },
  sobra = { { id, nome, qtd } },                                  -- comprado inteiro e não usado
  totais = { gasto, venda, lucro, espacos }, motivo = "dinheiro" }
```
`gasto` = dinheiro que sai (leilão + vendedor); `lucro` = venda - gasto - valor do estoque usado. Determinístico:
empate no lucro resolve pela menor magia.

## 5. `Scanner.lua`

- `ns.scanDirigido(aoTerminar)`: ids = reagentes de receitas conhecidas com `vende > 0` que não têm `vendedor`, mais os
  reagentes das magias de `fabrica` conhecidas. Para cada id, em fila: espera `C_AuctionHouse.IsThrottledMessageSystemReady()`
  (ou `AUCTION_HOUSE_THROTTLED_SYSTEM_READY`), chama
  `C_AuctionHouse.SendSearchQuery(C_AuctionHouse.MakeItemKey(id), { { sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false } }, false)`
  (`Price` = 0 no Forever: [página] `AuctionHouseEnumsDocumentation.lua` do espelho, build 70938).
  Commodity: em `COMMODITY_SEARCH_RESULTS_UPDATED(itemID)` lê `GetNumCommoditySearchResults` e
  `GetCommoditySearchResultInfo(itemID, i)` (`unitPrice`, `quantity`, `auctionID`, `containsOwnerItem`); se não
  `HasFullCommoditySearchResults` e a soma é menor que 1.000 unidades, `RequestMoreCommoditySearchResults` (no máximo
  3 páginas). Item: em `ITEM_SEARCH_RESULTS_UPDATED(itemKey)` lê `GetNumItemSearchResults` e
  `GetItemSearchResultInfo(itemKey, i)` (`auctionID`, `quantity`, `buyoutAmount`, `containsOwnerItem`); degrau
  `preco = floor(buyoutAmount / quantity)`, `inteiro = true`; sem buyout, ignora. Ignora o que é do próprio dono.
  Tempo limite de 6 s por id: segue e marca o id como "sem resposta".
- `ns.fullScan(aoTerminar)`: só se `time() - ultimoFull >= 900`. `C_AuctionHouse.ReplicateItems()`; conta
  `GetNumReplicateItems()` a cada 1 s até o número ficar igual em 3 contagens seguidas (o evento
  `REPLICATE_ITEM_LIST_UPDATE` nem sempre chega no Forever) ou 600 s; lê 250 por quadro com
  `GetReplicateItemInfo(i)` (índice 0; retornos 3 = quantidade, 10 = buyout, 17 = itemID), degrau `inteiro = true`.
  `revenda[id]` = 11º retorno de `C_Item.GetItemInfo(id)` quando vier (preço de venda ao vendedor).
- Os dois gravam `ns.scan = { tipo = "dirigido"|"full", em = time(), escadas, revenda, semResposta = { ids } }`,
  chamam `ns.replanejar()` e `aoTerminar`. `ns.scanEstado = { ocupado, feito, total }` para a barra de progresso.
- Fechar a AH no meio aborta e mantém o scan anterior.

## 6. `Compra.lua` (cada função roda dentro do OnClick do botão de ação)

- `ns.proximaAcao()` devolve `{ texto, executar }` conforme o contexto (AH aberta, vendedor aberto, janela de
  Leatherworking aberta) e o plano; o painel mostra `texto` no botão.
- Leilão, commodity: clique 1 `C_AuctionHouse.StartCommoditiesPurchase(id, qtd)`; em `COMMODITY_PRICE_UPDATED(unit, total)`
  o botão vira "Confirm <qtd> <nome> <total>" se `total <= custoPlanejado * 1.02 + 1`, senão
  `CancelCommoditiesPurchase()`, marca "price rose" e pede novo Scan desse item. Clique 2 `ConfirmCommoditiesPurchase(id, qtd)`.
  `COMMODITY_PURCHASE_SUCCEEDED`/`FAILED` avançam ou marcam erro.
- Leilão, item: um `PlaceBid(auctionID, preco * qtd)` por clique, lote a lote. Plano vindo de full scan (sem
  `auctionID`): antes de comprar o item, uma busca dirigida só dele (sem clique) e replanejar.
- Vendedor (com `MERCHANT_SHOW`): um clique compra todos os reagentes de vendedor do plano: acha o índice com
  `GetMerchantItemID(i)`, `BuyMerchantItem(i, qtd)` em pedaços de até `GetMerchantItemMaxStack(i)`.
- Craftar (janela de Leatherworking pronta): um clique = `C_TradeSkillUI.CraftRecipe(magia, n)` da próxima linha, na
  ordem `fabricar` e depois `crafts`; `n` limitado ao que os reagentes nas bolsas permitem.
- Vender (com `MERCHANT_SHOW`): um clique vende, com `C_Container.UseContainerItem(b, s)`, os produtos do plano que
  estão nas bolsas, até a quantidade craftada no plano. Nada além dos produtos do plano.
- Depois de cada ação: `ns.replanejar()` com o estoque novo.

## 7. `Painel.lua`

- Frame `CompraForeverPainel`, 300 de largura, ancorado `TOPLEFT` em `AuctionHouseFrame` `TOPRIGHT` (+4, 0) quando a AH
  abre (`AUCTION_HOUSE_SHOW`); em `MerchantFrame` com o vendedor aberto; no frame da janela de profissão quando ela
  abre (`ProfessionsFrame`, do `Blizzard_Professions` carregado sob demanda; existe no Forever, pasta Camelot); escondido nos `*_CLOSED`.
- De cima para baixo: dinheiro agora e bolsas livres; hora e tipo do scan; botões `CompraForeverScan` ("Scan") e
  `CompraForeverFull` ("Full scan", com a recarga em mm:ss); barra de progresso; linhas do plano (crafts:
  "15x Raptor Hide Harness +1g 27s"; compras: "90 Raptor Hide <= 2s 55c 2g 31s", com marca de feito); totais
  ("Spend 4g 10s, profit +1g 80s"); o botão grande `CompraForeverAcao` com o texto de `ns.proximaAcao()`.
- Sem plano lucrativo: "Nothing pays now" e o motivo.
- Valores em moeda com `GetCoinTextureString` quando existir, senão "1g 27s 05c".

## 8. `/compra sonda`

Imprime, para Heavy Leather (4234), Raptor Hide (4461) e Fine Thread (2321), `GetItemKeyInfo(MakeItemKey(id)).isCommodity`;
faz a busca dirigida de 5 ids e imprime o tempo de cada resposta; imprime `IsThrottledMessageSystemReady()`.
Os resultados vão para `comum\referencia\forever.md` com a marca [local].

## 9. Bancada

`node ferramentas\guia\pregao\bancada-pregao.mjs --addon addons-proprios\CompraForever --cenarios compra`, com o
prefixo de botão e os nomes das SVs vindos do addon carregado (não fixos em `PregaoForever`), o falso novo
`ferramentas\guia\pregao\bancada\compra.lua` (profissão, vendedor, venda, replicate) e os cenários em
`ferramentas\guia\casos-pregao\cenarios\compra\`. O planejador tem teste próprio:
`node ferramentas\compra\testar-planejador.mjs`.
