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
