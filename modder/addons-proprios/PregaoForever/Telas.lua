-- Telas.lua (PregaoForever): as visoes da onda 2 (Session e Mine), o painel do correio e o cartao da sonda, com os mesmos
-- rotulos e secoes dos quadros aprovados (pesquisa/telas). Next, Sell e Risk entram na onda 3.
-- Contrato: ARQUITETURA.md, secao 3.12. Le dados so pelas funcoes publicas do contrato, sempre por ns.ui.ler: modulo
-- ausente vira um traco. Texto em ingles sem acento; no maximo 5 linhas por secao e Show N more; estado em palavra.
local _, ns = ...
ns.telas = ns.telas or {}
local T = ns.telas
T._ = T._ or {}
local U = T._

T.visao = nil        -- 'mine', 'session' ou 'sonda'
T.sel = nil          -- indice do item selecionado entre os itens da lista
T.expandido = false  -- O: mostra o resto das secoes
T.conta = false      -- I: mostra a conta do item selecionado
T.pulados = {}       -- K: itens tirados da lista ate o fim da sessao
T.itens = {}         -- chaves dos itens selecionaveis da ultima pintura

local MAX_SECAO = 5  -- linhas por secao, contando o cabecalho e o Show N more

-- ---------- texto ----------
function U.mon(c)
  if type(c) == "number" then return ns.dinheiro(c) end
  return "-"
end

function U.sinal(c)
  if type(c) ~= "number" then return "-" end
  if c >= 0 then return "+" .. ns.dinheiro(c) end
  return ns.dinheiro(c)
end

-- 92 -> 1m, 5520 -> 1h 32m
function U.dur(s)
  if type(s) ~= "number" then return "-" end
  s = math.floor(s)
  if s < 0 then s = 0 end
  if s < 60 then return string.format("%ds", s) end
  if s < 3600 then return string.format("%dm", math.floor(s / 60)) end
  return string.format("%dh %02dm", math.floor(s / 3600), math.floor((s % 3600) / 60))
end

-- tempo restante de um leilao, em faixas
function U.faixaTempo(s)
  if type(s) ~= "number" then return "-" end
  if s <= 1800 then return "under 30m" end
  if s <= 7200 then return "30m-2h" end
  if s <= 43200 then return "2-12h" end
  return "12h+"
end

-- ---------- linha de estado: as tres primeiras linhas de toda visao, mais a faixa e os disjuntores ----------
function U.modoPalavra()
  local m = ns.modo()
  if m == "vivo" then return "LIVE", "verde" end
  if m == "papel" then return "PAPER", "amarelo" end
  return "READ ONLY", "amarelo"
end

