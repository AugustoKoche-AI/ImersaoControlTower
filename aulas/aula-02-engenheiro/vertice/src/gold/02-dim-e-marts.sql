-- gold: as tabelas que respondem as perguntas do dono.
--
--   1. Quais projetos estão atrasados, e de quais clientes?   → projeto_situacao_atual
--   2. Quanto esse atraso vai me custar?                      → projeto_situacao_atual (EAC, estouro, margem)
--   3. Tenho gente parada enquanto outro projeto pede gente?  → utilizacao_pessoa_semana (+ status_estruturado, na IA)
--   4. O que vai dar errado no próximo mês?                   → cobertura_capacidade, entregas_em_atraso (+ o modelo, na noite 3)
--
-- Regras de corte da Torre: SPI ou CPI < 0,9 = atenção; < 0,8 = crítico.
-- Farol pela regra do manual da Vértice: verde com SPI ≥ 0,95; amarelo ≥ 0,90; vermelho abaixo.

CREATE OR REFRESH MATERIALIZED VIEW lakehouse_vertice.gold.dim_projeto
COMMENT 'Dimensão de projeto: cliente, segmento, tipo, ferramenta onde é gerenciado, contrato, orçamento, prazo baseline, status e gerente.'
AS SELECT projeto_id, nome_projeto, concat(projeto_id, ' · ', nome_projeto) AS projeto,
          cliente, segmento, tipo_projeto, ferramenta, valor_contrato, orcamento,
          data_inicio, data_fim_baseline, datediff(data_fim_baseline, data_inicio) AS duracao_baseline_dias,
          status, gerente_projeto
FROM projetos;

CREATE OR REFRESH MATERIALIZED VIEW lakehouse_vertice.gold.projeto_situacao_atual
COMMENT 'Fotografia de hoje (16/10/2026) de cada projeto, calculada sobre as tarefas das 3 ferramentas: SPI, CPI, EAC, estouro previsto, margem projetada, atraso projetado, situação (ok, atenção, crítico, concluído), farol do gerente x farol calculado e se é "melancia" (farol verde com SPI < 0,9).'
AS WITH valor AS (
  SELECT projeto_id,
         SUM(horas)                                                     AS horas_totais,
         SUM(horas * pct_concluido / 100)                               AS horas_agregadas,
         SUM(horas * greatest(0, least(1, datediff(DATE'2026-10-16', inicio_baseline)
                                          / greatest(1, datediff(fim_baseline, inicio_baseline))))) AS horas_planejadas
  FROM tarefas
  GROUP BY projeto_id
),
custo AS (SELECT projeto_id, SUM(valor) AS ac FROM custos WHERE data <= DATE'2026-10-16' GROUP BY projeto_id),
farol AS (SELECT projeto_id, farol FROM status_semanal WHERE data_status = DATE'2026-10-16'),
kpi AS (
  SELECT d.*,
         v.horas_totais, v.horas_agregadas, v.horas_planejadas,
         d.orcamento * v.horas_planejadas / v.horas_totais     AS pv,
         d.orcamento * v.horas_agregadas / v.horas_totais      AS ev,
         c.ac,
         v.horas_agregadas / v.horas_planejadas                AS spi_bruto,
         d.orcamento * v.horas_agregadas / v.horas_totais / c.ac AS cpi_bruto,
         f.farol                                               AS farol_do_gerente
  FROM lakehouse_vertice.gold.dim_projeto d
  JOIN valor v USING (projeto_id)
  JOIN custo c USING (projeto_id)
  LEFT JOIN farol f USING (projeto_id)
)
SELECT projeto_id, projeto, nome_projeto, cliente, segmento, tipo_projeto, ferramenta, status, gerente_projeto,
       valor_contrato, orcamento, data_inicio, data_fim_baseline, duracao_baseline_dias,
       CAST(pv AS DECIMAL(18,2))                                                   AS pv,
       CAST(ev AS DECIMAL(18,2))                                                   AS ev,
       CAST(ac AS DECIMAL(18,2))                                                   AS ac,
       ROUND(horas_agregadas / horas_totais, 4)                                    AS pct_concluido,
       ROUND(spi_bruto, 4)                                                         AS spi,
       ROUND(cpi_bruto, 4)                                                         AS cpi,
       CAST(orcamento / cpi_bruto AS DECIMAL(18,2))                                AS eac,
       CAST(greatest(orcamento / cpi_bruto - orcamento, 0) AS DECIMAL(18,2))       AS estouro_previsto,
       ROUND((valor_contrato - orcamento / cpi_bruto) / valor_contrato, 4)         AS margem_projetada,
       ROUND((valor_contrato - orcamento) / valor_contrato, 4)                     AS margem_orcada,
       CAST(ROUND(duracao_baseline_dias / spi_bruto - duracao_baseline_dias) AS INT) AS atraso_projetado_dias,
       date_add(data_fim_baseline,
                CAST(ROUND(duracao_baseline_dias / spi_bruto - duracao_baseline_dias) AS INT)) AS termino_projetado,
       CASE WHEN status <> 'em_andamento'                THEN 'concluído'
            WHEN least(spi_bruto, cpi_bruto) < 0.8       THEN 'crítico'
            WHEN least(spi_bruto, cpi_bruto) < 0.9       THEN 'atenção'
            ELSE 'ok' END                                                          AS situacao,
       farol_do_gerente,
       CASE WHEN spi_bruto >= 0.95 THEN 'verde' WHEN spi_bruto >= 0.90 THEN 'amarelo' ELSE 'vermelho' END
                                                                                   AS farol_calculado,
       status = 'em_andamento' AND farol_do_gerente = 'verde' AND spi_bruto < 0.9  AS melancia
