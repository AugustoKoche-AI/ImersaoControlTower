// Converte um HTML do gerar_slides.py (1920x1080, motor da Jornada) num .pptx editável.
// Para cada slide: o fundo (gradiente + brilho) vira imagem; caixas com fundo/borda viram
// formas; blocos de texto viram caixas de texto com os runs (cor, negrito); prints e
// diagramas viram imagens. Uso: node scripts/html_para_pptx.js <deck.html> <saida.pptx>  (npm i pptxgenjs@3.12.0 puppeteer-core@23.11.1 numa pasta e rode com NODE_PATH=<pasta>/node_modules; usa o Google Chrome instalado)
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const puppeteer = require("puppeteer-core");
const PptxGenJS = require("pptxgenjs");

const [, , HTML, SAIDA] = process.argv;
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const PX = 13.333 / 1920;          // polegada por px (LAYOUT_WIDE)
const PT = 0.5;                    // pt por px (13.333in * 72 / 1920)

function hex(c) {
  const m = c && c.match(/rgba?\(([\d.]+),\s*([\d.]+),\s*([\d.]+)(?:,\s*([\d.]+))?\)/);
  if (!m) return null;
  const a = m[4] === undefined ? 1 : parseFloat(m[4]);
  const h = [m[1], m[2], m[3]].map(v => Math.round(+v).toString(16).padStart(2, "0")).join("").toUpperCase();
  return { hex: h, a };
}

