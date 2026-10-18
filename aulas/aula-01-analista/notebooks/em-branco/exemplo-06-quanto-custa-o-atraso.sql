-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 06: quanto custa? EAC, margem e prazo projetado
-- MAGIC Conceito: CTE encadeada, aritmética de KPI, janela (SUM OVER)
-- MAGIC Pergunta de negócio: SE NADA MUDAR, QUANTO A ATLAS VAI PERDER?
-- MAGIC
-- MAGIC   EAC (estimativa no término) = orçamento / CPI
-- MAGIC   estouro previsto            = EAC − orçamento
-- MAGIC   margem projetada            = (valor do contrato − EAC) / valor do contrato
-- MAGIC   desvio de prazo (dias)      = duração / SPI − duração
-- MAGIC
-- MAGIC É este número em R$ que a diretoria entende. SPI e CPI são o meio; o fim é dinheiro.

-- COMMAND ----------

-- escreva aqui a sua query

