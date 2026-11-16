-- CentralForever/Estados.lua: maestro do addon. Eventos, maquina de estados, tique de leitura em
-- combate e o comando /central. Contrato: CONTRATO.md, secoes 3.9, 8 e 9. Lua 5.1, so ASCII.
local _, ns = ...

local E = {}
ns.estados = E

-- Estados: OCIOSO, EM_COMBATE, SAINDO, RESUMO e AMOSTRA (amostra de login)
local estado = "OCIOSO"
local geracao = 0        -- muda a cada transicao; invalida timers antigos
local testeId = 0        -- invalida o retorno de /central test
local tiqueObj = nil
local inicioLuta = 0
local sujoDano = false
local sujoThreat = false
local ultThreat = 0
local ultDano = 0
local ultSeg = 0
local danoIndisponivel = false
local amostraFeita = false
local cargaFeita = false
local cargaPendente = false

local NOMES = {
  OCIOSO = "idle",
  EM_COMBATE = "in combat",
  SAINDO = "leaving combat",
  RESUMO = "showing summary",
  AMOSTRA = "login sample",
}

local function cfg()
  return ns.cfg or {}
end

local function sub(nome)
  local t = cfg()[nome]
  if type(t) == "table" then return t end
  return {}
end

local function ligado()
  return cfg().ligado ~= false
end

local function legivel(v)
  if issecretvalue then
    local ok, s = pcall(issecretvalue, v)
    if not ok or s then return false end
  end
  return true
end

-- ---------------------------------------------------------------------------
-- Chamadas guardadas aos outros modulos
-- ---------------------------------------------------------------------------

local function pModo(m, seg)
  if ns.painel and ns.painel.modo then ns.painel.modo(m, seg) end
end

local function pThreatOculto(seg)
  if ns.painel and ns.painel.threatOculto then ns.painel.threatOculto(seg) end
end

local function conta(campo, n)
  if ns.diario and ns.diario.conta then ns.diario.conta(campo, n) end
end

local function anota(tipo, t)
  if ns.diario and ns.diario.anota then ns.diario.anota(tipo, t) end
end

local function temResumo()
  local p = ns.dbPersonagem()
  return type(p) == "table" and type(p.ultima) == "table"
end

local function mostraResumo()
  if ns.medidor and ns.medidor.mostrarResumo then ns.medidor.mostrarResumo() end
end

-- ---------------------------------------------------------------------------
-- Tique de leitura (so em combate)
-- ---------------------------------------------------------------------------

local function tique()
  if estado ~= "EM_COMBATE" then return end
  local agora = GetTime()
  local cad = sub("cadencia")

  -- threat: sujo, ou a cada cadencia.threat
  if sujoThreat or agora - ultThreat >= (cad.threat or 0.25) then
    sujoThreat = false
    ultThreat = agora
    if ns.ameaca and ns.ameaca.atualizar then
      local visao = ns.ameaca.atualizar(agora)
      if ns.painel and ns.painel.threat then ns.painel.threat(visao) end
      if type(visao) == "table" and visao.pulso then conta("pulsos", 1) end
    end
  end

  -- dano: sujo e passou cadencia.dano, ou a cada 1 s
  if not danoIndisponivel then
    local desde = agora - ultDano
    if (sujoDano and desde >= (cad.dano or 0.5)) or desde >= 1 then
      sujoDano = false
      ultDano = agora
      if ns.medidor and ns.medidor.atualizar then ns.medidor.atualizar() end
    end
  end

  -- tempo: quando o segundo mudou
  local seg = math.floor(agora - inicioLuta)
  if seg ~= ultSeg then
    ultSeg = seg
    if ns.medidor and ns.medidor.tempo then ns.medidor.tempo(agora) end
  end
end

local function paraTique()
  if tiqueObj then
    tiqueObj:Cancel()
    tiqueObj = nil
  end
end

-- ---------------------------------------------------------------------------
-- Transicoes
-- ---------------------------------------------------------------------------

