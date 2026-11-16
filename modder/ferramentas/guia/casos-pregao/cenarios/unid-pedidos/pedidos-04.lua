-- O folego para em folego.max_buscas; as paginas do resumo nao entram na conta.
local function tecla(b)
  __bancada.ultimaTecla = __bancada.agoraUs()
  b.ns.pedidos.tecla()
end
local mercado = {}
for i = 1, 600 do mercado[tostring(40000 + i)] = { { preco = 10 + i, qtd = 1 } } end
mercado["2589"] = { { preco = 9, qtd = 14 } }
return {
  id = "pedidos-04", grupo = "unid-pedidos",
  descricao = "max_buscas = 2: duas buscas, resumo de duas paginas fora da conta, a terceira busca e recusada",
  inicio = { mercado = mercado },
  passos = {
    { abrir_leilao = true },
    { chamar = function(b)
        local ns = b.ns
        ns.cfg.folego.max_buscas = 2
        tecla(b)
        ns.pedidos.abrirFolego(function(ev, motivo) b.__fim = motivo end)
        local function busca(depois)
          local ok, motivo = ns.pedidos.enviar({ tipo = "busca", chave = "2589", sorts = {},
            aoResponder = depois, aoFalhar = function() b.__falhou = true end })
          if not ok then b.__recusa = motivo end
        end
        busca(function()
          busca(function()
            -- duas buscas feitas: o resumo e as paginas ainda saem
            ns.pedidos.enviar({ tipo = "browse", sorts = {}, aoResponder = function(info)
              ns.pedidos.enviar({ tipo = "mais_browse", sorts = {}, aoResponder = function()
                b.__pag = true
                busca(function() b.__terceira = true end)
              end })
            end })
          end)
        end)
      end },
    { ate_ocioso = true },
  },
  conferir = function(b)
    b.igual(b.contar("SendSearchQuery"), 2, "duas buscas e nenhuma mais")
    b.igual(b.contar("SendBrowseQuery"), 1, "o resumo saiu com as buscas esgotadas")
    b.igual(b.contar("RequestMoreBrowseResults"), 1, "a pagina a mais tambem")
    b.verdadeiro(b.__pag, "a pagina chegou")
    b.igual(b.__recusa, "max_buscas", "a terceira busca foi recusada por max_buscas")
    b.igual(b.__terceira, nil, "a terceira nao respondeu")
    b.igual(b.__fim, "max_buscas", "o dono foi avisado do fim")
    b.igual(b.ns.pedidos.estado().fase, "PARADO", "pedidos parado")
    b.igual(b.ns.pedidos.estado().buscas, 2, "duas buscas contadas")
    b.igual(#b.violacoes(), 0, "sem violacao")
  end,
}
