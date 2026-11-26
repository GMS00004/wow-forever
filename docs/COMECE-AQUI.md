# Comece aqui

Do zero até o agente cuidando dos seus addons, para qualquer facção, reino e classe. Leva uns 20 minutos, a maior parte esperando download.

## 1. Instale o que falta

| Programa | Para quê | Como conferir |
|---|---|---|
| Windows 10 ou 11 | as ferramentas são Windows PowerShell 5.1, que já vem no Windows | `powershell -Command $PSVersionTable.PSVersion` mostra 5.1 |
| [Git](https://git-scm.com) | baixar e atualizar o repositório | `git --version` |
| [Node 24](https://nodejs.org) | ferramentas de preço e testes | `node --version` |
| [Claude Code](https://claude.com/claude-code) | o agente (CLI ou extensão do VS Code; precisa de uma assinatura do Claude ou de uma chave da API da Anthropic) | `claude --version` |
| WoW Forever | o jogo, instalado e aberto ao menos uma vez com um personagem | a pasta `_forever_` dentro da pasta do World of Warcraft |

O agente está configurado com o modelo `opus` (linha `model:` de `modder\.claude\agents\wow-modder.md`). Se o seu plano não tiver esse modelo, troque por `sonnet` nessa linha, só na sua cópia.

## 2. Baixe o repositório

Num caminho curto (o Windows limita caminhos a 260 caracteres):

```powershell
git clone https://github.com/GMS00004/wow-forever.git C:\jogos\wow-forever
cd C:\jogos\wow-forever\modder\ferramentas\guia
npm ci
node baixar-api-forever.mjs
```

Os dois últimos comandos são só para as ferramentas de preço e os testes; o agente funciona sem eles.

## 3. Crie a sua pasta de jogador

Tudo o que é só seu (personagens, instalação, a memória do agente) fica em `jogadores\<seu apelido>\`, que o git ignora. A partir de `C:\jogos\wow-forever\modder`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ferramentas\jogador.ps1 -Novo seuapelido
powershell -NoProfile -ExecutionPolicy Bypass -File ferramentas\jogador.ps1 -Novo seuapelido -Aplicar
```

O primeiro comando mostra o que vai ser criado; o segundo cria a pasta a partir de `jogadores\_modelo\` e grava o `jogador-ativo.txt` na raiz, que diz a todos os scripts e ao agente qual pasta usar neste PC. O apelido é em minúsculas, sem espaço nem acento.

## 4. Abra o agente

```powershell
cd C:\jogos\wow-forever\modder
claude
```

Ou, no VS Code, abra a pasta `modder` e o painel do Claude Code. O agente wow-modder carrega sozinho (o `modder\.claude\settings.json` aponta para ele). Diga "oi".

Na primeira sessão ele faz o bootstrap, nesta ordem, sempre mostrando a prévia e esperando o seu ok:

1. acha a pasta do jogo no seu PC e grava em `jogadores\<você>\instalacao.json`;
2. lê o idioma do cliente e os personagens do `WTF`;
3. pergunta de uma vez o que falta: facção, reino e tipo (PvP ou Normal), região, classes e quais guias você segue;
4. escolhe a casa de leilão das ferramentas de preço pelo mapa de `comum\referencia\forever.md` (Horda PvP é a 113, então `us-113` nas Américas ou `eu-113` na Europa);
5. propõe o pacote base de addons, um por um, com o que cada um muda, o custo e a alternativa, e instala o que você aprovar;
6. fecha com o plano da UI: no primeiro login, o ElvUI abre o assistente de instalação, e o agente conduz a partir do perfil que você escolher.

Com o jogo aberto, ele só lê e audita; o que grava na pasta do jogo espera você fechar o jogo, e sempre faz backup antes.

## 5. O dia a dia

Toda sessão começa sozinha com a abertura: backup do WTF, atualização dos addons que você já aprovou e uma auditoria da pasta `AddOns`, em até cinco linhas. Depois é conversa. Exemplos do que pedir:

| Você diz | O que acontece |
|---|---|
| "quero um addon de bolsa" | ele propõe um, diz o custo e a alternativa, confere a versão do Forever pelo TOC e instala com o seu ok |
| "deu erro no BugSack" | ele lê o erro no `BugGrabber.lua` (com o jogo fechado) ou pede para você colar, e propõe uma mudança por vez |
| "cria as macros do meu guia de warrior" | ele lê o guia em `comum\fontes\` (ou pede para você trazer um) e cria as macros e teclas |
| "volta o Questie para a versão de ontem" | ele restaura do backup que a atualização guardou |
| "quanto custa subir Alchemy até o 225 na minha casa?" | ele roda as ferramentas de preço com a sua casa de leilão |
| "vou parar" | ele escreve o diário da sessão e faz backup do WTF se mudou alguma UI |

O agente não opina sobre gameplay. Build, rotação, rota de quests e economia vêm dos guias que você escolhe; se você pedir algo de gameplay sem guia, ele pergunta qual seguir. Guia novo entra na biblioteca `comum\fontes\` (e pode ir por PR para todo mundo usar).

## 6. Atualizar o repositório

```powershell
cd C:\jogos\wow-forever
git pull
```

A sua pasta de jogador não é tocada pelo `git pull`. Depois de um pull que mudou o agente, abra uma sessão nova do Claude Code.

## 7. Sem o Claude Code

Dá para usar as peças sozinhas. Primeiro, crie a sua pasta de jogador (passo 3) e grave a instalação, que o agente faria no bootstrap. A partir de `modder`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command ". .\ferramentas\wow-comum.ps1; Find-WowInstalacao | ConvertTo-Json -Depth 4"
powershell -NoProfile -ExecutionPolicy Bypass -Command ". .\ferramentas\wow-comum.ps1; Set-WowInstalacao -Raiz 'C:\Program Files (x86)\World of Warcraft' -Flavor _forever_"
```

O primeiro mostra onde o jogo está; troque a `-Raiz` do segundo pelo que ele achou. Depois:

| Peça | Como |
|---|---|
| gerenciador de addons | os scripts de `modder\ferramentas\`, por exemplo `addon-instalar.ps1 -Fonte github:Questie/Questie -Slug questie` (prévia) e o mesmo com `-Aplicar` (com o jogo fechado); o contrato completo está em `modder\ferramentas\CONTRATO.md` |
| ferramentas de preço | ponha a casa no seu `jogador.json` (ou passe `--casa us-113`), depois `node ferramentas\pregao\baixar-precos.mjs` e `node ferramentas\pregao\legado.mjs --ate 225`; o mapa das ferramentas está em `modder\ferramentas\LEIA-ME.md` |
| addons próprios | copie a pasta do addon para `Interface\AddOns` do Forever, ou ligue com `ferramentas\dev-link.ps1 -Pasta addons-proprios\<Nome>` (prévia) e o mesmo com `-Aplicar` |

## Quando algo dá errado

| Mensagem | O que fazer |
|---|---|
| `JOGADOR ausente` | crie a sua pasta (passo 3) |
| `INSTALACAO ausente` | o agente ainda não gravou a instalação, ou este PC não tem o jogo; peça o bootstrap ou use em modo só desenvolvimento |
| `RECUSA ... jogo aberto` | feche o jogo e peça de novo |
| `casa de leilao nao definida` | ponha o `casaLeilao` no seu `jogadores\<você>\jogador.json` ou passe `--casa us-113` |
| `PREREQ dependências do Node ausentes` | rode `npm ci` em `modder\ferramentas\guia` |
| erro de caminho longo | clone o repositório num caminho mais curto |
