# CompraForever: contrato (v0.3, 2026-11-23)

Addon de um fluxo só: na AH, o dono clica Scan e um painel colado na AH mostra, com o dinheiro e o espaço de bolsa de
agora, quanto comprar de cada material para craftar receitas conhecidas de Leatherworking e vender o produto no
vendedor com lucro. Um botão de ação faz uma coisa por clique: comprar, craftar, vender, postar no leilão. Desde a v0.2
há a vigia de preços (WATCH) e a postagem no leilão (SELL), seção 10. Desde a v0.3 há duas modalidades: a de lucro
(tudo o que as seções 1 a 11 descrevem) e a de rota, que sobe uma das seis profissões de ofício até o 150 ou o 225 pela
rota da ferramenta (seção 12). Substitui o PregaoForever.

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
| `CompraForever.toc` | Interface lida do cliente (16001 hoje), `## Version: 0.3.0`, `## SavedVariables: CompraForeverDB`, `## SavedVariablesPerCharacter: CompraForeverCharDB`, `## OptionalDeps: GuiaForever`, ordem: Dados, Nucleo, Planejador, Scanner, Vigia, Compra, Venda, Painel |
| `Dados.lua` | gerado por `ferramentas\compra\gerar-dados.mjs`; não editar à mão (seção 2) |
| `Nucleo.lua` | namespace, eventos, SavedVariables, config, receitas conhecidas, dinheiro e bolsas, `/compra` (seção 3) |
| `Planejador.lua` | função pura `ns.planejar(entrada)` (seção 4); sem chamada ao WoW |
| `Scanner.lua` | busca dirigida, full scan e busca da vigia; monta as escadas (seção 5) |
| `Vigia.lua` | lista de vigia com teto, busca periódica com a AH aberta, aviso, histórico de preços (seções 5 e 7) |
| `Compra.lua` | ações de um clique: comprar no leilão (inclusive o [WATCH]), comprar no vendedor, craftar, vender no vendedor (seção 6) |
| `Venda.lua` | postagem no leilão: fila (`/compra post`), piso (`/compra sell`), um PostCommodity/PostItem por clique (seção 6) |
| `Painel.lua` | o painel e o botão de ação; seções WATCH e SELL (seção 7) |

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
  - `CompraForeverDB = { config = { reserva = 0, desconto = 10, lucroMin = 50, margemMin = 5, duracao = 3, grande = 10000, pequena = 3000 }, ultimoFull = 0, vigia = { itens = { [id] = { nome, teto, qtd, venda } }, intervalo = 30, historico = { [id] = { { t, min, p25, unid } } } } }`
    (cobre; `desconto` e `margemMin` em %; `duracao` 1 a 3, padrão 3, é a duração do leilão postado).
    - `vigia.itens[id]`: `teto` em cobre por unidade, `qtd` (padrão 20), `venda` = piso de venda (`/compra sell`), ausente
      = sem piso. `vigia.intervalo` em segundos (padrão 30, `/compra watch every`, de 10 a 300).
    - `vigia.historico[id]`: um registro por busca que leu o item. `t` = hora (`time()`), `min` = menor preço, `p25` =
      preço no 25% das unidades à venda (da mais barata para a mais cara), `unid` = unidades à venda. Anel de 2000 por
      item: sai o mais antigo.
  - `CompraForeverCharDB = { conhecidas = { quem, em, pericia, ids = { [magia] = true }, n }, plano = <último plano> }`.
- Receitas conhecidas: em `TRADE_SKILL_SHOW`, `TRADE_SKILL_LIST_UPDATE` e `TRADE_SKILL_DATA_SOURCE_CHANGED`, 0,5 s
  depois, a mesma leitura do GuiaForever (`GuiaForever\Crafts.lua:56-95`: `C_TradeSkillUI.GetAllRecipeIDs` +
  `GetRecipeInfo(id).learned`, só a janela do próprio personagem e só Leatherworking). Sem gravação ainda: procurar em
  `GuiaForeverDB.personagens[*].receitasLW` a entrada com `quem == UnitName("player")` e `em` mais novo.
- `ns.dinheiro()` = `GetMoney() - config.reserva` (mínimo 0). `ns.espacosLivres()` = soma de
  `C_Container.GetContainerNumFreeSlots(b)` para `b = 0..4`. `ns.estoque(id)` = `C_Item.GetItemCount(id)` (só bolsas).
- `/compra` sem argumento: mostra/esconde o painel. `/compra reserva <valor>`, `/compra desconto <0-99>`,
  `/compra lucro <valor>` (valor em cobre, ou `1g20s`, `50s`, `30c`), `/compra sonda` (seção 8). Comandos da v0.2 (seção 10):
  `/compra watch <item> <teto> [qtd]`, `/compra watch` (lista), `/compra watch every <10-300>`, `/compra unwatch <item>`,
  `/compra sell <item> <piso|off>`, `/compra post <item> <preço|auto> [qtd]`, `/compra post` (fila), `/compra post clear`,
  `/compra duration <1-3>`. O item vem por ID ou link (shift-clique).
- Estado de sessão, sem SV: `ns.compraOcupada()` (cotação, lote, busca de item, pendência, ou postagem em curso) e
  `ns.vendaOcupada()` (postagem em curso). A vigia espera (2 s) enquanto há Scan em andamento ou `ns.compraOcupada()`.

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
- `ns.buscarVigia(ids, aoTerminar)`: sessão de busca `"vigia"`, mesma fila e mesma leitura de commodity e item. No fim
  não toca em `ns.scan` (só troca a escada dos ids que o scan já tinha) e não replaneja; chama
  `aoTerminar(escadas, semResposta)`. Sem dirigido, sem full, sem ids da receita: só os itens vigiados.
- Histórico: `ns.vigiaRegistrar(escadas, em, sem)` grava uma linha por item vigiado lido, ao fim de todo scan que vira
  `ns.scan` (no refresh, `S.escadas` é só o subconjunto lido) e ao fim de cada busca da vigia. Os ids em `sem` ficam como
  estavam.
- Intervalo efetivo da vigia: `max(intervalo, n_itens * 0.6 s)`, para ficar sob 100 buscas por minuto (limite da API).
  Um id entra na busca só quando o intervalo dele venceu. Com Scan em andamento ou `ns.compraOcupada()`, a vigia espera 2 s.
- `AUCTION_HOUSE_SHOW` zera as escadas e os avisos da vigia (`ns.vigia.escadas`, `ns.vigia.alerta`): o primeiro aviso
  depois de abrir a AH vem da primeira busca.
