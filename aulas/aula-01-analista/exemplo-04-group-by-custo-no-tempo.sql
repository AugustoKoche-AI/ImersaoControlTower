-- ============================================
-- EXEMPLO 04: GROUP BY — quanto a Vértice gasta por mês?
-- ============================================
-- Conceito: GROUP BY, date_trunc, try_cast, replace
-- Pergunta de negócio: qual é o custo real da carteira, mês a mês?
-- Conexão: a primeira query FALHA DE PROPÓSITO. Rode com --continuar.

-- 1. A query óbvia. Quebra: '12345,67' não é número.
SELECT date_trunc('MONTH', CAST(data AS DATE))  AS mes,
       SUM(CAST(valor AS DECIMAL(18,2)))        AS custo
FROM lakehouse_vertice.bronze.custos
GROUP BY 1
ORDER BY 1;

-- 2. A "correção" perigosa: try_cast não quebra... ele joga a linha fora em silêncio.
SELECT ROUND(SUM(try_cast(valor AS DECIMAL(18,2))) / 1e6, 2)               AS custo_milhoes_errado,
       COUNT(*) FILTER (WHERE try_cast(valor AS DECIMAL(18,2)) IS NULL)    AS linhas_perdidas
FROM lakehouse_vertice.bronze.custos;

-- 3. A correção certa: trocar a vírgula por ponto ANTES de converter
SELECT ROUND(SUM(CAST(replace(valor, ',', '.') AS DECIMAL(18,2))) / 1e6, 2) AS custo_milhoes
FROM lakehouse_vertice.bronze.custos;

-- 4. Agora sim: custo real por mês
SELECT date_trunc('MONTH', CAST(data AS DATE))                                     AS mes,
       ROUND(SUM(CAST(replace(valor, ',', '.') AS DECIMAL(18,2))) / 1e6, 2)        AS custo_milhoes
FROM lakehouse_vertice.bronze.custos
GROUP BY 1
ORDER BY 1;

-- 5. Por categoria: para onde vai o dinheiro de uma empresa de tecnologia?
--    (spoiler: gente. Folha alocada é quase dois terços do custo)
SELECT categoria,
       ROUND(SUM(CAST(replace(valor, ',', '.') AS DECIMAL(18,2))) / 1e6, 1) AS custo_milhoes
FROM lakehouse_vertice.bronze.custos
GROUP BY categoria
ORDER BY 2 DESC;
