-- Limites do fechar (secao 6.2): dias so dos ultimos 14, chave sem dia recente sai, blocos ate 126 por chave.
return {
  id = "banco-09", grupo = "unid-banco",
  descricao = "fechar aplica os limites da secao 6.2: 14 dias por chave, chave sem dia recente sai, 126 blocos por chave",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { chamar = function(b)
        local ns = b.ns
        local hoje = ns.diaMercado(ns.servidor())
        local m = ns.banco.memoria()
        m.itens['2589'] = { vend = 13, tipo = 'c', pilha = 20, conf = 1 }
        m.dias['2589'] = { [hoje] = { min = 9, qtd = 10 }, [hoje - 13] = { min = 9, qtd = 11 }, [hoje - 14] = { min = 9, qtd = 12 } }
        m.dias['1111'] = { [hoje - 30] = { min = 5, qtd = 1 } }
        local blocos = {}
        for i = 1, 130 do blocos[124000 + i] = { min = 9, qtd = i } end
        m.blocos['2589'] = blocos
      end },
    { reload = true },
  },
  conferir = function(b)
    local ns = b.ns
    local m = ns.banco.memoria()
    local hoje = ns.diaMercado(ns.servidor())
    local d = m.dias['2589']
    b.verdadeiro(d ~= nil and d[hoje] ~= nil and d[hoje - 13] ~= nil, "os dias dos ultimos 14 ficam")
    b.igual(d[hoje - 14], nil, "o dia 15 atras sai")
    b.igual(m.dias['1111'], nil, "chave sem dia nos ultimos 14 dias sai")
    local n = 0
    for _ in pairs(m.blocos['2589']) do n = n + 1 end
    b.igual(n, 126, "126 blocos por chave")
    b.igual(m.blocos['2589'][124130], { min = 9, qtd = 130 }, "o bloco mais novo fica")
    b.igual(m.blocos['2589'][124004], nil, "o bloco mais velho alem dos 126 sai")
    b.igual(m.itens['2589'], { vend = 13, tipo = 'c', pilha = 20, conf = 1 }, "itens nao tem limite e ficam")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
