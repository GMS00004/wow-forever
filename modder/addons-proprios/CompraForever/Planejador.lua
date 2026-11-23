local addon, ns = ...

-- Planejador: funcao pura ns.planejar(entrada) -> plano (CONTRATO secao 4). Nao chama API do WoW.
-- Decisoes:
-- * Degrau inteiro: o lote todo sai do dinheiro ao abrir; as unidades que sobram servem de graca aos crafts
--   seguintes (custo de decisao = preco do degrau) e, se ninguem usar, vao para `sobra`.
-- * Estoque: nao gasta dinheiro; entra no custo do craft pelo degrau mais barato da escada (ou vendedor com
--   desconto, o menor) e e descontado em totais.lucro.
-- * Fabricar: um nivel, so de magia conhecida; sobra de uma magia fica como saldo gratis para os crafts seguintes.
-- * Revenda: pseudo-receita com chave "r"..id, depois das magias no desempate; compra so do leilao. A compra
--   tambem entra em `leilao` (lista de compras completa); `revenda` informa o que foi revendido.
-- * motivo: "dinheiro" se alguma receita passou em lucro e margem e falhou no dinheiro; senao "espaco" se
--   falhou so nas bolsas; "limite" ao chegar a 5000 crafts; "lucro" no resto.
-- * Tudo em cobre inteiro (math.floor); iteracao sempre sobre listas ordenadas (deterministico).

local floor, ceil, max = math.floor, math.ceil, math.max
local sort = table.sort

local LIMITE = 5000
local VAZIO = {}
local CAMPOS = { "pos", "resto", "saldo", "sp", "fs", "fsp", "est", "casts", "qL", "cL", "qV", "cV", "valE", "pm" }
local NCAMPOS = #CAMPOS

