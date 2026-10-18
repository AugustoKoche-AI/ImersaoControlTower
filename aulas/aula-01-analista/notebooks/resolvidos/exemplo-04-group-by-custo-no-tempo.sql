-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 04: GROUP BY — quanto a Atlas gasta por mês?
-- MAGIC Conceito: GROUP BY, date_trunc, try_cast, replace
-- MAGIC Pergunta de negócio: qual é o custo real da carteira, mês a mês?
-- MAGIC Conexão: a primeira query FALHA DE PROPÓSITO. Rode com --continuar.
-- MAGIC
-- MAGIC 1. A query óbvia. Quebra: '12345,67' não é número.

-- COMMAND ----------

SELECT date_trunc('MONTH', CAST(data AS DATE))       AS mes,
       SUM(CAST(valor_real AS DECIMAL(18,2)))        AS custo
FROM lakehouse_atlas.bronze.custos
GROUP BY 1
ORDER BY 1;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. A "correção" perigosa: try_cast não quebra... ele joga a linha fora em silêncio.

-- COMMAND ----------

SELECT ROUND(SUM(try_cast(valor_real AS DECIMAL(18,2))) / 1e6, 2) AS custo_milhoes_errado,
       COUNT(*) FILTER (WHERE try_cast(valor_real AS DECIMAL(18,2)) IS NULL) AS linhas_perdidas
FROM lakehouse_atlas.bronze.custos;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. A correção certa: trocar a vírgula por ponto ANTES de converter

-- COMMAND ----------

SELECT ROUND(SUM(CAST(replace(valor_real, ',', '.') AS DECIMAL(18,2))) / 1e6, 2) AS custo_milhoes
FROM lakehouse_atlas.bronze.custos;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. Agora sim: custo real por mês

-- COMMAND ----------

SELECT date_trunc('MONTH', CAST(data AS DATE))                         AS mes,
       ROUND(SUM(CAST(replace(valor_real, ',', '.') AS DECIMAL(18,2))) / 1e6, 2) AS custo_milhoes
FROM lakehouse_atlas.bronze.custos
GROUP BY 1
ORDER BY 1;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 5. Por categoria: para onde vai o dinheiro?

-- COMMAND ----------

SELECT categoria,
       ROUND(SUM(CAST(replace(valor_real, ',', '.') AS DECIMAL(18,2))) / 1e6, 1) AS custo_milhoes
FROM lakehouse_atlas.bronze.custos
GROUP BY categoria
ORDER BY 2 DESC;
