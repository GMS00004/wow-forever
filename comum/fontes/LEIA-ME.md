# Biblioteca de fontes de gameplay

Aqui entram os guias que os jogadores deste repositório seguem: builds, macros, rotas de leveling, profissões, economia, raide, PvP e perfis de UI. A biblioteca é de todos; cada jogador diz no próprio `jogadores\<apelido>\jogador.md` quais fontes valem para ele. Os agentes de WoW configuram e respondem a partir destas fontes e não dão opinião própria de gameplay.

As que estão aqui hoje foram trazidas pelo Bruno para os personagens dele (Aliança: caçador, paladino, xamã, druida e o bruxo de um amigo). Guia de outra classe, de Horda ou de PvP é bem-vindo: entra por PR, no formato abaixo.

## Como alimentar

Uma subpasta por tema: `builds\`, `leveling\`, `economia\`, `profissoes\`, `raides\`, `pvp\` e `ui\` (perfis e strings de import de UI, como as do ElvUI). Cada fonte é um arquivo `.md` (resumo com as próprias palavras, mais o link), um PDF ou um `.txt` com uma string de import. Num `.md`, comece com este cabeçalho:

    tema: builds
    fonte: <autor ou site>
    url: <link, se houver>
    data: AAAA-MM-DD
    para: <classe, spec, facção ou atividade a que serve>
    seguir: <o que vale desta fonte; o que ignorar>

Não cole aqui conteúdo pago (rota comprada, código de importação de guia pago) nem a transcrição inteira de um vídeo: resumo e link bastam, e o crédito é do criador (ver `CREDITOS.md` na raiz).

## Como o modder usa

| Pasta | O modder tira dali |
|---|---|
| `ui\` | perfis do ElvUI e de outros addons |
| `builds\` | macros, barras e keybinds da classe |
| `leveling\`, `raides\`, `economia\`, `profissoes\`, `pvp\` | que addons e que configuração cada atividade pede |

Se duas fontes entrarem em conflito, o agente pergunta ao jogador qual vale e registra a decisão no `jogador.md` dele (ou na ficha do personagem).
