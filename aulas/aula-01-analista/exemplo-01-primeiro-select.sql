-- ============================================
-- EXEMPLO 01: SELECT — o que existe no catálogo?
-- ============================================
-- Conceito: SELECT, FROM, LIMIT, COUNT(*)
-- Pergunta de negócio: que obras a Atlas tem na carteira?
-- Conexão: antes de calcular qualquer KPI, olhe o dado. Sempre.

-- 1. A primeira olhada: 10 linhas de projetos
SELECT *
FROM lakehouse_atlas.bronze.projetos
LIMIT 10;

-- 2. Quantas obras? Quantas tarefas de cronograma? Quantos RDOs?
SELECT
    (SELECT COUNT(*) FROM lakehouse_atlas.bronze.projetos) AS obras,
    (SELECT COUNT(*) FROM lakehouse_atlas.bronze.tarefas)  AS tarefas,
    (SELECT COUNT(*) FROM lakehouse_atlas.bronze.rdo)      AS rdos,
    (SELECT COUNT(*) FROM lakehouse_atlas.bronze.custos)   AS lancamentos_de_custo;

-- 3. Só as colunas que importam para a diretoria
SELECT projeto_id, nome_projeto, cliente, setor, uf, valor_contrato, status
FROM lakehouse_atlas.bronze.projetos
LIMIT 10;

-- 4. Um RDO de verdade: é texto livre, escrito pelo engenheiro no fim do dia.
--    A causa do atraso está aqui dentro. Na noite 2, a IA vai tirar ela daqui.
SELECT data, projeto_id, texto_livre
FROM lakehouse_atlas.bronze.rdo
WHERE projeto_id = 'P011'
ORDER BY data DESC
LIMIT 5;
