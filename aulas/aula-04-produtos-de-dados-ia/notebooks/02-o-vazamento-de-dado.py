# Databricks notebook source
# MAGIC %md
# MAGIC # Noite 4 · O vazamento de dado (demonstração)
# MAGIC
# MAGIC O erro mais caro de ML não dá erro: dá um AUC lindo. Este notebook treina o **mesmo** modelo três vezes:
# MAGIC
# MAGIC | | Como divide | O que acontece |
# MAGIC |---|---|---|
# MAGIC | A | no tempo (treina até março, testa de abril em diante) | o número honesto |
# MAGIC | B | aleatório, linha a linha | a semana 20 do projeto treina, a 21 testa: o modelo "cola" |
# MAGIC | C | no tempo, mas com uma feature do futuro (o índice daqui a 4 semanas) | AUC 0,99, e o teste do prompt 2 barra |
# MAGIC
# MAGIC Só leitura: não grava nada, não registra modelo.

# COMMAND ----------

import json
import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingRegressor
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import train_test_split

FEATURES = [
    "spi", "cpi", "indice_min", "d_indice_min_4s", "pct_fisico", "pct_prazo",
    "d_spi_4s", "d_cpi_4s", "d_spi_8s", "d_cpi_8s", "semanas_cpi_caindo", "cpi_ultimas_4s", "spi_ultimas_4s",
    "ociosidade_4s", "pct_consultoria_4s", "pct_cloud_4s", "saidas_12s",
    "status_freeze_4s", "status_falta_sre_4s", "status_fornecedor_4s", "status_rotatividade_4s",
    "status_escopo_4s", "status_retrabalho_4s", "status_com_bloqueio_4s",
]
d = spark.table("lakehouse_vertice.ml.features_projeto_semana").toPandas().sort_values(["projeto_id", "semana"])
d["semana"] = pd.to_datetime(d["semana"])
d[FEATURES] = d[FEATURES].astype(float)
# a feature proibida: o pior índice (menor entre SPI e CPI) de 4 semanas DEPOIS da linha.
# Num sistema real ela entra sem ninguém perceber: é o "% concluído revisado" que o gerente corrige
# um mês depois e que alguém grava em cima da linha da semana original.
d["indice_daqui_a_4_semanas"] = d.groupby("projeto_id")["indice_min"].shift(-4).astype(float)
r = d[d["alvo_pior_indice_30d"].notna() & (d["pct_prazo"] > 0.15)].copy()

def treinar_e_medir(treino, teste, feats):
    m = HistGradientBoostingRegressor(random_state=42, max_depth=3, learning_rate=0.05,
                                      max_iter=300, min_samples_leaf=20)
    m.fit(treino[feats], treino["alvo_pior_indice_30d"] - treino["indice_min"])
    teste = teste[teste["elegivel"] == 1]
    return roc_auc_score(teste["estoura_30d"], -(teste["indice_min"] + m.predict(teste[feats])))

no_tempo_treino = r[r["semana"] <= "2026-03-06"]
no_tempo_teste = r[r["semana"] >= "2026-04-03"]
aleatorio_treino, aleatorio_teste = train_test_split(r, test_size=0.3, random_state=42)

resultado = pd.DataFrame([
    ("A · corte no tempo (o honesto)", treinar_e_medir(no_tempo_treino, no_tempo_teste, FEATURES)),
    ("B · divisão aleatória", treinar_e_medir(aleatorio_treino, aleatorio_teste, FEATURES)),
    ("C · no tempo + índice daqui a 4 semanas", treinar_e_medir(no_tempo_treino.dropna(subset=["indice_daqui_a_4_semanas"]),
                                                              no_tempo_teste.dropna(subset=["indice_daqui_a_4_semanas"]),
                                                              FEATURES + ["indice_daqui_a_4_semanas"])),
], columns=["experimento", "auc"])
resultado["passa no teste do prompt 2 (AUC < 0,98)?"] = resultado["auc"] < 0.98
display(resultado)

# COMMAND ----------

# MAGIC %md
# MAGIC **Medido em 18/10/2026:** A 0,922 · B 0,917 · C 0,991.
# MAGIC
# MAGIC *Esses números são da versão com 26 features. Em 19/10 saíram duas (capacidade e incidentes) e o modelo
# MAGIC honesto continuou em 0,92; este notebook não foi medido de novo, então a 2ª casa pode variar um pouco.
# MAGIC A ordem (C acima de 0,98 e barrado; A e B parecidos) é o que importa.*
# MAGIC
# MAGIC **A lição:** desta vez a divisão aleatória (B) não inflou o número — e isso não prova nada. Ela mede uma
# MAGIC situação que o modelo nunca vai enfrentar: na segunda-feira ele não tem a semana seguinte para colar. Às vezes
# MAGIC infla, às vezes não, e você só descobre depois. Por isso a regra é sempre dividir **no tempo**.
# MAGIC O C é o vazamento clássico: uma coluna que só existe depois do fato, e o AUC salta para 0,99. Por isso o
# MAGIC prompt 2 tem um `assert auc < 0.98`. **Modelo bom demais é bug até prova em contrário.**

# COMMAND ----------

dbutils.notebook.exit(json.dumps({l["experimento"]: round(float(l["auc"]), 4) for _, l in resultado.iterrows()}))
