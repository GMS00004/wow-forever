# GuiaForever

Addon próprio do dono, versão 1.3.1 (2026-11-13: a rota de Leatherworking, os treinadores e os padrões trocados pelo vídeo do ReptilioPlays, fonte máxima do dono para a profissão; ver `..\..\..\comum\fontes\profissoes\reptilio-leatherworking.md`). Antes: 1.3.0 (2026-11-08, noite: o paladino Ignatius Stonejaw, com talentos em opções lado a lado, lembrete de Righteous Fury, marcos de nível e macros; ver "O que mudou na 1.3"). Antes: 1.2.0 (2026-11-08, tarde: a janela J refeita no estilo do ElvUI, organizada por tipo de informação; ver "O que mudou na 1.2"), 1.1.0 (2026-11-08, madrugada: guia de habilidades de pet por família, aba Families e seção Next ability upgrades na aba Pet) e 1.0.1 (2026-11-07; a 1.0.1 só acrescenta à aba Help, seção Addons, as marcas de recompensa do RestedXP, o pular magia do Naowh e os preços no tooltip do Auctionator). Leva para dentro do jogo o que as fontes do dono dizem e o que ele decidiu sobre elas. Está ligado ao jogo por junction (`ferramentas\dev-link.ps1`, manifesto `estado\addons\dev-guiaforever.json`): editar aqui é editar o que o jogo carrega.

## O que mudou na 1.3

Pedido do dono, 2026-11-08, noite: integrar o guia do paladino Ignatius Stonejaw (Human, Protection, tanque da dupla com um warlock) como o do Hexumlite. A única fonte de gameplay é a ficha `..\..\..\comum\personagens\ignatius-stonejaw.md`, com as decisões do dono da mesma noite (Prot no 22, Sanctified Judgement; os 6 pontos livres de Prot e o 53 a 60 abertos). Contrato na seção 12 do `ARQUITETURA.md`. Nada muda para o Hexumlite, o Rurik e o Fingolfin: todo caminho novo só liga com os campos novos nos dados da classe (o banco de prova do caçador saiu idêntico ao de antes).

| Peça | O que faz |
|---|---|
| Talentos com opções lado a lado | onde as fontes divergem e o dono não escolheu, o plano guarda uma coluna por opção (A defesa, B mana, C mais mana; do 15 ao 19, B e C na ordem de Improved e Sanctified Judgement). A árvore marca com letras ("A B" dourado no ponto de agora, cinza nos seguintes, check no feito); a faixa do alto diz "Plan now (level N): ..."; a aba Talents ganha "Your pick" com a tabela nível a nível; o painel e o Coming up mostram "Precision 1/3 or Divine Intellect 1/5" |
| Lembrete de Righteous Fury | linha vermelha no painel quando o Righteous Fury está desligado, conferida só fora de combate (a cada 4 s e ao sair de combate); o botão mostra a tecla (Shift+1); o botão direito esconde até o próximo `/reload` |
| Marcos de nível | missão de classe do 12 (The Tome of Divinity, Duthorian Rall, catedral de Stormwind, até aprender Redemption) e do 20 (Test of Righteousness e The Tome of Valor), troca para uma mão e escudo no 22, montaria e dual spec no 40; os de missão com botão Arrow |
| Macros | `strike_Holy` e `judge_Start` com /startattack, `bubble_Cancel` (lança e cancela), `attack_Start`, `bop_Mouse` e `bof_Mouse` (mouseover), criadas no login; `cleanse_Mouse` refeita sozinha: Purify no 8, Cleanse no 42 |
| Dados | dicas de magia, rotação, armas, atributos e notas do paladino; 8 perguntas na aba Help; mapa de teclas na aba Keys (o layout do caçador, com o conteúdo do paladino) |

Arquivo novo no `.toc`: `Lembretes.lua`. Por isso o jogo precisa ser reiniciado para o lembrete, os marcos e a `cleanse_Mouse`; o resto vale com `/reload`.

