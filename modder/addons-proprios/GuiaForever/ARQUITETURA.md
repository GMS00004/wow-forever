# GuiaForever 1.0: arquitetura e contratos

Escrito em 2026-11-06 (noite), antes da execução do plano `C:\Users\PC-AVELL\.claude\plans\continue-lexical-elephant.md`. Este arquivo é o contrato entre os módulos: quem muda uma API aqui muda o contrato junto.

Objetivo da 1.0: o guia aparece onde o dono já está olhando, na hora certa, com um botão. São quatro peças:

1. o painel "Agora" embaixo do RestedXP;
2. o Ctrl+1 que alimenta o pet;
3. as marcas dentro das janelas do jogo (treinador de pet, árvore de talentos, tooltips);
4. a janela J, que vira a segunda camada.

## 1. Regras que valem para todo arquivo

| # | Regra |
|---|---|
| 1 | Lua 5.1 e só ASCII, sem acento nem em comentário (`ferramentas\guia\checar-lua.mjs`). Texto que aparece no jogo em inglês; comentários em português sem acento. |
| 2 | Cada arquivo começa com `local _, ns = ...` e publica só em `ns`. Global nova só com prefixo `GuiaForever`, `SLASH_GUIAFOREVER` ou `BINDING_`. |
| 3 | Nenhum arquivo depende de outro arquivo novo existir: toda chamada entre módulos é guardada (`if ns.agora and ns.agora.provedor then ... end`). O jogo só relê a lista do `.toc` ao abrir. Um `/reload` feito com o jogo aberto desde antes da 1.0 carrega o código novo dos arquivos antigos, mas não os arquivos novos. |
| 4 | Em combate, nada de `CreateMacro`, `EditMacro`, `DeleteMacro`, `SetBinding*`, `SaveBindings`, `PickupAction`, `PlaceAction`, `SetCVar`, `SetAttribute` ou `SetUIPanelLayoutAttribute`: use `ns.foraDeCombate`. A função que chama um deles começa com `if ns.emCombate() then ... return end` ou tem o comentário `-- fora-de-combate` na linha de cima (o `checar-combate.mjs` cobra). |
| 5 | Nunca ler API que vira secreta: `UnitAttackSpeed`, `UnitRangedDamage`, `UnitRangedAttackPower`, `GetUnitSpeed`, `C_Spell.GetSpellCooldown`, `GetSpellCharges`, `C_UnitAuras.*`. Nada de evento quente (`COMBAT_LOG_EVENT_UNFILTERED`, `UNIT_AURA`, `SPELL_UPDATE_COOLDOWN`). Em tooltip, sair cedo se `InCombatLockdown()`, ou se `issecretvalue` existir e disser que o dado é secreto. |
| 6 | Quadro da Blizzard só por `hooksecurefunc`, `HookScript`, `EventRegistry:RegisterCallback` e `TooltipDataProcessor.AddTooltipPostCall`. Nunca `SetScript` em quadro alheio. Nunca campo novo em tabela da Blizzard: use tabela fraca própria, `setmetatable({}, { __mode = "k" })`. Nunca carregar addon da Blizzard (`LoadAddOn`, `C_AddOns.LoadAddOn`) nem abrir janela protegida pelo código. |
| 7 | O guia marca e o dono clica: são proibidos `C_Traits.PurchaseRank`, `C_Traits.CommitConfig`, `BuyTrainerService`, `CastSpell*` e `UseContainerItem` (decisão do dono, 2026-11-06). |
| 8 | Nome de API do Forever: confira em `ferramentas\guia\api-forever\GlobalAPI.lua` (funções), `Events.lua` (eventos), `FrameXML.lua` (funções da interface) e `Templates.lua` (templates). Assinatura e retorno ficam em `Interface/AddOns/Blizzard_APIDocumentationGenerated/` do espelho `Ketho/wow-ui-source-forever` (branch `forever`): `gh api "repos/Ketho/wow-ui-source-forever/contents/<caminho>?ref=forever" -H "Accept: application/vnd.github.raw"`. No Forever **não existem** `IsPlayerSpell` nem `UnitCharacterPoints`. Função fora dessas listas, ou de outro addon, só com checagem de existência antes. |
| 9 | Addon de terceiro (Naowh, RestedXP, Questie, TomTom, ElvUI) só por chamada em tempo de execução, com `pcall` e checagem de tipo do que voltou. Nunca copiar código: a licença do Naowh é "all rights reserved". |
| 10 | Função chamada por evento, timer ou clique roda em `xpcall(fn, geterrorhandler())`: o erro vai para o BugSack, sem popup. |
| 11 | Conteúdo de gameplay (o que treinar, que talento, como usar) só dos dados (`Dicas.lua`, `Dados.lua`, `Ajuda.lua`, `Teclas.lua`), que citam a fonte. O código não inventa conselho. Estado (dieta, pontos de treino, magias conhecidas) vem do jogo. |

Assinaturas conferidas no espelho em 2026-11-06:

| Função | Retorno |
|---|---|
| `C_PetInfo.GetPetHappiness()` | felicidade (1 Unhappy, 2 Content, 3 Happy), % de dano, taxa de lealdade |
| `C_PetInfo.GetPetFoodTypes()` | lista de textos ("Meat", "Fish"...) |
| `C_PetInfo.CanPetEatItem(itemID)` | booleano |
| `C_PetInfo.GetPetTrainingPoints()` | total, usados |
| `C_PetInfo.GetSpellForPetAction(actionID)` | id da magia ou nil |
| `C_SpellBook.IsSpellKnown(spellID, banco)` | booleano; o banco padrão é `Enum.SpellBookSpellBank.Player`, e `.Pet` para o pet |
| `C_SpellBook.HasPetSpells()` | número de magias do pet e token (ou nada) |
| `C_ClassTalents.GetActiveConfigID()` | id ou nil |
| `C_Traits.GetConfigInfo(configID)` | tabela com `treeIDs` |
| `C_Traits.GetTreeCurrencyInfo(configID, treeID, false)` | lista; `[1].quantity` são os pontos livres |
| `C_QuestLog.GetLogIndexForQuestID(id)`, `IsComplete(id)`, `IsQuestFlaggedCompleted(id)`, `IsOnQuest(id)` | índice ou nil; booleanos |

## 2. Ordem de carga (`GuiaForever.toc`)

`Dados`, `Dicas`, `Ajuda`, `ProfissoesA`, `ProfissoesB`, `GuiaForever`, `Estado`, `Janela`, `Treinadores`, `SkinDB`, `Zona`, `Teclas`, `Rastreador`, `Agora`, `Pet`, `Arvore`, `Tooltips`. `OptionalDeps`: Questie, QuestieDB, TomTom, NaowhForever, NaowhForever_Training, RXPGuides (assim eles carregam antes e o `RXPFrame` já existe).

