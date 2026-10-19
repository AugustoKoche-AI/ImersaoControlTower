-- ============================================
-- EXEMPLO 02: ORDER BY, DISTINCT e CAST — o tamanho da carteira
-- ============================================
-- Conceito: ORDER BY, DISTINCT, CAST, SUM
-- Pergunta de negócio: quais são os maiores contratos e quanto vale a carteira?
-- Conexão: na bronze tudo é texto. Sem CAST, ORDER BY ordena como palavra.

-- 1. A armadilha: ordenar texto. '9000000.00' vem antes de '12000000.00'?
SELECT projeto_id, nome_projeto, valor_contrato
FROM lakehouse_vertice.bronze.projetos
ORDER BY valor_contrato DESC
LIMIT 5;

-- 2. Com CAST, ordena como número
SELECT projeto_id, nome_projeto, cliente,
       CAST(valor_contrato AS DECIMAL(18,2)) AS valor_contrato
FROM lakehouse_vertice.bronze.projetos
ORDER BY 4 DESC
LIMIT 10;

-- 3. A carteira inteira, e só o que está em andamento
SELECT COUNT(*)                                                         AS projetos,
       ROUND(SUM(CAST(valor_contrato AS DECIMAL(18,2))) / 1e6, 1)       AS carteira_milhoes,
       COUNT(*) FILTER (WHERE status = 'em_andamento')                  AS em_andamento,
       ROUND(SUM(CAST(valor_contrato AS DECIMAL(18,2)))
             FILTER (WHERE status = 'em_andamento') / 1e6, 1)           AS em_andamento_milhoes
FROM lakehouse_vertice.bronze.projetos;

-- 4. DISTINCT: para quais segmentos a Vértice trabalha?
SELECT DISTINCT segmento FROM lakehouse_vertice.bronze.projetos ORDER BY segmento;

-- 5. E em quais ferramentas os projetos vivem?
--    Repare: 'Excel', 'excel' e 'Planilha' são a mesma coisa. É a primeira sujeira do dia,
--    e é o retrato do problema da Vértice: cada um registra do seu jeito.
SELECT DISTINCT ferramenta
FROM lakehouse_vertice.bronze.projetos
ORDER BY ferramenta;