- Aviso (`ns.vigiaAvaliar`): um por passagem de "sem oportunidade" para "com oportunidade", por id. Som de raid warning
  e aviso na tela (`RaidNotice_AddMessage`), ou `print` se não houver o frame.

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
- Ordem de `acaoLeilao()` (v0.2): em andamento (cotação, compra, busca de item, Scan, postagem em curso) -> `[WATCH]`
  (`ns.vigiaOportunidade()`: o item vigiado com o menor preço mais perto do teto) -> `[SELL]` (`ns.vendaProxima()`) ->
  plano (o item mais caro primeiro).
- Vigia (`row.vigia`): a cotação da vigia passa do plano só pelo teto: `limiteCotacao` = `precoMax * qtd`, sem a folga
  de 2% e sem metade do lucro. Acima do teto, cancela, marca "Price rose above watch" e chama `ns.vigiaInvalidar(id)`
  (a escada sai; a próxima busca da vigia refaz). Item de leilão inteiro: um `PlaceBid` por lote, como no plano.
- `S.vigiaComprado[id]`: quantidade comprada pela vigia (soma em `compraFeita` com `vigia = true`).
- Venda (`Venda.lua`), um clique = uma pilha: `Post <qtd> <nome> @ <preço> (dep <depósito>) [SELL]` chama `PostCommodity` ou
  `PostItem` (item inteiro, pilha única). Se o cliente pedir (`AUCTION_HOUSE_POST_WARNING`), o botão vira
  `Confirm post <qtd> <nome>` e o clique seguinte chama `ConfirmPostCommodity`/`ConfirmPostItem`. Texto durante o
  envio: `Posting <nome>`. Prazo de 15 s sem resposta: "No answer: try again". Erro: "Post failed: try again".
- Venda, conclusão: `AUCTION_HOUSE_AUCTION_CREATED`, ou `OWNED_AUCTIONS_UPDATED` com a pilha fora da bolsa ou menor que
  antes (`talvezCriada`; o evento também dispara pela aba Leilões da Blizzard). Depois, `S.postado[id]` soma a quantidade
  e o pedido da fila perde a parte postada (sai da fila quando zera). Depósito sem dinheiro: "Not enough money for deposit".
- Venda, preço: o pedido sem preço (`auto`) e a sugestão usam o menor preço visto (`ns.vigia.escadas`, senão
  `ns.scan.escadas`). Posta nele, sem baixar (regra de igualar). A sugestão aparece só com piso (`venda`) e preço >= piso.
- Depois de cada ação: `ns.replanejar()` com o estoque novo.

## 7. `Painel.lua`

- Frame `CompraForeverPainel`, 300 de largura, ancorado `TOPLEFT` em `AuctionHouseFrame` `TOPRIGHT` (+4, 0) quando a AH
  abre (`AUCTION_HOUSE_SHOW`); em `MerchantFrame` com o vendedor aberto; no frame da janela de profissão quando ela
  abre (`ProfessionsFrame`, do `Blizzard_Professions` carregado sob demanda; existe no Forever, pasta Camelot); escondido nos `*_CLOSED`.
- De cima para baixo: dinheiro agora e bolsas livres; hora e tipo do scan; botões `CompraForeverScan` ("Scan") e
  `CompraForeverFull` ("Full scan", com a recarga em mm:ss); barra de progresso; linhas do plano (crafts:
  "15x Raptor Hide Harness +1g 27s"; compras: "90 Raptor Hide <= 2s 55c 2g 31s", com marca de feito); totais
  ("Spend 4g 10s, profit +1g 80s"); o botão grande `CompraForeverAcao` com o texto de `ns.proximaAcao()`.
- Seção WATCH (v0.2): cabeçalho `WATCH hh:mm` (hora da última busca que gravou) ou `WATCH (waiting)`; uma linha por
  item vigiado: `BUY <nome> <= <teto> | now <menor preço> (<unid>)` em verde quando o menor preço está no teto ou abaixo,
  cinza nos outros.
- Seção SELL (v0.2): pedidos da fila e sugestões, `<qtd> <nome> @ <preço>` com `(auto)` nas sugestões e ` [SELL]`; depois,
  `[x] posted <qtd> <nome>` para cada item de `S.postado` com quantidade maior que zero.
- Durante a busca da vigia, a barra mostra `Scanning feito/total` (o mesmo estado de Scan, `ns.scanEstado.ocupado`).
- Máximo de `MAX_LINHAS = 30` linhas de texto no painel; o que passar disso não aparece.
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

Cenários 12 a 16 (v0.2, `compra-12-watch-comandos.lua` a `compra-16-post-confirm-e-item.lua`):

| Cenário | Cobre |
|---|---|
| 12 | comandos da vigia por ID e por link, lista, alterar, `every 10` e `unwatch`; SV `CompraForeverDB.vigia` |
| 13 | busca sozinha com a AH aberta, histórico, painel WATCH, alerta ao cair, compra [WATCH] em dois cliques, SV |
| 14 | vigia com Scan: a busca da vigia atualiza `ns.scan.escadas` sem replanejar, o Scan registra no histórico, a vigia espera o Scan |
| 15 | sugestão [SELL] para item vigiado com piso, um PostCommodity por clique, `S.postado`, estoque cai |
| 16 | Confirm no clique seguinte, PostItem de item não empilhável, `auto` sem preço visto recusado, fila |

Os cenários 13, 14 e 15 têm `aceita_violacoes = true` só para a I9 da bancada: busca sem tecla do dono nos últimos 90 s
(regra herdada do PregaoForever). Nesses três, a conferência exige zero das outras violações. Os cenários 12 e 16 não
aceitam violação. Rodada de 2026-11-18: 17 cenários na bancada, 0 erros. Nada rodou no jogo.

## 10. Vigia e Venda: decisões e pendências (2026-11-18)

- Duração: `/compra duration` 1-3 vai direto para `PostCommodity`/`PostItem` (`duracao()` em `Venda.lua`). A
  correspondência 1, 2, 3 -> 2 h, 8 h, 24 h **não foi confirmada no jogo**.
- `OWNED_AUCTIONS_UPDATED` só conclui a postagem se a pilha saiu da bolsa ou encolheu (ver `talvezCriada` em
  `Venda.lua`). O evento também dispara por outros motivos, como a aba Leilões da Blizzard.
