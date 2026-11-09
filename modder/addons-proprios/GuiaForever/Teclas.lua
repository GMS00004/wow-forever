-- GuiaForever: aba Keys. O que cada tecla faz e a partir de que nivel, por classe.
-- Teclas e conteudo: UIForever\Config.lua (UIForeverConfig.teclas e barras.HUNTER) e as
-- teclas proprias das macros (Dados.lua, GuiaForeverMacros). Niveis: Dicas.lua (fontes do
-- dono) e, onde as fontes nao dao o nivel, os dados do Training Planner do Naowh Forever
-- (NaowhForever_Training\Data\TrainingData.lua, "built from game build 1.60.1.70790"),
-- lidos em 2026-11-06; esses levam f = "Naowh".
-- Mapa montado em 2026-11-06 a partir do cruzamento das fontes (tarefa T4 da sessao).
-- Ao mudar uma tecla ou um botao no UIForever, mude aqui tambem.
--
-- Campos: g = grupo, k = tecla, n = nivel em que comeca a funcionar, s = o que faz,
-- f = de onde vem o conteudo do botao (e o nivel, quando f = "Naowh"),
-- cheio = nivel em que a macro fica completa (quando for depois de n).
-- Janela 1.2: id = id de magia (icone da grade, pelo magias.json); icone = caminho, ou uma
-- funcao que devolve o caminho (lida na hora, para as texturas do pet); rot = rotulo da tecla
-- como nas barras do ElvUI ("1", "Q", "S1", "C1", "M4", "SMwU"). Sem rot = so em lista (k).

GuiaForeverTeclasGrupos = { "Main bar", "Shift bar", "Bar 2 and mouse", "Pet", "Other keys", "Click only (bar 6)" }

