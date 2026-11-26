# Addons próprios

Os addons escritos neste repositório, com o agente. O jogo não lê esta pasta: o `dev-link.ps1` liga a pasta de um addon ao `Interface\AddOns` do jogo por junction, então você edita aqui e testa lá sem copiar. Todos foram feitos para os personagens do Bruno (Aliança: caçador e paladino, com um pouco de xamã e druida); a tabela de baixo diz o que já serve para qualquer jogador.

## Catálogo

| Addon | Versão | O que faz | Estado | Detalhes |
|---|---|---|---|---|
| `CentralForever` | 0.1.0 | central de combate no canto inferior direito: DPS e dano da luta, dano acumulado, tempo e threat por papel; só exibe (em combate os valores vêm secretos), tudo no `Config.lua`; `/central` | ligado no Bruno; o diário dele ainda marca o teste no jogo como pendente | [LEIA-ME](CentralForever/LEIA-ME.md), [contrato](CentralForever/CONTRATO.md) |
| `CompraForever` | 0.4.1 | painel colado no leilão, no vendedor e na janela de profissão: escaneia, planeja com o dinheiro e as bolsas de agora e faz uma ação por clique (comprar, craftar, vender); vigia de preços, caça de preço e a rota para subir seis profissões até o 150 ou o 225 (no Leatherworking, até o 250); `/compra` | em uso pelo Bruno | [LEIA-ME](CompraForever/LEIA-ME.md), [contrato](CompraForever/CONTRATO.md) |
| `GuiaForever` | 1.5.1 | painel "Agora" com o próximo passo, cuidado do pet, marcas no treinador e na árvore de talentos, dicas e a janela J com talentos, magias, pets, teclas, profissões, treinadores e a aba Crafts; cria as macros da classe no login; `/guia` | em uso pelo Bruno | [LEIA-ME](GuiaForever/LEIA-ME.md), [arquitetura](GuiaForever/ARQUITETURA.md) |
| `UIForever` | 0.7.2 | grava no login o layout do ElvUI do `Config.lua`, define as teclas, põe magias e macros nos botões (só nos vazios e nos que ele mesmo preencheu), barra de XP da Blizzard com a XP das quests, minimapa grande no Shift+M | em uso pelo Bruno | [LEIA-ME](UIForever/LEIA-ME.md) e os comentários do `Config.lua` |
| `!KitAmigo` | 1.1.0 | o kit de um amigo que não usa o agente: Leatrix vendendo lixo e consertando, saque automático, boas-vindas em português (`/kit`) e, no bruxo, talento e treino por nível (`/kit bruxo`) | entregue com o `ferramentas\kit-amigo.ps1` | [LEIA-ME](!KitAmigo/LEIA-ME.md) |
| `PregaoForever` | 0.1.0 | terminal de leilão em modo leitura (régua que mede ações, faturas e dinheiro) | desligado em 2026-11-17, substituído pelo CompraForever; fica pelo design e pela pesquisa | [LEIA-ME](PregaoForever/LEIA-ME.md), [guia de uso](PregaoForever/guia/guia-pregaoforever.html), [design](PregaoForever/DESIGN.md) |
| `_modelo\Modelo` | 0.1.0 | o ponto de partida de um addon novo | modelo | abaixo |

O GuiaForever e o UIForever se ligam pelo nome das macros: o GuiaForever cria, o UIForever põe nos botões. O CompraForever lê as receitas conhecidas que o GuiaForever grava.

## Serve para quem

| Addon | Qualquer classe? | Horda? | O que falta para servir para você |
|---|---|---|---|
| `CentralForever` | sim | sim | só o papel: em `Config.lua`, `papelClasse` marca o paladino como tanque e o resto como dps; um warrior ou druida tanque entra ali |
| `CompraForever` | sim | o código sim | o `Dados.lua` traz as rotas e os preços da casa do Bruno (`us-111`); para a sua casa, ele precisa ser gerado com as ferramentas de preço apontando para a sua casa, e esse fluxo por jogador ainda não existe ([issue #2](https://github.com/GMS00004/wow-forever/issues/2)) |
| `GuiaForever` | o código lê a classe | o código lê a facção (treinadores e zonas por `UnitFactionGroup`) | o conteúdo cobre caçador e paladino da Aliança (talentos, magias, pets, macros, profissões e treinadores); outra classe ou a Horda pedem dados a partir dos seus guias, testados na bancada `rodar-janela.mjs`, que hoje só simula caçador e paladino da Aliança ([issue #1](https://github.com/GMS00004/wow-forever/issues/1)) |
| `UIForever` | o layout sim | sim | as magias nas barras e a barra de recargas existem só para caçador e paladino; o layout do ElvUI é o gosto do Bruno |
| `!KitAmigo` | não | não | é o kit de um amigo específico; serve de exemplo de kit para quem não usa o agente |

Quem joga uma classe ou a Horda é quem melhor pode completar os dados: peça ao agente para montar a partir do seu guia, rode a bancada e mande por PR ([CONTRIBUTING.md](../../CONTRIBUTING.md)).

## Criar um addon novo

1. Copie `_modelo\Modelo` para `addons-proprios\<Nome>`.
2. Renomeie a pasta, o `.toc` e o `.lua` para `<Nome>`, e troque a linha do `.lua` dentro do `.toc`.
3. Ligue ao jogo com o `dev-link.ps1`, primeiro em prévia e depois com `-Aplicar` (com o WoW fechado):
   `ferramentas\dev-link.ps1 -Pasta "addons-proprios\<Nome>"` e depois o mesmo com `-Aplicar`.
4. Abra o jogo e teste.

## Ciclo de edição

| Mudou | Para valer no jogo |
|---|---|
| código (`.lua`) | `/reload` |
| addon novo ou `.toc` novo (inclusive a Interface) | reinicie o jogo; `/reload` não pega arquivo novo |
| deu erro | o BugSack mostra o erro de Lua |

A Interface do `.toc` tem de bater com a do cliente (`/dump select(4, GetBuildInfo())`).

## Desligar

`ferramentas\dev-link.ps1 -Pasta "addons-proprios\<Nome>" -Remover` (prévia), e depois com `-Aplicar`. Só a junction é removida; a pasta em `addons-proprios` fica intacta.

## Testar fora do jogo

Os checadores e as bancadas ficam em `..\ferramentas\guia\` (rode `npm ci` uma vez ali): sintaxe Lua 5.1 e ASCII, regras de combate (função protegida sem guarda, API que vira secreta, função ou evento que não existe no Forever), um simulador de valor secreto e bancadas que rodam o addon no fengari com cenários. O comando único é `..\ferramentas\testar-tudo.ps1`; o mapa das ferramentas está em [`../ferramentas/LEIA-ME.md`](../ferramentas/LEIA-ME.md).
