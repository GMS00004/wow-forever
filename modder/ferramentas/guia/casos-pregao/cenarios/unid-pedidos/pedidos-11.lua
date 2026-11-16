-- FOCO: resposta sem a frente pede ate 2 paginas na mesma chave e grava a foto com frente.
local function falsos(b)
  local ns = b.ns
  b.__casa, b.__pers, b.__resumos, b.__gravadas = {}, {}, {}, {}
  ns.banco.casa = function() return b.__casa end
  ns.banco.pers = function() return b.__pers end
  ns.banco.cod = { resumo = function(t) b.__resumos[#b.__resumos + 1] = t return t end, proprio = function(t) return t end }
  ns.escada.fotoC = function(id)
    -- a frente so existe quando a escada esta inteira (nao ha linhas ocultas)
    local inteira = C_AuctionHouse.HasFullCommoditySearchResults(id)
    return { id = id, marcas = inteira and "FE" or "E" }
  end
  ns.escada.fotoI = function(k) return { id = k.itemID, marcas = "FE" } end
  ns.escada.gravar = function(chave, foto) b.__gravadas[#b.__gravadas + 1] = chave .. ":" .. foto.marcas end
  ns.cofre.conciliar = function() end
end
return {
  id = "pedidos-11", grupo = "unid-pedidos",
  descricao = "busca sem a frente: uma pagina a mais, e a foto com frente e gravada",
  inicio = { mercado = { ["2589"] = { { preco = 9, qtd = 14 }, { preco = 10, qtd = 5 }, { preco = 11, qtd = 5 }, { preco = 12, qtd = 5 } } } },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b)
        falsos(b)
        b.ns.cfg.foco.vigilia = { "2589" }
      end },
    { injetar = "busca_sem_frente" },
    { chamar = function(b)
        __bancada.ultimaTecla = __bancada.agoraUs()
        b.ns.pedidos.tecla()
        b.__r = b.ns.varredura.tecla()
      end },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(b.__r, true, "tecla abriu")
    b.igual(b.contar("SendSearchQuery"), 1, "uma busca")
    b.igual(b.contar("RequestMoreCommoditySearchResults"), 1, "uma pagina a mais para achar a frente")
    b.igual(b.__gravadas, { "2589:FE" }, "so a foto com frente foi gravada")
    b.igual(b.ns.pedidos.estado().buscas, 2, "as duas contam em max_buscas")
    b.igual(b.ns.varredura.estado().feitas, 1, "uma chave feita")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
