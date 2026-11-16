# PregaoForever 0.1.0: arquitetura (contrato congelado da onda 1)

Data: 2026-11-16. Este arquivo é o contrato que as tarefas das ondas 1 e 2 implementam. Ele não substitui o `DESIGN.md`: aponta para as seções dele, fixa o que o design deixou aberto entre módulos (nomes, assinaturas, quem registra cada evento, formato dos cenários da bancada) e fica congelado durante cada onda. Mudança aqui só na sessão principal, entre ondas, com uma linha em "Mudanças do contrato" no fim.

Decisões do dono gravadas em 2026-11-16 (ver `estado/estado.md`): DD1a sim, DD1b sim em dois tempos, DD3 itens 1 e 3 nos padrões (venda dos verdes ligada como fonte aprovada; regra `igualar` em equipamento e commodity), DD4 negociador `Hexumlite` com o ouro reunido e piso pessoal zero, DD9 e DD14 nos padrões, e confirmado que nenhum código de addon de terceiro é lido. Nas ondas 1 e 2 o `modo` é `leitura`: nenhuma função de ação existe no código.

## 1. Regras que valem para todo arquivo

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

## 2. Pastas, comandos e nomes

| O quê | Onde |
|---|---|
| Addon | `wow/modder/addons-proprios/PregaoForever/` (todos os `.lua` na raiz) |
| Scripts | `wow/modder/ferramentas/guia/pregao/` (rodam a partir de `wow/modder/ferramentas/guia/`) |
| Falso da bancada (Lua) | `wow/modder/ferramentas/guia/pregao/bancada/` |
| Casos do checador | `wow/modder/ferramentas/guia/casos-pregao/regras/` |
| Cenários da bancada | `wow/modder/ferramentas/guia/casos-pregao/cenarios/<grupo>/<id>.lua` |
| Dados gerados e saídas (fora do git) | `wow/modder/dados/pregao/` (`cache/` já tem o `ItemSparse-1.60.1.70938.csv`; `bancada/`, `arquivo/` e `json/` nascem quando preciso) |
| Relatórios de sessão | `wow/modder/addons-proprios/PregaoForever/relatorios/` |

Não confundir com `wow/modder/ferramentas/pregao/`, que é de outra frente (lista de crafts): nada do addon vai para lá.

Comandos de pronto (de `wow/modder/ferramentas/guia/`):

```
node checar-lua.mjs ../../addons-proprios/PregaoForever
node checar-combate.mjs ../../addons-proprios/PregaoForever --toc --prefixos PregaoForever,SLASH_PREGAOFOREVER,BINDING_
node pregao/checar-pregao.mjs ../../addons-proprios/PregaoForever
node pregao/rodar-casos-pregao.mjs
node pregao/checar-dados-pregao.mjs
node pregao/bancada-pregao.mjs --auto-teste
node pregao/bancada-pregao.mjs --cenarios <grupo>
node pregao/ler-pregao.mjs --ida-e-volta
```

Todo script de pronto termina com uma linha `RESUMO ... erros=N` e sai com 0 só quando `N` é 0.

## 3. Arquivos, ordem de carga e o que cada um publica

O `.toc` lista os 28 arquivos na ordem da tabela da seção 4.1 do `DESIGN.md`, com:

```
## Interface: 16001
## Title: PregaoForever
## Notes: Auction terminal: ruler, queue and one key per action
## Author: Bruno
## Version: 0.1.0
## SavedVariables: PregaoForeverDB
## SavedVariablesPerCharacter: PregaoForeverCharDB
## OptionalDeps: Auctionator, Syndicator, Baganator, ElvUI
```

Cada módulo publica uma tabela em `ns` com o nome do arquivo em minúsculas (`Banco.lua` publica `ns.banco`), criada no topo com `ns.banco = ns.banco or {}`. O `Nucleo.lua` publica direto em `ns`. Um módulo só chama outro pelo que está nas tabelas abaixo; função que não está aqui é `local` ou fica numa subtabela `_` do próprio módulo (`ns.banco._`), que ninguém de fora chama. Chamada a um módulo carregado depois é permitida só dentro de função (nunca no topo do arquivo), porque no topo ele ainda não existe.

