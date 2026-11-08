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
  -- Barra de recargas da rotacao (dono, 2026-11-06, noite: "uma barra com as
  -- habilidades da minha rotacao bem discriminadas na tela, a fim de trackear
  -- cooldowns"). Barra 5 do ElvUI (slots 49 a 59), logo abaixo do personagem,
  -- acima dos timers de ataque; so mostra o que o personagem ja aprendeu (o
  -- conteudo vem de UIForeverConfig.barraRecargas, slots 49 a 59). Sem tecla propria:
  -- as teclas continuam as da barra 1. O icone fica cinza enquanto recarrega,
  -- em todas as barras (desaturateOnCooldown, que no Forever le a recarga pelo
  -- objeto de duracao da Blizzard, sem ler valor secreto).
  { "actionbar.bar5.enabled", true },
  -- buttons e buttonsPerRow da barra 5 nao ficam aqui: o UIForever ajusta ao
  -- numero de magias conhecidas da lista UIForeverConfig.barraRecargas (0.6.0)
  { "actionbar.bar5.buttonSize", 44 },
  { "actionbar.bar5.buttonSpacing", 4 },
  { "actionbar.bar5.showGrid", false },
  { "actionbar.bar5.backdrop", false },
  { "actionbar.bar5.hotkeytext", false },
  { "movers.ElvAB_5", "BOTTOM,ElvUIParent,BOTTOM,0,300" },
  { "actionbar.desaturateOnCooldown", true },
  -- barras mais baixas e quadros afastados para caber o retrato
  { "movers.ElvAB_3", "BOTTOM,ElvUIParent,BOTTOM,0,139" },
  { "movers.ElvAB_1", "BOTTOM,ElvUIParent,BOTTOM,0,175" },
  { "movers.ElvUF_PlayerCastbarMover", "BOTTOM,ElvUIParent,BOTTOM,0,215" },
  { "movers.ElvUF_PlayerMover", "BOTTOM,ElvUIParent,BOTTOM,-385,139" },
  { "movers.ElvUF_TargetMover", "BOTTOM,ElvUIParent,BOTTOM,385,139" },
  { "movers.ElvUF_PetMover", "BOTTOM,ElvUIParent,BOTTOM,-385,101" },
  { "movers.ElvUF_TargetTargetMover", "BOTTOM,ElvUIParent,BOTTOM,385,101" },
  { "movers.ElvUF_FocusMover", "BOTTOM,ElvUIParent,BOTTOM,385,60" },
  -- buffs num lugar so (dono, 2026-11-06): os do quadro do jogador saem e a
  -- fileira perto do minimapa fica; debuffs do quadro prendem no proprio quadro
  { "unitframe.units.player.buffs.enable", false },
  { "unitframe.units.player.debuffs.attachTo", "FRAME" },
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
  -- a vida do jogador e do alvo (atual / maxima) esta na secao 1b, Numeros
  -- chats semitransparentes e com metade da altura (eram 236)
  { "chat.panelColor", { r = 0.06, g = 0.06, b = 0.06, a = 0.3 } },
  { "chat.separateSizes", true },
  { "chat.panelHeight", 118 },
  { "chat.panelHeightRight", 118 },
  { "chat.panelWidthRight", 472 },
  { "LeftChatPanelFaded", false },
  { "RightChatPanelFaded", false },
  -- sem o fundo dos dois paineis de chat (dono, 2026-11-08: "barra fantasma"
  -- nos dois cantos de baixo). O da direita ficava vazio (o Loot / Trade esta
  -- solto) e o da esquerda aparecia vazio quando o Edit Mode tirava o chat
  -- dele. O texto do chat e as barras de dados ficam; as abas somem ate passar
  -- o mouse (fadeTabsNoBackdrop, padrao do ElvUI). Para voltar: "SHOWBOTH".
  { "chat.panelBackdrop", "HIDEBOTH" },
  { "datatexts.panels.LeftChatDataPanel.backdrop", false },
  { "datatexts.panels.RightChatDataPanel.backdrop", false },
  -- a barra de XP da Blizzard (secao 6, barraXP) substitui a do ElvUI;
  -- para voltar a do ElvUI, true aqui e ligada = false la
  { "databars.experience.enable", false },
}

