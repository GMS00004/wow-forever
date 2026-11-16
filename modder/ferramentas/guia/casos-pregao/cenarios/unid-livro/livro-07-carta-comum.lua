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
  id = "livro-07", grupo = "unid-livro",
  descricao = "carta que nao e de leilao e ignorada: nada gravado, nem remetente nem assunto",
  inicio = {
    personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000,
    correio = {
      { remetente = "Fulano", assunto = "oi, tudo bem", dinheiro = 500, texto = "ola" },
      { remetente = "Beltrano", assunto = "dica" },
    },
  },
  aceita_erros = true,
  passos = {
    { chamar = function(b) preparar(b) end },
    { evento = { "MAIL_SHOW" } },
    { ate_ocioso = true },
  },
  conferir = function(b)
    semErrosMeus(b)
    local p = b.__pers
    b.igual(#p.correio, 0, "nenhuma fatura")
    local pn = b.ns.correio.painel()
    b.igual(pn.mostradas, 2, "duas cartas mostradas")
    b.igual(pn.nFaturas, 0, "nenhuma de leilao")
    b.igual(pn.maisCartas, false, "sem mais cartas")
    b.falso(contem(b.__pers, "Fulano"), "remetente fora do banco")
    b.falso(contem(b.__pers, "oi, tudo"), "assunto fora do banco")
    b.igual(b.contar("GetInboxText"), 0, "carta nao aberta")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
