-- Livro.lua (PregaoForever): a regua. Acoes, lotes abertos e fechados, registro Fora e sessao.
-- Onda 2: so mede. Toda acao que chega aqui e 'outside' (o dono agiu pela tela da Blizzard). Nenhuma funcao de acao.
-- Contrato: ARQUITETURA.md, secao 3.7. Gramatica: secao 4 (acao, lote, fora, sessao).
local _, ns = ...
ns.livro = ns.livro or {}
local L = ns.livro

local sessao = nil

local function sessaoAtual()
  if not sessao then
    sessao = {
      tIni = ns.servidor(),
      acoes = { post = 0, buy = 0, cancel = 0, outside = 0 },
      resultado = 0,
      fora = 0,
      mov = { valor = 0, n = 0 },
    }
  end
  return sessao
end

local function pers()
  return ns.banco.pers()
end

-- abertos guarda a linha codificada (disco) ou a tabela (memoria): le dos dois jeitos
local function ler(x)
  if type(x) == 'string' then return ns.banco.dec.lote(x) end
  return x
end

local function lista(p)
  if not p.abertos then p.abertos = {} end
  return p.abertos
end

local function achar(p, seq)
  local ab = lista(p)
  for i = 1, #ab do
    local l = ler(ab[i])
    if l and l.seq == seq then return i, l end
  end
  return nil, nil
end

-- ---------- acao ----------
function L.acao(r)
  local s = sessaoAtual()
  local a = {}
  for k, v in pairs(r) do a[k] = v end
  a.seq = ns.banco.seq()
  a.t = r.t or ns.servidor()
  a.verbo = r.verbo or ''
  a.chave = r.chave or ''
  a.qtd = r.qtd or 0
  a.preco = r.preco or 0
  a.origem = r.origem or 'outside'
  a.antes = r.antes or 0
  a.depois = r.depois or 0
  ns.banco.gravar('livro', ns.banco.cod.acao(a))
  if a.origem == 'outside' then
    s.acoes.outside = s.acoes.outside + 1
  elseif s.acoes[a.verbo] ~= nil then
    s.acoes[a.verbo] = s.acoes[a.verbo] + 1
  end
  s.mov.n = s.mov.n + 1
  if r.antes and r.depois then s.mov.valor = s.mov.valor + (r.depois - r.antes) end
  return a
end

-- a intencao so passa a existir na onda 3
function L.intencao(ordem)
  return nil
end

-- ---------- lotes ----------
-- Sem r.seq abre um lote aberto; com r.seq atualiza os campos do lote aberto de mesmo seq.
function L.lote(r)
  local p = pers()
  local ab = lista(p)
  if r.seq then
    local i, l = achar(p, r.seq)
    if not i then return nil end
    for k, v in pairs(r) do l[k] = v end
    ab[i] = ns.banco.cod.lote(l)
    return l
  end
  local teto = 100
  if ns.cfg and ns.pers() == ns.cfg.negociador then teto = 300 end
  if #ab >= teto then ns.log('warn', 'TOO MANY OPEN LOTS') end
  local l = {
    seq = ns.banco.seq(), t = ns.servidor(), chave = r.chave or '', qtd = r.qtd or 1, custo = r.custo or 0,
    origem = r.origem or 'coletado', estado = r.estado or 'maos', tFecho = 0, resultado = 0,
  }
  ab[#ab + 1] = ns.banco.cod.lote(l)
  return l
end

function L.fecharLote(seq, estado, resultado)
  local p = pers()
  local i, l = achar(p, seq)
  if not i then return nil end
  table.remove(lista(p), i)
  l.estado = estado
  l.tFecho = ns.servidor()
  if resultado ~= nil then l.resultado = resultado end
  ns.banco.gravar('lotes', ns.banco.cod.lote(l))
  local s = sessaoAtual()
  s.resultado = s.resultado + (l.resultado or 0)
  return l
end

-- lotes abertos, do mais velho ao mais novo (copias)
function L.abertos()
  local p = pers()
  local ab = lista(p)
  local r = {}
  for i = 1, #ab do
    local l = ler(ab[i])
    if l then
      local c = {}
      for k, v in pairs(l) do c[k] = v end
      r[#r + 1] = c
    end
  end
  table.sort(r, function(x, y) return x.seq < y.seq end)
  return r
end

-- ---------- Fora ----------
function L.fora(variacao, janela)
  local s = sessaoAtual()
  local f = { seq = ns.banco.seq(), t = ns.servidor(), variacao = variacao, janela = janela or 'play' }
  ns.banco.gravar('fora', ns.banco.cod.fora(f))
  s.fora = s.fora + variacao
  return f
end

-- ---------- sessao ----------
-- `movimento` e acrescimo ao contrato: soma de (depois - antes) das acoes e quantas foram, para o Cofre conciliar.
function L.sessao()
  local s = sessaoAtual()
  return {
    tIni = s.tIni,
    acoes = { post = s.acoes.post, buy = s.acoes.buy, cancel = s.acoes.cancel, outside = s.acoes.outside },
    resultado = s.resultado,
    fora = s.fora,
    movimento = { valor = s.mov.valor, n = s.mov.n },
  }
end

function L.fecharSessao()
  local s = sessaoAtual()
  local linha = {
    seq = ns.banco.seq(), tIni = s.tIni, tFim = ns.servidor(),
    -- lista na ordem da gramatica: post:buy:cancel:outside (a tela usa a forma com nomes, de sessao())
    acoes = { s.acoes.post or 0, s.acoes.buy or 0, s.acoes.cancel or 0, s.acoes.outside or 0 },
    resultado = s.resultado, fora = s.fora, gargalo = '', parametros = '',
  }
  ns.banco.gravar('sessoes', ns.banco.cod.sessao(linha))
  return linha
end
