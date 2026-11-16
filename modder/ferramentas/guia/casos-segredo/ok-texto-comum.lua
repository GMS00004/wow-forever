if C_StringUtil.WrapString("", "a", "b") ~= "" then error("vazio") end
if C_StringUtil.WrapString(nil, "a", "b") ~= "" then error("nil") end
if C_StringUtil.WrapString("5", nil, "%") ~= "5%" then error("sufixo") end
if C_StringUtil.WrapString("5", "<", ">") ~= "<5>" then error("prefixo e sufixo") end
if C_StringUtil.RoundToNearestString(2.6) ~= "3" then error("arredondar") end
if C_StringUtil.FloorToNearestString(2.6) ~= "2" then error("piso") end
if C_StringUtil.TruncateWhenZero(0) ~= "" then error("zero") end
if C_StringUtil.TruncateWhenZero(4) ~= "4" then error("quatro") end
