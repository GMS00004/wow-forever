-- Dados do GuiaForever: so dados, sem logica.
-- Fonte: fichas hexumlite-bull.md e rurik-thunderfist.md (2026-11-05).

GuiaForeverDados = {
  HUNTER = {
    personagem = "Hexumlite Bull",
    ordem = {
      [10] = "Deadly Aspects 1/5",
      [11] = "Deadly Aspects 2/5",
      [12] = "Deadly Aspects 3/5",
      [13] = "Deadly Aspects 4/5",
      [14] = "Deadly Aspects 5/5",
      [15] = "Focused Fire 1/2",
      [16] = "Focused Fire 2/2",
      [17] = "Improved Revive Pet 1/2",
      [18] = "Endurance Training 1/5",
      [19] = "Endurance Training 2/5",
      [20] = "Pathfinding 1/2",
      [21] = "Pathfinding 2/2",
      [22] = "TBD", [23] = "TBD", [24] = "TBD", [25] = "TBD",
      [26] = "TBD", [27] = "TBD", [28] = "TBD", [29] = "TBD",
      [30] = "TBD", [31] = "TBD", [32] = "TBD", [33] = "TBD",
      [34] = "TBD", [35] = "TBD", [36] = "TBD", [37] = "TBD",
      [38] = "TBD", [39] = "TBD", [40] = "TBD", [41] = "TBD",
      [42] = "TBD", [43] = "TBD", [44] = "TBD", [45] = "TBD",
      [46] = "TBD", [47] = "TBD", [48] = "TBD", [49] = "TBD",
      [50] = "TBD", [51] = "TBD", [52] = "TBD", [53] = "TBD",
      [54] = "TBD", [55] = "TBD", [56] = "TBD", [57] = "TBD",
      [58] = "TBD", [59] = "TBD", [60] = "TBD",
    },
    lei = {
      "Deadly Aspects 5/5 from 10 to 14",
      "Pathfinding 2/2, Bestial Swiftness and Unleashed Fury on row 3",
      "Summon Hawk and Ferocity 5/5 on row 4",
      "Intimidation and Bestial Discipline on row 5",
      "Frenzy",
      "Bestial Wrath at 40",
      "After 40: Marksmanship with Lethal Attacks and Careful Aim",
    },
    aberto = {
      { ponto = "Unleashed Fury",
        opcoes = { "Method: 4/5", "Kargoz: 5/5", "MetaGoblin: points, no number; alternates with Ferocity" } },
      { ponto = "Bestial Discipline",
        opcoes = { "Method: 2/2", "Kargoz: 1/2", "MetaGoblin: the key talent, right at 31" } },
      { ponto = "Spirit Bond",
        opcoes = { "Method: no", "Kargoz: 1 optional point", "MetaGoblin: yes" } },
      { ponto = "Improved Aspect of the Monkey",
        opcoes = { "Method: no", "Kargoz: 1 optional point", "MetaGoblin: no (only to solo elites with Screech)" } },
      { ponto = "Frenzy",
        opcoes = { "Method: 4/5", "Kargoz: 4/5", "MetaGoblin: 5/5" } },
      { ponto = "After 40",
        opcoes = {
          "Method: Marksmanship: Lethal Attacks 5/5, Careful Aim 5/5, Rapid Killing 2/2, Efficiency 3/5, Mortal Shots 5/5",
          "Kargoz: Marksmanship: crit, Careful Aim and Hawk Eye (range)",
          "MetaGoblin: Marksmanship (Lethal, Careful Aim, Rapid Killing), or respec to MM or SV at 40",
        } },
    },
  },

  SHAMAN = {
    personagem = "Rurik Thunderfist",
    ordem = {
      [10] = "Tidal Focus 1/5",
      [11] = "Tidal Focus 2/5",
      [12] = "Tidal Focus 3/5",
      [13] = "Tidal Focus 4/5",
      [14] = "Tidal Focus 5/5",
      [15] = "Mindfulness 1/3",
      [16] = "Mindfulness 2/3",
      [17] = "Mindfulness 3/3",
      [18] = "Improved Healing Wave 1 (free; Totemic Focus works too)",
      [19] = "Improved Healing Wave 2 (free; Totemic Focus works too)",
      [20] = "Water Shield 1/1",
      [21] = "Thundering Strikes 1/5",
      [22] = "Thundering Strikes 2/5",
      [23] = "Thundering Strikes 3/5",
      [24] = "Thundering Strikes 4/5",
      [25] = "Thundering Strikes 5/5",
      [26] = "Mental Dexterity 1/3",
      [27] = "Mental Dexterity 2/3",
      [28] = "Mental Dexterity 3/3",
      [29] = "Ancestral Knowledge 1",
      [30] = "RESPEC at the trainer (needs a good 2-handed weapon): Enhancement only. Thundering Strikes 5/5, Mental Dexterity 3/3, Ancestral Knowledge 2, Shamanistic Focus 1/1, Elemental Weapons 3/3, Anticipation 1, Stormstrike 1/1, Improved Ghost Wolf 2/2, Flurry 2, Improved Stormstrike 1/2",
      [31] = "Improved Stormstrike 2/2",
      [32] = "Spirit Weapons 1/1",
      [33] = "Mental Quickness 1/2",
      [34] = "Mental Quickness 2/2",
      [35] = "Tidal Focus 1/5",
      [36] = "Tidal Focus 2/5",
      [37] = "Tidal Focus 3/5",
      [38] = "Tidal Focus 4/5",
      [39] = "Tidal Focus 5/5",
      [40] = "Mindfulness 1/3",
      [41] = "Mindfulness 2/3",
      [42] = "Mindfulness 3/3",
      [43] = "Free point: Improved Healing Wave, Totemic Focus or Improved Reincarnation",
      [44] = "Free point: Improved Healing Wave, Totemic Focus or Improved Reincarnation",
      [45] = "Water Shield 1/1",
      [46] = "Maelstrom Weapon 1/5",
      [47] = "Maelstrom Weapon 2/5",
      [48] = "Maelstrom Weapon 3/5",
      [49] = "Maelstrom Weapon 4/5",
      [50] = "Maelstrom Weapon 5/5",
      [51] = "Rage of the Farseer 1/1",
      [52] = "Convection 1/5",
      [53] = "Convection 2/5",
      [54] = "Convection 3/5",
      [55] = "Convection 4/5",
      [56] = "Convection 5/5",
      [57] = "Elemental Devastation 1/3",
      [58] = "Elemental Devastation 2/3",
      [59] = "Elemental Devastation 3/3",
      [60] = "Flurry 3/5 (and respec at 60)",
    },
  },
}

