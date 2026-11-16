local s = __seg.numero(5)
local x = scrubsecretvalues(s)
if x ~= nil then error("esperava nil") end
local a, b, c = scrubsecretvalues(1, s, 3)
if a ~= 1 or b ~= nil or c ~= 3 then error("so o segredo vira nil") end
