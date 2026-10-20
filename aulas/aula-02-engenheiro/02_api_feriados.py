# Databricks notebook source
# MAGIC %md
# MAGIC # Noite 2 · 2 de 2 · Uma fonte de fora, por API
# MAGIC
# MAGIC Na empresa, o dado não chega pronto: alguém precisa ir buscar. Quando a fonte não tem conector,
# MAGIC entra o Python. O caminho é o mesmo da noite 1, em três passos:
# MAGIC
# MAGIC 1. **extrair** · o Python pede os feriados de 2026 a uma API pública (a BrasilAPI, sem chave)
# MAGIC 2. **pousar** · o JSON vai para o volume, do jeito que veio: `/Volumes/lakehouse_vertice/bronze/raw/feriados/`
# MAGIC 3. **carregar** · o `read_files` transforma o arquivo em tabela: `lakehouse_vertice.bronze.feriados`
# MAGIC
# MAGIC **Pergunta de negócio:** quantos dias úteis a Vértice perde em novembro, bem quando começa o
# MAGIC change freeze da Black Friday (01/11)?
# MAGIC
# MAGIC Rode com a computação **serverless** (ela tem internet), uma célula de cada vez.

# COMMAND ----------

# 1 · EXTRAIR: o Python pede o dado à API
import requests                # conversa com a API (HTTP)

url = "https://brasilapi.com.br/api/feriados/v1/2026"
resposta = requests.get(url, timeout=30)
resposta.raise_for_status()    # se a API cair, para aqui com o erro, em vez de seguir com nada

feriados = resposta.json()     # o JSON vira uma lista do Python: um dicionário por feriado
print(len(feriados), "feriados")
feriados[:3]

# COMMAND ----------

# 2 · POUSAR: o arquivo vai para o volume, do jeito que veio
import json, os               # json e os já vêm no Python

pasta = "/Volumes/lakehouse_vertice/bronze/raw/feriados"
os.makedirs(pasta, exist_ok=True)              # a pasta nova precisa existir

with open(f"{pasta}/feriados_2026.json", "w") as arquivo:
    json.dump(feriados, arquivo, ensure_ascii=False)

os.listdir(pasta)                              # deve aparecer: ['feriados_2026.json']

# COMMAND ----------

# MAGIC %sql
# MAGIC -- 3 · CARREGAR: o mesmo read_files da noite 1, agora numa pasta nova do volume
# MAGIC CREATE OR REPLACE TABLE lakehouse_vertice.bronze.feriados
# MAGIC COMMENT 'Feriados nacionais de 2026, da BrasilAPI. Ingestão por API: Python busca, o arquivo pousa no volume, o read_files carrega.'
# MAGIC AS SELECT date AS data, name AS feriado, type AS tipo, weekday AS dia_da_semana,
# MAGIC           _metadata.file_name AS arquivo
# MAGIC FROM read_files('/Volumes/lakehouse_vertice/bronze/raw/feriados/', format => 'json', multiLine => true)

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Deve aparecer: 02/11 (segunda), 15/11 (domingo) e 20/11 (sexta).
# MAGIC -- 2 dias úteis a menos em novembro, logo no começo do freeze da Black Friday.
# MAGIC SELECT data, feriado, dia_da_semana
# MAGIC FROM lakehouse_vertice.bronze.feriados
# MAGIC WHERE data BETWEEN '2026-11-01' AND '2026-11-30'
# MAGIC ORDER BY data
