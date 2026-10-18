-- gold: as tabelas que respondem as TRÊS perguntas da diretoria.
--
--   1. Quais obras vão estourar prazo ou orçamento?        → obra_situacao_atual
--   2. Onde tenho gente e equipamento parado?              → utilizacao_equipe_semana, utilizacao_equipamento_semana
--   3. Que material vai faltar antes de travar a frente?   → cobertura_estoque, desempenho_fornecedor
--
-- Regras de corte da Torre: SPI ou CPI < 0,9 = atenção; < 0,8 = crítico.

CREATE OR REFRESH MATERIALIZED VIEW lakehouse_atlas.gold.dim_projeto
COMMENT 'Dimensão de obra: cliente, setor, UF, contrato, orçamento, prazo baseline e status.'
AS SELECT projeto_id, nome_projeto, concat(projeto_id, ' · ', nome_projeto) AS obra,
          cliente, setor, uf, municipio, valor_contrato, orcamento,
          data_inicio, data_fim_baseline, datediff(data_fim_baseline, data_inicio) AS duracao_baseline_dias,
          status, gerente_projeto
FROM projetos;

CREATE OR REFRESH MATERIALIZED VIEW lakehouse_atlas.gold.obra_situacao_atual
COMMENT 'Fotografia de hoje (16/10/2026) de cada obra: SPI, CPI, EAC, estouro previsto, margem projetada, atraso projetado e situação (ok, atenção, crítico).'
AS WITH hoje AS (
  SELECT * FROM lakehouse_atlas.gold.fato_projeto_semana WHERE semana = DATE'2026-10-16'
)
SELECT d.projeto_id, d.obra, d.nome_projeto, d.cliente, d.setor, d.uf, d.status, d.gerente_projeto,
       d.valor_contrato, d.orcamento, d.data_fim_baseline,
       h.pv, h.ev, h.ac, h.spi, h.cpi, h.eac,
       CAST(greatest(h.eac - d.orcamento, 0) AS DECIMAL(18,2))                AS estouro_previsto,
       ROUND((d.valor_contrato - h.eac) / d.valor_contrato, 4)               AS margem_projetada,
       ROUND((d.valor_contrato - d.orcamento) / d.valor_contrato, 4)         AS margem_orcada,
       CAST(ROUND(d.duracao_baseline_dias / h.spi - d.duracao_baseline_dias) AS INT) AS atraso_projetado_dias,
       date_add(d.data_fim_baseline,
                CAST(ROUND(d.duracao_baseline_dias / h.spi - d.duracao_baseline_dias) AS INT)) AS termino_projetado,
       h.rupturas_previstas,
       CASE WHEN d.status <> 'em_andamento'          THEN 'concluída'
            WHEN h.spi < 0.8 OR h.cpi < 0.8          THEN 'crítico'
            WHEN h.spi < 0.9 OR h.cpi < 0.9          THEN 'atenção'
            ELSE 'ok' END                                                    AS situacao
FROM lakehouse_atlas.gold.dim_projeto d
JOIN hoje h USING (projeto_id);

CREATE OR REFRESH MATERIALIZED VIEW lakehouse_atlas.gold.utilizacao_equipe_semana
COMMENT 'Equipe × semana: horas disponíveis, apontadas e ociosas, com o SPI da obra na semana. Responde: tenho gente parada em obra atrasada?'
AS SELECT a.equipe_id, e.funcao, e.headcount, a.projeto_id, d.obra, d.uf, a.semana,
          SUM(a.horas_disponiveis)                                         AS horas_disponiveis,
          SUM(a.horas_apontadas)                                           AS horas_apontadas,
          SUM(greatest(a.horas_disponiveis - a.horas_apontadas, 0))        AS horas_ociosas,
          ROUND(SUM(a.horas_apontadas) / SUM(a.horas_disponiveis), 4)      AS utilizacao,
          MAX(f.spi)                                                       AS spi_da_obra
FROM apontamentos a
JOIN equipes e USING (equipe_id)
JOIN lakehouse_atlas.gold.dim_projeto d ON d.projeto_id = a.projeto_id
LEFT JOIN lakehouse_atlas.gold.fato_projeto_semana f ON f.projeto_id = a.projeto_id AND f.semana = a.semana
GROUP BY ALL;

