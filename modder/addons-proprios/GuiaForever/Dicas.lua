-- Dicas do GuiaForever por nivel: so dados, sem logica.
-- Fontes e decisoes do dono em 2026-11-05 (fichas em comum\personagens\).
GuiaForeverDicas = {
  HUNTER = {
    personagem = "Hexumlite Bull",
    magias = {   -- em ordem crescente de nivel
      { nivel = 1, texto = "No pet: maximize Auto Shot.", fonte = "Method" },  -- origem: hexumlite-bull.md:95
      { nivel = 4, texto = "Serpent Sting when the target won't die quickly.", fonte = "Method" },  -- origem: hexumlite-bull.md:95
      { nivel = 6, texto = "Arcane Shot.", fonte = "Method" },  -- origem: hexumlite-bull.md:95
      { nivel = 6, texto = "Hunter's Mark.", fonte = "Method" },  -- origem: hexumlite-bull.md:95
      { nivel = 8, texto = "Concussive Shot to slow and kite.", fonte = "Method" },  -- origem: hexumlite-bull.md:95
      { nivel = 10, texto = "Keep Aspect of the Hawk on whenever you fight.", fonte = "Method" },  -- origem: hexumlite-bull.md:96
      { nivel = 12, texto = "Mend Pet, for high-level elites.", fonte = "Method" },  -- origem: hexumlite-bull.md:97
      { nivel = 18, texto = "Multi-Shot: AoE; shares its cooldown with Aimed Shot.", fonte = "Method" },  -- origem: hexumlite-bull.md:98
      { nivel = 20, texto = "Aimed Shot: single target, 2 s cast.", fonte = "Method" },  -- origem: hexumlite-bull.md:99
      { nivel = 20, texto = "Aspect of the Cheetah: always out of combat when unmounted.", fonte = "Method" },  -- origem: hexumlite-bull.md:99
      { nivel = 20, texto = "Freezing Trap.", fonte = "Method" },  -- origem: hexumlite-bull.md:99
      { nivel = 24, texto = "Track Hidden.", fonte = "Method" },  -- origem: hexumlite-bull.md:100
      { nivel = 25, texto = "Summon Hawk (talent, new in Forever): keep 2 hawks and your pet out at all times.", fonte = "Method" },  -- origem: hexumlite-bull.md:101
      { nivel = 25, texto = "Hawks last 18 s: recast only in the last second.", fonte = "Method" },  -- origem: hexumlite-bull.md:101
      { nivel = 25, texto = "Summon Hawk shares a 6 s cooldown with Arcane Shot.", fonte = "Method" },  -- origem: hexumlite-bull.md:101
      { nivel = 25, texto = "After 25, Arcane Shot only in long single-target fights (one every 3 casts).", fonte = "Method" },  -- origem: hexumlite-bull.md:101
      { nivel = 26, texto = "Rapid Fire (5 min cooldown).", fonte = "Method" },  -- origem: hexumlite-bull.md:102
      { nivel = 28, texto = "Frost Trap: 60% slow in an area.", fonte = "Method" },  -- origem: hexumlite-bull.md:103
      { nivel = 30, texto = "Intimidation (talent); also works as the pet's taunt.", fonte = "Method" },  -- origem: hexumlite-bull.md:104
      { nivel = 30, texto = "Feign Death (can resist).", fonte = "Method" },  -- origem: hexumlite-bull.md:104
      { nivel = 30, texto = "Pet Dash, learned through Wild Taming: tame a pet that knows Dash and use it in combat until the spell-learned message.", fonte = "Method" },  -- origem: hexumlite-bull.md:104
      { nivel = 40, texto = "Bestial Wrath (talent).", fonte = "Method" },  -- origem: hexumlite-bull.md:105
    },
    armas = {
      { de = 1, ate = 10, texto = "Night Elf: white bow (3.81 DPS) from the Crown of the Earth chain, 7 quests, starts at Tenaron's Summons (Teldrassil).", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 03:47
      { de = 3, ate = 16, texto = "Vendor bows and guns at levels 3, 11, 14 and 16; the ranged weapon matters less than it seems.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:26
      { de = 11, ate = 20, texto = "Daryl's Hunting Bow (5.87 DPS, 1 agi) or Rifle (6.4 DPS): Daryl the Youngling quest, Loch Modan; 15 min timer, best near 14.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 06:29
      { de = 13, ate = 20, texto = "Calibrated Blunderbuss (9.57 DPS, 3 sta): Old Ironforge Incursion quest (Earthseer Pharsone, east Dun Morogh), Hall of Thanes dungeon.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 05:56
      { de = 13, ate = 20, texto = "For the Calibrated quest: Dark Iron Map, dropped by Dark Iron scouts and spies in east Dun Morogh.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 06:29
      { de = 16, ate = 20, texto = "Deadly Blunderbuss (8.27 DPS, 2 agi): Engineering 105 or auction house.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 07:03
      { de = 17, ate = 20, texto = "Owl Sight Rifle (7.88 DPS, 2 agi): The Sleeper Has Awakened escort (Kerlonian Evershade), Darkshore to Ashenvale.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 07:36
      { de = 17, ate = 22, texto = "Impaling Harpoon (9 agi, 5 int): Captain Greenskin, Deadmines.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 10:23
      { de = 19, ate = 22, texto = "Venom Strike (12.08 DPS, poison): Lord Serpentis, Wailing Caverns; the best until 22.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 10:55
      { de = 22, ate = 29, texto = "Raptor's End (12.07 DPS, 2 agi, 2 sta): 3-quest chain from Oromar, Wetlands; pick up at 22, finish before 29.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 11:26
      { de = 22, ate = 29, texto = "Naga Heartpiercer (13.33 DPS; hits for 42 and stuns naga): Lady Sarevess, second boss of Blackfathom Deeps.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 11:59
      { de = 22, ate = 29, texto = "Concealed Hand Crossbow (15.25 DPS, +12 RAP): Bazil Thredd, The Stockades.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 12:31
      { de = 22, ate = 29, texto = "Golem Site Long Gun (16.6 DPS, 6 agi): Relic Guardian, last boss of the Wetlands Excavation.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 12:31
      { de = 28, ate = 43, texto = "Master Hunter's Rifle (19.42 DPS) or bow (19.38 DPS, 6 agi): Hemet Nesingwary elite quest; pick up at 28, soloable near 41, before 43.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 13:36
      { de = 29, ate = 39, texto = "Quillboar Blaster (18.57 DPS, 4 agi): Crown of the Kraul quest, Razorfen Kraul; starts at Henry Gloombrow's journal (Great Lift base).", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 13:04
      { de = 30, ate = 39, texto = "Fel Sever Crossbow (20.83 DPS, +8 AP, interrupting proc): Arcanist Doan, Scarlet Monastery library.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 14:09
      { de = 40, ate = 47, texto = "Truth Seeker's Bow (23.75 DPS, 7 agi): turn in 25 books and documents at the Magus Tower in Stormwind.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 14:44
      { de = 42, ate = 47, texto = "Galgan's Fire Blaster (24.62 DPS, fire proc): Galgan Firehammer, Uldaman.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 15:18
      { de = 45, ate = 48, texto = "Verdant Keeper's Aim (27.32 DPS): Maraudon quest; Corruption of Earth and Seed with Keeper Marandis, north Desolace.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 15:51
      { de = 47, ate = 55, texto = "Thorium Rifle (BoE): Engineering 260 or auction house.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 16:57
      { de = 48, ate = 60, texto = "Mega Shot Rifle (27.4 DPS, +19 RAP): Tinker Gizlock, Maraudon.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 15:51
      { de = 48, ate = 60, texto = "Blackcrow (30.31 DPS, 3 agi, +0.9% crit): Shadow Hunter Vosh'gajin, Blackrock Spire; carries you to 60.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 16:24
      { de = 56, ate = 60, texto = "Flawless Arcanite Rifle (31.17 DPS, 9 sta, +10 RAP; BoE): Engineering 300 or auction house.", fonte = "Gladius (beta)" },  -- origem: transcricao Gladius J1kDM4QI3Ks 18:04
    },
    pets = {
      { de = 1, ate = 60, texto = "As a Night Elf, a nightsaber with Bite.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:23
      { de = 1, ate = 10, texto = "Teldrassil: nightsaber (1.4 s, level 5) or boar as a tank.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:41
      { de = 1, ate = 10, texto = "Elwynn: prowler (Bite 2 learned at 9 or 10, 1.5 s).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:41
      { de = 1, ate = 10, texto = "Dun Morogh: Crag Boar (early Charge) or the rare Ghostfang.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:41
      { de = 1, ate = 60, texto = "Pet inherits 100% of the hunter's crit.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:21
      { de = 1, ate = 60, texto = "Inherited armor: check the pet tooltip (sources disagree).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:21
      { de = 1, ate = 60, texto = "Taming an elite or rare: Freezing Trap and Scare Beast.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:47
      { de = 1, ate = 60, texto = "Stable: first slot free, second for 10 silver, third for 5 gold.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:48
      { de = 1, ate = 60, texto = "In a group, Growl off; Cower on to reduce threat.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:50
      { de = 1, ate = 60, texto = "An unhappy pet does much less damage and may run away: feed it tavern food or fish.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:51
      { de = 1, ate = 60, texto = "Training points grow with loyalty (300 at best friend).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:51
      { de = 1, ate = 60, texto = "Broken Tooth is the fastest pet (1.0 s): procs Frenzy more.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:53
      { de = 1, ate = 60, texto = "Leveling, damage: cat.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:32
      { de = 1, ate = 60, texto = "Leveling, single-target tank: boar (Charge holds threat).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:33
      { de = 1, ate = 60, texto = "Survival use: wolf (Furious Howl, a battle shout for the hunter).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:34
      { de = 1, ate = 60, texto = "Very heavy elite, solo: turtle (Shell Shield, -50% damage taken).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:35
      { de = 1, ate = 60, texto = "Area farming: bear (Swipe hits 3 targets, 5 s cooldown).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:36
      { de = 1, ate = 60, texto = "Balanced: spider (Web roots for 4 s).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:37
      { de = 1, ate = 60, texto = "Endgame PvE: cat, then raptor.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:38
      { de = 1, ate = 60, texto = "PvP vs casters: bat.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:39
      { de = 1, ate = 60, texto = "PvP vs healers: crocolisk (Dismember).", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:39
      { de = 1, ate = 60, texto = "PvP vs melee: spider or bird of prey.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:39
      { de = 1, ate = 60, texto = "PvP as a Night Elf: cat with Prowl.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:39
      { de = 10, ate = 10, texto = "Tame your first pet (Call Pet).", fonte = "Method" },  -- origem: hexumlite-bull.md:96
      { de = 10, ate = 10, texto = "Turn Growl on for the pet.", fonte = "Method" },  -- origem: hexumlite-bull.md:96
      { de = 10, ate = 10, texto = "Train Great Stamina and Natural Armor on the pet.", fonte = "Method" },  -- origem: hexumlite-bull.md:96
      { de = 10, ate = 10, texto = "Get a pet with a focus dump at 10.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:23
      { de = 10, ate = 16, texto = "Darkshore: Moonstalker (1.3 s), teaches Cower.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:41
      { de = 17, ate = 17, texto = "Darkshore: Moonstalker Sire at 17.", fonte = "LudiDeo (beta)" },  -- origem: ludideo-hunter-pets.md:41
      { de = 30, ate = 30, texto = "Pet Dash, learned through Wild Taming: tame a pet that knows Dash.", fonte = "Method" },  -- origem: hexumlite-bull.md:104
    },
    rotacao = {
      { de = 1, ate = 4, texto = "Kill starting-zone mobs until 4 and melee weave.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:25
      { de = 1, ate = 60, texto = "Auto Shot is a big part of your damage.", fonte = "Method" },  -- origem: hexumlite-bull.md:107
      { de = 1, ate = 60, texto = "If you are pulling the pet's aggro, let the pet land a few hits first.", fonte = "Method" },  -- origem: hexumlite-bull.md:107
      { de = 1, ate = 60, texto = "Since 11/03 all traps share a 30 s cooldown: using Immolation locks Freezing and Frost.", fonte = "Method" },  -- origem: hexumlite-bull.md:103
      { de = 16, ate = 40, texto = "Second mob: Serpent Sting with Immolation Trap and melee.", fonte = "MetaGoblin (beta)" },  -- origem: metagoblin-hunter.md:24
      { de = 16, ate = 60, texto = "Immolation Trap, option 1: Method leaves it out of the rotation; Freezing Trap (20) and Frost Trap (28) appear as control and slow.", fonte = "Method" },  -- origem: hexumlite-bull.md:99-103 (escolha do dono: as duas orientacoes)
      { de = 16, ate = 60, texto = "Immolation Trap, option 2: Raptor Strike together with Immolation Trap.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:25
      { de = 25, ate = 60, texto = "Hawk, Immolation Trap, Hawk again.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:25
      { de = 25, ate = 60, texto = "Serpent Sting in long fights.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:25
      { de = 25, ate = 60, texto = "Multi-Shot on groups.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:25
      { de = 25, ate = 60, texto = "Aimed Shot and Rapid Fire on bosses.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:25
      { de = 30, ate = 30, texto = "Intimidation.", fonte = "Kargoz (beta)" },  -- origem: kargoz-hunter-bm.md:25
    },
    atributos = {
      { texto = "Up to 45: Agility (blue Leatherworking pieces from 10). Spirit is worth little for a hunter.", fonte = "Method" },  -- origem: hexumlite-bull.md:80 (decisao do dono 2026-11-05)
      { texto = "From 46 on, with Careful Aim: Intellect and Spirit (the talent converts Intellect into attack power).", fonte = "MetaGoblin (beta)" },  -- origem: metagoblin-hunter.md:22
    },
    notas = {
      { texto = "Rank up whenever you can.", fonte = "Method" },  -- origem: hexumlite-bull.md:85
      { texto = "Traps share a 30 s cooldown since 11/03.", fonte = "Method" },  -- origem: hexumlite-bull.md:103
    },
  },
  SHAMAN = {
    personagem = "Rurik Thunderfist",
    magias = {   -- em ordem crescente de nivel
      { nivel = 10, texto = "Searing Totem.", fonte = "Method" },  -- origem: rurik-thunderfist.md:129
      { nivel = 12, texto = "Fire Nova: only with spare mana; the threat goes to you.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:76
      { nivel = 20, texto = "Ghost Wolf (40% speed).", fonte = "Method" },  -- origem: rurik-thunderfist.md:131
      { nivel = 20, texto = "Water Shield: always.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:73
      { nivel = 20, texto = "Lightning Shield: only with full mana between pulls.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:73
      { nivel = 26, texto = "Magma Totem: almost never while leveling.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:75
      { nivel = 30, texto = "Respec at the trainer: needs a good two-handed weapon.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:54
      { nivel = 30, texto = "Stormstrike (talent, from the respec).", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:54
      { nivel = 32, texto = "Windfury Totem, for the group.", fonte = "Method" },  -- origem: rurik-thunderfist.md:135
      { nivel = 46, texto = "Maelstrom Weapon: only worth it for Lightning Bolt; release at 5 stacks.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:78
      { nivel = 51, texto = "Rage of the Farseer: Bloodlust for you alone, with attack speed.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:44
    },
    armas = {
      { de = 1, ate = 29, texto = "One-hander and shield until Stormstrike.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:71
      { de = 1, ate = 60, texto = "Keep a one-hander and shield in your bags, with a swap macro, for pulls that go wrong.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:71
      { de = 1, ate = 60, texto = "Rockbiter, Flametongue and Windfury are similar; Frostbrand is behind; use the newest rank.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:72
      { de = 30, ate = 60, texto = "After Stormstrike, a two-hander, the slowest possible; weapon DPS above all.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:71
    },
    pets = {},
    rotacao = {
      { de = 1, ate = 60, texto = "One or two Lightning Bolts, then Flame Shock; without Flame Shock, Earth Shock first.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:74
      { de = 1, ate = 60, texto = "Then melee and Stormstrike on cooldown.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:74
      { de = 1, ate = 60, texto = "With Shamanistic Focus or high mana, Earth Shock on cooldown.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:74
      { de = 1, ate = 60, texto = "Searing Totem is the most efficient.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:75
      { de = 1, ate = 60, texto = "On a group of mobs, plant the totems in the middle and pull the mobs to them.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:75
      { de = 1, ate = 60, texto = "Stoneclaw Totem holds two mobs while you kill the first.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:76
      { de = 1, ate = 60, texto = "Fire Nova only with spare mana (it generates threat on you, so let Stoneclaw pulse first).", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:76
    },
    atributos = {
      { texto = "Weapon DPS > Intellect > Stamina and Spirit > spell damage > Agility > Strength.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:61
    },
    notas = {
      { texto = "Earth Shock rank 1 on the bar to interrupt without mana.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:74
      { texto = "Healing Wave, never Lesser: max rank and one 2 or 3 ranks below on the bar.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:77
      { texto = "Build the water totem chain bit by bit while leveling.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:79
      { texto = "Ghost Wolf on long stretches without mobs; with mobs on the way, kill them as you go.", fonte = "DoubleZug" },  -- origem: doublezug-shaman.md:80
    },
  },
}
