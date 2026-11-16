-- Pedidos.lua (PregaoForever): porta unica das consultas ao leilao (regra 9): folego, orcamento, ritmo,
-- uma consulta em voo, vigia do throttle e descarte de resposta alheia. Onda 2.
-- Contrato: ARQUITETURA.md, secao 3.5; DESIGN.md, secao 5.2 ("Regras de Pedidos.lua").
-- Nada aqui abre folego por evento ou timer: so abrirFolego, chamado pela tecla da Varredura.
local _, ns = ...
ns.pedidos = ns.pedidos or {}
local P = ns.pedidos

-- tipos de consulta; conta = entra em ritmo.buscas_min e folego.max_buscas (so buscas por item)
local TIPOS = {
  browse = { conta = false },
  mais_browse = { conta = false },
  proprios = { conta = false },
  busca = { conta = true, item = true },
  busca_venda = { conta = true, item = true },
  releitura = { conta = true, item = true },
  mais_busca = { conta = true, item = true },
}

local FILTROS_QUALIDADE = {
  'PoorQuality', 'CommonQuality', 'UncommonQuality', 'RareQuality', 'EpicQuality', 'LegendaryQuality', 'ArtifactQuality',
}

local FAIXA_TRAVADO = 'API STALLED - close and reopen the auction house'
local PASSO_VIGIA = 0.5
local JANELA_RITMO = 60

-- estado unico do modulo
local est = {
  fase = 'PARADO',     -- PARADO, ABERTO, TRAVADO
  gen = 0,             -- muda a cada abertura e fechamento: invalida timers antigos
  dono = nil,          -- funcao de quem dirige o ciclo; recebe ('fim', motivo)
  abertoEm = 0,
  buscas = 0,
  dropped = 0,
  motivo = nil,
  voo = nil,           -- { id, p, t, chave, itemID, itemKey, com }
  pend = nil,          -- pedido aceito que espera o throttle ou o ritmo
  prontoAusente = nil, -- ns.mono() em que o throttle passou a nao estar pronto, com pedido a enviar
  janela = {},         -- horas (ns.mono) das buscas por item, para o ritmo
  ultimaTecla = nil,
  aberto = nil,        -- leilao aberto, pelos eventos SHOW e CLOSED
  seqVoo = 0,
  vigia = nil,         -- gen do laco de vigia em andamento
}

local function cfgFolego()
  return (ns.cfg and ns.cfg.folego) or {}
end

local function cfgGuardas()
  return (ns.cfg and ns.cfg.guardas) or {}
end

local function tPulso()
  local t = (ns.cfg and tonumber(ns.cfg.T_pulso)) or 90
  if t > 240 then t = 240 end
  return t
end

local function leilaoAberto()
  if est.aberto ~= nil then return est.aberto end
  if AuctionHouseFrame and AuctionHouseFrame.IsShown then
    return AuctionHouseFrame:IsShown() and true or false
  end
  return false
end

-- tecla do dono ha menos de T_pulso segundos (I9). Estrito: no limite exato ja nao vale.
local function teclaRecente()
  if not est.ultimaTecla then return false end
  return (ns.mono() - est.ultimaTecla) < tPulso()
end