local function chavesOrdenadas(t)
  local l = {}
  if t then
    for k in pairs(t) do
      if type(k) == "number" then l[#l + 1] = k end
    end
  end
  sort(l)
  return l
end

function ns.planejar(entrada)
  local dados = entrada.dados or VAZIO
  local receitas = dados.receitas or VAZIO
  local itens = dados.itens or VAZIO
  local fabrica = dados.fabrica or VAZIO
  local conhecidas = entrada.conhecidas or VAZIO
  local estoque = entrada.estoque or VAZIO
  local desconto = entrada.desconto or 0
  local lucroMin = entrada.lucroMin or 0
  local margemMin = entrada.margemMin or 0
  local dinheiro = max(entrada.dinheiro or 0, 0)
  local espacos = entrada.espacos or 0
  local revenda = entrada.revenda

  -- escadas limpas (degraus sem quantidade saem)
  local esc = {}
  for id, lista in pairs(entrada.escadas or VAZIO) do
    local l = {}
    for i = 1, #lista do
      local d = lista[i]
      if d.preco and d.qtd and d.qtd > 0 then l[#l + 1] = d end
    end
    esc[id] = l
  end

  local function nomeItem(id)
    local it = itens[id]
    return (it and it.nome) or tostring(id)
  end
  local function pilhaDe(id)
    local it = itens[id]
    local p = it and it.pilha
    if not p or p < 1 then return 1 end
    return p
  end

  local vendC = {}
  local function vendPreco(id)
    local v = vendC[id]
    if v == nil then
      v = false
      local it = itens[id]
      if it and it.vendedor and it.vendedor > 0 then
        v = floor(it.vendedor * (100 - desconto) / 100)
      end
      vendC[id] = v
    end
    return v or nil
  end

  local estRefC = {}
  local function estRef(id)
    local v = estRefC[id]
    if v == nil then
      local l = esc[id]
      if l then
        for i = 1, #l do
          if v == nil or l[i].preco < v then v = l[i].preco end
        end
      end
      local vp = vendPreco(id)
      if vp and (v == nil or vp < v) then v = vp end
      v = v or 0
      estRefC[id] = v
    end
    return v
  end

  local fabC = {}
  local function fabDe(id)
    local f = fabC[id]
    if f == nil then
      f = false
      local m = fabrica[id]
      local r = m and conhecidas[m] and receitas[m]
      if r and r.produto == id and r.reagentes then f = r end
      fabC[id] = f
    end
    return f or nil
  end

  -- estado base (cumulativo) por item
  local base = {}
  local function baseDe(id)
    local b = base[id]
    if not b then
      b = { pos = 1, saldo = 0, sp = 0, fs = 0, fsp = 0, est = 0, casts = 0, qL = 0, cL = 0, qV = 0, cV = 0,
            valE = 0, pm = 0, lotes = {} }
      base[id] = b
    end
    return b
  end

  -- registro do item numa simulacao (copia do pai ou da base)
  local function rec(ov, pai, id)
    local r = ov[id]
    if r then return r end
    local s = (pai and pai[id]) or baseDe(id)
    r = { pos = s.pos, resto = s.resto, saldo = s.saldo, sp = s.sp, fs = s.fs, fsp = s.fsp, est = s.est,
          casts = s.casts, qL = s.qL, cL = s.cL, qV = s.qV, cV = s.cV, valE = s.valE, pm = s.pm }
    local snl = s.nl
    if snl then
      local nl = {}
      for i = 1, #snl do nl[i] = snl[i] end
      r.nl = nl
    end
    ov[id] = r
    return r
  end

  -- toma `need` unidades do item; devolve custo, dinheiro novo, ok
  local tomar
  tomar = function(ov, pai, id, need, soL, semFab)
    local custo, din = 0, 0
    if need <= 0 then return 0, 0, true end
    local o = rec(ov, pai, id)
    local l = esc[id] or VAZIO
    local est, vend, fm = 0, nil, nil
    if not soL then
      est = estoque[id] or 0
      vend = vendPreco(id)
      if not semFab then fm = fabDe(id) end
    end
    while need > 0 do
      local bc, bs
      if est - o.est > 0 then bc = estRef(id); bs = 1 end
      if o.saldo > 0 and (bc == nil or o.sp < bc) then bc = o.sp; bs = 2 end
      if o.fs > 0 and (bc == nil or o.fsp < bc) then bc = o.fsp; bs = 3 end
      local step = l[o.pos]
      if step and (bc == nil or step.preco < bc) then bc = step.preco; bs = 4 end
      if vend and (bc == nil or vend < bc) then bc = vend; bs = 5 end
      if fm and o.fs == 0 then
        local tmp = {}
        local cc, dd, ok = 0, 0, true
        local rg = fm.reagentes
        for i = 1, #rg do
          local c1, d1, ok1 = tomar(tmp, ov, rg[i][1], rg[i][2], false, true)
          if not ok1 then ok = false; break end
          cc = cc + c1
          dd = dd + d1
        end
        if ok then
          local q = fm.qtd or 1
          if q < 1 then q = 1 end
          local uc = floor(cc / q)
          if bc == nil or uc < bc then
            for k, v in pairs(tmp) do ov[k] = v end
            o.casts = o.casts + 1
            o.fs = q
            o.fsp = uc
            din = din + dd
            bc = uc
            bs = 3
          end
        end
      end
      if not bs then return custo, din, false end
      local k = 0
      if bs == 1 then
        k = est - o.est
        if k > need then k = need end
        o.est = o.est + k
        o.valE = o.valE + k * bc
        custo = custo + k * bc
      elseif bs == 2 then
        k = o.saldo
        if k > need then k = need end
        o.saldo = o.saldo - k
        custo = custo + k * bc
      elseif bs == 3 then
        k = o.fs
        if k > need then k = need end
        o.fs = o.fs - k
        custo = custo + k * bc
      elseif bs == 4 then
        local p = step.preco
        if o.pm < p then o.pm = p end
        local lote = o.nl
        if not lote then lote = {}; o.nl = lote end
        if step.inteiro then
          local n = step.qtd
          din = din + p * n
          o.qL = o.qL + n
          o.cL = o.cL + p * n
          o.saldo = o.saldo + n
          o.sp = p
          lote[#lote + 1] = { leilao = step.leilao, qtd = n, preco = p, i = o.pos, int = true }
          o.pos = o.pos + 1
          o.resto = nil
        else
          local disp = o.resto or step.qtd
          k = disp
          if k > need then k = need end
          din = din + p * k
          custo = custo + p * k
          o.qL = o.qL + k
          o.cL = o.cL + p * k
          lote[#lote + 1] = { leilao = step.leilao, qtd = k, preco = p, i = o.pos, int = false }
          if k == disp then
            o.pos = o.pos + 1
            o.resto = nil
          else
            o.resto = disp - k
          end
        end
      else
        k = need
        o.qV = o.qV + k
        o.cV = o.cV + k * bc
        din = din + k * bc
        custo = custo + k * bc
      end
      need = need - k
    end
    return custo, din, true
  end

  -- lista de receitas: magias em ordem, depois revenda por id
  local R = {}
  local magias = chavesOrdenadas(conhecidas)
  for i = 1, #magias do
    local m = magias[i]
    local r = conhecidas[m] and receitas[m]
    local it = r and itens[r.produto]
    if r and r.reagentes and it and it.vende and it.vende > 0 then
      local pq = r.qtd or 1
      R[#R + 1] = { magia = m, nome = r.nome or tostring(m), reagentes = r.reagentes, produto = r.produto,
                    pq = pq, venda = it.vende * pq, soL = false }
    end
  end
  if revenda then
    local ids = chavesOrdenadas(esc)
    for i = 1, #ids do
      local id = ids[i]
      local v = revenda[id]
      if v and v > 0 and #esc[id] > 0 then
        R[#R + 1] = { rev = id, nome = nomeItem(id), reagentes = { { id, 1 } }, produto = id, pq = 1,
                      venda = v, soL = true }
      end
    end
  end
  local nR = #R

  -- dependencias: item -> receitas que podem mexer nele
  local dep = {}
  for ri = 1, nR do
    local visto = {}
    local function add(id)
      if not visto[id] then
        visto[id] = true
        local d = dep[id]
        if not d then d = {}; dep[id] = d end
        d[#d + 1] = ri
      end
    end
    local rg = R[ri].reagentes
    for i = 1, #rg do
      add(rg[i][1])
      if not R[ri].soL then
        local f = fabDe(rg[i][1])
        if f then
          for j = 1, #f.reagentes do add(f.reagentes[j][1]) end
        end
      end
    end
  end

  local function simular(r)
    local ov = {}
    local custo, din = 0, 0
    local rg = r.reagentes
    for i = 1, #rg do
      local c, d, ok = tomar(ov, nil, rg[i][1], rg[i][2], r.soL, false)
      if not ok then return false end
      custo = custo + c
      din = din + d
    end
    local lucro = r.venda - custo
    local dI = 0
    for id, o in pairs(ov) do
      local b = baseDe(id)
      local p = pilhaDe(id)
      dI = dI + ceil((o.qL + o.qV) / p) - ceil((b.qL + b.qV) / p)
    end
    return { ov = ov, custo = custo, din = din, venda = r.venda, lucro = lucro, dI = dI,
             pass = lucro >= lucroMin and lucro * 100 >= margemMin * custo }
  end

  local cache = {}
  local agg = {}
  local pu = {}
  local rv = {}
  local gasto, espTot, nCrafts = 0, 0, 0
  local motivo = "lucro"

  -- Guloso preguicoso: lb[ri] e um limite superior do lucro do proximo craft (lucro so cai e pass = false e
  -- definitivo, pois as fontes so se esgotam e o custo so sobe). Resultado sujo e refeito so quando o maior
  -- limite aponta para ele; empate no limite resolve pelo menor indice (menor magia).
  local NEG = -math.huge
  local lb = {}
  for ri = 1, nR do lb[ri] = math.huge end
  local melhor, melhorRi

  while true do
    if nCrafts >= LIMITE then motivo = "limite"; break end
    local restante = dinheiro - gasto
    melhor, melhorRi = nil, nil
    local falhaDin, falhaEsp = false, false
    local excl, nex = {}, 0
    while true do
      local bi, bv = nil, NEG
      for ri = 1, nR do
        local v = lb[ri]
        if v > bv then bv = v; bi = ri end
      end
      if not bi then break end
      local res = cache[bi]
      if res == nil or res.sujo then
        res = simular(R[bi])
        cache[bi] = res
        if res and res.pass then lb[bi] = res.lucro else lb[bi] = NEG end
      else
        local r = R[bi]
        local p = pilhaDe(r.produto)
        local u = pu[r.produto] or 0
        local dP = ceil((u + r.pq) / p) - ceil(u / p)
        if res.din > restante then
          falhaDin = true
        elseif espTot + res.dI + dP > espacos then
          falhaEsp = true
        else
          melhor = res
          melhorRi = bi
          break
        end
        excl[nex + 1] = bi
        excl[nex + 2] = lb[bi]
        nex = nex + 2
        lb[bi] = NEG
      end
    end
    for i = 1, nex, 2 do lb[excl[i]] = excl[i + 1] end
    if not melhor then
      if falhaDin then motivo = "dinheiro"
      elseif falhaEsp then motivo = "espaco" end
      break
    end

    -- efetiva
    local r = R[melhorRi]
    local res = melhor
    for id, o in pairs(res.ov) do
      local b = baseDe(id)
      for i = 1, NCAMPOS do
        local k = CAMPOS[i]
        b[k] = o[k]
      end
      local L = b.lotes
      local nl = o.nl or VAZIO
      for i = 1, #nl do
        local e = nl[i]
        local last = L[#L]
        if last and not e.int and not last.int and last.i == e.i then
          last.qtd = last.qtd + e.qtd
        else
          L[#L + 1] = { leilao = e.leilao, qtd = e.qtd, preco = e.preco, i = e.i, int = e.int }
        end
      end
      local d = dep[id]
      if d then
        for i = 1, #d do
          local c = cache[d[i]]
          if c and c.pass then c.sujo = true end
        end
      end
    end
    res.sujo = true
    lb[melhorRi] = res.lucro
    local p = pilhaDe(r.produto)
    local u = pu[r.produto] or 0
    espTot = espTot + res.dI + (ceil((u + r.pq) / p) - ceil(u / p))
    pu[r.produto] = u + r.pq
    gasto = gasto + res.din
    nCrafts = nCrafts + 1
    local a
    if r.rev then
      a = rv[r.rev]
      if not a then a = { n = 0, custo = 0, venda = 0, pm = 0 }; rv[r.rev] = a end
      if res.custo > a.pm then a.pm = res.custo end
    else
      a = agg[melhorRi]
      if not a then a = { n = 0, custo = 0, venda = 0 }; agg[melhorRi] = a end
    end
    a.n = a.n + 1
    a.custo = a.custo + res.custo
    a.venda = a.venda + res.venda
  end

  -- saida
  local plano = { crafts = {}, fabricar = {}, leilao = {}, vendedor = {}, doEstoque = {}, revenda = {},
                  sobra = {}, totais = {}, motivo = motivo }
  local vendaTot, valorEstoque = 0, 0

  for ri = 1, nR do
    local a = agg[ri]
    if a then
      local r = R[ri]
      plano.crafts[#plano.crafts + 1] = { magia = r.magia, nome = r.nome, n = a.n, custo = a.custo,
                                          venda = a.venda, lucro = a.venda - a.custo }
      vendaTot = vendaTot + a.venda
    end
  end
  sort(plano.crafts, function(x, y)
    if x.lucro ~= y.lucro then return x.lucro > y.lucro end
    return x.magia < y.magia
  end)

  local ids = chavesOrdenadas(base)
  for i = 1, #ids do
    local id = ids[i]
    local b = base[id]
    if b.casts > 0 then
      local m = fabrica[id]
      plano.fabricar[#plano.fabricar + 1] = { magia = m, nome = (receitas[m] and receitas[m].nome) or tostring(m),
                                              n = b.casts }
    end
    if b.qL > 0 then
      local lotes, inteiro = {}, false
      for j = 1, #b.lotes do
        local e = b.lotes[j]
        lotes[j] = { leilao = e.leilao, qtd = e.qtd, preco = e.preco }
        if e.int then inteiro = true end
      end
      plano.leilao[#plano.leilao + 1] = { id = id, nome = nomeItem(id), qtd = b.qL, precoMax = b.pm,
                                          custo = b.cL, inteiro = inteiro, lotes = lotes }
    end
    if b.qV > 0 then
      plano.vendedor[#plano.vendedor + 1] = { id = id, nome = nomeItem(id), qtd = b.qV, custo = b.cV }
    end
    if b.est > 0 then
      plano.doEstoque[#plano.doEstoque + 1] = { id = id, nome = nomeItem(id), qtd = b.est }
      valorEstoque = valorEstoque + b.valE
    end
    if b.saldo > 0 then
      plano.sobra[#plano.sobra + 1] = { id = id, nome = nomeItem(id), qtd = b.saldo }
    end
  end
  sort(plano.fabricar, function(x, y) return x.magia < y.magia end)

  local rids = chavesOrdenadas(rv)
  for i = 1, #rids do
    local id = rids[i]
    local a = rv[id]
    plano.revenda[#plano.revenda + 1] = { id = id, nome = nomeItem(id), qtd = a.n, precoMax = a.pm,
                                          custo = a.custo, venda = a.venda, lucro = a.venda - a.custo }
    vendaTot = vendaTot + a.venda
  end

  plano.totais = { gasto = gasto, venda = vendaTot, lucro = vendaTot - gasto - valorEstoque, espacos = espTot }
  return plano
end

-- ---------------------------------------------------------------------------------------------------------------
-- Modalidade de rota (CONTRATO secao 12): ns.planejarRota(e) -> plano, mais as funcoes de formula.
-- Decisoes onde o contrato cala:
-- * Funcao pura; nenhuma tabela global nem cache entre chamadas.
-- * pontos nil conta 1. Passo com ganho <= 0 numa pericia (quebrado) vira estado "lacuna" no x onde quebra.
-- * Lacuna tambem quando os passos acabam antes do alvo (info.lacuna = a pericia onde falta).
-- * Estados de portao (semDados, semPericia, naoAprendida, lacuna) nao vendem; so "feito" vende.
-- * Receita atual nao conhecida chama "trainer" so se a origem nao e leilao/vendedor (padrao).
-- * Sem passo atual e sem outra regra, proximo = "none".
-- * Margem de quantidade: compra para ceil(k*(100+margem)/100) crafts; a sobra volta ao estoque virtual.
-- * Fonte ausente para um reagente: falta "semPreco".
-- * Linhas de leilao: uma por item (passo = primeiro passo que comprou), ordem passo e depois custo maior.
-- * Dicas: foco em maiuscula ("ANVIL"), "PLACE <objeto>", "LEARN <padrao>".
-- ---------------------------------------------------------------------------------------------------------------

local rfloor, rceil, rmax, rmin = math.floor, math.ceil, math.max, math.min
local rsort = table.sort
local rlower, rupper = string.lower, string.upper
local RVAZIO = {}
local RHUGE = math.huge

local function rChavesNum(t)
  local l = {}
  if t then
    for k in pairs(t) do
      if type(k) == "number" then l[#l + 1] = k end
    end
  end
  rsort(l)
  return l
end

-- chance de subir a pericia s com um craft (igual ao rota.mjs chanceEm)
function ns.rotaChance(r, s)
  local pontos = r.pontos
  if pontos == nil then pontos = 1 end
  if pontos <= 0 then return 0 end
  local amarela, cinza = r.amarela or 0, r.cinza or 0
  if s < amarela then return 1 end
  if s >= cinza then return 0 end
  return rmin(1, rmax(0, (cinza - s) / (cinza - amarela)))
end

-- receitas F (ate 3 niveis, sem ciclo) que um craft da receita pede no trecho: { { rec, k } }. Com `de`, so as que se
-- aprendem ate essa pericia (a inicial sempre), como no credito da conta de fora (ferramentas\pregao\CONTRATO.md 10.10)
local function rPacote(rota, trecho, rec, de)
  local lista = {}
  local fontes = trecho and trecho.fontes
  local receitas = rota and rota.receitas
  if not fontes or not receitas then return lista end
  local function desce(r, kAcima, nivel, caminho)
    local rg = r.reagentes or RVAZIO
    for i = 1, #rg do
      local fo = fontes[rg[i][1]]
      if fo and fo.f == "F" then
        local fr = receitas[fo.magia]
        if fr and de and fr.origem ~= "inicial" and (fr.aprende or 1) > de then fr = nil end
        if fr and not caminho[fo.magia] then
          local pq = fr.qtd or 1
          if pq < 1 then pq = 1 end
          local k = kAcima * rg[i][2] / pq
          lista[#lista + 1] = { rec = fr, k = k }
          if nivel < 3 then
            caminho[fo.magia] = true
            desce(fr, k, nivel + 1, caminho)
            caminho[fo.magia] = nil
          end
        end
      end
    end
  end
  desce(rec, 1, 1, {})
  return lista
end

local function rGanho(rec, lista, s, credito)
  local g = ns.rotaChance(rec, s) * (rec.pontos == nil and 1 or rec.pontos)
  if credito then
    for i = 1, #lista do
      local f = lista[i].rec
      g = g + lista[i].k * ns.rotaChance(f, s) * (f.pontos == nil and 1 or f.pontos)
    end
  end
  return g
end

function ns.rotaGanho(rota, trecho, magia, s, credito, de)
  local rec = rota and rota.receitas and rota.receitas[magia]
  if not rec then return 0 end
  return rGanho(rec, credito and rPacote(rota, trecho, rec, de) or RVAZIO, s, credito)
end

-- crafts que faltam no passo a partir de s (nil e o x se quebrado); `corte` troca o ate (limite de nivel)
function ns.rotaFaltam(rota, trecho, passo, s, credito, corte)
  local rec = rota and rota.receitas and rota.receitas[passo.magia]
  if not rec then return nil end
  local ate = passo.ate
  if corte and corte < ate then ate = corte end
  if s >= ate then return 0 end
  local lista = credito and rPacote(rota, trecho, rec, passo.de) or RVAZIO
  local t = 0
  for x = rmax(s, passo.de), ate - 1 do
    local g = rGanho(rec, lista, x, credito)
    if g <= 0 then return nil, x end
    t = t + 1 / g
  end
  return rceil(t - 1e-9)
end

-- maior pericia atingida com k crafts do passo a partir de s
local function rAvancar(rec, lista, s, de, ate, k, credito)
  local t = 0
  local x = rmax(s, de)
  while x < ate do
    local g = rGanho(rec, lista, x, credito)
    if g <= 0 then return x end
    t = t + 1 / g
    if rceil(t - 1e-9) > k then return x end
    x = x + 1
  end
  return ate
end

function ns.planejarRota(e)
  e = e or RVAZIO
  local rota = e.rota
  local itens = e.itens or RVAZIO
  local bolsa = e.bolsa or RVAZIO
  local correio = e.correio or RVAZIO
  local conhecidas = e.conhecidas or RVAZIO
  local desconto = e.desconto or 0
  local tolerancia = e.tolerancia or 0
  local margem = e.margem or 0
  local dinheiro = rmax(e.dinheiro or 0, 0)
  local espacos = e.espacos or 0
  local credito = e.credito ~= false
  local credVenda = e.credVenda or RVAZIO
  local alvo = e.alvo or 0
  local pericia = e.pericia
  local receitas = (rota and rota.receitas) or RVAZIO

  local plano = { crafts = {}, fabricar = {}, leilao = {}, vendedor = {}, doEstoque = {}, revenda = {}, sobra = {},
                  totais = { gasto = 0, venda = 0, lucro = 0, espacos = 0 }, motivo = "fim", modo = 2 }
  local info = {
    prof = e.prof or (rota and rota.slug) or (rota and rota.nome and rlower(rota.nome)) or nil,
    nome = rota and rota.nome, curto = rota and rota.curto, pericia = pericia, max = e.max, alvo = alvo,
    limite = alvo, estado = "ok", passos = {}, chega = pericia, curtos = {}, treinar = {}, rank = nil,
    dicas = {}, reservar = {}, vender = {}, restante = 0, scan = {}, proximo = "none", fonte = e.fonte,
    velho = false,
  }
  plano.rota = info

  local fonteRota = e.fonte
  if fonteRota and fonteRota.em then
    local uf = e.ultimoFull
    if type(uf) == "table" then uf = uf.em end
    if type(uf) == "number" and uf > fonteRota.em then info.velho = true end
    if e.agora and e.agora - fonteRota.em > 21600 then info.velho = true end
  end

  local function portao(estado, proximo, motivo)
    info.estado = estado
    info.proximo = proximo
    plano.motivo = motivo or estado
    return plano
  end

  -- 1. portoes
  if not rota then return portao("semDados", "none") end
  if pericia == nil then return portao("semPericia", "open") end
  if pericia == 0 then return portao("naoAprendida", "trainer") end

  local function nomeItem(id)
    local it = itens[id]
    return (it and it.nome) or tostring(id)
  end
  local function pilhaDe(id)
    local it = itens[id]
    local p = it and it.pilha
    if not p or p < 1 then return 1 end
    return p
  end
  local function sabe(m, rec)
    return (conhecidas[m] and true) or (rec ~= nil and rec.origem == "inicial") or false
  end

  -- venda (7): precisa da reserva
  local function montarVenda(reservar)
    local proibidos, produtos = {}, {}
    local ms = rChavesNum(receitas)
    for i = 1, #ms do
      local r = receitas[ms[i]]
      if r.produto then produtos[r.produto] = true end
      if r.ferramentas then
        for a = 1, #r.ferramentas do
          local its = r.ferramentas[a].itens or RVAZIO
          for b = 1, #its do proibidos[its[b]] = true end
        end
      end
      if r.acampamento then
        local its = r.acampamento.itens or RVAZIO
        for b = 1, #its do proibidos[its[b]] = true end
      end
      if r.padrao then proibidos[r.padrao] = true end
    end
    local ids = rChavesNum(produtos)
    local vender = {}
    for i = 1, #ids do
      local id = ids[i]
      if not proibidos[id] then
        local v = rmax(0, rmin(credVenda[id] or 0, (bolsa[id] or 0) - (reservar[id] or 0)))
        if v > 0 then vender[id] = v end
      end
    end
    return vender
  end

  if pericia >= alvo then
    info.vender = montarVenda(RVAZIO)
    return portao("feito", "done", "fim")
  end

  -- 2. passos
  local passos = {}
  for ti = 1, #(rota.trechos or RVAZIO) do
    local trecho = rota.trechos[ti]
    local ps = trecho.passos or RVAZIO
    for pi = 1, #ps do
      local p = ps[pi]
      local rec = receitas[p.magia]
      if rec and p.de < alvo then
        local ate = p.ate
        if ate > alvo then ate = alvo end
        passos[#passos + 1] = { magia = p.magia, de = p.de, ate = ate, trecho = trecho, rec = rec,
                                nome = rec.nome or tostring(p.magia) }
      end
    end
  end
  do
    local c = pericia
    for i = 1, #passos do
      local p = passos[i]
      if p.ate > c then
        if p.de > c then info.lacuna = c; return portao("lacuna", "none") end
        c = p.ate
      end
    end
    if c < alvo then info.lacuna = c; return portao("lacuna", "none") end
  end

  -- 3. tetos
  local ranks = {}
  for i = 1, #(rota.ranks or RVAZIO) do ranks[i] = rota.ranks[i] end
  rsort(ranks, function(a, b) return a.cap < b.cap end)
  local nivel = e.nivel or 60
  local capNivel = 75
  for i = 1, #ranks do
    if (ranks[i].nivel or 0) <= nivel and ranks[i].cap > capNivel then capNivel = ranks[i].cap end
  end
  local limite = rmin(alvo, capNivel)
  info.limite = limite
  local maxEf = e.max
  if not maxEf then
    for i = 1, #ranks do
      if ranks[i].cap > pericia then maxEf = ranks[i].cap; break end
    end
  end
  local rank
  if maxEf and maxEf < alvo then
    for i = 1, #ranks do
      if ranks[i].cap > maxEf then rank = ranks[i]; break end
    end
    if rank and pericia >= (rank.pericia or 0) then
      info.rank = { nome = rank.nome, custo = rank.custo, pericia = rank.pericia, nivel = rank.nivel,
                    cap = rank.cap, bloqueado = (rank.nivel or 0) > nivel }
    else
      rank = nil
    end
  end
  local noTeto = rank ~= nil and e.max ~= nil and pericia >= e.max

  -- 4. crafts que faltam
  local atual
  for i = 1, #passos do
    local p = passos[i]
    p.i = i
    local n = 0
    if pericia < p.ate and p.de < limite then
      local x
      n, x = ns.rotaFaltam(rota, p.trecho, p, pericia, credito, limite)
      if n == nil then info.lacuna = x; return portao("lacuna", "none") end
    end
    p.n = n
    p.k = 0
    if n > 0 and not atual then atual = p end
  end

  -- ---- simulacao de compra ----
  -- escadas: degrau sem preco ou sem quantidade e pulado na hora (nao copia a lista)
  local esc = e.escadas or RVAZIO

  local ctxPasso, ctxTrecho

  -- registro por item (copia ao escrever: o estado clonado divide os registros com o pai)
  local function escrita(S, id)
    local r = S.ids[id]
    if r == nil then
      r = { _o = S }
      S.ids[id] = r
    elseif r._o ~= S then
      local c = {}
      for k, v in pairs(r) do c[k] = v end
      c._o = S
      S.ids[id] = c
      r = c
    end
    return r
  end

  local function novoEstado(ilim)
    local S = { ilim = ilim, gasto = 0, fal = false, curtos = {}, regs = {}, ids = {}, maos = {}, objeto = nil }
    for id, n in pairs(bolsa) do
      local r = escrita(S, id)
      r.sv = n
      if ilim then r.ph = n end
    end
    for id, n in pairs(correio) do
      local r = escrita(S, id)
      r.sv = (r.sv or 0) + n
      if ilim then r.ph = (r.ph or 0) + n end
    end
    if ilim then S.scan = {} end
    return S
  end
  local function clonar(S)
    local T = { ilim = S.ilim, gasto = S.gasto, fal = false, curtos = {}, regs = {}, ids = {}, maos = {},
                objeto = S.objeto }
    for id, r in pairs(S.ids) do T.ids[id] = r end
    for k, v in pairs(S.maos) do T.maos[k] = v end
    for i = 1, #S.regs do T.regs[i] = S.regs[i] end
    return T
  end

  local function falta(S, id, q, tipo, cap, magia)
    if S.ilim then return end
    S.fal = true
    for i = 1, #S.curtos do
      local c = S.curtos[i]
      if c.id == id and c.tipo == tipo then c.falta = c.falta + q; return end
    end
    S.curtos[#S.curtos + 1] = { id = id, nome = nomeItem(id), falta = q, cap = cap, tipo = tipo, magia = magia }
  end

  local function podeFabricar(m, rec)
    if sabe(m, rec) then return true end
    if rec.origem == "treinador" and (rec.aprende or 0) <= rmax(pericia, ctxPasso.de) then return true end
    return false
  end

  local function comprarL(S, id, q, fonte)
    local l = esc[id] or RVAZIO
    local lim = RHUGE
    if not S.ilim and fonte.teto then lim = rfloor(fonte.teto * (100 + tolerancia) / 100) end
    if S.ilim then S.scan[id] = true end
    local r = escrita(S, id)
    local pos = r.pos or 1
    local resto = r.resto
    local comprou = false
    while q > 0 do
      local st = l[pos]
      if not st then break end
      local p, qt = st.preco, st.qtd
      if not p or not qt or qt <= 0 then
        pos = pos + 1
        resto = nil
      else
        if p > lim then break end
        if st.inteiro then
          local c = p * qt
          S.gasto = S.gasto + c
          r.qtd = (r.qtd or 0) + qt
          r.custo = (r.custo or 0) + c
          if p > (r.pm or 0) then r.pm = p end
          local usa = rmin(qt, q)
          q = q - usa
          if qt > usa then r.sv = (r.sv or 0) + qt - usa end
          pos = pos + 1
          resto = nil
        else
          local disp = resto or qt
          local k = rmin(disp, q)
          local c = p * k
          S.gasto = S.gasto + c
          r.qtd = (r.qtd or 0) + k
          r.custo = (r.custo or 0) + c
          if p > (r.pm or 0) then r.pm = p end
          q = q - k
          if k == disp then pos = pos + 1; resto = nil else resto = disp - k end
        end
        comprou = true
      end
    end
    r.pos = pos
    r.resto = resto
    if comprou then
      if not r.passo then r.passo = ctxPasso.i end
      if lim ~= RHUGE and lim > (r.tetoL or 0) then r.tetoL = lim end
    end
    if q > 0 then
      if S.ilim then
        local pu = fonte.teto
        if not pu then
          local ult = l[#l]
          pu = ult and ult.preco
        end
        S.gasto = S.gasto + (pu or 0) * q
      elseif #l == 0 then
        falta(S, id, q, "semPreco", nil)
      else
        falta(S, id, q, "preco", lim)
      end
    end
  end

  local function comprarV(S, id, q, fonte, tipo)
    if not fonte.preco then falta(S, id, q, "semPreco", nil); return end
    local pu = rfloor(fonte.preco * (100 - desconto) / 100)
    S.gasto = S.gasto + pu * q
    local r = escrita(S, id)
    r.vq = (r.vq or 0) + q
    r.vc = (r.vc or 0) + pu * q
    if not r.vtipo then r.vtipo = tipo end
    if not r.vpasso then r.vpasso = ctxPasso.i end
  end

  local obter
  obter = function(S, id, q, depth, tipo, keep)
    if q <= 0 then return end
    local rg = S.rg
    if not keep then rg.cons[id] = (rg.cons[id] or 0) + q end
    local r0 = S.ids[id]
    local sv = r0 and r0.sv or 0
    if sv > 0 then
      local t = rmin(sv, q)
      local r = escrita(S, id)
      r.sv = sv - t
      if S.ilim then
        local ph = r.ph or 0
        if ph > 0 then
          local d = rmin(ph, t)
          r.ph = ph - d
          r.fis = (r.fis or 0) + d
        end
      end
      q = q - t
      if q <= 0 then return end
    end
    local fontes = ctxTrecho.fontes
    local fonte = fontes and fontes[id]
    if not fonte then falta(S, id, q, "semPreco", nil); return end
    local f = fonte.f
    if f == "F" then
      local rec = receitas[fonte.magia]
      if rec and depth <= 3 and podeFabricar(fonte.magia, rec) then
        local pq = rec.qtd or 1
        if pq < 1 then pq = 1 end
        local c = rceil(q / pq)
        rg.prod[id] = (rg.prod[id] or 0) + c * pq
        local rgs = rec.reagentes or RVAZIO
        for i = 1, #rgs do obter(S, rgs[i][1], rgs[i][2] * c, depth + 1, "mat", false) end
        local sobra = c * pq - q
        if sobra > 0 then
          local r = escrita(S, id)
          r.sv = (r.sv or 0) + sobra
        end
        return
      end
      if fonte.teto then
        f = "L"
      else
        falta(S, id, q, "bloqueio", nil, fonte.magia)
        return
      end
    end
    if f == "L" then
      comprarL(S, id, q, fonte)
    elseif f == "V" then
      comprarV(S, id, q, fonte, tipo)
    else
      falta(S, id, q, "semPreco", nil)
    end
  end

  local function temNaBolsa(id, S)
    return (bolsa[id] or 0) + (correio[id] or 0) > 0 or (S and S.maos[id]) or false
  end

  -- custo de uma unidade, so para escolher o objeto de acampamento
  local function custoRef(id, fontes)
    local fo = fontes and fontes[id]
    if not fo then return nil end
    if fo.f == "V" and fo.preco then return rfloor(fo.preco * (100 - desconto) / 100) end
    local l = esc[id]
    if l and l[1] and l[1].preco then return l[1].preco end
    if fo.teto then return fo.teto end
    return RHUGE
  end

  -- k crafts do passo P no estado S (ja clonado)
  local function simPasso(S, P, k)
    S.rg = { cons = {}, prod = {} }
    ctxPasso, ctxTrecho = P, P.trecho
    local rec = P.rec
    local fontes = P.trecho.fontes
    local K = rceil(k * (100 + margem) / 100)
    local ferr = rec.ferramentas
    if ferr then
      for a = 1, #ferr do
        local its = ferr[a].itens or RVAZIO
        local tem = false
        for b = 1, #its do
          if temNaBolsa(its[b], S) then tem = true; break end
        end
        if not tem then
          local esc1
          for b = 1, #its do
            if fontes and fontes[its[b]] then esc1 = its[b]; break end
          end
          if esc1 then
            obter(S, esc1, 1, 1, "ferramenta", true)
            S.maos[esc1] = true
          elseif #its > 0 then
            falta(S, its[1], 1, "semPreco", nil)
          end
        end
      end
    end
    local ac = rec.acampamento
    if ac then
      local its = ac.itens or RVAZIO
      local ok = false
      if S.objeto then
        for b = 1, #its do
          if its[b] == S.objeto then ok = true; break end
        end
      end
      if not ok then
        local achou
        for b = 1, #its do
          if temNaBolsa(its[b], S) then achou = its[b]; break end
        end
        if achou then
          S.objeto = achou
        else
          local melhor, mc
          for b = 1, #its do
            local c = custoRef(its[b], fontes)
            if c and (mc == nil or c < mc) then melhor = its[b]; mc = c end
          end
          if melhor then
            obter(S, melhor, 1, 1, "objeto", true)
            S.maos[melhor] = true
            S.objeto = melhor
          elseif #its > 0 then
            falta(S, its[1], 1, "semPreco", nil)
          end
        end
      end
    end
    if rec.padrao and not sabe(P.magia, rec) and (rec.origem == "leilao" or rec.origem == "vendedor") then
      local id = rec.padrao
      if not temNaBolsa(id, S) then
        obter(S, id, 1, 1, "padrao", true)
        S.maos[id] = true
      end
    end
    local rgs = rec.reagentes or RVAZIO
    for i = 1, #rgs do obter(S, rgs[i][1], rgs[i][2] * K, 1, "mat", false) end
    if K > k then
      for i = 1, #rgs do
        local id = rgs[i][1]
        local back = rgs[i][2] * (K - k)
        local r = escrita(S, id)
        r.sv = (r.sv or 0) + back
        S.rg.cons[id] = (S.rg.cons[id] or 0) - back
      end
    end
    if rec.produto then
      local q = (rec.qtd or 1) * k
      local r = escrita(S, rec.produto)
      r.sv = (r.sv or 0) + q
      S.rg.prod[rec.produto] = (S.rg.prod[rec.produto] or 0) + q
    end
    S.regs[#S.regs + 1] = S.rg
  end

  -- pico de bolsa (espacos a mais que hoje): chegada das compras e do correio, depois consumo e producao
  local function calcPico(S)
    local inv, sl, pil = {}, {}, {}
    local base, cur = 0, 0
    local function toca(id)
      if inv[id] == nil then
        local b = bolsa[id] or 0
        local p = pilhaDe(id)
        pil[id] = p
        local r = S.ids[id]
        inv[id] = b + (correio[id] or 0) + (r and r.qtd or 0) + (r and r.vq or 0)
        base = base + rceil(b / p)
        sl[id] = rceil(inv[id] / p)
        cur = cur + sl[id]
      end
    end
    local function muda(id, delta)
      toca(id)
      local v = inv[id] + delta
      if v < 0 then v = 0 end
      inv[id] = v
      local n = rceil(v / pil[id])
      cur = cur - sl[id] + n
      sl[id] = n
    end
    for id, r in pairs(S.ids) do
      if r.qtd or r.vq then toca(id) end
    end
    for id in pairs(correio) do toca(id) end
    local pico = cur - base
    for i = 1, #S.regs do
      local rg = S.regs[i]
      for id, n in pairs(rg.cons) do muda(id, -n) end
      if cur - base > pico then pico = cur - base end
      for id, n in pairs(rg.prod) do muda(id, n) end
      if cur - base > pico then pico = cur - base end
    end
    return pico
  end

  local function falhou(S)
    if S.fal then return S.curtos[1].tipo end
    if S.gasto > dinheiro then return "dinheiro" end
    if calcPico(S) > espacos - 2 then return "espaco" end
    return nil
  end

  -- 5. caminhada inteira (sem limite de dinheiro, bolsa nem preco)
  local reservar, restante, scanIds = {}, 0, {}
  if atual then
    local W = novoEstado(true)
    for i = 1, #passos do
      local p = passos[i]
      if p.n > 0 then simPasso(W, p, p.n) end
    end
    for id, r in pairs(W.ids) do
      if r.fis and r.fis > 0 then reservar[id] = r.fis end
    end
    restante = W.gasto
    scanIds = rChavesNum(W.scan)
  end
  info.reservar = reservar
  info.restante = restante
  info.scan = scanIds

  -- 6. trecho de compra
  local S = novoEstado(false)
  local motivo
  local falhada
  if atual then
    for i = 1, #passos do
      local p = passos[i]
      if p.n > 0 then
        local T = clonar(S)
        simPasso(T, p, p.n)
        local why = falhou(T)
        if not why then
          S = T
          p.k = p.n
        else
          local best, bestS = 0, nil
          local lo, hi = 1, p.n - 1
          while lo <= hi do
            local mid = rfloor((lo + hi) / 2)
            local T2 = clonar(S)
            simPasso(T2, p, mid)
            if falhou(T2) then
              hi = mid - 1
            else
              best = mid
              bestS = T2
              lo = mid + 1
            end
          end
          if best > 0 then S = bestS; p.k = best end
          -- motivo e curtos da primeira tentativa que falhou: o passo inteiro sobre o estado de antes dele (secao
          -- 12.4). Refazer best + 1 por cima do S ja com os `best` crafts contava esses crafts em dobro.
          motivo = why
          falhada = T
          break
        end
      end
    end
  end
  if not motivo then motivo = (limite >= alvo) and "fim" or "limite" end
  plano.motivo = motivo

  -- saida: passos, crafts, chega
  local chega = pericia
  local parou = false
  for i = 1, #passos do
    local p = passos[i]
    local estado = "depois"
    if pericia >= p.ate then
      estado = "feito"
    elseif atual and p == atual then
      estado = "agora"
    elseif p.k > 0 then
      estado = "compra"
    end
    info.passos[#info.passos + 1] = { de = p.de, ate = p.ate, magia = p.magia, nome = p.nome, n = p.n,
                                      estado = estado }
    if p.n > 0 then
      local ateC = rmin(p.ate, limite)
      if p.k > 0 then
        plano.crafts[#plano.crafts + 1] = { magia = p.magia, nome = p.nome, n = p.k, de = p.de, ate = ateC,
                                            custo = 0, venda = 0, lucro = 0 }
      end
      if not parou then
        if p.k == p.n then
          chega = rmax(chega, ateC)
        else
          if p.k > 0 then
            local lista = credito and rPacote(rota, p.trecho, p.rec, p.de) or RVAZIO
            chega = rmax(chega, rAvancar(p.rec, lista, chega, p.de, ateC, p.k, credito))
          end
          parou = true
        end
      end
    end
  end
  info.chega = chega
  if atual then
    info.atual = { i = atual.i, magia = atual.magia, nome = atual.nome, de = atual.de, ate = atual.ate,
                   faltam = atual.n, encantar = atual.rec.encantar and true or false }
  end

  -- curtos (da primeira tentativa que falhou)
  if falhada then
    for i = 1, #falhada.curtos do
      local c = falhada.curtos[i]
      info.curtos[i] = { id = c.id, nome = c.nome, falta = c.falta, cap = c.cap, tipo = c.tipo, magia = c.magia }
    end
  end

  -- leilao e vendedor
  local ids = rChavesNum(S.ids)
  for i = 1, #ids do
    local id = ids[i]
    local r = S.ids[id]
    if r.qtd and r.qtd > 0 then
      local l = esc[id] or RVAZIO
      local pos, resto = r.pos or 1, r.resto
      local lotes, inteiro = {}, false
      for j = 1, pos - 1 do
        local st = l[j]
        if st.preco and st.qtd and st.qtd > 0 then
          lotes[#lotes + 1] = { leilao = st.leilao, qtd = st.qtd, preco = st.preco }
          if st.inteiro then inteiro = true end
        end
      end
      if resto and l[pos] then
        local st = l[pos]
        lotes[#lotes + 1] = { leilao = st.leilao, qtd = st.qtd - resto, preco = st.preco }
      end
      plano.leilao[#plano.leilao + 1] = { id = id, nome = nomeItem(id), qtd = r.qtd, precoMax = r.pm or 0,
                                          custo = r.custo or 0, inteiro = inteiro, lotes = lotes,
                                          passo = r.passo or 0, teto = r.tetoL or 0 }
    end
  end
  rsort(plano.leilao, function(a, b)
    if a.passo ~= b.passo then return a.passo < b.passo end
    if a.custo ~= b.custo then return a.custo > b.custo end
    return a.id < b.id
  end)
  for i = 1, #ids do
    local id = ids[i]
    local r = S.ids[id]
    if r.vq and r.vq > 0 then
      plano.vendedor[#plano.vendedor + 1] = { id = id, nome = nomeItem(id), qtd = r.vq, custo = r.vc or 0,
                                              tipo = r.vtipo or "mat", passo = r.vpasso or 0 }
    end
  end
  rsort(plano.vendedor, function(a, b)
    if a.passo ~= b.passo then return a.passo < b.passo end
    if a.custo ~= b.custo then return a.custo > b.custo end
    return a.id < b.id
  end)
  plano.totais.gasto = S.gasto
  if #S.regs > 0 then plano.totais.espacos = calcPico(S) end

  -- treinar: receitas da rota (passos e F) nao conhecidas
  do
    local vistos, lista = {}, {}
    local function junta(m, rec)
      if not vistos[m] and not sabe(m, rec) then
        vistos[m] = true
        lista[#lista + 1] = { magia = m, nome = rec.nome or tostring(m), custo = rec.treino,
                              aprende = rec.aprende or 0, origem = rec.origem, padrao = rec.padrao }
      end
    end
    local function desce(rec, trecho, nivelF)
      local fontes = trecho.fontes
      local rgs = rec.reagentes or RVAZIO
      for i = 1, #rgs do
        local fo = fontes and fontes[rgs[i][1]]
        if fo and fo.f == "F" and receitas[fo.magia] and nivelF <= 3 then
          junta(fo.magia, receitas[fo.magia])
          desce(receitas[fo.magia], trecho, nivelF + 1)
        end
      end
    end
    for i = 1, #passos do
      local p = passos[i]
      if p.n > 0 then
        junta(p.magia, p.rec)
        desce(p.rec, p.trecho, 1)
      end
    end
    rsort(lista, function(a, b)
      if a.aprende ~= b.aprende then return a.aprende < b.aprende end
      return a.magia < b.magia
    end)
    info.treinar = lista
  end

  -- venda
  info.vender = montarVenda(reservar)

  -- dicas do passo atual
  if atual then
    local rec = atual.rec
    if rec.foco then
      local nome = type(rec.foco) == "table" and rec.foco.nome or rec.foco
      if nome then info.dicas[#info.dicas + 1] = rupper(tostring(nome)) end
    end
    if rec.acampamento then
      info.dicas[#info.dicas + 1] = "PLACE " .. tostring(rec.acampamento.nome or "object")
    end
    if rec.padrao and not sabe(atual.magia, rec) and (bolsa[rec.padrao] or 0) > 0 then
      info.dicas[#info.dicas + 1] = "LEARN " .. nomeItem(rec.padrao)
    end
  end

  -- proximo
  local prox
  if noTeto then
    prox = "trainer"
  elseif atual and not sabe(atual.magia, atual.rec) and atual.rec.origem ~= "leilao"
         and atual.rec.origem ~= "vendedor" then
    prox = "trainer"
  end
  if not prox and atual then
    local pede = {}
    local function coleta(rec, trecho, nivelF)
      local rgs = rec.reagentes or RVAZIO
      for i = 1, #rgs do
        pede[rgs[i][1]] = true
        local fo = trecho.fontes and trecho.fontes[rgs[i][1]]
        if fo and fo.f == "F" and receitas[fo.magia] and nivelF <= 3 then
          coleta(receitas[fo.magia], trecho, nivelF + 1)
        end
      end
      for a = 1, #(rec.ferramentas or RVAZIO) do
        local its = rec.ferramentas[a].itens or RVAZIO
        for b = 1, #its do pede[its[b]] = true end
      end
      if rec.acampamento then
        local its = rec.acampamento.itens or RVAZIO
        for b = 1, #its do pede[its[b]] = true end
      end
      if rec.padrao then pede[rec.padrao] = true end
    end
    coleta(atual.rec, atual.trecho, 1)
    for id in pairs(pede) do
      if (correio[id] or 0) > 0 then prox = "mail"; break end
    end
  end
  if not prox then
    if #plano.leilao > 0 then
      prox = "ah"
    elseif #plano.vendedor > 0 or next(info.vender) ~= nil then
      prox = "vendor"
    elseif #plano.crafts > 0 then
      prox = "craft"
    elseif atual then
      prox = "ah"
    else
      prox = "none"
    end
  end
  info.proximo = prox
  return plano
end
