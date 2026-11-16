local s = __seg.numero(5)
local caminho = nil
if not issecretvalue(s) then
  caminho = "legivel"
else
  caminho = "secreto"
end
if caminho ~= "secreto" then error("caminho errado") end
