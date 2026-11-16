-- Ponta a ponta: o leilao fecha no meio do folego; nada mais sai e a fila fica zerada.
local mercado = {}
local ids = { 2589, 2592, 4306, 2318, 2319 }
local precos = { 9, 30, 100, 10, 40 }
for i = 1, #ids do mercado[tostring(ids[i])] = { { preco = precos[i], qtd = 10 + i, donos = 2 } } end
return {
  id = "folego-07", grupo = "folego",
  descricao = "fechar o leilao com o folego em andamento: tudo PARADO, nenhuma consulta depois, sem violacao",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000, mercado = mercado },
  passos = {
    { abrir_leilao = true },
    { tecla = "L" },
    { avancar = 1.5 },
    { chamar = function(b)
        b.__fase = b.ns.varredura.estado().fase
        b.__n15 = b.contar("QueryOwnedAuctions") + b.contar("SendBrowseQuery") + b.contar("SendSearchQuery")
      end },
    { fechar_leilao = true },
    { avancar = 60 },
  },
  conferir = function(b)
    b.verdadeiro(b.__fase ~= "PARADO", "o folego estava em andamento aos 1,5 s")
    local n = b.contar("QueryOwnedAuctions") + b.contar("SendBrowseQuery") + b.contar("SendSearchQuery")
    b.verdadeiro(n <= b.__n15 + 1, "no maximo a consulta que ja estava em voo (" .. n .. " contra " .. b.__n15 .. ")")
    b.igual(b.ns.varredura.estado().fase, "PARADO", "varredura parada")
    b.igual(b.ns.pedidos.estado().fase, "PARADO", "pedidos parado")
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
