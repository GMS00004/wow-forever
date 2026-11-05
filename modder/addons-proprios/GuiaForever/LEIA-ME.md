# GuiaForever

Addon próprio do dono, versão 0.5.0 (2026-11-05). Leva para dentro do jogo o que as fontes do dono dizem: talento por nível, dicas por nível (magias, armas, pets, rotação, atributos), roteiro das profissões, treinadores, macros do caçador e o perfil gráfico. Está ligado ao jogo por junction (`ferramentas\dev-link.ps1`, manifesto `estado\addons\dev-guiaforever.json`): editar aqui é editar o que o jogo carrega.

## Regra do conteúdo

Nada de gameplay sai da cabeça do agente. Cada dica vem de uma fonte em `..\..\..\comum\fontes\` ou de uma ficha em `..\..\..\comum\personagens\`, com a fonte no campo `fonte` e a origem (arquivo e linha) num comentário. Onde as fontes divergem, o dono escolhe; as escolhas estão na tabela "Decisões do dono" da ficha de cada personagem. Fonte anterior a 03/11 entra marcada "(beta)". Lacuna fica como "sem fonte" no jogo.

## Arquivos (na ordem do `.toc`)

| Arquivo | O que tem |
|---|---|
| `Dados.lua` | `GuiaForeverDados[CLASSE]` (talento por nível, `lei` e `aberto`), `GuiaForeverMacros[CLASSE]` (macros, com `versao`), `GuiaForeverGraficos` (CVars do perfil gráfico), `GuiaForeverProfissoesPlanejadas[CLASSE]` (profissões decididas pelo dono, para a aba Treinos) |
| `Dicas.lua` | `GuiaForeverDicas[CLASSE] = { personagem, magias = {{nivel, texto, fonte}}, armas/pets/rotacao = {{de, ate, texto, fonte}}, atributos, notas = {{texto, fonte}} }`; só ASCII, texto até 160 caracteres, fontes da lista do checador |
| `ProfissoesA.lua`, `ProfissoesB.lua` | roteiros das 10 profissões (`passos` por faixa de perícia e `treino` com nomes e lugares de treinadores) |
| `GuiaForever.lua` | núcleo: anúncio a cada nível, dicas do nível no chat, profissões, gráficos, macros, comandos `/guia`; compartilha funções com os outros arquivos pela tabela `ns` (listas de ganchos `ns.aoCarregar` e `ns.aoEntrar`) |
| `Janela.lua` | janela com abas (Nível, Talentos, Armas, Pets, Rotação, Prof., Treinos) e rolagem, botão do livro perto do minimapa, tecla J |
| `Treinadores.lua` | liga no Questie os ícones de treinador (classe e profissões conhecidas), liga o rastreamento de treinadores do minimapa, seta do TomTom para o treinador mais perto (NPCs pela API pública do QuestieDB, contrato 4) |
| `Bindings.xml` | a ação `GUIAFOREVER_JANELA` (abre e fecha a janela) |

Classes com dados: HUNTER (Hexumlite Bull) e SHAMAN (Rurik Thunderfist). As outras classes usam só as abas Prof. e Treinos.

## No jogo

| Como | O quê |
|---|---|
| J, botão do livro, `/guia` | abre e fecha a janela |
| `/guia nivel`, `talentos`, `armas`, `pets`, `rotacao`, `treinos` | abre a janela na aba |
| `/guia tudo`, `/guia prof` | ordem completa dos talentos e roteiro das profissões no chat |
| `/guia treinador classe` ou `/guia treinador <profissão>` | seta do TomTom para o treinador mais perto da facção |
| `/guia macros`, `/guia graficos` | recria macros que faltam; mostra o perfil gráfico |

O que roda sozinho, e onde fica guardado em `GuiaForeverDB` (SavedVariables da conta):

| Quando | O quê | Chave |
|---|---|---|
| uma vez por conta, no carregamento | Questie: `townsfolkConfig["Class Trainer"]` e `townsfolkKnownProfessions` ligados | `treinadores.questie` |
| uma vez por conta, no login | perfil gráfico | `graficos` |
| 8 s depois do login, por personagem | macros da classe (de novo só quando `versao` sobe), tecla J (só se livre), rastreamento de treinadores do minimapa | `macros`, `tecla`, `treinadores.rastreio` |

Desfazer: `/guia macros desfazer`, `/guia graficos desfazer`, `/guia tecla desfazer`, `/guia treinadores desfazer` (o do Questie vale depois de `/reload`).

## Como mudar e validar

1. Edite os dados (`Dicas.lua`, `Dados.lua`) com a fonte e a origem de cada linha. Macro nova: acrescente na lista e suba a `versao` do conjunto, senão o login não a cria.
2. Valide, a partir de `modder\ferramentas\guia\` (na primeira vez, `npm install` ali):
   - `node checar-lua.mjs ..\..\addons-proprios\GuiaForever --globais` (sintaxe Lua 5.1, ASCII e as globais de cada arquivo, para conferir contra a API);
   - `node checar-dicas.mjs ..\..\addons-proprios\GuiaForever\Dicas.lua` (esquema e regras dos dados);
   - `node rodar-casos.mjs` (o checador barra os 7 casos ruins e passa o bom).
3. Função nova do cliente: confira no espelho `Ketho/wow-ui-source-forever` (como em `..\..\..\comum\referencia\api-forever.md`, seção 3); função de outro addon, nos arquivos instalados em `_forever_\Interface\AddOns`.
4. Mudou só `.lua` que já existia: `/reload`. Arquivo novo ou `.toc` mudado: reiniciar o jogo.

## Pendente

- Teste no jogo da 0.5.0: J e o botão abrem a janela; as abas mostram o personagem; no próximo nível sai a dica no chat; o mapa mostra os treinadores do Questie; o botão de Leatherworking da aba Treinos põe a seta do TomTom; o BugSack fica vazio.
- Lacunas sem fonte: magias do caçador do 31 ao 60 (exceto o 40); do xamã do 1 ao 9 e do 33 ao 45; armas do xamã por nome; atributos do caçador só de fonte beta (MetaGoblin). Talentos do Hexumlite do 22 ao 60 em aberto (seis pontos, na ficha), mostrados como "A decidir".
