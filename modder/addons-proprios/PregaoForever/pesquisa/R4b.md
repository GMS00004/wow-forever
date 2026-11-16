> Relatório de pesquisa de 2026-11-16, da onda 1 do design do PregaoForever, gravado como estava (foto do dia). `<espelho>`, `<dados>` e `<tmp>` eram pastas temporárias da sessão; o Apêndice D do `DESIGN.md` diz como refazê-las. Onde este relatório e o `DESIGN.md` divergem, vale o `DESIGN.md`.

# R4b: estado do dono no jogo, economia, profissões e teclas

Data da leitura: 2026-11-16. Só leitura: pasta do projeto, `estado.md`, fichas, fontes, SavedVariables e `bindings-cache.wtf` da pasta do jogo. Nada foi escrito fora deste relatório. Nenhum script do projeto foi rodado. O nome da pasta da conta não aparece aqui; uso `<pasta da conta>`.

Marcas: `local` = lido nesta máquina (caminho e linha). Quando o texto local cita página da web, a marca original do levantamento aparece entre parênteses, e eu não reabri a página. `inferencia` = conclusão minha.

## 1. Personagens da conta

Reino: os quatro personagens estão no mesmo reino, `CAMWOW US1 Realm 7 PvE` (`<pasta da conta>/SavedVariables/GuiaForever.lua`, linhas 77, 87, 93 e 99; `local`). O `jogador.md` (linha 18) ainda diz "reino a definir".

| Personagem | Raça e classe | Nível atual (fonte, data) | Profissões e perícia | Papel |
|---|---|---|---|---|
| Hexumlite Bull | Night Elf Hunter (`personagens/hexumlite-bull.md`, linha 10) | Nível 11 em 2026-11-06, 21h32 (`modder/estado/estado.md`, linha 151; e linha 118, "Pet do Hexumlite (nível 11, gato)"). Nível 10 na mesma data, mais cedo (`hexumlite-bull.md`, linha 140). Inferência de nível 19 a 21 em 2026-11-12 (confiança baixa; ver abaixo). | Leatherworking 74/150 em 2026-11-08, 16h20 (`estado.md`, linha 162, print do dono). Skinning, Cooking e First Aid: sem perícia registrada. | Principal |
| Rurik Thunderfist | Dwarf Shaman (`personagens/rurik-thunderfist.md`, linha 10) | Sem nível registrado. Em `<pasta da conta>/91/Rurik-Thunderfist/SavedVariables/RXPGuides.lua`, o único segmento de XP começou em 2026-11-09 18:53 (linhas 899 a 908) e não fechou. Passo do guia: 4 (linha 239). Inferência: nível baixo (confiança baixa). | Herbalism e Enchanting: sem perícia registrada. | Principal |
| Fingolfin Ironjaw | Skyborne (macho) Druid (`personagens/fingolfin-ironjaw.md`, linha 10) | Sem nível registrado. Passo do guia: 1 (`RXPGuides.lua` de Fingolfin, linha 234). Nenhum segmento de XP fechado (linha 1254). Inferência: início da zona inicial (confiança baixa). | Alchemy e Tailoring: sem perícia registrada. | Alt da Alchemy, jogado ativamente (linha 11) |
| Ignatius Stonejaw | Human Paladin (`personagens/ignatius-stonejaw.md`, linha 12; confirmado pelo dono em 2026-11-08) | Nível 1 em Northshire, em 2026-11-08 às 19h59 (`ignatius-stonejaw.md`, linha 11; `estado.md`, linha 166). Sem nível posterior. Os avisos "New at 6" ocultos em `GuiaForever.lua`, linhas 79 a 82, não provam nível. | Mining e Blacksmithing: sem perícia registrada. | Tanque da dupla com o warlock do amigo, desde 2026-11-08 (`ignatius-stonejaw.md`, linha 14) |
| Warlock Demonology do amigo | Warlock (`personagens/amigo-warlock-demo.md`, linhas 11 a 14) | Fora da conta; sem dados locais. | Não se aplica. | DPS da dupla |

Por que o nível é só inferência: nenhum SavedVariables lido tem campo de nível do personagem. Em `GuiaForever.lua`, a palavra "level" não aparece, e as ocorrências de "nivel" são a chave `["nivel"]` das linhas de `skinCores` vistas (linhas 144 a 776, nível de criatura). Em `UIForever.lua` da conta, "level" aparece só em configuração de placa de nome e de alvo (linhas 79 a 232). O `RXPGuides.lua` de cada personagem tem uma lista de segmentos com XP acumulado e datas. No do Hexumlite, há 21 segmentos fechados (linhas 1364 a 2188), o último em 2026-11-12 21:11, com as zonas Ruins of Lordaeron (linha 2130) e Darkshore (linha 2105). Se cada segmento for um nível, o personagem estaria em torno do 22. A estrutura não está documentada, então isso fica como hipótese.

