-- ============================================
-- EXEMPLO 03: WHERE — filtrar, e achar a sujeira
-- ============================================
-- Conceito: WHERE, LIKE
-- Pergunta de negócio: dá para confiar nesse número?
-- Conexão com a noite 2: tudo que este exemplo acha é o que a silver conserta.
--
-- Dado sujo não dá erro: dá um número errado, em silêncio, e a diretoria decide em cima dele.
--
-- O WHERE vem depois do FROM e diz QUAIS linhas entram:
--   WHERE coluna = 'valor'      igual a
--   WHERE coluna LIKE '%/%'     "parece com". O % quer dizer "qualquer coisa aqui":
--                               '%/%' = tem uma barra em algum lugar

-- 1. A data de início em dois formatos na mesma coluna: 14/03/2025 e 2025-03-14.
--    Quantos projetos estão no formato com barra?
--    Deve aparecer: 24 (os outros 36 estão como 2025-03-14). Uma conta de prazo que só
--    entenda um dos formatos erra 24 projetos.
SELECT COUNT(*) AS formato_brasileiro
FROM lakehouse_vertice.bronze.projetos
WHERE data_inicio LIKE '%/%';

-- 2. Excel: a linha de TOTAL que o gerente deixou no fim de cada planilha.
--    Deve aparecer: 20 linhas, uma por planilha. Quem soma a coluna de horas inteira
--    conta tudo duas vezes.
SELECT arquivo, tarefa, horas_previstas
FROM lakehouse_vertice.bronze.excel_tarefas
WHERE tarefa = 'TOTAL';

-- 3. Financeiro: custo com vírgula decimal ('12345,67'). Para o computador, isso não é número.
--    Deve aparecer: 671 lançamentos. O exemplo 04 mostra o estrago.
SELECT COUNT(*) AS com_virgula
FROM lakehouse_vertice.bronze.custos
WHERE valor LIKE '%,%';
