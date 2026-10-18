-- Noite 2 · Verificação
-- Confere se o seu pipeline chegou nos mesmos números da aula.
-- Cada linha mostra o esperado, o obtido e se bateu. Seed fixa (42): se algo der
-- "CONFIRA", o problema está no código, não no dado.
--
-- Rode com:
--   python3 scripts/run_sql.py aulas/aula-02-engenheiro/prd/99-verificacao.sql --profile SEU-PERFIL

WITH v AS (
  -- silver: a limpeza fez o que prometeu
  SELECT 1 AS n, 'equipes únicas (123 linhas no RH → 120)' AS item, 120 AS esperado,
         (SELECT COUNT(*) FROM lakehouse_atlas.silver.equipes) AS obtido
  UNION ALL SELECT 2, 'grafias da Norte Aço que viraram 1 fornecedor', 4,
         (SELECT COUNT(DISTINCT fornecedor_como_veio) FROM lakehouse_atlas.silver.compras WHERE fornecedor = 'Metalúrgica Norte Aço Ltda')
  UNION ALL SELECT 3, 'datas de início em formato BR convertidas', 11,
         (SELECT COUNT_IF(data_veio_em_formato_br) FROM lakehouse_atlas.silver.projetos)
  UNION ALL SELECT 4, 'tarefas >100% corrigidas pela medição', 52,
         (SELECT COUNT_IF(pct_corrigido_pela_medicao) FROM lakehouse_atlas.silver.tarefas)
  UNION ALL SELECT 5, 'custos com vírgula decimal recuperados', 540,
         (SELECT COUNT_IF(valor_veio_com_virgula) FROM lakehouse_atlas.silver.custos)
  UNION ALL SELECT 6, 'custo real total (R$ mi) — igual à noite 1', 573,
         (SELECT CAST(ROUND(SUM(valor) / 1e6) AS INT) FROM lakehouse_atlas.silver.custos)
  -- gold: as três perguntas
  UNION ALL SELECT 7, 'obras críticas (SPI ou CPI < 0,8)', 7,
         (SELECT COUNT(*) FROM lakehouse_atlas.gold.obra_situacao_atual WHERE situacao = 'crítico')
  UNION ALL SELECT 8, 'obras em atenção', 6,
         (SELECT COUNT(*) FROM lakehouse_atlas.gold.obra_situacao_atual WHERE situacao = 'atenção')
  UNION ALL SELECT 9, 'estouro previsto (R$ mil) — noite 1 dava 41.9xx', 42365,
         (SELECT CAST(ROUND(SUM(estouro_previsto) / 1e3) AS INT) FROM lakehouse_atlas.gold.obra_situacao_atual WHERE status = 'em_andamento')
  UNION ALL SELECT 10, 'rupturas de estoque previstas hoje', 97,
         (SELECT COUNT_IF(ruptura_prevista) FROM lakehouse_atlas.gold.cobertura_estoque)
  UNION ALL SELECT 11, 'pedidos de compra em atraso hoje', 27,
         (SELECT COUNT(*) FROM lakehouse_atlas.gold.pedidos_em_atraso)
  UNION ALL SELECT 12, 'Norte Aço: lead time real ÷ prometido (×100)', 141,
         (SELECT CAST(ROUND(fator_atraso * 100) AS INT) FROM lakehouse_atlas.gold.desempenho_fornecedor WHERE fornecedor = 'Metalúrgica Norte Aço Ltda')
  UNION ALL SELECT 13, 'guindastes < 20% de uso nas últimas 12 semanas', 2,
         (SELECT COUNT(*) FROM (SELECT equipamento_id FROM lakehouse_atlas.gold.utilizacao_equipamento_semana
                                WHERE tipo = 'guindaste' AND semana > DATE'2026-07-24'
                                GROUP BY equipamento_id HAVING SUM(horas_operadas) / SUM(horas_disponiveis) < 0.2))
  -- IA e métricas
  UNION ALL SELECT 14, 'RDOs estruturados (todos)', 13730,
         (SELECT COUNT(*) FROM lakehouse_atlas.gold.rdo_estruturado)
  UNION ALL SELECT 15, 'RDOs da P011 com falta de equipamento (90 dias)', 37,
         (SELECT COUNT(*) FROM lakehouse_atlas.gold.rdo_estruturado
          WHERE projeto_id = 'P011' AND data >= DATE'2026-07-18' AND causa_atraso = 'falta_equipamento')
  UNION ALL SELECT 16, 'metric views criadas (mv_*)', 5,
         (SELECT COUNT(*) FROM lakehouse_atlas.information_schema.tables
          WHERE table_schema = 'gold' AND table_name LIKE 'mv\_%' AND table_type = 'METRIC_VIEW')
  UNION ALL SELECT 17, 'obras críticas pela metric view', 7,
         (SELECT CAST(MEASURE(obras_criticas) AS INT) FROM lakehouse_atlas.gold.mv_obras)
)
SELECT n, item, esperado, obtido, CASE WHEN esperado = obtido THEN 'ok' ELSE 'CONFIRA' END AS status
FROM v ORDER BY n;
