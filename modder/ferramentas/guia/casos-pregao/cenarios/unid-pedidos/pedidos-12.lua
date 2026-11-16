-- RESUMO que falha vira resumo incompleto; a triagem segue e o folego termina.
local function falsos(b)
  local ns = b.ns
  b.__casa, b.__pers, b.__resumos = {}, {}, {}
  ns.banco.casa = function() return b.__casa end
  ns.banco.pers = function() return b.__pers end
  ns.banco.cod = { resumo = function(t) b.__resumos[#b.__resumos + 1] = t return t end, proprio = function(t) return t end }
  ns.escada.fotoC = function(id) return { id = id, marcas = "FE" } end
  ns.escada.fotoI = function(k) return { id = k.itemID, marcas = "FE" } end
  ns.escada.gravar = function() end
  ns.cofre.conciliar = function() end
end
return {
  id = "pedidos-12", grupo = "unid-pedidos",
  descricao = "BROWSE_FAILURE: resumo guardado como incompleto, a varredura termina sem erro",
  inicio = { mercado = { ["2589"] = { { preco = 9, qtd = 14 } } } },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b) falsos(b) end },
    { injetar = "browse_falha" },
    { chamar = function(b)
        __bancada.ultimaTecla = __bancada.agoraUs()
        b.ns.pedidos.tecla()
        b.__r = b.ns.varredura.tecla()
      end },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(b.__r, true, "tecla abriu")
    b.igual(b.contar("SendBrowseQuery"), 1, "um pedido de resumo, que falhou")
    b.igual(b.__resumos[1].completa, false, "resumo guardado como incompleto")
    b.igual(b.__resumos[1].n, 0, "sem linhas")
    b.igual(b.ns.varredura.estado().fase, "PARADO", "fim parado")
    b.igual(b.ns.pedidos.estado().fase, "PARADO", "pedidos parado")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
