-- Vigia: /compra watch (id e link), lista, alterar, every, unwatch; o que fica em CompraForeverDB.vigia.
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
  id = "compra-12", grupo = "compra",
  descricao = "vigia: /compra watch por id e por link, lista, alterar, every 10 e unwatch; SV CompraForeverDB.vigia",
  inicio = {
    dinheiro = 51400,
    itens = {
      [4304] = { nome = "Thick Leather", vend = 70, pilha = 20 },
    },
  },
  passos = {
    { chamar = function(b)
      local v = CompraForeverDB.vigia
      b.verdadeiro(type(v) == "table", "vigia criada no ADDON_LOADED")
      b.igual(v.intervalo, 30, "intervalo padrao")
      b.igual(v.itens, {}, "sem itens")
      b.igual(v.historico, {}, "sem historico")
      local volta = capturar()
      SlashCmdList.COMPRAFOREVER("watch")
      SlashCmdList.COMPRAFOREVER("watch 4304 4s90c 20")
      volta()
      disse(b, "watch list is empty", "lista vazia")
      disse(b, "watching Thick Leather (4304) <= 4s 90c, buy 20", "adicionou, nome vindo de GetItemInfo")
      b.igual(v.itens[4304], { nome = "Thick Leather", teto = 490, qtd = 20 }, "item gravado")
      SlashCmdList.COMPRAFOREVER("watch 5000 1s")
      b.igual(v.itens[5000].nome, "Item 5000", "nome de GetItemInfo do falso")
      SlashCmdList.COMPRAFOREVER("unwatch 5000")
    end },
    -- com o link o nome vem do link (nome com espaco); sem qtd mantem a atual
    { chamar = function(b)
      local v = CompraForeverDB.vigia
      local volta = capturar()
      SlashCmdList.COMPRAFOREVER("watch |cffffffff|Hitem:4304::::::::60:::::|h[Thick Leather]|h|r 5s")
      SlashCmdList.COMPRAFOREVER("watch |Hitem:5001::::|h[Odd Name]|h 1s 3")
      b.igual(v.itens[5001], { nome = "Odd Name", teto = 100, qtd = 3 }, "nome do link com espaco")
      SlashCmdList.COMPRAFOREVER("unwatch 5001")
      SlashCmdList.COMPRAFOREVER("watch")
      volta()
      b.igual(v.itens[4304], { nome = "Thick Leather", teto = 500, qtd = 20 }, "alterado pelo link")
      disse(b, "updated Thick Leather (4304) <= 5s, buy 20", "mensagem de alteracao")
      disse(b, "Thick Leather (4304) <= 5s, buy 20, last -", "lista com o ultimo preco")
    end },
    { chamar = function(b)
      local v = CompraForeverDB.vigia
      SlashCmdList.COMPRAFOREVER("watch 4304 5s 40")
      b.igual(v.itens[4304].qtd, 40, "qtd alterada")
      local volta = capturar()
      SlashCmdList.COMPRAFOREVER("watch every 10")
      SlashCmdList.COMPRAFOREVER("watch every 5")
      SlashCmdList.COMPRAFOREVER("watch every 301")
      SlashCmdList.COMPRAFOREVER("watch 4304")
      SlashCmdList.COMPRAFOREVER("watch xyz 5s")
      volta()
      b.igual(v.intervalo, 10, "intervalo 10; 5 e 301 recusados")
      disse(b, "every must be 10 to 300", "recusa de intervalo")
      disse(b, "usage: /compra watch", "uso incompleto")
      b.igual(v.itens[4304].teto, 500, "nada mudou nos recusados")
    end },
    { chamar = function(b)
      local v = CompraForeverDB.vigia
      local volta = capturar()
      SlashCmdList.COMPRAFOREVER("unwatch 9999")
      SlashCmdList.COMPRAFOREVER("unwatch |Hitem:4304::::|h[Thick Leather]|h")
      SlashCmdList.COMPRAFOREVER("watch")
      volta()
      disse(b, "not watched: 9999", "unwatch de quem nao esta")
      disse(b, "unwatched 4304", "unwatch")
      disse(b, "watch list is empty", "lista vazia de novo")
      b.igual(v.itens, {}, "sem itens")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
