-- Leilao fechado zera a fila: com a consulta em voo, e com o pedido esperando o throttle.
local function falsos(b)
  local ns = b.ns
  b.__casa, b.__pers = {}, {}
  ns.banco.casa = function() return b.__casa end
  ns.banco.pers = function() return b.__pers end
  ns.banco.cod = { resumo = function(t) return t end, proprio = function(t) return t end }
  ns.escada.fotoC = function(id) return { id = id, marcas = "FE" } end
  ns.escada.fotoI = function(k) return { id = k.itemID, marcas = "FE" } end
  ns.escada.gravar = function() end
  ns.cofre.conciliar = function() end
end
local function tecla(b)
  __bancada.ultimaTecla = __bancada.agoraUs()
  b.ns.pedidos.tecla()
end
return {
  id = "pedidos-10", grupo = "unid-pedidos",
  descricao = "AUCTION_HOUSE_CLOSED com consulta em voo e com pedido pendente: tudo PARADO e nada mais sai",
  inicio = { mercado = { ["2589"] = { { preco = 9, qtd = 14 } } } },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b) falsos(b) tecla(b) b.ns.varredura.tecla() end },
    { avancar = 0.15 },                      -- a primeira mensagem saiu e ainda nao respondeu
    { chamar = function(b) b.__voo = b.ns.pedidos.estado().emVoo end },
    { fechar_leilao = true },
    { ate_ocioso = true },
    { chamar = function(b)
        b.__p1 = b.ns.pedidos.estado()
        b.__v1 = b.ns.varredura.estado()
        b.__q1 = b.contar("QueryOwnedAuctions")
        b.__t1 = b.contar("SendBrowseQuery") + b.contar("SendSearchQuery")
      end },
    -- pedido pendente: throttle travado, e o leilao fecha antes dos 30 s
    { abrir_leilao = true },
    { injetar = "throttle_travado" },
    { chamar = function(b) tecla(b) b.ns.varredura.tecla() end },
    { avancar = 10 },
    { chamar = function(b) b.__fase10 = b.ns.pedidos.estado().fase end },
    { fechar_leilao = true },
    { abrir_leilao = true },
    { avancar = 60 },
  },
  conferir = function(b)
    b.igual(b.__voo, true, "havia uma consulta em voo")
    b.igual(b.__p1.fase, "PARADO", "fechar: pedidos PARADO")
    b.igual(b.__p1.emVoo, false, "nada em voo")
    b.igual(b.__v1.fase, "PARADO", "fechar: varredura PARADA")
    b.igual(b.__q1, 1, "so a consulta que ja tinha saido")
    b.igual(b.__t1, 0, "nenhuma outra consulta depois do fechamento")
    b.igual(b.__fase10, "ABERTO", "aos 10 s o pedido esperava, ABERTO")
    b.igual(b.contar("QueryOwnedAuctions"), 1, "o pedido pendente nunca saiu: a fila foi zerada")
    b.igual(b.ns.pedidos.estado().fase, "PARADO", "PARADO no fim")
    b.igual(b.ns.faixaLigada("travado"), false, "sem faixa de travado: fechou antes dos 30 s")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