Esqueletos (onda 1): todo arquivo tem `local _, ns = ...`, um comentário de cabeçalho com a responsabilidade e a onda em que ganha corpo, e a criação da sua tabela. Os arquivos das ondas 3 a 5 e da fase 3 (`Receitas`, `Estimadores`, `Motor`, `Sombra`, `Estrategias`, `Acoes`, `Alertas`) ficam só nisso até a sua onda.

### 3.1 `Nucleo.lua` (publica direto em `ns`; onda 2)

| Nome | O que faz |
|---|---|
| `ns.NOME`, `ns.VERSAO` | `"PregaoForever"`, `"0.1.0"` |
| `ns.seguro(fn)` | devolve uma função que chama `fn` por `xpcall(fn, geterrorhandler(), ...)`, na mesma pilha (regra 3) |
| `ns.ao(evento, fn)` | registra `fn(evento, ...)` no quadro escondido do Núcleo; vários `fn` por evento, na ordem de registro; despacho por `ns.seguro`. Só o Núcleo chama `RegisterEvent` |
| `ns.depois(seg, fn)` | `C_Timer.After(seg, ns.seguro(fn))`. Proibido em `Acoes.lua` |
| `ns.servidor()` | `GetServerTime()`: única hora que vai ao disco |
| `ns.mono()` | `GetTime()`: intervalos curtos da sessão |
| `ns.fino()` | `GetTimePreciseSec()` se existir, senão `debugprofilestop() / 1000`, senão `nil` |
| `ns.diaMercado(t)` | `math.floor(t / 86400)` (dias desde 1970, UTC) |
| `ns.diaRisco()` | texto `AAAA-MM-DD` da data local por `date('*t')`, com virada às `cfg.disjuntores.dia_risco_hora` (6) |
| `ns.int(x)`, `ns.txt(x)` | `math.floor(x)`; `string.format('%d', math.floor(x))` (regra 14) |
| `ns.dinheiro(c)` | texto `1g 2s 3c` a partir de cobre inteiro |
| `ns.anel(max)` | objeto com `:por(v)`, `:itens()` (do mais velho ao mais novo) e `:tamanho()` |
| `ns.log(nivel, texto)` | anel de 60 linhas em memória, no formato `1|t|nivel|texto` da seção 6.1; o `Banco` copia para `PregaoForeverDB.log` |
| `ns.fatiar(n, fn, fim)` | chama `fn(i)` para `i = 1..n` em fatias de `cfg.fatia.ms` (2 ms) pelo `ns.fino()` (sem relógio fino: `cfg.fatia.linhas` por fatia), com `ns.depois(0, ...)` entre fatias; `fim()` no fim |
| `ns.emCombate()` | `InCombatLockdown()` como booleano |
| `ns.msg(texto)` | `print` com o prefixo do addon; texto em inglês |
| `ns.pers()` | `UnitName('player')`: chave de `pers[...]` e do `Config.lua` |
| `ns.casa()` | `GetNormalizedRealmName() .. ':' .. UnitFactionGroup('player')` |
| `ns.cfg`, `ns.modo()` | a tabela do `Config.lua`; `ns.modo()` devolve `'leitura'` quando o banco não carregou, o `Config` falta ou é de outro esquema, senão `ns.cfg.modo` |
| `ns.faixa` | faixa de estado atual (`nil` ou um destes textos: `CONFIG ERROR - read only`, `DATABASE NOT LOADED - tell the agent`, `Press L to reconcile`, `KEYS HELD`) |
| `ns.sujo(parte)` e `ns.aoSujo(fn)` | bandeira suja por parte (`'tela'`, `'conciliar'`); o Núcleo chama os `fn` no máximo uma vez por quadro |

### 3.2 `Tetos.lua`, `Config.lua`, `Calibrado.lua`, `Dados.lua`, `Receitas.lua` (onda 1)

