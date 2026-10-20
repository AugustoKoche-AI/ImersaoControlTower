#!/usr/bin/env python3
"""Transforma os exemplo-NN-*.sql de uma aula em notebooks do Databricks.

Uso:
  python3 scripts/gerar_notebooks.py aulas/aula-01-analista-sql
  python3 scripts/gerar_notebooks.py aulas/aula-01-analista-sql --importar --profile SEU-PERFIL

Gera duas versões em <aula>/notebooks/:
  resolvidos/   cada bloco do exemplo vira uma célula, com a query
  em-branco/    mesma estrutura, com a query trocada por "-- escreva aqui"
                (é a versão para escrever ao vivo durante a aula)

Os .sql continuam sendo a fonte: edite o exemplo e rode este script de novo.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import subprocess

CABECALHO = "-- Databricks notebook source\n"
SEPARADOR = "\n\n-- COMMAND ----------\n\n"


def blocos(sql: str) -> list[tuple[str, str]]:
    """Divide em (comentário, query): cada query com o comentário que vem logo antes dela."""
    saida, coment, query = [], [], []
    for linha in sql.splitlines():
        if linha.strip().startswith("--") and not query:
            coment.append(linha)
        elif linha.strip() == "" and not query:
            coment.append(linha)
        else:
            query.append(linha)
            if linha.rstrip().endswith(";"):
                saida.append(("\n".join(coment).strip("\n"), "\n".join(query).strip()))
                coment, query = [], []
    if coment or query:
        saida.append(("\n".join(coment).strip("\n"), "\n".join(query).strip()))
    return saida


def para_md(coment: str) -> str:
    linhas = [re.sub(r"^--\s?", "", l) for l in coment.splitlines() if not re.match(r"^--\s*=+\s*$", l)]
    texto = "\n".join(linhas).strip()
    return "-- MAGIC %md\n" + "\n".join(f"-- MAGIC {l}" if l else "-- MAGIC" for l in texto.splitlines())


def notebook(sql: str, em_branco: bool) -> str:
    celulas = []
    for coment, query in blocos(sql):
        if coment.strip():
            celulas.append(para_md(coment))
        if query:
            celulas.append("-- escreva aqui a sua query\n" if em_branco else query)
    return CABECALHO + SEPARADOR.join(celulas) + "\n"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("aula")
    ap.add_argument("--importar", action="store_true")
    ap.add_argument("--profile")
    a = ap.parse_args()
    aula = pathlib.Path(a.aula)
    gerados = []
    for f in sorted(aula.glob("exemplo-*.sql")):
        sql = f.read_text(encoding="utf-8")
        for pasta, branco in (("resolvidos", False), ("em-branco", True)):
            destino = aula / "notebooks" / pasta / f.name
            destino.parent.mkdir(parents=True, exist_ok=True)
            destino.write_text(notebook(sql, branco), encoding="utf-8")
            gerados.append(destino)
    print(f"ok: {len(gerados)} notebooks em {aula / 'notebooks'}")
    if not a.importar:
        return
    eu = json.loads(subprocess.run(["databricks", "current-user", "me", "--profile", a.profile, "-o", "json"],
                                   capture_output=True, text=True, check=True).stdout)["userName"]
    for nb in gerados:
        dest = f"/Workspace/Users/{eu}/imersao-torre/{aula.name}/{nb.parent.name}"
        subprocess.run(["databricks", "workspace", "mkdirs", dest, "--profile", a.profile], check=True)
        subprocess.run(["databricks", "workspace", "import", f"{dest}/{nb.stem}", "--file", str(nb),
                        "--language", "SQL", "--format", "SOURCE", "--overwrite", "--profile", a.profile],
                       check=True, capture_output=True)
    print(f"importados em /Workspace/Users/{eu}/imersao-torre/{aula.name}/")


if __name__ == "__main__":
    main()
