-- Vigia junto com o Scan normal: a busca da vigia troca a escada em ns.scan sem refazer o plano, o Scan grava no historico
-- e a vigia espera enquanto ns.scanEstado.ocupado.
return {
  id = "compra-14", grupo = "compra",
  descricao = "vigia + Scan: busca vigia atualiza ns.scan.escadas sem replanejar, Scan registra no historico, vigia espera o scan",
  aceita_violacoes = true,   -- so I9 (busca periodica por pedido do dono); conferir exige zero das outras
  inicio = {
    dinheiro = 51400,
    itens = {
      [4461] = { nome = "Raptor Hide", vend = 208, pilha = 10 },
      [4234] = { nome = "Heavy Leather", vend = 150, pilha = 20 },
      [2321] = { nome = "Fine Thread", vend = 25, pilha = 20 },
      [4455] = { nome = "Raptor Hide Harness", vend = 3096, pilha = 1 },
    },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 4234, qtd = 8 },
      { bolsa = 0, slot = 2, itemID = 2321, qtd = 4 },
    },
    receitas = {
      [4096] = { nome = "Raptor Hide Harness", produto = 4455, qtd = 1, reagentes = { { 4461, 6 }, { 4234, 4 }, { 2321, 2 } } },
    },
    sv_char = { conhecidas = { quem = "Hexumlite", em = 1, ids = { [4096] = true }, n = 1 } },
    sv = { vigia = { itens = { [4461] = { nome = "Raptor Hide", teto = 100, qtd = 20 } }, intervalo = 30, historico = {} } },
    mercado = {
      ["4461"] = { { id = 7001, preco = 130, qtd = 8 }, { id = 7002, preco = 160, qtd = 100 } },
    },
  },
  passos = {
    { abrir_leilao = true },
    { avancar = 5 },
    { chamar = function(b)
      local ns = b.ns
      b.igual(b.contar("SendSearchQuery"), 1, "uma busca da vigia")
      b.verdadeiro(ns.scan == nil, "sem scan ainda")
      b.igual(#CompraForeverDB.vigia.historico[4461], 1, "historico da vigia")
    end },
    { clique = "CompraForeverScan" },
    { avancar = 10 },
    { chamar = function(b)
      local ns = b.ns
      b.verdadeiro(ns.scan ~= nil, "scan terminou")
      b.verdadeiro(ns.plano ~= nil and ns.plano.leilao[1] ~= nil, "plano com a compra de Raptor Hide")
      b.igual(ns.plano.leilao[1].custo, 1680, "custo do plano")
      ns.planoAntes = ns.plano
      b.igual(#CompraForeverDB.vigia.historico[4461], 2, "o Scan gravou no historico")
      b.igual(b.contar("SendSearchQuery"), 3, "vigia (4461) + scan (4234 e 4461)")
    end },
    -- o preco cai a 120: a vigia troca a escada do scan, o plano fica como estava
    { chamar = function(b)
      __bancada.A.mercado[4461] = { { id = 7001, preco = 120, qtd = 8 }, { id = 7002, preco = 160, qtd = 100 } }
    end },
    { avancar = 25 },
    { chamar = function(b)
      local ns = b.ns
      b.igual(b.contar("SendSearchQuery"), 4, "quarta busca (vigia)")
      b.igual(ns.scan.escadas[4461][1].preco, 120, "escada do scan atualizada")
      b.verdadeiro(ns.plano == ns.planoAntes, "plano nao foi refeito")
      b.igual(ns.plano.leilao[1].custo, 1680, "plano com o custo antigo")
      b.igual(#CompraForeverDB.vigia.historico[4461], 3, "historico da vigia")
      b.igual(CompraForeverDB.vigia.historico[4461][3].min, 120, "min 120")
      b.verdadeiro(ns.scan.tipo == "dirigido", "o scan continua o mesmo")
    end },
    -- enquanto o scan esta ocupado a vigia espera (tenta de novo a cada 2 s)
    { chamar = function(b)
      b.ns.scanEstado.ocupado = true
    end },
    { avancar = 70 },
    { chamar = function(b)
      b.igual(b.contar("SendSearchQuery"), 4, "nenhuma busca da vigia com o scan ocupado")
      b.ns.scanEstado.ocupado = false
    end },
    { avancar = 3 },
    { chamar = function(b)
      b.igual(b.contar("SendSearchQuery"), 5, "a vigia volta quando o scan acaba")
    end },
  },
  conferir = function(b)
    local m = {}
    for _, v in ipairs(b.violacoes()) do
      if v.tipo ~= "I9" then m[#m + 1] = v.tipo .. ": " .. v.msg end
    end
    b.igual(#m, 0, "sem violacao I1/hardware: " .. table.concat(m, " / "))
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
