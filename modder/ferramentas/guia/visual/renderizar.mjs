// Fotografa os quadros do estudo visual (quadros.html#q1..#q4) pelo Edge sem tela, em png\.
// Uso: node renderizar.mjs [q1 q2 ...]   (sem argumento, todos)
//      node renderizar.mjs --html real.html agora pet   (outra pagina, hashes livres: grava png\real-agora.png e png\real-pet.png)
// Precisa do jogo instalado nesta maquina: as fontes vem do ElvUI e o fundo de um print do dono.
import { execFileSync } from "node:child_process";
import { mkdirSync, existsSync } from "node:fs";
import { basename, dirname, isAbsolute, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const aqui = dirname(fileURLToPath(import.meta.url));
const edge = ["C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", "C:/Program Files/Microsoft/Edge/Application/msedge.exe"].find(existsSync);
if (!edge) { console.error("RECUSA msedge.exe nao encontrado"); process.exit(2); }
const saida = join(aqui, "png");
mkdirSync(saida, { recursive: true });
const argv = process.argv.slice(2);
const iHtml = argv.indexOf("--html");
const arqHtml = iHtml >= 0 ? argv[iHtml + 1] : null;
const resto = argv.filter((_, i) => iHtml < 0 || (i !== iHtml && i !== iHtml + 1));
const comum = ["--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
  "--force-device-scale-factor=1", "--virtual-time-budget=4000", `--user-data-dir=${join(process.env.TEMP || aqui, "guia-visual-edge")}`];

if (arqHtml) {
  // pagina propria: a altura vem do proprio html (atributo data-h do body, medido por --dump-dom)
  const caminho = isAbsolute(arqHtml) ? arqHtml : [resolve(aqui, arqHtml), resolve(arqHtml)].find(existsSync);
  if (!caminho || !existsSync(caminho)) { console.error(`RECUSA ${arqHtml} nao encontrado`); process.exit(2); }
  const prefixo = basename(caminho).replace(/\.html?$/i, "");
  const hashes = resto.length ? resto : ["agora"];
  const urlBase = pathToFileURL(caminho).href;
  for (const h of hashes) {
    const url = `${urlBase}#${h}`;
    let alt = 780;
    try {
      const dom = execFileSync(edge, [...comum, "--window-size=844,800", "--dump-dom", url], { encoding: "utf8", timeout: 60000, stdio: ["ignore", "pipe", "ignore"] });
      const m = dom.match(/data-h="(\d+)"/);
      if (m) alt = Number(m[1]);
    } catch { /* usa a altura padrao */ }
    const arq = join(saida, `${prefixo}-${h}.png`);
    execFileSync(edge, [...comum, `--window-size=844,${alt}`, `--screenshot=${arq}`, url], { stdio: "ignore", timeout: 60000 });
    console.log(existsSync(arq) ? `OK ${arq}` : `FALHOU ${h}`);
  }
} else {
  const quadros = resto.length ? resto : ["q1", "q2", "q3", "q4"];
  const url = pathToFileURL(join(aqui, "quadros.html")).href;
  for (const q of quadros) {
    const arq = join(saida, `${q}.png`);
    execFileSync(edge, [...comum, "--window-size=1860,780", `--screenshot=${arq}`, `${url}#${q}`], { stdio: "ignore", timeout: 60000 });
    console.log(existsSync(arq) ? `OK ${arq}` : `FALHOU ${q}`);
  }
}
