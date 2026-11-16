-- Injecoes de busca de commodity: browse_falha, sem_resposta, busca_vazia, busca_outra_chave, busca_sem_frente e pagina que chega.
return {
  id = "auto-20", grupo = "autoteste",
  descricao = "browse_falha, sem_resposta, busca_vazia, busca_outra_chave e busca_sem_frente com RequestMore",
  inicio = {
    mercado = { ["2589"] = {
      { preco = 9, qtd = 14 }, { preco = 10, qtd = 20 }, { preco = 11, qtd = 40 }, { preco = 15, qtd = 3 }, { preco = 20, qtd = 8 },
    } },
  },
  passos = {
    { abrir_leilao = true },
    -- 1. browse com falha: BROWSE_FAILURE no lugar do resultado
    { injetar = "browse_falha" },
    { tecla = "L" },
    { ate_ocioso = true },
    { chamar = function(b)
        b.igual(#b.eventos("AUCTION_HOUSE_BROWSE_FAILURE"), 1, "BROWSE_FAILURE")
        b.igual(#b.eventos("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED"), 0, "sem resultado")
        b.igual(#b.eventos("AUCTION_HOUSE_THROTTLED_SYSTEM_READY"), 1, "mas o throttle libera")
      end },
    -- 2. resposta que nao chega
    { injetar = "sem_resposta" },
    { tecla = "C" },
    { ate_ocioso = true },
    { chamar = function(b)
        b.igual(#b.eventos("COMMODITY_SEARCH_RESULTS_UPDATED"), 0, "sem resposta de busca")
        b.igual(#b.eventos("AUCTION_HOUSE_THROTTLED_SYSTEM_READY"), 2, "o throttle libera do mesmo jeito")
        b.igual(C_AuctionHouse.GetNumCommoditySearchResults(2589), 0, "nada para ler")
      end },
    -- 3. resposta vazia onde havia oferta
    { injetar = "busca_vazia" },
    { tecla = "C" },
    { ate_ocioso = true },
    { chamar = function(b)
        b.igual(#b.eventos("COMMODITY_SEARCH_RESULTS_UPDATED"), 1, "o evento vem")
        b.igual(C_AuctionHouse.GetNumCommoditySearchResults(2589), 0, "mas vazio")
      end },
    -- 4. resposta de outra chave
    { injetar = "busca_outra_chave" },
    { tecla = "C" },
    { ate_ocioso = true },
    { chamar = function(b)
        local ev = b.eventos("COMMODITY_SEARCH_RESULTS_UPDATED")
        b.igual(#ev, 2, "mais um evento")
        b.igual(ev[2].args[1], 2590, "com o itemID errado")
      end },
    -- 5. primeira pagina sem a frente; RequestMore a traz
    { injetar = { "busca_sem_frente", 2 } },
    { tecla = "C" },
    { ate_ocioso = true },
    { chamar = function(b)
        b.igual(C_AuctionHouse.GetNumCommoditySearchResults(2589), 3, "faltam os 2 mais baratos")
        b.igual(C_AuctionHouse.GetCommoditySearchResultInfo(2589, 1).unitPrice, 11, "o primeiro visivel e o terceiro")
        b.igual(C_AuctionHouse.HasFullCommoditySearchResults(2589), false, "nao esta completo")
      end },
    { tecla = "N" },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(#b.eventos("COMMODITY_SEARCH_RESULTS_ADDED"), 1, "a pagina a mais chegou")
    b.igual(C_AuctionHouse.GetNumCommoditySearchResults(2589), 5, "agora com tudo")
    b.igual(C_AuctionHouse.GetCommoditySearchResultInfo(2589, 1).unitPrice, 9, "a frente voltou")
    b.verdadeiro(C_AuctionHouse.HasFullCommoditySearchResults(2589), "completo")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
