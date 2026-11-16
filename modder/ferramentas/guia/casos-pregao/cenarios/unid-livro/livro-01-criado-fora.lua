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
  id = "livro-01", grupo = "unid-livro",
  descricao = "leilao criado pela tela da Blizzard vira linha outside e lote postado",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000,
    proprios = { { id = 1001, itemID = 2589, qtd = 20, preco = 180 } },
  },
  aceita_erros = true,
  passos = {
    { chamar = function(b) preparar(b) end },
    { abrir_leilao = true },
    { injetar = { "dinheiro_muda", -30 } },
    { evento = { "AUCTION_HOUSE_AUCTION_CREATED", 1001 } },
    { evento = { "OWNED_AUCTIONS_UPDATED" } },
    { ate_ocioso = true },
  },
  conferir = function(b)
    semErrosMeus(b)
    local p = b.__pers
    b.igual(#p.livro, 1, "uma linha de acao (OWNED_AUCTIONS_UPDATED nao e acao)")
    local a = p.livro[1]
    b.igual(a.verbo, "post", "verbo")
    b.igual(a.origem, "outside", "origem de fora")
    b.igual(a.chave, "2589", "chave resolvida pelo leilao proprio")
    b.igual(a.qtd, 20, "quantidade")
    b.igual(a.preco, 180, "preco")
    b.igual(a.antes, 40000, "dinheiro antes")
    b.igual(a.depois, 39970, "dinheiro depois")
    b.igual(a.eco, "created", "eco")
    b.igual(#p.abertos, 1, "um lote aberto")
    b.igual(p.abertos[1].estado, "postado", "lote postado")
    b.igual(p.abertos[1].origem, "coletado", "origem coletado, custo desconhecido")
    b.igual(p.abertos[1].chave, "2589", "lote da mesma chave")
    b.igual(b.ns.livro.sessao().acoes, { post = 0, buy = 0, cancel = 0, outside = 1 }, "sessao conta outside")
    b.igual(b.ns.livro.intencao({}), nil, "intencao devolve nil na onda 2")
    b.igual(b.ns.ecos.emVoo(), nil, "nenhuma acao do addon em voo")
    b.igual(b.ns.ecos.depositos(), 30, "deposito do leilao ativo")
    b.igual(#p.fora, 0, "dinheiro dentro da janela nao e Fora")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
