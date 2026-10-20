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
A2, A3, A4 = "aulas/aula-03-modelagem-claude-code/claude-code/prd", "aulas/aula-03-modelagem-claude-code/prd", "aulas/aula-04-produtos-de-dados-ia/prd"

# (noite, título, subtítulo, caminho, deploy) — o número do prompt é a posição na lista
PROMPTS = [
    (2, "O bundle", "o projeto nasce como código", f"{A2}/prompt-01-bundle.md", "bundle deploy + run"),
    (2, "Silver", "as três ferramentas viram uma", f"{A2}/prompt-02-silver.md", "bundle deploy + run do pipeline"),
    (2, "Gold", "o produto de dados e as perguntas do dono", f"{A2}/prompt-03-gold.md", "bundle deploy + run"),
    (2, "Texto com IA", "o status semanal vira coluna", f"{A2}/prompt-04-texto-com-ia.md", "bundle deploy + run"),
    (2, "Métricas governadas", "o KPI definido uma vez só", f"{A2}/prompt-05-metricas.md", "bundle deploy + run"),
    (3, "Features", "o que descreve um projeto que vai estourar", f"{A3}/prompt-01-features.md", "bundle deploy"),
    (3, "Modelo e MLflow", "o baseline primeiro", f"{A3}/prompt-02-modelo.md", "bundle deploy"),
    (3, "Score em lote", "a probabilidade de estouro em 30 dias", f"{A3}/prompt-03-score.md", "bundle deploy"),
    (3, "Dashboard e Genie", "o dono pergunta em português", f"{A3}/prompt-04-dashboard-e-genie.md", "bundle deploy"),
    (4, "O agente que lê contrato", "o PDF que ninguém lê vira resposta", f"{A4}/prompt-01-agente-de-contratos.md", "Genie publicado"),
    (4, "O app da Torre", "a Torre na tela do dono", f"{A4}/prompt-02-app.md", "apps deploy"),
    (4, "A aprovação no Lakebase", "a decisão fica registrada", f"{A4}/prompt-03-aprovacao-lakebase.md", "apps deploy"),
]

TITULOS = {2: "Noite 2 · o pipeline nasce", 3: "Noite 3 · o pipeline passa a prever",
           4: "Noite 4 · o projeto ganha uma URL"}
INTERVALO = {2: "prompts-meio-23.md", 3: "prompts-meio-34.md"}   # o rodapé entra sempre, no fim


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
    n_total = 0
    for noite in (2, 3, 4):
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
    print(f"{n_total} prompts → PROMPTS.md")


if __name__ == "__main__":
    main()
