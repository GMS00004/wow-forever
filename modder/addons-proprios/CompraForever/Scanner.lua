local addon, ns = ...

-- Scanner: busca dirigida, full scan e /compra sonda (CONTRATO secoes 5 e 8). Monta ns.scan e chama ns.replanejar().
-- aoTerminar(scan) no fim; aoTerminar(nil, motivo) se abortar ("closed") ou nao comecar.

local floor, min = math.floor, math.min

local TEMPO_ID = 6         -- s por id na busca dirigida
local TEMPO_CACA = 3       -- s na busca da caca (uma pagina; o dono aperta de novo)
local RECARGA = 900        -- s entre full scans
local MAX_PAGINAS = 3
local MAX_UNIDADES = 1000
local LOTE = 250           -- linhas lidas por quadro no full scan
local FULL_MAX = 600       -- s ate desistir de esperar a lista do full scan
local IDS_SONDA = { 4461, 4234, 2318, 2319, 2592 }

ns.scan = nil
ns.scanEstado = { ocupado = false, feito = 0, total = 0 }

local ativo = nil          -- sessao em andamento
local ahAberta = false

local function leilaoAberto()
  if ahAberta then return true end
  return AuctionHouseFrame ~= nil and AuctionHouseFrame:IsShown() == true
end

local function ordenar(lista)
  table.sort(lista, function(a, b)
    if a.preco ~= b.preco then return a.preco < b.preco end
    if (a.leilao or 0) ~= (b.leilao or 0) then return (a.leilao or 0) < (b.leilao or 0) end
    return a.qtd > b.qtd
  end)
  return lista
end

local function souDono(nome)
  return nome ~= nil and nome == UnitName("player")
end

-- Sessao ---------------------------------------------------------------------------------------------

local function abrirSessao(tipo, aoTerminar)
  local S = { tipo = tipo, aoTerminar = aoTerminar, escadas = {}, revenda = {}, sem = {}, fim = false }
  ativo = S
  ns.scanEstado = { ocupado = true, feito = 0, total = 0 }
  return S
end

local function encerrar(S, scan, motivo)
  if S.fim then return end
  S.fim = true
  if ativo == S then ativo = nil end
  ns.scanEstado = { ocupado = false, feito = scan and ns.scanEstado.total or ns.scanEstado.feito, total = ns.scanEstado.total }
  if scan and not S.sonda then
    ns.scan = scan
    ns.replanejar()
    -- historico de precos dos itens vigiados (so o que esta busca leu: no refresh, S.escadas e o subconjunto)
    if ns.vigiaRegistrar then ns.vigiaRegistrar(S.escadas, time(), S.sem) end
  end
  if S.aoTerminar then S.aoTerminar(scan, motivo) end
end

local function esperarPronto(S, fn)
  S.espera = fn
  local function tenta()
    if S.fim or S.espera ~= fn then return end
    if C_AuctionHouse.IsThrottledMessageSystemReady() then
      S.espera = nil
      fn()
    else
      C_Timer.After(0.3, tenta)
    end
  end
  tenta()
end

-- Ids da busca dirigida ------------------------------------------------------------------------------

