tema: builds
fonte: Gladius Gaming (YouTube), "DO THIS FIRST! Ultimate Hunter Guide: Talents, Weapons & Macros World of Warcraft Forever"
url: https://www.youtube.com/watch?v=J1kDM4QI3Ks
data: 2026-11-05
seguir: candidata para o Hexumlite Bull, trazida pelo dono em 2026-11-05, sobretudo pelas macros. Atenção: vídeo de 2026-11-02, um dia antes das mudanças de 03/11 (regra do dono: só vale build de 03/11 em diante), e a build é de solar dungeon com pet tanque, não de leveling rápido. Serve para cruzar, não para seguir ao pé da letra.

# Gladius Gaming: hunter BM para solar (macros, armas, talentos)

Vídeo de 43:40, publicado em 2026-11-02. A descrição aponta o guia escrito na Mobalytics (https://mobalytics.gg/wow-forever/profile/gladius-unhgst/classes/forever-solo-hunter), que devolve 403 a cliente automático; a sessão não o leu. A transcrição foi lida inteira pela sessão (legenda automática, baixada pelo yt-dlp) e não fica no repositório. As macros aparecem só na tela (25:30 a 28:40), não na fala: o texto delas entra aqui a partir dos prints do dono. Marca: `[página]` (transcrição e descrição).

## Macros (25:30 a 28:40)

Texto transcrito dos prints que o dono tirou da tela do vídeo em 2026-11-05 (a contagem de caracteres de cada print bate com o texto); o uso vem da fala. Marca: `[página]` (prints do vídeo). Ficam na aba de macros do personagem ("Gladius Specific Macros").

| Tempo | Nome | Texto | Uso, pela fala | Tecla dele |
|---|---|---|---|---|
| 25:30 | send_Pet | `/petattack` | manda o pet no alvo | roda do mouse para cima |
| 25:30 | pet_Return | `#showtooltip Dismiss Pet` / `/petfollow` | chama o pet de volta (o `#showtooltip` só empresta o ícone; não dispensa o pet) | roda do mouse para baixo |
| 25:50 | move_Here | `/petmoveto` | o cursor vira mira e o pet vai ao ponto clicado (tirar o pet do caminho de uma patrulha) | clique do meio |
| 26:11 | Hunter's Mark | `#showtooltip Hunter's Mark` / `/petpassive` / `/petfollow` / `/cast [@mouseover, harm][] Hunter's Mark` | marca o que está sob o mouse sem trocar de alvo; o print mostra que a macro também põe o pet em passivo e o chama de volta, coisa que a fala não diz | não diz |
| 26:25 | Taunt | `#showtooltip Growl` / `/cast Growl` | taunt manual do pet, para dividir a ameaça com ele na dungeon | não diz |
| 26:40 | Freezing Trap | `#showtooltip Freezing Trap` / `/petpassive` / `/cast Freezing Trap` | o pet larga o mob e volta, o mob vem atrás e cai na armadilha, e o pet não a quebra | não diz |
| 27:10 | eagle_Eye | `#showtooltip eagle eye` / `/cast !eagle eye` | o `!` impede que o segundo aperto cancele o canal, então dá para relançar o Eagle Eye já fora do corpo e levar a visão a outro ponto (só carrega mobs da zona em que você está; serve para achar rare) | não diz |
| 27:50 | Attack_Speed | ver abaixo | escreve no chat a velocidade de ataque do alvo, para decidir se doma | não diz |

Texto da Attack_Speed (igual ao da descrição do vídeo):

    /run mainSpeed, offSpeed = UnitAttackSpeed("target") print(format("%s: attack speed = %.2f", GetUnitName("target"), mainSpeed))

A aba dele tem mais quatro macros que o vídeo não abre (nomes cortados no ícone: "Auto…", "passi…", "pet_…" com ícone de Auto Shot e "target").

## Build (19:10 a 25:06)

Ordem falada, sem link de calculadora: Endurance Training 5/5, Improved Aspect of the Monkey 3/3 (com o pet ganhando metade da esquiva), Pathfinding 2/2, Bestial Swiftness 1, Improved Revive Pet (pontos não ditos; quem não se preocupa com a morte do pet vai direto ao Unleashed Fury), Unleashed Fury 2, Summon Hawk, Improved Mend Pet 1 (o Mend Pet tira doença, maldição, magia e veneno), Ferocity 3, Intimidation, Ferocity 5/5, Unleashed Fury 4, Frenzy 4/5, Unleashed Fury 5/5, Bestial Wrath, Spirit Bond 2 e Bestial Discipline 2. Depois, Marksmanship: Lethal Shots 5/5, Careful Aim 5/5, Rapid Killing 2/2, Improved Stings (pontos não ditos) e Trueshot Aura 1 como último ponto.

Sem Deadly Aspects e sem Focused Fire, ao contrário das outras três candidatas. Frenzy depende da velocidade do pet: com pet de 1.0 (Broken Tooth), 3 pontos bastam; 1.2 fica no limite; o carrion bird dele é 2.0 até o 52 (Spiteflayer, 1.2).

Desatualizado depois de 03/11: o Pathfinding passou da linha 2 para a 3, então não dá para pegá-lo logo depois da linha 1.

## Outros pontos

| Assunto | O que o vídeo diz |
|---|---|
| Raça (00:15) | Para solar, Night Elf na Aliança (crit no racial, Shadowmeld, corrida mais rápida) e Troll na Horda; Dwarf ganhou busca de tesouro em baú e 1% de acerto; para dano, Orc ou Night Elf; Skyborn tem 2% de haste, que o pet BM não herda. |
| Pet | Carrion bird pela sobrevivência; o pet herda 100% do crit do caçador, 30% da armadura e o attack power (o maior entre corpo a corpo e distância). |
| Armas (02:40 a 19:10) | Progressão por raça e nível. Night Elf 1-10: arco branco da cadeia Crown of the Earth. Aliança 10-20: Calibrated Blunderbuss (missão da dungeon Hall of Thanes, a partir do 13), Daryl's Hunting Bow ou Rifle (Loch Modan, a partir do 11), Deadly Blunderbuss (Engineering 105) ou Owl Sight Rifle (escolta em Darkshore, 17). Depois: Venom Strike (Wailing Caverns), Master Hunter's Rifle (Nesingwary), Truth Seeker's Bow (25 livros, no 40), Blackcrow no fim. |
| Scorpid Sting | No Forever reduz a chance de acerto do mob (não mais Strength e Agility); com Improved Aspect of the Monkey e Screech, o mob quase não acerta o pet. |
| Truques de solo (28:40 a 32:45) | Freezing Trap e Scare Beast em ciclo infinito num beast para esperar a mana e reviver o pet; Feign Death reseta o chefe e deixa matar os adds separados antes de ele voltar. Cenas do beta. |
| Profissões (33:00 a 42:20) | Engineering é obrigatório para solar (armas, munição e bombas), com Leatherworking de segunda; rota de 1 a 200 e de 1 a 210 com lista de compras na tela. |
| Fishing (42:20) | Pescar até o 20 pelo fish bowl, um buff de 8% em atributos, que o pet também herda. |