-- 1b. Numeros em Expressway (pedido do dono em 2026-11-06: o 5 parecia 6 e o 6
-- parecia 8). No padrao do ElvUI 16.01 os quadros e as barras usam a Homespun,
-- fonte de pixel, e o resto a PT Sans Narrow. So o que e numero muda; nomes,
-- chat, tooltip e menus ficam como estao ("so nos numeros, por enquanto").
-- No ElvUI o nome e a vida do quadro dividem a fonte do modulo, por isso a vida
-- e o recurso do jogador e do alvo saem do texto padrao e viram textos proprios
-- (customTexts), cada um com a sua fonte, no mesmo lugar do texto padrao.
-- Para desfazer: ligado = false e /reload (volta cada item ao padrao do ElvUI).
local NUMEROS = {
  ligado = true,
  fonte = "Expressway", -- ja vem no ElvUI (a dos numeros de recarga)
  contorno = "OUTLINE",
  tamanhoQuadro = 13,   -- vida e recurso do jogador e do alvo
  tamanhoBotao = 12,    -- tecla e contagem nos botoes, contagem das auras
  tamanhoNivel = 14,    -- nivel do alvo (dono, 2026-11-06, noite: "ilegivel")
  tamanhoPlaca = 13,    -- nivel e vida nas placas de nome (o padrao do ElvUI e 11)
}

-- Vida em pontos, atual / maxima (pedido do dono em 2026-11-06). Tags do ElvUI
-- 16.01 no modo moderno (Tags\Modern.lua): o numero sai inteiro (longvalue) e
-- o ElvUI passa o valor da Blizzard direto, sem ler o valor secreto.
local VIDA = "||cFF29CC00[health:current:longvalue] / [health:max:longvalue]||r"
local RECURSO = "||cFF007ACC[perpp<%]||r" -- o padrao do ElvUI no Forever
-- Mana do jogador em numeros, atual / maxima, como a vida (dono, 2026-11-08,
-- madrugada: "preciso que a quantidade de mana seja displayed (em numeros)");
-- era o RECURSO_JOGADOR, sobre a barra de vida. O alvo continua em %
-- (decisao do modder: bicho sem mana mostraria "0 / 100" de furia).
-- Jogador, 2026-11-08 (tarde): numero e % da vida na barra verde, numero e % da
-- mana na barra azul (dono: "tanto em vida quanto em mana vai ter o numero
-- absoluto e a porcentagem"; o numero da mana sai de cima da barra de vida e
-- vai para a barra de mana). A mana fica em branco: o azul de antes some na
-- barra azul (decisao do modder). Tags do modo moderno, como as da vida.
local VIDA_PCT = "||cFF29CC00[perhp<%]||r"
local MANA = "||cFFFFFFFF[power:current:longvalue] / [power:max:longvalue]||r"
local MANA_PCT = "||cFFFFFFFF[perpp<%]||r"

local function numero(caminho, novo, padrao)
  local valor = padrao
  if NUMEROS.ligado then valor = novo end
  table.insert(UIForeverConfig.elvui, { caminho, valor })
end

-- barra: "Health" (padrao) ou "Power" (CustomText.lua:42 do ElvUI 16.01 aceita)
local function textoProprio(formato, lado, x, barra)
  return {
    enable = NUMEROS.ligado, text_format = formato, attachTextTo = barra or "Health",
    justifyH = lado, xOffset = x, yOffset = 0,
    font = NUMEROS.fonte, size = NUMEROS.tamanhoQuadro, fontOutline = NUMEROS.contorno,
  }
end

