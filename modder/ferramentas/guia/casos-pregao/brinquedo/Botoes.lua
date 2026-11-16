-- Brinquedo: botoes de tecla. Os de nome PregaoForever* recebem a bandeira de hardware; BrinquedoOutroBotao nao.
local _, ns = ...
local br = ns.brinquedo

local function botao(nome, aoClicar)
  local b = CreateFrame("Button", nome, UIParent)
  b:SetSize(40, 20)
  b:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  b:SetText(nome)
  b:SetScript("OnClick", function(self, ...)
    PregaoForeverDB = PregaoForeverDB or {}
    PregaoForeverDB.cliques = (PregaoForeverDB.cliques or 0) + 1
    aoClicar(...)
  end)
  return b
end

botao("PregaoForeverTeclaL", function() br.auto = true; br.consultaBrowse() end)
botao("PregaoForeverTeclaC", function() br.consultaCommodity(2589) end)
botao("PregaoForeverTeclaN", function() br.maisCommodity(2589) end)
botao("PregaoForeverTeclaI", function() br.consultaItem(br.itemKey) end)
botao("PregaoForeverTeclaO", function() br.proprios() end)
botao("PregaoForeverTeclaP", function() br.acaoPostar() end)
botao("PregaoForeverTeclaD", function() br.acaoDupla() end)
botao("BrinquedoOutroBotao", function() br.acaoPostar() end)