`Tetos.lua` publica `ns.tetos`, só dinheiro, com os valores duros da seção 9.2 (frações de `B` e pisos absolutos em cobre: `deposito_risco = { frac = 0.05, piso = 2000 }`, `deposito_perdido_dia = { frac = 0.02, piso = 800 }`, `lote_confirmacao = 0.02`, `ordem_micro = 0.10`, `acumulado_item = 0.20`, `estoque_total = 0.50`, `perda_dia = 0.05`, `perda_item_dia = 0.01`, `preco_postagem_ref = 3`, `volume_item_dia = 0.10`, `sonda = { deposito = 30, compra = 20 }`).

`Config.lua` publica `ns.cfg` com `esquema = 1` e todos os parâmetros do Apêndice B nos valores de partida, agrupados assim: `modo`, `negociador`, `piso_pessoal`, `cofre`, `reservas`, `licencas`, `destravas`, `folego`, `T_pulso`, `teclas`, `guardas`, `remoto`, `idades`, `ritmo`, `foco`, `fatia`, `triagem`, `fotos`, `dias`, `blocos`, `banco`, `salvar`, `desk_stale_dias`, `divergencia`, `venda`, `compra`, `antiguerra`, `disjuntores`, `sonda`, `degrau`. Tempos em segundos ou minutos como diz o nome do campo (`_s`, `_min`, `_ms`, `_h`); dinheiro em cobre. Valores desta onda: `modo = 'leitura'`; `negociador = 'Hexumlite'`; `piso_pessoal = {}` (zero para todos); `reservas = {}`; `licencas` com todas as estratégias em `nivel = 0`, e `venda_verdes` com `aprovadaEm = '2026-11-16'`; `venda.regra = { equipamento = 'igualar', commodity = 'igualar' }`, `venda.duracao` e `venda.lote` de commodity sem valor (`PICK RULE`); `folego.gatilho = 'tecla'`; `teclas` com o mapa da seção 11.2, marcado `pendente da DD5`.

`Calibrado.lua` publica `ns.calibrado = { esquema = 1, geradoEm = 0, recibo = 0, epoca = 0, valores = {}, sentinela = 'PREGAO-CALIBRADO-FIM' }`, neutro.

`Dados.lua` é gerado (seção 13): `ns.vend[itemID] = SellPrice` e `ns.pilha[itemID] = Stackable` (só os maiores que 1), com cabeçalho de origem. `Receitas.lua`: `ns.receitas = {}`.

### 3.3 `Banco.lua` (publica `ns.banco`; onda 2)

| Nome | O que faz |
|---|---|
| `abrir()` | no `ADDON_LOADED` do addon: aplica a seção 6.3 (banco `nil` com `PregaoForeverCharDB.bancoDesde` vira `carregado = false` e faixa `DATABASE NOT LOADED - tell the agent`, sem recriar); banco novo grava `esquema`, `epoca = ns.servidor()` e as tabelas da seção 6; marca `PregaoForeverCharDB.bancoDesde`; decodifica `dias`, `blocos`, `itens` e `calib` para tabelas numéricas na memória; confere o fim sujo (`fecho.dinheiro` contra `GetMoney()`) |
| `carregado` | booleano |
| `seq()` | incrementa e devolve `PregaoForeverDB.seq` |
| `casa()`, `pers(nome)` | a seção de mercado da casa atual e a seção do personagem (padrão `ns.pers()`), criando as subtabelas da seção 6 |
| `gravar(anel, linha)` | põe a linha no anel nomeado (`'livro'`, `'lotes'`, `'correio'`, `'fora'`, `'sinais'`, `'sessoes'`, `'fotos:<chave>'`) com os limites da seção 6.2, a poda por `recibo` e `sobrescritos`; atualiza o medidor |
| `cod.<tipo>(t)` e `dec.<tipo>(linha)` | codifica e decodifica cada tipo da gramática (seção 4): `itens`, `resumo`, `dias`, `blocos`, `fotoC`, `fotoI`, `sinal`, `acao`, `lote`, `fatura`, `fora`, `proprio`, `calib`, `sessao`, `npc`, `sonda`, `log`. `dec(cod(t))` devolve `t`; linha de versão desconhecida devolve `nil` |
| `medidor()` | bytes estimados (soma das strings mais 12 por entrada) |
| `naoSalvo()` | `n` de ações e minutos desde o último `/reload` |
| `param(nome)` | valor calibrado do `Calibrado.lua` dentro da faixa do Apêndice B, senão o de partida do `Config` |
| `desk()` | `'DESK OK'`, `'DESK STALE'` ou `'NO DESK'` (seção 12) |
| `fechar()` | no `PLAYER_LOGOUT`, dentro de `ns.seguro`: codifica as tabelas da memória, copia o `ns.log`, grava `pers[nome].fecho`, `salvoEm` e por último `fim = seq` |

