-- I9: sem tecla do dono ha T_pulso, o ciclo para onde esta, sem uma consulta a mais.
local function tecla(b)
  __bancada.ultimaTecla = __bancada.agoraUs()
  b.ns.pedidos.tecla()
end
return {
  id = "pedidos-05", grupo = "unid-pedidos",
  descricao = "T_pulso = 3 s: a cadeia de buscas para sozinha e nenhuma consulta sai depois",
  inicio = { mercado = { ["2589"] = { { preco = 9, qtd = 14 } } } },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b)
        local ns = b.ns
        ns.cfg.T_pulso = 3
        tecla(b)
        ns.pedidos.abrirFolego(function(ev, motivo) b.__fim = motivo end)
        local function cadeia()
          local ok, motivo = ns.pedidos.enviar({ tipo = "busca", chave = "2589", sorts = {},
            aoResponder = function() cadeia() end, aoFalhar = function() b.__falhou = true end })
          if not ok then b.__recusa = motivo end
        end
        cadeia()
      end },
    { avancar = 30 },
  },
  conferir = function(b)
    local n = b.contar("SendSearchQuery")
    b.verdadeiro(n >= 4 and n <= 8, "algumas buscas dentro dos 3 s (" .. n .. ")")
    b.igual(b.__fim, "sem_tecla", "dono avisado")
    b.igual(b.ns.pedidos.estado().fase, "PARADO", "pedidos parado")
    local ch = b.chamadas("SendSearchQuery")
    b.verdadeiro(#ch == n, "chamadas registradas")
    b.igual(#b.violacoes(), 0, "nenhuma consulta sem tecla (I9)")
    b.igual(b.__falhou, nil, "nenhuma falha")
  end,
}
