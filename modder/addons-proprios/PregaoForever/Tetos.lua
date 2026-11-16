-- Tetos.lua (PregaoForever): tetos duros de dinheiro, como constantes (regra 13; secao 9.2 do DESIGN).
-- Dinheiro em cobre inteiro (100 cobre = 1 prata; 10000 = 1 ouro). So este arquivo define teto duro.
-- Onda 1. Subir um teto e editar este arquivo, com registro (DD10). O Config so baixa.
local _, ns = ...

ns.tetos = {
  deposito_risco = { frac = 0.05, piso = 2000 },       -- fracao da banca; piso em cobre (20 prata): vale o maior
  deposito_perdido_dia = { frac = 0.02, piso = 800 },  -- fracao da banca; piso em cobre (8 prata): vale o maior
  lote_confirmacao = 0.02,        -- fracao da banca, primeira compra de um item
  ordem_micro = 0.10,             -- fracao da banca, custo por ordem em micro
  acumulado_item = 0.20,          -- fracao da banca, custo acumulado por item
  estoque_total = 0.50,           -- fracao da banca, estoque com risco de preco
  perda_dia = 0.05,               -- fracao da banca, perda do dia de risco
  perda_item_dia = 0.01,          -- fracao da banca, perda num item no dia
  preco_postagem_ref = 3,         -- vezes a referencia, teto do preco de postagem
  volume_item_dia = 0.10,         -- fracao das vendas inferidas do dia, compra diaria de um item
  sonda = { deposito = 30, compra = 20 },  -- cobre: classe sonda, deposito e compra por ordem
}
