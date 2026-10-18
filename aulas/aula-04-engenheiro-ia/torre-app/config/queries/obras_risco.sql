-- Obras em andamento, da pior para a melhor, com tudo que a diretoria precisa
-- para decidir numa linha: SPI, CPI, estouro, atraso, a causa que mais aparece
-- no RDO (90 dias) e a multa contratual estimada (só obras com contrato digitalizado).
WITH causa AS (
  SELECT projeto_id, causa_atraso, COUNT(*) AS rdos, SUM(coalesce(dias_impacto, 0)) AS dias
  FROM lakehouse_atlas.gold.rdo_estruturado
  WHERE data >= DATE'2026-07-18' AND causa_atraso NOT IN ('sem_ocorrencia', 'nao_reportado')
  GROUP BY projeto_id, causa_atraso
),
principal AS (
  SELECT projeto_id, max_by(causa_atraso, rdos) AS causa_principal,
         SUM(dias) FILTER (WHERE causa_atraso = 'falta_equipamento') AS dias_falta_equipamento,
         SUM(dias) FILTER (WHERE causa_atraso = 'mao_de_obra')       AS dias_falta_mao_de_obra
  FROM causa GROUP BY projeto_id
)
SELECT o.projeto_id, o.obra, o.cliente, o.uf, o.situacao,
       ROUND(o.spi, 2) AS spi, ROUND(o.cpi, 2) AS cpi,
       o.estouro_previsto, o.margem_projetada, o.atraso_projetado_dias, o.rupturas_previstas,
       o.valor_contrato,
       coalesce(p.causa_principal, 'sem_ocorrencia')  AS causa_principal,
       coalesce(p.dias_falta_equipamento, 0)          AS dias_falta_equipamento,
       coalesce(p.dias_falta_mao_de_obra, 0)          AS dias_falta_mao_de_obra,
       e.multa_dia_pct, e.multa_estimada, e.icamento_responsavel, e.chuva_da_prorrogacao
FROM lakehouse_atlas.gold.obra_situacao_atual o
LEFT JOIN principal p USING (projeto_id)
LEFT JOIN lakehouse_atlas.gold.contratos_exposicao e USING (projeto_id)
WHERE o.status = 'em_andamento'
ORDER BY CASE o.situacao WHEN 'crítico' THEN 0 WHEN 'atenção' THEN 1 ELSE 2 END, least(o.spi, o.cpi)
