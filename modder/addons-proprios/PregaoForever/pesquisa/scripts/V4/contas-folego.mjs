// Contas do folego (secao 5.2) e do orcamento por quadro (secao 1, regra 15), com os numeros da base.
// Uso: node contas-folego.mjs
const r = {};
// base 2.6: resumo de 7.718 chaves em 8,5 s e 16 pedidos; busca exata: 335 itens em 3 min 13 s
r.resumo_s_por_pedido = +(8.5 / 16).toFixed(2);
r.resumo_linhas_por_pedido = Math.round(7718 / 16);
r.busca_s_por_item_medido_base26 = +((3 * 60 + 13) / 335).toFixed(3);
r.busca_por_min_medido_base26 = +(335 / ((3 * 60 + 13) / 60)).toFixed(0);
// design: ate 30 buscas por minuto, 20 buscas por folego, teto de 60 s
const intervalo = 60 / 30;
r.foco_20_buscas_s = 20 * intervalo;
r.folego_com_resumo_s = +(1 + 8.5 + 20 * intervalo).toFixed(1);
r.folego_sem_resumo_s = 1 + 20 * intervalo;
// resumo maior (mercado com 12 mil chaves)
r.folego_resumo_12mil_s = +(1 + (12000 / 482) * (8.5 / 16) + 20 * intervalo).toFixed(1);
// idade da foto quando o dono age: busca k (0..19) sai em 1+8,5+2k s; o folego acaba em ~49,5 s; o dono le ~T_leitura
for (const leitura of [5, 15, 30]) {
  let velhas = 0;
  for (let k = 0; k < 20; k++) { const idade = (20 - 1 - k) * intervalo + leitura; if (idade > 30) velhas++; }
  r['fotos_velhas_de_20_com_leitura_' + leitura + 's'] = velhas;
}
// orcamento por quadro (R9 11.1: 1.000 a 3.000 iteracoes simples por ms, inferencia)
const linhas = 8000;
for (const ops of [5, 10]) for (const ritmo of [1000, 3000]) {
  const ms = linhas * ops / ritmo;
  r[`resumo_${ops}ops_${ritmo}it_ms`] = ms;
  r[`resumo_${ops}ops_${ritmo}it_quadros_2ms`] = Math.ceil(ms / 2);
  r[`resumo_${ops}ops_${ritmo}it_s_a_30fps`] = +(Math.ceil(ms / 2) / 30).toFixed(2);
}
// GetBrowseResults devolve a tabela inteira (R1a funcao 18). Lixo se chamada a cada pagina:
const pag = 16, porPag = 8000 / pag; let acum = 0; for (let p = 1; p <= pag; p++) acum += p * porPag;
r.linhas_alocadas_uma_chamada = 8000;
r.linhas_alocadas_chamada_por_pagina = acum;
const bytesLinha = (56 + 40 * 8) + (56 + 40 * 4); // BrowseResultInfo ~6 campos (8 nos) + itemKey 4 campos
r.MB_uma_chamada = +(8000 * bytesLinha / 1048576).toFixed(1);
r.MB_por_pagina = +(acum * bytesLinha / 1048576).toFixed(1);
// dia: virada em UTC para quem joga em UTC-3
r.virada_utc_em_brasilia = '21:00';
console.log(JSON.stringify(r, null, 2));
