-- Ajudas de leitura do banco depois do reload (la os aneis ja sao linhas de texto da gramatica, secao 4).
local function partes(linha)
  local r = {}
  for p in string.gmatch(linha .. "|", "([^|]*)|") do r[#r + 1] = p end
  return r
end

local function linhasDe(x)
  local r = {}
  if type(x) == "table" then
    for i = 1, #x do r[#r + 1] = x[i] end
  end
  return r
end

local function persDe(b)
  return b.db().pers["Hexumlite"]
end

local FATURA = { tipo = "seller", item = "Linen Cloth", jogador = "Compradorsecreto", lance = 1000, compra = 1000, deposito = 30,
                 corte = 50, atraso = 3600, hora = 22, min = 15, qtd = 20, comercio = true }

return {
  id = "fatura-01", grupo = "fatura",
  descricao = "venda pelo correio: leilao criado por fora, fatura de venda, ouro recolhido, conciliacao fecha e o lote vira vendido",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000,
    proprios = { { id = 1001, itemID = 2589, qtd = 20, preco = 180 } },
    correio = { { remetente = "Auction House", assunto = "Auction successful: Linen Cloth", dinheiro = 980, fatura = FATURA } },
  },
  passos = {
    { abrir_leilao = true },
    { injetar = { "dinheiro_muda", -30 } },
    { evento = { "AUCTION_HOUSE_AUCTION_CREATED", 1001 } },
    { evento = { "OWNED_AUCTIONS_UPDATED" } },
    { ate_ocioso = true },
    { fechar_leilao = true },
    { evento = { "MAIL_SHOW" } },
    { evento = { "MAIL_INBOX_UPDATE" } },
    { ate_ocioso = true },
    { chamar = function(b)
        b.__pend = b.ns.correio.painel().ouro
        __bancada.A.correio[1].dinheiro = 0
      end },
    { injetar = { "dinheiro_muda", 980 } },
    { evento = { "MAIL_INBOX_UPDATE" } },
    { ate_ocioso = true },
    { chamar = function(b) b.__r = b.ns.cofre.conciliar("correio") end },
    { evento = { "MAIL_CLOSED" } },
    { ate_ocioso = true },
    { chamar = function(b) b.__disj = b.ns.cofre.disjuntores() end },
    { reload = true },
  },
  conferir = function(b)
    b.igual(b.__pend, 980, "o painel mostra o ouro a caminho antes de recolher")
    b.igual(b.__r.texto, "RECONCILED 1 of 1", "a conciliacao do correio fecha")
    b.igual(b.__disj, {}, "nenhum disjuntor")
    local p = persDe(b)
    local cor = linhasDe(p.correio)
    b.igual(#cor, 1, "uma fatura no anel do correio")
    local f = partes(cor[1])
    b.igual(f[1], "1", "versao")
    b.igual(f[4], "seller", "tipo")
    b.igual(f[5], "2589", "chave resolvida pelo lote aberto")
    b.igual(f[6], "1000", "bid")
    b.igual(f[8], "30", "deposit")
    b.igual(f[9], "50", "consignment")
    b.igual(f[13], "20", "count")
    local liv = linhasDe(p.livro)
    b.igual(#liv, 1, "uma acao de fora no livro")
    b.igual(partes(liv[1])[4], "post", "verbo")
    b.igual(partes(liv[1])[9], "outside", "origem")
    local lotes = linhasDe(p.lotes)
    b.igual(#lotes, 1, "um lote fechado")
    b.igual(partes(lotes[1])[8], "vendido", "lote vendido pela fatura")
    b.igual(partes(lotes[1])[10], "950", "resultado: bid menos corte")
    b.igual(#linhasDe(p.fora), 0, "o ouro recolhido dentro da janela do correio nao e Fora")
    b.igual(b.contar("GetInboxText"), 0, "nenhuma carta foi aberta")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
