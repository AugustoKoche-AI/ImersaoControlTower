-- silver.equipes, silver.apontamentos, silver.equipamentos e silver.uso_equipamentos:
-- gente e máquina, onde estão e quanto trabalharam.
--
-- A sujeira: 3 equipes cadastradas duas vezes no RH (mesmo equipe_id, função em
-- CAIXA ALTA, UF em minúscula e headcount diferente). DISTINCT não resolve,
-- porque as linhas são diferentes. Ficamos com o cadastro no padrão do sistema
-- (função em minúsculas). A unicidade é conferida em src/testes/testes.sql.

CREATE OR REFRESH MATERIALIZED VIEW equipes (
  CONSTRAINT headcount_positivo EXPECT (headcount > 0) ON VIOLATION FAIL UPDATE
)
COMMENT 'Equipes de campo (uma linha por equipe). Duplicatas do RH removidas, mantendo o cadastro no padrão do sistema.'
AS WITH ordenado AS (
  SELECT *,
         COUNT(*) OVER (PARTITION BY equipe_id)                                     AS linhas_no_rh,
         row_number() OVER (PARTITION BY equipe_id
                            ORDER BY CASE WHEN funcao = lower(funcao) THEN 0 ELSE 1 END) AS ordem
  FROM lakehouse_atlas.bronze.equipes
)
SELECT equipe_id,
       lower(funcao)                     AS funcao,
       upper(trim(uf_base))              AS uf_base,
       CAST(custo_hora AS DECIMAL(10,2)) AS custo_hora,
       CAST(headcount AS INT)            AS headcount,
       projeto_id_atual,
       linhas_no_rh > 1                  AS cadastro_duplicado,
       linhas_no_rh
FROM ordenado
WHERE ordem = 1;

CREATE OR REFRESH MATERIALIZED VIEW apontamentos (
  CONSTRAINT horas_nao_negativas EXPECT (horas_apontadas >= 0 AND horas_disponiveis > 0) ON VIOLATION FAIL UPDATE
)
COMMENT 'Horas disponíveis x apontadas por equipe e dia. Apontado acima do disponível é hora extra (legítimo).'
AS SELECT
  apontamento_id, equipe_id, projeto_id,
  CAST(data AS DATE)                                   AS data,
  date_add(date_trunc('WEEK', CAST(data AS DATE)), 4)  AS semana,
  CAST(horas_disponiveis AS DOUBLE)                    AS horas_disponiveis,
  CAST(horas_apontadas AS DOUBLE)                      AS horas_apontadas,
  CAST(horas_apontadas AS DOUBLE) > CAST(horas_disponiveis AS DOUBLE) AS hora_extra
FROM lakehouse_atlas.bronze.apontamentos;

CREATE OR REFRESH MATERIALIZED VIEW equipamentos
COMMENT 'Frota: guindastes, escavadeiras, munck... e a obra onde cada equipamento está hoje (vazio = pátio).'
AS SELECT
  equipamento_id, tipo, modelo,
  nullif(projeto_id_atual, '')          AS projeto_id_atual,
  upper(trim(uf_atual))                 AS uf_atual,
  CAST(custo_hora AS DECIMAL(10,2))     AS custo_hora,
  propriedade
FROM lakehouse_atlas.bronze.equipamentos;

CREATE OR REFRESH MATERIALIZED VIEW uso_equipamentos (
  CONSTRAINT horas_operadas_validas EXPECT (horas_operadas BETWEEN 0 AND horas_disponiveis) ON VIOLATION FAIL UPDATE
)
COMMENT 'Horas operadas por equipamento e semana (semana começa na segunda).'
AS SELECT
  equipamento_id, projeto_id,
  CAST(semana_inicio AS DATE)                 AS semana_inicio,
  date_add(CAST(semana_inicio AS DATE), 4)    AS semana,
  CAST(horas_disponiveis AS DOUBLE)           AS horas_disponiveis,
  CAST(horas_operadas AS DOUBLE)              AS horas_operadas
FROM lakehouse_atlas.bronze.uso_equipamentos;
