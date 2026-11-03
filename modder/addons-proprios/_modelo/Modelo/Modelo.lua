-- Modelo de addon do dono. Ao copiar, troque o nome da pasta, do .toc e deste arquivo, e a linha do TOC.
local NOME = "Modelo"

SLASH_MODELO1 = "/modelo"
SlashCmdList["MODELO"] = function(msg)
    print("|cff33ff99" .. NOME .. "|r: comando /modelo recebido.")
end
