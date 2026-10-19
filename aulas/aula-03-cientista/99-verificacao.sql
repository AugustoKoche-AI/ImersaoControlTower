-- Noite 3 · Verificação: esperado × obtido
-- Rode com:  python3 scripts/run_sql.py aulas/aula-03-cientista/99-verificacao.sql --profile SEU-PERFIL
-- Seed fixa (42) e random_state=42: os números se repetem. "CONFIRA" = algo diferente do ensaio de 18/10.

WITH m AS (SELECT * FROM lakehouse_vertice.gold.modelo_metricas),
s AS (SELECT * FROM lakehouse_vertice.gold.score_estouro_30d),
f AS (SELECT * FROM lakehouse_vertice.gold.features_projeto_semana),
p AS (SELECT * FROM lakehouse_vertice.gold.projeto_situacao_atual),
checagens AS (
  SELECT 'features: linhas' AS item, '4235' AS esperado, CAST(COUNT(*) AS STRING) AS obtido FROM f UNION ALL
  SELECT 'features: linhas de treino (elegível com rótulo)', '1643', CAST(COUNT_IF(elegivel = 1 AND estoura_30d IS NOT NULL) AS STRING) FROM f UNION ALL
  SELECT 'features: taxa base', '0.167', CAST(ROUND(AVG(CASE WHEN elegivel = 1 THEN estoura_30d END), 3) AS STRING) FROM f UNION ALL
  SELECT 'features: nenhum alvo preenchido hoje', '0', CAST(COUNT_IF(semana = DATE'2026-10-16' AND alvo_pior_indice_30d IS NOT NULL) AS STRING) FROM f UNION ALL
  SELECT 'modelo: AUC (2 casas)', '0.92', CAST(ROUND(auc, 2) AS STRING) FROM m UNION ALL
  SELECT 'modelo: AUC da regra da folga (2 casas)', '0.87', CAST(ROUND(auc_baseline_folga, 2) AS STRING) FROM m UNION ALL
  SELECT 'modelo: ganha da regra da folga', 'true', CAST(auc >= auc_baseline_folga AS STRING) FROM m UNION ALL
  SELECT 'modelo: AUC abaixo de 0,98 (sem vazamento)', 'true', CAST(auc < 0.98 AS STRING) FROM m UNION ALL
  SELECT 'modelo: estouros avisados no top 5', '9 de 10', estouros_avisados || ' de ' || estouros_teste FROM m UNION ALL
  SELECT 'modelo: antecedência média (dias, arredondado)', '40', CAST(CAST(ROUND(antecedencia_media_dias) AS INT) AS STRING) FROM m UNION ALL
  SELECT 'score: uma linha por projeto em andamento', '41', CAST(COUNT(*) AS STRING) FROM s UNION ALL
  SELECT 'score: data de referência', '2026-10-16', CAST(MAX(data_referencia) AS STRING) FROM s UNION ALL
  SELECT 'score: faixa alto · medio · baixo', '18 · 4 · 19',
         COUNT_IF(faixa_risco = 'alto') || ' · ' || COUNT_IF(faixa_risco = 'medio') || ' · ' || COUNT_IF(faixa_risco = 'baixo') FROM s UNION ALL
  SELECT 'score: todo projeto crítico ou em atenção com prob 1,0', '17',
         CAST((SELECT COUNT(*) FROM s s2 JOIN p USING (projeto_id)
               WHERE p.situacao IN ('crítico', 'atenção') AND s2.prob_estouro_30d = 1.0) AS STRING) UNION ALL
  SELECT 'score: projetos ok para a regra com risco alto ou médio', '5',
         CAST((SELECT COUNT(*) FROM s s3 JOIN p USING (projeto_id)
               WHERE p.situacao = 'ok' AND s3.faixa_risco IN ('alto', 'medio')) AS STRING) UNION ALL
  SELECT 'score: probabilidade do PRJ-024 (2 casas)', '0.49',
         CAST((SELECT ROUND(prob_estouro_30d, 2) FROM s WHERE projeto_id = 'PRJ-024') AS STRING) UNION ALL
  SELECT 'score: nenhum motivo vazio', '0', CAST(COUNT_IF(principais_fatores IS NULL OR principais_fatores = '') AS STRING) FROM s
)
SELECT item, esperado, obtido, CASE WHEN esperado = obtido THEN 'ok' ELSE 'CONFIRA' END AS status FROM checagens;
