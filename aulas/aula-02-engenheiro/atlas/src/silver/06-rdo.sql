-- silver.rdo: o relatório diário de obra, ainda em texto livre.
--
-- A sujeira: 82 RDOs não preenchidos ('', 'N/A', 'ver RDO físico') e 2-3% escritos
-- em CAIXA ALTA. Não descartamos o RDO vazio: o dia sem relatório é informação
-- (a obra não reportou). Ele ganha a flag rdo_vazio e fica fora da IA.

CREATE OR REFRESH MATERIALIZED VIEW rdo
COMMENT 'RDOs em texto livre, um por obra e dia útil. rdo_vazio marca o dia sem relatório.'
AS SELECT
  rdo_id,
  projeto_id,
  CAST(data AS DATE)                                               AS data,
  responsavel,
  texto_livre,
  coalesce(trim(texto_livre), '') IN ('', 'N/A', 'ver RDO físico') AS rdo_vazio
FROM lakehouse_atlas.bronze.rdo;
