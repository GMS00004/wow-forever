-- Banco.lua (PregaoForever): SavedVariables do addon, gramatica das linhas (cod e dec), aneis com limite e poda,
-- medidor, leitor do Calibrado (desk e param), abrir e fechar. Onda 2.
-- Contrato: ARQUITETURA.md, secao 3.3, secao 4 (gramatica), secao 6 e mudancas 7 e 8.
-- Forma: a SV guarda linhas de texto (1|...). ns.banco.memoria() devolve as tabelas decodificadas de itens,
-- dias e blocos da casa atual, e de calib; o fechar codifica de volta com os limites da secao 6.2.
local _, ns = ...
local B = ns.banco or {}
ns.banco = B

local FAIXA_PERDIDO = 'DATABASE NOT LOADED - tell the agent'
local SENTINELA = 'PREGAO-CALIBRADO-FIM'
local MB = 1048576
local DIA = 86400
local BYTES_ENTRADA = 12
local LIMITE_SINAIS = 2000
local LIMITE_SESSOES = 60
local LIMITE_CHAVES_BLOCOS = 60
local CAP_AMOSTRAS = 100
-- limites dos aneis por personagem (secao 6.2): { negociador, outros }; fora nao tem limite no DESIGN, usa o do correio
local LIMITES_PESSOA = { livro = { 2000, 500 }, lotes = { 300, 100 }, correio = { 300, 100 }, fora = { 300, 100 } }
-- faixas do Apendice B para os parametros que o Calibrado pode trocar (lista parcial: so os do banco e do desk)
local FAIXAS_PARAM = {
  ['banco.teto_mb'] = { 1, 5 },
  ['banco.gatilho_poda_pct'] = { 50, 95 },
  ['dias.chaves'] = { 500, 3000 },
  ['dias.dias'] = { 7, 30 },
  ['blocos'] = { 42, 180 },
  ['fotos.fotos_por_chave'] = { 8, 64 },
  ['fotos.degraus_guardados'] = { 6, 40 },
  ['fotos.leiloes_por_foto'] = { 10, 60 },
  ['desk_stale_dias'] = { 3, 30 },
  ['salvar.sugestao_min'] = { 15, 90 },
  ['salvar.sugestao_acoes'] = { 20, 100 },
}

-- ---------- estado do modulo ----------
local mem = { casas = {}, calib = {} }      -- tabelas decodificadas (memoria())
local brutos = { casas = {}, calib = {} }   -- linhas que nao decodificaram (versao desconhecida): voltam como estavam
local medidorBytes = 0
local acoesSessao = 0
local cargaMono = nil
B.fimSujo = false

-- ---------- configuracao e Calibrado ----------
local function cfgTopo(nome, padrao)
  local c = ns.cfg
  if type(c) == 'table' and c[nome] ~= nil then return c[nome] end
  return padrao
end

local function cfgDe(secao, nome, padrao)
  local c = ns.cfg
  if type(c) == 'table' and type(c[secao]) == 'table' and c[secao][nome] ~= nil then return c[secao][nome] end
  return padrao
end

local function cabecalhoOk()
  local c = ns.calibrado
  if type(c) ~= 'table' or c.esquema ~= 1 or c.sentinela ~= SENTINELA then return false end
  return type(c.geradoEm) == 'number' and type(c.recibo) == 'number' and type(c.epoca) == 'number'
end

-- ---------- texto: numeros so por ns.txt (regra 14); '|' e quebra de linha viram '/' ----------
local function txt(v)
  local tv = type(v)
  if v == nil then return '' end
  if tv == 'number' then return ns.txt(v) end
  if tv == 'boolean' then return v and '1' or '0' end
  return (string.gsub(tostring(v), '[|\r\n]', '/'))
end

local function listaTxt(lista, sep)
  local r = {}
  for i = 1, #lista do r[i] = txt(lista[i]) end
  return table.concat(r, sep)
end

