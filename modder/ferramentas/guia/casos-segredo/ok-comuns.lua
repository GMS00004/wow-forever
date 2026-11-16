local a, b = 3, 3
if not (a == b) then error("a == b") end
if a ~= b then error("a ~= b") end
local t = { x = 1, [5] = "cinco" }
local k = 5
if t[k] ~= "cinco" then error("t[k]") end
t[k] = "seis"
if t[k] ~= "seis" then error("t[k] = ...") end
local i = 0
while i < 3 do i = i + 1 end
repeat i = i - 1 until i == 0
local v = (a == 3 and "sim") or "nao"
if v ~= "sim" then error("and/or") end
if (a) == (b) then else error("parenteses") end
local ordem = {}
for n, x in ipairs({ 10, 20 }) do ordem[n] = x end
for key in pairs({ z = 1 }) do if key ~= "z" then error("pairs") end end
if math.floor(2.5) ~= 2 or string.format("%d", 7) ~= "7" or tostring(4) ~= "4" or tonumber("9") ~= 9 then error("comuns") end
