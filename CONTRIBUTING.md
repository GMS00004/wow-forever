# Como contribuir

O repositório é do Bruno, e você tem permissão de escrita. O combinado é simples: o `main` só muda por pull request, e quem faz o merge é o Bruno. O plano Free da GitHub não trava o `main` em repositório privado, então isso vale pela palavra de cada um; se alguém mudar o `main` direto, um workflow abre uma issue para o Bruno com o comando para voltar.

## O fluxo

1. Atualize o seu `main`: `git checkout main` e `git pull`.
2. Crie uma branch com o seu nome e o assunto: `git checkout -b seunome/warrior-no-guiaforever`.
3. Faça a mudança e rode os testes: `powershell -NoProfile -ExecutionPolicy Bypass -File modder\ferramentas\testar-tudo.ps1`.
4. Commit e push da branch: `git push -u origin seunome/warrior-no-guiaforever`.
5. Abra o PR para o `main`. O CI roda os testes e a revisão do Bruno é pedida sozinha.
6. Ajuste o que a revisão pedir na mesma branch; o Bruno faz o merge (em geral, squash).

Não force push no `main` nem na branch de outra pessoa. Na sua branch, à vontade.

## O que não vai no PR

| Não commite | Por quê |
|---|---|
| a sua pasta de jogador (`jogadores\<você>\`) e o `jogador-ativo.txt` | é a memória do seu agente; o `.gitignore` já ignora, não force |
| `modder\dados\` | dados baixados do jogo e da rede, refeitos por script |
| um `Dados.lua` do CompraForever gerado com a sua casa de leilão | os dados que estão no repositório são os do Bruno; até existir o fluxo por jogador, gere e use só no seu PC |
| zip, backup do WTF, SavedVariables | têm dados da sua conta |
| conteúdo pago (rota comprada, código de importação de guia pago) ou a transcrição inteira de um vídeo | o crédito e o direito são do criador; resumo e link bastam |

## Mensagens de commit

Em português, no formato `tipo(escopo): o quê`, com uma linha `Por quê:` no corpo quando o motivo não for óbvio. Os tipos em uso: `feat`, `fix`, `docs`, `test`, `refactor`, `chore` e `ci`. O escopo é a peça: `wow` (agente e ferramentas), `pregao` (ferramentas de preço), o nome de um addon, `repo`.

    feat(GuiaForever): talentos e magias do Warrior Arms até o 20

    Do guia do <criador> (comum/fontes/builds/<arquivo>.md), testado na bancada.

    Por quê: o GuiaForever só cobria caçador e paladino.

## Convenções de código

| Onde | Regra |
|---|---|
| `.ps1` | Windows PowerShell 5.1, sem módulos; UTF-8 com BOM (sem BOM, o 5.1 quebra os acentos); `param()` primeiro e o corpo em `Invoke-ScriptWow`; o resto está na seção 1 do [contrato](modder/ferramentas/CONTRATO.md) |
| script que grava | prévia por padrão, `-Aplicar` para gravar, recusa com o jogo aberto, backup antes, linha no `registro.md`; e um teste em `modder\ferramentas\testes\` |
| `.lua` dos addons | Lua 5.1, texto do jogo em inglês (o cliente é `enUS`), só ASCII no código; nada que contorne valor secreto ou função protegida; passe no `checar-lua.mjs` e no `checar-combate.mjs` |
| `.mjs` | Node 20 ou mais novo, ES modules; dependência nova só em `modder\ferramentas\guia\package.json`, e com motivo |
| documentos | português; fato do Forever com fonte e data (ver o protocolo de verificação no `CLAUDE.md`) |
| nomes | pastas e scripts em português; termos do jogo e da API como são no jogo |

## Acrescentar a sua classe ou a Horda

O código dos addons já lê classe e facção; o que falta é dado. O caminho:

1. Traga o guia que você segue para `comum\fontes\` (resumo nas suas palavras, link e o cabeçalho de [comum/fontes/LEIA-ME.md](comum/fontes/LEIA-ME.md)).
2. Peça ao agente para montar os dados no addon a partir dessa fonte (macros e talentos no GuiaForever, barras no UIForever, o papel no `Config.lua` do CentralForever).
3. Rode a bancada do addon e o `testar-tudo.ps1`; teste no jogo com o seu personagem.
4. Abra o PR dizendo classe, facção e o que testou no jogo.

As issues com a etiqueta `agnostico` listam o que já se sabe que falta.

## Revisão

O Bruno revisa todo PR. Mudança em addon que roda no jogo precisa de teste no jogo de quem mandou; mudança em script que grava na pasta do jogo precisa de teste automatizado. PR pequeno e de um assunto só anda mais rápido.
