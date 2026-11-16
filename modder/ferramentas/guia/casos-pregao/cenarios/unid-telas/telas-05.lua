-- Teclas.lua: foco numa caixa de texto pausa as teclas e acende a faixa Keys paused (S12).
return {
  id = "telas-05", grupo = "unid-telas",
  descricao = "foco em caixa de texto pausa as teclas com a faixa Keys paused; soltar o foco volta",
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
    { chamar = function(b) b.igual(b.__mover, 1, "sem foco a tecla vale") end },
    { injetar = "foco_texto" },
    { avancar = 1 },
    { chamar = function(b)
        b.igual(b.ns.faixa, "Keys paused", "o tique da janela viu o foco")
        b.igual(b.tela().faixa, "Keys paused", "a tela mostra a faixa")
        b.verdadeiro(string.find(b.tela().linhas[4], "Keys paused", 1, true) ~= nil, "a faixa esta na linha de estado")
      end },
    { tecla = "N" },
    { chamar = function(b)
        b.igual(b.__mover, 1, "com o foco na caixa a tecla nao dispara")
        b.igual(b.__presenca, 1, "e nao conta como presenca do dono")
        b.verdadeiro(string.find(b.db().sonda.S12, "keys paused", 1, true) ~= nil, "S12 gravada")
      end },
    { injetar = "foco_livre" },
    { avancar = 1 },
    { chamar = function(b) b.igual(b.ns.faixaLigada("pausa"), false, "faixa de pausa limpa sem o foco") end },
    { tecla = "N" },
  },
  conferir = function(b)
    b.igual(b.__mover, 2, "a tecla volta a valer")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
