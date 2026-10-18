-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 01: SELECT — o que existe no catálogo?
-- MAGIC Conceito: SELECT, FROM, LIMIT, COUNT(*)
-- MAGIC Pergunta de negócio: que projetos a Vértice tem na carteira, e onde cada um vive?
-- MAGIC Conexão: antes de calcular qualquer KPI, olhe o dado. Sempre.
-- MAGIC
-- MAGIC 1. A primeira olhada: 10 linhas do cadastro de projetos do PMO

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Quanta coisa a Vértice tem? Projetos, tarefas em cada ferramenta, pessoas, status semanais

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. O mesmo tipo de informação, três caras diferentes. Olhe uma tarefa de cada ferramenta:
-- MAGIC    Excel: datas como texto OU como número (45930?), % como '45%' OU como 0.45

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ClickUp: status é uma estrutura, datas são milissegundos, o % está dentro de uma lista de campos

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC MS Project: horas no formato 'PT40H0M0S' e uma baseline dentro de cada tarefa

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. O status semanal: toda sexta o gerente escreve, em texto livre, como está o projeto.
-- MAGIC    A causa do atraso está aqui dentro. Na noite 2, a IA vai tirar ela daqui.

-- COMMAND ----------

-- escreva aqui a sua query

