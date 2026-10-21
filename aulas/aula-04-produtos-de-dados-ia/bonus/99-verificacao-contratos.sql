-- Bônus da noite 4 · Verificação do agente de contratos
-- Confere se o agente de contratos chegou nos mesmos números da aula.
-- Cada linha mostra o esperado, o obtido e se bateu. A seed é fixa (42).
-- (A gravação no Lakebase se confere com torre-app/scripts/ver_decisoes.py.)
--
-- Rode com:
--   python3 scripts/run_sql.py aulas/aula-04-produtos-de-dados-ia/bonus/99-verificacao-contratos.sql --profile SEU-PERFIL

WITH multa AS (   -- a mesma conta do 01-contratos.sql (passo 4a) e do Genie
  SELECT e.fornecedor, e.valor * least(CASE WHEN e.data_entrega IS NOT NULL THEN e.dias_de_atraso_na_entrega
                                            ELSE datediff(DATE'2026-10-16', e.data_prometida) END * c.multa_atraso_pct_dia,
                                       c.teto_multa_pct) / 100 AS multa_cobravel
  FROM lakehouse_vertice.silver.entregas_fornecedor e
  JOIN lakehouse_vertice.gold.contratos c ON lower(c.fornecedor) = lower(e.fornecedor)
  WHERE c.multa_atraso_pct_dia IS NOT NULL
    AND ((e.data_entrega IS NOT NULL AND e.dias_de_atraso_na_entrega > 0) OR e.em_atraso)
    AND e.data_prometida > add_months(c.data_fim_vigencia, -12)
),
avisos AS (
  SELECT fornecedor, datediff(date_sub(data_fim_vigencia, aviso_previo_dias), DATE'2026-10-16') AS dias_ate_limite
  FROM lakehouse_vertice.gold.contratos
),
checagens AS (
  SELECT 'contratos lidos' AS item, '8' AS esperado,
         CAST((SELECT COUNT(*) FROM lakehouse_vertice.gold.contratos) AS STRING) AS obtido
  UNION ALL
  SELECT 'cláusulas extraídas', '72',
         CAST((SELECT COUNT(*) FROM lakehouse_vertice.silver.contratos_clausulas) AS STRING)
  UNION ALL
  SELECT 'multa da CodeForge: % ao dia · teto', '0.5 · 10.0',
         (SELECT concat(CAST(multa_atraso_pct_dia AS STRING), ' · ', CAST(teto_multa_pct AS STRING))
          FROM lakehouse_vertice.gold.contratos WHERE fornecedor LIKE '%CodeForge%')
  UNION ALL
  SELECT 'contrato sem renovação automática', 'QualiTest Brasil',
         (SELECT array_join(sort_array(collect_list(fornecedor)), ', ')
          FROM lakehouse_vertice.gold.contratos WHERE NOT renovacao_automatica)
  UNION ALL
  SELECT 'contratos sem multa por atraso (só SLA)', '3',
         CAST((SELECT COUNT(*) FROM lakehouse_vertice.gold.contratos WHERE multa_atraso_pct_dia IS NULL) AS STRING)
  UNION ALL
  SELECT 'multa a cobrar da CodeForge na vigência atual (R$)', '1122967.66',
         CAST((SELECT ROUND(SUM(multa_cobravel), 2) FROM multa WHERE fornecedor LIKE '%CodeForge%') AS STRING)
  UNION ALL
  SELECT 'entregas da CodeForge atrasadas na vigência atual', '120',
         CAST((SELECT COUNT(*) FROM multa WHERE fornecedor LIKE '%CodeForge%') AS STRING)
  UNION ALL
  SELECT 'aviso prévio já vencido', 'DataPrime Analytics, NuvemSul Cloud',
         (SELECT array_join(sort_array(collect_list(fornecedor)), ', ')
          FROM avisos WHERE dias_ate_limite < 0)
  UNION ALL
  SELECT 'aviso prévio vencendo em até 60 dias', 'Observa360, QualiTest Brasil',
         (SELECT array_join(sort_array(collect_list(fornecedor)), ', ')
          FROM avisos WHERE dias_ate_limite BETWEEN 0 AND 60)
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
