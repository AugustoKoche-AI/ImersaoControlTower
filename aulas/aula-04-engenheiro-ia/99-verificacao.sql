-- Noite 4 · Verificação
-- Confere o agente de contratos e a base do app. Cada linha: esperado, obtido, status.
-- (A gravação no Lakebase é conferida à parte: torre-app/scripts/ver_decisoes.py.)
--
-- Rode com:
--   python3 scripts/run_sql.py aulas/aula-04-engenheiro-ia/99-verificacao.sql --profile SEU-PERFIL

WITH checagens AS (
  SELECT 'contratos lidos (PDF → texto)' AS item, '8' AS esperado,
         CAST((SELECT COUNT(*) FROM lakehouse_atlas.gold.contratos_texto WHERE length(texto) > 1000) AS STRING) AS obtido
  UNION ALL
  SELECT 'cláusulas (11 por contrato)', '88',
         CAST((SELECT COUNT(*) FROM lakehouse_atlas.gold.contratos_clausulas) AS STRING)
  UNION ALL
  SELECT 'contratos em que chuva dá prorrogação', 'P002,P011,P014',
         (SELECT concat_ws(',', sort_array(collect_list(projeto_id))) FROM lakehouse_atlas.gold.contratos_resumo WHERE chuva_da_prorrogacao)
  UNION ALL
  SELECT 'içamento por conta do cliente', 'P005',
         (SELECT concat_ws(',', sort_array(collect_list(projeto_id))) FROM lakehouse_atlas.gold.contratos_resumo WHERE icamento_responsavel = 'contratante')
  UNION ALL
  SELECT 'bônus por antecipação', 'P018,P033',
         (SELECT concat_ws(',', sort_array(collect_list(projeto_id))) FROM lakehouse_atlas.gold.contratos_resumo WHERE bonus_antecipacao)
  UNION ALL
  SELECT 'prazo para pleitear aditivo = 30 dias em todos', '8',
         CAST((SELECT COUNT(*) FROM lakehouse_atlas.gold.contratos_resumo WHERE prazo_aditivo_dias = 30) AS STRING)
  UNION ALL
  SELECT 'multa estimada P011 (R$)', '1876298.00',
         CAST((SELECT multa_estimada FROM lakehouse_atlas.gold.contratos_exposicao WHERE projeto_id = 'P011') AS STRING)
  UNION ALL
  SELECT 'obra com multa no teto', 'P005',
         (SELECT concat_ws(',', sort_array(collect_list(projeto_id))) FROM lakehouse_atlas.gold.contratos_exposicao WHERE multa_no_teto)
  UNION ALL
  SELECT 'soma das multas estimadas (R$ mi)', '6.97',
         CAST((SELECT ROUND(SUM(multa_estimada) / 1e6, 2) FROM lakehouse_atlas.gold.contratos_exposicao) AS STRING)
  UNION ALL
  SELECT 'obras em risco (atenção + crítico)', '13',
         CAST((SELECT COUNT(*) FROM lakehouse_atlas.gold.obra_situacao_atual WHERE status = 'em_andamento' AND situacao IN ('crítico', 'atenção')) AS STRING)
  UNION ALL
  SELECT 'guindastes ociosos (< 20%, 12 semanas)', 'EQ0017,EQ0018',
         (SELECT concat_ws(',', sort_array(collect_list(equipamento_id))) FROM (
            SELECT equipamento_id FROM lakehouse_atlas.gold.utilizacao_equipamento_semana
            WHERE tipo = 'guindaste' AND semana > DATE'2026-07-24' GROUP BY equipamento_id HAVING AVG(utilizacao) < 0.2))
)
SELECT item, esperado, obtido, CASE WHEN esperado = obtido THEN 'ok' ELSE 'CONFIRA' END AS status
FROM checagens
