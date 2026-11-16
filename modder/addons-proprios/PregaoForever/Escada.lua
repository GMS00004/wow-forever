-- Escada.lua (PregaoForever): transforma a resposta de uma busca do leilao em foto (secao 5.3). Commodity: ate 12 degraus sem as unidades proprias, cauda em 8 baldes ou T. Item: os 30 leiloes mais baratos, resto agregado, donos distintos e o booleano nomesVieram, sem nome. Grava pelo ns.banco e atualiza dias e blocos da memoria. Publica ns.escada. Onda 2.
-- Contrato: ARQUITETURA.md, secoes 3.6 e 4. So le a resposta da busca que a Varredura pediu; nenhuma consulta aqui (regra 9).
local _, ns = ...
ns.escada = ns.escada or {}
local E = ns.escada

local ultimas = {}     -- chave -> ultima foto gravada nesta sessao (E.ultima)
local BLOCO_S = 14400  -- blocos de 4 horas (secao 6)

local function cfgFotos(nome, padrao)
  local f = ns.cfg and ns.cfg.fotos
  return (f and f[nome]) or padrao
end

-- ---------- commodity ----------
-- Oito baldes da cauda, com limites em multiplos do preco do 12o degrau (secao 5.3); o oitavo e o resto.
local function baldes(resto, p12)
  local lim = {
    math.floor(p12 * 105 / 100), math.floor(p12 * 110 / 100), math.floor(p12 * 120 / 100), math.floor(p12 * 135 / 100),
    math.floor(p12 * 150 / 100), math.floor(p12 * 200 / 100), math.floor(p12 * 300 / 100),
  }
  local out = { 0, 0, 0, 0, 0, 0, 0, 0 }
  for i = 1, #resto do
    local d = resto[i]
    local k = 8
    for j = 1, 7 do
      if d.preco <= lim[j] then
        k = j
        break
      end
    end
    out[k] = out[k] + d.qtd
  end
  return out
end

