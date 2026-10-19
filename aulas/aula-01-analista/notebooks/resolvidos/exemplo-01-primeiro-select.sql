-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 01: SELECT — o que existe no catálogo?
-- MAGIC Conceito: SELECT, FROM, LIMIT, COUNT(*)
-- MAGIC Pergunta de negócio: que projetos a Vértice tem, e onde cada um vive?
-- MAGIC Conexão: antes de calcular qualquer coisa, olhe o dado. Sempre.
-- MAGIC
-- MAGIC O nome completo de uma tabela tem 3 partes: catálogo.schema.tabela
-- MAGIC   lakehouse_vertice . bronze . projetos
-- MAGIC Rode um bloco de cada vez: selecione o bloco e Ctrl+Enter.
-- MAGIC
-- MAGIC 1. A primeira olhada no cadastro de projetos do PMO.
-- MAGIC    SELECT *   traga todas as colunas
-- MAGIC    FROM ...   da tabela tal
-- MAGIC    LIMIT 10   só as 10 primeiras linhas
-- MAGIC    Deve aparecer: 10 projetos com cliente, valor do contrato, prazo e a coluna ferramenta
-- MAGIC    (Excel, ClickUp ou MS Project): é onde o cronograma de cada um vive. Repare que a
-- MAGIC    mesma ferramenta aparece escrita de jeitos diferentes. Volta no exemplo 02.

-- COMMAND ----------

SELECT *
FROM lakehouse_vertice.bronze.projetos
LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Quantos projetos a Vértice tem?
-- MAGIC    COUNT(*)   conta as linhas
-- MAGIC    AS nome    dá um nome para a coluna do resultado
-- MAGIC    Deve aparecer: 60.

-- COMMAND ----------

SELECT COUNT(*) AS projetos
FROM lakehouse_vertice.bronze.projetos;
