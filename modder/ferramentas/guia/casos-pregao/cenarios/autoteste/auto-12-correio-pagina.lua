-- Correio com mais cartas que a caixa mostra: GetInboxNumItems devolve mostradas e total.
local cartas = {}
for i = 1, 7 do cartas[i] = { remetente = "Alguem", assunto = "carta " .. i } end

return {
  id = "auto-12", grupo = "autoteste",
  descricao = "pagina_correio limita as cartas mostradas e o total continua certo",
  inicio = { parametros = { pagina_correio = 5 }, correio = cartas },
  passos = { { evento = { "MAIL_SHOW" } } },
  conferir = function(b)
    local mostradas, total = GetInboxNumItems()
    b.igual(mostradas, 5, "so 5 mostradas")
    b.igual(total, 7, "7 no total")
    b.verdadeiro(GetInboxHeaderInfo(5) ~= nil, "a quinta existe")
    b.verdadeiro(GetInboxHeaderInfo(6) == nil, "a sexta nao aparece")
  end,
}
