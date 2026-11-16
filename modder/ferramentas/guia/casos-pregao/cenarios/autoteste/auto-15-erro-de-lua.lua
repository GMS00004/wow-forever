-- Erro de Lua dentro de timer ou de evento e capturado pelo geterrorhandler e reprova o cenario (a menos que aceita_erros).
return {
  id = "auto-15", grupo = "autoteste",
  descricao = "erro capturado: aparece em b.erros(); sem aceita_erros reprovaria (esperado-falha na segunda parte)",
  aceita_erros = true,
  inicio = {},
  passos = {
    { chamar = function(b)
        C_Timer.After(1, function() error("explodiu no timer") end)
        xpcall(function() error("explodiu no xpcall") end, geterrorhandler())
      end },
    { avancar = 2 },
  },
  conferir = function(b)
    b.igual(#b.erros(), 2, "dois erros capturados")
    b.verdadeiro(string.find(b.erros()[1], "explodiu no xpcall", 1, true) ~= nil, "o do xpcall primeiro")
    b.verdadeiro(string.find(b.erros()[2], "explodiu no timer", 1, true) ~= nil, "o do timer depois")
  end,
}
