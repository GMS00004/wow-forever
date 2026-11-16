-- Ponta a ponta: sem outra tecla do dono, o folego para em T_pulso e nenhuma consulta sai depois (I9).
local mercado = {}
local ids = { 2589, 2592, 4306, 2318, 2319 }
local precos = { 9, 30, 100, 10, 40 }
for i = 1, #ids do mercado[tostring(ids[i])] = { { preco = precos[i], qtd = 10 + i, donos = 2 } } end
return {
  id = "folego-03", grupo = "folego",
  descricao = "T_pulso = 1 s: o folego para onde esta; nenhuma consulta depois; b.violacoes() vazio",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000, mercado = mercado },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b) b.ns.cfg.T_pulso = 1 end },
    { tecla = "L" },
    { avancar = 20 },
    { chamar = function(b)
        b.__n20 = b.contar("QueryOwnedAuctions") + b.contar("SendBrowseQuery") + b.contar("SendSearchQuery")
      end },
    { avancar = 100 },
  },
  conferir = function(b)
    local n = b.contar("QueryOwnedAuctions") + b.contar("SendBrowseQuery") + b.contar("SendSearchQuery")
    b.igual(n, b.__n20, "nenhuma consulta depois do fim do folego")
    b.verdadeiro(n < 8, "o folego nao chegou ao fim da lista: parou em T_pulso (" .. n .. " consultas)")
    b.igual(b.ns.varredura.estado().fase, "PARADO", "varredura parada")
    b.igual(b.ns.pedidos.estado().fase, "PARADO", "pedidos parado")
    b.igual(#b.violacoes(), 0, "sem violacao (I9)")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
