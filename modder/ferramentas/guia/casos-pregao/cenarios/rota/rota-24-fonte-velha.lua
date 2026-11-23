-- Fonte da rota velha ou publica (CONTRATO 12.4 e 12.7): a linha do scan ganha " | route dd/mm hh:mm full|public" e " old" quando
-- plano.rota.velho; velho = Full do jogo mais novo que a fonte da rota, ou fonte com mais de 6 h (estritamente: 21600 s nao e velho).
-- Velho tambem acende a dica "Newer Full: say atualiza". Todas as receitas conhecidas: sem dicas TRAIN ocupando as 4 dicas.
local TODAS = { [3919] = true, [3923] = true, [3924] = true, [3929] = true, [3931] = true, [8334] = true, [3937] = true,
  [3945] = true, [3946] = true, [3953] = true }

local function textos()
  local out = {}
  for _, r in ipairs({ CompraForeverPainel:GetRegions() }) do
    local t = r:GetText()
    if t and t ~= "" then out[#out + 1] = t end
  end
  return out
end
local function acha(trecho)
  for _, t in ipairs(textos()) do
    if string.find(t, trecho, 1, true) then return t end
  end
  return nil
end
-- a linha do scan (a que tem " | route ")
local function linhaScan() return acha(" | route ") end

local function fonte(tipo, em, ultimoFull)
  CompraForeverDados.rotas.fonte = { tipo = tipo, em = em, n = 6944 }
  CompraForeverDB.ultimoFull = ultimoFull or 0
  __bancada.ns.replanejar()
end

return {
  id = "rota-24", grupo = "rota",
  descricao = "fonte da rota: full recente sem aviso; publica sem old; mais de 6 h ou Full do jogo mais novo: old e Newer Full",
  inicio = __bancada.fixture("eng150", {
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 1, max = 75, ids = TODAS, n = 10, em = 1 } } },
  }),
  passos = {
    { abrir_leilao = true },
    -- a) full de 2 h atras (o do fixture), sem Full do jogo
    { chamar = function(b)
      local ns = b.ns
      ns.replanejar()
      local agora = time()
      local em = agora - 7200
      b.igual(ns.plano.rota.fonte, { tipo = "full", em = em, n = 6944 }, "fonte do plano")
      b.falso(ns.plano.rota.velho, "full de 2 h: nao velho")
      local l = linhaScan()
      b.verdadeiro(l ~= nil, "a linha do scan tem a fonte da rota")
      b.igual(l, "No scan yet | route " .. date("%d/%m %H:%M", em) .. " full", "linha do scan")
      b.verdadeiro(string.find(l, "^No scan yet | route %d%d/%d%d %d%d:%d%d full$") ~= nil, "formato da linha")
      b.falso(acha("Newer Full") ~= nil, "sem a dica Newer Full")
    end },
    -- b) publica, de 1 h
    { chamar = function(b)
      local em = time() - 3600
      fonte("publica", em)
      b.falso(b.ns.plano.rota.velho, "publica de 1 h: nao velha")
      b.igual(linhaScan(), "No scan yet | route " .. date("%d/%m %H:%M", em) .. " public", "linha do scan: public")
      b.falso(acha("Newer Full") ~= nil, "sem a dica Newer Full")
    end },
    -- c) 6 h exatas: nao velha; 6 h e 1 s: velha
    { chamar = function(b)
      local em = time() - 21600
      fonte("full", em)
      b.falso(b.ns.plano.rota.velho, "6 h exatas: nao velha")
      b.igual(linhaScan(), "No scan yet | route " .. date("%d/%m %H:%M", em) .. " full", "6 h exatas: sem old")
      em = time() - 21601
      fonte("full", em)
      b.verdadeiro(b.ns.plano.rota.velho, "6 h e 1 s: velha")
      b.igual(linhaScan(), "No scan yet | route " .. date("%d/%m %H:%M", em) .. " full old", "linha do scan: old")
      b.verdadeiro(acha("Newer Full: say atualiza") ~= nil, "dica Newer Full: say atualiza")
    end },
    -- d) publica velha tambem
    { chamar = function(b)
      local em = time() - 30 * 3600
      fonte("publica", em)
      b.verdadeiro(b.ns.plano.rota.velho, "publica de 30 h: velha")
      b.igual(linhaScan(), "No scan yet | route " .. date("%d/%m %H:%M", em) .. " public old", "public old")
    end },
    -- e) Full do jogo mais novo que a fonte (fonte de 2 h, Full do jogo agora)
    { chamar = function(b)
      local agora = time()
      fonte("full", agora - 7200, agora)
      b.verdadeiro(b.ns.plano.rota.velho, "Full do jogo mais novo que a fonte: velha")
      b.igual(linhaScan(), "No scan yet | route " .. date("%d/%m %H:%M", agora - 7200) .. " full old", "old por Full mais novo")
      b.verdadeiro(acha("Newer Full: say atualiza") ~= nil, "dica Newer Full")
      -- Full do jogo mais velho que a fonte: nao velha
      fonte("full", agora - 7200, agora - 10000)
      b.falso(b.ns.plano.rota.velho, "Full do jogo mais velho que a fonte: nao velha")
      b.falso(acha("Newer Full") ~= nil, "sem a dica Newer Full")
    end },
    -- f) com o scan feito a linha ganha a hora do scan antes da rota
    { chamar = function(b) fonte("publica", time() - 3600) end },
    { clique = "CompraForeverScan" },
    { ate_ocioso = true },
    { avancar = 1 },
    { chamar = function(b)
      local l = linhaScan()
      b.verdadeiro(l ~= nil and string.find(l, "^Scan %d%d:%d%d targeted | route %d%d/%d%d %d%d:%d%d public$") ~= nil,
        "linha do scan com o scan e a fonte: " .. tostring(l))
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nunca BuyTrainerService")
  end,
}
