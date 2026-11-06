-- UIForever: o que o modder define para a UI do dono. Mudou aqui, o proximo
-- login aplica (o dono nao configura nada dentro do jogo).

BINDING_HEADER_UIFOREVER = "UIForever"
BINDING_NAME_UIFOREVER_MINIMAPA = "Minimapa grande (liga e desliga)"

UIForeverConfig = {}

-- 1. Perfil do ElvUI. Caminhos a partir do perfil (ElvDB.profiles[perfil]).
-- Cada valor so e gravado quando muda aqui (o UIForever lembra o ultimo valor
-- aplicado); o que o dono mudar no jogo fica ate este arquivo mudar aquele item.
-- Pedido do dono em 2026-11-05, sobre o print da UI.
UIForeverConfig.elvui = {
  -- botoes menores (eram 50 nas barras 1 e 3, 38 na 2)
  { "actionbar.bar1.buttonSize", 34 },
  { "actionbar.bar1.buttons", 12 },
  { "actionbar.bar1.buttonsPerRow", 12 },
  { "actionbar.bar1.showGrid", false },
  { "actionbar.bar3.buttonSize", 34 },
  { "actionbar.bar3.buttons", 12 },
  { "actionbar.bar3.buttonsPerRow", 12 },
  { "actionbar.bar3.showGrid", false },
  { "actionbar.bar2.buttonSize", 30 },
  { "actionbar.bar2.buttons", 9 },
  { "actionbar.bar2.buttonsPerRow", 9 },
  { "actionbar.bar2.showGrid", false },
  { "actionbar.bar6.buttonSize", 30 },
  { "actionbar.bar6.showGrid", false },
  -- barras mais baixas e quadros afastados para caber o retrato
  { "movers.ElvAB_3", "BOTTOM,ElvUIParent,BOTTOM,0,139" },
  { "movers.ElvAB_1", "BOTTOM,ElvUIParent,BOTTOM,0,175" },
  { "movers.ElvUF_PlayerCastbarMover", "BOTTOM,ElvUIParent,BOTTOM,0,215" },
  { "movers.ElvUF_PlayerMover", "BOTTOM,ElvUIParent,BOTTOM,-385,139" },
  { "movers.ElvUF_TargetMover", "BOTTOM,ElvUIParent,BOTTOM,385,139" },
  { "movers.ElvUF_PetMover", "BOTTOM,ElvUIParent,BOTTOM,-385,101" },
  { "movers.ElvUF_TargetTargetMover", "BOTTOM,ElvUIParent,BOTTOM,385,101" },
  { "movers.ElvUF_FocusMover", "BOTTOM,ElvUIParent,BOTTOM,385,60" },
  -- retrato 3D animado no jogador e no alvo
  { "unitframe.units.player.width", 330 },
  { "unitframe.units.player.portrait.enable", true },
  { "unitframe.units.player.portrait.style", "3D" },
  { "unitframe.units.player.portrait.overlay", false },
  { "unitframe.units.player.portrait.width", 82 },
  { "unitframe.units.target.width", 330 },
  { "unitframe.units.target.portrait.enable", true },
  { "unitframe.units.target.portrait.style", "3D" },
  { "unitframe.units.target.portrait.overlay", false },
  { "unitframe.units.target.portrait.width", 82 },
  -- chats semitransparentes e com metade da altura (eram 236)
  { "chat.panelColor", { r = 0.06, g = 0.06, b = 0.06, a = 0.3 } },
  { "chat.separateSizes", true },
  { "chat.panelHeight", 118 },
  { "chat.panelHeightRight", 118 },
  { "chat.panelWidthRight", 472 },
  { "LeftChatPanelFaded", false },
  { "RightChatPanelFaded", false },
  { "datatexts.panels.LeftChatDataPanel.backdrop", false },
  { "datatexts.panels.RightChatDataPanel.backdrop", false },
}

-- Altura minima e maxima ao arrastar a borda de cima de um chat.
UIForeverConfig.chatAlturaMin = 60
UIForeverConfig.chatAlturaMax = 700

-- 2. Minimapa grande: Shift+M multiplica a escala; outro Shift+M volta.
UIForeverConfig.minimapaEscala = 2.2

