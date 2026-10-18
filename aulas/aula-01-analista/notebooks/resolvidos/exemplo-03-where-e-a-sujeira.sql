-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 03: WHERE — filtrar, e achar a sujeira
-- MAGIC Conceito: WHERE, LIKE, IS NULL, COUNT(*) FILTER
-- MAGIC Pergunta de negócio: dá para confiar nesse número?
-- MAGIC Conexão com a noite 2: tudo que este exemplo acha é o que a silver conserta.
-- MAGIC
-- MAGIC Este é o exemplo mais importante do dia. Dado sujo não dá erro:
-- MAGIC ele dá um número errado, em silêncio, e a diretoria decide em cima dele.
-- MAGIC
-- MAGIC 1. Data em dois formatos: 2025-03-14 e 14/03/2025 na mesma coluna

-- COMMAND ----------

SELECT COUNT(*) FILTER (WHERE data_inicio LIKE '%/%') AS formato_brasileiro,
       COUNT(*) FILTER (WHERE data_inicio LIKE '%-%') AS formato_iso
FROM lakehouse_vertice.bronze.projetos;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. A ferramenta escrita de vários jeitos, e projeto sem o código da ferramenta

-- COMMAND ----------

SELECT ferramenta, COUNT(*) AS projetos,
       COUNT(*) FILTER (WHERE codigo_ferramenta IS NULL) AS sem_codigo
FROM lakehouse_vertice.bronze.projetos
GROUP BY ferramenta
ORDER BY lower(ferramenta);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. Excel: a mesma coluna de data tem texto ('03/02/2026') e número de série do Excel ('46056')

-- COMMAND ----------

SELECT COUNT(*) FILTER (WHERE inicio_previsto LIKE '%/%')     AS data_como_texto,
       COUNT(*) FILTER (WHERE inicio_previsto NOT LIKE '%/%') AS data_como_numero
FROM lakehouse_vertice.bronze.excel_tarefas;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. Excel: o % concluído vem como '45%', '10,5%' ou 0.45. E tem tarefa com MAIS de 100%.

-- COMMAND ----------

SELECT pct_concluido, COUNT(*) AS tarefas
FROM lakehouse_vertice.bronze.excel_tarefas
WHERE pct_concluido NOT LIKE '%\%%' OR pct_concluido LIKE '1__%'
GROUP BY pct_concluido
ORDER BY tarefas DESC
LIMIT 15;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 5. Excel: a linha de TOTAL que o gerente deixou no fim da planilha. Somar tudo conta duas vezes.

-- COMMAND ----------

SELECT arquivo, tarefa, horas_previstas
FROM lakehouse_vertice.bronze.excel_tarefas
WHERE tarefa = 'TOTAL';

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 6. ClickUp: o status "concluído" escrito de 4 jeitos, "em andamento" de 5

-- COMMAND ----------

SELECT status.status AS status, COUNT(*) AS tarefas
FROM lakehouse_vertice.bronze.clickup_tarefas
GROUP BY status.status
ORDER BY tarefas DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 7. MS Project: tarefa-resumo (Summary = 1) soma as horas das tarefas de baixo.
-- MAGIC    Quem soma a coluna Work inteira conta as horas três vezes (projeto, fase, tarefa).

-- COMMAND ----------

SELECT Summary, OutlineLevel, COUNT(*) AS linhas
FROM lakehouse_vertice.bronze.msproject_tarefas
GROUP BY Summary, OutlineLevel
ORDER BY OutlineLevel;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 8. Custo com vírgula decimal: '12345,67'. CAST disso quebra (ou vira nulo).

-- COMMAND ----------

SELECT COUNT(*) FILTER (WHERE valor LIKE '%,%') AS com_virgula,
       COUNT(*)                                  AS total
FROM lakehouse_vertice.bronze.custos;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 9. Estorno: valor negativo. NÃO é erro, é informação: o lançamento foi revertido.

-- COMMAND ----------

SELECT categoria, COUNT(*) AS estornos
FROM lakehouse_vertice.bronze.custos
WHERE valor LIKE '-%'
GROUP BY categoria;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 10. A mesma consultoria digitada de quatro jeitos em compras

-- COMMAND ----------

SELECT fornecedor, COUNT(*) AS entregas
FROM lakehouse_vertice.bronze.entregas_fornecedor
WHERE lower(fornecedor) LIKE '%forge%'
GROUP BY fornecedor;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 11. Pessoa duplicada no cadastro do RH

-- COMMAND ----------

SELECT colaborador_id, COUNT(*) AS vezes
FROM lakehouse_vertice.bronze.colaboradores
GROUP BY colaborador_id
HAVING COUNT(*) > 1;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 12. Status semanal não preenchido

-- COMMAND ----------

SELECT COUNT(*) AS status_vazios
FROM lakehouse_vertice.bronze.status_semanal
WHERE texto_status IS NULL OR trim(texto_status) IN ('', 'N/A', 'ver ata da reunião');
