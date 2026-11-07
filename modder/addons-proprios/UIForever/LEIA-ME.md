# UIForever

Addon próprio criado em 2026-11-05 a partir do feedback do dono sobre o print da UI. Ele aplica a UI inteira no login, para o dono não configurar nada dentro do jogo. Versão 0.6.0 (a 0.2.0 foi feita em duas sessões paralelas na noite de 2026-11-05, no Avell e no Acer, e juntada depois: acrescentou as opções do menu do jogo, os CVars, e passou a respeitar o que o dono põe nos botões). O primeiro login com ele foi em 2026-11-05 às 19h29, com o diário limpo: 41 ajustes no ElvUI, 30 teclas e 13 botões do caçador, sem falha.

## Arquivos

| Arquivo | O que tem |
|---|---|
| `UIForever.toc` | Interface 16001, depende do ElvUI, SavedVariables `UIForeverDB` (conta) e `UIForeverCharDB` (personagem) |
| `Config.lua` | tudo o que se muda: layout do ElvUI, teclas, conteúdo dos botões por classe, escala do minimapa grande, opções do menu do jogo (CVars) e a barra de experiência (`barraXP`) |
| `UIForever.lua` | o motor; não precisa ser mexido para trocar a configuração |
| `Bindings.xml` | a tecla do minimapa grande (aparece em Keybindings, em AddOns); o cliente lê sozinho, fora do TOC |

## O que acontece no login

1. No `ADDON_LOADED` do UIForever, antes de o ElvUI montar a tela (o `E:InitDB` só roda no `PLAYER_LOGIN`), ele grava no `ElvDB` cru os pares de `UIForeverConfig.elvui`. Cada valor só é gravado quando muda no `Config.lua` (controle em `UIForeverDB.aplicado`); fora isso, o que o dono mudar pelo jogo fica.
2. Personagem novo herda o perfil do primeiro personagem configurado (`UIForeverDB.perfil`) e o private dele (`UIForeverDB.privadoModelo`, com o `install_complete`), então pula o assistente do ElvUI; o passo de chat do assistente (`E:SetupChat(true)`) roda sozinho depois do login.
3. Dois segundos depois de entrar no mundo, ele cria as alças de arrastar a altura dos dois chats, aplica as teclas e põe as magias e macros nos botões.
4. As teclas de `UIForeverConfig.teclas` são gravadas a cada login onde estiverem diferentes, pela API oficial (`SetBinding` e `SaveBindings`). Para essas teclas, o `Config.lua` vence o que o dono mudar no jogo.
5. Os botões de `UIForeverConfig.barras[<CLASSE>]` são conferidos no login e sempre que o personagem aprende magia ou as macros mudam (fora de combate e com o cursor vazio). Quando um slot lista macro e magia, a macro vence; a magia entra com o rank mais alto que o personagem conhece. Slots gerenciados: 1 a 12, 13 a 21, 25 a 36, 49 a 59 (a barra 5, de recargas da rotação, desde a 0.5.0; dinâmica desde a 0.6.0, passo 10) e 61 a 66. Os outros (22 a 24, 37 a 48, 60 e 67 a 72) ficam livres para o dono.
   - **Desde a 0.2.0 (2026-11-05), o botão é do dono.** O UIForever lembra, por personagem, o que ele mesmo pôs em cada slot (`UIForeverCharDB.slots`). Ele só troca ou esvazia um slot enquanto o conteúdo for o que ele pôs. O que o dono arrastar para um slot gerenciado, ou tirar dele, fica. Slot vazio que o UIForever nunca preencheu recebe a ação do plano quando ela existir (magia aprendida ou macro criada).
   - Por que mudou: na 0.1.0, ele devolvia cada slot ao plano e esvaziava os slots de magias ainda não aprendidas a cada `SPELLS_CHANGED`. Isso fazia sumir o que o dono arrastava (relato do dono em 2026-11-05).
   - Para o UIForever voltar a preencher um slot que o dono esvaziou, apague a entrada do slot em `UIForeverCharDB.slots`, com o jogo fechado, e entre de novo.
