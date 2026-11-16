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
  id = "livro-13", grupo = "unid-livro",
  descricao = "conciliacao do correio: o ouro que sai da carta de venda bate com a variacao do dinheiro; com sobra, UNEXPLAINED",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000,
    correio = {
      { remetente = "Auction House", assunto = "Auction successful: Linen Cloth", dinheiro = 980,
        fatura = { tipo = "seller", item = "Linen Cloth", jogador = "Compradorx", lance = 1000, compra = 1000, deposito = 30,
                   corte = 50, atraso = 3600, hora = 22, min = 15, qtd = 20, comercio = true } },
    },
  },
  aceita_erros = true,
  passos = {
    { chamar = function(b) preparar(b, { ["2589"] = "Linen Cloth" }) end },
    { evento = { "MAIL_SHOW" } },
    { chamar = function(b) b.__pend = b.ns.correio.painel().ouro; b.__banca = b.ns.cofre.banca() end },
    { chamar = function(b) __bancada.A.correio[1].dinheiro = 0 end },
    { injetar = { "dinheiro_muda", 980 } },
    { evento = { "MAIL_INBOX_UPDATE" } },
    { chamar = function(b) b.__r1 = b.ns.cofre.conciliar("correio") end },
    { injetar = { "dinheiro_muda", 7 } },
    { chamar = function(b) b.__r2 = b.ns.cofre.conciliar("correio") end },
  },
  conferir = function(b)
    semErrosMeus(b)
    b.igual(b.__pend, 980, "ouro a caminho no painel")
    b.igual(b.__banca.correio, 980, "banca soma o correio")
    b.igual(b.__banca.B, 40980, "B com o correio")
    b.igual(b.__r1.texto, "RECONCILED 1 of 1", "bateu")
    b.igual(b.__r1.ok, true, "ok")
    b.igual(b.__r2.texto, "UNEXPLAINED 7c", "7 cobre a mais")
    b.igual(b.ns.cofre.disjuntores(), {}, "7 cobre esta abaixo de 1%")
    b.igual(#b.__pers.fora, 0, "dentro da janela do correio nao e Fora")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
