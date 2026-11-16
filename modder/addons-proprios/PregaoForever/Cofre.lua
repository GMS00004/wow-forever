-- Cofre.lua (PregaoForever): banca do personagem logado, janelas de dinheiro e conciliacao. Onda 2: so em leitura.
-- Contrato: ARQUITETURA.md, secao 3.9; DESIGN.md, secoes 9.1, 9.4 e 10. Nao autoriza nada ate a onda 3.
local _, ns = ...
ns.cofre = ns.cofre or {}
local C = ns.cofre

local NOME_DESVIO = 'dinheiro_sem_explicacao'
local NOME_FIM_SUJO = 'fim_sujo'

-- janelas abertas e a variacao de dinheiro acumulada em cada uma
local jan = { leilao = false, correio = false, vendedor = false }
local acum = { leilao = 0, correio = 0, vendedor = 0 }
local movBase = { valor = 0, n = 0 }
local ultimo = nil

C.ultima = nil

local function cofreDoPers()
  local p = ns.banco.pers()
  if not p.cofre then p.cofre = {} end
  if not p.cofre.disjuntores then p.cofre.disjuntores = {} end
  return p.cofre
end

local function ligar(nome, gatilho)
  local d = cofreDoPers().disjuntores
  if d[nome] then return end
  d[nome] = '1|' .. gatilho .. '|' .. ns.txt(ns.servidor()) .. '|' .. ns.txt(ns.banco.seq())
  ns.log('warn', 'DISJUNTOR ' .. nome .. ' ' .. gatilho)
  ns.sujo('tela')
end

-- fim sujo: o Banco diz na entrada que o dinheiro nao bate com o ultimo fecho (booleano ou funcao)
local function conferirFimSujo()
  local f = ns.banco and ns.banco.fimSujo
  if type(f) == 'function' then f = f() end
  if f then ligar(NOME_FIM_SUJO, 'fim_sujo') end
end

-- ---------- banca ----------
function C.banca()
  local piso = 0
  if ns.cfg and ns.cfg.piso_pessoal then piso = ns.cfg.piso_pessoal[ns.pers()] or 0 end
  local livre = GetMoney() - piso
  local estoque = 0 -- sem valor de saida conservador ate a onda 3: nunca a custo
  local deposito = 0
  if ns.ecos and ns.ecos.depositos then deposito = ns.ecos.depositos() end
  local correio = 0
  if ns.correio and ns.correio.painel then correio = ns.correio.painel().ouro or 0 end
  return { B = livre + estoque + deposito + correio, livre = livre, estoque = estoque, deposito = deposito, correio = correio, piso = piso }
end

function C.autoriza(ordem)
  return false, 'READ ONLY'
end

function C.disjuntores()
  conferirFimSujo()
  local d = cofreDoPers().disjuntores
  local nomes = {}
  for k in pairs(d) do nomes[#nomes + 1] = k end
  table.sort(nomes)
  return nomes
end

-- ---------- conciliacao ----------
local function conciliarInterno(janela)
  local esperado, lido, n
  if janela == 'correio' then
    local p = ns.correio.painel()
    if p.maisCartas then
      C.ultima = { janela = janela, ok = false, texto = 'MORE MAIL WAITING', t = ns.servidor() }
      return C.ultima
    end
    esperado = p.coletado or 0
    lido = acum.correio
    n = p.nFaturas or 0
  else
    janela = 'leilao'
    local mv = ns.livro.sessao().movimento
    esperado = mv.valor - movBase.valor
    lido = acum.leilao
    n = mv.n - movBase.n
  end
  local desvio = lido - esperado
  if desvio < 0 then desvio = -desvio end
  local r
  if desvio == 0 then
    r = { janela = janela, ok = true, texto = 'RECONCILED ' .. ns.txt(n) .. ' of ' .. ns.txt(n), t = ns.servidor(), desvio = 0 }
  else
    r = { janela = janela, ok = false, texto = 'UNEXPLAINED ' .. ns.dinheiro(desvio), t = ns.servidor(), desvio = desvio }
    ns.log('warn', r.texto)
    -- limite: 1% de B (DESIGN 9.4); abaixo disso so fica registrado
    local limite = math.floor(C.banca().B / 100)
    if limite < 0 then limite = 0 end
    if desvio > limite then ligar(NOME_DESVIO, 'desvio') end
  end
  C.ultima = r
  ns.sujo('tela')
  return r
end

function C.conciliar(janela)
  if janela ~= 'correio' then ns.marcarFaixa('reconciliar', nil) end
  return conciliarInterno(janela)
end

-- ---------- janelas e PLAYER_MONEY ----------
local function aoDinheiro()
  local agora = GetMoney()
  if ultimo == nil then
    ultimo = agora
    return
  end
  local d = agora - ultimo
  ultimo = agora
  if d == 0 then return end
  if jan.leilao then
    acum.leilao = acum.leilao + d
  elseif jan.correio then
    acum.correio = acum.correio + d
  elseif jan.vendedor then
    acum.vendedor = acum.vendedor + d
  else
    ns.livro.fora(d, 'play')
  end
end

local function aoEntrar()
  if ultimo == nil then ultimo = GetMoney() end
  conferirFimSujo()
end

local function abrirLeilao()
  if ultimo == nil then ultimo = GetMoney() end
  jan.leilao = true
  acum.leilao = 0
  local mv = ns.livro.sessao().movimento
  movBase.valor, movBase.n = mv.valor, mv.n
  conferirFimSujo()
  ns.marcarFaixa('reconciliar', 'Press L to reconcile')
end

local function fecharLeilao()
  if jan.leilao then conciliarInterno('leilao') end
  jan.leilao = false
end

local function abrirCorreio()
  if ultimo == nil then ultimo = GetMoney() end
  jan.correio = true
  acum.correio = 0
end

local function fecharCorreio()
  if jan.correio then conciliarInterno('correio') end
  jan.correio = false
end

local function abrirVendedor()
  if ultimo == nil then ultimo = GetMoney() end
  jan.vendedor = true
  acum.vendedor = 0
end

local function fecharVendedor()
  jan.vendedor = false
end

local function aoBolsa()
  ns.sujo('conciliar')
end

ns.ao('PLAYER_LOGIN', aoEntrar)
ns.ao('PLAYER_ENTERING_WORLD', aoEntrar)
ns.ao('PLAYER_MONEY', aoDinheiro)
ns.ao('AUCTION_HOUSE_SHOW', abrirLeilao)
ns.ao('AUCTION_HOUSE_CLOSED', fecharLeilao)
ns.ao('MAIL_SHOW', abrirCorreio)
ns.ao('MAIL_CLOSED', fecharCorreio)
ns.ao('MERCHANT_SHOW', abrirVendedor)
ns.ao('MERCHANT_CLOSED', fecharVendedor)
ns.ao('BAG_UPDATE_DELAYED', aoBolsa)

-- a bandeira suja roda no maximo uma vez por quadro; so concilia dentro de uma janela de leilao ou de correio
ns.aoSujo('conciliar', function()
  if jan.correio then
    conciliarInterno('correio')
  elseif jan.leilao then
    conciliarInterno('leilao')
  end
end)
