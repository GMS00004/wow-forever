local _, ns = ...
function ns.rebaixar(estrategia)
  estrategia.concedido = math.min(estrategia.concedido, 1)
end
