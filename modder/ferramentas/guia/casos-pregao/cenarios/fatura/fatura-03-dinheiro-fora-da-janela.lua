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
  id = "fatura-03", grupo = "fatura",
  descricao = "dinheiro que muda fora da janela vira Fora; o que muda dentro do leilao sem linha que o explique liga o disjuntor",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000 },
  passos = {
    { avancar = 5 },
    { injetar = { "dinheiro_muda", 1240 } },
    { abrir_leilao = true },
    { injetar = { "dinheiro_muda", -500 } },
    { ate_ocioso = true },
    { chamar = function(b) b.__r = b.ns.cofre.conciliar("leilao") end },
    { fechar_leilao = true },
    { ate_ocioso = true },
    { chamar = function(b) b.__disj = b.ns.cofre.disjuntores() end },
    { reload = true },
  },
  conferir = function(b)
    b.igual(b.__r.texto, "UNEXPLAINED 5s", "o desvio dentro da janela")
    b.igual(b.__disj, { "dinheiro_sem_explicacao" }, "500 cobre passa de 1% da banca de 41240")
    local p = persDe(b)
    local fora = linhasDe(p.fora)
    b.igual(#fora, 1, "so a variacao de fora da janela vira Fora")
    local f = partes(fora[1])
    b.igual(f[4], "1240", "variacao")
    b.igual(f[5], "play", "janela")
    b.verdadeiro(string.find(p.cofre.disjuntores.dinheiro_sem_explicacao, "^1|desvio|%d+|%d+$") ~= nil, "disjuntor gravado no cofre do personagem")
    local ses = linhasDe(b.db().sessoes)
    b.igual(#ses, 1, "a sessao fechada no reload")
    b.igual(partes(ses[1])[7], "1240", "fora da sessao")
    b.igual(b.ns.modo(), "leitura", "continua em leitura")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
