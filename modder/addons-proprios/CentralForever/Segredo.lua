-- CentralForever/Segredo.lua: o unico arquivo que chama as APIs de combate (CONTRATO.md, secoes 2, 3.3 e 4).
-- Devolve "caixas" ({ cru, s, tem, n }) e oferece "ralos" (funcoes que entregam o valor cru a um
-- widget ou a um formatador). Valor possivelmente secreto nunca entra em conta, comparacao, teste
-- booleano, concatenacao, tostring, string.format nem chave de tabela. O campo cru so e lido aqui.
-- Regras: Lua 5.1, so ASCII, texto do jogo em ingles, nenhuma global nova.
local _, ns = ...

local S = ns.segredo or {}
ns.segredo = S

-- ---------------------------------------------------------------------------
-- Apoio (nada aqui toca valor secreto)
-- ---------------------------------------------------------------------------

-- caixa sem valor
local function caixaVazia()
  return { cru = nil, s = false, tem = false, n = nil }
end

-- texto que aparece quando nao ha valor
local function textoVazio()
  local cfg = ns.cfg
  if cfg and cfg.vazio then
    return cfg.vazio
  end
  return "--"
end

-- disjuntor: o recurso foi desligado por erros repetidos?
local function desligado(recurso)
  local d = ns.desligado
  if d and d[recurso] then
    return true
  end
  return false
end

-- conta um erro do recurso no Nucleo (se existir)
local function falhou(recurso, erro)
  if ns.falhou then
    pcall(ns.falhou, recurso, erro)
  end
end

-- estamos em combate? (so para S.zerar; sem como saber, trata como combate)
local function emCombate()
  if ns.emCombate then
    local ok, r = pcall(ns.emCombate)
    if ok and not r then
      return false
    end
    return true
  end
  if InCombatLockdown then
    local ok, r = pcall(InCombatLockdown)
    if ok and not r then
      return false
    end
    return true
  end
  return true
end

-- o tipo de dano (valor de ns.enum, com reserva literal)
local function tipoDano()
  local e = ns.enum
  if e and e.tipo and e.tipo.DamageDone then
    return e.tipo.DamageDone
  end
  return 0
end

-- ---------------------------------------------------------------------------
-- Predicado e caixa
-- ---------------------------------------------------------------------------

-- true se o valor pode ser lido (nao e secreto). Sem issecretvalue o cliente nao tem valores
-- secretos, entao tudo e legivel (CONTRATO.md 3.3).
function S.legivel(v)
  if not issecretvalue then
    return true
  end
  local ok, r = pcall(issecretvalue, v)
  if not ok then
    return false
  end
  return r == false
end

-- a tabela pode ser percorrida?
local function tabelaAcessivel(t)
  -- primeiro o teste de segredo; so depois o type (nada toca um valor secreto)
  if not S.legivel(t) then
    return false
  end
  if type(t) ~= "table" then
    return false
  end
  if canaccesstable then
    local ok, r = pcall(canaccesstable, t)
    if ok and r == true then
      return true
    end
    return false
  end
  return S.legivel(t)
end

-- Ordem obrigatoria: primeiro o teste de segredo; so com s falso se compara v com nil.
function S.caixa(v)
  local s = not S.legivel(v)
  if s then
    return { cru = v, s = true, tem = true, n = nil }
  end
  return { cru = v, s = false, tem = (v ~= nil), n = v }
end

-- "secreto", "legivel" ou "nada" (para o diario; nunca o valor)
function S.tipo(caixa)
  if type(caixa) ~= "table" then
    return "nada"
  end
  if caixa.s == true then
    return "secreto"
  end
  if caixa.tem == true then
    return "legivel"
  end
  return "nada"
end

-- ---------------------------------------------------------------------------
-- Leituras do medidor de dano
-- ---------------------------------------------------------------------------

-- percorre a sessao e acha a linha do jogador (roda dentro de pcall)
local function lerLinhas(sessao, r)
  if not S.legivel(sessao) then
    r.motivo = "inacessivel"
    return false
  end
  if type(sessao) ~= "table" then
    r.motivo = "nada"
    return false
  end
  if not tabelaAcessivel(sessao) then
    r.motivo = "inacessivel"
    return false
  end
  local fontes = sessao.combatSources
  if not S.legivel(fontes) then
    r.motivo = "inacessivel"
    return false
  end
  if type(fontes) ~= "table" then
    r.motivo = "nada"
    return false
  end
  if not tabelaAcessivel(fontes) then
    r.motivo = "inacessivel"
    return false
  end
  r.fontes = #fontes
  for _, fonte in ipairs(fontes) do
    if tabelaAcessivel(fonte) then
      local eu = S.caixa(fonte.isLocalPlayer)
      if eu.n == true then
        r.dps = S.caixa(fonte.amountPerSecond)
        r.total = S.caixa(fonte.totalAmount)
        r.linha = true
        break
      end
    end
  end
  r.ok = true
  r.motivo = "ok"
  return true
