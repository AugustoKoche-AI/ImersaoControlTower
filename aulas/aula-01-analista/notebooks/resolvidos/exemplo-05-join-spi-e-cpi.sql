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

WITH tarefas AS (
    SELECT projeto_id,
           CAST(valor_planejado AS DECIMAL(18,2))                    AS vp,
           LEAST(CAST(pct_concluido AS DOUBLE), 100) / 100           AS pct,   -- corta o >100%
           GREATEST(0, LEAST(1,
               datediff(DATE'2026-10-16', CAST(inicio_baseline AS DATE))
               / datediff(CAST(fim_baseline AS DATE), CAST(inicio_baseline AS DATE))
           ))                                                        AS pct_planejado
    FROM lakehouse_atlas.bronze.tarefas
),
valor AS (
    SELECT projeto_id,
           SUM(vp * pct_planejado) AS pv,
           SUM(vp * pct)           AS ev
    FROM tarefas
    GROUP BY projeto_id
),
custo AS (
    SELECT projeto_id,
           SUM(CAST(replace(valor_real, ',', '.') AS DECIMAL(18,2))) AS ac
    FROM lakehouse_atlas.bronze.custos
    GROUP BY projeto_id
)
SELECT p.projeto_id,
       p.nome_projeto,
       upper(trim(p.uf))                 AS uf,
       ROUND(v.ev / v.pv, 2)             AS spi,
       ROUND(v.ev / c.ac, 2)             AS cpi,
       CASE WHEN v.ev / v.pv < 0.8 OR v.ev / c.ac < 0.8 THEN 'crítico'
            WHEN v.ev / v.pv < 0.9 OR v.ev / c.ac < 0.9 THEN 'atenção'
            ELSE 'ok' END                AS situacao
FROM lakehouse_atlas.bronze.projetos p
JOIN valor v ON v.projeto_id = p.projeto_id
JOIN custo c ON c.projeto_id = p.projeto_id
WHERE p.status = 'em_andamento'
ORDER BY LEAST(v.ev / v.pv, v.ev / c.ac);
