if AbbreviateLargeNumbers(50475) ~= "50,475" then error("50475") end
if AbbreviateLargeNumbers(12.5) ~= "12.5" then error("12.5") end
if AbbreviateLargeNumbers(12) ~= "12" then error("12") end
if AbbreviateLargeNumbers(1500000) ~= "1.5M" then error("1500000") end
if BreakUpLargeNumbers(1234567) ~= "1,234,567" then error("1234567") end
