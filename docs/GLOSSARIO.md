# Glossário

Os termos que aparecem no repositório, em ordem alfabética.

| Termo | O que é |
|---|---|
| Addon próprio | addon escrito neste repositório, em `modder\addons-proprios\`, ligado ao jogo por junction |
| Agente | um assistente de IA com instruções e ferramentas próprias, que roda no Claude Code; aqui, o wow-modder |
| Auctionator | addon de leilão; o GuiaForever guarda a exportação dos preços que ele viu, e as ferramentas de preço leem |
| Bancada | um teste que roda o código Lua do addon fora do jogo, no fengari, com uma imitação mínima da API do jogo e cenários fixos |
| Bootstrap | a primeira sessão de um jogador: achar o jogo, montar o perfil, instalar o pacote base e planejar a UI |
| BugSack e BugGrabber | addons que capturam os erros de Lua; com o jogo fechado, os erros ficam em `WTF\Account\<conta>\SavedVariables\BugGrabber.lua` |
| Casa de leilão | o Forever não tem reino: há uma casa de leilão por região, ruleset (PvP, Normal...) e facção, com um número (a Horda PvP é a 113, a Aliança Normal, a 111); as ferramentas de preço usam `us-113`, `eu-113` e assim por diante |
| Checador | um script que lê o código de um addon e acusa problema sem rodá-lo (sintaxe, regra de combate, dado fora do esquema) |
| Claude Code | o programa da Anthropic que roda os agentes, no terminal ou no VS Code |
| CVar | variável de configuração do cliente (gráfico, som, interface), gravada no `WTF\Config.wtf` |
| ElvUI | addon que troca a interface inteira do jogo; é a base de UI do pacote, e o UIForever grava o layout nele |
| fengari | um interpretador Lua escrito em JavaScript, usado nas bancadas |
| Flavor | a variante do cliente dentro da pasta do World of Warcraft; a do Forever é a pasta `_forever_` |
| Fonte (de gameplay) | um guia que o jogador segue (build, macros, rota, profissão), guardado em `comum\fontes\`; o agente configura a partir dela e não opina sem ela |
| Função protegida | função do jogo que addon não pode chamar em combate (criar macro, mexer em barra, trocar tecla); chamar dá erro de "ação bloqueada" |
| Handoff | nota de trabalho em andamento (`HANDOFF-*.md`) para retomar uma frente numa sessão nova |
| Interface | o número da versão da API de addons (16001 para o cliente 1.60.1); o `## Interface` do TOC precisa bater com o do cliente para o addon carregar sem aviso |
| Jogador ativo | a pasta de `jogadores\` que este PC usa, apontada pelo `jogador-ativo.txt` da raiz |
| Junction | um atalho de pasta do Windows (ponto de junção): a pasta do addon fica no repositório e aparece também dentro de `AddOns` |
| Legacy point | a recompensa do Forever por levar uma profissão de ofício a certos marcos (150, 225); as ferramentas de preço calculam quanto custa |
| Manifesto | o arquivo `estado\addons\<slug>.json` que os scripts gravam para cada addon instalado (fonte, versão, pastas, hash, aprovação) |
| Pacote base | a lista de addons que o agente propõe no bootstrap, em `comum\referencia\pacote-base.md` |
| Prévia | o que um script mostra sem `-Aplicar`: o que faria, sem gravar nada |
| SavedVariables | os arquivos `.lua` em que cada addon guarda a configuração e os dados, dentro do `WTF`; o jogo regrava ao sair, por isso só se editam com o jogo fechado |
| Slug | o nome curto de um addon nos manifestos e nos comandos, em minúsculas (`questie`, `elvui`) |
| TOC | o arquivo `.toc` de cada addon: nome, versão, Interface e a lista de arquivos que o jogo carrega |
| Valor secreto | dado de combate que o cliente do Forever esconde dos addons durante a luta (dano, threat em porcentagem): dá para mandar para a tela, não para comparar nem fazer conta; contornar isso é proibido aqui |
| WTF | a pasta de configuração do cliente (`Config.wtf`, contas, personagens, SavedVariables); o backup dela vai para `%LOCALAPPDATA%\wow-agentes\backups\` |
| `wip(sync)` | commit automático do sync entre os dois notebooks do Bruno, que aparece no histórico até 2026-11-26 |
