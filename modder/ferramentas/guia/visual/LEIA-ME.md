# Estudo visual da janela J do GuiaForever (2026-11-08)

Pedido do dono, com a UI já boa: "o problema agora é somente o guia (Tecla J). Faça um estudo de como melhorar a disposição das informações, tornando agradável a parte visual. Se quiser, pode pegar alguns quadros do meu guia e me perguntar o que eu mudaria."

Este arquivo guarda o diagnóstico, a proposta e as decisões, para que outra sessão implemente sem refazer o estudo. Nada disto mudou o addon: a 1.1.0 continua como está.

## Arquivos

| Arquivo | Papel |
|---|---|
| `quadros.html` | os quatro quadros (`#q1` a `#q4`): à esquerda a janela 1.1.0 reconstruída do código, à direita o esboço da proposta |
| `renderizar.mjs` | fotografa os quadros pelo Edge sem tela em `png\q1.png` a `png\q4.png` (`node renderizar.mjs [q1 ...]`) |
| `icones.txt` | nomes dos ícones usados; `icones\` e `png\` ficam fora do git |

Para refazer os ícones (Git Bash, nesta pasta): `mkdir -p icones && for n in $(cat icones.txt); do curl -s -f -o icones/$n.jpg https://wow.zamimg.com/images/wow/icons/large/$n.jpg; done`. As fontes vêm do ElvUI instalado (PT Sans Narrow e Expressway) e o fundo de um print do dono (`Screenshots\WoWScrnShot_110626_022013.jpg`), então o render só funciona no Avell.

Como os quadros foram montados: o lado "hoje" segue `Janela.lua`, `Familias.lua` e `Teclas.lua` da 1.1.0 (tamanhos, cores, ordem dos blocos e os textos que o código gera), com os dados reais do nível 16 do Hexumlite (o nível veio do link dos itens da bolsa no `Syndicator.lua`, gravado no logout de 08/11 05:03). Os ranks do javali, os professores e as 38 regras saem do `PetGuia.lua` (convertido para JSON com o luaparse). O nome do pet, os pontos de treino e os ranks que o pet já tem (Bite 1 e Charge 1) são ilustrativos. Não há print da 1.1.0 aberta; o print de 06/11 22:28 mostra a 0.9, com as mesmas peças visuais.

## Diagnóstico da janela 1.1.0

| # | Problema | Onde no código |
|---|---|---|
| 1 | A janela usa o visual antigo da Blizzard (fundo `UI-DialogBox-Background`, borda de tooltip, botões vermelhos `UIPanelButtonTemplate` nas abas e nas ações, barra de rolagem dourada) no meio de uma UI toda ElvUI, plana e escura. O próprio painel Now já usa o estilo plano, então a janela J não combina nem com ele | `Janela.lua:735-741`, `:775`, `:580`, `:811` |
| 2 | A aba ativa só ganha um brilho (`LockHighlight`) num botão igual aos outros: difícil saber onde se está | `Janela.lua:673-677` |
| 3 | A caixa "Show all" vem depois das 7 abas, em x = 694, e o rótulo começa em 722: numa janela de 760, o texto passa da borda direita (conta pelo código, a conferir num print) | `Janela.lua:773-798` |
| 4 | O título repete o nome do personagem e não diz nada do estado (pontos de talento, pet, profissão) | `Janela.lua:690` |
| 5 | Todo o conteúdo é uma coluna de frases brancas de 14 em 700 de largura (mais de 120 caracteres por linha), sem ícone, sem coluna e sem alinhamento. O nível vai dentro da frase ("Level 18: ..."), então não dá para correr o olho pelos níveis | `Janela.lua:594-671` |
| 6 | Cada botão de ação é um botão vermelho de 260 × 22 numa linha só dele, embaixo do item; na aba Pet, três professores viram seis linhas | `Janela.lua:579-584`, `Familias.lua:194-201` |
| 7 | Estado em códigos de texto que pedem a legenda da aba Help: `[v]`, `[x]`, `> `, `*`, `+ ` | `Janela.lua:210`, `:223`, `Familias.lua:123`, `Teclas.lua:144` |
| 8 | Nada indica quais linhas têm tooltip (a fonte só aparece passando o mouse) | `Janela.lua:566-574` |
| 9 | Dado de tabela escrito como prosa: "Bite: rank 1 -> 3 (pet 16, 7 TP) - can train now", "Claw 3 - pet 16, 7 TP: ..." | `Familias.lua:231-234`, `:305` |
| 10 | A aba Families abre com as 38 linhas de "How pet abilities work" (aberta na primeira vez), e as 19 famílias ficam embaixo, como 19 cabeçalhos recolhidos | `Familias.lua:359-366` |
| 11 | O mapa de teclas é uma lista de texto, quando o natural é uma grade igual às barras de ação (que mostram S1, C1, M4) | `Teclas.lua:122-177` |
| 12 | Abas que juntam assuntos: Combat tem rotação, teclas, armas, atributos e notas numa rolagem só; Professions tem as minhas profissões, zona e treinadores | `Janela.lua:293-374` |
| 13 | Janela fixa em 760 × 600, sem redimensionar | `Janela.lua:10`, `:724` |

