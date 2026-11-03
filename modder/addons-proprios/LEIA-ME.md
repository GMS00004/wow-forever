# Addons próprios

Pasta dos addons que você escreve. O jogo não lê esta pasta: o `dev-link.ps1` liga a pasta de um addon ao `Interface\AddOns` do jogo por junction, então você edita aqui e testa lá sem copiar.

## Criar um addon novo

1. Copie `_modelo\Modelo` para `addons-proprios\<Nome>`.
2. Renomeie a pasta, o `.toc` e o `.lua` para `<Nome>`, e troque a linha do `.lua` dentro do `.toc`.
3. Ligue ao jogo com o `dev-link.ps1`, primeiro em prévia e depois com `-Aplicar` (com o WoW fechado):
   `ferramentas\dev-link.ps1 -Pasta "addons-proprios\<Nome>"` e depois o mesmo com `-Aplicar`.
4. Abra o jogo e teste.

## Ciclo de edição

- Mudou código (`.lua`): `/reload` no jogo.
- Addon novo ou `.toc` novo (incluindo a Interface): reinicie o jogo. `/reload` não basta para arquivo novo.
- Erros: use o BugSack para ver os erros de Lua.

## Desligar

`ferramentas\dev-link.ps1 -Pasta "addons-proprios\<Nome>" -Remover` (prévia), e depois com `-Aplicar`. Só a junction é removida; a pasta em `addons-proprios` fica intacta.

A Interface do `.toc` tem de bater com a do cliente (`/dump select(4, GetBuildInfo())`).