local function idsDirigido()
  local modo = ns.modo and ns.modo() or nil
  if modo and modo.tipo == "rota" then
    local pl = ns.plano
    if not (type(pl) == "table" and pl.modo == 2 and type(pl.rota) == "table" and pl.rota.prof == modo.prof) then
      ns.replanejar()
      pl = ns.plano
    end
    local ids = {}
    local lista = type(pl) == "table" and type(pl.rota) == "table" and pl.rota.scan
    if type(lista) == "table" then
      for i = 1, #lista do ids[i] = lista[i] end
    end
    table.sort(ids)
    return ids
  end
  local dados = rawget(_G, "CompraForeverDados") or {}
  local receitas, itens, fabrica = dados.receitas or {}, dados.itens or {}, dados.fabrica or {}
  local conhecidas = ns.conhecidas()
  local set = {}
  for magia in pairs(conhecidas) do
    local r = receitas[magia]
    local prod = r and itens[r.produto]
    if r and prod and (prod.vende or 0) > 0 then
      for _, rg in ipairs(r.reagentes) do
        local it = itens[rg[1]]
        if not (it and it.vendedor) then set[rg[1]] = true end
      end
    end
  end
  for _, magia in pairs(fabrica) do
    local r = conhecidas[magia] and receitas[magia]
    if r then
      for _, rg in ipairs(r.reagentes) do set[rg[1]] = true end
    end
  end
  local ids = {}
  for id in pairs(set) do ids[#ids + 1] = id end
  table.sort(ids)
  return ids
end
ns.idsDirigido = idsDirigido

-- Busca dirigida -------------------------------------------------------------------------------------

local proximo

local function terminarId(S, cur, semResposta)
  if S.fim or S.atual ~= cur then return end
  S.atual = nil
  if semResposta then
    S.sem[#S.sem + 1] = cur.id
  elseif S.sonda then
    S.tempos[#S.tempos + 1] = { id = cur.id, seg = GetTime() - cur.t0, tipo = cur.tipo, n = #cur.escada }
  end
  S.escadas[cur.id] = ordenar(cur.escada)
  ns.scanEstado.feito = ns.scanEstado.feito + 1
  proximo(S)
end

-- le tudo o que o cliente tem para o id e decide: mais uma pagina ou terminar
local function lerResultado(S, cur, tipo, chave)
  cur.tipo = tipo
  local escada, soma = {}, 0
  local A = C_AuctionHouse
  if tipo == "commodity" then
    for i = 1, A.GetNumCommoditySearchResults(cur.id) do
      local r = A.GetCommoditySearchResultInfo(cur.id, i)
      if r then
        soma = soma + (r.quantity or 0)
        -- a linha junta vendedores no mesmo preco: compravel = total menos o que e do proprio dono (a conta da UI da
        -- Blizzard, Blizzard_AuctionHouseUtil.lua do espelho do Forever); a isca do dono nao some com a linha inteira
        local q = (r.quantity or 0) - (r.numOwnerItems or 0)
        if not r.numOwnerItems and r.containsOwnerItem then q = 0 end
        if (r.unitPrice or 0) > 0 and q > 0 then
          escada[#escada + 1] = { preco = r.unitPrice, qtd = q, leilao = r.auctionID, inteiro = false }
        end
      end
    end
  else
    for i = 1, A.GetNumItemSearchResults(chave) do
      local r = A.GetItemSearchResultInfo(chave, i)
      if r then
        local q = r.quantity or 1
        soma = soma + q
        if not r.containsOwnerItem and (r.buyoutAmount or 0) > 0 and q > 0 then
          escada[#escada + 1] = { preco = floor(r.buyoutAmount / q), qtd = q, leilao = r.auctionID, inteiro = true, total = r.buyoutAmount }
        end
      end
    end
  end
  cur.escada = escada
  local cheio
  if tipo == "commodity" then cheio = A.HasFullCommoditySearchResults(cur.id) else cheio = A.HasFullItemSearchResults(chave) end
  if not cheio and not S.umaPagina and soma < MAX_UNIDADES and cur.paginas < MAX_PAGINAS then
    cur.paginas = cur.paginas + 1
    esperarPronto(S, function()
      if S.fim or S.atual ~= cur then return end
      if tipo == "commodity" then A.RequestMoreCommoditySearchResults(cur.id) else A.RequestMoreItemSearchResults(chave) end
    end)
    return
  end
  terminarId(S, cur, false)
end

local function buscarId(S, id)
  local cur = { id = id, escada = {}, paginas = 0, t0 = GetTime() }
  S.atual = cur
  local ordem = Enum and Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Price or 0
  C_AuctionHouse.SendSearchQuery(C_AuctionHouse.MakeItemKey(id), { { sortOrder = ordem, reverseSort = false } }, false)
  C_Timer.After(S.umaPagina and TEMPO_CACA or TEMPO_ID, function() terminarId(S, cur, true) end)
end

proximo = function(S)
  if S.fim then return end
  local i = ns.scanEstado.feito + 1
  if i > #S.ids then
    if S.sonda then
      encerrar(S, nil, "probe")
    elseif S.tipo == "vigia" then
      -- busca da vigia: nao toca em ns.scan (so troca a escada de quem ja tinha) nem replaneja
      local sem = {}
      for _, sid in ipairs(S.sem) do sem[sid] = true end
      if ns.scan and ns.scan.escadas then
        for id, esc in pairs(S.escadas) do
          if ns.scan.escadas[id] and not sem[id] then ns.scan.escadas[id] = esc end
        end
      end
      S.fim = true
      ativo = nil
      ns.scanEstado = { ocupado = false, feito = ns.scanEstado.feito, total = ns.scanEstado.total }
      if S.aoTerminar then S.aoTerminar(S.escadas, S.sem) end
    elseif S.tipo == "refresh" and ns.scan and ns.scan.escadas then
      -- nova busca de poucos itens: troca so a escada deles no scan atual
      for id, esc in pairs(S.escadas) do ns.scan.escadas[id] = esc end
      ns.scan.atualizadoEm = time()
      encerrar(S, ns.scan)
    else
      encerrar(S, { tipo = S.tipo, em = time(), escadas = S.escadas, revenda = nil, semResposta = S.sem })
    end
    return
  end
  local id = S.ids[i]
  esperarPronto(S, function() buscarId(S, id) end)
end

-- o id pode ser commodity ou item: aceita o evento que vier para o id pedido
local function aoResultadoCommodity(id)
  local S = ativo
  local cur = S and S.atual
  if cur and cur.id == id then lerResultado(S, cur, "commodity", nil) end
end
local function aoResultadoItem(chave)
  local S = ativo
  local cur = S and S.atual
  if cur and type(chave) == "table" and cur.id == chave.itemID then lerResultado(S, cur, "item", chave) end
end
ns.ao("COMMODITY_SEARCH_RESULTS_UPDATED", aoResultadoCommodity)
ns.ao("COMMODITY_SEARCH_RESULTS_ADDED", aoResultadoCommodity)
ns.ao("ITEM_SEARCH_RESULTS_UPDATED", aoResultadoItem)
ns.ao("ITEM_SEARCH_RESULTS_ADDED", aoResultadoItem)

local function iniciarBusca(tipo, ids, aoTerminar, sonda, umaPagina)
  if ativo then return false, "busy" end
  if not leilaoAberto() then return false, "closed" end
  local S = abrirSessao(tipo, aoTerminar)
  S.ids, S.sonda, S.umaPagina = ids, sonda, umaPagina
  if sonda then S.tempos = {} end
  ns.scanEstado.total = #ids
  proximo(S)
  return true, S
end

-- busca de novo so estes ids (preco que mudou na hora da compra) e refaz o plano com o resto do scan intacto
function ns.atualizarItens(ids, aoTerminar)
  if type(ids) ~= "table" or #ids == 0 then return false, "nothing" end
  local ok, motivo = iniciarBusca(ns.scan and "refresh" or "dirigido", ids, aoTerminar, false)
  return ok, (not ok) and motivo or nil
end

-- busca da vigia de precos: mesma fila, mas no fim nao mexe em ns.scan nem replaneja; aoTerminar(escadas, semResposta)
function ns.buscarVigia(ids, aoTerminar)
  if type(ids) ~= "table" or #ids == 0 then return false, "nothing" end
  local ok, motivo = iniciarBusca("vigia", ids, aoTerminar, false)
  return ok, (not ok) and motivo or nil
end

-- busca da caca (secao 13): um id, so a primeira pagina (a ponta barata, ja ordenada por preco), mesmo fim da vigia
-- descarta a busca da caca em andamento (o dono apertou de novo com ela parada); outras buscas ficam
function ns.abortarBuscaCaca()
  if ativo and ativo.umaPagina then
    encerrar(ativo, nil, "aborted")
    return true
  end
  return false
end

function ns.buscarCaca(id, aoTerminar)
  if type(id) ~= "number" then return false, "nothing" end
  local ok, motivo = iniciarBusca("vigia", { id }, aoTerminar, false, true)
  return ok, (not ok) and motivo or nil
end

function ns.scanDirigido(aoTerminar)
  local ids = idsDirigido()
  if #ids == 0 then return false, "nothing" end
  local ok, motivo = iniciarBusca("dirigido", ids, aoTerminar, false)
  return ok, (not ok) and motivo or nil
end

-- Full scan ------------------------------------------------------------------------------------------

-- O livro do full scan fica no disco para a ferramenta de crafts (CONTRATO secao 11, pedido do dono em 2026-11-23):
-- CompraForeverDB.full = { em, n, itens = { [id] = "unidades;lotes;preco:qtd,preco:qtd,..." } }, com os NIVEIS
-- precos mais baratos de cada item (lotes do mesmo preco somados). So o ultimo full; o SavedVariables vai ao disco no
-- /reload ou ao sair do jogo.
local NIVEIS = 40

local function gravarFull(escadas, em)
  local itens, n = {}, 0
  for id, l in pairs(escadas) do
    local partes, unid, ultimo, k = {}, 0, nil, 0
    for _, e in ipairs(l) do
      unid = unid + e.qtd
      if ultimo and ultimo.preco == e.preco then
        ultimo.qtd = ultimo.qtd + e.qtd
      elseif k < NIVEIS then
        k = k + 1
        ultimo = { preco = e.preco, qtd = e.qtd }
        partes[k] = ultimo
      else
        ultimo = nil
      end
    end
    local txt = {}
    for i, p in ipairs(partes) do txt[i] = p.preco .. ":" .. p.qtd end
    itens[id] = unid .. ";" .. #l .. ";" .. table.concat(txt, ",")
    n = n + 1
  end
  CompraForeverDB.full = { em = em, n = n, itens = itens }
end

local function lerFull(S, n, total)
  local idx = 0
  local vistos = {}
  local quem = UnitName("player")
  local function quadro()
    if S.fim then return end
    local fim = min(idx + LOTE, n)
    for i = idx, fim - 1 do
      local _, _, qtd, _, _, _, _, _, _, buyout, _, _, _, dono, _, _, id = C_AuctionHouse.GetReplicateItemInfo(i)
      if id and qtd and qtd > 0 and buyout and buyout > 0 and dono ~= quem then
        local l = S.escadas[id]
        if not l then
          l = {}
          S.escadas[id] = l
        end
        l[#l + 1] = { preco = floor(buyout / qtd), qtd = qtd, inteiro = true }
        if not vistos[id] then
          vistos[id] = true
          local venda = select(11, C_Item.GetItemInfo(id))
          if venda and venda > 0 then S.revenda[id] = venda end
        end
      end
    end
    idx = fim
    ns.scanEstado.feito = idx
    if idx < n then
      C_Timer.After(0, quadro)
      return
    end
    for _, l in pairs(S.escadas) do ordenar(l) end
    local em = time()
    gravarFull(S.escadas, em)
    encerrar(S, { tipo = "full", em = em, escadas = S.escadas, revenda = S.revenda, semResposta = {} })
  end
  quadro()
end

function ns.fullScan(aoTerminar)
  if ativo then return false, "busy" end
  if not leilaoAberto() then return false, "closed" end
  local db = CompraForeverDB
  local resta = RECARGA - (time() - (db.ultimoFull or 0))
  if resta > 0 then return false, "cooldown", resta end
  local S = abrirSessao("full", aoTerminar)
  db.ultimoFull = time()   -- o servidor conta a recarga desde o pedido, mesmo se a AH fechar no meio
  C_AuctionHouse.ReplicateItems()
  local ultimo, iguais, decorrido = -1, 0, 0
  local function contar()
    if S.fim then return end
    decorrido = decorrido + 1
    local n = C_AuctionHouse.GetNumReplicateItems() or 0
    ns.scanEstado.total = n
    if n == ultimo then iguais = iguais + 1 else ultimo, iguais = n, 1 end
    if n > 0 and iguais >= 3 then
      lerFull(S, n)
    elseif decorrido >= FULL_MAX then
      if n > 0 then lerFull(S, n) else encerrar(S, nil, "timeout") end
    else
      C_Timer.After(1, contar)
    end
  end
  C_Timer.After(1, contar)
  return true
end

-- Fechar a AH aborta e mantem o scan anterior --------------------------------------------------------

ns.ao("AUCTION_HOUSE_SHOW", function() ahAberta = true end)
ns.ao("AUCTION_HOUSE_CLOSED", function()
  ahAberta = false
  if ativo then encerrar(ativo, nil, "closed") end
end)

-- /compra sonda (secao 8) ----------------------------------------------------------------------------

function ns.sonda()
  local function dizer(t) print("CompraForever probe: " .. t) end
  local nomes = { [4234] = "Heavy Leather", [4461] = "Raptor Hide", [2321] = "Fine Thread" }
  for _, id in ipairs({ 4234, 4461, 2321 }) do
    local info = C_AuctionHouse.GetItemKeyInfo and C_AuctionHouse.GetItemKeyInfo(C_AuctionHouse.MakeItemKey(id))
    dizer(nomes[id] .. " (" .. id .. ") isCommodity=" .. (info and tostring(info.isCommodity) or "no data"))
  end
  dizer("throttle ready=" .. tostring(C_AuctionHouse.IsThrottledMessageSystemReady()))
  local ids = {}
  local usados = {}
  for _, id in ipairs(idsDirigido()) do
    if #ids < 5 then ids[#ids + 1] = id; usados[id] = true end
  end
  for _, id in ipairs(IDS_SONDA) do
    if #ids < 5 and not usados[id] then ids[#ids + 1] = id; usados[id] = true end
  end
  local sessao
  local ok, r = iniciarBusca("dirigido", ids, function(_, m)
    for _, t in ipairs(sessao and sessao.tempos or {}) do
      dizer(string.format("id %d %s %d tiers in %.2f s", t.id, t.tipo or "?", t.n, t.seg))
    end
    dizer("done" .. (m == "closed" and " (AH closed)" or ""))
  end, true)
  if not ok then dizer("not started: " .. tostring(r)) return end
  sessao = r
end

-- /compra sonda prof (secao 12.8): o que as APIs de profissao devolvem no Forever. So leitura; tudo em pcall, com a
-- existencia conferida por rawget (a bancada da erro em global que nao existe). Grava em CompraForeverDB.sonda.

local LINHAS_PROF = { { 171, "Alchemy" }, { 164, "Blacksmithing" }, { 333, "Enchanting" }, { 202, "Engineering" },
  { 165, "Leatherworking" }, { 197, "Tailoring" } }
local CAMPOS_INFO = { "professionID", "professionName", "skillLevel", "maxSkillLevel", "skillModifier",
  "parentProfessionID", "parentProfessionName" }
local EXISTE = { "C_TradeSkillUI.CraftEnchant", "C_TradeSkillUI.StopRecipeRepeat", "C_TradeSkillUI.GetRemainingRecasts",
  "C_TradeSkillUI.IsNearProfessionSpellFocus", "C_TradeSkillUI.GetRecipeRequirements", "C_TradeSkillUI.GetCraftableCount",
  "C_TradeSkillUI.GetProfessionInfoBySkillLineID", "GetProfessions", "GetProfessionInfo", "GetInboxNumItems", "GetInboxItem" }

-- "GetProfessions" ou "C_TradeSkillUI.CraftEnchant" -> a funcao, ou nil
local function achar(nome)
  local tab, fn = string.match(nome, "^([%w_]+)%.([%w_]+)$")
  if tab then
    local t = rawget(_G, tab)
    local f = type(t) == "table" and rawget(t, fn) or nil
    return type(f) == "function" and f or nil
  end
  local f = rawget(_G, nome)
  return type(f) == "function" and f or nil
end

local function campos(t, nomes)
  if type(t) ~= "table" then return tostring(t) end
  local p = {}
  for _, k in ipairs(nomes) do
    if t[k] ~= nil then p[#p + 1] = k .. "=" .. tostring(t[k]) end
  end
  return #p > 0 and table.concat(p, " ") or "empty table"
end

function ns.sondaProf()
  local linhas = {}
  local function dizer(t)
    linhas[#linhas + 1] = t
    print("CompraForever probe: " .. t)
  end
  -- chama sem repetir erro na tela (para lacos); devolve a lista { ok, r1, r2, ... } ou nil
  local function quieto(nome, ...)
    local f = achar(nome)
    if not f then return nil end
    local r = { pcall(f, ...) }
    if not r[1] then return nil end
    return r
  end
  local function chamar(nome, ...)
    local f = achar(nome)
    if not f then dizer(nome .. ": missing") return nil end
    local r = { pcall(f, ...) }
    if not r[1] then dizer(nome .. ": error " .. tostring(r[2])) return nil end
    return r
  end

  local nv = chamar("UnitLevel", "player")
  if nv then dizer("level " .. tostring(nv[2])) end

  local P = chamar("GetProfessions")
  if P then
    local idx = {}
    for i = 2, 6 do idx[#idx + 1] = tostring(P[i]) end
    dizer("GetProfessions " .. table.concat(idx, ","))
    for i = 2, 6 do
      local k = P[i]
      if type(k) == "number" then
        local I = chamar("GetProfessionInfo", k)
        if I then
          dizer("GetProfessionInfo(" .. k .. ") name=" .. tostring(I[2]) .. " skill=" .. tostring(I[4]) ..
            " max=" .. tostring(I[5]) .. " line=" .. tostring(I[8]) .. " mod=" .. tostring(I[9]))
        end
      end
    end
  end

  for _, x in ipairs(LINHAS_PROF) do
    local R = chamar("C_TradeSkillUI.GetProfessionInfoBySkillLineID", x[1])
    if R then dizer("BySkillLine " .. x[1] .. " " .. campos(R[2], CAMPOS_INFO)) end
  end

  local N = quieto("C_SkillInfo.GetNumSkillLines")
  dizer("C_SkillInfo.GetNumSkillLines " .. (N and tostring(N[2]) or "missing or error"))
  if achar("C_SkillInfo.GetSkillLineInfoByID") then
    for _, x in ipairs(LINHAS_PROF) do
      local R = quieto("C_SkillInfo.GetSkillLineInfoByID", x[1])
      if R then
        local v = R[2]
        dizer("SkillLineInfoByID " .. x[1] .. " " .. (type(v) == "table" and campos(v, { "name", "skillLineRank",
          "skillLineMaxRank", "rank", "maxRank", "skillLineDisplayName" }) or (tostring(v) .. " " .. tostring(R[3]) .. " " .. tostring(R[4]))))
      end
    end
  end

  local pronta = quieto("C_TradeSkillUI.IsTradeSkillReady")
  if pronta and pronta[2] then
    local B1 = chamar("C_TradeSkillUI.GetBaseProfessionInfo")
    if B1 then dizer("Base " .. campos(B1[2], CAMPOS_INFO)) end
    local C1 = chamar("C_TradeSkillUI.GetChildProfessionInfo")
    if C1 then dizer("Child " .. campos(C1[2], CAMPOS_INFO)) end
    local ids = chamar("C_TradeSkillUI.GetAllRecipeIDs")
    local lista = ids and type(ids[2]) == "table" and ids[2] or {}
    local aprendidas, primeira = 0, nil
    for _, id in ipairs(lista) do
      local G = quieto("C_TradeSkillUI.GetRecipeInfo", id)
      if G and type(G[2]) == "table" and G[2].learned then
        aprendidas = aprendidas + 1
        primeira = primeira or id
      end
    end
    dizer("recipes " .. #lista .. " learned " .. aprendidas)
    if primeira then
      local G = quieto("C_TradeSkillUI.GetRecipeInfo", primeira)
      dizer("recipe " .. primeira .. " " .. campos(G and G[2], { "name", "learned", "relativeDifficulty", "numSkillUps",
        "craftable", "disabled" }))
      local Q = chamar("C_TradeSkillUI.GetCraftableCount", primeira)
      if Q then dizer("GetCraftableCount " .. tostring(Q[2])) end
      local Rq = chamar("C_TradeSkillUI.GetRecipeRequirements", primeira)
      if Rq then
        local p = {}
        for _, q in ipairs(type(Rq[2]) == "table" and Rq[2] or {}) do
          p[#p + 1] = tostring(type(q) == "table" and q.name) .. ":" .. tostring(type(q) == "table" and q.met)
        end
        dizer("GetRecipeRequirements " .. (#p > 0 and table.concat(p, ", ") or "none"))
      end
    end
  else
    dizer("profession window closed: open it and run /compra sonda prof again")
  end

  local tem = {}
  for _, nome in ipairs(EXISTE) do
    tem[#tem + 1] = string.gsub(nome, "^C_TradeSkillUI%.", "TS.") .. "=" .. (achar(nome) and "yes" or "no")
  end
  dizer(table.concat(tem, " "))

  if type(CompraForeverDB) == "table" then
    CompraForeverDB.sonda = { em = time(), linhas = linhas }
    print("CompraForever probe: saved (/reload writes it to disk)")
  end
end
