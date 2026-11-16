-- PregaoForever.lua (PregaoForever): eventos de vida (ADDON_LOADED, PLAYER_LOGOUT) e /pregao. Onda 2.
-- Contrato: ARQUITETURA.md, secao 3.12. Ultimo arquivo do .toc: todos os modulos ja existem aqui.
local _, ns = ...

local function aoCarregar(_, nome)
  if nome ~= ns.NOME then return end
  if not ns.configOk() then
    ns.marcarFaixa('config', 'CONFIG ERROR - read only')
  end
  if ns.banco.abrir then ns.banco.abrir() end
  ns.pronto = true
  ns.log('info', 'loaded ' .. ns.VERSAO .. ' mode ' .. ns.modo())
  ns.sujo('tela')
end
ns.ao('ADDON_LOADED', aoCarregar)

ns.ao('PLAYER_LOGOUT', function()
  if ns.banco.fechar then ns.banco.fechar() end
end)

local function mostrarEstado()
  local desk = 'NO DESK'
  if ns.banco.desk then desk = ns.banco.desk() end
  local banco = 'NOT LOADED'
  if ns.banco.carregado then banco = 'loaded' end
  ns.msg(string.format('%s, mode %s, %s, database %s', ns.VERSAO, ns.modo(), desk, banco))
  if ns.faixa then ns.msg(ns.faixa) end
end

SLASH_PREGAOFOREVER1 = '/pregao'
SlashCmdList.PREGAOFOREVER = ns.seguro(function(msg)
  local pedido = string.lower(msg or '')
  if pedido == 'sonda' or pedido == 'probe' then
    if ns.janela.abrir then ns.janela.abrir('sonda') end
    return
  end
  mostrarEstado()
  if ns.janela.abrir then ns.janela.abrir() end
end)
