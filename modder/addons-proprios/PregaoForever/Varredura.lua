-- Varredura.lua (PregaoForever): maquina de varrer (DESIGN 5.2, opcao a: uma tecla por folego).
-- PARADO -> PROPRIOS -> RESUMO (se vencido) -> TRIAGEM -> FOCO -> PARADO. Toda consulta sai por ns.pedidos.
-- Contrato: ARQUITETURA.md, secao 3.6 e mudanca 7 (esta e dona de casa().resumo e de pers().proprios). Onda 2.
local _, ns = ...
ns.varredura = ns.varredura or {}
local R = ns.varredura

local v = {
  fase = 'PARADO',    -- PARADO, PROPRIOS, RESUMO, TRIAGEM, FOCO
  feitas = 0,
  total = 0,
  foco = {},          -- chaves do folego, na ordem de envio
  idx = 0,
  acum = nil,         -- linhas do resumo em acumulo
  tPedido = 0,        -- hora (servidor) do pedido do resumo
  tResp = 0,
  pedidosResumo = 0,
  tResumo = nil,      -- hora do ultimo resumo guardado nesta sessao
  piso = {},          -- candidatas da triagem do piso, do ultimo resumo lido: { chave }
  proprioChaves = {}, -- chaves com leilao proprio ativo, do ultimo PROPRIOS
  precisaConciliar = true,
  folegoMorto = false, -- o folego acabou durante a TRIAGEM: termina de ler o resumo, sem foco
  fatia = nil,
}

local function cfgFoco()
  return (ns.cfg and ns.cfg.foco) or {}
end

local function ehCom(chave)
  return string.find(chave, ':', 1, true) == nil
end

-- texto da chave de um itemKey: Itens quando existe, senao pela forma do itemKey
local function chaveDe(k)
  if ns.itens and ns.itens.chave then
    local c = ns.itens.chave(k)
    if c then return c end
  end
  if (k.itemLevel or 0) == 0 and (k.itemSuffix or 0) == 0 then
    return string.format('%d', k.itemID)
  end
  return string.format('%d:%d:%d', k.itemID, k.itemLevel or 0, k.itemSuffix or 0)
end

local function itemKeyDe(chave)
  local a, b, c = string.match(chave, '^(%d+):(%d+):(%d+)$')
  if a then
    return { itemID = tonumber(a), itemLevel = tonumber(b), itemSuffix = tonumber(c), battlePetSpeciesID = 0 }
  end
  return { itemID = tonumber(chave), itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 }
end

-- ---------- fim ----------
local function parado()
  v.fase = 'PARADO'
  v.acum = nil
  v.folegoMorto = false
  if v.fatia then
    v.fatia:parar()
    v.fatia = nil
  end
  ns.sujo('tela')
end

-- chamada pelo Pedidos quando o folego acaba (fim da lista, max_buscas, tempo, I9, travado, descartes, fechado)
local function dono(evento, motivo)
  if evento ~= 'fim' then return end
  if v.fase == 'TRIAGEM' and v.fatia and motivo ~= 'closed' then
    v.folegoMorto = true -- termina de ler o resumo que ja chegou; nao ha foco
    return
  end
  parado()
end

local function terminar()
  ns.pedidos.fecharFolego('fim')
  if v.fase ~= 'PARADO' then parado() end
end

-- ---------- prioridade do foco ----------
local function prioridade(chave)
  local delta = (cfgFoco().delta_min or 10) * 60
  if ns.escada and ns.escada.ultima then
    local foto, idade = ns.escada.ultima(chave)
    if foto and idade then
      return 1 - math.exp(-idade / delta)
    end
  end
  return 1
end

local function ordenarPorPrioridade(chaves)
  local pontos = {}
  for i = 1, #chaves do pontos[chaves[i]] = prioridade(chaves[i]) end
  table.sort(chaves, function(a, b)
    if pontos[a] ~= pontos[b] then return pontos[a] > pontos[b] end
    return a < b
  end)
  return chaves
end

