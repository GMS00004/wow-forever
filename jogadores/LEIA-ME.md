# Jogadores

Cada jogador tem uma pasta aqui com tudo o que é só dele: a ficha, os personagens, a instalação do jogo no PC dele e a memória do agente (o estado). O resto do repositório (o agente, as ferramentas, os addons, as referências e a biblioteca de guias) é o mesmo para todo mundo.

| Pasta | O que é | Vai para o git? |
|---|---|---|
| `_modelo\` | o molde vazio de onde sai a pasta de um jogador novo | sim |
| `guilherme\` | a pasta do Guilherme, com o estado real dele desde 2026-11-03 (serve de exemplo de uma pasta em uso) | sim |
| `<seu apelido>\` | a sua, criada pelo `jogador.ps1` | não: fica só no seu PC |

## Criar a sua

A partir da pasta `modder`:

    powershell -NoProfile -ExecutionPolicy Bypass -File ferramentas\jogador.ps1 -Novo <apelido>
    powershell -NoProfile -ExecutionPolicy Bypass -File ferramentas\jogador.ps1 -Novo <apelido> -Aplicar

O primeiro comando só mostra o que vai ser criado; o segundo copia o `_modelo\` para `jogadores\<apelido>\` e grava o `jogador-ativo.txt` na raiz do repositório, que diz a todos os scripts e ao agente qual pasta usar neste PC. Depois disso, abra o Claude Code na pasta `modder` e diga "oi": o agente vê o bootstrap pendente e conduz o resto (acha a instalação do jogo, pergunta facção, reino e personagens, e propõe o pacote de addons). O passo a passo completo está em [docs/COMECE-AQUI.md](../docs/COMECE-AQUI.md).

Para trocar de jogador no mesmo PC: `jogador.ps1 -Ativar <apelido> -Aplicar`. Sem argumentos, `jogador.ps1` mostra o ativo e os disponíveis.

## O que tem numa pasta de jogador

| Arquivo | Quem escreve | Para quê |
|---|---|---|
| `jogador.md` | o agente, com você | perfil (facção, reino, casa de leilão), personagens, fontes que você segue e preferências |
| `jogador.json` | o agente, com você | o que as ferramentas leem do perfil (hoje, a casa de leilão das ferramentas de preço) |
| `personagens\<nome>.md` | o agente, com você | uma ficha por personagem: build, rota, profissões e o que o agente configura a partir delas |
| `instalacao.json` | só os scripts (`Set-WowInstalacao`) | onde o jogo está instalado neste PC |
| `instalacao.md` | o agente | notas e histórico da instalação |
| `estado\estado.md` | o agente | a memória do agente: addons instalados, decisões, mudanças de UI, pendências e diário |
| `estado\registro.md` | só os scripts | uma linha por ação dos scripts (instalar, atualizar, backup, CVar...) |
| `estado\addons\<slug>.json` | só os scripts | o manifesto de cada addon instalado (fonte, versão, pastas e aprovação) |
| `estado\sessao.json` | só os scripts | a última Interface vista e a última abertura de sessão |

A sua pasta fica fora do git de propósito: assim os PRs levam ferramenta e conteúdo, não o estado de sessão de cada um. Se quiser guardar a sua em outro lugar (uma pasta sincronizada, por exemplo), ponha o caminho completo dela no `jogador-ativo.txt` em vez do apelido.
