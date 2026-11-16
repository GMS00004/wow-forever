local _, ns = ...

-- unico arquivo que menciona as funcoes da secao 2 e que le o campo cru (so em pcall)
local S = {}
ns.segredo = S

function S.caixa(v)
  local s = issecretvalue and issecretvalue(v) or false
  if s then return { cru = v, s = true, tem = true } end
  return { cru = v, s = false, tem = (v ~= nil), n = v }
end

function S.sessao(tipo)
  local ok, r = pcall(C_DamageMeter.GetCombatSessionFromType, tipo, 0)
  return { ok = ok, dados = r }
end

function S.duracao(tipo)
  local ok, r = pcall(C_DamageMeter.GetSessionDurationSeconds, tipo)
  return S.caixa(ok and r or nil)
end

function S.estado(unidade, mob)
  local ok, r = pcall(UnitThreatSituation, unidade, mob)
  return S.caixa(ok and r or nil)
end

function S.detalhe(unidade, mob)
  local ok, tanque, _, pct = pcall(UnitDetailedThreatSituation, unidade, mob)
  return { tanque = S.caixa(ok and tanque or nil), pct = S.caixa(ok and pct or nil) }
end

function S.lider(unidade, mob)
  local ok, r = pcall(UnitThreatLeadSituation, unidade, mob)
  return S.caixa(ok and r or nil)
end

function S.porcentagem(unidade, mob)
  local ok, r = pcall(UnitThreatPercentageOfLead, unidade, mob)
  return S.caixa(ok and r or nil)
end

function S.zerar()
  if ns.emCombate and ns.emCombate() then return false end
  pcall(C_DamageMeter.ResetAllCombatSessions)
  return true
end

-- ralos: o valor cru so sai daqui para um widget
function S.mostrarInteiro(fs, caixa)
  fs:SetText(C_StringUtil.RoundToNearestString(caixa.cru))
end

function S.mostrarAbrev(fs, caixa)
  fs:SetText(AbbreviateNumbers(caixa.cru))
end

function S.mostrarPct(fs, caixa)
  fs:SetText(C_StringUtil.WrapString(C_StringUtil.RoundToNearestString(caixa.cru), nil, "%"))
end

function S.mostrarBarra(barra, caixa)
  barra:SetValue(caixa.cru)
end

function S.mostrarSe(regiao, caixa)
  regiao:SetAlphaFromBoolean(caixa["cru"], 1, 0)
end
