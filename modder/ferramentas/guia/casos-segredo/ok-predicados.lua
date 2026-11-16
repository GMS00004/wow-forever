local s = __seg.numero(5)
if not issecretvalue(s) then error("esperava segredo") end
if issecretvalue(1) then error("1 nao e segredo") end
if issecretvalue(nil) then error("nil nao e segredo") end
if not issecrettable(__seg.tabela({})) then error("esperava tabela secreta") end
if issecrettable({}) then error("tabela comum") end
if canaccessvalue(s) then error("nao pode acessar") end
if not canaccessvalue(1) then error("pode acessar") end
if canaccesstable(__seg.tabela({})) then error("nao pode acessar a tabela") end
if not canaccesstable({}) then error("pode acessar a tabela") end
if not hasanysecretvalues(1, s) then error("esperava algum segredo") end
if hasanysecretvalues(1, 2) then error("nenhum segredo") end
