-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 04: GROUP BY — quanto a Vértice gasta por mês?
-- MAGIC Conceito: GROUP BY, date_trunc, try_cast, replace
-- MAGIC Pergunta de negócio: qual é o custo real da carteira, mês a mês?
-- MAGIC Conexão: a primeira query FALHA DE PROPÓSITO. Rode com --continuar.
-- MAGIC
-- MAGIC 1. A query óbvia. Quebra: '12345,67' não é número.

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. A "correção" perigosa: try_cast não quebra... ele joga a linha fora em silêncio.

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. A correção certa: trocar a vírgula por ponto ANTES de converter

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. Agora sim: custo real por mês

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 5. Por categoria: para onde vai o dinheiro de uma empresa de tecnologia?
-- MAGIC    (spoiler: gente. Folha alocada é quase dois terços do custo)

-- COMMAND ----------

-- escreva aqui a sua query

