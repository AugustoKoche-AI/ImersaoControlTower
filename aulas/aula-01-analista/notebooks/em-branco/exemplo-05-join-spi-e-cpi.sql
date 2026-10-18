-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 05: JOIN — quais obras estão atrasadas? (SPI e CPI)
-- MAGIC Conceito: JOIN, CTE (WITH), LEAST/GREATEST, datediff
-- MAGIC Pergunta de negócio: QUAIS OBRAS ESTÃO ATRASADAS OU ESTOURANDO O CUSTO?
-- MAGIC
-- MAGIC Gestão de projetos mede com três números (Earned Value):
-- MAGIC   PV  valor planejado   quanto DEVIA estar pronto até hoje, pelo cronograma
-- MAGIC   EV  valor agregado    quanto ESTÁ pronto, em R$ do orçamento
-- MAGIC   AC  custo real        quanto já GASTAMOS
-- MAGIC
-- MAGIC   SPI = EV / PV   < 1 é atraso      (0,80 = andou 80% do que devia)
-- MAGIC   CPI = EV / AC   < 1 é estouro     (0,80 = cada R$ 1 gasto entregou R$ 0,80)
-- MAGIC
-- MAGIC Regra de corte da Torre: abaixo de 0,9 = atenção; abaixo de 0,8 = crítico.
-- MAGIC O "hoje" do dataset é 16/10/2026: nunca use current_date() aqui,
-- MAGIC senão o seu número muda todo dia e não bate com o de ninguém.

-- COMMAND ----------

-- escreva aqui a sua query

