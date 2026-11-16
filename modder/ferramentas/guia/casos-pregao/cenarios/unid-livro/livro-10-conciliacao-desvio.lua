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
  id = "livro-10", grupo = "unid-livro",
  descricao = "desvio acima de 1% da banca: UNEXPLAINED e o disjuntor de dinheiro sem explicacao em pers().cofre",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000 },
  aceita_erros = true,
  passos = {
    { chamar = function(b) preparar(b) end },
    { abrir_leilao = true },
    { injetar = { "dinheiro_muda", -4000 } },
    { chamar = function(b)
        b.__r = b.ns.cofre.conciliar("leilao")
        b.__aut = { b.ns.cofre.autoriza({}) }
      end },
  },
  conferir = function(b)
    semErrosMeus(b)
    b.igual(b.__r.ok, false, "nao fechou")
    b.igual(b.__r.texto, "UNEXPLAINED 40s", "texto do desvio")
    b.igual(b.ns.cofre.disjuntores(), { "dinheiro_sem_explicacao" }, "disjuntor ligado")
    local d = b.__pers.cofre.disjuntores.dinheiro_sem_explicacao
    b.verdadeiro(string.find(d, "^1|desvio|%d+|%d+$") ~= nil, "gravado em pers().cofre com gatilho, hora e seq")
    b.igual(b.__aut, { false, "READ ONLY" }, "autoriza nega em leitura")
    b.igual(#b.__pers.fora, 0, "dentro da janela nao e Fora")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
