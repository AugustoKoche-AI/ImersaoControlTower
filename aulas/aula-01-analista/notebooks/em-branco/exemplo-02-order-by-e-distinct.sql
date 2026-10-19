-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 02: ORDER BY, CAST e DISTINCT — os maiores contratos
-- MAGIC Conceito: ORDER BY, CAST, DISTINCT
-- MAGIC Pergunta de negócio: quais são os maiores contratos da Vértice?
-- MAGIC Conexão: na bronze tudo é texto. Sem CAST, o Databricks ordena como palavra.
-- MAGIC
-- MAGIC 1. Os 5 maiores contratos... ou não.
-- MAGIC    ORDER BY coluna DESC   ordena do maior para o menor
-- MAGIC    Deve aparecer: uma lista que PARECE certa, com o PRJ-052 (R$ 8,4 mi) no topo. Está errada.
-- MAGIC    O valor é texto, e texto se ordena letra por letra: '8380000' vem antes de '15275000'
-- MAGIC    porque '8' vem depois de '1', como numa lista telefônica.

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. A correção: converter o texto em número antes de ordenar.
-- MAGIC    CAST(coluna AS DECIMAL(18,2))   transforma o texto em número com 2 casas decimais
-- MAGIC    Deve aparecer: o maior contrato de verdade é o PRJ-017, R$ 15,3 mi.

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. Em quais ferramentas os projetos vivem?
-- MAGIC    DISTINCT   tira as repetições: cada valor aparece uma vez só
-- MAGIC    Deve aparecer: 8 jeitos de escrever 3 ferramentas: 'Excel', 'excel', 'Planilha',
-- MAGIC    'ClickUp', 'Clickup', 'MS Project', 'Project', 'msproject'.
-- MAGIC    É o retrato do problema da Vértice: cada um registra do seu jeito.

-- COMMAND ----------

-- escreva aqui a sua query

