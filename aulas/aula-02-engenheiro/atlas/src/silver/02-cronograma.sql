-- silver.tarefas e silver.avanco_semanal: o cronograma e o boletim de medição.
--
-- A sujeira: 52 tarefas com pct_concluido acima de 100 (até 117%) no cronograma.
-- A tentação é cortar em 100 com LEAST(). Só que o número certo EXISTE em outro
-- sistema: o boletim de medição semanal (avanco_semanal) guarda o % medido de
-- verdade. Então a silver usa a última medição — e marca a linha corrigida.
-- Limpar bem é ir buscar a fonte confiável, não inventar um valor plausível.

CREATE OR REFRESH MATERIALIZED VIEW avanco_semanal (
  CONSTRAINT pct_entre_0_e_100 EXPECT (pct_concluido BETWEEN 0 AND 100) ON VIOLATION FAIL UPDATE
)
COMMENT 'Boletim de medição: % concluído de cada tarefa por semana (sexta-feira). Só há linha quando o % mudou.'
AS SELECT
  tarefa_id,
  projeto_id,
  CAST(data_medicao AS DATE)            AS data_medicao,
  CAST(pct_concluido AS DOUBLE)         AS pct_concluido
FROM lakehouse_atlas.bronze.avanco_semanal;

CREATE OR REFRESH MATERIALIZED VIEW tarefas (
  CONSTRAINT pct_entre_0_e_100 EXPECT (pct_concluido BETWEEN 0 AND 100) ON VIOLATION FAIL UPDATE,
  CONSTRAINT valor_planejado_positivo EXPECT (valor_planejado > 0) ON VIOLATION FAIL UPDATE,
  CONSTRAINT baseline_coerente EXPECT (fim_baseline >= inicio_baseline)
)
COMMENT 'Tarefas do cronograma com baseline e realizado. pct_concluido vem da última medição quando o cronograma traz valor acima de 100.'
AS WITH ultima_medicao AS (
  SELECT tarefa_id, max(pct_concluido) AS pct_medido      -- o % só sobe: a maior medição é a última
  FROM avanco_semanal
  GROUP BY tarefa_id
)
SELECT
  t.tarefa_id,
  t.projeto_id,
  t.disciplina,
  t.descricao,
  CAST(t.inicio_baseline AS DATE)                          AS inicio_baseline,
  CAST(t.fim_baseline AS DATE)                             AS fim_baseline,
  try_to_date(t.inicio_real, 'yyyy-MM-dd')                 AS inicio_real,
  try_to_date(t.fim_real, 'yyyy-MM-dd')                    AS fim_real,
  CASE WHEN CAST(t.pct_concluido AS DOUBLE) > 100 THEN coalesce(m.pct_medido, 0)
       ELSE CAST(t.pct_concluido AS DOUBLE) END            AS pct_concluido,
  CAST(t.pct_concluido AS DOUBLE) > 100                    AS pct_corrigido_pela_medicao,
  CAST(t.valor_planejado AS DECIMAL(18,2))                 AS valor_planejado
FROM lakehouse_atlas.bronze.tarefas t
LEFT JOIN ultima_medicao m USING (tarefa_id);