### 3.4 `Itens.lua` (publica `ns.itens`; onda 2)

| Nome | O que faz |
|---|---|
| `chave(itemKey)` | texto da chave (seção 4): `itemID` em commodity, `itemID:itemLevel:itemSuffix` em item |
| `itemKey(chave)` | a tabela `itemKey` do cliente a partir do texto |
| `deLocal(loc)` | chave, quantidade e tipo (`'c'` ou `'i'`) de um `ItemLocation` da bolsa, por `C_AuctionHouse.GetItemKeyFromItem` e `GetItemCommodityStatus` |
| `info(chave)` | `{ vend, tipo, pilha, conf, nome }` com o preço de vendedor lido ao vivo por `C_Item.GetItemInfo(link)` (regra 17); `nil` e pedido de carga por `C_Item.RequestLoadItemDataByID` se o item não está no cache; responde ao `ITEM_DATA_LOAD_RESULT` |
| `bolsas()` | lista de `{ bolsa, slot, chave, qtd, tipo }` das bolsas 0 a 4 que o leilão aceita, sem os itens de `cfg.reservas[ns.pers()]` (esses voltam com `reservado = true`) |

### 3.5 `Pedidos.lua` (publica `ns.pedidos`; onda 2)

Única porta das funções de consulta da regra 9. Regras na seção 5.2 do `DESIGN.md`.

| Nome | O que faz |
|---|---|
| `tecla()` | registra a presença do dono (hora da última tecla do terminal); toda tecla do `Teclas` chama |
| `abrirFolego(dono)` | abre um fôlego se houver tecla há até `cfg.T_pulso`; `dono` é a função de quem dirige o ciclo (a `Varredura`); devolve `false, motivo` se não abriu |
| `enviar(p)` | `p = { tipo, chave, sorts, aoResponder, aoFalhar }`, `tipo` entre `browse`, `mais_browse`, `proprios`, `busca`, `busca_venda`, `releitura`, `mais_busca`; confere I9, fôlego aberto, uma em voo, `IsThrottledMessageSystemReady()`, ritmo e `folego.max_buscas`; chama a função do cliente e espera a resposta certa (seção 5.2, "De quem é a resposta"), com prazo `cfg.guardas.consulta_s` |
| `fecharFolego(motivo)` | fecha e zera a fila |
| `estado()` | `{ fase = 'PARADO' | 'ABERTO' | 'TRAVADO', buscas, buscasMin, emVoo, motivo }` |

Registra os eventos `AUCTION_HOUSE_THROTTLED_*`, `AUCTION_HOUSE_NEW_RESULTS_RECEIVED`, `AUCTION_HOUSE_BROWSE_RESULTS_UPDATED`, `AUCTION_HOUSE_BROWSE_RESULTS_ADDED`, `AUCTION_HOUSE_BROWSE_FAILURE`, `COMMODITY_SEARCH_RESULTS_UPDATED`, `ITEM_SEARCH_RESULTS_UPDATED`, `OWNED_AUCTIONS_UPDATED` (para fechar a espera) e `AUCTION_HOUSE_CLOSED`.

### 3.6 `Varredura.lua` e `Escada.lua` (publicam `ns.varredura` e `ns.escada`; onda 2)

