-- Projetos em andamento, do pior para o melhor, com tudo que o dono precisa
-- para decidir numa linha: SPI, CPI, estouro, atraso, farol do gerente x número,
-- a causa que mais aparece no status semanal (90 dias, extraída por IA), os dias
-- de impacto por falta de SRE e por rotatividade (o que o simulador usa), a
-- ruptura de capacidade e a multa que dá para cobrar de fornecedor atrasado.
WITH causa AS (
  SELECT projeto_id, causa_bloqueio, COUNT(*) AS semanas, SUM(coalesce(dias_impacto, 0)) AS dias
  FROM lakehouse_vertice.gold.status_estruturado
  WHERE data_status >= DATE'2026-07-18' AND causa_bloqueio NOT IN ('sem_bloqueio', 'nao_reportado')
  GROUP BY projeto_id, causa_bloqueio
),
principal AS (
  SELECT projeto_id, max_by(causa_bloqueio, semanas) AS causa_principal,
         SUM(dias) FILTER (WHERE causa_bloqueio = 'falta_sre')    AS dias_falta_sre,
         SUM(dias) FILTER (WHERE causa_bloqueio = 'rotatividade') AS dias_rotatividade
  FROM causa GROUP BY projeto_id
),
capacidade AS (
  SELECT projeto_id, COUNT_IF(ruptura_prevista) AS rupturas_capacidade
  FROM lakehouse_vertice.gold.cobertura_capacidade GROUP BY projeto_id
),
multa AS (
  SELECT projeto_id, SUM(multa_cobravel) AS multa_a_cobrar
  FROM lakehouse_vertice.gold.contratos_multa_fornecedor WHERE na_vigencia_atual GROUP BY projeto_id
)
SELECT p.projeto_id, p.projeto, p.cliente, p.ferramenta, p.situacao,
       ROUND(p.spi, 2) AS spi, ROUND(p.cpi, 2) AS cpi,
       p.estouro_previsto, p.margem_projetada, p.atraso_projetado_dias,
       p.farol_do_gerente, p.farol_calculado, p.melancia,
       coalesce(c.causa_principal, 'sem_bloqueio') AS causa_principal,
       coalesce(c.dias_falta_sre, 0)               AS dias_falta_sre,
       coalesce(c.dias_rotatividade, 0)            AS dias_rotatividade,
       coalesce(k.rupturas_capacidade, 0)          AS rupturas_capacidade,
       coalesce(m.multa_a_cobrar, 0)               AS multa_a_cobrar
FROM lakehouse_vertice.gold.projeto_situacao_atual p
LEFT JOIN principal c USING (projeto_id)
LEFT JOIN capacidade k USING (projeto_id)
LEFT JOIN multa m USING (projeto_id)
WHERE p.status = 'em_andamento'
ORDER BY CASE p.situacao WHEN 'crítico' THEN 0 WHEN 'atenção' THEN 1 ELSE 2 END, least(p.spi, p.cpi)