## Proposta

A direção é uma só: a janela J passa a ter a cara do ElvUI e cada tipo de dado ganha o componente que combina com ele.

| Princípio | Como fica |
|---|---|
| Mesma linguagem do ElvUI | com o ElvUI carregado, a janela e os controles passam pelas funções de skin dele (`SetTemplate("Transparent")`, `S:HandleButton`, `S:HandleTab`, `S:HandleScrollBar`, `S:HandleEditBox`, `S:HandleCheckBox`, `S:HandleCloseButton`, em `ElvUI\Game\Shared\Modules\Skins\Skins.lua` e `General\Toolkit.lua` do 16.01 instalado); sem ElvUI, as mesmas texturas planas desenhadas pelo guia |
| Navegação lateral | as abas viram uma coluna à esquerda com ícone, a ativa com fundo e uma faixa na cor de destaque; o "Show all" desce para o pé da coluna (resolve o item 3 e abre espaço para aba nova) |
| Cabeçalho de estado | no lugar do título, três etiquetas: pontos de talento livres, pet (família, nível, felicidade) e a profissão que trava |
| Gramática de linha | `[nível] [ícone] texto principal + complemento cinza ....... [fonte] [ação]`: o nível numa coluna própria, a fonte como etiqueta discreta à direita, o botão pequeno na própria linha. Linhas zebradas, nível atual em destaque, nível passado esmaecido |
| Componente por tipo de dado | cartões no Now, cartão do pet com barras, tabela de ranks com passo a passo, grade de teclas com ícones, régua de níveis para os ranks de cada família, barras de progresso nas profissões |
| Ícones no lugar dos códigos | marca verde e x vermelho, cadeado com o nível, estrela da escolha do Saltii, etiqueta NEW |
| Tipografia e ritmo | três tamanhos (título de seção em Expressway 12 maiúscula na cor de destaque, texto em PT Sans Narrow 14 a 15, complemento 12,5 cinza); espaços de 4, 8 e 16 |
| Janela | 820 × 600 por padrão, redimensionável (`SetResizable`, `SetResizeBounds`, ambos na lista da API do Forever), tamanho lembrado |

Quadros desenhados (`png\`):

| Quadro | Hoje | Proposta |
|---|---|---|
| `q1` Now | lista de frases, botão vermelho embaixo do item, "Level 18:" repetido | cartões com faixa de cor, ícone, complemento e a tecla desenhada; "Coming up" com o nível numa coluna |
| `q2` Pet | 25 linhas de texto, três botões vermelhos para três professores | cartão do pet (retrato, felicidade, pontos de treino, dieta), tabela Ability/Rank/Pet/TP/Status/Teacher com um botão Arrow, passo a passo em 5 etapas, checklist do treino |
| `q3` Combat | Rotation e Keys numa rolagem só, teclas em texto | sub-abas (Rotation, Keys, Weapons, Stats); grade de teclas com os rótulos das barras (S1, C1, M4), cadeado com o nível nas que ainda não valem, NEW nas novas, o texto longo no tooltip; "Coming next" com as teclas desenhadas |
| `q4` Families | 38 regras na frente, famílias embaixo | lista de famílias à esquerda (a do seu pet marcada), detalhe à direita com etiquetas, dieta, régua de ranks por nível do pet (tem, pode aprender agora, depois) com os professores no tooltip, e as notas com a fonte |

Pontos técnicos a conferir na implementação: ícone de magia ainda não aprendida (o `GetSpellTexture` por nome falha para magia fora do livro; os dados de `Teclas.lua` e `Dicas.lua` precisariam do id da magia), o retrato do pet por `SetPortraitTexture(textura, "pet")`, e que as funções de skin do ElvUI aceitem quadros criados por outro addon fora de combate (o próprio ElvUI usa nelas os quadros da Blizzard).

## Decisões

Do dono, em 2026-11-08, depois de ver os quadros:

| Pergunta | Resposta |
|---|---|
| Navegação | coluna à esquerda com ícones |
| Fonte das dicas | "Não quero que você só despeje informações a rodo e tb nem ligo mais pra fonte dela. Só quero que esteja organizado e estruturado para eu acompanhar bem" (a janela deixa de mostrar a fonte, e cada aba mostra o que importa agora, com o resto a um clique) |
| Teclas | grade igual às barras |
| Próximo passo | implementar tudo na 1.2 |

Do agente: cor de destaque pela classe do personagem; janela de 820 × 600, redimensionável. O plano está em `C:\Users\PC-AVELL\.claude\plans\guia-1-2-janela-organizada.md`, e a regra das etiquetas de fonte nos quadros (`[Method]`, `[LudiDeo]`) fica superada pela decisão acima.
