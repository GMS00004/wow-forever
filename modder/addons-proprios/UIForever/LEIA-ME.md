# UIForever

Addon próprio criado em 2026-11-05 a partir do feedback do dono sobre o print da UI. Ele aplica a UI inteira no login, para o dono não configurar nada dentro do jogo. Versão 0.1.0. Até a tarde de 2026-11-05 ainda não tinha rodado no jogo, porque não existia `UIForever.lua` nas SavedVariables; a conferência do primeiro login está nas pendências de `..\..\estado\estado.md`.

## Arquivos

| Arquivo | O que tem |
|---|---|
| `UIForever.toc` | Interface 16001, depende do ElvUI, SavedVariables `UIForeverDB` (conta) e `UIForeverCharDB` (personagem) |
| `Config.lua` | tudo o que se muda: layout do ElvUI, teclas, conteúdo dos botões por classe e escala do minimapa grande |
| `UIForever.lua` | o motor; não precisa ser mexido para trocar a configuração |
| `Bindings.xml` | a tecla do minimapa grande (aparece em Keybindings, em AddOns); o cliente lê sozinho, fora do TOC |

## O que acontece no login

1. No `ADDON_LOADED` do UIForever, antes de o ElvUI montar a tela (o `E:InitDB` só roda no `PLAYER_LOGIN`), ele grava no `ElvDB` cru os pares de `UIForeverConfig.elvui`. Cada valor só é gravado quando muda no `Config.lua` (controle em `UIForeverDB.aplicado`); fora isso, o que o dono mudar pelo jogo fica.
2. Personagem novo herda o perfil do primeiro personagem configurado (`UIForeverDB.perfil`) e o private dele (`UIForeverDB.privadoModelo`, com o `install_complete`), então pula o assistente do ElvUI; o passo de chat do assistente (`E:SetupChat(true)`) roda sozinho depois do login.
3. Dois segundos depois de entrar no mundo, ele cria as alças de arrastar a altura dos dois chats, aplica as teclas e põe as magias e macros nos botões.
4. As teclas de `UIForeverConfig.teclas` são gravadas a cada login onde estiverem diferentes, pela API oficial (`SetBinding` e `SaveBindings`). Para essas teclas, o `Config.lua` vence o que o dono mudar no jogo.
5. Os botões de `UIForeverConfig.barras[<CLASSE>]` são reaplicados no login e sempre que o personagem aprende magia ou as macros mudam (fora de combate e com o cursor vazio). Quando um slot lista macro e magia, a macro vence; a magia entra com o rank mais alto que o personagem conhece; slot gerenciado sem nada definido para a classe é esvaziado. Slots gerenciados: 1 a 12, 13 a 21, 25 a 36 e 61 a 66. Os outros (22 a 24, 37 a 60 e 67 a 72) ficam livres para o dono.
6. Shift+M (`UIForever_AlternarMinimapa`) multiplica a escala do minimapa por `minimapaEscala` (2,2) no mesmo canto e volta no segundo toque; se o dono sair do jogo com ele grande, o próximo login volta ao normal.

## Ligação com o GuiaForever

As macros do caçador são criadas pelo GuiaForever (`..\GuiaForever\Dados.lua`, `GuiaForeverMacros.HUNTER`), e o UIForever só as põe nos botões, pelo nome. Se uma macro mudar de nome lá, troque o nome também em `barras.HUNTER` do `Config.lua`, senão o botão cai na magia de reserva ou fica vazio. As teclas do pet (Shift+roda e clique do meio) são do GuiaForever e não estão no `UIForever`.

Até 2026-11-05 só o caçador tem barras. O Rurik (Shaman) entra quando a build dele fechar.

## Mudar alguma coisa

Edite o `Config.lua` e dê `/reload` no jogo (o `ADDON_LOADED` roda de novo no reload). Mudou o `.toc` ou criou arquivo: reinicie o jogo.

## Diagnóstico

O diário do addon fica em `UIForeverDB.log` (últimas 60 linhas), em `WTF\Account\<conta>\SavedVariables\UIForever.lua`, e os erros de Lua no `BugGrabber.lua` da mesma pasta. Leia os dois com o jogo fechado.

## Desfazer

`ferramentas\dev-link.ps1 -Pasta addons-proprios\UIForever -Remover -Aplicar` tira o addon, e `ferramentas\wtf-restaurar.ps1 -De <backups>\sessoes\2026-11-05_1212 -Aplicar` devolve o perfil do ElvUI e as teclas de antes. As duas coisas são necessárias, porque o addon grava no perfil do ElvUI e no `bindings-cache.wtf`.