- A vigia zera escadas e avisos a cada abertura da AH (`AUCTION_HOUSE_SHOW`).
- O painel mostra "Scanning" por alguns segundos a cada ciclo da vigia (a busca usa o mesmo estado de Scan).
- Preço no `/compra post` vai sem espaço (`6s09c`).
- **Decisão aberta para o dono**: a busca periódica da vigia roda sem tecla do dono enquanto a AH está aberta (a bancada
  marca I9, regra herdada do PregaoForever). Falta decidir se o addon pausa a vigia depois de N minutos sem tecla do
  dono. Nada foi implementado para isso.

## 11. Full scan no disco (0.2.1, 2026-11-23)

Pedido do dono: "Gostaria que fosse fácil atualizar as estimativas de custos", e a escolha "CompraForever guarda o
Full". No fim do `lerFull` (antes do `encerrar`), `gravarFull` grava `CompraForeverDB.full = { em, n, itens }`, com
`itens[id] = "unidades;anuncios;preco:qtd,preco:qtd,..."`: as unidades e os anúncios de todo o livro do item (sem os do
dono, como a escada) e os 40 preços mais baratos (`NIVEIS`), com a quantidade somada dos anúncios de mesmo preço. Só
o último full fica; um full abortado (AH fechada) não troca o livro gravado. A ferramenta lê esse bloco
(`baixar-precos.mjs`, `lerFullCompra`) e usa o livro por 6 horas (`legado.mjs`, `comFullCompra`; seção 10.9 do
`ferramentas\pregao\CONTRATO.md`). Bancada: o cenário 03 confere o livro gravado e o aborto; rodada de 2026-11-23,
17 cenários, 0 erros. Nada rodou no jogo.

## 12. Modalidade de rota (0.3, 2026-11-23)

Pedido do dono: "Eu quero que essas compras sejam ultra simples igual foi no leatherworking também. Eu deveria poder
escolher a 'Modalidade' no compraforever". Escolhas dele (2026-11-23): fluxo inteiro como na de lucro (comprar,
craftar na ordem da rota, avisar o treinador, vender a sobra no vendedor); as seis profissões, marcos 150 e 225; a rota
da ferramenta (`ferramentas\pregao\legado.mjs`); encantamento sem item feito à mão, com o addon contando. Escolhas do
agente, ditas ao dono: compra por trechos até onde bolsa e dinheiro deixam; nunca acima de `teto x (100 + tolerancia)
/ 100` (tolerância 10%); sem folga de quantidade (margem 0%); a perícia dos intermediários conta (12.4); o correio
pendente sobrevive ao `/reload` nos dois modos (12.6); nenhum arquivo `.lua` novo (o TOC só muda a versão).

A modalidade de lucro não muda: com `ns.modo().tipo == "lucro"`, `ns.planejar`, `acaoLeilao`, `acaoCraft`,
`aVender`, `idsDirigido` e `montarLinhas` fazem o que as seções 1 a 11 dizem. As duas únicas mudanças visíveis nela são
a largura dos botões Scan e Full (12.7) e o correio gravado (12.6).

### 12.1 `CompraForeverDados.rotas` (gerado pelo `gerar-dados.mjs` a partir de `dados\pregao\rotas.json`)

```lua
rotas = {
  versao = 1, geradoEm = 1795470000,                    -- epoch da rodada do legado
  fonte = { tipo = "full", em = 1795467617, n = 6944 }, -- ou { tipo = "publica", em = <epoch da foto> }
  credito = true, treinoAte = nil,                      -- crafts com o credito dos intermediarios; --treino-ate
  itens = { [id] = { nome = "Linen Cloth", vende = 13, pilha = 20, vinculo = 0 } },  -- todo item citado por uma rota
  profs = {
    engineering = {
      nome = "Engineering", curto = "Eng", linha = 202,
      ranks = { { nome = "Journeyman Engineering", cap = 150, pericia = 50, custo = 500, nivel = 10 },
                { nome = "Expert Engineering", cap = 225, pericia = 125, custo = 5000, nivel = 20 } },
      receitas = {
        [3923] = { nome = "Rough Copper Bomb", produto = 4360, qtd = 2,
                   reagentes = { { 2840, 1 }, { 4359, 1 }, { 4357, 2 }, { 2589, 1 } },
                   amarela = 60, cinza = 90, pontos = 1, aprende = 30, origem = "treinador", treino = 130,
                   ferramentas = { { nome = "Blacksmith Hammer", itens = { 5956, 260811, 285280, 285281 } } },
                   foco = "Anvil" },
        -- produto = nil e encantar = true no encantamento sem item; acampamento = { nome, itens = { id } };
        -- padrao = <itemID> quando origem e "leilao" ou "vendedor"
      },
      trechos = {
        { de = 1, ate = 150, chegou = 150,
          passos = { { magia = 3919, de = 1, ate = 59, crafts = 119 }, { magia = 3923, de = 59, ate = 65, crafts = 7 } },
          fontes = { [4357] = { f = "L", qtd = 133, custo = 1809, teto = 14 },
                     [4377] = { f = "F", magia = 3945, qtd = 48, teto = 41 },  -- teto so se o item tem preco de leilao
                     [5956] = { f = "V", qtd = 1, preco = 18 } },
          totais = { custo = 105916, crafts = 279, craftsExtra = 144 } },
        { de = 150, ate = 225, chegou = 225, passos = { ... }, fontes = { ... }, totais = { ... } },
      },
    },
  },
}
```

- `receitas` tem as receitas dos passos, as que fabricam intermediário (letra F, em qualquer nível) e as que fabricam
  ferramenta ou objeto. As tabelas da rota não se misturam com `receitas`, `itens` e `fabrica` da modalidade de lucro.
- `fontes` é a decisão do `balanco` do trecho, item a item: `L` (leilão: quantidade, custo pelo livro e `teto`, o preço
  da última unidade no livro de ofertas, em cobre por unidade), `V` (vendedor: quantidade e preço cheio por unidade) ou
  `F` (fabricar pela `magia`; `teto` presente se o item também tem preço de leilão, para a troca por compra em 12.4).
  Ferramenta, objeto de acampamento e padrão também entram em `fontes`.
- `ranks.nivel`: o Naowh traz `null`; o gerador põe 10, 20 e 35 pelos tetos 150, 225 e 300
  (`comum\referencia\profissoes-forever.md:28`). O Apprentice (teto 75) não aparece em `ranks`.
- `crafts` dos passos já vem com o crédito dos intermediários quando `credito = true` (12.4). Em jogo, o planejador
  refaz os crafts a partir da perícia real com a mesma fórmula; `testar-rota.mjs` (R20) confere que o Lua dá o mesmo
  número que o JS em todo passo das 12 rotas.

### 12.2 Gravação

