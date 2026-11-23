// Calculadora de receitas do PregaoForever (fora do jogo): Leatherworking pelo receitas-lw.json e, com --profissao,
// as seis profissoes de oficio (secao 10). Contrato em CONTRATO.md, secao 5.
// Uso: node crafts.mjs --pericia 180 [--linhas 8] [--todas] [--profissao <nome>]
import { pathToFileURL } from 'node:url';
import { ARQ_RECEITAS, ARQ_PRECOS, lerJson, moeda, arqReceitas, acharProfissao, PROFISSOES } from './comum.mjs';

const JANELA_AUCTIONATOR = 21600; // segundos: a exportacao do Auctionator so vale ate 6 horas
const PROF_MAX = 3;               // niveis de receita encadeada (candidato F) a partir do reagente direto
const USO = 'uso: node crafts.mjs --pericia 180 [--linhas 8] [--todas] [--desconto-vendedor 10] [--profissao <nome>]';

// Desconto de reputacao no vendedor, em %, padrao da linha de comando (secao 6.4). Dito pelo dono em 2026-11-17:
// o Hexumlite tem 10% em todo item de vendedor de Darnassus, linhas incluidas. 0 desliga.
export const DESCONTO_VENDEDOR = 10;

const chave = (id) => String(id);

// Copia das receitas com o preco de compra no vendedor (itens e padroes) vezes (1 - pct/100), arredondado.
// O preco de venda ao vendedor nao muda (reputacao so barateia a compra). pct 0 devolve as receitas. Funcao pura.
export function comDesconto(receitas, pct) {
  if (!pct) return receitas;
  const f = 1 - pct / 100;
  const d = (v) => (typeof v === 'number' && v > 0 ? Math.round(v * f) : v);
  const itens = {};
  for (const [k, it] of Object.entries(receitas.itens || {})) itens[k] = { ...it, compra: d(it.compra) };
  const lista = receitas.receitas.map((r) =>
    r.itemReceita ? { ...r, itemReceita: { ...r.itemReceita, compra: d(r.itemReceita.compra) } } : r);
  return { ...receitas, itens, receitas: lista };
}

// Le o valor de --desconto-vendedor (inteiro de 0 a 99). Devolve o numero ou { erro }.
export function lerDesconto(v) {
  if (v === undefined || !/^\d+$/.test(v) || Number(v) > 99) return { erro: '--desconto-vendedor pede um inteiro de 0 a 99' };
  return Number(v);
}

// Reagentes validos de uma receita: id diferente de 0 e quantidade maior que 0.
const reagentesDe = (r) => r.reagentes.filter((g) => Number(g.id) !== 0 && g.qtd > 0);