## 2. O que o dono já fez com a casa de leilões ou com ouro

| Data | Ação | Citação ou dado | Fonte | Marca |
|---|---|---|---|---|
| 2026-11-04 (tarde) | Auctionator 341 instalado, do zip da CurseForge | "...o agente instalou, com prévia, !BugGrabber, Auctionator, Forever Quests, TomTom e Leatrix Plus" | `modder/estado/estado.md`, linha 136 | local |
| 2026-11-05 (madrugada) | Baganator 840, Syndicator 289 e Pawn 2.14.1 baixados pelo agente, do Wago | "Baixados pelo Wago Baganator 840, Syndicator 289 e Pawn 2.14.1" | `estado.md`, linha 141 | local |
| 2026-11-05 | Leatrix: vender lixo e consertar automático ligados | "vender lixo, consertar e loot rápido ligados" | `estado.md`, linha 58; `<pasta da conta>/SavedVariables/Leatrix_Plus.lua`, linhas 140 e 164 (`AutoSellJunk` e `AutoRepairGear` = "On") | local |
| 2026-11-07 | Dono traz o vídeo de ouro do Studen Albatroz; as dicas são decididas | Ver seção 4 | `estado.md`, linha 155 | local |
| 2026-11-07 | GuiaForever 1.0.1: texto de ajuda sobre o preço de vendedor e de leilão no tooltip | "Pedido do dono depois do vídeo de ouro do Studen Albatroz" | `estado.md`, linha 85 | local |
| 2026-11-07 | Forever Guide 1.38.5 instalado; inclui leilão e preço | "...profissões, leilão e LFG" | `estado.md`, linhas 30 e 156 | local |
| 2026-11-08 | Motivação de dinheiro, num pedido de UI | "...para ela não ficar voltando o tempo todo [...] estou precisando de dinheiro" | `estado.md`, linha 82 | local |
| 2026-11-08 | Kit do amigo com Auctionator, Pawn, Baganator e Syndicator | "Base RestedXP (...), Questie, Leatrix, Pawn e Auctionator; opcionais escolhidos Baganator e DBM" | `estado.md`, linhas 52 e 163 | local |
| até 2026-11-14 23:58 (UTC-3) | Varreduras de leilão já feitas, com preços gravados | `AUCTIONATOR_SAVEDVARS.TimeOfLastBrowseScan = 1794711536` (Unix 2026-11-15 02:58 UTC, por conversão minha); base de preços `AUCTIONATOR_PRICE_DATABASE` com `__dbversion = 8` e chave `PvE`, arquivo de 561 KB | `<pasta da conta>/SavedVariables/Auctionator.lua`, linhas 139 a 145 | local, inferencia (data) |
| sem data | Nenhuma postagem gravada pelo Auctionator | `AUCTIONATOR_POSTING_HISTORY` só tem `__dbversion = 1` | `Auctionator.lua`, linhas 148 a 150 | local |

Os dados do Auctionator são da conta inteira. A pasta não separa por personagem, então não dá para dizer em qual personagem as varreduras foram feitas.

## 3. Pendências abertas em `estado.md` que tocam economia, profissões ou leilão

| Desde | Pendência | Espera | Linha |
|---|---|---|---|
| 2026-11-13 | GuiaForever 1.3.1 (rota de Leatherworking do ReptilioPlays): conferir no Hexumlite a rota, os totais por faixa e os treinadores. Aos 225, ver se o Cured Rugged Hide é ensinado; se não for, Nightscape Pants direto até 240 | dono | 104 |
| 2026-11-07 | Forever Guide: conferir se o preço de leilão dele repete o do Auctionator e o que desligar pelo `wtf-sv.ps1` | agente e ok do dono | 121 |
| 2026-11-06 | Skinning: as faixas de cor não têm fonte aberta; calibrar `skinCores` e `skinLog` com esfoladas reais | agente | 116 |
| 2026-11-05 | Pesos do Pawn: as fontes dão só a ordem dos atributos; as setas usam os pesos padrão | dono | 115 |
| 2026-11-05 | Postal (correio): o dono acha que não tem versão Forever; sem fonte | dono e agente | 108 |
| 2026-11-08 | Kit do amigo: compartilhar o zip no Drive; conferir o vendedor e o lixo vendido no primeiro login dele | dono | 127 |

