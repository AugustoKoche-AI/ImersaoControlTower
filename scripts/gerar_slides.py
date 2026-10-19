#!/usr/bin/env python3
"""Monta a apresentação (slides 1920x1080 num HTML só) no visual da Jornada.

O visual (CSS, navegação por teclado/clique/toque, impressão em PDF) vem de
`slides/_modelo.html`, o mesmo motor das apresentações do time (jornada-ops).
Cada apresentação é um fragmento com só as <section class="slide">:

    slides/<nome>.slides.html   ->   slides/<nome>.html

Marcadores no fragmento:
    <!-- titulo: ... -->   título da aba
    [[RODAPE]]             logo + número da página
    [[IMG:docs/img/x.jpg]] imagem do repositório, embutida em base64

O HTML final abre sozinho (só a Poppins vem do Google Fonts).

Uso:  python3 scripts/gerar_slides.py slides/imersao.slides.html [--artifact destino.html]
"""
import base64
import mimetypes
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
MODELO = RAIZ / "slides" / "_modelo.html"
LOGO = RAIZ / "docs" / "img" / "logo-jornada-horizontal-branco.png"
RODAPE = '<img class="logo" alt="Jornada de Dados"><div class="pg"></div>'


def pendente(caminho: str) -> str:
    """Print que ainda não existe: um quadro tracejado com o nome do arquivo esperado."""
    nome = Path(caminho).name
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900" viewBox="0 0 1600 900">'
           f'<rect x="6" y="6" width="1588" height="888" rx="28" fill="#101016" stroke="#467CF6" '
           f'stroke-width="6" stroke-dasharray="26 18"/>'
           f'<text x="800" y="420" fill="#22C2F4" font-family="Poppins, sans-serif" font-size="64" '
           f'font-weight="700" text-anchor="middle">print pendente</text>'
           f'<text x="800" y="510" fill="#a3a6b4" font-family="Poppins, sans-serif" font-size="40" '
           f'text-anchor="middle">docs/img/{nome}</text></svg>')
    return "data:image/svg+xml;base64," + base64.b64encode(svg.encode()).decode("ascii")


def embutir(caminho: str) -> str:
    arq = RAIZ / caminho
    if not arq.exists():
        print(f"  aviso: {caminho} não existe ainda — entra o quadro de print pendente")
        return pendente(caminho)
    tipo = mimetypes.guess_type(arq.name)[0] or "image/png"
    return f"data:{tipo};base64," + base64.b64encode(arq.read_bytes()).decode("ascii")


def main() -> None:
    frag = Path(sys.argv[1]).resolve()
    slides = frag.read_text(encoding="utf-8")
    titulo = re.search(r"<!-- titulo: (.+?) -->", slides).group(1)
    html = MODELO.read_text(encoding="utf-8").replace("[[TITULO]]", titulo)
    html = html.replace("</style>", f'  img.logo {{ content: url("{embutir(LOGO.relative_to(RAIZ).as_posix())}"); }}\n</style>', 1)
    slides = slides.replace("[[RODAPE]]", RODAPE)
    slides = re.sub(r"\[\[IMG:(.+?)\]\]", lambda m: embutir(m.group(1)), slides)
    html = html.replace("[[SLIDES]]", slides)
    saida = frag.with_name(frag.name.replace(".slides.html", ".html"))
    saida.write_text(html, encoding="utf-8")
    print(f"ok: {saida.relative_to(RAIZ)} · {html.count('<section class=')} slides · {len(html) // 1024} KB")
    if "--artifact" in sys.argv:
        art = re.sub(r"<!doctype html>|</?html[^>]*>|</?head>|</?body>|<meta [^>]+>", "", html, flags=re.I)
        art = art.replace(":root {", ":root { color-scheme: dark;", 1)
        destino = Path(sys.argv[sys.argv.index("--artifact") + 1])
        destino.parent.mkdir(parents=True, exist_ok=True)
        destino.write_text(art.lstrip(), encoding="utf-8")
        print(f"artifact: {destino}")


if __name__ == "__main__":
    main()
