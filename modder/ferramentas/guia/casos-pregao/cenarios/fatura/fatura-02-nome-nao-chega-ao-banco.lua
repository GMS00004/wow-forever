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
  id = "fatura-02", grupo = "fatura",
  descricao = "fatura com nome de jogador, remetente e assunto: nenhum deles chega ao banco, ao log nem ao arquivo salvo",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000,
    correio = {
      { remetente = "Auction House", assunto = "Auction successful: Linen Cloth", dinheiro = 980,
        fatura = { tipo = "seller", item = "Linen Cloth", jogador = "Compradorsecreto", lance = 1000, compra = 1000,
                   deposito = 30, corte = 50, atraso = 3600, hora = 22, min = 15, qtd = 20, comercio = true } },
      { remetente = "Auction House", assunto = "Auction won: Linen Cloth", dinheiro = 0,
        fatura = { tipo = "buyer", item = "Linen Cloth", jogador = "Vendedorsecreto", lance = 90, compra = 90, qtd = 5,
                   comercio = true } },
      { remetente = "Fulanoremetente", assunto = "assuntosecreto", dinheiro = 100, texto = "corpo da carta" },
    },
  },
  passos = {
    { chamar = function(b) __bancada.A.correio[2].anexo = { itemID = 2589, qtd = 5 }; __bancada.A.correio[2].itens = 1 end },
    { evento = { "MAIL_SHOW" } },
    { evento = { "MAIL_INBOX_UPDATE" } },
    { ate_ocioso = true },
    { chamar = function(b) b.__painel = b.ns.correio.painel() end },
    { reload = true },
  },
  conferir = function(b)
    local p = persDe(b)
    local cor = linhasDe(p.correio)
    b.igual(#cor, 2, "so as duas cartas de leilao viram fatura")
    local tipos = { partes(cor[1])[4], partes(cor[2])[4] }
    table.sort(tipos)
    b.igual(tipos, { "buyer", "seller" }, "tipos gravados")
    for i = 1, 2 do
      if partes(cor[i])[4] == "buyer" then b.igual(partes(cor[i])[5], "2589", "compra: chave pelo anexo") end
    end
    b.igual(b.__painel.nFaturas, 2, "o painel conta as duas faturas")
    local texto = __bancada.serializarSV()
    for _, nome in ipairs({ "Compradorsecreto", "Vendedorsecreto", "Fulanoremetente", "assuntosecreto", "corpo da carta" }) do
      b.falso(string.find(texto, nome, 1, true) ~= nil, "o texto " .. nome .. " nao esta nas SavedVariables")
    end
    for _, linha in ipairs(b.ns.registro:itens()) do
      b.falso(string.find(linha, "secreto", 1, true) ~= nil or string.find(linha, "Fulano", 1, true) ~= nil, "nem no log")
    end
    b.igual(b.contar("GetInboxText"), 0, "nenhuma carta foi aberta")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
