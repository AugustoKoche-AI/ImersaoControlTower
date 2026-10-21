-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Noite 4 · O que o modelo vale (conferência, só leitura)
-- MAGIC
-- MAGIC Abra depois do prompt 3. Tudo aqui lê tabelas que o job já gravou: dá para mostrar na live sem
-- MAGIC esperar treino nenhum.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 1. O modelo contra a régua: AUC, baselines e a métrica do dono

-- COMMAND ----------

SELECT versao,
       ROUND(auc, 4)                    AS auc_modelo,
       ROUND(auc_baseline_folga, 4)     AS auc_regra_da_folga,
       ROUND(auc_baseline_cpi, 4)       AS auc_so_o_cpi,
       ROUND(auc_baseline_tendencia, 4) AS auc_tendencia,
       ROUND(auc_classificador, 4)      AS auc_classificador_sim_nao,
       estouros_avisados || ' de ' || estouros_teste AS estouros_avisados_no_top5,
       ROUND(antecedencia_media_dias)   AS dias_de_antecedencia,
       ROUND(estouro_previsto_avisado / 1e6, 2) AS estouro_desses_projetos_mi,
       projetos_avisados,
       feature_principal
FROM lakehouse_vertice.ml.modelo_metricas;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 2. A lista de segunda-feira
-- MAGIC Os 17 primeiros a regra de corte já vê (probabilidade 1,0). O valor do modelo começa no 18º.

-- COMMAND ----------

SELECT s.ranking, s.projeto_id, p.nome_projeto, p.cliente, p.situacao,
       ROUND(p.spi, 2) AS spi, ROUND(p.cpi, 2) AS cpi,
       s.prob_estouro_30d, s.faixa_risco, s.principais_fatores
FROM lakehouse_vertice.gold.score_estouro_30d s
JOIN lakehouse_vertice.gold.projeto_situacao_atual p USING (projeto_id)
ORDER BY s.ranking;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 3. O que a regra de corte não vê e o modelo vê
-- MAGIC Projetos "ok" para a regra (SPI e CPI >= 0,9) com probabilidade relevante de cruzar em 30 dias.

-- COMMAND ----------

SELECT s.projeto_id, p.nome_projeto, p.cliente, ROUND(p.spi, 2) AS spi, ROUND(p.cpi, 2) AS cpi,
       s.prob_estouro_30d, s.principais_fatores
FROM lakehouse_vertice.gold.score_estouro_30d s
JOIN lakehouse_vertice.gold.projeto_situacao_atual p USING (projeto_id)
WHERE p.situacao = 'ok' AND s.prob_estouro_30d >= 0.1
ORDER BY s.prob_estouro_30d DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 4. A curva do PRJ-024: por que ele entrou na lista
-- MAGIC O índice está acima de 0,9 hoje (SPI 0,91), mas a 0,01 do corte: o modelo dá 46% de chance de cruzar em 30 dias.
-- MAGIC É o marketplace de sellers, um e-commerce: o change freeze da Black Friday começa em 01/11, daqui a 15 dias,
-- MAGIC e trava deploy. Repare no que aconteceu com o SPI no freeze do ano passado (novembro de 2025 a janeiro).

-- COMMAND ----------

SELECT semana, ROUND(spi, 3) AS spi, ROUND(cpi, 3) AS cpi, ROUND(indice_min, 3) AS pior_indice,
       ROUND(spi_ultimas_4s, 2) AS ritmo_ultimo_mes, status_freeze_4s, estoura_30d
FROM lakehouse_vertice.ml.features_projeto_semana
WHERE projeto_id = 'PRJ-024' AND semana >= DATE'2025-10-01'
ORDER BY semana;
