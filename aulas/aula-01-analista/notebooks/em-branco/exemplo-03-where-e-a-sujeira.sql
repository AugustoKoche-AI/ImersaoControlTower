-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 03: WHERE — filtrar, e achar a sujeira
-- MAGIC Conceito: WHERE, LIKE
-- MAGIC Pergunta de negócio: dá para confiar nesse número?
-- MAGIC Conexão com a noite 2: tudo que este exemplo acha é o que a silver conserta.
-- MAGIC
-- MAGIC Dado sujo não dá erro: dá um número errado, em silêncio, e a diretoria decide em cima dele.
-- MAGIC
-- MAGIC O WHERE vem depois do FROM e diz QUAIS linhas entram:
-- MAGIC   WHERE coluna = 'valor'      igual a
-- MAGIC   WHERE coluna LIKE '%/%'     "parece com". O % quer dizer "qualquer coisa aqui":
-- MAGIC                               '%/%' = tem uma barra em algum lugar
-- MAGIC
-- MAGIC 1. A data de início em dois formatos na mesma coluna: 14/03/2025 e 2025-03-14.
-- MAGIC    Quantos projetos estão no formato com barra?
-- MAGIC    Deve aparecer: 24 (os outros 36 estão como 2025-03-14). Uma conta de prazo que só
-- MAGIC    entenda um dos formatos erra 24 projetos.

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Excel: a linha de TOTAL que o gerente deixou no fim de cada planilha.
-- MAGIC    Deve aparecer: 20 linhas, uma por planilha. Quem soma a coluna de horas inteira
-- MAGIC    conta tudo duas vezes.

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. Financeiro: custo com vírgula decimal ('12345,67'). Para o computador, isso não é número.
-- MAGIC    Deve aparecer: 671 lançamentos. O exemplo 04 mostra o estrago.

-- COMMAND ----------

-- escreva aqui a sua query