6. As opções do menu de `UIForeverConfig.cvars` (hoje: auto loot ligado e "NPC Names" em "All NPCs", pedido do dono em 2026-11-05; e, desde a noite do mesmo dia, os timers nativos `showSwingTimer` e `cooldownViewerEnabled`, ver `..\..\..\comum\referencia\api-forever.md`, seção 3d) são gravadas pela API oficial (`C_CVar.SetCVar` ou `SetCVar`), fora de combate, uma vez por personagem: o controle fica em `UIForeverCharDB.cvars`, e só uma linha que mudar no `Config.lua` é gravada de novo. O que o dono mudar no menu depois fica naquele personagem, mas como essas opções costumam valer para a conta, o primeiro login de outro personagem pode religar; para desligar de vez, tire a linha do `Config.lua`. O diário registra o valor de antes de cada uma (`cvars: nome antes->depois`).
7. Shift+M (`UIForever_AlternarMinimapa`) multiplica a escala do minimapa por `minimapaEscala` (2,2) no mesmo canto e volta no segundo toque; se o dono sair do jogo com ele grande, o próximo login volta ao normal.
8. **Barra de experiência da Blizzard (desde a 0.3.0, 2026-11-05).** Dois segundos depois de entrar no mundo, junto com as teclas e os botões, o UIForever cria a barra de experiência com o próprio modelo da Blizzard. A barra de XP do ElvUI fica desligada pelo par `databars.experience.enable = false` do `Config.lua`.
   - Por que não a barra original: o ElvUI 16.01 apaga o `StatusTrackingBarManager` da Blizzard quando as barras de ação dele estão ligadas (`AB:DisableBlizzard` chama `Kill()`). Esse quadro é do Edit Mode, onde já houve avisos de taint, por isso o UIForever não o ressuscita.
   - O que é igual à Blizzard: a barra (`ExpStatusBarTemplate`, com o código, as animações, o marcador e a previsão do descanso e o tooltip dela) e o container, recriado à mão com o atlas `UI-HUD-ExperienceBar-Frame` e os 20 segmentos de `StatusBarDividerTemplate`. O tamanho é 1192 × 17 e a barra fica 3 menor, em (1, 2), como no `InitializeBars` do Forever (constantes `STATUS_BAR_CONTAINER_*` do `Camelot`). Fonte: espelho `Ketho/wow-ui-source-forever`, pasta `Blizzard_StatusTrackingBar`.
   - Inferência a conferir no print: no XML da Blizzard, a moldura (`BarFrameTexture`) não tem âncora. O UIForever a estica no container (`SetAllPoints`).
   - Lugar: onde estava a barra do ElvUI, com a base presa ao `ElvUI_ExperienceBarHolder`, que o ElvUI continua posicionando com a barra desligada. `barraXP.ponto` no `Config.lua` troca o lugar.
   - Quests: soma `GetQuestLogRewardXP(questID)` de cada quest do log (`C_QuestLog.GetInfo`, sem cabeçalhos nem quests escondidas). O trecho começa na XP atual e vai até atual + quests, com o desenho da previsão do descanso, sem saturação e em amarelo (`corQuests`). O trecho mais curto (quests ou descanso) fica por cima. Recalcula, com 0,3 s de folga, em `QUEST_LOG_UPDATE`, `QUEST_TURNED_IN`, `PLAYER_XP_UPDATE`, `PLAYER_LEVEL_UP` e `UPDATE_EXHAUSTION`.
   - Tooltip: o da Blizzard (XP e descanso), mais o que falta para o próximo nível, a XP das quests do log e quantas são, a parte das prontas para entregar e o que falta depois de entregar todas (ou quanto sobra).
   - O texto da barra é o da Blizzard (`XP: atual/máximo`) e segue a opção do jogo: aparece ao passar o mouse, ou sempre, com a CVar `xpBarText`.
   - Se o modelo da Blizzard faltar, o UIForever avisa no chat e no diário, e o dono fica sem barra de XP até religar a do ElvUI no `Config.lua`.
