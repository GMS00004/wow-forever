-- Dois defeitos vistos pelo dono em 23/11/2026 (CONTRATO 12.7):
-- a) o painel ficava solto na tela quando a janela de ancora sumia sem o evento de fechar (ancorado numa janela escondida);
--    agora so ancora em janela na tela e reavalia no OnHide da janela.
-- b) na rota, o Scan sem nada para buscar dizia "No known recipes: open Leatherworking" (texto do lucro); agora diz
--    "Nothing to buy for the route". No lucro, o texto de antes continua.
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
local function clicar(botao, mouse)
  botao:GetScript("OnClick")(botao, mouse or "LeftButton")
end

return {
  id = "rota-27", grupo = "rota",
  descricao = "painel some quando a janela de ancora some sem evento; Scan sem nada para buscar: texto da rota na rota, do lucro no lucro",
  inicio = __bancada.fixture("eng150", {
    sv_char = { versao = 2, modo = { tipo = "rota", prof = "engineering", alvo = 150 },
      prof = { engineering = { pericia = 1, max = 75, ids = { [3919] = true }, n = 1, em = 1 } } },
  }),
  passos = {
    { abrir_treinador = true },
    { chamar = function(b)
      b.verdadeiro(CompraForeverPainel:IsShown(), "painel visivel no treinador")
      local _, rel = CompraForeverPainel:GetPoint(1)
      b.verdadeiro(rel == ClassTrainerFrame, "painel ancorado no treinador")
      -- a janela some sem o TRAINER_CLOSED: o painel some junto
      ClassTrainerFrame:Hide()
      b.falso(CompraForeverPainel:IsShown(), "painel some com a janela, mesmo sem o evento de fechar")
    end },
    { abrir_leilao = true },
    { chamar = function(b)
      b.verdadeiro(CompraForeverPainel:IsShown(), "painel visivel na AH")
      local _, rel = CompraForeverPainel:GetPoint(1)
      b.verdadeiro(rel == AuctionHouseFrame, "painel ancorado na AH, nao no treinador escondido")
      local ns = b.ns
      local original = ns.scanDirigido
      ns.scanDirigido = function() return false, "nothing" end
      clicar(CompraForeverScan)
      ns.atualizarPainel()
      b.verdadeiro(acha("Nothing to buy for the route") ~= nil, "rota: texto de nada para comprar")
      b.falso(acha("No known recipes") ~= nil, "rota: sem o texto do lucro")
      -- volta para o lucro (clique direito anda para tras: Eng 150 -> Profit)
      clicar(CompraForeverModo, "RightButton")
      b.igual(ns.modo(), { tipo = "lucro" }, "modo de lucro")
      clicar(CompraForeverScan)
      ns.atualizarPainel()
      b.verdadeiro(acha("No known recipes: open Leatherworking") ~= nil, "lucro: o texto de antes")
      ns.scanDirigido = original
    end },
  },
}