end

-- { ok, linha, dps, total, fontes, motivo }. motivo (extra do contrato, so para o diario):
-- "ok", "desligado", "ausente", "falhou", "nada" ou "inacessivel".
function S.sessao(tipoSessao)
  local r = { ok = false, linha = false, dps = caixaVazia(), total = caixaVazia(), fontes = nil, motivo = "ausente" }
  if desligado("sessao") then
    r.motivo = "desligado"
    return r
  end
  if C_DamageMeter and C_DamageMeter.GetCombatSessionFromType then
    local ok, sessao = pcall(C_DamageMeter.GetCombatSessionFromType, tipoSessao, tipoDano())
    if not ok then
      falhou("sessao", sessao)
      r.motivo = "falhou"
      return r
    end
    local ok2, erro2 = pcall(lerLinhas, sessao, r)
    if not ok2 then
      falhou("sessao", erro2)
      return { ok = false, linha = false, dps = caixaVazia(), total = caixaVazia(), fontes = nil, motivo = "falhou" }
    end
  end
  return r
end

-- caixa da duracao da sessao em segundos
function S.duracao(tipoSessao)
  if desligado("sessao") then
    return caixaVazia()
  end
  if C_DamageMeter and C_DamageMeter.GetSessionDurationSeconds then
    local ok, v = pcall(C_DamageMeter.GetSessionDurationSeconds, tipoSessao)
    if ok then
      return S.caixa(v)
    end
    falhou("sessao", v)
  end
  return caixaVazia()
end

-- ok (o medidor esta disponivel), motivo (so se for texto legivel)
function S.disponivel()
  if desligado("sessao") then
    return false, nil
  end
  if C_DamageMeter and C_DamageMeter.IsDamageMeterAvailable then
    local ok, disp, motivo = pcall(C_DamageMeter.IsDamageMeterAvailable)
    if not ok then
      falhou("sessao", disp)
      return false, nil
    end
    local cd = S.caixa(disp)
    local cm = S.caixa(motivo)
    local texto = nil
    if type(cm.n) == "string" then
      texto = cm.n
    end
    return cd.n == true, texto
  end
  return false, nil
end

-- chama ResetAllCombatSessions, so fora de combate; devolve se chamou
function S.zerar()
  if emCombate() then
    return false
  end
  if C_DamageMeter and C_DamageMeter.ResetAllCombatSessions then
    local ok, erro = pcall(C_DamageMeter.ResetAllCombatSessions)
    if ok then
      return true
    end
    falhou("sessao", erro)
  end
  return false
end

-- ---------------------------------------------------------------------------
-- Leituras de threat e de nome
-- ---------------------------------------------------------------------------

-- caixa de UnitThreatSituation(unidade, mob); mob pode ser nil
function S.estado(unidade, mob)
  if desligado("ameaca") then
    return caixaVazia()
  end
  if UnitThreatSituation then
    -- sem mob, chama com um argumento so (nao passa nil explicito a funcao do jogo)
    local ok, v
    if mob == nil then
      ok, v = pcall(UnitThreatSituation, unidade)
    else
      ok, v = pcall(UnitThreatSituation, unidade, mob)
    end
    if ok then
      return S.caixa(v)
    end
    falhou("ameaca", v)
  end
  return caixaVazia()
end

-- captura os retornos de uma chamada protegida: ok, quantos vieram, e a lista deles
local function capturar(ok, ...)
  return ok, select("#", ...), { ... }
end

-- { veio, tanque, pct } de UnitDetailedThreatSituation(unidade, mob)
function S.detalhe(unidade, mob)
  local r = { veio = false, tanque = caixaVazia(), pct = caixaVazia() }
  if desligado("ameaca") then
    return r
  end
  if UnitDetailedThreatSituation then
    local ok, qtd, rets = capturar(pcall(UnitDetailedThreatSituation, unidade, mob))
    if ok then
      if qtd > 0 then
        r.veio = true
        r.tanque = S.caixa(rets[1])
        r.pct = S.caixa(rets[3])
      end
    else
      falhou("ameaca", rets[1])
    end
  end
  return r
end

-- caixa de UnitThreatLeadSituation(unidade, mob)
function S.lider(unidade, mob)
  if desligado("ameaca") then
    return caixaVazia()
  end
  if UnitThreatLeadSituation then
    local ok, v = pcall(UnitThreatLeadSituation, unidade, mob)
    if ok then
      return S.caixa(v)
    end
    falhou("ameaca", v)
  end
  return caixaVazia()
end

