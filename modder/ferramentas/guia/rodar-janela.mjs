// Banco de prova da janela J do GuiaForever (ARQUITETURA.md, secao 11.8).
// Roda os .lua do .toc no fengari (Lua 5.3 em JavaScript) com a API do WoW simulada num estado fixo
// (cacador Night Elf 16, javali 16, Skinning 75/75, Leatherworking 55/100), chama os construtores de cada
// aba e sub-aba, confere os blocos contra o contrato (tipos, campos, C1, C2, C5, C6) e grava
// visual\real.json e visual\real.html.
//
// Uso: node rodar-janela.mjs [--estrito] [--desenhar] [--abrir] [--abas a,b/c] [--pular]
//        [--classe HUNTER|PALADIN] [--nivel N] [--livres K] [--com-furia] [--sem "<magia>"]... [--paladino]
// --abrir: abre a janela e cada aba, sub-aba e id antigo, faz a busca "boar" e fecha (erro de Lua = erro).
// --classe: o personagem simulado. HUNTER (padrao) = cacador Night Elf, nivel 16, 0 pontos livres, javali, Skinning/
//   Leatherworking, Darkshore. PALADIN = Ignatius Stonejaw, Human, nivel 27, 1 ponto livre, sem pet, Elwynn Forest
//   (mapa 1429), Mining 75/75 e Blacksmithing 55/100; grava visual\real-PALADIN.json e .html (o real.json e .html
//   continuam sendo do cacador). Com PALADIN o banco tambem simula C_UnitAuras, issecretvalue e as APIs de macro.
// --nivel N / --livres K: nivel e pontos de talento livres do personagem simulado (padroes acima).
// --com-furia: o buff Righteous Fury ativo (GetAuraDataBySpellName devolve a aura).
// --sem "<magia>" (repetivel): tira a magia do livro de magias simulado.
// --paladino (so com --classe PALADIN): cenario do paladino 1.3 (ARQUITETURA.md 12.2 a 12.4). Imprime uma linha por
//   verificacao (PAL ok/FALHA a..e) e "PALADINO falhas=N". As verificacoes a, b, c e d rodam no mesmo processo,
//   trocando o simulado (nivel, livro, furia) e redisparando PLAYER_LEVEL_UP e SPELLS_CHANGED; a verificacao e
//   (o cacador sem item "lembrete:"/"marco:" e sem macro cleanse_Mouse) roda num processo filho sem --classe.
// --pular: cenario do treino pulado (a classe simulada e a escolhida).
// Saida: 0 sem erro; 1 com erro de contrato, de construtor ou de desenho; 2 se um arquivo nem carregou.
//
// Lua 5.3 nao e o 5.1 do jogo: o ambiente poe unpack, table.getn, strtrim, tinsert, wipe etc. Diferencas que o
// banco NAO esconde: numero float concatenado vira "8.0" (no 5.1 seria "8"), string.format("%d", 3.5) erra,
// string.format("%s", nil) nao erra.
import { createRequire } from "node:module";
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const require = createRequire(import.meta.url);
const aqui = dirname(fileURLToPath(import.meta.url));
const pastaAddon = join(aqui, "..", "..", "addons-proprios", "GuiaForever");
const pastaVisual = join(aqui, "visual");
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require("fengari");

// ---------- argumentos ----------
const args = process.argv.slice(2);
const ESTRITO = args.includes("--estrito");
const DESENHAR = args.includes("--desenhar");
const ABRIR = args.includes("--abrir");
let filtroAbas = null;
{
  const i = args.indexOf("--abas");
  if (i >= 0) filtroAbas = String(args[i + 1] || "").split(",").map((s) => s.trim()).filter(Boolean);
}
const valorDe = (nome) => { const i = args.indexOf(nome); return i >= 0 ? args[i + 1] : undefined; };
const CLASSE = String(valorDe("--classe") || "HUNTER").toUpperCase();
if (CLASSE !== "HUNTER" && CLASSE !== "PALADIN") { console.error("--classe: HUNTER ou PALADIN"); process.exit(2); }
const PAL = CLASSE === "PALADIN";
const NIVEL_CFG = Number(valorDe("--nivel") ?? (PAL ? 27 : 16));
const LIVRES_CFG = Number(valorDe("--livres") ?? (PAL ? 1 : 0));
const COM_FURIA = args.includes("--com-furia");
const SEM = args.flatMap((a, i) => (a === "--sem" && args[i + 1] !== undefined ? [args[i + 1]] : []));
const SO_MACROS = args.includes("--macros"); // uso interno do processo filho do cacador (verificacao e)
const CASO_FILHO = args.includes("--filho-cacador");
if (args.includes("--paladino") && !PAL) { console.error("--paladino exige --classe PALADIN"); process.exit(2); }
if (![NIVEL_CFG, LIVRES_CFG].every(Number.isInteger)) { console.error("--nivel e --livres: numeros inteiros"); process.exit(2); }
const luaStr = (s) => JSON.stringify(String(s));
const CFG_LUA = `__CFG = { classe = ${luaStr(CLASSE)}, nivel = ${NIVEL_CFG}, livres = ${LIVRES_CFG}, furia = ${COM_FURIA}, novas = ${PAL || SO_MACROS}, sem = { ${SEM.map(luaStr).join(", ")} } }\n`;

