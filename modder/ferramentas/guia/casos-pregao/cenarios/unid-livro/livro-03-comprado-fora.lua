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
  id = "livro-03", grupo = "unid-livro",
  descricao = "compra de commodity e de item pela tela da Blizzard vira uma linha outside cada e lote em maos",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000 },
  aceita_erros = true,
  passos = {
    { chamar = function(b) preparar(b) end },
    { abrir_leilao = true },
    { injetar = { "dinheiro_muda", -90 } },
    { evento = { "COMMODITY_PURCHASE_SUCCEEDED" } },
    { evento = { "COMMODITY_PURCHASED", 2589, 10 } },
    { injetar = { "dinheiro_muda", -500 } },
    { evento = { "AUCTION_HOUSE_PURCHASE_COMPLETED", 7 } },
    { avancar = 2 },
    { injetar = { "dinheiro_muda", -20 } },
    { evento = { "COMMODITY_PURCHASE_SUCCEEDED" } },
    { ate_ocioso = true },
  },
  conferir = function(b)
    semErrosMeus(b)
    local p = b.__pers
    b.igual(#p.livro, 3, "os dois ecos da commodity viram uma linha; item e eco sem detalhe, uma cada")
    local a = p.livro[1]
    b.igual(a.verbo, "buy", "verbo")
    b.igual(a.chave, "2589", "chave da commodity")
    b.igual(a.qtd, 10, "quantidade")
    b.igual(a.preco, 9, "preco por unidade")
    b.igual(a.antes, 40000, "antes")
    b.igual(a.depois, 39910, "depois")
    b.igual(a.origem, "outside", "origem")
    b.igual(p.livro[2].qtd, 1, "compra de item: uma unidade")
    b.igual(p.livro[2].preco, 500, "preco do item pelo dinheiro")
    b.igual(p.livro[3].preco, 20, "eco de commodity sem detalhe vira linha pelo prazo")
    b.igual(#p.abertos, 3, "tres lotes")
    b.igual(p.abertos[1].origem, "comprado", "origem comprado")
    b.igual(p.abertos[1].estado, "maos", "em maos")
    b.igual(p.abertos[1].custo, 90, "custo pago")
    b.igual(b.ns.livro.sessao().acoes.outside, 3, "sessao")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
