-- Caca (secao 13.3): busca sem resposta. Antes de 2 s o aperto nao faz nada; depois, o aperto descarta a busca parada
-- e manda outra; sem aperto, a busca da caca desiste em 3 s (nao em 6).
return {
  id = "compra-21", grupo = "compra",
  descricao = "caca: busca parada se refaz no aperto depois de 2 s; sozinha desiste em 3 s; tempo de resposta no painel",
  inicio = {
    dinheiro = 100000,
    itens = {
      [4304] = { nome = "Thick Leather", vend = 70, pilha = 20 },
    },
    mercado = {
      ["4304"] = { { id = 9301, preco = 500, qtd = 50 }, { id = 9302, preco = 656, qtd = 100 } },
    },
  },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b) SlashCmdList.COMPRAFOREVER("hunt 4304 5s20c 10g") end },
    { injetar = { "sem_eco", 1 } },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(b.contar("SendSearchQuery"), 1, "uma busca, sem resposta")
      b.igual(CompraForeverAcao:GetText(), "Hunting Thick Leather...", "esperando")
      b.falso(CompraForeverAcao:IsEnabled(), "antes de 2 s o aperto nao faz nada")
    end },
    { avancar = 1.5 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Hunting Thick Leather... (press to retry)", "parada: aperto refaz")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "habilitado para refazer")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(b.contar("SendSearchQuery"), 2, "busca nova no aperto")
      b.igual(CompraForeverAcao:GetText(), "Buy 50 Thick Leather (2g 50s) [HUNT]", "a busca nova respondeu")
      local ok = false
      for _, r in ipairs({ CompraForeverPainel:GetRegions() }) do
        local t = r:GetText()
        if t and string.find(t, "Searches 2 | lost 0 | resp ", 1, true) then ok = true end
      end
      b.verdadeiro(ok, "tempo de resposta no painel")
      b.verdadeiro(b.ns.caca.resposta ~= nil and b.ns.caca.resposta < 2, "resposta medida: " .. tostring(b.ns.caca.resposta))
    end },
    -- sem aperto: a busca parada desiste sozinha em 3 s
    { chamar = function(b) SlashCmdList.COMPRAFOREVER("hunt 4304 5s20c 10g") end },
    { injetar = { "sem_eco", 1 } },
    { clique = "CompraForeverAcao" },
    { avancar = 3.5 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Hunt Thick Leather <= 5s 20c", "desistiu em 3 s e voltou a buscar no aperto")
      b.verdadeiro(b.ns.caca.buscando == false, "nao esta mais buscando")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
