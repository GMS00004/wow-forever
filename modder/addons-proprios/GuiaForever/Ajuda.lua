-- GuiaForever: perguntas e respostas da aba Help, so dados (tarefa C2; contrato em
-- ARQUITETURA.md, secao 7). Cada linha cita a fonte; o comentario de origem aponta a ficha.
-- Origem: jogadores\bruno\personagens\hexumlite-bull.md (ficha, numero da linha) e as fontes em
-- comum\fontes\ (numero da linha). "you" = decisao do dono registrada na ficha.

GuiaForeverAjuda = {
  HUNTER = {
    { id = "unhappy", aba = "pet", pergunta = "My pet is Unhappy. What now?", linhas = {
      -- origem: comum\fontes\builds\ludideo-hunter-pets.md:51 (felicidade e lealdade)
      { texto = "Unhappy pets do much less damage and can run away.", fonte = "LudiDeo (beta)" },
      -- origem: comum\fontes\builds\ludideo-hunter-pets.md:51; ficha jogadores\bruno\personagens\hexumlite-bull.md:152
      { texto = "Feed it tavern food (bread, cheese, fruit), or fish if you fish. Feed Pet is not learned yet (question 3).", fonte = "LudiDeo (beta)" },
    } },
    { id = "comida", aba = "pet", pergunta = "What does my pet eat, and where do I buy food?", linhas = {
      -- origem: comum\fontes\builds\ludideo-hunter-pets.md:51 (comida de taverna e peixe)
      { texto = "Tavern food (bread, cheese, fruit), and fish if you fish.", fonte = "LudiDeo (beta)" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:152 (o que o gato come: nao conferido)
      { texto = "What a cat eats on Forever (not checked).", fonte = "you" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:152 (sem resposta na ficha nem nas fontes)
      { texto = "Where to buy it: not in your sources yet.", fonte = "you" },
    } },
    { id = "feed", aba = "pet", pergunta = "Why don't I have Feed Pet yet?", linhas = {
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:152 (Naowh marca como magia de quest do 10)
      { texto = "The Naowh planner marks Feed Pet as a quest spell from level 10.", fonte = "Naowh" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:152 (de qual quest vem: nao conferido)
      { texto = "Which quest gives it: not checked yet.", fonte = "Naowh" },
    } },
    { id = "treino", aba = "pet", pergunta = "Where do I train my pet, and what should I train?", linhas = {
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:152 (Onde: pelo RestedXP)
      { texto = "Training the Beast is turned in to Jocaste, in Darnassus. Pet trainer: Silvaria, up the ramp on the right.", fonte = "RestedXP" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:101 (nivel 10)
      { texto = "At level 10: Growl on, with Great Stamina and Natural Armor trained.", fonte = "Method" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:102 (nivel 12)
      { texto = "At level 12: Mend Pet, from the hunter trainer (for high-level elites).", fonte = "Method" },
    } },
    { id = "growl", aba = "pet", pergunta = "Should Growl autocast be on?", linhas = {
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:101 (Growl ligado no 10)
      { texto = "Solo: yes, keep Growl on (from level 10).", fonte = "Method" },
      -- origem: comum\fontes\builds\ludideo-hunter-pets.md:50 (autocast, no grupo)
      { texto = "In a group: Growl off and Cower on, to cut threat.", fonte = "LudiDeo (beta)" },
    } },
    { id = "claw2", aba = "pet", pergunta = "How does my pet learn Claw 2?", linhas = {
      -- origem: comum\fontes\builds\ludideo-hunter-pets.md:52 (treino de habilidade de pet selvagem)
      { texto = "Tame a wild pet that already knows the ability (the teacher).", fonte = "LudiDeo (beta)" },
      -- origem: comum\fontes\builds\ludideo-hunter-pets.md:52
      { texto = "Stable your main pet first, turn off the teacher's other abilities, and fight until it learns.", fonte = "LudiDeo (beta)" },
      -- origem: comum\fontes\builds\saltii-hunter-pets.md (cartao 12, Claw ranks 1 to 8), 2026-11-08
      { texto = "Teacher: Strigid Hunter (8-9, Teldrassil); the pet needs level 8.", fonte = "Saltii" },
      { texto = "Every rank and its teachers: J > Families, and Next ability upgrades in the Pet tab.", fonte = "Saltii" },
    } },
    { id = "proximorank", aba = "pet", pergunta = "When does my pet need a higher-level beast for a rank?", linhas = {
      -- origem: comum\fontes\builds\saltii-hunter-pets.md (cartoes 11, 12 e 14) e ludideo-hunter-pets.md:52
      { texto = "Never a new pet: you tame a teacher beast, learn the rank, let it go and teach your own pet.", fonte = "LudiDeo (beta)" },
      { texto = "Each rank has a pet level (Bite and Claw: 1, 8, 16, 24, 32, 40, 48, 56) and a teacher level.", fonte = "Saltii" },
      { texto = "The Pet tab lists the next rank of each ability and the teachers you can tame now.", fonte = "Saltii" },
    } },
    { id = "talento", aba = "talentos", pergunta = "Which talent now, and what is still open?", linhas = {
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:60 e :82 (lei das tres builds)
      { texto = "Now (10-14): Deadly Aspects 5/5, the same in all three builds (your rule).", fonte = "you" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:77 (decisao do dono, Kargoz)
      { texto = "15-19 (your pick): Focused Fire 2/2, Improved Revive Pet 1, Endurance Training 2.", fonte = "Kargoz (beta)" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:82 (lei das tres builds)
      { texto = "20-21: Pathfinding 2/2, the same in all three builds (your rule).", fonte = "you" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:64-70 (divergencias ainda abertas)
      { texto = "Still open: Unleashed Fury, Bestial Discipline, Spirit Bond, Monkey, Frenzy, and picks after 40.", fonte = "you" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:17 (status provisorio)
      { texto = "The whole build is provisional until you confirm it.", fonte = "you" },
    } },
    { id = "mend", aba = "combate", pergunta = "When does Mend Pet come, and on which key?", linhas = {
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:102
      { texto = "Mend Pet comes at level 12, for high-level elites.", fonte = "Method" },
      -- origem: modder\addons-proprios\GuiaForever\Teclas.lua:30 (tecla R)
      { texto = "Key R (pet_AllInOne): no pet = Call Pet, dead pet = Revive Pet, live pet = Mend Pet from 12.", fonte = "leak" },
    } },
    { id = "alvos", aba = "combate", pergunta = "One mob at a time or two with the pet?", linhas = {
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:129 (um por vez, Method)
      { texto = "Not decided by you yet. Option A: one mob at a time, mostly from range.", fonte = "Method" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:130 (dois por vez, MetaGoblin)
      { texto = "Option B: two at once, the pet holds the first. Riskier and faster.", fonte = "MetaGoblin (beta)" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:136-140 (tecla 5 desfaz a divisao)
      { texto = "Key 5 sends the pet on the target you mark, which undoes a two-mob split.", fonte = "you" },
    } },
    { id = "mark5", aba = "combate", pergunta = "Which Hunter's Mark macro is on key 5?", linhas = {
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:140 (troca de 2026-11-06)
      { texto = "Key 5 is mark_Conc, your pick on 2026-11-06 (built without a video source).", fonte = "you" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:140 (primeiro aperto = mark_Pet do leak)
      { texto = "First press on a new target: Hunter's Mark and sends the pet (from 10).", fonte = "leak" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:140; Teclas.lua:24
      { texto = "Next presses: Concussive Shot when ready (from 8).", fonte = "you" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:120 (Hunter's Mark a partir do 6)
      { texto = "Before level 10 it is only Hunter's Mark, from level 6.", fonte = "MetaGoblin (beta)" },
    } },
    { id = "atributos", aba = "combate", pergunta = "Which stats matter on my gear?", linhas = {
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:80 (decisao do dono, ate o 45)
      { texto = "Up to 45 (your pick): Agility. Leatherworking blues with lots of Agility raise DPS a lot.", fonte = "you" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:80 (decisao do dono, do 46)
      { texto = "From 46 (your pick): Intellect and Spirit, since Careful Aim turns Intellect into attack power.", fonte = "MetaGoblin (beta)" },
    } },
    { id = "prof", aba = "profissoes", pergunta = "How far should I level Skinning and Leatherworking here?", linhas = {
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:160 (decididas pelo dono)
      { texto = "You chose Leatherworking and Skinning (2026-11-04); Cooking and First Aid are secondary.", fonte = "you" },
      -- origem: comum\fontes\profissoes\reptilio-leatherworking.md (Merchant's Favor; desde 2026-11-13
      -- substitui a linha da Method "blue Agility gear from level 10", que divergia do nivel 12)
      { texto = "Your first blue Leatherworking pieces are the Merchant's Favor belts: skill 60, level 12 to wear, 30 Favor each.", fonte = "ReptilioPlays" },
      -- origem: jogadores\bruno\estado\estado.md, alteracao de 2026-11-06 (GuiaForever 0.6.0: metas aprovadas pelo dono) e Dados.lua (GuiaForeverRastreador);
      -- LW 125 em 20-30 desde 2026-11-13 (rota do ReptilioPlays: Heavy Hide a partir do 125)
      { texto = "Your goals by area: levels 1-10 Skinning 75 and Leatherworking 75; 10-20 Skinning 125, LW 100; 20-30 Skinning 150, LW 125.", fonte = "you" },
      -- origem: Dados.lua (GuiaForeverRastreador); a ligacao zona -> faixa e do agente, a conferir
      { texto = "The tracker under the minimap shows your skill against the goal of this area (zone mapping not checked).", fonte = "you" },
    } },
    { id = "rota", aba = "ajuda", pergunta = "How do I follow the route when Questie disagrees?", linhas = {
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:94 (Questie x RestedXP)
      { texto = "When Questie and RestedXP disagree, follow RestedXP.", fonte = "RestedXP" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:94 (seguir a rota a risca)
      { texto = "Follow the route to the letter: its quest order lands the XP on time.", fonte = "RestedXP" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:94 (seta e janela do passo)
      { texto = "The arrow at the top and the step window show the next step; it advances by itself.", fonte = "RestedXP" },
      -- origem: modder\addons-proprios\GuiaForever\Teclas.lua:54 (tecla V)
      { texto = "Key V (RXPTargeting) targets the NPC or mob of the current step.", fonte = "RestedXP" },
      -- origem: jogadores\bruno\personagens\hexumlite-bull.md:94 (fora da rota)
      { texto = "Off the route, click the right step in the list above.", fonte = "RestedXP" },
    } },
  },
  -- Paladino (Ignatius Stonejaw): perguntas tiradas da ficha jogadores\bruno\personagens\ignatius-stonejaw.md;
  -- cada linha leva a linha da ficha (ou do arquivo da fonte) em "origem".
  PALADIN = {
    { id = "prot-quando", aba = "talentos", pergunta = "When do I switch to Protection, and when do I get a shield?", linhas = {
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:86 (decisao 1 do dono: Prot no 22)
      { texto = "Protection from 22, your pick: Redoubt 5/5, with a one-hander and shield.", fonte = "you" },
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:45 (duas maos ate o 21; Deadmanfred)
      { texto = "Two-hander until 21; from 22 a one-hander and shield, with the first Redoubt point.", fonte = "Deadmanfred" },
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:86 (coluna C: DPS ate o 40 e dual spec)
      { texto = "Other guides advise DPS until 40 and a tank dual spec; you chose 22 instead.", fonte = "Jurdi" },
    } },
    { id = "judge-agora", aba = "combate", pergunta = "How do I use Judgement now?", linhas = {
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:95 (Judgement fora do GCD, sem consumir o seal)
      { texto = "Judgement is off the GCD and does not use up the seal: press it whenever it is ready.", fonte = "Perfect Gaming Weather" },
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:95 (taunt a 10 jardas, 3 s)
      { texto = "With Seal of Fury, Judgement taunts for 3 s at up to 10 yards.", fonte = "Perfect Gaming Weather" },
    } },
    { id = "consecration", aba = "combate", pergunta = "How much should I use Consecration?", linhas = {
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:95 (moderacao; a fonte e a linha da ficha)
      { texto = "It costs a lot of mana: use it in moderation, and hold it when threat is already safe.", fonte = "Jurdi" },
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:105 (dano cheio nos quatro primeiros)
      { texto = "Full damage only on the first four enemies.", fonte = "Perfect Gaming Weather" },
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:106 (rank 2 no 30)
      { texto = "At 30, rank 2 costs almost double the mana, for a little more damage.", fonte = "DwarfLord (beta)" },
    } },
    { id = "selo-aura-bencao", aba = "agora", pergunta = "Which seal, aura and blessing do I use while leveling?", linhas = {
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:102 (Seal of Fury, tanque, do 10)
      { texto = "Seal of Fury all the time: it is the tank seal from 10.", fonte = "Perfect Gaming Weather" },
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:104 (Retribution Aura do 16)
      { texto = "Retribution Aura is the leveling aura from 16 on.", fonte = "Perfect Gaming Weather" },
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:111 (bencao de leveling do Prot)
      { texto = "Blessing of Kings is the leveling blessing for Protection.", fonte = "Perfect Gaming Weather" },
    } },
    { id = "nivel-12-20-40", aba = "agora", pergunta = "What do I do at 12, 20 and 40?", linhas = {
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:103 (quest de classe do 12)
      { texto = "At 12, do the class quest right away, in the Cathedral of Light (Redemption).", fonte = "Deadmanfred" },
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:105 (quest de classe do 20)
      { texto = "At 20, the Tome of Valor gives Bastion of Stormwind, a paladin shield.", fonte = "Perfect Gaming Weather" },
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:108 (montaria e dual spec no 40)
      { texto = "At 40, the mount and the dual spec open.", fonte = "Perfect Gaming Weather" },
    } },
    { id = "arma-atributos", aba = "combate", pergunta = "Which weapon and stats should I look for?", linhas = {
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:115 (arma: spell power e dano alto)
      { texto = "The weapon is the biggest jump: spell power and high damage. Rhahk'Zor's Hammer and Scepter of the Abandoned come first.", fonte = "Perfect Gaming Weather" },
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:115 (uma mao rapida, 1.5 a 1.8)
      { texto = "For Protection, a fast one-hander (1.5 to 1.8 speed) gives more Seal of Fury hits.", fonte = "Deadmanfred" },
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:119 (ordem de atributos do Prot)
      { texto = "For Protection, spell power comes first in the leveling order.", fonte = "Perfect Gaming Weather" },
    } },
    { id = "bolha-tecla", aba = "combate", pergunta = "Why does pressing the bubble key twice remove the bubble?", linhas = {
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:132-134 (macro de bolha e aviso do Jurdi)
      { texto = "The bubble macro casts Divine Shield and then cancels it, so a second press takes the bubble off.", fonte = "Jurdi" },
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:134 (aviso do Jurdi: mundo aberto)
      { texto = "Pressing it twice in the open world is risky: the bubble is gone.", fonte = "Jurdi" },
    } },
    { id = "duo-warlock", aba = "ajuda", pergunta = "What helps the tank and warlock duo?", linhas = {
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:148 (Curse of the Elements, so o DwarfLord fala)
      { texto = "Curse of the Elements from the warlock raises all magic damage, the holy damage of the paladin too.", fonte = "DwarfLord (beta)" },
      -- origem: jogadores\bruno\personagens\ignatius-stonejaw.md:148 (sem fonte para a dupla como tal: decisao do dono)
      { texto = "No source covers the tank and warlock duo as such.", fonte = "you" },
    } },
  },
}
