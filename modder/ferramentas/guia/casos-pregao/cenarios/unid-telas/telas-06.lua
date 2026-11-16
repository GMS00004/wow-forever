-- Teclas.lua: H alterna KEYS ON e KEYS HELD pela faixa held do Nucleo.
return {
  id = "telas-06", grupo = "unid-telas",
  descricao = "H alterna KEYS ON e KEYS HELD",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  passos = {
    { avancar = 1 },
    { abrir_leilao = true },
    { avancar = 1 },
    { chamar = function(b)
        b.verdadeiro(string.find(b.tela().linhas[2], "KEYS ON", 1, true) ~= nil, "comeca com KEYS ON")
        b.igual(b.ns.faixaLigada("held"), false, "sem a faixa held")
      end },
    { tecla = "H" },
    { avancar = 0.1 },
    { chamar = function(b)
        b.igual(b.ns.faixa, "KEYS HELD", "H solta as teclas")
        b.igual(b.tela().faixa, "KEYS HELD", "a tela acompanha")
        b.verdadeiro(string.find(b.tela().linhas[2], "KEYS HELD", 1, true) ~= nil, "a linha MODE diz KEYS HELD")
        b.verdadeiro(string.find(b.tela().linhas[4], "KEYS HELD", 1, true) ~= nil, "a faixa esta na linha de estado")
      end },
    { tecla = "H" },
    { avancar = 0.1 },
    { chamar = function(b)
        b.igual(b.ns.faixa, "KEYS HELD", "H dentro da janela de repeticao e ignorada")
      end },
    { avancar = 1 },
    { tecla = "H" },
    { avancar = 1 },
  },
  conferir = function(b)
    b.igual(b.ns.faixaLigada("held"), false, "H rearma")
    b.verdadeiro(string.find(b.tela().linhas[2], "KEYS ON", 1, true) ~= nil, "volta a KEYS ON")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
