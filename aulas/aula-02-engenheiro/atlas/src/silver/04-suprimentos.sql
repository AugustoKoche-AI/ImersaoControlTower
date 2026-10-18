-- silver.materiais, silver.compras e silver.estoque: o que a obra consome e o que chega.
--
-- Sujeiras resolvidas aqui:
--   · o MESMO fornecedor digitado de quatro jeitos ('Metalúrgica Norte Aço Ltda',
--     'Metalurgica Norte Aco', 'METALÚRGICA NORTE AÇO LTDA', 'Norte Aço Metalúrgica').
--     Sem normalizar, ele vira quatro fornecedores medianos — e o pior fornecedor
--     da carteira some do ranking.
--   · saldo de estoque negativo (erro de inventário): vira 0 e ganha flag.
--   · data_entrega vazia NÃO é sujeira: é pedido ainda em aberto.

CREATE OR REFRESH MATERIALIZED VIEW materiais
COMMENT 'Cadastro de materiais com disciplina e lead time contratado.'
AS SELECT
  material_id, descricao, unidade, disciplina,
  CAST(preco_referencia AS DECIMAL(18,2))       AS preco_referencia,
  CAST(lead_time_contratado_dias AS INT)        AS lead_time_contratado_dias
FROM lakehouse_atlas.bronze.materiais;

CREATE OR REFRESH MATERIALIZED VIEW compras (
  CONSTRAINT fornecedor_normalizado EXPECT (fornecedor IS NOT NULL) ON VIOLATION FAIL UPDATE,
  CONSTRAINT promessa_depois_do_pedido EXPECT (data_prometida >= data_pedido)
)
COMMENT 'Pedidos de compra com fornecedor normalizado e lead time real x prometido.'
AS SELECT
  pedido_id,
  projeto_id,
  material_id,
  CASE WHEN lower(fornecedor) LIKE '%norte a%' THEN 'Metalúrgica Norte Aço Ltda'
       ELSE fornecedor END                                     AS fornecedor,
  fornecedor                                                    AS fornecedor_como_veio,
  CAST(quantidade AS DOUBLE)                                    AS quantidade,
  CAST(valor_unitario AS DECIMAL(18,2))                         AS valor_unitario,
  CAST(quantidade AS DOUBLE) * CAST(valor_unitario AS DECIMAL(18,2)) AS valor_total,
  CAST(data_pedido AS DATE)                                     AS data_pedido,
  CAST(data_prometida AS DATE)                                  AS data_prometida,
  try_to_date(data_entrega, 'yyyy-MM-dd')                       AS data_entrega,
  CAST(lead_time_dias AS INT)                                   AS lead_time_prometido_dias,
  datediff(try_to_date(data_entrega, 'yyyy-MM-dd'), CAST(data_pedido AS DATE)) AS lead_time_real_dias,
  status = 'em_aberto'                                          AS em_aberto,
  status = 'em_aberto' AND CAST(data_prometida AS DATE) < DATE'2026-10-16' AS em_atraso
FROM lakehouse_atlas.bronze.compras;

CREATE OR REFRESH MATERIALIZED VIEW estoque (
  CONSTRAINT saldo_nao_negativo EXPECT (saldo >= 0) ON VIOLATION FAIL UPDATE
)
COMMENT 'Saldo semanal de cada material em cada obra e o consumo diário previsto pelo planejamento.'
AS SELECT
  projeto_id,
  material_id,
  CAST(data AS DATE)                                 AS data,
  greatest(CAST(saldo AS DOUBLE), 0)                 AS saldo,
  CAST(saldo AS DOUBLE) < 0                          AS saldo_negativo_corrigido,
  CAST(consumo_previsto_dia AS DOUBLE)               AS consumo_previsto_dia
FROM lakehouse_atlas.bronze.estoque;
