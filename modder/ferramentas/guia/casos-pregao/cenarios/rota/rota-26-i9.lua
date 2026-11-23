-- I9 na rota: nenhuma busca no leilao sem tecla do dono. Com a AH aberta e nenhuma tecla ou clique do dono: troca de modo por comando
-- (/compra mode), reload_real e 120 s de BAG_UPDATE nao fazem SendBrowseQuery, SendSearchQuery, SendSellSearchQuery nem ReplicateItems
-- (a bancada tambem marca violacao I9 se uma busca sair sem tecla nos ultimos 90 s). O controle final: o clique do dono no Scan busca.
-- CONTRATO 12.3: sem scan, o plano de rota existe (ns.replanejar chama o planejador mesmo sem ns.scan) e as linhas de leilao viram
-- "Scan at the AH".
local BUSCAS = { "SendBrowseQuery", "SendSearchQuery", "SendSellSearchQuery", "ReplicateItems" }
local function buscas(b)
  local n = 0
  for _, nome in ipairs(BUSCAS) do n = n + b.contar(nome) end
  return n
end
local function textos()
  local out = {}
  for _, r in ipairs({ CompraForeverPainel:GetRegions() }) do
    local t = r:GetText()
    if t and t ~= "" then out[#out + 1] = t end
  end
  return out
end
local function tem(b, trecho, msg)
  for _, t in ipairs(textos()) do
    if string.find(t, trecho, 1, true) then return true end
  end
  b.verdadeiro(false, msg .. " (texto '" .. trecho .. "' nao achado em: " .. table.concat(textos(), " | ") .. ")")
  return false
end

local passos = {
  { abrir_leilao = true },
  { avancar = 100 },
  -- troca de modo por comando, sem tecla do dono
  { chamar = function(b)
    SlashCmdList.COMPRAFOREVER("mode eng 150")
    b.igual(b.ns.modo(), { tipo = "rota", prof = "engineering", alvo = 150 }, "modo Eng 150")
    SlashCmdList.COMPRAFOREVER("mode eng 225")
    SlashCmdList.COMPRAFOREVER("mode profit")
    SlashCmdList.COMPRAFOREVER("mode eng")
  end },
  { avancar = 30 },
  { chamar = function(b)
    b.igual(buscas(b), 0, "a troca de modo por comando nao busca")
    b.igual(b.contar("Request"), 0, "nada de Request")
    b.verdadeiro(b.ns.plano ~= nil and b.ns.plano.modo == 2, "plano de rota existe sem scan")
    b.igual(b.ns.plano.rota.proximo, "ah", "proximo: AH")
    b.igual(#b.ns.plano.leilao, 0, "sem escada: nenhuma linha de leilao")
  end },
  { avancar = 1 },
  { chamar = function(b)
    tem(b, "Scan at the AH", "sem scan: as linhas de leilao viram 'Scan at the AH'")
  end },
  -- reload_real com a rota ligada
  { reload_real = true },
  { abrir_leilao = true },
  { avancar = 30 },
  { chamar = function(b)
    b.igual(buscas(b), 0, "o reload e abrir a AH nao buscam")
    b.igual(b.ns.modo(), { tipo = "rota", prof = "engineering", alvo = 150 }, "o modo sobreviveu")
    b.verdadeiro(b.ns.plano ~= nil and b.ns.plano.modo == 2, "plano de rota depois do reload, sem scan")
  end },
}
-- 120 s de BAG_UPDATE (a cada 10 s)
for _ = 1, 12 do
  passos[#passos + 1] = { evento = { "BAG_UPDATE", 0 } }
  passos[#passos + 1] = { evento = "BAG_UPDATE_DELAYED" }
  passos[#passos + 1] = { avancar = 10 }
end
passos[#passos + 1] = { chamar = function(b)
  b.igual(buscas(b), 0, "120 s de BAG_UPDATE nao buscam")
  b.igual(#b.violacoes(), 0, "sem violacao I9")
  b.igual(b.contar("StartCommoditiesPurchase") + b.contar("PlaceBid"), 0, "nenhuma compra")
end }
-- controle: o clique do dono no Scan busca (com tecla, sem violacao)
passos[#passos + 1] = { clique = "CompraForeverScan" }
passos[#passos + 1] = { ate_ocioso = true }
passos[#passos + 1] = { chamar = function(b)
  b.igual(b.contar("SendSearchQuery"), 12, "o Scan do dono faz as 12 buscas dirigidas")
  b.igual(#b.violacoes(), 0, "com a tecla do dono, sem violacao")
  b.igual(b.ns.plano.rota.proximo, "ah", "proximo: AH")
  b.igual(#b.ns.plano.leilao, 12, "12 linhas depois do scan")
end }

return {
  id = "rota-26", grupo = "rota",
  descricao = "I9 na rota: troca de modo por comando, reload e 120 s de BAG_UPDATE nao fazem nenhuma busca no leilao; so o Scan do dono",
  inicio = __bancada.fixture("eng150", {
    sv_char = { versao = 2, modo = { tipo = "lucro" },
      prof = { engineering = { pericia = 1, max = 75, ids = { [3919] = true }, n = 1, em = 1 } } },
  }),
  passos = passos,
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nunca BuyTrainerService")
  end,
}
