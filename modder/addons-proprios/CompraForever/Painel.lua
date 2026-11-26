local addon, ns = ...

-- Painel: frame colado na AH, no vendedor ou na janela de profissao (CONTRATO secao 7). Mostra dinheiro, scan, o
-- plano e o botao de acao (texto e clique de ns.proximaAcao()). Sem arquivo de textura nem fonte alem dos do cliente.

local floor, max, min = math.floor, math.max, math.min

local LARG = 300
local Y_LINHAS = 80       -- topo da primeira linha de plano
local ALT_LINHA = 13
local MAX_LINHAS = 30
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

local function botao(nome, rotulo, x, larg, altura, y)
  local b = CreateFrame("Button", nome, f, "UIPanelButtonTemplate")
  b:SetSize(larg, altura)
  b:SetPoint("TOPLEFT", f, "TOPLEFT", x, -(y or 40))
  b:SetText(rotulo)
  return b
end

local btScan = botao("CompraForeverScan", "Scan", 8, 90, 22)
local btFull = botao("CompraForeverFull", "Full scan", 102, 96, 22)
local btModo = botao("CompraForeverModo", "Profit", 202, 90, 22)
btModo:RegisterForClicks("LeftButtonUp", "RightButtonUp")

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

-- botao da isca (secao 13): so aparece com a isca ligada, logo acima do botao de acao
local btIsca = CreateFrame("Button", "CompraForeverIsca", f, "UIPanelButtonTemplate")
btIsca:SetSize(LARG - 16, 22)
btIsca:SetPoint("BOTTOMLEFT", btAcao, "TOPLEFT", 0, 4)
btIsca:SetText("Bait")
btIsca:Hide()

-- Linhas do plano -------------------------------------------------------------------------------------------

local function nomeMagia(magia)
  local d = rawget(_G, "CompraForeverDados")
  local r = d and d.receitas and d.receitas[magia]
  return r and r.nome or tostring(magia)
end

local function nomeItem(id)
  local d = rawget(_G, "CompraForeverDados")
  local it = d and d.itens and d.itens[id]
  if it and it.nome then return it.nome end
  local w = ns.vigiaDB and ns.vigiaDB()
  return w and w.itens[id] and w.itens[id].nome or tostring(id)
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

local function emRota()
  return ns.plano ~= nil and ns.plano.modo == 2
end

local MOTIVOS_ROTA = { dinheiro = "money", espaco = "bags", preco = "price", semPreco = "no price", bloqueio = "blocked",
                       fim = "target", limite = "level cap" }
local RED = "|cffff4040"

local function itensNoCorreio()
  local n = 0
  for _, q in pairs((ns.sessao or {}).correio or {}) do n = n + q end
  return n
end

-- Texto do NEXT da rota (sem cor); nil quando o plano nao diz nada
local function textoProximo(plano)
  local r = plano and plano.rota
  if not r then return nil end
  local p = plano.proximo or r.proximo
  local nome = r.nome or "?"
  if p == "ah" then return "NEXT: AH" end
  if p == "mail" then return "NEXT: mailbox (" .. itensNoCorreio() .. " items)" end
  if p == "vendor" then return "NEXT: vendor" end
  if p == "trainer" then return "NEXT: trainer" end
  if p == "craft" then return "NEXT: " .. nome .. " window" end
  if p == "open" then return "NEXT: open " .. nome .. " once" end
  if p == "done" then return "DONE: " .. nome .. " " .. tostring(r.alvo) end
  return nil
end

