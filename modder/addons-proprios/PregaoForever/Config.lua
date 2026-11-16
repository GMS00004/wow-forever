-- Config.lua (PregaoForever): parametros escritos pelo agente (Apendice B do DESIGN). Esquema 1.
-- Onda 1, valores de partida. Tempo no nome do campo (_s, _min, _ms, _h). Dinheiro em cobre inteiro.
-- Nada se configura no jogo (regra 11). O Calibrado valida as faixas; os tetos de Tetos.lua so o Config baixa.
local _, ns = ...

ns.cfg = {
  esquema = 1,

  -- Modo, banca e pessoas
  modo = 'leitura',               -- texto: leitura, papel ou vivo; nesta onda leitura (DD1a)
  negociador = 'Hexumlite',       -- nome de personagem; DD4
  piso_pessoal = {},              -- cobre por personagem, 0 em diante; vazio = zero para todos (DD4)
  cofre = {
    piso_teto_deposito = 2000,    -- cobre, de 0 ate 2000 (20 prata, de Tetos.lua); so baixa (DD10)
    piso_teto_perdido = 800,      -- cobre, de 0 ate 800 (8 prata, de Tetos.lua); so baixa (DD10)
  },
  reservas = {},                  -- lista de itens por personagem; vazio = toda sobra vai a KEPT (DD14)
  licencas = {                    -- nivel 0 a 3; so desce dentro do jogo (regra 13); DD3
    venda_verdes = { nivel = 0, aprovadaEm = '2026-11-16' },  -- fonte aprovada pelo dono
    venda_sobras = { nivel = 0 },
    piso = { nivel = 0 },
    vao = { nivel = 0 },
    sniper = { nivel = 0 },
  },
  destravas = {},                 -- disjuntor -> 'seq'; so com o sim do dono na sessao (DD10)
  folego = {
    gatilho = 'tecla',            -- texto: tecla ou presenca (DD13)
    max_buscas = 20,              -- buscas por ciclo; 5 a 100 nas fases 1 e 2
    max_s = 60,                   -- segundos por ciclo; 20 a 180 nas fases 1 e 2
  },
  T_pulso = 90,                   -- segundos desde a ultima tecla do dono; 30 a 240 (DD13)

  -- Teclas: mapa da secao 11.2, pendente da DD5 (o dono confere o desenho antes de valer)
  teclas = {                      -- pendente da DD5; uma letra ou F1 a F5 por acao
    olhar = 'L',                  -- abre ou renova um folego de varredura
    proxima = 'N',                -- proxima linha (so navegacao)
    anterior = 'U',               -- linha anterior (so navegacao)
    porque = 'I',                 -- conta da linha
    mais = 'O',                   -- mostra o resto da secao
    pular = 'K',                  -- tira a linha da fila ate o fim da sessao
    postar = 'P',                 -- rele ou arma o bilhete de postagem
    comprar = 'B',                -- rele, cota a commodity e arma o item
    cancelar = 'C',               -- so arma o bilhete de cancelamento
    confirmar = 'Y',              -- executa o bilhete da tela
    desistir = 'M',               -- desarma o bilhete e cancela a cotacao
    segurar = 'H',                -- solta ou rearma as teclas de acao
    visao_1 = 'F1',               -- visao Next
    visao_2 = 'F2',               -- visao Sell
    visao_3 = 'F3',               -- visao Mine
    visao_4 = 'F4',               -- visao Risk
    visao_5 = 'F5',               -- visao Session
  },

  guardas = {
    repeticao_ms = 400,           -- milissegundos; tecla repetida em menos disso e ignorada; 200 a 1000
    rajada_teclas = 6,            -- teclas; 4 a 10 disparos em rajada
    rajada_s = 2,                 -- segundos da janela de rajada; 1 a 5
    validade_bilhete_s = 20,      -- segundos; 10 a 60
    prazo_cotacao_s = 5,          -- segundos da cotacao; 2 a 15
    corte_confirmacao_s = 5,      -- segundos; confirmacao so com menos disso de cotacao; 3 a 15
    prazo_eco_s = 10,             -- segundos; 3 a 30 (o dobro do maior tempo medido)
    prazo_consulta_s = 10,        -- segundos; 3 a 30
    throttle_travado_s = 30,      -- segundos; 10 a 120
    alerta_s = 10,                -- segundos que o alerta fica na tela; 5 a 30
    T_ver = 1.15,                 -- segundos de intervalo de erro de dedo; 0.5 a 3; 1 mais a latencia
  },

  janela = {                      -- unidades da UI; 520 x 500 e hipotese ate a S0 (comando 15, H-36)
    w = 520,
    h = 500,
    escala = 1,
  },

  remoto = {
    latencia_ms = 150,            -- milissegundos de acesso remoto; 0 a 1000; o dono le no overlay
  },

  -- Idades de foto
  idades = {
    A_exec_s = 30,                -- segundos entre a foto e a tecla de comprar; 5 a 120
    post = { idade_max_min = 5 }, -- minutos; idade maxima para postar; 0.5 a 10
    idade_cancelar = nil,         -- sem numero: a foto do proprio leilao no ultimo folego
    resumo_vencido_min = 10,      -- minutos; resumo vencido; 2 a 30
  },

  ritmo = {
    buscas_min = 30,              -- buscas por minuto; 5 a 100; sobe so pelo portao da secao 17.1
    acoes_min = 10,               -- verbos concluidos por minuto; 1 em diante; teto e o degrau liberado
  },

  foco = {
    vigilia = {},                 -- lista de chaves com papel aberto; 0 a 20 nas fases 1 e 2
    vigilia_max = 8,              -- chaves; maximo de vigilia
    cotas = { bolsas = 8, proprios = 4, piso = 4, giro = 4 },  -- vagas por folego; soma igual a folego.max_buscas
    delta_min = 10,               -- minutos; idade media das fotos na hora da tecla; 2 a 60
  },

  fatia = {
    ms = 2,                       -- milissegundos por fatia de trabalho; 1 a 5
    linhas = 500,                 -- linhas do resumo por fatia; 100 a 2000
  },

  triagem = {
    g_cob_pct = 3,                -- porcento de cobertura do giro; 1 a 10
    peso_media = 0.3,             -- peso da media movel; 0.1 a 0.5
    k_t_h = 1,                    -- horas; 0.1 a 10
  },

  fotos = {
    degraus_guardados = 12,       -- degraus; 6 a 40
    baldes_cauda = 8,             -- baldes da cauda; limites da secao 5.3
    leiloes_por_foto = 30,        -- leiloes por foto de item; 10 a 60
    chaves_anel = 60,             -- chaves com anel, por degrau da secao 17.1
    fotos_por_chave = 16,         -- fotos por chave; 8 a 64; 16 na fase 1 (48 na fase 2)
  },

  dias = {
    chaves = 1500,                -- chaves no banco; 500 a 3000
    dias = 14,                    -- dias no banco; 7 a 30
  },
  blocos = 126,                   -- blocos de 4 horas; 42 a 180 (tres semanas)

  banco = {
    teto_mb = 3,                  -- MB do teto do banco; 1 a 5
    gatilho_poda_pct = 80,        -- porcento do teto que dispara a poda; 50 a 95
  },

  salvar = {
    sugestao_min = 45,            -- minutos entre sugestoes de salvar; 15 a 90
    sugestao_acoes = 50,          -- acoes entre sugestoes de salvar; 20 a 100
  },

  desk_stale_dias = 7,            -- dias; DESK STALE; 3 a 30

  divergencia = {
    tolerancia_pct = 10,          -- porcento; 5 a 25 (secao 7.6)
    tolerancia_cobre = 1,         -- cobre; piso da tolerancia
  },

  -- Venda (DD3: regra, duracao e lote sem valor ate o dono escolher)
  venda = {
    regra = { equipamento = 'igualar', commodity = 'igualar' },  -- igualar, cobrir ou folga (DD3)
    duracao = { equipamento = nil, commodity = nil },  -- PICK RULE: horas 2, 8 ou 24; sem valor ate a DD3
    lote = { equipamento = nil, commodity = nil },     -- PICK RULE: pilha, receita ou fixo; sem valor ate a DD3
    folga = nil,                  -- ticks; so se a regra for folga (o dono da, se escolher)
    lote_item = 1,                -- unidades por tecla; fixo em 1 (DD11)
    isca = {                      -- filtro de isca (50 fotos rotuladas, R9 1.7)
      fracao_janela = 0.05,       -- fracao da janela; 0.01 a 0.15
      salto_pct = 15,             -- porcento; 5 a 40
      degraus = 3,                -- degraus; 1 a 5
      salto_min_ticks = 3,        -- ticks; 1 a 10
      escada_min = 20,            -- unidades; 5 a 100
    },
    janela_ref = {                -- janela N_ref da referencia
      fracao = 0.15,              -- fracao da escada; 0.05 a 0.5
      minimo = 5,                 -- unidades; 1 a 20
      maximo = 2000,              -- unidades; 200 a 10000
    },
    referencia_forte = {          -- referencia forte (onda 2)
      commodity_unidades = 5,     -- unidades; 3 a 20
      commodity_donos = 2,        -- donos; 1 a 5
      item_arremates = 5,         -- arremates; 3 a 20
      item_donos = 3,             -- donos; 1 a 5
    },
    suspeito_x = 3,               -- vezes; dado suspeito pelo Auctionator acima disso; 2 a 5
    teto_postagem_x = 3,          -- vezes a referencia; 1.5 a 3; so baixa (DD10)
    wilson_pct = 80,              -- porcento; intervalo de Wilson do veredito; 80 a 95
    desfechos_freq = 10,          -- desfechos por classe, duracao e regra; 5 a 30
    sombra = {                    -- recursao da sombra
      K = 3,                      -- niveis de recursao; 1 a 6
      desfechos_comparar = 50,    -- desfechos por classe; 30 a 200
    },
  },

  -- Compra (DD10)
  compra = {
    tiquete = 15,                 -- cobre por tecla; 1 a 200
    mu_min = 0.15,                -- fracao do custo; margem minima de compra; 0.03 a 0.3
    eta_real = { piso = 1.0, resto = 0.5 },  -- razao realizado sobre previsto; 0.3 a 1
    teclas_revenda = 5,           -- teclas de uma compra para revenda; 3 a 6
    piso = { custo_ida = 0 },     -- cobre por ida (tempo por acao); 0 a 500
    apara_robusta = 0.2,          -- fracao; apara do preco robusto; 0.1 a 0.3
    dias_min_mediana = 5,         -- dias; minimos para a mediana dos minimos; 3 a 14
    delta_max_min = 15,           -- minutos; intervalo maximo de um par de fotos; 5 a 120; nunca entre sessoes
    repostagem = {                -- casamento de repostagem
      tol_rep = 0.10,             -- fracao; 0 a 0.25
      g_rep = 0.05,               -- fracao; 0.01 a 0.15
      coortes = 32,               -- coortes por chave; 8 a 64
    },
    classe_b = {                  -- classe B
      pares = 3,                  -- pares validos; 2 a 6
      dias = 2,                   -- dias distintos; 1 a 3
    },
    sobrevivencia = {             -- sobrevivencia das pechinchas
      faixas_pct = { 10, 30 },    -- porcento; faixas de desconto; 10 a 30
      releituras = 15,            -- releituras da tecla B
      minimo = 0.5,               -- fracao; 0.3 a 0.7
    },
    sniper_ja_sumiu_pct = 70,     -- porcento em 30 sinais; portao do sniper; 50 a 80
    guarda_regime_x = 3,          -- vezes o lote; guarda de regime; 1 a 8
    volume_dia = {                -- volume diario por item (so aperta o Tetos)
      pct = 10,                   -- porcento das vendas inferidas; 1 a 10
      horas_min = 2,              -- horas minimas de exposicao; 2 a 6
    },
    pi_react = 0.2,               -- fracao; desconto de reacao do papel; 0 a 0.5
    exposicao_min_h = 2,          -- horas; exposicao minima para not sold; 1 a 6
    t_fecho_h = 72,               -- horas; 24 a 240
    papel = {                     -- portao de papel
      sinais = 30,                -- sinais; 20 a 60
      grupos_item_dia = 10,       -- grupos item-dia; 5 a 20
      max_item_pct = 20,          -- porcento por item; 10 a 34
      razao = 0.5,                -- razao; 0.3 a 1
    },
    micro_plena_lotes = 30,       -- lotes; portao de micro para plena; 20 a 60
    prova_piso = {                -- prova do piso
      varreduras = 3,             -- varreduras em blocos de 4 horas distintos
      tiquete_x = 2,              -- vezes o tiquete
    },
    ordem_micro_ganho_x = 3,      -- vezes as teclas vezes o tiquete; 1 a 10 (DD10)
    vao_degraus_max = 2,          -- degraus comprados pelo vao; 1 a 3 (DD10)
  },

  -- Antiguerra (DD10)
  antiguerra = {
    g1 = {                        -- cancelamentos com repostagem por item
      cancelamentos = 2,          -- cancelamentos; 1 a 4
      horas = 4,                  -- horas; 1 a 12
    },
    g2 = {                        -- coberturas
      coberturas = 2,             -- coberturas em 60 minutos; 1 a 4
      janela_min = 60,            -- minutos; 30 a 120
      vista_min = 10,             -- minutos depois da postagem; 3 a 30
      tregua_h = 4,               -- horas de tregua; 1 a 12
    },
    parede = {                    -- parede da escada
      pct = 25,                   -- porcento da escada; 10 a 50
      donos = 2,                  -- donos; 1 a 3
    },
    deriva = {                    -- deriva de preco
      pares_min_h = 6,            -- horas; 6 a 48
      pares_max_h = 48,           -- horas; 6 a 48
      chaves = 30,                -- chaves por classe
      suspende_pct = -10,         -- porcento em dois dias
      dias = 2,                   -- dias seguidos
    },
    acao_muda = 3,                -- INCERTO seguidos; 2 a 5
    dado_ruim_folegos = 2,        -- folegos incompletos; 2 a 5
    compras_perdidas = 3,         -- "ja sumiu" seguidas; 2 a 5
    dinheiro_sem_explicacao_pct = 1,  -- porcento da banca, na janela de leilao ou correio; 0.5 a 3
  },

  disjuntores = {
    dia_risco_hora = 6,           -- hora local em que vira o dia de risco; 0 a 12
    destrava_perda_h = 24,        -- horas; destrava do disjuntor de perda num item; 12 a 72
  },

  sonda = { deposito = 30, compra = 20 },  -- cobre; classe sonda; fixo (igual a Tetos.lua)

  -- Fase 3 e gargalo (secao 17.1)
  degrau = 0,                     -- degrau atual, 0 a 3; so desce dentro do jogo; portoes da secao 17.1
  degrau_banca = { 15, 60, 250 }, -- ouro para abrir os degraus 1, 2 e 3; proposta do projeto (DD10)
  gargalo = {
    capital_livre_pct = 20,       -- porcento da banca livre; 10 a 30
    sinal_pct = 50,               -- porcento da banca; 40 a 70
    giro_x = 2,                   -- vezes o tempo de venda medido; 1.5 a 4 (DD10)
  },
}