// Funcao pura: nao le arquivo e nao usa relogio. A hora vem em opcoes.agora (epoch em segundos).
export function calcular(receitas, precos, opcoes) {
  const { pericia, agora } = opcoes;
  const itens = receitas.itens || {};
  const pub = precos.publico || {};
  const pubItens = pub.itens || {};
  const vendedor = new Set((precos.vendedor || []).map(chave));
  const auct = precos.auctionator || null;
  const aucFresco = auct !== null && agora - auct.em <= JANELA_AUCTIONATOR;

  // Receitas agrupadas pelo produto, para o candidato F.
  const porProduto = new Map();
  for (const r of receitas.receitas) {
    if (!r.produto) continue; // encantamento (secao 10): nao faz item
    const k = chave(r.produto.id);
    if (!porProduto.has(k)) porProduto.set(k, []);
    porProduto.get(k).push(r);
  }

  // Preco do Auctionator: so vale se a exportacao esta na janela e o item tem idade 0.
  function precoA(id) {
    if (!aucFresco) return null;
    const it = auct.itens?.[chave(id)];
    return it && it.idadeDias === 0 && it.preco != null ? it.preco : null;
  }

  // Preco de leilao: Auctionator (A) ou minimo publico (P). Memorizado por item.
  const memoPl = new Map();
  function pl(id) {
    const k = chave(id);
    if (!memoPl.has(k)) {
      const a = precoA(id);
      let v = null;
      if (a !== null) v = { preco: a, fonte: 'A' };
      else if (pubItens[k]) v = { preco: pubItens[k].min, fonte: 'P' };
      memoPl.set(k, v);
    }
    return memoPl.get(k);
  }

  // Preco conservador: o maior entre o preco de leilao e o p25 publico (sem dado publico, o proprio preco).
  function pc(id) {
    const p = pl(id);
    if (p === null) return null;
    const pb = pubItens[chave(id)];
    return pb ? Math.max(p.preco, pb.p25) : p.preco;
  }

  // Custo unitario de um item: o menor entre L (leilao), V (vendedor) e F (fabricar).
  // Devolve { preco, letra, bloq }. bloq indica que a guarda de ciclo cortou algum ramo; esse
  // resultado nao entra no cache, para que um corte feito por um caminho nao estrague a conta de outro.
  const cache = new Map();
  function cu(id, modo, prof, caminho) {
    const k = `${modo}|${chave(id)}|${prof}`;
    if (cache.has(k)) return cache.get(k);
    let bloq = false;
    const cands = [];
    const L = modo === 'min' ? (pl(id)?.preco ?? null) : pc(id);
    if (L !== null) cands.push({ preco: L, letra: 'L' });
    const it = itens[chave(id)];
    if (vendedor.has(chave(id)) && it && it.compra > 0) cands.push({ preco: it.compra, letra: 'V' });
    const receitasDoItem = porProduto.get(chave(id)) || [];
    if (receitasDoItem.length > 0) {
      if (caminho.has(chave(id))) bloq = true;
      else if (prof <= PROF_MAX) {
        const caminho2 = new Set(caminho);
        caminho2.add(chave(id));
        let melhor = null;
        for (const r of receitasDoItem) {
          let soma = 0, ok = true;
          for (const g of reagentesDe(r)) {
            const x = cu(g.id, modo, prof + 1, caminho2);
            if (x.bloq) bloq = true;
            if (x.preco === null) ok = false;
            else soma += g.qtd * x.preco;
          }
          if (ok) {
            const preco = soma / r.produto.qtd;
            if (melhor === null || preco < melhor) melhor = preco;
          }
        }
        if (melhor !== null) cands.push({ preco: melhor, letra: 'F' });
      }
    }
    // Empate: vale o candidato que veio primeiro (L, V, F).
    let escolhido = null;
    for (const c of cands) if (escolhido === null || c.preco < escolhido.preco) escolhido = c;
    const res = escolhido
      ? { preco: escolhido.preco, letra: escolhido.letra, bloq }
      : { preco: null, letra: null, bloq };
    if (!bloq) cache.set(k, res);
    return res;
  }

  // Monta a linha de uma receita, com todos os campos da tabela do contrato.
  function linhaDe(r) {
    const prod = r.produto; // null no encantamento (secao 10)
    const pk = prod ? chave(prod.id) : null;
    const itemProd = pk ? itens[pk] || null : null;
    const guarda = () => (pk ? new Set([pk]) : new Set());
    const reag = reagentesDe(r).map((g) => ({
      id: g.id,
      qtd: g.qtd,
      min: cu(g.id, 'min', 1, guarda()),
      cons: cu(g.id, 'cons', 1, guarda()),
    }));

    const semPreco = reag.some((g) => g.min.preco === null);
    const somaDe = (modo) => reag.reduce((s, g) => s + g.qtd * g[modo].preco, 0);
    const custo = semPreco ? null : Math.round(somaDe('min'));
    const custoCons = (semPreco || reag.some((g) => g.cons.preco === null)) ? null : Math.round(somaDe('cons'));

    const fontes = {};
    for (const g of reag) if (g.min.preco !== null) fontes[chave(g.id)] = g.min.letra;

    // Venda ao vendedor: o produto nao depende de preco de reagente, mas, com sem preco, os campos de dinheiro saem null.
    // Encantamento: nao ha produto, a venda e 0.
    let vendaNpc = null;
    if (!semPreco) vendaNpc = prod ? (itemProd ? prod.qtd * itemProd.vende : null) : 0;
    const lucroNpc = vendaNpc !== null && custo !== null ? vendaNpc - custo : null;
    const lucroNpcCons = vendaNpc !== null && custoCons !== null ? vendaNpc - custoCons : null;

    // Menor quantidade de unidades por dia que o leilao aguenta, entre reagentes com letra L no modo cons.
    let ate = null;
    if (!semPreco) {
      for (const g of reag) {
        const p = pubItens[chave(g.id)];
        if (g.cons.letra === 'L' && p) {
          const v = Math.floor(0.25 * p.unid / g.qtd);
          ate = ate === null ? v : Math.min(ate, v);
        }
      }
    }

    // Cor da receita para a pericia atual.
    const s = pericia;
    const { amarela, cinza } = r;
    let cor;
    if (s < amarela) cor = 'laranja';
    else if (s < (amarela + cinza) / 2) cor = 'amarela';
    else if (s < cinza) cor = 'verde';
    else cor = 'cinza';

    // Chance de subir a pericia com uma craft (sem pontos, a chance e 0).
    let chance;
    if (r.pontos === 0) chance = 0;
    else if (cor === 'laranja') chance = 1;
    else if (cor === 'cinza') chance = 0;
    else chance = Math.min(1, Math.max(0, (cinza - s) / (cinza - amarela)));

    const custoPonto = chance > 0 && custo !== null && vendaNpc !== null
      ? (custo - vendaNpc) / (chance * r.pontos)
      : null;

    // Leilao do produto: nao entra se o produto e vinculado (vinculo 1) ou sem preco.
    const vinculado = itemProd !== null && itemProd.vinculo === 1;
    const plProd = !semPreco && !vinculado && prod ? pl(prod.id) : null;
    const precoLeilao = plProd ? plProd.preco : null;
    const fontePrecoLeilao = plProd ? plProd.fonte : null;
    const lucroLeilao = precoLeilao !== null && custo !== null
      ? Math.round(prod.qtd * precoLeilao * 0.95) - custo
      : null;

    // Media de saidas por dia, so nos dias com 23 horas ou mais de cobertura.
    const saidas = pk ? pub.saidas?.[pk] : undefined;
    const horas = pub.horas || {};
    const diasCheios = Object.keys(horas).filter((d) => horas[d] >= 23);
    let saiDia = null;
    if (saidas && diasCheios.length > 0) {
      saiDia = diasCheios.reduce((t, d) => t + (saidas[d] || 0), 0) / diasCheios.length;
    }

    const listados = pk ? pubItens[pk]?.unid ?? null : null;

    // Divergencia: Auctionator (idade 0) e minimo publico diferem mais de 20% do minimo publico.
    const divergencias = [];
    const vistos = new Set();
    for (const id of [...reag.map((g) => g.id), ...(prod ? [prod.id] : [])]) {
      const k = chave(id);
      if (vistos.has(k)) continue;
      vistos.add(k);
      const a = precoA(id);
      const p = pubItens[k];
      if (a !== null && p && p.min > 0 && Math.abs(a - p.min) > 0.2 * p.min) divergencias.push(Number(id));
    }

    // Pericia para aprender: a do item de receita; sem item, estimada a partir da cor amarela. No esquema 2
    // (secao 10): a receita que vem com a profissao e 1; a de treinador pelo Naowh usa a pericia dele.
    const nw = r.naowh || null;
    let aprende, aprendeFonte;
    if (r.inicial) { aprende = 1; aprendeFonte = 'inicial'; }
    else if (nw && nw.origem === 'trainer' && nw.aprende != null) { aprende = nw.aprende; aprendeFonte = 'naowh'; }
    else if (r.itemReceita != null) { aprende = r.itemReceita.periciaExigida; aprendeFonte = 'item'; }
    else if (nw && nw.aprende != null) { aprende = nw.aprende; aprendeFonte = 'naowh'; }
    else { aprende = Math.max(1, amarela - 25); aprendeFonte = 'estimada'; }
    const aprendeEstimado = aprendeFonte === 'estimada';
    const podeFazer = aprende <= pericia;
    // Custo de treino da receita, quando o Naowh diz que e de treinador (cobre); senao null.
    const treino = nw && nw.origem === 'trainer' && typeof nw.custo === 'number' ? nw.custo : null;

    // Ralo: ha preco de leilao, mas poucos anuncios (ou nenhum).
    const ralo = precoLeilao !== null && (listados === null || listados < 5);

    return {
      magia: r.magia,
      nome: r.nome,
      produtoId: prod ? prod.id : null,
      qtd: prod ? prod.qtd : 0,
      semPreco,
      fontes,
      // preco unitario e letra (L, V ou F) de cada reagente no modo min, para os numeros vivos do J (secao 6.3)
      reagentes: reag.map((g) => ({ id: Number(g.id), qtd: g.qtd, preco: g.min.preco, letra: g.min.letra })),
      custo,
      custoCons,
      vendaNpc,
      lucroNpc,
      lucroNpcCons,
      ate,
      cor,
      chance,
      custoPonto,
      precoLeilao,
      fontePrecoLeilao,
      lucroLeilao,
      saiDia,
      listados,
      divergencias,
      aprende,
      aprendeEstimado,
      aprendeFonte,
      treino,
      podeFazer,
      ralo,
    };
  }

  const linhas = receitas.receitas.map(linhaDe);
  return { pericia, linhas, semPreco: linhas.filter((l) => l.semPreco).length };
}

