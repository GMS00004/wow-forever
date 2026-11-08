-- GuiaForever: Painel Agora embaixo do RestedXP (tarefa A6; contrato em ARQUITETURA.md, secao 4).
-- Ate 4 linhas "o que fazer agora", cada uma com um botao. As linhas nascem e somem pelos eventos
-- dos provedores; o painel some em combate. Nenhum outro arquivo depende deste existir (regra 3):
-- quem quiser entrar chama `if ns.agora and ns.agora.provedor then ... end`.
-- Os botoes so chamam funcoes Lua (seta, janela, Naowh), nunca magia (regra 7); nada protegido aqui (regra 4).

local _, ns = ...

ns.agora = ns.agora or {}
local A = ns.agora

local LARGURA, ALT_LINHA, ALT_TITULO, MAX_LINHAS = 360, 26, 22, 4
local ALT_RODAPE, LARG_BOTAO = 16, 54
local LARG_TEXTO = LARGURA - 34 - 6 - LARG_BOTAO - 6

local CORES = {
  vermelho = { 0.9, 0.2, 0.2 },
  laranja = { 1, 0.55, 0.1 },
  amarelo = { 1, 0.85, 0.1 },
  azul = { 0.3, 0.6, 1 },
}

-- Utilidades ------------------------------------------------------------------

local function emCombate()
  return InCombatLockdown and InCombatLockdown() and true or false
end

-- Regra 10: erro de callback vai para o BugSack, sem popup.
local function seguro(fn, ...)
  if type(fn) ~= "function" then return false end
  local n = select("#", ...)
  local args = { ... }
  return xpcall(function() return fn(unpack(args, 1, n)) end, geterrorhandler())
end

local function dbOcultos()
  local db = ns.dbPersonagem()
  if type(db.agoraOcultos) ~= "table" then db.agoraOcultos = {} end
  return db.agoraOcultos
end

-- Treino pulado (dono, 2026-11-08: "quando eu clicar para [pular] alguma coisa, para ela nao
-- ficar voltando o tempo todo [...] estou precisando de dinheiro"). O botao direito no aviso de
-- treino guarda as magias daquele aviso (id do Naowh ou nome das Dicas) e o aviso so volta com
-- magia nova, mostrando so a nova. Antes ele escondia pelo texto, que muda com o treinador mais
-- perto ("Train 2 spells: Kaerbrus" virou "...: Dorion" e voltou). Desfazer: J > Now > Hidden.
local function dbPulados()
  local db = ns.dbPersonagem()
  if type(db.treinoPulado) ~= "table" then db.treinoPulado = {} end
  return db.treinoPulado
end

-- Estado ----------------------------------------------------------------------

local provedores = {}        -- lista de { id, eventos, itens }
local eventosVistos = {}     -- evento -> true (um ns.ao por evento)
local todos = {}             -- ultima lista completa, ordenada
local visiveis = {}          -- sem os ocultos
local vistos = {}            -- chave -> texto do que esta na tela (para o fade de entrada)
local pendente = false       -- atualizacao pedida durante o combate
local voltaEm = 0            -- GetTime() a partir do qual o painel pode voltar depois do combate
local loginAte = nil         -- GetTime() do fim do "Next 3"
local ancoraAtual = nil

-- Fontes (CreateFont, regra do contrato) --------------------------------------------

local ARQ_FONTE = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local fonteTitulo = CreateFont("GuiaForeverAgoraFonteTitulo")
fonteTitulo:SetFont(ARQ_FONTE, 13, "")
fonteTitulo:SetTextColor(0.7, 0.7, 0.7)
local fonteTexto = CreateFont("GuiaForeverAgoraFonteTexto")
fonteTexto:SetFont(ARQ_FONTE, 15, "")
fonteTexto:SetTextColor(1, 1, 1)

-- Painel ------------------------------------------------------------------------------

local painel = CreateFrame("Frame", "GuiaForeverAgora", UIParent, "BackdropTemplate")
painel:SetSize(LARGURA, ALT_TITULO + 4)
painel:SetFrameStrata("MEDIUM")
painel:Hide()
if painel.SetBackdrop then
  painel:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
  })
  painel:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
  painel:SetBackdropBorderColor(0, 0, 0, 1)
