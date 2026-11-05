-- Dicas do GuiaForever por nivel: so dados, sem logica.
-- Fontes e decisoes do dono em 2026-11-05 (fichas em comum\personagens\).
GuiaForeverDicas = {
  HUNTER = {
    personagem = "Hexumlite Bull",
    magias = {   -- em ordem crescente de nivel
      { nivel = 1, texto = "Sem pet: maximize o Auto Shot.", fonte = "Method" },  -- origem: hexumlite-bull.md:95
      { nivel = 4, texto = "Serpent Sting quando o alvo nao for morrer rapido.", fonte = "Method" },  -- origem: hexumlite-bull.md:95
      { nivel = 6, texto = "Arcane Shot.", fonte = "Method" },  -- origem: hexumlite-bull.md:95
      { nivel = 6, texto = "Hunter's Mark.", fonte = "Method" },  -- origem: hexumlite-bull.md:95
      { nivel = 8, texto = "Concussive Shot para desacelerar e kitar.", fonte = "Method" },  -- origem: hexumlite-bull.md:95
      { nivel = 10, texto = "Aspect of the Hawk ligado sempre que lutar.", fonte = "Method" },  -- origem: hexumlite-bull.md:96
      { nivel = 12, texto = "Mend Pet, para elites de nivel alto.", fonte = "Method" },  -- origem: hexumlite-bull.md:97
      { nivel = 18, texto = "Multi-Shot: AoE; divide a recarga com o Aimed Shot.", fonte = "Method" },  -- origem: hexumlite-bull.md:98
      { nivel = 20, texto = "Aimed Shot: alvo unico, 2 s de cast.", fonte = "Method" },  -- origem: hexumlite-bull.md:99
      { nivel = 20, texto = "Aspect of the Cheetah: sempre fora de combate, sem montaria.", fonte = "Method" },  -- origem: hexumlite-bull.md:99
      { nivel = 20, texto = "Freezing Trap.", fonte = "Method" },  -- origem: hexumlite-bull.md:99
      { nivel = 24, texto = "Track Hidden.", fonte = "Method" },  -- origem: hexumlite-bull.md:100
      { nivel = 25, texto = "Summon Hawk (talento, novo do Forever): manter 2 falcoes e o pet fora o tempo todo.", fonte = "Method" },  -- origem: hexumlite-bull.md:101
      { nivel = 25, texto = "Falcoes duram 18 s: refazer so no ultimo segundo.", fonte = "Method" },  -- origem: hexumlite-bull.md:101
      { nivel = 25, texto = "Summon Hawk divide 6 s de recarga com o Arcane Shot.", fonte = "Method" },  -- origem: hexumlite-bull.md:101
      { nivel = 25, texto = "Depois do 25, Arcane Shot so em luta longa de alvo unico (um a cada 3 casts).", fonte = "Method" },  -- origem: hexumlite-bull.md:101
      { nivel = 26, texto = "Rapid Fire (recarga de 5 min).", fonte = "Method" },  -- origem: hexumlite-bull.md:102
      { nivel = 28, texto = "Frost Trap: 60% de lentidao em area.", fonte = "Method" },  -- origem: hexumlite-bull.md:103
      { nivel = 30, texto = "Intimidation (talento); tambem serve de taunt do pet.", fonte = "Method" },  -- origem: hexumlite-bull.md:104
      { nivel = 30, texto = "Feign Death (pode errar).", fonte = "Method" },  -- origem: hexumlite-bull.md:104
      { nivel = 30, texto = "Dash do pet, aprendido por Wild Taming: dome um pet que saiba Dash e use-o em combate ate a mensagem de magia aprendida.", fonte = "Method" },  -- origem: hexumlite-bull.md:104
      { nivel = 40, texto = "Bestial Wrath (talento).", fonte = "Method" },  -- origem: hexumlite-bull.md:105
    },
    armas = {
      { de = 1, ate = 10, texto = "Night Elf: arco branco (3.81 DPS) da cadeia Crown of the Earth, 7 missoes, comeca em Tenaron's Summons (Teldrassil).", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 03:47
      { de = 3, ate = 16, texto = "Arcos e armas de fogo de vendedor nos niveis 3, 11, 14 e 16; a arma de longo alcance importa menos do que parece.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:26
      { de = 11, ate = 20, texto = "Daryl's Hunting Bow (5.87 DPS, 1 agi) ou Rifle (6.4 DPS): missao de Daryl the Youngling, Loch Modan; 15 min de tempo, ideal perto do 14.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 06:29
      { de = 13, ate = 20, texto = "Calibrated Blunderbuss (9.57 DPS, 3 sta): missao Old Ironforge Incursion (Earthseer Pharsone, leste de Dun Morogh), dungeon Hall of Thanes.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 05:56
      { de = 13, ate = 20, texto = "Para a missao da Calibrated: Dark Iron Map, que cai dos Dark Iron scouts e spies no leste de Dun Morogh.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 06:29
      { de = 16, ate = 20, texto = "Deadly Blunderbuss (8.27 DPS, 2 agi): Engineering 105 ou leilao.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 07:03
      { de = 17, ate = 20, texto = "Owl Sight Rifle (7.88 DPS, 2 agi): escolta The Sleeper Has Awakened (Kerlonian Evershade), Darkshore ate Ashenvale.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 07:36
      { de = 17, ate = 22, texto = "Impaling Harpoon (9 agi, 5 int): Captain Greenskin, Deadmines.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 10:23
      { de = 19, ate = 22, texto = "Venom Strike (12.08 DPS, veneno): Lord Serpentis, Wailing Caverns; a melhor ate o 22.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 10:55
      { de = 22, ate = 29, texto = "Raptor's End (12.07 DPS, 2 agi, 2 sta): cadeia de 3 missoes de Oromar, Wetlands; pegar no 22, terminar antes do 29.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 11:26
      { de = 22, ate = 29, texto = "Naga Heartpiercer (13.33 DPS; fere 42 e atordoa naga): Lady Sarevess, segundo chefe de Blackfathom Deeps.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 11:59
      { de = 22, ate = 29, texto = "Concealed Hand Crossbow (15.25 DPS, +12 RAP): Bazil Thredd, The Stockades.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 12:31
      { de = 22, ate = 29, texto = "Golem Site Long Gun (16.6 DPS, 6 agi): Relic Guardian, ultimo chefe da Wetlands Excavation.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 12:31
      { de = 28, ate = 43, texto = "Master Hunter's Rifle (19.42 DPS) ou arco (19.38 DPS, 6 agi): missao elite de Hemet Nesingwary; pegar no 28, solavel perto do 41, antes do 43.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 13:36
      { de = 29, ate = 39, texto = "Quillboar Blaster (18.57 DPS, 4 agi): missao Crown of the Kraul, Razorfen Kraul; comeca no diario de Henry Gloombrow (base do Great Lift).", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 13:04
      { de = 30, ate = 39, texto = "Fel Sever Crossbow (20.83 DPS, +8 AP, proc que interrompe): Arcanist Doan, biblioteca do Scarlet Monastery.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 14:09
      { de = 40, ate = 47, texto = "Truth Seeker's Bow (23.75 DPS, 7 agi): entregar 25 livros e documentos na Magus Tower de Stormwind.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 14:44
      { de = 42, ate = 47, texto = "Galgan's Fire Blaster (24.62 DPS, proc de fogo): Galgan Firehammer, Uldaman.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 15:18
      { de = 45, ate = 48, texto = "Verdant Keeper's Aim (27.32 DPS): missao de Maraudon; Corruption of Earth and Seed com Keeper Marandis, norte de Desolace.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 15:51
      { de = 47, ate = 55, texto = "Thorium Rifle (BoE): Engineering 260 ou leilao.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 16:57
      { de = 48, ate = 60, texto = "Mega Shot Rifle (27.4 DPS, +19 RAP): Tinker Gizlock, Maraudon.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 15:51
      { de = 48, ate = 60, texto = "Blackcrow (30.31 DPS, 3 agi, +0.9% crit): Shadow Hunter Vosh'gajin, Blackrock Spire; leva ate o 60.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 16:24
      { de = 56, ate = 60, texto = "Flawless Arcanite Rifle (31.17 DPS, 9 sta, +10 RAP; BoE): Engineering 300 ou leilao.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 18:04
    },
    pets = {
      { de = 1, ate = 60, texto = "No Night Elf, nightsaber com Bite.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:23
      { de = 1, ate = 10, texto = "Teldrassil: nightsaber (1,4 s, nivel 5) ou javali como tanque.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:41
      { de = 1, ate = 10, texto = "Elwynn: prowler (Bite 2 aprendido no 9 ou 10, 1,5 s).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:41
      { de = 1, ate = 10, texto = "Dun Morogh: javali Crag Boar (Charge cedo) ou o raro Ghostfang.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:41
      { de = 1, ate = 60, texto = "Pet herda 100% do crit do cacador.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:21
      { de = 1, ate = 60, texto = "Armadura herdada: confira no tooltip do pet (as fontes divergem).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:21
      { de = 1, ate = 60, texto = "Domar elite ou raro: Freezing Trap e Scare Beast.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:47
      { de = 1, ate = 60, texto = "Estabulo: primeiro espaco gratis, segundo por 10 prata, terceiro por 5 ouro.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:48
      { de = 1, ate = 60, texto = "No grupo, Growl desligado; Cower ligado para reduzir ameaca.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:50
      { de = 1, ate = 60, texto = "Pet infeliz da muito menos dano e pode fugir: alimentar com comida de taverna ou peixe.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:51
      { de = 1, ate = 60, texto = "Pontos de treino crescem com a lealdade (300 em best friend).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:51
      { de = 1, ate = 60, texto = "Broken Tooth e o pet mais rapido (1,0 s): proca mais Frenzy.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:53
      { de = 1, ate = 60, texto = "Uso leveling, dano: gato.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:32
      { de = 1, ate = 60, texto = "Uso leveling, tanque de alvo unico: javali (Charge segura a ameaca).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:33
      { de = 1, ate = 60, texto = "Uso survival: lobo (Furious Howl, grito de batalha para o cacador).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:34
      { de = 1, ate = 60, texto = "Elite muito pesado, solo: tartaruga (Shell Shield, -50% de dano recebido).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:35
      { de = 1, ate = 60, texto = "Farm em area: urso (Swipe em 3 alvos, recarga de 5 s).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:36
      { de = 1, ate = 60, texto = "Equilibrado: aranha (Web prende 4 s).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:37
      { de = 1, ate = 60, texto = "PvE de fim de jogo: gato, depois raptor.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:38
      { de = 1, ate = 60, texto = "PvP contra caster: morcego.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:39
      { de = 1, ate = 60, texto = "PvP contra healer: crocolisk (Dismember).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:39
      { de = 1, ate = 60, texto = "PvP contra corpo a corpo: aranha ou ave de rapina.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:39
      { de = 1, ate = 60, texto = "PvP no Night Elf: gato com Prowl.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:39
      { de = 10, ate = 10, texto = "Domar o primeiro pet (Call Pet).", fonte = "Method" },  -- origem: hexumlite-bull.md:96
      { de = 10, ate = 10, texto = "Growl ligado no pet.", fonte = "Method" },  -- origem: hexumlite-bull.md:96
      { de = 10, ate = 10, texto = "Great Stamina e Natural Armor treinados no pet.", fonte = "Method" },  -- origem: hexumlite-bull.md:96
      { de = 10, ate = 10, texto = "Pegar pet com focus dump no 10.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:23
      { de = 10, ate = 16, texto = "Darkshore: Moonstalker (1,3 s), ensina Cower.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:41
      { de = 17, ate = 17, texto = "Darkshore: Moonstalker Sire no 17.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:41
      { de = 30, ate = 30, texto = "Dash do pet, aprendido por Wild Taming: dome um pet que saiba Dash.", fonte = "Method" },  -- origem: hexumlite-bull.md:104
    },
    rotacao = {
      { de = 1, ate = 4, texto = "Matar mobs da zona inicial ate o 4 e fazer melee weave.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:25
      { de = 1, ate = 60, texto = "Auto Shot e grande parte do dano.", fonte = "Method" },  -- origem: hexumlite-bull.md:107
      { de = 1, ate = 60, texto = "Se estiver puxando o aggro do pet, deixe o pet bater alguns golpes antes.", fonte = "Method" },  -- origem: hexumlite-bull.md:107
      { de = 1, ate = 60, texto = "Desde 03/11 todas as armadilhas dividem 30 s de recarga: usar a Immolation trava Freezing e Frost.", fonte = "Method" },  -- origem: hexumlite-bull.md:103
      { de = 16, ate = 40, texto = "Segundo mob: Serpent Sting com Immolation Trap e corpo a corpo.", fonte = "MetaGoblin (beta)" },  -- origem: metagoblin-hunter.md:24
      { de = 16, ate = 60, texto = "Immolation Trap, opcao 1: a Method nao a poe na rotacao; Freezing Trap (20) e Frost Trap (28) aparecem como controle e lentidao.", fonte = "Method" },  -- origem: hexumlite-bull.md:99-103 (escolha do dono: as duas orientacoes)
      { de = 16, ate = 60, texto = "Immolation Trap, opcao 2: Raptor Strike junto com Immolation Trap.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:25
      { de = 25, ate = 60, texto = "Hawk, Immolation Trap, Hawk de novo.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:25
      { de = 25, ate = 60, texto = "Serpent Sting em luta longa.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:25
      { de = 25, ate = 60, texto = "Multi-Shot em grupo.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:25
      { de = 25, ate = 60, texto = "Aimed Shot e Rapid Fire em chefe.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:25
      { de = 30, ate = 30, texto = "Intimidation.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:25
    },
    atributos = {
      { texto = "Ate o 45: Agility (pecas azuis de Leatherworking desde o 10). Spirit vale pouco para cacador.", fonte = "Method" },  -- origem: hexumlite-bull.md:80 (decisao do dono 2026-11-05)
      { texto = "Do 46 em diante, com o Careful Aim: Intellect e Spirit (o talento converte Intellect em attack power).", fonte = "MetaGoblin (beta)" },  -- origem: metagoblin-hunter.md:22
    },
    notas = {
      { texto = "Subir de rank sempre que puder.", fonte = "Method" },  -- origem: hexumlite-bull.md:85
      { texto = "Armadilhas dividem 30 s de recarga desde 03/11.", fonte = "Method" },  -- origem: hexumlite-bull.md:103
    },
  },
  SHAMAN = {
    personagem = "Rurik Thunderfist",
    magias = {   -- em ordem crescente de nivel
      { nivel = 10, texto = "Searing Totem.", fonte = "Method" },  -- origem: rurik-thunderfist.md:129
      { nivel = 12, texto = "Fire Nova: so com mana sobrando; a ameaca vai para voce.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:76
      { nivel = 20, texto = "Ghost Wolf (40% de velocidade).", fonte = "Method" },  -- origem: rurik-thunderfist.md:131
      { nivel = 20, texto = "Water Shield: sempre.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:73
      { nivel = 20, texto = "Lightning Shield: so com mana cheia entre puxadas.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:73
      { nivel = 26, texto = "Magma Totem: quase nunca no leveling.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:75
      { nivel = 30, texto = "Respec no treinador: pede boa arma de duas maos.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:54
      { nivel = 30, texto = "Stormstrike (talento, no respec).", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:54
      { nivel = 32, texto = "Windfury Totem, para o grupo.", fonte = "Method" },  -- origem: rurik-thunderfist.md:135
      { nivel = 46, texto = "Maelstrom Weapon: so vale para Lightning Bolt; soltar com 5 cargas.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:78
      { nivel = 51, texto = "Rage of the Farseer: Bloodlust so seu, com velocidade de ataque.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:44
    },
    armas = {
      { de = 1, ate = 29, texto = "Uma mao e escudo ate o Stormstrike.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:71
      { de = 1, ate = 60, texto = "Uma mao e escudo na bolsa, com macro de troca, para puxadas que dao errado.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:71
      { de = 1, ate = 60, texto = "Rockbiter, Flametongue e Windfury parecidos; Frostbrand atras; usar o rank mais novo.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:72
      { de = 30, ate = 60, texto = "Depois do Stormstrike, arma de duas maos, a mais lenta possivel; DPS da arma acima de tudo.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:71
    },
    pets = {},
    rotacao = {
      { de = 1, ate = 60, texto = "Um ou dois Lightning Bolt, depois Flame Shock; sem Flame Shock, Earth Shock antes.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:74
      { de = 1, ate = 60, texto = "Depois, corpo a corpo e Stormstrike na recarga.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:74
      { de = 1, ate = 60, texto = "Com Shamanistic Focus ou mana alta, Earth Shock na recarga.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:74
      { de = 1, ate = 60, texto = "Searing Totem e o mais eficiente.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:75
      { de = 1, ate = 60, texto = "Num grupo de mobs, plantar os totens no centro e puxar os mobs ate eles.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:75
      { de = 1, ate = 60, texto = "Stoneclaw Totem segura dois mobs enquanto voce mata o primeiro.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:76
      { de = 1, ate = 60, texto = "Fire Nova so quando sobra mana (gera ameaca para voce, entao deixe o Stoneclaw pulsar antes).", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:76
    },
    atributos = {
      { texto = "DPS da arma > Intellect > Stamina e Spirit > spell damage > Agility > Strength.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:61
    },
    notas = {
      { texto = "Earth Shock rank 1 na barra para interromper sem mana.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:74
      { texto = "Healing Wave, nunca Lesser: rank maximo e um 2 ou 3 abaixo na barra.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:77
      { texto = "Cadeia de totens de agua feita aos poucos, durante o leveling.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:79
      { texto = "Ghost Wolf em trecho longo sem mobs; com mobs no caminho, ir matando enquanto anda.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:80
    },
  },
}