GuiaForeverTeclas = {
  HUNTER = {
    -- barra 1
    { g = "Main bar", k = "1", tecla = "1", n = 1, cheio = 4, f = "you", rot = "1", id = 75,
      s = "sting_Auto: Auto Shot; in combat the next press casts Serpent Sting once per target (Sting from 4)" },
    { g = "Main bar", k = "2", tecla = "2", n = 6, f = "Method", rot = "2", id = 3044, s = "Arcane Shot" },
    { g = "Main bar", k = "3", tecla = "3", n = 18, f = "Method", rot = "3", id = 2643, s = "Multi-Shot (shares cooldown with Aimed Shot)" },
    { g = "Main bar", k = "4", tecla = "4", n = 20, f = "Method", rot = "4", id = 19434, s = "Aimed Shot (2 s cast)" },
    { g = "Main bar", k = "5", tecla = "5", n = 6, cheio = 10, f = "you", rot = "5", id = 1130,
      s = "mark_Conc: 1st press on a new target = Hunter's Mark and sends the pet (pet from 10); next presses = Concussive Shot when ready (from 8)" },
    { g = "Main bar", k = "6", tecla = "6", n = 26, cheio = 40, f = "leak", rot = "6", id = 3045,
      s = "Burst: Rapid Fire (26) with Bestial Wrath (40), racials and trinket 13" },
    { g = "Main bar", k = "Q", tecla = "Q", n = 1, f = "Method", rot = "Q", id = 14260, s = "Raptor Strike (melee, only when melee is unavoidable)" },
    { g = "Main bar", k = "E", tecla = "E", n = 12, f = "Naowh", rot = "E", id = 2974, s = "Wing Clip (melee slow)" },
    { g = "Main bar", k = "R", tecla = "R", n = 10, cheio = 12, f = "leak", rot = "R", id = 136,
      s = "pet_AllInOne: no pet = Call Pet; dead pet = Revive Pet; live pet = Mend Pet (12)" },
    { g = "Main bar", k = "F", tecla = "F", n = 1, f = "Method", rot = "F", id = 75, s = "Auto Shot" },
    { g = "Main bar", k = "T", tecla = "T", n = 25, f = "Method", rot = "T", id = 1293525, s = "Summon Hawk (talent; shares cooldown with Arcane Shot)" },
    { g = "Main bar", k = "G", tecla = "G", n = 16, f = "Naowh", rot = "G", id = 1495, s = "Mongoose Bite (melee, after a dodge)" },
    -- barra 3 (Shift)
    { g = "Shift bar", k = "Shift+1", tecla = "SHIFT-1", n = 10, cheio = 30, f = "leak", rot = "S1", id = 13165,
      s = "aspect_Hawk: Aspect of the Hawk; with Alt, Aspect of the Beast (30)" },
    { g = "Shift bar", k = "Shift+2", tecla = "SHIFT-2", n = 4, f = "Naowh", rot = "S2", id = 13163, s = "Aspect of the Monkey" },
    { g = "Shift bar", k = "Shift+3", tecla = "SHIFT-3", n = 20, cheio = 40, f = "leak", rot = "S3", id = 5118,
      s = "aspect_Cheetah: Aspect of the Cheetah; with Alt, Aspect of the Pack (40)" },
    { g = "Shift bar", k = "Shift+4", tecla = "SHIFT-4", n = 28, f = "Method", rot = "S4", id = 13809, s = "Frost Trap (all traps share a 30 s cooldown)" },
    { g = "Shift bar", k = "Shift+5", tecla = "SHIFT-5", n = 16, f = "Naowh", rot = "S5", id = 13795, s = "Immolation Trap" },
    { g = "Shift bar", k = "Shift+6", tecla = "SHIFT-6", n = 34, f = "Naowh", rot = "S6", id = 13813, s = "Explosive Trap" },
    { g = "Shift bar", k = "Shift+Q", tecla = "SHIFT-Q", n = 20, f = "Naowh", rot = "SQ", id = 781, s = "Disengage" },
    { g = "Shift bar", k = "Shift+E", tecla = "SHIFT-E", n = 30, f = "Method", rot = "SE", id = 5384, s = "Feign Death (can be resisted)" },
    { g = "Shift bar", k = "Shift+R", tecla = "SHIFT-R", n = 30, f = "Method", rot = "SR", id = 19577, s = "Intimidation (talent; also a pet taunt)" },
    { g = "Shift bar", k = "Shift+F", tecla = "SHIFT-F", n = 32, f = "Naowh", rot = "SF", id = 1543, s = "Flare" },
    { g = "Shift bar", k = "Shift+T", tecla = "SHIFT-T", n = 14, f = "Naowh", rot = "ST", id = 1513, s = "Scare Beast" },
    { g = "Shift bar", k = "Shift+G", tecla = "SHIFT-G", n = 12, f = "Naowh", rot = "SG", id = 20736, s = "Distracting Shot" },
    -- barra 2 e mouse
    { g = "Bar 2 and mouse", k = "Z", tecla = "Z", pet = "Growl", n = 10, f = "Gladius", rot = "Z", id = 2649, s = "Taunt: pet Growl" },
    { g = "Bar 2 and mouse", k = "X", tecla = "X", n = 20, f = "leak", rot = "X", id = 5118,
      s = "cancel_Cheetah: cancels Cheetah or Pack without using the global cooldown" },
    { g = "Bar 2 and mouse", k = "V", tecla = "V", n = 1, f = "RestedXP", rot = "V", icone = "Interface\\Icons\\INV_Misc_Map_01",
      s = "RXPTargeting: targets the NPC or mob of the current RestedXP step" },
    { g = "Bar 2 and mouse", k = "Ctrl+1", tecla = "CTRL-1", n = 10, f = "Naowh", rot = "C1", id = 6991, s = "Feed Pet" },
    { g = "Bar 2 and mouse", k = "Ctrl+2", tecla = "CTRL-2", n = 10, f = "Naowh", rot = "C2", id = 2641, s = "Dismiss Pet" },
    { g = "Bar 2 and mouse", k = "Ctrl+3", tecla = "CTRL-3", n = 10, f = "Naowh", rot = "C3", id = 1515, s = "Tame Beast" },
    { g = "Bar 2 and mouse", k = "Ctrl+4", tecla = "CTRL-4", n = 14, f = "Gladius", rot = "C4", id = 6197,
      s = "eagle_Eye: Eagle Eye, recast without breaking the channel (level per Naowh)" },
    { g = "Bar 2 and mouse", k = "Mouse 4 (side)", tecla = "BUTTON4", n = 8, f = "Method", rot = "M4", id = 5116, s = "Concussive Shot" },
    { g = "Bar 2 and mouse", k = "Mouse 5 (side)", tecla = "BUTTON5", n = 20, f = "Gladius", rot = "M5", id = 1499,
      s = "Freezing Trap: pet goes passive, then the trap (the mob runs into it)" },
    -- pet
    { g = "Pet", k = "Shift+wheel up", tecla = "SHIFT-MOUSEWHEELUP", n = 10, f = "Gladius", rot = "SMwU",
      icone = function() return _G.PET_ATTACK_TEXTURE or "Interface\\Icons\\Ability_GhoulFrenzy" end,
      s = "send_Pet: pet attacks your target" },
    { g = "Pet", k = "Shift+wheel down", tecla = "SHIFT-MOUSEWHEELDOWN", n = 10, f = "Gladius", rot = "SMwD",
      icone = function() return _G.PET_FOLLOW_TEXTURE or "Interface\\Icons\\Ability_Tracking" end,
      s = "pet_Return: pet comes back (follow)" },
    { g = "Pet", k = "Middle click", tecla = "BUTTON3", n = 10, f = "Gladius", rot = "M3",
      icone = function() return _G.PET_MOVE_TO_TEXTURE or "Interface\\Icons\\Ability_Hunter_Pet_Goto" end,
      s = "move_Here: pet moves to where you click" },
    -- outras teclas
    { g = "Other keys", k = "A / D", n = 1, f = "you", s = "strafe left / right" },
    { g = "Other keys", k = "Ctrl+X", tecla = "CTRL-X", n = 1, f = "you", s = "sit / stand (moves down in water)" },
    { g = "Other keys", k = "Ctrl+R", tecla = "CTRL-R", n = 1, f = "you", s = "reply to whisper" },
    { g = "Other keys", k = "Ctrl+V", tecla = "CTRL-V", n = 1, f = "you", s = "nameplates on / off" },
    { g = "Other keys", k = "Shift+M", tecla = "SHIFT-M", n = 1, f = "you", s = "big minimap on / off" },
    { g = "Other keys", k = "J", tecla = "J", n = 1, f = "you", s = "this guide" },
    -- barra 6, sem tecla
    { g = "Click only (bar 6)", k = "bar 6", n = 1, f = "Naowh", s = "Track Beasts" },
    { g = "Click only (bar 6)", k = "bar 6", n = 10, f = "Naowh", s = "Track Humanoids" },
    { g = "Click only (bar 6)", k = "bar 6", n = 18, f = "Naowh", s = "Track Undead" },
    { g = "Click only (bar 6)", k = "bar 6", n = 24, f = "Method", s = "Track Hidden" },
    { g = "Click only (bar 6)", k = "bar 6", n = 24, f = "Naowh", s = "Beast Lore" },
    { g = "Click only (bar 6)", k = "bar 6", n = 10, f = "Gladius", s = "Attack_Speed: prints the target's attack speed" },
  },
  PALADIN = {
    -- barra 1
    { g = "Main bar", k = "1", tecla = "1", n = 6, f = "Jurdi", rot = "1", id = 679,
      s = "strike_Holy: starts auto attack and casts Holy Strike" },
    { g = "Main bar", k = "2", tecla = "2", n = 4, f = "Jurdi", rot = "2", id = 20271,
      s = "judge_Start: starts auto attack and casts Judgement" },
    { g = "Main bar", k = "3", tecla = "3", n = 10, f = "Naowh", rot = "3", id = 1311649, s = "Seal of Fury" },
    { g = "Main bar", k = "4", tecla = "4", n = 20, f = "Naowh", rot = "4", id = 26573, s = "Consecration" },
    { g = "Main bar", k = "5", tecla = "5", n = 20, f = "Naowh", rot = "5", id = 879, s = "Exorcism" },
    { g = "Main bar", k = "6", tecla = "6", n = 44, f = "Naowh", rot = "6", id = 24275, s = "Hammer of Wrath" },
    { g = "Main bar", k = "Q", tecla = "Q", n = 8, f = "Naowh", rot = "Q", id = 853, s = "Hammer of Justice" },
    { g = "Main bar", k = "E", tecla = "E", n = 42, f = "Naowh", rot = "E", id = 20927, s = "Holy Shield (talent)" },
    { g = "Main bar", k = "R", tecla = "R", n = 20, f = "Naowh", rot = "R", id = 19750, s = "Flash of Light" },
    { g = "Main bar", k = "F", tecla = "F", n = 1, f = "Deadmanfred", rot = "F",
      icone = "Interface\\Icons\\Ability_MeleeDamage", s = "attack_Start: starts auto attack" },
    { g = "Main bar", k = "T", tecla = "T", n = 10, f = "Naowh", rot = "T", id = 633, s = "Lay on Hands" },
    { g = "Main bar", k = "G", tecla = "G", n = 34, f = "Jurdi", rot = "G", id = 642,
      s = "bubble_Cancel: Divine Shield; press again to cancel it (careful in the open world)" },
    -- barra 3 (Shift)
    { g = "Shift bar", k = "Shift+1", tecla = "SHIFT-1", n = 10, f = "Naowh", rot = "S1", id = 25780, s = "Righteous Fury" },
    { g = "Shift bar", k = "Shift+2", tecla = "SHIFT-2", n = 16, f = "Naowh", rot = "S2", id = 7294, s = "Retribution Aura" },
    { g = "Shift bar", k = "Shift+3", tecla = "SHIFT-3", n = 20, f = "Naowh", rot = "S3", id = 20217, s = "Blessing of Kings" },
    { g = "Shift bar", k = "Shift+4", tecla = "SHIFT-4", n = 4, f = "Naowh", rot = "S4", id = 19740, s = "Blessing of Might" },
    { g = "Shift bar", k = "Shift+5", tecla = "SHIFT-5", n = 6, f = "Naowh", rot = "S5", id = 639, s = "Holy Light" },
    { g = "Shift bar", k = "Shift+6", tecla = "SHIFT-6", n = 1, f = "Naowh", rot = "S6", id = 465, s = "Devotion Aura" },
    { g = "Shift bar", k = "Shift+Q", tecla = "SHIFT-Q", n = 6, f = "Naowh", rot = "SQ", id = 498, s = "Divine Protection" },
    { g = "Shift bar", k = "Shift+E", tecla = "SHIFT-E", n = 6, f = "Naowh", rot = "SE", id = 21082, s = "Seal of the Crusader" },
    { g = "Shift bar", k = "Shift+R", tecla = "SHIFT-R", n = 10, f = "Naowh", rot = "SR", id = 20287, s = "Seal of Righteousness" },
    { g = "Shift bar", k = "Shift+F", tecla = "SHIFT-F", n = 12, f = "Naowh", rot = "SF", id = 7328, s = "Redemption" },
    { g = "Shift bar", k = "Shift+T", tecla = "SHIFT-T", n = 30, f = "Naowh", rot = "ST", id = 20165, s = "Seal of Light" },
    { g = "Shift bar", k = "Shift+G", tecla = "SHIFT-G", n = 30, f = "Naowh", rot = "SG", id = 19752, s = "Divine Intervention" },
    -- barra 2 e mouse
    { g = "Bar 2 and mouse", k = "Z", tecla = "Z", n = 14, f = "Naowh", rot = "Z", id = 19742, s = "Blessing of Wisdom" },
    { g = "Bar 2 and mouse", k = "X", tecla = "X", n = 8, cheio = 42, f = "Jurdi", rot = "X", id = 1152,
      s = "cleanse_Mouse: Purify on mouseover (Cleanse from 42)" },
    { g = "Bar 2 and mouse", k = "V", tecla = "V", n = 1, f = "RestedXP", rot = "V", icone = "Interface\\Icons\\INV_Misc_Map_01",
      s = "RXPTargeting: targets the NPC or mob of the current RestedXP step" },
    { g = "Bar 2 and mouse", k = "Ctrl+1", tecla = "CTRL-1", n = 22, f = "Naowh", rot = "C1", id = 20164, s = "Seal of Justice" },
    { g = "Bar 2 and mouse", k = "Ctrl+2", tecla = "CTRL-2", n = 22, f = "Naowh", rot = "C2", id = 19746, s = "Concentration Aura" },
    { g = "Bar 2 and mouse", k = "Ctrl+3", tecla = "CTRL-3", n = 24, f = "Naowh", rot = "C3", id = 2878, s = "Turn Undead" },
    { g = "Bar 2 and mouse", k = "Ctrl+4", tecla = "CTRL-4", n = 38, f = "Naowh", rot = "C4", id = 20166, s = "Seal of Wisdom" },
    { g = "Bar 2 and mouse", k = "Mouse 4 (side)", tecla = "BUTTON4", n = 10, f = "Jurdi", rot = "M4", id = 1022,
      s = "bop_Mouse: Blessing of Protection on mouseover, else target or you; press again to cancel yours" },
    { g = "Bar 2 and mouse", k = "Mouse 5 (side)", tecla = "BUTTON5", n = 18, f = "Jurdi", rot = "M5", id = 1044,
      s = "bof_Mouse: Blessing of Freedom on mouseover, else target or you" },
    -- outras teclas
    { g = "Other keys", k = "A / D", n = 1, f = "you", s = "strafe left / right" },
    { g = "Other keys", k = "Ctrl+X", tecla = "CTRL-X", n = 1, f = "you", s = "sit / stand (moves down in water)" },
    { g = "Other keys", k = "Ctrl+R", tecla = "CTRL-R", n = 1, f = "you", s = "reply to whisper" },
    { g = "Other keys", k = "Ctrl+V", tecla = "CTRL-V", n = 1, f = "you", s = "nameplates on / off" },
    { g = "Other keys", k = "Shift+M", tecla = "SHIFT-M", n = 1, f = "you", s = "big minimap on / off" },
    { g = "Other keys", k = "J", tecla = "J", n = 1, f = "you", s = "this guide" },
  },
}

