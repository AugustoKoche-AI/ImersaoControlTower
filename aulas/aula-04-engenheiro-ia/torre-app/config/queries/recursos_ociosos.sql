-- Gente e equipamento parado nas últimas 12 semanas (até 16/10/2026).
-- Equipamento: utilização média abaixo de 20%. Equipe: as 15 com mais horas ociosas.
-- horas_paradas_semana e custo_ocioso_semana são MÉDIAS por semana: é o que deixa
-- de ser desperdiçado em cada semana em que o recurso trabalha em outra obra.
WITH equip AS (
  SELECT 'equipamento' AS tipo_recurso, equipamento_id AS recurso_id, modelo AS descricao,
         projeto_id AS projeto_origem, obra AS obra_origem, uf,
         AVG(utilizacao) AS utilizacao_media,
         AVG(horas_paradas) AS horas_paradas_semana,
         AVG(custo_ocioso) AS custo_ocioso_semana
  FROM lakehouse_atlas.gold.utilizacao_equipamento_semana
  WHERE semana > DATE'2026-07-24'
  GROUP BY ALL
  HAVING AVG(utilizacao) < 0.2
),
equipe AS (
  SELECT 'equipe' AS tipo_recurso, u.equipe_id AS recurso_id,
         concat(u.funcao, ' · ', MAX(u.headcount), ' pessoas') AS descricao,
         u.projeto_id AS projeto_origem, u.obra AS obra_origem, u.uf,
         SUM(u.horas_apontadas) / SUM(u.horas_disponiveis) AS utilizacao_media,
         SUM(u.horas_ociosas) / COUNT(DISTINCT u.semana) AS horas_paradas_semana,
         SUM(u.horas_ociosas) / COUNT(DISTINCT u.semana) * MAX(e.custo_hora) AS custo_ocioso_semana
  FROM lakehouse_atlas.gold.utilizacao_equipe_semana u
  JOIN lakehouse_atlas.silver.equipes e USING (equipe_id)
  WHERE u.semana > DATE'2026-07-24'
  GROUP BY u.equipe_id, u.funcao, u.projeto_id, u.obra, u.uf
  ORDER BY horas_paradas_semana DESC
  LIMIT 15
)
SELECT tipo_recurso, recurso_id, descricao, projeto_origem, obra_origem, uf,
       ROUND(utilizacao_media, 3) AS utilizacao_media,
       ROUND(horas_paradas_semana, 1) AS horas_paradas_semana,
       ROUND(custo_ocioso_semana, 2) AS custo_ocioso_semana
FROM (SELECT * FROM equip UNION ALL SELECT * FROM equipe)
ORDER BY tipo_recurso, utilizacao_media
