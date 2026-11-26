# API de addons do WoW Forever: referência

Conferido em 2026-11-03. Marcas: `[página]` = página aberta pelo WebFetch (resumo do modelo sobre a página); `[busca]` = só o resumo de uma busca web, não a página; `[local]` = lido na máquina. Fato de terceiro é pista até ser conferido no cliente ou no TOC. Fatos de lançamento e de Interface vêm de `forever.md` nesta mesma pasta e não são repetidos aqui.

## 1. Regras (não negociáveis)

- **Secret values e funções protegidas:** a interface moderna (era Midnight) restringe dados de combate. Um addon pode exibir dado de combate, mas não pode decidir nada com ele, e não pode contornar a restrição. `[busca]` (Forever segue as regras do Midnight; a restrição de FrameStrata também vale: `GetFrameStrata` pode devolver secret value em alguns frames.) Fonte da restrição: Endgame Tools e Forever Mastery em `forever.md`.
- **Nada que contorne:** não usar truque, reflexão ou leitura indireta para ler um valor secreto, nem chamar função protegida por caminho alternativo. Se a API não dá o dado, o addon não tem o dado. `[busca]` (regra de projeto; a Blizzard restringe por conta própria).
- **Política da Blizzard:** addon é grátis, sem versão paga, com código legível. `[página]` (Forever Mastery, em `forever.md`). Não há política própria do Forever publicada. `[página]`
- **Automação de comunicação ou marcação:** segundo o Massively OP (15/09), a Blizzard vai restringir addons que automatizam isso. `[página]` (Forever Mastery). Tratar como restrição prevista, não como regra fechada.
- **Dúvida sobre se algo é permitido:** perguntar antes de implementar. Não supor.

## 2. Convenções de TOC do Forever

Todos `[página]` (Forever Mastery, lido em 2026-11-03, em `forever.md`):

- **Sufixo de arquivo só do Forever:** `<Nome>_Forever.toc` ou `<Nome>_Camelot.toc` (também `-Forever` e `-Camelot`, como o `Get-TocDoForever` da biblioteca aceita). Quando existe, ele vence o `<Nome>.toc` comum.
- **Marcador dentro de um TOC comum:** `[AllowLoadGameType camelot]` numa linha `## Title:`, `## AllowLoadGameType:` ou em qualquer linha. A biblioteca lê esses tokens (`Get-TocInfo`).
- **Lista de Interface:** `## Interface: 16001` (versão 1.60.1). O Classic Era é 11509; addon só do Classic Era não carrega no Forever. O número pode mudar no lançamento: conferir de novo depois do patch. `[página]`
- **Conferir a Interface no jogo:** `/dump select(4, GetBuildInfo())`. `[página]` (Endgame Tools)
- **Pasta de addons:** `World of Warcraft\_forever_\Interface\AddOns`. `[página]` (Endgame Tools). Um guia escreve `forever\` sem os sublinhados: conflito a conferir na instalação. `[busca]` (Mobalytics)
- **Interface vs. TOC do cliente:** a Interface do `.toc` tem de bater com a do cliente, senão o jogo não carrega o addon. Por isso o `Test-AddonForever` da biblioteca recusa TOC sem a Interface 16001.

## 3. Onde ler a API

- **Documentação de API, warcraft.wiki.gg:** `https://warcraft.wiki.gg/wiki/World_of_Warcraft_API`. `[página]`, 2026-11-03: é a documentação de API para addons e macros, com Lua API, Widget API, Events, CVars, Namespaces (ex.: `C_...`) e índice de sistemas. A página tinha ~692 mil caracteres; só o começo foi lido. A própria página diz estar atualizada até o PTR do Patch 12.1.5, e não cita Forever. Não encontrei na leitura a seção de secret values nem a de TOC, e o número 16001 não aparece nela. `[página]`
- **Mudanças de API por patch:** `https://warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes/notes` (aparece na busca; não aberta). `[busca]`
- **Espelho do código da interface da Blizzard no GitHub:** `https://github.com/Gethe/wow-ui-source`, um espelho em git do código da UI (uma branch por cliente, ex.: live, ptr, beta). `[busca]`. **Não achei na busca uma branch "forever" nesse repo.** Não conferido na lista de branches (não abri o GitHub).
- **Código da interface do Forever:** `Ketho/wow-ui-source-forever`, branch padrão `forever`. `[página]`, 2026-11-05 (lido pelo `gh`): o último commit é de 2026-09-24 com a mensagem "1.60.1 (70009)", ou seja, um build do beta, anterior ao cliente instalado (1.60.1.70790 em 05/11); o TOC do `Blizzard_MacroUI` não declara `## Interface`. Leitura sem clonar: `gh api -H "Accept: application/vnd.github.raw" "repos/Ketho/wow-ui-source-forever/contents/<caminho>?ref=forever"`. A documentação gerada (`Blizzard_APIDocumentationGenerated`) não lista funções globais antigas como `CreateMacro`, `SetBindingMacro`, `SaveBindings` e `GetBindingAction`; o uso real se acha com `gh search code "<função> repo:Ketho/wow-ui-source-forever"` (ex.: `SaveBindings(GetCurrentBindingSet())`). Conferido ali: `Constants.MacroConsts` (120 macros da conta e 30 por personagem), `Enum.BindingSet` (Character = 2) e os ícones do pet (`PET_ATTACK_TEXTURE` e outros, em `Blizzard_ActionBar/Shared/PetActionBar.lua`). Que uma função existe no cliente é inferência pelo uso no código da Blizzard até rodar no jogo.
- **Anotações para o editor (VS Code):** extensão `Ketho.wow-api` ("WoW API", LuaLS; loads quando a pasta tem um `.toc`). `[busca]` (Marketplace e GitHub `Ketho/vscode-wow-api`, MIT segundo agregador). Não instalada nesta sessão: não confirmei se o cadastro já traz as APIs do Forever.

## 3a. ElvUI 16.01 por dentro (para configurar sem abrir o jogo)

Tudo `[local]`, lido no código instalado em `Interface\AddOns\ElvUI` em 2026-11-05 e usado pelo addon próprio UIForever. Não foi testado no jogo ainda (ver a pendência em `jogadores\bruno\estado\estado.md`).

