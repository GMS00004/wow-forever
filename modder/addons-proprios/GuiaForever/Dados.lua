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
      [22] = "A decidir", [23] = "A decidir", [24] = "A decidir", [25] = "A decidir",
      [26] = "A decidir", [27] = "A decidir", [28] = "A decidir", [29] = "A decidir",
      [30] = "A decidir", [31] = "A decidir", [32] = "A decidir", [33] = "A decidir",
      [34] = "A decidir", [35] = "A decidir", [36] = "A decidir", [37] = "A decidir",
      [38] = "A decidir", [39] = "A decidir", [40] = "A decidir", [41] = "A decidir",
      [42] = "A decidir", [43] = "A decidir", [44] = "A decidir", [45] = "A decidir",
      [46] = "A decidir", [47] = "A decidir", [48] = "A decidir", [49] = "A decidir",
      [50] = "A decidir", [51] = "A decidir", [52] = "A decidir", [53] = "A decidir",
      [54] = "A decidir", [55] = "A decidir", [56] = "A decidir", [57] = "A decidir",
      [58] = "A decidir", [59] = "A decidir", [60] = "A decidir",
    },
    lei = {
      "Deadly Aspects 5/5 do 10 ao 14",
      "Pathfinding 2/2, Bestial Swiftness e Unleashed Fury na linha 3",
      "Summon Hawk e Ferocity 5/5 na linha 4",
      "Intimidation e Bestial Discipline na linha 5",
      "Frenzy",
      "Bestial Wrath no 40",
      "Depois do 40: Marksmanship com Lethal Attacks e Careful Aim",
    },
    aberto = {
      { ponto = "Unleashed Fury",
        opcoes = { "Method: 4/5", "Kargoz: 5/5", "MetaGoblin: pontos, sem numero; alterna com Ferocity" } },
      { ponto = "Bestial Discipline",
        opcoes = { "Method: 2/2", "Kargoz: 1/2", "MetaGoblin: o talento-chave, logo no 31" } },
      { ponto = "Spirit Bond",
        opcoes = { "Method: nao", "Kargoz: 1 ponto opcional", "MetaGoblin: sim" } },
      { ponto = "Improved Aspect of the Monkey",
        opcoes = { "Method: nao", "Kargoz: 1 ponto opcional", "MetaGoblin: nao (so para solar elite com Screech)" } },
      { ponto = "Frenzy",
        opcoes = { "Method: 4/5", "Kargoz: 4/5", "MetaGoblin: 5/5" } },
      { ponto = "Depois do 40",
        opcoes = {
          "Method: Marksmanship: Lethal Attacks 5/5, Careful Aim 5/5, Rapid Killing 2/2, Efficiency 3/5, Mortal Shots 5/5",
          "Kargoz: Marksmanship: crit, Careful Aim e Hawk Eye (alcance)",
          "MetaGoblin: Marksmanship (Lethal, Careful Aim, Rapid Killing), ou respec para MM ou SV no 40",
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
      [18] = "Improved Healing Wave 1 (livre; Totemic Focus tambem serve)",
      [19] = "Improved Healing Wave 2 (livre; Totemic Focus tambem serve)",
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
      [30] = "RESPEC no treinador (pede boa arma de 2 maos): so Enhancement. Thundering Strikes 5/5, Mental Dexterity 3/3, Ancestral Knowledge 2, Shamanistic Focus 1/1, Elemental Weapons 3/3, Anticipation 1, Stormstrike 1/1, Improved Ghost Wolf 2/2, Flurry 2, Improved Stormstrike 1/2",
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
      [43] = "Ponto livre: Improved Healing Wave, Totemic Focus ou Improved Reincarnation",
      [44] = "Ponto livre: Improved Healing Wave, Totemic Focus ou Improved Reincarnation",
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
      [60] = "Flurry 3/5 (e respec no 60)",
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
    versao = 2,  -- 2: sting_Auto (2026-11-05, noite)
    fonte = "Gladius Gaming e leak",
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
