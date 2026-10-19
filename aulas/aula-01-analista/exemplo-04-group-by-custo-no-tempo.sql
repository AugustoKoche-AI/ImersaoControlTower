-- ============================================
-- EXEMPLO 04: GROUP BY — para onde vai o dinheiro da Vértice?
-- ============================================
-- Conceito: GROUP BY, SUM, replace
-- Pergunta de negócio: quanto a Vértice gasta, por categoria de custo?
-- Conexão: é a pergunta 2 do dono ("quanto custa?") começando a ter resposta.
--
-- A tabela é a bronze.custos: um lançamento de custo por linha (23.640 linhas).

-- 1. Quanto cada categoria gastou?
--    GROUP BY categoria   junta as linhas da mesma categoria e faz a conta dentro de cada grupo
--    SUM(...)             soma a coluna dentro do grupo
--    O valor é texto, então primeiro CAST para número (exemplo 02).
--    Deve aparecer: um ERRO. É de propósito: '1827,44' não vira número. É a vírgula do exemplo 03.
SELECT categoria,
       SUM(CAST(valor AS DECIMAL(18,2))) AS custo
FROM lakehouse_vertice.bronze.custos
GROUP BY categoria;

-- 2. A correção: trocar a vírgula por ponto ANTES de converter.
--    replace(valor, ',', '.')   troca ',' por '.'
--    ROUND(x / 1000000, 1)      em milhões, com 1 casa decimal
--    Deve aparecer: pessoal no topo, com R$ 117,8 mi. Empresa de tecnologia gasta com gente:
--    quase dois terços dos R$ 193,35 mi de custo.
SELECT categoria,
       ROUND(SUM(CAST(replace(valor, ',', '.') AS DECIMAL(18,2))) / 1000000, 1) AS custo_milhoes
FROM lakehouse_vertice.bronze.custos
GROUP BY categoria
ORDER BY custo_milhoes DESC;