- **Ordem de carga:** o `E:OnInitialize` roda o `PrepDB` (que trabalha numa cópia), e o `E:InitDB` só roda dentro do `E:Initialize`, chamado pelo `OnEnable` no `PLAYER_LOGIN`. Por isso um addon que depende do ElvUI pode gravar direto no `ElvDB` cru no próprio `ADDON_LOADED`, e o ElvUI monta a tela já com esses valores.
- **Perfil:** a chave é `E.mynameRealm` (ex.: `profileKeys["Hexumlite Bull"] = "Hexumlite Bull"`), e o AceDB usa `defaultProfile = true`. O `private.install_complete` (16.01 no Hexumlite) é o que faz o assistente de instalação não abrir; copiar o private de um personagem que já tem essa marca faz o personagem novo pular o assistente.
- **Nomes das configurações:** `chat.panelColor` (cor e alfa do fundo dos chats), `chat.separateSizes` com `panelHeight` e `panelHeightRight`, aplicados por `CH:PositionChats()`; `LeftChatPanelFaded` e `RightChatPanelFaded` escondem os chats; `datatexts.panels.<painel>.backdrop`; `unitframe.units.<unidade>.portrait` com `enable`, `style = '3D'`, `width` e `overlay`; `general.minimap.scale`, aplicado por `M:UpdateSettings()` via `MinimapCluster:SetScale`. O `E:SetupChat(true)` roda o passo de chat do assistente. O ElvUI não tem alça para mudar a altura do chat.
- **Fontes** (`[local]`, 2026-11-06, `Media\SharedMedia.lua` e `Defaults\Profile.lua`): o ElvUI registra no LibSharedMedia as fontes Action Man, Continuum Medium, Die Die Die!, PT Sans Narrow, Expressway, Homespun e Invisible (arquivos em `ElvUI\Game\Shared\Media\Fonts`); o LSM soma as do jogo (Friz Quadrata TT, Arial Narrow, Morpheus, Skurri). No padrão, `unitframe.font` (tamanho 10, `MONOCHROMEOUTLINE`) e as barras de ação (`actionbar.font` e, por barra, `hotkeyFont` e `countFont`) usam Homespun (fonte de pixel), assim como a contagem das auras perto do minimapa e das bolsas do ElvUI. `general.font`, chat, tooltip, placas de nome e a contagem das auras nos quadros usam PT Sans Narrow. O `P.cooldown.*` (números de recarga), os textos do `general.fonts` e o `private.general.dmgfont` (números de dano) usam Expressway. O perfil do dono não tinha nenhuma chave de fonte gravada em 06/11, ou seja, tudo no padrão. `general.UIScale` está em 0,7, e as bolsas do ElvUI estão desligadas (`private.bags.enable = false`, por causa do Baganator). No quadro, o nome, a vida, o recurso e a barra de lançamento dividem o `unitframe.font` (`UF:Configure_FontString`); só os `customTexts` (chaves `text_format`, `attachTextTo`, `justifyH`, `xOffset`, `yOffset`, `font`, `size`, `fontOutline` e `enable`) e o `castbar.customTimeFont` têm fonte própria. As fontes de número da Blizzard (`NumberFontNormal` e mais 25, que o Baganator usa nas contagens) recebem a fonte geral em `E:UpdateBlizzardFonts`, chamada no `E:Initialize`.
- **Teclas das barras:** barra 1 = `ACTIONBUTTON`, barra 2 = `ELVUIBAR2BUTTON`, barra 3 = `MULTIACTIONBAR3BUTTON`, barra 6 = `MULTIACTIONBAR1BUTTON`, barra do pet = `BONUSACTIONBUTTON`. Slots de ação: barra 1 = 1 a 12, barra 2 = 13 a 24, barra 3 = 25 a 36, barra 6 = 61 a 72.

- **Barra de experiência** (`[página]`, código da tag `v16.01` do `github.com/tukui-org/ElvUI`, lido pelo `gh` em 2026-11-05; a versão bate com a instalada): a barra de XP do ElvUI já mostra a XP das quests do log, ligada por padrão (`databars.experience.showQuestXP = true`, com `questTrackedOnly`, `questCompletedOnly` e `questCurrentZoneOnly` desligados). Ela aparece como um trecho na cor `databars.colors.quest` (verde a 40%) e no tooltip como "Quest Log XP" e "Remaining". A barra fica no quadro `ElvUI_ExperienceBarHolder` (mover `ExperienceBarMover`, padrão `BOTTOM,ElvUIParent,BOTTOM,0,44`), que continua posicionado com a barra desligada (`E:DisableMover` só tira o mover da lista). O `AB:DisableBlizzard`, das barras de ação, chama `StatusTrackingBarManager:Kill()`, que tira os eventos do quadro e o põe num pai escondido. Por isso, com as barras de ação do ElvUI ligadas, a barra de experiência da Blizzard some.

## 3b. CVars das opções do menu

