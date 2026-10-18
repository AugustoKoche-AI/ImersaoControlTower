-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 02: ORDER BY, DISTINCT e CAST — o tamanho da carteira
-- MAGIC Conceito: ORDER BY, DISTINCT, CAST, SUM
-- MAGIC Pergunta de negócio: quais são os maiores contratos e quanto vale a carteira?
-- MAGIC Conexão: na bronze tudo é texto. Sem CAST, ORDER BY ordena como palavra.
-- MAGIC
-- MAGIC 1. A armadilha: ordenar texto. '9.000.000' vem antes de '62.000.000'?

-- COMMAND ----------

SELECT projeto_id, nome_projeto, valor_contrato
FROM lakehouse_atlas.bronze.projetos
ORDER BY valor_contrato DESC
LIMIT 5;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Com CAST, ordena como número

-- COMMAND ----------

SELECT projeto_id, nome_projeto, cliente,
       CAST(valor_contrato AS DECIMAL(18,2)) AS valor_contrato
FROM lakehouse_atlas.bronze.projetos
ORDER BY 4 DESC
LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. A carteira inteira

-- COMMAND ----------

SELECT COUNT(*)                                          AS obras,
       ROUND(SUM(CAST(valor_contrato AS DECIMAL(18,2))) / 1e6, 1) AS carteira_milhoes
FROM lakehouse_atlas.bronze.projetos;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. DISTINCT: em quais setores e UFs a Atlas atua?
-- MAGIC    Repare na UF: 'MG', 'mg' e ' MG ' são a mesma coisa. É a primeira sujeira do dia.

-- COMMAND ----------

SELECT DISTINCT setor FROM lakehouse_atlas.bronze.projetos ORDER BY setor;

-- COMMAND ----------

SELECT DISTINCT uf, length(uf) AS tamanho
FROM lakehouse_atlas.bronze.projetos
ORDER BY uf;
