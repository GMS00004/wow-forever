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

return {
  id = "fatura-04", grupo = "fatura",
  descricao = "reload preserva livro e correio: a caixa lida de novo depois do reload nao duplica a fatura",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000,
    proprios = { { id = 1001, itemID = 2589, qtd = 20, preco = 180 } },
    correio = {
      { remetente = "Auction House", assunto = "Auction successful: Linen Cloth", dinheiro = 980,
        fatura = { tipo = "seller", item = "Linen Cloth", jogador = "Compradorsecreto", lance = 1000, compra = 1000,
                   deposito = 30, corte = 50, atraso = 3600, hora = 22, min = 15, qtd = 20, comercio = true } },
    },
  },
  passos = {
    { abrir_leilao = true },
    { injetar = { "dinheiro_muda", -30 } },
    { evento = { "AUCTION_HOUSE_AUCTION_CREATED", 1001 } },
    { ate_ocioso = true },
    { fechar_leilao = true },
    { evento = { "MAIL_SHOW" } },
    { evento = { "MAIL_INBOX_UPDATE" } },
    { ate_ocioso = true },
    { evento = { "MAIL_CLOSED" } },
    { reload = true },
    { chamar = function(b)
        local p = persDe(b)
        b.__antes = { #linhasDe(p.livro), #linhasDe(p.correio), #linhasDe(p.lotes) }
      end },
    { evento = { "MAIL_SHOW" } },
    { evento = { "MAIL_INBOX_UPDATE" } },
    { ate_ocioso = true },
    { evento = { "MAIL_CLOSED" } },
    { reload = true },
  },
  conferir = function(b)
    b.igual(b.__antes, { 1, 1, 1 }, "depois do primeiro reload: uma acao, uma fatura, um lote fechado")
    local p = persDe(b)
    b.igual(#linhasDe(p.livro), 1, "livro igual depois do segundo reload")
    b.igual(#linhasDe(p.correio), 1, "a fatura nao foi gravada de novo")
    b.igual(#linhasDe(p.lotes), 1, "lote fechado uma vez so")
    b.igual(#linhasDe(b.db().sessoes), 2, "uma linha de sessao por reload")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
