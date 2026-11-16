// V8-ambicao: escada de capital. Aritmetica sobre HIPOTESES, nao previsao.
// Todos os parametros abaixo sao numeros que o proprio addon mede (regua, secao 10 do design).
// Unidade: ouro (float); dia = 1 dia de jogo com uma sessao.

const OURO0 = 5.0912;            // base 4.1: 50.912 cobre somando os quatro personagens
const ALVOS = [15, 60, 250, 1000];
const MAX_DIAS = 3650;

// voltas por dia = quantas vezes o mesmo ouro vai e volta dentro da sessao
// ciclo = entrega da compra (H-10) + tempo ate vender + correio da venda (base 1.8, cerca de 1 h)
function voltas(c) {
  const ciclo = c.t_entrega + c.t_venda + c.t_correio;
  return Math.max(1, Math.floor(c.sessao_h / ciclo));   // minimo 1: a volta que atravessa a noite
}

// margem esperada por unidade de capital aplicado numa volta
// margem = liquida de corte e deposito quando acerta; perda = fracao perdida quando erra
function borda(c) { return c.acerto * c.margem - (1 - c.acerto) * c.perda; }

function simula(c, opt = {}) {
  const k = voltas(c);
  const e = borda(c);
  let g = opt.ouro0 ?? OURO0;
  const piso = opt.piso ?? c.piso;
  const quando = {};
  let ganhoTrading = 0, ganhoFora = 0;
  const partes = {};
  for (let dia = 1; dia <= MAX_DIAS; dia++) {
    const ativo = !opt.portao || (dia > opt.portao.dia && g >= opt.portao.banca);
    if (ativo && !opt.semTrading) {
      for (let v = 0; v < k; v++) {
        let aplicado = c.fracao * Math.max(0, g - piso);
        if (opt.absorcao != null) aplicado = Math.min(aplicado, opt.absorcao);
        const d = aplicado * e;
        g += d; ganhoTrading += d;
      }
    }
    const fora = opt.semFora ? 0 : c.fora;
    g += fora; ganhoFora += fora;
    if (g <= 0) break;
    for (const a of ALVOS) {
      if (quando[a] == null && g >= a) {
        quando[a] = dia;
        const tot = ganhoTrading + ganhoFora;
        partes[a] = tot > 0 ? ganhoTrading / tot : 0;
      }
    }
    if (quando[ALVOS[ALVOS.length - 1]] != null) break;
  }
  return { quando, partes, k, e };
}

const cenarios = {
  'C1 lento (HIPOTESE)': {
    fracao: 0.25, margem: 0.10, acerto: 0.60, perda: 0.08,
    sessao_h: 3, t_entrega: 1, t_venda: 6, t_correio: 1, fora: 0.5, piso: 1,
  },
  'C2 central (HIPOTESE)': {
    fracao: 0.50, margem: 0.12, acerto: 0.70, perda: 0.06,
    sessao_h: 6, t_entrega: 0.25, t_venda: 1.5, t_correio: 1, fora: 1.5, piso: 1,
  },
  'C3 pesado (HIPOTESE)': {
    fracao: 0.50, margem: 0.15, acerto: 0.80, perda: 0.05,
    sessao_h: 10, t_entrega: 0, t_venda: 1, t_correio: 1, fora: 3.0, piso: 1,
  },
};

const fmt = (r) => ALVOS.map((a) => (r.quando[a] == null ? '>10a' : String(r.quando[a])).padStart(6)).join(' ');
const fmtP = (r) => ALVOS.map((a) => (r.partes[a] == null ? '   -' : (100 * r.partes[a]).toFixed(0).padStart(3) + '%').padStart(6)).join(' ');