// ---------- linha de comando ----------

const ASCII = (s) => String(s).replace(/[^\x20-\x7e]/g, '?');
const celula = (s, n) => {
  const t = ASCII(s);
  return (t.length > n ? t.slice(0, n - 2) + '..' : t).padEnd(n);
};
const linha = (cols, larguras) => cols.map((c, i) => celula(c, larguras[i])).join(' ').trimEnd();
const mo = (v) => (v === null ? '-' : moeda(v));

// Hora local HH:MM a partir de epoch em segundos.
function hora(epoch) {
  const d = new Date(epoch * 1000);
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}

// Idade em "35 min" ou "2 h 05 min".
function idade(seg) {
  const s = Math.max(0, Math.floor(seg));
  const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
  return h ? `${h} h ${String(m).padStart(2, '0')} min` : `${m} min`;
}

// Coluna aprende: "145 i" quando vem do item, "~140" quando e estimada, "120 t" do treinador pelo Naowh e "1 s"
// quando vem com a profissao (secao 10).
export const aprendeTxt = (l) => {
  if (l.aprendeEstimado) return `~${l.aprende}`;
  if (l.aprendeFonte === 'naowh') return `${l.aprende} t`;
  if (l.aprendeFonte === 'inicial') return `${l.aprende} s`;
  return `${l.aprende} i`;
};

