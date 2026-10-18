-- Conferência da bronze: as 12 tabelas da noite 1 estão lá, e inteiras?
--
-- Se qualquer contagem vier diferente, raise_error() INTERROMPE o job aqui,
-- antes de a silver e a gold serem recalculadas em cima de meio dado.
-- A seed é fixa (42): estes números são os mesmos para todo mundo.

WITH contagem AS (
  SELECT 'projetos' AS tabela, 40 AS esperado, (SELECT COUNT(*) FROM lakehouse_atlas.bronze.projetos) AS obtido
  UNION ALL SELECT 'tarefas',           8000,  (SELECT COUNT(*) FROM lakehouse_atlas.bronze.tarefas)
  UNION ALL SELECT 'avanco_semanal',    55703, (SELECT COUNT(*) FROM lakehouse_atlas.bronze.avanco_semanal)
  UNION ALL SELECT 'custos',            19445, (SELECT COUNT(*) FROM lakehouse_atlas.bronze.custos)
  UNION ALL SELECT 'compras',           13304, (SELECT COUNT(*) FROM lakehouse_atlas.bronze.compras)
  UNION ALL SELECT 'materiais',         25,    (SELECT COUNT(*) FROM lakehouse_atlas.bronze.materiais)
  UNION ALL SELECT 'estoque',           40094, (SELECT COUNT(*) FROM lakehouse_atlas.bronze.estoque)
  UNION ALL SELECT 'equipes',           123,   (SELECT COUNT(*) FROM lakehouse_atlas.bronze.equipes)
  UNION ALL SELECT 'apontamentos',      41190, (SELECT COUNT(*) FROM lakehouse_atlas.bronze.apontamentos)
  UNION ALL SELECT 'equipamentos',      300,   (SELECT COUNT(*) FROM lakehouse_atlas.bronze.equipamentos)
  UNION ALL SELECT 'uso_equipamentos',  19817, (SELECT COUNT(*) FROM lakehouse_atlas.bronze.uso_equipamentos)
  UNION ALL SELECT 'rdo',               13730, (SELECT COUNT(*) FROM lakehouse_atlas.bronze.rdo)
)
SELECT tabela, esperado, obtido,
       CASE WHEN esperado = obtido THEN 'ok'
            ELSE raise_error(concat('bronze.', tabela, ': esperado ', esperado, ', veio ', obtido,
                                    '. Rode de novo o 00-carregar-dados e o 01-ingestao-bronze da noite 1.'))
       END AS status
FROM contagem;
