-- CentralForever/Config.lua: o que o modder define para a central de combate.
-- Mudou aqui, o /reload aplica (o dono nao configura nada dentro do jogo).
-- So dados; nenhum codigo. Medidas em unidades da UI (na tela do dono, 2560x1440 com
-- escala 0.7, 1 unidade = 1,3125 px). Cores em { r, g, b } ou { r, g, b, a }, de 0 a 1.
-- O significado de cada chave e o contrato de cada modulo estao em CONTRATO.md.

CentralForeverConfig = {
  ligado = true,
  versaoConfig = 1,

  -- Quadro: canto inferior direito, acima da faixa de datatexts do ElvUI (y 4 a 27).
  ponto = { "BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -4, 31 },
  largura = 406,
  altura = 76,
  vao = 4,
  cartaoThreat = { largura = 132 },
  cartaoDano = { largura = 270 },
  strata = "MEDIUM",
  nivel = 20,

  -- Fonte dos numeros e das palavras (escolha do dono em 2026-11-06). A Expressway nao tem
  -- digitos de largura fixa, entao todo numero fica em caixa fixa alinhada a direita.
  fonte = {
    nome = "Expressway",
    arquivo = "Interface\\AddOns\\ElvUI\\Game\\Shared\\Media\\Fonts\\Expressway.ttf",
    contorno = "OUTLINE",
  },
  tamanhos = { dps = 38, luta = 20, total = 16, tempo = 16, rotulo = 13, palavra = 24, linha2 = 18 },
  -- largura fixa de cada campo (o texto nunca e medido)
  caixas = { dps = 116, valor = 76, rotulo = 46, threat = 124 },
  regua = { largura = 120, altura = 6, marca = 80 },
  borda = { fina = 1, perto = 2, alto = 3 },

  cores = {
    fundo = { 0.051, 0.051, 0.051, 0.80 },
    borda = { 0, 0, 0, 1 },
    dps = { 1, 1, 1 },
    luta = { 1, 1, 1 },
    total = { 0.784, 0.784, 0.784 },
    tempo = { 0.651, 0.651, 0.651 },
    rotulo = { 0.651, 0.651, 0.651 },
    trilho = { 0.149, 0.149, 0.149 },
    marca = { 1, 1, 1, 0.35 },
    neutro = { 0.651, 0.651, 0.651 },
    ambar = { 1, 0.690, 0 },
    vermelhao = { 1, 0.125, 0 },
    vermelhaoTexto = { 1, 0.416, 0.302 },
    cheio = { 0.851, 0.102, 0 },
    azul = { 0.361, 0.784, 1 },
    branco = { 1, 1, 1 },
    pulso = { 1, 1, 1, 0.35 },
  },

  -- Textos que aparecem no jogo (ingles).
  rotulos = { dps = "DPS", luta = "FIGHT", total = "TOTAL" },
  vazio = "--",
  tempoZero = "0:00",

  -- Formatador de cada numero: "inteiro" (C_StringUtil.RoundToNearestString) ou
  -- "abrev" (AbbreviateNumbers). Vale igual dentro e fora de combate.
  formato = { dps = "inteiro", luta = "abrev", total = "abrev" },

  -- Papel no threat: por classe, com sobrescrita por nome do personagem. Padrao "dps".
  papelClasse = { PALADIN = "tanque" },
  papel = {},
  papelPadrao = "dps",

  threat = {
    palavras = {
      SAFE = "SAFE", CLOSE = "CLOSE", HIGH = "HIGH", ON_YOU = "ON YOU",
      HELD = "HELD", SLIPPING = "SLIPPING", LOOSE = "LOOSE", LOST = "LOST",
      NEUTRO = "THREAT",
    },
    outro = "other",
    escala = 100,
    perto = { entra = 80, sai = 75 },
    alto = { entra = 95, sai = 90 },
    desafiante = { entra = 80, sai = 75 },
    melhoraSeg = 1.0,
    pulsoSeg = 0.3,
    pulsoMinSeg = 8,
    pulsoAposAlvoSeg = 0.5,
    semAlvoSeg = 2,
    fadeSeg = 0.4,
    nomeMax = 7,
    -- no tanque, com a porcentagem secreta (chefe), usa UnitThreatLeadSituation:
    -- 0 e 1 = HELD, 2 e 3 = SLIPPING (escala invertida: 3 e o pior caso)
    usarLider = true,
    liderSlipping = 2,
    unidades = { "pet", "party1", "party2", "party3", "party4",
                 "partypet1", "partypet2", "partypet3", "partypet4" },
  },

  -- Segundos. O tique so existe em combate.
  cadencia = { tique = 0.25, dano = 0.5, tempo = 1.0, threat = 0.25 },
  entrada = { fadeSeg = 0.15 },
  resumo = {
    carenciaSeg = 1.0,
    tentativas = 8,
    intervaloSeg = 0.2,
    acesoSeg = 3,
    fadeSeg = 1.0,
    -- dono, 2026-11-16, vendo a previa: so texto (sem caixa) e mais forte que os 0.45 iniciais
    alfa = 0.65,
    fundo = false,
  },
  login = { mostrarSeg = 4 },
  amostra = { seg = 10 },

  -- Janela nativa do medidor da Blizzard: "esconder" poe o CVar damageMeterEnabled em 0
  -- (o valor anterior fica guardado por personagem e volta sozinho) ou "deixar".
  janelaNativa = "esconder",
  -- Reserva: se o motor nao coletar com a janela nativa desligada, o addon devolve o CVar.
  -- So depois de reservaLutas lutas seguidas, de pelo menos reservaDurMin segundos cada, sem a
  -- linha do jogador (uma luta sem dano sozinha nao prova nada).
  reservaCVar = true,
  reservaLutas = 3,
  reservaDurMin = 10,

  sondas = { ligado = true, maxLutas = 30, maxEntradas = 300 },
  log = { max = 80 },
  disjuntor = { erros = 3 },
}