// Monta uma secao: titulo, cabecalho, ate "limite" linhas e a linha "mais N".
function secao(titulo, cabs, larguras, dados, limite) {
  const out = [titulo];
  if (dados.length === 0) return [...out, '  nenhuma'];
  out.push(linha(cabs, larguras));
  for (const d of dados.slice(0, limite)) out.push(linha(d, larguras));
  if (dados.length > limite) out.push(`mais ${dados.length - limite}`);
  return out;
}

function relatorio(res, receitas, precos, agora, limite, todas) {
  const porMagia = new Map(receitas.receitas.map((r) => [chave(r.magia), r]));
  const itens = receitas.itens || {};
  // Letras das fontes na ordem dos reagentes da receita (ex.: LVL).
  const letras = (l) => reagentesDe(porMagia.get(chave(l.magia)))
    .map((g) => l.fontes[chave(g.id)] || '?').join('');

  // Cabecalho: pericia, foto publica e exportacao do Auctionator, cada uma com hora e idade.
  const foto = precos.publico?.foto;
  const fotoTxt = foto ? `foto publica ${hora(foto)} (ha ${idade(agora - foto)})` : 'foto publica sem data';
  let aucTxt = 'Auctionator: sem exportacao';
  if (precos.auctionator) {
    const seg = agora - precos.auctionator.em;
    aucTxt = `Auctionator: exportado ${hora(precos.auctionator.em)} (ha ${idade(seg)})`;
    if (seg > JANELA_AUCTIONATOR) aucTxt += ', velha: nao usada';
  }
  const cab = [`PREGAO - ${receitas.profissao?.nome ?? 'Leatherworking'} - pericia ${res.pericia}`, `${fotoTxt} | ${aucTxt}`];

  // Sem --todas, as secoes so mostram receitas que a pericia atual deixa aprender.
  const mostra = (l) => todas || l.podeFazer;
  const foraPericia = res.linhas.filter((l) => !l.podeFazer).length;

  // PAGAM NO VENDEDOR: lucro >= 0, do maior para o menor.
  const vendedorRows = res.linhas
    .filter((l) => mostra(l) && l.lucroNpc !== null && l.lucroNpc >= 0)
    .sort((a, b) => b.lucroNpc - a.lucroNpc)
    .map((l) => [l.nome, l.cor, `${moeda(l.custo)} ${letras(l)}`, mo(l.vendaNpc), mo(l.lucroNpc), mo(l.lucroNpcCons), l.ate ?? '-']);
  // Empatam: lucro menor que 0 e de ate 2% do custo.
  const empatam = res.linhas.filter((l) =>
    mostra(l) && l.lucroNpc !== null && l.custo !== null && l.lucroNpc < 0 && l.lucroNpc >= -0.02 * l.custo).length;

  // SOBEM A PERICIA: chance > 0, do menor custo por ponto para o maior (sem custo por ponto, no fim).
  const sobemRows = res.linhas
    .filter((l) => mostra(l) && l.chance > 0)
    .sort((a, b) => {
      if (a.custoPonto === null) return b.custoPonto === null ? 0 : 1;
      if (b.custoPonto === null) return -1;
      return a.custoPonto - b.custoPonto;
    })
    .map((l) => [
      l.nome, l.cor, aprendeTxt(l), `${Math.round(l.chance * 100)}%`, mo(l.custoPonto), mo(l.lucroNpc), mo(l.lucroLeilao),
    ]);

  // PAGAM NO LEILAO: lucro > 0, do maior para o menor. Linha ralo leva '*' depois dos listados.
  const leilaoRows = res.linhas
    .filter((l) => mostra(l) && l.lucroLeilao !== null && l.lucroLeilao > 0)
    .sort((a, b) => b.lucroLeilao - a.lucroLeilao)
    .map((l) => [
      l.nome, l.cor, `${Math.round(l.chance * 100)}%`, mo(l.precoLeilao), l.fontePrecoLeilao ?? '-',
      moeda(l.lucroLeilao), `${l.listados ?? '-'}${l.ralo ? '*' : ''}`,
      l.saiDia === null ? '-' : String(Math.round(l.saiDia * 10) / 10),
    ]);

  // Rodape: sem preco (e fora por pericia, sem --todas) e divergencias numa linha so, com no maximo 6 ids;
  // depois os avisos fixos em tres linhas.
  const divIds = [...new Set(res.linhas.flatMap((l) => l.divergencias))].sort((a, b) => a - b);
  const divTxt = divIds.length === 0
    ? 'nenhuma'
    : divIds.slice(0, 6).join(', ') + (divIds.length > 6 ? ` e mais ${divIds.length - 6}` : '');
  const resumo = `sem preco: ${res.semPreco} receita(s)`
    + (todas ? '' : ` | fora por pericia: ${foraPericia} (use --todas)`)
    + ` | divergencias A x P: ${divTxt}`;
  const rodape = [
    resumo,
    'aviso: chance de ponto: formula do Classic, nao conferida no Forever | corte de 5% do leilao: inferido do cliente',
    'aviso: V = vendedor, pode ter estoque limitado | saidas por dia: estimativa de terceiro',
    'aviso: ~ = pericia de aprender estimada | * = menos de 5 listados',
  ];

  return [
    ...cab,
    ...secao('PAGAM NO VENDEDOR',
      ['receita', 'cor', 'custo', 'vendedor', 'lucro', 'lucro cons.', 'ate'],
      [26, 8, 19, 11, 11, 11, 5], vendedorRows, limite),
    `empatam (lucro menor que 0 e de ate 2% do custo): ${empatam}`,
    ...secao('SOBEM A PERICIA',
      ['receita', 'cor', 'aprende', 'chance', 'custo/ponto', 'lucro vend.', 'lucro leil.'],
      [26, 8, 8, 7, 13, 12, 12], sobemRows, limite),
    ...secao('PAGAM NO LEILAO (se vender)',
      ['receita', 'cor', 'chance', 'preco', 'fonte', 'lucro', 'listados', 'saiDia'],
      [26, 8, 7, 12, 6, 12, 9, 7], leilaoRows, limite),
    ...rodape,
  ];
}

