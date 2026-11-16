-- Nucleo e PregaoForever.lua: carga, eventos, erro isolado, dinheiro, anel, log, fatiador, faixa e bandeira suja.
return {
  id = "nucleo-01", grupo = "unid-nucleo",
  descricao = "Nucleo publica o contrato da secao 3.1 e o ADDON_LOADED marca ns.pronto",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 50912 },
  aceita_erros = true,
  passos = {
    { avancar = 1 },
    { chamar = function(b)
        local ns = b.ns
        b.__ordem = {}
        ns.ao("PREGAO_TESTE", function(ev, a) b.__ordem[#b.__ordem + 1] = "um:" .. tostring(a) end)
        ns.ao("PREGAO_TESTE", function() error("falha de proposito") end)
        ns.ao("PREGAO_TESTE", function(ev, a) b.__ordem[#b.__ordem + 1] = "tres:" .. tostring(a) end)
        b.__fatias = 0
        b.__fim = false
        ns.fatiar(5000, function(i) b.__fatias = b.__fatias + 1 end, function() b.__fim = true end)
        b.__sujas = 0
        ns.aoSujo("tela", function() b.__sujas = b.__sujas + 1 end)
        ns.sujo("tela"); ns.sujo("tela"); ns.sujo("tela")
        ns.marcarFaixa("reconciliar", "Press L to reconcile")
        ns.marcarFaixa("config", "CONFIG ERROR - read only")
        b.__faixa1 = ns.faixa
        ns.marcarFaixa("config", nil)
        b.__faixa2 = ns.faixa
        local a = ns.anel(3)
        for i = 1, 5 do a:por(i) end
        b.__anel = a:itens()
        ns.log("info", "a|b")
      end },
    { evento = { "PREGAO_TESTE", 7 } },
    { ate_ocioso = true },
  },
  conferir = function(b)
    local ns = b.ns
    b.igual(ns.pronto, true, "ADDON_LOADED do addon marcou ns.pronto")
    b.igual(ns.modo(), "leitura", "modo leitura com o Config da onda")
    b.igual(b.__ordem, { "um:7", "tres:7" }, "um tratador com erro nao derruba os outros")
    b.igual(#b.erros() >= 1, true, "o erro de proposito foi ao geterrorhandler")
    b.igual(b.__fatias, 5000, "o fatiador fez todas as linhas")
    b.igual(b.__fim, true, "o fatiador chamou fim")
    b.igual(b.__sujas, 1, "tres ns.sujo no mesmo quadro viram uma chamada")
    b.igual(b.__faixa1, "CONFIG ERROR - read only", "faixa de maior prioridade vence")
    b.igual(b.__faixa2, "Press L to reconcile", "apagar a maior volta para a seguinte")
    b.igual(b.__anel, { 3, 4, 5 }, "anel guarda os mais novos")
    b.igual(ns.dinheiro(50912), "5g 9s 12c", "dinheiro em texto")
    b.igual(ns.dinheiro(0), "0c", "zero")
    b.igual(ns.dinheiro(-205), "-2s 5c", "negativo")
    b.igual(ns.txt(10 / 2), "5", "numero vira texto inteiro")
    b.igual(ns.pers(), "Hexumlite", "personagem")
    b.verdadeiro(string.find(ns.casa(), ":Alliance$") ~= nil, "casa com a faccao")
    b.verdadeiro(string.find(ns.diaRisco(), "^%d%d%d%d%-%d%d%-%d%d$") ~= nil, "dia de risco em AAAA-MM-DD")
    local ult = ns.registro:itens()
    b.verdadeiro(string.find(ult[#ult], "^1|%d+|info|a/b$") ~= nil, "log no formato da gramatica, sem barra no texto")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
