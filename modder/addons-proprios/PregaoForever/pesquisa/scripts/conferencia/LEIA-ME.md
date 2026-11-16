# Conferência do design por script

Scripts que conferiram o `DESIGN.md` e o `LEIA-ME.md` em 2026-11-16, guardados para a próxima edição do contrato. Rodam com `node`, sem instalar nada, a partir desta pasta. Nenhum altera arquivo, menos o `aplicar-trocas.mjs` com `--aplicar`.

| Script | O que confere | Comando |
|---|---|---|
| `gate-final.mjs` | Os 169 ids de achado na tabela de mudanças; referência a artefato de processo; estilo do `LEIA-ME.md` (sem marcador, negrito ou travessão); relatórios citados; caminho temporário, código de terceiro, conta ou e-mail; hipótese, decisão, passo de sonda e invariante citados contra os definidos; seções citadas que não existem | `node gate-final.mjs ..\..\.. ..\..\processo\achados-todos.md` |
| `conferir-nomes.mjs` | Cada nome de função, evento, enum e texto do cliente citado em crase, contra um conjunto de palavras tirado do espelho da interface da Blizzard, das listas oficiais do projeto e do arquivo de textos | `node conferir-nomes.mjs <espelho>\Interface\AddOns ..\..\..\..\..\ferramentas\guia\api-forever <GlobalStrings enUS.lua> ..\..\..\DESIGN.md` |
| `conferir-comandos.mjs` | Os comandos da sonda do Apêndice A: quantos são, tamanho (o jogo aceita até 255 caracteres) e parênteses, aspas e blocos fechados | `node conferir-comandos.mjs ..\..\..\DESIGN.md` |
| `conferir-escada.mjs` | As tabelas da seção 3.4 (escada de capital), refeitas por um modelo independente | `node conferir-escada.mjs` |
| `aplicar-trocas.mjs` | Aplica trocas exatas de texto: cada bloco tem de casar uma única vez, e sem `--aplicar` é só prévia | `node aplicar-trocas.mjs <arquivo> <arquivo de trocas> [--aplicar]` |
| `tokens-por-agente.mjs` | Soma os tokens de cada agente de um Workflow a partir dos transcritos (o `usage` de cada mensagem, sem repetir a mesma mensagem) e cruza com os rótulos do diário | `node tokens-por-agente.mjs <pasta do workflow> [--json <saída>]` |

O `<espelho>` e o arquivo de textos não ficam no repositório: o Apêndice D do `DESIGN.md` diz de onde baixá-los. Existir no conjunto de palavras prova que o nome é real, não que a assinatura ou o uso estão certos.

A pasta `trocas\` guarda os cinco arquivos de trocas das duas varreduras de consistência (135 blocos), no formato que o `aplicar-trocas.mjs` lê. Já foram aplicados: rodar de novo só mostra que os blocos não casam mais.
