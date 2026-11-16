local s = __seg.numero(1234)
if not issecretvalue(AbbreviateNumbers(s)) then error("AbbreviateNumbers deveria devolver segredo") end
if AbbreviateNumbers(1234) ~= "1.2K" then error("1234") end
if AbbreviateNumbers(1234567) ~= "1.23M" then error("1234567") end
if AbbreviateNumbers(999) ~= "999" then error("999") end
if AbbreviateNumbers(7) ~= "7" then error("7") end
if __seg.real(AbbreviateNumbers(s)) ~= "1.2K" then error("valor real") end
if not issecretvalue(AbbreviateLargeNumbers(s)) then error("large") end
if not issecretvalue(BreakUpLargeNumbers(s)) then error("break") end
