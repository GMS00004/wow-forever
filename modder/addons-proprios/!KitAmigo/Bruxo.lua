-- Bruxo (Warlock) do amigo: build do Crix ("Demonology 1 to 60", sem respec), escolha do dono
-- em 2026-11-08 (ficha comum\personagens\amigo-warlock-demo.md). Tudo em portugues.
-- Ao subir de nivel: janela com o talento do nivel, o treino no instrutor (nomes do proprio
-- cliente, entao em portugues no jogo dele), as magias que o Crix pula e a missao do demonio.
-- /kit bruxo mostra de novo. Macro "Marca" (Dor Lancinante com /petattack, do Crix) criada
-- quando ele aprende a magia e posta no primeiro botao vazio da barra 1, fora de combate.
-- Treino: nivel, id da magia e preco em cobre, da tabela do NaowhForever_Training (gerada do
-- cliente 1.60.1.70790); so os fatos, sem codigo dele. Nomes de talento: Wowhead do Forever em
-- portugues (locale 8), a conferir no jogo.

local _, ns = ...

local function ehBruxo()
  local _, classe = UnitClass("player")
  return classe == "WARLOCK"
end
ns.ehBruxo = ehBruxo

local DEMO, SUP = "Demonologia", "Supl\195\173cio"
local T = {}
local function faixa(de, ate, nome, arvore, max, inicio)
  for n = de, ate do T[n] = { nome, (inicio or 1) + (n - de), max, arvore } end
end
T[10] = { "Corrup\195\167\195\163o Aprimorada", 1, 5, SUP }
faixa(11, 15, "Poder Profano", DEMO, 5)
faixa(16, 17, "Energias Demon\195\173acas", DEMO, 2)
faixa(18, 20, "Vitalidade Vil", DEMO, 3)
faixa(21, 23, "Sayaad Aprimorado", DEMO, 3)
faixa(24, 25, "Mestre-evocador", DEMO, 2)
faixa(26, 28, "Marca Demon\195\173aca", DEMO, 3)
T[29] = { "Domin\195\162ncia Vil", 1, 1, DEMO }
T[30] = { "Sacrif\195\173cio Demon\195\173aco", 1, 1, DEMO }
T[31] = { "V\195\173nculo An\195\173mico", 1, 1, DEMO }
faixa(32, 34, "Conhecimento Demon\195\173aco", DEMO, 3)
T[35] = { texto = "1 ponto livre em Demonologia (o Crix sugere Abra\195\167o Demon\195\173aco ou \195\137gide Demon\195\173aca)" }
faixa(36, 40, "Mestre Demonologista", DEMO, 5)
T[41] = { "Pacto Demon\195\173aco", 1, 1, DEMO }
faixa(42, 45, "Corrup\195\167\195\163o Aprimorada", SUP, 5, 2)
faixa(46, 50, "Supress\195\163o", SUP, 5)
local DEPOIS_50 = "1 ponto em Supl\195\173cio, nesta ordem: Pandemia, Ru\195\173na da Agonia Aprimorada (2 pontos) e Malevol\195\170ncia"

local NOTAS = {
  [10] = "Primeiro talento: abra a janela de talentos e coloque o ponto. De agora em diante, um ponto por n\195\173vel.",
  [18] = "A Dor Lancinante chegou: o bot\195\163o Marca aparece na sua barra. Comece as lutas por ele.",
  [20] = "Quando tiver a S\195\186cubo, use ela o tempo todo. O Emiss\195\161rio do Caos fica para as puxadas grandes nas masmorras.",
  [26] = "Com a Marca Demon\195\173aca, comece cada luta pelo bot\195\163o Marca: o alvo fica marcado e o dem\195\180nio bate muito mais.",
  [31] = "V\195\173nculo An\195\173mico: deixe sempre ligado, como a Armadura Demon\195\173aca.",
  [41] = "Pacto Demon\195\173aco: sacrifique o Diabrete e chame a S\195\186cubo; o b\195\180nus continua.",
}

