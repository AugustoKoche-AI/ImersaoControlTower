# Databricks notebook source
# MAGIC %md
# MAGIC # Noite 3 · Prompt 3 · O score: a lista que a diretoria abre na segunda-feira
# MAGIC
# MAGIC Pontua **hoje (16/10/2026)** todas as obras em andamento com o modelo `@prod` e grava
# MAGIC `gold.score_estouro_30d`, com a probabilidade, o ranking, a faixa e os **motivos em português**.
# MAGIC
# MAGIC Não há endpoint de modelo no Free Edition: o modelo roda **em lote**, dentro do job, e o resultado vira
# MAGIC tabela. Para a diretoria isso não muda nada: o número está lá toda manhã, no dashboard, no Genie e no app.
# MAGIC
# MAGIC Esta tabela é um **contrato** com a noite 4 (o app lê dela). Nome e colunas não mudam.

# COMMAND ----------

# MAGIC %md
# MAGIC **Primeiro, o MLflow novo.** O serverless vem com MLflow 2.11, que sobe o modelo para o Unity Catalog
# MAGIC com credencial direta no S3 — e o Free Edition **nega** (`s3:PutObject ... explicit deny`). A partir da
# MAGIC 2.21 o upload usa URL pré-assinada, que funciona. Medido em 18/10/2026.

# COMMAND ----------

# MAGIC %pip install -q -U "mlflow-skinny[databricks]>=2.21,<3"

# COMMAND ----------

dbutils.library.restartPython()

# COMMAND ----------

dbutils.widgets.text("catalog", "lakehouse_atlas")
catalog = dbutils.widgets.get("catalog")

MODELO = f"{catalog}.gold.modelo_estouro_30d"
HOJE = "2026-10-16"
CORTE = 0.9

import math
import mlflow
import numpy as np
import pandas as pd

FEATURES = [
    "spi", "cpi", "indice_min", "d_indice_min_4s", "pct_fisico", "pct_prazo",
    "d_spi_4s", "d_cpi_4s", "d_cpi_8s", "semanas_cpi_caindo", "cpi_ultimas_4s", "spi_ultimas_4s",
    "ociosidade_4s", "rupturas_previstas", "pct_subcontrato_4s", "pct_mao_de_obra_4s",
    "rdo_chuva_4s", "rdo_falta_material_4s", "rdo_falta_equipamento_4s", "rdo_mao_de_obra_4s",
    "rdo_com_ocorrencia_4s",
]

mlflow.set_registry_uri("databricks-uc")
# sklearn.load_model + pandas: spark_udf não roda no serverless (InvalidVersion)
modelo = mlflow.sklearn.load_model(f"models:/{MODELO}@prod")
sigma = float(spark.table(f"{catalog}.gold.modelo_metricas").first()["sigma"])