// ---------- o ambiente Lua ----------
const PRELUDIO = String.raw`
local G = _G
local rawget, rawset, setmetatable, type, pairs, ipairs, tostring, tonumber, select, pcall, xpcall, next =
  rawget, rawset, setmetatable, type, pairs, ipairs, tostring, tonumber, select, pcall, xpcall, next
local string, table, math, os, debug = string, table, math, os, debug

__ns = {}
__acessados = {}
__erros = {}
__chat = {}

local function traco(e) return debug.traceback(tostring(e), 2) end
local function manipulador(e)
  __erros[#__erros + 1] = traco(e)
  return e
end
function geterrorhandler() return manipulador end

-- ---------- o que o Lua 5.1 tem e o 5.3 nao ----------
unpack = table.unpack
table.getn = function(t) return #t end
table.setn = function() end
table.maxn = function(t) local m = 0 for k in pairs(t) do if type(k) == "number" and k > m then m = k end end return m end
math.mod = math.fmod
string.gfind = string.gmatch
loadstring = load
tinsert, tremove, sort = table.insert, table.remove, table.sort
format, gsub, strfind, strmatch, gmatch = string.format, string.gsub, string.find, string.match, string.gmatch
strlower, strupper, strsub, strlen, strrep, strbyte, strchar, strrev = string.lower, string.upper, string.sub, string.len, string.rep, string.byte, string.char, string.reverse
floor, ceil, abs, max, min, sqrt, random = math.floor, math.ceil, math.abs, math.max, math.min, math.sqrt, math.random
function strtrim(s, chars)
  chars = chars or " \t\r\n"
  local c = "[" .. chars:gsub("[%^%]%-%%]", "%%%0") .. "]"
  return (tostring(s):gsub("^" .. c .. "+", ""):gsub(c .. "+$", ""))
end
function strsplit(delim, s, n)
  if s == nil then return end
  local set = "[" .. delim:gsub("[%^%]%-%%]", "%%%0") .. "]"
  local out, pos = {}, 1
  while true do
    if n and #out >= n - 1 then break end
    local a = s:find(set, pos)
    if not a then break end
    out[#out + 1] = s:sub(pos, a - 1)
    pos = a + 1
  end
  out[#out + 1] = s:sub(pos)
  return table.unpack(out)
end
function strjoin(delim, ...) return table.concat({ ... }, delim) end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function tContains(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end
function CopyTable(t)
  if type(t) ~= "table" then return t end
  local c = {}
  for k, v in pairs(t) do c[k] = CopyTable(v) end
  return c
end
function Mixin(o, ...)
  for i = 1, select("#", ...) do for k, v in pairs((select(i, ...))) do o[k] = v end end
  return o
end
bit = {
  band = function(a, b) return a & b end, bor = function(a, b) return a | b end,
  bxor = function(a, b) return a ~ b end, lshift = function(a, n) return a << n end,
  rshift = function(a, n) return a >> n end, bnot = function(a) return ~a end,
}
function print(...)
  local t = {}
  for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end
  __chat[#__chat + 1] = table.concat(t, " ")
end
function date(f, t)
  local ok, r = pcall(os.date, f, t)
  if ok and r then return r end
  return "2026-11-08 12:00:00"
end
function time(t)
  if t then local ok, r = pcall(os.time, t) if ok and r then return r end end
  return 1793000000
end

-- ---------- tempo e timers ----------
local relogio, seq, fila = 1000.0, 0, {}
function GetTime() return relogio end
local function enfileirar(s, fn, obj)
  seq = seq + 1
  fila[#fila + 1] = { t = relogio + (tonumber(s) or 0), seq = seq, fn = fn, obj = obj }
end
local function objetoTimer()
  local o = { cancelado = false }
  o.Cancel = function(self) self.cancelado = true end
  o.IsCancelled = function(self) return self.cancelado end
  return o
end
C_Timer = {
  After = function(s, fn) enfileirar(s, fn) end,
  NewTimer = function(s, fn) local o = objetoTimer() enfileirar(s, fn, o) return o end,
  NewTicker = function(s, fn) local o = objetoTimer() enfileirar(s, fn, o) return o end, -- roda uma vez so
}
function __esvaziar()
  local guarda = 0
  while #fila > 0 and guarda < 5000 do
    guarda = guarda + 1
    table.sort(fila, function(a, b) if a.t ~= b.t then return a.t < b.t end return a.seq < b.seq end)
    local it = table.remove(fila, 1)
    if it.t > relogio then relogio = it.t end
    if not (it.obj and it.obj.cancelado) then xpcall(it.fn, manipulador, it.obj) end
  end
end

-- ---------- quadros falsos ----------
local metodos = {}
local nulo = function() end
local MT = {}
MT.__index = function(t, k)
  local m = metodos[k]
  if m ~= nil then return m end
  if type(k) == "string" and k:find("^[A-Z]") then return nulo end -- metodo desconhecido: nao faz nada
  return nil
end
local registros = {} -- evento -> lista de quadros, na ordem de registro

local function novoQuadro(tipo, nome, pai)
  local f = setmetatable({}, MT)
  rawset(f, "__d", { tipo = tipo or "Frame", nome = nome, pai = pai, eventos = {}, scripts = {}, ganchos = {}, txt = "", mostrado = true })
  return f
end
local function D(f) return rawget(f, "__d") end

function metodos.GetName(f) return D(f).nome end
function metodos.GetObjectType(f) return D(f).tipo end
function metodos.GetParent(f) return D(f).pai end
function metodos.SetParent(f, p) D(f).pai = p end
function metodos.RegisterEvent(f, ev)
  local d = D(f)
  if d.eventos[ev] then return end
  d.eventos[ev] = true
  registros[ev] = registros[ev] or {}
  table.insert(registros[ev], f)
end
metodos.RegisterUnitEvent = metodos.RegisterEvent
function metodos.UnregisterEvent(f, ev)
  D(f).eventos[ev] = nil
  local l = registros[ev]
  if l then for i = #l, 1, -1 do if l[i] == f then table.remove(l, i) end end end
end
function metodos.UnregisterAllEvents(f) for ev in pairs(D(f).eventos) do metodos.UnregisterEvent(f, ev) end end
function metodos.IsEventRegistered(f, ev) return D(f).eventos[ev] == true end
function metodos.SetScript(f, nome, fn) D(f).scripts[nome] = fn end
function metodos.GetScript(f, nome) return D(f).scripts[nome] end
function metodos.HasScript() return true end
function metodos.HookScript(f, nome, fn)
  local g = D(f).ganchos
  g[nome] = g[nome] or {}
  table.insert(g[nome], fn)
end
function metodos.SetText(f, t) if t == nil then D(f).txt = "" else D(f).txt = t end end
function metodos.GetText(f) return D(f).txt end
function metodos.SetFormattedText(f, fmt, ...) D(f).txt = string.format(fmt, ...) end
function metodos.SetSize(f, w, h) local d = D(f) d.w, d.h = w, h end
function metodos.SetWidth(f, w) D(f).w = w end
function metodos.SetHeight(f, h) D(f).h = h end
function metodos.GetWidth(f) return D(f).w or 100 end
function metodos.GetHeight(f) return D(f).h or 100 end
function metodos.GetSize(f) return D(f).w or 100, D(f).h or 100 end
function metodos.GetStringHeight() return 14 end
function metodos.GetStringWidth(f) return 7 * #(tostring(D(f).txt or "")) end
metodos.GetTextWidth = metodos.GetStringWidth
metodos.GetUnboundedStringWidth = metodos.GetStringWidth
function metodos.CreateTexture(f, nome) return novoQuadro("Texture", nome, f) end
function metodos.CreateFontString(f, nome) return novoQuadro("FontString", nome, f) end
function metodos.CreateAnimationGroup(f) return novoQuadro("AnimationGroup", nil, f) end
function metodos.CreateAnimation(f) return novoQuadro("Animation", nil, f) end
function metodos.Show(f)
  local d = D(f)
  local antes = d.mostrado
  d.mostrado = true
  if not antes and d.scripts.OnShow then xpcall(d.scripts.OnShow, manipulador, f) end
end
function metodos.Hide(f)
  local d = D(f)
  local antes = d.mostrado
  d.mostrado = false
  if antes and d.scripts.OnHide then xpcall(d.scripts.OnHide, manipulador, f) end
end
function metodos.SetShown(f, v) if v then metodos.Show(f) else metodos.Hide(f) end end
function metodos.IsShown(f) return D(f).mostrado end
function metodos.IsVisible(f) return D(f).mostrado end
function metodos.GetFrameLevel() return 1 end
function metodos.GetAlpha() return 1 end
function metodos.GetScale() return 1 end
function metodos.GetEffectiveScale() return 1 end

function CreateFrame(tipo, nome, pai, modelo)
  if type(nome) == "string" and nome:find("$parent", 1, true) and type(pai) == "table" and D(pai) and D(pai).nome then
    nome = nome:gsub("%$parent", D(pai).nome)
  end
  local f = novoQuadro(tipo, nome, pai)
  if type(nome) == "string" then rawset(G, nome, f) end
  return f
end
function CreateFont(nome)
  local f = novoQuadro("Font", nome)
  if type(nome) == "string" then rawset(G, nome, f) end
  return f
end

-- barramento de eventos: chama o OnEvent e os ganchos de cada quadro registrado
function __disparar(ev, ...)
  local l = registros[ev]
  if not l then return end
  local copia = {}
  for i = 1, #l do copia[i] = l[i] end
  for _, f in ipairs(copia) do
    local d = D(f)
    local fn = d.scripts.OnEvent
    if fn then xpcall(fn, manipulador, f, ev, ...) end
    if d.ganchos.OnEvent then
      for _, g in ipairs(d.ganchos.OnEvent) do xpcall(g, manipulador, f, ev, ...) end
    end
  end
end

function hooksecurefunc(a, b, c)
  local alvo, nome, fn
  if type(a) == "table" then alvo, nome, fn = a, b, c else alvo, nome, fn = G, a, b end
  local orig = rawget(alvo, nome)
  if type(orig) ~= "function" or type(fn) ~= "function" then return end
  rawset(alvo, nome, function(...)
    local r = { orig(...) }
    xpcall(fn, manipulador, ...)
    return table.unpack(r)
  end)
end
function InCombatLockdown() return false end

UIParent = novoQuadro("Frame", "UIParent"); D(UIParent).w, D(UIParent).h = 1920, 1080
Minimap = novoQuadro("Frame", "Minimap")
GameTooltip = novoQuadro("GameTooltip", "GameTooltip")
DEFAULT_CHAT_FRAME = novoQuadro("Frame", "DEFAULT_CHAT_FRAME")
function DEFAULT_CHAT_FRAME.AddMessage(_, t) __chat[#__chat + 1] = tostring(t) end
UISpecialFrames = {}
SlashCmdList = {}
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
function GetScreenWidth() return 1920 end
function GetScreenHeight() return 1080 end
function GetLocale() return "enUS" end
function GetBuildInfo() return "1.60.1", "70790", "Nov  3 2026", 160001 end
function IsLoggedIn() return true end
function IsShiftKeyDown() return false end
function IsControlKeyDown() return false end
function IsAltKeyDown() return false end

-- ---------- enums ----------
Enum = {
  SpellBookSpellBank = { Player = 0, Pet = 1 },
  SpellBookItemType = { None = 0, Spell = 1, FutureSpell = 2, PetAction = 3, Flyout = 4 },
  TrainerType = { Class = 0, Tradeskill = 1, Pet = 2 },
  UIMapType = { Cosmic = 0, World = 1, Continent = 2, Zone = 3, Dungeon = 4, Micro = 5, Orphan = 6 },
  MinimapTrackingFilter = { Unfiltered = 0, Auctioneer = 1, Banker = 2, FlightMaster = 4, Innkeeper = 8, Mailbox = 16, Repair = 32, TrivialQuests = 64, Stable = 128, Trainer = 256, Vendor = 512 },
  TooltipDataType = { Item = 0, Spell = 1, Unit = 2 },
  BindingSet = { Default = 0, Account = 1, Character = 2 },
}

-- ---------- o personagem ----------
local PALADINO = __CFG.classe == "PALADIN"
local PERSONAGEM, PET = "Hexumlite Bull", "Boar"
if PALADINO then PERSONAGEM, PET = "Ignatius Stonejaw", nil end
local NIVEL = __CFG.nivel
function UnitClass(u)
  if u == "player" then
    if PALADINO then return "Paladin", "PALADIN", 2 end
    return "Hunter", "HUNTER", 3
  end
end
function UnitRace(u)
  if u == "player" then
    if PALADINO then return "Human", "Human", 1 end
    return "Night Elf", "NightElf", 4
  end
end
function UnitFactionGroup(u) if u == "player" then return "Alliance", "Alliance" end end
function UnitName(u) if u == "player" then return PERSONAGEM end if u == "pet" then return PET end end
function UnitFullName(u) if u == "player" then return PERSONAGEM, "Forever" end if u == "pet" then return PET end end
function UnitLevel(u) if u == "player" or u == "pet" then return NIVEL end return 0 end
function UnitExists(u) return u == "player" or (u == "pet" and not PALADINO) end
function UnitIsDead() return false end
function UnitIsPlayer(u) return u == "player" end
function UnitGUID(u) if u == "player" then return "Player-1-00000001" end if u == "pet" then return "Pet-0-0-0-0-1-0000000001" end end
function UnitCreatureFamily(u) if u == "pet" then return PET end end
function UnitCreatureType(u) if u == "pet" then return "Beast" end end
function UnitSex() return 2 end
function UnitXP() return 0 end
function UnitXPMax() return 1000 end
function IsInGroup() return false end
function IsMounted() return false end
function UnitOnTaxi() return false end
function UnitIsDeadOrGhost() return false end
function IsInRaid() return false end
function GetNumGroupMembers() return 0 end
function GetRealmName() return "Forever" end
function GetNormalizedRealmName() return "Forever" end
function GetRealZoneText() return PALADINO and "Elwynn Forest" or "Darkshore" end
function GetZoneText() return PALADINO and "Elwynn Forest" or "Darkshore" end

C_ClassColor = {
  GetClassColor = function(token)
    local r, g, b = 0.67, 0.83, 0.45
    local hex = "ffaad372"
    if PALADINO then r, g, b, hex = 0.96, 0.55, 0.73, "fff48cba" end
    local o = { r = r, g = g, b = b }
    function o.GetRGB() return r, g, b end
    function o.GenerateHexColor() return hex end
    return o
  end,
}

-- ---------- livros de magia ----------
local magiasJogador, magiasPet
-- Cleanse chega no nivel 42 (Naowh, TrainingData.lua) e nao esta em Dicas.magias nem nas teclas: entra aqui.
local EXTRAS_PALADINO = { { 42, "Cleanse" } }
local function montarJogador()
  if magiasJogador then return magiasJogador end
  local lista, vistos = {}, {}
  local function add(nome)
    for _, x in ipairs(__CFG.sem) do if string.lower(x) == string.lower(tostring(nome)) then return end end
    if type(nome) == "string" and nome ~= "" and not vistos[nome] then
      vistos[nome] = true
      lista[#lista + 1] = { id = 100000 + #lista + 1, name = nome }
    end
  end
  local dicas = rawget(G, "GuiaForeverDicas")
  local h = dicas and dicas[__CFG.classe]
  if h and h.magias then for _, e in ipairs(h.magias) do if e.magia and (e.nivel or 0) <= NIVEL then add(e.magia) end end end
  local teclas = rawget(G, "GuiaForeverTeclas")
  local t = teclas and teclas[__CFG.classe]
  if t then
    for _, e in ipairs(t) do
      if (e.n or 99) <= NIVEL and type(e.s) == "string" then
        local resto = e.s:match("^[%w]+_[%w]+:%s*(.*)$") or e.s
        for seg in (resto .. ";"):gmatch("([^;,=()]+)[;,=()]") do
          seg = strtrim(seg)
          local ok = seg ~= "" and #seg <= 32 and not seg:find("%d")
          if ok then
            for palavra in seg:gmatch("%S+") do
              if not (palavra:find("^%u") or palavra == "of" or palavra == "the") then ok = false break end
            end
          end
          if ok then add(seg) end
        end
      end
    end
  end
  if PALADINO then for _, x in ipairs(EXTRAS_PALADINO) do if x[1] <= NIVEL then add(x[2]) end end end
  magiasJogador = lista
  return lista
end
local function montarPet()
  if magiasPet then return magiasPet end
  if PALADINO then magiasPet = {} return magiasPet end
  local g = rawget(G, "GuiaForeverPetGuia")
  local lista = {}
  for i, nome in ipairs({ "Bite", "Charge", "Growl", "Great Stamina" }) do
    local id = 200000 + i
    local h = g and g.habilidades and g.habilidades[nome]
    if h and h.ranks and h.ranks[1] and type(h.ranks[1].id) == "number" then id = h.ranks[1].id end
    lista[#lista + 1] = { id = id, name = nome }
  end
  magiasPet = lista
  return lista
end
local function nomeDe(id)
  for _, l in ipairs({ montarJogador(), montarPet() }) do
    for _, m in ipairs(l) do if m.id == id then return m.name end end
  end
end
local function banco(b) if b == Enum.SpellBookSpellBank.Pet then return montarPet() end return montarJogador() end

local function mkapi(nome, t)
  setmetatable(t, { __index = function(_, k)
    if type(k) == "string" then __acessados[nome .. "." .. k] = true end
    return nil
  end })
  rawset(G, nome, t)
end
local V2 = function(x, y) local o = { x = x, y = y } function o.GetXY() return x, y end return o end
CreateVector2D = V2
UiMapPoint = { CreateFromCoordinates = function(m, x, y) return { uiMapID = m, position = V2(x, y) } end }

mkapi("C_SpellBook", {
  GetNumSpellBookSkillLines = function() return 1 end,
  GetSpellBookSkillLineInfo = function(i) if i == 1 then return { name = "General", itemIndexOffset = 0, numSpellBookItems = #montarJogador() } end end,
  GetSpellBookItemInfo = function(slot, b)
    local m = banco(b)[slot]
    if m then return { spellID = m.id, name = m.name, itemType = Enum.SpellBookItemType.Spell } end
  end,
  HasPetSpells = function() return #montarPet(), "PET" end,
  IsSpellKnown = function(id, b)
    for _, m in ipairs(banco(b)) do if m.id == id then return true end end
    return false
  end,
})
mkapi("C_Spell", {
  GetSpellName = function(id) return nomeDe(id) end,
  GetSpellTexture = function(id) return "Interface\\Icons\\INV_Misc_QuestionMark" end,
})
mkapi("C_PetInfo", {
  GetPetHappiness = function() return 3, 125, 0 end,
  GetPetFoodTypes = function() return { "Meat", "Fish", "Cheese", "Bread", "Fungus", "Fruit" } end,
  GetPetTrainingPoints = function() return 107, 95 end,
  CanPetEatItem = function() return false end,
  GetSpellForPetAction = function() return nil end,
})
mkapi("C_ClassTalents", { GetActiveConfigID = function() return 1 end })
mkapi("C_Traits", {
  GetConfigInfo = function() return { treeIDs = { 1 } } end,
  GetTreeCurrencyInfo = function() return { { quantity = __CFG.livres } } end,
})
mkapi("C_SkillInfo", {
  GetNumSkillLines = function() return 2 end,
  GetSkillLineInfo = function(i)
    if PALADINO then
      if i == 1 then return { name = "Mining", rank = 75, maxRank = 75, isHeader = false } end
      if i == 2 then return { name = "Blacksmithing", rank = 55, maxRank = 100, isHeader = false } end
      return nil
    end
    if i == 1 then return { name = "Skinning", rank = 75, maxRank = 75, isHeader = false } end
    if i == 2 then return { name = "Leatherworking", rank = 55, maxRank = 100, isHeader = false } end
  end,
})
mkapi("C_QuestLog", {
  GetLogIndexForQuestID = function() return nil end,
  IsComplete = function() return false end,
  IsQuestFlaggedCompleted = function() return false end,
  IsOnQuest = function() return false end,
})
mkapi("C_Map", {
  GetBestMapForUnit = function() return PALADINO and 1429 or 1439 end,
  GetMapInfo = function(id)
    if PALADINO then
      if id == 1429 then return { mapID = 1429, name = "Elwynn Forest", mapType = Enum.UIMapType.Zone, parentMapID = 1415 } end
      if id == 1415 then return { mapID = 1415, name = "Eastern Kingdoms", mapType = Enum.UIMapType.Continent, parentMapID = 947 } end
      if id == 947 then return { mapID = 947, name = "Azeroth", mapType = Enum.UIMapType.World, parentMapID = 0 } end
      return nil
    end
    if id == 1439 then return { mapID = 1439, name = "Darkshore", mapType = Enum.UIMapType.Zone, parentMapID = 1414 } end
    if id == 1414 then return { mapID = 1414, name = "Kalimdor", mapType = Enum.UIMapType.Continent, parentMapID = 947 } end
    if id == 947 then return { mapID = 947, name = "Azeroth", mapType = Enum.UIMapType.World, parentMapID = 0 } end
  end,
  GetPlayerMapPosition = function() return V2(0.5, 0.5) end,
  GetWorldPosFromMapPos = function(m, v) return 1, V2(0, 0) end,
  CanSetUserWaypointOnMap = function() return true end,
  SetUserWaypoint = function() end,
  ClearUserWaypoint = function() end,
})
mkapi("C_SuperTrack", { SetSuperTrackedUserWaypoint = function() end })
mkapi("C_Minimap", {
  GetNumTrackingTypes = function() return 0 end,
  GetTrackingInfo = function() return nil end,
  GetTrackingFilter = function() return nil end,
  SetTracking = function() end,
})
mkapi("C_Item", { GetItemInfo = function() return nil end })
mkapi("C_Container", {
  GetContainerNumSlots = function() return 0 end,
  GetContainerItemInfo = function() return nil end,
})
mkapi("C_CVar", { GetCVar = function() return "0" end, SetCVar = function() end })
mkapi("C_AddOns", { IsAddOnLoaded = function() return false end })
mkapi("C_Trainer", { GetTrainerType = function() return nil end })
mkapi("C_TooltipInfo", { GetItemByID = function() return nil end })

-- APIs que so o paladino 1.3 (Lembretes.lua, ns.macroGerenciada) usa; o cacador fica como antes
-- (sem elas, a macro de comida do pet nem e criada). __CFG.novas liga no paladino e no filho do cacador.
__macros = {}
if __CFG.novas then
  mkapi("C_UnitAuras", {
    GetAuraDataBySpellName = function(unidade, nome)
      if __CFG.furia and unidade == "player" and nome == "Righteous Fury" then return { name = "Righteous Fury", spellId = 25780 } end
      return nil
    end,
  })
  function issecretvalue() return false end
  function GetNumMacros() return 0, #__macros end
  function GetMacroIndexByName(nome)
    for i, m in ipairs(__macros) do if m.nome == nome then return i end end
    return 0
  end
  function GetMacroInfo(i)
    local m = __macros[i]
    if m then return m.nome, m.icone, m.corpo end
  end
  function CreateMacro(nome, icone, corpo)
    __macros[#__macros + 1] = { nome = nome, icone = icone, corpo = corpo }
    return #__macros
  end
  function EditMacro(i, nome, icone, corpo)
    local m = __macros[i]
    if not m then return nil end
    if nome then m.nome = nome end
    if icone then m.icone = icone end
    if corpo then m.corpo = corpo end
    return i
  end
end

-- cenario do paladino: trocar o simulado no meio da rodada (nivel, livro, furia)
function __redefinir(nivel, sem, furia)
  NIVEL = nivel
  __CFG.nivel = nivel
  __CFG.sem = sem or {}
  __CFG.furia = furia and true or false
  magiasJogador = nil
end
-- ---------- avisa o que o codigo le e nao existe ----------
setmetatable(G, { __index = function(_, k)
  if type(k) == "string" then __acessados[k] = true end
  return nil
end })

-- ---------- carregar arquivos e rodar ----------
-- esc/ser: serializador JSON dos blocos (funcao vira "<fn>")
local function esc(s)
  return '"' .. (s:gsub('[%c"\\]', function(c)
    local m = { ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }
    return m[c] or string.format("\\u%04x", c:byte())
  end)) .. '"'
end
local function ser(v, prof, vistos, out)
  local tv = type(v)
  if tv == "nil" then out[#out + 1] = "null"
  elseif tv == "boolean" then out[#out + 1] = tostring(v)
  elseif tv == "number" then
    if v ~= v or v == math.huge or v == -math.huge then out[#out + 1] = "null"
    elseif math.type(v) == "integer" then out[#out + 1] = tostring(v)
    else out[#out + 1] = string.format("%.14g", v) end
  elseif tv == "string" then out[#out + 1] = esc(v)
  elseif tv == "function" then out[#out + 1] = '"<fn>"'
  elseif tv == "table" then
    if rawget(v, "__d") then out[#out + 1] = '"<quadro>"' return end
    if vistos[v] or prof > 40 then out[#out + 1] = '"<ciclo>"' return end
    vistos[v] = true
    local n, total = #v, 0
    for _ in pairs(v) do total = total + 1 end
    if total == 0 then out[#out + 1] = "[]"
    elseif n == total then
      out[#out + 1] = "["
      for i = 1, n do
        if i > 1 then out[#out + 1] = "," end
        ser(v[i], prof + 1, vistos, out)
      end
      out[#out + 1] = "]"
    else
      local chaves = {}
      for k in pairs(v) do chaves[#chaves + 1] = tostring(k) end
      table.sort(chaves, function(a, b)
        if a == "t" then return b ~= "t" end
        if b == "t" then return false end
        return a < b
      end)
      out[#out + 1] = "{"
      for i, k in ipairs(chaves) do
        if i > 1 then out[#out + 1] = "," end
        out[#out + 1] = esc(k) .. ":"
        local val = v[k]
        if val == nil then val = v[tonumber(k)] end
        ser(val, prof + 1, vistos, out)
      end
      out[#out + 1] = "}"
    end
    vistos[v] = nil
  else out[#out + 1] = esc("<" .. tv .. ">") end
end
local function json(v) local out = {} ser(v, 0, {}, out) return table.concat(out) end

function __carregar(nome, fonte)
  local f, err = load(fonte, "@" .. nome, "t")
  if not f then return json({ ok = false, erro = "sintaxe: " .. tostring(err) }) end
  local ok, e = xpcall(f, traco, "GuiaForever", __ns)
  if not ok then return json({ ok = false, erro = tostring(e) }) end
  return json({ ok = true })
end

function __sequencia()
  local passos = {
    { "ADDON_LOADED", "GuiaForever" }, { "PLAYER_LOGIN" }, { "PLAYER_ENTERING_WORLD", true, false },
    { "SPELLS_CHANGED" }, { "UNIT_PET", "player" }, { "PET_BAR_UPDATE" }, { "QUEST_LOG_UPDATE" },
  }
  for _, p in ipairs(passos) do
    __disparar(table.unpack(p))
    __esvaziar()
  end
  return json({ ok = true })
end

-- plano: entradas { id, sub, modo, fn } e abas sem construtor
local COMPAT = {
  { "familias", nil, "blocosFamilias" }, { "pet", "upgrades", "blocosProximosRanks" }, { "combate", "teclas", "blocosTeclas" },
  { "profissoes", "zona", "blocosZona" }, { "profissoes", "treinos", "blocosTreinos" },
}
function __plano()
  local ns = __ns
  local cons = type(ns.abasConstrutores) == "table" and ns.abasConstrutores or {}
  local entradas, semConstrutor, temConstrutor = {}, {}, {}
  if type(ns.abas) == "table" then
    for _, a in ipairs(ns.abas) do
      if type(cons[a.id]) == "function" then
        temConstrutor[a.id] = true
        if type(a.subs) == "table" and #a.subs > 0 then
          for _, s in ipairs(a.subs) do entradas[#entradas + 1] = { id = a.id, sub = s.id, modo = "novo" } end
        else
          entradas[#entradas + 1] = { id = a.id, modo = "novo" }
        end
      else
        semConstrutor[#semConstrutor + 1] = a.id
      end
    end
  end
  for _, c in ipairs(COMPAT) do
    if not temConstrutor[c[1]] and type(ns[c[3]]) == "function" then
      entradas[#entradas + 1] = { id = c[1], sub = c[2], modo = "compat", fn = c[3] }
    end
  end
  local meta = { abas = ns.abas, semConstrutor = semConstrutor }
  if type(ns.abasEstado) == "function" then
    local ok, r = pcall(ns.abasEstado)
    if ok then meta.estado = r end
  end
  return json({ entradas = entradas, meta = meta })
end

function __construir(id, sub, modo, nomeFn, desenhar)
  local b = {}
  local ctx = { nivel = __CFG.nivel, classe = __CFG.classe, tudo = false, sub = sub, largura = 626, atualizar = function() end, abrir = function() end }
  local res = { blocos = b }
  local fn
  if modo == "novo" then fn = (__ns.abasConstrutores or {})[id] else fn = __ns[nomeFn] end
  if type(fn) ~= "function" then
    res.erro = "construtor ausente"
  else
    local ok, e = xpcall(function() fn(b, ctx) end, traco)
    if not ok then res.erro = tostring(e) end
  end
  if desenhar and not res.erro then
    local ui = __ns.ui
    if type(ui) == "table" and type(ui.desenhar) == "function" then
      local conteudo = novoQuadro("Frame", nil, UIParent)
      local ok, e = xpcall(function() return ui.desenhar(conteudo, b, 626, ctx) end, traco)
      if ok then res.desenho = { ok = true, altura = e } else res.desenho = { ok = false, erro = tostring(e) } end
    else
      res.desenho = { ausente = true }
    end
  end
  res.erros = nil
  return json(res)
end

-- --abrir: abre a janela e cada aba, sub-aba e id antigo; erro de Lua (de xpcall interno ou direto) conta
function __abrir()
  local ns = __ns
  local passos, falhas = 0, {}
  local function passo(nome, fn)
    passos = passos + 1
    local antes = #__erros
    local ok, e = xpcall(fn, traco)
    __esvaziar()
    if not ok then falhas[#falhas + 1] = { passo = nome, erro = tostring(e) } end
    for i = antes + 1, #__erros do falhas[#falhas + 1] = { passo = nome, erro = __erros[i] } end
    for i = #__erros, antes + 1, -1 do __erros[i] = nil end
  end
  if type(ns.alternarJanela) ~= "function" then return json({ passos = 0, falhas = { { passo = "alternarJanela", erro = "ausente" } } }) end
  passo("alternarJanela (abrir)", function() ns.alternarJanela() end)
  for _, a in ipairs(ns.abas or {}) do
    passo("abrirAba " .. a.id, function() ns.abrirAba(a.id) end)
    for _, s in ipairs(a.subs or {}) do
      passo("abrirAba " .. a.id .. "/" .. s.id, function() ns.abrirAba(a.id, s.id) end)
    end
  end
  local ids = {}
  for k in pairs(ns.apelidosAba or {}) do ids[#ids + 1] = k end
  table.sort(ids)
  for _, k in ipairs(ids) do passo("abrirAba (antigo) " .. k, function() ns.abrirAba(k) end) end
  local achados = 0
  passo("buscarJanela boar", function()
    local r = ns.buscarJanela("boar")
    if type(r) ~= "table" then error("buscarJanela nao devolveu tabela") end
    achados = #r
  end)
  passo("alternarJanela (fechar)", function() ns.alternarJanela() end)
  return json({ passos = passos, falhas = falhas, achados = achados })
end

-- Cenario do treino pulado (dono, 2026-11-08): o aviso "Train 2 spells: <treinador>" pulado pelo
-- botao direito nao volta quando o treinador mais perto muda, so com magia nova.
function __pular()
  local ns = __ns
  local A = ns.agora
  local falhas = {}
  local function falha(s) falhas[#falhas + 1] = s end
  if not (A and A.itens and A.atualizar and A.pulados and A.desfazerPulo) then
    return json({ falhas = { "ns.agora sem itens/atualizar/pulados/desfazerPulo" } })
  end
  local treinador, agora = "Dorion", { { 16, 1495, 1500 }, { 16, 13795, 1500 } }
  local antigo = rawget(_G, "NaowhForever")
  rawset(_G, "NaowhForever", { Training = {
    Plan = function() return { now = agora } end,
    NearestTrainer = function() return { 0, 0, "trainer", treinador } end,
  } })
  local function treino()
    A.atualizar(); __esvaziar()
    for _, it in ipairs(A.itens() or {}) do if it.chave == "classe:treino" then return it end end
  end
  local it = treino()
  if not it then falha("sem aviso de treino com 2 magias") elseif tostring(it.texto) ~= "Train 2 spells: Dorion" then falha("texto: " .. tostring(it.texto)) end
  if it and type(it.aoOcultar) ~= "function" then falha("aviso sem aoOcultar") end
  if it and it.aoOcultar then it.aoOcultar() end
  if treino() then falha("o aviso continua depois do pulo") end
  treinador = "Kaerbrus"
  if treino() then falha("o aviso voltou com outro treinador") end
  agora[#agora + 1] = { 16, 1513, 1100 }
  local novo = treino()
  if not novo then falha("magia nova nao trouxe o aviso") elseif not tostring(novo.texto):find("^Train 1 spell") then falha("com magia nova: " .. tostring(novo.texto)) end
  local p = A.pulados()
  if #p ~= 2 then falha("pulados = " .. #p .. " (esperado 2)") end
  local b = {}
  local okH = pcall(ns.abasConstrutores.agora, b, { nivel = __CFG.nivel, classe = __CFG.classe, tudo = false, atualizar = function() end, abrir = function() end })
  local achou = false
  for _, x in ipairs(b) do if x.t == "item" and tostring(x.s):find("^Skipped training: 2 spells") then achou = true end end
  if not okH or not achou then falha("J > Now > Hidden sem 'Skipped training: 2 spells'") end
  A.desfazerPulo(); __esvaziar()
  local volta = treino()
  if not volta or not tostring(volta.texto):find("^Train 3 spells") then falha("desfazer: " .. tostring(volta and volta.texto)) end
  rawset(_G, "NaowhForever", antigo)
  A.desfazerPulo(); __esvaziar()
  return json({ falhas = falhas })
end

-- Cenario do paladino 1.3 (ARQUITETURA.md 12.2 a 12.4). Devolve { linhas = { { id, ok, msg } } }.
function __paladino()
  local ns = __ns
  local A = ns.agora
  local linhas = {}
  local function v(id, ok, msg) linhas[#linhas + 1] = { id = id, ok = ok and true or false, msg = msg } end
  local function chaves(prefixo)
    local r = {}
    for _, it in ipairs(A.itens() or {}) do
      if string.sub(tostring(it.chave), 1, #prefixo) == prefixo then r[#r + 1] = it end
    end
    return r
  end
  local function macro(nome)
    for _, m in ipairs(__macros) do if m.nome == nome then return m end end
  end
  local function plano1(txt) return (string.gsub(txt, "\n", " | ")) end
  -- troca o simulado e redispara o que o addon escuta (nivel, livro de magias, timers)
  local function mudar(nivel, sem, furia)
    __redefinir(nivel, sem, furia)
    __disparar("PLAYER_LEVEL_UP", nivel); __esvaziar()
    __disparar("SPELLS_CHANGED"); __esvaziar()
    A.atualizar(); __esvaziar()
  end
  local cfg0 = { nivel = __CFG.nivel, sem = __CFG.sem, furia = __CFG.furia }

  -- a. talentos com opcoes lado a lado (nivel 27, 1 ponto livre)
  mudar(27, {}, false)
  local plano = ns.arvore.plano()
  local e27 = plano[27]
  v("a1", e27 and e27.opcoes and #e27.opcoes == 3 and e27.opcoes[1].id == "A" and e27.opcoes[2].id == "B" and e27.opcoes[3].id == "C",
    "plano()[27].opcoes tem 3 colunas A, B, C")
  local prox = ns.arvore.proximo()
  v("a2", prox and prox.nivel == 27 and type(prox.opcoes) == "table" and #prox.opcoes > 0,
    "proximo().nivel == 27 com opcoes (nivel " .. tostring(prox and prox.nivel) .. ")")
  local rs = e27 and ns.arvore.resumoOpcoes(e27)
  v("a3", type(rs) == "string" and string.find(rs, " or ", 1, true) ~= nil, "resumoOpcoes(plano()[27]).s tem ' or ': " .. tostring(rs))
  local b = {}
  local ok, err = xpcall(function() ns.abasConstrutores.talentos(b, { nivel = 27, classe = "PALADIN", tudo = false, atualizar = function() end, abrir = function() end }) end, traco)
  local achou = false
  for _, x in ipairs(b) do if x.t == "tabela" and x.id == "talentos:op:prot:tab" then achou = true end end
  v("a4", ok and achou, "aba Talents com a tabela talentos:op:prot:tab" .. (ok and "" or (": " .. tostring(err))))
  local e53 = plano[53]
  v("a5", e53 and e53.tbd and e53.opcoes == nil, "plano()[53] e tbd sem opcoes")

  -- b. lembrete de Righteous Fury (fora de combate)
  A.atualizar(); __esvaziar()
  local l = chaves("lembrete:Righteous Fury")
  v("b1", #l == 1 and l[1].prio == 15 and l[1].cor == "vermelho",
    "sem furia: item lembrete:Righteous Fury (prio 15, vermelho); itens = " .. #l)
  -- d. (nivel 27) macro com Purify, depois dos timers do login
  local m27 = macro("cleanse_Mouse")
  v("d1", m27 and string.find(m27.corpo, "Purify", 1, true) ~= nil and string.find(m27.corpo, "Cleanse", 1, true) == nil,
    "nivel 27: macro cleanse_Mouse com Purify: " .. tostring(m27 and plano1(m27.corpo)))
  mudar(27, {}, true)
  __disparar("PLAYER_REGEN_ENABLED"); __esvaziar() -- o caminho real de reavaliar (verificar -> agora.atualizar)
  v("b2", #chaves("lembrete:") == 0, "com furia: nenhum item lembrete: (" .. #chaves("lembrete:") .. ")")
  mudar(27, {}, false)
  __disparar("PLAYER_REGEN_ENABLED"); __esvaziar()
  v("b3", #chaves("lembrete:Righteous Fury") == 1, "furia caiu: o item volta")

  -- c. marcos
  mudar(12, { "Redemption" }, false)
  v("c1", #chaves("marco:12:") >= 1, "nivel 12 sem Redemption: item marco:12: (" .. #chaves("marco:12:") .. ")")
  mudar(12, {}, false)
  v("c2", #chaves("marco:12:") == 0, "nivel 12 com Redemption: sem marco:12: (" .. #chaves("marco:12:") .. ")")
  mudar(22, {}, false)
  v("c3", #chaves("marco:22:") >= 1, "nivel 22: marco:22: (" .. #chaves("marco:22:") .. ")")
  mudar(23, {}, false)
  v("c4", #chaves("marco:22:") == 0, "nivel 23: sem marco:22: (" .. #chaves("marco:22:") .. ")")

  -- d. com Cleanse no livro (nivel 42), a macro e editada
  mudar(42, {}, false)
  local m42 = macro("cleanse_Mouse")
  v("d2", m42 and string.find(m42.corpo, "Cleanse", 1, true) ~= nil, "nivel 42: macro cleanse_Mouse com Cleanse: " .. tostring(m42 and plano1(m42.corpo)))
  local nCl = 0
  for _, m in ipairs(__macros) do if m.nome == "cleanse_Mouse" then nCl = nCl + 1 end end
  v("d3", nCl == 1, "editada no lugar: uma so cleanse_Mouse no registro (" .. nCl .. " de " .. #__macros .. " macros)")

  mudar(cfg0.nivel, cfg0.sem, cfg0.furia)
  return json({ linhas = linhas })
end

-- Verificacao e: o cacador (rodado sem --classe) nao tem lembrete, marco nem a macro cleanse_Mouse.
function __cacador()
  local A = __ns.agora
  local linhas = {}
  A.atualizar(); __esvaziar()
  local n = 0
  for _, it in ipairs(A.itens() or {}) do
    local c = tostring(it.chave)
    if string.sub(c, 1, 9) == "lembrete:" or string.sub(c, 1, 6) == "marco:" then n = n + 1 end
  end
  linhas[#linhas + 1] = { id = "e1", ok = n == 0, msg = "cacador: itens lembrete:/marco: = " .. n }
  local tem = false
  for _, m in ipairs(__macros) do if m.nome == "cleanse_Mouse" then tem = true end end
  linhas[#linhas + 1] = { id = "e2", ok = not tem, msg = "cacador: sem macro cleanse_Mouse (macros no registro: " .. #__macros .. ")" }
  return json({ linhas = linhas })
end

function __final()
  local nomes = {}
  for k in pairs(__acessados) do nomes[#nomes + 1] = k end
  table.sort(nomes)
  return json({ naoSimuladas = nomes, erros = __erros, chat = __chat })
end
`;

