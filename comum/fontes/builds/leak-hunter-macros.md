tema: builds
fonte: leak (Leaku, YouTube), "Hunter Macros Guide for WoW Forever | Everything You Need To Know About Macros", e o documento de macros dele no HackMD
url: https://www.youtube.com/watch?v=_W3hOy-hxK0 (documento: https://hackmd.io/tEYnof60S5iYBYCF80QKgA?view)
data: 2026-11-05
seguir: macros de caçador para o Hexumlite Bull, trazidas pelo dono em 2026-11-05. Não tem build. Vídeo de 2026-11-01, antes das mudanças de 03/11, e as demonstrações foram gravadas em outra versão do WoW porque o Forever ainda não tinha saído; o documento, segundo o autor, é atualizado sempre, e o texto abaixo é o que estava lá em 2026-11-05.

# leak: macros de caçador no Forever

Vídeo de 16:01, publicado em 2026-11-01. A transcrição foi lida inteira pela sessão (legenda automática, baixada pelo yt-dlp) e não fica no repositório. O texto das macros saiu do documento público do autor no HackMD, baixado inteiro em markdown pela sessão em 2026-11-05 (não precisa de print). Marca: `[página]` (transcrição e documento).

Afirmações do autor sobre o Forever: macro não precisa mais de `/startattack`, porque qualquer habilidade já inicia o ataque; `/petmoveto` é novo no Forever (o cursor vira mira e o pet fica parado no ponto clicado); o modo de pet "assist" é novo e torna as macros de `/petattack` menos importantes; Raptor Strike não usa o recarga global, então pode ir na mesma macro de outra habilidade.

## Macros do documento

Cada linha da macro separada por " / ". "Tempo" é onde o vídeo fala dela.

