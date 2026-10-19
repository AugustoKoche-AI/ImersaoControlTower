-- Conferência da bronze: as 13 tabelas da noite 1 estão lá, e inteiras?
--
-- Se qualquer contagem vier diferente, raise_error() INTERROMPE o job aqui,
-- antes de a silver e a gold serem recalculadas em cima de meio dado.
-- A seed é fixa (42): estes números são os mesmos para todo mundo.

WITH contagem AS (
  SELECT 'projetos' AS tabela, 60 AS esperado, (SELECT COUNT(*) FROM lakehouse_vertice.bronze.projetos) AS obtido
  UNION ALL SELECT 'status_semanal',       3911,  (SELECT COUNT(*) FROM lakehouse_vertice.bronze.status_semanal)
  UNION ALL SELECT 'excel_tarefas',        1663,  (SELECT COUNT(*) FROM lakehouse_vertice.bronze.excel_tarefas)
  UNION ALL SELECT 'clickup_tarefas',      2119,  (SELECT COUNT(*) FROM lakehouse_vertice.bronze.clickup_tarefas)
  UNION ALL SELECT 'msproject_tarefas',    1260,  (SELECT COUNT(*) FROM lakehouse_vertice.bronze.msproject_tarefas)
  UNION ALL SELECT 'colaboradores',        523,   (SELECT COUNT(*) FROM lakehouse_vertice.bronze.colaboradores)
  UNION ALL SELECT 'alocacoes',            517,   (SELECT COUNT(*) FROM lakehouse_vertice.bronze.alocacoes)
  UNION ALL SELECT 'apontamentos',         30883, (SELECT COUNT(*) FROM lakehouse_vertice.bronze.apontamentos)
  UNION ALL SELECT 'custos',               23640, (SELECT COUNT(*) FROM lakehouse_vertice.bronze.custos)
  UNION ALL SELECT 'entregas_fornecedor',  640,   (SELECT COUNT(*) FROM lakehouse_vertice.bronze.entregas_fornecedor)
  UNION ALL SELECT 'contratos_capacidade', 93,    (SELECT COUNT(*) FROM lakehouse_vertice.bronze.contratos_capacidade)
  UNION ALL SELECT 'consumo_capacidade',   6070,  (SELECT COUNT(*) FROM lakehouse_vertice.bronze.consumo_capacidade)
  UNION ALL SELECT 'postmortems',          101,   (SELECT COUNT(*) FROM lakehouse_vertice.bronze.postmortems)
)
SELECT tabela, esperado, obtido,
       CASE WHEN esperado = obtido THEN 'ok'
            ELSE raise_error(concat('bronze.', tabela, ': esperado ', esperado, ', veio ', obtido,
                                    '. Rode de novo o 00-carregar-dados e o 01-ingestao-bronze da noite 1.'))
       END AS status
FROM contagem;
