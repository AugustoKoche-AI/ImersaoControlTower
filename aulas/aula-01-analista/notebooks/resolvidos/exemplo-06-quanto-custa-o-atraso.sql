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

WITH tarefas AS (
    SELECT projeto_id,
           CAST(valor_planejado AS DECIMAL(18,2))          AS vp,
           LEAST(CAST(pct_concluido AS DOUBLE), 100) / 100 AS pct,
           GREATEST(0, LEAST(1,
               datediff(DATE'2026-10-16', CAST(inicio_baseline AS DATE))
               / datediff(CAST(fim_baseline AS DATE), CAST(inicio_baseline AS DATE)))) AS pct_planejado
    FROM lakehouse_atlas.bronze.tarefas
),
valor AS (
    SELECT projeto_id, SUM(vp * pct_planejado) AS pv, SUM(vp * pct) AS ev
    FROM tarefas GROUP BY projeto_id
),
custo AS (
    SELECT projeto_id, SUM(CAST(replace(valor_real, ',', '.') AS DECIMAL(18,2))) AS ac
    FROM lakehouse_atlas.bronze.custos GROUP BY projeto_id
),
obra AS (
    SELECT p.projeto_id, p.nome_projeto, p.cliente,
           CAST(p.valor_contrato  AS DECIMAL(18,2)) AS valor_contrato,
           CAST(p.orcamento_custo AS DECIMAL(18,2)) AS orcamento,
           -- a data de início vem em dois formatos: tenta um, depois o outro
           datediff(CAST(p.data_fim_baseline AS DATE),
                    coalesce(try_to_date(p.data_inicio, 'yyyy-MM-dd'),
                             try_to_date(p.data_inicio, 'dd/MM/yyyy'))) AS duracao_dias,
           v.ev / v.pv AS spi,
           v.ev / c.ac AS cpi
    FROM lakehouse_atlas.bronze.projetos p
    JOIN valor v USING (projeto_id)
    JOIN custo c USING (projeto_id)
    WHERE p.status = 'em_andamento'
)
SELECT projeto_id, nome_projeto, cliente,
       ROUND(cpi, 2)                                               AS cpi,
       ROUND(orcamento / cpi / 1e6, 1)                             AS eac_milhoes,
       ROUND((orcamento / cpi - orcamento) / 1e6, 1)               AS estouro_milhoes,
       ROUND(100 * (valor_contrato - orcamento / cpi) / valor_contrato, 1) AS margem_projetada_pct,
       ROUND(duracao_dias / spi - duracao_dias)                    AS atraso_projetado_dias,
       ROUND(SUM(orcamento / cpi - orcamento) OVER () / 1e6, 1)    AS estouro_total_carteira_milhoes
FROM obra
ORDER BY estouro_milhoes DESC
LIMIT 15;
