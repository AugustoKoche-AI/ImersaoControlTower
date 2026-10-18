-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 06: quanto custa? CPI, EAC, prazo projetado e o farol do gerente
-- MAGIC Conceito: CTE encadeada, aritmética de KPI, janela (SUM OVER), comparação
-- MAGIC Pergunta de negócio: SE NADA MUDAR, QUANTO A VÉRTICE VAI PERDER? E O FAROL MOSTRA ISSO?
-- MAGIC
-- MAGIC   valor agregado (EV) = orçamento × (horas agregadas ÷ horas totais)
-- MAGIC   CPI = EV / custo real           < 1 é estouro (cada R$ 1 gasto entregou menos de R$ 1)
-- MAGIC   EAC (estimativa no término) = orçamento / CPI
-- MAGIC   estouro previsto            = EAC − orçamento
-- MAGIC   margem projetada            = (valor do contrato − EAC) / valor do contrato
-- MAGIC   atraso projetado (dias)     = duração / SPI − duração
-- MAGIC
-- MAGIC Usa o rascunho do exemplo 05 (bronze.rascunho_tarefas): rode o 05 antes.

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC O farol mente? O manual da Vértice diz: verde só com SPI ≥ 0,95.
-- MAGIC Quantos projetos o gerente pintou de verde com o número dizendo outra coisa?

-- COMMAND ----------

-- escreva aqui a sua query