-- { nivel, id, preco em cobre, q = missao de classe, pular = o Crix pula para economizar ouro }
local TREINO = {  { 1, 348, 10 }, -- Immolate
  { 4, 172, 100 }, -- Corruption
  { 4, 702, 100 }, -- Curse of Weakness
  { 6, 1454, 100 }, -- Life Tap
  { 6, 695, 100 }, -- Shadow Bolt
  { 8, 980, 200 }, -- Bane of Agony
  { 8, 5782, 200 }, -- Fear
  { 10, 6201, 300 }, -- Create Healthstone
  { 10, 696, 300 }, -- Demon Skin
  { 10, 1120, 300 }, -- Drain Soul
  { 10, 707, 300 }, -- Immolate
  { 10, 697, 0, q = true }, -- Summon Voidwalker
  { 12, 1108, 800 }, -- Curse of Weakness
  { 12, 755, 800 }, -- Health Funnel
  { 12, 705, 800 }, -- Shadow Bolt
  { 14, 6222, 1000 }, -- Corruption
  { 14, 704, 1000 }, -- Curse of Recklessness
  { 14, 689, 1000 }, -- Drain Life
  { 16, 1455, 1600 }, -- Life Tap
  { 16, 5697, 1600 }, -- Unending Breath
  { 18, 1014, 1700 }, -- Bane of Agony
  { 18, 693, 1700 }, -- Create Soulstone
  { 18, 5676, 1700 }, -- Searing Pain
  { 20, 440892, 2500 }, -- Curse of the Elements
  { 20, 706, 2500 }, -- Demon Armor
  { 20, 3698, 2500 }, -- Health Funnel
  { 20, 1094, 2500 }, -- Immolate
  { 20, 5740, 2500 }, -- Rain of Fire
  { 20, 698, 2500 }, -- Ritual of Summoning
  { 20, 1088, 2500 }, -- Shadow Bolt
  { 20, 713, 0, q = true }, -- Summon Incubus
  { 20, 712, 0, q = true }, -- Summon Succubus
  { 22, 6202, 3800 }, -- Create Healthstone
  { 22, 6205, 3800 }, -- Curse of Weakness
  { 22, 699, 3800 }, -- Drain Life
  { 22, 126, 3800 }, -- Eye of Kilrogg
  { 24, 6223, 4800 }, -- Corruption
  { 24, 5138, 4800, pular = true }, -- Drain Mana
  { 24, 8288, 4800 }, -- Drain Soul
  { 24, 5500, 4800 }, -- Sense Demons
  { 24, 18867, 4800 }, -- Shadowburn
  { 26, 1714, 5000 }, -- Curse of Tongues
  { 26, 132, 5000, pular = true }, -- Detect Invisibility
  { 26, 1456, 5000 }, -- Life Tap
  { 26, 17919, 5000 }, -- Searing Pain
  { 28, 6217, 6000 }, -- Bane of Agony
  { 28, 710, 6000 }, -- Banish
  { 28, 6366, 6000, pular = true }, -- Create Firestone
  { 28, 7658, 6000 }, -- Curse of Recklessness
  { 28, 3699, 6000 }, -- Health Funnel
  { 28, 1106, 6000 }, -- Shadow Bolt
  { 30, 20752, 7000 }, -- Create Soulstone
  { 30, 1311676, 7000 }, -- Curse of the Elements
  { 30, 1086, 7000 }, -- Demon Armor
  { 30, 709, 7000 }, -- Drain Life
  { 30, 1949, 7000 }, -- Hellfire
  { 30, 2941, 7000 }, -- Immolate
  { 30, 1098, 7000 }, -- Subjugate Demon
  { 30, 691, 0, q = true }, -- Summon Felhunter
  { 32, 1293818, 8000 }, -- Conflagrate
  { 32, 7646, 8000 }, -- Curse of Weakness
  { 32, 6213, 8000 }, -- Fear
  { 32, 6229, 8000 }, -- Shadow Ward
  { 32, 18868, 8000 }, -- Shadowburn
  { 34, 7648, 9000 }, -- Corruption
  { 34, 5699, 9000 }, -- Create Healthstone
  { 34, 6226, 9000, pular = true }, -- Drain Mana
  { 34, 6219, 9000 }, -- Rain of Fire
  { 34, 17920, 9000 }, -- Searing Pain
  { 36, 17951, 10000, pular = true }, -- Create Firestone
  { 36, 2362, 10000, pular = true }, -- Create Spellstone
  { 36, 3700, 10000 }, -- Health Funnel
  { 36, 11687, 10000 }, -- Life Tap
  { 36, 7641, 10000 }, -- Shadow Bolt
  { 38, 11711, 11000 }, -- Bane of Agony
  { 38, 2970, 11000, pular = true }, -- Detect Invisibility
  { 38, 7651, 11000 }, -- Drain Life
  { 38, 8289, 11000 }, -- Drain Soul
  { 38, 18879, 11000 }, -- Siphon Life
  { 40, 17962, 14000 }, -- Conflagrate
  { 40, 20755, 14000 }, -- Create Soulstone
  { 40, 1311677, 14000 }, -- Curse of the Elements
  { 40, 11733, 14000 }, -- Demon Armor
  { 40, 5484, 14000 }, -- Howl of Terror
  { 40, 11665, 14000 }, -- Immolate
  { 40, 18869, 14000 }, -- Shadowburn
  { 42, 7659, 15000 }, -- Curse of Recklessness
  { 42, 11707, 15000 }, -- Curse of Weakness
  { 42, 6789, 15000 }, -- Death Coil
  { 42, 11683, 15000 }, -- Hellfire
  { 42, 17921, 15000 }, -- Searing Pain
  { 42, 11739, 15000 }, -- Shadow Ward
  { 44, 11671, 16000 }, -- Corruption
  { 44, 11703, 16000, pular = true }, -- Drain Mana
  { 44, 11693, 16000 }, -- Health Funnel
  { 44, 11659, 16000 }, -- Shadow Bolt
  { 44, 11725, 16000 }, -- Subjugate Demon
  { 46, 17952, 20000, pular = true }, -- Create Firestone
  { 46, 11729, 20000 }, -- Create Healthstone
  { 46, 11699, 20000 }, -- Drain Life
  { 46, 11688, 20000 }, -- Life Tap
  { 46, 11677, 20000 }, -- Rain of Fire
  { 48, 11712, 21000 }, -- Bane of Agony
  { 48, 18647, 21000 }, -- Banish
  { 48, 18930, 21000 }, -- Conflagrate
  { 48, 17727, 21000, pular = true }, -- Create Spellstone
  { 48, 18870, 21000 }, -- Shadowburn
  { 48, 18880, 21000 }, -- Siphon Life
  { 48, 6353, 21000 }, -- Soul Fire
  { 50, 20756, 22000 }, -- Create Soulstone
  { 50, 11719, 22000 }, -- Curse of Tongues
  { 50, 1311680, 22000 }, -- Curse of the Elements
  { 50, 17925, 22000 }, -- Death Coil
  { 50, 11734, 22000 }, -- Demon Armor
  { 50, 11743, 22000, pular = true }, -- Detect Invisibility
  { 50, 11667, 22000 }, -- Immolate
  { 50, 1293812, 22000 }, -- Incinerate
  { 50, 1122, 0, q = true }, -- Inferno
  { 50, 17922, 22000 }, -- Searing Pain
  { 52, 11708, 23000 }, -- Curse of Weakness
  { 52, 11675, 23000 }, -- Drain Soul
  { 52, 11694, 23000 }, -- Health Funnel
  { 52, 11660, 23000 }, -- Shadow Bolt
  { 52, 11740, 23000 }, -- Shadow Ward
  { 54, 18931, 24000 }, -- Conflagrate
  { 54, 11672, 24000 }, -- Corruption
  { 54, 11700, 24000 }, -- Drain Life
  { 54, 11704, 24000, pular = true }, -- Drain Mana
  { 54, 11684, 24000 }, -- Hellfire
  { 54, 17928, 24000 }, -- Howl of Terror
  { 56, 17953, 25000, pular = true }, -- Create Firestone
  { 56, 11717, 25000 }, -- Curse of Recklessness
  { 56, 6215, 25000 }, -- Fear
  { 56, 11689, 25000 }, -- Life Tap
  { 56, 18871, 25000 }, -- Shadowburn
  { 56, 17924, 25000 }, -- Soul Fire
  { 58, 11713, 26000 }, -- Bane of Agony
  { 58, 11730, 26000 }, -- Create Healthstone
  { 58, 17926, 26000 }, -- Death Coil
  { 58, 11678, 26000 }, -- Rain of Fire
  { 58, 17923, 26000 }, -- Searing Pain
  { 58, 18881, 26000 }, -- Siphon Life
  { 58, 11726, 26000 }, -- Subjugate Demon
  { 60, 603, 27000 }, -- Bane of Doom
  { 60, 18932, 27000 }, -- Conflagrate
  { 60, 20757, 27000 }, -- Create Soulstone
  { 60, 17728, 27000, pular = true }, -- Create Spellstone
  { 60, 11735, 27000 }, -- Demon Armor
  { 60, 11695, 27000 }, -- Health Funnel
  { 60, 11668, 27000 }, -- Immolate
  { 60, 1293813, 27000 }, -- Incinerate
  { 60, 18540, 0, q = true }, -- Ritual of Doom
  { 60, 11661, 27000 }, -- Shadow Bolt
}

