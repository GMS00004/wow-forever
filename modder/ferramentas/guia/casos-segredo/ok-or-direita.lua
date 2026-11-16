local s = __seg.numero(5)
local a = nil
local x = a or s
if not issecretvalue(x) then error("esperava o segredo") end
local z = false or s
