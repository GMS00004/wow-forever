-- Um passo que nao pode rodar (tecla de um botao que nao existe) reprova o cenario, em vez de passar calado.
return {
  id = "auto-14", grupo = "autoteste",
  descricao = "tecla sem botao reprova (esperado-falha)",
  esperado_falha = "nao existe",
  inicio = {},
  passos = { { tecla = "Z" } },
  conferir = function(b) end,
}
