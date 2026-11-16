-- Correio.lua (PregaoForever): le a caixa de correio. Grava so cartas de leilao (linha fatura) e nao pega nada.
-- Le GetInboxNumItems, GetInboxHeaderInfo e GetInboxInvoiceInfo sem abrir a carta (nunca o texto dela).
-- Nome de jogador, remetente e assunto nao sao gravados. Contrato: ARQUITETURA.md, secao 3.10; DESIGN.md, secao 10.
local _, ns = ...
ns.correio = ns.correio or {}
local K = ns.correio

local TIPOS = { buyer = true, seller = true, seller_temp_invoice = true }

local est = {
  aberto = false, mostradas = 0, total = 0, faturas = 0, aCaminho = 0, liquido = 0, outras = 0,
  base = nil, coletado = 0, maisCartas = false,
}
-- assinatura da fatura (sem nome) -> quantas ja foram gravadas
local vistas = nil

local function assinatura(tipo, bid, buyout, deposit, consig, count, eh, em)
  return tipo .. '|' .. ns.txt(bid) .. '|' .. ns.txt(buyout) .. '|' .. ns.txt(deposit) .. '|' .. ns.txt(consig) ..
    '|' .. ns.txt(count) .. '|' .. ns.txt(eh) .. '|' .. ns.txt(em)
end

-- depois de um /reload, as faturas ja gravadas no anel voltam a contar como vistas
local function semear()
  vistas = {}
  pcall(function()
    local anel = ns.banco.pers().correio
    if not anel then return end
    local itens = anel
    if type(anel.itens) == 'function' then itens = anel:itens() end
    for i = 1, #itens do
      local f = itens[i]
      if type(f) == 'string' then f = ns.banco.dec.fatura(f) end
      if f then
        local a = assinatura(f.tipo, f.bid or 0, f.buyout or 0, f.deposit or 0, f.consignment or 0, f.count or 1,
          f.etaHour or 0, f.etaMin or 0)
        vistas[a] = (vistas[a] or 0) + 1
      end
    end
  end)
end

local function nomeDoLote(chave)
  local ok, info = pcall(function()
    if ns.itens and ns.itens.info then return ns.itens.info(chave) end
    return nil
  end)
  if ok and info then return info.nome end
  return nil
end

