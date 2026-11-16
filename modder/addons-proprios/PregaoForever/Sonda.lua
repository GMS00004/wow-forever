-- Sonda.lua (PregaoForever): roteiro dos passos de medicao da onda 2 (S1, S3, S4, S5, S9, S12, S13), um cartao por passo,
-- e a gravacao de sonda[passo] no formato 1|t|build|resultado (ns.banco.cod.sonda quando o banco existir).
-- Contrato: ARQUITETURA.md, secoes 3.12 e 4; DESIGN.md, Apendice A. Nesta onda a sonda so le e mede: nenhuma acao de leilao.
local _, ns = ...
ns.sonda = ns.sonda or {}
local S = ns.sonda

-- Um cartao por passo: o que fazer (DO), o que le (READS) e o limite (LIMIT). Texto em ingles, sem acento.
S.passos = {
  { id = "S1",
    fazer = "click Save now (reloads the interface); repeat with the saved data at 1, 3 and 5 MB",
    le = "server time at the click and at the next load; then check the saved file",
    limite = "4 reloads, no gold spent" },
  { id = "S3",
    fazer = "nothing extra: press L once as usual, with a green item that has a suffix in the bags",
    le = "key text of a green with a suffix; commodity flag of the keys; both ladders of a gear item",
    limite = "passive, zero cost" },
  { id = "S4",
    fazer = "5 timed looks (L): with and without Auctionator; on the Buy tab and on the Auctions tab",
    le = "summary time and requests; repeat; throttle pace; how the addons share the house",
    limite = "zero cost" },
  { id = "S5",
    fazer = "press L over 20 ladders and read the first rung of each",
    le = "owners count and time left filled in; order of the first page; own units marked",
    limite = "zero cost" },
  { id = "S9",
    fazer = "post and cancel one auction with the Blizzard window, not with this addon",
    le = "whether the events of an action done outside reach the addon",
    limite = "1 deposit, paid by you" },
  { id = "S12",
    fazer = "click in the Blizzard search box (then in the Auctionator box) and press N",
    le = "whether the addon sees the text box focus: the banner Keys paused",
    limite = "zero cost" },
  { id = "S13",
    fazer = "the agent breaks Config.lua, you reload and note it, the agent restores it",
    le = "whether the later files load and the banner CONFIG ERROR shows; then the truncated saved file",
    limite = "2 reloads" },
}

S.atual = 1

function S.indice(id)
  for i = 1, #S.passos do
    if S.passos[i].id == id then return i end
  end
  return nil
end

local function tabela()
  if type(PregaoForeverDB) ~= "table" then return nil end
  if ns.banco and ns.banco.carregado == false then return nil end
  if type(PregaoForeverDB.sonda) ~= "table" then PregaoForeverDB.sonda = {} end
  return PregaoForeverDB.sonda
end

-- Linha gravada do passo (ou nil).
function S.registro(id)
  local t = tabela()
  if not t then return nil end
  local v = t[id]
  if type(v) == "string" then return v end
  return nil
end

-- Texto do resultado (quarto campo da linha) ou nil.
function S.resultado(id)
  local linha = S.registro(id)
  if not linha then return nil end
  local r = string.match(linha, "^[^|]*|[^|]*|[^|]*|(.*)$")
  if r == nil or r == "" then return nil end
  return r
end

-- Grava sonda[id] = 1|t|build|resultado. Devolve a linha ou nil se nao ha onde gravar.
function S.gravar(id, resultado)
  local t = tabela()
  if not t then return nil end
  local agora = ns.servidor()
  local build = "?"
  if GetBuildInfo then
    local _, b = GetBuildInfo()
    if b ~= nil then build = tostring(b) end
  end
  local limpo = string.gsub(tostring(resultado or ""), "[|\r\n]", "/")
  local linha = nil
  if ns.banco and ns.banco.cod and type(ns.banco.cod.sonda) == "function" then
    local ok, r = pcall(ns.banco.cod.sonda, { t = agora, build = build, resultado = limpo })
    if ok and type(r) == "string" then linha = r end
  end
  if not linha then linha = "1|" .. ns.txt(agora) .. "|" .. build .. "|" .. limpo end
  t[id] = linha
  return linha
end

-- S1: carimbo do clique de salvar (a Janela chama so quando vai recarregar).
function S.aoSalvar()
  S.gravar("S1", "click=" .. ns.txt(ns.servidor()))
  ns.sujo("tela")
end

-- S12: o foco numa caixa de texto foi visto pelo addon.
function S.aoPausa()
  S.gravar("S12", "text box focus seen: keys paused")
  ns.sujo("tela")
end

-- S9: eventos de acao feita por fora; junta as palavras vistas.
function S.aoEvento(palavra)
  local atual = S.resultado("S9") or ""
  if string.find(atual, palavra, 1, true) then return end
  local novo = atual
  if novo == "" then novo = "seen:" end
  S.gravar("S9", novo .. " " .. palavra)
  ns.sujo("tela")
end

-- Cartao do passo i: dados para a tela.
function S.cartao(i)
  local p = S.passos[i]
  if not p then return nil end
  local res = S.resultado(p.id)
  return {
    id = p.id, posicao = i, total = #S.passos,
    fazer = p.fazer, le = p.le, limite = p.limite,
    resultado = res or "waiting for the game",
    feito = res ~= nil,
  }
end

-- ---------- eventos ----------
ns.ao("ADDON_LOADED", function(_, nome)
  if nome ~= ns.NOME then return end
  -- S1: segundo carimbo, no carregamento que segue o clique de salvar
  local r = S.resultado("S1")
  if r then
    local clique = string.match(r, "click=(%d+)")
    if clique and not string.find(r, "load=", 1, true) then
      local agora = ns.servidor()
      S.gravar("S1", "click=" .. clique .. " load=" .. ns.txt(agora) .. " gap=" .. ns.txt(agora - tonumber(clique)) .. "s")
    end
  end
  -- S13: Config quebrado e os arquivos seguintes carregaram (este arquivo vem depois do Config)
  if not ns.configOk() then
    S.gravar("S13", "config error seen at load, later files loaded")
  end
end)

ns.ao("AUCTION_HOUSE_AUCTION_CREATED", function() S.aoEvento("created") end)
ns.ao("AUCTION_CANCELED", function() S.aoEvento("canceled") end)