`ns.varredura.tecla()` é o `L`: abre o fôlego por `ns.pedidos.abrirFolego` e dirige a máquina da seção 5.2 (PROPRIOS, RESUMO, TRIAGEM, FOCO), com o foco da seção 5.1. `ns.varredura.estado()` devolve `{ fase, feitas, total, idadeResumo }` para as telas. O resumo é lido por `GetBrowseResults()` uma vez no `..._UPDATED` e pelos payloads de `..._ADDED`; a triagem roda por `ns.fatiar`. O primeiro fôlego depois da abertura chama `ns.cofre.conciliar('leilao')` ao fim de PROPRIOS.

`ns.escada.fotoC(itemID)` e `ns.escada.fotoI(itemKey)` leem a resposta da busca e devolvem a foto da seção 5.3 (sem as unidades próprias, com as marcas `F` e `E`, nomes descartados); `ns.escada.gravar(chave, foto)` grava pelo `ns.banco` e atualiza `dias` e `blocos`. `ns.escada.ultima(chave)` devolve a foto mais nova e a idade.

### 3.7 `Livro.lua` (publica `ns.livro`; onda 2)

| Nome | O que faz |
|---|---|
| `acao(r)` | grava uma ação (`r` com os campos da linha `acao`); na onda 2 só chega `origem = 'outside'` |
| `intencao(ordem)` | existe só como função que devolve `nil` até a onda 3 |
| `lote(r)`, `fecharLote(seq, estado, resultado)` | lotes abertos e fechados (seção 10) |
| `fora(variacao, janela)` | registro `Fora` |
| `sessao()` | `{ tIni, acoes = { post, buy, cancel, outside }, resultado, fora }` da sessão corrente, para a visão Session |
| `fecharSessao()` | grava a linha `sessoes` (chamado pelo `Banco.fechar`) |

### 3.8 `Ecos.lua` (publica `ns.ecos`; onda 2, só observação)

Registra `AUCTION_HOUSE_AUCTION_CREATED`, `AUCTION_CANCELED`, `AUCTION_HOUSE_PURCHASE_COMPLETED`, `COMMODITY_PURCHASE_SUCCEEDED`, `COMMODITY_PURCHASED` e `OWNED_AUCTIONS_UPDATED`. Sem ação do addon em voo (sempre, na onda 2), todo eco vira `ns.livro.acao` com `origem = 'outside'` e o lote correspondente. `ns.ecos.emVoo()` devolve `nil` na onda 2. Não chama função de ação nem de consulta.

### 3.9 `Cofre.lua` (publica `ns.cofre`; onda 2 só a conciliação, em leitura)

| Nome | O que faz |
|---|---|
| `banca()` | `{ B, livre, estoque, deposito, correio, piso }` do personagem logado (seção 9.1) |
| `conciliar(janela)` | `janela` é `'leilao'` ou `'correio'`; compara dinheiro, leilões próprios e bolsas (ou faturas) com o Livro e devolve `{ ok, texto }`, com `texto` igual a `RECONCILED n of n` ou `UNEXPLAINED <dinheiro>` (seção 10); desvio acima de `cfg.divergencia` liga o disjuntor de dinheiro sem explicação em `pers.cofre` |
| `autoriza(ordem)` | devolve `false, 'READ ONLY'` até a onda 3 |
| `disjuntores()` | lista dos ligados, para a linha de estado |

Registra `PLAYER_MONEY` e as janelas `AUCTION_HOUSE_SHOW`/`CLOSED`, `MAIL_SHOW`/`CLOSED` e `MERCHANT_SHOW`/`CLOSED`: variação fora de janela vira `ns.livro.fora`. Na abertura do leilão põe `ns.faixa = 'Press L to reconcile'` até o primeiro fôlego conciliar.

### 3.10 `Correio.lua` (publica `ns.correio`; onda 2)

Registra `MAIL_SHOW`, `MAIL_INBOX_UPDATE` e `MAIL_CLOSED`. Lê `GetInboxNumItems`, `GetInboxHeaderInfo` e `GetInboxInvoiceInfo` (nunca `GetInboxText` nesta onda: a S7 decide), grava só cartas de leilão como linha `fatura`, descarta `playerName`, remetente e assunto. `ns.correio.painel()` devolve `{ mostradas, total, faturas, aCaminho, maisCartas }`. Não pega nada (regra 10).