local function limparJanela(agora)
  local nova = {}
  local j = est.janela
  for i = 1, #j do
    if agora - j[i] < JANELA_RITMO then nova[#nova + 1] = j[i] end
  end
  est.janela = nova
  return #nova
end

-- ---------- chave de busca ----------
local function ehCommodity(chave)
  return string.find(chave, ':', 1, true) == nil
end

local function itemKeyDe(chave)
  if ns.itens and ns.itens.itemKey then
    local k = ns.itens.itemKey(chave)
    if k then return k end
  end
  local a, b, c = string.match(chave, '^(%d+):(%d+):(%d+)$')
  if a then
    return { itemID = tonumber(a), itemLevel = tonumber(b), itemSuffix = tonumber(c), battlePetSpeciesID = 0 }
  end
  return { itemID = tonumber(chave), itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 }
end

local function mesmaChave(voo, itemKey)
  if type(itemKey) ~= 'table' then return false end
  local k = voo.itemKey
  return itemKey.itemID == k.itemID and (itemKey.itemLevel or 0) == (k.itemLevel or 0)
    and (itemKey.itemSuffix or 0) == (k.itemSuffix or 0)
end

local function filtrosDeQualidade()
  local f = {}
  local lista = Enum and Enum.AuctionHouseFilter
  if lista then
    for i = 1, #FILTROS_QUALIDADE do
      local v = lista[FILTROS_QUALIDADE[i]]
      if v ~= nil then f[#f + 1] = v end
    end
  end
  return f
end

-- ---------- fim e falha ----------
local function encerrar(fase, motivo)
  est.fase = fase
  est.motivo = motivo
  est.voo = nil
  est.pend = nil
  est.prontoAusente = nil
  est.gen = est.gen + 1
  local d = est.dono
  est.dono = nil
  if d then d('fim', motivo) end
end

function P.fecharFolego(motivo)
  if est.fase ~= 'ABERTO' then return end
  encerrar('PARADO', motivo or 'fim')
end

local function travar()
  if est.fase ~= 'ABERTO' then return end
  ns.marcarFaixa('travado', FAIXA_TRAVADO)
  ns.log('warn', 'throttle stuck, queries stopped')
  encerrar('TRAVADO', 'travado')
end

local function falhar(voo, motivo)
  if est.voo ~= voo then return end
  est.voo = nil
  if voo.p.aoFalhar then voo.p.aoFalhar(motivo) end
end

local function responder(voo, info)
  if est.voo ~= voo then return end
  est.voo = nil
  if voo.p.aoResponder then voo.p.aoResponder(info) end
end

-- ---------- envio ----------
local function chamarCliente(p, voo)
  local tipo = p.tipo
  local sorts = p.sorts or {}
  if tipo == 'browse' then
    C_AuctionHouse.SendBrowseQuery({ searchString = '', sorts = sorts, filters = filtrosDeQualidade() })
  elseif tipo == 'mais_browse' then
    C_AuctionHouse.RequestMoreBrowseResults()
  elseif tipo == 'proprios' then
    C_AuctionHouse.QueryOwnedAuctions(sorts)
  elseif tipo == 'busca' then
    local separar = true
    if p.separar ~= nil then separar = p.separar end
    C_AuctionHouse.SendSearchQuery(voo.itemKey, sorts, separar)
  elseif tipo == 'busca_venda' then
    local separar = true
    if p.separar ~= nil then separar = p.separar end
    C_AuctionHouse.SendSellSearchQuery(voo.itemKey, sorts, separar)
  elseif tipo == 'releitura' then
    if voo.com then
      C_AuctionHouse.RefreshCommoditySearchResults(voo.itemID)
    else
      C_AuctionHouse.RefreshItemSearchResults(voo.itemKey)
    end
  elseif tipo == 'mais_busca' then
    if voo.com then
      C_AuctionHouse.RequestMoreCommoditySearchResults(voo.itemID)
    else
      C_AuctionHouse.RequestMoreItemSearchResults(voo.itemKey)
    end
  end
end

local vigiar

-- Tenta mandar o pedido pendente. Devolve nada; ou envia, ou continua pendente, ou fecha o folego.
local function tentar()
  local p = est.pend
  if not p or est.fase ~= 'ABERTO' then return end
  local agora = ns.mono()
  -- I9: conferida a cada tentativa, imediatamente antes do envio
  if not teclaRecente() then
    P.fecharFolego('sem_tecla')
    return
  end
  local maxS = cfgFolego().max_s
  if maxS and (agora - est.abertoEm) >= maxS then
    P.fecharFolego('max_s')
    return
  end
  local def = TIPOS[p.tipo]
  if def.conta then
    local maxB = cfgFolego().max_buscas
    if maxB and est.buscas >= maxB then
      P.fecharFolego('max_buscas')
      return
    end
    local porMin = (ns.cfg and ns.cfg.ritmo and ns.cfg.ritmo.buscas_min) or 30
    if limparJanela(agora) >= porMin then
      return -- espera o ritmo; o vigia tenta de novo
    end
  end
  if not C_AuctionHouse.IsThrottledMessageSystemReady() then
    if not est.prontoAusente then est.prontoAusente = agora end
    local lim = cfgGuardas().throttle_travado_s or 30
    if (agora - est.prontoAusente) >= lim then travar() end
    return
  end
  est.prontoAusente = nil
  est.pend = nil
  est.seqVoo = est.seqVoo + 1
  local voo = { id = est.seqVoo, p = p, t = agora }
  if def.item then
    voo.chave = p.chave
    voo.com = ehCommodity(p.chave)
    voo.itemKey = p.itemKey or itemKeyDe(p.chave)
    voo.itemID = voo.itemKey.itemID
  end
  est.voo = voo
  if def.conta then
    est.buscas = est.buscas + 1
    est.janela[#est.janela + 1] = agora
  end
  local ok = xpcall(chamarCliente, geterrorhandler(), p, voo)
  if not ok then
    falhar(voo, 'erro')
    return
  end
  local prazo = cfgGuardas().prazo_consulta_s or 10
  local id = voo.id
  ns.depois(prazo, function()
    if est.voo and est.voo.id == id then falhar(est.voo, 'prazo') end
  end)
end

-- laco de vigia: roda so enquanto ha pedido esperando o throttle ou o ritmo; um por folego
vigiar = function()
  if not est.pend or est.vigia == est.gen then return end
  local gen = est.gen
  est.vigia = gen
  local function passo()
    if gen ~= est.gen or est.fase ~= 'ABERTO' then return end
    tentar()
    if gen ~= est.gen or est.fase ~= 'ABERTO' then return end
    if not est.pend then
      est.vigia = nil
      return
    end
    ns.depois(PASSO_VIGIA, passo)
  end
  ns.depois(PASSO_VIGIA, passo)
end

function P.tecla()
  est.ultimaTecla = ns.mono()
end

function P.abrirFolego(dono)
  if est.fase == 'TRAVADO' then return false, 'travado' end
  if est.fase == 'ABERTO' then return false, 'aberto' end
  if not leilaoAberto() then return false, 'leilao_fechado' end
  if not teclaRecente() then return false, 'sem_tecla' end
  est.fase = 'ABERTO'
  est.gen = est.gen + 1
  est.dono = dono
  est.abertoEm = ns.mono()
  est.buscas = 0
  est.dropped = 0
  est.motivo = nil
  est.voo = nil
  est.pend = nil
  est.prontoAusente = nil
  est.vigia = nil
  return true
end

-- p = { tipo, chave, sorts, aoResponder, aoFalhar }. Devolve true se aceitou (enviou ou ficou pendente);
-- false, motivo se recusou. Recusa por I9, tempo ou max_buscas fecha o folego.
function P.enviar(p)
  if est.fase ~= 'ABERTO' then return false, 'sem_folego' end
  local def = type(p) == 'table' and TIPOS[p.tipo]
  if not def then return false, 'tipo' end
  if def.item and type(p.chave) ~= 'string' then return false, 'chave' end
  if est.voo or est.pend then return false, 'em_voo' end
  est.pend = p
  tentar()
  if est.fase ~= 'ABERTO' then
    return false, est.motivo
  end
  if est.pend then vigiar() end
  return true
end

function P.estado()
  local agora = ns.mono()
  return {
    fase = est.fase,
    buscas = est.buscas,
    buscasMin = limparJanela(agora),
    emVoo = est.voo ~= nil,
    motivo = est.motivo,
  }
end

-- ---------- eventos ----------
local function tipoEmVoo()
  return est.voo and est.voo.p.tipo or nil
end

ns.ao('AUCTION_HOUSE_SHOW', function()
  est.aberto = true
end)

ns.ao('AUCTION_HOUSE_CLOSED', function()
  est.aberto = false
  if est.fase == 'ABERTO' then
    P.fecharFolego('closed')
  elseif est.fase == 'TRAVADO' then
    est.fase = 'PARADO'
    est.motivo = 'closed'
  end
  est.voo = nil
  est.pend = nil
  est.prontoAusente = nil
  ns.marcarFaixa('travado', nil)
end)

ns.ao('AUCTION_HOUSE_THROTTLED_SYSTEM_READY', function()
  est.prontoAusente = nil
  tentar()
  if est.pend then vigiar() end
end)

ns.ao('AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED', function()
  if est.fase ~= 'ABERTO' then return end
  est.dropped = est.dropped + 1
  if est.dropped >= 2 then
    P.fecharFolego('descartada')
    return
  end
  if est.voo then falhar(est.voo, 'descartada') end
end)

-- eventos do throttle que so contam como sinal: o envio e a resposta acontecem nos eventos de resultado
ns.ao('AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED', function() end)
ns.ao('AUCTION_HOUSE_THROTTLED_MESSAGE_SENT', function() end)
ns.ao('AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED', function() end)

-- resposta de resumo chega com payload nil; com itemKey no payload e resposta de busca (nao e nossa em RESUMO)
ns.ao('AUCTION_HOUSE_NEW_RESULTS_RECEIVED', function(_, itemKey)
  local voo = est.voo
  if voo and voo.p.tipo == 'browse' and itemKey == nil then voo.recebido = true end
end)

-- a lista do resumo tambem muda quando chega resposta de busca: so vale com um browse em voo
ns.ao('AUCTION_HOUSE_BROWSE_RESULTS_UPDATED', function()
  local voo = est.voo
  local tipo = tipoEmVoo()
  if tipo == 'browse' then
    local linhas = C_AuctionHouse.GetBrowseResults()
    responder(voo, { linhas = linhas, completo = C_AuctionHouse.HasFullBrowseResults() and true or false })
  elseif tipo == 'mais_browse' then
    -- a lista foi trocada no meio da paginacao: resumo incompleto
    falhar(voo, 'lista_mudou')
  end
end)

ns.ao('AUCTION_HOUSE_BROWSE_RESULTS_ADDED', function(_, adicionadas)
  local voo = est.voo
  if tipoEmVoo() == 'mais_browse' then
    responder(voo, { linhas = adicionadas or {}, completo = C_AuctionHouse.HasFullBrowseResults() and true or false })
  end
end)

ns.ao('AUCTION_HOUSE_BROWSE_FAILURE', function()
  local voo = est.voo
  local tipo = tipoEmVoo()
  if tipo == 'browse' or tipo == 'mais_browse' then falhar(voo, 'falha') end
end)

ns.ao('OWNED_AUCTIONS_UPDATED', function()
  local voo = est.voo
  if tipoEmVoo() == 'proprios' then responder(voo, {}) end
end)

local function eventoDeBusca(voo, ok, tipos)
  if not voo or not ok then return end
  for i = 1, #tipos do
    if voo.p.tipo == tipos[i] then
      responder(voo, { chave = voo.chave, itemKey = voo.itemKey, com = voo.com })
      return
    end
  end
end

local BUSCAS = { 'busca', 'busca_venda', 'releitura' }
local MAIS = { 'mais_busca' }

ns.ao('COMMODITY_SEARCH_RESULTS_UPDATED', function(_, itemID)
  local voo = est.voo
  eventoDeBusca(voo, voo and voo.com and voo.itemID == itemID, BUSCAS)
end)

ns.ao('ITEM_SEARCH_RESULTS_UPDATED', function(_, itemKey, novoLeilao)
  if novoLeilao ~= nil then return end -- atualizacao de um leilao, nao e resposta
  local voo = est.voo
  eventoDeBusca(voo, voo and not voo.com and mesmaChave(voo, itemKey), BUSCAS)
end)

ns.ao('COMMODITY_SEARCH_RESULTS_ADDED', function(_, itemID)
  local voo = est.voo
  eventoDeBusca(voo, voo and voo.com and voo.itemID == itemID, MAIS)
end)

ns.ao('ITEM_SEARCH_RESULTS_ADDED', function(_, itemKey)
  local voo = est.voo
  eventoDeBusca(voo, voo and not voo.com and mesmaChave(voo, itemKey), MAIS)
end)
