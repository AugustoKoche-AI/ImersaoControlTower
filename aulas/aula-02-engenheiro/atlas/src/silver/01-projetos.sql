-- silver.projetos: uma linha por obra, tipada.
--
-- Sujeiras resolvidas aqui:
--   · data_inicio em dois formatos (2025-03-14 e 14/03/2025) → coalesce de dois try_to_date
--   · UF escrita de três jeitos ('MG', 'mg', ' MG ')         → upper(trim())
-- O EXPECT é o contrato: se uma data não converter, o pipeline PARA.

CREATE OR REFRESH MATERIALIZED VIEW projetos (
  CONSTRAINT data_inicio_valida EXPECT (data_inicio IS NOT NULL) ON VIOLATION FAIL UPDATE,
  CONSTRAINT uf_com_duas_letras EXPECT (length(uf) = 2) ON VIOLATION FAIL UPDATE,
  CONSTRAINT prazo_depois_do_inicio EXPECT (data_fim_baseline > data_inicio)
)
COMMENT 'Obras da carteira da Atlas. Datas e UF padronizadas a partir de bronze.projetos.'
AS SELECT
  projeto_id,
  nome_projeto,
  cliente,
  setor,
  upper(trim(uf))                                         AS uf,
  municipio,
  CAST(valor_contrato  AS DECIMAL(18,2))                  AS valor_contrato,
  CAST(orcamento_custo AS DECIMAL(18,2))                  AS orcamento,
  coalesce(try_to_date(data_inicio, 'yyyy-MM-dd'),
           try_to_date(data_inicio, 'dd/MM/yyyy'))        AS data_inicio,
  CAST(data_fim_baseline AS DATE)                         AS data_fim_baseline,
  status,
  gerente_projeto,
  data_inicio LIKE '%/%'                                  AS data_veio_em_formato_br
FROM lakehouse_atlas.bronze.projetos;