console.log('ESCADA DE CAPITAL: dias de jogo ate cada degrau, partindo de 5,09 ouro');
console.log('Tudo abaixo e HIPOTESE: aritmetica sobre parametros que o addon mede.');
console.log('');
for (const [nome, c] of Object.entries(cenarios)) {
  const k = voltas(c), e = borda(c);
  const taxa = c.fracao * k * e;
  const pEmpate = c.perda / (c.margem + c.perda);
  const virada = c.piso + c.fora / taxa;
  console.log('== ' + nome + ' ==');
  console.log(`  fracao aplicada ${c.fracao}  margem liquida ${c.margem}  acerto ${c.acerto}  perda no erro ${c.perda}`);
  console.log(`  sessao ${c.sessao_h} h  ciclo ${c.t_entrega + c.t_venda + c.t_correio} h  voltas/dia ${k}  entradas de fora ${c.fora} ouro/dia  piso ${c.piso} ouro`);
  console.log(`  borda por volta ${(100 * e).toFixed(2)}% do aplicado; crescimento do trading ${(100 * taxa).toFixed(2)}% ao dia sobre (ouro - piso); acerto de empate ${(100 * pEmpate).toFixed(0)}%`);
  console.log(`  banca de virada (ganho diario do trading = entradas de fora): ${virada.toFixed(1)} ouro`);
  console.log(`  trading no dia 1: ${(100 * taxa * (OURO0 - c.piso)).toFixed(1)} prata/dia = ${(100 * taxa * (OURO0 - c.piso) / c.sessao_h).toFixed(1)} prata por hora de sessao`);
  console.log('  variante                                                      15     60    250   1000   (dias)');
  const linhas = [
    ['a) trading + entradas de fora', simula(c)],
    ['b) so trading (entradas = 0)', simula(c, { semFora: true })],
    ['c) so entradas de fora (sem trading)', simula(c, { semTrading: true })],
    ['d) como escrito: compra so apos dia 14 e 15 ouro', simula(c, { portao: { dia: 14, banca: 15 } })],
    ['e) (a) com absorcao de 50 ouro por volta', simula(c, { absorcao: 50 })],
    ['f) (a) sem consolidar: parte de 1,27 ouro no negociador', simula(c, { ouro0: OURO0 / 4 })],
  ];
  for (const [rot, r] of linhas) console.log('  ' + rot.padEnd(58) + fmt(r));
  console.log('  ' + 'parte do ganho que veio do trading em (a)'.padEnd(58) + fmtP(simula(c)));
  console.log('');
}

// Sensibilidade no cenario central: o que mais pesa
console.log('== SENSIBILIDADE no C2 central: dias ate 60 e ate 250 ouro, mudando UM parametro ==');
const base = cenarios['C2 central (HIPOTESE)'];
const b0 = simula(base);
const d = (r, a) => (r.quando[a] == null ? '>10a' : String(r.quando[a]));
console.log(`  ${'base'.padEnd(44)} 60: ${d(b0, 60).padStart(5)}   250: ${d(b0, 250).padStart(5)}`);
const testes = [
  ['voltas/dia 1 (ciclo de 6 h)', { t_venda: 4.75 }],
  ['voltas/dia 4 (ciclo de 1,5 h)', { t_venda: 0.25 }],
  ['fracao aplicada 0,25', { fracao: 0.25 }],
  ['fracao aplicada 0,75 (acima do teto duro)', { fracao: 0.75 }],
  ['margem liquida 0,06', { margem: 0.06 }],
  ['margem liquida 0,18', { margem: 0.18 }],
  ['acerto 0,50', { acerto: 0.50 }],
  ['acerto 0,90', { acerto: 0.90 }],
  ['perda no erro 0,12', { perda: 0.12 }],
  ['entradas de fora 0 (so trading)', { fora: 0 }],
  ['entradas de fora 0,5 ouro/dia', { fora: 0.5 }],
  ['entradas de fora 3 ouro/dia', { fora: 3 }],
  ['entradas de fora 6 ouro/dia', { fora: 6 }],
  ['sessao de 12 h (4 voltas)', { sessao_h: 12 }],
  ['sessao de 3 h (1 volta)', { sessao_h: 3 }],
];
for (const [rot, mud] of testes) {
  const c = { ...base, ...mud };
  const r = simula(c);
  console.log(`  ${rot.padEnd(44)} 60: ${d(r, 60).padStart(5)}   250: ${d(r, 250).padStart(5)}   (voltas ${voltas(c)}, taxa ${(100 * c.fracao * voltas(c) * borda(c)).toFixed(1)}%/dia)`);
}
const rPiso = simula(base, { piso: 0 });
console.log(`  ${'piso pessoal 0 em vez de 1 ouro'.padEnd(44)} 60: ${d(rPiso, 60).padStart(5)}   250: ${d(rPiso, 250).padStart(5)}`);

