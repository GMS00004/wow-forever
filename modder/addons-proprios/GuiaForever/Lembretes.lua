-- GuiaForever: lembretes de buff fora de combate, marcos de nivel e macros refeitas por magia
-- (1.3; contrato em ARQUITETURA.md, secao 12.4).
-- Nenhum outro arquivo depende deste existir (regra 3). Classe sem os campos `lembretes` e `marcos`
-- nos dados (o cacador): nenhum item, nenhum timer, nenhuma macro.

local _, ns = ...

-- Lua 5.1: xpcall nao repassa argumentos, por isso o fechamento (regra 10).
local function seguro(fn, ...)
  if type(fn) ~= "function" then return false end
  local n = select("#", ...)
  local args = { ... }
  return xpcall(function() return fn(unpack(args, 1, n)) end, geterrorhandler())
end

local ocultos = {} -- chave -> true; so ate o proximo /reload (de proposito, fora do DB)
local ultimoEstado = nil

local function dadosDaClasse()
  return ns.dicas and ns.dicas() or nil
end

local function nivelAtual()
  return (ns.estado and tonumber(ns.estado.nivel)) or (UnitLevel and UnitLevel("player")) or 1
end

-- Buff do jogador. Excecao unica da regra 5 (12.4): guarda de combate na primeira linha e issecretvalue.
-- Devolve true/false, ou nil quando nao da para saber (em combate, erro, valor secreto).
local function auraAtiva(nome)
  if ns.emCombate() then return nil end
  if type(nome) ~= "string" or not (C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName) then return nil end
  local ok, resultado = pcall(C_UnitAuras.GetAuraDataBySpellName, "player", nome, "HELPFUL")
  if not ok then return nil end
  if issecretvalue and issecretvalue(resultado) then return nil end
  return resultado ~= nil
end

-- Entradas de `lembretes` que estao valendo agora e cujo buff falta.
local function lembretesFaltando()
  local d = dadosDaClasse()
  local lista = d and d.lembretes
  local r = {}
  if type(lista) ~= "table" then return r end
  local nivel = nivelAtual()
  for i, e in ipairs(lista) do
    if type(e) == "table" and e.magia and (tonumber(e.nivel) or 1) <= nivel and ns.conhece(e.magia)
       and auraAtiva(e.magia) == false then
      r[#r + 1] = { i = i, e = e }
    end
  end
  return r
end

local function assinatura(lista)
  local t = {}
  for _, x in ipairs(lista) do t[#t + 1] = x.i end
  return table.concat(t, ",")
end

local function abrirTeclas()
  if ns.abrirAba then ns.abrirAba("teclas") end
end

local function itensLembretes()
  local itens = {}
  for _, x in ipairs(lembretesFaltando()) do
    local e = x.e
    local chave = "lembrete:" .. e.magia
    if not ocultos[chave] then
      local tecla = ns.teclaDe and ns.teclaDe(e.magia) or nil
      itens[#itens + 1] = {
        chave = chave, prio = 15, cor = "vermelho",
        icone = (ns.iconeMagia and e.id and ns.iconeMagia(e.id)) or nil,
        texto = e.texto or (e.magia .. " is off"),
        dica = { "Checked out of combat only.", "Key: " .. (tecla or "not on your bars") },
        fonte = e.fonte, aba = "teclas",
        aoOcultar = function() ocultos[chave] = true end,
        botao = { rotulo = tecla or "Keys", acao = abrirTeclas },
      }
    end
  end
  return itens
end

local function marcoFeito(m)
  if m.magia then return ns.conhece(m.magia) and true or false end
  if m.missao then return ns.missao(m.missao) == "feita" end
  return false
end

local function itensMarcos()
  local d = dadosDaClasse()
  local lista = d and d.marcos
  local itens = {}
  if type(lista) ~= "table" then return itens end
  local nivel = nivelAtual()
  for i, m in ipairs(lista) do
    if type(m) == "table" and m.nivel and m.texto and m.fonte then
      local nv = tonumber(m.nivel) or 1
      local acionavel = (m.magia or m.missao) and true or false
      local ate = tonumber(m.ate) or (acionavel and 60 or nv)
      if nivel >= nv and nivel <= ate and not (acionavel and marcoFeito(m)) then
        local icone = (ns.iconeMagia and m.id and ns.iconeMagia(m.id)) or "Interface\\Icons\\INV_Misc_Book_11"
        local item = {
          chave = "marco:" .. nv .. ":" .. i,
          prio = acionavel and 30 or 90, cor = acionavel and "laranja" or "azul",
          icone = icone, texto = m.texto, dica = { m.texto }, fonte = m.fonte, aba = "agora",
        }
        if m.mapa and m.x and m.y and ns.seta then
          item.botao = { rotulo = "Arrow", acao = function() ns.seta(m.mapa, m.x, m.y, m.npc or m.texto) end }
        end
        itens[#itens + 1] = item
      end
    end
  end
  return itens
end

-- Verificacao periodica (sem UNIT_AURA): so chama o painel quando o estado de alguma entrada mudou.
local function verificar()
  if ns.emCombate() then return end
  local novo = assinatura(lembretesFaltando())
  if novo ~= ultimoEstado then
    ultimoEstado = novo
    if ns.agora and ns.agora.atualizar then ns.agora.atualizar() end
  end
end

-- Macros por magia: a primeira magia conhecida de `magias` entra no %s do `modelo`.
local function refazerMacros()
  if ns.emCombate() or not ns.macroGerenciada then return end
  local dm = GuiaForeverMacros and GuiaForeverMacros[ns.classe()]
  local lista = dm and dm.gerenciadas
  if type(lista) ~= "table" then return end
  for _, g in ipairs(lista) do
    if type(g) == "table" and g.nome and type(g.magias) == "table" and type(g.modelo) == "string" then
      local achada
      for _, m in ipairs(g.magias) do
        if ns.conhece(m) then achada = m; break end
      end
      if achada then
        local ok, corpo = pcall(string.format, g.modelo, achada)
        if ok then
          seguro(ns.macroGerenciada, g.nome, (ns.iconeMagia and ns.iconeMagia(achada)) or 134400, corpo)
        end
      end
    end
  end
end

local function pedirMacros(chave, segundos)
  ns.agendar(chave, segundos, function()
    ns.foraDeCombate("lembretes:macros", refazerMacros)
  end)
end

if ns.agora and ns.agora.provedor then
  ns.agora.provedor({ id = "lembretes", eventos = { "PLAYER_LEVEL_UP", "SPELLS_CHANGED" }, itens = itensLembretes })
  ns.agora.provedor({ id = "marcos", eventos = { "PLAYER_LEVEL_UP", "SPELLS_CHANGED", "QUEST_TURNED_IN", "PLAYER_ENTERING_WORLD" }, itens = itensMarcos })
end

ns.ao("PLAYER_LOGIN", function()
  local d = dadosDaClasse()
  if d and type(d.lembretes) == "table" and C_Timer and C_Timer.NewTicker then
    C_Timer.NewTicker(4, function() seguro(verificar) end)
  end
  pedirMacros("lembretes:macrosLogin", 9)
end)

ns.ao("PLAYER_REGEN_ENABLED", function()
  local d = dadosDaClasse()
  if d and type(d.lembretes) == "table" then ns.agendar("lembretes:verificar", 1, verificar) end
end)

ns.ao("SPELLS_CHANGED", function()
  local d = dadosDaClasse()
  if d and type(d.lembretes) == "table" then ns.agendar("lembretes:verificar", 1, verificar) end
  pedirMacros("lembretes:macrosSpells", 2)
end)
