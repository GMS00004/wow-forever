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

GuiaForeverTeclasGrupos = { "Main bar", "Shift bar", "Bar 2 and mouse", "Pet", "Other keys", "Click only (bar 6)" }

GuiaForeverTeclas = {
  HUNTER = {
    -- barra 1
    { g = "Main bar", k = "1", tecla = "1", n = 1, cheio = 4, f = "you",
      s = "sting_Auto: Auto Shot; in combat the next press casts Serpent Sting once per target (Sting from 4)" },
    { g = "Main bar", k = "2", tecla = "2", n = 6, f = "Method", s = "Arcane Shot" },
    { g = "Main bar", k = "3", tecla = "3", n = 18, f = "Method", s = "Multi-Shot (shares cooldown with Aimed Shot)" },
    { g = "Main bar", k = "4", tecla = "4", n = 20, f = "Method", s = "Aimed Shot (2 s cast)" },
    { g = "Main bar", k = "5", tecla = "5", n = 6, cheio = 10, f = "you",
      s = "mark_Conc: 1st press on a new target = Hunter's Mark and sends the pet (pet from 10); next presses = Concussive Shot when ready (from 8)" },
    { g = "Main bar", k = "6", tecla = "6", n = 26, cheio = 40, f = "leak",
      s = "Burst: Rapid Fire (26) with Bestial Wrath (40), racials and trinket 13" },
    { g = "Main bar", k = "Q", tecla = "Q", n = 1, f = "Method", s = "Raptor Strike (melee, only when melee is unavoidable)" },
    { g = "Main bar", k = "E", tecla = "E", n = 12, f = "Naowh", s = "Wing Clip (melee slow)" },
    { g = "Main bar", k = "R", tecla = "R", n = 10, cheio = 12, f = "leak",
      s = "pet_AllInOne: no pet = Call Pet; dead pet = Revive Pet; live pet = Mend Pet (12)" },
    { g = "Main bar", k = "F", tecla = "F", n = 1, f = "Method", s = "Auto Shot" },
    { g = "Main bar", k = "T", tecla = "T", n = 25, f = "Method", s = "Summon Hawk (talent; shares cooldown with Arcane Shot)" },
    { g = "Main bar", k = "G", tecla = "G", n = 16, f = "Naowh", s = "Mongoose Bite (melee, after a dodge)" },
    -- barra 3 (Shift)
    { g = "Shift bar", k = "Shift+1", tecla = "SHIFT-1", n = 10, cheio = 30, f = "leak",
      s = "aspect_Hawk: Aspect of the Hawk; with Alt, Aspect of the Beast (30)" },
    { g = "Shift bar", k = "Shift+2", tecla = "SHIFT-2", n = 4, f = "Naowh", s = "Aspect of the Monkey" },
    { g = "Shift bar", k = "Shift+3", tecla = "SHIFT-3", n = 20, cheio = 40, f = "leak",
      s = "aspect_Cheetah: Aspect of the Cheetah; with Alt, Aspect of the Pack (40)" },
    { g = "Shift bar", k = "Shift+4", tecla = "SHIFT-4", n = 28, f = "Method", s = "Frost Trap (all traps share a 30 s cooldown)" },
    { g = "Shift bar", k = "Shift+5", tecla = "SHIFT-5", n = 16, f = "Naowh", s = "Immolation Trap" },
    { g = "Shift bar", k = "Shift+6", tecla = "SHIFT-6", n = 34, f = "Naowh", s = "Explosive Trap" },
    { g = "Shift bar", k = "Shift+Q", tecla = "SHIFT-Q", n = 20, f = "Naowh", s = "Disengage" },
    { g = "Shift bar", k = "Shift+E", tecla = "SHIFT-E", n = 30, f = "Method", s = "Feign Death (can be resisted)" },
    { g = "Shift bar", k = "Shift+R", tecla = "SHIFT-R", n = 30, f = "Method", s = "Intimidation (talent; also a pet taunt)" },
    { g = "Shift bar", k = "Shift+F", tecla = "SHIFT-F", n = 32, f = "Naowh", s = "Flare" },
    { g = "Shift bar", k = "Shift+T", tecla = "SHIFT-T", n = 14, f = "Naowh", s = "Scare Beast" },
    { g = "Shift bar", k = "Shift+G", tecla = "SHIFT-G", n = 12, f = "Naowh", s = "Distracting Shot" },
    -- barra 2 e mouse
    { g = "Bar 2 and mouse", k = "Z", tecla = "Z", pet = "Growl", n = 10, f = "Gladius", s = "Taunt: pet Growl" },
    { g = "Bar 2 and mouse", k = "X", tecla = "X", n = 20, f = "leak",
      s = "cancel_Cheetah: cancels Cheetah or Pack without using the global cooldown" },
    { g = "Bar 2 and mouse", k = "V", tecla = "V", n = 1, f = "RestedXP", s = "RXPTargeting: targets the NPC or mob of the current RestedXP step" },
    { g = "Bar 2 and mouse", k = "Ctrl+1", tecla = "CTRL-1", n = 10, f = "Naowh", s = "Feed Pet" },
    { g = "Bar 2 and mouse", k = "Ctrl+2", tecla = "CTRL-2", n = 10, f = "Naowh", s = "Dismiss Pet" },
    { g = "Bar 2 and mouse", k = "Ctrl+3", tecla = "CTRL-3", n = 10, f = "Naowh", s = "Tame Beast" },
    { g = "Bar 2 and mouse", k = "Ctrl+4", tecla = "CTRL-4", n = 14, f = "Gladius", s = "eagle_Eye: Eagle Eye, recast without breaking the channel (level per Naowh)" },
    { g = "Bar 2 and mouse", k = "Mouse 4 (side)", tecla = "BUTTON4", n = 8, f = "Method", s = "Concussive Shot" },
    { g = "Bar 2 and mouse", k = "Mouse 5 (side)", tecla = "BUTTON5", n = 20, f = "Gladius",
      s = "Freezing Trap: pet goes passive, then the trap (the mob runs into it)" },
    -- pet
    { g = "Pet", k = "Shift+wheel up", tecla = "SHIFT-MOUSEWHEELUP", n = 10, f = "Gladius", s = "send_Pet: pet attacks your target" },
    { g = "Pet", k = "Shift+wheel down", tecla = "SHIFT-MOUSEWHEELDOWN", n = 10, f = "Gladius", s = "pet_Return: pet comes back (follow)" },
    { g = "Pet", k = "Middle click", tecla = "BUTTON3", n = 10, f = "Gladius", s = "move_Here: pet moves to where you click" },
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
    { g = "Click only (bar 6)", k = "bar 6", n = 10, f = "Gladius", s = "Attack_Speed: prints the target's attack speed (to pick a pet)" },
  },
}