## 4. Fontes de economia aprovadas e a decisão do dono

Só uma fonte de economia existe: `comum/fontes/economia/studen-ouro-leveling.md` (Studen Albatroz, 2026-11-07, `https://www.youtube.com/watch?v=UI0W2Qswhfo`). O campo `seguir` (linha 5) traz a decisão, com o texto exato da fonte:

> "decisão do dono em 2026-11-07 ("Minhas decisões"): valem as dicas de recompensa de missão, de treino e de itens verdes (2 a 4), que já estão nos addons instalados; a dica 1 (Skinning em todos e vender todo o couro) não vale, e o couro do Hexumlite segue o roteiro do Leatherworking. A dica 5 depende do guia pago e fica de fora."

| Dica (tempo do vídeo) | Conteúdo | Decisão do dono | Marca |
|---|---|---|---|
| 1 (02:03) | Skinning em todo personagem; vender todo o couro no vendedor | Não vale. Conflita com a regra de não repetir profissão e com o Leatherworking do Hexumlite | local (`studen-ouro-leveling.md`, linhas 15, 31 e 32) |
| 2 (03:38) | Não treinar magia que não vai usar no leveling | Vale (dica já coberta pelo Naowh: "Skip", no `/nftraining`) | local (linhas 16, 26) |
| 3 (04:50) | Na recompensa de missão com escolha, pegar a que vende por mais, salvo melhoria | Vale (já no RestedXP: ícone de vendedor, linha 25) | local (linhas 17, 25) |
| 4 (05:39) | Vender no leilão os itens verdes com bons atributos, não no vendedor | Vale (Auctionator mostra o preço do vendedor e o do leilão, linha 27) | local (linhas 18, 27) |
| 5 (06:51) | Ficar após render missão de bicho, em área de renascimento | Fica de fora (depende do guia pago) | local (linha 19) |

Ressalva: o arquivo não guarda as palavras do dono. "Minhas decisões" é um rótulo, e o resto é paráfrase do agente. Não há como citar a fala do dono de forma exata (desvio).

## 5. Profissões: o que consome e produz, faixa de nível em que o dono está

Base: `comum/fontes/profissoes/roteiros.md` (metas e incertezas), `reptilio-leatherworking.md` (fonte máxima do Leatherworking desde 2026-11-13) e `comum/referencia/profissoes-forever.md`. O `roteiros.md` não traz passos por faixa para as profissões que não são Leatherworking; esses passos estão em `modder/addons-proprios/GuiaForever/ProfissoesA.lua` e `ProfissoesB.lua`, que não li (desvio).

### 5a. Hexumlite: Leatherworking e Skinning (principal), Cooking e First Aid (secundárias)

| Faixa (perícia) | Receita da rota | Consome | Produz | Fonte |
|---|---|---|---|---|
| 55 a 85, em que ele estava em 11-08 (perícia 74) | Embossed Leather Gloves, 35 crafts | 3 Light Leather e 2 Coarse Thread por craft (105 e 70 no total) | Luvas de couro, item level 13 | `reptilio-leatherworking.md`, linhas 128 e 240 |
| 85 a 100 (próxima) | Fine Leather Belt, 20 crafts; guardar os 20 cintos para o passo de 118 a 125 | 6 Light Leather e 2 Coarse Thread por craft | Cinto de couro, item level 16 | linhas 129 e 241 |
| 1 a 30 (feito antes) | Light Leather, 32 crafts | 3 Ruined Leather Scraps por craft (96 no total) | Light Leather | linha 125 |
| Treino | Journeyman: perícia 50 e nível 10, até 150; Expert: 125 e nível 20, até 225; Artisan: 200 e nível 35, até 300 | Não se aplica | Não se aplica | linha 76 |

