-- Pedidos e Varredura: abrir o leilao nao consulta; nada consulta antes de uma tecla do dono.
local CONSULTAS = { "SendBrowseQuery", "RequestMoreBrowseResults", "SendSearchQuery", "SendSellSearchQuery",
  "RefreshCommoditySearchResults", "RefreshItemSearchResults", "RequestMoreCommoditySearchResults",
  "RequestMoreItemSearchResults", "QueryOwnedAuctions" }
return {
  id = "pedidos-01", grupo = "unid-pedidos",
  descricao = "abrir o leilao e esperar nao consulta; sem tecla nem o folego abre nem o pedido sai",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000,
    mercado = { ["2589"] = { { preco = 9, qtd = 14, donos = 2 } } } },
  passos = {
    { abrir_leilao = true },
    { avancar = 120 },
    { chamar = function(b)
        local ns = b.ns
        b.__sem = { ns.varredura.tecla() }
        b.__abrir = { ns.pedidos.abrirFolego(function() end) }
        b.__env = { ns.pedidos.enviar({ tipo = "busca", chave = "2589" }) }
      end },
    { avancar = 5 },
  },
  conferir = function(b)
    for _, nome in ipairs(CONSULTAS) do
      b.igual(b.contar(nome), 0, "nenhuma consulta: " .. nome)
    end
    b.igual(b.__sem[1], false, "varredura.tecla sem tecla do dono recusa")
    b.igual(b.__sem[2], "sem_tecla", "motivo: sem tecla")
    b.igual(b.__abrir[2], "sem_tecla", "abrirFolego sem tecla recusa")
    b.igual(b.__env[1], false, "enviar fora de folego recusa")
    b.igual(b.__env[2], "sem_folego", "motivo: sem folego")
    b.igual(b.ns.pedidos.estado().fase, "PARADO", "pedidos parado")
    b.igual(b.ns.varredura.estado().fase, "PARADO", "varredura parada")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
