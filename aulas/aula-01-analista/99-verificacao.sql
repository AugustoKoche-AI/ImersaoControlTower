-- Noite 1 · Verificação
-- Confere se o seu ambiente chegou nos mesmos números da aula.
-- Cada linha mostra o esperado, o obtido e se bateu. Se algo der "CONFIRA",
-- o problema está no upload ou na query, não no dado: a seed é fixa (42).
--
-- Rode com:
--   python3 scripts/run_sql.py aulas/aula-01-analista/99-verificacao.sql --profile SEU-PERFIL

WITH contagens AS (
    SELECT 'linhas em projetos'        AS item, 40      AS esperado, (SELECT COUNT(*) FROM lakehouse_atlas.bronze.projetos)         AS obtido UNION ALL
    SELECT 'linhas em tarefas',                 8000,    (SELECT COUNT(*) FROM lakehouse_atlas.bronze.tarefas)          UNION ALL
    SELECT 'linhas em avanco_semanal',          55703,   (SELECT COUNT(*) FROM lakehouse_atlas.bronze.avanco_semanal)   UNION ALL
    SELECT 'linhas em custos',                  19445,   (SELECT COUNT(*) FROM lakehouse_atlas.bronze.custos)           UNION ALL
    SELECT 'linhas em compras',                 13304,   (SELECT COUNT(*) FROM lakehouse_atlas.bronze.compras)          UNION ALL
    SELECT 'linhas em materiais',               25,      (SELECT COUNT(*) FROM lakehouse_atlas.bronze.materiais)        UNION ALL
    SELECT 'linhas em estoque',                 40094,   (SELECT COUNT(*) FROM lakehouse_atlas.bronze.estoque)          UNION ALL
    SELECT 'linhas em equipes',                 123,     (SELECT COUNT(*) FROM lakehouse_atlas.bronze.equipes)          UNION ALL
    SELECT 'linhas em apontamentos',            41190,   (SELECT COUNT(*) FROM lakehouse_atlas.bronze.apontamentos)     UNION ALL
    SELECT 'linhas em equipamentos',            300,     (SELECT COUNT(*) FROM lakehouse_atlas.bronze.equipamentos)     UNION ALL
    SELECT 'linhas em uso_equipamentos',        19817,   (SELECT COUNT(*) FROM lakehouse_atlas.bronze.uso_equipamentos) UNION ALL
    SELECT 'linhas em rdo',                     13730,   (SELECT COUNT(*) FROM lakehouse_atlas.bronze.rdo)              UNION ALL
    SELECT 'custos com vírgula decimal',        540,     (SELECT COUNT(*) FROM lakehouse_atlas.bronze.custos WHERE valor_real LIKE '%,%') UNION ALL
    SELECT 'carteira (R$ mi, arredondado)',     903,     (SELECT CAST(ROUND(SUM(CAST(valor_contrato AS DECIMAL(18,2))) / 1e6) AS INT) FROM lakehouse_atlas.bronze.projetos) UNION ALL
    SELECT 'custo real total (R$ mi)',          573,     (SELECT CAST(ROUND(SUM(CAST(replace(valor_real, ',', '.') AS DECIMAL(18,2))) / 1e6) AS INT) FROM lakehouse_atlas.bronze.custos)
),
kpi AS (
    SELECT p.projeto_id,
           SUM(CAST(t.valor_planejado AS DECIMAL(18,2)) * LEAST(CAST(t.pct_concluido AS DOUBLE), 100) / 100) AS ev,
           SUM(CAST(t.valor_planejado AS DECIMAL(18,2)) * GREATEST(0, LEAST(1,
               datediff(DATE'2026-10-16', CAST(t.inicio_baseline AS DATE))
               / datediff(CAST(t.fim_baseline AS DATE), CAST(t.inicio_baseline AS DATE))))) AS pv
    FROM lakehouse_atlas.bronze.projetos p
    JOIN lakehouse_atlas.bronze.tarefas t USING (projeto_id)
    WHERE p.status = 'em_andamento'
    GROUP BY p.projeto_id
),
ac AS (
    SELECT projeto_id, SUM(CAST(replace(valor_real, ',', '.') AS DECIMAL(18,2))) AS ac
    FROM lakehouse_atlas.bronze.custos GROUP BY projeto_id
),
resumo AS (
    SELECT 'obras em andamento' AS item, 36 AS esperado, COUNT(*) AS obtido FROM kpi UNION ALL
    SELECT 'obras críticas (SPI ou CPI < 0,8)', 7,
           COUNT(*) FILTER (WHERE k.ev / k.pv < 0.8 OR k.ev / a.ac < 0.8) FROM kpi k JOIN ac a USING (projeto_id) UNION ALL
    SELECT 'obras em atenção (< 0,9, sem crítico)', 6,
           COUNT(*) FILTER (WHERE (k.ev / k.pv < 0.9 OR k.ev / a.ac < 0.9)
                              AND NOT (k.ev / k.pv < 0.8 OR k.ev / a.ac < 0.8)) FROM kpi k JOIN ac a USING (projeto_id)
)
SELECT item, esperado, obtido, CASE WHEN esperado = obtido THEN 'ok' ELSE 'CONFIRA' END AS status
FROM (SELECT * FROM contagens UNION ALL SELECT * FROM resumo);