- Perícia 74/150 em 2026-11-08: o teto de 150 indica que o Journeyman já foi treinado (inferência). Sem o Journeyman, a perícia trava em 75 (fala do vídeo, `reptilio-leatherworking.md`, linha 262).
- Padrões do Merchant's Favor a partir da perícia 60: cintos (30 Favor, nível 12), luvas 75 (nível 15). Peças "Binds when picked up" (linhas 96, 166 a 177).
- Skinning (metas de área por faixa, `roteiros.md`, linhas 36 a 40): 10 a 20 pede 125 de perícia; 20 a 30 pede 150. Para esfolar, o bicho até o 10 pede só a perícia inicial; do 11 ao 20, (nível menos 10) vezes 10; do 21 em diante, nível vezes 5 (`profissoes-forever.md`, linha 77; wow.gg, 2026-11-04, via `[página]` do levantamento). A perícia de Skinning do Hexumlite não está registrada.
- Materiais novos do Skinning: Pristine Leather, Pristine Hide e Pristine Scale (`profissoes-forever.md`, linha 14). Blacksmithing usa Pristine Leather (linha 18).
- Cooking: comida dá Well Fed, com 5% a mais de XP por abate (`profissoes-forever.md`, linha 44; `hexumlite-bull.md`, linha 160). First Aid: agora faz as Healing Potions (seis receitas saíram de Alchemy; `profissoes-forever.md`, linhas 45 e 67).

### 5b. Rurik: Herbalism e Enchanting

| Profissão | Consome | Produz | Fonte |
|---|---|---|---|
| Herbalism | Não se aplica (coleta) | Ervas, que "alimentam 180 receitas" (`profissoes-forever.md`, linha 16) | `profissoes-forever.md`, linha 16 |
| Enchanting | Para a relíquia: 1 Large Glimmering Shard, 2 Greater Magic Essence, 3 Strange Dust e 1 Simple Wood | Encantos. Não encanta item já vinculado de outro personagem da conta; só item BoE, antes de ir pelo correio (sem pergaminho no lançamento). Polished Driftwood Icon: BoP, item level 25, pede nível 20, só para xamã | `profissoes-forever.md`, linhas 19, 68 e 69 |

- Faixa do Rurik: início (Dun Morogh, passo 4 da rota, `RXPGuides.lua`, linha 239). Sem perícia registrada. O treino de Journeyman pede nível 10 e perícia 50, segundo as fontes gerais (`profissoes-forever.md`, linha 28; sem fonte de Enchanting por faixa).

### 5c. Fingolfin: Alchemy e Tailoring

| Profissão | Consome | Produz | Fonte |
|---|---|---|---|
| Alchemy | Ervas (vêm do Rurik pelo correio, `fingolfin-ironjaw.md`, linha 19) | Poções e elixires; itens não BoP, então podem ir pelo correio e pelo leilão (confirmado no tooltip, 2026-11-04). Duas receitas mudaram de perícia, três usam material novo; seis Healing Potions foram para First Aid. Reagentes para outras profissões (tinturas, Sulfuric Acid) | `profissoes-forever.md`, linhas 17 e 66 |
| Tailoring | Não encontrado nas fontes | Não encontrado nas fontes. 208 receitas, cinzas cerca de 35 pontos antes do fim; camp Faction Banner | `profissoes-forever.md`, linha 21 |

- Faixa do Fingolfin: início (passo 1 da rota, linha 234). Alchemy: treino de Journeyman pede perícia 50 e nível 10, segundo a fonte geral (`profissoes-forever.md`, linha 28). Cada marco 150, 225 e 300 rende 1 ponto de Legacy para a conta (`profissoes-forever.md`, linha 35).

### 5d. Ignatius: Mining e Blacksmithing

| Profissão | Consome | Produz | Fonte |
|---|---|---|---|
| Mining | Veias (sem mudança de perícia) | Barras Azerothium e Heavy Thorium, usadas por Alchemy, Blacksmithing e Engineering; "alimentam 606 receitas" | `profissoes-forever.md`, linha 15 |
| Blacksmithing | Barras (Mining), Pristine Leather (Skinning), Strange Dust e Sulfuric Acid (Alchemy) | Armas e armaduras; Runed Rods vão para o Enchanting | `profissoes-forever.md`, linha 18; `ignatius-stonejaw.md`, linha 120 (peças com muito spell power) |

- Faixa do Ignatius: nível 1 em 2026-11-08 (`ignatius-stonejaw.md`, linha 11). Sem perícia registrada.
- Níveis de treino conflitantes: Mining com 75, 150 e 225 em uma seção; 50, 125 e 200 em outra (`roteiros.md`, linha 28). Blacksmithing de 215 a 300 marcado como não testado (`roteiros.md`, linha 22).

### 5e. Mudanças do Forever nas profissões (só o que está escrito com fonte)

