# !KitAmigo

Addon do kit do amigo do dono (criado em 2026-11-08). Não é ligado ao jogo do dono: entra só no `Kit-WoW-Forever.zip`, que o `ferramentas\kit-amigo.ps1` monta. O amigo não entende de tecnologia e não fala inglês, então tudo o que ele vê sai em português.

## O que faz

1. Semente do Leatrix Plus: no carregamento, se a global `LeaPlusDB` ainda não existe, cria com `AutoSellJunk`, `AutoRepairGear` e `FasterLooting` em `"On"`. O `!` no nome faz a pasta carregar antes do Leatrix (como o `!BugGrabber`). Enquanto o Leatrix não tem arquivo salvo, o jogo não troca a global, e o Leatrix lê esses valores no `ADDON_LOADED` dele (`LoadVarChk`, `Leatrix_Plus.lua:238` e `:14027` da 1.60.25). Com arquivo salvo, vale o que está salvo. Ao sair, o Leatrix regrava tudo a partir das próprias variáveis (`:14431`), então semear depois do carregamento não funcionaria.
2. Saque automático (`autoLootDefault` 1) uma vez por personagem, fora de combate.
3. Janela de boas-vindas em português uma vez por conta (`/kit` mostra de novo). Com o jogo fora do `ptBR`, a janela ganha uma linha ensinando a trocar o idioma no Battle.net.
4. Se no login o Leatrix não estiver vendendo o lixo (a semente falhou ou o amigo desligou), escreve no chat, uma vez, os cliques do `/ltp` com os rótulos do Leatrix em português ("Automação", "Vender objetos pobres", "Reparar", "Recarregar").

## Bruxo (1.1.0, 2026-11-08, `Bruxo.lua`)

Só age se o personagem for Warlock. Segue a ordem do Crix, escolhida pelo dono (ficha `comum\personagens\amigo-warlock-demo.md`).

1. `PLAYER_LEVEL_UP`: abre uma janela em português com o talento do nível, o nome em português da Wowhead do Forever (tabela `T`), a árvore e o rank. Ela traz também as magias do instrutor naquele nível, com nome do próprio cliente (`C_Spell.GetSpellName`) e custo somado, e as que o Crix pula (Drenar Mana, Pedra de Fogo, Pedra Mágica, Detectar Invisibilidade). Fecha com a missão do demônio novo e uma nota do Crix nos níveis 10, 18, 20, 26, 31 e 41. Nível sem nada a dizer não abre janela.
2. `/kit bruxo` mostra o nível atual e os próximos três talentos.
3. A macro "Marca" (`#showtooltip`, `/petattack`, `/cast <Dor Lancinante>`) é criada uma vez por personagem quando ele conhece qualquer rank da Dor Lancinante, e vai para o primeiro slot vazio de 1 a 12. Fora de combate, com reprise no `PLAYER_REGEN_ENABLED`. Sem slot vazio, o chat manda arrastar pela janela `/macro`.

A tabela `TREINO` (nível, número da magia e preço em cobre; `q` para missão, `pular` para o que o Crix pula) saiu do `NaowhForever_Training\Data\TrainingData.lua` (classe 9, cliente 1.60.1.70790), só como fatos. Os níveis e preços não foram conferidos no instrutor, e os nomes em inglês usados para marcar `pular` vêm do `SpellName` de 70862. O nome "Suplício" para a árvore Affliction é o nome do cliente em português de memória, ainda não conferido no jogo.

Teste fora do jogo: os dois arquivos rodaram no fengari, com eventos simulados (níveis 2 a 51, rank 2 da Dor Lancinante e `/kit bruxo` no 27). A janela por nível, a macro criada uma vez na tecla 7 (com 6 slots ocupados) e a semente do Leatrix saíram como esperado.

## Limites

Nada rodou no jogo. A semente do item 1 é dedução pela ordem de carregamento e pela regra das variáveis salvas sem arquivo (a mesma em que o `_G.LeaPlusDB = _G.LeaPlusDB or {}` do Leatrix se apoia), não teste. Texto com acento vai em escape de byte, porque o `checar-lua.mjs` exige `.lua` só em ASCII. Checadores: `node checar-lua.mjs "..\..\addons-proprios\!KitAmigo"` e `node checar-combate.mjs "..\..\addons-proprios\!KitAmigo" --toc --prefixos "KitAmigo,SLASH_KITAMIGO,LeaPlusDB,StaticPopupDialogs"` (o `StaticPopupDialogs` é o registro padrão de diálogo da API).
