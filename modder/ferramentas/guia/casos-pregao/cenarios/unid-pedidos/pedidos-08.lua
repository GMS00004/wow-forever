-- De quem e a resposta: outra chave, atualizacao de leilao e lista do resumo fora do RESUMO sao ignoradas.
local function tecla(b)
  __bancada.ultimaTecla = __bancada.agoraUs()
  b.ns.pedidos.tecla()
end
return {
  id = "pedidos-08", grupo = "unid-pedidos",
  descricao = "resposta de outra chave nao fecha a espera (so o prazo fecha); BROWSE_RESULTS_UPDATED fora do RESUMO nao le a lista",
  inicio = { mercado = { ["2589"] = { { preco = 9, qtd = 14 } }, ["2592"] = { { preco = 30, qtd = 5 } } } },
  passos = {
    { abrir_leilao = true },
    { injetar = "busca_outra_chave" },
    { chamar = function(b)
        local ns = b.ns
        tecla(b)
        ns.pedidos.abrirFolego(function() end)
        b.__log = {}
        ns.pedidos.enviar({ tipo = "busca", chave = "2589", sorts = {},
          aoResponder = function() b.__log[#b.__log + 1] = "resp" end,
          aoFalhar = function(m) b.__log[#b.__log + 1] = "falha:" .. m end })
      end },
    { avancar = 5 },
    { chamar = function(b)
        b.__aos5 = #b.__log
        b.__voo5 = b.ns.pedidos.estado().emVoo
      end },
    -- eventos de outra chave e de atualizacao de leilao, na mao
    { evento = { "COMMODITY_SEARCH_RESULTS_UPDATED", 2592 } },
    { evento = { "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" } },
    { evento = { "AUCTION_HOUSE_BROWSE_RESULTS_ADDED", {} } },
    { evento = { "OWNED_AUCTIONS_UPDATED" } },
    { evento = { "ITEM_SEARCH_RESULTS_UPDATED", { itemID = 2589, itemLevel = 0, itemSuffix = 0 }, 77 } },
    { chamar = function(b) b.__aosEv = #b.__log end },
    { avancar = 7 },
    -- agora uma resposta certa; o falso dispara o UPDATED espurio do resumo junto
    { chamar = function(b)
        local ns = b.ns
        tecla(b)
        ns.pedidos.abrirFolego(function() end)
        ns.pedidos.enviar({ tipo = "busca", chave = "2592", sorts = {},
          aoResponder = function() b.__log[#b.__log + 1] = "resp2592" end,
          aoFalhar = function(m) b.__log[#b.__log + 1] = "falha2:" .. m end })
      end },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(b.__aos5, 0, "aos 5 s a resposta de outra chave nao fechou a espera")
    b.igual(b.__voo5, true, "ainda em voo")
    b.igual(b.__aosEv, 0, "eventos alheios nao fecharam")
    b.igual(b.__log[1], "falha:prazo", "o prazo de 10 s fechou: falha")
    b.igual(b.__log[2], "resp2592", "a resposta certa da chave seguinte fechou")
    b.igual(#b.__log, 2, "so isso")
    b.igual(b.contar("GetBrowseResults"), 0, "a lista do resumo nunca foi lida fora do RESUMO")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