// Trading por hora de sessao em cada degrau, contra a unica estimativa de farm que os relatorios trazem
console.log('');
console.log('== OURO POR HORA DE SESSAO SO DO TRADING, por degrau (HIPOTESE) ==');
console.log('  comparacao: R5b 2c traz a estimativa de um vendedor de ouro, da beta: 3 a 10 ouro por hora de farm no nivel 20 a 30 (nao medida)');
console.log('  banca        C1 lento    C2 central    C3 pesado');
for (const B of [5.09, 15, 60, 250, 1000]) {
  const cols = Object.values(cenarios).map((c) => {
    const porHora = c.fracao * voltas(c) * borda(c) * Math.max(0, B - c.piso) / c.sessao_h;
    return porHora.toFixed(2).padStart(9);
  });
  console.log(`  ${String(B).padStart(7)}  ${cols.join('     ')}   ouro/h`);
}
for (const [nome, c] of Object.entries(cenarios)) {
  const taxa = c.fracao * voltas(c) * borda(c);
  const b3 = c.piso + 3 * c.sessao_h / taxa;
  console.log(`  ${nome}: o trading so passa de 3 ouro por hora de sessao com banca acima de ${b3.toFixed(0)} ouro`);
}

// O que e day trading pesado em cada degrau: carga de teclas, acoes, buscas e banco
console.log('');
console.log('== CARGA POR VOLTA em cada degrau, com os tetos do design (HIPOTESE: absorcao A por item por volta) ==');
console.log('  aplicado = 50% de (banca - piso 1); itens = max(3 pelo teto de 20% por item, aplicado / A)');
console.log('  chamadas de acao por item = 3 (cotar, confirmar, postar); teclas por item = 6 (N, B rele, B cota, Y, N, P)');
console.log('  vigilia = uma foto por item a cada 5 min (R9 2.2: 5 min para 30 un/h com lotes de 6)');
console.log('  banca    A   aplicado  itens  acoes  min a 10/min  teclas  buscas/min vigilia  teclas L por passada  fotos MB (48 x 300 B)');
for (const B of [5.09, 15, 60, 250, 1000]) {
  for (const A of [1, 5]) {
    const aplicado = 0.5 * (B - 1);
    const itens = Math.max(3, Math.ceil(aplicado / A));
    const acoes = itens * 3;
    const teclas = itens * 6;
    const vig = itens / 5;
    const L = Math.ceil(itens / 20);
    const mb = itens * 48 * 300 / 1e6;
    console.log(`  ${String(B).padStart(6)} ${String(A).padStart(4)} ${aplicado.toFixed(1).padStart(9)} ${String(itens).padStart(6)} ${String(acoes).padStart(6)} ${(acoes / 10).toFixed(1).padStart(13)} ${String(teclas).padStart(7)} ${vig.toFixed(1).padStart(19)} ${String(L).padStart(21)} ${mb.toFixed(2).padStart(22)}`);
  }
}
console.log('  limites: teto duro do design 10 acoes/min e 30 buscas/min (secao 9.2); limite documentado 100 buscas/min (base 2.2); correio cerca de 60 min (base 1.8)');
console.log(`  itens que cabem na vigilia de 5 min: ${30 * 5} a 30 buscas/min; ${100 * 5} a 100 buscas/min`);

