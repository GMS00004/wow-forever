-- /compra sonda prof (CONTRATO 12.8): roda com a janela fechada e aberta, sem erro de Lua, mesmo sem as APIs de
-- profissao na bancada, e grava as linhas em CompraForeverDB.sonda.
return {
  id = "rota-00", grupo = "rota",
  descricao = "sonda de profissao: so leitura, sem erro com APIs ausentes, grava as linhas",
  inicio = { dinheiro = 1000 },
  passos = {
    { chamar = function(b) SlashCmdList.COMPRAFOREVER("sonda prof") end },
    { chamar = function(b)
      local s = b.db().sonda
      b.verdadeiro(type(s) == "table" and type(s.linhas) == "table", "gravou a sonda")
      b.verdadeiro(#s.linhas >= 5, "linhas da sonda com a janela fechada: " .. tostring(s and #s.linhas))
    end },
    { abrir_profissao = { nome = "Leatherworking", nivel = 150 } },
    { chamar = function(b) SlashCmdList.COMPRAFOREVER("sonda prof") end },
    { chamar = function(b)
      local s = b.db().sonda
      local achou = false
      for _, l in ipairs(s.linhas) do if string.find(l, "^Base ") then achou = true end end
      b.verdadeiro(achou, "com a janela aberta le a info da base")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
