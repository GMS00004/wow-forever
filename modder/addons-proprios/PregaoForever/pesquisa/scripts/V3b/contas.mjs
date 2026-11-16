// Contas de conferencia do parecer V3b-motor (so aritmetica, nada do jogo)
const f = (x, d = 3) => Number(x).toFixed(d);

// 1. P* do exemplo da secao 3.1 do design: v=50, p=200, c=0.05, rs=1, rx=0
const pstar = (p, v, c, du, rs, rx) => ((1 - rx) * du) / (p * (1 - c) - v + (rs - rx) * du);
console.log('P* deposito 100c:', f(pstar(200, 50, 0.05, 100, 1, 0)));
console.log('P* deposito 30c :', f(pstar(200, 50, 0.05, 30, 1, 0)));

// 2. Intervalo de Wilson de 95% para k de n
const wilson = (k, n, z = 1.96) => {
  const ph = k / n, z2 = z * z;
  const c = (ph + z2 / (2 * n)) / (1 + z2 / n);
  const h = (z * Math.sqrt((ph * (1 - ph)) / n + z2 / (4 * n * n))) / (1 + z2 / n);
  return [c - h, c + h];
};
for (const [k, n] of [[4, 10], [2, 10], [7, 10], [12, 30], [21, 30]]) {
  const [a, b] = wilson(k, n);
  console.log(`Wilson ${k}/${n}:`, f(a), f(b));
}

// 3. Fracao recuperada pela formula xi do R9 2.2: xi = 1 + 0.5*u^0.8, u = lambda*Delta/l_f
const xi = (u) => 1 + 0.5 * Math.pow(u, 0.8);
for (const [lam, lf, dmin] of [[30, 6, 5], [30, 6, 15], [30, 6, 60], [3, 3, 30], [600, 20, 1], [600, 20, 3], [600, 20, 10]]) {
  const u = (lam * (dmin / 60)) / lf;
  console.log(`lambda=${lam}/h l_f=${lf} Delta=${dmin}min u=${f(u, 2)} xi=${f(xi(u), 2)} recuperado=${f(1 / xi(u), 2)}`);
}

// 4. Delta_alvo = 0.4*l_f/lambda (em minutos)
for (const [lam, lf] of [[30, 6], [3, 3], [600, 20], [200, 10]]) {
  console.log(`Delta_alvo lambda=${lam} l_f=${lf}:`, f((0.4 * lf / lam) * 60, 1), 'min');
}

// 5. Fracao de leiloes que expira dentro de Delta, com tempo restante uniforme em [0, D]
for (const [D, dmin] of [[2, 5], [2, 10], [2, 30], [2, 60], [8, 30], [8, 60], [24, 60]]) {
  console.log(`expira em ${dmin}min com duracao ${D}h:`, f(Math.min(1, dmin / 60 / D), 3));
}

// 6. Salto relativo de 1 e 2 ticks em precos baixos (filtro de isca de 15%, cobertura fina de 3%)
for (const p of [5, 9, 20, 50, 108, 200]) {
  console.log(`preco ${p}c: +1 tick = ${f(100 / p, 1)}%  +2 ticks = ${f(200 / p, 1)}%`);
}
console.log('preco minimo para 1 tick < 15%:', Math.ceil(1 / 0.15), 'ticks; para 1 tick <= 3%:', Math.ceil(1 / 0.03), 'ticks');

// 7. Ordem entre precos iguais: chance de 5 observacoes concordantes se a ordem for aleatoria
console.log('5 concordantes ao acaso:', f(2 * Math.pow(0.5, 5), 4));

// 8. Colisao de assinatura truncada: n vendedores distintos numa escada, b bits
const colisao = (n, bits) => 1 - Math.exp((-n * (n - 1)) / (2 * Math.pow(2, bits)));
for (const [n, b] of [[20, 12], [50, 12], [20, 16], [50, 16], [200, 16], [50, 20]]) {
  console.log(`colisao n=${n} bits=${b}:`, f(colisao(n, b), 4));
}
console.log('nomes por balde com 3.6M personagens e 16 bits:', f(3.6e6 / 65536, 0));

// 9. Cobertura de tempo: horas observadas por dia e fracao do dia
for (const h of [1, 2, 3]) console.log(`leilao aberto com folegos densos ${h}h/dia: cobre`, f((h / 24) * 100, 1), '% do dia');

// 10. Folego: 20 buscas a 30 por minuto
console.log('20 buscas a 30/min:', (20 / 30) * 60, 's');
