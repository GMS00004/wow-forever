# Lições do agente e do Bruno ao construir os addons e as ferramentas

Estes arquivos reúnem o que o agente de IA e o Bruno aprenderam construindo os addons e as ferramentas do WoW Forever (GuiaForever, UIForever, CentralForever, PregaoForever, CompraForever e as calculadoras de custo fora do jogo). Foram copiados do second brain do Bruno em 2026-11-26, continuam em inglês, que é o idioma original, e não são atualizados aqui: quando o código e uma dessas páginas discordarem, vale o código. Cada página abre com uma nota dizendo de quando é e quando foi atualizada pela última vez.

| Arquivo | Assunto |
|---|---|
| [01-guiaforever-ui-e-macros.md](01-guiaforever-ui-e-macros.md) | Como o agente cria e mantém o GuiaForever e o UIForever: ler o código da interface do Forever pelo `gh`, contador de macros, ElvUI configurado antes do login, bancada de testes e o que já rodou no jogo. |
| [02-centralforever-valores-secretos.md](02-centralforever-valores-secretos.md) | Como um addon de dano e ameaça lida com valores escondidos em combate: quais funções da API devolvem esses valores, como isolar o código que os toca e como provar isso fora do jogo com um simulador. |
| [03-pregaoforever-design-do-leilao.md](03-pregaoforever-design-do-leilao.md) | Design do addon de leilão: o portão mecânico que confere um documento de design, o aviso de AGENTS.md em addons de terceiros e os fatos do leilão lidos no cliente e medidos no jogo. |
| [04-crafts-fora-do-jogo-e-precos.md](04-crafts-fora-do-jogo-e-precos.md) | Ferramentas em Node que dizem quais receitas de profissão compensam: preços do Auctionator pela API pública, tabelas do cliente, o arquivo público de preços por hora e o mapa das casas de leilão por ruleset. |
| [05-custo-legacy-das-seis-profissoes.md](05-custo-legacy-das-seis-profissoes.md) | Como a ferramenta estima o custo dos pontos de Legacy das seis profissões de criação até o nível 225: a tabela de receitas do Naowh, as correções da rota gulosa, a atualização fácil e o cálculo em cópia isolada para outra casa e facção. |
| [06-compraforever-modalidade-de-rota.md](06-compraforever-modalidade-de-rota.md) | A modalidade de rota do CompraForever: a rota calculada fora do jogo, as quantidades refeitas dentro dele, o teste de paridade entre Lua e JS e o que aconteceu no primeiro uso real em Engineering. |
| [07-compraforever-caca-de-preco.md](07-compraforever-caca-de-preco.md) | A caça de preço do CompraForever no leilão: linhas de commodity, tempos de compra medidos no jogo, anúncios isca e a regra de uma tecla, uma ação. |
