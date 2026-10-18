-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 02: ORDER BY, DISTINCT e CAST — o tamanho da carteira
-- MAGIC Conceito: ORDER BY, DISTINCT, CAST, SUM
-- MAGIC Pergunta de negócio: quais são os maiores contratos e quanto vale a carteira?
-- MAGIC Conexão: na bronze tudo é texto. Sem CAST, ORDER BY ordena como palavra.
-- MAGIC
-- MAGIC 1. A armadilha: ordenar texto. '9.000.000' vem antes de '62.000.000'?

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Com CAST, ordena como número

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. A carteira inteira

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. DISTINCT: em quais setores e UFs a Atlas atua?
-- MAGIC    Repare na UF: 'MG', 'mg' e ' MG ' são a mesma coisa. É a primeira sujeira do dia.

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- escreva aqui a sua query