// Contas de apoio dos achados
console.log('');
console.log('== CONTAS DE APOIO ==');
const banca = OURO0 - 1;
console.log(`  banca consolidada = 5,09 - piso 1 = ${banca.toFixed(2)} ouro; teto de estoque 50% = ${(banca * 0.5).toFixed(2)} ouro`);
console.log(`  uma volta do aplicavel a 10% e 15% = ${(banca * 0.5 * 10).toFixed(0)} a ${(banca * 0.5 * 15).toFixed(0)} prata (o resumo do design diz 50 a 75)`);
const b1 = OURO0 / 4 - 1;
console.log(`  sem consolidar (1/4 do ouro no negociador): banca = ${b1.toFixed(2)} ouro; aplicavel = ${(b1 * 50).toFixed(1)} prata; uma volta = ${(b1 * 0.5 * 10).toFixed(1)} a ${(b1 * 0.5 * 15).toFixed(1)} prata`);
console.log(`  tetos de deposito com banca de ${banca.toFixed(2)} ouro: em risco 5% = ${(banca * 5).toFixed(1)} prata; perdido no dia 2% = ${(banca * 2).toFixed(1)} prata`);
console.log(`  tetos de deposito sem consolidar: em risco = ${(b1 * 5).toFixed(2)} prata; perdido no dia = ${(b1 * 2).toFixed(2)} prata`);
console.log(`  ate 17/11 o deposito minimo e 1 prata (base 1.7): cabem ${Math.floor(banca * 5)} leiloes no teto em risco consolidado e ${Math.floor(b1 * 5)} sem consolidar; ${Math.floor(banca * 2)} expiracoes esgotam o teto do dia`);
console.log(`  exemplo do proprio design (verde de 50 cobre de vendedor, deposito de 30 cobre em 24 h): cabem ${Math.floor(banca * 500 / 30)} consolidado e ${Math.floor(b1 * 500 / 30)} sem consolidar`);
const eta = 0.5, mu = 0.15, corte = 0.05;
console.log(`  limiar do vao na secao 3.2: (1 + margem)/(1 - c) = ${((1 + mu) / (1 - corte)).toFixed(3)} x o preco medio pago`);
console.log(`  limiar implicito da compra na secao 7.4 (eta ${eta} sobre o ganho, mu_min ${mu}): saida liquida >= ${(1 + mu / eta).toFixed(2)} x custo; preco de saida >= ${((1 + mu / eta) / (1 - corte)).toFixed(3)} x o preco pago (antes de deposito e teclas)`);
const tiq = 15, teclas = 4;
for (const m of [0.15, 0.30]) {
  const ordemMin = (teclas * tiq) / m;
  console.log(`  ordem minima em que ${teclas} teclas x ${tiq} cobre cabem numa margem de ${m}: ${ordemMin.toFixed(0)} cobre; a 5% da banca isso pede banca de ${(ordemMin / 0.05 / 10000).toFixed(2)} ouro (o design pede 15)`);
}
console.log(`  ordem micro de 5% com banca de ${banca.toFixed(2)} ouro = ${(banca * 5).toFixed(1)} prata; ganho esperado a 15% = ${(banca * 5 * 0.15).toFixed(1)} prata contra ${(teclas * tiq / 100).toFixed(2)} prata de teclas`);
console.log(`  blocos de 4 h por 3 semanas: ${6 * 21} pontos por chave; 1.500 chaves x ${6 * 21} x 10 bytes = ${(1500 * 126 * 10 / 1e6).toFixed(2)} MB; 150 chaves = ${(150 * 126 * 10 / 1e6).toFixed(2)} MB (o campo dias guarda 14 pontos por chave)`);
console.log(`  anel de 48 fotos a cada 5 min cobre ${(48 * 5 / 60).toFixed(0)} h; numa sessao de 10 h giram ${10 * 12} fotos por chave`);
console.log(`  postar 40 lotes: ${40} teclas se a linha seguinte entra sob o cursor, ${40 * 2} se cada lote pede N + P; 150 lotes a 10 acoes/min = ${150 / 10} min`);