async function main() {
  const browser = await puppeteer.launch({ executablePath: CHROME, headless: "new",
    args: ["--allow-file-access-from-files"] });
  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080, deviceScaleFactor: 2 });
  await page.goto("file://" + path.resolve(HTML), { waitUntil: "networkidle0" });
  await new Promise(r => setTimeout(r, 4000));                      // Mermaid desenhar
  await page.addStyleTag({ content: `
    #stage{transform:none!important;position:fixed;left:0;top:0}
    #viewport{display:block!important}
    #progress,#hint{display:none!important}` });
  const n = await page.$$eval("section.slide", s => s.length);

  const pres = new PptxGenJS();
  pres.layout = "LAYOUT_WIDE";
  pres.title = "Projeto Farol";
  const fundos = {};

  for (let i = 0; i < n; i++) {
    await page.evaluate(i => {
      document.querySelectorAll("section.slide").forEach((s, j) => s.classList.toggle("active", j === i));
    }, i);
    await new Promise(r => setTimeout(r, 150));

    // ---- fundo: o slide sem o conteúdo
    await page.evaluate(i => {
      const s = document.querySelectorAll("section.slide")[i];
      [...s.children].forEach(c => c.style.visibility = "hidden");
    }, i);
    const bg = await page.screenshot({ clip: { x: 0, y: 0, width: 1920, height: 1080 }, type: "jpeg", quality: 82 });
    await page.evaluate(i => {
      const s = document.querySelectorAll("section.slide")[i];
      [...s.children].forEach(c => c.style.visibility = "");
    }, i);
    const hb = crypto.createHash("md5").update(bg).digest("hex");
    fundos[hb] = fundos[hb] || "image/jpeg;base64," + Buffer.from(bg).toString("base64");

    // ---- elementos
    const itens = await page.evaluate(i => {
      const s = document.querySelectorAll("section.slide")[i];
      const out = [];
      const INLINE = new Set(["SPAN", "B", "STRONG", "I", "EM", "CODE", "A", "BR", "SMALL", "SUB", "SUP"]);
      const cs = el => getComputedStyle(el);
      const visivel = el => { const r = el.getBoundingClientRect(); return r.width > 0 && r.height > 0 && cs(el).visibility !== "hidden"; };
      const temTextoDireto = el => [...el.childNodes].some(nd =>
        (nd.nodeType === 3 && nd.textContent.trim()) || (nd.nodeType === 1 && INLINE.has(nd.tagName) && nd.textContent.trim()));
      function runs(el, herda) {
        const res = [];
        el.childNodes.forEach(nd => {
          if (nd.nodeType === 3) {
            const t = nd.textContent.replace(/\s+/g, " ");
            if (t) res.push({ text: t, ...herda });
          } else if (nd.nodeType === 1 && INLINE.has(nd.tagName)) {
            if (nd.tagName === "BR") { res.push({ br: true }); return; }
            const c = cs(nd);
            const grad = nd.classList.contains("grad") || c.webkitTextFillColor === "rgba(0, 0, 0, 0)" ||
                         c.color === "rgba(0, 0, 0, 0)";
            res.push(...runs(nd, { color: grad ? "rgb(34, 194, 244)" : c.color,
                                   bold: parseInt(c.fontWeight) >= 600, italic: c.fontStyle === "italic",
                                   mono: /Mono|monospace/.test(c.fontFamily) }));
          }
        });
        return res;
      }
      function caixa(el) {
        const r = el.getBoundingClientRect(), c = cs(el);
        const bg = c.backgroundColor, bi = c.backgroundImage;
        let fill = bg !== "rgba(0, 0, 0, 0)" ? bg : null;
        if (!fill && bi && bi.includes("gradient") && !el.classList.contains("grad")) {
          const m = bi.match(/rgba?\([^)]+\)|#[0-9a-fA-F]{3,6}/); if (m) fill = m[0];
        }
        const bw = parseFloat(c.borderTopWidth) || 0;
        const borda = bw > 0 && c.borderTopStyle !== "none" && c.borderLeftWidth === c.borderTopWidth ? c.borderTopColor : null;
        const blw = parseFloat(c.borderLeftWidth) || 0;
        if (blw > 0 && bw === 0 && c.borderLeftStyle !== "none")      // só a borda esquerda: vira uma barrinha
          out.push({ k: "box", x: r.left, y: r.top, w: blw, h: r.height, fill: c.borderLeftColor, raio: 0, bw: 0 });
        if (!fill && !borda) return;
        const raios = [c.borderTopLeftRadius, c.borderTopRightRadius, c.borderBottomLeftRadius, c.borderBottomRightRadius].map(parseFloat);
        const uniforme = raios.every(v => v === raios[0]);
        // célula de tabela: borda de cima é só espaçamento (cor do fundo); desenha a área interna
        const bt = parseFloat(c.borderTopWidth) || 0;
        const isCell = el.tagName === "TD" || el.tagName === "TH";
        out.push({ k: "box", x: r.left, y: r.top + (isCell ? bt : 0), w: r.width, h: r.height - (isCell ? bt : 0),
                   fill, borda: isCell ? null : borda, bw, raio: uniforme ? raios[0] : 0,
                   tracejado: c.borderTopStyle === "dashed", opacidade: parseFloat(c.opacity) });
      }
      function texto(el) {
        const r = el.getBoundingClientRect(), c = cs(el);
        const pl = parseFloat(c.paddingLeft), pr = parseFloat(c.paddingRight), pt = parseFloat(c.paddingTop), pb = parseFloat(c.paddingBottom);
        const bl = parseFloat(c.borderLeftWidth) || 0, btp = parseFloat(c.borderTopWidth) || 0;
        const grad = el.classList.contains("grad");
        const base = { color: grad ? "rgb(34, 194, 244)" : c.color, bold: parseInt(c.fontWeight) >= 600,
                       italic: c.fontStyle === "italic", mono: /Mono|monospace/.test(c.fontFamily) };
        const rs = runs(el, base);
        if (!rs.some(x => x.text && x.text.trim())) return;
        // tira espaço do começo e do fim
        const prim = rs.find(x => x.text); if (prim) prim.text = prim.text.replace(/^\s+/, "");
        const ult = [...rs].reverse().find(x => x.text); if (ult) ult.text = ult.text.replace(/\s+$/, "");
        const fs = parseFloat(c.fontSize);
        const lh = c.lineHeight === "normal" ? fs * 1.25 : parseFloat(c.lineHeight);
        const pre = c.whiteSpace.startsWith("pre");
        let rsFinal = rs;
        if (pre) {                                   // código: mantém quebras e espaços
          rsFinal = [];
          const walk = (nd, herda) => nd.childNodes.forEach(ch => {
            if (ch.nodeType === 3) rsFinal.push({ text: ch.textContent, ...herda });
            else if (ch.nodeType === 1) { const cc = cs(ch); walk(ch, { ...herda, color: cc.color }); }
          });
          walk(el, base);
        }
        out.push({ k: "text", x: r.left + pl + bl, y: r.top + pt + btp, w: r.width - pl - pr - bl, h: r.height - pt - pb - btp,
                   size: fs, lh, align: c.textAlign, upper: c.textTransform === "uppercase",
                   spacing: c.letterSpacing === "normal" ? 0 : parseFloat(c.letterSpacing), pre, runs: rsFinal,
                   li: el.tagName === "LI" && el.closest("ul.list") ? true : false });
      }
      function visita(el) {
        if (!visivel(el)) return;
        const tag = el.tagName;
        if (tag === "IMG") { const r = el.getBoundingClientRect(), c = cs(el);
          out.push({ k: "img", x: r.left, y: r.top, w: r.width, h: r.height, src: el.currentSrc || el.src,
                     fit: c.objectFit, pos: c.objectPosition, nw: el.naturalWidth, nh: el.naturalHeight }); return; }
        if (tag === "PRE" && el.classList.contains("mermaid")) { const r = el.getBoundingClientRect();
          out.push({ k: "shot", x: r.left, y: r.top, w: r.width, h: r.height }); return; }
        if (tag === "svg") return;
        caixa(el);
        if (el.tagName === "LI" && el.closest("ul.list")) {     // o marcador quadrado ciano
          const r = el.getBoundingClientRect(), b = getComputedStyle(el, "::before");
          if (b.content !== "none") out.push({ k: "box", x: r.left + parseFloat(b.left || 0), y: r.top + parseFloat(b.top || 0),
            w: parseFloat(b.width), h: parseFloat(b.height),
            fill: b.backgroundColor !== "rgba(0, 0, 0, 0)" ? b.backgroundColor : null,
            borda: parseFloat(b.borderTopWidth) > 0 ? b.borderTopColor : null, bw: parseFloat(b.borderTopWidth) || 0,
            raio: parseFloat(b.borderTopLeftRadius) || 0 });
        }
        if (temTextoDireto(el) || (tag === "PRE")) { texto(el);
          // filhos em bloco dentro de um bloco com texto direto ainda precisam ser visitados
          [...el.children].forEach(ch => { if (!INLINE.has(ch.tagName) && tag !== "PRE") visita(ch); });
          return; }
        [...el.children].forEach(visita);
      }
      [...s.children].forEach(visita);
      return out;
    }, i);

    // diagramas: print do elemento em 2x
    // imagem que não é PNG/JPEG em base64 (SVG, por exemplo): vira print do elemento
    for (const it of itens.filter(x => x.k === "img" && !(x.src && /^data:image\/(png|jpe?g);base64,/.test(x.src)))) it.k = "shot";
    for (const it of itens.filter(x => x.k === "shot")) {
      const buf = await page.screenshot({ clip: { x: it.x, y: it.y, width: it.w, height: it.h }, type: "png", omitBackground: true });
      it.data = "image/png;base64," + Buffer.from(buf).toString("base64");
    }

    // ---- monta o slide
    const sl = pres.addSlide();
    sl.background = { data: fundos[hb] };
    for (const it of itens) {
      const pos = { x: it.x * PX, y: it.y * PX, w: Math.max(it.w, 1) * PX, h: Math.max(it.h, 1) * PX };
      if (it.k === "box") {
        const f = hex(it.fill), b = hex(it.borda);
        const raio = Math.min(it.raio, it.w / 2, it.h / 2) * PX;
        const o = { ...pos };
        const op = it.opacidade === undefined || isNaN(it.opacidade) ? 1 : it.opacidade;
        o.fill = f ? { color: f.hex, transparency: Math.round((1 - f.a * op) * 100) } : { type: "none" };
        o.line = b && b.a > 0 ? { color: b.hex, width: Math.max(it.bw * PT, 0.25), transparency: Math.round((1 - b.a) * 100),
                                  dashType: it.tracejado ? "dash" : "solid" } : { type: "none" };
        if (raio > 0) { o.rectRadius = raio; sl.addShape(pres.shapes.ROUNDED_RECTANGLE, o); }
        else sl.addShape(pres.shapes.RECTANGLE, o);
      } else if (it.k === "text") {
        const partes = [];
        it.runs.forEach((r, j) => {
          if (r.br) { if (partes.length) partes[partes.length - 1].options.breakLine = true; return; }
          const c = hex(r.color) || { hex: "FFFFFF", a: 1 };
          let t = it.upper ? r.text.toUpperCase() : r.text;
          if (it.pre) {                                   // uma linha por parágrafo no código
            const linhas = t.split("\n");
            linhas.forEach((ln, k) => {
              partes.push({ text: ln, options: { color: c.hex, bold: r.bold, fontFace: "Courier New",
                                                 breakLine: k < linhas.length - 1 } });
            });
            return;
          }
          partes.push({ text: t, options: { color: c.hex, bold: r.bold, italic: r.italic,
                                            fontFace: r.mono ? "Courier New" : "Poppins" } });
        });
        if (!partes.length) continue;
        sl.addText(partes, { ...pos, w: pos.w * 1.04, isTextBox: true, margin: 0, valign: "top",
          align: it.align === "center" ? "center" : it.align === "right" || it.align === "end" ? "right" : "left",
          fontSize: Math.round(it.size * PT * 10) / 10, fontFace: "Poppins",
          lineSpacing: Math.round(it.lh * PT * 10) / 10,
          charSpacing: it.spacing ? it.spacing * PT : undefined, fit: "none", wrap: true });
      } else if (it.k === "img") {
        if (!it.src || !it.src.startsWith("data:")) continue;
        const data = it.src.replace(/^data:/, "");
        const o = { data, ...pos };
        if (it.fit === "cover" || it.fit === "contain") o.sizing = { type: it.fit, w: pos.w, h: pos.h };
        if (it.fit === "contain" && it.nw && it.nh) {      // centraliza a imagem inteira na caixa
          const esc = Math.min(it.w / it.nw, it.h / it.nh), ww = it.nw * esc, hh = it.nh * esc;
          Object.assign(o, { x: (it.x + (it.w - ww) / 2) * PX, y: (it.y + (it.h - hh) / 2) * PX, w: ww * PX, h: hh * PX });
          delete o.sizing;
        }
        if (it.fit === "cover" && it.nw && it.nh) {        // corta do topo, como object-position: top
          const esc = Math.max(it.w / it.nw, it.h / it.nh);
          const cw = it.w / esc, ch = it.h / esc;
          o.sizing = { type: "crop", x: ((it.nw - cw) / 2) * PX * 0 + 0, y: 0, w: cw * PX, h: ch * PX };
          // pptxgenjs recorta em polegadas da imagem original: normaliza pela largura natural
          const k = pos.w / (cw * PX);
          o.sizing = { type: "crop", x: ((it.nw - cw) / 2) * PX * k, y: 0, w: pos.w, h: pos.h };
          o.w = it.nw * PX * k; o.h = it.nh * PX * k;
        }
        const b64 = data.split(",")[1] || "";
        if (b64.length % 4 !== 0 || /[^A-Za-z0-9+/=]/.test(b64)) { console.error("\nimagem inválida no slide", i + 1, data.slice(0, 60), b64.length); continue; }
        sl.addImage(o);
      } else if (it.k === "shot") {
        sl.addImage({ data: it.data, ...pos });
      }
    }
    process.stdout.write(`${i + 1} `);
  }
  await browser.close();
  // checagem: todo base64 que vai para o pptx precisa decodificar
  pres._slides.forEach((sl, k) => {
    const imgs = [...(sl._slideObjects || []).filter(o => o.image || o.imageData || o._type === "image")];
    (sl._relsMedia || []).forEach(m => {
      const d = m.data || "";
      const b = d.includes(",") ? d.split(",")[1] : d;
      if (d && (b.length % 4 !== 0 || /[^A-Za-z0-9+/=]/.test(b))) console.error("ruim no slide", k + 1, m.type, d.slice(0, 50), b.length);
    });
  });
  await pres.writeFile({ fileName: SAIDA });
  console.log("\nok:", SAIDA, n, "slides");
}
main().catch(e => { console.error(e); process.exit(1); });