-- Macros do personagem, criadas no login de cada personagem da classe quando a
-- versao do conjunto sobe (depois, /guia macros recria as que faltarem;
-- /guia macros desfazer apaga e o login nao recria mais).
-- Fontes: Gladius Gaming, video de 2026-11-02 (comum\fontes\builds\gladius-hunter.md),
-- texto transcrito dos prints do dono; leak, documento publico no HackMD
-- (comum\fontes\builds\leak-hunter-macros.md), texto conferido em 2026-11-05.
-- Teclas e escolha das macros do leak: dono, em 2026-11-05.
GuiaForeverMacros = {
  HUNTER = {
    versao = 4,  -- 2: sting_Auto (2026-11-05, noite); 3: mark_Pet (2026-11-06); 4: mark_Conc (2026-11-06, noite)
    fonte = "Gladius Gaming and leak",
    lista = {
      { nome = "send_Pet", icone = "Ability_GhoulFrenzy", tecla = "SHIFT-MOUSEWHEELUP",
        corpo = "/petattack" },
      { nome = "pet_Return", icone = "INV_MISC_QUESTIONMARK", tecla = "SHIFT-MOUSEWHEELDOWN",
        corpo = "#showtooltip Dismiss Pet\n/petfollow" },
      { nome = "move_Here", icone = "Ability_Hunter_Pet_Goto", tecla = "BUTTON3",
        corpo = "/petmoveto" },
      { nome = "Hunter's Mark", icone = "INV_MISC_QUESTIONMARK",
        corpo = "#showtooltip Hunter's Mark\n/petpassive\n/petfollow\n/cast [@mouseover, harm][] Hunter's Mark" },
      { nome = "Taunt", icone = "INV_MISC_QUESTIONMARK",
        corpo = "#showtooltip Growl\n/cast Growl" },
      { nome = "Freezing Trap", icone = "INV_MISC_QUESTIONMARK",
        corpo = "#showtooltip Freezing Trap\n/petpassive\n/cast Freezing Trap" },
      { nome = "eagle_Eye", icone = "INV_MISC_QUESTIONMARK",
        corpo = "#showtooltip eagle eye\n/cast !eagle eye" },
      { nome = "Attack_Speed", icone = "Ability_Hunter_BeastTaming",
        corpo = '/run mainSpeed, offSpeed = UnitAttackSpeed("target") print(format("%s: attack speed = %.2f", GetUnitName("target"), mainSpeed))' },
      -- leak: as escolhidas pelo dono
      { nome = "pet_AllInOne", icone = "INV_MISC_QUESTIONMARK",
        corpo = "#showtooltip\n/cast [@pet,dead] Revive Pet; [nopet] Call Pet; Mend Pet" },
      { nome = "Burst", icone = "INV_MISC_QUESTIONMARK",
        corpo = "#showtooltip Rapid Fire\n/cast Rapid Fire\n/cast Elune's Light\n/cast Blood Fury\n/cast Berserking\n/cast Bestial Wrath\n/use 13" },
      { nome = "aspect_Hawk", icone = "INV_MISC_QUESTIONMARK",
        corpo = "#showtooltip\n/cast [mod:alt] Aspect of the Beast; Aspect of the Hawk" },
      { nome = "aspect_Cheetah", icone = "INV_MISC_QUESTIONMARK",
        corpo = "#showtooltip\n/cast [mod:alt] Aspect of the Pack; Aspect of the Cheetah" },
      { nome = "cancel_Cheetah", icone = "Ability_Mount_JungleTiger",
        corpo = "/cancelaura Aspect of the Cheetah\n/cancelaura Aspect of the Pack" },
      -- pedido do dono (2026-11-05, noite): Auto Shot primeiro, Serpent Sting no
      -- aperto seguinte, depois so Auto Shot. Fora de combate o [combat] pula a
      -- sequencia e so o Auto Shot sai; em combate sai o Sting uma vez por alvo.
      -- O "!" nunca desliga o Auto Shot. Recomeca: novo alvo, fim do combate, Alt.
      -- Mecanica conferida em Blizzard_ChatFrameBase/Shared/CastSequenceManager.lua
      -- (espelho Ketho/wow-ui-source-forever); "!" e "null" so o teste no jogo confirma.
      { nome = "sting_Auto", icone = "INV_MISC_QUESTIONMARK",
        corpo = "#showtooltip\n/castsequence [combat] reset=target/combat/alt Serpent Sting, null\n/cast !Auto Shot" },
      -- "Hunter's Mark Leveling" do leak (11:05 do video): marca e manda o pet.
      -- Escolha do dono em 2026-11-06, no nivel 10 e com pet, no lugar da do
      -- Gladius no 5 (que poe o pet em passivo e o chama de volta). O leak avisa:
      -- so sozinho no mundo aberto, em grupo puxa o mob antes da hora.
      { nome = "mark_Pet", icone = "INV_MISC_QUESTIONMARK",
        corpo = "#showtooltip Hunter's Mark\n/petattack\n/cast Hunter's Mark" },
      -- pedido do dono (2026-11-06, noite): "um macro que usa Hunter's Mark e
      -- Concussive Shot", no 5 no lugar da mark_Pet. 1o aperto num alvo novo:
      -- /petattack e Hunter's Mark; depois a sequencia para no "null" e a linha de
      -- baixo solta o Concussive Shot sempre que estiver pronto. No aperto da marca
      -- o Concussive falha pela recarga global (pode aparecer o aviso vermelho).
      -- Recomeca so com alvo novo. Mesmo truque do "null" da sting_Auto.
      { nome = "mark_Conc", icone = "INV_MISC_QUESTIONMARK",
        corpo = "#showtooltip\n/petattack\n/castsequence reset=target Hunter's Mark, null\n/cast Concussive Shot" },
    },
  },
}

