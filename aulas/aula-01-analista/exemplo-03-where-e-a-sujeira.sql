-- ============================================
-- EXEMPLO 03: WHERE — filtrar, e achar a sujeira
-- ============================================
-- Conceito: WHERE, LIKE, IS NULL, COUNT(*) FILTER
-- Pergunta de negócio: dá para confiar nesse número?
-- Conexão com a noite 2: tudo que este exemplo acha é o que a silver conserta.
--
-- Este é o exemplo mais importante do dia. Dado sujo não dá erro:
-- ele dá um número errado, em silêncio, e a diretoria decide em cima dele.

-- 1. Data em dois formatos: 2025-03-14 e 14/03/2025 na mesma coluna
SELECT COUNT(*) FILTER (WHERE data_inicio LIKE '%/%') AS formato_brasileiro,
       COUNT(*) FILTER (WHERE data_inicio LIKE '%-%') AS formato_iso
FROM lakehouse_atlas.bronze.projetos;

-- 2. UF escrita de três jeitos
SELECT uf, COUNT(*) AS obras
FROM lakehouse_atlas.bronze.projetos
GROUP BY uf
ORDER BY upper(trim(uf));

-- 3. Tarefa com mais de 100% concluída. Não existe: é erro de digitação no cronograma.
SELECT tarefa_id, projeto_id, descricao, pct_concluido
FROM lakehouse_atlas.bronze.tarefas
WHERE CAST(pct_concluido AS DOUBLE) > 100
ORDER BY CAST(pct_concluido AS DOUBLE) DESC;

-- 4. Custo com vírgula decimal: '12345,67'. CAST disso quebra (ou vira nulo).
SELECT COUNT(*) FILTER (WHERE valor_real LIKE '%,%') AS com_virgula,
       COUNT(*)                                       AS total
FROM lakehouse_atlas.bronze.custos;

-- 5. Estorno: valor negativo. NÃO é erro, é informação: o lançamento foi revertido.
SELECT categoria, COUNT(*) AS estornos
FROM lakehouse_atlas.bronze.custos
WHERE valor_real LIKE '-%'
GROUP BY categoria;

-- 6. O mesmo fornecedor digitado de quatro jeitos no ERP de compras
SELECT fornecedor, COUNT(*) AS pedidos
FROM lakehouse_atlas.bronze.compras
WHERE lower(fornecedor) LIKE '%norte%'
GROUP BY fornecedor;

-- 7. Equipe duplicada no cadastro do RH
SELECT equipe_id, COUNT(*) AS vezes
FROM lakehouse_atlas.bronze.equipes
GROUP BY equipe_id
HAVING COUNT(*) > 1;

-- 8. RDO não preenchido
SELECT COUNT(*) AS rdos_vazios
FROM lakehouse_atlas.bronze.rdo
WHERE texto_livre IS NULL OR trim(texto_livre) IN ('', 'N/A', 'ver RDO físico');
