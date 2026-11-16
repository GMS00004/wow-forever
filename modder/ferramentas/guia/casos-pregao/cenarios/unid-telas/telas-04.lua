-- Teclas.lua: tecla repetida dentro de cfg.guardas.repeticao_ms e ignorada; cada tecla aceita avisa o Pedidos.
return {
  id = "telas-04", grupo = "unid-telas",
  descricao = "tecla repetida dentro da janela de repeticao e ignorada",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { avancar = 1 },
    { chamar = function(b)
        b.__mover, b.__presenca = 0, 0
        local original = b.ns.telas.mover
        b.ns.telas.mover = function(d) b.__mover = b.__mover + 1 return original(d) end
        b.ns.pedidos.tecla = function() b.__presenca = b.__presenca + 1 end
      end },
    { abrir_leilao = true },
    { avancar = 1 },
    { tecla = "N" },
    { avancar = 0.1 },
    { tecla = "N" },
    { chamar = function(b)
        b.igual(b.__mover, 1, "a segunda N, 100 ms depois, foi ignorada")
        b.igual(b.__presenca, 1, "a repeticao nao conta como presenca")
      end },
    { avancar = 0.5 },
    { tecla = "N" },
    { tecla = "U" },
  },
  conferir = function(b)
    b.igual(b.__mover, 3, "N depois de 600 ms vale; U e outra tecla e vale")
    b.igual(b.__presenca, 3, "cada tecla aceita chama ns.pedidos.tecla()")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