// ---------- ponte JS <-> fengari ----------
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);

function pcallLua(nomeFn, ...argv) {
  lua.lua_getglobal(L, to_luastring(nomeFn));
  for (const a of argv) {
    if (a === undefined || a === null) lua.lua_pushnil(L);
    else if (typeof a === "boolean") lua.lua_pushboolean(L, a);
    else if (a instanceof Uint8Array) lua.lua_pushstring(L, a);
    else lua.lua_pushstring(L, to_luastring(String(a)));
  }
  const st = lua.lua_pcall(L, argv.length, 1, 0);
  const r = lua.lua_tostring(L, -1);
  const txt = r ? to_jsstring(r) : "";
  lua.lua_pop(L, 1);
  if (st !== 0) throw new Error("Lua (" + nomeFn + "): " + txt);
  return JSON.parse(txt);
}

{
  const pre = to_luastring(CFG_LUA + PRELUDIO);
  let st = lauxlib.luaL_loadbuffer(L, pre, pre.length, to_luastring("=prelude"));
  if (st === 0) st = lua.lua_pcall(L, 0, 0, 0);
  if (st !== 0) {
    console.error("ERRO no ambiente simulado (prelude): " + to_jsstring(lua.lua_tostring(L, -1)));
    process.exit(2);
  }
}

