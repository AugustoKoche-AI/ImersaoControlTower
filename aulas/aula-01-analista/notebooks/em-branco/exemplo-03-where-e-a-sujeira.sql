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
-- MAGIC 2. A ferramenta escrita de vários jeitos, e projeto sem o código da ferramenta

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. Excel: a mesma coluna de data tem texto ('03/02/2026') e número de série do Excel ('46056')

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. Excel: o % concluído vem como '45%', '10,5%' ou 0.45. E tem tarefa com MAIS de 100%.

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 5. Excel: a linha de TOTAL que o gerente deixou no fim da planilha. Somar tudo conta duas vezes.

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 6. ClickUp: o status "concluído" escrito de 4 jeitos, "em andamento" de 5

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 7. MS Project: tarefa-resumo (Summary = 1) soma as horas das tarefas de baixo.
-- MAGIC    Quem soma a coluna Work inteira conta as horas três vezes (projeto, fase, tarefa).

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 8. Custo com vírgula decimal: '12345,67'. CAST disso quebra (ou vira nulo).

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 9. Estorno: valor negativo. NÃO é erro, é informação: o lançamento foi revertido.

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 10. A mesma consultoria digitada de quatro jeitos em compras

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 11. Pessoa duplicada no cadastro do RH

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 12. Status semanal não preenchido

-- COMMAND ----------

-- escreva aqui a sua query

