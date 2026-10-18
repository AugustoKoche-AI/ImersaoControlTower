-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 01: SELECT — o que existe no catálogo?
-- MAGIC Conceito: SELECT, FROM, LIMIT, COUNT(*)
-- MAGIC Pergunta de negócio: que obras a Atlas tem na carteira?
-- MAGIC Conexão: antes de calcular qualquer KPI, olhe o dado. Sempre.
-- MAGIC
-- MAGIC 1. A primeira olhada: 10 linhas de projetos

-- COMMAND ----------

SELECT *
FROM lakehouse_atlas.bronze.projetos
LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Quantas obras? Quantas tarefas de cronograma? Quantos RDOs?

-- COMMAND ----------

SELECT
    (SELECT COUNT(*) FROM lakehouse_atlas.bronze.projetos) AS obras,
    (SELECT COUNT(*) FROM lakehouse_atlas.bronze.tarefas)  AS tarefas,
    (SELECT COUNT(*) FROM lakehouse_atlas.bronze.rdo)      AS rdos,
    (SELECT COUNT(*) FROM lakehouse_atlas.bronze.custos)   AS lancamentos_de_custo;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. Só as colunas que importam para a diretoria

-- COMMAND ----------

SELECT projeto_id, nome_projeto, cliente, setor, uf, valor_contrato, status
FROM lakehouse_atlas.bronze.projetos
LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. Um RDO de verdade: é texto livre, escrito pelo engenheiro no fim do dia.
-- MAGIC    A causa do atraso está aqui dentro. Na noite 2, a IA vai tirar ela daqui.

-- COMMAND ----------

SELECT data, projeto_id, texto_livre
FROM lakehouse_atlas.bronze.rdo
WHERE projeto_id = 'P011'
ORDER BY data DESC
LIMIT 5;
