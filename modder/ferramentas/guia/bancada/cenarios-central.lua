-- Passos e cenarios da bancada da central (CONTRATO.md, secao 11.4). Lua 5.3 no fengari; so ASCII.
-- Carregado por chunk "=cenarios-central" depois de api-central.lua. Define __cenarios:
--   lista, porId, listar(), passosDe(B), afirmacoesDe(B, p).
-- Cada cenario: { id, titulo, jogo, chaves, cfg, api, dbInicial, passos(p), afirma(a, p) }.
-- Os passos medem o painel e guardam em p.m; as afirmacoes so leem p.m, o banco e o ambiente.

local C = { lista = {}, porId = {} }
__cenarios = C

local function def(t)
  C.lista[#C.lista + 1] = t
  C.porId[t.id] = t
end

function C.listar()
  local linhas = {}
  for _, c in ipairs(C.lista) do linhas[#linhas + 1] = c.id .. "  " .. c.titulo end
  return table.concat(linhas, "\n")
end

local CHAVE = "Rastro-Reino"

-- ---------------------------------------------------------------------------
-- Passos
-- ---------------------------------------------------------------------------

function C.passosDe(B)
  local J = B.J
  local med = B.med
  local p = { m = {} }

  local TIPOS = { Combat = 0, Encounter = 1, ChallengeMode = 2, PvPMatch = 3, Map = 4, Chat = 5 }
  local ESTADOS = { Inactive = 0, Activating = 1, Active = 2 }

  function p.agora() return B.agoraSeg() end
  function p.avancar(seg) B.avancar(seg) end
  function p.foto(nome) B.foto(nome) end

  function p.alvo(t)
    t = t or {}
    local amigo = t.amigo == true
    J.alvo = {
      nome = t.nome or (amigo and "Parceiro" or "Javali"),
      hostil = (not amigo) and (t.hostil ~= false),
      morto = t.morto == true,
      chefe = t.chefe == true,
      classificacao = t.chefe and "worldboss" or "normal",
      classe = "WARRIOR",
    }
    B.disparar("PLAYER_TARGET_CHANGED")
  end

  function p.semAlvo()
    J.alvo = nil
    B.disparar("PLAYER_TARGET_CHANGED")
  end

  function p.entrarCombate()
    if J.emCombate then return end
    J.emCombate = true
    if B.limpeza then B.limpeza.cancelado = true; B.limpeza = nil end
    med.proximoId = med.proximoId + 1
    if med.atual then med.expirada = med.atual end
    med.atual = { id = med.proximoId, jog = 0, pet = 0, ini = B.agora() }
    med.currentVazia = false
    B.novaLuta()
    J.restricoes[0] = 1
    B.disparar("ADDON_RESTRICTION_STATE_CHANGED", 0, 1)
    B.disparar("PLAYER_REGEN_DISABLED")
    J.restricoes[0] = 2
    B.disparar("ADDON_RESTRICTION_STATE_CHANGED", 0, 2)
  end

  function p.dano(t)
    t = t or {}
    if not J.emCombate or not med.atual then error("passo dano fora de combate", 0) end
    local coleta = not (J.cvars.damageMeterEnabled == "0" and B.chaves.U9 == "naocoleta")
    if coleta then
      local j, pe = t.jogador or 0, t.pet or 0
      med.atual.jog = med.atual.jog + j
      med.atual.pet = med.atual.pet + pe
      med.overall.jog = med.overall.jog + j
      med.overall.pet = med.overall.pet + pe
    end
    B.disparar("DAMAGE_METER_COMBAT_SESSION_UPDATED", 0, 0)
    B.disparar("DAMAGE_METER_COMBAT_SESSION_UPDATED", 0, med.atual.id)
  end

  -- ameaca{ player = { estado, pct, tanque, geral, lider }, party1 = {...}, pet = false }
  function p.ameaca(t)
    local ks = {}
    for k in pairs(t) do ks[#ks + 1] = k end
    table.sort(ks)
    for _, unit in ipairs(ks) do
      local ent = t[unit]
      if ent == false then J.ameaca[unit] = nil else J.ameaca[unit] = ent end
      B.disparar("UNIT_THREAT_SITUATION_UPDATE", unit)
    end
    B.disparar("UNIT_THREAT_LIST_UPDATE", "target")
  end

  function p.sairCombate(t)
    t = t or {}
    if not J.emCombate then return end
    J.emCombate = false
    B.fecharLuta()
    local s = med.atual
    if s and not s.fim then
      s.fim = B.agora()
      med.overallDur = med.overallDur + (s.fim - s.ini) / 1000000
    end
    if t.currentVazia then med.currentVazia = true end
    B.disparar("PLAYER_REGEN_ENABLED")
    local atraso = t.atrasoRestricao
    if atraso == nil then atraso = B.chaves.U8 end
    p.m.tRestricaoSai = B.agoraSeg() + atraso
    local function limpar()
      if J.emCombate then return end
      B.limpeza = nil
      J.restricoes[0] = 0
      B.disparar("ADDON_RESTRICTION_STATE_CHANGED", 0, 0)
    end
    if atraso <= 0 then limpar() else B.limpeza = B.agendar(atraso, limpar) end
  end

  -- restricao{ tipo = "Map", estado = "Active" } (ou numeros; ou { "Map", "Active" })
  function p.restricao(t)
    local tipo = t.tipo or t[1]
    local estado = t.estado or t[2]
    tipo = TIPOS[tipo] or tipo
    estado = ESTADOS[estado] or estado
    J.restricoes[tipo] = estado
    B.disparar("ADDON_RESTRICTION_STATE_CHANGED", tipo, estado)
  end

  function p.morrer()
    J.morto = true
    B.disparar("PLAYER_DEAD")
    if J.emCombate then p.sairCombate{} end
  end

  function p.reviver()
    J.morto = false
    B.disparar("PLAYER_ALIVE")
  end

  function p.petMorre()
    if J.pet then J.pet.existe = false end
    J.ameaca.pet = nil
    B.disparar("UNIT_PET", "player")
  end

  function p.recarregar() B.recarregar() end

  function p.comando(texto)
    local slash, resto = string.match(texto, "^(%S+)%s*(.*)$")
    local achou = false
    local nomes = {}
    for nome in pairs(SlashCmdList) do nomes[#nomes + 1] = nome end
    table.sort(nomes)
    for _, nome in ipairs(nomes) do
      for i = 1, 9 do
        local v = rawget(_G, "SLASH_" .. nome .. i)
        if v and string.lower(v) == string.lower(slash) then
          achou = true
          B.chamar(SlashCmdList[nome], resto)
        end
      end
    end
    if not achou then B.falha("AF", "afirma: nenhum comando registrado para " .. tostring(slash)) end
  end

  -- anda ate a condicao ficar verdadeira (ou o limite); devolve se ficou
  function p.ate(cond, max, passo)
    passo = passo or 0.1
    local gasto = 0
    while gasto < max do
      if cond() then return true end
      B.avancar(passo)
      gasto = gasto + passo
    end
    return cond()
  end

  -- luta basica: dano do jogador e do pet a cada 0,5 s
  function p.lutar(seg, jogador, pet)
    local n = math.floor(seg / 0.5 + 0.5)
    for _ = 1, n do
      p.dano{ jogador = jogador or 400, pet = pet or 100 }
      p.avancar(0.5)
    end
  end

  -- copia dos campos de um widget que as afirmacoes leem (o registro vivo muda depois)
  local function snap(e)
    if not e then return nil end
    local s = {
      id = e.id, nome = e.nome, tipo = e.tipo, texto = e.texto, textoSecreto = e.textoSecreto,
      recebeuSegredo = e.recebeuSegredo, alfa = e.alfa, visivel = e.visivel, cor = e.cor, nEscritas = e.nEscritas,
      valor = e.valor, pai = e.pai, n = {}, pontos = {},
    }
    for k, v in pairs(e.n) do s.n[k] = v end
    for i, v in ipairs(e.pontos) do s.pontos[i] = v end
    return s
  end

  -- o que o painel mostra agora
  function p.painel()
    local raiz = rawget(_G, "CentralForeverPainel")
    if not raiz then return { existe = false } end
    local er = B.E[raiz]
    local dano, thr = er.filhos[1], er.filhos[2]
    local r = { existe = true, raiz = snap(er), raizAlfa = 0, tickers = B.tickersAtivos() }
    if B.visivelEfetivo(raiz) then r.raizAlfa = B.alfaEfetivo(raiz) end
    if not dano or not thr then return r end
    local function por(e, tipo)
      local t = {}
      for _, x in ipairs(e.regioes) do
        if x.tipo == tipo then t[#t + 1] = x end
      end
      return t
    end
    local function vis(e)
      return B.visivelEfetivo(e.w) and B.alfaEfetivo(e.w) > 0.001
    end
    local d, t = por(dano, "FontString"), por(thr, "FontString")
    local dt, tt = por(dano, "Texture"), por(thr, "Texture")
    r.danoVisivel, r.threatVisivel = vis(dano), vis(thr)
    r.dps, r.luta, r.total, r.tempo = snap(d[1]), snap(d[3]), snap(d[5]), snap(d[7])
    r.palavra, r.linha2, r.onYou, r.neutro = snap(t[1]), snap(t[2]), snap(t[3]), snap(t[4])
    r.barra = snap(thr.filhos[1])
    r.fundoDano = snap(dt[1])
    r.preenchimento = snap(tt[2])
    r.moldura2 = snap(tt[7])
    r.moldura3 = snap(tt[11])
    r.pulsoTex = snap(tt[15])
    return r
  end

  return p
end

-- ---------------------------------------------------------------------------
-- Afirmacoes
-- ---------------------------------------------------------------------------

function C.afirmacoesDe(B, p)
  local a = {}
  local J = B.J

  function a.ok(cond, msg)
    if not cond then B.falha("AF", "afirma: " .. msg) end
  end

  function a.igual(x, y, msg)
    if x ~= y then B.falha("AF", "afirma: " .. msg .. " (veio " .. tostring(x) .. ", esperado " .. tostring(y) .. ")") end
  end

  function a.cfg() return rawget(_G, "CentralForeverConfig") or {} end
  function a.db() return rawget(_G, "CentralForeverDB") end

  function a.pers()
    local d = a.db()
    return d and d.personagens and d.personagens[CHAVE]
  end

  function a.lutas()
    local d = a.db()
    return d and d.diario and d.diario.lutas or {}
  end

  function a.ultimaLuta()
    local l = a.lutas()
    return l[#l]
  end

  function a.avulsas(tipo)
    local d = a.db()
    local r = {}
    if d and d.diario and d.diario.avulsas then
      for _, e in ipairs(d.diario.avulsas) do
        if e.tipo == tipo then r[#r + 1] = e end
      end
    end
    return r
  end

  function a.carga()
    local d = a.db()
    return d and d.diario and d.diario.carga and d.diario.carga[CHAVE]
  end

  function a.palavraDe(estado)
    local t = (a.cfg().threat or {}).palavras or {}
    return t[estado]
  end

  -- a cor de um texto bate com a cor do Config (tolerancia 0,01)
  function a.corIgual(e, nome)
    local ref = (a.cfg().cores or {})[nome]
    local c = e and e.cor
    if not ref or not c then return false end
    for i = 1, 3 do
      if math.abs((c[i] or 0) - (ref[i] or 0)) > 0.01 then return false end
    end
    return true
  end

  function a.texto(e) return e and e.texto or nil end

  function a.contem(texto, trecho)
    return texto ~= nil and string.find(texto, trecho, 1, true) ~= nil
  end

  function a.chatComCentral()
    local n = 0
    for _, l in ipairs(B.chat) do
      if string.find(l, "CentralForever", 1, true) then n = n + 1 end
    end
    return n
  end

  return a
end

-- ---------------------------------------------------------------------------
-- Cenarios
-- ---------------------------------------------------------------------------

local CACADOR = { classe = "HUNTER", pet = true }
local TANQUE = { classe = "PALADIN", pet = false, grupo = { "party1", "partypet1" } }

-- leituras do banco para os passos (as afirmacoes tem as suas em "a")
local function persAgora()
  local d = rawget(_G, "CentralForeverDB")
  return d and d.personagens and d.personagens[CHAVE]
end

local function avulsasAgora(tipo)
  local d = rawget(_G, "CentralForeverDB")
  local n = 0
  if d and d.diario and d.diario.avulsas then
    for _, e in ipairs(d.diario.avulsas) do
      if e.tipo == tipo then n = n + 1 end
    end
  end
  return n
end

local function chatCentralAgora()
  local n = 0
  for _, l in ipairs(__bancada.chat) do
    if string.find(l, "CentralForever", 1, true) then n = n + 1 end
  end
  return n
end

-- o que a convivencia guardou depois de uma luta (para as afirmacoes por luta)
local function fotoConvivencia()
  local pers = persAgora() or {}
  return {
    semLinha = pers.semLinha, coletaSemJanela = pers.coletaSemJanela, reservaFeita = pers.reservaFeita,
    cvar = __bancada.J.cvars.damageMeterEnabled, reservas = avulsasAgora("reserva"), chat = chatCentralAgora(),
  }
end

-- uma luta inteira de duracao conhecida; com dano (lutar) ou sem nenhum dano (so o tempo passa)
local function lutaDeDuracao(p, seg, comDano)
  p.entrarCombate()
  if comDano then p.lutar(seg) else p.avancar(seg) end
  p.sairCombate{}
  p.avancar(8)
  return fotoConvivencia()
end

-- C01 -----------------------------------------------------------------------
def{
  id = "C01", titulo = "carga fora de combate, cacador com pet",
  jogo = CACADOR,
  passos = function(p)
    p.avancar(1)
    p.m.login = p.painel()
    p.avancar(1.5)
    p.m.depoisCarga = p.painel()
    p.foto("login")
    p.avancar(3.5)
    p.m.fim = p.painel()
    p.foto("depois")
  end,
  afirma = function(a, p)
    local B = __bancada
    local cfg = a.cfg()
    local pt = cfg.ponto or {}
    local m = p.m
    a.ok(m.login.existe, "o painel nao foi criado (CentralForeverPainel)")
    if m.login.existe then
      local er = m.login.raiz
      local ponto = er.pontos[1]
      a.ok(er.pai and er.pai.nome == "UIParent", "o pai do painel nao e UIParent")
      a.ok(ponto and ponto.ponto == pt[1] and ponto.rel == pt[2] and ponto.relPonto == pt[3] and ponto.x == pt[4] and ponto.y == pt[5], "o ponto do painel nao bate com o Config")
      local n = 0
      for _, f in ipairs(B.UIParentE.filhos) do
        if f.nome == "CentralForeverPainel" then n = n + 1 end
      end
      a.igual(n, 1, "numero de paineis criados")
      a.ok(m.login.raizAlfa > 0.9 and m.login.danoVisivel, "a amostra de login nao aparece no primeiro segundo")
      a.ok(m.fim.raizAlfa < 0.01, "o painel nao voltou a oculto depois da amostra de login")
    end
    a.ok(a.carga() ~= nil, "falta a entrada carga do diario")
    a.igual(B.J.cvars.damageMeterEnabled, "0", "CVar damageMeterEnabled depois da carga")
    local pers = a.pers()
    a.igual(pers and pers.cvarAntes, "1", "cvarAntes guardado")
  end,
}

-- luta no mundo, usada por C02 e C03
local function lutaMundo(p)
  p.avancar(5)
  p.alvo{ nome = "Javali" }
  p.ameaca{ player = { estado = 0, pct = 40, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
  p.entrarCombate()
  p.avancar(0.5)
  p.lutar(2.5)
  p.m.combate = p.painel()
  p.foto("cacador-safe")
  p.lutar(1)
end

-- C02 -----------------------------------------------------------------------
def{
  id = "C02", titulo = "luta no mundo com tudo secreto e estado legivel",
  jogo = CACADOR,
  passos = function(p)
    lutaMundo(p)
    p.sairCombate{}
    p.avancar(8)
  end,
  afirma = function(a, p)
    local c = p.m.combate
    a.ok(c.existe, "o painel nao existe")
    a.ok(c.raizAlfa > 0.99 and c.danoVisivel, "modo combate: painel e cartao de dano visiveis")
    a.ok(c.tickers >= 1, "modo combate: o tique nao esta ligado")
    a.ok(c.dps and c.dps.recebeuSegredo, "DPS nao foi escrito por ralo com segredo")
    a.ok(c.luta and c.luta.recebeuSegredo, "FIGHT nao foi escrito por ralo com segredo")
    a.ok(c.total and c.total.recebeuSegredo, "TOTAL nao foi escrito por ralo com segredo")
    a.ok(c.threatVisivel, "o cartao de threat nao aparece (cacador com pet)")
    a.igual(a.texto(c.palavra), a.palavraDe("SAFE"), "palavra do threat pelo estado 0 do cacador")
    local l = a.ultimaLuta()
    a.ok(l ~= nil, "o diario nao fechou a luta")
    if l then
      a.igual(l.dano and l.dano.dps, "secreto", "diario: dano.dps")
      a.igual(l.dano and l.dano.total, "secreto", "diario: dano.total")
    end
  end,
}

-- C03 -----------------------------------------------------------------------
def{
  id = "C03", titulo = "fim de luta com valores legiveis",
  jogo = CACADOR,
  passos = function(p)
    lutaMundo(p)
    p.sairCombate{}
    p.avancar(0.5)
    p.m.pos = p.painel()
    local achou = p.ate(function()
      local d = rawget(_G, "CentralForeverDB")
      local pers = d and d.personagens and d.personagens[CHAVE]
      return pers ~= nil and pers.ultima ~= nil
    end, 5, 0.1)
    if achou then p.m.tUltima = p.agora() end
    -- ainda no modo pos (o resumo so entra 3 s depois de a captura terminar), com os numeros da luta
    p.avancar(0.5)
    p.m.posLuta = p.painel()
    p.foto("pos-luta")
    p.avancar(4)
    p.m.resumo = p.painel()
    p.foto("resumo")
  end,
  afirma = function(a, p)
    local m = p.m
    local pers = a.pers()
    local u = pers and pers.ultima
    a.ok(u ~= nil, "ultima nao foi gravada")
    if u then
      a.ok(type(u.dps) == "number" and type(u.luta) == "number" and type(u.total) == "number" and type(u.dur) == "number", "ultima sem numeros")
      a.ok(m.tUltima ~= nil and m.tUltima - m.tRestricaoSai <= 1 + 8 * 0.2 + 0.15, "ultima gravada tarde demais depois de a restricao sair")
    end
    a.ok(m.pos.existe and m.pos.raizAlfa > 0.99 and m.pos.danoVisivel, "modo pos: painel visivel")
    a.ok(not m.pos.threatVisivel, "modo pos: o threat devia estar escondido")
    a.ok(m.posLuta.raizAlfa > 0.99 and m.posLuta.danoVisivel and not m.posLuta.threatVisivel, "foto pos-luta: devia estar no modo pos")
    a.ok(m.posLuta.dps and m.posLuta.dps.texto ~= "" and m.posLuta.dps.texto ~= "--" and m.posLuta.luta and m.posLuta.luta.texto ~= "" and m.posLuta.luta.texto ~= "--", "foto pos-luta: DPS e FIGHT sem numero")
    local alfa = (a.cfg().resumo or {}).alfa or 0.45
    a.ok(math.abs(m.resumo.raizAlfa - alfa) < 0.02, "modo resumo: alfa do painel diferente de cfg.resumo.alfa")
    a.ok(not m.resumo.threatVisivel, "modo resumo: o threat devia estar escondido")
  end,
}

-- C04 -----------------------------------------------------------------------
def{
  id = "C04", titulo = "chefe: detalhado todo secreto, estado legivel",
  jogo = CACADOR,
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Chefe", chefe = true }
    p.ameaca{ player = { estado = 1, pct = 70, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(0.5)
    p.lutar(2.5)
    p.m.combate = p.painel()
    p.foto("chefe")
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    local c = p.m.combate
    a.ok(c.threatVisivel, "o cartao de threat nao aparece no chefe")
    a.igual(a.texto(c.palavra), a.palavraDe("HIGH"), "palavra pelo estado 1")
    a.ok(a.corIgual(c.palavra, "vermelhaoTexto"), "cor da palavra HIGH")
    a.ok(c.barra and c.barra.recebeuSegredo, "a regua nao recebeu o valor pelo ralo")
    a.ok(c.linha2 and c.linha2.recebeuSegredo, "a linha 2 nao recebeu a porcentagem pelo ralo")
  end,
}

-- C05 -----------------------------------------------------------------------
def{
  id = "C05", titulo = "estado tambem secreto (NEUTRO)",
  jogo = CACADOR,
  chaves = { U4 = "secreto" },
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Chefe", chefe = true }
    p.ameaca{ player = { estado = 1, pct = 70, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(0.5)
    p.lutar(2.5)
    p.m.combate = p.painel()
    p.foto("neutro")
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    local c = p.m.combate
    a.ok(c.threatVisivel, "o cartao de threat nao aparece com o estado secreto")
    a.igual(a.texto(c.palavra), "", "a palavra principal devia ficar vazia no estado NEUTRO")
    a.ok(c.onYou and (c.onYou.n.SetAlphaFromBoolean or 0) >= 1, "o texto ON YOU nao recebeu SetAlphaFromBoolean")
    a.ok(c.neutro and (c.neutro.n.SetAlphaFromBoolean or 0) >= 1, "o texto neutro nao recebeu SetAlphaFromBoolean")
    a.ok(c.onYou and c.onYou.recebeuSegredo, "o texto ON YOU nao recebeu o booleano secreto")
    a.ok(not (c.moldura2 and c.moldura2.visivel) and not (c.moldura3 and c.moldura3.visivel), "o estado NEUTRO nao devia ter moldura")
  end,
}

-- C06 -----------------------------------------------------------------------
def{
  id = "C06", titulo = "sem alvo em combate",
  jogo = CACADOR,
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, geral = 0, pct = 40, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(0.5)
    p.lutar(1.5)
    p.m.antes = p.painel()
    p.semAlvo()
    p.lutar(1)
    p.m.umSeg = p.painel()
    p.m.escritasAntes = p.painel().dps and p.painel().dps.nEscritas or 0
    p.lutar(2)
    p.m.tresSeg = p.painel()
    p.m.escritasDepois = p.painel().dps and p.painel().dps.nEscritas or 0
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    local m = p.m
    a.ok(m.antes.threatVisivel, "o cartao de threat devia aparecer antes de perder o alvo")
    a.ok(m.umSeg.threatVisivel, "o cartao de threat sumiu antes de 2 s sem alvo")
    a.ok(not m.tresSeg.threatVisivel, "o cartao de threat nao sumiu depois de 2 s sem alvo")
    a.ok(m.tresSeg.danoVisivel, "o cartao de dano sumiu junto")
    a.ok((m.escritasDepois or 0) > (m.escritasAntes or 0), "o dano parou de ser escrito sem alvo")
  end,
}

-- C07 -----------------------------------------------------------------------
def{
  id = "C07", titulo = "alvo amigo no meio da luta (paladino cura o parceiro)",
  jogo = TANQUE,
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 3, geral = 3, pct = 100, tanque = true }, party1 = { estado = 0, geral = 3, pct = 10, tanque = false } }
    p.entrarCombate()
    p.avancar(0.5)
    p.lutar(1.5)
    p.m.antes = p.painel()
    p.alvo{ amigo = true, nome = "Parceiro" }
    p.lutar(3)
    p.m.depois = p.painel()
    p.foto("alvo-amigo")
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    a.ok(p.m.antes.threatVisivel, "o cartao de threat devia aparecer no tanque")
    a.igual(__bancada.consultasMobAmigo, 0, "consultas de threat com mob amigo")
    a.ok(p.m.depois.threatVisivel, "o cartao de threat devia seguir pela consulta sem mob")
  end,
}

-- C08 -----------------------------------------------------------------------
def{
  id = "C08", titulo = "solo sem pet (as duas variantes de U6)",
  jogo = { classe = "HUNTER", pet = false },
  passos = function(p)
    local B = __bancada
    p.m.vistos = 0
    local function luta(variante)
      B.chaves.U6 = variante
      p.alvo{ nome = "Javali" }
      p.ameaca{ player = { estado = 3, pct = 100, tanque = true } }
      p.entrarCombate()
      for _ = 1, 12 do
        p.dano{ jogador = 300 }
        p.avancar(0.25)
        if p.painel().threatVisivel then p.m.vistos = p.m.vistos + 1 end
      end
      p.sairCombate{}
      p.avancar(8)
    end
    p.avancar(5)
    luta("nada")
    luta("valores")
  end,
  afirma = function(a, p)
    a.igual(p.m.vistos, 0, "amostras com o cartao de threat visivel em solo sem pet")
  end,
}

-- C09 -----------------------------------------------------------------------
def{
  id = "C09", titulo = "cacador a 85% do pet",
  jogo = CACADOR,
  chaves = { U5 = "legivel" },
  passos = function(p)
    local B = __bancada
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(1.5)
    p.ameaca{ player = { estado = 0, pct = 85, tanque = false } }
    p.avancar(2)
    p.m.close = p.painel()
    p.m.pulsos1 = B.luta.pulsos
    p.foto("cacador-close")
    p.ameaca{ player = { estado = 0, pct = 88, tanque = false } }
    p.avancar(2)
    p.ameaca{ player = { estado = 0, pct = 83, tanque = false } }
    p.avancar(3)
    p.m.pulsos2 = B.luta.pulsos
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    local c = p.m.close
    a.igual(a.texto(c.palavra), a.palavraDe("CLOSE"), "palavra a 85%")
    a.ok(a.corIgual(c.palavra, "ambar"), "cor da palavra CLOSE")
    a.ok(c.moldura2 and c.moldura2.visivel, "moldura 2 do CLOSE")
    a.ok(p.m.pulsos1 <= 1, "mais de um pulso ao entrar em CLOSE")
    a.igual(p.m.pulsos2, p.m.pulsos1, "pulsos enquanto fica acima de 80%")
  end,
}

-- C10 -----------------------------------------------------------------------
def{
  id = "C10", titulo = "cacador puxa (estado 3)",
  jogo = CACADOR,
  passos = function(p)
    local B = __bancada
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(1.5)
    p.m.pulsosAntes = B.luta.pulsos
    p.ameaca{ player = { estado = 3, pct = 100, tanque = true } }
    p.avancar(2)
    p.m.onYou = p.painel()
    p.m.pulsosDepois = B.luta.pulsos
    p.foto("cacador-onyou")
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    local c = p.m.onYou
    a.igual(a.texto(c.palavra), a.palavraDe("ON_YOU"), "palavra com estado 3")
    a.ok(c.preenchimento and c.preenchimento.visivel, "cartao cheio do ON_YOU")
    a.ok(a.corIgual(c.palavra, "branco"), "cor da palavra ON_YOU")
    a.igual(p.m.pulsosDepois - p.m.pulsosAntes, 1, "pulsos ao puxar")
  end,
}

-- C11 -----------------------------------------------------------------------
def{
  id = "C11", titulo = "pet morre no meio da luta e o mob vem no cacador",
  jogo = CACADOR,
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(1.5)
    p.m.antes = p.painel()
    p.petMorre()
    p.ameaca{ player = { estado = 3, pct = 100, tanque = true }, pet = false }
    p.avancar(2.5)
    p.m.depois = p.painel()
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    a.ok(p.m.antes.threatVisivel, "o cartao devia aparecer com o pet vivo")
    a.ok(p.m.depois.threatVisivel, "o cartao sumiu quando o pet morreu")
    a.igual(a.texto(p.m.depois.palavra), a.palavraDe("ON_YOU"), "palavra depois da morte do pet")
  end,
}

-- C12 -----------------------------------------------------------------------
def{
  id = "C12", titulo = "tanque segurando, partypet1 a 92%",
  jogo = TANQUE,
  chaves = { U5 = "legivel" },
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 3, pct = 100, tanque = true }, party1 = { estado = 0, pct = 20, tanque = false }, partypet1 = { estado = 0, pct = 30, tanque = false } }
    p.entrarCombate()
    p.avancar(1.5)
    p.foto("tanque-held")
    p.ameaca{ partypet1 = { estado = 0, pct = 92, tanque = false } }
    p.avancar(2)
    p.m.slipping = p.painel()
    p.foto("tanque-slipping")
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    local c = p.m.slipping
    a.igual(a.texto(c.palavra), a.palavraDe("SLIPPING"), "palavra do tanque com desafiante a 92%")
    a.igual(a.texto(c.linha2), "Voidwal 92%", "linha 2 com nome e porcentagem do demonio")
    a.ok(a.corIgual(c.palavra, "ambar"), "cor do SLIPPING")
  end,
}

-- C13 -----------------------------------------------------------------------
def{
  id = "C13", titulo = "tanque perde o alvo para party1",
  jogo = TANQUE,
  chaves = { U5 = "legivel" },
  passos = function(p)
    local B = __bancada
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 3, pct = 100, tanque = true }, party1 = { estado = 0, pct = 40, tanque = false } }
    p.entrarCombate()
    p.avancar(1.5)
    p.m.pulsosAntes = B.luta.pulsos
    p.ameaca{ player = { estado = 1, pct = 70, tanque = false }, party1 = { estado = 3, pct = 100, tanque = true } }
    p.avancar(2)
    p.m.lost = p.painel()
    p.m.pulsosDepois = B.luta.pulsos
    p.foto("tanque-lost")
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    local c = p.m.lost
    a.igual(a.texto(c.palavra), a.palavraDe("LOST"), "palavra ao perder o alvo")
    a.ok(a.contem(a.texto(c.linha2), "Kellan"), "linha 2 sem o nome de party1")
    a.ok(c.preenchimento and c.preenchimento.visivel, "cartao cheio do LOST")
    a.igual(p.m.pulsosDepois - p.m.pulsosAntes, 1, "pulsos ao perder o alvo")
  end,
}

-- C14 -----------------------------------------------------------------------
def{
  id = "C14", titulo = "tanque com mob solto em party1",
  jogo = TANQUE,
  chaves = { U5 = "legivel" },
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 3, pct = 100, tanque = true }, party1 = { estado = 0, pct = 10, tanque = false } }
    p.entrarCombate()
    p.avancar(1.5)
    p.ameaca{ party1 = { estado = 0, geral = 3, pct = 10, tanque = false } }
    p.avancar(2)
    p.m.loose = p.painel()
    p.foto("loose")
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    local c = p.m.loose
    a.igual(a.texto(c.palavra), a.palavraDe("LOOSE"), "palavra com mob solto")
    a.ok(a.contem(a.texto(c.linha2), "Kellan"), "linha 2 sem o nome de quem esta com o mob solto")
    a.ok(c.moldura3 and c.moldura3.visivel, "moldura 3 do LOOSE")
  end,
}

-- C15 -----------------------------------------------------------------------
def{
  id = "C15", titulo = "tanque em chefe: porcentagens secretas, lider legivel em 2",
  jogo = TANQUE,
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Chefe", chefe = true }
    p.ameaca{ player = { estado = 3, pct = 100, tanque = true, lider = 0 }, party1 = { estado = 0, pct = 50, tanque = false } }
    p.entrarCombate()
    p.avancar(1.5)
    p.ameaca{ player = { estado = 3, pct = 100, tanque = true, lider = 2 } }
    p.avancar(2)
    p.m.slipping = p.painel()
    p.foto("lider")
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    local c = p.m.slipping
    a.igual(a.texto(c.palavra), a.palavraDe("SLIPPING"), "palavra pelo lider")
    local l2 = a.texto(c.linha2) or ""
    a.ok(string.find(l2, "%a") == nil, "linha 2 devia ficar sem nome")
    a.igual(l2, "", "linha 2 devia ficar vazia (nenhuma porcentagem de desafiante com alguma secreta)")
    a.ok(c.linha2 and not c.linha2.recebeuSegredo, "linha 2 recebeu uma porcentagem secreta")
    a.ok(c.barra ~= nil, "a regua do threat nao foi encontrada")
    a.igual(c.barra and c.barra.valor, 0, "regua devia ficar em 0 (nenhuma porcentagem de desafiante)")
    a.ok(c.barra and not c.barra.recebeuSegredo, "a regua recebeu uma porcentagem secreta")
  end,
}

-- C16 -----------------------------------------------------------------------
def{
  id = "C16", titulo = "troca de alvo a cada 1,5 s, alternando seguro e ON_YOU",
  jogo = CACADOR,
  passos = function(p)
    local B = __bancada
    p.avancar(5)
    p.alvo{ nome = "Mob A" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(2)
    p.m.palavras = {}
    for i = 1, 6 do
      local puxa = (i % 2 == 1)
      p.alvo{ nome = puxa and "Mob B" or "Mob A" }
      if puxa then
        p.ameaca{ player = { estado = 3, pct = 100, tanque = true } }
      else
        p.ameaca{ player = { estado = 0, pct = 30, tanque = false } }
      end
      p.avancar(1.45)
      p.m.palavras[i] = p.painel().palavra and p.painel().palavra.texto
      p.avancar(0.05)
    end
    p.m.pulsos = B.luta.pulsos
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    for i = 1, 6 do
      local esperado = (i % 2 == 1) and a.palavraDe("ON_YOU") or a.palavraDe("SAFE")
      a.igual(p.m.palavras[i], esperado, "palavra apos a troca de alvo " .. i)
    end
    a.igual(p.m.pulsos, 0, "pulsos causados por troca de alvo")
  end,
}

-- C17 -----------------------------------------------------------------------
def{
  id = "C17", titulo = "medidor indisponivel (com motivo)",
  jogo = CACADOR,
  api = { medidorIndisponivel = "disabled" },
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(0.5)
    p.lutar(2.5)
    p.m.combate = p.painel()
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    local c = p.m.combate
    local vazio = a.cfg().vazio or "--"
    a.igual(a.texto(c.dps), vazio, "DPS com o medidor indisponivel")
    a.igual(a.texto(c.luta), vazio, "FIGHT com o medidor indisponivel")
    a.igual(a.texto(c.total), vazio, "TOTAL com o medidor indisponivel")
    local carga = a.carga()
    a.ok(carga ~= nil and carga.disponivel == false, "o diario devia marcar disponivel = false")
    a.igual(carga and carga.motivo, "disabled", "motivo no diario")
    a.igual(a.texto(c.palavra), a.palavraDe("ON_YOU"), "o threat devia funcionar")
  end,
}

-- C18 -----------------------------------------------------------------------
def{
  id = "C18", titulo = "API ausente (sem C_DamageMeter, C_StringUtil, C_RestrictedActions)",
  jogo = CACADOR,
  api = { sem = { "C_DamageMeter", "C_StringUtil", "C_RestrictedActions" } },
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(0.5)
    p.lutar(2.5)
    p.m.combate = p.painel()
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    local carga = a.carga()
    a.ok(carga ~= nil, "falta a entrada carga do diario")
    if carga then
      a.ok(carga.tem and carga.tem.medidor == false, "diario: tem.medidor devia ser false")
      a.ok(carga.tem and carga.tem.arredondar == false, "diario: tem.arredondar devia ser false")
      a.ok(carga.tem and carga.tem.restricoes == false, "diario: tem.restricoes devia ser false")
    end
    a.ok(p.m.combate.danoVisivel, "o cartao de dano devia continuar")
  end,
}

-- C19 -----------------------------------------------------------------------
def{
  id = "C19", titulo = "/reload em combate (carga com InCombatLockdown verdadeiro)",
  jogo = { classe = "HUNTER", pet = true, emCombate = true },
  passos = function(p)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.avancar(1.5)
    p.m.combate = p.painel()
    p.m.cvarEmCombate = __bancada.J.cvars.damageMeterEnabled
    p.dano{ jogador = 500 }
    p.avancar(1)
    p.sairCombate{}
    p.avancar(6)
    p.m.cvarDepois = __bancada.J.cvars.damageMeterEnabled
  end,
  afirma = function(a, p)
    local c = p.m.combate
    a.ok(c.existe and c.raizAlfa > 0.99 and c.danoVisivel, "a carga em combate devia entrar em EM_COMBATE")
    a.ok(c.tickers >= 1, "a carga em combate devia ligar o tique")
    a.igual(p.m.cvarEmCombate, "1", "CVar durante o combate (C.aplicar pendente)")
    a.igual(p.m.cvarDepois, "0", "CVar depois do combate (C.aplicar roda ao sair)")
    local pers = a.pers()
    a.igual(pers and pers.cvarAntes, "1", "cvarAntes depois do combate")
  end,
}

-- C20 -----------------------------------------------------------------------
def{
  id = "C20", titulo = "restricao demora 5 s para sair",
  jogo = CACADOR,
  passos = function(p)
    local B = __bancada
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(0.5)
    p.lutar(2.5)
    p.m.textoAntes = p.painel().dps and p.painel().dps.texto
    p.sairCombate{ atrasoRestricao = 5 }
    -- tentativas esgotadas (1 s + 8 x 0,2 s), ainda antes do modo resumo (mais 3 s)
    p.avancar(3.3)
    p.m.textoApos = p.painel().dps and p.painel().dps.texto
    p.avancar(2.7)
    p.m.chamadasAntes = B.contagem.GetCombatSessionFromType or 0
    p.avancar(14)
    p.m.chamadasDepois = B.contagem.GetCombatSessionFromType or 0
    p.m.timers = B.timersAtivos()
    p.m.depois = p.painel()
  end,
  afirma = function(a, p)
    a.igual(p.m.chamadasDepois, p.m.chamadasAntes, "leituras do medidor depois de esgotadas as tentativas")
    a.igual(p.m.timers, 0, "timers ainda ativos 20 s depois")
    local pers = a.pers()
    a.ok(not (pers and pers.ultima), "ultima nao devia existir com a restricao ativa durante a captura")
    a.igual(p.m.textoApos, p.m.textoAntes, "texto do DPS depois das tentativas esgotadas (devia ficar como estava)")
  end,
}

-- C21 -----------------------------------------------------------------------
def{
  id = "C21", titulo = "restricao de tipo Map e de tipo Chat fora de combate",
  jogo = CACADOR,
  passos = function(p)
    p.avancar(6)
    p.m.antes = p.painel()
    p.restricao{ "Map", "Activating" }
    p.restricao{ "Map", "Active" }
    p.avancar(0.5)
    p.restricao{ "Map", "Inactive" }
    p.restricao{ "Chat", "Active" }
    p.avancar(0.5)
    p.restricao{ "Chat", "Inactive" }
    p.avancar(2)
    p.m.depois = p.painel()
  end,
  afirma = function(a, p)
    a.ok(p.m.antes.raizAlfa < 0.01 and p.m.depois.raizAlfa < 0.01, "o estado mudou por causa de restricao fora do tipo Combat")
    a.ok(p.m.depois.tickers == 0, "o tique ligou por causa de restricao fora do tipo Combat")
    a.ok(#a.avulsas("restricao") >= 2, "faltam entradas avulsas restricao no diario")
  end,
}

-- C22 -----------------------------------------------------------------------
def{
  id = "C22", titulo = "Current vazia ao sair do combate, Expired com a luta",
  jogo = CACADOR,
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(0.5)
    p.lutar(2.5)
    p.sairCombate{ currentVazia = true }
    p.avancar(8)
  end,
  afirma = function(a, p)
    local pers = a.pers()
    a.ok(pers and pers.ultima ~= nil, "ultima nao foi gravada a partir da Expired")
    local l = a.ultimaLuta()
    a.igual(l and l.resumo and l.resumo.fonte, "expired", "fonte do resumo")
  end,
}

-- C23 -----------------------------------------------------------------------
def{
  id = "C23", titulo = "combatSources inacessivel em combate (U2)",
  jogo = CACADOR,
  chaves = { U2 = "inacessivel" },
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(0.5)
    p.lutar(2.5)
    p.m.combate = p.painel()
    p.sairCombate{}
    p.avancar(8)
  end,
  afirma = function(a, p)
    local c = p.m.combate
    local vazio = a.cfg().vazio or "--"
    a.igual(a.texto(c.dps), vazio, "DPS com combatSources inacessivel")
    a.igual(a.texto(c.luta), vazio, "FIGHT com combatSources inacessivel")
    local l = a.ultimaLuta()
    a.igual(l and l.dano and l.dano.sessao, "inacessivel", "diario: dano.sessao")
  end,
}

-- C24 -----------------------------------------------------------------------
def{
  id = "C24", titulo = "rajada de 200 eventos por segundo, com unidades de fora",
  jogo = CACADOR,
  passos = function(p)
    local B = __bancada
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(0.5)
    p.m.leiturasAntes = B.contagem.GetCombatSessionFromType or 0
    p.m.ameacaAntes = (B.contagem.UnitThreatSituation or 0)
    for passo = 1, 60 do
      for i = 1, 5 do
        p.dano{ jogador = 10 }
        B.disparar("UNIT_THREAT_SITUATION_UPDATE", "nameplate" .. i)
        B.disparar("UNIT_THREAT_LIST_UPDATE", "mouseover")
      end
      p.avancar(0.05)
    end
    p.m.leiturasDepois = B.contagem.GetCombatSessionFromType or 0
    p.m.ameacaDepois = (B.contagem.UnitThreatSituation or 0)
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    local m = p.m
    a.ok(m.leiturasDepois - m.leiturasAntes <= 60, "leituras do medidor demais na rajada (" .. (m.leiturasDepois - m.leiturasAntes) .. " em 3 s)")
    a.ok(m.ameacaDepois - m.ameacaAntes <= 60, "leituras de threat demais na rajada (" .. (m.ameacaDepois - m.ameacaAntes) .. " em 3 s)")
  end,
}

-- C25 -----------------------------------------------------------------------
def{
  id = "C25", titulo = "pet como linha propria (U7)",
  jogo = CACADOR,
  chaves = { U7 = "propria" },
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(0.5)
    p.dano{ jogador = 1000, pet = 500 }
    p.avancar(2)
    p.m.combate = p.painel()
    p.sairCombate{}
    p.avancar(8)
  end,
  afirma = function(a, p)
    a.igual(a.texto(p.m.combate.luta), "1.0K", "FIGHT so com a linha do jogador")
    local l = a.ultimaLuta()
    a.igual(l and l.fontes, 2, "diario: fontes")
  end,
}

-- C26 -----------------------------------------------------------------------
def{
  id = "C26", titulo = "tres lutas seguidas de 12 s sem a linha do jogador, CVar em 0 posto pelo addon (U9 = nao coleta)",
  jogo = CACADOR,
  chaves = { U9 = "naocoleta" },
  passos = function(p)
    p.avancar(5)
    p.m.cvarAntes = __bancada.J.cvars.damageMeterEnabled
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.m.luta = {}
    for i = 1, 3 do
      p.m.luta[i] = lutaDeDuracao(p, 12, true)
    end
  end,
  afirma = function(a, p)
    local m = p.m
    a.igual(m.cvarAntes, "0", "CVar antes da luta (o addon devia te-lo posto em 0)")
    for i = 1, 2 do
      local l = m.luta[i]
      a.igual(l.cvar, "0", "CVar depois da luta " .. i .. " (a reserva nao devia ter disparado)")
      a.igual(l.semLinha, i, "semLinha depois da luta " .. i)
      a.ok(l.reservaFeita ~= true, "reservaFeita depois da luta " .. i)
      a.igual(l.reservas, 0, "entradas avulsas reserva depois da luta " .. i)
      a.igual(l.chat, 0, "avisos no chat depois da luta " .. i)
    end
    local l3 = m.luta[3]
    a.igual(l3.cvar, "1", "CVar devolvido pela reserva depois da luta 3")
    a.igual(l3.reservaFeita, true, "reservaFeita depois da luta 3")
    a.igual(l3.reservas, 1, "entradas avulsas reserva depois da luta 3")
    a.igual(l3.chat, 1, "avisos no chat depois da luta 3")
    local pers = a.pers()
    a.igual(pers and pers.cvarAntes, nil, "cvarAntes devia ser apagado ao devolver o CVar")
    a.igual(a.chatComCentral(), 1, "avisos no chat no fim")
  end,
}

-- C27 -----------------------------------------------------------------------
def{
  id = "C27", titulo = "morte em combate e volta",
  jogo = CACADOR,
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(0.5)
    p.lutar(2.5)
    p.morrer()
    p.avancar(8)
    p.reviver()
    p.avancar(3)
  end,
  afirma = function(a, p)
    local pers = a.pers()
    a.ok(pers and pers.ultima ~= nil, "o resumo nao saiu depois da morte")
  end,
}

-- C28 -----------------------------------------------------------------------
def{
  id = "C28", titulo = "voltar ao combate durante SAINDO",
  jogo = CACADOR,
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(0.5)
    p.lutar(2.5)
    p.sairCombate{}
    p.avancar(0.3)
    p.m.saindo = p.painel()
    p.entrarCombate()
    p.avancar(2)
    p.m.volta = p.painel()
    p.m.ultimaNaVolta = (function()
      local d = rawget(_G, "CentralForeverDB")
      local pers = d and d.personagens and d.personagens[CHAVE]
      return pers and pers.ultima
    end)()
    p.lutar(1)
    p.sairCombate{}
    p.avancar(8)
  end,
  afirma = function(a, p)
    a.ok(p.m.volta.tickers >= 1, "o tique devia voltar com o combate")
    a.ok(p.m.volta.raizAlfa > 0.99 and p.m.volta.danoVisivel, "o painel devia voltar ao modo combate")
    a.ok(p.m.ultimaNaVolta == nil, "resumo parcial gravado ao voltar ao combate")
    local pers = a.pers()
    a.ok(pers and pers.ultima ~= nil, "o resumo da segunda saida nao saiu")
  end,
}

-- C29 -----------------------------------------------------------------------
def{
  id = "C29", titulo = "comando /central",
  jogo = CACADOR,
  passos = function(p)
    local B = __bancada
    p.avancar(6)
    p.comando("/central")
    p.m.linhasVazio = #B.chat
    p.comando("/central test")
    p.avancar(1)
    p.m.amostra = p.painel()
    p.avancar(12)
    p.m.cvar0 = B.J.cvars.damageMeterEnabled
    p.comando("/central meter")
    p.m.cvar1 = B.J.cvars.damageMeterEnabled
    p.comando("/central meter")
    p.m.cvar2 = B.J.cvars.damageMeterEnabled
    p.comando("/central reset")
    p.m.resetsFora = B.J.resets
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(0.5)
    p.comando("/central reset")
    p.avancar(0.5)
    p.m.resetsDentro = B.J.resets
    p.sairCombate{}
    p.avancar(6)
    p.m.chat = #B.chat
  end,
  afirma = function(a, p)
    local B = __bancada
    local m = p.m
    a.ok(m.linhasVazio >= 1, "/central nao respondeu")
    a.ok(m.amostra.raizAlfa > 0.99 and m.amostra.danoVisivel, "/central test nao mostrou a amostra")
    a.igual(m.cvar0, "0", "CVar antes de /central meter")
    a.igual(m.cvar1, "1", "CVar depois do primeiro /central meter")
    a.igual(m.cvar2, "0", "CVar depois do segundo /central meter")
    a.igual(m.resetsFora, 1, "/central reset fora de combate")
    a.igual(m.resetsDentro, 1, "/central reset em combate nao devia chamar a API")
    for _, l in ipairs(B.chat) do
      if string.find(l, "[^\1-\127]") then a.ok(false, "resposta com caractere fora do ASCII: " .. l) end
    end
  end,
}

-- C30 -----------------------------------------------------------------------
def{
  id = "C30", titulo = "cfg.ligado = false",
  jogo = { classe = "HUNTER", pet = true, cvars = { damageMeterEnabled = "0" } },
  cfg = function(c) c.ligado = false end,
  dbInicial = { v = 1, personagens = { [CHAVE] = { cvarAntes = "1" } } },
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.entrarCombate()
    p.avancar(2)
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    a.ok(rawget(_G, "CentralForeverPainel") == nil, "o painel foi criado com cfg.ligado = false")
    a.igual(__bancada.J.cvars.damageMeterEnabled, "1", "CVar devolvido")
    local pers = a.pers()
    a.ok(pers and pers.cvarAntes == nil, "cvarAntes devia ser apagado")
  end,
}

-- C31 -----------------------------------------------------------------------
def{
  id = "C31", titulo = "luta sem dano (curta e longa) e depois uma luta normal",
  jogo = CACADOR,
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.m.curta = lutaDeDuracao(p, 3, false)
    p.m.longa = lutaDeDuracao(p, 12, false)
    p.m.normal = lutaDeDuracao(p, 5, true)
  end,
  afirma = function(a, p)
    local m = p.m
    a.igual(m.curta.cvar, "0", "CVar depois da luta curta sem dano")
    a.ok((m.curta.semLinha or 0) == 0, "semLinha depois da luta curta (3 s) devia continuar em 0")
    a.igual(m.longa.cvar, "0", "CVar depois da luta longa sem dano")
    a.igual(m.longa.semLinha, 1, "semLinha depois da luta longa (12 s) sem dano")
    a.ok(m.longa.reservaFeita ~= true, "a reserva disparou com uma luta sem dano")
    a.igual(m.normal.cvar, "0", "CVar depois da luta normal")
    a.igual(m.normal.coletaSemJanela, true, "coletaSemJanela depois da luta normal")
    a.igual(m.normal.semLinha, 0, "semLinha depois da luta normal")
    a.ok(m.normal.reservaFeita ~= true, "a reserva disparou na luta normal")
    a.igual(#a.avulsas("reserva"), 0, "entradas avulsas reserva")
    a.igual(a.chatComCentral(), 0, "avisos no chat")
  end,
}

-- C32 -----------------------------------------------------------------------
def{
  id = "C32", titulo = "luta normal e depois tres lutas de 12 s sem a linha",
  jogo = CACADOR,
  passos = function(p)
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.m.normal = lutaDeDuracao(p, 5, true)
    p.m.vazias = {}
    for i = 1, 3 do
      p.m.vazias[i] = lutaDeDuracao(p, 12, false)
    end
  end,
  afirma = function(a, p)
    local m = p.m
    a.igual(m.normal.coletaSemJanela, true, "coletaSemJanela depois da luta normal")
    for i = 1, 3 do
      local l = m.vazias[i]
      a.igual(l.cvar, "0", "CVar depois da luta vazia " .. i)
      a.igual(l.coletaSemJanela, true, "coletaSemJanela depois da luta vazia " .. i)
      a.ok(l.reservaFeita ~= true, "a reserva disparou na luta vazia " .. i)
    end
    a.igual(#a.avulsas("reserva"), 0, "entradas avulsas reserva")
    a.igual(a.chatComCentral(), 0, "avisos no chat")
  end,
}

-- C33 -----------------------------------------------------------------------
def{
  id = "C33", titulo = "cacador com dois mobs: alvo A em ON_YOU, troca para o alvo B seguro",
  jogo = CACADOR,
  passos = function(p)
    local B = __bancada
    p.avancar(5)
    p.alvo{ nome = "Mob A" }
    p.ameaca{ player = { estado = 3, pct = 100, tanque = true }, pet = { estado = 0, pct = 20, tanque = false } }
    p.entrarCombate()
    p.avancar(2)
    p.m.antes = p.painel()
    p.m.pulsosAntes = B.luta.pulsos
    p.alvo{ nome = "Mob B" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false } }
    -- uma leitura (o tique e de 0,25 s), bem antes de melhoraSeg
    p.avancar(0.3)
    p.m.depois = p.painel()
    p.m.pulsosDepois = B.luta.pulsos
    p.avancar(2)
    p.sairCombate{}
    p.avancar(6)
  end,
  afirma = function(a, p)
    local m = p.m
    a.igual(a.texto(m.antes.palavra), a.palavraDe("ON_YOU"), "palavra com o alvo A")
    a.igual(a.texto(m.depois.palavra), a.palavraDe("SAFE"), "palavra na leitura seguinte a troca para o alvo B (sem a espera de melhoraSeg)")
    a.igual(m.pulsosDepois, m.pulsosAntes, "pulsos causados pela troca de alvo")
  end,
}

-- C34 -----------------------------------------------------------------------
def{
  id = "C34", titulo = "DAMAGE_METER_CURRENT_SESSION_UPDATED tres vezes em luta e uma vez fora dela",
  jogo = CACADOR,
  passos = function(p)
    local B = __bancada
    p.avancar(5)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 30, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.m.avulsasAntes = avulsasAgora("nova_sessao")
    p.entrarCombate()
    p.avancar(0.5)
    for _ = 1, 3 do
      p.lutar(1)
      B.disparar("DAMAGE_METER_CURRENT_SESSION_UPDATED")
      p.avancar(0.5)
    end
    p.m.avulsasEmLuta = avulsasAgora("nova_sessao")
    p.sairCombate{}
    p.avancar(8)
    B.disparar("DAMAGE_METER_CURRENT_SESSION_UPDATED")
    p.avancar(1)
  end,
  afirma = function(a, p)
    local m = p.m
    a.igual(m.avulsasAntes, 0, "entradas nova_sessao antes da luta")
    a.igual(m.avulsasEmLuta, 0, "entradas nova_sessao durante a luta (devia ser so contador)")
    local l = a.ultimaLuta()
    a.igual(l and l.novasSessoes, 3, "novasSessoes do registro da luta")
    a.igual(#a.avulsas("nova_sessao"), 1, "entradas avulsas nova_sessao")
  end,
}

-- GEN: roteiro generico dos addons de brinquedo -------------------------------
def{
  id = "GEN", titulo = "roteiro generico (carga, luta com dano e threat secretos, fim de luta)",
  jogo = CACADOR,
  passos = function(p)
    p.avancar(3)
    p.alvo{ nome = "Javali" }
    p.ameaca{ player = { estado = 0, pct = 40, tanque = false }, pet = { estado = 3, pct = 100, tanque = true } }
    p.entrarCombate()
    p.avancar(0.5)
    for i = 1, 12 do
      p.dano{ jogador = 100 * i }
      p.avancar(0.05)
    end
    p.ameaca{ player = { estado = 1, pct = 70, tanque = false } }
    p.avancar(1)
    p.ameaca{ player = { estado = 3, pct = 100, tanque = true } }
    for i = 1, 10 do
      p.dano{ jogador = 200 }
      p.ameaca{ player = { estado = 3, pct = 100 + i, tanque = true } }
      p.avancar(0.1)
    end
    p.avancar(1)
    p.sairCombate{}
    p.avancar(6)
  end,
}
