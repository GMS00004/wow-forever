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
  id = "livro-04", grupo = "unid-livro",
  descricao = "PLAYER_MONEY com todas as janelas fechadas vira linha Fora; depois de fechar o leilao tambem",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000 },
  aceita_erros = true,
  passos = {
    { chamar = function(b) preparar(b) end },
    { avancar = 1 },
    { injetar = { "dinheiro_muda", 1240 } },
    { injetar = { "dinheiro_muda", -40 } },
    { abrir_leilao = true },
    { fechar_leilao = true },
    { injetar = { "dinheiro_muda", 300 } },
    { ate_ocioso = true },
  },
  conferir = function(b)
    semErrosMeus(b)
    local f = b.__pers.fora
    b.igual(#f, 3, "tres variacoes fora de janela")
    b.igual(f[1].variacao, 1240, "primeira")
    b.igual(f[1].janela, "play", "dentro da sessao")
    b.igual(f[2].variacao, -40, "segunda")
    b.igual(f[3].variacao, 300, "depois de fechar o leilao")
    b.igual(b.ns.livro.sessao().fora, 1500, "soma na sessao")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
