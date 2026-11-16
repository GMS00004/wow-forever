local s = __seg.numero(5)
local t = {}
t.valor = s
t[1] = s
table.insert(t, s)
local u = { s, a = s }
if not issecretvalue(t.valor) or not issecretvalue(t[1]) or not issecretvalue(t[2]) then error("perdeu o segredo") end
if not issecretvalue(u[1]) or not issecretvalue(u.a) then error("perdeu o segredo no construtor") end
