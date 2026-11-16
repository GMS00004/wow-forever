local s = __seg.numero(87.4)
local r = C_StringUtil.WrapString(C_StringUtil.RoundToNearestString(s), nil, "%")
if not issecretvalue(r) then error("esperava segredo") end
if __seg.real(r) ~= "87%" then error("valor real: " .. __seg.real(r)) end
local v = __seg.texto("")
if __seg.real(C_StringUtil.WrapString(v, "a", "b")) ~= "" then error("vazio") end