-- Aba Keys (janela 1.2) ----------------------------------------------------------------
local _, ns = ...

local PROXIMOS = 6 -- niveis a frente mostrados em "Coming next"
local GRADE = { "Main bar", "Shift bar", "Bar 2 and mouse", "Pet" } -- grupos desenhados como barras
local FORA_GRADE = { ["Other keys"] = true, ["Click only (bar 6)"] = true }
local ESPACO = { ["6"] = true, S6 = true, V = true, C4 = true } -- espaco depois destas teclas, como nas barras

-- Conferencia com as barras e o pet reais (fora de combate). Comando de botao de barra ->
-- slot pela tabela da secao 3 do ARQUITETURA.md; slot vazio ou pet sem a magia gera aviso.
local BARRAS = {
  { "^ACTIONBUTTON(%d+)$", 0 }, { "^ELVUIBAR2BUTTON(%d+)$", 12 }, { "^MULTIACTIONBAR3BUTTON(%d+)$", 24 },
  { "^MULTIACTIONBAR4BUTTON(%d+)$", 36 }, { "^MULTIACTIONBAR2BUTTON(%d+)$", 48 }, { "^MULTIACTIONBAR1BUTTON(%d+)$", 60 },
}

-- Avisos de hoje, em texto puro (sem codigo de cor). Comeca com espaco quando ha aviso.
local function avisoTecla(e)
  if not e.tecla then return "" end
  if InCombatLockdown and InCombatLockdown() then return "" end
  local txt = ""
  if GetBindingAction and GetActionInfo then
    local cmd = GetBindingAction(e.tecla)
    if type(cmd) == "string" then
      for _, b in ipairs(BARRAS) do
        local casa = tonumber(string.match(cmd, b[1]) or "")
        if casa and casa >= 1 and casa <= 12 then
          if GetActionInfo(b[2] + casa) == nil then txt = txt .. " (empty button)" end
          break
        end
      end
    end
  end
  -- so com o pet fora: com ele guardado o livro do pet vem vazio e o aviso mentiria
  local petFora = ns.estado and ns.estado.pet and ns.estado.pet.existe
  if e.pet and ns.petConhece and petFora then
    local ok, sabe = pcall(ns.petConhece, e.pet)
    if ok and sabe == false then txt = txt .. " (your pet must learn " .. e.pet .. " first)" end
  end
  return txt
