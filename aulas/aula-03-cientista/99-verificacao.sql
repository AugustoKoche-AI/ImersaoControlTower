-- Noite 3 · Verificação: esperado × obtido
-- Rode com:  python3 scripts/run_sql.py aulas/aula-03-cientista/99-verificacao.sql --profile SEU-PERFIL
-- Seed fixa (42) e random_state=42: os números se repetem. "CONFIRA" = algo diferente do ensaio de 18/10.

WITH m AS (SELECT * FROM lakehouse_atlas.gold.modelo_metricas),
s AS (SELECT * FROM lakehouse_atlas.gold.score_estouro_30d),
f AS (SELECT * FROM lakehouse_atlas.gold.features_obra_semana),
checagens AS (
  SELECT 'features: linhas' AS item, '2874' AS esperado, CAST(COUNT(*) AS STRING) AS obtido FROM f UNION ALL
  SELECT 'features: linhas de treino (elegível com rótulo)', '1535', CAST(COUNT_IF(elegivel = 1 AND estoura_30d IS NOT NULL) AS STRING) FROM f UNION ALL
  SELECT 'features: taxa base', '0.084', CAST(ROUND(AVG(CASE WHEN elegivel = 1 THEN estoura_30d END), 3) AS STRING) FROM f UNION ALL
  SELECT 'features: nenhum alvo preenchido hoje', '0', CAST(COUNT_IF(semana = DATE'2026-10-16' AND alvo_pior_indice_30d IS NOT NULL) AS STRING) FROM f UNION ALL
  SELECT 'modelo: AUC (2 casas)', '0.97', CAST(ROUND(auc, 2) AS STRING) FROM m UNION ALL
  SELECT 'modelo: ganha da regra da folga', 'true', CAST(auc >= auc_baseline_folga AS STRING) FROM m UNION ALL
  SELECT 'modelo: AUC abaixo de 0,995 (sem vazamento)', 'true', CAST(auc < 0.995 AS STRING) FROM m UNION ALL
  SELECT 'modelo: estouros avisados no top 5', '6 de 7', estouros_avisados || ' de ' || estouros_teste FROM m UNION ALL
  SELECT 'modelo: antecedência média (dias, arredondado)', '46', CAST(CAST(ROUND(antecedencia_media_dias) AS INT) AS STRING) FROM m UNION ALL
  SELECT 'score: uma linha por obra em andamento', '36', CAST(COUNT(*) AS STRING) FROM s UNION ALL
  SELECT 'score: data de referência', '2026-10-16', CAST(MAX(data_referencia) AS STRING) FROM s UNION ALL
  SELECT 'score: faixa alto · medio · baixo', '13 · 1 · 22',
         COUNT_IF(faixa_risco = 'alto') || ' · ' || COUNT_IF(faixa_risco = 'medio') || ' · ' || COUNT_IF(faixa_risco = 'baixo') FROM s UNION ALL
  SELECT 'score: obra mais arriscada que a regra ainda chama de ok', 'P034',
         (SELECT s2.projeto_id FROM s s2 JOIN lakehouse_atlas.gold.obra_situacao_atual o USING (projeto_id)
          WHERE o.situacao = 'ok' ORDER BY s2.ranking LIMIT 1) UNION ALL
  SELECT 'score: toda obra crítica ou em atenção com prob 1,0', '13',
         CAST((SELECT COUNT(*) FROM s s3 JOIN lakehouse_atlas.gold.obra_situacao_atual o USING (projeto_id)
               WHERE o.situacao IN ('crítico', 'atenção') AND s3.prob_estouro_30d = 1.0) AS STRING) UNION ALL
  SELECT 'score: nenhum motivo vazio', '0', CAST(COUNT_IF(principais_fatores IS NULL OR principais_fatores = '') AS STRING) FROM s
)
SELECT item, esperado, obtido, CASE WHEN esperado = obtido THEN 'ok' ELSE 'CONFIRA' END AS status FROM checagens;
