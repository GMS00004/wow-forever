-- Prova de que a bancada reprova: a afirmacao abaixo e falsa de proposito. O proprio auto-teste conta este cenario
-- como esperado-falha (campo esperado_falha): se ele passasse, seria erro.
return {
  id = "auto-13", grupo = "autoteste",
  descricao = "afirmacao falsa de proposito (esperado-falha)",
  esperado_falha = "de proposito",
  inicio = { dinheiro = 100 },
  passos = { { avancar = 1 } },
  conferir = function(b)
    b.igual(GetMoney(), 999, "dinheiro de proposito errado")
  end,
}