`CompraForeverDB.config` ganha `tolerancia = 10` (0 a 100, %) e `margem = 0` (0 a 50, %). `CompraForeverCharDB` passa a
ter `versao = 2`:

```lua
CompraForeverCharDB = {
  versao = 2,
  modo = { tipo = "lucro" },                                   -- ou { tipo = "rota", prof = "engineering", alvo = 150 }
  prof = { engineering = { pericia = 47, max = 75, em = 1795468000, ids = { [3919] = true }, n = 1, idsEm = 1795468000 } },
  rota = { engineering = { credito = { [4358] = 60 }, vendido = { [4358] = 40 }, craftado = { [3919] = 30 }, gasto = 1809, inicio = 1795468000 } },
  correio = { [4357] = 119 }, correioVisto = { [4357] = 0 }, correioEm = { [4357] = 1795468000 },
  conhecidas = { ... }, plano = { ... },                       -- os de hoje (secao 3)
}
```

Migração no `iniciarSV` quando `versao` é nil: `modo = { tipo = "lucro" }`, tabelas vazias, e a `conhecidas` de hoje
copiada para `prof.leatherworking` (`pericia`, `ids`, `n`, `em`, `idsEm = em`). A `conhecidas` continua sendo escrita
como hoje pela janela de Leatherworking (cenários 01 e outros leem). `rota[slug].credito[id]` é quanto o addon craftou
do item na rota e ainda não vendeu: só isso pode ser vendido (12.5).

### 12.3 Profissões e modo (`Nucleo.lua`)

- `ns.PROFS` (lista, nesta ordem): `{ slug = "alchemy", nome = "Alchemy", curto = "Alch", linha = 171 }`,
  `blacksmithing`/`Blacksmithing`/`BS`/164, `enchanting`/`Enchanting`/`Ench`/333, `engineering`/`Engineering`/`Eng`/202,
  `leatherworking`/`Leatherworking`/`LW`/165, `tailoring`/`Tailoring`/`Tail`/197.
- `ns.slugDe(info)`: o slug cujo `nome` é `info.professionName` ou `info.parentProfessionName`, ou cuja `linha` é
  `info.professionID` ou `info.parentProfessionID`; senão nil. `ns.slugDaJanela()`: o slug da janela de profissão do
  próprio personagem, pronta (`IsTradeSkillReady`, não linked/guild/npc), lido de `GetChildProfessionInfo` e depois
  `GetBaseProfessionInfo`; senão nil.
- `gravarConhecidas` vale para as seis: grava `prof[slug] = { pericia = skillLevel, max = maxSkillLevel, em, ids, n,
  idsEm }` da janela aberta (a mesma escolha de hoje entre a info do filho e a da base). Em Leatherworking também grava
  `conhecidas` como hoje. Roda nos eventos de hoje e também em `NEW_RECIPE_LEARNED`, `LEARNED_SPELL_IN_SKILL_LINE` e
  `SKILL_LINES_CHANGED` (0,5 s depois, um só agendamento).
- Perícia sem a janela (reserva, tudo em `pcall` e com a existência conferida por `rawget`/`type`): em
  `CHAT_MSG_SKILL`, o texto enUS `Your skill in (.+) has increased to (%d+)` atualiza `prof[slug].pericia` (só para cima)
  e `em`; em `SKILL_LINES_CHANGED` e no `PLAYER_ENTERING_WORLD`, `C_TradeSkillUI.GetProfessionInfoBySkillLineID(linha)`
  e depois `GetProfessions` + `GetProfessionInfo(i)` (nome igual ao da profissão) atualizam `pericia` e `max` quando
  devolvem número e o nome ou a linha conferem. A janela aberta sempre vence. Depois de qualquer mudança de perícia:
  `ns.replanejar()`.
- `ns.modo()` devolve `CompraForeverCharDB.modo` ou `{ tipo = "lucro" }`. `ns.definirModo(m)` grava, chama
  `ns.replanejar()` e `ns.atualizarPainel()`. `ns.profDoModo()`: `modo.prof` na rota, `"leatherworking"` no lucro.
- `ns.modosDisponiveis()`: `{ tipo = "lucro" }` e, para cada profissão de `ns.PROFS` com `CompraForeverDados.rotas.profs[slug]`
  e com `prof[slug]` gravado, `{ tipo = "rota", prof = slug, alvo = 150 }` e o mesmo com 225. Sem nenhum `prof` gravado,
  entram as seis. `ns.rotuloModo(m)`: `"Profit"`, ou `curto .. " " .. alvo` (`"Eng 150"`).
- `ns.replanejar()` no modo de rota chama `ns.planejarRota(ns.entradaRota())` mesmo sem `ns.scan` (craft e venda
  funcionam logo depois de um `/reload`; sem scan, as linhas de leilão viram "Scan at the AH"); guarda em `ns.plano` e
  não grava `CompraForeverCharDB.plano`. No lucro, o de hoje.
- `ns.entradaRota()`: `{ rota = rotas.profs[slug], itens = rotas.itens, alvo, pericia = prof[slug] and prof[slug].pericia,
  max = prof[slug] and prof[slug].max, nivel = UnitLevel("player"), conhecidas = prof[slug] and prof[slug].ids,
  bolsa = { [id] = ns.estoqueBolsa(id) }, correio = { [id] = n }` (todos os ids citados pela rota da profissão)
  `, dinheiro = ns.dinheiro(), espacos = ns.espacosLivres(), desconto = cfg.desconto, tolerancia = cfg.tolerancia,
  margem = cfg.margem, escadas = ns.scan and ns.scan.escadas or {}, credito = rotas.credito ~= false,
  credVenda = CompraForeverCharDB.rota[slug].credito, fonte = rotas.fonte, ultimoFull = CompraForeverDB.ultimoFull,
  agora = time() }`. `ns.estoqueBolsa` é exportado pelo `Compra.lua` (a contagem só das bolsas).
- Comandos (`/compra`): `mode` (imprime o modo e os disponíveis); `mode profit`; `mode <prof> [150|225]` com `<prof>`
  sendo slug, nome ou curto, sem diferenciar maiúsculas (`eng`, `engineering`, `bs`...), alvo padrão 150; respostas
  `target must be 150 or 225`, `no route for <Prof>: ask for an estimate`, `<Prof> not seen on this character: open it
  once` (aceita o modo assim mesmo); `tolerance [0-100]`; `margin [0-50]`; `steps` (imprime os passos da rota do modo
  com `done`, `now` e `next`); `sonda prof` (12.8). A linha de uso inclui os novos.