## 3. `Estado.lua`: base comum (tarefa A5)

| API | Contrato |
|---|---|
| `ns.ao(evento, fn)` | um quadro só para os eventos; registra com `pcall` (evento desconhecido não quebra); chama `fn(evento, ...)` com `xpcall`; vários `fn` por evento, na ordem de registro |
| `ns.agendar(chave, segundos, fn)` | debounce: um timer pendente por chave |
| `ns.foraDeCombate(chave, fn)` | roda já se fora de combate; em combate guarda por chave e roda no `PLAYER_REGEN_ENABLED` |
| `ns.estado` | tabela mantida pelos eventos: `nivel`, `classe` (token), `raca` (token de `UnitRace`, ex. "NightElf"), `faccao` ("Alliance"/"Horde"), `emGrupo`, `mapa` (`C_Map.GetBestMapForUnit("player")`), `zona` (`GetRealZoneText()`), `continente` (sobe os pais com `C_Map.GetMapInfo` até `Enum.UIMapType.Continent`), `pet = { existe, morto, nome, felicidade, danoPct, dieta, pontosTotal, pontosUsados, nivel }` |
| `ns.conhece(magia)` | número: `C_SpellBook.IsSpellKnown(id)`; texto: cache do livro por nome (como `magiasConhecidas`, `UIForever\UIForever.lua:225-254`), refeito no `SPELLS_CHANGED` |
| `ns.petConhece(nome)` | livro do pet (`C_SpellBook` com `Enum.SpellBookSpellBank.Pet`); reserva: nomes da barra do pet (`GetPetActionInfo(1..10)`) |
| `ns.pontosTalento()` | pontos de talento livres por `C_Traits`; `nil` quando não dá para saber |
| `ns.missao(id)` | "feita", "pronta", "andando" ou "fora" |
| `ns.seta(mapa, x, y, titulo)` | x e y de 0 a 1; uma seta do guia por vez (apaga a anterior). Usa o TomTom (`AddWaypoint` com `title`, `from = "GuiaForever"`, `persistent = false`, `crazy = true`, `cleardistance = 10`). Sem ele, a seta nativa (`C_Map.CanSetUserWaypointOnMap`, `C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapa, x, y))`, `C_SuperTrack.SetSuperTrackedUserWaypoint(true)`). Sem as duas, o chat recebe "/way #mapa x y". Devolve true quando pôs seta |
| `ns.limparSeta()` | apaga a seta do guia |
| `ns.distancia(mapa, x, y)` | jardas até o ponto no mesmo continente (`C_Map.GetWorldPosFromMapPos`), ou nil |
| `ns.teclaDe(nome)` | acha nas barras (slots 1 a 72) a macro (`GetActionText`) ou magia com esse nome. Pelo comando do slot (1-12 `ACTIONBUTTON`, 13-24 `ELVUIBAR2BUTTON`, 25-36 `MULTIACTIONBAR3BUTTON`, 37-48 `MULTIACTIONBAR4BUTTON`, 49-60 `MULTIACTIONBAR2BUTTON`, 61-72 `MULTIACTIONBAR1BUTTON`) e `GetBindingKey`, devolve "1", "Shift+2", "Ctrl+1" ou "Mouse 4"; nil se não houver |
| `ns.relevante(e, ctx)` | filtro das dicas (seção 7); `ctx = { tudo = bool, aba = "pet"|... }` |
| `ns.log(texto)` | `GuiaForeverDB.log`, até 60 linhas, com hora |
| `ns.dbPersonagem()` | `GuiaForeverDB.personagens[ns.chavePersonagem()]`, criada se faltar |
| `ns.nomeMagia(id)`, `ns.iconeMagia(id)` | `C_Spell.GetSpellName`/`GetSpellTexture`, com reserva em `GetSpellInfo` |

