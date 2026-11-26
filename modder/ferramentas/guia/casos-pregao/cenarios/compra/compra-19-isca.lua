-- Isca (secao 13): botao proprio posta 1 unidade a preco fixo por clique, com tecla propria; nao toma o botao de acao;
-- a caca conta as unidades dos outros numa linha que tem a isca do dono (quantity - numOwnerItems).
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
  id = "compra-19", grupo = "compra",
  descricao = "isca: /compra bait e baitkey, 1 PostCommodity de 1 unidade por clique, botao de acao intacto, caca conta 100 numa linha com 1 do dono",
  inicio = {
    dinheiro = 100000,
    itens = {
      [4304] = { nome = "Thick Leather", vend = 70, pilha = 20 },
    },
    bolsas = {
      { bolsa = 0, slot = 1, itemID = 4304, qtd = 20 },
    },
    mercado = {
      ["4304"] = { { id = 9101, preco = 500, qtd = 101, meus = 1 }, { id = 9102, preco = 656, qtd = 107 } },
    },
  },
  passos = {
    { abrir_leilao = true },
    { avancar = 1 },
    { chamar = function(b)
      b.falso(CompraForeverIsca:IsShown(), "sem isca o botao fica escondido")
      SlashCmdList.COMPRAFOREVER("bait 4304 5s")
      SlashCmdList.COMPRAFOREVER("baitkey e")
      SlashCmdList.COMPRAFOREVER("key e")
      b.igual(CompraForeverDB.teclaIsca, "E", "tecla da isca")
      b.verdadeiro(CompraForeverDB.tecla == nil, "a mesma tecla nao vira a do botao de acao")
      local d = __bancada.bindings[CompraForeverPainel]
      b.igual(d and d.E, "CompraForeverIsca", "E clica o botao da isca com a AH aberta")
      b.igual(CompraForeverCharDB.isca.qtd, 1, "qtd padrao 1")
      b.verdadeiro(CompraForeverIsca:IsShown(), "botao da isca na tela")
      b.verdadeiro(string.find(CompraForeverIsca:GetText(), "Bait 1 Thick Leather @ 5s", 1, true) ~= nil, "texto da isca: " .. CompraForeverIsca:GetText())
      b.igual(CompraForeverAcao:GetText(), "Nothing to do", "botao de acao sem nada")
    end },
    { clique = "CompraForeverIsca" },
    { chamar = function(b)
      b.igual(b.contar("PostCommodity"), 1, "um PostCommodity")
      local a = b.chamadas("PostCommodity")[1].args
      b.igual(a[3], 1, "uma unidade so")
      b.igual(a[4], 500, "a 5s")
      b.igual(CompraForeverAcao:GetText(), "Nothing to do", "a postagem da isca nao toma o botao de acao")
    end },
    { avancar = 2 },
    { chamar = function(b)
      b.igual(CompraForeverCharDB.isca.postadas, 1, "uma isca postada")
      b.igual(C_Item.GetItemCount(4304), 19, "19 sobram")
      tem(b, "", "painel vivo")
      SlashCmdList.COMPRAFOREVER("hunt 4304 5s20c 10g")
    end },
    { clique = "CompraForeverAcao" },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverAcao:GetText(), "Buy 100 Thick Leather (5g) [HUNT]", "linha com a isca do dono: compra as 100 dos outros")
      tem(b, "BAIT 1 Thick Leather @ 5s | posted 1", "linha da isca no painel da caca")
    end },
    -- isca no meio da caca: o botao de acao continua o da caca
    { clique = "CompraForeverIsca" },
    { chamar = function(b)
      b.igual(b.contar("PostCommodity"), 2, "segunda isca")
      b.igual(CompraForeverAcao:GetText(), "Buy 100 Thick Leather (5g) [HUNT]", "botao de acao intacto")
    end },
    { avancar = 2 },
    { chamar = function(b)
      SlashCmdList.COMPRAFOREVER("bait off")
      SlashCmdList.COMPRAFOREVER("hunt off")
      b.falso(CompraForeverIsca:IsShown(), "isca desligada: botao some")
      b.verdadeiro(CompraForeverCharDB.isca == nil, "isca apagada")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
  end,
}
