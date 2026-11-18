-- Venda: item vigiado com piso (/compra sell); a vigia busca, o botao sugere postar tudo ao menor preco (igualar),
-- um PostCommodity por clique, uma pilha por vez, ate acabar o estoque.
return {
  id = "compra-15", grupo = "compra",
  aceita_violacoes = true,   -- so I9 (busca periodica da vigia por pedido do dono); conferir exige zero das outras
  descricao = "venda: sugestao [SELL] para item vigiado com piso, um PostCommodity por clique, sessao.postado, estoque cai",
  inicio = {
    dinheiro = 100000,
    itens = {
      [4304] = { nome = "Thick Leather", vend = 70, pilha = 40 },
    },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 4304, qtd = 40 },
      { bolsa = 0, slot = 2, itemID = 4304, qtd = 20 },
    },
    sv = { vigia = { itens = { [4304] = { nome = "Thick Leather", teto = 490, qtd = 20 } }, intervalo = 30, historico = {} } },
    mercado = {
      ["4304"] = { { id = 8002, preco = 609, qtd = 100 } },
    },
  },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Nothing to do", "sem piso nao ha sugestao")
      SlashCmdList.COMPRAFOREVER("sell 4304 6s")
      b.igual(CompraForeverDB.vigia.itens[4304].venda, 600, "piso gravado no item vigiado")
    end },
    { avancar = 3 },
    { chamar = function(b)
      local t = CompraForeverAcao:GetText()
      b.igual(t, "Post 40 Thick Leather @ 6s 09c (dep 16s 80c) [SELL]", "texto da sugestao")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
      b.igual(b.contar("PostCommodity"), 0, "nada postado sem clique")
    end },
    { clique = "CompraForeverAcao" },
    { chamar = function(b)
      b.igual(b.contar("PostCommodity"), 1, "um PostCommodity")
      b.igual(b.contar("ConfirmPostCommodity"), 0, "nenhum Confirm")
      b.igual(b.contar("PostItem"), 0, "nenhum PostItem")
      local a = b.chamadas("PostCommodity")[1].args
      b.igual(a[1].bagID, 0, "bolsa 0")
      b.igual(a[1].slotIndex, 1, "slot 1")
      b.igual(a[2], 3, "duracao 3")
      b.igual(a[3], 40, "40 unidades")
      b.igual(a[4], 609, "preco igual ao menor atual")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado enquanto posta")
      b.igual(CompraForeverAcao:GetText(), "Posting Thick Leather", "texto Posting")
    end },
    { avancar = 2 },
    { chamar = function(b)
      local ns = b.ns
      b.igual(ns.sessao.postado[4304], 40, "postado na sessao")
      b.igual(C_Item.GetItemCount(4304), 20, "20 sobram nas bolsas")
      b.verdadeiro(GetMoney() < 100000, "deposito pago")
      b.igual(ns.venda.em, nil, "postagem concluida")
      local t = CompraForeverAcao:GetText()
      b.verdadeiro(string.find(t, "Post 20 Thick Leather @ 6s 09c", 1, true) ~= nil, "proxima pilha: " .. t)
      b.verdadeiro(string.find(t, "[SELL]", 1, true) ~= nil, "etiqueta SELL")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado de novo")
      local achou = false
      for _, r in ipairs({ CompraForeverPainel:GetRegions() }) do
        local x = r:GetText()
        if x and string.find(x, "[x] posted 40 Thick Leather", 1, true) then achou = true end
      end
      b.verdadeiro(achou, "linha posted no painel")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 2 },
    { chamar = function(b)
      b.igual(b.contar("PostCommodity"), 2, "segundo PostCommodity")
      b.igual(b.chamadas("PostCommodity")[2].args[3], 20, "20 unidades")
      b.igual(b.ns.sessao.postado[4304], 60, "60 postadas")
      b.igual(C_Item.GetItemCount(4304), 0, "bolsas vazias")
      b.igual(CompraForeverAcao:GetText(), "Nothing to do", "nada mais")
      b.falso(CompraForeverAcao:IsEnabled(), "botao desabilitado")
    end },
  },
  conferir = function(b)
    local m = {}
    for _, v in ipairs(b.violacoes()) do
      if v.tipo ~= "I9" then m[#m + 1] = v.tipo .. ": " .. v.msg end
    end
    b.igual(#m, 0, "sem violacao I1/hardware: " .. table.concat(m, " / "))
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
