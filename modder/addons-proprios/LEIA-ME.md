# Addons próprios

Pasta dos addons que você escreve. O jogo não lê esta pasta: o `dev-link.ps1` liga a pasta de um addon ao `Interface\AddOns` do jogo por junction, então você edita aqui e testa lá sem copiar.

## Addons desta pasta

| Addon | O que faz | Detalhes |
|---|---|---|
| `GuiaForever` | próximo talento por nível, roteiro das profissões, perfil gráfico, lembrete do RestedXP e macros do caçador criadas no login (`/guia`) | `..\estado\estado.md` (linhas do GuiaForever) |
| `UIForever` | layout do ElvUI, teclas, magias e macros nos botões por classe, minimapa grande no Shift+M e alça de altura dos chats, tudo aplicado no login | `UIForever\LEIA-ME.md` |
| `CentralForever` | central de combate no canto inferior direito: DPS, dano da luta, dano acumulado, tempo e threat; só exibe, tudo no `Config.lua` (0.1.0, ainda não rodou no jogo) | `CentralForever\LEIA-ME.md` |
| `PregaoForever` | terminal de leilão em três peças (régua que mede, fila do que fazer, mão que age por uma tecla do dono por ação); 0.1.0 ligado ao jogo em 2026-11-16, em modo leitura (só a régua; fila e mão na onda 3, se a DD12 decidir). Guia de uso: https://claude.ai/artifact/SVhE5CoGUNKXxN2sWGTf1p (cópia em `PregaoForever\guia\`) | `PregaoForever\LEIA-ME.md` |

Os dois se ligam pelo nome das macros: o GuiaForever cria, o UIForever põe nos botões.

## Criar um addon novo

1. Copie `_modelo\Modelo` para `addons-proprios\<Nome>`.
2. Renomeie a pasta, o `.toc` e o `.lua` para `<Nome>`, e troque a linha do `.lua` dentro do `.toc`.
3. Ligue ao jogo com o `dev-link.ps1`, primeiro em prévia e depois com `-Aplicar` (com o WoW fechado):
   `ferramentas\dev-link.ps1 -Pasta "addons-proprios\<Nome>"` e depois o mesmo com `-Aplicar`.
4. Abra o jogo e teste.

## Ciclo de edição

- Mudou código (`.lua`): `/reload` no jogo.
- Addon novo ou `.toc` novo (incluindo a Interface): reinicie o jogo. `/reload` não basta para arquivo novo.
- Erros: use o BugSack para ver os erros de Lua.

## Desligar

`ferramentas\dev-link.ps1 -Pasta "addons-proprios\<Nome>" -Remover` (prévia), e depois com `-Aplicar`. Só a junction é removida; a pasta em `addons-proprios` fica intacta.

A Interface do `.toc` tem de bater com a do cliente (`/dump select(4, GetBuildInfo())`).

## Addons que existem

| Pasta | O que é | Onde ler |
|---|---|---|
| `GuiaForever` | guia de jogo: talento e dicas por nível, profissões, treinadores, macros do caçador, perfil gráfico | `GuiaForever\LEIA-ME.md` |
| `UIForever` | layout do ElvUI, teclas, barras por classe e minimapa grande, definidos no `Config.lua` | comentários do `UIForever\Config.lua` |
| `!KitAmigo` | só para o kit do amigo (não roda no jogo do dono): deixa o Leatrix vendendo lixo e consertando, liga o saque automático e mostra boas-vindas em português (`/kit`); no bruxo, talento e treino a cada nível (`/kit bruxo`) e a macro Marca | `!KitAmigo\LEIA-ME.md` |
| `CentralForever` | central de combate: DPS, dano da luta, dano acumulado, tempo e threat; só exibe, tudo no `Config.lua` | `CentralForever\LEIA-ME.md` |
| `PregaoForever` | addon de leilão 0.1.0 em modo leitura (régua: mede ações, faturas e dinheiro); contrato das ondas 1 e 2 em `ARQUITETURA.md`, design em `DESIGN.md`, medidas do jogo em `pesquisa\sonda\` | `PregaoForever\guia\guia-pregaoforever.html` e `PregaoForever\LEIA-ME.md` |

Checagens sem interpretador Lua (sintaxe, ASCII, globais e os dados do GuiaForever): `..\ferramentas\guia\` (rodar `npm install` uma vez ali; os comandos estão no LEIA-ME do GuiaForever).
