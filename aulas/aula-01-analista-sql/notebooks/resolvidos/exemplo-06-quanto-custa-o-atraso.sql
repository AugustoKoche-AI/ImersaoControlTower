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

WITH valor AS (
    SELECT projeto_id,
           SUM(horas)                       AS horas_totais,
           SUM(horas * pct_concluido / 100) AS horas_agregadas,
           SUM(horas * GREATEST(0, LEAST(1,
               datediff(DATE'2026-10-16', inicio_baseline) / datediff(fim_baseline, inicio_baseline)
           )))                               AS horas_planejadas
    FROM lakehouse_vertice.bronze.rascunho_tarefas
    GROUP BY projeto_id
),
custo AS (
    SELECT projeto_id,
           SUM(CAST(replace(valor, ',', '.') AS DECIMAL(18,2))) AS custo_real
    FROM lakehouse_vertice.bronze.custos
    GROUP BY projeto_id
),
farol AS (
    SELECT projeto_id, lower(farol) AS farol
    FROM lakehouse_vertice.bronze.status_semanal
    WHERE data_status = '2026-10-16'
)
SELECT p.projeto_id,
       p.cliente,
       ROUND(v.horas_agregadas / v.horas_planejadas, 2)                          AS spi,
       ROUND(CAST(p.orcamento_custo AS DECIMAL(18,2))
             * v.horas_agregadas / v.horas_totais / c.custo_real, 2)              AS cpi,
       f.farol                                                                   AS farol_do_gerente,
       -- estouro = EAC − orçamento = orçamento ÷ CPI − orçamento
       ROUND((c.custo_real * v.horas_totais / v.horas_agregadas
              - CAST(p.orcamento_custo AS DECIMAL(18,2))) / 1000000, 2)           AS estouro_milhoes
FROM lakehouse_vertice.bronze.projetos p
JOIN valor v USING (projeto_id)
JOIN custo c USING (projeto_id)
JOIN farol f USING (projeto_id)
WHERE p.status = 'em_andamento'
ORDER BY spi;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. O número para o dono: quanto a carteira vai estourar, somando só quem estoura.
-- MAGIC    (Projeto que está gastando menos que o previsto não "compensa" o que outro queima.)
-- MAGIC    Nada novo: as mesmas contas do bloco 1, agora somadas. GREATEST(0, x) zera quem não estoura.
-- MAGIC    Deve aparecer: R$ 6,47 mi. A resposta da pergunta 2.

-- COMMAND ----------

WITH valor AS (
    SELECT projeto_id,
           SUM(horas)                       AS horas_totais,
           SUM(horas * pct_concluido / 100) AS horas_agregadas
    FROM lakehouse_vertice.bronze.rascunho_tarefas
    GROUP BY projeto_id
),
custo AS (
    SELECT projeto_id,
           SUM(CAST(replace(valor, ',', '.') AS DECIMAL(18,2))) AS custo_real
    FROM lakehouse_vertice.bronze.custos
    GROUP BY projeto_id
)
SELECT ROUND(SUM(GREATEST(0,
           c.custo_real * v.horas_totais / v.horas_agregadas
           - CAST(p.orcamento_custo AS DECIMAL(18,2)))) / 1000000, 2) AS estouro_previsto_milhoes
FROM lakehouse_vertice.bronze.projetos p
JOIN valor v USING (projeto_id)
JOIN custo c USING (projeto_id)
WHERE p.status = 'em_andamento';
