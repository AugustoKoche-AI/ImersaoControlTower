-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 00 (BÔNUS): TIME TRAVEL — errei, e agora?
-- MAGIC Conceito: toda tabela Delta guarda versões. DESCRIBE HISTORY, VERSION AS OF, RESTORE
-- MAGIC Pergunta de negócio: alguém duplicou um projeto e a carteira do dono ficou errada. Dá para voltar?
-- MAGIC Conexão: a bronze não é "só um arquivo". Cada mudança vira uma versão, e nenhuma se perde.
-- MAGIC          Rode bloco a bloco (selecione o bloco e Ctrl+Enter), não tudo de uma vez.
-- MAGIC
-- MAGIC A gente brinca numa CÓPIA do cadastro, para não mexer na bronze de verdade.
-- MAGIC
-- MAGIC 1. Uma cópia do cadastro de projetos. Ela nasce na versão 0.

-- COMMAND ----------

DROP TABLE IF EXISTS lakehouse_vertice.bronze.projetos_copia;

-- COMMAND ----------

CREATE TABLE lakehouse_vertice.bronze.projetos_copia AS
SELECT * FROM lakehouse_vertice.bronze.projetos;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Como está hoje: 60 projetos, carteira de R$ 305,2 mi

-- COMMAND ----------

SELECT COUNT(*)                                                 AS projetos,
       ROUND(SUM(CAST(valor_contrato AS DECIMAL(18,2))) / 1e6, 1) AS carteira_mi
FROM lakehouse_vertice.bronze.projetos_copia;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. O erro: alguém rodou a carga do PRJ-021 duas vezes. O projeto agora aparece duplicado.

-- COMMAND ----------

INSERT INTO lakehouse_vertice.bronze.projetos_copia
SELECT * FROM lakehouse_vertice.bronze.projetos_copia
WHERE projeto_id = 'PRJ-021';

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. O estrago: 61 projetos, e a carteira "cresceu" de R$ 305,2 mi para R$ 318,8 mi sem nenhum contrato novo

-- COMMAND ----------

SELECT COUNT(*)                                                 AS projetos,
       ROUND(SUM(CAST(valor_contrato AS DECIMAL(18,2))) / 1e6, 1) AS carteira_mi
FROM lakehouse_vertice.bronze.projetos_copia;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 5. O histórico: cada linha é uma versão. Versão 0 = a cópia; versão 1 = o INSERT errado.
-- MAGIC    Repare nas colunas operation (CREATE TABLE AS SELECT, WRITE) e operationMetrics (numOutputRows: 1).

-- COMMAND ----------

DESCRIBE HISTORY lakehouse_vertice.bronze.projetos_copia;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 6. A viagem no tempo: a tabela como ela era ANTES do erro. Sem restaurar nada, só olhando.

-- COMMAND ----------

SELECT COUNT(*)                                                 AS projetos,
       ROUND(SUM(CAST(valor_contrato AS DECIMAL(18,2))) / 1e6, 1) AS carteira_mi
FROM lakehouse_vertice.bronze.projetos_copia VERSION AS OF 0;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 7. Volta para a versão 0 de verdade.

-- COMMAND ----------

RESTORE TABLE lakehouse_vertice.bronze.projetos_copia TO VERSION AS OF 0;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 8. Conferindo: 60 projetos de novo. E o histórico ganhou mais uma linha (RESTORE):
-- MAGIC    voltar no tempo também fica registrado.

-- COMMAND ----------

SELECT COUNT(*)                                                 AS projetos,
       ROUND(SUM(CAST(valor_contrato AS DECIMAL(18,2))) / 1e6, 1) AS carteira_mi
FROM lakehouse_vertice.bronze.projetos_copia;

-- COMMAND ----------

DESCRIBE HISTORY lakehouse_vertice.bronze.projetos_copia;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 9. Arrumando a casa: a cópia não faz parte da bronze. (Antes de apagar, dá uma olhada
-- MAGIC    na aba History dela no Catalog: é o mesmo histórico, pela interface.)

-- COMMAND ----------

DROP TABLE lakehouse_vertice.bronze.projetos_copia;