-- caixa do primeiro retorno de UnitName(unidade)
function S.nome(unidade)
  if desligado("ameaca") then
    return caixaVazia()
  end
  if UnitName then
    local ok, v = pcall(UnitName, unidade)
    if ok then
      return S.caixa(v)
    end
    falhou("ameaca", v)
  end
  return caixaVazia()
end

-- ---------------------------------------------------------------------------
-- Ralos de exibicao (secao 4). Cada um roda inteiro em pcall, devolve true se escreveu
-- no widget (o valor ou o texto vazio) e chama ns.falhou("formato", erro) se errar.
-- ---------------------------------------------------------------------------

-- a caixa tem valor para mostrar? (com o disjuntor "formato" aberto, nao tem)
local function usavel(caixa)
  if desligado("formato") then
    return false
  end
  if type(caixa) ~= "table" then
    return false
  end
  return caixa.tem == true
end

-- escreve o valor como inteiro arredondado
local function pintarInteiro(fs, caixa)
  if C_StringUtil and C_StringUtil.RoundToNearestString then
    fs:SetText(C_StringUtil.RoundToNearestString(caixa.cru))
    return true
  end
  if AbbreviateNumbers then
    fs:SetText(AbbreviateNumbers(caixa.cru))
    return true
  end
  if AbbreviateLargeNumbers then
    fs:SetText(AbbreviateLargeNumbers(caixa.cru))
    return true
  end
  fs:SetText(textoVazio())
  return true
end

-- escreve o valor abreviado
local function pintarAbrev(fs, caixa)
  if AbbreviateNumbers then
    fs:SetText(AbbreviateNumbers(caixa.cru))
    return true
  end
  if AbbreviateLargeNumbers then
    fs:SetText(AbbreviateLargeNumbers(caixa.cru))
    return true
  end
  fs:SetText(textoVazio())
  return true
end

-- escreve o valor arredondado com "%" (sem WrapString: so o numero arredondado)
local function pintarPct(fs, caixa)
  if C_StringUtil and C_StringUtil.WrapString and C_StringUtil.RoundToNearestString then
    fs:SetText(C_StringUtil.WrapString(C_StringUtil.RoundToNearestString(caixa.cru), nil, "%"))
    return true
  end
  return pintarInteiro(fs, caixa)
end

-- corpos dos ralos (rodam dentro de pcall)
local function corpoInteiro(fs, caixa)
  if not usavel(caixa) then
    fs:SetText(textoVazio())
    return true
  end
  return pintarInteiro(fs, caixa)
end

local function corpoAbrev(fs, caixa)
  if not usavel(caixa) then
    fs:SetText(textoVazio())
    return true
  end
  return pintarAbrev(fs, caixa)
end

local function corpoPct(fs, caixa)
  if not usavel(caixa) then
    fs:SetText(textoVazio())
    return true
  end
  return pintarPct(fs, caixa)
end

local function corpoBarra(barra, caixa)
  if not usavel(caixa) then
    barra:SetValue(0)
    return true
  end
  barra:SetValue(caixa.cru)
  return true
end

local function corpoSe(regiao, caixa)
  if not usavel(caixa) then
    regiao:SetAlpha(0)
    return true
  end
  regiao:SetAlphaFromBoolean(caixa.cru, 1, 0)
  return true
end

-- o inverso: visivel quando o booleano e falso
local function corpoSeNao(regiao, caixa)
  if not usavel(caixa) then
    regiao:SetAlpha(0)
    return true
  end
  regiao:SetAlphaFromBoolean(caixa.cru, 0, 1)
  return true
end

-- roda um corpo em pcall; erro vira ns.falhou("formato", erro)
local function executar(corpo, alvo, caixa)
  if not alvo then
    return false
  end
  local ok, res = pcall(corpo, alvo, caixa)
  if not ok then
    falhou("formato", res)
    return false
  end
  return res == true
end

function S.mostrarInteiro(fs, caixa)
  return executar(corpoInteiro, fs, caixa)
end

function S.mostrarAbrev(fs, caixa)
  return executar(corpoAbrev, fs, caixa)
end

-- formato: "inteiro" (padrao) ou "abrev"
function S.mostrarNumero(fs, caixa, formato)
  if formato == "abrev" then
    return executar(corpoAbrev, fs, caixa)
  end
  return executar(corpoInteiro, fs, caixa)
end

function S.mostrarPct(fs, caixa)
  return executar(corpoPct, fs, caixa)
end

function S.mostrarBarra(barra, caixa)
  return executar(corpoBarra, barra, caixa)
end

-- a regiao tem de ser filha propria, sem fade. Com inverso == true, aparece quando o booleano e falso.
function S.mostrarSe(regiao, caixa, inverso)
  if inverso == true then
    return executar(corpoSeNao, regiao, caixa)
  end
  return executar(corpoSe, regiao, caixa)
end
