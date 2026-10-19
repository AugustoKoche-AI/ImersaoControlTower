-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 06: QUANTO CUSTA? O estouro e o farol do gerente
-- MAGIC Conceito: juntar várias consultas com WITH e fazer conta de KPI
-- MAGIC Pergunta de negócio: SE NADA MUDAR, QUANTO A VÉRTICE VAI PERDER? E O FAROL MOSTRA ISSO?
-- MAGIC Usa o rascunho do exemplo 05 (bronze.rascunho_tarefas): rode o 05 antes.
-- MAGIC
-- MAGIC As contas (todas sobre o orçamento de custo do projeto):
-- MAGIC   valor agregado (EV) = orçamento × fração pronta          (quanto vale o que já foi entregue)
-- MAGIC   CPI = EV ÷ custo real                                    abaixo de 1 é estouro: cada R$ 1
-- MAGIC                                                            gasto entregou menos de R$ 1
-- MAGIC   EAC = orçamento ÷ CPI                                    quanto o projeto vai custar no fim,
-- MAGIC                                                            se o ritmo continuar
-- MAGIC   estouro previsto = EAC − orçamento
-- MAGIC
-- MAGIC A consulta tem 3 pedaços (WITH), cada um uma pergunta simples:
-- MAGIC   valor   quanto de cada projeto está pronto, e quanto devia estar (o exemplo 05)
-- MAGIC   custo   quanto cada projeto já gastou (o exemplo 04, por projeto)
-- MAGIC   farol   a cor que o gerente publicou nesta sexta, 16/10
-- MAGIC
-- MAGIC 1. Projeto a projeto: prazo, custo, estouro, e o farol do gerente.
-- MAGIC    Deve aparecer: 41 projetos, do pior para o melhor. Repare na coluna farol_do_gerente:
-- MAGIC    PRJ-012, 028, 034 e 042 estão VERDES com SPI abaixo de 0,9. São os "melancias":
-- MAGIC    verdes por fora, vermelhos por dentro.

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. O número para o dono: quanto a carteira vai estourar, somando só quem estoura.
-- MAGIC    (Projeto que está gastando menos que o previsto não "compensa" o que outro queima.)
-- MAGIC    Nada novo: as mesmas contas do bloco 1, agora somadas. GREATEST(0, x) zera quem não estoura.
-- MAGIC    Deve aparecer: R$ 6,47 mi. A resposta da pergunta 2.

-- COMMAND ----------

-- escreva aqui a sua query

