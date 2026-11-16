-- Sem aceita_erros, um erro de Lua capturado reprova o cenario.
return {
  id = "auto-16", grupo = "autoteste",
  descricao = "erro de Lua reprova (esperado-falha)",
  esperado_falha = "erro de Lua",
  inicio = {},
  passos = {
    { chamar = function(b) C_Timer.After(1, function() error("boom") end) end },
    { avancar = 2 },
  },
  conferir = function(b) end,
}