### 3.11 `Teclas.lua` (publica `ns.teclas`; onda 2 só navegação)

Botões nomeados `PregaoForeverTecla<X>` (`X` = `L`, `N`, `U`, `I`, `O`, `K`, `H`, `F3`, `F5`, `Y`), cada um com `OnClick` que chama `ns.pedidos.tecla()` e a função da tecla. `ligar()` no `AUCTION_HOUSE_SHOW` e `soltar()` no `AUCTION_HOUSE_CLOSED`, por `SetOverrideBindingClick(janela, true, tecla, nomeDoBotao)` e `ClearOverrideBindings(janela)`, só com `ns.emCombate()` falso (senão fica pendente para `PLAYER_REGEN_ENABLED`, regra 16). Filtro de repetição (`cfg.guardas.repeticao_ms`), pausa com foco em caixa de texto (`GetCurrentKeyBoardFocus()`, faixa `Keys paused`), `H` alterna `KEYS ON` e `KEYS HELD`. `Y` só existe na visão Session e chama `ReloadUI()` com tudo em repouso. `F1`, `F2` e `F4` ficam sem binding até a onda 3.

### 3.12 `Janela.lua`, `Telas.lua`, `Visual.lua`, `Sonda.lua`, `Pontes.lua`, `PregaoForever.lua` (onda 2)

`ns.janela.abrir()` e `fechar()` seguem `AUCTION_HOUSE_SHOW` e `AUCTION_HOUSE_CLOSED`; a janela `PregaoForeverJanela` fica à direita do `AuctionHouseFrame`, no tamanho que a S0 mediu (seção 11.1), com três zonas (estado, lista, bilhete). O painel do correio é o quadro `PregaoForeverCorreio`, com `MAIL_SHOW` e `MAIL_CLOSED`.

`ns.telas.mostrar(visao)` com `visao` em `'mine'`, `'session'`, `'sonda'`; `ns.telas.redesenhar()` pela bandeira suja. Cada visão segue o quadro aprovado (`pesquisa/telas/`). Ganchos da bancada: `ns.__tela = { visao, selecionada, linhas = { texto... }, faixa, estado }`, atualizado a cada redesenho (seção 16, item 8).

`Visual.lua` é a cópia do kit `ns.ui` do `GuiaForever/Visual.lua` (do dono), com os nomes do PregaoForever.

`ns.sonda` guarda o roteiro dos passos da onda 2 (S1, S3, S4, S5, S9, S12, S13), um cartão por passo, e grava `sonda[passo]` no formato da seção 6.1.

`ns.pontes.auctionator(chave)`, `ns.pontes.syndicator(chave)` e `ns.pontes.elvui(quadro)`: tudo em `pcall`, devolvendo `nil` se o addon falta. A assinatura real de cada um se lê no jogo por `/dump`, com o dono; até lá cada ponte devolve `nil`.

`PregaoForever.lua` registra `ADDON_LOADED` (filtrando o nome), chama `ns.banco.abrir()` e confere o `Config`; registra `PLAYER_LOGOUT` (chama `ns.banco.fechar()`); cria `/pregao` (abre a janela ou mostra o estado) e `/pregao sonda` (abre o cartão da sonda).

## 4. Gramática do banco (congelada)

Texto da seção 6.1 do `DESIGN.md`, sem mudança. O `Banco.lua`, o `ler-pregao.mjs`, o replay e a mesa seguem esta gramática; o `ler-pregao.mjs --ida-e-volta` passa cada exemplo abaixo por decodificar e codificar e exige o mesmo texto.

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

## 5. A bancada (contrato entre a onda 1 e a onda 2)

