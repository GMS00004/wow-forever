-- !KitAmigo: deixa o kit do amigo pronto no primeiro login, sem configurar nada no jogo.
-- O amigo nao fala ingles: todo texto que ele ve sai em portugues.
-- 1. Semente do Leatrix Plus. Este arquivo roda antes do Leatrix (o "!" no nome da pasta
--    carrega primeiro, como o !BugGrabber). Enquanto o Leatrix nao tem arquivo salvo, o jogo
--    nao troca a global, e o Leatrix le estes valores no ADDON_LOADED dele (LoadVarChk).
--    Com arquivo salvo, vale o que esta salvo (a escolha dele no /ltp manda).
-- 2. Saque automatico, uma vez por personagem (CVar autoLootDefault), fora de combate.
-- 3. Boas-vindas em portugues, uma vez por conta; /kit mostra de novo. Com o jogo fora do
--    portugues, a janela diz como trocar o idioma.
-- Texto com acento vai em escape de byte (o checar-lua.mjs exige .lua so em ASCII).

local NOME, ns = ...

local SEMENTE_LEATRIX = {
  AutoSellJunk = "On",    -- vende o lixo no vendedor
  AutoRepairGear = "On",  -- conserta no vendedor
  FasterLooting = "On",   -- saque mais rapido
}

if type(LeaPlusDB) ~= "table" then
  LeaPlusDB = {}
  for chave, valor in pairs(SEMENTE_LEATRIX) do LeaPlusDB[chave] = valor end
end

local COR = "|cff33ff99Kit do Guilherme:|r "

local LINHAS = {
  "Bem-vindo ao WoW Forever!",
  "",
  "A caixa do RestedXP mostra o pr\195\179ximo passo, e a seta leva at\195\169 l\195\161. O texto da caixa \195\169 em ingl\195\170s, mas \195\169 s\195\179 seguir a seta: ele aceita e entrega as miss\195\181es sozinho.",
  "",
  "No mapa (tecla M), o ! amarelo \195\169 miss\195\163o para pegar, e o ? \195\169 miss\195\163o para entregar.",
  "",
  "Seta verde num item quer dizer que ele \195\169 melhor que o seu.",
  "",
  "No vendedor, o lixo \195\169 vendido e o equipamento \195\169 consertado sozinhos.",
  "",
  "A tecla B abre todas as bolsas juntas.",
  "",
  "Digite /kit para ver esta janela de novo.",
}

local LINHA_IDIOMA = "Seu jogo est\195\161 em outro idioma. Para deixar em portugu\195\170s: feche o jogo, abra o Battle.net, entre nas configura\195\167\195\181es do jogo e escolha Portugu\195\170s (Brasil) no idioma do texto."

local AVISO_LEATRIX_PT = "para o vendedor vender o lixo e consertar sozinho, digite /ltp, clique em Automa\195\167\195\163o, marque Vender objetos pobres e Reparar e clique em Recarregar."
local AVISO_LEATRIX_EN = "para o vendedor vender o lixo e consertar sozinho, digite /ltp, clique em Automation, marque Sell junk automatically e Repair automatically e clique em Reload."

local function emPortugues()
  return GetLocale() == "ptBR"
end

-- fora-de-combate
local function gravarCVar(nome, valor)
  if InCombatLockdown() then return false end
  if C_CVar and C_CVar.SetCVar then return (pcall(C_CVar.SetCVar, nome, valor)) end
  if SetCVar then return (pcall(SetCVar, nome, valor)) end
  return false
end

local LINHA_BRUXO = "Voc\195\170 \195\169 bruxo: a cada n\195\173vel, uma janela diz o talento e o que aprender no instrutor. Digite /kit bruxo para ver de novo."

local function textoBemvindo()
  local linhas = {}
  for i, linha in ipairs(LINHAS) do linhas[i] = linha end
  if ns.ehBruxo and ns.ehBruxo() then
    table.insert(linhas, #linhas, LINHA_BRUXO)
    table.insert(linhas, #linhas, "")
  end
  if not emPortugues() then
    table.insert(linhas, 2, "")
    table.insert(linhas, 3, LINHA_IDIOMA)
  end
  return table.concat(linhas, "\n")
end

StaticPopupDialogs["KITAMIGO_BEMVINDO"] = {
  text = "%s",
  button1 = "Entendi",
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

local function mostrarBemvindo()
  StaticPopup_Show("KITAMIGO_BEMVINDO", textoBemvindo())
end

local function aoEntrar()
  if not KitAmigoCharDB.saque then
    if gravarCVar("autoLootDefault", "1") then KitAmigoCharDB.saque = true end
  end
  if type(LeaPlusDB) == "table" and LeaPlusDB.AutoSellJunk ~= "On" and not KitAmigoDB.avisoLeatrix then
    KitAmigoDB.avisoLeatrix = true
    print(COR .. (emPortugues() and AVISO_LEATRIX_PT or AVISO_LEATRIX_EN))
  end
  if not KitAmigoDB.bemvindo then
    KitAmigoDB.bemvindo = true
    C_Timer.After(5, mostrarBemvindo)
  end
end

local quadro = CreateFrame("Frame")
quadro:RegisterEvent("ADDON_LOADED")
quadro:RegisterEvent("PLAYER_LOGIN")
quadro:SetScript("OnEvent", function(_, evento, arg1)
  if evento == "ADDON_LOADED" and arg1 == NOME then
    KitAmigoDB = KitAmigoDB or {}
    KitAmigoCharDB = KitAmigoCharDB or {}
  elseif evento == "PLAYER_LOGIN" then
    aoEntrar()
  end
end)

SLASH_KITAMIGO1 = "/kit"
SlashCmdList["KITAMIGO"] = function(msg)
  local arg = string.lower(strtrim(msg or ""))
  if arg == "bruxo" and ns.kitBruxo and ns.kitBruxo() then return end
  mostrarBemvindo()
end
