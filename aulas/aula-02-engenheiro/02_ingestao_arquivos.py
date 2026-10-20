# Databricks notebook source
# MAGIC %md
# MAGIC # Noite 2 · 2 de 3 · Do storage (data lake) para a bronze
# MAGIC
# MAGIC Nem tudo mora num banco. Cada gerente controla o projeto numa ferramenta, e o que chega é **arquivo**:
# MAGIC 20 planilhas Excel, 25 exports do ClickUp (JSON) e 15 cronogramas do MS Project (XML). Eles ficam
# MAGIC num **storage**, o data lake da empresa (aqui, o Storage do Supabase).
# MAGIC
# MAGIC Os três passos de toda ingestão:
# MAGIC 1. **extrair** · baixar cada arquivo do storage
# MAGIC 2. **pousar** · gravar no volume, do jeito que veio (`/Volumes/lakehouse_vertice/bronze/raw/`)
# MAGIC 3. **carregar** · o mesmo `read_files` de ontem transforma os arquivos em tabela
# MAGIC
# MAGIC Rode com a computação **serverless**, uma célula de cada vez.

# COMMAND ----------

# O endereço público do storage. Público para LER: ninguém consegue apagar nem trocar arquivo.
STORAGE = "https://COLE-AQUI.supabase.co/storage/v1/object/public/vertice"   # está no README da noite 2
VOLUME  = "/Volumes/lakehouse_vertice/bronze/raw"

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 0 · Apague o trabalho manual de ontem

# COMMAND ----------

for tabela in ["excel_tarefas", "clickup_tarefas", "msproject_tarefas"]:
    spark.sql(f"DROP TABLE IF EXISTS lakehouse_vertice.bronze.{tabela}")
    print("apagada:", tabela)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 1 · O que tem no storage?
# MAGIC
# MAGIC O `manifesto.json` é a lista de arquivos de cada pasta. É um JSON, como a API dos feriados.

# COMMAND ----------

import requests

manifesto = requests.get(f"{STORAGE}/manifesto.json", timeout=30).json()

for pasta, arquivos in manifesto.items():
    print(f"{pasta:<10} {len(arquivos):>3} arquivos · ex.: {arquivos[0]}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 2 · Baixe e pouse no volume, arquivo por arquivo

# COMMAND ----------

import os
from urllib.parse import quote

def baixar_pasta(pasta, arquivos):
    os.makedirs(f"{VOLUME}/{pasta}", exist_ok=True)
    for nome in arquivos:
        resposta = requests.get(f"{STORAGE}/{pasta}/{quote(nome)}", timeout=60)   # 1 · extrair
        resposta.raise_for_status()
        with open(f"{VOLUME}/{pasta}/{nome}", "wb") as arquivo:                  # 2 · pousar
            arquivo.write(resposta.content)
    return len(arquivos)

for pasta, arquivos in manifesto.items():
    print(f"{pasta:<10} {baixar_pasta(pasta, arquivos):>3} arquivos no volume")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 3 · Carregue: o mesmo `read_files` de ontem

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE OR REPLACE TABLE lakehouse_vertice.bronze.excel_tarefas AS
# MAGIC SELECT `ID`               AS id,
# MAGIC        `Fase`             AS fase,
# MAGIC        `Tarefa`           AS tarefa,
# MAGIC        `Responsável`      AS responsavel,
# MAGIC        `Início previsto`  AS inicio_previsto,
# MAGIC        `Término previsto` AS termino_previsto,
# MAGIC        `Início real`      AS inicio_real,
# MAGIC        `Término real`     AS termino_real,
# MAGIC        `% Concluído`      AS pct_concluido,
# MAGIC        `Horas previstas`  AS horas_previstas,
# MAGIC        url_decode(_metadata.file_name) AS arquivo
# MAGIC FROM read_files('/Volumes/lakehouse_vertice/bronze/raw/excel/',
# MAGIC                 format => 'excel', headerRows => 1, inferColumnTypes => false)

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE OR REPLACE TABLE lakehouse_vertice.bronze.clickup_tarefas AS
# MAGIC SELECT list.id   AS list_id,
# MAGIC        list.name AS list_name,
# MAGIC        t.*,
# MAGIC        url_decode(_metadata.file_name) AS arquivo
# MAGIC FROM (
# MAGIC     SELECT list, explode(tasks) AS t, _metadata
# MAGIC     FROM read_files('/Volumes/lakehouse_vertice/bronze/raw/clickup/',
# MAGIC                     format => 'json', multiLine => true)
# MAGIC )

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE OR REPLACE TABLE lakehouse_vertice.bronze.msproject_tarefas AS
# MAGIC SELECT * EXCEPT (_rescued_data),
# MAGIC        url_decode(_metadata.file_name) AS arquivo
# MAGIC FROM read_files('/Volumes/lakehouse_vertice/bronze/raw/msproject/',
# MAGIC                 format => 'xml', rowTag => 'Task')

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Deve aparecer o mesmo de ontem: clickup_tarefas 2.119 · excel_tarefas 1.663 · msproject_tarefas 1.260
# MAGIC SELECT 'excel_tarefas' AS tabela, COUNT(*) AS linhas FROM lakehouse_vertice.bronze.excel_tarefas
# MAGIC UNION ALL SELECT 'clickup_tarefas', COUNT(*) FROM lakehouse_vertice.bronze.clickup_tarefas
# MAGIC UNION ALL SELECT 'msproject_tarefas', COUNT(*) FROM lakehouse_vertice.bronze.msproject_tarefas
# MAGIC ORDER BY linhas DESC