end

-- Icone da tecla: id de magia, caminho, ou a funcao que devolve o caminho (lida na hora).
local function iconeDe(e)
  local i = e.icone
  if type(i) == "function" then
    local ok, v = pcall(i)
    i = ok and v or nil
  end
  if i == nil then i = e.id end
  return i
end

-- Nome curto: o texto antes de ":", "(" ou ";" (o nome da macro ou da magia).
local function nomeDe(e)
  local nome = string.match(e.s, "^([^:(;]+)") or e.s
  return (string.gsub(nome, "%s+$", ""))
end

-- Explicacao da tecla: o que faz, quando completa e os avisos de hoje.
local function explicacaoDe(e, n)
  local txt = (string.gsub(e.s, " %(level per Naowh%)", ""))
  if e.cheio and n < e.cheio then txt = txt .. " Complete at " .. e.cheio .. "." end
  return txt .. avisoTecla(e)
end

local function estadoDe(e, n)
  if e.n > n then return "travado" end
  if e.n == n or e.cheio == n then return "novo" end
  return nil
end

local function tecla(e, n)
  local estado = estadoDe(e, n)
  return {
    k = e.rot, icone = iconeDe(e), nome = nomeDe(e), estado = estado,
    nivel = (estado == "travado") and e.n or nil, dica = explicacaoDe(e, n),
  }