hoje = spark.sql(f"""
    SELECT f.*, p.nome_projeto
    FROM {catalog}.gold.features_obra_semana f
    JOIN {catalog}.silver.projetos p USING (projeto_id)
    WHERE f.semana = DATE'{HOJE}' AND p.status = 'em_andamento'
""").toPandas()
hoje[FEATURES] = hoje[FEATURES].astype(float)
print(f"{len(hoje)} obras em andamento para pontuar · sigma do modelo {sigma:.4f}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## A probabilidade
# MAGIC
# MAGIC O modelo prevê o pior índice das próximas 4 semanas. A probabilidade é a chance de ele ficar abaixo de
# MAGIC 0,9, com o erro medido no teste. Quem **já está** abaixo de 0,9 recebe 1,0: para essas a regra de corte
# MAGIC já acendeu, e o modelo não tem nada a acrescentar sobre "se" — só sobre "por quê".

# COMMAND ----------

hoje["pior_previsto"] = hoje["indice_min"] + modelo.predict(hoje[FEATURES])
z = (CORTE - hoje["pior_previsto"]) / sigma
hoje["prob_estouro_30d"] = 0.5 * (1 + z.apply(lambda v: math.erf(v / math.sqrt(2))))
ja_abaixo = hoje["indice_min"] < CORTE
hoje.loc[ja_abaixo, "prob_estouro_30d"] = 1.0
hoje["prob_estouro_30d"] = hoje["prob_estouro_30d"].clip(0, 1).round(4)

hoje = hoje.sort_values(["prob_estouro_30d", "indice_min"], ascending=[False, True]).reset_index(drop=True)
hoje["ranking"] = np.arange(1, len(hoje) + 1)
hoje["faixa_risco"] = np.select([hoje["prob_estouro_30d"] >= 0.5, hoje["prob_estouro_30d"] >= 0.2],
                                ["alto", "medio"], "baixo")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Os motivos, em português
# MAGIC
# MAGIC Probabilidade sem motivo não gera ação. Cada obra ganha os 2 ou 3 sinais mais fortes, escritos como o
# MAGIC gerente falaria. São regras sobre as mesmas features que o modelo usa, ordenadas pela gravidade.

# COMMAND ----------

def br(x, casas=2):
    return f"{x:.{casas}f}".replace(".", ",")

def motivos(r):
    sinais = []   # (gravidade, texto)
    if r["indice_min"] < CORTE:
        qual = "SPI" if r["spi"] <= r["cpi"] else "CPI"
        sinais.append((100, f"já abaixo do corte: {qual} {br(min(r['spi'], r['cpi']))}"))
    else:
        folga = r["indice_min"] - CORTE
        if folga < 0.05:
            sinais.append((6 - 60 * folga, f"a {br(folga)} do corte de 0,9 (índice {br(r['indice_min'])})"))
    if not pd.isna(r["d_cpi_4s"]) and r["d_cpi_4s"] < -0.004:
        sinais.append((5 + 300 * -r["d_cpi_4s"],
                       f"CPI caindo há {int(r['semanas_cpi_caindo'])} de 4 semanas ({br(r['d_cpi_4s'], 3)})"))
    if not pd.isna(r["cpi_ultimas_4s"]) and r["cpi_ultimas_4s"] < 0.85:
        sinais.append((4 + 10 * (0.85 - r["cpi_ultimas_4s"]),
                       f"cada R$ 1 gasto no último mês entregou R$ {br(r['cpi_ultimas_4s'])}"))
    if not pd.isna(r["spi_ultimas_4s"]) and r["spi_ultimas_4s"] < 0.85:
        sinais.append((4 + 10 * (0.85 - r["spi_ultimas_4s"]),
                       f"ritmo do último mês em {br(100 * r['spi_ultimas_4s'], 0)}% do planejado"))
    if not pd.isna(r["rdo_falta_equipamento_4s"]) and r["rdo_falta_equipamento_4s"] >= 0.1:
        sinais.append((5, f"falta de equipamento em {br(100 * r['rdo_falta_equipamento_4s'], 0)}% dos RDOs"))
    if not pd.isna(r["rdo_chuva_4s"]) and r["rdo_chuva_4s"] >= 0.2:
        sinais.append((4, f"chuva em {br(100 * r['rdo_chuva_4s'], 0)}% dos RDOs"))
    if not pd.isna(r["rdo_falta_material_4s"]) and r["rdo_falta_material_4s"] >= 0.4:
        sinais.append((3, f"falta de material em {br(100 * r['rdo_falta_material_4s'], 0)}% dos RDOs"))
    if not pd.isna(r["rdo_mao_de_obra_4s"]) and r["rdo_mao_de_obra_4s"] >= 0.15:
        sinais.append((3, f"problema de mão de obra em {br(100 * r['rdo_mao_de_obra_4s'], 0)}% dos RDOs"))
    if not pd.isna(r["ociosidade_4s"]) and r["ociosidade_4s"] >= 0.15:
        sinais.append((3, f"{br(100 * r['ociosidade_4s'], 0)}% das horas da equipe paradas"))
    if r["rupturas_previstas"] >= 3:
        sinais.append((2, f"{int(r['rupturas_previstas'])} materiais com ruptura prevista"))
    if not sinais:
        return "sem sinal de piora: índices estáveis e acima do corte"
    sinais.sort(key=lambda s: -s[0])
    return "; ".join(t for _, t in sinais[:3])

hoje["principais_fatores"] = hoje.apply(motivos, axis=1)

# COMMAND ----------

saida = hoje[["projeto_id", "prob_estouro_30d", "ranking", "faixa_risco", "principais_fatores"]].copy()
saida.insert(1, "data_referencia", pd.to_datetime(HOJE).date())
saida["ranking"] = saida["ranking"].astype("int32")

(spark.createDataFrame(saida)
 .selectExpr("CAST(projeto_id AS STRING) AS projeto_id", "CAST(data_referencia AS DATE) AS data_referencia",
             "CAST(prob_estouro_30d AS DOUBLE) AS prob_estouro_30d", "CAST(ranking AS INT) AS ranking",
             "CAST(faixa_risco AS STRING) AS faixa_risco", "CAST(principais_fatores AS STRING) AS principais_fatores")
 .write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(f"{catalog}.gold.score_estouro_30d"))

spark.sql(f"""COMMENT ON TABLE {catalog}.gold.score_estouro_30d IS
  'Noite 3: probabilidade de cada obra em andamento ter SPI ou CPI abaixo de 0,9 nas próximas 4 semanas (data_referencia = 2026-10-16), com ranking, faixa (alto >= 0,5; medio >= 0,2; baixo) e os principais fatores em português. Obra já abaixo de 0,9 = 1,0. Lida pelo app da noite 4.'""")
for col, txt in {
    "prob_estouro_30d": "Probabilidade de 0 a 1 de o SPI ou o CPI ficar abaixo de 0,9 em até 30 dias. 1,0 = já está abaixo.",
    "ranking": "1 = obra mais arriscada da carteira hoje",
    "faixa_risco": "alto (>= 0,5), medio (>= 0,2) ou baixo",
    "principais_fatores": "Os 2 ou 3 sinais mais fortes, em português, para o gerente agir",
}.items():
    spark.sql(f"ALTER TABLE {catalog}.gold.score_estouro_30d ALTER COLUMN {col} COMMENT '{txt}'")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Os testes do score
# MAGIC Uma linha por obra em andamento, probabilidade entre 0 e 1, e toda obra que já está abaixo do corte no topo.

# COMMAND ----------

t = spark.sql(f"""
  SELECT COUNT(*) AS linhas,
         (SELECT COUNT(*) FROM {catalog}.silver.projetos WHERE status = 'em_andamento') AS em_andamento,
         COUNT_IF(prob_estouro_30d < 0 OR prob_estouro_30d > 1 OR prob_estouro_30d IS NULL) AS fora_da_faixa,
         COUNT(DISTINCT ranking) AS rankings,
         COUNT_IF(principais_fatores IS NULL OR principais_fatores = '') AS sem_motivo
  FROM {catalog}.gold.score_estouro_30d
""").first()
assert t["linhas"] == t["em_andamento"], f"{t['linhas']} linhas para {t['em_andamento']} obras em andamento"
assert t["fora_da_faixa"] == 0 and t["sem_motivo"] == 0 and t["rankings"] == t["linhas"], t
print("score ok:", t.asDict())
display(spark.table(f"{catalog}.gold.score_estouro_30d").orderBy("ranking"))