-- chaves de lote comprado aberto (leitura defensiva: o formato e do Livro)
local function chavesDeLotes()
  local out = {}
  if not (ns.banco and ns.banco.pers) then return out end
  local p = ns.banco.pers()
  local ab = p and p.abertos
  if type(ab) ~= 'table' then return out end
  for i = 1, #ab do
    local x = ab[i]
    if type(x) == 'string' then
      local partes = {}
      for campo in string.gmatch(x, '[^|]*') do partes[#partes + 1] = campo end
      if partes[7] == 'comprado' and partes[4] ~= '' then out[#out + 1] = partes[4] end
    elseif type(x) == 'table' and x.origem == 'comprado' and x.chave then
      out[#out + 1] = x.chave
    end
  end
  return out
end

-- ---------- o foco (DESIGN 5.1) ----------
local function montarFoco()
  local f = cfgFoco()
  local max = (ns.cfg.folego and ns.cfg.folego.max_buscas) or 20
  local usadas = {}
  local function unicas(lista)
    local out = {}
    for i = 1, #lista do
      if not usadas[lista[i]] then
        usadas[lista[i]] = true
        out[#out + 1] = lista[i]
      end
    end
    return out
  end

  -- 1. vigilia: as fixadas e os lotes comprados abertos, ate vigilia_max
  local cand = {}
  local fix = f.vigilia or {}
  for i = 1, #fix do cand[#cand + 1] = fix[i] end
  local lotes = chavesDeLotes()
  for i = 1, #lotes do cand[#cand + 1] = lotes[i] end
  local vig = unicas(cand)
  local vmax = f.vigilia_max or 8
  while #vig > vmax do
    usadas[vig[#vig]] = nil
    vig[#vig] = nil
  end

  -- 2. cotas, encolhidas na proporcao das vagas que a vigilia ocupou (minimo 1); giro e da fase 2
  local cotas = f.cotas or { bolsas = 8, proprios = 4, piso = 4 }
  local livres = max - #vig
  if livres < 0 then livres = 0 end
  local function cota(n)
    if not n or n <= 0 then return 0 end
    local c = ns.int(n * livres / max)
    if c < 1 then c = 1 end
    return c
  end

  local bolsas, vistasB = {}, {}
  if ns.itens and ns.itens.bolsas then
    local lista = ns.itens.bolsas()
    for i = 1, #lista do
      local ch = lista[i].chave
      if ch and not lista[i].reservado and not vistasB[ch] then
        vistasB[ch] = true
        bolsas[#bolsas + 1] = ch
      end
    end
  end
  local candBolsas = ordenarPorPrioridade(bolsas)

  local function sobra(lista)
    local out = {}
    for i = 1, #lista do out[i] = lista[i] end
    return out
  end

  local listas = {
    { nome = 'bolsas', n = cota(cotas.bolsas), chaves = candBolsas },
    { nome = 'proprios', n = cota(cotas.proprios), chaves = ordenarPorPrioridade(sobra(v.proprioChaves)) },
    { nome = 'piso', n = cota(cotas.piso), chaves = ordenarPorPrioridade(sobra(v.piso)) },
  }
  local escolhidas = { bolsas = {}, proprios = {}, piso = {} }
  local carga = 0 -- vaga ociosa de uma cota passa a seguinte
  for i = 1, #listas do
    local l = listas[i]
    local vagas = l.n + carga
    local pegas = 0
    for j = 1, #l.chaves do
      if pegas >= vagas then break end
      local ch = l.chaves[j]
      if not usadas[ch] then
        usadas[ch] = true
        escolhidas[l.nome][#escolhidas[l.nome] + 1] = ch
        pegas = pegas + 1
      end
    end
    carga = vagas - pegas
  end

  -- 4. ordem de envio: vigilia e triagem primeiro; as linhas de acao (venda e compra) por ultimo
  local foco = {}
  local ordem = { vig, escolhidas.piso, escolhidas.proprios, escolhidas.bolsas }
  for i = 1, #ordem do
    for j = 1, #ordem[i] do foco[#foco + 1] = ordem[i][j] end
  end
  return foco
end

-- ---------- FOCO: uma chave por vez ----------
local proxima

local function fimDaChave()
  v.feitas = v.feitas + 1
  ns.sujo('tela')
  proxima()
end

local function temFrente(foto)
  if foto.frente ~= nil then return foto.frente and true or false end
  local m = foto.marcas
  if type(m) == 'string' then return string.find(m, 'F', 1, true) ~= nil end
  if type(m) == 'table' then return (m.F or m.frente) and true or false end
  return true
end

local function gravarFoto(chave, foto)
  if foto then ns.escada.gravar(chave, foto) end
end

local function lerFoto(chave, tentativa)
  local k = itemKeyDe(chave)
  local com = ehCom(chave)
  local foto
  if com then foto = ns.escada.fotoC(k.itemID) else foto = ns.escada.fotoI(k) end
  if foto and not temFrente(foto) and tentativa < 2 then
    local cheia
    if com then cheia = C_AuctionHouse.HasFullCommoditySearchResults(k.itemID)
    else cheia = C_AuctionHouse.HasFullItemSearchResults(k) end
    if not cheia then
      -- resposta sem a frente: ate 2 paginas a mais, na mesma chave
      local ok = ns.pedidos.enviar({
        tipo = 'mais_busca', chave = chave, sorts = {},
        aoResponder = function() lerFoto(chave, tentativa + 1) end,
        aoFalhar = function()
          gravarFoto(chave, foto)
          fimDaChave()
        end,
      })
      if not ok then terminar() end
      return
    end
  end
  gravarFoto(chave, foto)
  if com then
    fimDaChave()
    return
  end
  -- equipamento: tambem a busca de venda, com a chave sem nivel e sem sufixo (as variantes do mesmo itemID)
  local base = string.format('%d:0:0', k.itemID)
  local ok = ns.pedidos.enviar({
    tipo = 'busca_venda', chave = base, sorts = {},
    aoResponder = function()
      gravarFoto(base, ns.escada.fotoI(itemKeyDe(base)))
      fimDaChave()
    end,
    aoFalhar = function() fimDaChave() end,
  })
  if not ok then terminar() end
end

local function buscar(chave)
  local ok = ns.pedidos.enviar({
    tipo = 'busca', chave = chave, sorts = {},
    aoResponder = function() lerFoto(chave, 0) end,
    aoFalhar = function() fimDaChave() end, -- 10 s sem a resposta: sem foto, proxima chave
  })
  if not ok then terminar() end
end

proxima = function()
  if v.fase ~= 'FOCO' then return end
  v.idx = v.idx + 1
  if v.idx > #v.foco then
    terminar()
    return
  end
  buscar(v.foco[v.idx])
end

local function iniciarFoco()
  v.fase = 'FOCO'
  v.foco = montarFoco()
  v.idx = 0
  v.feitas = 0
  v.total = #v.foco
  ns.sujo('tela')
  proxima()
end

-- ---------- TRIAGEM: le o acumulado em fatias e guarda o resumo ----------
local function triagem(completa)
  v.fase = 'TRIAGEM'
  local linhas = v.acum or {}
  local n = #linhas
  local dados = {}
  local piso = {}
  local tPedido, tResp, pedidos = v.tPedido, v.tResp, v.pedidosResumo
  local alca = ns.fatiar(n, function(i)
    local r = linhas[i]
    local k = r.itemKey
    local chave = chaveDe(k)
    local minimo = r.minPrice or 0
    local qtd = r.totalQuantity or 0
    dados[i] = { chave = chave, min = minimo, qtd = qtd }
    -- piso: commodity com menor preco abaixo do preco de vendedor (item so depois da S4, H-07)
    if qtd > 0 and minimo > 0 and ehCom(chave) then
      local vend = ns.vend and ns.vend[k.itemID]
      if vend and vend > 0 and minimo < vend then piso[#piso + 1] = chave end
    end
  end, function()
    v.fatia = nil
    v.piso = piso
    v.tResumo = tResp
    ns.banco.casa().resumo = ns.banco.cod.resumo({
      t = tPedido, tr = tResp, pedidos = pedidos, completa = completa and true or false, n = n, dados = dados,
    })
    v.acum = nil
    if v.folegoMorto then
      parado()
      return
    end
    iniciarFoco()
  end)
  if v.fase == 'TRIAGEM' then v.fatia = alca end
end

-- ---------- RESUMO: SendBrowseQuery, GetBrowseResults uma vez, paginas pelo payload de ADDED ----------
local function seguirResumo(info)
  if info.completo then
    triagem(true)
    return
  end
  local ok = ns.pedidos.enviar({
    tipo = 'mais_browse', sorts = {},
    aoResponder = function(mais)
      v.pedidosResumo = v.pedidosResumo + 1
      local a = v.acum
      for i = 1, #mais.linhas do a[#a + 1] = mais.linhas[i] end
      seguirResumo(mais)
    end,
    aoFalhar = function() triagem(false) end,
  })
  if not ok then triagem(false) end
end

local function iniciarResumo()
  v.fase = 'RESUMO'
  v.acum = {}
  v.pedidosResumo = 0
  v.tPedido = ns.servidor()
  ns.sujo('tela')
  local ok = ns.pedidos.enviar({
    tipo = 'browse', sorts = {},
    aoResponder = function(info)
      v.pedidosResumo = 1
      v.tResp = ns.servidor()
      v.acum = info.linhas -- zera o acumulo: a lista inteira vem desta chamada
      seguirResumo(info)
    end,
    aoFalhar = function()
      v.tResp = ns.servidor()
      triagem(false)
    end,
  })
  if not ok then triagem(false) end
end

local function resumoVencido()
  local t = v.tResumo
  if not t and ns.banco and ns.banco.casa then
    local r = ns.banco.casa().resumo
    t = r and r.t
  end
  if not t then return true end
  local minimo = (ns.cfg.idades and (ns.cfg.idades.resumo_vencido_min or ns.cfg.idades.resumo_min)) or 10
  return (ns.servidor() - t) > minimo * 60
end

-- ---------- PROPRIOS: QueryOwnedAuctions, grava pers().proprios, concilia no primeiro folego ----------
local function lerProprios()
  local n = C_AuctionHouse.GetNumOwnedAuctions()
  local agora = ns.servidor()
  local linhas, chaves, vistas = {}, {}, {}
  for i = 1, n do
    local a = C_AuctionHouse.GetOwnedAuctionInfo(i)
    if a then
      linhas[#linhas + 1] = ns.banco.cod.proprio({
        auctionID = a.auctionID, estado = a.status or 0, qtd = a.quantity or 1, tempo = a.timeLeftSeconds or 0,
        lance = a.bidAmount or 0, arremate = a.buyoutAmount or 0, t = agora,
      })
      if (a.status or 0) == 0 and a.itemKey then
        local ch = chaveDe(a.itemKey)
        if not vistas[ch] then
          vistas[ch] = true
          chaves[#chaves + 1] = ch
        end
      end
    end
  end
  ns.banco.pers().proprios = linhas
  v.proprioChaves = chaves
end

local function depoisDeProprios()
  if resumoVencido() then
    iniciarResumo()
  else
    iniciarFoco()
  end
end

local function iniciarProprios()
  v.fase = 'PROPRIOS'
  ns.sujo('tela')
  local ok = ns.pedidos.enviar({
    tipo = 'proprios', sorts = {},
    aoResponder = function()
      lerProprios()
      if v.precisaConciliar then
        v.precisaConciliar = false
        if ns.cofre and ns.cofre.conciliar then
          ns.seguro(function() ns.cofre.conciliar('leilao') end)()
        end
      end
      depoisDeProprios()
    end,
    aoFalhar = function() depoisDeProprios() end, -- sem resposta: segue sem os proprios; concilia no proximo folego
  })
  if not ok then terminar() end
end

-- ---------- publico ----------
-- O L: abre o folego (so com tecla do dono ha ate T_pulso) e dirige a maquina. Devolve true ou false, motivo.
function R.tecla()
  if v.fase ~= 'PARADO' then return false, 'varrendo' end
  local ok, motivo = ns.pedidos.abrirFolego(dono)
  if not ok then return false, motivo end
  v.feitas = 0
  v.total = 0
  v.foco = {}
  v.idx = 0
  v.folegoMorto = false
  iniciarProprios()
  return true
end

function R.estado()
  local idade
  local t = v.tResumo
  if not t and ns.banco and ns.banco.casa then
    local r = ns.banco.casa().resumo
    t = r and r.t
  end
  if t then idade = ns.servidor() - t end
  return { fase = v.fase, feitas = v.feitas, total = v.total, idadeResumo = idade }
end

ns.ao('AUCTION_HOUSE_SHOW', function()
  v.precisaConciliar = true
end)

ns.ao('AUCTION_HOUSE_CLOSED', function()
  v.precisaConciliar = true
  v.foco = {}
  v.proprioChaves = {}
  parado()
end)
