-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 02: ORDER BY, DISTINCT e CAST — o tamanho da carteira
-- MAGIC Conceito: ORDER BY, DISTINCT, CAST, SUM
-- MAGIC Pergunta de negócio: quais são os maiores contratos e quanto vale a carteira?
-- MAGIC Conexão: na bronze tudo é texto. Sem CAST, ORDER BY ordena como palavra.
-- MAGIC
-- MAGIC 1. A armadilha: ordenar texto. '9000000.00' vem antes de '12000000.00'?

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Com CAST, ordena como número

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. A carteira inteira, e só o que está em andamento

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. DISTINCT: para quais segmentos a Vértice trabalha?

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 5. E em quais ferramentas os projetos vivem?
-- MAGIC    Repare: 'Excel', 'excel' e 'Planilha' são a mesma coisa. É a primeira sujeira do dia,
-- MAGIC    e é o retrato do problema da Vértice: cada um registra do seu jeito.

-- COMMAND ----------

-- escreva aqui a sua query