### 12.4 `Planejador.lua`: `ns.planejarRota(e) -> plano` (puro, sem API do WoW)

Funções exportadas (para os testes e para o `Compra.lua`): `ns.rotaChance(r, s)`, `ns.rotaGanho(rota, trecho, magia,
s, credito)`, `ns.rotaFaltam(rota, trecho, passo, s, credito)`.

- Chance, igual ao `rota.mjs:22-27`: `pontos <= 0` dá 0; `s < amarela` dá 1; `s >= cinza` dá 0; senão
  `(cinza - s) / (cinza - amarela)`.
- Crédito dos intermediários: um "pacote" é 1 craft da receita do passo mais os crafts de intermediário que ele pede.
  Para cada reagente cuja fonte no trecho é `F` (até 3 níveis, sem ciclo), `k = qtd do reagente / qtd que a receita F
  faz`, multiplicado pelos níveis de cima. `ganho(m, x) = chance(m, x) * pontos(m) + (credito and soma de k * chance(f, x)
  * pontos(f) or 0)`.
- Crafts que faltam num passo a partir da perícia `s`: `t = soma, para x de max(s, de) a ate - 1, de 1 / ganho(x)`; se
  algum `ganho(x) <= 0`, o passo está quebrado (nil); senão `ceil(t - 1e-9)`; 0 quando `s >= ate`. Com `credito = false`,
  Rough Dynamite (3919) dá 119 do 1 ao 59 e 78 do 40 (o mesmo que o `rota.mjs`).

Algoritmo:
1. Portões, nesta ordem, com `plano.rota.estado`: sem `e.rota` → `"semDados"`; `e.pericia == nil` → `"semPericia"`
   (nada a comprar, NEXT "Open <Prof> once"); `e.pericia == 0` → `"naoAprendida"` ("Learn <Prof> at a trainer");
   `e.pericia >= e.alvo` → `"feito"` (só a venda).
2. Passos: os `passos` dos trechos em ordem, os que começam abaixo do alvo, com `ate` cortado no alvo. Buraco entre
   passos contendo a perícia → `"lacuna"` ("Route gap at <n>: new estimate").
3. Tetos: `capNivel` = o maior `cap` de rank com `nivel <= e.nivel` (75 se nenhum; `e.nivel` nil conta como 60);
   `limite = min(alvo, capNivel)`; o rank seguinte vira `rota.rank = { nome, custo, pericia, nivel, cap, bloqueado }`
   quando a perícia já chegou ao `pericia` dele e o `max` (ou, sem `max`, o menor cap acima da perícia) é menor que o
   alvo; `bloqueado` quando o `nivel` do rank passa de `e.nivel`.
4. Crafts que faltam `n[i]` de cada passo até o `limite`; `atual` = o primeiro com `n > 0`.
5. Caminhada inteira (sem limite de dinheiro, bolsa nem preço), do passo atual ao último abaixo do limite, com estoque
   `bolsa + correio`: dá `reservar[id]` (quanto do estoque de hoje os passos que faltam consomem), `restante` (custo
   para terminar, pela escada ou por `teto x qtd`) e `scan` (ids de leilão para o Scan dirigido: fontes L, F que caem em
   compra, padrões e ferramentas de leilão; lista ordenada).
6. Trecho de compra, passo a passo, com estado `S` (estoque virtual = bolsa + correio + produtos dos passos já
   simulados; ponteiro em cada escada; gasto; compras; fabricados; ferramentas na mão; objeto montado):
   - quantidade do passo para comprar: `ceil(n[i] * (100 + margem) / 100)`;
   - ferramenta: se nenhum dos `itens` da ferramenta está na bolsa nem comprado, obter 1 do primeiro item que tem fonte;
   - objeto de acampamento: se o passo pede um e o objeto montado é outro, obter 1 (o de menor custo com fonte);
   - padrão: receita não conhecida, `origem` `leilao` ou `vendedor`, padrão fora da bolsa e não comprado: obter 1;
   - reagentes: `obter(id, qtd * n)`: primeiro o estoque virtual; fonte `F` com `podeFabricar` abre nos reagentes da
     receita (até 3 níveis; a sobra volta ao estoque); `F` que não pode fabricar compra no leilão se tem `teto`, senão
     bloqueia ("Learn <receita>"); `L` anda na escada só nos degraus com `preco <= floor(teto * (100 + tolerancia) / 100)`
     (commodity em parte; degrau inteiro todo, a sobra ao estoque); `V` sem limite a `floor(preco * (100 - desconto) /
     100)`; sem escada: falta `"semPreco"`; escada esgotada no limite: falta `"preco"`;
   - `podeFabricar(m)`: conhecida, ou `origem == "inicial"`, ou `origem == "treinador"` e `aprende <= max(pericia, de do
     passo)`;
   - produto: entra no estoque virtual;
   - o passo cabe se `gasto <= dinheiro`, sem falta, e o pico de bolsa `<= espacos - 2`. Pico: espaços a mais que as
     compras e o correio pedem quando chegam (`ceil((bolsa + delta) / pilha) - ceil(bolsa / pilha)` por item), e depois,
     passo a passo, o consumo e a produção, valendo o maior valor.
   - se o passo não cabe inteiro, busca binária do maior `k < n` que cabe; fica com `k` se `k > 0`; para aí, com
     `motivo` = `"dinheiro"`, `"espaco"`, `"preco"`, `"semPreco"` ou `"bloqueio"`. Chegando ao fim: `"fim"` (ao alvo) ou
     `"limite"` (parou no teto do nível).
7. Venda: para cada item que é produto de alguma receita da rota e não é ferramenta, objeto nem padrão:
   `vender[id] = max(0, min(credVenda[id] or 0, bolsa[id] - reservar[id]))`.

Saída: o formato da seção 4, com `modo = 2`; `leilao` com `passo` e `teto` (o limite por unidade, já com a tolerância)
em cada linha, em ordem de passo e depois de custo; `vendedor` com `tipo` (`"mat"`, `"ferramenta"`, `"padrao"`,
`"objeto"`); `fabricar = {}`; `crafts` = os passos do trecho `{ magia, nome, n, de, ate, custo = 0, venda = 0, lucro = 0 }`;
`revenda = {}`, `sobra = {}`, `doEstoque = {}`; `totais = { gasto, venda = 0, lucro = 0, espacos = pico }`; e