// ---------- carregar o .toc ----------
const toc = readFileSync(join(pastaAddon, "GuiaForever.toc"), "utf8").split(/\r?\n/).map((l) => l.trim()).filter((l) => l && !l.startsWith("#"));
const arquivos = toc.filter((l) => /\.lua$/i.test(l));
let falhouCarga = false;
const fontes = {};
for (const nome of arquivos) {
  const caminho = join(pastaAddon, nome);
  if (!existsSync(caminho)) { console.log(`CARGA ${nome}: arquivo nao existe`); falhouCarga = true; continue; }
  const bytes = readFileSync(caminho);
  fontes[nome] = bytes.toString("utf8");
  const r = pcallLua("__carregar", nome, Uint8Array.from(bytes));
  if (!r.ok) { falhouCarga = true; console.log(`CARGA ${nome}: FALHOU\n  ${String(r.erro).split("\n").join("\n  ")}`); }
}
console.log(`CARGA ${arquivos.length - (falhouCarga ? 1 : 0)} de ${arquivos.length} arquivos do .toc (ver acima se houver falha)`);
pcallLua("__sequencia");
if (CASO_FILHO) { // processo filho da verificacao e do --paladino: so confere o cacador e sai
  const r = pcallLua("__cacador");
  for (const x of r.linhas) console.log("PAL " + x.id + " " + (x.ok ? "ok   " : "FALHA") + " " + x.msg);
  process.exit(0);
}

