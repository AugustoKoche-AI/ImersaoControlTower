-- silver.postmortems: o relato de cada incidente em produção, ainda em texto livre.
-- A IA (src/ia/postmortem_estruturado.sql) tira daqui o serviço, a causa raiz,
-- a duração e quantos usuários foram afetados.

CREATE OR REFRESH MATERIALIZED VIEW postmortems (
  CONSTRAINT severidade_conhecida EXPECT (severidade IN ('SEV1', 'SEV2', 'SEV3')) ON VIOLATION FAIL UPDATE
)
COMMENT 'Postmortems de incidentes em produção (um por incidente): projeto, data, severidade (SEV1 a SEV3) e o texto livre com serviço afetado, duração, causa raiz e impacto.'
AS SELECT
  incidente_id,
  projeto_id,
  CAST(data AS DATE)       AS data,
  severidade,
  texto_postmortem
FROM lakehouse_vertice.bronze.postmortems;