```lua
plano.rota = {
  prof, nome, curto, pericia, max, alvo, limite, estado,   -- "ok"|"semDados"|"semPericia"|"naoAprendida"|"feito"|"lacuna"
  atual = { i, magia, nome, de, ate, faltam, encantar },   -- nil sem passo atual
  passos = { { de, ate, magia, nome, n, estado } },        -- "feito"|"agora"|"compra"|"depois"
  chega = 91,                                              -- ate onde a compra do trecho leva a pericia
  curtos = { { id, nome, falta, cap, tipo } },             -- tipo "preco"|"semPreco"|"bloqueio"
  treinar = { { magia, nome, custo, aprende } },           -- receitas da rota (passos e F) nao conhecidas, por aprende
  rank = { nome, custo, pericia, nivel, cap, bloqueado },  -- ou nil
  dicas = { "ANVIL" },                                     -- foco do passo atual, objeto a montar, padrao na bolsa
  reservar = { [id] = n }, vender = { [id] = n }, restante = cobre, scan = { ids },
  proximo = "ah",                                          -- "open"|"trainer"|"mail"|"ah"|"vendor"|"craft"|"done"|"none"
  fonte = e.fonte, velho = bool,                           -- velho: Full mais novo que a fonte, ou fonte com mais de 6 h
}
```

`proximo`, nesta ordem: `feito` → `"done"`; `semPericia` → `"open"`; rank no teto ou receita atual não conhecida →
`"trainer"`; correio com item que o passo atual pede → `"mail"`; linhas de leilão → `"ah"`; linhas de vendedor ou
`vender` → `"vendor"`; dá para craftar com a bolsa → `"craft"`; senão `"ah"`.

Decisões da implementação (2026-11-23, onde o texto acima calava): `plano.rota.prof` vem de `e.prof` (o
`ns.entradaRota` manda o slug); passo com ganho `<= 0` ou passos que acabam antes do alvo dão `estado = "lacuna"`, com
`rota.lacuna` = a perícia que falta, e `proximo = "none"`; nos portões, `motivo` repete o estado (e `feito` usa `"fim"`),
só `feito` calcula `vender`, e `proximo` é `"none"` em `semDados`, `"open"` em `semPericia` e `"trainer"` em
`naoAprendida`; sem passo atual, `proximo = "none"`; receita atual não conhecida só manda ao treinador quando a origem
não é `leilao` nem `vendedor` (aí o caminho é o padrão); reagente sem fonte no trecho vira falta `"semPreco"`; com margem,
a compra é para `ceil(k * (100 + margem) / 100)` crafts e a sobra volta ao estoque virtual; uma linha de leilão e uma de
vendedor por item, com o `passo` do primeiro uso; dicas `"ANVIL"` (o foco em maiúsculas), `"PLACE <objeto>"` e
`"LEARN <padrao>"`; `curtos` da primeira tentativa que falhou (com `magia` no tipo `"bloqueio"`); `reservar` gasta o
estoque físico antes do produzido e a bolsa antes do correio; `velho` quando `ultimoFull` é mais novo que `fonte.em` ou
a fonte tem mais de 6 horas.

### 12.5 `Compra.lua` no modo de rota (`ns.plano.modo == 2`)

- `ns.contexto()` = `{ ah, vend, prof, profSlug, mail, trainer }`; `prof` é verdade quando `ns.slugDaJanela()` é o
  `ns.profDoModo()` (no lucro, só Leatherworking, como hoje). `MAIL_SHOW`/`MAIL_CLOSED` e `TRAINER_SHOW`/`TRAINER_CLOSED`
  marcam `mail` e `trainer`. Exporta `ns.estoqueBolsa`.
- Leilão: as linhas do plano na ordem de `passo` (no lucro, a de hoje); o limite da cotação de linha de rota é
  `min(qtd * teto, floor(custo * 1.05) + 1)`; acima dele, o caminho de hoje (cancela, rebusca o item, replaneja).
  Compra de leilão soma em `CompraForeverCharDB.rota[slug].gasto`.
- Vendedor: primeiro vende (`plano.rota.vender`, pilhas inteiras, `MerchantFrame` na tela, `UseContainerItem`; o
  crédito da venda tira de `rota[slug].credito` e soma em `vendido`), depois compra as linhas de vendedor
  (`comprarVendedor` de hoje; texto `Buy at vendor (<custo>)`). No lucro, os textos e a ordem de hoje.
- Craft (janela da profissão do modo aberta), primeira regra que vale: `feito` → `Done: <Prof> <alvo>`; rank no teto →
  `Train <rank> (<custo>)` ou `<rank> needs level <n>`; receita do passo não conhecida → `Train <receita> (<custo>)`,
  ou `Learn <padrao>` com o padrão na bolsa, ou `Buy pattern <nome>`; requisito não cumprido em
  `C_TradeSkillUI.GetRecipeRequirements(magia)` (em `pcall`; o primeiro com `met == false`) → `Need <nome> nearby`;
  passo com `encantar` → `Enchant manually (<n> left)`, sem `CraftRecipe` nem `CraftEnchant`; senão o lote:
  `B = min(faltam, 20, o que a bolsa permite contando os intermediários)`; primeiro os intermediários desse lote, do
  nível mais fundo (`Make <n> <nome>`), depois o principal (`Craft <n> <nome>`). Sem reagente: `Take mail first (<n>
  items)` com correio pendente, senão `Buy mats at the AH`. Todos esses, menos Make e Craft, ficam desligados.
- Progresso do craft na rota: pela queda do primeiro reagente que a receita não produz (`sinal = -1`, `por` = qtd por
  craft), o que serve para produto que não empilha e para encantamento; o crédito soma em `rota[slug].craftado[magia]`
  e, se há produto, em `rota[slug].credito[produto]`. Prazo `10 + 6 * n`. A pendência também termina em
  `UNIT_SPELLCAST_INTERRUPTED` do `"player"` e em `UPDATE_TRADESKILL_CAST_STOPPED`. Se a perícia chega ao `ate` do passo
  durante o lote do principal, `pcall(C_TradeSkillUI.StopRecipeRepeat)` (é parar, não é ação) e a pendência termina.
- O que nunca: `BuyTrainerService`, `TakeInboxItem`, `AutoLootMailItem`, `CraftEnchant`, `CraftRecipe` de
  encantamento sem item, `UseContainerItem` sem o vendedor na tela, segunda ação de leilão no mesmo clique.

### 12.6 Correio gravado (os dois modos)