// Le --pericia, --linhas e --todas. Devolve { erro } se faltar ou vier errado.
function lerOpcoes(argv) {
  const op = { pericia: null, linhas: 8, todas: false, desconto: DESCONTO_VENDEDOR, profissao: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--todas') {
      op.todas = true;
    } else if (a === '--profissao') {
      const p = acharProfissao(argv[++i]);
      if (!p) return { erro: `--profissao pede uma de: ${Object.keys(PROFISSOES).join(', ')}` };
      op.profissao = p;
    } else if (a === '--desconto-vendedor') {
      const d = lerDesconto(argv[++i]);
      if (d.erro) return d;
      op.desconto = d;
    } else if (a === '--pericia' || a === '--linhas') {
      const v = argv[++i];
      if (v === undefined || !/^\d+$/.test(v)) return { erro: `${a} pede um numero inteiro` };
      if (a === '--pericia') op.pericia = Number(v);
      else op.linhas = Number(v);
    } else {
      return { erro: `argumento desconhecido: ${a}` };
    }
  }
  if (op.pericia === null) return { erro: 'falta --pericia' };
  if (op.linhas < 1) return { erro: '--linhas precisa ser pelo menos 1' };
  return op;
}

async function lerEntrada(arq, script) {
  try {
    return await lerJson(arq);
  } catch (e) {
    if (e.code === 'ENOENT') {
      console.error(`falta ${arq}: rode antes ${script}`);
      process.exit(2);
    }
    throw e;
  }
}

async function linhaDeComando(argv) {
  const op = lerOpcoes(argv);
  if (op.erro) {
    console.error(`${op.erro}\n${USO}`);
    process.exit(2);
  }
  const arq = op.profissao ? arqReceitas(op.profissao.slug) : ARQ_RECEITAS;
  const gerar = op.profissao ? `gerar-receitas.mjs --profissao ${op.profissao.slug}` : 'gerar-receitas.mjs';
  const receitas = comDesconto(await lerEntrada(arq, gerar), op.desconto);
  const precos = await lerEntrada(ARQ_PRECOS, 'baixar-precos.mjs');
  const agora = Math.floor(Date.now() / 1000);
  const res = calcular(receitas, precos, { pericia: op.pericia, agora });
  console.log(relatorio(res, receitas, precos, agora, op.linhas, op.todas).join('\n'));
  console.log(`desconto de vendedor: ${op.desconto}% na compra${op.desconto ? ' (Darnassus; fora de la, --desconto-vendedor 0)' : ''}`);
}

// So roda a linha de comando quando o arquivo e chamado direto.
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  linhaDeComando(process.argv.slice(2)).catch((e) => {
    console.error(`erro: ${e.message}`);
    process.exit(1);
  });
}
