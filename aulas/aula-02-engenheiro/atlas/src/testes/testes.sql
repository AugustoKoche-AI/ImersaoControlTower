-- Testes de qualidade: rodam DEPOIS do medalhão e quebram o job se algo estiver errado.
--
-- raise_error() dentro de CASE WHEN interrompe a tarefa. Melhor o dashboard
-- ficar com o dado de ontem do que com o dado errado de hoje.
--
-- O teste mais importante é o 3: a limpeza NÃO pode mudar o custo total.
-- Se mudou, alguém jogou linha fora sem querer.

WITH testes AS (
  SELECT 1 AS n, 'uma linha por equipe na silver' AS teste,
         (SELECT COUNT(*) FROM lakehouse_atlas.silver.equipes) = (SELECT COUNT(DISTINCT equipe_id) FROM lakehouse_atlas.silver.equipes) AS passou
  UNION ALL
  SELECT 2, 'Norte Aço virou um fornecedor só',
         (SELECT COUNT(DISTINCT fornecedor) FROM lakehouse_atlas.silver.compras WHERE lower(fornecedor) LIKE '%norte%') = 1
  UNION ALL
  SELECT 3, 'a limpeza não mudou o custo total (bronze = silver)',
         (SELECT SUM(CAST(replace(valor_real, ',', '.') AS DECIMAL(18,2))) FROM lakehouse_atlas.bronze.custos)
       = (SELECT SUM(valor) FROM lakehouse_atlas.silver.custos)
  UNION ALL
  SELECT 4, 'nenhuma tarefa acima de 100%',
         (SELECT COUNT(*) FROM lakehouse_atlas.silver.tarefas WHERE pct_concluido > 100) = 0
  UNION ALL
  SELECT 5, 'as 40 obras têm fotografia de hoje',
         (SELECT COUNT(*) FROM lakehouse_atlas.gold.obra_situacao_atual) = 40
  UNION ALL
  SELECT 6, 'toda obra em andamento tem SPI e CPI',
         (SELECT COUNT(*) FROM lakehouse_atlas.gold.obra_situacao_atual
          WHERE status = 'em_andamento' AND (spi IS NULL OR cpi IS NULL)) = 0
  UNION ALL
  SELECT 7, 'EV de hoje bate com o % do cronograma limpo',
         (SELECT ROUND(SUM(ev)) FROM lakehouse_atlas.gold.fato_projeto_semana WHERE semana = DATE'2026-10-16')
       = (SELECT ROUND(SUM(valor_planejado * pct_concluido / 100)) FROM lakehouse_atlas.silver.tarefas)
  UNION ALL
  SELECT 8, 'custo acumulado de hoje = soma dos lançamentos',
         (SELECT SUM(ac) FROM lakehouse_atlas.gold.fato_projeto_semana WHERE semana = DATE'2026-10-16')
       = (SELECT SUM(valor) FROM lakehouse_atlas.silver.custos WHERE data <= DATE'2026-10-16')
)
SELECT n, teste,
       CASE WHEN passou THEN 'ok' ELSE raise_error(concat('Teste ', n, ' falhou: ', teste)) END AS status
FROM testes
ORDER BY n;
