-- Ponta a ponta: o primeiro folego concilia, o segundo nao; os proprios vao para pers().proprios.
return {
  id = "folego-08", grupo = "folego",
  descricao = "o primeiro L depois da abertura concilia; o segundo nao; leiloes proprios gravados em pers().proprios",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000,
    mercado = { ["2589"] = { { preco = 9, qtd = 14, donos = 2 }, { preco = 11, qtd = 5, proprio = true } } },
    proprios = { { itemID = 2589, qtd = 5, preco = 11 } } },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b)
        b.__faixa0 = b.ns.faixa
        b.__chamadas = 0
        local f = b.ns.cofre.conciliar
        b.ns.cofre.conciliar = function(...)
          b.__chamadas = b.__chamadas + 1
          return f(...)
        end
      end },
    { tecla = "L" },
    { ate_ocioso = true },
    { chamar = function(b)
        b.__c1 = b.__chamadas
        b.__proprios = b.ns.banco.pers().proprios
      end },
    { avancar = 20 },
    { tecla = "L" },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(b.__faixa0, "Press L to reconcile", "faixa de conciliar na abertura, sem consulta")
    b.igual(b.__c1, 1, "conciliou no primeiro folego")
    b.igual(b.__chamadas, 1, "nao conciliou no segundo")
    b.verdadeiro(type(b.__proprios) == "table" and #b.__proprios == 1, "um leilao proprio gravado")
    b.igual(b.contar("QueryOwnedAuctions"), 2, "proprios em todo folego")
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