- **Onde ficam:** as opções de interface não estão no `WTF\Config.wtf` (que guarda gráficos, som e cache), e sim no `WTF\Account\<conta>\config-cache.wtf` (conta: `statusText`, `nameplateShowFriendlyNpcs`, `nameplateShowEnemyMinus`) e no `config-cache.wtf` da pasta do personagem (`nameplateMaxDistance` e as outras distâncias e escalas de placa). CVar no valor padrão não aparece em nenhum dos três. `[local]`, 2026-11-05. Por isso o `wtf-cvar.ps1` (que grava no `Config.wtf`) não é o caminho para elas (não testado se o cliente leria dali, e os `config-cache.wtf` são cache da configuração guardada no servidor): o caminho é `SetCVar` num addon próprio (o UIForever faz isso, seção 5 do `Config.lua`) ou o menu do jogo.
- **Auto loot:** `autoLootDefault`, caixa "Auto Loot" em Options > Controls (`Blizzard_SettingsDefinitions_Frame/Controls.lua`). O Leatrix Plus liga o mesmo CVar com `/ltp al`. `[página]` (Ketho/wow-ui-source-forever, build 70009, lido pelo `gh` em 2026-11-05)
- **Nomes de NPC:** o menu "NPC Names" (Options > Nameplates) é um seletor que grava cinco CVars: `UnitNameNPC`, `UnitNameHostleNPC` (com o erro de grafia da Blizzard), `UnitNameInteractiveNPC`, `UnitNameFriendlySpecialNPCName` e `ShowQuestUnitCircles`. Opções: 1 = só NPCs rastreados, 2 = hostis, 3 = hostis e interativos, 4 = todos os NPCs (`UnitNameNPC` = 1 e os outros três em 0), 5 = nenhum. O padrão do Forever (`Camelot/NameplatesOverrides.lua`) é 5 no preset de experiência Classic e 3 nos outros. Não existe opção "todo inimigo, de qualquer cor": a 4 é a única que não filtra por reação, e traz os amigáveis junto; o dono relatou em 05/11 que, no padrão, os inimigos cinza ficavam sem nome (o que exatamente o `UnitNameHostleNPC` cobre não está no código). `[página]` (mesmo arquivo `Nameplates.lua`, 2026-11-05)
- **Magia nova na barra:** `AutoPushSpellToActionBar` (padrão 1) faz o jogo pôr sozinho a magia aprendida na barra; é por personagem (`CVars.lua` do BlizzardInterfaceResources, branch `forever`: account falso, character verdadeiro), e o evento `SPELL_PUSHED_TO_ACTIONBAR` existe na lista. `[página]`, cópia local das listas, lida em 2026-11-08. O UIForever 0.7.0 desliga só no paladino.
- **Buff do jogador fora de combate:** `C_UnitAuras.GetAuraDataBySpellName` e `GetPlayerAuraBySpellID` estão na lista do Forever e só são secretas sob restrição de combate (seção 3d). O GuiaForever 1.3 lê o Righteous Fury só fora de combate, com `issecretvalue` (exceção única da regra 5 do `ARQUITETURA.md`, cobrada pelo `checar-combate.mjs`). Não testado no jogo.
- **Placas de inimigo:** `nameplateShowEnemies` (tecla `NAMEPLATES`), `nameplateShowAll` (sempre, fora de combate também) e `nameplateShowEnemyMinus`. O Leatrix Plus, com "Combat plates" ligado, liga e desliga `nameplateShowEnemies` a cada entrada e saída de combate (desligado no dono em 2026-11-05). `[página]` e `[local]`
- **Gráficos (menu Options > System > Graphics):** as quatro barras da seção Graphics Quality (`graphicsQuality`, `graphicsViewDistance`, `graphicsEnvironmentDetail`, `graphicsGroundClutter`) vão de 0 a 9 no CVar e mostram o número mais 1 (`IncrementByOne`), então CVar 8 aparece como 9. Mexer na barra de qualidade sobrescreve todos os itens de baixo, por isso ela vem primeiro. Escalas dos seletores: sombras, SSAO, efeitos de profundidade e de computação com 2 = "Good"; partículas 2 = "Fair"; líquidos 0 a 3 (3 = "High"); textura 0 a 2 (2 = "High"); borda e iluminação secundária 1 = "Good"; densidade de magias 0 = "Essential", 1 = "Reduced", 2 = "Everything". O "Bloom Intensity" do menu é outro CVar (`graphicsBloomUserMult`, Low ou High, só com `IsLinearEnabledOnStart`); `bloomUserMult` e `groundEffectDensity` não têm controle no menu. A aba de raide só vale com `RAIDsettingsEnabled`, padrão 0 (desligada no Avell, que não grava o CVar). Padrões: `vsync` 1, `GxApi` auto, `groundEffectDensity` 16, `bloomUserMult` 1. `[página]` (`Blizzard_SettingsDefinitions_Shared/Graphics.lua`, `Graphics.xml` e `Blizzard_Settings_Shared/Mainline/GraphicsOverrides.lua` do espelho Ketho, build 70009; padrões do `CVars.lua` do BlizzardInterfaceResources), lidos pelo `gh` em 2026-11-08, mais o `Config.wtf` do Avell `[local]`
- **Nomes em português (ptBR) dos gráficos:** Opções > Sistema > Gráficos; "Qualidade gráfica" com as abas "Base" e "Raide e Campo de Batalha"; "Qualidade básica do jogo", "Qualidade das sombras", "Detalhes de líquidos" (ou "Detalhes de líquidos legados" quando há água PBR, com "Detalhes de líquidos com PBR" ao lado), "Densidade de partículas", "SSAO", "Efeitos de profundidade", "Efeitos de computação", "Modo borda", "Resolução da textura", "Densidade de Feitiços", "Texturas projetadas", "Iluminação secundária", "Distância de visão", "Detalhes do ambiente", "Detalhe do solo", "Modo de exibição" ("Tela cheia (Modo Janela)"), "Sinc. vertical", "API Gráfica". Níveis: Baixo, Médio (Fair), Bom (Good), Alto, Ultra; Essencial, Reduzida, Tudo; Ativado, Desativado. `[página]` (`Resources/GlobalStrings/ptBR.lua` do BlizzardInterfaceResources, branch `forever`, build 70532, lido pelo `gh` em 2026-11-08; não visto no cliente em português)

## 3c. Barra de experiência e quests no Forever

`[página]`: espelho `Ketho/wow-ui-source-forever`, branch `forever`, lido pelo `gh` em 2026-11-05. O espelho é do build 70009, mais velho que o cliente, então os fatos abaixo são do espelho.

- **A barra é a moderna, não a roxa do Classic.** O TOC do `Blizzard_StatusTrackingBar` carrega, no Forever (`camelot`), os arquivos `[Family]`, que são os do `Mainline`: `ExpStatusBarTemplate`, o atlas `UI-HUD-ExperienceBar-*`, o marcador e a previsão do descanso. O container é o `MainStatusTrackingBarContainer`, do Edit Mode. As constantes do `Camelot` dão o tamanho: container de 1192 × 17, 20 segmentos e barra 3 menor, em (1, 2).
- **Quests:** o Forever usa a API moderna do diário. Existem `C_QuestLog.GetNumQuestLogEntries`, `C_QuestLog.GetInfo(i)` (com `isHeader`, `isHidden` e `questID`), `C_QuestLog.ReadyForTurnIn(questID)` e `GetQuestLogRewardXP(questID)`, que devolve a XP total e a base, como no `QuestUtils.lua` do `Mainline`. O `QuestInfo.lua` que carrega é o `[Family]` (`mainline`), e não o `Vanilla`.
- **Atlas como textura de barra:** a Blizzard passa nome de atlas direto ao `StatusBar:SetStatusBarTexture` (`GradualAnimatedStatusBarMixin:SetBarTexture`).

