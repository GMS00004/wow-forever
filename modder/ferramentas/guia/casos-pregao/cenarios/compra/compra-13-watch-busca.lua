-- Vigia: busca periodica com a AH aberta, historico, painel, alerta, compra em dois cliques, persistencia.
local function textos()
  local out = {}
  for _, r in ipairs({ CompraForeverPainel:GetRegions() }) do
    local t = r:GetText()
    if t and t ~= "" then out[#out + 1] = t end
  end
  return out
end
local function tem(b, trecho, msg)
  local lista = textos()
  for _, t in ipairs(lista) do
    if string.find(t, trecho, 1, true) then return end
  end
  b.verdadeiro(false, msg .. " (texto '" .. trecho .. "' nao achado em: " .. table.concat(lista, " | ") .. ")")
end

return {
  id = "compra-13", grupo = "compra",
  aceita_violacoes = true,   -- so I9: a busca da vigia e periodica por pedido do dono (conferir exige zero das outras)
  descricao = "vigia: busca sozinha com a AH aberta, historico, painel WATCH, alerta ao cair, compra [WATCH] em dois cliques, SV",
  inicio = {
    dinheiro = 100000,
    itens = {
      [4304] = { nome = "Thick Leather", vend = 70, pilha = 20 },
    },
    sv = { vigia = { itens = { [4304] = { nome = "Thick Leather", teto = 490, qtd = 20 } }, intervalo = 30, historico = {} } },
    mercado = {
      ["4304"] = { { preco = 609, qtd = 40 }, { preco = 650, qtd = 100 } },
    },
  },
  passos = {
    { abrir_leilao = true },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(b.contar("SendSearchQuery"), 0, "primeira busca so 2 s depois de abrir")
    end },
    { avancar = 2 },
    { chamar = function(b)
      local ns = b.ns
      b.igual(b.contar("SendSearchQuery"), 1, "uma busca do 4304")
      b.igual(b.chamadas("SendSearchQuery")[1].args[1].itemID, 4304, "busca do id 4304")
      b.verdadeiro(ns.scan == nil, "ns.scan continua nil")
      b.verdadeiro(ns.plano == nil, "ns.plano continua nil")
      local h = CompraForeverDB.vigia.historico[4304]
      b.igual(#h, 1, "uma entrada no historico")
      b.igual(h[1].min, 609, "min 609")
      b.igual(h[1].unid, 140, "140 unidades")
      b.igual(h[1].p25, 609, "p25: 25% de 140 = 35 cai no primeiro degrau")
      b.igual(ns.vigia.escadas[4304][1].preco, 609, "escada guardada")
      tem(b, "  Thick Leather <= 4s 90c | now 6s 09c (140)", "linha WATCH em cinza")
      tem(b, "|cff999999", "cinza")
      tem(b, "WATCH ", "titulo")
      tem(b, "No scan yet", "a linha de sem scan continua")
      b.igual(CompraForeverAcao:GetText(), "Nothing to do", "sem acao")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado")
      b.igual(b.contar("PlaySound"), 0, "sem alerta")
    end },
    -- nao busca de novo antes do intervalo
    { avancar = 20 },
    { chamar = function(b)
      b.igual(b.contar("SendSearchQuery"), 1, "ainda uma busca")
    end },
    -- a queda: Thick Leather a 3s 40c
    { chamar = function(b)
      __bancada.A.mercado[4304] = { { id = 8001, preco = 340, qtd = 50 }, { id = 8002, preco = 609, qtd = 40 } }
    end },
    { avancar = 12 },
    { chamar = function(b)
      b.igual(b.contar("SendSearchQuery"), 2, "segunda busca")
      b.igual(b.contar("PlaySound"), 1, "um alerta sonoro")
      b.igual(b.chamadas("PlaySound")[1].args[1], 8959, "som 8959")
      b.igual(CompraForeverAcao:GetText(), "Buy 20 Thick Leather (68s) [WATCH]", "botao de acao da vigia")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
      tem(b, "BUY Thick Leather <= 4s 90c | now 3s 40c (90)", "linha WATCH em verde com BUY")
      tem(b, "|cff33ff33", "verde")
      b.igual(#CompraForeverDB.vigia.historico[4304], 2, "duas entradas")
    end },
    { clique = "CompraForeverAcao" },
    { chamar = function(b)
      b.igual(b.contar("StartCommoditiesPurchase"), 1, "um Start")
      b.igual(b.chamadas("StartCommoditiesPurchase")[1].args[1], 4304, "Start do 4304")
      b.igual(b.chamadas("StartCommoditiesPurchase")[1].args[2], 20, "Start de 20")
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 0, "nada confirmado no clique 1")
    end },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Confirm 20 Thick Leather (68s)", "texto vira Confirm")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 2 },
    { chamar = function(b)
      local ns = b.ns
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 1, "um Confirm")
      b.igual(b.contar("StartCommoditiesPurchase"), 1, "ainda um Start")
      b.igual(GetMoney(), 100000 - 6800, "dinheiro")
      b.igual(ns.sessao.vigiaComprado[4304], 20, "vigiaComprado")
      b.igual(ns.sessao.comprado[4304], 20, "comprado")
      b.verdadeiro(ns.scan == nil, "ns.scan ainda nil")
      b.igual(ns.vigia.escadas[4304][1].qtd, 30, "escada consumida: sobram 30 a 3s 40c")
      b.igual(b.contar("PlaySound"), 1, "a oferta que sobra nao alerta de novo")
    end },
    -- o mercado volta ao normal
    { chamar = function(b)
      __bancada.A.mercado[4304] = { { id = 8002, preco = 609, qtd = 40 } }
    end },
    { avancar = 31 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Nothing to do", "preco voltou: sem acao")
      tem(b, "  Thick Leather <= 4s 90c | now 6s 09c (40)", "linha cinza de novo")
    end },
    { salvar_sv = "compra-13" },
    { reload = true },
    { chamar = function(b)
      local h = CompraForeverDB.vigia.historico[4304]
      b.verdadeiro(#h >= 3, "historico persiste: " .. tostring(#h))
      b.igual(h[1].min, 609, "primeira entrada")
      b.igual(CompraForeverDB.vigia.itens[4304].teto, 490, "item vigiado persiste")
    end },
  },
  conferir = function(b)
    -- I9 (busca so com tecla do dono em 90 s) vem do PregaoForever; a busca da vigia e periodica por pedido do dono
    local m = {}
    for _, v in ipairs(b.violacoes()) do
      if v.tipo ~= "I9" then m[#m + 1] = v.tipo .. ": " .. v.msg end
    end
    b.igual(#m, 0, "sem violacao I1/hardware: " .. table.concat(m, " / "))
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
