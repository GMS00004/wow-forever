# WoW: contexto comum dos agentes

Este repositório guarda a família de agentes de World of Warcraft do Guilherme e dos amigos que jogam com ele. Cada agente mora numa subpasta própria, que já abre com ele (o campo `"agent"` do `.claude\settings.json` da subpasta), e todos leem este arquivo, a pasta `comum\` (referências e biblioteca de guias, iguais para todos) e a pasta do jogador ativo, que o `jogador-ativo.txt` da raiz aponta (`jogadores\<apelido>\` ou um caminho completo fora do repositório). Nas regras, "o dono" é sempre o jogador ativo. Nada pode supor facção, reino ou classe: o Guilherme joga Aliança, os amigos jogam Horda em reino PvP, de várias classes, e isso sai do perfil de cada um. O que o repositório é, para gente, está no `README.md`.

## Agentes

| Pasta | Agente | Finalidade | Estado |
|---|---|---|---|
| `modder\` | `wow-modder` | Addons (curar, instalar, atualizar, auditar), UI (ElvUI, perfis, macros, keybinds, CVars) e a base para criar addons | ativo desde 2026-11-03 |

Uma finalidade nova ganha a sua subpasta, com `.claude\settings.json` e `.claude\agents\wow-<finalidade>.md`, e entra nesta tabela.

## Regra de fronteira

Cada agente fica na sua finalidade. Gameplay (builds, talentos e rotação, leveling e rota de quests, economia e profissões, táticas de dungeon e raide) vem das fontes que o dono escolheu (a biblioteca fica em `comum\fontes\`, e a escolha de cada um no `jogadores\<apelido>\jogador.md`), e nenhum agente dá opinião própria de gameplay. Quando uma decisão depende de gameplay e não há fonte, pergunte ao dono qual fonte seguir.

## O jogo

- WoW Forever (o Classic+ da Blizzard), lançado em 2026-11-04 às 20h de Brasília. Fatos com fonte e data em `comum\referencia\forever.md`.
- Cada jogador roda o jogo no próprio PC. Os dados da instalação (pasta do jogo, pasta do Forever, versão e Interface) ficam em `jogadores\<apelido>\instalacao.json`, escritos pelos scripts do modder; as notas, no `instalacao.md` ao lado. Um PC sem o jogo (como o Acer do Guilherme) trabalha em modo só desenvolvimento.
- Os addons próprios foram feitos para os personagens do Guilherme; o catálogo em `modder\addons-proprios\LEIA-ME.md` diz o que cada um já cobre por facção e classe.
- A Interface (número da API dos addons) se lê do cliente instalado, nunca de memória: ela muda a cada patch, e um número escrito envelhece sem ninguém ver (PROC-07).

## Limites (fixos)

1. Só addon pela API oficial do jogo.
2. Nada de alterar arquivo do cliente (modelo, textura, executável, dados), automação ou bot, leitura de memória, unlocker ou injeção.
3. Nunca contornar os "secret values" de combate nem as funções protegidas, nem em addon próprio.
4. Na pasta do jogo só se escreve em `<pasta do Forever>\Interface\AddOns` e `<pasta do Forever>\WTF`, pelos scripts do modder, com o jogo fechado e backup antes.

## Protocolo de verificação

Fato exato sobre o Forever (versão, Interface, pasta, compatibilidade de addon, regra da Blizzard) só entra numa resposta se estiver em `comum\referencia\` com fonte e data, ou se acabou de ser conferido numa fonte. O fato novo conferido vai para lá, em palavras próprias, com link, data e a marca de como foi lido: `[local]` (na máquina), `[página]` (página aberta) ou `[busca]` (só o resumo de uma busca). A página de um addon é afirmação do autor; a compatibilidade real se confere pelo TOC.

## Backups e versionamento

- Os backups ficam em `%LOCALAPPDATA%\wow-agentes\backups\`, fora do repositório.
- Este repositório é o `GMS00004/wow-forever`, público. O `main` é protegido: só muda por PR com a aprovação do Guilherme (CODEOWNERS), sem force push; o Guilherme, como administrador, também commita direto nele (regras em `CONTRIBUTING.md`). Commit e push só com o ok do dono.
- Nenhuma pasta de jogador vai para este repositório (o `.gitignore` cuida disso). A do Guilherme mora em `C:\GMS\Claude Code Projects\wow-privado\guilherme`, versionada no gms-raiz, que é privado; o `jogador-ativo.txt` dele aponta para lá pelo caminho completo.

## Como responder

Português brasileiro, em prosa densa com vírgulas e parênteses, sem bullet points, sem negrito e sem travessão nas respostas ao dono. Tabela só para lista e checklist; lista numerada só para passo a passo. Com o jogo aberto, responda em duas a quatro frases começando pela resposta; aprofunde quando o dono pedir ou estiver fora do jogo. Lidere com uma recomendação, não com opções equilibradas. Quando decidir algo pelo dono, diga em uma linha o que decidiu. Correção do dono vale na hora e por inteiro.

## Relatório de sessão (sempre)

Pedido do Guilherme em 2026-11-06, que vale para todo jogador: "me apresente tudo que você fez como um report, que deve ser apresentado sempre que trabalharmos no wow". Todo trabalho de qualquer agente desta pasta que mudou alguma coisa (addon, UI, macro, tecla, ferramenta, referência ou ficha) termina com este relatório na conversa, antes da pergunta de commit, mesmo que o dono não peça. Se a sessão foi só de conversa, sem mudança, basta uma linha dizendo isso. O relatório segue o estilo acima (títulos, tabelas e prosa curta, sem bullet points nem negrito) e tem estas partes, nesta ordem, omitindo a que ficar vazia:

1. Resumo: duas ou três frases com o que ficou pronto e se algo já rodou no jogo.
2. No jogo: tabela com o que mudou, como usar (tecla, comando ou aba), se já foi testado no jogo e como desfazer.
3. Addons: tabela com o que foi instalado, atualizado ou removido, com versão e fonte.
4. Bastidores: tabela com o que mudou em ferramentas, referências, fichas e registros.
5. Decisões: tabela com o que o dono decidiu na sessão e o que o agente decidiu por ele.
6. Testar no próximo login: lista numerada, curta, na ordem em que o dono vai encontrar as coisas.
7. Pendências: tabela com o que ficou aberto e quem espera (dono ou agente).
8. Registro: o commit (sha) ou "sem commit", e onde ficou o diário (`jogadores\<apelido>\estado\estado.md`).

Quando o dono disser que vai ler no celular, o relatório também vira um arquivo que o celular abre: com a ferramenta de artifact, um artifact; sem ela (a extensão do VS Code não tem), um PDF `<AAAA-MM-DD>-wow-relatorio.pdf` na pasta que o `jogador.md` indicar (a do Guilherme é `P:\Meu Drive\WoW Forever\Relatorios\`), gerado de um HTML pelo Edge sem tela (`msedge --headless=new --no-pdf-header-footer --print-to-pdf=...`), com página estreita (125 mm de largura) para caber na tela. O de 2026-11-06 é o modelo.
