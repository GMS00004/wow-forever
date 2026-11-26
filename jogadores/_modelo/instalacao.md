# Instalação do WoW Forever neste PC

O `instalacao.json` ao lado (pasta do jogo e do Forever) é escrito pelo bootstrap do wow-modder, com `Set-WowInstalacao`, depois de você confirmar o que o `Find-WowInstalacao` achou. Até lá ele não existe, e os scripts respondem `INSTALACAO ausente`. Este arquivo guarda as notas e o histórico da sua instalação.

## Como os scripts detectam

`Find-WowInstalacao` (em `modder\ferramentas\wow-comum.ps1`) procura a pasta do jogo no registro de desinstalação do Windows, no `Battle.net.config` e nos caminhos comuns. A pasta do Forever é a subpasta cujo `.flavor.info` aponta para o produto do Forever (no cliente de 2026, `_forever_`). A versão sai do `.build.info` da raiz, e a Interface é calculada dela (1.60.1 dá 16001).

## Histórico

| Data | O quê |
|---|---|