## O que mudou na 1.2

Pedido do dono, 2026-11-08: "Minha UI agora está bem boa, o problema agora é somente o guia (Tecla J)". Estudo e quadros em `ferramentas\guia\visual\` (LEIA-ME e `png\q1` a `q4`); decisões dele: navegação em coluna à esquerda, teclas numa grade igual às barras, nada de fonte na tela e nada de despejar informação ("Só quero que esteja organizado e estruturado para eu acompanhar bem"). Contrato na seção 11 do `ARQUITETURA.md`; plano em `C:\Users\PC-AVELL\.claude\plans\guia-1-2-janela-organizada.md`.

| Peça | O que mudou |
|---|---|
| Janela | estilo do ElvUI (skin dele quando carregado, aparência plana sem ele), 820 × 600 por padrão e redimensionável pela alça do canto (o tamanho fica salvo) |
| Cabeçalho | etiquetas de estado: pontos de talento livres, pet (família, nível, felicidade) e a profissão que trava; clique abre a aba |
| Navegação | coluna à esquerda com ícone por aba e o contador do Now; "Show all" no pé da coluna |
| Now | cartões com a faixa de cor, o ícone, uma linha de explicação, a tecla desenhada e o botão; "Coming up" com o nível numa coluna |
| Pet | cartão do pet (retrato, felicidade, pontos de treino, dieta), tabela de upgrades com um Arrow e o passo a passo em 5 etapas, checklist do treino |
| Families | lista de famílias à esquerda (a do seu pet marcada) e o detalhe à direita, com a régua de ranks por nível do pet; "How abilities work" vira um item da lista, com as 5 etapas e só as 8 regras essenciais (as outras com "Show all") |
| Combat | sub-abas Rotation, Keys, Weapons e Stats; Keys é uma grade com os rótulos das barras (S1, C1, M4), cadeado com o nível nas teclas que ainda não valem e NEW nas novas |
| Professions | sub-abas Mine, Zone e Trainers; Mine tem um cartão por profissão com o passo atual e, embaixo, o roteiro de cada uma numa tabela (faixa de perícia, receita e quantidade, materiais), com o passo atual em destaque e o resto em "Show N more", e, nas de fabricar, o total de materiais de cada faixa de treino (Apprentice, Journeyman, Expert, Artisan; na faixa atual, só o que falta), em pares de quantidade e material, com a faixa atual e a próxima abertas (os dois pedidos do dono na mesma tarde) |
| Help | sub-abas Questions (recolhidas), Addons (tabela) e Signs |
| Painel Now | botão direito no aviso de treino ("Train 2 spells: Dorion") pula aquelas magias: o aviso só volta com magia nova, e só com ela (antes voltava sempre que o treinador mais perto mudava, porque escondia pelo texto); a lista dos pulados e o "Show again" ficam em J > Now > Hidden; o tooltip do painel não mostra mais a fonte. Pedido do dono na mesma tarde; vale já com `/reload` |
| Curadoria | a fonte some da tela (fica nos dados); cada seção mostra até 5 linhas e guarda o resto em "Show N more"; estado por ícone, não por código de texto; frases dos dados que citavam a fonte foram reescritas |

Arquivos novos no `.toc`: `Visual.lua` e `Abas.lua`. Por isso o jogo precisa ser reiniciado; um `/reload` num jogo aberto antes deles mostra na janela só o aviso para reiniciar.

## O que mudou na 1.1

Pedido do dono, 2026-11-07, noite: um guia completo de habilidades de pet, por família e com progressão ("quando preciso arrumar outro pet [...] de level maior pra aprender um nível maior de habilidade"), no jogo e em PDF, com as explicações dos vídeos do Saltii e do LudiDeo. Contrato na seção 10 do ARQUITETURA.md.

| Peça | O que faz |
|---|---|
| aba Families (J) | "How pet abilities work" (o caminho para aprender um rank sem trocar de pet, pontos de treino, estábulo, felicidade, velocidade de ataque), uma seção por família (papel, habilidade única, dieta, habilidades, notas das fontes, feras rápidas e a progressão rank a rank com o professor), "Abilities" com todos os professores, "Pet trainer" e "Sources" |
| Next ability upgrades (aba Pet e Families) | lê a família, o nível e o livro do pet e mostra, por habilidade, o maior rank que o pet já pode treinar (ou o seguinte, com o nível que falta), os pontos de treino e até 3 professores que você já pode domar, com botão Arrow |
| PDF | o mesmo conteúdo em P:\Meu Drive\WoW Forever\Guias\guia-pets-cacador.pdf (125 mm, para o celular) |

Dados gerados por ferramentas\guia\pets\gerar-guia.mjs a partir do cliente do Forever (wago.tools, build 1.60.1.70862), da Forever-Hunter-Pets (MIT) e da Petopia (professores), dos cartões do Saltii e dos textos das fontes (textos.json). O Saltii marca o doador documentado de cada rank com *.

## O que mudou na 1.0

Pedido do dono, 2026-11-06, noite: "A user experience do guia está genuinamente muito ruim. Sinto que não estou nem conseguindo aproveitar o jogo, porque o tempo inteiro preciso voltar ao Claude para consultar as coisas." A resposta foi o plano `C:\Users\PC-AVELL\.claude\plans\continue-lexical-elephant.md`. A 1.0 deixa de ser uma janela que o dono consulta e passa a aparecer onde ele já está olhando, na hora certa, com um botão:

1. O painel "Agora", embaixo do RestedXP, com até 4 linhas que nascem e somem pelos eventos do jogo e nunca aparecem em combate.
2. O Ctrl+1 alimenta o pet com a comida certa da bolsa, pela macro `feed_Pet`.
3. Marcas dentro das janelas do jogo: o selo "PLAN" no treinador de pet, os selos "NOW", "ALL" e "?" na árvore de talentos, e linhas do guia nos tooltips de item, de magia e de ação do pet.
4. A janela J vira a segunda camada: 6 abas, busca, seções recolhíveis, texto 14, a fonte de cada linha no tooltip, "Show all" e as perguntas que o dono fez ao Claude, respondidas pelas fontes.

Os contratos entre os arquivos estão em `ARQUITETURA.md`.

Desde a 0.7.0, todo o texto do jogo está em inglês. Os subcomandos do `/guia` têm apelidos em inglês, e os em português continuam valendo.

## Regra do conteúdo

Nada de gameplay sai da cabeça do agente. Cada dica vem de uma fonte em `..\..\..\comum\fontes\` ou de uma ficha em `..\..\..\comum\personagens\`. A fonte fica no campo `fonte` e a origem (arquivo e linha) num comentário. Onde as fontes divergem, o dono escolhe, e as escolhas estão na tabela "Decisões do dono" da ficha de cada personagem. Fonte anterior a 03/11 entra marcada "(beta)", e decisão do próprio dono entra com a fonte "you". Lacuna fica como "sem fonte" no jogo. O estado (dieta do pet, pontos de treino, magias conhecidas, perícia) vem do jogo.

## Arquivos (na ordem do `.toc`)

| Arquivo | O que tem |
|---|---|
| `Dados.lua` | `GuiaForeverDados[CLASSE]` (talento por nível, `lei` e `aberto`), `GuiaForeverMacros`, `GuiaForeverGraficos`, `GuiaForeverProfissoesPlanejadas`, `GuiaForeverRastreador` e, desde a 1.0, `GuiaForeverPet` (ids das magias de pet, missão 6103, treinadores de pet e vendedor de carne, com coordenadas do Naowh) |
| `Dicas.lua` | `GuiaForeverDicas[CLASSE]`. As listas `magias`, `armas`, `pets`, `rotacao`, `atributos` e `notas` trazem os campos opcionais da 1.0 (`tags`, `raca`, `zona`, `requer`, `magia`, `prio`). A lista nova `petTreino` guarda as habilidades de pet do plano |
| `PetGuia.lua` | gerado (1.1): `GuiaForeverPetGuia`, famílias, habilidades, ranks, professores, regras e notas; nunca editar à mão |
| `Ajuda.lua` | `GuiaForeverAjuda[CLASSE]`: 14 perguntas (13 até a 1.0.1) do dono com as respostas das fontes, para a aba Help (1.0) |
| `ProfissoesA.lua`, `ProfissoesB.lua` | roteiros das 10 profissões |
| `GuiaForever.lua` | núcleo: profissões, gráficos, macros e comandos `/guia`; funções compartilhadas em `ns` |
| `Estado.lua` | base comum da 1.0: eventos (`ns.ao`), debounce, fila de depois do combate, estado do jogo (`ns.estado`), magias conhecidas, livro do pet, pontos de talento por `C_Traits`, missões, uma seta só (`ns.seta`, pelo TomTom ou pela seta nativa), tecla de uma ação (`ns.teclaDe`) e o filtro das dicas (`ns.relevante`) |
| `Visual.lua` | `ns.ui` (1.2): skin do ElvUI com reserva plana, fontes, cores, ícones e o desenhista dos blocos (`ns.ui.desenhar`) |
| `Janela.lua` | a casca da janela J (1.2): cabeçalho de estado, navegação à esquerda, busca (`ns.buscarJanela`), sub-abas, redimensionar e "Show all"; tecla J e botão do livro. Não constrói conteúdo |
| `Treinadores.lua` | Questie e minimapa com os treinadores; seta para o treinador de classe, de profissão ou de pet (`/guia trainer pet`) |
| `SkinDB.lua` | as 924 criaturas com loot de Skinning (cmangos/classic-db) |
| `Zona.lua` | linha de Skinning no tooltip dos bichos, diário de calibração e `ns.bichosDaZona` (1.0) |
| `Teclas.lua` | `GuiaForeverTeclas[CLASSE]`. Desde a 1.0, a lista confere cada tecla contra a barra real e avisa quando o botão está vazio ou o pet ainda não sabe a habilidade |
| `Rastreador.lua` | rastreador de profissões embaixo do minimapa (fonte 13 na 1.0), "Skin here" no tooltip e a linha do painel quando a profissão trava no teto do treino |
| `Agora.lua` | o painel Agora e os provedores de talento, de treino de classe (pelo Naowh) e de teclas novas |
| `Lembretes.lua` | 1.3: provedores de lembrete de buff fora de combate (`lembretes`) e de marcos de nível (`marcos`), e as macros refeitas pela magia conhecida (`GuiaForeverMacros[classe].gerenciadas`) |
| `Familias.lua` | aba Families e Next ability upgrades (1.1): `ns.petRanks`, `ns.blocosProximosRanks`, `ns.blocosFamilias` |
| `Pet.lua` | provedor do pet (ausente, fome, comida, missão, treino, autocast do Growl), macro `feed_Pet` e as marcas no treinador de pet |
| `Arvore.lua` | plano de talentos (`ns.arvore.plano`, `ns.arvore.proximo`) e as marcas na árvore de talentos do Forever |
| `Tooltips.lua` | linhas do guia nos tooltips de item ("Your pet can eat this"), de magia (tecla e uso) e de ação do pet (autocast) |
| `Abas.lua` | construtores das abas (1.2): Now, Pet, Families (repasse), Talents, Combat, Professions e Help, mais `ns.abasEstado` e `ns.abaVisivel` |
| `Bindings.xml` | a ação `GUIAFOREVER_JANELA` |

Classes com dados: HUNTER (Hexumlite Bull), SHAMAN (Rurik Thunderfist) e, desde a 1.3, PALADIN (Ignatius Stonejaw). O pet é do caçador; o painel, as marcas na árvore, as teclas e as macros valem para o caçador e o paladino; o xamã usa a janela.

## No jogo

| Onde | O quê |
|---|---|
| Embaixo do RestedXP | Painel "Now" com até 4 linhas: faixa vermelha para o que te prejudica agora, laranja para tarefa na cidade, amarela para quando der e azul para aviso. O clique no texto abre o J no assunto; o botão da linha põe a seta, abre o planejador ou mostra a tecla; o botão direito esconde a linha até o texto mudar. Nos primeiros 30 s depois de entrar, o painel mostra "Next 3" |
| Ctrl+1 | macro `feed_Pet`: alimenta com a melhor comida da bolsa que o pet come (nasce quando o Feed Pet é aprendido) |
| Treinador de pet | selo "PLAN" na próxima graduação do plano e um painel à direita com os pontos de treino; você compra com o botão Train da própria janela |
| Árvore de talentos | selo "NOW" no ponto do nível, níveis nos seguintes, check nos feitos e, do 22 em diante, "ALL" e "?"; faixa "Plan:" no alto; você aplica o ponto |
| Tooltips | comida: "Your pet can eat this"; magia: "Key:" e "Use:" das fontes; Growl e Cower: o autocast das fontes |
| J, botão do livro, `/guia` | a janela; `/guia now`, `pet`, `talents`, `combat`, `professions`, `help` (e os nomes antigos) abrem a aba |
| `/guia trainer class`, `/guia trainer pet`, `/guia trainer <profissão>` | seta para o treinador mais perto |
| `/guia tudo`, `/guia prof` | ordem completa dos talentos e roteiro das profissões no chat |
| `/guia rastreador`, `/guia macros`, `/guia graficos` | rastreador, macros e perfil gráfico |

O que roda sozinho fica guardado em `GuiaForeverDB` (SavedVariables da conta):

| Quando | O quê | Chave |
|---|---|---|
| uma vez por conta, no carregamento | Questie com os treinadores ligados | `treinadores.questie` |
| uma vez por conta, no login | perfil gráfico | `graficos` |
| 8 s depois do login, por personagem | macros da classe (de novo só quando `versao` sobe), tecla J (só se livre), rastreamento de treinadores do minimapa | `macros`, `tecla`, `treinadores.rastreio` |
| fora de combate, quando a bolsa, o pet ou as magias mudam | a macro `feed_Pet` | `macros[personagem].gerenciadas` |
| o tempo todo | linhas escondidas do painel e estado das seções da janela | `personagens[...].agoraOcultos`, `secoes` |

Para desfazer:

| Comando | O que volta |
|---|---|
| `/guia macros undo` | apaga as macros criadas pelo guia, inclusive a `feed_Pet`, se você não as editou |
| `/guia graphics undo` | volta o perfil gráfico |
| `/guia key undo` | solta a tecla J |
| `/guia trainers undo` | desliga os treinadores no Questie e no minimapa |

Uma linha do painel some com o botão direito e volta na aba Now do J, em "Hidden".

## Rastreador de profissões (0.6.0; 0.9.1; 1.0)

O rastreador mostra uma linha por profissão planejada com meta na faixa da área (`Skinning 42 / 75`), verde quando bate a meta e com "teto N" quando o treino trava abaixo dela. As metas foram aprovadas pelo dono: 1-10, 75 e 75; 10-20, Skinning 125 e Leatherworking 100; 20-30, Skinning 150 e Leatherworking 125 (era 150 até 2026-11-13; na rota do ReptilioPlays o Heavy Hide entra no 125). A ligação zona → faixa é do agente e está a conferir. Desde a 0.9.1, ele fica embaixo do último quadro visível da pilha do minimapa. Na 1.0, a letra passa a 13, o tooltip ganha "Skin here" com os 3 melhores bichos da zona, e a profissão travada no teto vira uma linha laranja no painel, com seta para o treinador.

## Zona e calibração de cor (0.8.0; 1.0)

A linha "Skinning: needs N" do tooltip e a seção da zona na aba Professions usam `SkinDB.lua` e o Questie. A perícia mínima segue o wow.gg (04/11/2026). As faixas de cor ficam em `FAIXAS`. Na 1.0, o laranja vai até 24 acima da mínima, calibrado por 1 transição do diário (nightsaber de nível 6: laranja até a perícia 24 e amarelo com 25). Amarelo e verde seguem estimados. O diário (`skinCores`, `skinLog`, `skinAprendidos`) continua gravando.

## Como mudar e validar

1. Edite os dados (`Dicas.lua`, `Dados.lua`, `Ajuda.lua`) com a fonte e a origem de cada linha. Macro nova: acrescente na lista e suba a `versao` do conjunto.
2. Valide, a partir de `modder\ferramentas\guia\` (na primeira vez, `npm install` ali e as listas da API pelo comando em `api-forever-baixar.txt`):
   - `node checar-lua.mjs ..\..\addons-proprios\GuiaForever --globais`: sintaxe Lua 5.1 e ASCII; desde 2026-11-08, também escape inválido em string entre aspas (o Lua 5.1 aceita `"\I"` e guarda só o `I`, então um caminho com barra simples quebra sem erro).
   - `node checar-dicas.mjs ..\..\addons-proprios\GuiaForever\Dicas.lua` e `node checar-ajuda.mjs ..\..\addons-proprios\GuiaForever\Ajuda.lua`: esquema dos dados.
   - `node checar-combate.mjs ..\..\addons-proprios\GuiaForever --toc`: chamada protegida sem guarda de combate, API que vira secreta, função ou evento que não existe no Forever, template inexistente, chamada proibida (compra, magia, gastar ponto) e `.toc` diferente dos arquivos.
   - `node rodar-casos.mjs` e `node rodar-casos-combate.mjs`: os casos de teste dos checadores.
   - `node rodar-janela.mjs --estrito --abrir --desenhar` (1.2): roda o addon fora do jogo no fengari, num estado fixo (caçador 16, javali 16), monta cada aba e sub-aba, confere os blocos contra a seção 11 do `ARQUITETURA.md` (tipos, campos, fonte na tela, códigos de texto, tamanho), abre a janela e passa tudo pelo desenhista; `--pular` roda o cenário do treino pulado; `RESUMO erros=0` é o pronto. Ele grava `ferramentas\guia\visual\real.html`, e `node visual\renderizar.mjs --html real.html agora pet` fotografa as abas em `visual\png\real-*.png` (prévia aproximada; quem desenha no jogo é o `Visual.lua`).
   - `node rodar-janela.mjs --classe PALADIN --estrito --abrir --desenhar --paladino` (1.3): o mesmo banco como o Ignatius (Human, nível 27, 1 ponto livre, sem pet; `--nivel`, `--livres`, `--com-furia` e `--sem "<magia>"` mudam o estado). O `--paladino` confere as opções lado a lado, o lembrete de Righteous Fury (some com o buff e volta sem ele), os marcos do 12 e do 22, a `cleanse_Mouse` (Purify no 27, Cleanse no 42) e, num processo filho, que o caçador não ganha nada disso; `PALADINO falhas=0` é o pronto. Grava `visual\real-PALADIN.json` e `.html` (o `real.json` continua do caçador).
3. Função nova do cliente: confira nas listas de `api-forever\` e, para a assinatura, no espelho `Ketho/wow-ui-source-forever`; o caminho está em `..\..\..\comum\referencia\api-forever.md`, seções 3 e 3e.
4. Mudou só `.lua` que já existia: `/reload`. Arquivo novo ou `.toc` mudado: reiniciar o jogo.
5. Guia de pets (1.1), a partir de `modder\ferramentas\guia\pets\` (o cache fica em `cache\`, fora do git):
   - fatos do cliente: `node gerar-habilidades.mjs --build <build> --cache cache` e `node checar-habilidades.mjs habilidades.json`;
   - professores e feras: `node gerar-professores.mjs --cache cache --saida-dir .` e `node checar-professores.mjs` (relê a Forever-Hunter-Pets pelo sha mais novo e a Petopia);
   - cartões do Saltii (`saltii.json`, `node checar-saltii.mjs`), fala do Saltii (`saltii-fala.json`, `node checar-saltii-fala.mjs`), tier list do LudiDeo (`ludideo-tier.json`, `node checar-ludideo-tier.mjs`) e textos-base das fontes (`textos-base.json`): editados a partir de `comum\fontes\builds\`; `node juntar-textos.mjs` junta tudo no `textos.json` e `node checar-textos.mjs` confere;
   - junção: `node gerar-guia.mjs --pasta . --petopia cache\petopia-abilities.html --lua ..\..\..\addons-proprios\GuiaForever\PetGuia.lua` e `node checar-guia.mjs`;
   - PDF: `node gerar-pdf.mjs --json guia.json --pdf "P:\Meu Drive\WoW Forever\Guias\guia-pets-cacador.pdf"`.
   Depois, `checar-lua.mjs` e `checar-combate.mjs` na pasta do addon, e `/reload` no jogo (o `PetGuia.lua` já está no `.toc`).

## Pendente

**Teste da 1.3 no jogo (paladino).** Sair e entrar no jogo (arquivo novo no `.toc`). Depois, no Ignatius: `/uif bars` uma vez (UIForever 0.7.0) e conferir os botões; painel Now (os marcos aparecem no 12, 20, 22 e 40; o lembrete de Righteous Fury, a partir do 10); macros na janela de macro (`/macro`, aba do personagem); J > Talents com "Your pick" quando chegar ao 15; a árvore com as letras A, B e C; BugSack sem erro do GuiaForever nem do UIForever. A conferir no jogo: o `GetAuraDataBySpellName` fora de combate, a macro que entra no botão só quando a magia dela é aprendida (`espera`, UIForever 0.7.0) e o ícone `Ability_MeleeDamage` da `attack_Start`.

**Teste da 1.2 no jogo.** Reiniciar o jogo (dois arquivos novos no `.toc`). Depois: J abre a janela nova; trocar de aba e de sub-aba; arrastar a alça do canto; Families com o javali marcado e a régua; Combat > Keys com a grade; Professions > Mine com o roteiro de Leatherworking; buscar "boar"; Esc fecha; BugSack sem erro do GuiaForever. A conferir no jogo: as texturas de estado (marca, x, cadeado), a skin do ElvUI nos controles, o retrato do pet e os ícones de talento por `C_Traits`.


**Teste da 1.0 no jogo.** Ele começa por reiniciar o jogo: a 1.0 tem 6 arquivos novos no `.toc`, e o `/reload` não basta. A lista completa está no relatório da sessão de 2026-11-07, na ordem em que o dono encontra as coisas:

1. painel embaixo do RestedXP;
2. vendedor à direita dele;
3. painel some em combate;
4. seta da Jocaste e do Keldas;
5. Ctrl+1 depois do Feed Pet;
6. tooltip da comida;
7. treinador de pet;
8. árvore de talentos;
9. janela J;
10. BugSack vazio.

Ainda sem teste no jogo:

| O quê | Desde |
|---|---|
| macro `sting_Auto` (o "!" e o "null") | 0.4.0 |
| `mark_Conc` | 0.8.0 |
| ligação zona → faixa do rastreador | 0.6.0 |

**Lacunas sem fonte:**

| Classe | O que falta |
|---|---|
| Caçador | magias do 31 ao 60 (exceto o 40); talentos do Hexumlite do 22 ao 60 (seis pontos em aberto, na ficha) |
| Xamã | magias do 1 ao 9 e do 33 ao 45; armas por nome |
