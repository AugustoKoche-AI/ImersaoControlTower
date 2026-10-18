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

CREATE OR REPLACE VIEW lakehouse_vertice.bronze.rascunho_tarefas
COMMENT 'Rascunho da noite 1: tarefas do Excel, ClickUp e MS Project empilhadas à mão. Na noite 2 vira silver.tarefas.'
AS
-- Excel: data em texto OU número de série; % em texto OU fração; e a linha de TOTAL
SELECT regexp_extract(arquivo, 'PRJ-[0-9]{3}', 0)                         AS projeto_id,
       'excel'                                                            AS ferramenta,
       tarefa,
       CASE WHEN inicio_previsto LIKE '%/%' THEN to_date(inicio_previsto, 'dd/MM/yyyy')
            ELSE date_add(DATE'1899-12-30', CAST(inicio_previsto AS INT)) END   AS inicio_baseline,
       CASE WHEN termino_previsto LIKE '%/%' THEN to_date(termino_previsto, 'dd/MM/yyyy')
            ELSE date_add(DATE'1899-12-30', CAST(termino_previsto AS INT)) END  AS fim_baseline,
       LEAST(100, CASE WHEN pct_concluido LIKE '%\%%'
                       THEN CAST(replace(replace(pct_concluido, '%', ''), ',', '.') AS DOUBLE)
                       ELSE CAST(pct_concluido AS DOUBLE) * 100 END)      AS pct_concluido,
       CAST(replace(horas_previstas, 'h', '') AS DOUBLE)                  AS horas
FROM lakehouse_vertice.bronze.excel_tarefas
WHERE tarefa <> 'TOTAL'

UNION ALL
-- ClickUp: o projeto vem do cadastro do PMO (pelo código da lista, ou pelo nome quando o código falta);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC datas em milissegundos; % e baseline dentro da lista de campos personalizados

-- COMMAND ----------

SELECT p.projeto_id,
       'clickup',
       c.name,
       to_date(timestamp_millis(CAST(filter(c.custom_fields, f -> f.name = 'Início baseline')[0].value AS BIGINT))),
       to_date(timestamp_millis(CAST(filter(c.custom_fields, f -> f.name = 'Fim baseline')[0].value AS BIGINT))),
       CAST(filter(c.custom_fields, f -> f.name = 'Progresso (%)')[0].value AS DOUBLE),
       c.time_estimate / 3600000                                           -- milissegundos → horas
FROM lakehouse_vertice.bronze.clickup_tarefas c
JOIN lakehouse_vertice.bronze.projetos p
  ON p.codigo_ferramenta = c.list_id OR p.nome_projeto = c.list_name

UNION ALL
-- MS Project: só as tarefas de verdade (sem as tarefas-resumo); horas em 'PT40H0M0S'
SELECT regexp_extract(arquivo, 'PRJ-[0-9]{3}', 0),
       'msproject',
       Name,
       to_date(Baseline.Start),
       to_date(Baseline.Finish),
       CAST(PercentComplete AS DOUBLE),
       CAST(regexp_extract(Work, 'PT([0-9]+)H', 1) AS DOUBLE)
FROM lakehouse_vertice.bronze.msproject_tarefas
WHERE Summary = 0;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Conferência: 60 projetos, cada um numa ferramenta

-- COMMAND ----------

SELECT ferramenta, COUNT(DISTINCT projeto_id) AS projetos, COUNT(*) AS tarefas
FROM lakehouse_vertice.bronze.rascunho_tarefas
GROUP BY ferramenta;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. A resposta: SPI de cada projeto em andamento, do mais atrasado para o menos

-- COMMAND ----------

WITH valor AS (
    SELECT projeto_id,
           ferramenta,
           SUM(horas * pct_concluido / 100) AS horas_agregadas,
           SUM(horas * GREATEST(0, LEAST(1,
               datediff(DATE'2026-10-16', inicio_baseline) / datediff(fim_baseline, inicio_baseline)
           )))                               AS horas_planejadas
    FROM lakehouse_vertice.bronze.rascunho_tarefas
    GROUP BY projeto_id, ferramenta
)
SELECT p.projeto_id,
       p.nome_projeto,
       v.ferramenta,
       ROUND(v.horas_agregadas / v.horas_planejadas, 2) AS spi,
       CASE WHEN v.horas_agregadas / v.horas_planejadas < 0.8 THEN 'crítico'
            WHEN v.horas_agregadas / v.horas_planejadas < 0.9 THEN 'atenção'
            ELSE 'ok' END                               AS situacao_prazo
FROM lakehouse_vertice.bronze.projetos p
JOIN valor v USING (projeto_id)
WHERE p.status = 'em_andamento'
ORDER BY spi;
