local s = __seg.numero(5)
local function passa(x, y)
  return y, x
end
local a, b = passa(s, 1)
if not issecretvalue(b) then error("o segredo nao voltou") end
if a ~= 1 then error("o comum mudou") end
