__seg.recusa("SetWidth", 5)
__seg.recusa("SetWidth", "texto", nil, {})
if __seg.algum(1, 2) then error("nenhum segredo") end
if not __seg.algum(1, __seg.numero(2)) then error("esperava algum") end