local function fotoC(itemID)
  local chave = ns.itens.chave({ itemID = itemID, itemLevel = 0, itemSuffix = 0 }, true)
  local API = C_AuctionHouse
  local escada = API.HasFullCommoditySearchResults(itemID) and true or false
  local n = API.GetNumCommoditySearchResults(itemID) or 0

  -- linhas da resposta, na ordem em que chegaram (a frente e a ordem crescente de preco, H-28)
  local linhas = {}
  local ordem = true
  local ultimoPreco = nil
  for i = 1, n do
    local r = API.GetCommoditySearchResultInfo(itemID, i)
    if r then
      linhas[#linhas + 1] = r
      if ultimoPreco and r.unitPrice < ultimoPreco then ordem = false end
      ultimoPreco = r.unitPrice
    end
  end

  -- vazia suspeita: zero linhas onde a foto anterior tinha oferta (secao 5.3); descartada
  local anterior = E.ultima(chave)
  if #linhas == 0 and anterior and (anterior.qtot or 0) > 0 then
    return nil, 'vazia suspeita'
  end

  -- agrega por preco, sem as unidades proprias (numOwnerItems)
  local porPreco, precos = {}, {}
  local proprio = false
  local propriasTotal = 0
  for _, r in ipairs(linhas) do
    local p = r.unitPrice
    local g = porPreco[p]
    if not g then
      g = { preco = p, qtd = 0, donos = 0, proprias = 0, conta = 0 }
      porPreco[p] = g
      precos[#precos + 1] = p
    end
    local propria = r.numOwnerItems or 0
    if propria > 0 or r.containsOwnerItem then proprio = true end
    g.qtd = g.qtd + (r.quantity or 0) - propria
    g.proprias = g.proprias + propria
    if (r.totalNumberOfOwners or 0) > g.donos then g.donos = r.totalNumberOfOwners end
    if r.containsAccountItem then g.conta = 1 end
    propriasTotal = propriasTotal + propria
  end
  table.sort(precos)

  local todos = {}
  for _, p in ipairs(precos) do
    local g = porPreco[p]
    if g.qtd < 0 then g.qtd = 0 end
    if g.qtd > 0 then todos[#todos + 1] = g end
  end

  local lim = cfgFotos('degraus_guardados', 12)
  local degraus = {}
  for i = 1, math.min(lim, #todos) do
    local g = todos[i]
    degraus[i] = { preco = g.preco, qtd = g.qtd, donos = g.donos, proprias = g.proprias, conta = g.conta }
  end

  local soma = 0
  for _, g in ipairs(todos) do soma = soma + g.qtd end

  local cauda = 'T'
  local qtot
  if escada then
    local resto = {}
    for i = lim + 1, #todos do resto[#resto + 1] = todos[i] end
    local p12 = degraus[#degraus] and degraus[#degraus].preco or 0
    cauda = baldes(resto, p12)
    qtot = soma
  else
    qtot = (API.GetCommoditySearchResultsQuantity(itemID) or 0) - propriasTotal
    if qtot < 0 then qtot = 0 end
  end

  local marcas = (ordem and 'F' or '') .. (escada and 'E' or '')
  return {
    tipo = 'c', chave = chave, t = ns.servidor(), marcas = marcas, qtot = qtot,
    degraus = degraus, cauda = cauda,
    frente = ordem, escada = escada, comProprio = proprio,
  }
end

-- ---------- item ----------
local function fotoI(itemKey)
  local chave = ns.itens.chave(itemKey, false)
  local API = C_AuctionHouse
  local escada = API.HasFullItemSearchResults(itemKey) and true or false
  local n = API.GetNumItemSearchResults(itemKey) or 0

  local linhas = {}
  local ordem = true
  local ultimo = nil
  for i = 1, n do
    local r = API.GetItemSearchResultInfo(itemKey, i)
    if r then
      linhas[#linhas + 1] = r
      if r.buyoutAmount and r.buyoutAmount > 0 then
        if ultimo and r.buyoutAmount < ultimo then ordem = false end
        ultimo = r.buyoutAmount
      end
    end
  end

  -- vazia suspeita: zero linhas onde a foto anterior tinha oferta; descartada
  local anterior = E.ultima(chave)
  if #linhas == 0 and anterior and ((anterior.leiloes and #anterior.leiloes > 0) or (anterior.resto and anterior.resto.contagem > 0)) then
    return nil, 'vazia suspeita'
  end

  -- donos: nomes so entram numa tabela local, para contar distintos; nunca saem daqui (regra 20)
  local nomesLocais = {}
  local contagemNomes = 0
  local nomesVieram = false
  local maxDonos = 0
  local proprio = false
  local comArremate = {}
  for _, r in ipairs(linhas) do
    local lista = r.owners
    if type(lista) == 'table' and #lista > 0 then
      nomesVieram = true
      for j = 1, #lista do
        local nome = lista[j]
        if nomesLocais[nome] == nil then
          nomesLocais[nome] = true
          contagemNomes = contagemNomes + 1
        end
      end
    end
    if (r.totalNumberOfOwners or 0) > maxDonos then maxDonos = r.totalNumberOfOwners end
    if r.containsOwnerItem or (r.numOwnerItems or 0) > 0 then proprio = true end
    -- leilao so de lance fica fora da frente e da contagem
    if r.buyoutAmount and r.buyoutAmount > 0 then comArremate[#comArremate + 1] = r end
  end
  local donos = nomesVieram and contagemNomes or maxDonos

  table.sort(comArremate, function(a, b)
    if a.buyoutAmount ~= b.buyoutAmount then return a.buyoutAmount < b.buyoutAmount end
    return (a.auctionID or 0) < (b.auctionID or 0)
  end)

  local lim = cfgFotos('leiloes_por_foto', 30)
  local leiloes = {}
  local restoN, restoSoma = 0, 0
  for i = 1, #comArremate do
    local r = comArremate[i]
    if i <= lim then
      leiloes[#leiloes + 1] = {
        id = r.auctionID, arremate = r.buyoutAmount, lance = r.bidAmount or 0, faixa = r.timeLeft or 0,
        qtd = r.quantity or 1, dono = r.containsOwnerItem and 1 or 0, conta = r.containsAccountItem and 1 or 0,
      }
    else
      restoN = restoN + 1
      restoSoma = restoSoma + (r.quantity or 1)
    end
  end

  local marcas = (ordem and 'F' or '') .. (escada and 'E' or '')
  return {
    tipo = 'i', chave = chave, t = ns.servidor(), marcas = marcas,
    donos = donos, nomesVieram = nomesVieram and 1 or 0,
    leiloes = leiloes, resto = { contagem = restoN, soma = restoSoma },
    frente = ordem, escada = escada, comProprio = proprio,
  }
end

-- ---------- API publica ----------
-- fotoC(itemID) e fotoI(itemKey): a foto, ou nil e o motivo (vazia suspeita). Nao grava.
function E.fotoC(itemID) return fotoC(itemID) end
function E.fotoI(itemKey) return fotoI(itemKey) end

-- ultima(chave): a foto mais nova desta sessao e a idade em segundos
function E.ultima(chave)
  local f = ultimas[chave]
  if not f then return nil end
  return f, ns.servidor() - f.t
end

-- dias e blocos: so com a frente marcada e sem unidade propria na leitura (secao 5.3)
local function atualizarMemoria(chave, foto)
  local b = ns.banco
  local m = (b and b.memoria and b.memoria()) or nil
  if not m or not m.dias or not m.blocos then return end
  local minimo, qtd
  if foto.tipo == 'i' then
    qtd = foto.resto.soma
    for i = 1, #foto.leiloes do qtd = qtd + foto.leiloes[i].qtd end
    if foto.leiloes[1] then minimo = foto.leiloes[1].arremate end
  else
    qtd = foto.qtot
    if foto.degraus[1] then minimo = foto.degraus[1].preco end
  end
  if minimo == nil then return end
  local dia = ns.diaMercado(foto.t)
  local bloco = math.floor(foto.t / BLOCO_S)
  local md = m.dias[chave] or {}
  m.dias[chave] = md
  local novoMin = minimo
  if md[dia] and md[dia].min < minimo then novoMin = md[dia].min end
  md[dia] = { min = novoMin, qtd = qtd }
  local mb = m.blocos[chave] or {}
  m.blocos[chave] = mb
  mb[bloco] = { min = minimo, qtd = qtd }
end

-- gravar(chave, foto): grava a linha pelo banco no anel fotos:<chave>. Sem foto (vazia suspeita) nao grava.
function E.gravar(chave, foto)
  if not foto then return false, 'sem foto' end
  local b = ns.banco
  if not b or not b.gravar or not b.seq or not b.cod then return false, 'banco nao carregou' end
  chave = tostring(chave)
  foto.seq = b.seq()
  local linha
  if foto.tipo == 'i' then linha = b.cod.fotoI(foto) else linha = b.cod.fotoC(foto) end
  b.gravar('fotos:' .. chave, linha)
  ultimas[chave] = foto
  if foto.frente and not foto.comProprio then atualizarMemoria(chave, foto) end
  return true
end