CREATE OR REFRESH MATERIALIZED VIEW lakehouse_atlas.gold.utilizacao_equipamento_semana
COMMENT 'Equipamento × semana: horas operadas sobre disponíveis, com tipo, modelo e obra. Responde: tenho guindaste parado enquanto outra obra espera por um?'
AS SELECT u.equipamento_id, q.tipo, q.modelo, u.projeto_id, d.obra, d.uf, u.semana,
          u.horas_disponiveis, u.horas_operadas,
          u.horas_disponiveis - u.horas_operadas                 AS horas_paradas,
          ROUND(u.horas_operadas / u.horas_disponiveis, 4)       AS utilizacao,
          q.custo_hora,
          CAST((u.horas_disponiveis - u.horas_operadas) * q.custo_hora AS DECIMAL(18,2)) AS custo_ocioso
FROM uso_equipamentos u
JOIN equipamentos q USING (equipamento_id)
JOIN lakehouse_atlas.gold.dim_projeto d ON d.projeto_id = u.projeto_id;

CREATE OR REFRESH MATERIALIZED VIEW lakehouse_atlas.gold.desempenho_fornecedor
COMMENT 'Fornecedor (normalizado): pedidos, lead time prometido x real, % entregue no prazo e pedidos em atraso hoje.'
AS SELECT fornecedor,
          COUNT(*)                                                                 AS pedidos,
          COUNT(DISTINCT fornecedor_como_veio)                                     AS grafias_no_erp,
          ROUND(AVG(lead_time_prometido_dias), 1)                                   AS lead_time_prometido_medio,
          ROUND(AVG(lead_time_real_dias), 1)                                        AS lead_time_real_medio,
          ROUND(AVG(lead_time_real_dias / lead_time_prometido_dias), 3)             AS fator_atraso,
          ROUND(AVG(CASE WHEN data_entrega <= data_prometida THEN 1.0 ELSE 0.0 END)
                FILTER (WHERE data_entrega IS NOT NULL), 4)                         AS pct_no_prazo,
          COUNT_IF(em_atraso)                                                       AS pedidos_em_atraso,
          CAST(SUM(valor_total) AS DECIMAL(18,2))                                   AS valor_comprado
FROM compras
GROUP BY fornecedor;

CREATE OR REFRESH MATERIALIZED VIEW lakehouse_atlas.gold.cobertura_estoque
COMMENT 'Material × obra hoje (16/10/2026): saldo, consumo previsto, cobertura em dias, próxima entrega prometida e se haverá ruptura antes dela.'
AS WITH hoje AS (
  SELECT * FROM estoque WHERE data = DATE'2026-10-16'
),
proxima AS (
  SELECT projeto_id, material_id,
         min_by(fornecedor, data_prometida) AS fornecedor_proxima_entrega,
         MIN(data_prometida)                AS proxima_entrega_prometida
  FROM compras WHERE em_aberto
  GROUP BY projeto_id, material_id
)
SELECT h.projeto_id, d.obra, d.uf, h.material_id, m.descricao AS material, m.disciplina, m.unidade,
       h.saldo, h.consumo_previsto_dia,
       ROUND(try_divide(h.saldo, h.consumo_previsto_dia), 1)                        AS cobertura_dias,
       p.proxima_entrega_prometida, p.fornecedor_proxima_entrega,
       CASE WHEN p.proxima_entrega_prometida >= DATE'2026-10-16'
            THEN datediff(p.proxima_entrega_prometida, DATE'2026-10-16')
            ELSE m.lead_time_contratado_dias END                                    AS dias_ate_reposicao,
       m.lead_time_contratado_dias,
       h.consumo_previsto_dia > 0 AND
       h.saldo / h.consumo_previsto_dia <
         CASE WHEN p.proxima_entrega_prometida >= DATE'2026-10-16'
              THEN datediff(p.proxima_entrega_prometida, DATE'2026-10-16')
              ELSE m.lead_time_contratado_dias END                                  AS ruptura_prevista
FROM hoje h
JOIN materiais m USING (material_id)
JOIN lakehouse_atlas.gold.dim_projeto d ON d.projeto_id = h.projeto_id
LEFT JOIN proxima p ON p.projeto_id = h.projeto_id AND p.material_id = h.material_id
WHERE d.status = 'em_andamento';

CREATE OR REFRESH MATERIALIZED VIEW lakehouse_atlas.gold.pedidos_em_atraso
COMMENT 'Pedidos de compra em aberto com data prometida anterior a hoje (16/10/2026).'
AS SELECT c.pedido_id, c.projeto_id, d.obra, c.material_id, m.descricao AS material, c.fornecedor,
          c.quantidade, c.valor_total, c.data_pedido, c.data_prometida,
          datediff(DATE'2026-10-16', c.data_prometida) AS dias_de_atraso
FROM compras c
JOIN materiais m USING (material_id)
JOIN lakehouse_atlas.gold.dim_projeto d ON d.projeto_id = c.projeto_id
WHERE c.em_atraso;