`S.correio` e o `visto` da seção 6 passam a ser `CompraForeverCharDB.correio` e `correioVisto` (as mesmas tabelas,
ligadas no `ADDON_LOADED` depois do `iniciarSV`), mais `correioEm[id]` (hora da compra). Reconciliação: uma vez no
`PLAYER_ENTERING_WORLD` contra o `correioVisto` gravado (pega o correio tirado antes do `/reload`); quando a bolsa sobe
(a de hoje); ao abrir a caixa (`MAIL_SHOW`, `MAIL_INBOX_UPDATE`), só quando `GetInboxNumItems()` mostra todas as
cartas: conta os anexos por item (`GetInboxItem(i, j)`, segundo retorno, em `pcall`) e baixa `correio[id]` para esse
número nas entradas com mais de 60 segundos (só para baixo; a compra no leilão chega na hora, e os 60 s só protegem a
carta a caminho); entradas com mais de 30 dias saem.

### 12.7 Painel no modo de rota

- `botao(nome, rotulo, x, larg, altura, y)` (y padrão -40). Fileira de cima: `CompraForeverScan` x=8 largura 90,
  `CompraForeverFull` x=102 largura 96 (o texto de hoje, `Full scan` ou `Full scan mm:ss`, que o cenário 09 confere e
  cabe nos 96), `CompraForeverModo` x=202 largura 90 (o rótulo de
  `ns.rotuloModo`; clique esquerdo vai para o próximo de `ns.modosDisponiveis()`, o direito para o anterior;
  desligado com `ns.compraOcupada()`).
- Linha do scan (y=24): a de hoje e, no modo de rota, ` | route dd/mm hh:mm full|public`, com ` old` quando `velho`.
- Linhas (máximo 30): `NEXT: AH` / `NEXT: mailbox (<n> items)` / `NEXT: vendor` / `NEXT: trainer` / `NEXT: <Prof>
  window` / `NEXT: open <Prof> once` / `DONE: <Prof> <alvo>`; `<Prof> <pericia>/<max> -> <alvo>` (com `(<limite> until
  lvl <n>)` se o nível corta); `Now <receita> <de>-<ate>: <faltam> left`; `BUY to <chega> (<motivo>)`; até 4 dicas
  (`TRAIN <nome> <custo>`, `TRAIN <rank> <custo> (lvl <n>)`, `ANVIL needed`, `PLACE <objeto>`, `LEARN <padrao>: right-click
  it`, `SHORT <n> <nome> > <cap>: new estimate` em vermelho, `Newer Full: say atualiza`); até 12 linhas de compra
  (`<qtd> <nome> <= <teto>  <custo>`; `<qtd> <nome> (vendor) <custo>`; depois `+<n> more`); até 3 de craft
  (`[CRAFT] <n>x <nome> <de>-<ate>`); `Sell <n> leftovers (+<valor>)`; `Spend <gasto> | left ~<restante>`; a linha de
  correio de hoje. WATCH e SELL continuam acima quando têm itens.
- O painel também aparece, só com as dicas, na caixa de correio (`MailFrame`) e no treinador (`ClassTrainerFrame`),
  no modo de rota. Sem ação possível onde o dono está, o botão de ação mostra o NEXT, desligado.
- Âncora (correção de 2026-11-23, noite): o painel só se prende a uma janela que está na tela (`IsShown`), reavalia no
  `OnHide` dessa janela (gancho por `HookScript`, um por janela) e de novo 0,1 s depois de cada evento de abrir e fechar.
  Antes, a janela do treinador fechava, o estado de "aberta" ficava, e o painel ficava solto onde ela estava.
- Scan sem nada para buscar (`"nothing"`): na rota, `Nothing to buy for the route` (tudo o que a rota pede está na bolsa
  ou no correio); no lucro, `No known recipes: open Leatherworking`, como antes.
- Ordem das dicas (ajuste de 2026-11-23, porque o treino de uma rota nova ocupava as 4 vagas e escondia o resto):
  `Scan at the AH` (sem preço), `SHORT <n> <nome> > <teto em moeda>: new estimate`, `BLOCKED <nome>: learn its recipe
  first`, o rank, as dicas do passo, `Newer Full: say atualiza`; depois o `TRAIN` das receitas que o trecho de compra
  pede (aprende até o `chega`), e o resto como `TRAIN +<n> more (see them at the trainer)`. No treinador e no correio
  vão todas, com o treino inteiro.
- Rota-mode também replaneja ao entrar no mundo (depois de um `/reload`) e meio segundo depois de a bolsa mudar, sem
  ação em andamento; no fim de cada lote, a perícia gravada sobe para a da janela, mesmo sem evento de perícia.

### 12.8 `/compra sonda prof`

