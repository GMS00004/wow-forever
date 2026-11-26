-- Caca (secao 13.4): tempo da cotacao, tempo da compra (aperto de confirmar ate a resposta) e a fila do cliente
-- amostrada a 0,5 s e a 1 s com a compra pendente; painel e registro dos ultimos 100 na SV, em ms.
local function linha(trecho)
  for _, r in ipairs({ CompraForeverPainel:GetRegions() }) do
    local t = r:GetText()
    if t and string.find(t, trecho, 1, true) then return t end
  end
  return nil
end

return {
  id = "compra-22", grupo = "compra",
  descricao = "caca: tempos de cotacao e compra e a fila durante a compra, no painel e em CompraForeverCharDB.caca.tempos",
  inicio = {
    dinheiro = 100000,
    itens = {
      [4304] = { nome = "Thick Leather", vend = 70, pilha = 20 },
    },
    mercado = {
      ["4304"] = { { id = 9401, preco = 500, qtd = 50 }, { id = 9402, preco = 656, qtd = 100 } },
    },
  },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b)
      __bancada.A.P.t_acao = 1.5   -- servidor lento: a cotacao e a compra levam 1,5 s
      SlashCmdList.COMPRAFOREVER("hunt 4304 5s20c 10g")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { clique = "CompraForeverAcao" },
    { avancar = 2 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Confirm 50 Thick Leather (2g 50s)", "Confirm")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 1.2 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Buying 50 Thick Leather", "compra pendente")
    end },
    { avancar = 1 },
    { chamar = function(b)
      local cc = CompraForeverCharDB.caca
      b.igual(cc.qtd, 50, "comprou")
      b.igual(#cc.tempos, 1, "um registro de tempo")
      local t = cc.tempos[1]
      b.igual(t.res, "ok", "resultado")
      b.igual(t.cota, 1500, "cotacao em 1,5 s")
      b.igual(t.compra, 1500, "compra em 1,5 s")
      b.verdadeiro(t.l05 ~= nil and t.l10 ~= nil, "fila amostrada a 0,5 s e a 1 s")
      local l = linha("Quote 1.5s | buy 1.5s | queue 0.5s ")
      b.verdadeiro(l ~= nil and string.find(l, "1s ", 1, true) ~= nil, "linha de tempos no painel: " .. tostring(l))
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