-- Perfil grafico (aplicado uma vez no login). Fonte: video da Bellular
-- "We Tested Every WoW Forever Graphics Setting" (28/10/2026); nomes e escalas
-- conferidos no codigo da interface do Forever (Blizzard_SettingsDefinitions_Shared/Graphics.lua).
GuiaForeverGraficos = {
  { cvar = "graphicsLiquidDetail", valor = "3" },
  { cvar = "graphicsSpellDensity", valor = "0" },
  { cvar = "raidGraphicsSpellDensity", valor = "0" },
  { cvar = "graphicsViewDistance", valor = "8" },
  { cvar = "groundEffectDensity", valor = "64" },
  { cvar = "bloomUserMult", valor = "0.6" },
}

-- Profissoes de cada personagem, por classe, para a aba Treinos (onde aprender
-- antes de ter a profissao). Fonte: decisoes do dono em 2026-11-04
-- (comum\jogador.md): nos principais, Cooking e First Aid como secundarias.
GuiaForeverProfissoesPlanejadas = {
  HUNTER = { "Leatherworking", "Skinning", "Cooking", "First Aid" },  -- Hexumlite Bull
  SHAMAN = { "Herbalism", "Enchanting", "Cooking", "First Aid" },     -- Rurik Thunderfist
  DRUID = { "Alchemy", "Tailoring" },                                -- Fingolfin Ironjaw (alt)
  PALADIN = { "Mining", "Blacksmithing" },                           -- alt sem nome
}