function U.disjuntores()
  local lista = ns.ui.ler("cofre", "disjuntores")
  local out = {}
  if type(lista) ~= "table" then return out end
  for i = 1, #lista do
    local d = lista[i]
    if type(d) == "table" then d = d.texto or d.nome or d.id end
    if d ~= nil then out[#out + 1] = tostring(d) end
  end
  return out
end

function U.estadoLinhas()
  local rows = {}
  local banca = ns.ui.ler("cofre", "banca")
  local b = (type(banca) == "table") and banca or {}
  rows[1] = { rot = "BUDGET", t = string.format("%s   FREE %s   STOCK %s   DEPOSITS %s   IN MAIL %s",
    U.mon(b.B), U.mon(b.livre), U.mon(b.estoque), U.mon(b.deposito), U.mon(b.correio)) }
  local palavra, cp = U.modoPalavra()
  local teclas = "KEYS ON"
  if ns.teclas and ns.teclas.held then teclas = "KEYS HELD" end
  rows[2] = { rot = "MODE", palavra = palavra, cp = cp, t = " AT RISK -   " .. teclas }
  local ve = ns.ui.ler("varredura", "estado")
  local idade = "not read yet"
  if type(ve) == "table" and type(ve.idadeResumo) == "number" then idade = U.dur(ve.idadeResumo) .. " old" end
  local t3 = idade
  local pe = ns.ui.ler("pedidos", "estado")
  if type(pe) == "table" and pe.fase ~= nil then
    local f = pe.fase
    if f == "PARADO" then f = "IDLE" elseif f == "ABERTO" then f = "OPEN" elseif f == "TRAVADO" then f = "STUCK" end
    t3 = t3 .. "   SCAN " .. tostring(f)
  end
  rows[3] = { rot = "PRICES", t = t3 }
  local nota = {}
  if ns.faixa then nota[#nota + 1] = ns.faixa end
  local dj = U.disjuntores()
  if #dj > 0 then nota[#nota + 1] = "BREAKERS " .. table.concat(dj, "; ") end
  if #nota > 0 then
    rows[4] = { rot = "NOTE", t = table.concat(nota, "   "), cor = "amarelo" }
  end
  return rows
end

-- ---------- secoes: cabecalho + itens + Show N more ----------
-- itens: linhas ja prontas. Devolve as linhas a mostrar (com o Show N more) e quantas ficaram visiveis.
function U.cortar(itens)
  local n = #itens
  local visiveis = n
  local mais = nil
  if not T.expandido and n > MAX_SECAO - 1 then
    visiveis = MAX_SECAO - 2
    mais = string.format("Show %d more", n - visiveis)
  elseif T.expandido and n > MAX_SECAO - 1 then
    mais = "Show less"
  end
  return visiveis, mais
end

-- ---------- Session ----------
function U.session()
  local lista = {}
  local s = ns.ui.ler("livro", "sessao")
  local ok = type(s) == "table"
  local a = (ok and type(s.acoes) == "table") and s.acoes or {}
  local agora = ns.servidor()
  local dec = nil
  if ok and type(s.tIni) == "number" then dec = agora - s.tIni end
  local nAcoes = nil
  if ok then nAcoes = (a.post or 0) + (a.buy or 0) + (a.cancel or 0) + (a.outside or 0) end
  if ok then
    lista[#lista + 1] = { rot = "SESSION", t = U.dur(dec) .. "   actions " .. ns.txt(nAcoes) }
    lista[#lista + 1] = { t = string.format("(post %d, buy %d, cancel %d, done in Blizzard UI %d)   unconfirmed %s",
      a.post or 0, a.buy or 0, a.cancel or 0, a.outside or 0,
      (type(s.incertos) == "number") and ns.txt(s.incertos) or "-") }
  else
    lista[#lista + 1] = { rot = "SESSION", t = "-" }
  end
  local res = ok and s.resultado or nil
  local porAcao, porHora = "-", "-"
  if type(res) == "number" then
    if nAcoes and nAcoes > 0 then porAcao = U.sinal(math.floor(res / nAcoes)) end
    if dec and dec >= 60 then porHora = U.sinal(math.floor(res * 3600 / dec)) end
  end
  lista[#lista + 1] = { rot = "RESULT", t = string.format("realized %s   per action %s   per hour %s",
    U.sinal(res), porAcao, porHora) }
  lista[#lista + 1] = { t = "budget used -" }
  if ok and type(s.fora) == "number" then
    lista[#lista + 1] = { rot = "OUTSIDE", t = U.sinal(s.fora) .. " today (not trading)" }
  end
  -- PACE so aparece com numero medido: nenhuma fonte na onda 2
  lista[#lista + 1] = { rot = "BY PLAN", t = "none yet" }
  local feitos = 0
  for i = 1, #(ns.sonda and ns.sonda.passos or {}) do
    if ns.sonda.resultado(ns.sonda.passos[i].id) then feitos = feitos + 1 end
  end
  local total = ns.sonda and #ns.sonda.passos or 0
  lista[#lista + 1] = { rot = "CHECKS", t = string.format("probe steps recorded %d of %d", feitos, total) }
  -- STORAGE
  local bytes = ns.ui.ler("banco", "medidor")
  local teto = ns.cfg and ns.cfg.banco and ns.cfg.banco.teto_mb
  local mb = "-"
  if type(bytes) == "number" then
    local dec10 = math.floor(bytes * 10 / 1048576 + 0.5)
    mb = string.format("%d.%d MB", math.floor(dec10 / 10), dec10 % 10)
  end
  local ns1, ns2 = ns.ui.ler("banco", "naoSalvo")
  local acoes, minutos
  if type(ns1) == "table" then
    acoes = ns1.n or ns1.acoes
    minutos = ns1.min or ns1.minutos
  else
    acoes, minutos = ns1, ns2
  end
  local nao = "unsaved -"
  if type(acoes) == "number" then
    nao = string.format("unsaved %d actions", math.floor(acoes))
    if type(minutos) == "number" then nao = nao .. string.format(", %d min", math.floor(minutos)) end
  end
  lista[#lista + 1] = { rot = "STORAGE", t = string.format("%s of %s   %s", mb,
    teto and (ns.txt(teto) .. " MB") or "-", nao) }

  -- bilhete: salvar so com tudo em repouso
  local repouso = ns.teclas.repouso()
  local bil = {}
  local estado = "READY"
  if repouso then
    bil[1] = { rot = "TICKET", botao = "[Y] save now (reloads the interface)" }
  else
    estado = "SAVE BLOCKED"
    bil[1] = { rot = "TICKET", palavra = "SAVE BLOCKED", cp = "laranja", t = "- finish or cancel first" }
    bil[2] = { botao = "[Y] save now (reloads the interface)" }
  end
  return {
    lista = lista, itens = {}, bilhete = bil, estado = estado,
    y = { linha = repouso and 1 or 2, ativo = repouso },
  }
end

-- ---------- Mine ----------
local function campo(v, ...)
  for i = 1, select("#", ...) do
    local k = select(i, ...)
    if v[k] ~= nil then return v[k] end
  end
  return nil
end

-- um leilao proprio: linha da gramatica 1|auctionID|estado|qtd|tempo|lance|arremate|t, ou tabela ja decodificada
function U.proprio(v)
  local p = nil
  if type(v) == "string" then
    local f = {}
    for x in string.gmatch(v, "([^|]*)") do f[#f + 1] = x end
    if f[1] == "1" and #f >= 8 then
      p = { id = tonumber(f[2]), estado = tonumber(f[3]), qtd = tonumber(f[4]), tempo = tonumber(f[5]),
        lance = tonumber(f[6]), arremate = tonumber(f[7]) }
    end
  elseif type(v) == "table" then
    p = { id = tonumber(campo(v, "id", "auctionID")), estado = tonumber(campo(v, "estado", "status")),
      qtd = tonumber(campo(v, "qtd", "quantity")), tempo = tonumber(campo(v, "tempo", "timeLeftSeconds")),
      lance = tonumber(campo(v, "lance", "bid")), arremate = tonumber(campo(v, "arremate", "buyout")) }
  end
  if p and p.id then return p end
  return nil
end

function U.proprios()
  local pers = ns.ui.ler("banco", "pers")
  local src = (type(pers) == "table") and pers.proprios or nil
  local out = {}
  if type(src) ~= "table" then return out end
  for _, v in pairs(src) do
    local p = U.proprio(v)
    if p then out[#out + 1] = p end
  end
  table.sort(out, function(x, y) return x.id < y.id end)
  return out
end

function U.nomeLeilao(p)
  local qtd = p.qtd and ns.txt(p.qtd) or "?"
  -- nome do item pela chave que o Ecos viu no OWNED_AUCTIONS_UPDATED; sem ela, o id do leilao
  local nome = nil
  if ns.ecos and ns.ecos.chaveDoLeilao and ns.itens and ns.itens.info then
    local ok, info = pcall(function()
      local chave = ns.ecos.chaveDoLeilao(p.id)
      if chave then return ns.itens.info(chave) end
      return nil
    end)
    if ok and type(info) == "table" and type(info.nome) == "string" and info.nome ~= "" then
      nome = string.sub(info.nome, 1, 28)
    end
  end
  if nome then return string.format("%s x%s", nome, qtd) end
  return string.format("Auction %d x%s", p.id, qtd)
end

function U.precoLeilao(p)
  if not p.arremate or p.arremate <= 0 then return "-" end
  local q = p.qtd or 1
  if q > 1 then return ns.dinheiro(math.floor(p.arremate / q)) .. " ea" end
  return ns.dinheiro(p.arremate)
end

function U.mine()
  local todos = U.proprios()
  local itens = {}
  for i = 1, #todos do
    if not T.pulados[todos[i].id] then itens[#itens + 1] = todos[i] end
  end
  local banca = ns.ui.ler("cofre", "banca")
  local dep = (type(banca) == "table") and banca.deposito or nil
  local lista = {}
  lista[1] = { rot = string.format("MY AUCTIONS (%d)", #itens), rc = "dourado", t = "deposits at risk " .. U.mon(dep) }
  lista[2] = { cols = { "", "price", "left", "cheaper ahead" }, cor = "cinza" }
  local visiveis, mais = U.cortar(itens)
  local chaves = {}
  for i = 1, visiveis do
    local p = itens[i]
    chaves[i] = p.id
    if p.estado == 1 then
      lista[#lista + 1] = { item = i, cols = { U.nomeLeilao(p), { t = "SOLD", cor = "verde" }, "-", "gold time unknown" } }
    else
      lista[#lista + 1] = { item = i, cols = { U.nomeLeilao(p), U.precoLeilao(p), U.faixaTempo(p.tempo), "-" } }
    end
  end
  if #itens == 0 then lista[#lista + 1] = { t = "none read yet - press L", cor = "cinza" } end
  if mais then lista[#lista + 1] = { t = mais, cor = "azul" } end

  local bil = {}
  local sel = (T.sel and itens[T.sel] and T.sel <= visiveis) and itens[T.sel] or nil
  if T.conta and sel then
    bil[1] = { rot = "WHY", t = U.nomeLeilao(sel) }
    bil[2] = { t = string.format("price %s   left %s   cheaper ahead -", U.precoLeilao(sel), U.faixaTempo(sel.tempo)) }
    bil[3] = { t = string.format("state %s   deposit at risk -", sel.estado == 1 and "SOLD" or "ACTIVE") }
  else
    bil[1] = { rot = "TICKET", t = "none" }
  end
  return { lista = lista, itens = chaves, bilhete = bil, estado = "NONE" }
end

-- ---------- cartao da sonda ----------
-- quebra um texto longo em linhas de no maximo max letras, nas palavras
function U.quebrar(texto, max)
  local out = {}
  local atual = ""
  for palavra in string.gmatch(tostring(texto or ""), "%S+") do
    if atual ~= "" and #atual + 1 + #palavra > max then
      out[#out + 1] = atual
      atual = palavra
    elseif atual == "" then
      atual = palavra
    else
      atual = atual .. " " .. palavra
    end
  end
  if atual ~= "" or #out == 0 then out[#out + 1] = atual end
  return out
end

function U.secaoLonga(lista, rot, texto)
  local partes = U.quebrar(texto, 64)
  for i = 1, #partes do
    lista[#lista + 1] = { rot = (i == 1) and rot or "", t = partes[i] }
  end
end

function U.sonda()
  local c = ns.sonda.cartao(ns.sonda.atual)
  local lista = {}
  local chaves = {}
  for i = 1, #ns.sonda.passos do chaves[i] = ns.sonda.passos[i].id end
  lista[1] = { rot = "STEP", palavra = c.feito and "DONE" or "READY", cp = c.feito and "verde" or "azul",
    t = string.format("%s (%d of %d)", c.id, c.posicao, c.total) }
  U.secaoLonga(lista, "DO", c.fazer)
  U.secaoLonga(lista, "READS", c.le)
  U.secaoLonga(lista, "RESULT", c.resultado)
  U.secaoLonga(lista, "LIMIT", c.limite)
  local bil = { { rot = "TICKET", t = "read only: nothing is posted or bought" } }
  return { lista = lista, itens = chaves, bilhete = bil, estado = c.feito and "DONE" or "READY", sonda = true }
end

-- ---------- pintura ----------
function T.redesenhar()
  local visao = T.visao
  if not visao then return end
  local est = U.estadoLinhas()
  local v
  if visao == "session" then v = U.session() elseif visao == "sonda" then v = U.sonda() else v = U.mine() end
  local n = #v.itens
  if visao == "sonda" then T.sel = ns.sonda.atual end
  if T.sel and (n == 0 or T.sel > n) then T.sel = (n > 0) and n or nil end
  if not T.sel and n > 0 then T.sel = 1 end
  if visao == "sonda" then
    -- a selecao da sonda e o passo; nenhuma linha da lista leva a seta
  else
    for i = 1, #v.lista do
      if v.lista[i].item ~= nil then v.lista[i].sel = (v.lista[i].item == T.sel) end
    end
  end
  T.itens = v.itens

  ns.janela.pintar("estado", est)
  ns.janela.pintar("lista", v.lista)
  ns.janela.pintar("bilhete", v.bilhete)
  ns.janela.pintarAbas(visao)
  ns.janela.pintarY(visao == "session" and v.y or nil)
  ns.janela.pintarSonda(visao == "sonda")

  local linhas = {}
  local zonas = { est, v.lista, v.bilhete }
  for z = 1, #zonas do
    for i = 1, #zonas[z] do linhas[#linhas + 1] = ns.ui.plano(zonas[z][i]) end
  end
  ns.__tela = { visao = visao, selecionada = T.sel, linhas = linhas, faixa = ns.faixa, estado = v.estado }
end

function T.mostrar(visao)
  if visao ~= "mine" and visao ~= "session" and visao ~= "sonda" then return false end
  if T.visao ~= visao then
    T.sel = nil
    T.conta = false
    T.expandido = false
  end
  T.visao = visao
  T.redesenhar()
  return true
end

-- ---------- navegacao (N, U, I, O, K): so mexem na tela ----------
function T.proximoPasso()
  if not ns.sonda then return end
  ns.sonda.atual = ns.sonda.atual + 1
  if ns.sonda.atual > #ns.sonda.passos then ns.sonda.atual = 1 end
  T.redesenhar()
end

function T.mover(d)
  if T.visao == "sonda" then
    local a = ns.sonda.atual + d
    if a < 1 then a = 1 end
    if a > #ns.sonda.passos then a = #ns.sonda.passos end
    ns.sonda.atual = a
    T.redesenhar()
    return
  end
  local n = #T.itens
  if n == 0 then return end
  local s = (T.sel or 0) + d
  if s < 1 then s = 1 end
  if s > n then s = n end
  T.sel = s
  T.redesenhar()
end

function T.porque()
  if T.visao ~= "mine" or not T.sel then return end
  T.conta = not T.conta
  T.redesenhar()
end

function T.mais()
  T.expandido = not T.expandido
  T.redesenhar()
end

function T.pular()
  if T.visao == "sonda" then
    T.proximoPasso()
    return
  end
  if T.visao ~= "mine" or not T.sel then return end
  local chave = T.itens[T.sel]
  if chave ~= nil then T.pulados[chave] = true end
  T.conta = false
  T.redesenhar()
end

-- ---------- painel do correio ----------
function U.correio()
  local p = ns.ui.ler("correio", "painel")
  local rows = {}
  if type(p) ~= "table" then
    rows[1] = { rot = "STATE", t = "-" }
    rows[2] = { rot = "CHECK", t = "-" }
    return rows, "NONE"
  end
  local mostradas = tonumber(p.mostradas)
  local total = tonumber(p.total)
  local mais = p.maisCartas and true or (mostradas ~= nil and total ~= nil and total > mostradas)
  local estado, cp, texto, verifica
  if mais then
    estado, cp = "MORE MAIL WAITING", "laranja"
    texto = string.format("- %s of %s letters shown", mostradas and ns.txt(mostradas) or "-", total and ns.txt(total) or "-")
    verifica = "not closed: the box shows less than the total"
  else
    estado, cp = "READY", "verde"
    texto = string.format("- %s letters read. Take your mail now.", mostradas and ns.txt(mostradas) or "-")
    verifica = "waiting for you to take the mail"
  end
  rows[1] = { rot = "STATE", palavra = estado, cp = cp, t = texto }

  local nVend, ganho, corte, devol = 0, 0, 0, 0
  local nExp, itensExp, perdido = 0, 0, 0
  local nComp, itensComp = 0, 0
  local faturas = (type(p.faturas) == "table") and p.faturas or {}
  for i = 1, #faturas do
    local f = faturas[i]
    if type(f) == "table" then
      local tipo = f.tipo
      if tipo == "seller" then
        nVend = nVend + 1
        ganho = ganho + (tonumber(f.bid) or 0) - (tonumber(f.consignment) or 0)
        corte = corte + (tonumber(f.consignment) or 0)
        devol = devol + (tonumber(f.deposit) or 0)
      elseif tipo == "buyer" then
        nComp = nComp + 1
        itensComp = itensComp + (tonumber(f.count) or 1)
      elseif tipo == "expired" then
        nExp = nExp + 1
        itensExp = itensExp + (tonumber(f.count) or 1)
        perdido = perdido + (tonumber(f.deposit) or 0)
      end
    end
  end
  rows[2] = { rot = string.format("SOLD (%d)", nVend),
    t = string.format("%s   cut %s   deposits back %s", U.sinal(ganho), U.mon(corte), U.mon(devol)) }
  rows[3] = { rot = string.format("EXPIRED (%d)", nExp),
    t = string.format("%d items back   deposits lost %s", itensExp, U.mon(perdido)) }
  rows[4] = { rot = string.format("BOUGHT (%d)", nComp), t = string.format("%d items to collect", itensComp) }
  local a = p.aCaminho
  local nPend = 0
  local prim = nil
  if type(a) == "number" then
    nPend = math.floor(a)
  elseif type(a) == "table" then
    nPend = #a
    prim = a[1]
  end
  local tp = "none"
  if nPend > 0 then
    tp = "sale pending"
    if type(prim) == "table" and prim.etaHour and prim.etaMin then
      tp = tp .. string.format(", gold arrives at %02d:%02d", math.floor(prim.etaHour), math.floor(prim.etaMin))
    end
  end
  rows[5] = { rot = string.format("PENDING (%d)", nPend), t = tp }
  rows[6] = { rot = "CHECK", t = verifica }
  return rows, estado
end

function T.redesenharCorreio()
  local rows, estado = U.correio()
  ns.janela.pintarCorreio(rows)
  local linhas = {}
  for i = 1, #rows do linhas[#linhas + 1] = ns.ui.plano(rows[i]) end
  ns.__correio = { linhas = linhas, estado = estado }
end

-- ---------- bandeira suja ----------
ns.aoSujo("tela", function()
  T.redesenhar()
  if ns.janela.correioAberto() then T.redesenharCorreio() end
end)
