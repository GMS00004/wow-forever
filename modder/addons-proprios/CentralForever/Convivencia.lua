-- CentralForever/Convivencia.lua: esconde a janela nativa do medidor da Blizzard pelo CVar dela
-- (damageMeterEnabled), guardando o valor anterior por personagem. Contrato: secao 3.8.
-- Unico arquivo que grava CVar. Lua 5.1, so ASCII.
local _, ns = ...

local C = {}
ns.convivencia = C

local pendente = false

local function cfg()
  return ns.cfg or {}
end

local function ligado()
  return cfg().ligado ~= false
end

-- Valor atual do CVar como texto legivel, ou nil
local function lerCVar()
  if not (C_CVar and C_CVar.GetCVar) then return nil end
  local ok, v = pcall(C_CVar.GetCVar, "damageMeterEnabled")
  if not ok then return nil end
  if issecretvalue then
    local ok2, s = pcall(issecretvalue, v)
    if not ok2 or s then return nil end
  end
  if type(v) == "string" then return v end
  return nil
end

-- Unica gravacao de CVar do addon. Devolve true se gravou.
local function gravar(valor)
  if ns.emCombate() then pendente = true return end
  if not (C_CVar and C_CVar.SetCVar) then return false end
  local ok = pcall(C_CVar.SetCVar, "damageMeterEnabled", valor)
  return ok and true or false
end

function C.pendente()
  return pendente
end

function C.aplicar()
  if ns.emCombate() then
    pendente = true
    return
  end
  pendente = false
  local p = ns.dbPersonagem()
  local quer = ligado() and cfg().janelaNativa == "esconder" and not p.nativaVisivel
  if quer then
    local atual = lerCVar()
    if p.cvarAntes == nil and atual ~= nil then
      p.cvarAntes = atual
    end
    if atual ~= nil and atual ~= "0" then
      gravar("0")
    end
  elseif p.cvarAntes ~= nil then
    if gravar(p.cvarAntes) then
      p.cvarAntes = nil
    else
      pendente = true
    end
  end
end

function C.alternar()
  local p = ns.dbPersonagem()
  p.nativaVisivel = not p.nativaVisivel
  C.aplicar()
  return p.nativaVisivel
end

-- Reserva: o motor nao coleta com a janela nativa desligada. So dispara depois de varias lutas
-- seguidas, cada uma longa o bastante, sem a linha do jogador e com o CVar em "0" por causa do
-- addon. Uma luta sem dano (puxar e fingir de morto, por exemplo) sozinha nao prova nada. Se a
-- linha aparecer uma vez com o CVar em "0", o motor coleta sem a janela e a reserva nunca mais roda.
function C.aoFimDeLuta(teveLinha, dur)
  if not ligado() or cfg().janelaNativa ~= "esconder" then return end
  local p = ns.dbPersonagem()
  if p.nativaVisivel then return end
  if lerCVar() ~= "0" then return end
  if teveLinha then
    p.coletaSemJanela = true
    p.semLinha = 0
    return
  end
  if not cfg().reservaCVar then return end
  if p.reservaFeita or p.coletaSemJanela then return end
  -- so vale se o addon e quem manteve o CVar em 0 (o valor anterior era outro)
  local antes = p.cvarAntes
  if antes == nil or antes == "0" then return end
  local durMin = cfg().reservaDurMin
  if type(durMin) ~= "number" then durMin = 10 end
  if type(dur) ~= "number" or dur < durMin then return end
  p.semLinha = (p.semLinha or 0) + 1
  local lutas = cfg().reservaLutas
  if type(lutas) ~= "number" then lutas = 3 end
  if p.semLinha < lutas then return end
  p.reservaFeita = true
  p.nativaVisivel = true
  C.aplicar()
  if ns.diario and ns.diario.anota then
    ns.diario.anota("reserva", { antes = antes })
  end
  ns.msg("No damage data was collected in the last fights while the Blizzard meter was hidden, so it was turned back on. Use /central meter to hide it again.")
end
