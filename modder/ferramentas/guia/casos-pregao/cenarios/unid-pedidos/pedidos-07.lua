-- Dois AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED encerram o folego; um so perde a consulta em voo.
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
return {
  id = "pedidos-07", grupo = "unid-pedidos",
  descricao = "mensagem_descartada duas vezes: o folego acaba; so uma: a varredura segue para a proxima consulta",
  inicio = { mercado = { ["2589"] = { { preco = 9, qtd = 14 } }, ["2592"] = { { preco = 30, qtd = 5 } } } },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b) falsos(b) end },
    -- primeiro folego: um descarte so
    { injetar = { "mensagem_descartada", 1 } },
    { chamar = function(b)
        __bancada.ultimaTecla = __bancada.agoraUs()
        b.ns.pedidos.tecla()
        b.__a = b.ns.varredura.tecla()
      end },
    { ate_ocioso = true },
    { chamar = function(b)
        b.__fase1 = b.ns.pedidos.estado()
        b.__browse1 = b.contar("SendBrowseQuery")
        b.__busca1 = b.contar("SendSearchQuery")
        b.__vfase1 = b.ns.varredura.estado()
      end },
    -- segundo folego: dois descartes
    { injetar = { "mensagem_descartada", 2 } },
    { avancar = 70 },
    { chamar = function(b)
        __bancada.ultimaTecla = __bancada.agoraUs()
        b.ns.pedidos.tecla()
        b.__q0 = b.contar("QueryOwnedAuctions")
        b.__b0 = b.contar("SendBrowseQuery")
        b.__s0 = b.contar("SendSearchQuery")
        b.__b = b.ns.varredura.tecla()
      end },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(b.__a, true, "primeiro folego abriu")
    b.igual(b.__browse1 >= 1, true, "depois do descarte a varredura mandou a consulta seguinte")
    b.igual(b.__busca1 >= 1, true, "e chegou ate as buscas")
    b.igual(b.__fase1.motivo, "fim", "um descarte nao encerra: o folego acabou pela lista")
    b.igual(b.__vfase1.fase, "PARADO", "varredura parada no fim")
    b.igual(b.__b, true, "segundo folego abriu")
    local est = b.ns.pedidos.estado()
    b.igual(est.fase, "PARADO", "dois descartes: PARADO")
    b.igual(est.motivo, "descartada", "motivo: descartada")
    b.igual(b.contar("QueryOwnedAuctions") - b.__q0, 1, "no segundo folego: a consulta dos proprios")
    b.igual(b.contar("SendBrowseQuery") - b.__b0, 0, "resumo ainda novo: nao pede")
    b.igual(b.contar("SendSearchQuery") - b.__s0, 1, "so a primeira busca; a segunda chave nao sai depois dos dois descartes")
    b.igual(b.ns.varredura.estado().fase, "PARADO", "varredura parada")
    b.igual(#b.eventos("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED"), 3, "tres descartes no total")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
