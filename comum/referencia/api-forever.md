# API de addons do WoW Forever: referência

Conferido em 2026-11-03. Marcas: `[página]` = página aberta pelo WebFetch (resumo do modelo sobre a página); `[busca]` = só o resumo de uma busca web, não a página; `[local]` = lido na máquina. Fato de terceiro é pista até ser conferido no cliente ou no TOC. Fatos de lançamento e de Interface vêm de `forever.md` nesta mesma pasta e não são repetidos aqui.

## 1. Regras (não negociáveis)

- **Secret values e funções protegidas:** a interface moderna (era Midnight) restringe dados de combate. Um addon pode exibir dado de combate, mas não pode decidir nada com ele, e não pode contornar a restrição. `[busca]` (Forever segue as regras do Midnight; a restrição de FrameStrata também vale: `GetFrameStrata` pode devolver secret value em alguns frames.) Fonte da restrição: Endgame Tools e Forever Mastery em `forever.md`.
- **Nada que contorne:** não usar truque, reflexão ou leitura indireta para ler um valor secreto, nem chamar função protegida por caminho alternativo. Se a API não dá o dado, o addon não tem o dado. `[busca]` (regra de projeto; a Blizzard restringe por conta própria).
- **Política da Blizzard:** addon é grátis, sem versão paga, com código legível. `[página]` (Forever Mastery, em `forever.md`). Não há política própria do Forever publicada. `[página]`
- **Automação de comunicação ou marcação:** segundo o Massively OP (15/09), a Blizzard vai restringir addons que automatizam isso. `[página]` (Forever Mastery). Tratar como restrição prevista, não como regra fechada.
- **Dúvida sobre se algo é permitido:** perguntar antes de implementar. Não supor.

## 2. Convenções de TOC do Forever

Todos `[página]` (Forever Mastery, lido em 2026-11-03, em `forever.md`):

- **Sufixo de arquivo só do Forever:** `<Nome>_Forever.toc` ou `<Nome>_Camelot.toc` (também `-Forever` e `-Camelot`, como o `Get-TocDoForever` da biblioteca aceita). Quando existe, ele vence o `<Nome>.toc` comum.
- **Marcador dentro de um TOC comum:** `[AllowLoadGameType camelot]` numa linha `## Title:`, `## AllowLoadGameType:` ou em qualquer linha. A biblioteca lê esses tokens (`Get-TocInfo`).
- **Lista de Interface:** `## Interface: 16001` (versão 1.60.1). O Classic Era é 11509; addon só do Classic Era não carrega no Forever. O número pode mudar no lançamento: conferir de novo depois do patch. `[página]`
- **Conferir a Interface no jogo:** `/dump select(4, GetBuildInfo())`. `[página]` (Endgame Tools)
- **Pasta de addons:** `World of Warcraft\_forever_\Interface\AddOns`. `[página]` (Endgame Tools). Um guia escreve `forever\` sem os sublinhados: conflito a conferir na instalação. `[busca]` (Mobalytics)
- **Interface vs. TOC do cliente:** a Interface do `.toc` tem de bater com a do cliente, senão o jogo não carrega o addon. Por isso o `Test-AddonForever` da biblioteca recusa TOC sem a Interface 16001.

## 3. Onde ler a API

- **Documentação de API, warcraft.wiki.gg:** `https://warcraft.wiki.gg/wiki/World_of_Warcraft_API`. `[página]`, 2026-11-03: é a documentação de API para addons e macros, com Lua API, Widget API, Events, CVars, Namespaces (ex.: `C_...`) e índice de sistemas. A página tinha ~692 mil caracteres; só o começo foi lido. A própria página diz estar atualizada até o PTR do Patch 12.1.5, e não cita Forever. Não encontrei na leitura a seção de secret values nem a de TOC, e o número 16001 não aparece nela. `[página]`
- **Mudanças de API por patch:** `https://warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes/notes` (aparece na busca; não aberta). `[busca]`
- **Espelho do código da interface da Blizzard no GitHub:** `https://github.com/Gethe/wow-ui-source`, um espelho em git do código da UI (uma branch por cliente, ex.: live, ptr, beta). `[busca]`. **Não achei na busca uma branch "forever" nesse repo.** Não conferido na lista de branches (não abri o GitHub).
- **Código da interface do Forever:** `Ketho/wow-ui-source-forever`, branch padrão `forever`. `[página]`, 2026-11-05 (lido pelo `gh`): o último commit é de 2026-09-24 com a mensagem "1.60.1 (70009)", ou seja, um build do beta, anterior ao cliente instalado (1.60.1.70790 em 05/11); o TOC do `Blizzard_MacroUI` não declara `## Interface`. Leitura sem clonar: `gh api -H "Accept: application/vnd.github.raw" "repos/Ketho/wow-ui-source-forever/contents/<caminho>?ref=forever"`. A documentação gerada (`Blizzard_APIDocumentationGenerated`) não lista funções globais antigas como `CreateMacro`, `SetBindingMacro`, `SaveBindings` e `GetBindingAction`; o uso real se acha com `gh search code "<função> repo:Ketho/wow-ui-source-forever"` (ex.: `SaveBindings(GetCurrentBindingSet())`). Conferido ali: `Constants.MacroConsts` (120 macros da conta e 30 por personagem), `Enum.BindingSet` (Character = 2) e os ícones do pet (`PET_ATTACK_TEXTURE` e outros, em `Blizzard_ActionBar/Shared/PetActionBar.lua`). Que uma função existe no cliente é inferência pelo uso no código da Blizzard até rodar no jogo.
- **Anotações para o editor (VS Code):** extensão `Ketho.wow-api` ("WoW API", LuaLS; loads quando a pasta tem um `.toc`). `[busca]` (Marketplace e GitHub `Ketho/vscode-wow-api`, MIT segundo agregador). Não instalada nesta sessão: não confirmei se o cadastro já traz as APIs do Forever.

## 4. Fluxo de desenvolvimento

1. Editar em `addons-proprios\<Nome>` (modelo em `addons-proprios\_modelo\Modelo`; instruções em `addons-proprios\LEIA-ME.md`).
2. Ligar ao jogo com `ferramentas\dev-link.ps1`: prévia, depois `-Aplicar` com o jogo fechado. A junction aponta para a pasta de desenvolvimento; nada é copiado.
3. Mudança de código: `/reload` no jogo.
4. Addon novo ou TOC novo (incluindo a Interface): reiniciar o jogo. `/reload` não basta para arquivo novo. `[página]` (Forever Mastery)
5. Erros: BugSack.
6. Antes de depender de uma API, conferir na documentação e, se houver dúvida, no cliente. Não supor que uma API existe no Forever só porque existe no Mainline.
7. Desligar: `dev-link.ps1 -Remover` (prévia e `-Aplicar`); a pasta de desenvolvimento fica intacta.

## 5. Pendências de conferência

- Não consegui conferir na página do warcraft.wiki.gg a seção de secret values, a de TOC e o número 16001. (Conferir o 16001 no cliente com `/dump`.)
- A branch `forever` do Ketho foi conferida em 2026-11-05 (ver a seção 3); a ausência de uma branch do Forever no Gethe continua sem conferência direta. O espelho do Ketho é do build 70009: conferir de novo quando ele subir para o build do cliente.
- A página da API não foi lida inteira (só ~100 mil de ~692 mil caracteres).
- Os fatos de restrição de combate são de resumos de busca e de sites de terceiros; a lista exata do que o Forever bloqueia só sai do cliente.
- Lançamento em 2026-11-04 (23:00 UTC): até lá, os fatos de cliente final são de beta/pré-lançamento.