-- quadros do jogador e do alvo. Jogador: na vida, numero a esquerda e % a
-- direita; na mana, o mesmo. Alvo: vida a direita e recurso em % a esquerda,
-- os dois sobre a barra de vida (como o texto padrao).
-- Desfazer o do jogador: voltar este bloco ao commit db3abcb e por enable = false
-- em UIForeverVidaPct e UIForeverRecursoPct (o UIForever nao apaga texto que sai
-- da lista), depois /reload; ou o backup do WTF sessoes\2026-11-08_1451.
local TEXTOS = {
  player = {
    { "UIForeverVida", VIDA, "LEFT", 2 },
    { "UIForeverVidaPct", VIDA_PCT, "RIGHT", -2 },
    { "UIForeverRecurso", MANA, "LEFT", 2, "Power" },
    { "UIForeverRecursoPct", MANA_PCT, "RIGHT", -2, "Power" },
  },
  target = {
    { "UIForeverVida", VIDA, "RIGHT", -2 },
    { "UIForeverRecurso", RECURSO, "LEFT", 2 },
  },
}
for unidade, textos in pairs(TEXTOS) do
  local base = "unitframe.units." .. unidade
  numero(base .. ".health.text_format", "", VIDA)
  numero(base .. ".power.text_format", "", RECURSO)
  for _, t in ipairs(textos) do
    table.insert(UIForeverConfig.elvui, { base .. ".customTexts." .. t[1], textoProprio(t[2], t[3], t[4], t[5]) })
  end
  numero(base .. ".castbar.customTimeFont.enable", true, false) -- tempo da barra de lancamento
  numero(base .. ".castbar.customTimeFont.font", NUMEROS.fonte, "PT Sans Narrow")
end

-- Nivel do alvo (dono, 2026-11-06, noite: "o nivel do nightsaber esta ilegivel").
-- No ElvUI o nivel vem na mesma linha do nome, na Homespun 10 de pixel, no painel
-- de info embaixo do quadro, e por isso a 0.4.0 o deixou de fora. Agora o nivel
-- sai do nome e vira texto proprio na ponta direita do painel, com a cor de
-- dificuldade e o "+" de elite; o nome continua no centro, na fonte de antes.
numero("unitframe.units.target.name.text_format", "[classcolor][name]",
  "[classcolor][name] [difficultycolor][smartlevel] [shortclassification]")
table.insert(UIForeverConfig.elvui, { "unitframe.units.target.customTexts.UIForeverNivel", {
  enable = NUMEROS.ligado, text_format = "[difficultycolor][smartlevel][shortclassification]",
  attachTextTo = "InfoPanel", justifyH = "RIGHT", xOffset = -4, yOffset = 0,
  font = NUMEROS.fonte, size = NUMEROS.tamanhoNivel, fontOutline = NUMEROS.contorno,
} })

