# !KitAmigo

Addon do kit do amigo do dono (criado em 2026-11-08). Não é ligado ao jogo do dono: entra só no `Kit-WoW-Forever.zip`, que o `ferramentas\kit-amigo.ps1` monta. O amigo não entende de tecnologia e não fala inglês, então tudo o que ele vê sai em português.

## O que faz

1. Semente do Leatrix Plus: no carregamento, se a global `LeaPlusDB` ainda não existe, cria com `AutoSellJunk`, `AutoRepairGear` e `FasterLooting` em `"On"`. O `!` no nome faz a pasta carregar antes do Leatrix (como o `!BugGrabber`). Enquanto o Leatrix não tem arquivo salvo, o jogo não troca a global, e o Leatrix lê esses valores no `ADDON_LOADED` dele (`LoadVarChk`, `Leatrix_Plus.lua:238` e `:14027` da 1.60.25). Com arquivo salvo, vale o que está salvo. Ao sair, o Leatrix regrava tudo a partir das próprias variáveis (`:14431`), então semear depois do carregamento não funcionaria.
2. Saque automático (`autoLootDefault` 1) uma vez por personagem, fora de combate.
3. Janela de boas-vindas em português uma vez por conta (`/kit` mostra de novo). Com o jogo fora do `ptBR`, a janela ganha uma linha ensinando a trocar o idioma no Battle.net.
4. Se no login o Leatrix não estiver vendendo o lixo (a semente falhou ou o amigo desligou), escreve no chat, uma vez, os cliques do `/ltp` com os rótulos do Leatrix em português ("Automação", "Vender objetos pobres", "Reparar", "Recarregar").

## Limites

Nada rodou no jogo. A semente do item 1 é dedução pela ordem de carregamento e pela regra das variáveis salvas sem arquivo (a mesma em que o `_G.LeaPlusDB = _G.LeaPlusDB or {}` do Leatrix se apoia), não teste. Texto com acento vai em escape de byte, porque o `checar-lua.mjs` exige `.lua` só em ASCII. Checadores: `node checar-lua.mjs "..\..\addons-proprios\!KitAmigo"` e `node checar-combate.mjs "..\..\addons-proprios\!KitAmigo" --toc --prefixos "KitAmigo,SLASH_KITAMIGO,LeaPlusDB,StaticPopupDialogs"` (o `StaticPopupDialogs` é o registro padrão de diálogo da API).
