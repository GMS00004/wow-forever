-- Caca (secao 13.2): a confirmacao falha (outro comprou antes): conta a perda e busca de novo na hora, encadeado no
-- clique de confirmar, para o aperto seguinte ja cotar.
local function textos()
  local out = {}
  for _, r in ipairs({ CompraForeverPainel:GetRegions() }) do
    local t = r:GetText()
    if t and t ~= "" then out[#out + 1] = t end
  end
  return out
end
local function tem(b, trecho, msg)
  local lista = textos()
  for _, t in ipairs(lista) do
    if string.find(t, trecho, 1, true) then return end
  end
  b.verdadeiro(false, msg .. " (texto '" .. trecho .. "' nao achado em: " .. table.concat(lista, " | ") .. ")")
end

return {
  id = "compra-20", grupo = "compra",
  descricao = "caca: compra recusada conta lost, busca encadeada e o aperto seguinte ja cota",
  inicio = {
    dinheiro = 100000,
    itens = {
      [4304] = { nome = "Thick Leather", vend = 70, pilha = 20 },
    },
    mercado = {
      ["4304"] = { { id = 9201, preco = 500, qtd = 50 }, { id = 9202, preco = 656, qtd = 100 } },
    },
  },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b) SlashCmdList.COMPRAFOREVER("hunt 4304 5s20c 10g") end },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Buy 50 Thick Leather (2g 50s) [HUNT]", "pilha no alvo")
      tem(b, "Searches 1 | lost 0 | resp ", "contador de buscas")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Confirm 50 Thick Leather (2g 50s)", "Confirm")
    end },
    { injetar = "compra_falha" },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(b.contar("ConfirmCommoditiesPurchase"), 1, "um Confirm")
      b.igual(CompraForeverCharDB.caca.qtd, 0, "nada comprado")
      b.igual(b.contar("SendSearchQuery"), 2, "busca encadeada depois da recusa")
    end },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Buy 50 Thick Leather (2g 50s) [HUNT]", "o aperto seguinte ja cota")
      tem(b, "Searches 2 | lost 1 | resp ", "uma perda contada")
      tem(b, "Someone bought first: hunting again", "mensagem da perda")
    end },
    { clique = "CompraForeverAcao" },
    { chamar = function(b)
      b.igual(b.contar("StartCommoditiesPurchase"), 2, "cotou de novo sem buscar antes")
      b.igual(b.contar("SendSearchQuery"), 2, "sem busca extra")
    end },
    -- o mesmo pelo erro do leilao ("Internal auction error" no jogo) na confirmacao
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Confirm 50 Thick Leather (2g 50s)", "Confirm de novo")
    end },
    { injetar = { "erro_leilao", "DatabaseError" } },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(b.contar("SendSearchQuery"), 3, "busca encadeada depois do erro do leilao")
    end },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Buy 50 Thick Leather (2g 50s) [HUNT]", "o aperto seguinte ja cota de novo")
      tem(b, "Searches 3 | lost 2 | resp ", "duas perdas")
      b.igual(CompraForeverCharDB.caca.qtd, 0, "nada comprado")
    end },
    -- e a compra que da certo
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverCharDB.caca.qtd, 50, "50 compradas")
      b.igual(GetMoney(), 100000 - 25000, "dinheiro")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao (busca no rastro do clique)")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
