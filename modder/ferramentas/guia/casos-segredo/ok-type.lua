local n = __seg.numero(5)
local t = __seg.texto("a")
local b = __seg.bool(false)
local q = __seg.tabela({})
if type(n) ~= "number" then error("number") end
if type(t) ~= "string" then error("string") end
if type(b) ~= "boolean" then error("boolean") end
if type(q) ~= "table" then error("table") end
if type(1) ~= "number" or type(nil) ~= "nil" then error("comuns") end