| Mudança | Fonte no arquivo | Marca |
|---|---|---|
| Camps: cada profissão tem três objetos (perícia 20, 140 e 300), dividem campfire, recarga de 1 h | `profissoes-forever.md`, linha 12 | local (levantamento: `[página]`) |
| Leatherworking: 198 receitas cinzas cerca de 25 pontos antes; 102 peças de couro e 24 de malha | linha 13 | local (`[página]` do levantamento) |
| Equipamento craftado é BoP (só para quem fabrica) | linha 13 | local |
| Alchemy: itens de Alchemy não são BoP (conferido no tooltip de 2026-11-04) | linha 66 | local |
| Healing Potions passaram para First Aid | linhas 17, 45, 67 | local (linha 45 vem de `[busca]` do levantamento; linha 67, de `[página]`) |
| Legacy points: um por marco 150, 225 e 300, por ofício, uma vez por conta | linha 35 | local (`[página]` do levantamento) |
| Merchant's Favor é por personagem | linha 37 | local (`[página]`) |
| Não há banco de conta; 48 slots e 8 de bolsa por personagem | linha 32 | local (`[página]`, fonte única conquestcapped) |
| Economy Hold: restringe troca, correio, banco de guilda e leilão; duração desconhecida | linha 34 | local (`[página]`, fonte única) |
| Pedras e vellum: sem pergaminho de encantamento no lançamento | linha 69 | local (`[busca]`) |
| Sem Jewelcrafting na lista de profissões | linha 22 | local (`[página]`) |
| Nenhuma fonte diz que um craft dá mais de 1 ponto de perícia | linha 26 | local (busca) |

## 6. Teclas do UIForever (`modder/addons-proprios/UIForever/Config.lua`) e do cliente

Ocupadas pelo `Config.lua` (linhas 263 a 294; "valem para todos os personagens"):

| Tecla | Ação | Linha |
|---|---|---|
| A / D | STRAFELEFT / STRAFERIGHT (andar de lado) | 264-265 |
| 1 a 6 | ACTIONBUTTON1 a 6 (barra 1) | 267-268 |
| Q E R F T G | ACTIONBUTTON7 a 12 (barra 1) | 269-270 |
| Shift+1 a 6 | MULTIACTIONBAR3BUTTON1 a 6 (barra 3) | 272-274 |
| Shift+Q E R F T G | MULTIACTIONBAR3BUTTON7 a 12 (barra 3) | 275-277 |
| Z / X / V | ELVUIBAR2BUTTON1 a 3 (barra de rodapé) | 279 |
| Ctrl+1 a 4 | ELVUIBAR2BUTTON4 a 7 (Ctrl+1 = feed_Pet, slot 16) | 280-281, 328 |
| Mouse 4 / 5 (laterais) | ELVUIBAR2BUTTON8 e 9 (rodapé) | 282 |
| Ctrl+R | REPLY | 285 |
| Ctrl+V | NAMEPLATES | 286 |
| Ctrl+X | SITORSTAND (era X) | 287 |
| Shift+M | UIFOREVER_MINIMAPA | 289 |
| J | GUIAFOREVER_JANELA | 293 |

Ocupadas fora do `Config.lua` (`<pasta da conta>/91/Hexumlite-Bull/bindings-cache.wtf`, linhas 1, 19, 20, 30, 31 e 38; e `estado.md`, linhas 63 e 86):

| Tecla | Ação |
|---|---|
| Botão do meio (BUTTON3) | macro `move_Here` (mover pet) |
| Shift + roda para cima / para baixo | macros `send_Pet` / `pet_Return` |
| `[` / `]` | PAWN_COMPARE_LEFT / PAWN_COMPARE_RIGHT (Pawn) |
| `;` | INTERACTTARGET |

Atalhos do Auctionator (`Auctionator.lua`, linhas 15, 16, 26, 44, 48, 53 e 65): postar com Espaço, pular com Shift+Espaço, voltar com Backspace, comprar com Alt+clique direito, escolher sacola com Alt+clique esquerdo, cancelar com clique direito e cancelar undercut com Espaço.

Livres pelos arquivos (sem confirmar no cliente):
- Letras: B, C, H, I, K, L, M, N, O, P, U e Y. Não aparecem nem no `Config.lua` nem no cache de teclas. As teclas padrão do cliente (por exemplo bolsas, personagem, mapa) não estão nesses arquivos, então pode haver ocupação. Não conferido.
- W e S: não estão no `Config.lua`; pelo padrão do WoW (não conferido no cliente) são o andar para frente e para trás, então estão ocupados.
- Números 7, 8, 9, 0, - e =: fora do `Config.lua`. Como as barras 1 a 12 do padrão usam essas teclas, pode haver ocupação. Não conferido.
- Teclas de função F1 a F12: nenhuma no `Config.lua` nem no cache. Livres pelos arquivos.
- Roda do mouse sem tecla: nenhuma no `Config.lua`. Por padrão, controla o zoom da câmera (não conferido aqui).
- Botões do mouse: BUTTON3, 4 e 5 ocupados. BUTTON6 em diante não aparece nos arquivos (livres pelos arquivos).

