local s = __seg.numero(5)
__seg.modo.formatoErra = false
local t = tostring(s)
if not issecretvalue(t) then error("tostring deveria devolver segredo") end
local f = string.format("%d", s)
if not issecretvalue(f) then error("format deveria devolver segredo") end
local c = "x" .. s
if not issecretvalue(c) then error("concat deveria devolver segredo") end
if __seg.real(c) ~= "x5" then error("valor real") end
__seg.modo.formatoErra = true
