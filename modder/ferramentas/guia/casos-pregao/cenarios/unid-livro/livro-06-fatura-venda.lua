-- Falsos do banco e dos itens (outras tarefas escrevem os de verdade): aneis em memoria, cod e dec que copiam a tabela.
local function preparar(b, nomes)
  local ns = b.ns
  local bk = ns.banco
  local seq = 100
  local pers = { livro = {}, lotes = {}, abertos = {}, correio = {}, fora = {}, cofre = {} }
  b.__pers = pers
  b.__sessoes = {}
  local aneis = { livro = pers.livro, lotes = pers.lotes, correio = pers.correio, fora = pers.fora, sessoes = b.__sessoes }
  bk.seq = function() seq = seq + 1 return seq end
  bk.pers = function() return pers end
  bk.gravar = function(anel, linha) local a = aneis[anel]; a[#a + 1] = linha end
  local copia = function(t) local c = {} for k, v in pairs(t) do c[k] = v end return c end
  bk.cod = setmetatable({}, { __index = function() return copia end })
  bk.dec = setmetatable({}, { __index = function() return copia end })
  ns.itens = ns.itens or {}
  ns.itens.info = function(chave) return { nome = (nomes or {})[chave] } end
end

-- procura um texto em qualquer parte de uma tabela (chaves e valores)
local function contem(v, texto, vistos)
  vistos = vistos or {}
  if type(v) == "string" then return string.find(v, texto, 1, true) ~= nil end
  if type(v) ~= "table" or vistos[v] then return false end
  vistos[v] = true
  for k, x in pairs(v) do
    if contem(k, texto, vistos) or contem(x, texto, vistos) then return true end
  end
  return false
end

-- o Banco do esqueleto da onda 1 quebra o ADDON_LOADED; o que nao pode haver e erro nos quatro arquivos desta tarefa
local function semErrosMeus(b)
  local ruins = {}
  for _, e in ipairs(b.erros()) do
    local s = tostring(e)
    if string.find(s, "Livro.lua", 1, true) or string.find(s, "Ecos.lua", 1, true) or string.find(s, "Cofre.lua", 1, true)
      or string.find(s, "Correio.lua", 1, true) then
      ruins[#ruins + 1] = s
    end
  end
  b.igual(ruins, {}, "nenhum erro nos arquivos Livro, Ecos, Cofre e Correio")
end

return {
  id = "livro-06", grupo = "unid-livro",
  descricao = "fatura de venda gravada com bid, deposit e consignment, sem nenhum nome, sem abrir a carta; fecha o lote",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000,
    correio = {
      { remetente = "Auction House", assunto = "Auction successful: Linen Cloth", dinheiro = 980, itens = 0,
        fatura = { tipo = "seller", item = "Linen Cloth", jogador = "Compradorx", lance = 1000, compra = 1000, deposito = 30,
                   corte = 50, atraso = 3600, hora = 22, min = 15, qtd = 20, comercio = true } },
    },
  },
  aceita_erros = true,
  passos = {
    { chamar = function(b)
        preparar(b, { ["2589"] = "Linen Cloth" })
        b.ns.livro.lote({ chave = "2589", qtd = 20, custo = 0, origem = "coletado", estado = "postado" })
      end },
    { evento = { "MAIL_SHOW" } },
    { evento = { "MAIL_INBOX_UPDATE" } },
    { ate_ocioso = true },
  },
  conferir = function(b)
    semErrosMeus(b)
    local p = b.__pers
    b.igual(#p.correio, 1, "uma fatura, mesmo com duas leituras da caixa")
    local f = p.correio[1]
    b.igual(f.tipo, "seller", "tipo")
    b.igual(f.chave, "2589", "chave resolvida pelo nome contra os lotes abertos")
    b.igual(f.bid, 1000, "bid")
    b.igual(f.buyout, 1000, "buyout")
    b.igual(f.deposit, 30, "deposit")
    b.igual(f.consignment, 50, "consignment")
    b.igual(f.moneyDelay, 3600, "moneyDelay")
    b.igual(f.etaHour, 22, "etaHour")
    b.igual(f.etaMin, 15, "etaMin")
    b.igual(f.count, 20, "count")
    b.igual(f.commerce, 1, "commerce")
    b.falso(contem(b.__pers, "Compradorx"), "nome do comprador nao esta em lugar nenhum do banco")
    b.falso(contem(b.__pers, "Auction House"), "remetente nao esta no banco")
    b.falso(contem(b.__pers, "Linen Cloth"), "nome do item nao esta no banco")
    b.falso(contem(b.__pers, "successful"), "assunto nao esta no banco")
    b.igual(b.contar("GetInboxText"), 0, "a carta nunca foi aberta")
    b.igual(#p.abertos, 0, "lote fechado")
    b.igual(#p.lotes, 1, "um lote no anel de fechados")
    b.igual(p.lotes[1].estado, "vendido", "vendido")
    b.igual(p.lotes[1].resultado, 950, "bid menos corte menos custo")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