-- 1c. Quadro do pet legivel (dono, 2026-11-06, noite: "como eu cuido do meu pet,
-- com uma UI aceitavel"). A barra do pet ja muda de cor com a felicidade
-- (health.colorHappiness, padrao do ElvUI no Forever: verde Happy, amarelo
-- Content, vermelho Unhappy). Sobre ela, em Expressway: a felicidade em palavra,
-- na mesma cor, a esquerda (tags happiness:color e happiness:full do ElvUI, que
-- so existem no cacador com pet), e a vida em % a direita. O nome fica no centro.
-- Para desfazer: PET.ligado = false e /reload.
local PET = { ligado = true }
for nome, texto in pairs({
  UIForeverFelicidade = { "[happiness:color][happiness:full]", "LEFT", 2 },
  UIForeverVidaPet = { "||cFF29CC00[perhp<%]||r", "RIGHT", -2 },
}) do
  local t = textoProprio(texto[1], texto[2], texto[3])
  t.enable = PET.ligado
  table.insert(UIForeverConfig.elvui, { "unitframe.units.pet.customTexts." .. nome, t })
end

-- contagem das auras nos quadros (pilhas)
for _, unidade in ipairs({ "player", "target", "pet", "targettarget", "focus" }) do
  for _, grupo in ipairs({ "buffs", "debuffs", "auras" }) do
    numero("unitframe.units." .. unidade .. "." .. grupo .. ".countFont", NUMEROS.fonte, "PT Sans Narrow")
  end
end

-- botoes: a tecla (1 a 6, S1, C1...) e a contagem (municao, cargas, reagentes);
-- o nome da macro e texto e fica de fora
for _, barra in ipairs({ "bar1", "bar2", "bar3", "bar4", "bar5", "bar6", "barPet", "stanceBar" }) do
  local base = "actionbar." .. barra
  numero(base .. ".hotkeyFont", NUMEROS.fonte, "Homespun")
  numero(base .. ".hotkeyFontOutline", NUMEROS.contorno, "MONOCHROMEOUTLINE")
  numero(base .. ".hotkeyFontSize", NUMEROS.tamanhoBotao, 10)
  numero(base .. ".countFont", NUMEROS.fonte, "Homespun")
  numero(base .. ".countFontOutline", NUMEROS.contorno, "MONOCHROMEOUTLINE")
  numero(base .. ".countFontSize", NUMEROS.tamanhoBotao, 10)
end

-- auras perto do minimapa: a contagem (o tempo ja sai em Expressway)
for _, grupo in ipairs({ "buffs", "debuffs" }) do
  numero("auras." .. grupo .. ".countFont", NUMEROS.fonte, "Homespun")
  numero("auras." .. grupo .. ".countFontOutline", NUMEROS.contorno, "MONOCHROMEOUTLINE")
  numero("auras." .. grupo .. ".countFontSize", NUMEROS.tamanhoBotao, 10)
end

-- placas de nome: o percentual de vida e o nivel (o nome fica)
for _, placa in ipairs({ "FRIENDLY_PLAYER", "FRIENDLY_NPC", "ENEMY_PLAYER", "ENEMY_NPC" }) do
  numero("nameplates.units." .. placa .. ".health.text.font", NUMEROS.fonte, "PT Sans Narrow")
  numero("nameplates.units." .. placa .. ".level.font", NUMEROS.fonte, "PT Sans Narrow")
  numero("nameplates.units." .. placa .. ".health.text.fontSize", NUMEROS.tamanhoPlaca, 11)
  numero("nameplates.units." .. placa .. ".level.fontSize", NUMEROS.tamanhoPlaca, 11)
end

-- barra de vida do tooltip
numero("tooltip.healthBar.font", NUMEROS.fonte, "PT Sans Narrow")

-- Fontes de numero da propria Blizzard (contagem de itens nas bolsas do
-- Baganator e nas janelas do jogo, NumberFontNormal e afins): o ElvUI as poe na
-- fonte geral; o UIForever troca so a fonte, mantendo tamanho e contorno, logo
-- depois de cada E:UpdateBlizzardFonts (UIForever.lua, secao 1b).
UIForeverConfig.fonteNumeros = { ligado = NUMEROS.ligado, fonte = NUMEROS.fonte }

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

  -- J abre o GuiaForever (dono, 2026-11-05, noite); tira a J da janela de guilda,
  -- que continua no menu do jogo.
  { "J", "GUIAFOREVER_JANELA" },
}

-- 4. O que fica em cada botao, por classe. Slot = numero da acao:
-- barra 1 = 1 a 12, barra 2 (rodape) = 13 a 21, barra 3 = 25 a 36,
-- barra 6 (acima do chat da direita, so clique) = 61 a 66.
-- { macro = "nome" } usa a macro se ela existir; { magia = "nome" } usa a magia
-- se o personagem ja a conhece (nome em ingles, cliente enUS). Os dois juntos:
-- a macro vence. Magia aprendida depois entra sozinha no slot dela, se o slot
-- estiver vazio. Desde a 0.2.0 o que o dono pos ou tirou de um slot fica: o
-- UIForever so mexe no slot enquanto ele tiver o que o proprio UIForever pos.
UIForeverConfig.gerenciados = { { 1, 12 }, { 13, 21 }, { 25, 36 }, { 49, 59 }, { 61, 66 } }

UIForeverConfig.barras = {
  -- Hexumlite (BM). Magias e niveis: Method, guia de leveling de cacador de
  -- 03/11 (ficha do personagem). Macros: GuiaForever (Gladius e leak).
  HUNTER = {
    -- barra 1: 1 2 3 4 5 6 Q E R F T G
    [1] = { macro = "sting_Auto", magia = "Serpent Sting" },  -- macro do GuiaForever (dono, 2026-11-05)
    [2] = { magia = "Arcane Shot" },
    [3] = { magia = "Multi-Shot" },
    [4] = { magia = "Aimed Shot" },
    [5] = { macro = "mark_Conc", magia = "Hunter's Mark" },  -- marca e manda o pet, depois Concussive Shot (dono, 2026-11-06, noite); antes mark_Pet (leak) e a do Gladius
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
    [16] = { macro = "feed_Pet", magia = "Feed Pet" },  -- macro criada pelo GuiaForever depois de aprender o Feed Pet; ate la vale a magia (dono, 2026-11-06)
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
    -- barra 5 (recargas da rotacao, sem tecla): slots 49 a 59 sem plano fixo; as
    -- magias vem de UIForeverConfig.barraRecargas.HUNTER, na ordem, sem buracos
    -- barra 6 (clique)
    [61] = { magia = "Track Beasts" },
    [62] = { magia = "Track Humanoids" },
    [63] = { magia = "Track Hidden" },
    [64] = { magia = "Track Undead" },
    [65] = { magia = "Beast Lore" },
    [66] = { macro = "Attack_Speed" },
  },
}