`node pregao/bancada-pregao.mjs [--addon <pasta>] [--auto-teste] [--cenarios <grupo>] [--cenario <id>]`, em fengari (Lua 5.3), com o falso em `pregao/bancada/`. O padrão de `--addon` é `../../addons-proprios/PregaoForever`. Carrega os arquivos na ordem do `.toc`, cada um como bloco com os argumentos `("PregaoForever", ns)`, com o `ns` compartilhado. O que o falso simula e as variantes injetáveis estão na seção 16 do `DESIGN.md`.

Um cenário é um arquivo Lua que devolve:

```lua
return {
  id = "folego-01",
  grupo = "folego",
  descricao = "L abre um folego; nada consulta antes do L",
  inicio = {            -- estado do falso antes do ADDON_LOADED
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance",
    dinheiro = 40000,
    bolsas = { { bolsa = 0, slot = 1, itemID = 2589, qtd = 20 } },
    mercado = { ["2589"] = { { preco = 9, qtd = 14, donos = 2 } } },
    proprios = {}, correio = {}, sv = nil,   -- sv: tabela PregaoForeverDB inicial, ou nil
  },
  passos = {
    { abrir_leilao = true },
    { avancar = 5 },               -- segundos do relogio simulado, rodando timers e eventos devidos
    { tecla = "L" },               -- despacha o clique no botao PregaoForeverTeclaL, com a bandeira de hardware
    { ate_ocioso = true },         -- avanca ate nao haver timer nem resposta pendente (limite de 600 s)
    { injetar = "throttle_travado" },
    { evento = { "PLAYER_MONEY" } },
    { reload = true },             -- PLAYER_LOGOUT, serializa o SV e recarrega o addon com ele
    { salvar_sv = "folego-01" },   -- grava ../../dados/pregao/bancada/folego-01-sv.lua
  },
  conferir = function(b)
    b.igual(b.contar("SendBrowseQuery"), 1, "um resumo por folego")
    b.verdadeiro(b.tela().faixa == nil, "faixa limpa depois do folego")
  end,
}
```

A tabela `b`, que a bancada passa ao `conferir`: `b.ns` (o `ns` do addon), `b.db()` (o `PregaoForeverDB` em memória), `b.tela()` (o `ns.__tela`), `b.contar(nome)` e `b.chamadas(nome)` (chamadas às funções do falso, com hora e argumentos), `b.eventos()` (os disparados, em ordem), `b.agora()`, `b.violacoes()` (bandeira de hardware, I1 e I9), `b.erros()` (erros capturados pelo `geterrorhandler`) e as asserções `b.igual(obtido, esperado, msg)`, `b.verdadeiro(x, msg)` e `b.falso(x, msg)`. Cenário com asserção falha, violação ou erro de Lua conta como erro. A saída lista `OK <id>` ou `FALHA <id>: <motivo>` e termina com `RESUMO cenarios=<n> erros=<e>`; código de saída 0 só com `e = 0`, 2 se um arquivo do addon não carregou.

`--auto-teste` roda os cenários de `casos-pregao/cenarios/autoteste/`, que só conferem o falso (um addon de brinquedo em `casos-pregao/brinquedo/`), e é o pronto da onda 1. Os grupos `folego`, `fatura` e `dados` são da onda 2, cada um escrito pela tarefa que constrói o módulo que ele testa.

## 6. Checador e casos

`checar-pregao.mjs <pasta>` confere as regras estáticas listadas na seção 16 do `DESIGN.md` ("Checadores estáticos") e imprime uma linha por achado, `<arquivo>:<linha> R<n> <texto>`, e `RESUMO arquivos=<n> erros=<e>`. Os casos ficam em `casos-pregao/regras/r<NN>-bom/` e `r<NN>-ruim/`, cada um uma pasta de addon mínima com um `esperado.txt` (`0` no bom; `R<NN>` no ruim). `rodar-casos-pregao.mjs` roda o checador em cada pasta e exige o resultado esperado; termina com `RESUMO casos=<n> erros=<e>`.

## Mudanças do contrato

Entre as ondas 1 e 2, em 2026-11-16, na sessão principal:

1. `Nucleo.lua` está pronto e é a referência (o código vale sobre a tabela 3.1). Acréscimos: `ns.aoSujo(parte, fn)` recebe a parte; `ns.marcarFaixa(nome, texto)` liga (texto) ou apaga (`nil`) uma faixa, e `ns.faixa` fica com a de maior prioridade, na ordem `config`, `banco`, `restricao`, `travado`, `pausa`, `held`, `reconciliar` (as duas faixas de tecla vêm antes de reconciliar porque com elas nem o `L` responde); `ns.faixaLigada(nome)`; `ns.configOk()`; `ns.registro` é o anel do log; `ns.fatiar` devolve um objeto com `:parar()`. Os módulos não escrevem `ns.faixa` direto: usam `ns.marcarFaixa`.
2. `PregaoForever.lua` está pronto: chama `ns.banco.abrir()` no `ADDON_LOADED`, `ns.banco.fechar()` no `PLAYER_LOGOUT`, e `/pregao` chama `ns.janela.abrir()` ou `ns.janela.abrir('sonda')`. `ns.janela.abrir(visao)` aceita a visão inicial.
3. `Config.lua` ganha `janela = { w, h, escala }` (520, 500 e 1 até a S0). A `Janela.lua` lê o tamanho daí.
4. `Pedidos.lua` registra também `COMMODITY_SEARCH_RESULTS_ADDED` e `ITEM_SEARCH_RESULTS_ADDED` (existem em `ferramentas/guia/api-forever/Events.lua`; a bancada os dispara no `RequestMore` de busca).
5. A bancada aceita mais do que a seção 5 lista (o cabeçalho de `pregao/bancada-pregao.mjs` e os cenários de `casos-pregao/cenarios/autoteste/` são a referência): passos `clique = "<botão>"`, `chamar = function(b) ... end` e `fechar_leilao`; campos de cenário `esperado_falha`, `aceita_violacoes` e `aceita_erros`; em `inicio`, `parametros`, `itens`, `sv_char`, `semente`, `hora`, `fuso` e `combate`; `node pregao/bancada-pregao.mjs --injecoes` lista as injeções. Ainda não simula o processo de venda (onda 3) nem as injeções de arquivo (Config quebrado, Calibrado truncado).
6. Cenários de unidade: cada módulo tem os seus em `casos-pregao/cenarios/unid-<modulo>/`, que chamam o módulo por `chamar` e podem trocar por falsos, dentro do cenário, as funções de outros módulos de que ele depende (`b.ns.banco.gravar = function(...) end`). Os grupos `folego`, `fatura` e `dados` são de ponta a ponta e só passam com todos os módulos da onda 2 juntos. O exemplo é `casos-pregao/cenarios/unid-nucleo/nucleo-01.lua`.
7. Tabelas do banco que não são anel. `ns.banco.memoria()` devolve, da casa atual, as tabelas da memória: `itens[chave] = { vend, tipo, pilha, conf }`, `dias[chave][dia] = { min, qtd }`, `blocos[chave][bloco] = { min, qtd }` e `calib[parametro] = { valor, n, medido, em, build, amostras }`; quem lê o mercado escreve nelas (`Itens` em `itens`; `Escada` em `dias` e `blocos`), e o `Banco.fechar` codifica com os limites da seção 6.2, em ordem de chave. As tabelas que se substituem inteiras têm um dono, que escreve direto com `ns.banco.cod`: `casa().resumo` é da `Varredura`; `pers().proprios` é da `Varredura`, no estado PROPRIOS, lido de `C_AuctionHouse.GetNumOwnedAuctions` e `GetOwnedAuctionInfo`; `pers().cofre` é do `Cofre`; `sonda[passo]` é da `Sonda`. Os anéis (`livro`, `lotes`, `correio`, `fora`, `sinais`, `sessoes`, `fotos:<chave>`) só por `ns.banco.gravar`; `pers().abertos` pelo `Livro`.
8. Método da onda 2: cada tarefa trabalha numa cópia própria da pasta do addon (`--addon <cópia>` na bancada e a cópia como pasta nos checadores) e só no fim copia os seus arquivos para a pasta real, para não carregar arquivo de outra tarefa pela metade.
