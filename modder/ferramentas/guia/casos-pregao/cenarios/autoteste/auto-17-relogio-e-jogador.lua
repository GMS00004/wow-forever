-- Relogio simulado, timers, ticker, hora do servidor e local, jogador, dinheiro, combate.
return {
  id = "auto-17", grupo = "autoteste",
  descricao = "C_Timer.After e NewTicker no relogio simulado; GetTime, GetServerTime, date; UnitName, GetMoney, combate",
  inicio = { personagem = "Hexumlite", reino = "Forever", faccao = "Alliance", dinheiro = 40000 },
  passos = {
    { chamar = function(b)
        local t = {}
        b.__t = t
        b.__tempo0 = GetTime()
        b.__servidor0 = GetServerTime()
        C_Timer.After(0, function() t[#t + 1] = "zero" end)
        C_Timer.After(2.5, function() t[#t + 1] = "dois" end)
        C_Timer.NewTicker(1, function() t[#t + 1] = "tic" end, 3)
        C_Timer.After(5, function() t[#t + 1] = "cinco" end)
      end },
    { avancar = 0.5 },
    { chamar = function(b) b.igual(b.__t, { "zero" }, "depois de 0,5 s so o After(0) disparou") end },
    { ate_ocioso = true },
    { chamar = function(b)
        b.igual(b.__t, { "zero", "tic", "tic", "dois", "tic", "cinco" }, "ordem dos disparos")
        b.igual(GetTime() - b.__tempo0, 5, "GetTime andou 5 s")
        b.igual(GetServerTime() - b.__servidor0, 5, "GetServerTime andou 5 s")
        b.verdadeiro(GetTimePreciseSec() > GetTime(), "GetTimePreciseSec existe e anda")
        b.igual(date("%Y-%m-%d"), "2026-11-16", "a data de partida")
        b.igual(date("*t").hour, 21, "hora local de partida")
        b.igual(b.agora(), 5, "b.agora em segundos")
      end },
    { avancar = 3 * 3600 },
    { chamar = function(b)
        b.igual(date("%Y-%m-%d"), "2026-11-17", "a data virou depois de 3 h")
        b.igual(date("*t").hour, 0, "meia-noite")
        b.igual(UnitName("player"), "Hexumlite", "UnitName")
        b.igual(GetNormalizedRealmName(), "Forever", "reino")
        b.igual(UnitFactionGroup("player"), "Alliance", "faccao")
        b.igual(GetMoney(), 40000, "dinheiro")
        b.igual(InCombatLockdown(), false, "fora de combate")
      end },
    { injetar = "combate_on" },
    { chamar = function(b) b.igual(InCombatLockdown(), true, "em combate") end },
    { injetar = "combate_off" },
    { injetar = { "dinheiro_muda", -500 } },
  },
  conferir = function(b)
    b.igual(InCombatLockdown(), false, "fora de combate de novo")
    b.igual(#b.eventos("PLAYER_REGEN_DISABLED"), 1, "REGEN_DISABLED")
    b.igual(#b.eventos("PLAYER_REGEN_ENABLED"), 1, "REGEN_ENABLED")
    b.igual(GetMoney(), 39500, "dinheiro mudou")
    b.igual(#b.eventos("PLAYER_MONEY"), 1, "PLAYER_MONEY")
    b.verdadeiro(b.contar("UnitName") >= 1, "chamadas contadas")
  end,
}