end

local titulo = painel:CreateFontString(nil, "OVERLAY")
titulo:SetFontObject(fonteTitulo)
titulo:SetPoint("TOPLEFT", painel, "TOPLEFT", 10, -5)
titulo:SetJustifyH("LEFT")
titulo:SetText("Now (0)")

local rodape = painel:CreateFontString(nil, "OVERLAY")
rodape:SetFontObject(fonteTitulo)
rodape:SetPoint("BOTTOMLEFT", painel, "BOTTOMLEFT", 10, 4)
rodape:SetJustifyH("LEFT")
rodape:Hide()

-- A margem das janelas do jogo (UIForever) depende de onde o painel esta e do tamanho dele.
local function avisarMargem()
  if UIForever_AtualizarMargem then
    ns.agendar("agora:margem", 0.3, function()
      if UIForever_AtualizarMargem then UIForever_AtualizarMargem() end
    end)
  end
end

-- Sob o RestedXP; sem ele, no canto esquerdo da tela. Reancora so quando o alvo muda.
local function ancorar()
  local rxp = _G["RXPFrame"]
  local nova = (type(rxp) == "table" and rxp.GetObjectType) and "rxp" or "ui"
  if nova == ancoraAtual then return end
  ancoraAtual = nova
  painel:ClearAllPoints()
  if nova == "rxp" then
    painel:SetPoint("TOPLEFT", rxp, "BOTTOMLEFT", 0, -8)
  else
    painel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 12, -240)
  end
  avisarMargem()
end

painel:SetScript("OnSizeChanged", function() avisarMargem() end)

-- Linhas ----------------------------------------------------------------------------

local linhas = {}

local function dicaTooltip(dono, item)
  GameTooltip:SetOwner(dono, "ANCHOR_RIGHT")
  GameTooltip:SetText(tostring(item.texto), 1, 1, 1)
  local d = item.dica
  if type(d) == "string" then
    GameTooltip:AddLine(d, 0.9, 0.9, 0.9, true)
  elseif type(d) == "table" then
    for _, l in ipairs(d) do GameTooltip:AddLine(tostring(l), 0.9, 0.9, 0.9, true) end
  end
  -- sem a linha "Source:" desde a 1.2 (dono: "nem ligo mais pra fonte dela")
  if type(item.aoOcultar) == "function" then
    GameTooltip:AddLine("Click: open the guide. Right-click: skip these for now (only new ones bring it back).", 0.5, 0.5, 0.5, true)
  else
    GameTooltip:AddLine("Click: open the guide. Right-click: hide until it changes.", 0.5, 0.5, 0.5, true)
  end
  GameTooltip:Show()
end

local desenhar -- definida adiante

local function ocultar(item)
  if not (item and item.chave) then return end
  if type(item.aoOcultar) == "function" then
    -- o provedor guarda o que foi pulado e deixa de emitir o item; refaz a lista
    seguro(item.aoOcultar)
    GameTooltip:Hide()
    if A.atualizar then A.atualizar() end
    return
  end
  dbOcultos()[item.chave] = tostring(item.texto)
  desenhar()
end