FROM kpi;

CREATE OR REFRESH MATERIALIZED VIEW lakehouse_vertice.gold.utilizacao_pessoa_semana
COMMENT 'Pessoa × projeto × semana: papel (dev, qa, sre, tech_lead...), senioridade, horas disponíveis, apontadas e ociosas, utilização, custo da hora ociosa e o SPI do projeto na semana. Responde: tenho gente parada enquanto outro projeto pede gente?'
AS SELECT a.colaborador_id, c.nome, c.papel, c.senioridade, a.projeto_id, d.projeto, d.cliente, a.semana,
          SUM(a.horas_disponiveis)                                                    AS horas_disponiveis,
          SUM(a.horas_apontadas)                                                      AS horas_apontadas,
          SUM(greatest(a.horas_disponiveis - a.horas_apontadas, 0))                   AS horas_ociosas,
          ROUND(SUM(a.horas_apontadas) / SUM(a.horas_disponiveis), 4)                 AS utilizacao,
          c.custo_hora,
          CAST(SUM(greatest(a.horas_disponiveis - a.horas_apontadas, 0)) * c.custo_hora AS DECIMAL(18,2)) AS custo_ocioso,
          MAX(f.spi)                                                                  AS spi_do_projeto
FROM apontamentos a
JOIN colaboradores c USING (colaborador_id)
JOIN lakehouse_vertice.gold.dim_projeto d ON d.projeto_id = a.projeto_id
LEFT JOIN lakehouse_vertice.gold.fato_projeto_semana f ON f.projeto_id = a.projeto_id AND f.semana = a.semana
GROUP BY ALL;

CREATE OR REFRESH MATERIALIZED VIEW lakehouse_vertice.gold.desempenho_fornecedor
COMMENT 'Fornecedor (normalizado): entregas, grafias diferentes no cadastro de compras, prazo prometido x real, fator de atraso, % entregue no prazo e entregas em atraso hoje.'
AS SELECT fornecedor,
          COUNT(*)                                                                 AS entregas,
          COUNT(DISTINCT fornecedor_como_veio)                                     AS grafias_no_cadastro,
          ROUND(AVG(prazo_prometido_dias), 1)                                       AS prazo_prometido_medio,
          ROUND(AVG(prazo_real_dias), 1)                                            AS prazo_real_medio,
          ROUND(AVG(prazo_real_dias / prazo_prometido_dias), 3)                     AS fator_atraso,
          ROUND(AVG(CASE WHEN data_entrega <= data_prometida THEN 1.0 ELSE 0.0 END)
                FILTER (WHERE data_entrega IS NOT NULL), 4)                         AS pct_no_prazo,
          COUNT_IF(em_atraso)                                                       AS entregas_em_atraso,
          CAST(SUM(valor) AS DECIMAL(18,2))                                         AS valor_contratado
FROM entregas_fornecedor
GROUP BY fornecedor;

CREATE OR REFRESH MATERIALIZED VIEW lakehouse_vertice.gold.cobertura_capacidade
COMMENT 'Contrato de capacidade × hoje (16/10/2026): banco de horas de consultoria ou créditos de cloud de cada projeto em andamento, saldo, consumo previsto por dia, cobertura em dias e se haverá ruptura (cobertura < 30 dias, o prazo para aprovar aditivo).'
AS WITH hoje AS (SELECT * FROM consumo_capacidade WHERE data = DATE'2026-10-16')
SELECT c.contrato_id, c.projeto_id, d.projeto, d.cliente, c.fornecedor, c.tipo, c.unidade,
       c.quantidade_contratada, h.saldo, h.consumo_previsto_dia,
       ROUND(try_divide(h.saldo, h.consumo_previsto_dia), 1)                    AS cobertura_dias,
       date_add(DATE'2026-10-16', CAST(floor(try_divide(h.saldo, h.consumo_previsto_dia)) AS INT)) AS data_prevista_fim_saldo,
       c.data_fim_vigencia,
       h.consumo_previsto_dia > 0 AND h.saldo / h.consumo_previsto_dia < 30     AS ruptura_prevista
FROM contratos_capacidade c
JOIN hoje h USING (contrato_id)
JOIN lakehouse_vertice.gold.dim_projeto d ON d.projeto_id = c.projeto_id
WHERE d.status = 'em_andamento';

CREATE OR REFRESH MATERIALIZED VIEW lakehouse_vertice.gold.entregas_em_atraso
COMMENT 'Entregas de fornecedor em aberto com data prometida anterior a hoje (16/10/2026), com dias de atraso.'
AS SELECT e.entrega_id, e.projeto_id, d.projeto, e.fornecedor, e.item, e.valor, e.data_pedido, e.data_prometida,
          datediff(DATE'2026-10-16', e.data_prometida) AS dias_de_atraso
FROM entregas_fornecedor e
JOIN lakehouse_vertice.gold.dim_projeto d ON d.projeto_id = e.projeto_id
WHERE e.em_atraso;