-- divide por texto simples, mantendo os campos vazios; '' vira uma parte vazia
local function dividir(s, sep)
  local r, i = {}, 1
  while true do
    local a, b = string.find(s, sep, i, true)
    if not a then
      r[#r + 1] = string.sub(s, i)
      return r
    end
    r[#r + 1] = string.sub(s, i, a - 1)
    i = b + 1
  end
end

local function montar(partes)
  return '1|' .. table.concat(partes, '|')
end

-- ---------- decodificacao ----------
local ruim = false  -- marca a leitura de um numero que nao e numero (e o campo fica nil)

local function N(s)
  if s == '' then return nil end
  local n = tonumber(s)
  if n == nil then ruim = true end
  return n
end

-- linha com versao 1 e a quantidade certa de campos depois da versao; devolve os campos (o [1] e a versao)
local function campos(linha, minimo, maximo)
  ruim = false
  if type(linha) ~= 'string' then return nil end
  local p = dividir(linha, '|')
  local n = #p - 1
  if p[1] ~= '1' or n < minimo or n > maximo then return nil end
  return p
end

-- texto de uma linha de lista (dias, blocos, dados do resumo): o corpo depois de "1|"
local function corpoV1(l)
  ruim = false
  if type(l) ~= 'string' then return nil end
  if l == '1|' then return '' end
  if string.sub(l, 1, 2) == '1|' then return string.sub(l, 3) end
  return nil
end

-- lista de valores com ':' (acoes da sessao, bilhete): numero quando parece numero, senao texto
local function listaMista(s)
  local r = {}
  if s == '' then return r end
  local partes = dividir(s, ':')
  for i = 1, #partes do
    if string.match(partes[i], '^%-?%d+$') then r[i] = tonumber(partes[i]) else r[i] = partes[i] end
  end
  return r
end

local function listaNumeros(s)
  local r = {}
  if s == '' then return r end
  local partes = dividir(s, ',')
  for i = 1, #partes do r[i] = N(partes[i]) end
  return r
end

local function numerosOrdenados(t)
  local ks = {}
  for k in pairs(t) do ks[#ks + 1] = k end
  table.sort(ks)
  return ks
end

local function chavesTexto(t)
  local ks = {}
  for k in pairs(t) do ks[#ks + 1] = k end
  table.sort(ks, function(a, b) return tostring(a) < tostring(b) end)
  return ks
end

-- ---------- gramatica (secao 4): cod.<tipo> e dec.<tipo> ----------
local cod, dec = {}, {}

-- esquema de cada tipo: { nome, tipo } com 'n' numero, 's' texto, 'l' lista com ':'
local ESQ = {
  itens = { { 'vend', 'n' }, { 'tipo', 's' }, { 'pilha', 'n' }, { 'conf', 'n' } },
  sinal = { { 'seq', 'n' }, { 't', 'n' }, { 'estrategia', 's' }, { 'nivel', 'n' }, { 'chave', 's' }, { 'qtd', 'n' },
    { 'preco', 'n' }, { 'previsto', 'n' }, { 'motivo', 's' }, { 'executou', 'n' }, { 'desfecho', 's' },
    { 'realizado', 'n' }, { 'exposicao', 'n' } },
  acao = { { 'seq', 'n' }, { 't', 'n' }, { 'verbo', 's' }, { 'chave', 's' }, { 'qtd', 'n' }, { 'preco', 'n' },
    { 'estrategia', 's' }, { 'origem', 's' }, { 'antes', 'n' }, { 'depois', 'n' }, { 'eco', 's' }, { 'tEco', 'n' },
    { 'erro', 's' }, { 'bilhete', 'l' }, { 'fotoEm', 'n' } },
  lote = { { 'seq', 'n' }, { 't', 'n' }, { 'chave', 's' }, { 'qtd', 'n' }, { 'custo', 'n' }, { 'origem', 's' },
    { 'estado', 's' }, { 'tFecho', 'n' }, { 'resultado', 'n' } },
  fatura = { { 'seq', 'n' }, { 't', 'n' }, { 'tipo', 's' }, { 'chave', 's' }, { 'bid', 'n' }, { 'buyout', 'n' },
    { 'deposit', 'n' }, { 'consignment', 'n' }, { 'moneyDelay', 'n' }, { 'etaHour', 'n' }, { 'etaMin', 'n' },
    { 'count', 'n' }, { 'commerce', 'n' } },
  fora = { { 'seq', 'n' }, { 't', 'n' }, { 'variacao', 'n' }, { 'janela', 's' } },
  proprio = { { 'auctionID', 'n' }, { 'estado', 'n' }, { 'qtd', 'n' }, { 'tempo', 'n' }, { 'lance', 'n' },
    { 'arremate', 'n' }, { 't', 'n' } },
  sessao = { { 'seq', 'n' }, { 'tIni', 'n' }, { 'tFim', 'n' }, { 'acoes', 'l' }, { 'resultado', 'n' },
    { 'fora', 'n' }, { 'gargalo', 's' }, { 'parametros', 's' } },
  npc = { { 'compra', 'n' }, { 'disponivel', 'n' }, { 't', 'n' } },
  sonda = { { 't', 'n' }, { 'build', 'n' }, { 'resultado', 's' } },
  log = { { 't', 'n' }, { 'nivel', 's' }, { 'texto', 's' } },
}

local function codPorEsquema(esq)
  return function(t)
    local partes = {}
    for i = 1, #esq do
      local f = esq[i]
      if f[2] == 'l' then partes[i] = listaTxt(t[f[1]] or {}, ':') else partes[i] = txt(t[f[1]]) end
    end
    return montar(partes)
  end
end

local function decPorEsquema(esq)
  return function(l)
    local p = campos(l, #esq, #esq)
    if p == nil then return nil end
    local r = {}
    for i = 1, #esq do
      local f = esq[i]
      local v = p[i + 1]
      if f[2] == 'n' then r[f[1]] = N(v)
      elseif f[2] == 's' then r[f[1]] = v
      else r[f[1]] = listaMista(v) end
    end
    if ruim then return nil end
    return r
  end
end

for nome, esq in pairs(ESQ) do
  cod[nome] = codPorEsquema(esq)
  dec[nome] = decPorEsquema(esq)
end

-- itens: o tipo so pode ser c (commodity) ou i (item)
local decItensBruto = dec.itens
function dec.itens(l)
  local r = decItensBruto(l)
  if r == nil or (r.tipo ~= 'c' and r.tipo ~= 'i') then return nil end
  return r
end

-- resumo: tabela { t, tr, pedidos, completa, n, dados }; dados e a string 1|chave=min:qtd;...
-- na memoria (dec) dados vira { [chave] = { min, qtd } }; cod devolve a tabela com dados como string
function cod.resumo(t)
  local dados = t.dados or {}
  local ks = chavesTexto(dados)
  local partes = {}
  for i = 1, #ks do
    local v = dados[ks[i]]
    partes[i] = txt(ks[i]) .. '=' .. txt(v.min) .. ':' .. txt(v.qtd)
  end
  return { t = t.t, tr = t.tr, pedidos = t.pedidos, completa = t.completa, n = t.n, dados = '1|' .. table.concat(partes, ';') }
end

function dec.resumo(t)
  if type(t) ~= 'table' then return nil end
  local corpo = corpoV1(t.dados)
  if corpo == nil then return nil end
  local dados = {}
  if corpo ~= '' then
    local pares = dividir(corpo, ';')
    for i = 1, #pares do
      local eq = string.find(pares[i], '=', 1, true)
      if not eq then return nil end
      local v = dividir(string.sub(pares[i], eq + 1), ':')
      if #v ~= 2 then return nil end
      dados[string.sub(pares[i], 1, eq - 1)] = { min = N(v[1]), qtd = N(v[2]) }
    end
  end
  if ruim then return nil end
  return { t = t.t, tr = t.tr, pedidos = t.pedidos, completa = t.completa, n = t.n, dados = dados }
end

-- dias e blocos: 1|chave:min:qtd;... com chave numerica
local function codMapaTempo(mapa)
  local ks = numerosOrdenados(mapa)
  local partes = {}
  for i = 1, #ks do
    local v = mapa[ks[i]]
    partes[i] = txt(ks[i]) .. ':' .. txt(v.min) .. ':' .. txt(v.qtd)
  end
  return '1|' .. table.concat(partes, ';')
end

local function decMapaTempo(l)
  local corpo = corpoV1(l)
  if corpo == nil then return nil end
  local r = {}
  if corpo == '' then return r end
  local pares = dividir(corpo, ';')
  for i = 1, #pares do
    local v = dividir(pares[i], ':')
    if #v ~= 3 then return nil end
    local k = N(v[1])
    if k == nil or ruim then return nil end
    r[k] = { min = N(v[2]), qtd = N(v[3]) }
  end
  if ruim then return nil end
  return r
end

cod.dias, dec.dias = codMapaTempo, decMapaTempo
cod.blocos, dec.blocos = codMapaTempo, decMapaTempo

-- fotos de commodity: 1|seq|t|marcas|qtot|degraus|cauda; degrau preco:qtd:donos:proprias:conta; cauda 8 baldes ou T
function cod.fotoC(t)
  local degs = {}
  local ds = t.degraus or {}
  for i = 1, #ds do
    local d = ds[i]
    degs[i] = table.concat({ txt(d.preco), txt(d.qtd), txt(d.donos), txt(d.proprias), txt(d.conta) }, ':')
  end
  local cauda
  if t.cauda == 'T' then cauda = 'T' else cauda = listaTxt(t.cauda or {}, ',') end
  return montar({ txt(t.seq), txt(t.t), txt(t.marcas), txt(t.qtot), table.concat(degs, ','), cauda })
end

function dec.fotoC(l)
  local p = campos(l, 6, 6)
  if p == nil then return nil end
  local degs = {}
  if p[6] ~= '' then
    local partes = dividir(p[6], ',')
    for i = 1, #partes do
      local v = dividir(partes[i], ':')
      if #v ~= 5 then return nil end
      degs[i] = { preco = N(v[1]), qtd = N(v[2]), donos = N(v[3]), proprias = N(v[4]), conta = N(v[5]) }
    end
  end
  local cauda = 'T'
  if p[7] ~= 'T' then cauda = listaNumeros(p[7]) end
  local r = { seq = N(p[2]), t = N(p[3]), marcas = p[4], qtot = N(p[5]), degraus = degs, cauda = cauda }
  if ruim then return nil end
  return r
end

-- fotos de item: 1|seq|t|marcas|donos|nomesVieram|leiloes|resto; leilao id:arremate:lance:faixa:qtd:dono:conta
function cod.fotoI(t)
  local ls = {}
  local lei = t.leiloes or {}
  for i = 1, #lei do
    local x = lei[i]
    ls[i] = table.concat({ txt(x.id), txt(x.arremate), txt(x.lance), txt(x.faixa), txt(x.qtd), txt(x.dono), txt(x.conta) }, ':')
  end
  local resto = ''
  if t.resto ~= nil then resto = txt(t.resto.contagem) .. ':' .. txt(t.resto.soma) end
  return montar({ txt(t.seq), txt(t.t), txt(t.marcas), txt(t.donos), txt(t.nomesVieram), table.concat(ls, ','), resto })
end

function dec.fotoI(l)
  local p = campos(l, 7, 7)
  if p == nil then return nil end
  local ls = {}
  if p[7] ~= '' then
    local partes = dividir(p[7], ',')
    for i = 1, #partes do
      local v = dividir(partes[i], ':')
      if #v ~= 7 then return nil end
      ls[i] = { id = N(v[1]), arremate = N(v[2]), lance = N(v[3]), faixa = N(v[4]), qtd = N(v[5]), dono = N(v[6]), conta = N(v[7]) }
    end
  end
  local resto = nil
  if p[8] ~= '' then
    local v = dividir(p[8], ':')
    if #v ~= 2 then return nil end
    resto = { contagem = N(v[1]), soma = N(v[2]) }
  end
  local r = { seq = N(p[2]), t = N(p[3]), marcas = p[4], donos = N(p[5]), nomesVieram = N(p[6]), leiloes = ls, resto = resto }
  if ruim then return nil end
  return r
end

-- calibracao: 1|valor|n|medido|em|build, e depois (se houver) as amostras separadas por ';'
function cod.calib(t)
  local partes = { txt(t.valor), txt(t.n), txt(t.medido), txt(t.em), txt(t.build) }
  if t.amostras and #t.amostras > 0 then partes[6] = table.concat(t.amostras, ';') end
  return montar(partes)
end

function dec.calib(l)
  local p = campos(l, 5, 6)
  if p == nil then return nil end
  local r = { valor = N(p[2]), n = N(p[3]), medido = N(p[4]), em = N(p[5]), build = N(p[6]), amostras = {} }
  if p[7] ~= nil and p[7] ~= '' then r.amostras = dividir(p[7], ';') end
  if ruim then return nil end
  return r
end

-- ---------- memoria: codificacao com os limites da secao 6.2 (em ordem de chave) ----------
local function codificarMapa(mapa, codFn, brutosMapa)
  local saida = {}
  for k, v in pairs(mapa) do saida[k] = codFn(v) end
  for k, l in pairs(brutosMapa or {}) do
    if mapa[k] == nil then saida[k] = l end
  end
  return saida
end

-- dias e blocos: por chave, so os maiores (mais novos) ate maxPorChave; minimoDia corta os dias velhos;
-- chaves ordenadas pelo dia mais novo e cortadas em maxChaves
local function codificarJanela(mapa, brutosMapa, codFn, minimoDia, maxPorChave, maxChaves)
  local cand = {}
  for chave, dias in pairs(mapa) do
    local ks = numerosOrdenados(dias)
    local manter, sub = {}, {}
    for i = #ks, 1, -1 do
      local k = ks[i]
      if (minimoDia == nil or k >= minimoDia) and #manter < maxPorChave then
        manter[#manter + 1] = k
        sub[k] = dias[k]
      end
    end
    if #manter > 0 then cand[#cand + 1] = { chave = chave, ultimo = manter[1], sub = sub } end
  end
  table.sort(cand, function(a, b)
    if a.ultimo ~= b.ultimo then return a.ultimo > b.ultimo end
    return tostring(a.chave) < tostring(b.chave)
  end)
  local saida = {}
  for i = 1, math.min(#cand, maxChaves) do saida[cand[i].chave] = codFn(cand[i].sub) end
  for k, l in pairs(brutosMapa or {}) do
    if mapa[k] == nil then saida[k] = l end
  end
  return saida
end

local function codificarCalib(mapa, brutosMapa)
  local saida = {}
  for p, v in pairs(mapa) do
    local am = v.amostras or {}
    local corte = {}
    for i = math.max(1, #am - CAP_AMOSTRAS + 1), #am do corte[#corte + 1] = am[i] end
    saida[p] = cod.calib({ valor = v.valor, n = v.n, medido = v.medido, em = v.em, build = v.build, amostras = corte })
  end
  for p, l in pairs(brutosMapa or {}) do
    if mapa[p] == nil then saida[p] = l end
  end
  return saida
end

local function decodificarMapa(mapaSV, decFn, saida, brutosMapa)
  if type(mapaSV) ~= 'table' then return 0 end
  local naoLidas = 0
  for k, l in pairs(mapaSV) do
    local v = decFn(l)
    if v == nil then
      brutosMapa[k] = l
      naoLidas = naoLidas + 1
    else
      saida[k] = v
    end
  end
  return naoLidas
end

-- ---------- SavedVariables: secoes, medidor, recibo, sequencia ----------
-- secao de mercado da casa na SV (linhas de texto); cria as subtabelas da secao 6
local function casaSV(key)
  local db = PregaoForeverDB
  db.casas = db.casas or {}
  local sec = db.casas[key]
  if sec == nil then
    sec = {}
    db.casas[key] = sec
  end
  sec.itens = sec.itens or {}
  sec.resumo = sec.resumo or {}
  sec.dias = sec.dias or {}
  sec.blocos = sec.blocos or {}
  sec.fotos = sec.fotos or {}
  sec.npc = sec.npc or {}
  return sec
end

-- soma das strings da SV mais 12 bytes por entrada (sem contar numeros e booleanos)
local function medirTudo(t, vistos)
  vistos = vistos or {}
  if vistos[t] then return 0 end
  vistos[t] = true
  local total = 0
  for _, v in pairs(t) do
    total = total + BYTES_ENTRADA
    if type(v) == 'string' then
      total = total + #v
    elseif type(v) == 'table' then
      total = total + medirTudo(v, vistos)
    end
  end
  return total
end

local function recibo()
  local r = 0
  local db = PregaoForeverDB
  if db and type(db.recibo) == 'number' then r = db.recibo end
  if cabecalhoOk() and ns.calibrado.recibo > r then r = ns.calibrado.recibo end
  return r
end

local function limiteBytes()
  return cfgDe('banco', 'teto_mb', 3) * MB * cfgDe('banco', 'gatilho_poda_pct', 80) / 100
end

local function seqDe(l)
  local s = string.match(l, '^1|(%d+)|')
  if s == nil then return nil end
  return tonumber(s)
end

local function registrarSobrescrito(chave, s)
  local so = PregaoForeverDB.sobrescritos
  local r = so[chave]
  if r == nil then
    so[chave] = { s, s }
  else
    if s < r[1] then r[1] = s end
    if s > r[2] then r[2] = s end
  end
end

local function tirar(lista, i)
  local v = table.remove(lista, i)
  medidorBytes = medidorBytes - (#v + BYTES_ENTRADA)
  return v
end

-- todas as listas de fotos da SV, em ordem fixa (casa e chave)
local function aneisFotos()
  local r = {}
  local db = PregaoForeverDB
  for _, casa in ipairs(chavesTexto(db.casas)) do
    local sec = db.casas[casa]
    if type(sec) == 'table' and type(sec.fotos) == 'table' then
      for _, chave in ipairs(chavesTexto(sec.fotos)) do
        r[#r + 1] = { nome = casa .. '/fotos:' .. chave, lista = sec.fotos[chave] }
      end
    end
  end
  return r
end

-- poda (secao 6.2): acima do gatilho, sai primeiro a foto com seq ate o recibo, depois a mais velha
local function poda()
  local alvo = limiteBytes()
  local r = recibo()
  local aneis = aneisFotos()
  for _, a in ipairs(aneis) do
    local i = 1
    while i <= #a.lista and medidorBytes > alvo do
      local s = seqDe(a.lista[i])
      if s ~= nil and s <= r then tirar(a.lista, i) else i = i + 1 end
    end
  end
  while medidorBytes > alvo do
    local ha, hi, hs = nil, nil, nil
    for _, a in ipairs(aneis) do
      for i = 1, #a.lista do
        local s = seqDe(a.lista[i])
        if s ~= nil and (hs == nil or s < hs) then ha, hi, hs = a, i, s end
      end
    end
    if ha == nil then break end
    tirar(ha.lista, hi)
    if hs > r then registrarSobrescrito(ha.nome, hs) end
  end
  if medidorBytes > alvo then ns.log('aviso', 'poda sem efeito: so fotos, e ainda acima do gatilho') end
end

-- anel e limite de um nome de anel; chaveSob e a chave em sobrescritos
local function anelDe(anel)
  local db = PregaoForeverDB
  if anel == 'sinais' then return db.sinais, LIMITE_SINAIS, 'sinais' end
  if anel == 'sessoes' then return db.sessoes, LIMITE_SESSOES, 'sessoes' end
  local chave = string.match(anel, '^fotos:(.+)$')
  if chave ~= nil then
    local casa = ns.casa()
    local sec = casaSV(casa)
    sec.fotos[chave] = sec.fotos[chave] or {}
    return sec.fotos[chave], cfgDe('fotos', 'fotos_por_chave', 16), casa .. '/' .. anel
  end
  local lim = LIMITES_PESSOA[anel]
  if lim ~= nil then
    local eu = ns.pers()
    local p = B.pers(eu)
    local limite = lim[2]
    if eu == cfgTopo('negociador', nil) then limite = lim[1] end
    return p[anel], limite, eu .. '/' .. anel
  end
  return nil
end

-- ---------- abrir (ADDON_LOADED) ----------
local function criarBanco()
  local t = ns.servidor()
  PregaoForeverDB = {
    esquema = 1, epoca = t, seq = 0, recibo = 0, calib = {}, casas = {}, sinais = {}, pers = {},
    sessoes = {}, sonda = {}, log = {}, sobrescritos = {}, salvoEm = 0, fim = 0,
  }
  return PregaoForeverDB
end

local function carregarBanco(db)
  db.seq = db.seq or 0
  db.recibo = db.recibo or 0
  db.fim = db.fim or 0
  db.salvoEm = db.salvoEm or 0
  db.calib = db.calib or {}
  db.casas = db.casas or {}
  db.sinais = db.sinais or {}
  db.pers = db.pers or {}
  db.sessoes = db.sessoes or {}
  db.sonda = db.sonda or {}
  db.log = db.log or {}
  db.sobrescritos = db.sobrescritos or {}
  mem = { casas = {}, calib = {} }
  brutos = { casas = {}, calib = {} }
  local naoLidas = 0
  for key, sec in pairs(db.casas) do
    local m = { itens = {}, dias = {}, blocos = {} }
    local b = { itens = {}, dias = {}, blocos = {} }
    if type(sec) == 'table' then
      naoLidas = naoLidas + decodificarMapa(sec.itens, dec.itens, m.itens, b.itens)
      naoLidas = naoLidas + decodificarMapa(sec.dias, dec.dias, m.dias, b.dias)
      naoLidas = naoLidas + decodificarMapa(sec.blocos, dec.blocos, m.blocos, b.blocos)
    end
    mem.casas[key] = m
    brutos.casas[key] = b
  end
  naoLidas = naoLidas + decodificarMapa(db.calib, dec.calib, mem.calib, brutos.calib)
  if naoLidas > 0 then ns.log('aviso', 'linhas de versao desconhecida: ' .. ns.txt(naoLidas)) end
end

local function perdido(motivo)
  B.carregado = false
  B.fimSujo = false
  ns.log('erro', 'banco nao carregou: ' .. motivo)
  ns.marcarFaixa('banco', FAIXA_PERDIDO)
end

function B.abrir()
  local db = PregaoForeverDB
  local charDB = PregaoForeverCharDB
  if db == nil and type(charDB) == 'table' and charDB.bancoDesde ~= nil then
    return perdido('PregaoForeverDB ausente, com bancoDesde no personagem')
  end
  if db ~= nil and (type(db) ~= 'table' or db.esquema ~= 1) then
    return perdido('esquema de PregaoForeverDB desconhecido')
  end
  local novo = db == nil
  if novo then db = criarBanco() else carregarBanco(db) end
  if type(charDB) ~= 'table' then charDB = {} end
  PregaoForeverCharDB = charDB
  if charDB.bancoDesde == nil then charDB.bancoDesde = ns.servidor() end

  -- saida suja: o fim nao e o seq, ou o dinheiro nao bate com o fecho do personagem (secao 6.3)
  local sujo = db.fim ~= db.seq
  local p = db.pers[ns.pers()]
  if p ~= nil and p.fecho ~= nil and p.fecho.dinheiro ~= GetMoney() then sujo = true end
  B.fimSujo = sujo
  if sujo then ns.log('aviso', 'saida sem fecho limpo: fim ou dinheiro diferente do fecho') end

  medidorBytes = medirTudo(db)
  B.carregado = true
  cargaMono = ns.mono()
  acoesSessao = 0
  if ns.faixaLigada('banco') then ns.marcarFaixa('banco', nil) end
  ns.log('info', novo and 'banco novo' or 'banco carregado')
end

-- ---------- uso pelos outros modulos ----------
-- secao de mercado da casa atual, na SV (linhas de texto)
function B.casa()
  if B.carregado ~= true then return {} end
  return casaSV(ns.casa())
end

-- secao do personagem (padrao ns.pers()), com as subtabelas da secao 6
function B.pers(nome)
  if B.carregado ~= true then return {} end
  nome = nome or ns.pers()
  local db = PregaoForeverDB
  db.pers = db.pers or {}
  local p = db.pers[nome]
  if p == nil then
    p = {}
    db.pers[nome] = p
  end
  p.livro = p.livro or {}
  p.lotes = p.lotes or {}
  p.abertos = p.abertos or {}
  p.proprios = p.proprios or {}
  p.correio = p.correio or {}
  p.fora = p.fora or {}
  p.cofre = p.cofre or {}
  return p
end

-- tabelas decodificadas da memoria: itens, dias e blocos da casa atual, e calib
function B.memoria()
  local key = ns.casa()
  local m = mem.casas[key]
  if m == nil then
    m = { itens = {}, dias = {}, blocos = {} }
    mem.casas[key] = m
    if B.carregado == true then casaSV(key) end
  end
  return { itens = m.itens, dias = m.dias, blocos = m.blocos, calib = mem.calib }
end

function B.seq()
  if B.carregado ~= true then return nil end
  local db = PregaoForeverDB
  db.seq = (db.seq or 0) + 1
  return db.seq
end

-- grava uma linha no anel; anel cheio sobrescreve o mais velho e anota o que cobriu sem recibo
function B.gravar(anel, linha)
  if B.carregado ~= true or type(linha) ~= 'string' then return false end
  local lista, limite, chaveSob = anelDe(anel)
  if lista == nil then
    ns.log('erro', 'anel desconhecido: ' .. tostring(anel))
    return false
  end
  lista[#lista + 1] = linha
  medidorBytes = medidorBytes + #linha + BYTES_ENTRADA
  while #lista > limite do
    local velha = tirar(lista, 1)
    local s = seqDe(velha)
    if s ~= nil and s > recibo() then registrarSobrescrito(chaveSob, s) end
  end
  if anel == 'livro' then acoesSessao = acoesSessao + 1 end
  if medidorBytes > limiteBytes() then poda() end
  return true
end

function B.medidor()
  return medidorBytes
end

-- acoes e minutos desde o ultimo /reload
function B.naoSalvo()
  local minutos = 0
  if cargaMono ~= nil then minutos = math.floor((ns.mono() - cargaMono) / 60) end
  return acoesSessao, minutos
end

-- valor calibrado dentro da faixa do Apendice B; fora dela, ou sem Calibrado valido, vale o do Config
local function caminhoCfg(nome)
  local v = ns.cfg
  for parte in string.gmatch(nome, '[^%.]+') do
    if type(v) ~= 'table' then return nil end
    v = v[parte]
  end
  return v
end

function B.param(nome)
  local partida = caminhoCfg(nome)
  local faixa = FAIXAS_PARAM[nome]
  if faixa == nil or not cabecalhoOk() then return partida end
  local valores = ns.calibrado.valores or {}
  local e = valores[nome]
  local v = nil
  if type(e) == 'table' then v = e.valor elseif type(e) == 'number' then v = e end
  if type(v) == 'number' and v >= faixa[1] and v <= faixa[2] then return v end
  return partida
end

-- leitor do Calibrado (secao 12, modos): cabecalho, sentinela e idade ate cfg.desk_stale_dias
function B.desk()
  if not cabecalhoOk() then return 'NO DESK' end
  local idade = ns.servidor() - ns.calibrado.geradoEm
  local limite = cfgTopo('desk_stale_dias', 7) * DIA
  if idade >= 0 and idade <= limite then return 'DESK OK' end
  return 'DESK STALE'
end

-- saida limpa: codifica a memoria na SV, grava o fecho e por ultimo fim = seq (secao 6.3)
function B.fechar()
  if B.carregado ~= true then return end
  local db = PregaoForeverDB
  -- a linha da sessao vem antes do fecho: ela gasta um seq e o fecho registra o ultimo
  if ns.livro and ns.livro.fecharSessao then
    xpcall(ns.livro.fecharSessao, geterrorhandler())
  end
  local hoje = ns.diaMercado(ns.servidor())
  for key, m in pairs(mem.casas) do
    local sec = casaSV(key)
    local b = brutos.casas[key] or { itens = {}, dias = {}, blocos = {} }
    sec.itens = codificarMapa(m.itens, cod.itens, b.itens)
    sec.dias = codificarJanela(m.dias, b.dias, cod.dias,
      hoje - cfgDe('dias', 'dias', 14) + 1, cfgDe('dias', 'dias', 14), cfgDe('dias', 'chaves', 1500))
    sec.blocos = codificarJanela(m.blocos, b.blocos, cod.blocos, nil, cfgTopo('blocos', 126), LIMITE_CHAVES_BLOCOS)
  end
  db.calib = codificarCalib(mem.calib, brutos.calib)
  db.log = ns.registro:itens()
  local p = B.pers(ns.pers())
  p.fecho = { dinheiro = GetMoney(), t = ns.servidor(), seq = db.seq }
  db.salvoEm = ns.servidor()
  db.fim = db.seq
  medidorBytes = medirTudo(db)
end

B.cod = cod
B.dec = dec