local function criarLinha(i)
  local r = CreateFrame("Frame", nil, painel)
  r:SetSize(LARGURA - 2, ALT_LINHA)
  r:SetPoint("TOPLEFT", painel, "TOPLEFT", 1, -(ALT_TITULO + (i - 1) * ALT_LINHA))

  r.faixa = r:CreateTexture(nil, "ARTWORK")
  r.faixa:SetPoint("TOPLEFT", r, "TOPLEFT", 3, -3)
  r.faixa:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 3, 3)
  r.faixa:SetWidth(4)

  r.icone = r:CreateTexture(nil, "ARTWORK")
  r.icone:SetSize(18, 18)
  r.icone:SetPoint("LEFT", r, "LEFT", 12, 0)

  r.texto = r:CreateFontString(nil, "OVERLAY")
  r.texto:SetFontObject(fonteTexto)
  r.texto:SetPoint("LEFT", r, "LEFT", 34, 0)
  r.texto:SetWidth(LARG_TEXTO)
  r.texto:SetJustifyH("LEFT")
  r.texto:SetWordWrap(false)

  -- area de clique sobre o texto (esquerdo abre o J, direito esconde)
  r.clique = CreateFrame("Button", nil, r)
  r.clique:SetPoint("LEFT", r, "LEFT", 34, 0)
  r.clique:SetSize(LARG_TEXTO, ALT_LINHA)
  r.clique:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  r.clique:SetScript("OnClick", function(_, botao)
    local item = r.item
    if not item then return end
    seguro(function()
      if botao == "RightButton" then
        ocultar(item)
      elseif item.aba and ns.abrirAba then
        ns.abrirAba(item.aba)
      end
    end)
  end)
  r.clique:SetScript("OnEnter", function(self)
    local item = r.item
    if not item then return end
    seguro(dicaTooltip, self, item)
  end)
  r.clique:SetScript("OnLeave", function() GameTooltip:Hide() end)

  r.botao = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
  r.botao:SetSize(LARG_BOTAO, 22)
  r.botao:SetPoint("RIGHT", r, "RIGHT", -6, 0)
  r.botao:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  r.botao:SetScript("OnClick", function(_, qual)
    local b = r.item and r.item.botao
    if not b then return end
    local fn = (qual == "RightButton" and b.acaoDireita) or b.acao
    if type(fn) == "function" then seguro(fn) end
  end)

  -- fade de entrada de 0,3 s (sem som e sem piscar)
  r.fadeIni = nil
  r:SetScript("OnUpdate", function(self)
    if not self.fadeIni then return end
    local t = (GetTime() - self.fadeIni) / 0.3
    if t >= 1 then
      self:SetAlpha(1)
      self.fadeIni = nil
    else
      self:SetAlpha(t)
    end
  end)

  linhas[i] = r
  return r
end

local function preencher(r, item, novo)
  r.item = item
  local c = CORES[item.cor] or CORES.azul
  r.faixa:SetColorTexture(c[1], c[2], c[3], 1)
  if item.icone then
    r.icone:SetTexture(item.icone)
    r.icone:Show()
  else
    r.icone:Hide()
  end
  r.texto:SetText(tostring(item.texto))
  local b = item.botao
  if type(b) == "table" and b.rotulo then
    r.botao:SetText(tostring(b.rotulo))
    r.botao:Show()
  else
    r.botao:Hide()
  end
  if novo then
    r:SetAlpha(0)
    r.fadeIni = GetTime()
  elseif not r.fadeIni then
    r:SetAlpha(1)
  end
  r:Show()
end

-- Visibilidade -----------------------------------------------------------------------------

local function janelaAberta()
  local j = _G["GuiaForeverJanela"]
  return j and j.IsShown and j:IsShown() and true or false
end

local function aplicarVisibilidade()
  local quer = #visiveis > 0 and not emCombate() and GetTime() >= voltaEm and not janelaAberta()
  if quer then
    if not painel:IsShown() then ancorar(); painel:Show() end
  elseif painel:IsShown() then
    painel:Hide()
  end
end

local function noLogin()
  return loginAte ~= nil and GetTime() < loginAte
end

