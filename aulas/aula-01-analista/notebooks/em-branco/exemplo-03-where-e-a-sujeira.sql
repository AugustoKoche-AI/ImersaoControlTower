-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 03: WHERE — filtrar, e achar a sujeira
-- MAGIC Conceito: WHERE, LIKE, IS NULL, COUNT(*) FILTER
-- MAGIC Pergunta de negócio: dá para confiar nesse número?
-- MAGIC Conexão com a noite 2: tudo que este exemplo acha é o que a silver conserta.
-- MAGIC
-- MAGIC Este é o exemplo mais importante do dia. Dado sujo não dá erro:
-- MAGIC ele dá um número errado, em silêncio, e a diretoria decide em cima dele.
-- MAGIC
-- MAGIC 1. Data em dois formatos: 2025-03-14 e 14/03/2025 na mesma coluna

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. UF escrita de três jeitos

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. Tarefa com mais de 100% concluída. Não existe: é erro de digitação no cronograma.

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. Custo com vírgula decimal: '12345,67'. CAST disso quebra (ou vira nulo).

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 5. Estorno: valor negativo. NÃO é erro, é informação: o lançamento foi revertido.

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 6. O mesmo fornecedor digitado de quatro jeitos no ERP de compras

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 7. Equipe duplicada no cadastro do RH

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 8. RDO não preenchido

-- COMMAND ----------

-- escreva aqui a sua query

