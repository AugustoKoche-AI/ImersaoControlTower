#!/usr/bin/env python3
"""Monta a "empresa" da noite 2 no Supabase: o banco dos sistemas e o storage dos arquivos.

Rode UMA vez, do seu computador, depois de criar o projeto no painel do Supabase:

    pip install psycopg2-binary requests
    export SUPABASE_DB_URL="postgresql://postgres.<ref>:<senha>@aws-0-<regiao>.pooler.supabase.com:5432/postgres"
    export SUPABASE_URL="https://<ref>.supabase.co"
    export SUPABASE_SERVICE_KEY="<service_role key>"      # Project Settings > API (secret)
    export ALUNO_SENHA="<senha que vai no README, só leitura>"
    python3 material/carregar_supabase.py --dados ./dados

O que ele cria:
  banco   schema vertice, 6 tabelas com TODAS as colunas como texto, do jeito que estão no CSV.
          A sujeira (vírgula decimal, data em dois formatos, status vazio) é conteúdo: a silver
          da noite 3 conta com ela. Nada de tipar aqui.
          usuário "aluno", que só lê o schema vertice.
  storage bucket público "vertice" com excel/, clickup/, msproject/ e um manifesto.json listando
          os arquivos (o aluno baixa pela URL pública, sem chave).
"""
import argparse
import csv
import json
import os
import sys
from pathlib import Path
from urllib.parse import quote

import psycopg2
import requests

# tabela do banco ← arquivo CSV do gerador (o mesmo que a noite 1 subiu na mão)
TABELAS = {
    "projetos": "pmo/projetos.csv",
    "status_semanal": "pmo/status_semanal.csv",
    "colaboradores": "rh/colaboradores.csv",
    "apontamentos": "timesheet/apontamentos.csv",
    "custos": "financeiro/custos.csv",
    "entregas_fornecedor": "compras/entregas_fornecedor.csv",
}
PASTAS_DE_ARQUIVO = ["excel", "clickup", "msproject"]
BUCKET = "vertice"


def carregar_banco(db_url: str, dados: Path, senha_aluno: str) -> None:
    con = psycopg2.connect(db_url)
    con.autocommit = True
    cur = con.cursor()
    cur.execute("CREATE SCHEMA IF NOT EXISTS vertice")
    for tabela, arquivo in TABELAS.items():
        caminho = dados / arquivo
        with open(caminho, encoding="utf-8", newline="") as f:
            colunas = next(csv.reader(f))
        definicao = ", ".join(f'"{c}" text' for c in colunas)
        cur.execute(f"DROP TABLE IF EXISTS vertice.{tabela}")
        cur.execute(f"CREATE TABLE vertice.{tabela} ({definicao})")
        with open(caminho, encoding="utf-8", newline="") as f:
            cur.copy_expert(f"COPY vertice.{tabela} FROM STDIN WITH (FORMAT csv, HEADER true)", f)
        cur.execute(f"SELECT COUNT(*) FROM vertice.{tabela}")
        print(f"  banco   vertice.{tabela:<20} {cur.fetchone()[0]:>7} linhas")

    # o aluno só lê: nada de INSERT, UPDATE, DELETE ou DROP
    cur.execute("SELECT 1 FROM pg_roles WHERE rolname = 'aluno'")
    if cur.fetchone():
        cur.execute("ALTER ROLE aluno WITH LOGIN PASSWORD %s", (senha_aluno,))
    else:
        cur.execute("CREATE ROLE aluno WITH LOGIN PASSWORD %s", (senha_aluno,))
    cur.execute("GRANT USAGE ON SCHEMA vertice TO aluno")
    cur.execute("GRANT SELECT ON ALL TABLES IN SCHEMA vertice TO aluno")
    print("  banco   usuário aluno: só SELECT no schema vertice")
    con.close()


def carregar_storage(url: str, chave: str, dados: Path) -> None:
    h = {"Authorization": f"Bearer {chave}", "apikey": chave}
    r = requests.post(f"{url}/storage/v1/bucket", headers=h, timeout=30,
                      json={"id": BUCKET, "name": BUCKET, "public": True})
    if r.status_code not in (200, 201) and "already exists" not in r.text.lower():
        sys.exit(f"bucket: {r.status_code} {r.text}")
    manifesto = {}
    tipos = {".xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
             ".json": "application/json", ".xml": "application/xml"}
    for pasta in PASTAS_DE_ARQUIVO:
        arquivos = sorted(p for p in (dados / pasta).iterdir() if p.is_file())
        for p in arquivos:
            destino = f"{url}/storage/v1/object/{BUCKET}/{pasta}/{quote(p.name)}"
            r = requests.post(destino, data=p.read_bytes(), timeout=60,
                              headers={**h, "x-upsert": "true", "Content-Type": tipos.get(p.suffix, "application/octet-stream")})
            if r.status_code not in (200, 201):
                sys.exit(f"upload {pasta}/{p.name}: {r.status_code} {r.text}")
        manifesto[pasta] = [p.name for p in arquivos]
        print(f"  storage {BUCKET}/{pasta:<10} {len(arquivos):>3} arquivos")
    r = requests.post(f"{url}/storage/v1/object/{BUCKET}/manifesto.json", timeout=30,
                      data=json.dumps(manifesto, ensure_ascii=False, indent=2).encode(),
                      headers={**h, "x-upsert": "true", "Content-Type": "application/json"})
    if r.status_code not in (200, 201):
        sys.exit(f"manifesto: {r.status_code} {r.text}")
    print(f"  storage manifesto: {url}/storage/v1/object/public/{BUCKET}/manifesto.json")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--dados", default="./dados")
    p.add_argument("--so-banco", action="store_true")
    p.add_argument("--so-storage", action="store_true")
    a = p.parse_args()
    dados = Path(a.dados)
    if not a.so_storage:
        carregar_banco(os.environ["SUPABASE_DB_URL"], dados, os.environ["ALUNO_SENHA"])
    if not a.so_banco:
        carregar_storage(os.environ["SUPABASE_URL"].rstrip("/"), os.environ["SUPABASE_SERVICE_KEY"], dados)
    print("pronto.")


if __name__ == "__main__":
    main()
