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
