#!/usr/bin/env python3
"""Monta o PROMPTS.md a partir da seção "## O prompt" de cada arquivo de prd.

Uso:  python3 scripts/gerar_prompts.py      (rode da raiz do repositório)

O texto NÃO é copiado à mão: é extraído dos arquivos de cada noite, para o
guia da sequência e o material da noite nunca divergirem. As partes fixas
(cabeçalho, intervalos entre noites e rodapé) ficam em scripts/prompts-*.md:
edite lá, nunca direto no PROMPTS.md, que é gerado.

Noite que ainda não tem os arquivos de prompt é pulada (com aviso), para o
PROMPTS.md poder ser gerado à medida que as noites ficam prontas.
"""
import pathlib
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parents[1]
A3, A4 = "aulas/aula-03-modelagem-claude-code/claude-code/prd", "aulas/aula-04-produtos-de-dados-ia/prd"

# (noite, título, subtítulo, caminho, deploy) — o número do prompt é a posição na lista
PROMPTS = [
    (3, "Conferência + silver", "a bronze conferida e as três ferramentas viram uma", f"{A3}/prompt-02-silver.md", "bundle deploy + run do pipeline"),
    (3, "Gold + testes", "o produto de dados e as perguntas do dono", f"{A3}/prompt-03-gold.md", "bundle deploy + run"),
    (3, "O job completo", "a Torre roda sozinha, e lê o texto do status com IA", f"{A3}/prompt-04-job-completo.md", "bundle deploy + run"),
    (3, "O dashboard", "o dono vê a Torre", f"{A3}/prompt-05-dashboard.md", "bundle deploy"),
    (4, "O modelo", "o que vai dar errado no próximo mês", f"{A4}/prompt-01-modelo.md", "bundle deploy + run"),
    (4, "Métricas + Genie", "o dono pergunta em português", f"{A4}/prompt-02-genie.md", "bundle deploy + run + deploy"),
    (4, "O app da Torre", "a Torre na tela do dono", f"{A4}/prompt-03-app.md", "apps deploy"),
    (4, "A aprovação no Lakebase", "a decisão fica registrada (opcional)", f"{A4}/prompt-04-aprovacao-lakebase.md", "apps deploy"),
]

TITULOS = {3: "Noite 3 · a Torre roda sozinha", 4: "Noite 4 · a Torre prevê, responde e ganha uma URL"}
INTERVALO = {3: "prompts-meio-34.md"}   # o rodapé entra sempre, no fim


def extrair(caminho: str) -> str:
    """Devolve o conteúdo do primeiro bloco ``` depois de '## O prompt'."""
    txt = (RAIZ / caminho).read_text(encoding="utf-8")
    depois = txt.split("## O prompt", 1)[1]
    m = re.search(r"```\n(.*?)\n```", depois, re.S)
    if not m:
        sys.exit(f"bloco não encontrado em {caminho}")
    return m.group(1).rstrip()


def main() -> None:
    texto = (RAIZ / "scripts/prompts-cabecalho.md").read_text(encoding="utf-8")
    # o 1 da noite 3 é o bundle feito à mão com a CLI (prd/passo-01-bundle-na-mao.md), não um prompt
    n_total = 1
    for noite in (3, 4):
        da_noite = [p for p in PROMPTS if p[0] == noite]
        existentes = [p for p in da_noite if (RAIZ / p[3]).exists()]
        if not existentes:
            print(f"aviso: noite {noite} ainda sem prompts — pulada")
            continue
        partes = []
        for _, titulo, sub, caminho, deploy in existentes:
            n_total += 1
            partes.append(
                f"### Prompt {n_total} · {titulo}\n\n"
                f"*{sub}* · noite {noite} · {deploy} · "
                f"[texto completo, com o que falar e as armadilhas]({caminho})\n\n"
                f"```\n{extrair(caminho)}\n```\n"
            )
        texto += f"## {TITULOS[noite]}\n\n" + "\n".join(partes)
        if noite in INTERVALO:
            texto += (RAIZ / "scripts" / INTERVALO[noite]).read_text(encoding="utf-8")
    texto += (RAIZ / "scripts/prompts-rodape.md").read_text(encoding="utf-8")
    (RAIZ / "PROMPTS.md").write_text(texto, encoding="utf-8")
    print(f"{n_total - 1} prompts → PROMPTS.md")


if __name__ == "__main__":
    main()
