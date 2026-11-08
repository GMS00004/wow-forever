# GuiaForever

Addon próprio do dono, versão 1.1.0 (2026-11-08: guia de habilidades de pet por família, aba Families e seção Next ability upgrades na aba Pet; ver "O que mudou na 1.1"). Antes: versão 1.0.1 (2026-11-07; a 1.0.1 só acrescenta à aba Help, seção Addons, as marcas de recompensa do RestedXP, o pular magia do Naowh e os preços no tooltip do Auctionator). Leva para dentro do jogo o que as fontes do dono dizem e o que ele decidiu sobre elas. Está ligado ao jogo por junction (`ferramentas\dev-link.ps1`, manifesto `estado\addons\dev-guiaforever.json`): editar aqui é editar o que o jogo carrega.

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
| `Janela.lua` | janela J (760 × 600, abas Now, Pet, Families (1.1), Talents, Combat, Professions e Help, busca, seções recolhíveis), botão do livro e tecla J; os ids antigos das abas continuam valendo (`ns.apelidosAba`) |
| `Treinadores.lua` | Questie e minimapa com os treinadores; seta para o treinador de classe, de profissão ou de pet (`/guia trainer pet`) |
| `SkinDB.lua` | as 924 criaturas com loot de Skinning (cmangos/classic-db) |
| `Zona.lua` | linha de Skinning no tooltip dos bichos, diário de calibração e `ns.bichosDaZona` (1.0) |
| `Teclas.lua` | `GuiaForeverTeclas[CLASSE]`. Desde a 1.0, a lista confere cada tecla contra a barra real e avisa quando o botão está vazio ou o pet ainda não sabe a habilidade |
| `Rastreador.lua` | rastreador de profissões embaixo do minimapa (fonte 13 na 1.0), "Skin here" no tooltip e a linha do painel quando a profissão trava no teto do treino |
| `Agora.lua` | o painel Agora e os provedores de talento, de treino de classe (pelo Naowh) e de teclas novas |
| `Familias.lua` | aba Families e Next ability upgrades (1.1): `ns.petRanks`, `ns.blocosProximosRanks`, `ns.blocosFamilias` |
| `Pet.lua` | provedor do pet (ausente, fome, comida, missão, treino, autocast do Growl), macro `feed_Pet` e as marcas no treinador de pet |
| `Arvore.lua` | plano de talentos (`ns.arvore.plano`, `ns.arvore.proximo`) e as marcas na árvore de talentos do Forever |
| `Tooltips.lua` | linhas do guia nos tooltips de item ("Your pet can eat this"), de magia (tecla e uso) e de ação do pet (autocast) |
| `Bindings.xml` | a ação `GUIAFOREVER_JANELA` |

Classes com dados: HUNTER (Hexumlite Bull) e SHAMAN (Rurik Thunderfist). O painel, o pet e as marcas são do caçador; as outras classes usam a janela.

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

O rastreador mostra uma linha por profissão planejada com meta na faixa da área (`Skinning 42 / 75`), verde quando bate a meta e com "teto N" quando o treino trava abaixo dela. As metas foram aprovadas pelo dono: 1-10, 75 e 75; 10-20, Skinning 125 e Leatherworking 100; 20-30, 150 e 150. A ligação zona → faixa é do agente e está a conferir. Desde a 0.9.1, ele fica embaixo do último quadro visível da pilha do minimapa. Na 1.0, a letra passa a 13, o tooltip ganha "Skin here" com os 3 melhores bichos da zona, e a profissão travada no teto vira uma linha laranja no painel, com seta para o treinador.

## Zona e calibração de cor (0.8.0; 1.0)

A linha "Skinning: needs N" do tooltip e a seção da zona na aba Professions usam `SkinDB.lua` e o Questie. A perícia mínima segue o wow.gg (04/11/2026). As faixas de cor ficam em `FAIXAS`. Na 1.0, o laranja vai até 24 acima da mínima, calibrado por 1 transição do diário (nightsaber de nível 6: laranja até a perícia 24 e amarelo com 25). Amarelo e verde seguem estimados. O diário (`skinCores`, `skinLog`, `skinAprendidos`) continua gravando.

## Como mudar e validar

1. Edite os dados (`Dicas.lua`, `Dados.lua`, `Ajuda.lua`) com a fonte e a origem de cada linha. Macro nova: acrescente na lista e suba a `versao` do conjunto.
2. Valide, a partir de `modder\ferramentas\guia\` (na primeira vez, `npm install` ali e as listas da API pelo comando em `api-forever-baixar.txt`):
   - `node checar-lua.mjs ..\..\addons-proprios\GuiaForever --globais`: sintaxe Lua 5.1 e ASCII.
   - `node checar-dicas.mjs ..\..\addons-proprios\GuiaForever\Dicas.lua` e `node checar-ajuda.mjs ..\..\addons-proprios\GuiaForever\Ajuda.lua`: esquema dos dados.
   - `node checar-combate.mjs ..\..\addons-proprios\GuiaForever --toc`: chamada protegida sem guarda de combate, API que vira secreta, função ou evento que não existe no Forever, template inexistente, chamada proibida (compra, magia, gastar ponto) e `.toc` diferente dos arquivos.
   - `node rodar-casos.mjs` e `node rodar-casos-combate.mjs`: os casos de teste dos checadores.
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
