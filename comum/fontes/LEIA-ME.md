# Fontes de gameplay do dono

Aqui entram os guias que o dono decidiu seguir. Os agentes de WoW configuram e respondem a partir destas fontes e não dão opinião própria de gameplay.

## Como alimentar

Uma subpasta por tema: `builds\`, `leveling\`, `economia\`, `raides\`, `pvp\` e `ui\` (perfis e strings de import de UI, como as do ElvUI). Cada fonte é um arquivo `.md` (texto colado, resumo ou link), um PDF ou um `.txt` com uma string de import. Num `.md`, comece com este cabeçalho:

    tema: builds
    fonte: <autor ou site>
    url: <link, se houver>
    data: AAAA-MM-DD
    seguir: <o que vale desta fonte; o que ignorar>

## Como o modder usa

| Pasta | O modder tira dali |
|---|---|
| `ui\` | perfis do ElvUI e de outros addons |
| `builds\` | macros, barras e keybinds da classe |
| `leveling\`, `raides\`, `economia\`, `pvp\` | que addons e que configuração cada atividade pede |

Se duas fontes entrarem em conflito, o agente pergunta ao dono qual vale e registra a decisão no arquivo da fonte.
