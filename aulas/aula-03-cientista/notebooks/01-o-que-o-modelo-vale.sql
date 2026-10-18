-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Noite 3 · O que o modelo vale (conferência, só leitura)
-- MAGIC
-- MAGIC Abra depois do prompt 3. Tudo aqui lê tabelas que o job já gravou: dá para mostrar na live sem
-- MAGIC esperar treino nenhum.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 1. O modelo contra a régua: AUC, baselines e a métrica da diretoria

-- COMMAND ----------

SELECT versao,
       ROUND(auc, 4)                AS auc_modelo,
       ROUND(auc_baseline_folga, 4) AS auc_regra_da_folga,
       ROUND(auc_classificador, 4)  AS auc_classificador_sim_nao,
       estouros_avisados || ' de ' || estouros_teste AS estouros_avisados_no_top5,
       ROUND(antecedencia_media_dias) AS dias_de_antecedencia,
       ROUND(estouro_previsto_avisado / 1e6, 1) AS estouro_dessas_obras_mi,
       feature_principal
FROM lakehouse_atlas.gold.modelo_metricas;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 2. A lista de segunda-feira
-- MAGIC As 13 primeiras a regra de corte já vê (probabilidade 1,0). O valor do modelo começa na 14ª.

-- COMMAND ----------

SELECT s.ranking, s.projeto_id, o.nome_projeto, o.uf, o.situacao,
       ROUND(o.spi, 2) AS spi, ROUND(o.cpi, 2) AS cpi,
       s.prob_estouro_30d, s.faixa_risco, s.principais_fatores
FROM lakehouse_atlas.gold.score_estouro_30d s
JOIN lakehouse_atlas.gold.obra_situacao_atual o USING (projeto_id)
ORDER BY s.ranking;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 3. O que a regra de corte não vê e o modelo vê
-- MAGIC Obras "ok" para a regra (SPI e CPI >= 0,9) com probabilidade relevante de cruzar em 30 dias.

-- COMMAND ----------

SELECT s.projeto_id, o.nome_projeto, ROUND(o.spi, 2) AS spi, ROUND(o.cpi, 2) AS cpi,
       s.prob_estouro_30d, s.principais_fatores
FROM lakehouse_atlas.gold.score_estouro_30d s
JOIN lakehouse_atlas.gold.obra_situacao_atual o USING (projeto_id)
WHERE o.situacao = 'ok' AND s.prob_estouro_30d >= 0.1
ORDER BY s.prob_estouro_30d DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 4. A curva da P034: por que ela entrou na lista
-- MAGIC O índice está acima de 0,9 hoje, mas a distância encolheu. É isso que o modelo pesa.

-- COMMAND ----------

SELECT semana, ROUND(spi, 3) AS spi, ROUND(cpi, 3) AS cpi, ROUND(indice_min, 3) AS pior_indice,
       ROUND(spi_ultimas_4s, 2) AS ritmo_ultimo_mes, estoura_30d
FROM lakehouse_atlas.gold.features_obra_semana
WHERE projeto_id = 'P034' AND semana >= DATE'2026-06-01'
ORDER BY semana;
