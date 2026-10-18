-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 05: UNION — as três ferramentas numa fila só
-- MAGIC Conceito: CTE (WITH), UNION ALL, CASE, JOIN, conversão de datas
-- MAGIC Pergunta de negócio: QUAIS PROJETOS ESTÃO MAIS ATRASADOS?
-- MAGIC
-- MAGIC É a primeira pergunta que o CTO recebeu, e ninguém na Vértice sabia responder:
-- MAGIC 20 projetos estão no Excel, 25 no ClickUp e 15 no MS Project. Aqui a gente faz
-- MAGIC um RASCUNHO à mão: cada ferramenta é traduzida para as mesmas 7 colunas e
-- MAGIC empilhada com UNION ALL. Na noite 2 isso vira pipeline de verdade (silver).
-- MAGIC
-- MAGIC Gestão de projetos mede atraso com o SPI (Earned Value):
-- MAGIC   planejado  quanto DEVIA estar pronto até hoje, pela baseline (em horas)
-- MAGIC   agregado   quanto ESTÁ pronto: horas da tarefa × % concluído
-- MAGIC   SPI = agregado / planejado      < 1 é atraso (0,80 = andou 80% do que devia)
-- MAGIC
-- MAGIC Regra de corte da Torre: abaixo de 0,9 = atenção; abaixo de 0,8 = crítico.
-- MAGIC O "hoje" do dataset é 16/10/2026: nunca use current_date() aqui,
-- MAGIC senão o seu número muda todo dia e não bate com o de ninguém.
-- MAGIC
-- MAGIC 1. O rascunho: uma view com as tarefas das três ferramentas no mesmo formato

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC datas em milissegundos; % e baseline dentro da lista de campos personalizados

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Conferência: 60 projetos, cada um numa ferramenta

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. A resposta: SPI de cada projeto em andamento, do mais atrasado para o menos

-- COMMAND ----------

-- escreva aqui a sua query

