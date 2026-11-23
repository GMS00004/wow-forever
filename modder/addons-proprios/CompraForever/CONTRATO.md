# CompraForever: contrato (v0.2, 2026-11-18)

Addon de um fluxo só: na AH, o dono clica Scan e um painel colado na AH mostra, com o dinheiro e o espaço de bolsa de
agora, quanto comprar de cada material para craftar receitas conhecidas de Leatherworking e vender o produto no
vendedor com lucro. Um botão de ação faz uma coisa por clique: comprar, craftar, vender, postar no leilão. Desde a v0.2
há a vigia de preços (WATCH) e a postagem no leilão (SELL), seção 10. Substitui o PregaoForever.

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
| `CompraForever.toc` | Interface lida do cliente (16001 hoje), `## Version: 0.2.0`, `## SavedVariables: CompraForeverDB`, `## SavedVariablesPerCharacter: CompraForeverCharDB`, `## OptionalDeps: GuiaForever`, ordem: Dados, Nucleo, Planejador, Scanner, Vigia, Compra, Venda, Painel |
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
