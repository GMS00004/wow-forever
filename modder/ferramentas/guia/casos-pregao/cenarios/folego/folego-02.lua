-- Ponta a ponta: o folego para em max_buscas e uma consulta por vez.
local mercado = {}
local ids = { 2589, 2592, 4306, 2318, 2319 }
local precos = { 9, 30, 100, 10, 40 }
for i = 1, #ids do mercado[tostring(ids[i])] = { { preco = precos[i], qtd = 10 + i, donos = 2 } } end
return {
  id = "folego-02", grupo = "folego",
  descricao = "max_buscas = 3 com cinco chaves de piso: tres buscas, uma em voo por vez, sem violacao",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000, mercado = mercado },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b) b.ns.cfg.folego.max_buscas = 3 end },
    { tecla = "L" },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(b.contar("SendSearchQuery"), 3, "tres buscas, nem uma a mais")
    b.igual(b.ns.pedidos.estado().buscas, 3, "tres contadas")
    b.igual(b.ns.varredura.estado().fase, "PARADO", "parado no fim")
    local env = b.eventos("AUCTION_HOUSE_THROTTLED_MESSAGE_SENT")
    local resp = b.eventos("AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED")
    b.igual(#env, #resp, "toda mensagem enviada foi respondida: nunca duas em voo")
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
