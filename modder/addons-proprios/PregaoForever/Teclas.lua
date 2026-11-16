-- Teclas.lua (PregaoForever): botoes nomeados PregaoForeverTecla<X>, bindings so com a janela aberta e fora de combate,
-- filtro de repeticao, pausa com foco em caixa de texto, H alterna KEYS ON e KEYS HELD. Onda 2: so navegacao e o Y de salvar.
-- Contrato: ARQUITETURA.md, secao 3.11. Nenhuma funcao de acao aqui (regra 6); F1, F2 e F4 ficam sem binding ate a onda 3.
local _, ns = ...
ns.teclas = ns.teclas or {}
local T = ns.teclas

T.LISTA = { "L", "N", "U", "I", "O", "K", "H", "F3", "F5", "Y" }
-- rotulo clicavel de cada botao (toda tecla tem botao com o rotulo dela)
T.ROTULO = {
  L = "L look again", N = "N next", U = "U back", I = "I why", O = "O more", K = "K skip", H = "H hold",
  F3 = "F3 MINE", F5 = "F5 SESSION", Y = "Y save now (reloads the interface)",
}
-- campo do Config.teclas de cada botao
T.CAMPO = {
  L = "olhar", N = "proxima", U = "anterior", I = "porque", O = "mais", K = "pular", H = "segurar",
  F3 = "visao_3", F5 = "visao_5", Y = "confirmar",
}
T.botoes = {}
T.ultimo = {}        -- GetTime da ultima tecla aceita, por botao
T.ultimaTecla = nil  -- letra da ultima tecla aceita, para o rodape
T.pendente = false   -- ligar ou soltar ficou para o PLAYER_REGEN_ENABLED
T.ligado = false
T.pausado = false
T.held = false

-- tecla do jogo ligada ao botao x (Config.teclas, senao a propria letra)
function T.tecla(x)
  local mapa = ns.cfg and ns.cfg.teclas
  local k = mapa and mapa[T.CAMPO[x]]
  if type(k) == "string" and k ~= "" then return k end
  return x
end

-- Cria os dez botoes dentro do quadro pai (quem posiciona e a Janela).
function T.criar(pai)
  for i = 1, #T.LISTA do
    local x = T.LISTA[i]
    if not T.botoes[x] then
      local b = ns.ui.botao(pai, "PregaoForeverTecla" .. x, T.ROTULO[x], 64, 24)
      b:SetScript("OnClick", ns.seguro(function() T.clicar(x) end))
      T.botoes[x] = b
    end
  end
  return T.botoes
end

-- Tudo em repouso: nenhuma maquina em andamento, nenhuma acao sem eco, nenhum folego aberto.
function T.repouso()
  local pe = ns.ui.ler("pedidos", "estado")
  if type(pe) == "table" then
    if pe.fase ~= nil and pe.fase ~= "PARADO" then return false end
    if pe.emVoo then return false end
  end
  local ve = ns.ui.ler("varredura", "estado")
  if type(ve) == "table" then
    local f = ve.fase
    if f == "PROPRIOS" or f == "RESUMO" or f == "TRIAGEM" or f == "FOCO" then return false end
  end
  local ev = ns.ui.ler("ecos", "emVoo")
  if ev ~= nil and ev ~= false then return false end
  return true
end

-- Foco do teclado numa caixa de texto: as teclas nao disparam e a faixa diz Keys paused.
function T.verFoco()
  local f = nil
  if GetCurrentKeyBoardFocus then f = GetCurrentKeyBoardFocus() end
  local p = (f ~= nil and f ~= false)
  if p ~= T.pausado then
    T.pausado = p
    if p then
      ns.marcarFaixa("pausa", "Keys paused")
      if ns.sonda and ns.sonda.aoPausa then ns.sonda.aoPausa() end
    else
      ns.marcarFaixa("pausa", nil)
    end
  end
  return p
end

function T.alternarHeld()
  T.held = not T.held
  if T.held then ns.marcarFaixa("held", "KEYS HELD") else ns.marcarFaixa("held", nil) end
end

-- Uma tecla aceita: repeticao, pausa, presenca do dono e a funcao da tecla.
function T.clicar(x)
  if not (ns.janela and ns.janela.aberta and ns.janela.aberta()) then return end
  if x == "Y" and not (ns.telas and ns.telas.visao == "session") then return end
  if T.verFoco() then return end
  local g = ns.cfg and ns.cfg.guardas
  local ms = (g and g.repeticao_ms) or 400
  local agora = ns.mono()
  local u = T.ultimo[x]
  if u and (agora - u) * 1000 < ms then return end
  T.ultimo[x] = agora
  T.ultimaTecla = x
  if ns.pedidos and ns.pedidos.tecla then ns.pedidos.tecla() end
  T.executar(x)
  ns.sujo("tela")
end

function T.executar(x)
  if x == "L" then
    if ns.varredura and ns.varredura.tecla then ns.varredura.tecla() end
  elseif x == "N" then
    ns.telas.mover(1)
  elseif x == "U" then
    ns.telas.mover(-1)
  elseif x == "I" then
    ns.telas.porque()
  elseif x == "O" then
    ns.telas.mais()
  elseif x == "K" then
    ns.telas.pular()
  elseif x == "H" then
    T.alternarHeld()
  elseif x == "F3" then
    ns.telas.mostrar("mine")
  elseif x == "F5" then
    ns.telas.mostrar("session")
  elseif x == "Y" then
    ns.janela.salvar()
  end
end

-- Bindings de sobreposicao: so com a janela aberta e fora de combate (regra 16).
function T.ligar()
  if not (ns.janela and ns.janela.aberta and ns.janela.aberta()) then return end
  if ns.emCombate() then
    T.pendente = true
    return
  end
  T.pendente = false
  local dono = ns.janela.quadro()
  for i = 1, #T.LISTA do
    local x = T.LISTA[i]
    SetOverrideBindingClick(dono, true, T.tecla(x), "PregaoForeverTecla" .. x)
  end
  T.ligado = true
end

function T.soltar()
  if ns.emCombate() then
    T.pendente = true
    return
  end
  T.pendente = false
  local dono = ns.janela and ns.janela.quadro and ns.janela.quadro()
  if dono then ClearOverrideBindings(dono) end
  T.ligado = false
end

-- Saiu do combate: o estado final da janela decide.
ns.ao("PLAYER_REGEN_ENABLED", function()
  if not T.pendente then return end
  T.pendente = false
  if ns.janela and ns.janela.aberta() and ns.janela.leilao then T.ligar() else T.soltar() end
end)
