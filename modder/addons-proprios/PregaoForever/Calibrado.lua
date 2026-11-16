-- Calibrado.lua (PregaoForever): parametros medidos (valor, amostras, data), escritos pelo agente ou pela mesa.
-- Onda 1: nasce neutro. O leitor e a conferencia do cabecalho ficam em Banco.lua (onda 2).
local _, ns = ...

ns.calibrado = { esquema = 1, geradoEm = 0, recibo = 0, epoca = 0, valores = {}, sentinela = 'PREGAO-CALIBRADO-FIM' }
