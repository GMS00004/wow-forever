-- Botao de modo (CONTRATO 12.7, 12.3): o clique esquerdo anda para o proximo de ns.modosDisponiveis(), o direito para o anterior;
-- a escolha fica em CompraForeverCharDB.modo e sobrevive ao reload_real; o clique nao faz busca nem acao de leilao.
-- Engineering gravada no personagem: os modos sao Profit, Eng 150 e Eng 225 (so a profissao vista, secao 12.3).
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

-- as funcoes de busca e de acao do leilao: nenhuma pode rodar por causa de um clique no botao de modo
local PROIBIDAS = { "SendBrowseQuery", "SendSearchQuery", "SendSellSearchQuery", "ReplicateItems", "StartCommoditiesPurchase",
  "ConfirmCommoditiesPurchase", "PlaceBid", "PostCommodity", "PostItem", "CancelAuction" }
local function semLeilao(b, msg)
  local n = 0
  for _, nome in ipairs(PROIBIDAS) do n = n + b.contar(nome) end
  b.igual(n, 0, msg)
end

local function clicarModo(botao)
  CompraForeverModo:GetScript("OnClick")(CompraForeverModo, botao)
end

return {
  id = "rota-01", grupo = "rota",
  descricao = "botao de modo: esquerdo avanca, direito volta, grava em CompraForeverCharDB.modo, sobrevive ao reload_real, sem busca nem acao de leilao",
  inicio = __bancada.fixture("eng150", {
    sv_char = { versao = 2, modo = { tipo = "lucro" },
      prof = { engineering = { pericia = 1, max = 75, ids = { [3919] = true }, n = 1, em = 1 } } },
  }),
  passos = {
    { abrir_leilao = true },
    { chamar = function(b)
      -- geometria da fileira de cima (12.7)
      local function geo(w)
        local pt, rel, relPt, x, y = w:GetPoint(1)
        return { pt, rel == CompraForeverPainel, relPt, x, y, w:GetWidth() }
      end
      b.igual(geo(CompraForeverScan), { "TOPLEFT", true, "TOPLEFT", 8, -40, 90 }, "Scan x=8 largura 90")
      b.igual(geo(CompraForeverFull), { "TOPLEFT", true, "TOPLEFT", 102, -40, 96 }, "Full x=102 largura 96")
      b.igual(geo(CompraForeverModo), { "TOPLEFT", true, "TOPLEFT", 202, -40, 90 }, "Modo x=202 largura 90")
      b.igual(CompraForeverModo:GetText(), "Profit", "rotulo do lucro")
      b.verdadeiro(CompraForeverModo:IsEnabled(), "Modo habilitado")
      b.igual(b.ns.modo(), { tipo = "lucro" }, "modo de lucro")
      local lista = b.ns.modosDisponiveis()
      b.igual(lista, { { tipo = "lucro" }, { tipo = "rota", prof = "engineering", alvo = 150 },
        { tipo = "rota", prof = "engineering", alvo = 225 } }, "modos disponiveis")
    end },
    -- 1: Profit -> Eng 150
    { clique = "CompraForeverModo" },
    { chamar = function(b)
      local ns = b.ns
      b.igual(ns.modo(), { tipo = "rota", prof = "engineering", alvo = 150 }, "modo Eng 150")
      b.igual(CompraForeverCharDB.modo, { tipo = "rota", prof = "engineering", alvo = 150 }, "gravado no personagem")
      b.igual(CompraForeverModo:GetText(), "Eng 150", "rotulo Eng 150")
      b.igual(ns.rotuloModo(ns.modo()), "Eng 150", "ns.rotuloModo")
      b.verdadeiro(ns.plano ~= nil and ns.plano.modo == 2, "plano de rota (modo 2)")
      b.igual(ns.plano.rota.estado, "ok", "plano da rota ok")
      b.igual(ns.plano.rota.alvo, 150, "alvo 150 no plano")
      b.igual(CompraForeverCharDB.plano, nil, "o plano da rota nao e gravado")
      semLeilao(b, "o clique no modo nao busca nem age no leilao")
      b.igual(CompraForeverCharDB.versao, 2, "versao 2")
    end },
    -- 2: Eng 150 -> Eng 225 (a rota do fixture acaba no 150: lacuna em 150)
    { clique = "CompraForeverModo" },
    { chamar = function(b)
      local ns = b.ns
      b.igual(ns.modo(), { tipo = "rota", prof = "engineering", alvo = 225 }, "modo Eng 225")
      b.igual(CompraForeverModo:GetText(), "Eng 225", "rotulo Eng 225")
      b.igual(ns.plano.rota.alvo, 225, "alvo 225 no plano")
      b.igual(ns.plano.rota.estado, "lacuna", "a rota do fixture acaba no 150: lacuna")
      b.igual(ns.plano.rota.lacuna, 150, "lacuna em 150")
      semLeilao(b, "ainda sem busca nem acao de leilao")
    end },
    -- 3: Eng 225 -> Profit (volta ao inicio da lista)
    { clique = "CompraForeverModo" },
    { chamar = function(b)
      local ns = b.ns
      b.igual(ns.modo(), { tipo = "lucro" }, "voltou ao lucro")
      b.igual(CompraForeverCharDB.modo, { tipo = "lucro" }, "lucro gravado")
      b.igual(CompraForeverModo:GetText(), "Profit", "rotulo Profit")
      b.verdadeiro(ns.plano == nil or ns.plano.modo ~= 2, "sem plano de rota no lucro")
      semLeilao(b, "ainda sem busca nem acao de leilao")
    end },
    -- 4: clique direito: Profit -> Eng 225 (o anterior, com volta pelo fim) e depois Eng 225 -> Eng 150
    { chamar = function(b) clicarModo("RightButton") end },
    { chamar = function(b)
      b.igual(b.ns.modo(), { tipo = "rota", prof = "engineering", alvo = 225 }, "direito do Profit vai ao ultimo")
      clicarModo("RightButton")
    end },
    { chamar = function(b)
      b.igual(b.ns.modo(), { tipo = "rota", prof = "engineering", alvo = 150 }, "direito do Eng 225 vai ao Eng 150")
      b.igual(CompraForeverModo:GetText(), "Eng 150", "rotulo Eng 150")
      semLeilao(b, "o clique direito tambem nao busca")
    end },
    -- reload_real: o modo vem do disco
    { reload_real = true },
    { chamar = function(b)
      b.igual(b.ns.modo(), { tipo = "rota", prof = "engineering", alvo = 150 }, "modo depois do reload")
      b.igual(CompraForeverCharDB.modo, { tipo = "rota", prof = "engineering", alvo = 150 }, "gravado depois do reload")
      b.igual(CompraForeverCharDB.versao, 2, "versao 2 depois do reload")
      b.igual(CompraForeverCharDB.prof.engineering.pericia, 1, "pericia gravada sobreviveu")
    end },
    { abrir_leilao = true },
    { avancar = 1 },
    { chamar = function(b)
      b.igual(CompraForeverModo:GetText(), "Eng 150", "rotulo Eng 150 depois do reload")
      -- 12.3: no modo de rota o plano existe mesmo sem scan ("craft e venda funcionam logo depois de um /reload")
      local pl = b.ns.plano
      b.verdadeiro(pl ~= nil and pl.modo == 2, "plano de rota existe depois do reload, sem scan")
      b.igual(pl and pl.rota and pl.rota.estado, "ok", "plano da rota ok depois do reload")
      b.igual(pl and pl.rota and pl.rota.pericia, 1, "pericia 1 no plano")
      tem(b, "Engineering 1/75 -> 150", "linha da profissao no painel")
      semLeilao(b, "reload e abrir a AH nao buscam sozinhos")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nunca BuyTrainerService")
  end,
}