-- 4b. Barra 5 compacta (0.6.0). Para cada classe, as magias na ordem do nivel em
-- que chegam (Method; Mongoose Bite e Immolation Trap pelo Kargoz e pela
-- MetaGoblin; as armadilhas dividem 30 s, Aimed Shot divide a recarga com o
-- Multi-Shot, Summon Hawk divide 6 s com o Arcane Shot). So as que o personagem
-- ja conhece entram, nos slots seguidos a partir do 49, e a barra 5 do ElvUI
-- ganha esse numero de botoes (minimo 1), centrada no mover dela.
UIForeverConfig.barraRecargas = {
  HUNTER = { "Raptor Strike", "Arcane Shot", "Concussive Shot", "Mongoose Bite", "Immolation Trap",
    "Multi-Shot", "Aimed Shot", "Summon Hawk", "Rapid Fire", "Intimidation", "Bestial Wrath" },
}

-- 4c. Margem das janelas do jogo (0.6.0, dono, 2026-11-06). O RestedXP fica no
-- alto a esquerda e o painel Agora do GuiaForever logo embaixo dele; vendedor,
-- missao, treinador, talentos e livro abrem a direita dessa coluna. A margem e a
-- borda direita da coluna (lado esquerdo do RXPFrame mais o maior entre a largura
-- dele e a do GuiaForeverAgora, ou larguraMinima se o painel nao existir) mais
-- folga. Desligado, ou sem RestedXP, a margem volta ao padrao do jogo (16).
UIForeverConfig.margemJanelas = { ligado = true, folga = 8, larguraMinima = 360 }

-- 4d. Chat da esquerda de volta no painel de baixo (0.6.0). O Edit Mode da
-- Blizzard reposiciona o ChatFrame1 e o ElvUI so o devolve ao LeftChatPanel se o
-- achar sobre o painel; ver UIForever.lua, secao 9.
UIForeverConfig.chatNoPainel = true