-- compra: a chave vem do anexo; venda: o nome da carta contra os lotes abertos (o nome nao vai ao disco)
local function resolver(i, tipo, nome)
  local abertos = ns.livro.abertos()
  if tipo == 'buyer' then
    local _, id = GetInboxItem(i, 1)
    if not id then return '', nil end
    local chave = ns.txt(id)
    for j = 1, #abertos do
      local c = abertos[j].chave
      if string.sub(c, 1, #chave + 1) == chave .. ':' then return c, nil end
    end
    return chave, nil
  end
  if tipo == 'seller' and nome then
    for j = 1, #abertos do
      local l = abertos[j]
      if l.estado == 'postado' and l.chave ~= '' and nomeDoLote(l.chave) == nome then return l.chave, l end
    end
  end
  return '', nil
end

local function gravar(i, f)
  local tipo, nome = f[1], f[2]
  local bid, buyout, deposit, consig = f[4] or 0, f[5] or 0, f[6] or 0, f[7] or 0
  local count = f[11] or 1
  local chave, lote = resolver(i, tipo, nome)
  local linha = {
    seq = ns.banco.seq(), t = ns.servidor(), tipo = tipo, chave = chave, bid = bid, buyout = buyout, deposit = deposit,
    consignment = consig, moneyDelay = f[8] or 0, etaHour = f[9] or 0, etaMin = f[10] or 0, count = count,
    commerce = f[12] and 1 or 0,
  }
  ns.banco.gravar('correio', ns.banco.cod.fatura(linha))
  -- venda no leilao fecha o lote pela fatura: o recebido liquido do corte, menos o custo do lote
  if lote then
    if count >= lote.qtd then
      ns.livro.fecharLote(lote.seq, 'vendido', (lote.resultado or 0) + bid - consig - (lote.custo or 0))
    else
      local resta = lote.qtd - count
      local custoResta = math.floor((lote.custo or 0) * resta / lote.qtd)
      ns.livro.lote({
        seq = lote.seq, qtd = resta, custo = custoResta,
        resultado = (lote.resultado or 0) + bid - consig - ((lote.custo or 0) - custoResta),
      })
    end
  end
end

local function ler()
  if vistas == nil then semear() end
  local mostradas, total = GetInboxNumItems()
  mostradas = mostradas or 0
  total = total or mostradas
  local nFat, pend, liq, outras = 0, 0, 0, 0
  local contagem = {}
  -- para o painel: as faturas da caixa (sem nome) e as vendas pendentes com a hora do ouro
  local lista, pendentes = {}, {}
  for i = 1, mostradas do
    local h = { GetInboxHeaderInfo(i) }
    local dinheiro = h[5] or 0
    local f = { GetInboxInvoiceInfo(i) }
    local tipo = f[1]
    if tipo and TIPOS[tipo] then
      nFat = nFat + 1
      pend = pend + dinheiro
      if tipo == 'seller_temp_invoice' then
        pendentes[#pendentes + 1] = { etaHour = f[9] or 0, etaMin = f[10] or 0 }
      else
        lista[#lista + 1] = { tipo = tipo, bid = f[4] or 0, deposit = f[6] or 0, consignment = f[7] or 0, count = f[11] or 1 }
      end
      if tipo == 'seller' then liq = liq + (f[4] or 0) + (f[6] or 0) - (f[7] or 0) end
      local a = assinatura(tipo, f[4] or 0, f[5] or 0, f[6] or 0, f[7] or 0, f[11] or 1, f[9] or 0, f[10] or 0)
      contagem[a] = (contagem[a] or 0) + 1
      if contagem[a] > (vistas[a] or 0) then
        vistas[a] = contagem[a]
        gravar(i, f)
      end
    else
      outras = outras + dinheiro
    end
  end
  est.maisCartas = total > mostradas
  if not est.maisCartas then
    for a, v in pairs(vistas) do
      local k = contagem[a] or 0
      if v > k then vistas[a] = k end
    end
  end
  est.mostradas, est.total, est.faturas, est.aCaminho, est.liquido, est.outras = mostradas, total, nFat, pend, liq, outras
  est.lista, est.pendentes = lista, pendentes
  -- o que saiu das cartas nesta janela: base tomada na primeira leitura com a caixa cheia
  local agora = liq - pend
  if est.base == nil and total > 0 then est.base = { col = agora, out = outras } end
  est.coletado = 0
  if est.base then
    local a = agora - est.base.col
    local b = est.base.out - outras
    if a > 0 then est.coletado = est.coletado + a end
    if b > 0 then est.coletado = est.coletado + b end
  end
  ns.sujo('conciliar')
  ns.sujo('tela')
end

function K.painel()
  return {
    mostradas = est.mostradas, total = est.total,
    -- para a tela: listas de faturas ({ tipo, bid, deposit, consignment, count }) e de vendas pendentes ({ etaHour, etaMin })
    faturas = est.lista or {}, aCaminho = est.pendentes or {},
    -- para o Cofre: a contagem de faturas e o ouro nas cartas de leilao
    nFaturas = est.faturas, ouro = est.aCaminho,
    maisCartas = est.maisCartas, aviso = est.maisCartas and 'MORE MAIL WAITING' or nil,
    -- acrescimos ao contrato, para a conciliacao do Cofre
    coletado = est.coletado, liquido = est.liquido,
  }
end

local function aoAbrir()
  est.aberto = true
  est.base = nil
  est.coletado = 0
  ler()
end

local function aoAtualizar()
  if not est.aberto then return end
  ler()
end

local function aoFechar()
  est.aberto = false
  ns.sujo('tela')
end

ns.ao('MAIL_SHOW', aoAbrir)
ns.ao('MAIL_INBOX_UPDATE', aoAtualizar)
ns.ao('MAIL_CLOSED', aoFechar)
