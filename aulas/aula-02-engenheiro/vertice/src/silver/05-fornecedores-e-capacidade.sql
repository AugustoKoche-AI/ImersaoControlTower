-- silver.entregas_fornecedor, silver.contratos_capacidade e silver.consumo_capacidade:
-- o que as consultorias prometem entregar e quanto ainda resta de horas e de cloud.
--
-- Sujeiras resolvidas aqui:
--   · a MESMA consultoria digitada de quatro jeitos ('CodeForge Consultoria Ltda',
--     'Codeforge Consultoria', 'CODEFORGE CONSULTORIA LTDA', 'Code Forge Consultoria').
--     Sem normalizar, ela vira quatro fornecedores medianos — e o pior fornecedor
--     da carteira some do ranking.
--   · saldo negativo no consumo (erro de lançamento): vira 0 e ganha flag.
--   · data_entrega vazia NÃO é sujeira: é entrega ainda em aberto.

CREATE OR REFRESH MATERIALIZED VIEW entregas_fornecedor (
  CONSTRAINT fornecedor_normalizado EXPECT (fornecedor IS NOT NULL) ON VIOLATION FAIL UPDATE,
  CONSTRAINT promessa_depois_do_pedido EXPECT (data_prometida >= data_pedido)
)
COMMENT 'Entregas das consultorias por projeto: fornecedor normalizado, valor, prazo prometido x real, em aberto e em atraso (prometida antes de 16/10/2026 e não entregue).'
AS SELECT
  entrega_id,
  projeto_id,
  CASE WHEN replace(lower(fornecedor), ' ', '') LIKE '%codeforge%' THEN 'CodeForge Consultoria Ltda'
       ELSE fornecedor END                                                AS fornecedor,
  fornecedor                                                              AS fornecedor_como_veio,
  item,
  CAST(valor AS DECIMAL(18,2))                                            AS valor,
  CAST(data_pedido AS DATE)                                               AS data_pedido,
  CAST(data_prometida AS DATE)                                            AS data_prometida,
  try_to_date(data_entrega, 'yyyy-MM-dd')                                 AS data_entrega,
  CAST(prazo_contratado_dias AS INT)                                      AS prazo_prometido_dias,
  datediff(try_to_date(data_entrega, 'yyyy-MM-dd'), CAST(data_pedido AS DATE)) AS prazo_real_dias,
  datediff(try_to_date(data_entrega, 'yyyy-MM-dd'), CAST(data_prometida AS DATE)) AS dias_de_atraso_na_entrega,
  status = 'em_aberto'                                                    AS em_aberto,
  status = 'em_aberto' AND CAST(data_prometida AS DATE) < DATE'2026-10-16' AS em_atraso
FROM lakehouse_vertice.bronze.entregas_fornecedor;

CREATE OR REFRESH MATERIALIZED VIEW contratos_capacidade
COMMENT 'Contratos de capacidade por projeto: banco de horas de consultoria (horas) e créditos de cloud (R$), com quantidade contratada e vigência.'
AS SELECT
  contrato_id,
  projeto_id,
  fornecedor,
  tipo,
  unidade,
  CAST(quantidade_contratada AS DOUBLE)     AS quantidade_contratada,
  CAST(data_inicio AS DATE)                 AS data_inicio,
  CAST(data_fim_vigencia AS DATE)           AS data_fim_vigencia,
  CAST(valor_contrato AS DECIMAL(18,2))     AS valor_contrato
FROM lakehouse_vertice.bronze.contratos_capacidade;

CREATE OR REFRESH MATERIALIZED VIEW consumo_capacidade (
  CONSTRAINT saldo_nao_negativo EXPECT (saldo >= 0) ON VIOLATION FAIL UPDATE
)
COMMENT 'Saldo semanal (sexta) de cada contrato de capacidade, o consumo da semana e o consumo diário previsto para as próximas 4 semanas.'
AS SELECT
  contrato_id,
  CAST(data AS DATE)                          AS data,
  CAST(consumido_semana AS DOUBLE)            AS consumido_semana,
  greatest(CAST(saldo AS DOUBLE), 0)          AS saldo,
  CAST(saldo AS DOUBLE) < 0                   AS saldo_negativo_corrigido,
  CAST(consumo_previsto_dia AS DOUBLE)        AS consumo_previsto_dia
FROM lakehouse_vertice.bronze.consumo_capacidade;