| Tempo | Nome no documento | Texto | O que faz |
|---|---|---|---|
| 04:39 | All in One Pet | `#showtooltip` / `/cast [@pet,dead] Revive Pet; [nopet] Call Pet; Mend Pet` | um botão só: chama o pet se não houver, revive se morreu, cura se está vivo |
| 04:59 | Petmoveto | `/petmoveto` | o pet vai ao ponto clicado e fica lá |
| 05:28 | Pet Attack | `/petattack` / `/cast Dash` / `/cast Dive` / `/cast Charge` | manda o pet no alvo usando Dash, Dive ou o Charge do javali |
| 05:58 | Pet Recall | `/petpassive` / `/cast Dash` / `/cast Dive` / `/petfollow` | pet em passivo, correndo de volta |
| 06:18 | Combining Attack and Recall | `/cast Dash` / `/cast Dive` / `/petattack [nomod]` / `/cast Charge [nomod]` / `/petpassive [mod:alt]` / `/petfollow [mod:alt]` | sem modificador ataca, com Alt volta |
| 06:59 | All in One Pet Abilities | `#showtooltip [pet:Hyena]Tendon Rip;[pet:Spider]Web;[pet:Crocolisk]Dismember;[pet:Crab]Pinch;[pet:Owl]Mine!;[pet:Bat]Sonic Blast` / `/cast [@mouseover,harm][]Web` / `/cast Tendon Rip` / `/cast Pinch` / `/cast Dismember` / `/cast Mine!` / `/cast Sonic Blast` | a habilidade ativa do pet que estiver fora, num botão (para PvP, com o autocast dela desligado) |
| 07:46 | Raptor Strike Macros (4) | `#showtooltip Mongoose Bite` / `/cast Raptor Strike` / `/cast Mongoose Bite`; o mesmo com Strider Kick, Wing Clip e Counterattack | junta Raptor Strike a uma habilidade corpo a corpo para poupar tecla |
| 08:20 | Weaving Macros | vazio | o autor espera para saber se o melee weave continua valendo no 60 |
| 08:44 | All in One Stings | `#showtooltip` / `/cast [mod:alt] Viper Sting; [mod:ctrl] Scorpid Sting; Serpent Sting` | Serpent sem modificador, Viper com Alt, Scorpid com Ctrl |
| 09:05 | All in One Cooldowns | `#showtooltip Rapid Fire` / `/cast Rapid Fire` / `/cast Elune's Light` / `/cast Blood Fury` / `/cast Berserking` / `/cast Bestial Wrath` / `/use 13` | burst: Rapid Fire, racial de dano (Elune's Light no Night Elf), Bestial Wrath e trinket de uso (13 no primeiro espaço, 14 no segundo); linhas de outras raças não atrapalham |
| 09:49 | Combine Hawks and Arcane Shot | `#showtooltip` / `/cast [mod:alt] Arcane Shot; Summon Hawk` | Summon Hawk sem modificador, Arcane Shot com Alt |
| 10:10 | Cancel Cheetah and Pack | `/cancelaura Aspect of the Cheetah` / `/cancelaura Aspect of the Pack` | tira o aspecto sem gastar recarga global nem mana (evita o daze ao kitar) |
| 10:43 | Combine Cheetah and Pack | `#showtooltip` / `/cast [mod:alt] Aspect of the Pack; Aspect of the Cheetah` | Cheetah sem modificador, Pack com Alt |
| 10:43 | Combine Beast and Hawk | `#showtooltip` / `/cast [mod:alt] Aspect of the Beast; Aspect of the Hawk` | Hawk sem modificador, Beast com Alt |
| (só no documento) | Scatter Shot (2) | `#showtooltip Scatter Shot` / `/petpassive` / `/petfollow` / `/cast Scatter Shot`; a outra igual com `/cast [@mouseover, harm, nodead][] Scatter Shot` | para PvP: o pet para de bater no alvo do Scatter |
| 11:05 | Hunter's Mark Leveling | `#showtooltip Hunter's Mark` / `/petattack` / `/cast Hunter's Mark` | marca e já manda o pet; o autor diz para usar só solo no mundo aberto, porque em grupo puxa o mob antes da hora |
| 11:51 | Chain Cast Eagle Eye | `#showtooltip Eagle Eye` / `/cast !Eagle Eye` | relança o Eagle Eye já fora do corpo para seguir explorando |
| 12:24 | Cursor Macros (2) | `#showtooltip Flare` / `/cast [@cursor] Flare`; o mesmo com Volley | solta no ponto do cursor sem a mira |
| 12:50 | Mouseover Macros (4) | `#showtooltip <magia>` / `/cast [@mouseover,harm,nodead][]<magia>`, para Tranquilizing Shot, Scare Beast, Hunter's Mark e Scatter Shot | lança no que está sob o mouse sem trocar de alvo |
| 13:25 | Focus Macros (2) | `/focus [@mouseover,harm,nodead]`; e `#showtooltip Tranquilizing Shot` / `/cast [@focus,harm,nodead][@target] Tranquilizing Shot` | marca um foco e lança o Tranquilizing Shot nele |
| 14:27 | Improved Tracking | `/run local c=UnitCreatureType("target");for i=1,C_Minimap.GetNumTrackingTypes()do local t=C_Minimap.GetTrackingInfo(i);if t.name:find(c,1,true)then C_Minimap.SetTracking(i,true);break end end` | troca o rastreamento para o tipo do alvo (no Forever o Improved Tracking só vale para o tipo rastreado); o autor avisa que dá erro dentro de instância, por restrição da API |
| 15:02 | Extra Action Button | `#showtooltip` / `/stopcasting` / `/click ExtraActionButton1` | para o cast e aperta o botão extra; o autor duvida que o Forever tenha esse botão |

No vídeo (02:09), o exemplo de como criar uma macro é `#showtooltip` / `/cast Freezing Trap`, sem comando de pet. O crédito da macro de habilidades do pet é do Discord Classic Hunter, segundo a descrição.

## Cruzamento com as macros do Gladius

| Macro | Gladius | leak |
|---|---|---|
| Pet ataca | `/petattack` | o mesmo, mais Dash, Dive e Charge; e uma versão que volta com Alt |
| Pet volta | `#showtooltip Dismiss Pet` / `/petfollow` | `/petpassive`, Dash, Dive e `/petfollow` (deixa o pet em passivo) |
| Pet até um ponto | `/petmoveto` | igual |
| Hunter's Mark | mouseover, e põe o pet em passivo e o chama de volta | duas versões: só mouseover, sem comando de pet; e a de leveling, que manda o pet atacar (o oposto da do Gladius) |
| Eagle Eye | `/cast !eagle eye` | igual |
| Freezing Trap | com `/petpassive` | o exemplo do vídeo não tem comando de pet |
| Taunt do pet | `/cast Growl` | diz que dá para macrar o Growl, sem texto |
| Velocidade de ataque | `/run` com `UnitAttackSpeed` | não tem |

O Kargoz cita, no guia pago, uma macro de Raptor Strike com Immolation Trap num aperto só; o leak usa a mesma ideia (Raptor Strike fora da recarga global) com as habilidades corpo a corpo.

## Outros pontos

| Assunto | O que o vídeo diz |
|---|---|
| Macros gerais e do personagem | Na janela do `/macro`, a aba da esquerda vale para a conta inteira e a da direita só para o personagem. |
| Ícone | Com `#showtooltip` na primeira linha, o ícone e a dica da magia aparecem sozinhos; não precisa escolher ícone. |
| Modificadores | Alt, Ctrl e Shift trocam a magia da mesma tecla; o autor usa isso para economizar teclas. |