// ---------- conferencia ----------
const TIPOS = new Set(["sec", "card", "item", "nota", "vazio", "tabela", "passos", "checklist", "grade", "regua", "perfil", "titulo", "etiquetas", "segs", "duas", "botao"]);
const COMPAT_TIPOS = new Set(["texto", "cab", "linha", "espaco"]);
const OBRIGATORIOS = {
  sec: ["s"], card: ["s"], item: ["s"], nota: ["s"], vazio: ["s"], titulo: ["s"], tabela: ["colunas", "linhas"], passos: ["lista"],
  checklist: ["itens"], grade: ["teclas"], regua: ["linhas"], perfil: ["titulo"], etiquetas: ["lista"], segs: ["aba", "opcoes", "atual"],
  duas: ["id", "lista", "detalhe"], botao: ["s"], texto: ["s"], cab: ["s"], linha: ["s"], espaco: [],
};
const NAO_TEXTO = new Set(["t", "id", "estado", "cor", "icone", "aba", "atual", "alinha", "retrato", "tecla_id"]);
const semCodigos = (s) => String(s).replace(/\|c[0-9a-fA-F]{8}/g, "").replace(/\|r/g, "");
const trecho = (s, n = 70) => { const x = semCodigos(s).replace(/\s+/g, " "); return x.length > n ? x.slice(0, n) + "..." : x; };

// textos de um bloco (sem descer em "detalhe", que e conferido como lista de blocos)
function textosDe(v, chave, saida) {
  if (typeof v === "string") { if (!NAO_TEXTO.has(chave)) saida.push(v); return; }
  if (Array.isArray(v)) { for (const x of v) textosDe(x, chave, saida); return; }
  if (v && typeof v === "object") {
    for (const [k, x] of Object.entries(v)) { if (k === "detalhe") continue; textosDe(x, k, saida); }
  }
}
function temFonte(v) {
  if (Array.isArray(v)) return v.some(temFonte);
  if (v && typeof v === "object") return Object.entries(v).some(([k, x]) => k !== "detalhe" && (k === "fonte" || temFonte(x)));
  return false;
}
function valorFonte(v) {
  if (Array.isArray(v)) { for (const x of v) { const r = valorFonte(x); if (r !== undefined) return r; } return undefined; }
  if (v && typeof v === "object") {
    for (const [k, x] of Object.entries(v)) {
      if (k === "detalhe") continue;
      if (k === "fonte") return x;
      const r = valorFonte(x); if (r !== undefined) return r;
    }
  }
  return undefined;
}
function limitesDe(v, saida) {
  if (Array.isArray(v)) { v.forEach((x) => limitesDe(x, saida)); return; }
  if (v && typeof v === "object") for (const [k, x] of Object.entries(v)) { if (k === "detalhe") continue; if (k === "limite" && typeof x === "number") saida.push(x); else limitesDe(x, saida); }
}