local function entrar()
  if estado == "EM_COMBATE" then return end
  -- voltou ao combate durante SAINDO, RESUMO ou amostra: aborta a captura
  if estado ~= "OCIOSO" then
    if ns.medidor and ns.medidor.cancelarCaptura then ns.medidor.cancelarCaptura() end
  end
  geracao = geracao + 1
  testeId = testeId + 1
  estado = "EM_COMBATE"
  local agora = GetTime()
  inicioLuta = agora
  sujoDano = false
  sujoThreat = true
  ultThreat = agora
  ultDano = agora
  ultSeg = 0
  danoIndisponivel = false

  local papel
  if ns.ameaca and ns.ameaca.papel then papel = ns.ameaca.papel() end
  if ns.diario and ns.diario.abrirLuta then ns.diario.abrirLuta({ papel = papel }) end
  if ns.medidor and ns.medidor.aoEntrar then ns.medidor.aoEntrar(agora) end
  if ns.ameaca and ns.ameaca.aoEntrar then ns.ameaca.aoEntrar(agora) end
  pModo("combate")

  -- medidor indisponivel: campos de dano em vazio e motivo no diario; o threat segue
  if ns.segredo and ns.segredo.disponivel then
    local ok, motivo = ns.segredo.disponivel()
    if not ok then
      danoIndisponivel = true
      local vazio = cfg().vazio or "--"
      if ns.painel and ns.painel.texto then
        ns.painel.texto("dps", vazio)
        ns.painel.texto("luta", vazio)
        ns.painel.texto("total", vazio)
      end
      if ns.diario and ns.diario.marca then
        ns.diario.marca("dano", "disponivel", false)
        if type(motivo) == "string" then ns.diario.marca("dano", "motivo", motivo) end
      end
    end
  end

  paraTique()
  tiqueObj = ns.tique(sub("cadencia").tique or 0.25, tique)
end

local function sair()
  if estado ~= "EM_COMBATE" then return end
  paraTique()
  geracao = geracao + 1
  local minha = geracao
  estado = "SAINDO"
  local agora = GetTime()
  local inicio = inicioLuta

  if ns.ameaca and ns.ameaca.aoSair then ns.ameaca.aoSair() end
  pThreatOculto(sub("threat").fadeSeg or 0.4)
  pModo("pos")

  local function feito()
    if geracao ~= minha or estado ~= "SAINDO" then return end
    local dur = math.floor(agora - inicio + 0.5)
    if ns.convivencia and ns.convivencia.aoFimDeLuta and ns.medidor and ns.medidor.temLinha then
      ns.convivencia.aoFimDeLuta(ns.medidor.temLinha(), dur)
    end
    if ns.diario and ns.diario.fecharLuta then
      ns.diario.fecharLuta({ dur = dur })
    end
    ns.depois(sub("resumo").acesoSeg or 3, function()
      if geracao ~= minha or estado ~= "SAINDO" then return end
      if ns.emCombate() then return end
      estado = "RESUMO"
      mostraResumo()
      pModo("resumo")
    end)
  end

  if ns.medidor and ns.medidor.aoSair then
    ns.medidor.aoSair(agora, feito)
  else
    feito()
  end
end

-- Carga do diario: uma vez por login, fora de combate
local function tentaCarga()
  if cargaFeita then return end
  if ns.emCombate() then
    cargaPendente = true
    return
  end
  cargaPendente = false
  cargaFeita = true
  if ns.diario and ns.diario.carga then ns.diario.carga() end
end

-- O que se faz ao sair do combate (chamado pelos dois gatilhos)
local function aposCombate()
  if ns.convivencia and ns.convivencia.pendente and ns.convivencia.pendente() then
    if ns.convivencia.aplicar then ns.convivencia.aplicar() end
  end
  if cargaPendente then tentaCarga() end
end