## 3d. Timers no Forever: valores secretos, Swing Timer e Cooldown Manager

`[página]`: espelho `Ketho/wow-ui-source-forever`, branch `forever` (build 70009), e ElvUI na tag `v16.01`, lidos pelo `gh` em 2026-11-05. Nada foi testado no jogo.

- **O que vira secreto em combate:** na documentação gerada (`Blizzard_APIDocumentationGenerated`), `UnitAttackSpeed`, `UnitRangedDamage`, `UnitRangedAttackPower` e `GetUnitSpeed` levam `SecretWhenUnitStatsRestricted`; `C_Spell.GetSpellCooldown` e `GetSpellCharges` levam `SecretWhenCooldownsRestricted`; `C_UnitAuras.GetAuraDataByIndex`, `GetAuraDataBySpellName` e `GetPlayerAuraBySpellID` levam `SecretWhenUnitAuraRestricted`. Pelo `SecretPredicatesDocumentation.lua`, as duas últimas restrições valem "quando há restrição de combate, encontro, chave ou PvP" (uma magia pode ser marcada como nunca ou sempre secreta), e as de estatística, "quando o acesso a estatísticas da unidade normalmente seria secreto". Já `UnitCastingInfo` leva `SecretWhenUnitSpellCastRestricted`, que só vale para unidade que não seja o jogador ou o pet. Consequência: um timer de Auto Shot feito por addon não consegue ler a velocidade do tiro em combate.
- **Swing Timer nativo:** o addon `Blizzard_SwingTimer` carrega só no Forever (`## AllowLoadGameType: camelot`). Ele liga pela CVar `showSwingTimer`, caixa "Swing Timer" em Options > Advanced (`Blizzard_SettingsDefinitions_Frame/AdvancedOptions.lua`, quando `InterfaceOverrides.HasSwingTimer()`). Há três barras, `SwingTimerMainHandFrame`, `SwingTimerOffHandFrame` e `SwingTimerRangedFrame` (`Enum.PlayerSwingType.Ranged`, o Auto Shot), movidas pelo evento `PLAYER_SWING` (duração e tipo, vindos do cliente). Cada barra só aparece com a arma certa (`UnitAttackSpeed`), e fica opaca e com texto vermelho fora de alcance (`PLAYER_SWING_RANGE_UPDATE`). São sistema do Edit Mode (`Enum.EditModeSystem.SwingTimer`). No preset (`Blizzard_EditMode/Mainline/EditModePresetLayouts.lua`), as três ficam com visibilidade "Always", 213 × 15, título e tempo ligados, empilhadas pelo container de quadros de baixo.
- **ElvUI e o Swing Timer:** o ElvUI 16.01 só aplica o visual dele (`ElvUI/Game/Shared/Skins/SwingTimer.lua`: tira as texturas e pinta a barra na cor da classe), com `private.skins.blizzard.swingTimer = true` por padrão. Ele não esconde as barras.
- **Cooldown Manager nativo:** o `Blizzard_CooldownViewer` carrega no Forever (`## AllowLoadGameType: standard, camelot`). Ele liga pela CVar `cooldownViewerEnabled`, caixa "Enable Cooldown Manager" em Options > Advanced. As magias e os buffs acompanhados se escolhem no painel dele, dentro do jogo. O ElvUI 16.01 tem skin para ele, desligada por padrão (`private.skins.blizzard.cooldownManager = false`).
- **Número da recarga nos botões:** o ElvUI 16.01 usa o contador nativo dos quadros de recarga (`ElvUI/Game/Shared/General/Cooldowns.lua`: `SetHideCountdownNumbers`, `SetCountdownFormatter`). A CVar da Blizzard para o mesmo fim é `countdownForCooldowns` (`Blizzard_SettingsDefinitions_Frame/ActionBars.lua`).
- **Sem versão Forever:** WeakAuras e OmniCC (seção da `forever.md`).

## 3e. Listas oficiais, janelas da Blizzard, treinador de pet e pet (2026-11-06)

Estes fatos foram lidos em 2026-11-06 e 2026-11-07, para o GuiaForever 1.0 (`modder\addons-proprios\GuiaForever\ARQUITETURA.md`). Nada foi testado no jogo. Marcas: `[página]` é o espelho `Ketho/wow-ui-source-forever` (branch `forever`, build 70009) ou o repositório `Ketho/BlizzardInterfaceResources` (branch `forever`, último commit no build 1.60.1.70532, de 2026-10-21), lidos pelo `gh`; `[local]` são arquivos instalados no Avell.

### Listas da API