// problemas: { sev: "erro"|"aviso", aba, idx, regra, texto }
function conferirBlocos(rotulo, blocos, prefixoIdx, problemas) {
  blocos.forEach((b, i) => {
    const idx = prefixoIdx + i;
    if (!b || typeof b !== "object" || Array.isArray(b)) { problemas.push({ sev: "erro", aba: rotulo, idx, regra: "TIPO", texto: "bloco nao e tabela" }); return; }
    const t = b.t;
    const compat = COMPAT_TIPOS.has(t);
    if (!TIPOS.has(t) && !compat) { problemas.push({ sev: "erro", aba: rotulo, idx, regra: "TIPO", texto: `tipo desconhecido "${t}"` }); return; }
    const sevCompat = ESTRITO ? "erro" : "aviso";
    const sev = compat ? sevCompat : "erro";
    if (compat) problemas.push({ sev: sevCompat, aba: rotulo, idx, regra: "TIPO-COMPAT", texto: `tipo compativel "${t}"` });
    for (const campo of OBRIGATORIOS[t]) {
      if (b[campo] === undefined || b[campo] === null) problemas.push({ sev, aba: rotulo, idx, regra: "CAMPO", texto: `${t} sem "${campo}"` });
      else if (campo === "s" && typeof b[campo] !== "string") problemas.push({ sev, aba: rotulo, idx, regra: "CAMPO", texto: `${t}.s nao e texto` });
    }
    if (t === "duas" && !Array.isArray(b.detalhe) && b.detalhe !== undefined) problemas.push({ sev, aba: rotulo, idx, regra: "CAMPO", texto: "duas.detalhe nao e lista" });
    // C1
    if (temFonte(b)) problemas.push({ sev, aba: rotulo, idx, regra: "C1", texto: `campo fonte="${valorFonte(b)}"` });
    const textos = [];
    textosDe(b, "", textos);
    const src = textos.find((x) => semCodigos(x).includes("Source"));
    if (src !== undefined) problemas.push({ sev, aba: rotulo, idx, regra: "C1", texto: `"Source" em: ${trecho(src)}` });
    // C2
    const lims = [];
    limitesDe(b, lims);
    for (const l of lims) if (l > 6) problemas.push({ sev, aba: rotulo, idx, regra: "C2", texto: `limite=${l}` });
    // C5
    for (const x of textos) {
      const s = semCodigos(x);
      const motivo = /^\[v\]/.test(s) ? "comeca com [v]" : /^\[x\]/.test(s) ? "comeca com [x]" : s.startsWith("> ") ? 'comeca com "> "'
        : s.startsWith("+ ") ? 'comeca com "+ "' : s.includes("* =") ? 'contem "* ="' : /\*\s*$/.test(s) ? 'termina em "*"' : null;
      if (motivo) problemas.push({ sev, aba: rotulo, idx, regra: "C5", texto: `${motivo}: ${trecho(x)}` });
    }
    // C6 (sempre aviso; nota e texto sao paragrafos)
    if (!["nota", "texto", "passos"].includes(t)) {
      if (typeof b.s === "string" && semCodigos(b.s).length > 60) problemas.push({ sev: "aviso", aba: rotulo, idx, regra: "C6", texto: `s com ${semCodigos(b.s).length}: ${trecho(b.s, 50)}` });
      if (typeof b.sub === "string" && semCodigos(b.sub).length > 80) problemas.push({ sev: "aviso", aba: rotulo, idx, regra: "C6", texto: `sub com ${semCodigos(b.sub).length}: ${trecho(b.sub, 50)}` });
    }
    if (t === "duas" && Array.isArray(b.lista)) {
      b.lista.forEach((e) => {
        if (e && typeof e.s === "string" && semCodigos(e.s).length > 60) problemas.push({ sev: "aviso", aba: rotulo, idx, regra: "C6", texto: `duas.lista s com ${semCodigos(e.s).length}: ${trecho(e.s, 50)}` });
      });
    }
    if (t === "duas" && Array.isArray(b.detalhe)) conferirBlocos(rotulo + " (detalhe)", b.detalhe, 0, problemas);
  });
}

// ---------- rodar as abas ----------
const plano = pcallLua("__plano");
const casaFiltro = (e) => {
  if (!filtroAbas) return true;
  const chave = e.id + (e.sub ? "/" + e.sub : "");
  const compatNome = e.id + (e.sub ? "-" + e.sub : "");
  return filtroAbas.some((f) => f === chave || f === e.id || f === compatNome);
};
const entradas = plano.entradas.filter(casaFiltro);
const problemas = [];
const saidaAbas = {}; // chave -> blocos (real.json)
const listaEntradas = [];
let desenhoAusente = false;
let erros = 0, avisos = 0;
const conta = (p) => { if (p.sev === "erro") erros++; else avisos++; };

for (const a of plano.meta.semConstrutor || []) {
  if (!filtroAbas || filtroAbas.includes(a)) problemas.push({ sev: "aviso", aba: a, idx: "-", regra: "CONSTRUTOR", texto: "aba em ns.abas sem construtor em ns.abasConstrutores" });
}
if (entradas.length === 0) problemas.push({ sev: "aviso", aba: "-", idx: "-", regra: "CONSTRUTOR", texto: "nenhuma aba para rodar" });

for (const e of entradas) {
  const rotulo = e.id + (e.sub ? "/" + e.sub : "");
  const chave = e.id + (e.sub ? "-" + e.sub : "");
  const antes = problemas.length;
  let blocos = [];
  let r;
  try { r = pcallLua("__construir", e.id, e.sub, e.modo, e.fn, DESENHAR); }
  catch (ex) { r = { blocos: [], erro: String(ex.message) }; }
  if (r.erro) problemas.push({ sev: "erro", aba: rotulo, idx: "-", regra: "CONSTRUTOR", texto: String(r.erro) });
  else {
    blocos = Array.isArray(r.blocos) ? r.blocos : [];
    conferirBlocos(rotulo, blocos, 0, problemas);
  }
  if (r.desenho) {
    if (r.desenho.ausente) desenhoAusente = true;
    else if (!r.desenho.ok) problemas.push({ sev: "erro", aba: rotulo, idx: "-", regra: "DESENHO", texto: String(r.desenho.erro) });
  }
  saidaAbas[chave] = blocos;
  listaEntradas.push({ chave, id: e.id, sub: e.sub || null, modo: e.modo });
  const meus = problemas.slice(antes);
  const ne = meus.filter((p) => p.sev === "erro").length, na = meus.filter((p) => p.sev === "aviso").length;
  console.log(`ABA ${rotulo} blocos=${blocos.length} erros=${ne} avisos=${na}`);
}
if (DESENHAR && desenhoAusente) problemas.push({ sev: "aviso", aba: "-", idx: "-", regra: "DESENHO", texto: "ns.ui.desenhar ainda nao existe: nada foi desenhado" });

if (ABRIR) {
  let ab;
  try { ab = pcallLua("__abrir"); } catch (ex) { ab = { passos: 0, falhas: [{ passo: "__abrir", erro: String(ex.message) }] }; }
  for (const f of ab.falhas || []) problemas.push({ sev: "erro", aba: f.passo, idx: "-", regra: "ABRIR", texto: String(f.erro).split("\n").slice(0, 3).join(" | ") });
  console.log(`ABRIR passos=${ab.passos} falhas=${(ab.falhas || []).length} achados_boar=${ab.achados ?? "-"}`);
}

if (args.includes("--pular")) {
  let pu;
  try { pu = pcallLua("__pular"); } catch (ex) { pu = { falhas: [String(ex.message)] }; }
  for (const f of pu.falhas || []) problemas.push({ sev: "erro", aba: "pular", idx: "-", regra: "PULAR", texto: String(f) });
  console.log(`PULAR falhas=${(pu.falhas || []).length}`);
}

if (args.includes("--paladino")) {
  let falhasPal = 0;
  const mostrar = (ls) => { for (const x of ls) { if (!x.ok) falhasPal++; console.log("PAL " + x.id + " " + (x.ok ? "ok   " : "FALHA") + " " + x.msg); } };
  try { mostrar(pcallLua("__paladino").linhas); }
  catch (ex) { falhasPal++; console.log("PAL FALHA cenario: " + String(ex.message).split("\n")[0]); }
  const filho = spawnSync(process.execPath, [fileURLToPath(import.meta.url), "--filho-cacador", "--macros"], { encoding: "utf8" });
  const linhasE = (filho.stdout || "").split(/\r?\n/).filter((l) => l.startsWith("PAL e"));
  if (filho.status !== 0 || linhasE.length < 2) { falhasPal++; console.log("PAL e FALHA processo do cacador saiu " + filho.status + ": " + (filho.stderr || filho.stdout || "").split("\n")[0]); }
  else for (const l of linhasE) { if (l.includes(" FALHA ")) falhasPal++; console.log(l); }
  console.log("PALADINO falhas=" + falhasPal);
  if (falhasPal) problemas.push({ sev: "erro", aba: "paladino", idx: "-", regra: "PALADINO", texto: falhasPal + " verificacao(oes) falharam" });
}

const fim = pcallLua("__final");
for (const m of fim.erros) problemas.push({ sev: "aviso", aba: "-", idx: "-", regra: "EVENTO", texto: "erro de Lua em evento ou timer: " + m.split("\n").slice(0, 3).join(" | ") });
problemas.forEach(conta);

// lista agrupada por (sev, aba, regra)
const grupos = new Map();
for (const p of problemas) {
  const k = `${p.sev}|${p.aba}|${p.regra}`;
  if (!grupos.has(k)) grupos.set(k, []);
  grupos.get(k).push(p);
}
const ordem = { erro: 0, aviso: 1 };
const gruposOrd = [...grupos.entries()].sort((a, b) => ordem[a[1][0].sev] - ordem[b[1][0].sev]);
if (gruposOrd.length) console.log("");
for (const [, g] of gruposOrd) {
  const p = g[0];
  const idxs = g.map((x) => x.idx).filter((x) => x !== "-");
  const idxTxt = idxs.length ? ` #${[...new Set(idxs)].slice(0, 8).join(",")}${new Set(idxs).size > 8 ? ",..." : ""}` : "";
  const n = g.length > 1 ? ` (${g.length}x)` : "";
  console.log(`${p.sev === "erro" ? "ERRO " : "AVISO"} ${p.aba}${idxTxt} ${p.regra}${n}: ${p.texto}`);
}

// nao simuladas: o que o codigo leu como global e nao existe
const PROPOSITAIS = new Set(["Questie", "QuestieDB", "TomTom", "NaowhForever", "NaowhForever_Training", "RXPGuides", "RXPFrame", "ElvUI", "LibStub"]);
const todoFonte = Object.values(fontes).join("\n");
const reEsc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const chamadas = [], lidas = [];
for (const nome of fim.naoSimuladas) {
  const base = nome.split(".")[0];
  if (PROPOSITAIS.has(base) || /^(GuiaForever|SLASH_|BINDING_)/.test(base) || base.startsWith("__")) continue;
  const re = new RegExp(`(^|[^\\w.:])${reEsc(nome)}\\s*\\(|pcall\\(\\s*${reEsc(nome)}\\b`);
  (re.test(todoFonte) ? chamadas : lidas).push(nome);
}
console.log("");
console.log(`NAO SIMULADAS chamadas no codigo (${chamadas.length}): ${chamadas.join(", ") || "-"}`);
console.log(`NAO SIMULADAS so lidas, provavel checagem (${lidas.length}): ${lidas.join(", ") || "-"}`);
console.log(`RESUMO erros=${erros} avisos=${avisos}`);