-- Aba Keys -------------------------------------------------------------------
local _, ns = ...

local VERDE, CINZA, AMARELO, FIM = "|cff40ff40", "|cff999999", "|cffffd100", "|r"
local PROXIMOS = 6 -- niveis a frente mostrados em "Coming next"

-- Conferencia com as barras e o pet reais (fora de combate). Comando de botao de barra ->
-- slot pela tabela da secao 3 do ARQUITETURA.md; slot vazio ou pet sem a magia gera aviso cinza.
local BARRAS = {
  { "^ACTIONBUTTON(%d+)$", 0 }, { "^ELVUIBAR2BUTTON(%d+)$", 12 }, { "^MULTIACTIONBAR3BUTTON(%d+)$", 24 },
  { "^MULTIACTIONBAR4BUTTON(%d+)$", 36 }, { "^MULTIACTIONBAR2BUTTON(%d+)$", 48 }, { "^MULTIACTIONBAR1BUTTON(%d+)$", 60 },
}

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
  if txt == "" then return "" end
  return CINZA .. txt .. FIM
end

local function linha(e, n)
  local txt = AMARELO .. e.k .. FIM .. ": " .. e.s
  if e.cheio and n < e.cheio then txt = txt .. CINZA .. " (complete at " .. e.cheio .. ")" .. FIM end
  return txt .. avisoTecla(e)
end

function ns.blocosTeclas(b)
  local T, cab = ns.blocoTexto, ns.blocoCabecalho
  local lista = GuiaForeverTeclas[ns.classe()]
  if not lista then
    T(b, "No key map for this class yet.")
    return
  end
  local n = UnitLevel("player") or 1
  T(b, ns.COR .. "Your keys at level " .. n .. ns.FIM)

  local novas = {}
  for _, e in ipairs(lista) do
    if e.n == n or (e.cheio and e.cheio == n) then novas[#novas + 1] = e end
  end
  if #novas > 0 then
    cab(b, "New at this level")
    for _, e in ipairs(novas) do T(b, VERDE .. "+ " .. FIM .. linha(e, n)) end
  end

  for _, g in ipairs(GuiaForeverTeclasGrupos) do
    local doGrupo = {}
    for _, e in ipairs(lista) do
      if e.g == g and e.n <= n then doGrupo[#doGrupo + 1] = e end
    end
    if #doGrupo > 0 then
      cab(b, g)
      for _, e in ipairs(doGrupo) do T(b, linha(e, n)) end
    end
  end

  local proximas, depois = {}, {}
  for _, e in ipairs(lista) do
    if e.n > n then
      if e.n <= n + PROXIMOS then proximas[#proximas + 1] = e else depois[#depois + 1] = e end
    end
  end
  local porNivel = function(a, c) return a.n < c.n end
  table.sort(proximas, porNivel)
  table.sort(depois, porNivel)
  if #proximas > 0 then
    cab(b, "Coming next (up to level " .. (n + PROXIMOS) .. ")")
    for _, e in ipairs(proximas) do T(b, "Level " .. e.n .. ": " .. linha(e, n)) end
  end
  if #depois > 0 then
    cab(b, "Later")
    for _, e in ipairs(depois) do T(b, CINZA .. "Level " .. e.n .. ": " .. e.k .. ": " .. e.s .. FIM .. avisoTecla(e)) end
  end
  T(b, " ")
  T(b, CINZA .. "Levels: your sources (Method, Gladius, leak) and, where they give none, the Naowh Training Planner (/nftraining). Button contents: UIForever." .. FIM)
end
