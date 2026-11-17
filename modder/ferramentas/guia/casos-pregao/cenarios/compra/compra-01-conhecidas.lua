-- Receitas conhecidas: leitura da janela de Leatherworking (0,5 s depois), reserva do GuiaForeverDB, moeda e valores.
return {
  id = "compra-01", grupo = "compra",
  descricao = "abre a profissao com 3 receitas aprendidas e grava; sem gravacao usa a reserva do GuiaForeverDB; moeda e /compra",
  inicio = {
    dinheiro = 100000,
    receitas = {
      [4096] = { nome = "Raptor Hide Harness", produto = 4455, qtd = 1, reagentes = { { 4461, 6 }, { 4234, 4 }, { 2321, 2 } } },
      [4097] = { nome = "Raptor Hide Belt", produto = 4456, qtd = 1, reagentes = { { 4461, 4 }, { 4234, 4 }, { 2321, 2 } } },
      [3760] = { nome = "Hillman's Cloak", produto = 3719, qtd = 1, reagentes = { { 4234, 5 }, { 2321, 2 } } },
      [3761] = { nome = "Fine Leather Tunic", produto = 4243, qtd = 1, reagentes = { { 4231, 3 } }, aprendida = false },
    },
  },
  passos = {
    { abrir_profissao = true },
    { avancar = 0.3 },
    { chamar = function(b)
      b.falso(CompraForeverCharDB.conhecidas, "nada gravado antes de 0,5 s")
    end },
    { avancar = 0.4 },
    { chamar = function(b)
      local k = CompraForeverCharDB.conhecidas
      b.verdadeiro(k ~= nil, "conhecidas gravadas")
      if not k then return end
      b.igual(k.n, 3, "tres aprendidas (a quarta nao)")
      b.igual(k.ids, { [4096] = true, [4097] = true, [3760] = true }, "ids")
      b.igual(k.quem, UnitName("player"), "quem")
      b.igual(k.pericia, 150, "pericia")
      b.verdadeiro(type(k.em) == "number", "em")
      local ids, origem = b.ns.conhecidas()
      b.igual(origem, "proprio", "origem")
      b.igual(ids, k.ids, "ns.conhecidas devolve as gravadas")
    end },
    { fechar_profissao = true },
    -- SV vazia: a reserva do GuiaForeverDB do mesmo personagem, a gravacao mais nova
    { chamar = function(b)
      CompraForeverCharDB.conhecidas = nil
      GuiaForeverDB = { personagens = {
        X = { receitasLW = { quem = UnitName("player"), em = 100, ids = { [4096] = true }, n = 1 } },
        Y = { receitasLW = { quem = UnitName("player"), em = 200, ids = { [4096] = true, [4097] = true }, n = 2 } },
        Z = { receitasLW = { quem = "Outro", em = 900, ids = { [999] = true }, n = 1 } },
      } }
      local ids, origem = b.ns.conhecidas()
      b.igual(origem, "guia", "origem reserva")
      b.igual(ids, { [4096] = true, [4097] = true }, "reserva: mais nova do mesmo quem")
      GuiaForeverDB = nil
      local vazio, o2 = b.ns.conhecidas()
      b.igual(next(vazio), nil, "sem nada conhecido")
      b.igual(o2, nil, "sem origem")
    end },
    -- moeda, valores e /compra
    { chamar = function(b)
      local ns = b.ns
      b.igual(ns.moeda(12705), "1g 27s 05c", "moeda 12705")
      b.igual(ns.moeda(5500), "55s", "moeda 5500")
      b.igual(ns.moeda(255), "2s 55c", "moeda 255")
      b.igual(ns.moeda(0), "0c", "moeda 0")
      b.igual(ns.moeda(-1), "-", "moeda negativa")
      b.igual(ns.lerValor("1g20s"), 12000, "1g20s")
      b.igual(ns.lerValor("50s"), 5000, "50s")
      b.igual(ns.lerValor("30c"), 30, "30c")
      b.igual(ns.lerValor("250"), 250, "numero puro")
      b.igual(ns.lerValor("1g 5c"), 10005, "com espaco")
      b.igual(ns.lerValor("abc"), nil, "lixo")
      b.igual(ns.lerValor("12x"), nil, "unidade desconhecida")
      SlashCmdList.COMPRAFOREVER("reserva 1g")
      b.igual(CompraForeverDB.config.reserva, 10000, "/compra reserva")
      b.igual(ns.dinheiro(), 90000, "dinheiro menos reserva")
      SlashCmdList.COMPRAFOREVER("desconto 25")
      b.igual(CompraForeverDB.config.desconto, 25, "/compra desconto")
      SlashCmdList.COMPRAFOREVER("desconto 150")
      b.igual(CompraForeverDB.config.desconto, 25, "desconto fora da faixa e recusado")
      SlashCmdList.COMPRAFOREVER("lucro 2s")
      b.igual(CompraForeverDB.config.lucroMin, 200, "/compra lucro")
      b.igual(CompraForeverDB.config.margemMin, 5, "margem padrao")
      b.igual(ns.plano, nil, "sem scan, sem plano")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