local function nomeMagia(id)
  if C_Spell and C_Spell.GetSpellName then
    local ok, n = pcall(C_Spell.GetSpellName, id)
    if ok and n then return n end
  end
  return nil
end

local function moeda(cobre)
  local o = math.floor(cobre / 10000)
  local p = math.floor((cobre % 10000) / 100)
  if o > 0 and p > 0 then return o .. " ouro e " .. p .. " prata" end
  if o > 0 then return o .. " ouro" end
  return p .. " prata"
end

local function textoTalento(n)
  if n < 10 then return nil end
  local t = T[n]
  if not t then return "Talento: " .. DEPOIS_50 .. "." end
  if t.texto then return "Talento: " .. t.texto .. "." end
  return string.format("Talento: %s %d/%d (\195\161rvore %s).", t[1], t[2], t[3], t[4])
end

local function linhasTreino(n)
  local aprender, pular, missao, custo = {}, {}, {}, 0
  for _, e in ipairs(TREINO) do
    if e[1] == n then
      local nome = nomeMagia(e[2])
      if nome then
        if e.q then missao[#missao + 1] = nome
        elseif e.pular then pular[#pular + 1] = nome
        else
          aprender[#aprender + 1] = nome
          custo = custo + e[3]
        end
      end
    end
  end
  local linhas = {}
  if #aprender > 0 then
    linhas[#linhas + 1] = "No instrutor de bruxo, aprenda: " .. table.concat(aprender, ", ") .. " (cerca de " .. moeda(custo) .. ")."
  end
  if #pular > 0 then
    linhas[#linhas + 1] = "Pode pular, para economizar ouro: " .. table.concat(pular, ", ") .. "."
  end
  if #missao > 0 then
    linhas[#linhas + 1] = "Dem\195\180nio novo por miss\195\163o de classe: " .. table.concat(missao, ", ") .. "."
  end
  return linhas
end

local function textoNivel(n, comProximos)
  local partes = {}
  local tal = textoTalento(n)
  if tal then partes[#partes + 1] = tal end
  for _, l in ipairs(linhasTreino(n)) do partes[#partes + 1] = l end
  if NOTAS[n] then partes[#partes + 1] = NOTAS[n] end
  if comProximos then
    local prox = {}
    for k = n + 1, math.min(n + 3, 60) do
      local t = textoTalento(k)
      if t then prox[#prox + 1] = k .. ": " .. t:gsub("^Talento: ", "") end
    end
    if #prox > 0 then partes[#partes + 1] = "Pr\195\179ximos talentos:\n" .. table.concat(prox, "\n") end
  end
  if #partes == 0 then return nil end
  return "N\195\173vel " .. n .. "\n\n" .. table.concat(partes, "\n\n") .. "\n\nDigite /kit bruxo para ver isto de novo."
end

StaticPopupDialogs["KITAMIGO_NIVEL"] = {
  text = "%s",
  button1 = "Entendi",
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

local function mostrarNivel(n, comProximos)
  local texto = textoNivel(n, comProximos)
  if texto then StaticPopup_Show("KITAMIGO_NIVEL", texto) end
end

-- /kit bruxo: o plano do nivel atual e os proximos talentos
function ns.kitBruxo()
  if not ehBruxo() then return false end
  mostrarNivel(UnitLevel("player") or 1, true)
  return true
end

-- Macro "Marca" ------------------------------------------------------------------------------
-- os seis ranks da Dor Lancinante no treino (18, 26, 34, 42, 50, 58); qualquer um serve
local DOR_LANCINANTE = { 5676, 17919, 17920, 17921, 17922, 17923 }
local NOME_MACRO = "Marca"
local TECLAS = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" }
local macroPendente = false

local function temAcao(slot)
  if C_ActionBar and C_ActionBar.HasAction then return C_ActionBar.HasAction(slot) end
  return true
end

-- fora-de-combate
local function criarMacro()
  if not KitAmigoCharDB or KitAmigoCharDB.macroFeita or not ehBruxo() then return end
  if InCombatLockdown() then macroPendente = true; return end
  macroPendente = false
  if not (C_SpellBook and C_SpellBook.IsSpellKnown) then return end
  local nome
  for _, id in ipairs(DOR_LANCINANTE) do
    local ok, sabe = pcall(C_SpellBook.IsSpellKnown, id)
    if ok and sabe then nome = nomeMagia(id); break end
  end
  if not nome then return end
  if not (CreateMacro and GetMacroIndexByName and PickupMacro and PlaceAction and ClearCursor) then return end
  local idx = GetMacroIndexByName(NOME_MACRO) or 0
  if idx == 0 then
    local corpo = "#showtooltip\n/petattack\n/cast " .. nome
    for _, icone in ipairs({ "INV_MISC_QUESTIONMARK", 134400 }) do
      local okc, r = pcall(CreateMacro, NOME_MACRO, icone, corpo, true)
      if okc and type(r) == "number" and r > 0 then idx = r; break end
    end
  end
  if idx == 0 then return end
  KitAmigoCharDB.macroFeita = true
  local slot
  for s = 1, 12 do
    if not temAcao(s) then slot = s; break end
  end
  local cor = "|cff33ff99Kit do Bruno:|r "
  if slot and not (GetCursorInfo and GetCursorInfo()) then
    ClearCursor()
    PickupMacro(idx)
    PlaceAction(slot)
    ClearCursor()
    print(cor .. "bot\195\163o novo na sua barra, na tecla " .. TECLAS[slot] .. ": Marca. Comece a luta com ele: " .. nome .. " no alvo e o dem\195\180nio ataca junto.")
  else
    print(cor .. "a macro Marca est\195\161 pronta: digite /macro e arraste a Marca para a sua barra.")
  end
end

local quadro = CreateFrame("Frame")
quadro:RegisterEvent("PLAYER_LOGIN")
quadro:RegisterEvent("SPELLS_CHANGED")
quadro:RegisterEvent("PLAYER_REGEN_ENABLED")
quadro:RegisterEvent("PLAYER_LEVEL_UP")
quadro:SetScript("OnEvent", function(_, evento, arg1)
  if not ehBruxo() then return end
  if evento == "PLAYER_LEVEL_UP" then
    local n = tonumber(arg1)
    if n then C_Timer.After(2, function() mostrarNivel(n, false) end) end
  elseif evento == "PLAYER_REGEN_ENABLED" then
    if macroPendente then criarMacro() end
  else
    criarMacro()
  end
end)