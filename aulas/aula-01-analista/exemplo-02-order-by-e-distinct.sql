-- ============================================
-- EXEMPLO 02: ORDER BY, CAST e DISTINCT — os maiores contratos
-- ============================================
-- Conceito: ORDER BY, CAST, DISTINCT
-- Pergunta de negócio: quais são os maiores contratos da Vértice?
-- Conexão: na bronze tudo é texto. Sem CAST, o Databricks ordena como palavra.

-- 1. Os 5 maiores contratos... ou não.
--    ORDER BY coluna DESC   ordena do maior para o menor
--    Deve aparecer: uma lista que PARECE certa, com o PRJ-052 (R$ 8,4 mi) no topo. Está errada.
--    O valor é texto, e texto se ordena letra por letra: '8380000' vem antes de '15275000'
--    porque '8' vem depois de '1', como numa lista telefônica.
SELECT projeto_id, nome_projeto, valor_contrato
FROM lakehouse_vertice.bronze.projetos
ORDER BY valor_contrato DESC
LIMIT 5;

-- 2. A correção: converter o texto em número antes de ordenar.
--    CAST(coluna AS DECIMAL(18,2))   transforma o texto em número com 2 casas decimais
--    Deve aparecer: o maior contrato de verdade é o PRJ-017, R$ 15,3 mi.
SELECT projeto_id, nome_projeto,
       CAST(valor_contrato AS DECIMAL(18,2)) AS valor_numero
FROM lakehouse_vertice.bronze.projetos
ORDER BY valor_numero DESC
LIMIT 5;

-- 3. Em quais ferramentas os projetos vivem?
--    DISTINCT   tira as repetições: cada valor aparece uma vez só
--    Deve aparecer: 8 jeitos de escrever 3 ferramentas: 'Excel', 'excel', 'Planilha',
--    'ClickUp', 'Clickup', 'MS Project', 'Project', 'msproject'.
--    É o retrato do problema da Vértice: cada um registra do seu jeito.
SELECT DISTINCT ferramenta
FROM lakehouse_vertice.bronze.projetos
ORDER BY ferramenta;
