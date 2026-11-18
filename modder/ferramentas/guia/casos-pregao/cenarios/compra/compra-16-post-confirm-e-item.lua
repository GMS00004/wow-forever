-- Venda: o cliente pede confirmacao (POST_WARNING): clique 1 posta, clique 2 confirma; item nao empilhavel por PostItem;
-- /compra post auto sem preco visto e recusado; fila por /compra post.
local falas = {}
local function capturar()
  local antigo = print
  falas = {}
  print = function(...)
    local t = {}
    for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end
    falas[#falas + 1] = table.concat(t, " ")
  end
  return function() print = antigo end
end
local function disse(b, trecho, msg)
  for _, f in ipairs(falas) do
    if string.find(f, trecho, 1, true) then return end
  end
  b.verdadeiro(false, msg .. " (nao achei '" .. trecho .. "' em: " .. table.concat(falas, " | ") .. ")")
end

return {
  id = "compra-16", grupo = "compra",
  descricao = "venda: Confirm no clique seguinte, PostItem de item nao empilhavel, auto sem preco recusado, fila",
  inicio = {
    dinheiro = 100000,
    itens = {
      [4304] = { nome = "Thick Leather", vend = 70, pilha = 40 },
      [3000] = { nome = "Plain Sword", vend = 100, pilha = 1 },
    },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 4304, qtd = 40 },
      { bolsa = 0, slot = 2, itemID = 3000, qtd = 1 },
    },
  },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b)
      local volta = capturar()
      SlashCmdList.COMPRAFOREVER("post 4304 auto")
      SlashCmdList.COMPRAFOREVER("post")
      volta()
      disse(b, "no price seen for Thick Leather: Scan or watch it first", "recusa sem preco visto")
      disse(b, "post queue is empty", "fila vazia")
      b.igual(#b.ns.venda.fila, 0, "nada enfileirado")
      b.igual(CompraForeverAcao:GetText(), "Nothing to do", "sem acao")
      volta = capturar()
      SlashCmdList.COMPRAFOREVER("sell 4304 6s")
      volta()
      disse(b, "watch it first", "piso so para item vigiado")
      SlashCmdList.COMPRAFOREVER("post 4304 6s09c")
      b.igual(#b.ns.venda.fila, 1, "um pedido")
      b.igual(b.ns.venda.fila[1].preco, 609, "preco do pedido")
      SlashCmdList.COMPRAFOREVER("post clear")
      b.igual(#b.ns.venda.fila, 0, "fila esvaziada")
      SlashCmdList.COMPRAFOREVER("post 4304 6s09c 25")
      b.verdadeiro(string.find(CompraForeverAcao:GetText(), "Post 25 Thick Leather @ 6s 09c", 1, true) ~= nil, "texto do pedido: " .. CompraForeverAcao:GetText())
    end },
    { injetar = { "post_pede_confirmacao" } },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(b.contar("PostCommodity"), 1, "um PostCommodity")
      local a = b.chamadas("PostCommodity")[1].args
      b.igual(a[3], 25, "25 unidades")
      b.igual(a[4], 609, "preco")
      b.igual(b.contar("ConfirmPostCommodity"), 0, "Confirm ainda nao")
      b.igual(CompraForeverAcao:GetText(), "Confirm post 25 Thick Leather", "botao pede o Confirm")
      b.verdadeiro(CompraForeverAcao:IsEnabled(), "botao habilitado")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 2 },
    { chamar = function(b)
      local ns = b.ns
      b.igual(b.contar("ConfirmPostCommodity"), 1, "um Confirm")
      b.igual(b.contar("PostCommodity"), 1, "ainda um Post")
      local a = b.chamadas("ConfirmPostCommodity")[1].args
      b.igual(a[2], 3, "duracao 3")
      b.igual(a[3], 25, "25 unidades")
      b.igual(a[4], 609, "preco")
      b.igual(ns.sessao.postado[4304], 25, "postado")
      b.igual(C_Item.GetItemCount(4304), 15, "15 sobram")
      b.igual(#ns.venda.fila, 0, "pedido atendido saiu da fila")
      b.igual(ns.venda.em, nil, "sem postagem em andamento")
    end },
    -- item nao empilhavel: PostItem com lance = compra
    { chamar = function(b)
      SlashCmdList.COMPRAFOREVER("post 3000 2g")
      b.verdadeiro(string.find(CompraForeverAcao:GetText(), "Post 1 Plain Sword @ 2g", 1, true) ~= nil, "texto do item: " .. CompraForeverAcao:GetText())
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 2 },
    { chamar = function(b)
      local ns = b.ns
      b.igual(b.contar("PostItem"), 1, "um PostItem")
      local a = b.chamadas("PostItem")[1].args
      b.igual(a[1].slotIndex, 2, "slot 2")
      b.igual(a[2], 3, "duracao 3")
      b.igual(a[3], 1, "qtd 1")
      b.igual(a[4], 20000, "lance")
      b.igual(a[5], 20000, "compra")
      b.igual(ns.sessao.postado[3000], 1, "postado")
      b.igual(#ns.venda.fila, 0, "fila vazia")
      b.igual(b.contar("ConfirmPostItem"), 0, "sem Confirm")
    end },
    { chamar = function(b)
      SlashCmdList.COMPRAFOREVER("duration 2")
      b.igual(CompraForeverDB.config.duracao, 2, "duracao configurada")
      SlashCmdList.COMPRAFOREVER("duration 9")
      b.igual(CompraForeverDB.config.duracao, 2, "duracao invalida recusada")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
