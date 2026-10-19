-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 02: ORDER BY, DISTINCT e CAST — o tamanho da carteira
-- MAGIC Conceito: ORDER BY, DISTINCT, CAST, SUM
-- MAGIC Pergunta de negócio: quais são os maiores contratos e quanto vale a carteira?
-- MAGIC Conexão: na bronze tudo é texto. Sem CAST, ORDER BY ordena como palavra.
-- MAGIC
-- MAGIC 1. A armadilha: ordenar texto. '9000000.00' vem antes de '12000000.00'?

-- COMMAND ----------

SELECT projeto_id, nome_projeto, valor_contrato
FROM lakehouse_vertice.bronze.projetos
ORDER BY valor_contrato DESC
LIMIT 5;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Com CAST, ordena como número

-- COMMAND ----------

SELECT projeto_id, nome_projeto, cliente,
       CAST(valor_contrato AS DECIMAL(18,2)) AS valor_contrato
FROM lakehouse_vertice.bronze.projetos
ORDER BY 4 DESC
LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. A carteira inteira, e só o que está em andamento

-- COMMAND ----------

SELECT COUNT(*)                                                         AS projetos,
       ROUND(SUM(CAST(valor_contrato AS DECIMAL(18,2))) / 1e6, 1)       AS carteira_milhoes,
       COUNT(*) FILTER (WHERE status = 'em_andamento')                  AS em_andamento,
       ROUND(SUM(CAST(valor_contrato AS DECIMAL(18,2)))
             FILTER (WHERE status = 'em_andamento') / 1e6, 1)           AS em_andamento_milhoes
FROM lakehouse_vertice.bronze.projetos;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. DISTINCT: para quais segmentos a Vértice trabalha?

-- COMMAND ----------

SELECT DISTINCT segmento FROM lakehouse_vertice.bronze.projetos ORDER BY segmento;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 5. E em quais ferramentas os projetos vivem?
-- MAGIC    Repare: 'Excel', 'excel' e 'Planilha' são a mesma coisa. É a primeira sujeira do dia,
-- MAGIC    e é o retrato do problema da Vértice: cada um registra do seu jeito.

-- COMMAND ----------

SELECT DISTINCT ferramenta
FROM lakehouse_vertice.bronze.projetos
ORDER BY ferramenta;
