-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 07 (BÔNUS): ler um PDF com SQL
-- MAGIC Conceito: read_files com binaryFile e ai_parse_document
-- MAGIC Pergunta de negócio: o que o contrato da CodeForge diz sobre multa por atraso?
-- MAGIC Conexão com a noite 4: hoje o Databricks LÊ o PDF. Na quinta, a IA tira dele os campos
-- MAGIC (multa por dia, teto, aviso prévio) e calcula quanto a Vértice pode cobrar: R$ 1,12 mi.
-- MAGIC
-- MAGIC Antes: suba a pasta documentos/ do zip para o volume, como as outras
-- MAGIC   /Volumes/lakehouse_vertice/bronze/raw/documentos/contratos/*.pdf
-- MAGIC
-- MAGIC 1. O contrato da CodeForge, cláusula por cláusula.
-- MAGIC    format => 'binaryFile'     o read_files lê o PDF como arquivo, sem tentar interpretar
-- MAGIC    ai_parse_document(...)     uma IA lê o PDF e devolve os pedaços: título, seção, texto
-- MAGIC    variant_explode(...)       a lista de pedaços vira linhas, uma por pedaço
-- MAGIC    :type e :content           pegam o tipo e o texto de cada pedaço
-- MAGIC    Deve aparecer (leva uns 10 segundos): as cláusulas do contrato. Repare na CLÁUSULA 6:
-- MAGIC    multa de 0,5% por dia de atraso, limitada a 10% do valor da entrega.

-- COMMAND ----------

SELECT e.value:type::STRING    AS tipo,
       e.value:content::STRING AS texto
FROM (
  SELECT ai_parse_document(content, map('version', '2.0')) AS doc
  FROM read_files('/Volumes/lakehouse_vertice/bronze/raw/documentos/contratos/contrato_codeforge_consultoria_ltda.pdf',
                  format => 'binaryFile')
), LATERAL variant_explode(doc:document:elements) AS e;