-- 5. Opcoes do menu do jogo (CVars), gravadas pela API oficial (SetCVar).
-- Cada linha e gravada uma vez por personagem, quando o valor daqui muda; o que
-- o dono mudar depois no menu fica ate este arquivo mudar aquela linha.
-- Pedido do dono em 2026-11-05.
UIForeverConfig.cvars = {
  -- Options > Controls > Auto Loot
  { "autoLootDefault", "1" },
  -- Options > Nameplates > NPC Names = All NPCs: nome em todo NPC, de qualquer
  -- cor (escolha do dono). Sao os cinco CVars que o proprio menu grava nessa
  -- opcao (Blizzard_SettingsDefinitions_Frame/Nameplates.lua do Forever).
  { "UnitNameNPC", "1" },
  { "UnitNameHostleNPC", "0" },
  { "UnitNameInteractiveNPC", "0" },
  { "UnitNameFriendlySpecialNPCName", "0" },
  { "ShowQuestUnitCircles", "1" },
  -- Timers nativos do Forever (pedido do dono em 2026-11-05, noite: "timer de
  -- auto attack e outros timers uteis"). Os dois sao da Blizzard e lidam com
  -- os valores secretos de combate por dentro, o que addon nao consegue.
  -- Swing Timer (Options > Advanced): barras de mao principal (melee weave) e a
  -- distancia (Auto Shot), addon Blizzard_SwingTimer, so no Forever. Lugar,
  -- tamanho e "sempre / em combate" ficam no Edit Mode.
  { "showSwingTimer", "1" },
  -- Cooldown Manager (Options > Advanced > Enable Cooldown Manager): recargas e
  -- buffs escolhidos no painel dele, dentro do jogo. Desligado em 2026-11-06,
  -- noite, por escolha do dono: a barra de recargas da rotacao (barra 5) faz o
  -- papel, e os icones pequenos dele, sem magias escolhidas, so duplicavam.
  { "cooldownViewerEnabled", "0" },
  -- M abre o mapa maximizado (dono, 2026-11-08: "o mapa do M e pequeno demais").
  -- E o mesmo CVar que o botao de maximizar do mapa grava
  -- (QuestLogOwnerMixin:HandleUserActionMaximizeSelf); o botao de minimizar
  -- volta para a janela e fica, porque esta linha so e gravada uma vez.
  { "miniWorldMap", "0" },
}

-- 6. Barra de experiencia com a cara original da Blizzard (pedido do dono em
-- 2026-11-05), no lugar da barra de XP do ElvUI: o proprio modelo da barra do
-- Forever (ExpStatusBarTemplate), a moldura e os 20 segmentos do container da
-- Blizzard, mais um trecho com a XP das quests do log e, no tooltip, o que
-- falta para o proximo nivel. O texto da barra segue a opcao do jogo (aparece
-- ao passar o mouse, ou sempre, se o "status text" estiver ligado).
UIForeverConfig.barraXP = {
  ligada = true,
  -- metade do comprimento (dono, 2026-11-08), como a propria Blizzard faz no
  -- modo de controle: STATUS_BAR_CONTAINER_WIDTH_GAMEPAD = 1192 / 2 e
  -- STATUS_BAR_NUM_SEGMENTS_GAMEPAD = 20 / 2 (Camelot\StatusTrackingBarConstants.lua).
  -- Para voltar ao tamanho cheio: 1192 e 20.
  largura = 596,  -- era 1192 (STATUS_BAR_CONTAINER_WIDTH)
  altura = 17,    -- STATUS_BAR_CONTAINER_HEIGHT
  segmentos = 10, -- era 20 (STATUS_BAR_NUM_SEGMENTS)
  -- sem "ponto", a barra fica onde estava a barra de XP do ElvUI; para mudar:
  -- ponto = { "BOTTOM", "UIParent", "BOTTOM", 0, 44 },
  corQuests = { r = 1, g = 0.82, b = 0, a = 0.7 }, -- trecho das quests (amarelo de quest)
}

-- 7. Icones de cidade do Questie no minimapa e no mapa (dono, 2026-11-08: "o
-- icone dos vendedores e etc tem que aparecer no meu minimapa, tudo de
-- relevante tem de aparecer no minimapa"). Nomes das categorias do Questie
-- (QuestieMenu.lua e Townsfolk.lua). Os treinadores das profissoes que o
-- personagem tem ja aparecem ("Known Professions", ligado no Questie).
-- Estabulo, municao e comida de pet so existem para o cacador. Cada item so e
-- gravado quando entra nesta lista; o que o dono desmarcar depois no menu do
-- Questie (botao do Questie no minimapa) fica desmarcado.
UIForeverConfig.questie = {
  ligado = true,
  cidade = {
    "Repair", "Innkeeper", "Flight Master", "Stable Master", "Mailbox", "Banker", "Auctioneer",
    "Class Trainer", "Weapon Master",
    -- vendedores (submenu Vendor do Questie); Trade Goods tem linha e sal do Leatherworking
    "Ammo", "Pet Food", "Food", "Drink", "Bags", "Trade Goods",
  },
  escalaMinimapa = 1.0, -- tamanho dos icones de cidade no minimapa (o padrao do Questie e 0.7)
}

-- 8. Dragao do elite no retrato do alvo (dono, 2026-11-08: "preciso que seja
-- melhor indicado visualmente quando um inimigo e elite, eu gosto do dragao
-- dourado da UI da Blizzard"). A arte e a regra sao as do quadro de alvo da
-- Blizzard no Forever: elite = dragao dourado, chefe = dourado com asas, raro e
-- raro elite = prateado com asas. escala = 1 e o tamanho da Blizzard (em volta
-- de um retrato redondo de 58, aqui imaginario e centrado no retrato do ElvUI);
-- x (para fora do retrato) e y (para cima) acertam a posicao depois de ver no
-- jogo. Desligar: ligado = false e /reload.
UIForeverConfig.elite = { ligado = true, escala = 1.0, x = 0, y = 0 }