local function amostraDeLogin()
  geracao = geracao + 1
  local minha = geracao
  estado = "AMOSTRA"
  mostraResumo()
  pModo("pos")
  ns.depois(sub("login").mostrarSeg or 4, function()
    if geracao ~= minha or estado ~= "AMOSTRA" then return end
    if ns.emCombate() then return end
    if temResumo() then
      estado = "RESUMO"
      mostraResumo()
      pModo("resumo")
    else
      estado = "OCIOSO"
      pModo("oculto")
    end
  end)
end

-- ---------------------------------------------------------------------------
-- Eventos
-- ---------------------------------------------------------------------------

ns.ao("PLAYER_ENTERING_WORLD", function()
  if not ligado() then
    if ns.convivencia and ns.convivencia.aplicar then ns.convivencia.aplicar() end
    return
  end
  if ns.painel and ns.painel.criar then ns.painel.criar() end
  if ns.convivencia and ns.convivencia.aplicar then ns.convivencia.aplicar() end
  if not cargaFeita then ns.depois(2, tentaCarga) end

  if ns.emCombate() then
    amostraFeita = true
    entrar()
    return
  end
  if estado == "EM_COMBATE" then
    sair()
    aposCombate()
    return
  end
  if not amostraFeita then
    amostraFeita = true
    amostraDeLogin()
  end
end)

ns.ao("PLAYER_REGEN_DISABLED", function()
  if not ligado() then return end
  entrar()
end)

ns.ao("PLAYER_REGEN_ENABLED", function()
  if not ligado() then return end
  sair()
  aposCombate()
end)

ns.ao("ADDON_RESTRICTION_STATE_CHANGED", function(_, tipo, est)
  if not ligado() then return end
  local en = ns.enum or {}
  local rc = en.restricao and en.restricao.Combat
  local es = en.estado or {}
  if tipo == rc then
    if est == es.Activating or est == es.Active then
      entrar()
    elseif est == es.Inactive then
      sair()
      aposCombate()
    end
  else
    anota("restricao", { restricao = tipo, estado = est })
  end
end)

ns.ao("DAMAGE_METER_COMBAT_SESSION_UPDATED", function()
  if not ligado() then return end
  sujoDano = true
  conta("eventosDano", 1)
end)

ns.ao("DAMAGE_METER_CURRENT_SESSION_UPDATED", function()
  if not ligado() then return end
  sujoDano = true
  -- em luta vira contador do registro da luta (o evento pode ser frequente); fora dela, entrada avulsa
  if estado == "EM_COMBATE" then
    conta("novasSessoes", 1)
  else
    anota("nova_sessao", {})
  end
end)

ns.ao("DAMAGE_METER_RESET", function()
  if not ligado() then return end
  sujoDano = true
  anota("reset", {})
end)

-- so interessa a unidade do jogador, do pet, do alvo ou do grupo
local function unidadeInteressa(u)
  if type(u) ~= "string" or not legivel(u) then return false end
  if u == "player" or u == "pet" or u == "target" then return true end
  local lista = sub("threat").unidades
  if type(lista) == "table" then
    for i = 1, #lista do
      if lista[i] == u then return true end
    end
  end
  return false
end

local function aoThreat(_, unidade)
  if not ligado() then return end
  if not unidadeInteressa(unidade) then return end
  sujoThreat = true
  conta("eventosAmeaca", 1)
end

ns.ao("UNIT_THREAT_LIST_UPDATE", aoThreat)
ns.ao("UNIT_THREAT_SITUATION_UPDATE", aoThreat)

ns.ao("PLAYER_TARGET_CHANGED", function()
  if not ligado() then return end
  if ns.ameaca and ns.ameaca.aoAlvo then ns.ameaca.aoAlvo(GetTime()) end
  sujoThreat = true
end)

local function aoGrupo()
  if not ligado() then return end
  if ns.ameaca and ns.ameaca.aoGrupo then ns.ameaca.aoGrupo() end
end

