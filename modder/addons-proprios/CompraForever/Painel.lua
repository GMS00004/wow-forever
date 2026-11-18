local addon, ns = ...

-- Painel: frame colado na AH, no vendedor ou na janela de profissao (CONTRATO secao 7). Mostra dinheiro, scan, o
-- plano e o botao de acao (texto e clique de ns.proximaAcao()). Sem arquivo de textura nem fonte alem dos do cliente.

local floor, max, min = math.floor, math.max, math.min

local LARG = 300
local Y_LINHAS = 80       -- topo da primeira linha de plano
local ALT_LINHA = 13
local MAX_LINHAS = 22
local RECARGA_FULL = 900
local MOTIVOS = { dinheiro = "money", espaco = "bags", lucro = "profit", limite = "limit" }

local f = CreateFrame("Frame", "CompraForeverPainel", UIParent, "BackdropTemplate")
f:SetSize(LARG, 200)
f:SetFrameStrata("MEDIUM")
f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
f:SetBackdropColor(0, 0, 0, 0.88)
f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
f:Hide()

local function texto(y, fonte)
  local t = f:CreateFontString(nil, "OVERLAY", fonte or "GameFontHighlightSmall")
  t:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -y)
  t:SetWidth(LARG - 16)
  t:SetJustifyH("LEFT")
  t:SetWordWrap(false)
  return t
end

local fsDinheiro = texto(8, "GameFontNormal")
local fsScan = texto(24)

local function botao(nome, rotulo, x, larg, altura)
  local b = CreateFrame("Button", nome, f, "UIPanelButtonTemplate")
  b:SetSize(larg, altura)
  b:SetPoint("TOPLEFT", f, "TOPLEFT", x, -40)
  b:SetText(rotulo)
  return b
end

local btScan = botao("CompraForeverScan", "Scan", 8, 136, 22)
local btFull = botao("CompraForeverFull", "Full scan", 148, 144, 22)

local barraFundo = f:CreateTexture(nil, "BACKGROUND")
barraFundo:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -68)
barraFundo:SetSize(LARG - 16, 6)
barraFundo:SetColorTexture(0.2, 0.2, 0.2, 1)
local barra = f:CreateTexture(nil, "ARTWORK")
barra:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -68)
barra:SetSize(1, 6)
barra:SetColorTexture(0.2, 0.8, 0.3, 1)

local linhas = {}
for i = 1, MAX_LINHAS do linhas[i] = texto(Y_LINHAS + (i - 1) * ALT_LINHA) end
local fsMensagem = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fsMensagem:SetJustifyH("LEFT")
fsMensagem:SetWidth(LARG - 16)
fsMensagem:SetWordWrap(false)

local btAcao = CreateFrame("Button", "CompraForeverAcao", f, "UIPanelButtonTemplate")
btAcao:SetSize(LARG - 16, 28)
btAcao:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 8)
btAcao:SetText("Nothing to do")

-- Linhas do plano -------------------------------------------------------------------------------------------

local function nomeMagia(magia)
  local d = rawget(_G, "CompraForeverDados")
  local r = d and d.receitas and d.receitas[magia]
  return r and r.nome or tostring(magia)
end

local function nomeItem(id)
  local d = rawget(_G, "CompraForeverDados")
  local it = d and d.itens and d.itens[id]
  return it and it.nome or tostring(id)
end

-- BIG >= config.grande (1g), small >= config.pequena (30s), skip abaixo; ajustavel por /compra grande e /compra pequena
local CORES = { BIG = "|cff33ff33", small = "|cffffd100", skip = "|cff999999" }
local ORDEM_CAT = { "BIG", "small", "skip" }
local function categoria(lucro)
  local cfg = ns.config()
  if lucro >= (cfg.grande or 10000) then return "BIG" end
  if lucro >= (cfg.pequena or 3000) then return "small" end
  return "skip"
end
ns.categoria = categoria