-- 3. Teclas (valem para todos os personagens). Esquema escolhido pelo dono em
-- 2026-11-05: A/D andam de lado, habilidades em volta do WASD, Shift dobra a
-- barra, laterais do mouse (Logitech G703) na barra do rodape.
-- Barra 1 do ElvUI = ACTIONBUTTON, barra 3 = MULTIACTIONBAR3BUTTON,
-- barra 2 (rodape) = ELVUIBAR2BUTTON.
-- Fora daqui (do GuiaForever, escolha do dono): Shift+roda e clique da roda
-- para o pet.
UIForeverConfig.teclas = {
  { "A", "STRAFELEFT" },
  { "D", "STRAFERIGHT" },

  { "1", "ACTIONBUTTON1" }, { "2", "ACTIONBUTTON2" }, { "3", "ACTIONBUTTON3" },
  { "4", "ACTIONBUTTON4" }, { "5", "ACTIONBUTTON5" }, { "6", "ACTIONBUTTON6" },
  { "Q", "ACTIONBUTTON7" }, { "E", "ACTIONBUTTON8" }, { "R", "ACTIONBUTTON9" },
  { "F", "ACTIONBUTTON10" }, { "T", "ACTIONBUTTON11" }, { "G", "ACTIONBUTTON12" },

  { "SHIFT-1", "MULTIACTIONBAR3BUTTON1" }, { "SHIFT-2", "MULTIACTIONBAR3BUTTON2" },
  { "SHIFT-3", "MULTIACTIONBAR3BUTTON3" }, { "SHIFT-4", "MULTIACTIONBAR3BUTTON4" },
  { "SHIFT-5", "MULTIACTIONBAR3BUTTON5" }, { "SHIFT-6", "MULTIACTIONBAR3BUTTON6" },
  { "SHIFT-Q", "MULTIACTIONBAR3BUTTON7" }, { "SHIFT-E", "MULTIACTIONBAR3BUTTON8" },
  { "SHIFT-R", "MULTIACTIONBAR3BUTTON9" }, { "SHIFT-F", "MULTIACTIONBAR3BUTTON10" },
  { "SHIFT-T", "MULTIACTIONBAR3BUTTON11" }, { "SHIFT-G", "MULTIACTIONBAR3BUTTON12" },

  { "Z", "ELVUIBAR2BUTTON1" }, { "X", "ELVUIBAR2BUTTON2" }, { "V", "ELVUIBAR2BUTTON3" },
  { "CTRL-1", "ELVUIBAR2BUTTON4" }, { "CTRL-2", "ELVUIBAR2BUTTON5" },
  { "CTRL-3", "ELVUIBAR2BUTTON6" }, { "CTRL-4", "ELVUIBAR2BUTTON7" },
  { "BUTTON4", "ELVUIBAR2BUTTON8" }, { "BUTTON5", "ELVUIBAR2BUTTON9" },

  -- o que as teclas acima tiraram do lugar
  { "CTRL-R", "REPLY" },
  { "CTRL-V", "NAMEPLATES" },
  { "CTRL-X", "SITORSTAND" }, -- sentar e descer na agua (era o X); pedido do dono em 2026-11-05

  { "SHIFT-M", "UIFOREVER_MINIMAPA" },
}

-- 4. O que fica em cada botao, por classe. Slot = numero da acao:
-- barra 1 = 1 a 12, barra 2 (rodape) = 13 a 21, barra 3 = 25 a 36,
-- barra 6 (acima do chat da direita, so clique) = 61 a 66.
-- { macro = "nome" } usa a macro se ela existir; { magia = "nome" } usa a magia
-- se o personagem ja a conhece (nome em ingles, cliente enUS). Os dois juntos:
-- a macro vence. Slot de barra gerenciada fora da lista fica vazio.
-- Magia aprendida depois entra sozinha no slot dela.
UIForeverConfig.gerenciados = { { 1, 12 }, { 13, 21 }, { 25, 36 }, { 61, 66 } }

UIForeverConfig.barras = {
  -- Hexumlite (BM). Magias e niveis: Method, guia de leveling de cacador de
  -- 03/11 (ficha do personagem). Macros: GuiaForever (Gladius e leak).
  HUNTER = {
    -- barra 1: 1 2 3 4 5 6 Q E R F T G
    [1] = { magia = "Serpent Sting" },
    [2] = { magia = "Arcane Shot" },
    [3] = { magia = "Multi-Shot" },
    [4] = { magia = "Aimed Shot" },
    [5] = { macro = "Hunter's Mark", magia = "Hunter's Mark" },
    [6] = { macro = "Burst", magia = "Rapid Fire" },
    [7] = { magia = "Raptor Strike" },
    [8] = { magia = "Wing Clip" },
    [9] = { macro = "pet_AllInOne", magia = "Mend Pet" },
    [10] = { magia = "Auto Shot" },
    [11] = { magia = "Summon Hawk" },
    [12] = { magia = "Mongoose Bite" },
    -- barra 2 (rodape): Z X V Ctrl+1 Ctrl+2 Ctrl+3 Ctrl+4 mouse4 mouse5
    [13] = { macro = "Taunt" },
    [14] = { macro = "cancel_Cheetah" },
    [15] = { macro = "RXPTargeting" },
    [16] = { magia = "Feed Pet" },
    [17] = { magia = "Dismiss Pet" },
    [18] = { magia = "Tame Beast" },
    [19] = { macro = "eagle_Eye", magia = "Eagle Eye" },
    [20] = { magia = "Concussive Shot" },
    [21] = { macro = "Freezing Trap", magia = "Freezing Trap" },
    -- barra 3: Shift + 1 2 3 4 5 6 Q E R F T G
    [25] = { macro = "aspect_Hawk", magia = "Aspect of the Hawk" },
    [26] = { magia = "Aspect of the Monkey" },
    [27] = { macro = "aspect_Cheetah", magia = "Aspect of the Cheetah" },
    [28] = { magia = "Frost Trap" },
    [29] = { magia = "Immolation Trap" },
    [30] = { magia = "Explosive Trap" },
    [31] = { magia = "Disengage" },
    [32] = { magia = "Feign Death" },
    [33] = { magia = "Intimidation" },
    [34] = { magia = "Flare" },
    [35] = { magia = "Scare Beast" },
    [36] = { magia = "Distracting Shot" },
    -- barra 6 (clique)
    [61] = { magia = "Track Beasts" },
    [62] = { magia = "Track Humanoids" },
    [63] = { magia = "Track Hidden" },
    [64] = { magia = "Track Undead" },
    [65] = { magia = "Beast Lore" },
    [66] = { macro = "Attack_Speed" },
  },
}
