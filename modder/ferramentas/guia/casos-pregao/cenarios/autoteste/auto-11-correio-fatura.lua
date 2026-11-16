-- Correio: GetInboxNumItems com 2 retornos, cabecalho com wasRead/textCreated, fatura com os 12 retornos.
return {
  id = "auto-11", grupo = "autoteste",
  descricao = "correio com fatura devolve os 12 retornos; GetInboxText marca a carta como lida",
  inicio = {
    correio = {
      { remetente = "Auction House", assunto = "Auction successful: Linen Cloth", dinheiro = 0, itens = 0,
        fatura = { tipo = "seller", item = "Linen Cloth", jogador = "Compradorx", lance = 1000, compra = 1000, deposito = 30,
                   corte = 50, atraso = 3600, hora = 22, min = 15, qtd = 20, comercio = true } },
      { remetente = "Fulano", assunto = "oi", texto = "ola", dinheiro = 0 },
    },
  },
  passos = {
    { evento = { "MAIL_SHOW" } },
  },
  conferir = function(b)
    local mostradas, total = GetInboxNumItems()
    b.igual(mostradas, 2, "cartas mostradas")
    b.igual(total, 2, "cartas no total")
    b.igual(select("#", GetInboxNumItems()), 2, "dois retornos")

    local cab = { GetInboxHeaderInfo(1) }
    b.igual(select("#", GetInboxHeaderInfo(1)), 13, "o cabecalho tem 13 retornos")
    b.igual(cab[4], "Auction successful: Linen Cloth", "assunto")
    b.igual(cab[9], false, "wasRead antes")
    b.igual(cab[11], false, "textCreated antes")

    local f = { GetInboxInvoiceInfo(1) }
    b.igual(select("#", GetInboxInvoiceInfo(1)), 12, "a fatura tem 12 retornos")
    b.igual(f, { "seller", "Linen Cloth", "Compradorx", 1000, 1000, 30, 50, 3600, 22, 15, 20, true }, "os 12 valores, na ordem")
    local _, n = b.ns.brinquedo.fatura(1)
    b.igual(n, 12, "o addon leu 12 retornos")

    b.verdadeiro(GetInboxInvoiceInfo(2) == nil, "carta comum nao tem fatura")
    local texto, _, _, isInvoice = GetInboxText(1)
    b.igual(isInvoice, true, "GetInboxText diz que e fatura")
    b.igual(select(4, GetInboxText(2)), false, "carta comum nao e fatura")
    b.igual(texto, "", "sem texto")
    local depois = { GetInboxHeaderInfo(1) }
    b.igual(depois[9], true, "wasRead depois de GetInboxText")
    b.igual(depois[11], true, "textCreated depois de GetInboxText")
    b.igual(#b.chamadas("GetInboxInvoiceInfo") >= 4, true, "as chamadas ficam registradas com os argumentos")
    b.igual(b.chamadas("GetInboxInvoiceInfo")[1].args[1], 1, "argumento da primeira chamada")
    b.igual(b.ns.brinquedo.log[#b.ns.brinquedo.log].nome, "MAIL_SHOW", "o addon recebeu MAIL_SHOW")
  end,
}