end

function ns.blocosTeclas(b, ctx)
  local lista = GuiaForeverTeclas[ns.classe()]
  if not lista then
    b[#b + 1] = { t = "vazio", s = "No key map for this class yet." }
    return
  end
  local n = UnitLevel("player") or 1

  b[#b + 1] = { t = "sec", s = "Your keys", qtd = "level " .. n, id = "teclas-tuas" }
  for _, g in ipairs(GRADE) do
    local teclas = {}
    for _, e in ipairs(lista) do
      if e.g == g then
        teclas[#teclas + 1] = tecla(e, n)
        if ESPACO[e.rot] then teclas[#teclas + 1] = false end
      end
    end
    if #teclas > 0 then b[#b + 1] = { t = "grade", titulo = g, teclas = teclas } end
  end

  -- proximas: teclas das grades que chegam em ate PROXIMOS niveis, na ordem de nivel
  local proximas = {}
  for i, e in ipairs(lista) do
    if e.rot and e.n > n and e.n <= n + PROXIMOS then proximas[#proximas + 1] = { e = e, i = i } end
  end
  table.sort(proximas, function(a, c)
    if a.e.n ~= c.e.n then return a.e.n < c.e.n end
    return a.i < c.i
  end)
  if #proximas > 0 then
    b[#b + 1] = { t = "sec", s = "Coming next", qtd = "up to level " .. (n + PROXIMOS), id = "teclas-proximas" }
    local ultimo
    for _, p in ipairs(proximas) do
      local e = p.e
      b[#b + 1] = {
        t = "item", nivel = (e.n ~= ultimo) and e.n or "", icone = iconeDe(e), tecla = e.rot,
        s = nomeDe(e), dica = explicacaoDe(e, n),
      }
      ultimo = e.n
    end
  end

  -- fora das grades: recolhida, uma linha por tecla (k curto; o que faz em s)
  local outras = {}
  for _, e in ipairs(lista) do
    if FORA_GRADE[e.g] then outras[#outras + 1] = e end
  end
  if #outras > 0 then
    b[#b + 1] = { t = "sec", s = "Other keys", qtd = tostring(#outras), aberta = false, id = "teclas-outras" }
    for _, e in ipairs(outras) do
      b[#b + 1] = { t = "item", nivel = (e.n > 1) and e.n or "", tecla = e.k, s = e.s, apagado = (e.n > n) or nil }
    end
  end
end