local function montarLinhas()
  local L = {}
  local plano, S = ns.plano, ns.sessao or {}
  local crafts, fabricar, leilao, vendedor = {}, {}, {}, {}
  if plano then
    crafts, fabricar, leilao, vendedor = plano.crafts, plano.fabricar, plano.leilao, plano.vendedor
  end
  local noPlano = {}
  for _, c in ipairs(fabricar) do noPlano["m" .. c.magia] = true end
  for _, c in ipairs(crafts) do noPlano["m" .. c.magia] = true end
  for _, r in ipairs(leilao) do noPlano["i" .. r.id] = true end
  for _, r in ipairs(vendedor) do noPlano["i" .. r.id] = true end

  if not ns.scan then
    L[#L + 1] = "No scan yet: open the AH and click Scan"
  elseif plano and #plano.crafts == 0 and #plano.revenda == 0 then
    L[#L + 1] = "Nothing pays now (" .. (MOTIVOS[plano.motivo] or tostring(plano.motivo or "?")) .. ")"
  end

  for _, c in ipairs(fabricar) do L[#L + 1] = "|cff999999" .. c.n .. "x " .. c.nome .. " (make)|r" end

  -- Categorias (pedido do dono, 2026-11-17): cor pelo tamanho do lucro, etiqueta pelo tipo de cada linha.
  local d = rawget(_G, "CompraForeverDados") or {}
  local daBolsa = {}
  for _, e in ipairs(plano and plano.doEstoque or {}) do
    local it = d.itens and d.itens[e.id]
    if not (it and it.vendedor) then daBolsa[e.id] = true end   -- linha e tinta na bolsa nao contam como sobra
  end
  local function usaBolsa(magia)
    local r = d.receitas and d.receitas[magia]
    for _, rg in ipairs(r and r.reagentes or {}) do
      if daBolsa[rg[1]] then return true end
    end
    return false
  end
  local grupos = {}
  for _, c in ipairs(crafts) do
    grupos[#grupos + 1] = { cat = categoria(c.lucro or 0), lucro = c.lucro or 0,
      texto = (usaBolsa(c.magia) and "[BAGS] " or "[CRAFT] ") .. c.n .. "x " .. c.nome .. " +" .. ns.moeda(c.lucro or 0) }
  end
  for _, r in ipairs(plano and plano.revenda or {}) do
    grupos[#grupos + 1] = { cat = categoria(r.lucro or 0), lucro = r.lucro or 0,
      texto = "[RESALE] " .. r.qtd .. "x " .. r.nome .. " +" .. ns.moeda(r.lucro or 0) }
  end
  for _, cat in ipairs(ORDEM_CAT) do
    local soma, grupo = 0, {}
    for _, x in ipairs(grupos) do
      if x.cat == cat then soma = soma + x.lucro; grupo[#grupo + 1] = x end
    end
    if #grupo > 0 then
      table.sort(grupo, function(a, b)
        if a.lucro ~= b.lucro then return a.lucro > b.lucro end
        return a.texto < b.texto
      end)
      L[#L + 1] = CORES[cat] .. cat .. " +" .. ns.moeda(soma) .. (cat == "skip" and " (not worth it)" or "") .. "|r"
      for _, x in ipairs(grupo) do L[#L + 1] = CORES[cat] .. "  " .. x.texto .. "|r" end
    end
  end
  local magias = {}
  for magia in pairs(S.craftado or {}) do
    if not noPlano["m" .. magia] then magias[#magias + 1] = magia end
  end
  table.sort(magias)
  for _, magia in ipairs(magias) do L[#L + 1] = "[x] " .. S.craftado[magia] .. "x " .. nomeMagia(magia) end

  for _, r in ipairs(leilao) do
    L[#L + 1] = r.qtd .. " " .. r.nome .. " <= " .. ns.moeda(r.precoMax) .. "  " .. ns.moeda(r.custo)
  end
  for _, r in ipairs(vendedor) do
    L[#L + 1] = r.qtd .. " " .. r.nome .. " (vendor)  " .. ns.moeda(r.custo)
  end
  local ids = {}
  for id in pairs(S.comprado or {}) do
    if not noPlano["i" .. id] then ids[#ids + 1] = id end
  end
  table.sort(ids)
  for _, id in ipairs(ids) do L[#L + 1] = "[x] " .. S.comprado[id] .. " " .. nomeItem(id) end
  ids = {}
  for id, n in pairs(S.vendido or {}) do
    if n > 0 then ids[#ids + 1] = id end
  end
  table.sort(ids)
  for _, id in ipairs(ids) do L[#L + 1] = "[x] sold " .. S.vendido[id] .. " " .. nomeItem(id) end

  if plano and #plano.crafts > 0 then
    L[#L + 1] = CORES[categoria(plano.totais.lucro or 0)] .. "Spend " .. ns.moeda(plano.totais.gasto) .. ", profit +"
      .. ns.moeda(plano.totais.lucro) .. "|r"
  end
  -- o que o leilao entrega chega pelo correio: craftar so depois de pegar na caixa de correio
  local noCorreio = 0
  for _, n in pairs(S.correio or {}) do noCorreio = noCorreio + n end
  if noCorreio > 0 then L[#L + 1] = "Mailbox: " .. noCorreio .. " bought items to collect" end
  return L
end
ns.montarLinhas = montarLinhas   -- usado pela bancada (cenario compra-11)

-- Atualizacao ------------------------------------------------------------------------------------------------

local msgPainel = nil

local function mmss(seg)
  seg = max(0, floor(seg))
  return string.format("%d:%02d", floor(seg / 60), seg % 60)
end

local function alvo()
  local c = ns.contexto()
  if c.ah and AuctionHouseFrame then return AuctionHouseFrame end
  if c.vend and MerchantFrame then return MerchantFrame end
  if c.prof and _G.ProfessionsFrame then return _G.ProfessionsFrame end
  return nil
end

function ns.atualizarPainel()
  local c = ns.contexto()
  local e = ns.scanEstado or {}
  fsDinheiro:SetText("Money " .. ns.moeda(ns.dinheiro()) .. "   Bags free " .. ns.espacosLivres())

  local sc = ns.scan
  if e.ocupado then
    fsScan:SetText("Scanning " .. (e.feito or 0) .. "/" .. (e.total or 0))
  elseif sc then
    fsScan:SetText("Scan " .. date("%H:%M", sc.em) .. " " .. (sc.tipo == "full" and "full" or "targeted"))
  else
    fsScan:SetText("No scan yet")
  end
  local frac = (e.total or 0) > 0 and min(1, (e.feito or 0) / e.total) or 0
  barra:SetWidth(max(1, floor((LARG - 16) * frac)))

  btScan:SetEnabled(c.ah and not e.ocupado)
  local db = CompraForeverDB
  local resta = RECARGA_FULL - (time() - ((db and db.ultimoFull) or 0))
  if resta > 0 then
    btFull:SetText("Full scan " .. mmss(resta))
    btFull:Disable()
  else
    btFull:SetText("Full scan")
    btFull:SetEnabled(c.ah and not e.ocupado)
  end

  local L = montarLinhas()
  local n = min(#L, MAX_LINHAS)
  for i = 1, MAX_LINHAS do
    if i <= n then
      linhas[i]:SetText(i == MAX_LINHAS and #L > MAX_LINHAS and "..." or L[i])
      linhas[i]:Show()
    else
      linhas[i]:SetText("")
      linhas[i]:Hide()
    end
  end
  local yMsg = Y_LINHAS + n * ALT_LINHA + 2
  fsMensagem:ClearAllPoints()
  fsMensagem:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -yMsg)
  fsMensagem:SetText((ns.mensagem and ns.mensagem()) or msgPainel or "")
  f:SetHeight(yMsg + 16 + 8 + 28 + 8)

  local a = ns.proximaAcao and ns.proximaAcao() or nil
  btAcao:SetText(a and a.texto or "Nothing to do")
  btAcao:SetEnabled(a ~= nil and a.executar ~= nil)
end

-- Prende o painel a direita da janela e o desenha acima dela. A janela de profissao do Forever tem uma coluna de abas
-- na borda direita (LargeSideTabButtonTemplate, Camelot\Blizzard_ProfessionsFrame.xml) e a pagina de craft em
-- frameLevel 100: sem o afastamento e o nivel, o painel ficava atras das abas e da janela.
local function ancorar(a)
  f:ClearAllPoints()
  local dx = (a == _G.ProfessionsFrame) and 48 or 4
  f:SetPoint("TOPLEFT", a, "TOPRIGHT", dx, 0)
  f:SetFrameStrata(a:GetFrameStrata() or "MEDIUM")
  f:SetFrameLevel(min((a:GetFrameLevel() or 0) + 200, 9000))
end

local function reavaliar()
  local a = alvo()
  if a then
    ancorar(a)
    f:Show()
  else
    f:Hide()
  end
  ns.atualizarPainel()
end

function ns.alternarPainel()
  if f:IsShown() then
    f:Hide()
    return
  end
  local a = alvo()
  if a then
    ancorar(a)
  else
    f:ClearAllPoints()
    f:SetFrameStrata("MEDIUM")
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end
  f:Show()
  ns.atualizarPainel()
end

-- Botoes -----------------------------------------------------------------------------------------------------

local MOTIVOS_SCAN = { closed = "Open the AH first", busy = "Scan running", nothing = "No known recipes: open Leatherworking",
                       cooldown = "Full scan on cooldown" }

btScan:SetScript("OnClick", function()
  msgPainel = nil
  local ok, motivo = ns.scanDirigido(function() ns.atualizarPainel() end)
  if not ok then msgPainel = MOTIVOS_SCAN[motivo] or tostring(motivo) end
  ns.atualizarPainel()
end)

btFull:SetScript("OnClick", function()
  msgPainel = nil
  local ok, motivo = ns.fullScan(function() ns.atualizarPainel() end)
  if not ok then msgPainel = MOTIVOS_SCAN[motivo] or tostring(motivo) end
  ns.atualizarPainel()
end)

btAcao:SetScript("OnClick", function()
  local a = ns.proximaAcao()
  if a and a.executar then a.executar() end
  ns.atualizarPainel()
end)

-- Eventos e relogio ------------------------------------------------------------------------------------------

for _, ev in ipairs({ "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "MERCHANT_SHOW", "MERCHANT_CLOSED", "TRADE_SKILL_CLOSE" }) do
  ns.ao(ev, reavaliar)
end
ns.ao("TRADE_SKILL_SHOW", function()
  reavaliar()
  C_Timer.After(0.5, reavaliar)   -- a janela de profissao e a leitura da pericia chegam depois do evento
end)
ns.ao("PLAYER_MONEY", function() ns.atualizarPainel() end)
ns.ao("BAG_UPDATE_DELAYED", function() ns.atualizarPainel() end)

local acum = 0
f:SetScript("OnUpdate", function(_, dt)
  acum = acum + (dt or 0)
  if acum < 0.5 then return end
  acum = 0
  ns.atualizarPainel()
end)