// ---------- real.json e real.html ----------
mkdirSync(pastaVisual, { recursive: true });
const dados = {
  gerado: new Date().toISOString(),
  estrito: ESTRITO,
  personagem: PAL ? { nome: "Ignatius Stonejaw", classe: "Paladin", nivel: NIVEL_CFG } : { nome: "Hexumlite Bull", classe: "Hunter", nivel: 16 },
  entradas: listaEntradas,
  meta: plano.meta,
  blocos: saidaAbas,
};
const sufixo = PAL ? "-PALADIN" : "";
writeFileSync(join(pastaVisual, "real" + sufixo + ".json"), JSON.stringify(dados, null, 1));

const quadros = readFileSync(join(pastaVisual, "quadros.html"), "utf8");
const css = (quadros.match(/<style>([\s\S]*?)<\/style>/) || [, ""])[1];
const embutido = JSON.stringify(dados).replace(/</g, "\\u003c").replace(/\u2028/g, "\\u2028").replace(/\u2029/g, "\\u2029");
const html = MODELO_HTML(css, embutido);
writeFileSync(join(pastaVisual, "real" + sufixo + ".html"), html);

process.exit(falhouCarga ? 2 : erros > 0 ? 1 : 0);

// ---------- o modelo do real.html (sem crases nem cifrao-chave dentro: e uma String.raw) ----------
function MODELO_HTML(cssProposta, json) {
  return String.raw`<!doctype html>
<!-- Gerado por rodar-janela.mjs: os blocos que os construtores do GuiaForever devolvem (real.json, embutido abaixo), desenhados com o CSS da proposta (quadros.html). Aproximado: nao e o desenho do jogo. Hash = aba (#agora, #pet, #combate-teclas). -->
<html><head><meta charset="utf-8"><title>GuiaForever: blocos reais</title>
<style>
${"__CSS__"}
/* ---------- real.html: casca em fluxo, altura livre ---------- */
body { width: 844px; height: auto; overflow: visible; padding: 12px; background: #2a2a2a; }
.elv { padding-top: 48px; height: auto; min-height: 600px; overflow: visible; }
.elv .area { position: relative; left: auto; right: auto; top: auto; bottom: auto; margin-left: 151px; min-height: 551px; overflow: visible; padding: 12px 18px 12px 16px; }
.ph { display: inline-block; width: 20px; height: 20px; background: #4a4a4a; border: 1px solid #000; flex: none; vertical-align: middle; }
.card .ph { width: 28px; height: 28px; }
.petcard .ph { width: 58px; height: 58px; border-radius: 50%; }
.nav .ph { width: 20px; height: 20px; }
.chipE .ph { width: 18px; height: 18px; }
.tile .q.ph2 { background-color: #4a4a4a; }
.nav { cursor: pointer; }
.row .tecla, .card .tecla { margin-left: auto; }
.card .dir .tecla { margin-left: 0; }
.vz { color: #999; padding: 4px 6px; font-size: 14px; }
.aviso { margin: 8px 0; padding: 6px 10px; background: #4a1f1f; border: 1px solid #000; color: #ffd0d0; font-size: 13px; }
.estado { font: bold 12px Arial; margin-right: 2px; flex: none; }
.estado.feito { color: #6be06b; } .estado.falta { color: #e63333; } .estado.agora { color: #ffd100; } .estado.depois { color: #777; } .estado.travado { color: #aaa; }
.row.dest { box-shadow: inset 2px 0 0 var(--ac); }
.tb td.dir, .tb th.dir { text-align: right; } .tb td.centro, .tb th.centro { text-align: center; }
.tit40 { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; }
.tit40 .ph { width: 40px; height: 40px; }
.tit40 .nm { font-size: 20px; line-height: 20px; }
.eixo .rotH .ph { width: 18px; height: 18px; }
.lista .it .ph { width: 18px; height: 18px; }
</style></head>
<body>
<div id="raiz"></div>
<script>
var D = ${"__JSON__"};
var ICONES_PADRAO = [
  { id: "agora", rotulo: "Now", icone: "Interface\\Icons\\INV_Misc_Book_09" }, { id: "pet", rotulo: "Pet", icone: "Interface\\Icons\\Ability_Hunter_BeastCall" },
  { id: "familias", rotulo: "Families", icone: "Interface\\Icons\\Ability_Hunter_BeastTaming" }, { id: "talentos", rotulo: "Talents", icone: "Interface\\Icons\\Ability_Marksmanship" },
  { id: "combate", rotulo: "Combat", icone: "Interface\\Icons\\Ability_ImpalingBolt" }, { id: "profissoes", rotulo: "Professions", icone: "Interface\\Icons\\INV_Misc_Pelt_Wolf_01" },
  { id: "ajuda", rotulo: "Help", icone: "Interface\\Icons\\INV_Misc_QuestionMark" }
];
var CORES = { destaque: "var(--ac)", verde: "#6be06b", vermelho: "#e63333", laranja: "#ff8c1a", amarelo: "#ffd91a", azul: "#4d99ff", cinza: "#999", dourado: "#ffd100", texto: "#fff" };
function cor(n) { return CORES[n] || n || "#888"; }
function esc(s) { return String(s == null ? "" : s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"); }
function cc(s) {
  var abre = false;
  return esc(s).replace(/\|c[0-9a-fA-F]{2}([0-9a-fA-F]{6})|\|r/g, function (m, h) {
    if (h) { var r = (abre ? "</span>" : "") + '<span style="color:#' + h + '">'; abre = true; return r; }
    if (abre) { abre = false; return "</span>"; }
    return "";
  }) + (abre ? "</span>" : "");
}
function iconeUrl(x) {
  if (typeof x !== "string") return null;
  var m = x.replace(/\//g, "\\").match(/^Interface\\Icons\\([^\\]+)$/i);
  return m ? "icones/" + m[1].toLowerCase() + ".jpg" : null;
}
function falha(i) { var s = document.createElement("span"); s.className = "ph " + (i.className || ""); i.replaceWith(s); }
function ico(x, cls) {
  var u = iconeUrl(x);
  if (!u) return '<span class="ph ' + (cls || "") + '"></span>';
  return '<img src="' + u + '"' + (cls ? ' class="' + cls + '"' : "") + ' onerror="falha(this)">';
}
function dicaAttr(b) { var d = b.dica; if (Array.isArray(d)) d = d.join("\n"); return d ? ' title="' + esc(d) + '"' : ""; }
function tecla(k) { return k ? '<span class="tecla">' + cc(k) + "</span>" : ""; }
function botao(b) { return b && b.botao ? '<span class="bE">' + cc(b.botao.rotulo) + "</span>" : ""; }
function estadoIco(e, nv) {
  if (!e) return "";
  var m = { feito: "&#10003;", falta: "&#10007;", agora: "&#9679;", depois: "&#9679;", travado: "&#128274;" };
  return '<span class="estado ' + esc(e) + '">' + (m[e] || "?") + (e === "travado" && nv ? " " + esc(nv) : "") + "</span>";
}
function fundo(x) { var u = iconeUrl(x); return u ? "background-image:url(" + u + ")" : ""; }

var R = {};
R.sec = function (b) { return '<div class="sec"' + dicaAttr(b) + '><span class="ch">' + (b.aberta === false ? "&#9656;" : "&#9662;") + "</span>" + cc(b.s) + (b.qtd != null ? ' <span class="qtd">' + esc(b.qtd) + "</span>" : "") + "</div>"; };
R.cab = function (b) { return R.sec({ s: b.s, aberta: b.aberta, qtd: b.resumo }); };
R.card = function (b) {
  return '<div class="card" style="--cor:' + cor(b.cor) + '"' + dicaAttr(b) + ">" + ico(b.icone) + "<div><div class=\"t\">" + cc(b.s) + "</div>" + (b.sub ? '<div class="s">' + cc(b.sub) + "</div>" : "") + '</div><div class="dir">' + tecla(b.tecla) + botao(b) + "</div></div>";
};
R.item = function (b) {
  var badge = b.nivel === undefined ? "" : '<span class="badge' + (b.nivel === "" ? " vazio" : "") + '">' + esc(b.nivel) + "</span>";
  return '<div class="row' + (b.apagado ? " dim" : "") + (b.destaque ? " dest" : "") + '"' + dicaAttr(b) + ">" + badge + estadoIco(b.estado, b.nivelTrava) + (b.icone ? ico(b.icone) : "") +
    "<div>" + cc(b.s) + (b.sub ? ' <span class="s">' + cc(b.sub) + "</span>" : "") + "</div>" + tecla(b.tecla) + botao(b) + "</div>";
};
R.linha = function (b) { return R.item({ s: b.s, dica: b.dica }); };
R.nota = function (b) { return '<div class="nota"' + dicaAttr(b) + ">" + cc(b.s) + "</div>"; };
R.texto = R.nota;
R.vazio = function (b) { return '<div class="vz">' + cc(b.s) + "</div>"; };
R.espaco = function () { return '<div style="height:8px"></div>'; };
R.botao = function (b) { return '<div style="margin:2px 0 4px 6px"><span class="bE">' + cc(b.s) + "</span></div>"; };
R.tabela = function (b) {
  var cols = b.colunas || [], al = function (c) { return c && c.alinha === "dir" ? "dir" : c && c.alinha === "centro" ? "centro" : ""; };
  var tem = (b.linhas || []).some(function (l) { return l && l.botao; });
  var h = '<table class="tb"><tr>' + cols.map(function (c) { return '<th class="' + al(c) + '"' + (c.largura ? ' style="width:' + c.largura + 'px"' : "") + ">" + cc(c.s) + "</th>"; }).join("") + (tem ? "<th></th>" : "") + "</tr>";
  var limT = b.limite || 6, todas = b.linhas || [], sobra = Math.max(0, todas.length - limT);
  todas.slice(0, limT).forEach(function (l) {
    var cel = (l && l.celulas) || [];
    h += '<tr class="' + (l && l.apagado ? "dim" : "") + '"' + (l ? dicaAttr(l) : "") + ">" + cols.map(function (c, i) {
      var x = cel[i], o = typeof x === "object" && x ? x : { s: x };
      return '<td class="' + al(c) + (o.numero ? " num" : "") + '"' + (o.cor ? ' style="color:' + cor(o.cor) + '"' : "") + ">" + estadoIco(o.estado) + (o.icone ? ico(o.icone) : "") + cc(o.s) + "</td>";
    }).join("") + (tem ? "<td>" + (l && l.botao ? '<span class="bE">' + cc(l.botao.rotulo) + "</span>" : "") + "</td>" : "") + "</tr>";
  });
  if (sobra > 0) h += '<tr><td colspan="' + (cols.length + (tem ? 1 : 0)) + '" style="color:#aad372;font-size:13px">Show ' + sobra + " more</td></tr>";
  return h + "</table>";
};
R.passos = function (b) {
  return '<div class="passos" style="flex-wrap:wrap">' + (b.lista || []).map(function (s, i) { return (i ? '<span class="seta">&rsaquo;</span>' : "") + '<span class="p"><span class="n">' + (i + 1) + "</span>" + cc(s) + "</span>"; }).join("") + "</div>";
};
R.checklist = function (b) {
  return '<div style="padding:2px 6px">' + (b.itens || []).map(function (i) { return '<span class="chk"><i class="' + (i.feito ? "s" : "n") + '">' + (i.feito ? "&#10003;" : "&#10007;") + "</i>" + cc(i.s) + (i.sub ? ' <span class="c-cin" style="color:#999;font-size:12.5px">&nbsp;' + cc(i.sub) + "</span>" : "") + "</span>"; }).join("") + "</div>";
};
R.grade = function (b) {
  return (b.titulo ? '<div class="gtit">' + cc(b.titulo) + "</div>" : "") + '<div class="grade">' + (b.teclas || []).map(function (t) {
    if (!t) return '<div class="sep"></div>';
    var u = iconeUrl(t.icone);
    return '<div class="tile ' + (t.estado === "travado" ? "trava" : t.estado === "novo" ? "novo" : "") + '"' + dicaAttr(t) + '><div class="q' + (u ? "" : " ph2") + '" style="' + fundo(t.icone) + '"><span class="k">' + cc(t.k) + "</span></div>" +
      (t.estado === "travado" ? '<div class="lv">' + esc(t.nivel) + "</div>" : "") + (t.estado === "novo" ? '<span class="tag">NEW</span>' : "") + '<div class="nm">' + cc(t.nome) + "</div></div>";
  }).join("") + "</div>";
};
R.regua = function (b) {
  var mn = b.min || 1, mx = b.max || 60, x = function (lv) { return "calc(78px + (100% - 84px) * " + ((lv - mn) / (mx - mn || 1)) + ")"; };
  var h = "", linhas = b.linhas || [];
  linhas.forEach(function (l, i) {
    var y = i * 30;
    h += '<div class="rotH" style="top:' + y + 'px">' + ico(l.icone) + cc(l.nome) + '</div><div class="faixa" style="top:' + (y + 12) + 'px"></div>';
    (l.marcas || []).forEach(function (m) {
      var c = m.estado === "tem" ? "sabe" : m.estado === "agora" ? "agora" : "futuro";
      h += '<div class="mk ' + c + '" style="left:' + x(m.nivel) + ";top:" + (y + 4) + 'px"' + dicaAttr(m) + ">" + esc(m.rank) + "</div>";
    });
  });
  if (b.atual != null) h += '<div class="hoje" style="left:' + x(b.atual) + '"><span>' + cc(b.rotuloAtual || "") + "</span></div>";
  for (var lv = Math.ceil(mn / 10) * 10; lv <= mx; lv += 10) h += '<div class="reg" style="left:' + x(lv) + '">' + lv + "</div>";
  return '<div class="eixo" style="height:' + (linhas.length * 30 + 24) + 'px">' + h + '</div><div class="leg"><span><i style="background:#aad372"></i>has it</span><span><i style="background:#2a2208;border:1px solid #ffd100"></i>can learn now</span><span><i style="background:#151515;border:1px solid #555"></i>later</span></div>';
};
R.perfil = function (b) {
  var barras = (b.barras || []).slice(0, 2).map(function (r) {
    var p = r.max ? Math.max(0, Math.min(100, 100 * r.valor / r.max)) : 0;
    return '<div class="barraE"><div class="f" style="width:' + p + "%;background:" + cor(r.cor || "verde") + '"></div><div class="r">' + cc(r.s) + "</div></div>";
  }).join("");
  return '<div class="petcard">' + ico(b.icone, "retrato") + '<div style="width:190px"><div class="nome">' + cc(b.titulo) + '</div><div class="s" style="color:#9a9a9a;font-size:13px">' + (b.sub || []).map(cc).join("<br>") + "</div></div><div>" + barras + '</div><div style="width:150px;margin-left:4px">' + (b.etiquetas || []).map(function (e) { return '<span class="dieta">' + cc(e) + "</span>"; }).join("") + "</div></div>";
};
R.titulo = function (b) { return '<div class="tit40">' + ico(b.icone) + '<div><div class="nm">' + cc(b.s) + '</div><div style="margin-top:4px">' + (b.etiquetas || []).map(function (e) { return '<span class="dieta">' + cc(e) + "</span>"; }).join("") + "</div></div></div>"; };
R.etiquetas = function (b) { return '<div style="margin:2px 0"><span style="color:#999;font-size:12.5px">' + cc(b.rotulo || "") + "&nbsp; </span>" + (b.lista || []).map(function (e) { return '<span class="dieta">' + cc(e) + "</span>"; }).join("") + "</div>"; };
R.segs = function (b) { return '<div class="segs">' + (b.opcoes || []).map(function (o) { return '<span class="' + (o.id === b.atual ? "on" : "") + '">' + cc(o.s) + "</span>"; }).join("") + "</div>"; };
R.duas = function (b) {
  var lista = (b.lista || []).map(function (e) { return '<div class="it' + (e.id === b.atual ? " on" : "") + '">' + (e.icone ? ico(e.icone) : "") + cc(e.s) + (e.marca ? '<span class="seu">' + cc(e.marca) + "</span>" : e.sub ? '<span class="p">' + cc(e.sub) + "</span>" : "") + "</div>"; }).join("");
  return '<div class="duas"><div class="lista"' + (b.largura ? ' style="width:' + b.largura + 'px"' : "") + ">" + lista + '</div><div class="detalhe">' + render(b.detalhe || []) + "</div></div>";
};

function um(b) {
  if (!b || typeof b !== "object") return '<div class="aviso">bloco invalido</div>';
  var f = R[b.t];
  return f ? f(b) : '<div class="aviso">tipo desconhecido: ' + esc(b.t) + "</div>";
}
// "Show N more", como o Visual.lua faz (contrato 11.4: a secao mostra "limite" unidades, padrao 5)
function maisLinha(n) { return '<div class="row"><span class="badge vazio"></span><div style="color:#aad372;font-size:13px">Show ' + n + " more</div></div>"; }
function render(blocos) {
  var out = "", i = 0, fechada = false, lim = 5, cont = 0, esc2 = 0;
  var unidade = function (x) { return x && (x.t === "item" || x.t === "linha" || x.t === "card" || x.t === "nota" || x.t === "texto"); };
  var fecharSec = function () { if (esc2 > 0) out += maisLinha(esc2); esc2 = 0; cont = 0; };
  while (i < blocos.length) {
    var b = blocos[i];
    if (b && (b.t === "sec" || b.t === "cab")) { fecharSec(); fechada = b.aberta === false; lim = b.limite || 5; out += um(b); i++; continue; }
    if (fechada) { i++; continue; }
    var linhas = function (x) { return x && (x.t === "item" || x.t === "linha"); }, notas = function (x) { return x && (x.t === "nota" || x.t === "texto"); };
    var grupo = linhas(b) ? linhas : notas(b) ? notas : null;
    if (grupo) {
      var h = "";
      while (i < blocos.length && grupo(blocos[i])) { if (cont < lim) { h += um(blocos[i]); cont++; } else esc2++; i++; }
      out += "<div>" + h + "</div>"; continue;
    }
    if (unidade(b)) { if (cont < lim) { out += um(b); cont++; } else esc2++; i++; continue; }
    out += um(b); i++;
  }
  fecharSec();
  return out;
}

function chaveDoHash() {
  var h = (location.hash || "#agora").slice(1), ks = Object.keys(D.blocos);
  if (D.blocos[h]) return h;
  var f = ks.filter(function (k) { return k.indexOf(h + "-") === 0; });
  return f.length ? f[0] : null;
}
function desenhar() {
  var h = (location.hash || "#agora").slice(1), chave = chaveDoHash();
  var e = D.entradas.filter(function (x) { return x.chave === chave; })[0];
  var abas = (D.meta && D.meta.abas && D.meta.abas.length) ? D.meta.abas : ICONES_PADRAO;
  var ativa = e ? e.id : h;
  var nav = abas.map(function (a) { return '<div class="nav' + (a.id === ativa ? " on" : "") + '" onclick="irPara(\'' + a.id + "')\">" + ico(a.icone) + esc(a.rotulo) + "</div>"; }).join("");
  var chips = ((D.meta && D.meta.estado) || []).map(function (c) { return '<div class="chipE">' + ico(c.icone) + cc(c.s) + (c.n != null ? ' <span class="n"' + (c.cor ? ' style="color:' + cor(c.cor) + '"' : "") + ">" + esc(c.n) + "</span>" : "") + "</div>"; }).join("");
  var p = D.personagem;
  var area = chave ? render(D.blocos[chave]) : '<div class="aviso">Sem blocos para #' + esc(h) + ". Chaves: " + esc(Object.keys(D.blocos).join(", ")) + "</div>";
  document.getElementById("raiz").innerHTML = '<div class="elv"><div class="topo">' + ico("Interface\\Icons\\INV_Misc_Book_09", "livro") + '<div><div class="nome">GuiaForever</div><div class="sub">' + esc(p.nome) + " &middot; " + esc(p.classe) + " &middot; level " + p.nivel + '</div></div><div class="chips">' + chips + '</div><div class="buscaE">Search</div><div class="x">&#10005;</div></div>' +
    '<div class="trilho">' + nav + '<div class="rodape"><span class="chave"></span>Show all</div></div><div class="area">' + area + "</div></div>";
  document.body.setAttribute("data-h", String(Math.ceil(document.querySelector(".elv").getBoundingClientRect().height + 24)));
}
function irPara(id) {
  var f = D.entradas.filter(function (x) { return x.id === id; })[0];
  location.hash = f ? f.chave : id;
}
window.addEventListener("hashchange", desenhar);
desenhar();
</script></body></html>`.replace("__CSS__", () => cssProposta).replace("__JSON__", () => json + ";");
}
