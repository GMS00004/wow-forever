-- /compra mode (CONTRATO 12.3): sem argumento, profit, eng 150, alvo invalido, profissao sem rota, profissao nao vista.
-- O fixture mescla a rota da Engineering nos dados reais (que tem as seis): so a Engineering esta gravada no personagem, entao
-- Blacksmithing tem rota mas e "nao vista"; a rota do Tailoring e tirada dos dados no passo para o caso "sem rota".
local function dizer(b, cmd)
  local antes = #__bancada.chat
  SlashCmdList.COMPRAFOREVER(cmd)
  local falas = {}
  for i = antes + 1, #__bancada.chat do falas[#falas + 1] = __bancada.chat[i] end
  return falas
end

return {
  id = "rota-02", grupo = "rota",
  descricao = "/compra mode: profit, eng 150, alvo invalido, profissao sem rota, profissao nao vista, sem argumento",
  inicio = __bancada.fixture("eng150", {
    sv_char = { versao = 2, modo = { tipo = "lucro" },
      prof = { engineering = { pericia = 1, max = 75, ids = { [3919] = true }, n = 1, em = 1 } } },
  }),
  passos = {
    { abrir_leilao = true },
    -- sem argumento: o modo e a lista (so as profissoes vistas)
    { chamar = function(b)
      local f = dizer(b, "mode")
      b.igual(f, { "CompraForever: mode Profit", "CompraForever: available: Profit, Eng 150, Eng 225" }, "mode sem argumento")
      b.igual(b.ns.modo(), { tipo = "lucro" }, "mode sem argumento nao muda o modo")
    end },
    -- eng 150 (slug, nome e curto, sem diferenciar maiusculas; alvo padrao 150)
    { chamar = function(b)
      local f = dizer(b, "mode eng 150")
      b.igual(f, { "CompraForever: mode Eng 150" }, "mode eng 150")
      b.igual(b.ns.modo(), { tipo = "rota", prof = "engineering", alvo = 150 }, "modo Eng 150")
      b.igual(CompraForeverCharDB.modo, { tipo = "rota", prof = "engineering", alvo = 150 }, "gravado")
      b.igual(b.ns.plano.modo, 2, "plano de rota")
      b.igual(b.ns.plano.rota.estado, "ok", "plano ok")
      b.igual(b.ns.plano.rota.pericia, 1, "pericia 1 no plano")
      b.igual(CompraForeverModo:GetText(), "Eng 150", "rotulo do botao")
    end },
    { chamar = function(b)
      b.igual(dizer(b, "mode Engineering 225"), { "CompraForever: mode Eng 225" }, "mode Engineering 225")
      b.igual(b.ns.modo(), { tipo = "rota", prof = "engineering", alvo = 225 }, "alvo 225")
      b.igual(dizer(b, "MODE ENG"), { "CompraForever: mode Eng 150" }, "alvo padrao 150, maiusculas")
      b.igual(b.ns.modo(), { tipo = "rota", prof = "engineering", alvo = 150 }, "alvo padrao 150")
    end },
    -- alvo invalido: mensagem e o modo nao muda
    { chamar = function(b)
      b.igual(dizer(b, "mode eng 300"), { "CompraForever: target must be 150 or 225" }, "alvo 300 invalido")
      b.igual(dizer(b, "mode eng 100"), { "CompraForever: target must be 150 or 225" }, "alvo 100 invalido")
      b.igual(dizer(b, "mode eng abc"), { "CompraForever: target must be 150 or 225" }, "alvo texto invalido")
      b.igual(b.ns.modo(), { tipo = "rota", prof = "engineering", alvo = 150 }, "o modo nao mudou")
    end },
    -- sem rota nos dados
    { chamar = function(b)
      CompraForeverDados.rotas.profs.tailoring = nil
      b.igual(dizer(b, "mode tailoring"), { "CompraForever: no route for Tailoring: ask for an estimate" }, "Tailoring sem rota")
      b.igual(b.ns.modo(), { tipo = "rota", prof = "engineering", alvo = 150 }, "o modo nao mudou")
    end },
    -- com rota mas nunca vista: avisa e aceita
    { chamar = function(b)
      local f = dizer(b, "mode bs")
      b.igual(f, { "CompraForever: Blacksmithing not seen on this character: open it once", "CompraForever: mode BS 150" },
        "Blacksmithing nao vista, aceita assim mesmo")
      b.igual(b.ns.modo(), { tipo = "rota", prof = "blacksmithing", alvo = 150 }, "modo BS 150")
      b.igual(b.ns.plano.rota.estado, "semPericia", "sem a pericia gravada: semPericia")
      b.igual(b.ns.plano.rota.proximo, "open", "proximo: abrir a profissao")
      b.igual(#b.ns.plano.leilao, 0, "nada a comprar sem a pericia")
    end },
    { avancar = 1 },
    { chamar = function(b)
      local achou = false
      for _, r in ipairs({ CompraForeverPainel:GetRegions() }) do
        if r:GetText() == "NEXT: open Blacksmithing once" then achou = true end
      end
      b.verdadeiro(achou, "painel: NEXT: open Blacksmithing once")
    end },
    -- uso e profit
    { chamar = function(b)
      local f = dizer(b, "mode xyz")
      b.igual(f, { "CompraForever: usage: /compra mode [profit | <profession> [150|225]]" }, "uso")
      b.igual(dizer(b, "mode profit"), { "CompraForever: mode Profit" }, "mode profit")
      b.igual(b.ns.modo(), { tipo = "lucro" }, "modo de lucro")
      b.igual(CompraForeverCharDB.modo, { tipo = "lucro" }, "lucro gravado")
      b.igual(CompraForeverModo:GetText(), "Profit", "rotulo Profit")
      b.igual(dizer(b, "mode"), { "CompraForever: mode Profit", "CompraForever: available: Profit, Eng 150, Eng 225" }, "mode sem argumento no lucro")
    end },
  },
  conferir = function(b)
    b.igual(#b.violacoes(), 0, "sem violacao")
    b.igual(#b.erros(), 0, "sem erro de Lua")
    b.igual(b.contar("BuyTrainerService"), 0, "nunca BuyTrainerService")
    b.igual(b.contar("SendSearchQuery") + b.contar("SendBrowseQuery") + b.contar("ReplicateItems"), 0, "o comando nao busca")
  end,
}