Imprime (prefixo `CompraForever probe:`) e grava em `CompraForeverDB.sonda = { em, linhas = { ... } }` (vai ao disco no
`/reload`): `UnitLevel("player")`; `GetProfessions()` e, para cada índice, `GetProfessionInfo(i)` (nome, perícia, máximo,
linha); `C_TradeSkillUI.GetProfessionInfoBySkillLineID(linha)` das seis (os campos que vêm); `C_SkillInfo` (quantas
linhas e a info da linha de cada profissão, se as funções existem); com a janela aberta, `GetBaseProfessionInfo` e
`GetChildProfessionInfo` (id, nome, perícia, máximo, pai), quantas receitas e quantas aprendidas, e para a primeira
aprendida `GetRecipeInfo` (`learned`, `relativeDifficulty`, `numSkillUps`), `GetCraftableCount` e
`GetRecipeRequirements`; e se existem `CraftEnchant`, `StopRecipeRepeat`, `GetRemainingRecasts`,
`IsNearProfessionSpellFocus` e `GetRecipeRequirements`. Tudo em `pcall`, com a existência conferida antes; nada
chama ação. Os resultados vão para `comum\referencia\` com a marca [local].

### 12.9 Bancada e testes da rota

- Falso novo `ferramentas\guia\pregao\bancada\rota.lua`, carregado depois de `compra.lua` e antes de `executor.lua`
  (`bancada-pregao.mjs` carrega todos os falsos em ordem, com o `executor.lua` por último). Todo campo novo é opcional e
  o padrão reproduz o comportamento de hoje (os 17 cenários `compra` continuam iguais). Cobre: profissão por cenário
  (`inicio.profissoes = { { id, nome, nivel, max } }`, `abrir_profissao = { nome = ... }`, id e máximo de verdade em
  `GetBaseProfessionInfo`/`GetChildProfessionInfo`); receitas com `amarela`, `cinza`, `pontos`, `prof`, `foco`,
  `ferramentas` e `encantar` (produto nil); subida de perícia no craft pela fórmula da 12.4, por `inicio.pericia_modo`
  (`"nunca"` padrão, `"sempre"`, `"roteiro"` com lista, `"aleatorio"` com semente própria), sem passar do máximo, com
  `CHAT_MSG_SKILL`, `SKILL_LINES_CHANGED` e `TRADE_SKILL_LIST_UPDATE` depois de subir (desligáveis); `UnitLevel`;
  `GetProfessions`/`GetProfessionInfo`/`GetProfessionInfoBySkillLineID` (com `inicio.apis_prof = "nil"` para o caso de
  não responderem); `GetRecipeRequirements` pelo `foco` e `inicio.perto`; `StopRecipeRepeat`; `UNIT_SPELLCAST_*` e
  `UPDATE_TRADESKILL_CAST_STOPPED`; `A.P.craft_lote = "um"` (o servidor faz um só); falta de ferramenta e de bigorna
  com `UI_ERROR_MESSAGE`; treinador só de leitura (`abrir_treinador`, `treinar = { magia }`, `treinar_rank = cap`;
  `BuyTrainerService` sempre viola `"treino"`); caixa de correio (`abrir_correio`, `pegar_correio`, `GetInboxNumItems`,
  `GetInboxItem`; `TakeInboxItem`/`AutoLootMailItem` violam `"correio"`); `CraftEnchant` e `CraftRecipe` de encantamento
  violam `"encanto"`; bolsa curta pelo `A.P.tamanho_bolsa` de hoje; `reload_real` (fecha as janelas antes do reload);
  `inicio.dados` mesclado no `CompraForeverDados` depois de carregar e de cada reload; e `__bancada.fixture("eng150")`,
  um `inicio` completo da Engineering do 1 ao 150 com tetos fixos.
- Cenários em `ferramentas\guia\casos-pregao\cenarios\rota\` (`--cenarios rota`), cada um conferindo zero violação,
  zero erro de Lua, nenhum `BuyTrainerService` e no máximo uma ação de leilão por clique:

| Cenário | Cobre |
|---|---|
| rota-00 | `/compra sonda prof` com a janela fechada e aberta, sem erro com as APIs ausentes, grava as linhas |
| rota-00b | os falsos novos da bancada, direto pelas APIs falsas, e o fixture `eng150` |
| rota-01 | botão de modo e gravação depois do `reload_real`; o clique não faz busca nem ação de leilão |
| rota-02 | `/compra mode` (profit, eng 150, alvo inválido, profissão não vista, sem argumento) |
| rota-03 | plano do 1 com bolsa e dinheiro de sobra: as 12 linhas de leilão na ordem do primeiro uso, o martelo no vendedor |
| rota-04 | bolsa curta: só o começo da rota, `motivo = "espaco"` |
| rota-05 | dinheiro curto: prefixo da rota, gasto dentro do dinheiro, `motivo = "dinheiro"` |
| rota-06 | teto em lotes inteiros: compra até o limite, para no degrau acima, linha SHORT |
| rota-07 | cotação acima do limite da rota (que a fórmula do lucro aceitaria): cancela |
| rota-08 | commodity em dois cliques no modo de rota, correio gravado, linha sai do plano |
| rota-09 | martelo no vendedor uma vez só; já na bolsa, não compra |
| rota-10 | intermediário antes do principal (Heavy Blasting Powder antes do Heavy Dynamite), só o que o lote pede |
| rota-11 | perícia cruza o fim do passo no meio do lote: para e passa ao seguinte, com e sem os eventos de perícia |
| rota-12 | receita não conhecida: dica de treino, nenhum craft; depois de treinar, craft |
| rota-13 | teto do rank: dica do Journeyman, nível exigido, Expert pedindo nível 20 |
| rota-14 | perícia 40: 78 crafts no primeiro passo e as quantidades certas |
| rota-15 | alvo atingido: DONE, sem compra, só venda |
| rota-16 | venda guarda o que os passos seguintes pedem, ferramenta, matéria-prima e o que o addon não craftou |
| rota-17 | `reload_real` no meio: o correio não é recomprado e os contadores de venda sobrevivem |
| rota-18 | modalidade de lucro igual à de hoje (os números do cenário compra-04), também depois de ir à rota e voltar |
| rota-19 | Enchanting: passo de encantamento mostra "Enchant manually", nenhum CraftRecipe dele; varinha crafta normal |
| rota-20 | bolsa enche no meio do craft: botão volta com a mensagem, sem tentar de novo sozinho |
| rota-21 | bigorna: "Need Anvil nearby" longe; perto, crafta |
| rota-22 | servidor faz um craft só por pedido: o progresso e o botão continuam certos |
| rota-23 | limite de quantidade da commodity (falso): mensagem, nunca dois Start no mesmo clique |
| rota-24 | fonte da rota velha ou pública: aviso no painel |
| rota-25 | `Dados.lua` real, Engineering 150: as linhas batem com os dados, tetos positivos, sem erro |
| rota-26 | nenhuma busca no leilão sem tecla do dono (troca de modo, reload, 120 s de BAG_UPDATE) |
| rota-27 | painel some quando a janela de âncora some sem o evento de fechar; Scan sem nada para buscar: texto da rota na rota, do lucro no lucro |

- `node ferramentas\compra\testar-rota.mjs` (fengari, o `Planejador.lua` de verdade, como o `testar-planejador.mjs`):
  R1-R5 fórmula (119 do 1; 78 do 40; 0 e 7 do 59; 4 do 62; Copper Tube 10 e Practice Lock 5 exatos), R6 plano da
  Engineering 1-150 do 1, R7 prefixo por bolsa, R8 por dinheiro, R9 limite do teto (dentro e fora), R10 correio conta,
  R11 receita não conhecida, R12 rank e nível, R13 venda e reserva, R14 crédito do intermediário, R15 alvo atingido, R16
  encantamento, R17 ferramenta fabricada, R18 determinismo, R19 desempenho (Blacksmithing 1-225 abaixo de 1000 ms, e
  119 replanejamentos seguidos abaixo de 1000 ms), R20 o Lua igual ao JS em todo passo das 12 rotas do `Dados.lua`.

Rodada de 2026-11-23 (noite), com o `Dados.lua` gerado pelo `estimativas.mjs` das 19h31 (Full das 18h00): bancada
`--cenarios rota` 28 cenários e `--cenarios compra` 17, 0 erros; `testar-rota.mjs` 20 casos (R20: 74 passos, 0
divergências entre o Lua e o JS); `testar-planejador.mjs` 12; `checar-dados.mjs --exigir-full` ok; `checar-combate`
só com o R9 já conhecido do `UseContainerItem`. Nada da modalidade de rota rodou no jogo ainda.