desenhar = function()
  ancorar()
  local ocultos = dbOcultos()
  visiveis = {}
  for _, it in ipairs(todos) do
    if ocultos[it.chave] ~= tostring(it.texto) then visiveis[#visiveis + 1] = it end
  end
  local limite = noLogin() and 3 or MAX_LINHAS
  local n = #visiveis
  local mostrar = math.min(n, limite)

  local agora = {}
  for i = 1, MAX_LINHAS do
    local r = linhas[i] or criarLinha(i)
    local it = visiveis[i]
    if it and i <= mostrar then
      local marca = tostring(it.texto)
      agora[it.chave] = marca
      preencher(r, it, vistos[it.chave] ~= marca)
    else
      r.item = nil
      r.fadeIni = nil
      r:Hide()
    end
  end
  vistos = agora

  titulo:SetText(noLogin() and "Next 3" or ("Now (" .. n .. ")"))
  local alt = ALT_TITULO + mostrar * ALT_LINHA + 4
  if n > mostrar then
    rodape:SetText("+" .. (n - mostrar) .. " more (J)")
    rodape:Show()
    alt = alt + ALT_RODAPE
  else
    rodape:Hide()
  end
  painel:SetHeight(alt)
  aplicarVisibilidade()
end

-- Provedores ------------------------------------------------------------------------------------

local function refazer()
  if emCombate() then pendente = true; return end
  local ctx = {
    estado = ns.estado,
    nivel = ns.estado and ns.estado.nivel,
    classe = ns.estado and ns.estado.classe,
  }
  local lista, vistas = {}, {}
  for pi, p in ipairs(provedores) do
    local saida
    local ok = xpcall(function() saida = p.itens(ctx) end, geterrorhandler())
    if ok and type(saida) == "table" then
      for _, it in ipairs(saida) do
        if type(it) == "table" and type(it.chave) == "string" and it.texto ~= nil
           and not vistas[it.chave] then
          vistas[it.chave] = true
          it.prio = tonumber(it.prio) or 99
          it.ordem = pi * 1000 + #lista
          lista[#lista + 1] = it
        end
      end
    end
  end
  table.sort(lista, function(a, b)
    if a.prio ~= b.prio then return a.prio < b.prio end
    return a.ordem < b.ordem
  end)
  todos = lista
  desenhar()
end

function A.atualizar()
  if emCombate() then pendente = true; return end
  ns.agendar("agora:atualizar", 0.4, refazer)
end

function A.itens()
  return todos
end

function A.ocultos()
  local r = {}
  for k, v in pairs(dbOcultos()) do r[k] = v end
  return r
end

function A.mostrar(chave)
  if chave == nil then return end
  dbOcultos()[chave] = nil
  desenhar()
end

-- treino pulado: a lista (para a secao Hidden do J) e o desfazer
function A.pulados()
  local r = {}
  for k in pairs(dbPulados()) do
    r[#r + 1] = type(k) == "number" and ((ns.nomeMagia and ns.nomeMagia(k)) or ("spell " .. k)) or tostring(k)
  end
  table.sort(r)
  return r
end

function A.desfazerPulo()
  local db = ns.dbPersonagem()
  db.treinoPulado = {}
  A.atualizar()
end

function A.provedor(def)
  if type(def) ~= "table" or type(def.id) ~= "string" or type(def.itens) ~= "function" then return end
  local novo = { id = def.id, eventos = def.eventos, itens = def.itens }
  local lugar
  for i, p in ipairs(provedores) do
    if p.id == def.id then lugar = i end
  end
  if lugar then provedores[lugar] = novo else provedores[#provedores + 1] = novo end
  if type(def.eventos) == "table" then
    for _, ev in ipairs(def.eventos) do
      if type(ev) == "string" and not eventosVistos[ev] then
        eventosVistos[ev] = true
        ns.ao(ev, function() A.atualizar() end)
      end
    end
  end
  A.atualizar()
end

-- Eventos do proprio painel ----------------------------------------------------------------------

ns.ao("PLAYER_LOGIN", function()
  loginAte = GetTime() + 30
  ns.agendar("agora:fimlogin", 30.5, desenhar)
  A.atualizar()
end)

ns.ao("PLAYER_ENTERING_WORLD", function()
  ancoraAtual = nil -- o RestedXP pode ter aparecido depois do addon
  A.atualizar()
end)

ns.ao("PLAYER_LEVEL_UP", function() A.atualizar() end)
ns.ao("SPELLS_CHANGED", function() A.atualizar() end)

ns.ao("PLAYER_REGEN_DISABLED", function()
  painel:Hide()
end)

ns.ao("PLAYER_REGEN_ENABLED", function()
  voltaEm = GetTime() + 3
  if pendente then
    pendente = false
    A.atualizar()
  end
end)

-- Quadro proprio e leve: reavalia a visibilidade (volta 3 s depois do combate, J aberto ou fechado).
local controle = CreateFrame("Frame")
local acum = 0
controle:SetScript("OnUpdate", function(_, dt)
  acum = acum + (dt or 0)
  if acum < 0.3 then return end
  acum = 0
  xpcall(aplicarVisibilidade, geterrorhandler())
end)

-- Provedor: talento --------------------------------------------------------------------------------

A.provedor{
  id = "talento",
  eventos = { "PLAYER_LEVEL_UP", "TRAIT_TREE_CURRENCY_INFO_UPDATED", "PLAYER_ENTERING_WORLD" },
  itens = function()
    local p = ns.arvore and ns.arvore.proximo and ns.arvore.proximo()
    if not p then return {} end
    local texto, dica
    if p.tbd then
      texto = "Talent point: your pick, sources differ"
      dica = { "Your plan has no fixed pick for level " .. p.nivel .. " yet.", "Open the Talents tab (J) for the sources." }
    else
      texto = "Talent point: " .. tostring(p.texto)
      dica = { "Level " .. p.nivel .. " pick in your talent plan.", "Open the Talents tab (J) for the whole plan." }
    end
    return { {
      chave = "talento:ponto", prio = 50, cor = "amarelo",
      icone = "Interface\\Icons\\INV_Misc_Book_09",
      texto = texto, dica = dica, fonte = "Your talent plan",
      aba = "talentos",
      botao = { rotulo = "Show", acao = function() if ns.abrirAba then ns.abrirAba("talentos") end end },
    } }
  end,
}

-- Provedor: treino de classe -------------------------------------------------------------------------

local function dinheiro(cobre)
  if type(cobre) ~= "number" then return nil end
  if GetCoinTextureString then
    local ok, s = pcall(GetCoinTextureString, cobre)
    if ok and type(s) == "string" then return s end
  end
  return cobre .. " copper"
end

local function nomeDe(id)
  return (ns.nomeMagia and ns.nomeMagia(id)) or ("spell " .. tostring(id))
end

-- Naowh em tempo de execucao (regra 9): tudo em pcall, com checagem de tipo.
local function treinoNaowh(nivel)
  local nw = _G["NaowhForever"]
  local tr = type(nw) == "table" and nw.Training
  if type(tr) ~= "table" or type(tr.Plan) ~= "function" then return nil end
  local ok, plano = pcall(tr.Plan, nivel)
  if not ok or type(plano) ~= "table" then return nil end
  local agora = type(plano.now) == "table" and plano.now or {}
  local lista = {}
  local pulados = dbPulados()
  for _, e in ipairs(agora) do
    if type(e) == "table" and not e.quest and not pulados[e[2]] then lista[#lista + 1] = e end
  end
  if #lista == 0 then return {} end

  local custo
  if type(tr.Total) == "function" then
    local okT, t = pcall(tr.Total, lista)
    if okT and type(t) == "number" then custo = t end
  end
  if not custo then
    custo = 0
    for _, e in ipairs(lista) do custo = custo + (tonumber(e[3]) or 0) end
  end

  local treinador
  if type(tr.NearestTrainer) == "function" then
    -- o Naowh devolve o NPC como lista { x, y, categoria, nome, titulo, classe, lado } (Route.lua, NPC_NAME = 4)
    local okN, npc = pcall(tr.NearestTrainer)
    if okN and type(npc) == "table" and type(npc[4]) == "string" then treinador = npc[4] end
  end

  local dica = {}
  for _, e in ipairs(lista) do
    dica[#dica + 1] = nomeDe(e[2]) .. " (level " .. tostring(e[1]) .. ")"
  end
  local d = dinheiro(custo)
  if d then dica[#dica + 1] = "Total cost: " .. d end

  local n = #lista
  local texto = "Train " .. n .. (n == 1 and " spell" or " spells")
  if treinador then texto = texto .. ": " .. treinador end

  local icone = (ns.iconeMagia and ns.iconeMagia(lista[1][2])) or "Interface\\Icons\\INV_Misc_Book_11"
  return { {
    chave = "classe:treino", prio = 60, cor = "amarelo", icone = icone,
    texto = texto, dica = dica, fonte = "Naowh Forever", aba = "nivel",
    aoOcultar = function()
      local p = dbPulados()
      for _, e in ipairs(lista) do if e[2] then p[e[2]] = true end end
    end,
    botao = {
      rotulo = "Arrow",
      acao = function()
        local t = type(nw) == "table" and nw.Training
        if type(t) == "table" and type(t.WaypointToTrainer) == "function" then
          pcall(t.WaypointToTrainer)
        elseif ns.setaTreinador then
          ns.setaTreinador("classe")
        end
      end,
      acaoDireita = function()
        if type(nw.OpenTrainingWindow) == "function" then
          pcall(nw.OpenTrainingWindow, nivel, "spells")
        elseif type(nw.ToggleTrainingWindow) == "function" then
          pcall(nw.ToggleTrainingWindow)
        end
      end,
    },
  } }
end

-- Sem Naowh: magias de Dicas.magias (com o campo `magia`) ate o nivel que o jogo diz que faltam.
local function treinoDicas(nivel)
  local dicas = ns.dicas and ns.dicas()
  local magias = dicas and dicas.magias
  if type(magias) ~= "table" then return {} end
  local faltam, vistas = {}, {}
  local pulados = dbPulados()
  for _, e in ipairs(magias) do
    if type(e) == "table" and e.magia and (tonumber(e.nivel) or 99) <= nivel and not pulados[e.magia]
       and not vistas[e.magia] and (not ns.relevante or ns.relevante(e)) and not ns.conhece(e.magia) then
      vistas[e.magia] = true
      faltam[#faltam + 1] = e
    end
  end
  if #faltam == 0 then return {} end
  local dica = {}
  for _, e in ipairs(faltam) do
    local nome = type(e.magia) == "number" and nomeDe(e.magia) or tostring(e.magia)
    dica[#dica + 1] = nome .. " (level " .. tostring(e.nivel) .. ")"
  end
  local n = #faltam
  local icone = type(faltam[1].magia) == "number" and ns.iconeMagia and ns.iconeMagia(faltam[1].magia)
  return { {
    chave = "classe:treino", prio = 60, cor = "amarelo",
    icone = icone or "Interface\\Icons\\INV_Misc_Book_11",
    texto = "Train " .. n .. (n == 1 and " spell" or " spells") .. ": class trainer",
    dica = dica, fonte = faltam[1].fonte, aba = "nivel",
    aoOcultar = function()
      local p = dbPulados()
      for _, e in ipairs(faltam) do p[e.magia] = true end
    end,
    botao = {
      rotulo = "Arrow",
      acao = function() if ns.setaTreinador then ns.setaTreinador("classe") end end,
    },
  } }
end

A.provedor{
  id = "classe",
  eventos = { "PLAYER_LEVEL_UP", "SPELLS_CHANGED", "LEARNED_SPELL_IN_SKILL_LINE", "PLAYER_ENTERING_WORLD" },
  itens = function(ctx)
    local nivel = ctx and ctx.nivel
    if type(nivel) ~= "number" then return {} end
    local r = treinoNaowh(nivel)
    if r then return r end
    return treinoDicas(nivel)
  end,
}

-- Provedor: teclas novas ----------------------------------------------------------------------------------

-- Acao curta: `s` cortado no primeiro " (" ou ":".
local function acaoCurta(s)
  s = tostring(s or "")
  local corte = #s + 1
  local a = string.find(s, " (", 1, true)
  local b = string.find(s, ":", 1, true)
  if a and a < corte then corte = a end
  if b and b < corte then corte = b end
  return string.sub(s, 1, corte - 1)
end

A.provedor{
  id = "teclas",
  eventos = { "PLAYER_LEVEL_UP", "PLAYER_ENTERING_WORLD" },
  itens = function(ctx)
    local nivel = ctx and ctx.nivel
    local tab = GuiaForeverTeclas and ctx and ctx.classe and GuiaForeverTeclas[ctx.classe]
    if type(nivel) ~= "number" or type(tab) ~= "table" then return {} end
    local r = {}
    for i, t in ipairs(tab) do
      if type(t) == "table" and t.k and (t.n == nivel or t.cheio == nivel) then
        r[#r + 1] = {
          chave = "teclas:" .. tostring(t.k) .. ":" .. nivel .. ":" .. i,
          prio = 90, cor = "azul",
          texto = "New at " .. nivel .. ": " .. tostring(t.k) .. " = " .. acaoCurta(t.s),
          dica = { tostring(t.s or ""), "Key: " .. tostring(t.k) },
          fonte = t.f, aba = "teclas",
        }
      end
    end
    return r
  end,
}
