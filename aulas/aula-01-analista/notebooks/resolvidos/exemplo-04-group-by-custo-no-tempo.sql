-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 04: GROUP BY — para onde vai o dinheiro da Vértice?
-- MAGIC Conceito: GROUP BY, SUM, replace
-- MAGIC Pergunta de negócio: quanto a Vértice gasta, por categoria de custo?
-- MAGIC Conexão: é a pergunta 2 do dono ("quanto custa?") começando a ter resposta.
-- MAGIC
-- MAGIC A tabela é a bronze.custos: um lançamento de custo por linha (23.640 linhas).
-- MAGIC
-- MAGIC 1. Quanto cada categoria gastou?
-- MAGIC    GROUP BY categoria   junta as linhas da mesma categoria e faz a conta dentro de cada grupo
-- MAGIC    SUM(...)             soma a coluna dentro do grupo
-- MAGIC    O valor é texto, então primeiro CAST para número (exemplo 02).
-- MAGIC    Deve aparecer: um ERRO. É de propósito: '1827,44' não vira número. É a vírgula do exemplo 03.

-- COMMAND ----------

SELECT categoria,
       SUM(CAST(valor AS DECIMAL(18,2))) AS custo
FROM lakehouse_vertice.bronze.custos
GROUP BY categoria;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. A correção: trocar a vírgula por ponto ANTES de converter.
-- MAGIC    replace(valor, ',', '.')   troca ',' por '.'
-- MAGIC    ROUND(x / 1000000, 1)      em milhões, com 1 casa decimal
-- MAGIC    Deve aparecer: pessoal no topo, com R$ 117,8 mi. Empresa de tecnologia gasta com gente:
-- MAGIC    quase dois terços dos R$ 193,35 mi de custo.

-- COMMAND ----------

SELECT categoria,
       ROUND(SUM(CAST(replace(valor, ',', '.') AS DECIMAL(18,2))) / 1000000, 1) AS custo_milhoes
FROM lakehouse_vertice.bronze.custos
GROUP BY categoria
ORDER BY custo_milhoes DESC;
