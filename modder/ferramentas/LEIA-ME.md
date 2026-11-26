# Ferramentas

Tudo o que o agente roda, e que também roda sozinho na linha de comando. Duas famílias: os scripts do gerenciador de addons, em Windows PowerShell 5.1, que são os únicos que gravam na pasta do jogo; e as ferramentas fora do jogo, em Node, que testam os addons e calculam preços e rotas.

## Mapa

| Onde | Linguagem | O que é | Entrada |
|---|---|---|---|
| `*.ps1` (esta pasta) | PowerShell 5.1 | o gerenciador de addons: instalar, atualizar, remover, auditar, backup e restauração do WTF, CVars, SavedVariables, junction de addon próprio, abertura de sessão e jogador ativo | [CONTRATO.md](CONTRATO.md) |
| `wow-comum.ps1` | PowerShell 5.1 | a biblioteca que todos os scripts carregam (só define funções) | [CONTRATO.md](CONTRATO.md), seção 8 |
| `testes\` | PowerShell 5.1 | as 10 suítes `t-*.ps1`, com uma instalação falsa do jogo (`fixture\`), addons de exemplo (`fontes-fixture\`) e respostas de rede gravadas (`respostas\`) | [CONTRATO.md](CONTRATO.md), seção 11 |
| `testar-tudo.ps1` | PowerShell 5.1 | o comando único de testes, o mesmo do CI | o cabeçalho do script |
| `guia\` | Node | os checadores e as bancadas de todos os addons próprios (o nome vem do GuiaForever, o primeiro a usá-los): `checar-lua.mjs`, `checar-combate.mjs`, o simulador de valor secreto (`bancada\`), as bancadas `rodar-janela.mjs` (GuiaForever), `rodar-central.mjs` (CentralForever) e `pregao\bancada-pregao.mjs` (PregaoForever e CompraForever), e os casos de teste de cada um (`casos-*`); também os geradores do guia de pets (`pets\`) e o estudo visual da janela J (`visual\`) | [GuiaForever/LEIA-ME.md](../addons-proprios/GuiaForever/LEIA-ME.md), seção de checagens |
| `guia\pregao\` | Node | a bancada e os leitores do PregaoForever, que o CompraForever também usa | [PregaoForever/ARQUITETURA.md](../addons-proprios/PregaoForever/ARQUITETURA.md) |
| `pregao\` | Node | as ferramentas de preço e de profissão fora do jogo: foto pública do leilão da sua casa, crafts que pagam, rota mais barata de perícia, custo do Legacy point nas seis profissões de ofício, coletor horário e tendência de preço | [pregao/CONTRATO.md](pregao/CONTRATO.md) |
| `compra\` | Node | gera e confere o `Dados.lua` do CompraForever e testa o planejador e a rota dele | [CompraForever/CONTRATO.md](../addons-proprios/CompraForever/CONTRATO.md) |
| `kit-amigo.ps1` e `kit\` | PowerShell e HTML | monta o kit de addons de um amigo que não usa o agente (zip com instalador de dois cliques e guia em PDF) | o cabeçalho do `kit-amigo.ps1` |

Há três lugares com "pregão" no nome porque o PregaoForever (o primeiro addon de leilão) nasceu com eles: `addons-proprios\PregaoForever` é o addon (desligado), `ferramentas\guia\pregao` é a bancada dele, que o CompraForever herdou, e `ferramentas\pregao` são as ferramentas de preço, que servem a todos.

## Como os scripts de PowerShell se comportam

| Regra | Como aparece |
|---|---|
| Prévia por padrão | sem `-Aplicar`, o script só mostra o que faria |
| Jogo fechado para gravar | com o jogo aberto, quem grava responde `RECUSA` |
| Backup antes | o WTF e as pastas substituídas vão para `%LOCALAPPDATA%\wow-agentes\backups\` |
| Saída que o agente lê | uma linha por fato, com prefixo em maiúsculas e `chave=valor` (`INSTALACAO ok ...`, `ATUALIZADO slug=...`) |
| Código de saída | 0 ok, 1 recusa ou diferença, 2 pré-requisito ausente, 3 erro de rede ou de arquivo |
| Onde ficam os dados | na pasta do jogador ativo (`jogadores\<apelido>\`), que o `jogador-ativo.txt` aponta |

Rode sempre a partir de `modder`, assim: `powershell -NoProfile -ExecutionPolicy Bypass -File ferramentas\<script>.ps1 <argumentos>`.

## Testes

`testar-tudo.ps1` roda tudo e diz, por linha, o que passou, o que falhou e o que ficou de fora (e por quê). Antes, uma vez: `npm ci` e `node baixar-api-forever.mjs` em `guia\`. As checagens que precisam de dados baixados do jogo (`modder\dados`, fora do git) só rodam no PC de quem baixou.
