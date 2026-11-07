-- GuiaForever: Linhas do guia nos tooltips (tarefas A7 e B2; contrato em ARQUITETURA.md, secao 6).
-- Fase A: "Your pet can eat this" no tooltip de item. Fase B: tecla e uso no tooltip de magia, e orientacao de autocast
-- no tooltip de acao do pet (Enum.TooltipDataType.Spell e .PetAction; so TooltipDataProcessor, regra 6).
-- Nenhum outro arquivo depende deste existir (regra 3). Em combate nada e lido nem escrito (regra 5).

local _, ns = ...

local function emCombate()
  return InCombatLockdown and InCombatLockdown() and true or false
end

local function ehSecreto(v)
  return issecretvalue and issecretvalue(v) and true or false
end

-- Lua 5.1: xpcall nao repassa argumentos, por isso o fechamento (regra 10).
local function seguro(fn, ...)
  local n = select("#", ...)
  local args = { ... }
  return xpcall(function() return fn(unpack(args, 1, n)) end, geterrorhandler())
end

local function linhaDeComida(tooltip, dados)
  if emCombate() then return end
  if type(tooltip) ~= "table" or not tooltip.AddLine then return end
  if tooltip.IsForbidden and tooltip:IsForbidden() then return end
  if type(dados) ~= "table" then return end
  local id = dados.id
  if ehSecreto(id) or type(id) ~= "number" then return end
  local est = ns.estado
  if not (est and est.classe == "HUNTER" and est.pet and est.pet.existe) then return end
  if not (C_PetInfo and C_PetInfo.CanPetEatItem) then return end
  local ok, come = pcall(C_PetInfo.CanPetEatItem, id)
  if not (ok and come) then return end
  local cor = ns.COR or "|cff33ff99"
  local fim = ns.FIM or "|r"
  tooltip:AddLine(cor .. "Your pet can eat this" .. fim)
end

-- Fase B ---------------------------------------------------------------------------

local function dicasCacador()
  local d = GuiaForeverDicas
  return type(d) == "table" and type(d.HUNTER) == "table" and d.HUNTER or nil
end

local function cortar(texto, max)
  if #texto <= max then return texto end
  return string.sub(texto, 1, max - 3) .. "..."
end

local function tooltipValido(tooltip, dados)
  if emCombate() then return false end
  if type(tooltip) ~= "table" or not tooltip.AddLine then return false end
  if tooltip.IsForbidden and tooltip:IsForbidden() then return false end
  return type(dados) == "table"
end

local function juntar(base, fonte)
  if type(fonte) == "string" and fonte ~= "" then return base .. " (" .. fonte .. ")" end
  return base
end

local function linhasDeMagia(tooltip, dados)
  if not tooltipValido(tooltip, dados) then return end
  local id = dados.id
  if ehSecreto(id) or type(id) ~= "number" then return end
  local nome = ns.nomeMagia and ns.nomeMagia(id)
  if type(nome) ~= "string" or ehSecreto(nome) then return end
  local cor = ns.COR or "|cff33ff99"
  local fim = ns.FIM or "|r"
  local alvo = string.lower(nome)
  local linhas = {}
  local tecla = ns.teclaDe and ns.teclaDe(nome)
  if type(tecla) == "string" then linhas[#linhas + 1] = "Key: " .. tecla end
  local d = dicasCacador()
  local lista = d and d.magias
  if type(lista) == "table" and ns.relevante then
    for _, e in ipairs(lista) do
      if type(e.magia) == "string" and string.lower(e.magia) == alvo
         and type(e.texto) == "string" and ns.relevante(e) then
        linhas[#linhas + 1] = cortar(juntar("Use: " .. e.texto, e.fonte), 120)
        break
      end
    end
  end
  for i = 1, math.min(#linhas, 2) do tooltip:AddLine(cor .. linhas[i] .. fim) end
end

-- Nome da habilidade do pet sem ler valor secreto: primeiro o titulo do tooltip (lines[1].leftText),
-- depois o id como magia. O formato exato do data nesse tipo nao esta na documentacao (ver relatorio).
local function nomeDaAcaoDoPet(dados)
  local linhas = dados.lines
  if type(linhas) == "table" and type(linhas[1]) == "table" then
    local t = linhas[1].leftText
    if type(t) == "string" and not ehSecreto(t) and t ~= "" then return t end
  end
  local id = dados.id
  if type(id) == "number" and not ehSecreto(id) then
    local n = ns.nomeMagia and ns.nomeMagia(id)
    if type(n) == "string" and not ehSecreto(n) then return n end
  end
  return nil
end

local function linhasDeAcaoDoPet(tooltip, dados)
  if not tooltipValido(tooltip, dados) then return end
  local nome = nomeDaAcaoDoPet(dados)
  if not nome then return end
  local d = dicasCacador()
  if not d then return end
  local alvo = string.lower(nome)
  local linhas = {}
  if type(d.petTreino) == "table" then
    for _, e in ipairs(d.petTreino) do
      if type(e.habilidade) == "string" and string.lower(e.habilidade) == alvo and type(e.texto) == "string" then
        linhas[#linhas + 1] = juntar(e.texto, e.fonte)
        break
      end
    end
  end
  if (alvo == "growl" or alvo == "cower") and type(d.pets) == "table" then
    for _, e in ipairs(d.pets) do
      local grupo = false
      if type(e.tags) == "table" then
        for _, t in ipairs(e.tags) do if t == "grupo" then grupo = true end end
      end
      if grupo and type(e.texto) == "string" and string.find(string.lower(e.texto), alvo, 1, true) then
        local t = e.texto
        if not (string.find(t, "^In group") or string.find(t, "^In a group")) then t = "In groups: " .. t end
        linhas[#linhas + 1] = juntar(t, e.fonte)
        break
      end
    end
  end
  local cor = ns.COR or "|cff33ff99"
  local fim = ns.FIM or "|r"
  for i = 1, math.min(#linhas, 2) do tooltip:AddLine(cor .. linhas[i] .. fim) end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
  local tipos = Enum.TooltipDataType
  if tipos.Item then
    TooltipDataProcessor.AddTooltipPostCall(tipos.Item, function(tooltip, dados)
      seguro(linhaDeComida, tooltip, dados)
    end)
  end
  if tipos.Spell then
    TooltipDataProcessor.AddTooltipPostCall(tipos.Spell, function(tooltip, dados)
      seguro(linhasDeMagia, tooltip, dados)
    end)
  end
  if tipos.PetAction then
    TooltipDataProcessor.AddTooltipPostCall(tipos.PetAction, function(tooltip, dados)
      seguro(linhasDeAcaoDoPet, tooltip, dados)
    end)
  end
end
