# Jogador

Ficha do jogador para os agentes de WoW deste repositório. O wow-modder preenche com você no bootstrap e relê em toda sessão. Pode editar à mão: o agente respeita o que estiver aqui.

## Perfil

| Campo | Valor |
|---|---|
| Apelido | (o nome desta pasta) |
| Facção | (Horda ou Aliança) |
| Reino | (nome do reino e o tipo: PvP ou Normal) |
| Região | (US ou EU) |
| Casa de leilão das ferramentas de preço | (o id, como `us-113`; o mapa por facção e tipo de reino está em `comum\referencia\forever.md`; vai também no `jogador.json`) |
| Idioma do cliente (`textLocale` do `Config.wtf`) | (o agente lê no bootstrap) |
| Conta(s) em `WTF\Account` | (só um apelido, como `conta1`; o nome real da pasta não vem para cá) |
| PC que roda o jogo | (o nome do PC) |

## Personagens

Cada personagem principal ganha uma ficha em `personagens\`, com build, rota, profissões e o que o agente configura a partir delas.

| Personagem | Raça e classe | Spec | Profissões | Papel | Ficha |
|---|---|---|---|---|---|

## Fontes que eu sigo

Os guias ficam na biblioteca comum, `comum\fontes\`, para todo mundo aproveitar. Aqui vai só o que vale para você. Sem fonte, o agente não opina sobre gameplay: pergunta qual seguir.

| Para | Fonte (arquivo em `comum\fontes\`) | Observação |
|---|---|---|

## Preferências

| Preferência | Valor |
|---|---|
| UI | ElvUI completa (padrão do pacote base) |
| Autonomia do agente | padrão: atualiza sozinho o addon já aprovado; addon novo, remoção e qualquer mudança de UI esperam o seu ok |
| Relatório de sessão em PDF | (pasta onde salvar, se quiser ler no celular) |