## 7. Addons de economia (Auctionator, Baganator, Syndicator, Pawn) e configuração

| Addon | Versão e instalação | Configuração (`estado.md` e SavedVariables) | Pendência |
|---|---|---|---|
| Auctionator | 341, 2026-11-04, atualização manual (`estado.md`, linha 19) | Dicas de preço no tooltip ligadas: `vendor_tooltips` e `auction_tooltips` = true; `auction_mean_tooltips` = false; `price_history_days` 21; `auction_duration` 24; `undercut_percentage` 0 e `undercut_static_value` 0 (sem corte automático de preço); `autoscan_interval` 15; `auto_list_search` true (`Auctionator.lua`, linhas 3 a 137). | Ver incógnita 1. |
| Baganator | 840, 2026-11-05, do Wago (linha 27) | Bolsas. `Baganator.lua` da conta tem 5,5 KB (não lido) | Nenhuma em `estado.md` |
| Syndicator | 289, 2026-11-05, do Wago (linha 28) | Itens dos outros personagens da conta, para o Baganator | Nenhuma em `estado.md` |
| Pawn | 2.14.1, 2026-11-05, release do GitHub (linha 29) | Escala automática desligada; comparação por `[` e `]` (`Pawn.lua`, `AutoSelectScales` = false) | Pesos de atributo: pendente (linha 115) |
| Leatrix Plus (apoio) | 1.60.25 (linha 21) | Vender lixo e consertar automático ligados (`Leatrix_Plus.lua`, linhas 140 e 164) | Nenhuma |

Fora do escopo, mas útil: `Auctionator.lua` (561 KB) não é UTF-8 válido; a ferramenta de edição recusa esse arquivo.

## Incógnitas

1. Se a tela de leilão do Auctionator abre no Forever. Como conferir: abrir a casa de leilões no jogo e ver se as abas do Auctionator aparecem; depois ler o BugGrabber.
2. Duração e bloqueios do Economy Hold (`profissoes-forever.md`, linha 34). Como conferir: no jogo, tentar postar e enviar pelo correio durante o bloqueio, se ele aparecer; anotar a mensagem exata.
3. Nível atual de Hexumlite, Rurik, Fingolfin e Ignatius. Como conferir: `/played` no jogo ou o painel do personagem; depois comparar com a inferência de 19 a 21 do Hexumlite.
4. Teclas padrão do cliente, em especial B, C, H, I, K, L, M, N, O, P, U, Y e os números 7, 8, 9, 0, - e =. Como conferir: Options > Keybindings no jogo, ou a aba Keys do GuiaForever (`/guia keys`).
5. Se um craft dá mais de um ponto de perícia no Forever. Como conferir: SkillUp Forever (citado em `profissoes-forever.md`, linha 26), ou contar os pontos em um craft de teste.
6. Níveis de treino de Mining e Tailoring (`roteiros.md`, linha 28; `profissoes-forever.md`, linha 81). Como conferir: no treinador de cada profissão, no jogo.

## Desvios

- As palavras exatas do dono sobre as dicas do Studen não estão no arquivo; só o rótulo "Minhas decisões" e a paráfrase. Usei o texto do campo `seguir`, marcado como paráfrase.
- Nenhum SavedVariables lido tem campo de nível do personagem. A inferência de nível (Hexumlite, 19 a 21) vem da contagem de segmentos do RestedXP, com estrutura não documentada.
- `roteiros.md` não traz passos por faixa para as profissões fora do Leatherworking. Não li `ProfissoesA.lua` e `ProfissoesB.lua` (fora da lista do brief).
- As fontes do Forever em `profissoes-forever.md` são `[página]` e `[busca]` do levantamento de 2026-11-04. Não reabri nenhuma página; a marca `local` vale para a leitura do arquivo.
- `jogador.md`, linha 18, diz "reino a definir", mas os SavedVariables dão o reino. Não alterei o arquivo.
- Criei as pastas `pesquisa` e `tmp/R4b` no scratchpad, só para este relatório.