Lista oficial de nomes `[página]`: o `Ketho/BlizzardInterfaceResources`, branch `forever`, pasta `Resources`, tem `GlobalAPI.lua` (funções), `FrameXML.lua` (funções da interface), `Events.lua`, `Templates.lua`, `CVars.lua`, `LuaEnum.lua`, `Mixins.lua`, `Frames.lua` e `AtlasInfo.lua`. Uma cópia fica em `modder\ferramentas\guia\api-forever\`, fora do git; o comando para baixar está em `api-forever-baixar.txt`. É a base do `checar-combate.mjs`.

Duas funções do Classic **não existem** no Forever `[página]`: `IsPlayerSpell` (use `C_SpellBook.IsSpellKnown(spellID, banco)`) e `UnitCharacterPoints` (use `C_ClassTalents.GetActiveConfigID`, `C_Traits.GetConfigInfo(...).treeIDs` e `C_Traits.GetTreeCurrencyInfo(config, árvore, false)[1].quantity`). Também não estão na lista os eventos `LEARNED_SPELL_IN_TAB` (registro morto no UIForever até a 0.5.0) e a global `GetActionText` (há `C_ActionBar.GetActionText`). A global, mesmo fora da lista, funciona no jogo pelo que se infere do diário do UIForever, que registra macros postas pelo nome (inferência, n=1; não houve teste direto da função).

### Janelas da Blizzard

Margem das janelas `[página]`: vendedor, missão, conversa, treinador, talentos, livro e personagem abrem a partir de uma margem pública, `SetUIPanelLayoutAttribute("LEFT_OFFSET", x)`, que vale 16 por padrão (`Blizzard_UIParentPanelManager/Shared/UIPanelLayoutFrame.lua`). O `FramePositionDelegate:UpdateUIPanelPositions` (`UIParentPanelManager.lua:616-725`) põe o painel da esquerda nessa margem e o do centro logo depois dele. O addon Skinner usa o mesmo setter para o `TOP_OFFSET`. O UIForever 0.6.0 usa para abrir as janelas à direita do RestedXP.

### Treinador de pet

Modo pet do treinador `[página]`: não há `CraftFrame` nem `GetCraftInfo`. O treinador de pet reusa o `ClassTrainerFrame` em modo pet (`Blizzard_TrainerUI/Mainline/Blizzard_TrainerUI.lua:453-745`), com título e retrato do pet e custo em pontos de treino. `C_Trainer.GetTrainerType()` devolve `Enum.TrainerType`, e Pet é 3. Cada linha passa pela global `ClassTrainerFrame_InitServiceButton(button, elementData)`, que aceita `hooksecurefunc`. Os eventos são `TRAINER_SHOW`, `TRAINER_UPDATE`, `TRAINER_CLOSED` e `UNIT_PET_TRAINING_POINTS`.

### Pet

API do pet `[página]`, de `PetInfoDocumentation.lua`, nenhuma com `SecretWhen`:

| Função | Retorno |
|---|---|
| `C_PetInfo.GetPetHappiness()` | felicidade (1 a 3), % de dano, taxa de lealdade |
| `C_PetInfo.GetPetFoodTypes()` | lista de textos |
| `C_PetInfo.CanPetEatItem(itemID)` | booleano |
| `C_PetInfo.GetPetTrainingPoints()` | total, usados |
| `C_PetInfo.GetSpellForPetAction(actionID)` | id da magia |

Os eventos são `UNIT_HAPPINESS` e `PET_UI_UPDATE`. O ElvUI esconde o `PetFrame` da Blizzard, então a felicidade tem de ser mostrada no `ElvUF_Pet` (UIForever 0.5.0).

### Tooltips e setas

Tooltips e setas `[página]`: o `TooltipDataProcessor.AddTooltipPostCall` existe no Forever e cobre `SetTrainerService`, `SetSpellBookItem` e `SetPetAction`; ninguém usa `OnTooltipSetSpell`. A seta nativa, sem TomTom, sai de `C_Map.SetUserWaypoint` mais `C_SuperTrack.SetSuperTrackedUserWaypoint`.

### Alvo elite, mapa e tags de recurso (lido em 2026-11-08)

Lido `[página]` no espelho `Ketho/wow-ui-source-forever`. `UnitClassification` e `UnitIsBossMob` não têm `SecretWhen` no `UnitDocumentation.lua`, então o retorno nunca é secreto e um addon pode decidir com ele em combate. O quadro de alvo do Forever escolhe a arte em `Blizzard_UnitFrame\Camelot\TargetFrameUtils.lua` (`GetBossPortraitFrameData`): chefe usa `UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold-Winged` (11, -4), raro e raro elite usam `...-Boss-Rare-Silver-Winged` (8, -7) e elite usa `...-Boss-Gold` (0, 1). Os números são o deslocamento do canto de cima à direita em relação ao container, e o retrato é um círculo de 58 em (-26, -19). Mapa: o M abre maximizado ou em janela pelo CVar `miniWorldMap` (`QuestLogOwnerMixin`), salvo quando a regra `Enum.GameRule.MaximizeWorldMapDisabled` está ativa; no Forever o botão de maximizar aparece (print do dono, 2026-11-08), então a regra não está ativa. Barra de XP: `STATUS_BAR_CONTAINER_WIDTH_GAMEPAD` e `STATUS_BAR_NUM_SEGMENTS_GAMEPAD` são a metade dos normais (`Camelot\StatusTrackingBarConstants.lua`). ElvUI 16.01 `[local]`: no modo moderno, `Tags\Modern.lua` tem `health:current:longvalue`, `power:current:longvalue` e `power:max:longvalue`.

### Talentos e RestedXP

Os talentos são uma árvore nova `[página]`: não há `Blizzard_TalentUI`. A árvore é o `PlayerSpellsFrame.TalentsFrame` (`Blizzard_PlayerSpells`, carregado só quando aberto), com botões por nó. Por isso o guia de talentos do RestedXP, que só conhece o `PlayerTalentFrame`, não funciona no Forever (`[local]`: `RXPGuides/Talents.lua:214-235`).

### NPCs no Naowh

Posições de NPC `[local]`: `NaowhForever\Shared\Game\Towns.lua` tem `ns.TownNPCs[uiMapID] = { { x, y, categoria, nome, título, classe, lado } }`, de 0 a 100, com treinadores de pet, estábulos e vendedores de comida do Forever. Os de Dolanaar, em Teldrassil (1438), são Keldas, "Pet Trainer", em 56.8 59.8, e Dazalar, "Hunter Trainer", em 56.7 59.5. Os de Darnassus (1457) são Jocaste (40.4 8.6), Silvaria, "Pet Trainer" (42.5 9.2), e Jaeana, "Meat Vendor" (64.5 71.7). A licença do Naowh é "all rights reserved": o GuiaForever lê esses dados em tempo de execução e não copia código.

## 3f. Medidor de dano, threat e valores secretos em combate (2026-11-16)

`[página]`: documentação gerada do espelho `Ketho/wow-ui-source-forever`, branch `forever`, no commit `bebcb6bf` (build 70938, de 2026-11-13), lida pelo `gh` em 2026-11-16; a pasta e a documentação do medidor mudaram pela última vez no build 70707. Uma cópia fica em `modder\ferramentas\guia\api-forever\doc\`, fora do git (comando em `api-forever-baixar.txt`), e o `conferir-doc.mjs` confere 30 âncoras dela a cada build novo. `[local]`: listas da API (build 70532), ElvUI 16.01 instalado e arquivos do WTF. Nada desta seção foi testado no jogo. Ela sustenta o addon `CentralForever` (`modder\addons-proprios\CentralForever\CONTRATO.md`).

- **Não há log de combate para addon:** `Events.lua` lista `COMBAT_LOG_EVENT_UNFILTERED`, mas `GlobalAPI.lua` não tem `CombatLogGetCurrentEventInfo`; do log só existe `C_CombatLog.*` (inclui `IsCombatLogRestricted`). O datatext de DPS do ElvUI nem registra o evento no ramo moderno (`ElvUI\Game\Shared\Modules\DataTexts\DPS.lua:67`) e fica em 0 no Forever (linha lida por subagente). `[local]`
- **Dano e DPS saem do medidor nativo, `C_DamageMeter`** (`DamageMeterDocumentation.lua`): `GetCombatSessionFromType(sessionType, type)` e `GetCombatSessionFromID(sessionID, type)` devolvem `{ combatSources, maxAmount, totalAmount, durationSeconds }`; cada fonte tem `name`, `classFilename`, `totalAmount`, `amountPerSecond`, `isLocalPlayer` e outros. As duas levam `SecretWhenInCombat = true` (linhas 23 e 41), definido como "produzem valores secretos quando as restrições de combate para addons estão em vigor" (`SecretPredicatesDocumentation.lua:95-97`). `GetSessionDurationSeconds(sessionType)` (linha 97) não tem marca de segredo. Por campo: `isLocalPlayer`, `classFilename`, `classification` e `deathRecapID` são `NeverSecret`; `name` e `sourceGUID`, `ConditionalSecret`; `specIconID`, `SecretValue` (linhas 199 a 209). Sessões: `Enum.DamageMeterSessionType` Overall 0, Current 1, Expired 2; tipo `Enum.DamageMeterType.DamageDone` 0. Eventos: `DAMAGE_METER_COMBAT_SESSION_UPDATED(type, sessionID)` (dois por atualização: o da Overall com `sessionID` 0 e o da sessão atual), `DAMAGE_METER_CURRENT_SESSION_UPDATED` e `DAMAGE_METER_RESET`, sem argumentos. Os argumentos dessas funções são `AllowedWhenUntainted`: um addon não pode passar a elas um valor secreto. `[página]`
- **A janela nativa só depende do CVar para aparecer:** `Blizzard_DamageMeter` carrega no Forever (`## AllowLoadGameType: standard, camelot`). `DamageMeterMixin:ShouldBeShown()` testa o CVar `damageMeterEnabled` (padrão 0, por personagem), depois `C_DamageMeter.IsDamageMeterAvailable()` e a visibilidade do Edit Mode (Always, InCombat, Hidden, InGroup). Nos arquivos da janela (`DamageMeter.lua`, `DamageMeterSessionWindow.lua`, `DamageMeterEntry.lua`), o CVar só aparece ali e no callback que reavalia a visibilidade quando ele muda (`DamageMeter.lua:74` e `:171`). O Details (`Tercioo/Details-Damage-Meter`, `core/parser_nocleu.lua:718-722`) e o QUI (`zol-wow/QUI`, `QUI_DamageMeter/damage_meter/damage_meter.lua:3869-3875`) põem o CVar em 0 enquanto mostram os próprios números lidos da mesma API, o que indica que o motor coleta com a janela desligada. Isso é leitura do código deles para o cliente moderno, não teste no Forever: o diário da CentralForever confirma (campo `coletaSemJanela`). No WTF, só o Hexumlite tinha `damageMeterEnabled "1"` em 2026-11-16. `[página]` e `[local]`
- **Threat tem dois predicados, por função** (`UnitDocumentation.lua`): `UnitThreatSituation(unit, mobUnit?)` (linha 3279, estado 0 a 3) e `UnitThreatLeadSituation(unit, mobUnit)` (linha 3244: "0 a 3, o quanto a unidade está acima do segundo; quem não é o primeiro recebe sempre vermelho") levam `SecretWhenUnitThreatStateRestricted`. `UnitDetailedThreatSituation(unit, mobUnit)` (linha 1086: `isTanking`, `status`, `scaledPercentage`, `rawPercentage`, `rawThreat`; `MayReturnNothing`) e `UnitThreatPercentageOfLead` (linha 3262) levam `SecretWhenUnitThreatValuesRestricted`, e isso vale para a função inteira, inclusive o `status` que ela devolve. Pelo texto dos predicados (`SecretPredicatesDocumentation.lua:160-167`), consulta de jogador, pet ou aliado contra o alvo "em geral não é secreta" no estado, inclusive contra chefe; nos valores, só contra alvo que não é chefe. Por isso o estado se lê de `UnitThreatSituation` e a porcentagem de `UnitDetailedThreatSituation`. `UnitThreatSituation(unit)` sem mob devolve o pior estado da unidade contra qualquer inimigo. `GetThreatStatusColor` recusa argumento secreto vindo de addon. `UnitExists`, `UnitCanAttack`, `UnitAffectingCombat`, `UnitIsDeadOrGhost`, `UnitClassification` e `UnitIsBossMob` não têm marca de segredo; `UnitName` leva `SecretWhenUnitNameIdentityRestricted` (legível para jogador, grupo e pets do grupo; secreto em token composto como `targettarget`). `[página]`
- **O que um addon pode fazer com um valor secreto:** aceitam segredo vindo de addon (`SecretArguments = "AllowedWhenTainted"`) `FontString:SetText` e `SetFormattedText` (`SimpleFontStringAPIDocumentation.lua:664` e `:539`), `StatusBar:SetValue`, `SetMinMaxValues` e `SetStatusBarColor` (`SimpleStatusBarAPIDocumentation.lua:355`, `:229`, `:282`), `Region:SetAlphaFromBoolean(valor, alfaSeVerdadeiro, alfaSeFalso)` e `SetVertexColorFromBoolean`, `AbbreviateNumbers(number, options)` e `AbbreviateLargeNumbers` (`LocalizationDocumentation.lua:26` e `:10`), `C_StringUtil.RoundToNearestString(number)` e `C_StringUtil.WrapString(infix, prefix, suffix)` (`StringUtilDocumentation.lua:138` e `:204`). Recusam (`AllowedWhenUntainted`): `SetShown`, `SetWidth`, `SetHeight`, `SetSize`, `SetPoint`. O objeto que recebeu segredo passa a devolver segredo em `GetText`, `GetValue` e `GetAlpha` (aspectos `Text`, `BarValue` e `Alpha`). `CreateAbbreviateConfig` tem a pré-condição `RequiresRestrictedAbbreviationBreakpoints` (falha com erro) e não aceita segredo. O que não está na documentação e só o cliente responde: se aritmética, comparação, `tostring` e `string.format` com segredo dão erro em código de addon (a CentralForever nunca faz nenhuma delas). `[página]`
- **Restrições de addon:** `C_RestrictedActions.IsAddOnRestrictionActive(type)` e `GetAddOnRestrictionState(type)`; evento `ADDON_RESTRICTION_STATE_CHANGED(type, state)`, disparado antes de a restrição entrar e depois de sair. Tipos (`Enum.AddOnRestrictionType`): Combat 0, Encounter 1, ChallengeMode 2, PvPMatch 3, Map 4, Chat 5. Estados: Inactive 0, Activating 1, Active 2. `IsAddOnRestrictionActive` devolve sempre falso durante o despacho do evento. CVars de teste na lista: `addonCombatRestrictionsForced` e `taintLogObjectSecrets`. `[página]` e `[local]`
- **ElvUI no canto inferior direito:** a barra de threat é `databars.threat` (ligada por padrão, mover `ThreatBarMover` em `BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-4,4`; no perfil do dono, 472 x 24), só aparece em combate, com pet ou grupo, e descarta valor secreto. O tooltip prende o próprio `BOTTOMRIGHT` no `TOPRIGHT` do `TooltipMover` (quadro de 130 x 20), mais o deslocamento do perfil (`Modules\Tooltip\Tooltip.lua:173-190` e `:1264-1267`): com o mover em y, a caixa do tooltip nasce em y + 20 + o deslocamento vertical. `[local]`
- **Expressway não tem dígitos de largura fixa:** no arquivo `ElvUI\Game\Shared\Media\Fonts\Expressway.ttf`, o "1" avança 256/1000 de em e os outros dígitos cerca de 580; a PT Sans Narrow é tabular (478). Lido da tabela de métricas da fonte por um subagente, não reconferido pela sessão principal. Número que muda rápido vai em caixa de largura fixa alinhada à direita. `[local]`
- **A confirmar no jogo (o diário da CentralForever grava):** segredo de cada campo de dano e de threat em mundo, dungeon e chefe; duração legível em combate; pet somado na linha do dono; threat solo sem pet; o texto exato de cada formatador; o que é a sessão Expired; quando chega `DAMAGE_METER_RESET`.