9. **Margem das janelas do jogo (desde a 0.6.0, 2026-11-06).** Três segundos depois de entrar no mundo, o UIForever calcula a borda direita da coluna da esquerda (o lado esquerdo do `RXPFrame` mais o maior entre a largura dele e a do `GuiaForeverAgora`, ou `larguraMinima` se o painel não existir, em unidades do `UIParent`) e aplica `margemJanelas.folga` por cima, pela `SetUIPanelLayoutAttribute("LEFT_OFFSET", x)`. É a margem que o Forever usa para abrir vendedor, missão, treinador, talentos e livro (`Blizzard_UIParentPanelManager`, `UIPanelLayoutFrame.lua` e `UIParentPanelManager.lua`). Só fora de combate (em combate fica na fila do `PLAYER_REGEN_ENABLED`). Roda de novo ao soltar o mouse sobre o `RXPFrame`, quando ele muda de tamanho e quando alguém chama a global `UIForever_AtualizarMargem()` (o GuiaForever a chama quando o painel Agora muda). Sem RestedXP, ou com `margemJanelas.ligado = false`, a margem volta para 16. O diário registra `margem das janelas: antes -> depois` só quando o valor muda.
10. **Barra 5 dinâmica (desde a 0.6.0).** Os slots 49 a 59 não têm mais plano fixo no `barras.HUNTER`. As magias conhecidas de `barraRecargas.HUNTER`, na ordem, ocupam os slots seguidos a partir do 49, e o UIForever ajusta `buttons` e `buttonsPerRow` da `bar5` no `E.db` ao número delas (mínimo 1) e manda o ElvUI redesenhar (`AB:PositionAndSizeBar("bar5")`, fora de combate). A barra fica centrada porque o mover dela (`ElvAB_5`) está ancorado pelo centro de baixo. A regra do botão do dono continua: se o dono pôs outra coisa num desses slots, o UIForever não mexe nele, e a magia daquela posição fica de fora. Com o livro de magias ainda vazio no login, a barra não encolhe.
11. **Buffs num lugar só e Ctrl+1 (0.6.0).** No quadro do jogador os buffs saem (`buffs.enable = false`) e os debuffs prendem no quadro (`attachTo = "FRAME"`); fica a fileira de auras perto do minimapa. O slot 16 (Ctrl+1) recebe a macro `feed_Pet`, criada pelo GuiaForever depois de aprender o Feed Pet; até lá vale a magia.
12. **Chat da esquerda no painel (desde a 0.6.0, `chatNoPainel`).** O Edit Mode da Blizzard reancora o `ChatFrame1`, e o ElvUI só o devolve ao `LeftChatPanel` se o achar sobre o painel (`Chat.lua`, `FindChatWindows`). Depois de cada reancoragem do Edit Mode (`ApplySystemAnchor` do `ChatFrame1` e `EditModeManagerFrame:UpdateLayoutInfo`) e uma vez no login, o UIForever confere e, se o chat principal não está no painel, grava o id dele como janela da esquerda e chama o `CH:PositionChat` do próprio ElvUI. Não mexe em aba, canal nem no layout do Edit Mode, e não chama `E:SetupChat`. O diário registra `chat da esquerda devolvido ao LeftChatPanel`. Desligar: `chatNoPainel = false`. Sem teste no jogo até a primeira sessão com a 0.6.0.

## Ligação com o GuiaForever

As macros do caçador são criadas pelo GuiaForever (`..\GuiaForever\Dados.lua`, `GuiaForeverMacros.HUNTER`), e o UIForever só as põe nos botões, pelo nome. Se uma macro mudar de nome lá, troque o nome também em `barras.HUNTER` do `Config.lua`, senão o botão cai na magia de reserva ou fica vazio. As teclas do pet (Shift+roda e clique do meio) são do GuiaForever e não estão no `UIForever`. A J, que abre o guia do GuiaForever, está no `UIForever` desde 2026-11-05 à noite (escolha do dono), porque a J era da janela de guilda e o GuiaForever só a pega quando está livre. A tecla 1 do caçador usa a macro `sting_Auto` do GuiaForever, com o Serpent Sting de reserva.

Até 2026-11-05 só o caçador tem barras. O Rurik (Shaman) entra quando a build dele fechar.

## Mudar alguma coisa

Edite o `Config.lua` e dê `/reload` no jogo (o `ADDON_LOADED` roda de novo no reload). Mudou o `.toc` ou criou arquivo: reinicie o jogo.

## Diagnóstico

O diário do addon fica em `UIForeverDB.log` (últimas 60 linhas), em `WTF\Account\<conta>\SavedVariables\UIForever.lua`, e os erros de Lua no `BugGrabber.lua` da mesma pasta. Leia os dois com o jogo fechado.

## Desfazer

`ferramentas\dev-link.ps1 -Pasta addons-proprios\UIForever -Remover -Aplicar` tira o addon, e `ferramentas\wtf-restaurar.ps1 -De <backups>\sessoes\2026-11-05_1212 -Aplicar` devolve o perfil do ElvUI e as teclas de antes. As duas coisas são necessárias, porque o addon grava no perfil do ElvUI e no `bindings-cache.wtf`. As opções do menu (CVars) não voltam com o backup do WTF de forma garantida (ficam também no servidor): desfaça pelo menu do jogo (Options > Controls > Auto Loot; Options > Nameplates > NPC Names; o valor de antes fica no diário, e o padrão do Forever é a opção 3, hostis e interativos, fora do preset Classic) e tire as linhas do `Config.lua`.

Só a barra de experiência: no `Config.lua`, `barraXP.ligada = false` e `true` no par `databars.experience.enable`, e depois `/reload`. A barra do ElvUI volta com as quests dela, que vêm ligadas por padrão (`showQuestXP`).
