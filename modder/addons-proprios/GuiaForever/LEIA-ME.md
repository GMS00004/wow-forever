# GuiaForever

Addon próprio do dono, versão 0.5.0 (2026-11-05). Leva para dentro do jogo o que as fontes do dono dizem: talento por nível, dicas por nível (magias, armas, pets, rotação, atributos), roteiro das profissões, treinadores, macros do caçador e o perfil gráfico. Está ligado ao jogo por junction (`ferramentas\dev-link.ps1`, manifesto `estado\addons\dev-guiaforever.json`): editar aqui é editar o que o jogo carrega.

Versão 0.7.0 (2026-11-06): todo o texto do jogo foi traduzido para inglês a pedido do dono, com apelidos de subcomando em inglês (`/guia level`, `talents`, `weapons`, `rotation`, `trainers`, `all`, `tracker`, `graphics`, `trainer class|<profession>`, e `undo` no lugar de `desfazer`); os subcomandos em português continuam valendo.

## Regra do conteúdo

Nada de gameplay sai da cabeça do agente. Cada dica vem de uma fonte em `..\..\..\comum\fontes\` ou de uma ficha em `..\..\..\comum\personagens\`, com a fonte no campo `fonte` e a origem (arquivo e linha) num comentário. Onde as fontes divergem, o dono escolhe; as escolhas estão na tabela "Decisões do dono" da ficha de cada personagem. Fonte anterior a 03/11 entra marcada "(beta)". Lacuna fica como "sem fonte" no jogo.

## Arquivos (na ordem do `.toc`)

| Arquivo | O que tem |
|---|---|
| `Dados.lua` | `GuiaForeverDados[CLASSE]` (talento por nível, `lei` e `aberto`), `GuiaForeverMacros[CLASSE]` (macros, com `versao`), `GuiaForeverGraficos` (CVars do perfil gráfico), `GuiaForeverProfissoesPlanejadas[CLASSE]` (profissões decididas pelo dono, para a aba Treinos) |
| `Dicas.lua` | `GuiaForeverDicas[CLASSE] = { personagem, magias = {{nivel, texto, fonte}}, armas/pets/rotacao = {{de, ate, texto, fonte}}, atributos, notas = {{texto, fonte}} }`; só ASCII, texto até 160 caracteres, fontes da lista do checador |
| `ProfissoesA.lua`, `ProfissoesB.lua` | roteiros das 10 profissões (`passos` por faixa de perícia e `treino` com nomes e lugares de treinadores) |
| `GuiaForever.lua` | núcleo: anúncio a cada nível, dicas do nível no chat, profissões, gráficos, macros, comandos `/guia`; compartilha funções com os outros arquivos pela tabela `ns` (listas de ganchos `ns.aoCarregar` e `ns.aoEntrar`) |
| `Janela.lua` | janela com abas (Level, Talents, Weapons, Pets, Rotation, Keys, Prof., Zone, Trainers; 580 de largura desde a 0.8.0) e rolagem, botão do livro perto do minimapa, tecla J |
| `Treinadores.lua` | liga no Questie os ícones de treinador (classe e profissões conhecidas), liga o rastreamento de treinadores do minimapa, seta do TomTom para o treinador mais perto (NPCs pela API pública do QuestieDB, contrato 4) |
| `SkinDB.lua` | `GuiaForeverSkinDB[idDoNPC] = { nome, nivelMin, nivelMax, tipo }`: as 924 criaturas com loot de Skinning do cmangos/classic-db (0.8.0) |
| `Zona.lua` | aba Zone, linha de Skinning no tooltip dos bichos e diário de calibração (0.8.0; ver a seção abaixo) |
| `Teclas.lua` | `GuiaForeverTeclas[CLASSE]` e a aba Keys (0.8.0): o que cada tecla faz e a partir de que nível (ver a seção abaixo) |
| `Rastreador.lua` | rastreador discreto de profissões embaixo do minimapa (0.6.0): perícia / meta da área de quest atual, por `GuiaForeverRastreador` do `Dados.lua`; mouse em cima mostra área, faixa, teto e o passo do roteiro |
| `Bindings.xml` | a ação `GUIAFOREVER_JANELA` (abre e fecha a janela) |

Classes com dados: HUNTER (Hexumlite Bull) e SHAMAN (Rurik Thunderfist). As outras classes usam só as abas Prof. e Treinos.

## No jogo

| Como | O quê |
|---|---|
| J, botão do livro, `/guia` | abre e fecha a janela |
| `/guia nivel`, `talentos`, `armas`, `pets`, `rotacao`, `treinos` | abre a janela na aba |
| `/guia tudo`, `/guia prof` | ordem completa dos talentos e roteiro das profissões no chat |
| `/guia treinador classe` ou `/guia treinador <profissão>` | seta do TomTom para o treinador mais perto da facção |
| `/guia rastreador` | mostra ou esconde o rastreador de profissões embaixo do minimapa (lembrado em `GuiaForeverDB.rastreadorOculto`) |
| `/guia macros`, `/guia graficos` | recria macros que faltam; mostra o perfil gráfico |

O que roda sozinho, e onde fica guardado em `GuiaForeverDB` (SavedVariables da conta):

| Quando | O quê | Chave |
|---|---|---|
| uma vez por conta, no carregamento | Questie: `townsfolkConfig["Class Trainer"]` e `townsfolkKnownProfessions` ligados | `treinadores.questie` |
| uma vez por conta, no login | perfil gráfico | `graficos` |
| 8 s depois do login, por personagem | macros da classe (de novo só quando `versao` sobe), tecla J (só se livre), rastreamento de treinadores do minimapa | `macros`, `tecla`, `treinadores.rastreio` |

Desfazer: `/guia macros desfazer`, `/guia graficos desfazer`, `/guia tecla desfazer`, `/guia treinadores desfazer` (o do Questie vale depois de `/reload`).

## Rastreador de profissões (0.6.0, 2026-11-06)

Pedido do dono: ver de forma discreta até que perícia subir cada profissão antes de sair da área de quest. Escolhas dele em 2026-11-06: meta pelo nível da área, a partir das fontes dele, e o rastreador embaixo do minimapa.

- **O que mostra:** uma linha por profissão planejada da classe (`GuiaForeverProfissoesPlanejadas`) que tem meta na faixa da área: `Skinning 42 / 75`, em verde quando a meta foi batida. Quando o teto do treino atual fica abaixo da meta, aparece "teto N" em amarelo. Profissão ainda não aprendida aparece em cinza, com "aprender". Some em combate (`esconderEmCombate`) e quando não há meta.
- **Metas** (`GuiaForeverRastreador.faixas`, números aprovados pelo dono): 1–10, Skinning 75 e Leatherworking 75; 10–20, Skinning 125 e Leatherworking 100; 20–30, Skinning 150 e Leatherworking 150. Saem do wow-professions (Skinning por nível de bicho) e do Gfinity (Leatherworking pelo couro de cada faixa); 75 também é o teto do Apprentice.
- **Zona → faixa** (`GuiaForeverRastreador.zonas`, pelo `GetRealZoneText`): Teldrassil, Elwynn Forest e Dun Morogh na 1–10; Darkshore, Westfall, Loch Modan e Redridge Mountains na 10–20; Ashenvale, Wetlands, Duskwood, Stonetalon Mountains e Hillsbrad Foothills na 20–30. A ligação é do agente, pelo nível típico dos bichos de cada zona, e está a conferir. Fora da lista (cidade, zona nova do Forever), vale a faixa do nível do personagem.
- **Perícia e teto:** `ns.minhasProfissoes()` lê primeiro `C_SkillInfo.GetNumSkillLines` e `C_SkillInfo.GetSkillLineInfo(i)` (tabela com `name`, `isHeader`, `rank` e `maxRank`; é a API que a janela de perícias do Forever usa, `Blizzard_UIPanels_Game/Camelot/SkillsFrame.lua`). As globais antigas (`GetProfessions` com `GetProfessionInfo`, e `GetSkillLineInfo`) ficam de reserva, e não foi conferido se existem no cliente. Até a 0.5.0, a leitura usava só as globais antigas: se elas não existirem no Forever, o `/guia prof` e a aba Prof. nunca acharam profissão.
- **Lugar:** `TOP` do quadro preso ao `BOTTOM` do último quadro visível da pilha embaixo do minimapa (`Minimap`, depois `MinimapPanel` e as barras de dados do ElvUI, como a `ElvUI_ReputationBar`), contando só os que estão na coluna do minimapa e encostados no de cima (folga de 12 unidades). Desde a 0.9.1: na 0.6.0 ele ficava preso ao `MinimapPanel` e a barra de reputação, que o ElvUI põe logo abaixo do painel, cobria a primeira linha (print do dono de 06/11, 22h56). Reposiciona a cada atualização e quando um quadro da pilha aparece ou some (`HookScript` de `OnShow` e `OnHide`).

## Aba Zone (0.8.0)

Na zona onde o jogador está, lista cada bicho esfolável com a perícia de Skinning que ele pede e até onde dá ponto, com um botão de seta do TomTom para os até 6 mais úteis, e põe uma linha "Skinning: needs N" no tooltip dos bichos (`/guia zone`). Sem Skinning, mostra a lista com perícia 0.

- **Dados:** `SkinDB.lua` (924 criaturas com loot de Skinning, do banco aberto cmangos/classic-db, GPL-3.0); locais e níveis vêm do QuestieDB e do ZoneDB do Questie, lidos só depois de `Questie.API.isReady`. A perícia mínima segue wow.gg/professions/forever/skinning (04/11/2026): até o nível 10 pede 1, de 11 a 20 pede (nível - 10) x 10, do 21 em diante nível x 5.
- **Estimativa:** as faixas de cor (laranja até mínima+25, amarelo até +50, verde até +100, cinza depois) são a regra dos nós de coleta, a confirmar; ficam na tabela `FAIXAS` no topo de `Zona.lua` e aparecem marcadas "estimated". Os níveis de personagem dos treinos (10, 20, 35) vêm do addon Naowh (inferência).
- **Diário de calibração** (`GuiaForeverDB`): `skinCores` (cor da linha "Skinnable" do cadáver, com nível e perícia, até 400), `skinLog` (nível do alvo e perícia antes e depois de cada esfolada, até 400) e `skinAprendidos` (bichos esfoláveis que não estão no SkinDB). Nada disso roda em combate; se a API negar o dado, o addon fica sem ele.

Correções da sessão principal no gate: o diário de cores grava uma vez por cadáver e perícia (o tooltip de unidade se refaz várias vezes com o mouse em cima), e o nível do cadáver esfolado vem primeiro do `mouseover`, depois do `softinteract` e só então do alvo (quem esfola clicando nem sempre está com ele no alvo).

## Aba Keys (0.8.0)

Pedido do dono em 2026-11-06: "um guia de cada nível, qual macro eu vou usar a partir de cada nível, e das minhas hotkeys". A aba mostra, no nível do personagem, o que é novo neste nível, o que cada tecla já faz (por grupo: barra principal, barra do Shift, barra 2 e mouse, pet, outras teclas, só clique), o que chega nos próximos 6 níveis e o resto depois (`/guia keys`).

- **Dados:** `Teclas.lua`, montado a partir do cruzamento das fontes de 2026-11-06 (UIForever `Config.lua`, macros do `Dados.lua`, `Dicas.lua`, fontes de `comum\fontes\builds\`). Nível de cada magia: das fontes do dono; onde elas não dão, dos dados do Training Planner do Naowh Forever (`NaowhForever_Training\Data\TrainingData.lua`, gerado do cliente 1.60.1.70790), marcados `f = "Naowh"`.
- **Manutenção:** ao mudar uma tecla ou um botão no UIForever, mude a linha correspondente aqui. A tabela não lê os botões do jogo; é um mapa escrito.

## Como mudar e validar

1. Edite os dados (`Dicas.lua`, `Dados.lua`) com a fonte e a origem de cada linha. Macro nova: acrescente na lista e suba a `versao` do conjunto, senão o login não a cria.
2. Valide, a partir de `modder\ferramentas\guia\` (na primeira vez, `npm install` ali):
   - `node checar-lua.mjs ..\..\addons-proprios\GuiaForever --globais` (sintaxe Lua 5.1, ASCII e as globais de cada arquivo, para conferir contra a API);
   - `node checar-dicas.mjs ..\..\addons-proprios\GuiaForever\Dicas.lua` (esquema e regras dos dados);
   - `node rodar-casos.mjs` (o checador barra os 7 casos ruins e passa o bom).
3. Função nova do cliente: confira no espelho `Ketho/wow-ui-source-forever` (como em `..\..\..\comum\referencia\api-forever.md`, seção 3); função de outro addon, nos arquivos instalados em `_forever_\Interface\AddOns`.
4. Mudou só `.lua` que já existia: `/reload`. Arquivo novo ou `.toc` mudado: reiniciar o jogo.

## Pendente

- Teste no jogo da 0.8.0 (arquivos novos no `.toc`: reiniciar o jogo, não basta `/reload`): abas Keys e Zone abrem e cabem na janela; a Zone lista os bichos de Teldrassil ou Darkshore com cores e o botão de seta funciona; o tooltip de um bicho mostra "Skinning: needs N"; depois de esfolar alguns, com o jogo fechado, conferir `skinCores` e `skinLog` no `GuiaForever.lua` das SavedVariables (se a cor da linha "Skinnable" varia com a perícia, dá para trocar a estimativa das `FAIXAS` pelos números reais). A macro `mark_Conc` no 5 (conjunto de macros na versão 4): 1o aperto marca e manda o pet, os seguintes soltam o Concussive Shot.

- Teste no jogo da 0.6.0 (precisa reiniciar o jogo: arquivo novo no `.toc`): o rastreador aparece embaixo do minimapa, mostra Skinning e Leatherworking com a meta de Teldrassil, some em combate, e o `/guia prof` passa a achar as profissões; conferir a ligação de cada zona a uma faixa.
- Teste no jogo da macro `sting_Auto` (conjunto de macros na versão 2, 2026-11-05 à noite): fora de combate a tecla 1 só liga o Auto Shot; o aperto seguinte, já em combate, solta o Serpent Sting; os outros não desligam o Auto Shot; Alt+1 reaplica o Sting. A J abre o guia pelo UIForever (`UIForeverConfig.teclas`), porque a J era da janela de guilda.
- Teste no jogo da 0.5.0: J e o botão abrem a janela; as abas mostram o personagem; no próximo nível sai a dica no chat; o mapa mostra os treinadores do Questie; o botão de Leatherworking da aba Treinos põe a seta do TomTom; o BugSack fica vazio.
- Lacunas sem fonte: magias do caçador do 31 ao 60 (exceto o 40); do xamã do 1 ao 9 e do 33 ao 45; armas do xamã por nome; atributos do caçador só de fonte beta (MetaGoblin). Talentos do Hexumlite do 22 ao 60 em aberto (seis pontos, na ficha), mostrados como "A decidir".
