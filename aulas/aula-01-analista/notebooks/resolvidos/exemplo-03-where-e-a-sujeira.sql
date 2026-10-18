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

SELECT COUNT(*) FILTER (WHERE data_inicio LIKE '%/%') AS formato_brasileiro,
       COUNT(*) FILTER (WHERE data_inicio LIKE '%-%') AS formato_iso
FROM lakehouse_atlas.bronze.projetos;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. UF escrita de três jeitos

-- COMMAND ----------

SELECT uf, COUNT(*) AS obras
FROM lakehouse_atlas.bronze.projetos
GROUP BY uf
ORDER BY upper(trim(uf));

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. Tarefa com mais de 100% concluída. Não existe: é erro de digitação no cronograma.

-- COMMAND ----------

SELECT tarefa_id, projeto_id, descricao, pct_concluido
FROM lakehouse_atlas.bronze.tarefas
WHERE CAST(pct_concluido AS DOUBLE) > 100
ORDER BY CAST(pct_concluido AS DOUBLE) DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. Custo com vírgula decimal: '12345,67'. CAST disso quebra (ou vira nulo).

-- COMMAND ----------

SELECT COUNT(*) FILTER (WHERE valor_real LIKE '%,%') AS com_virgula,
       COUNT(*)                                       AS total
FROM lakehouse_atlas.bronze.custos;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 5. Estorno: valor negativo. NÃO é erro, é informação: o lançamento foi revertido.

-- COMMAND ----------

SELECT categoria, COUNT(*) AS estornos
FROM lakehouse_atlas.bronze.custos
WHERE valor_real LIKE '-%'
GROUP BY categoria;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 6. O mesmo fornecedor digitado de quatro jeitos no ERP de compras

-- COMMAND ----------

SELECT fornecedor, COUNT(*) AS pedidos
FROM lakehouse_atlas.bronze.compras
WHERE lower(fornecedor) LIKE '%norte%'
GROUP BY fornecedor;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 7. Equipe duplicada no cadastro do RH

-- COMMAND ----------

SELECT equipe_id, COUNT(*) AS vezes
FROM lakehouse_atlas.bronze.equipes
GROUP BY equipe_id
HAVING COUNT(*) > 1;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 8. RDO não preenchido

-- COMMAND ----------

SELECT COUNT(*) AS rdos_vazios
FROM lakehouse_atlas.bronze.rdo
WHERE texto_livre IS NULL OR trim(texto_livre) IN ('', 'N/A', 'ver RDO físico');
