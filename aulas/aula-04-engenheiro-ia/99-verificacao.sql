-- Noite 4 · Verificação
-- Confere se o agente de contratos e manual chegou nos mesmos números da aula.
-- Cada linha mostra o esperado, o obtido e se bateu. A seed é fixa (42).
-- (A gravação no Lakebase se confere com torre-app/scripts/ver_decisoes.py.)
--
-- Rode com:
--   python3 scripts/run_sql.py aulas/aula-04-engenheiro-ia/99-verificacao.sql --profile SEU-PERFIL

WITH checagens AS (
  SELECT 'contratos lidos' AS item, '8' AS esperado,
         CAST((SELECT COUNT(*) FROM lakehouse_vertice.gold.contratos_resumo) AS STRING) AS obtido
  UNION ALL
  SELECT 'cláusulas extraídas', '72',
         CAST((SELECT COUNT(*) FROM lakehouse_vertice.gold.contratos_clausulas) AS STRING)
  UNION ALL
  SELECT 'seções do manual', '10',
         CAST((SELECT COUNT(*) FROM lakehouse_vertice.gold.manual_secoes) AS STRING)
  UNION ALL
  SELECT 'multa da CodeForge: % ao dia · teto', '0.5 · 10.0',
         (SELECT concat(CAST(multa_atraso_pct_dia AS STRING), ' · ', CAST(teto_multa_pct AS STRING))
          FROM lakehouse_vertice.gold.contratos_resumo WHERE fornecedor LIKE '%CodeForge%')
  UNION ALL
  SELECT 'contrato sem renovação automática', 'QualiTest Brasil',
         (SELECT array_join(sort_array(collect_list(fornecedor)), ', ')
          FROM lakehouse_vertice.gold.contratos_resumo WHERE NOT renovacao_automatica)
  UNION ALL
  SELECT 'contratos sem multa por atraso (só SLA)', '3',
         CAST((SELECT COUNT(*) FROM lakehouse_vertice.gold.contratos_resumo WHERE multa_atraso_pct_dia IS NULL) AS STRING)
  UNION ALL
  SELECT 'multa a cobrar da CodeForge na vigência atual (R$)', '1122967.65',
         CAST((SELECT ROUND(SUM(multa_cobravel), 2) FROM lakehouse_vertice.gold.contratos_multa_fornecedor
               WHERE fornecedor LIKE '%CodeForge%' AND na_vigencia_atual) AS STRING)
  UNION ALL
  SELECT 'entregas da CodeForge atrasadas na vigência atual', '120',
         CAST((SELECT COUNT(*) FROM lakehouse_vertice.gold.contratos_multa_fornecedor
               WHERE fornecedor LIKE '%CodeForge%' AND na_vigencia_atual) AS STRING)
  UNION ALL
  SELECT 'aviso prévio já vencido', 'DataPrime Analytics, NuvemSul Cloud',
         (SELECT array_join(sort_array(collect_list(fornecedor)), ', ')
          FROM lakehouse_vertice.gold.contratos_avisos WHERE situacao_aviso = 'vencido')
  UNION ALL
  SELECT 'aviso prévio vencendo em até 60 dias', 'Observa360, QualiTest Brasil',
         (SELECT array_join(sort_array(collect_list(fornecedor)), ', ')
          FROM lakehouse_vertice.gold.contratos_avisos WHERE situacao_aviso = 'vence em até 60 dias')
  UNION ALL
  SELECT 'SREs com uso < 20% nas últimas 12 semanas', 'COL0017, COL0018',
         (SELECT array_join(sort_array(collect_list(colaborador_id)), ', ') FROM (
            SELECT colaborador_id FROM lakehouse_vertice.gold.utilizacao_pessoa_semana
            WHERE papel = 'sre' AND semana > DATE'2026-07-24'
            GROUP BY colaborador_id HAVING SUM(horas_apontadas) / SUM(horas_disponiveis) < 0.2))
  UNION ALL
  SELECT 'dias de impacto por falta de SRE no PRJ-011 (90 dias)', '57.0',
         CAST((SELECT SUM(dias_impacto) FROM lakehouse_vertice.gold.status_estruturado
               WHERE projeto_id = 'PRJ-011' AND data_status >= DATE'2026-07-18' AND causa_bloqueio = 'falta_sre') AS STRING)
)
SELECT item, esperado, obtido, CASE WHEN esperado = obtido THEN 'ok' ELSE 'CONFIRA' END AS status
FROM checagens;