-- Rastreador de profissoes (Rastreador.lua), embaixo do minimapa: a pericia de
-- cada profissao e a meta da area de quest atual. Pedido do dono em 2026-11-06,
-- que escolheu "meta pelo nivel da area, a partir das fontes dele":
--   Skinning: faixas por nivel de bicho do wow-professions (bichos de nivel
--   1-2 ate 75; 10-20 de 75 a 125; 25-27 de 125 a 150);
--   Leatherworking: couro de cada faixa no roteiro do Gfinity (Light Leather ate
--   100; Medium Leather de 100 a 150).
--   75 tambem e o teto do Apprentice (o Journeyman pede nivel 10).
-- Os numeros por faixa foram aprovados pelo dono; a ligacao de cada zona a uma
-- faixa (pelo nivel tipico dos bichos da zona) e do agente, a conferir.
GuiaForeverRastreador = {
  ligado = true,
  esconderEmCombate = true,
  faixas = {
    { nome = "1-10", nivelDe = 1, nivelAte = 9, metas = { Skinning = 75, Leatherworking = 75 } },
    { nome = "10-20", nivelDe = 10, nivelAte = 19, metas = { Skinning = 125, Leatherworking = 100 } },
    { nome = "20-30", nivelDe = 20, nivelAte = 29, metas = { Skinning = 150, Leatherworking = 150 } },
  },
  -- zona (nome do cliente enUS, GetRealZoneText) -> faixa. Fora desta lista
  -- (cidade, zona nova do Forever), vale a faixa do nivel do personagem.
  zonas = {
    ["Teldrassil"] = 1, ["Elwynn Forest"] = 1, ["Dun Morogh"] = 1,
    ["Darkshore"] = 2, ["Westfall"] = 2, ["Loch Modan"] = 2, ["Redridge Mountains"] = 2,
    ["Ashenvale"] = 3, ["Wetlands"] = 3, ["Duskwood"] = 3, ["Stonetalon Mountains"] = 3,
    ["Hillsbrad Foothills"] = 3,
  },
}

-- GuiaForeverPet: dados do pet do cacador para a 1.0 (ARQUITETURA.md secao 7).
-- Conferidos em 2026-11-06 nos arquivos instalados (so leitura), em
-- "C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\":
--   magias (ids de magia do cliente 1.60.1.70790): NaowhForever_Training\Data\TrainingData.lua,
--     classe 3 (HUNTER), linhas 267-276 (883 call, 2641 dismiss, 6991 feed, 982 revive, 1515 tame, 136 mend).
--   missao 6103 "Training the Beast", entregue a Jocaste: RXPGuides\Guides\forever\Alliance-1-10_NightElf.lua, linha 2231.
--   treinadores, Jocaste e Jaeana (coordenadas = Towns.lua / 100): NaowhForever\Shared\Game\Towns.lua,
--     Keldas linha 675 (mapa 1438), Jocaste linha 1443, Jaeana linha 1451, Silvaria linha 1500 (mapa 1457).
GuiaForeverPet = {
  HUNTER = {
    magias = { feed = 6991, call = 883, revive = 982, tame = 1515, dismiss = 2641, mend = 136 },
    missoes = {
      { id = 6103, nome = "Training the Beast", npc = "Jocaste", raca = "NightElf", mapa = 1457, x = 0.404, y = 0.086, fonte = "RestedXP" },
    },
    treinadores = {
      { npc = "Keldas", mapa = 1438, x = 0.568, y = 0.598, fonte = "Naowh" },   -- Towns.lua:675
      { npc = "Silvaria", mapa = 1457, x = 0.425, y = 0.092, fonte = "Naowh" }, -- Towns.lua:1500
    },
    comida = {
      reservados = {},
      vendedores = {
        { npc = "Jaeana", dieta = "Meat", mapa = 1457, x = 0.645, y = 0.717, fonte = "Naowh" },  -- Towns.lua:1451
      },
    },
  },
}
