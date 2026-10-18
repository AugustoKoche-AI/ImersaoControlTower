-- gold.fato_projeto_semana: O produto de dados da Torre. Uma linha por obra e semana.
--
-- É daqui que saem SPI, CPI, EAC e a evolução de cada obra. As três medidas do
-- Earned Value são ACUMULADAS até a semana:
--   PV  valor planejado  quanto devia estar pronto, pelo baseline (linear por tarefa)
--   EV  valor agregado   quanto está pronto: Σ valor_planejado × % medido no boletim
--   AC  custo real       quanto já gastamos (lançamentos líquidos de estorno)
--
-- O "hoje" do dataset é 16/10/2026. Nunca use current_date(): o número mudaria
-- todo dia e não bateria com o de ninguém.

CREATE OR REFRESH MATERIALIZED VIEW lakehouse_atlas.gold.fato_projeto_semana (
  CONSTRAINT pv_nao_negativo EXPECT (pv >= 0) ON VIOLATION FAIL UPDATE,
  CONSTRAINT ev_nao_passa_orcamento EXPECT (ev <= orcamento * 1.0001) ON VIOLATION FAIL UPDATE
)
COMMENT 'Obra × semana (sexta-feira): PV, EV, AC acumulados, SPI, CPI, EAC, horas da equipe e rupturas previstas. Hoje do dataset: 2026-10-16.'
AS WITH semanas AS (
  SELECT projeto_id, orcamento,
         explode(sequence(date_add(date_trunc('WEEK', data_inicio), 4), DATE'2026-10-16', INTERVAL 1 WEEK)) AS semana
  FROM projetos
),
pv AS (
  SELECT s.projeto_id, s.semana,
         SUM(t.valor_planejado * greatest(0, least(1,
             datediff(s.semana, t.inicio_baseline) / greatest(1, datediff(t.fim_baseline, t.inicio_baseline))))) AS pv
  FROM semanas s JOIN tarefas t ON t.projeto_id = s.projeto_id
  GROUP BY s.projeto_id, s.semana
),
delta_tarefa AS (                -- quanto cada tarefa andou em cada medição (o boletim guarda o acumulado)
  SELECT projeto_id, tarefa_id, data_medicao,
         pct_concluido - coalesce(lag(pct_concluido) OVER (PARTITION BY tarefa_id ORDER BY data_medicao), 0) AS delta_pct
  FROM avanco_semanal
),
avanco_incremental AS (          -- o avanço da semana, em reais do orçamento
  SELECT d.projeto_id, d.data_medicao AS semana,
         SUM(t.valor_planejado * d.delta_pct / 100) AS ev_semana
  FROM delta_tarefa d JOIN tarefas t USING (tarefa_id)
  GROUP BY d.projeto_id, d.data_medicao
),
custo_semana AS (
  SELECT projeto_id, semana, SUM(valor) AS ac_semana FROM custos GROUP BY projeto_id, semana
),
horas_semana AS (
  SELECT projeto_id, semana, SUM(horas_disponiveis) AS horas_disponiveis, SUM(horas_apontadas) AS horas_apontadas
  FROM apontamentos GROUP BY projeto_id, semana
),
proxima_entrega AS (              -- para cada saldo semanal, a próxima entrega PROMETIDA ainda em aberto
  SELECT e.projeto_id, e.material_id, e.data, e.saldo, e.consumo_previsto_dia, m.lead_time_contratado_dias,
         MIN(c.data_prometida) AS proxima_prometida
  FROM estoque e
  JOIN materiais m USING (material_id)
  LEFT JOIN compras c
    ON c.projeto_id = e.projeto_id AND c.material_id = e.material_id
   AND c.data_pedido <= e.data AND (c.data_entrega IS NULL OR c.data_entrega > e.data)
  GROUP BY ALL
),
rupturas AS (
  -- Ruptura prevista: o estoque acaba antes da próxima entrega prometida chegar.
  -- Se a promessa já venceu e não chegou, ela não vale mais: conta o lead time de um pedido novo.
  SELECT projeto_id, data AS semana,
         COUNT_IF(consumo_previsto_dia > 0 AND
                  saldo / consumo_previsto_dia <
                  CASE WHEN proxima_prometida >= data THEN datediff(proxima_prometida, data)
                       ELSE lead_time_contratado_dias END) AS rupturas_previstas
  FROM proxima_entrega
  GROUP BY projeto_id, data
),
acumulado AS (
  SELECT s.projeto_id, s.semana, s.orcamento,
         pv.pv,
         SUM(coalesce(a.ev_semana, 0)) OVER w AS ev,
         SUM(coalesce(c.ac_semana, 0)) OVER w AS ac,
         coalesce(h.horas_disponiveis, 0) AS horas_disponiveis,
         coalesce(h.horas_apontadas, 0)   AS horas_apontadas,
         coalesce(r.rupturas_previstas, 0) AS rupturas_previstas
  FROM semanas s
  JOIN pv USING (projeto_id, semana)
  LEFT JOIN avanco_incremental a USING (projeto_id, semana)
  LEFT JOIN custo_semana c USING (projeto_id, semana)
  LEFT JOIN horas_semana h USING (projeto_id, semana)
  LEFT JOIN rupturas r USING (projeto_id, semana)
  WINDOW w AS (PARTITION BY s.projeto_id ORDER BY s.semana)
)
SELECT projeto_id,
       semana,
       year(semana)                                  AS ano,
       month(semana)                                 AS mes,
       CAST(orcamento AS DECIMAL(18,2))              AS orcamento,
       CAST(pv AS DECIMAL(18,2))                     AS pv,
       CAST(ev AS DECIMAL(18,2))                     AS ev,
       CAST(ac AS DECIMAL(18,2))                     AS ac,
       ROUND(try_divide(ev, pv), 4)                  AS spi,
       ROUND(try_divide(ev, ac), 4)                  AS cpi,
       CAST(try_divide(orcamento, try_divide(ev, ac)) AS DECIMAL(18,2)) AS eac,
       horas_disponiveis,
       horas_apontadas,
       greatest(horas_disponiveis - horas_apontadas, 0) AS horas_ociosas,
       rupturas_previstas
FROM acumulado;