Eventos que o `Estado` acompanha: `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, `PLAYER_LEVEL_UP`, `ZONE_CHANGED_NEW_AREA`, `GROUP_ROSTER_UPDATE`, `SPELLS_CHANGED`, `LEARNED_SPELL_IN_SKILL_LINE`, `UNIT_PET`, `UNIT_HAPPINESS`, `PET_UI_UPDATE`, `PET_BAR_UPDATE`, `UNIT_PET_TRAINING_POINTS`, `TRAIT_TREE_CURRENCY_INFO_UPDATED`, `PLAYER_REGEN_DISABLED`, `PLAYER_REGEN_ENABLED`, `QUEST_LOG_UPDATE`.

## 4. `Agora.lua`: o painel (tarefa A6)

| API | Contrato |
|---|---|
| `ns.agora.provedor{ id, eventos, itens }` | registra um provedor. `eventos` é a lista de eventos que pedem atualização; `itens(ctx)` devolve uma lista de itens e roda em `pcall` |
| `ns.agora.atualizar()` | refaz a lista (debounce de 0,4 s; em combate só marca pendente) |
| `ns.agora.itens()` | a última lista completa, ordenada (para a aba Now do J) |
| `ns.agora.ocultos()`, `ns.agora.mostrar(chave)` | o que o dono escondeu e o desfazer |

Item: `{ chave, prio, cor, icone, texto, dica, fonte, aba, botao }`.

| Campo | Conteúdo |
|---|---|
| `chave` | id estável, ex. "pet:fome" |
| `prio` | número; menor aparece primeiro |
| `cor` | "vermelho", "laranja", "amarelo" ou "azul" |
| `icone` | textura, fileID ou nil |
| `texto` | até cerca de 8 palavras, em inglês |
| `dica` | linhas do tooltip |
| `fonte` | quem diz |
| `aba` | aba do J aberta pelo clique no texto |
| `botao` | `{ rotulo, acao, acaoDireita }` |

O painel:

| Aspecto | Comportamento |
|---|---|
| Quadro | comum (sem template seguro), `GuiaForeverAgora`, 360 de largura, linhas de 26 e no máximo 4 linhas |
| Rodapé | "+N more (J)" quando passa de 4 |
| Âncora | `TOPLEFT` no `BOTTOMLEFT` do `RXPFrame`, com y −8; sem RestedXP, `UIParent` `TOPLEFT` (12, −240) |
| Título | "Now (n)", fonte 13 cinza |
| Linha | faixa de 4 px na cor, ícone de 18, texto branco em fonte 15 (objetos de fonte criados com `CreateFont`), botão `UIPanelButtonTemplate` com 22 de altura à direita |
| Fundo | `BackdropTemplate`, `Interface\Buttons\WHITE8X8` em (0,06; 0,06; 0,06; 0,8) e borda de 1 px preta |
| Cores das faixas | vermelho (0,9; 0,2; 0,2), laranja (1; 0,55; 0,1), amarelo (1; 0,85; 0,1), azul (0,3; 0,6; 1) |
| Some | em combate (volta 3 s depois do `PLAYER_REGEN_ENABLED`), quando a lista está vazia e com o J aberto |
| Linha nova | entra com um fade de 0,3 s; sem som e sem piscar |
| Clique no texto | `ns.abrirAba(item.aba)` |
| Mouse por cima | tooltip com `dica` e "Source: ..." |
| Botão direito | esconde até o texto mudar (`ns.dbPersonagem().agoraOcultos[chave] = texto`) |
| Login | por 30 s o título vira "Next 3" e o painel mostra só 3 linhas |
| Mudança de tamanho ou lugar | chama `UIForever_AtualizarMargem()` se existir |

Prioridades:

| prio | Item |
|---|---|
| 10 | pet ausente ou morto |
| 20 | pet infeliz |
| 30 | missão de classe ou de pet pronta para entregar |
| 40 | treino de pet |
| 50 | talento |
| 60 | treino de classe |
| 70 | profissão travada |
| 80 | comida do pet acabando |
| 90 | avisos azuis |

Provedores da tarefa A6:

| Provedor | O que faz |
|---|---|
| `talento` | `ns.arvore.proximo()` dá "Talent point: Deadly Aspects 2/5", botão "Show", que abre a aba de talentos do J; "TBD" vira "Talent point: your pick, sources differ" |
| `classe` | `NaowhForever.Training.Plan(nivel)` em `pcall` dá "Train N spells: <treinador>", com botão "Arrow" (rota do Naowh em `pcall`); o botão direito abre o planejador. Sem Naowh: magias de `Dicas.magias` até o nível que `ns.conhece` diz que faltam, com seta por `ns.setaTreinador("classe")` |
| `teclas` | linhas de `GuiaForeverTeclas` com `n` ou `cheio` igual ao nível: "New at 12: E = Wing Clip" (azul) |

## 5. `Arvore.lua` (tarefas A6 e B1)

`ns.arvore.plano()` lê `GuiaForeverDados[classe].ordem` e devolve `[nivel] = { nome, rank, max, texto }`, ou `{ tbd = true }` para "TBD". `ns.arvore.proximo()` calcula `gastos = (nivel - 9) - ns.pontosTalento()` e devolve `{ nivel = 10 + gastos, ... }`; devolve nil sem ponto livre, sem plano ou com `ns.pontosTalento()` nil. A fase B põe as marcas na árvore (selo "NOW", níveis, check, "ALL" e "?"). Elas só entram quando o próprio jogo carrega o `Blizzard_PlayerSpells` (evento `ADDON_LOADED`), e o mapa nome → nó sai do `C_Traits`.

## 6. `Pet.lua` e `Tooltips.lua` (tarefas A7 e B2)

Provedor `pet`, só para `HUNTER` a partir do nível 10:

| Item | Quando |
|---|---|
| pet ausente ou morto | pet fora há 10 s (fora de montaria, táxi e morte do jogador); botão com `ns.teclaDe("pet_AllInOne")` |
| sem Feed Pet | felicidade abaixo de 3 sem Feed Pet conhecido; botão "Why" |
| infeliz com comida | felicidade 1; botão com a tecla da `feed_Pet` |
| sem comida | felicidade 1 ou 2 sem comida na bolsa: "Cat is Unhappy: buy Meat or Fish" (dieta do jogo) |
| contente | felicidade 2 por 5 s: "feed for Happy" |
| missão pronta | `GuiaForeverPet[classe].missoes` com `ns.missao(id) == "pronta"`; botão "Arrow" |
| treino de pet | habilidades de `Dicas.petTreino` no intervalo, que o pet não conhece; botão "Arrow" para o treinador de pet mais perto (dados) |
| autocast do Growl | ligado em grupo ou desligado sozinho (`GetPetActionInfo`): só aviso, com a dica "right-click Growl on the pet bar" |
| comida acabando | menos de 5 comidas comestíveis na bolsa |

A macro de alimentar fica em `ns.macroGerenciada(nome, icone, corpo)`, que só roda fora de combate:

1. Se a macro não existe, cria como macro do personagem e grava o corpo em `GuiaForeverDB.macros[chave].criadas[nome]` (assim o `/guia macros undo` também a apaga) e em `.gerenciadas[nome]`.
2. Se existe e o corpo atual é o último que o guia gravou, edita só quando o corpo novo for diferente.
3. Se o dono editou, deixa e registra em `ns.log`.

A `feed_Pet` tem este corpo:

    #showtooltip Feed Pet
    /stopmacro [nopet][@pet,dead][combat]
    /cast Feed Pet
    /use <nome da comida>

Ela nasce só depois de o Feed Pet (6991) ser conhecido e é refeita no `BAG_UPDATE_DELAYED` e no `UNIT_PET`. A comida é a de `C_PetInfo.CanPetEatItem` com o nível de item mais alto até o nível do pet, fora as que dão "Well Fed" (linha do `C_TooltipInfo.GetItemByID`) e as de `GuiaForeverPet[classe].comida.reservados`. No empate fica a pilha maior.

No treinador de pet:

| Parte | Comportamento |
|---|---|
| Quando entra | depois do `ADDON_LOADED` do `Blizzard_TrainerUI`, ou já se ele estiver carregado, por `hooksecurefunc("ClassTrainerFrame_InitServiceButton", ...)` |
| Quando age | só com `C_Trainer.GetTrainerType() == Enum.TrainerType.Pet` |
| Selo "PLAN" | na próxima graduação não aprendida das habilidades de `petTreino`, ancorado no `button.icon` (o ElvUI muda o resto da linha); quadros guardados em tabela fraca |
| Painel `GuiaForeverPainelPet` | no `TOPRIGHT` do `ClassTrainerFrame` (+8), com o título "Pet plan (Method, level 10)", "Training points: N free", uma linha por habilidade (check ou x) e, em cinza, "In groups: Growl off, Cower on (LudiDeo)" |
| Botão de compra | nenhum: o dono usa o botão Train da própria janela |
| Fecha | no `TRAINER_CLOSED` |

`Tooltips.lua`:

| Fase | Linha | Quando |
|---|---|---|
| A | "Your pet can eat this" (cor do guia) | tooltip de item, com pet ativo e `CanPetEatItem(id)` |
| B | "Key 5: ..." (de `Teclas`) e "Use: ..." (de `Dicas.magias` com `magia`) | tooltip de magia |
| B | "Autocast: on solo, off in groups (LudiDeo)" | tooltip de ação do pet, para Growl e Cower |

Todas as linhas têm o mesmo limite: no máximo 2 linhas a mais, nunca em combate e nunca com dado secreto.

## 7. Dados (tarefas A2 e A4)

Campos opcionais em toda entrada de `GuiaForeverDicas[classe].magias/armas/pets/rotacao/atributos/notas`:

| Campo | Conteúdo |
|---|---|
| `tags` | lista de "pvp", "grupo", "fimdejogo", "escolhapet" |
| `raca` | token, ex. "NightElf" |
| `zona` | nome do cliente, ex. "Teldrassil" |
| `requer` | nome de magia que precisa ser conhecida |
| `magia` | a magia de que a dica fala, para o tooltip (só em `magias`) |
| `prio` | 1 (essencial), 2 (útil) ou 3 (opcional) |

O `ns.relevante(e, ctx)` dá falso em seis casos (fora deles dá verdadeiro):

1. `tags` com "pvp" ou "fimdejogo", sem `ctx.tudo`;
2. "grupo" sem estar em grupo, sem `ctx.tudo`;
3. "escolhapet" fora da aba pet, sem `ctx.tudo`;
4. `raca` diferente da do personagem;
5. `zona` diferente da atual, sem `ctx.tudo`;
6. `requer` não conhecida.

Lista nova por classe, `petTreino = { { de, ate, habilidade, texto, fonte } }`: cada habilidade de pet que as fontes mandam treinar, a partir do nível dela. Ela fica na tela até o pet saber, mesmo depois do `ate`.

Tabela nova em `Dados.lua`:

    GuiaForeverPet = {
      HUNTER = {
        magias = { feed = 6991, call = 883, revive = 982, tame = 1515, dismiss = 2641, mend = 136 },
        missoes = { { id = 6103, nome = "Training the Beast", npc = "Jocaste", raca = "NightElf",
                      mapa = <uiMapID>, x = <0-1>, y = <0-1>, fonte = "RestedXP" } },
        treinadores = { { npc = "<nome>", mapa = <uiMapID>, x = <0-1>, y = <0-1>, fonte = "<de onde>" } },
        comida = { reservados = {},
                   vendedores = { { npc, dieta = "Meat", mapa, x, y, fonte } } },  -- reserva quando o Naowh nao estiver
      },
    }

Coordenadas só de dado conferido: Questie, QuestieDB ou `ns.TownNPCs` do Naowh, lidos nos arquivos instalados, com o caminho no comentário. As fontes permitidas em `fonte` são Method, DoubleZug, Kargoz (beta), Gladius (beta), LudiDeo (beta), MetaGoblin (beta), RestedXP, Naowh e leak.

`Ajuda.lua` (tarefa C2):

    GuiaForeverAjuda = { HUNTER = { { id, aba, pergunta, linhas = { { texto, fonte } } } } }

O `id` é único, a `pergunta` tem até 90 caracteres, cada `texto` até 160 e a `fonte` é uma das permitidas. Cada linha leva o comentário `-- origem:` apontando a ficha ou a fonte.

## 8. Janela J e comandos (tarefas A8 e C1)

`Janela.lua` exporta `ns.abas` (lista `{ id, rotulo }`), e o `/guia` gera os subcomandos dela (com `addons`). Na fase A, o texto passa a usar a fonte `GuiaForeverFonteTexto` (14) e a aba Level filtra por `ns.relevante`. Na fase C, a janela vira 760 × 600, com as abas Now, Pet, Talents, Combat, Professions e Help, busca, seções recolhíveis, a fonte de cada linha no tooltip e "Show all".

Ids das abas da fase C:

| id | Rótulo |
|---|---|
| `agora` | Now |
| `pet` | Pet |
| `talentos` | Talents |
| `combate` | Combat |
| `profissoes` | Professions |
| `ajuda` | Help |

Os ids antigos continuam aceitos por `ns.abrirAba` e pelo `/guia`, por um mapa de apelidos:

| Id antigo | Vai para |
|---|---|
| `nivel` | `agora` |
| `pets` | `pet` |
| `armas`, `rotacao`, `teclas` | `combate` |
| `prof`, `zona`, `treinos` | `profissoes` |
| `addons` | `ajuda` |

O mapa vale para que os itens do painel (que usam `talentos`, `nivel`, `teclas`, `pet`) e os comandos antigos continuem abrindo o lugar certo.

## 9. UIForever 0.6.0 (tarefa A9)

A margem das janelas do jogo é a borda direita da coluna da esquerda: o lado esquerdo do `RXPFrame` mais o maior entre a largura dele e a do `GuiaForeverAgora` (360 quando ele não existe), mais 8, em unidades do `UIParent`. Ela é aplicada por `SetUIPanelLayoutAttribute("LEFT_OFFSET", v)` só fora de combate, no login (+3 s), quando o `RXPFrame` muda de lugar ou tamanho e quando a global `UIForever_AtualizarMargem()` é chamada. Sem RestedXP, a margem fica no padrão (16).

## 10. Guia de pets (1.1.0, 2026-11-08)

Pedido do dono em 2026-11-07: um guia completo de habilidades de pet, por família e com progressão ("quando preciso domar outra fera de nível maior para aprender o rank seguinte"), no jogo e em PDF, com as explicações dos vídeos do Saltii (cartões) e do LudiDeo (tier list). Plano: `C:\Users\PC-AVELL\.claude\plans\olha-a-coisa-que-wiggly-pinwheel.md`.

### 10.1 Arquivos

| Arquivo | Papel |
|---|---|
| `PetGuia.lua` | dados gerados, global `GuiaForeverPetGuia`; nunca editar à mão (`ferramentas\guia\pets\gerar-guia.mjs`) |
| `Familias.lua` | módulo: aba "Families" e a seção de próximos ranks da aba Pet |
| `Janela.lua` | aba nova `{ id = "familias", rotulo = "Families" }` logo depois de `pet`; botões de aba com 94 de largura e passo de 96 (7 abas cabem nos 760); `construtores.familias` chama `ns.blocosFamilias(b)`; `construtores.pet` chama `ns.blocosProximosRanks(b)` logo depois de "Your pet" (as duas chamadas guardadas, regra 3) |
| `GuiaForever.toc` | `PetGuia.lua` depois de `Dicas.lua`; `Familias.lua` depois de `Pet.lua`; versão 1.1.0 |

Entradas do gerador, em `ferramentas\guia\pets\`: `habilidades.json` (cliente do Forever pelo wago.tools, build 1.60.1.70862: famílias, dieta, habilidades, rank, nível do pet, pontos de treino, spell id), `professores.json` e `feras.json` (Forever-Hunter-Pets, MIT, e Petopia Forever: quem ensina cada rank e a velocidade de cada fera), `saltii.json` (cartões do Saltii) e `textos.json` (notas por família e regras, escritas a partir das fontes do dono, cada uma com a fonte).

### 10.2 `GuiaForeverPetGuia`

    GuiaForeverPetGuia = {
      gerado = "AAAA-MM-DD", build = "1.60.1.70862",
      fontes = { { id = "Saltii", nome = "...", url = "...", data = "..." }, ... },
      regras = { { t = "<linha>", f = "<fonte>" }, ... },      -- "How pet abilities work"
      familias = {                                              -- lista, na ordem de exibição
        { nome = "Cat", papel = "Damage", unica = "Prowl", dieta = { "Meat", "Fish" },
          habilidades = { "Bite", "Claw", "Dash", "Prowl", ... }, -- treináveis por fera (sem passivas técnicas)
          notas = { { t = "<linha>", f = "<fonte>" }, ... },
          rapidas = { { npc = 2850, n = "Broken Tooth", nv = "37", z = "Badlands", v = 1.0, f = "<fonte>" }, ... } },
      },
      habilidades = {
        Claw = { desc = "<efeito>", treinador = false, familias = { "Bat", ... },  -- ou "all"
                 ranks = { { r = 1, pet = 1, pt = 1, id = <spellId>,
                             prof = { { npc = <id>, n = "Strigid Owl", nv = "5-6", z = "Teldrassil",
                                        fam = "Bird of Prey", v = 2.0, f = "Saltii", s = true, ok = true } } } } },
      },
    }

`s = true` marca o doador documentado pelo Saltii (vem primeiro na lista); os outros professores seguem por nível. `ok` é a confirmação da Forever-Hunter-Pets (`nil` quando a fonte não diz). Habilidade de treinador (`treinador = true`) não tem `prof`. Texto só ASCII, até 160 caracteres por `t`, em inglês.

### 10.3 `Familias.lua`

| API | Contrato |
|---|---|
| `ns.petRanks()` | `{ [habilidade] = rank }` do pet ativo, pelo livro do pet (`C_SpellBook.HasPetSpells`, `GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Pet)`): primeiro pelo `spellID` contra os `id` dos ranks do `GuiaForeverPetGuia`, depois pelo nome com o número do `subName` ("Rank 3"). Sem pet, `{}` |
| `ns.blocosProximosRanks(b)` | seção "Next ability upgrades" (aberta): família (`UnitCreatureFamily("pet")`), nível do pet e do jogador; para cada habilidade da família, o rank atual, o próximo (nível do pet e pontos de treino) e se já dá para treinar; até 3 professores que o jogador já pode domar (nível máximo da fera menor ou igual ao do jogador, porque o Tame Beast não funciona acima do seu nível, nota da Blizzard de 24/09), o do Saltii primeiro, com zona; um botão "Arrow" por professor quando o QuestieDB tiver o spawn (mesmo caminho de `Treinadores.lua`/`Zona.lua`, `ns.seta`). Uma linha final lembra o caminho: estabular o pet, domar o professor, lutar até aprender, devolver o professor e ensinar no Beast Training. Sem pet ou sem família conhecida, uma linha só |
| `ns.blocosFamilias(b)` | aba Families: (1) "How pet abilities work" (aberta na primeira vez) com `regras`; (2) `ns.blocosProximosRanks`; (3) uma seção recolhida por família, com resumo "papel, única, dieta", as linhas de papel, habilidade única, dieta, habilidades, notas e feras rápidas, e uma subseção recolhida (nível 2) "<Família> progression" com uma linha por rank de cada habilidade (`Claw 3 - pet 16, 7 TP: Black Bear Patriarch (16-17, Loch Modan)`, os outros professores no tooltip da linha); (4) "Abilities": uma seção recolhida por habilidade com efeito, quem aprende e os ranks com até 4 professores na linha e o resto no tooltip; (5) "Pet trainer": as de treinador com rank, nível e pontos; (6) "Sources" |

Regras da seção 1 valem por inteiro. Leitura só de estado (`UnitCreatureFamily`, `UnitLevel`, livro do pet, `C_PetInfo.GetPetTrainingPoints`); nada de API secreta, nada que compre ou treine (regra 7). Atualiza no `UNIT_PET`, `PET_BAR_UPDATE`, `SPELLS_CHANGED` e `UNIT_PET_TRAINING_POINTS` pelo `ns.ao`, só marcando sujo; a janela recalcula ao montar a aba.

### 10.4 PDF

`ferramentas\guia\pets\gerar-pdf.mjs` monta um HTML com o mesmo conteúdo do `GuiaForeverPetGuia` (regras, famílias com progressão, habilidades com todos os professores, treinador, fontes), página de 125 mm de largura, e imprime pelo Edge sem tela (`msedge --headless=new --no-pdf-header-footer --print-to-pdf=...`) em `P:\Meu Drive\WoW Forever\Guias\guia-pets-cacador.pdf`. Texto em inglês, igual ao do jogo.

## 11. Janela J 1.2: organizada (2026-11-08)

Pedido e decisões do dono em `ferramentas\guia\visual\LEIA-ME.md` (estudo, quadros `png\q1` a `q4`) e no plano `C:\Users\PC-AVELL\.claude\plans\guia-1-2-janela-organizada.md`. Esta seção é o contrato entre `Visual.lua`, `Janela.lua`, `Abas.lua`, `Familias.lua`, `Teclas.lua`, `Zona.lua` e `Treinadores.lua`. As regras da seção 1 continuam valendo por inteiro.

### 11.1 Curadoria (vale para todo construtor)

| # | Regra |
|---|---|
| C1 | A janela nunca mostra a fonte. Bloco não tem campo `fonte`, e nenhum texto, sub ou dica contém "Source" ou o nome de uma fonte entre parênteses. O `fonte` continua nos arquivos de dados |
| C2 | Seção mostra no máximo `limite` unidades (padrão 5; tabela, 6); o desenhista põe "Show N more" e "Show less" sozinho. Construtor não passa `limite` acima de 6 |
| C3 | Referência longa (regras de pet, todas as habilidades, as famílias, as perguntas da Help) nunca abre sozinha: fica em `duas` (lista e detalhe) ou em `sec` com `aberta = false` |
| C4 | A aba começa pelo que dá para fazer agora, depois o progresso, depois a referência |
| C5 | Estado por `estado` (ícone), nunca por código de texto: proibidos `[v]`, `[x]`, `> ` no começo, `+ ` no começo, `* =` e `*` no fim |
| C6 | `s` até cerca de 60 caracteres, `sub` até cerca de 80; o que passar vai para `dica` (tooltip) |
| C7 | Com "Show all" desligado (`ctx.tudo` falso), o construtor só emite o que `ns.relevante` aprova e o que é do nível atual ou próximo; o resto só com `ctx.tudo` |

### 11.2 Casca (`Janela.lua`), medidas em unidades do `UIParent`

| Parte | Medida e comportamento |
|---|---|
| Janela | `GuiaForeverJanela`, 820 × 600 na primeira vez; `SetResizable(true)` e `SetResizeBounds(700, 460, 1200, 900)`; alça de 16 × 16 no canto inferior direito; tamanho em `GuiaForeverDB.janela = { w, h }`, posição em `GuiaForeverDB.pos` (como hoje); `ns.ui.painel(janela, "janela")`; Esc fecha (`UISpecialFrames`) |
| Cabeçalho | 48 de altura. Ícone do livro (28), "GuiaForever" (fonte `titulo`) e, embaixo, "<nome> · <Classe> · level N" (fonte `menor`, cinza). À direita: as etiquetas de `ns.abasEstado()` (até 3; clique abre `e.aba`, `e.sub`), a busca (150 × 24, `ns.ui.skinBusca`) e o fechar (`ns.ui.skinFechar`) |
| Trilho | 150 de largura, do cabeçalho ao pé, fundo preto a 28% e borda direita preta. Um item de 34 de altura por aba visível (`ns.abaVisivel(id)`, guardada; sem ela, todas): ícone 20, rótulo em fonte `nav`. Ativo: fundo branco a 7% e faixa de 3 px na cor `destaque`. Contador laranja (fonte `numero`) no Now com o número de itens visíveis do painel. No pé, a chave "Show all" (liga `ctx.tudo`; desliga ao fechar a janela, como hoje) |
| Área | à direita do trilho, com rolagem (`UIPanelScrollFrameTemplate` com `ns.ui.skinRolagem`); margens 16 à esquerda, 12 em cima e embaixo, 10 mais a rolagem à direita. `largura` do desenhista = largura da janela − 150 − 44 |
| Atualização | `ns.atualizarJanela()` refaz a aba atual (só com a janela aberta); a rolagem volta ao topo ao trocar de aba ou sub-aba |
| Busca | a partir de 2 letras, roda os construtores de todas as abas e sub-abas, junta os blocos com texto (`s`, `sub`, `nome`, texto das células e das notas) que contêm a busca e mostra um `sec` por aba ("Pet", "Combat · Keys") com um `item` por achado; clique no item abre a aba e a sub-aba dele |

Abas (`ns.abas`, na ordem; o `/guia` confere os ids por ela):

| id | Rótulo | Ícone | Sub-abas (`id` = rótulo) |
|---|---|---|---|
| `agora` | Now | `Interface\Icons\INV_Misc_Book_09` | |
| `pet` | Pet | `Interface\Icons\Ability_Hunter_BeastCall` | |
| `familias` | Families | `Interface\Icons\Ability_Hunter_BeastTaming` | |
| `talentos` | Talents | `Interface\Icons\Ability_Marksmanship` | |
| `combate` | Combat | `Interface\Icons\Ability_ImpalingBolt` | `rotacao` = Rotation, `teclas` = Keys, `armas` = Weapons, `atributos` = Stats |
| `profissoes` | Professions | `Interface\Icons\INV_Misc_Pelt_Wolf_01` | `minhas` = Mine, `zona` = Zone, `treinos` = Trainers |
| `ajuda` | Help | `Interface\Icons\INV_Misc_QuestionMark` | `perguntas` = Questions, `addons` = Addons, `sinais` = Signs |

Cada aba é `{ id, rotulo, icone, subs = { { id, rotulo } } }`. A sub-aba atual fica em `GuiaForeverDB.sub[aba]` (padrão: a primeira). `ns.abrirAba(id, sub)` aceita os ids novos e os antigos por `ns.apelidosAba`, que passa a mapear para `{ aba, sub }`: `nivel` para agora; `pets` para pet; `armas` para combate/armas; `rotacao` para combate/rotacao; `teclas` para combate/teclas; `prof` para profissoes/minhas; `zona` para profissoes/zona; `treinos` para profissoes/treinos; `addons` para ajuda/addons. A tecla J, o botão do livro e o `GuiaForever_AlternarJanela` ficam como estão.

### 11.3 Construtores (`Abas.lua` e módulos)

`ns.abasConstrutores[id] = function(b, ctx)` acrescenta blocos à lista `b`. `ctx = { nivel, classe, tudo, sub, largura, atualizar, abrir }`, em que `atualizar()` refaz a janela e `abrir(aba, sub)` troca de aba. A casca chama o construtor em `xpcall` (erro vira um `vazio` "This tab hit an error (see BugSack)."). Quem constrói:

| Aba ou sub-aba | Função |
|---|---|
| `agora`, `pet`, `talentos`, `combate` (rotacao, armas, atributos), `profissoes` (minhas), `ajuda` (todas) | `Abas.lua` |
| `pet`, seção de upgrades | `ns.blocosProximosRanks(b, ctx)`, em `Familias.lua` (chamada pelo construtor de `pet`) |
| `familias` | `ns.blocosFamilias(b, ctx)`, em `Familias.lua` (o construtor de `Abas.lua` só repassa) |
| `combate/teclas` | `ns.blocosTeclas(b, ctx)`, em `Teclas.lua` |
| `profissoes/zona` | `ns.blocosZona(b, ctx)`, em `Zona.lua` |
| `profissoes/treinos` | `ns.blocosTreinos(b, ctx)`, em `Treinadores.lua` |

O construtor de uma aba com sub-abas emite primeiro o bloco `segs` e depois só a sub-aba `ctx.sub`. Também em `Abas.lua`: `ns.abasEstado()` devolve até 3 etiquetas `{ icone, s, n, cor, aba, sub }` (pontos de talento livres por `ns.pontosTalento()`, laranja quando passam de 0; para o caçador, família, nível e felicidade do pet; a profissão que trava, laranja, ou a primeira profissão) e `ns.abaVisivel(id)` (Pet e Families só para quem tem dados de pet). Toda chamada entre módulos fica guardada (regra 3).

### 11.4 Blocos

Campos comuns opcionais: `dica` (texto ou lista de textos: tooltip, com o `s` do bloco como título) e `aoClicar` (função; a linha ganha realce). `cor` é um nome de `ns.ui.cor`. `icone` é o que `ns.ui.icone` aceita. `botao = { rotulo, acao }` desenha um botão pequeno (22 de altura, largura do texto) à direita da linha.

| `t` | Campos | Como desenha |
|---|---|---|
| `sec` | `s`, `id`, `qtd`, `aberta` (padrão true), `limite` | título em fonte `secao` (maiúsculas) na cor `destaque`, com seta de recolher, `qtd` cinza ao lado e um fio até a borda. Os blocos seguintes, até o próximo `sec`, são da seção. Recolher grava `GuiaForeverDB.secoes[id]`; "Show N more" grava `GuiaForeverDB.mais[id]` |
| `card` | `cor`, `icone`, `s`, `sub`, `tecla`, `botao`, `dica`, `aoClicar` | 42 de altura mínima, faixa de 4 px na `cor`, ícone 28, `s` em fonte `cartao`, `sub` em `menor` cinza, `tecla` desenhada como tecla à direita, depois o botão |
| `item` | `nivel`, `estado`, `nivelTrava`, `icone`, `s`, `sub`, `tecla`, `botao`, `dica`, `apagado`, `destaque`, `aoClicar` | linha de 28 de altura mínima, zebrada na seção: coluna de nível (30, fonte `numero`, caixa a 8%; `""` deixa a coluna vazia; sem `nivel`, sem coluna), ícone de estado (16), ícone (20), `s` e `sub` (cinza) na mesma linha, quebrando se precisar; `tecla` e botão à direita. `apagado` = 55% de opacidade; `destaque` = faixa de 2 px na cor `destaque` |
| `nota` | `s`, `dica` | parágrafo em fonte `texto`, zebrado, quebra de linha livre |
| `vazio` | `s` | uma linha cinza (estado vazio: "Nothing needs you right now.") |
| `tabela` | `id`, `colunas = { { s, largura, alinha } }`, `linhas = { { celulas, apagado, dica, botao } }`, `limite` | cabeçalho em fonte `secao` cinza; linhas de 30, zebradas. Célula: texto ou `{ s, icone, estado, numero, cor }`. `largura` nil divide o que sobra; `alinha` "esq", "centro" ou "dir". Botão de linha numa última coluna automática. `limite` (padrão 6) com "Show N more" |
| `passos` | `lista` (textos) | etiquetas numeradas (número na cor `destaque`) separadas por "›", quebrando para a linha de baixo se não couberem |
| `checklist` | `itens = { { s, feito, sub } }` | etiquetas em linha com o ícone de feito ou de falta |
| `grade` | `titulo`, `teclas = { { k, icone, nome, estado, nivel, dica } ou false }` | `titulo` cinza em fonte `menor`; quadrados de 46 com o ícone e `k` no canto (fonte `tecla`), `nome` embaixo (fonte 11, corta com "..."); `estado` "novo" = contorno na cor `destaque` e a etiqueta NEW; "travado" = ícone cinza e escuro com o `nivel` no centro; `false` = espaço de 10 |
| `regua` | `min`, `max`, `atual`, `rotuloAtual`, `linhas = { { nome, icone, marcas = { { nivel, rank, estado, dica } } } }` | uma faixa de 30 por linha (ícone e nome em 78 de largura), marcas redondas de 18 com o `rank` na posição do `nivel`; `estado` "tem" = cheia na cor `destaque`, "agora" = dourada com brilho, "depois" = vazia cinza; linha tracejada dourada no `atual` com o `rotuloAtual`; régua de níveis embaixo (de 10 em 10) e a legenda "has it / can learn now / later" |
| `perfil` | `icone`, `retrato` (unidade, ex. "pet"), `titulo`, `sub` (lista de linhas), `barras = { { s, valor, max, cor } }`, `etiquetas` (textos) | cartão: retrato redondo de 58 (`SetPortraitTexture` na unidade; sem unidade, o `icone`), título em fonte `titulo`, linhas cinza, até 2 barras de 210 × 16 com o texto por cima, etiquetas à direita |
| `titulo` | `icone`, `s`, `etiquetas` | cabeçalho de detalhe: ícone 40, `s` em fonte `titulo` (20), etiquetas embaixo |
| `etiquetas` | `rotulo`, `lista` | rótulo cinza e etiquetas em linha |
| `segs` | `aba`, `opcoes = { { id, s } }`, `atual` | sub-abas em segmentos colados; a atual com fundo a 9% e sublinhado na cor `destaque`; clique grava `GuiaForeverDB.sub[aba]` e chama `ctx.atualizar()` |
| `duas` | `id`, `lista = { { id, s, sub, icone, marca } }`, `atual`, `detalhe` (blocos), `largura` (padrão 190) | coluna da esquerda com os itens (25 de altura; `marca` = etiqueta na cor `destaque`, ex. "YOUR PET"); o atual realçado com faixa à esquerda; à direita, `detalhe` desenhado pelo mesmo desenhista. Clique grava `GuiaForeverDB.sel[id]` e chama `ctx.atualizar()`; o construtor lê a escolha por `ns.ui.selecionado(id, padrao)` |
| `botao` | `s`, `f` | só o botão pequeno, numa linha (compatível) |

Compatíveis, desenhados no estilo novo: `texto` = `nota`, `cab` = `sec`, `linha` = `item` sem nível, `espaco` = 8 de altura. Construtor da 1.2 não os emite.

Estados (`estado` de `item`, de célula e de `checklist`): "feito" (marca verde, `Interface\RaidFrame\ReadyCheck-Ready`), "falta" (x vermelho, `ReadyCheck-NotReady`), "agora" (ponto dourado), "depois" (ponto cinza), "travado" (cadeado `Interface\Buttons\LockButton-Locked-Up` e o `nivelTrava`). As texturas ficam a conferir no jogo; sem textura, um quadrado na cor.

### 11.5 `ns.ui` (`Visual.lua`)

| API | Contrato |
|---|---|
| `ns.ui.cor(nome)` | r, g, b, a. Nomes: `destaque` (cor da classe por `C_ClassColor.GetClassColor(token)`, reserva verde 0,67/0,83/0,45), `fundo` (0,05/0,05/0,05/0,92), `borda` (0/0/0/1), `zebra` (1/1/1/0,035), `cinza` (0,6), `texto` (1), `verde`, `vermelho`, `laranja`, `amarelo`, `azul` (os de `Agora.lua`), `dourado` (1/0,82/0) |
| `ns.ui.hex(nome)` | o código de cor "\|cffRRGGBB" |
| `ns.ui.fonte(nome)` | nome de objeto de fonte (`CreateFont`, criado uma vez): `titulo` 17, `nav` 15, `cartao` 15, `texto` 14, `menor` 12 (PT Sans Narrow); `secao` 12, `numero` 12, `tecla` 12 com contorno (Expressway). Arquivo pela `LibSharedMedia-3.0` do ElvUI (`Fetch("font", "PT Sans Narrow")` e `"Expressway"`) quando existir; senão `STANDARD_TEXT_FONT`. Sombra preta de 1 px |
| `ns.ui.icone(x)` | número = id de magia (`C_Spell.GetSpellTexture`, reserva `GetSpellTexture`); texto começando por "Interface" = caminho; "macro:<nome>" = ícone de `GetMacroInfo`; nil ou falha = `Interface\Icons\INV_Misc_QuestionMark` |
| `ns.ui.painel(f, estilo)` | estilo "janela", "cartao" ou "campo": com ElvUI, `f:SetTemplate("Transparent")` (janela) ou `f:SetTemplate()`; sem ElvUI ou se falhar, `BackdropTemplate` com `Interface\Buttons\WHITE8X8`, fundo `fundo` e borda `borda` de 1 px |
| `ns.ui.skinBotao(b)`, `skinRolagem(sf)`, `skinBusca(eb)`, `skinCaixa(cb)`, `skinFechar(b)` | ElvUI: `E:GetModule("Skins")` e `S:HandleButton`, `HandleScrollBar` (na barra do `ScrollFrame`), `HandleEditBox`, `HandleCheckBox`, `HandleCloseButton`, cada um em `pcall`; sem ElvUI, aparência plana própria |
| `ns.ui.botao(pai, rotulo)` | botão pequeno (22 de altura, largura do texto + 20), já com a skin |
| `ns.ui.etiqueta(pai)` | quadro de etiqueta com `:Definir(icone, s, n, cor)` (ícone 18, texto, número em fonte `numero`) |
| `ns.ui.tooltip(dono, titulo, dica)` | `GameTooltip` com o título em branco e as linhas da dica; nunca "Source:" |
| `ns.ui.selecionado(id, padrao)` | `GuiaForeverDB.sel[id]` ou `padrao` |
| `ns.ui.desenhar(conteudo, blocos, largura, ctx)` | desenha os blocos de cima para baixo no quadro `conteudo`, reaproveitando quadros de pools guardados no próprio `conteudo`, esconde o que sobrou e devolve a altura total. Cada tipo de bloco tem uma função na tabela de despacho `desenhistas[t]`; tipo desconhecido vira `vazio` com o nome do tipo |

Sem regra nova de combate: nada disso é protegido. Os quadros e as skins só se criam quando a janela abre.

### 11.6 Dados para ícones

`Dicas.lua` (entradas de `magias`) e `Teclas.lua` ganham `id` (id de magia do cliente; o de rank 1 serve, o ícone é o mesmo). Entrada de macro em `Teclas.lua` ganha o `id` da magia principal (sting_Auto = Auto Shot) ou `icone` com caminho; o campo `rot` dá o rótulo da tecla como nas barras do ElvUI ("1", "Q", "S1", "C1", "M4"). Os ids saem da `TrainingData.lua` do Naowh (só o fato, nunca o código) cruzada com o `SpellName` do wago.tools no build do cliente, por `ferramentas\guia\visual\magias.mjs`, que grava `magias.json`.

### 11.7 Chaves novas do `GuiaForeverDB`

`janela = { w, h }`, `sub = { [aba] = sub }`, `mais = { [secId] = true }`, `sel = { [id] = escolha }`. `aba`, `pos`, `secoes`, `botao` e `tecla` ficam como estão.

### 11.8 Banco de prova (`ferramentas\guia\rodar-janela.mjs`)

Roda os `.lua` do `.toc` no fengari (Lua em JavaScript) com a API do jogo simulada num estado fixo (caçador Night Elf 16, javali 16 feliz com Bite 1 e Charge 1, sem grupo, Skinning 75 de 75 e Leatherworking 55 de 100), chama cada aba e sub-aba e confere os blocos contra esta seção (tipos, campos obrigatórios, C1, C2, C5, C6). `--estrito` faz dos tipos compatíveis um erro; `--abas a,b/c` limita; `--desenhar` passa os blocos pelo `ns.ui.desenhar` com quadros simulados, para pegar erro de execução. Grava `ferramentas\guia\visual\real.json` e `real.html` (os blocos desenhados com o CSS dos quadros), que o `renderizar.mjs` fotografa.

### 11.9 Como ficou (2026-11-08, depois da execução)

Executado em três ondas (contrato e esqueletos na sessão principal; T1 a T3; T4 a T7) e um portão final. O que difere do texto acima ou foi acrescentado:

| Onde | O quê |
|---|---|
| `Visual.lua` | o separador de `passos` é ">" (só ASCII); fontes extras `mini` (11) e `detalhe` (20); `ns.ui.botao(pai, rotulo, acao)` e `etiqueta:Definir(icone, s, n, cor, antes)` aceitam um argumento a mais; `nivelTrava` aparece como "Lv N" cinza no fim do texto; só `item`, `card`, `nota`, `linha` e `texto` contam para o `limite`; `skinCaixa` e `skinFechar` sem ElvUI ficam com a aparência da Blizzard |
| `Janela.lua` | `ns.buscarJanela(texto)` devolve os blocos do resultado (a caixa de busca usa a mesma); a busca põe `limite = 30` nas seções dela; `GuiaForeverDB.janela = { w = , h = }`; o ponto do meio (·) vai como `\194\183`; os ajudantes antigos `ns.blocoTexto`, `ns.blocoCabecalho` e `ns.blocoBotao` continuam (compatíveis); sem `ns.ui.desenhar` (jogo aberto antes do `.toc` novo), a janela só mostra o aviso para reiniciar |
| `Abas.lua` | `semFonte` tira de texto de dados o nome de fonte no começo ou entre parênteses; a sub-aba Mine ganhou, a pedido do dono, uma `sec` recolhível por profissão com o roteiro numa `tabela` (`limite = 4`; três colunas nas de fabricar, duas nas de coleta; os passos feitos só com "Show all"), e nas de fabricar uma `sec` por faixa de treino com o total de materiais (`totaisPorFaixa`: o passo entra na faixa em que começa, a faixa atual soma só os passos que terminam acima da perícia, o que está entre parênteses no texto fica de fora; `tabela` de 4 colunas com dois materiais por linha) |
| `Familias.lua` | regras com `e = true` (8 essenciais, marcadas em `ferramentas\guia\pets\textos.json` e passadas pelo `gerar-guia.mjs`); a nota de tier vira etiqueta "Tier: ..." sem o nome; `limpo()` descarta nota ou regra que ainda cite fonte |
| `Teclas.lua` | campos novos `rot`, `id` e `icone`; os ícones do pet (`PET_ATTACK_TEXTURE` e os outros) lidos na hora; a grade mostra todas as teclas, as que ainda não valem com cadeado |
| Dados | ids de magia em `Dicas.lua` (30 entradas); 10 frases de `Dicas.lua` e `Ajuda.lua` e 16 de `ProfissoesA.lua`/`ProfissoesB.lua` reescritas sem o nome da fonte nem a palavra "source"; `checar-dicas.mjs` aceita `id` |
| `Agora.lua` | item pode ter `aoOcultar` (função): o botão direito chama ela em vez de esconder pelo texto. O treino de classe usa isso para guardar as magias puladas em `ns.dbPersonagem().treinoPulado` (id do Naowh ou nome das Dicas), e os dois provedores deixam de emitir as puladas; `ns.agora.pulados()` e `ns.agora.desfazerPulo()` servem a seção Hidden do J. O tooltip do painel não mostra mais "Source:" |
| Banco de prova | `--pular` (cenário do treino pulado: some, não volta com outro treinador, volta só com magia nova, aparece em Hidden, desfaz); `--abrir` (abre a janela, cada aba e sub-aba, os ids antigos e a busca "boar"); o `real.html` respeita o `limite` e põe "Show N more" |

Resultado do portão final: `checar-lua`, `checar-combate`, `checar-dicas`, `checar-ajuda`, `checar-guia`, os 16 e os 13 casos, e `rodar-janela.mjs --estrito --abrir --desenhar` com 14 abas e sub-abas, 29 passos de abertura e `RESUMO erros=0 avisos=0`. Nada disso rodou no jogo ainda.