-- Dicas da rota, por urgencia: sem preco (Scan), item acima do teto, item bloqueado, rank, foco/objeto/padrao, Full
-- novo; depois o treino que o trecho de compra pede. No painel normal cabem 4 (o resto do treino vira "+N more"); no
-- treinador e no correio (todas = true) vai tudo, com o treino inteiro.
local function dicasRota(r, L, todas)
  local u = {}
  local semPreco = ns.plano ~= nil and ns.plano.motivo == "semPreco"
  for _, c in ipairs(r.curtos or {}) do
    if c.tipo == "semPreco" then semPreco = true end
  end
  if semPreco then u[#u + 1] = "Scan at the AH" end
  for _, c in ipairs(r.curtos or {}) do
    if c.tipo == "preco" then
      u[#u + 1] = RED .. "SHORT " .. tostring(c.falta) .. " " .. tostring(c.nome) .. " > " .. ns.moeda(c.cap or 0) .. ": new estimate|r"
    elseif c.tipo == "bloqueio" then
      u[#u + 1] = RED .. "BLOCKED " .. tostring(c.nome) .. ": learn its recipe first|r"
    end
  end
  if r.rank then
    u[#u + 1] = "TRAIN " .. tostring(r.rank.nome) .. " " .. ns.moeda(r.rank.custo or 0)
      .. (r.rank.bloqueado and (" (lvl " .. tostring(r.rank.nivel) .. ")") or "")
  end
  for _, d in ipairs(r.dicas or {}) do
    if string.find(d, "^PLACE") or string.find(d, "^LEARN") or string.find(d, "needed") then u[#u + 1] = d
    else u[#u + 1] = d .. " needed" end
  end
  if r.velho then u[#u + 1] = "Newer Full: say atualiza" end
  local trein, ate = {}, r.chega or r.pericia or 0
  for _, x in ipairs(r.treinar or {}) do
    if todas or (x.aprende or 0) <= ate then
      trein[#trein + 1] = "TRAIN " .. tostring(x.nome) .. " " .. ns.moeda(x.custo or 0)
    end
  end
  if todas then
    for _, s in ipairs(u) do L[#L + 1] = s end
    for _, s in ipairs(trein) do L[#L + 1] = s end
    return
  end
  local cabe = 4
  for _, s in ipairs(u) do
    if cabe > 0 then L[#L + 1] = s; cabe = cabe - 1 end
  end
  local resto = #trein
  for _, s in ipairs(trein) do
    if cabe > 1 or (cabe == 1 and resto == 1) then
      L[#L + 1] = s
      cabe, resto = cabe - 1, resto - 1
    end
  end
  if resto > 0 and cabe > 0 then L[#L + 1] = "TRAIN +" .. resto .. " more (see them at the trainer)" end
end

local function montarLinhasRota(soDicas)
  local L = {}
  local plano = ns.plano
  local r = plano and plano.rota
  if not r then return L end
  if soDicas then
    dicasRota(r, L, true)
    return L
  end
  local prox = textoProximo(plano)
  if prox then L[#L + 1] = prox end
  if r.estado ~= "feito" then
    local t = tostring(r.nome) .. " " .. tostring(r.pericia or "?") .. "/" .. tostring(r.max or "?") .. " -> " .. tostring(r.alvo)
    if r.limite and r.alvo and r.limite < r.alvo then
      t = t .. " (" .. r.limite .. " until lvl " .. tostring(r.rank and r.rank.nivel or "?") .. ")"
    end
    L[#L + 1] = t
  end
  if r.atual then
    L[#L + 1] = "Now " .. tostring(r.atual.nome) .. " " .. tostring(r.atual.de) .. "-" .. tostring(r.atual.ate) .. ": "
      .. tostring(r.atual.faltam) .. " left"
  end
  local nl, nv = #(plano.leilao or {}), #(plano.vendedor or {})
  if r.chega and nl + nv > 0 then
    L[#L + 1] = "BUY to " .. r.chega .. " (" .. (MOTIVOS_ROTA[plano.motivo] or tostring(plano.motivo or "?")) .. ")"
  end
  dicasRota(r, L)
  local mostra = 0
  for _, x in ipairs(plano.leilao or {}) do
    if mostra < 12 then
      mostra = mostra + 1
      L[#L + 1] = x.qtd .. " " .. x.nome .. " <= " .. ns.moeda(x.teto or x.precoMax or 0) .. "  " .. ns.moeda(x.custo or 0)
    end
  end
  for _, x in ipairs(plano.vendedor or {}) do
    if mostra < 12 then
      mostra = mostra + 1
      L[#L + 1] = x.qtd .. " " .. x.nome .. " (vendor)  " .. ns.moeda(x.custo or 0)
    end
  end
  if nl + nv > mostra then L[#L + 1] = "+" .. (nl + nv - mostra) .. " more" end
  for i, c in ipairs(plano.crafts or {}) do
    if i > 3 then break end
    L[#L + 1] = "[CRAFT] " .. c.n .. "x " .. tostring(c.nome) .. " " .. tostring(c.de) .. "-" .. tostring(c.ate)
  end
  local nv2, valor = 0, 0
  local d = rawget(_G, "CompraForeverDados")
  local itens = d and d.rotas and d.rotas.itens or {}
  for id, q in pairs(r.vender or {}) do
    nv2 = nv2 + q
    valor = valor + q * ((itens[id] and itens[id].vende) or 0)
  end
  if nv2 > 0 then L[#L + 1] = "Sell " .. nv2 .. " leftovers (+" .. ns.moeda(valor) .. ")" end
  L[#L + 1] = "Spend " .. ns.moeda((plano.totais and plano.totais.gasto) or 0) .. " | left ~" .. ns.moeda(r.restante or 0)
  local noCorreio = itensNoCorreio()
  if noCorreio > 0 then L[#L + 1] = "Mailbox: " .. noCorreio .. " bought items to collect" end
  return L
end

local alvo   -- definido mais abaixo

local function montarLinhas()
  -- caca ligada (secao 13): o painel mostra so ela
  local h = ns.cacaLinhas and ns.cacaLinhas()
  if h then
    local li = ns.iscaLinha and ns.iscaLinha()
    if li then h[#h + 1] = li end
    return h
  end
  local L = {}
  local plano, S = ns.plano, ns.sessao or {}
  if emRota() then
    local a = alvo and alvo()
    local mf, tf = rawget(_G, "MailFrame"), rawget(_G, "ClassTrainerFrame")
    if a ~= nil and (a == mf or a == tf) then return montarLinhasRota(true) end
  end
  local crafts, fabricar, leilao, vendedor = {}, {}, {}, {}
  if plano then
    crafts, fabricar, leilao, vendedor = plano.crafts, plano.fabricar, plano.leilao, plano.vendedor
  end
  local noPlano = {}
  for _, c in ipairs(fabricar) do noPlano["m" .. c.magia] = true end
  for _, c in ipairs(crafts) do noPlano["m" .. c.magia] = true end
  for _, r in ipairs(leilao) do noPlano["i" .. r.id] = true end
  for _, r in ipairs(vendedor) do noPlano["i" .. r.id] = true end

  -- vigia de precos: uma linha por item vigiado (verde com BUY quando o minimo esta no teto ou abaixo)
  local vdb = ns.vigiaDB and ns.vigiaDB()
  local vitens = ns.vigiaListar and ns.vigiaListar() or {}
  if vdb and #vitens > 0 then
    local V = ns.vigia
    L[#L + 1] = V.em and ("WATCH " .. date("%H:%M", V.em)) or "WATCH (waiting)"
    for _, x in ipairs(vitens) do
      local esc = V.escadas[x.id]
      local now, buy = "-", false
      if esc and esc[1] then
        local unid = 0
        for _, d in ipairs(esc) do unid = unid + d.qtd end
        now = ns.moeda(esc[1].preco) .. " (" .. unid .. ")"
        buy = esc[1].preco <= x.teto
      end
      L[#L + 1] = (buy and "|cff33ff33BUY " or "|cff999999  ") .. x.nome .. " <= " .. ns.moeda(x.teto) .. " | now " .. now .. "|r"
    end
  end

  -- venda no leilao: pedidos da fila e sugestoes (item vigiado com piso), mais o que ja foi postado
  local pend = ns.vendaPendentes and ns.vendaPendentes() or {}
  local postados = {}
  for id, n in pairs(S.postado or {}) do
    if n > 0 then postados[#postados + 1] = id end
  end
  table.sort(postados)
  if #pend > 0 or #postados > 0 then
    L[#L + 1] = "SELL"
    for _, x in ipairs(pend) do
      L[#L + 1] = "  " .. x.qtd .. " " .. x.nome .. " @ " .. ns.moeda(x.preco) .. (x.auto and " (auto)" or "") .. " [SELL]"
    end
    for _, id in ipairs(postados) do L[#L + 1] = "[x] posted " .. S.postado[id] .. " " .. nomeItem(id) end
  end

  if emRota() then
    for _, x in ipairs(montarLinhasRota(false)) do L[#L + 1] = x end
    return L
  end

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

-- So vale janela na tela: o aviso de fechar pode faltar ou chegar antes do Hide, e o painel ancorado numa janela
-- escondida ficava solto no meio da tela (visto pelo dono em 23/11/2026, depois de fechar o treinador).
local function naTela(fr)
  if not fr then return false end
  if fr.IsShown then return fr:IsShown() and true or false end
  return true
end

alvo = function()
  local c = ns.contexto()
  if c.ah and naTela(AuctionHouseFrame) then return AuctionHouseFrame end
  if c.vend and naTela(MerchantFrame) then return MerchantFrame end
  if c.prof and naTela(_G.ProfessionsFrame) then return _G.ProfessionsFrame end
  if emRota() then
    if c.mail and naTela(rawget(_G, "MailFrame")) then return _G.MailFrame end
    if c.trainer and naTela(rawget(_G, "ClassTrainerFrame")) then return _G.ClassTrainerFrame end
  end
  return nil
end

local function rotuloModo()
  if ns.rotuloModo and ns.modo then return ns.rotuloModo(ns.modo()) end
  return "Profit"
end

local function mesmoModo(a, b)
  return a ~= nil and b ~= nil and a.tipo == b.tipo and a.prof == b.prof and a.alvo == b.alvo
end

local function trocarModo(passo)
  if not (ns.modosDisponiveis and ns.definirModo and ns.modo) then return end
  if ns.compraOcupada and ns.compraOcupada() then return end
  local lista = ns.modosDisponiveis()
  local n = #lista
  if n == 0 then return end
  local atual = ns.modo()
  local i = 0
  for k, m in ipairs(lista) do
    if mesmoModo(m, atual) then i = k; break end
  end
  local novo = i == 0 and 1 or (((i - 1 + passo) % n) + 1)
  ns.definirModo(lista[novo])
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
  if emRota() and not e.ocupado and ns.plano.rota and ns.plano.rota.fonte then
    local r = ns.plano.rota
    fsScan:SetText(fsScan:GetText() .. " | route " .. date("%d/%m %H:%M", r.fonte.em or 0) .. " "
      .. (r.fonte.tipo == "full" and "full" or "public") .. (r.velho and " old" or ""))
  end
  btModo:SetText(rotuloModo())
  btModo:SetEnabled(not (ns.compraOcupada and ns.compraOcupada()))
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
  local ia = ns.iscaAcao and ns.iscaAcao() or nil
  if ia then
    btIsca:SetText(ia.texto)
    btIsca:SetEnabled(ia.executar ~= nil)
    btIsca:Show()
  else
    btIsca:Hide()
  end
  f:SetHeight(yMsg + 16 + 8 + 28 + 8 + (ia and 26 or 0))

  local a = ns.proximaAcao and ns.proximaAcao() or nil
  local prox = (a == nil and emRota()) and textoProximo(ns.plano) or nil
  btAcao:SetText(a and a.texto or prox or "Nothing to do")
  btAcao:SetEnabled(a ~= nil and a.executar ~= nil)
end

-- Prende o painel a direita da janela e o desenha acima dela. A janela de profissao do Forever tem uma coluna de abas
-- na borda direita (LargeSideTabButtonTemplate, Camelot\Blizzard_ProfessionsFrame.xml) e a pagina de craft em
-- frameLevel 100: sem o afastamento e o nivel, o painel ficava atras das abas e da janela.
local reavaliar
local comGancho = {}

local function ancorar(a)
  f:ClearAllPoints()
  local dx = (a == _G.ProfessionsFrame) and 48 or 4
  f:SetPoint("TOPLEFT", a, "TOPRIGHT", dx, 0)
  f:SetFrameStrata(a:GetFrameStrata() or "MEDIUM")
  f:SetFrameLevel(min((a:GetFrameLevel() or 0) + 200, 9000))
  -- quando a janela de ancora some, o painel reavalia na hora, com ou sem o evento de fechar
  if not comGancho[a] and a.HookScript then
    comGancho[a] = true
    a:HookScript("OnHide", function() reavaliar() end)
  end
end

reavaliar = function()
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

-- Na rota, "nothing" quer dizer que a rota nao pede nada do leilao agora (tudo na bolsa ou no correio), nao que faltam
-- receitas: o texto do lucro confundiu o dono em 23/11/2026.
local function motivoScan(motivo)
  if motivo == "nothing" and emRota() then return "Nothing to buy for the route" end
  return MOTIVOS_SCAN[motivo] or tostring(motivo)
end

btScan:SetScript("OnClick", function()
  msgPainel = nil
  local ok, motivo = ns.scanDirigido(function() ns.atualizarPainel() end)
  if not ok then msgPainel = motivoScan(motivo) end
  ns.atualizarPainel()
end)

btFull:SetScript("OnClick", function()
  msgPainel = nil
  local ok, motivo = ns.fullScan(function() ns.atualizarPainel() end)
  if not ok then msgPainel = motivoScan(motivo) end
  ns.atualizarPainel()
end)

btModo:SetScript("OnClick", function(_, botaoMouse)
  trocarModo(botaoMouse == "RightButton" and -1 or 1)
  ns.atualizarPainel()
end)

btAcao:SetScript("OnClick", function()
  local a = ns.proximaAcao()
  if a and a.executar then a.executar() end
  ns.atualizarPainel()
end)

btIsca:SetScript("OnClick", function()
  local a = ns.iscaAcao and ns.iscaAcao()
  if a and a.executar then a.executar() end
  ns.atualizarPainel()
end)

-- Tecla do botao de acao (secao 13): so com a AH aberta, um aperto = um clique no botao (SetOverrideBindingClick).
-- O jogo aceita os botoes laterais do mouse direto (BUTTON4, BUTTON5); nada de macro de varios cliques.
local teclaLigada = nil
function ns.aplicarTecla()
  if InCombatLockdown() then return end
  local db = rawget(_G, "CompraForeverDB")
  local k = type(db) == "table" and db.tecla or nil
  local ki = type(db) == "table" and db.teclaIsca or nil
  -- depois de um /reload com a AH aberta o AUCTION_HOUSE_SHOW nao vem: confere a janela tambem
  local ahf = rawget(_G, "AuctionHouseFrame")
  local ah = (ns.contexto and ns.contexto().ah) or (ahf ~= nil and ahf.IsShown ~= nil and ahf:IsShown() == true)
  if teclaLigada then
    ClearOverrideBindings(f)
    teclaLigada = nil
  end
  if k and ah then
    SetOverrideBindingClick(f, true, k, "CompraForeverAcao")
    teclaLigada = k
  end
  if ki and ki ~= k and ah then
    SetOverrideBindingClick(f, true, ki, "CompraForeverIsca")
    teclaLigada = teclaLigada or ki
  end
end
ns.ao("AUCTION_HOUSE_SHOW", function() ns.aplicarTecla() end)
ns.ao("AUCTION_HOUSE_CLOSED", function() ns.aplicarTecla() end)

-- Eventos e relogio ------------------------------------------------------------------------------------------

for _, ev in ipairs({ "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "MERCHANT_SHOW", "MERCHANT_CLOSED", "TRADE_SKILL_CLOSE",
                         "MAIL_SHOW", "MAIL_CLOSED", "TRAINER_SHOW", "TRAINER_CLOSED" }) do
  ns.ao(ev, function()
    reavaliar()
    C_Timer.After(0.1, reavaliar)   -- a janela da Blizzard pode abrir depois deste ouvinte, no mesmo evento
  end)
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
