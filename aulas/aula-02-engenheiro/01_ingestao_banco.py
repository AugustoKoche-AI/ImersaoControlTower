# Databricks notebook source
# MAGIC %md
# MAGIC # Noite 2 · 1 de 3 · Do banco dos sistemas para a bronze
# MAGIC
# MAGIC Ontem você baixou 6 CSV e subiu na mão. Na Vértice de verdade, esses dados **moram num banco**: o
# MAGIC cadastro do PMO, o status de toda sexta, o RH, o timesheet, o financeiro e as compras. Ninguém
# MAGIC exporta CSV toda semana: o pipeline vai buscar.
# MAGIC
# MAGIC | Tabela no banco (Supabase) | Sistema | Vira |
# MAGIC |---|---|---|
# MAGIC | `vertice.projetos` | PMO | `bronze.projetos` |
# MAGIC | `vertice.status_semanal` | PMO | `bronze.status_semanal` |
# MAGIC | `vertice.colaboradores` | RH | `bronze.colaboradores` |
# MAGIC | `vertice.apontamentos` | timesheet | `bronze.apontamentos` |
# MAGIC | `vertice.custos` | financeiro | `bronze.custos` |
# MAGIC | `vertice.entregas_fornecedor` | compras | `bronze.entregas_fornecedor` |
# MAGIC
# MAGIC **A regra da bronze:** guardar o dado do jeito que chegou. Tudo como texto, sem limpar nada. A
# MAGIC sujeira (vírgula decimal, data em dois formatos) é evidência: a silver de amanhã resolve.
# MAGIC
# MAGIC Rode com a computação **serverless**, uma célula de cada vez.

# COMMAND ----------

# MAGIC %pip install psycopg2-binary --quiet

# COMMAND ----------

# A conexão com o banco. O usuário "aluno" só consegue LER: não dá para apagar nada.
# (Numa empresa, a senha ficaria num secret scope, nunca no notebook. Aqui ela é pública e só lê.)
HOST    = "COLE-AQUI.pooler.supabase.com"   # está no README da noite 2
PORTA   = 5432
BANCO   = "postgres"
USUARIO = "aluno.COLE-AQUI"                  # está no README da noite 2
SENHA   = "COLE-AQUI"                        # está no README da noite 2

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 0 · Apague o trabalho manual de ontem
# MAGIC
# MAGIC É proposital: no fim, as tabelas voltam, agora vindas do banco por código.

# COMMAND ----------

TABELAS = ["projetos", "status_semanal", "colaboradores", "apontamentos", "custos", "entregas_fornecedor"]

for tabela in TABELAS:
    spark.sql(f"DROP TABLE IF EXISTS lakehouse_vertice.bronze.{tabela}")
    print("apagada:", tabela)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 1 · Conecte e olhe o que tem lá

# COMMAND ----------

import psycopg2
import pandas as pd

conexao = psycopg2.connect(host=HOST, port=PORTA, dbname=BANCO, user=USUARIO,
                           password=SENHA, sslmode="require")

# o mesmo SQL que você já sabe, agora rodando no banco do sistema
pd.read_sql("SELECT * FROM vertice.projetos LIMIT 5", conexao)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 2 · Uma tabela inteira: do banco para a bronze
# MAGIC
# MAGIC `pandas` traz a tabela para a memória; o Spark grava no catálogo. Todas as colunas como texto
# MAGIC (`StringType`), igual ao `inferColumnTypes => false` de ontem.

# COMMAND ----------

from pyspark.sql.types import StructType, StructField, StringType

def banco_para_bronze(tabela):
    df = pd.read_sql(f"SELECT * FROM vertice.{tabela}", conexao)          # 1 · extrair
    df = df.astype(object).where(df.notna(), None)                          # vazio continua vazio (null)
    esquema = StructType([StructField(c, StringType()) for c in df.columns])
    (spark.createDataFrame(df, schema=esquema)                              # 2 · carregar
          .write.mode("overwrite").option("overwriteSchema", "true")
          .saveAsTable(f"lakehouse_vertice.bronze.{tabela}"))
    return len(df)

banco_para_bronze("projetos")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 3 · As outras cinco, com um `for`

# COMMAND ----------

for tabela in TABELAS:
    linhas = banco_para_bronze(tabela)
    print(f"{tabela:<22} {linhas:>7} linhas")

conexao.close()

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Deve aparecer o mesmo de ontem: apontamentos 30.883 · custos 23.640 · status_semanal 3.911
# MAGIC -- entregas_fornecedor 640 · colaboradores 523 · projetos 60
# MAGIC SELECT 'projetos' AS tabela, COUNT(*) AS linhas FROM lakehouse_vertice.bronze.projetos
# MAGIC UNION ALL SELECT 'status_semanal', COUNT(*) FROM lakehouse_vertice.bronze.status_semanal
# MAGIC UNION ALL SELECT 'colaboradores', COUNT(*) FROM lakehouse_vertice.bronze.colaboradores
# MAGIC UNION ALL SELECT 'apontamentos', COUNT(*) FROM lakehouse_vertice.bronze.apontamentos
# MAGIC UNION ALL SELECT 'custos', COUNT(*) FROM lakehouse_vertice.bronze.custos
# MAGIC UNION ALL SELECT 'entregas_fornecedor', COUNT(*) FROM lakehouse_vertice.bronze.entregas_fornecedor
# MAGIC ORDER BY linhas DESC
