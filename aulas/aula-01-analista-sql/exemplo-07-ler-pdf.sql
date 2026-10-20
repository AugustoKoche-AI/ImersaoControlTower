-- ============================================
-- EXEMPLO 07 (BÔNUS): ler um PDF com SQL
-- ============================================
-- Conceito: read_files com binaryFile e ai_parse_document
-- Pergunta de negócio: o que o contrato da CodeForge diz sobre multa por atraso?
-- Conexão com a noite 4: hoje o Databricks LÊ o PDF. Na quinta, a IA tira dele os campos
-- (multa por dia, teto, aviso prévio) e calcula quanto a Vértice pode cobrar: R$ 1,12 mi.
--
-- Antes: suba a pasta documentos/ do zip para o volume, como as outras
--   /Volumes/lakehouse_vertice/bronze/raw/documentos/contratos/*.pdf

-- 1. O contrato da CodeForge, cláusula por cláusula.
--    format => 'binaryFile'     o read_files lê o PDF como arquivo, sem tentar interpretar
--    ai_parse_document(...)     uma IA lê o PDF e devolve os pedaços: título, seção, texto
--    variant_explode(...)       a lista de pedaços vira linhas, uma por pedaço
--    :type e :content           pegam o tipo e o texto de cada pedaço
--    Deve aparecer (leva uns 10 segundos): as cláusulas do contrato. Repare na CLÁUSULA 6:
--    multa de 0,5% por dia de atraso, limitada a 10% do valor da entrega.
SELECT e.value:type::STRING    AS tipo,
       e.value:content::STRING AS texto
FROM (
  SELECT ai_parse_document(content, map('version', '2.0')) AS doc
  FROM read_files('/Volumes/lakehouse_vertice/bronze/raw/documentos/contratos/contrato_codeforge_consultoria_ltda.pdf',
                  format => 'binaryFile')
), LATERAL variant_explode(doc:document:elements) AS e;
