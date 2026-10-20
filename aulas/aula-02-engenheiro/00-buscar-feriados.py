#!/usr/bin/env python3
"""Noite 2 · abertura · ingestão por API, o gabarito do "prompt 0".

Os três passos de toda ingestão, os mesmos da noite 1:
  1. extrair  · o Python busca os feriados de 2026 na BrasilAPI (pública, sem chave)
  2. pousar   · o JSON vai, do jeito que veio, para o volume: /Volumes/lakehouse_vertice/bronze/raw/feriados/
  3. carregar · o read_files transforma o arquivo em tabela: lakehouse_vertice.bronze.feriados

Travou no prompt? Baixe este arquivo para o seu repositório e rode (só precisa do Python e da CLI):
    curl -fsSLO https://raw.githubusercontent.com/lvgalvao/ImersaoControlTower/main/aulas/aula-02-engenheiro/00-buscar-feriados.py
    python3 00-buscar-feriados.py --profile <perfil>

Deve aparecer: 14 feriados em 2026. Em novembro, 2 caem em dia útil: 02/11 e 20/11 (o 15/11 é domingo).
"""
import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

URL = "https://brasilapi.com.br/api/feriados/v1/2026"
PASTA_NO_VOLUME = "/Volumes/lakehouse_vertice/bronze/raw/feriados"

# O SQL do passo 3. É o mesmo read_files da noite 1, agora numa pasta nova do volume.
CARREGAR = f"""
CREATE OR REPLACE TABLE lakehouse_vertice.bronze.feriados
COMMENT 'Feriados nacionais de 2026, da BrasilAPI. Ingestão por API: Python busca, o arquivo pousa no volume, o read_files carrega.'
AS SELECT date AS data, name AS feriado, type AS tipo, weekday AS dia_da_semana,
          _metadata.file_name AS arquivo
FROM read_files('{PASTA_NO_VOLUME}/', format => 'json', multiLine => true)
"""

CONFERIR = """
SELECT data, feriado, dia_da_semana
FROM lakehouse_vertice.bronze.feriados
WHERE data BETWEEN '2026-11-01' AND '2026-11-30'
ORDER BY data
"""


def buscar() -> list:
    """Passo 1: extrair. Usa o requests se estiver instalado; senão, o urllib, que já vem no Python."""
    try:
        import requests
        resposta = requests.get(URL, timeout=30)
        resposta.raise_for_status()          # se a API cair, para aqui, em vez de gravar arquivo vazio
        return resposta.json()
    except ImportError:
        from urllib.request import urlopen
        with urlopen(URL, timeout=30) as resposta:
            return json.load(resposta)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--profile", required=True, help="o profile do seu login no Databricks")
    profile = p.parse_args().profile

    feriados = buscar()
    print(f"1 · extrair: {len(feriados)} feriados de {URL}")

    with tempfile.TemporaryDirectory() as pasta:
        arquivo = Path(pasta) / "feriados_2026.json"
        arquivo.write_text(json.dumps(feriados, ensure_ascii=False, indent=2), encoding="utf-8")
        destino = f"dbfs:{PASTA_NO_VOLUME}/feriados_2026.json"
        # a pasta nova precisa existir antes da cópia (senão: "no such directory")
        subprocess.run(["databricks", "fs", "mkdir", f"dbfs:{PASTA_NO_VOLUME}", "--profile", profile], check=True)
        subprocess.run(["databricks", "fs", "cp", str(arquivo), destino, "--overwrite", "--profile", profile], check=True)
        print(f"2 · pousar: {destino}")

    print("3 · carregar: bronze.feriados com read_files")
    for sql in (CARREGAR, CONFERIR):     # a própria CLI roda o SQL no warehouse
        subprocess.run(["databricks", "experimental", "aitools", "tools", "query", sql.strip(),
                        "--profile", profile], check=True)


if __name__ == "__main__":
    main()