## 3g. Leilão, profissão e vendedor (2026-11-17, para o CompraForever)

`[página]`: documentação gerada do espelho `Ketho/wow-ui-source-forever`, branch `forever`, commit "1.60.1 (70938)" de 2026-11-13, lida pelo `gh` em 2026-11-17 (`AuctionHouseDocumentation.lua`, `AuctionHouseEnumsDocumentation.lua`, `TradeSkillUIDocumentation.lua`, `ContainerDocumentation.lua`); o cliente instalado já está no 70959. `HasRestrictions = true` (função que exige clique de hardware): `StartCommoditiesPurchase`, `PlaceBid`, `CancelAuction`, `PostItem`/`PostCommodity` e as confirmações de postagem. Sem `HasRestrictions`: `ConfirmCommoditiesPurchase`, `SendSearchQuery`, `RequestMoreCommoditySearchResults`, `ReplicateItems`, `C_TradeSkillUI.CraftRecipe(recipeSpellID, numCasts)` e `C_Container.UseContainerItem`. `Enum.AuctionHouseSortOrder.Price = 0`. A janela de profissão é o `ProfessionsFrame` (há `Blizzard_Professions\Camelot\`). `BuyMerchantItem` não está na documentação gerada (função global antiga). Nada disso rodou no jogo; o `/compra sonda` do CompraForever confere commodity e tempo de busca.

### 3g.0 Profissão para a modalidade de rota do CompraForever (2026-11-23)

`[página]`: `TradeSkillUIDocumentation.lua` do mesmo espelho (`Ketho/wow-ui-source-forever`, branch `forever`), lido pelo
`gh api` em 2026-11-23, e os nomes conferidos na lista local `ferramentas\guia\api-forever\GlobalAPI.lua` (build 70532).
`C_TradeSkillUI.CraftEnchant(recipeSpellID, numCasts = 1, craftingReagents, itemTarget: ItemLocation, applyConcentration)`
existe e, como o `CraftRecipe`, não tem `HasRestrictions` (`GlobalAPI.lua:4315`). `GetRecipeRequirements(recipeID)` devolve
uma lista de `CraftingRecipeRequirement` (o CompraForever lê `name` e `met`; `:4381`). `GetProfessionInfoBySkillLineID
(skillLineID)` devolve um `ProfessionInfo`. `IsNearProfessionSpellFocus(profession)` recebe o enum `Profession`, não o
nome do objeto (`:4405`). `StopRecipeRepeat` (`:4445`), `GetCraftableCount(recipeSpellID)` e `GetRemainingRecasts()`
estão na lista. Eventos na lista (`Events.lua`): `CHAT_MSG_SKILL`, `SKILL_LINES_CHANGED`, `NEW_RECIPE_LEARNED`,
`LEARNED_SPELL_IN_SKILL_LINE`, `UPDATE_TRADESKILL_CAST_STOPPED`, `TRAINER_SHOW`, `MAIL_SHOW`, `MAIL_INBOX_UPDATE`. Nada
disso rodou no jogo: o `/compra sonda prof` (CompraForever 0.3.0) imprime e grava o que essas funções devolvem, e o
resultado entra aqui com a marca `[local]`.

`[local]` Sonda de 2026-11-23 21:14 (Ignatius, nível 10, janela de Engineering aberta, lida em `CompraForeverDB.sonda`):
`GetProfessions()` devolveu os índices `7,8,5,nil,6` (Mining, Engineering, First Aid, sem pesca, Cooking), e
`GetProfessionInfo(i)` devolve nome, perícia, máximo e skillLine (Engineering: `skill=1 max=75 line=202`).
`C_TradeSkillUI.GetProfessionInfoBySkillLineID(202)` devolve a mesma perícia; para profissão que o personagem não tem,
devolve a tabela com `skillLevel=0` e `maxSkillLevel=0`, não `nil`. `C_SkillInfo.GetNumSkillLines()` deu 26, e a leitura
por id dá `nil` nas profissões que o personagem não tem. `GetBaseProfessionInfo` trouxe Engineering; `GetChildProfessionInfo`
veio vazio (`professionID=0`), então no Forever não há expansão filha. A janela listou 275 receitas, 3 aprendidas;
`GetCraftableCount` e `GetRecipeRequirements` (vazia para Rough Blasting Powder) responderam. Todas as funções da lista acima
existem no cliente. No mesmo dia a rota levou a Engineering do 1 ao 150 no jogo.

`[local]` Janela do treinador (2026-11-23): o filtro do treinador pode ficar mostrando só as receitas indisponíveis; aí a
lista parece vazia de receitas para aprender, embora a janela de profissão as mostre em "Unlearned > Learnable now". O
dono disse que o treinador "estava mostrando só as receitas unavailable" (onde se troca o filtro não foi visto). A
janela de profissão do Forever lista todas as receitas, aprendidas ou não, com
a fonte (Trainer, Vendor, Drop) e o treinador mais perto.

### 3g.1 Postagem no leilao (2026-11-18)

`[página]`: documentação gerada do espelho `Ketho/wow-ui-source-forever`, branch `forever`, arquivos
`Interface/AddOns/Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua` (namespace `C_AuctionHouse`) e
`AuctionHouseEnumsDocumentation.lua`, lidos por `gh api` em 2026-11-18. Nada disto foi testado no jogo.

| Função (`C_AuctionHouse`) | Argumentos (tipo) | Retorno | `HasRestrictions` |
|---|---|---|---|
| `PostCommodity` | `item` (`ItemLocation`), `duration` (`luaIndex`), `quantity` (`number`), `unitPrice` (`BigUInteger`) | `needsConfirmation` (`bool`) | sim |
| `ConfirmPostCommodity` | os mesmos quatro de `PostCommodity` | nenhum | sim |
| `PostItem` | `item`, `duration`, `quantity`, `bid` (`BigUInteger`, `Nilable`), `buyout` (`BigUInteger`, `Nilable`) | `needsConfirmation` (`bool`) | sim |
| `ConfirmPostItem` | os mesmos de `PostItem` | nenhum | sim |
| `CalculateCommodityDeposit` | `itemID` (`number`), `duration` (`luaIndex`), `quantity` (`number`) | `depositCost` (`number`, `Nilable`) | não |
| `CalculateItemDeposit` | `item` (`ItemLocation`), `duration` (`luaIndex`), `quantity` (`number`) | `depositCost` (`number`, `Nilable`) | não |

Todas levam `SecretArguments = "AllowedWhenUntainted"`. `ItemLocation` tem o mixin `ItemLocationMixin`.

Eventos de postagem, todos `SynchronousEvent = true`:

| Evento | Literal | Payload |
|---|---|---|
| `AuctionHousePostError` | `AUCTION_HOUSE_POST_ERROR` | nenhum |
| `AuctionHousePostWarning` | `AUCTION_HOUSE_POST_WARNING` | nenhum |
| `AuctionHouseAuctionCreated` | `AUCTION_HOUSE_AUCTION_CREATED` | `auctionID` (`number`); a própria documentação diz que a UI base não usa |
| `OwnedAuctionsUpdated` | `OWNED_AUCTIONS_UPDATED` | nenhum |

Enum `AuctionHouseTimeLeftBand` (`AuctionHouseEnumsDocumentation.lua`, 4 valores): `Short` 0, `Medium` 1, `Long` 2,
`VeryLong` 3. Não é o tipo do argumento `duration` da postagem, que é `luaIndex`.

Pendência: a documentação não dá a faixa de `duration`. O dono leu o índice como 1 a 3, e a correspondência com as
durações de 2 h, 8 h e 24 h, lidas no jogo pela sonda S0 do PregaoForever em 2026-11-16, não foi confirmada. Antes de
postar com `duration`, confirmar no cliente.

## 4. Fluxo de desenvolvimento

1. Editar em `addons-proprios\<Nome>` (modelo em `addons-proprios\_modelo\Modelo`; instruções em `addons-proprios\LEIA-ME.md`).
2. Ligar ao jogo com `ferramentas\dev-link.ps1`: prévia, depois `-Aplicar` com o jogo fechado. A junction aponta para a pasta de desenvolvimento; nada é copiado.
3. Mudança de código: `/reload` no jogo.
4. Addon novo ou TOC novo (incluindo a Interface): reiniciar o jogo. `/reload` não basta para arquivo novo. `[página]` (Forever Mastery)
5. Erros: BugSack.
6. Antes de depender de uma API, conferir na documentação e, se houver dúvida, no cliente. Não supor que uma API existe no Forever só porque existe no Mainline.
7. Desligar: `dev-link.ps1 -Remover` (prévia e `-Aplicar`); a pasta de desenvolvimento fica intacta.

## 5. Pendências de conferência

- Não consegui conferir na página do warcraft.wiki.gg a seção de secret values, a de TOC e o número 16001. (Conferir o 16001 no cliente com `/dump`.)
- A branch `forever` do Ketho foi conferida em 2026-11-05 (ver a seção 3); a ausência de uma branch do Forever no Gethe continua sem conferência direta. O espelho do Ketho é do build 70009: conferir de novo quando ele subir para o build do cliente.
- A página da API não foi lida inteira (só ~100 mil de ~692 mil caracteres).
- Os fatos de restrição de combate são de resumos de busca e de sites de terceiros; a lista exata do que o Forever bloqueia só sai do cliente.
- Lançamento em 2026-11-04 (23:00 UTC): até lá, os fatos de cliente final são de beta/pré-lançamento.
