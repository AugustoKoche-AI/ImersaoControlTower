-- ============================================
-- EXEMPLO 01: SELECT — o que existe no catálogo?
-- ============================================
-- Conceito: SELECT, FROM, LIMIT, COUNT(*)
-- Pergunta de negócio: que projetos a Vértice tem, e onde cada um vive?
-- Conexão: antes de calcular qualquer coisa, olhe o dado. Sempre.
--
-- O nome completo de uma tabela tem 3 partes: catálogo.schema.tabela
--   lakehouse_vertice . bronze . projetos
-- Rode um bloco de cada vez: selecione o bloco e Ctrl+Enter.

-- 1. A primeira olhada no cadastro de projetos do PMO.
--    SELECT *   traga todas as colunas
--    FROM ...   da tabela tal
--    LIMIT 10   só as 10 primeiras linhas
--    Deve aparecer: 10 projetos com cliente, valor do contrato, prazo e a coluna ferramenta
--    (Excel, ClickUp ou MS Project): é onde o cronograma de cada um vive. Repare que a
--    mesma ferramenta aparece escrita de jeitos diferentes. Volta no exemplo 02.
SELECT *
FROM lakehouse_vertice.bronze.projetos
LIMIT 10;

-- 2. Quantos projetos a Vértice tem?
--    COUNT(*)   conta as linhas
--    AS nome    dá um nome para a coluna do resultado
--    Deve aparecer: 60.
SELECT COUNT(*) AS projetos
FROM lakehouse_vertice.bronze.projetos;
