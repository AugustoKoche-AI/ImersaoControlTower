-- silver.custos: cada lançamento de custo real, em número.
--
-- Sujeiras resolvidas aqui:
--   · 540 valores com vírgula decimal ('12345,67') → replace antes do CAST.
--     Com try_cast elas virariam NULL e sumiriam do total em silêncio (R$ 16,8 mi).
--   · estorno vem como valor negativo. NÃO é erro: é o lançamento revertido.
--     Fica na tabela (o custo real é líquido) e ganha a coluna estorno para quem
--     quiser separar.

CREATE OR REFRESH MATERIALIZED VIEW custos (
  CONSTRAINT valor_convertido EXPECT (valor IS NOT NULL) ON VIOLATION FAIL UPDATE,
  CONSTRAINT data_valida EXPECT (data IS NOT NULL) ON VIOLATION FAIL UPDATE
)
COMMENT 'Lançamentos de custo real por obra. Valor em DECIMAL, vírgula decimal corrigida; estornos mantidos e sinalizados.'
AS SELECT
  lancamento_id,
  projeto_id,
  CAST(data AS DATE)                                         AS data,
  date_add(date_trunc('WEEK', CAST(data AS DATE)), 4)        AS semana,          -- sexta da semana
  categoria,
  descricao,
  CAST(replace(valor_real, ',', '.') AS DECIMAL(18,2))      AS valor,
  CAST(replace(valor_real, ',', '.') AS DECIMAL(18,2)) < 0  AS estorno,
  valor_real LIKE '%,%'                                      AS valor_veio_com_virgula,
  centro_custo
FROM lakehouse_atlas.bronze.custos;