ns.ao("GROUP_ROSTER_UPDATE", aoGrupo)
ns.ao("UNIT_PET", aoGrupo)

ns.ao("ADDON_ACTION_BLOCKED", function(_, addon, funcao)
  if not ligado() then return end
  if type(addon) ~= "string" or not legivel(addon) or addon ~= "CentralForever" then return end
  local nome = "?"
  if type(funcao) == "string" and legivel(funcao) then nome = funcao end
  anota("bloqueio", { funcao = nome })
end)

-- ---------------------------------------------------------------------------
-- Comando /central
-- ---------------------------------------------------------------------------

local function estadoPosTeste()
  if estado == "RESUMO" then
    mostraResumo()
    pModo("resumo")
  elseif estado == "SAINDO" or estado == "AMOSTRA" then
    pModo("pos")
  else
    pModo("oculto")
  end
end

local function cmdStatus()
  ns.msg("State: " .. (NOMES[estado] or estado))
  local papel = "?"
  if ns.ameaca and ns.ameaca.papel then papel = tostring(ns.ameaca.papel()) end
  ns.msg("Threat role: " .. papel)
  if ns.segredo and ns.segredo.disponivel then
    local ok, motivo = ns.segredo.disponivel()
    if ok then
      ns.msg("Damage meter: available")
    elseif type(motivo) == "string" then
      ns.msg("Damage meter: unavailable (" .. motivo .. ")")
    else
      ns.msg("Damage meter: unavailable")
    end
  end
  local cv = "?"
  if C_CVar and C_CVar.GetCVar then
    local ok, v = pcall(C_CVar.GetCVar, "damageMeterEnabled")
    if ok and type(v) == "string" and legivel(v) then cv = v end
  end
  ns.msg("Blizzard meter CVar (damageMeterEnabled): " .. cv)
  local db = ns.db()
  ns.msg("Fights in the journal: " .. tostring(#db.diario.lutas))
end

local function cmdTest()
  if ns.emCombate() then
    ns.msg("Cannot show the sample during combat.")
    return
  end
  if not (ns.painel and ns.painel.existe and ns.painel.existe()) then
    ns.msg("The panel is not available.")
    return
  end
  testeId = testeId + 1
  local meu = testeId
  pModo("amostra")
  ns.msg("Showing the sample panel.")
  ns.depois(sub("amostra").seg or 10, function()
    if testeId ~= meu or estado == "EM_COMBATE" or ns.emCombate() then return end
    estadoPosTeste()
  end)
end

local function cmdMeter()
  local visivel = ns.convivencia and ns.convivencia.alternar and ns.convivencia.alternar()
  if visivel then
    ns.msg("The Blizzard damage meter window will be shown.")
  else
    ns.msg("The Blizzard damage meter window will be hidden.")
  end
  if ns.convivencia and ns.convivencia.pendente and ns.convivencia.pendente() then
    ns.msg("In combat: the change applies when combat ends.")
  end
end

local function cmdReset()
  if ns.emCombate() then
    ns.msg("Cannot reset the damage meter during combat.")
    return
  end
  if ns.segredo and ns.segredo.zerar and ns.segredo.zerar() then
    ns.msg("Damage meter reset.")
  else
    ns.msg("The damage meter could not be reset.")
  end
end

local function comando(msg)
  local arg = string.lower(string.match(tostring(msg or ""), "^%s*(%S*)") or "")
  if arg == "" then
    cmdStatus()
  elseif arg == "test" or arg == "teste" then
    cmdTest()
  elseif arg == "meter" then
    cmdMeter()
  elseif arg == "reset" then
    cmdReset()
  else
    ns.msg("Usage: /central [test | meter | reset]")
  end
end

SLASH_CENTRALFOREVER1 = "/central"
if SlashCmdList then
  SlashCmdList["CENTRALFOREVER"] = function(msg)
    xpcall(comando, geterrorhandler(), msg)
  end
end
