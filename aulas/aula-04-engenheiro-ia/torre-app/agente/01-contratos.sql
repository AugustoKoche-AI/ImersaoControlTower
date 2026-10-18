-- Noite 4 · O agente que lê contrato
--
-- "Por que a obra atrasou?" a gold já responde (rdo_estruturado). A pergunta
-- seguinte da diretoria é sempre a mesma: "E O QUE O CONTRATO DIZ?" — tem
-- multa? a chuva dá direito a prorrogação? o guindaste era nosso ou do cliente?
--
-- A resposta está em 8 PDFs no volume. Três passos, todos em SQL:
--   1. ai_parse_document  PDF → texto (o modelo lê a página, não o arquivo)
--   2. split por cláusula  texto → uma linha por cláusula (o Genie cita a cláusula)
--   3. ai_query com schema texto → colunas tipadas (multa, teto, chuva, içamento…)
--
-- O schema JSON no ai_query é a diferença entre "um texto bonito" e um dado
-- que dá para somar: o modelo é obrigado a devolver número, booleano e enum.
--
-- Custo medido no Free Edition: ~30 s para os 8 contratos (parse + extração).

-- 1. PDF → texto ---------------------------------------------------------------
CREATE OR REPLACE TABLE lakehouse_atlas.gold.contratos_texto
COMMENT 'Texto integral de cada contrato EPC, extraído do PDF com ai_parse_document.'
AS
SELECT regexp_extract(path, 'contrato_(P[0-9]+)\\.pdf', 1)                        AS projeto_id,
       path                                                                       AS arquivo,
       concat_ws('\n', transform(try_cast(ai_parse_document(content):document:elements AS ARRAY<VARIANT>),
                                 e -> try_cast(e:content AS STRING)))             AS texto,
       current_timestamp()                                                        AS _extraido_em
FROM read_files('/Volumes/lakehouse_atlas/bronze/raw/documentos/contratos/', format => 'binaryFile');

-- 2. Uma linha por cláusula ----------------------------------------------------
--    O PDF quebra linha no meio da frase: juntamos tudo e cortamos em "CLÁUSULA N - ".
CREATE OR REPLACE TABLE lakehouse_atlas.gold.contratos_clausulas
COMMENT 'Cláusulas dos contratos EPC (uma linha por cláusula): número, título e texto. Use para citar o que o contrato diz sobre multa, chuva, içamento, suprimentos, aditivos e reajuste.'
AS
WITH partes AS (
  SELECT projeto_id, arquivo,
         explode(split(regexp_replace(texto, '\\s+', ' '), '(?=CLÁUSULA [0-9]+ - )')) AS parte
  FROM lakehouse_atlas.gold.contratos_texto
)
SELECT projeto_id,
       CAST(regexp_extract(parte, '^CLÁUSULA ([0-9]+) - ', 1) AS INT)                        AS clausula_numero,
       trim(regexp_extract(parte, '^CLÁUSULA [0-9]+ - ([A-ZÁÉÍÓÚÂÊÔÃÕÇ ]+?) (?=[A-Z][a-zà-ú]|O |A |Os |As |Dias |Todos )', 1)) AS titulo,
       trim(regexp_replace(parte, '^CLÁUSULA [0-9]+ - [A-ZÁÉÍÓÚÂÊÔÃÕÇ ]+? (?=[A-Z][a-zà-ú]|O |A |Os |As |Dias |Todos )', '')) AS texto,
       arquivo
FROM partes
WHERE parte LIKE 'CLÁUSULA %';

-- 3. O contrato vira coluna ----------------------------------------------------
CREATE OR REPLACE TABLE lakehouse_atlas.gold.contratos_resumo
COMMENT 'Resumo estruturado de cada contrato EPC extraído por IA (ai_query com schema): multa diária, teto da multa, se chuva dá prorrogação, quem responde pelo içamento e pela estrutura metálica, prazo para pleitear aditivo, índice de reajuste e bônus por antecipação.'
AS
WITH extraido AS (
  SELECT projeto_id, arquivo,
         ai_query('databricks-meta-llama-3-3-70b-instruct',
           concat('Você é um analista de contratos de engenharia. Leia o contrato EPC abaixo e ',
                  'preencha os campos exatamente como o contrato diz. Responda só o JSON.\n\n', texto),
           responseFormat => '{
             "type": "json_schema",
             "json_schema": {"name": "contrato", "strict": true, "schema": {"type": "object", "properties": {
               "multa_dia_pct":          {"type": "number",  "description": "multa por dia de atraso, em % do valor global (cláusula de multa por atraso). Ex.: 0,05% = 0.05"},
               "teto_multa_pct":         {"type": "number",  "description": "limite máximo da multa, em % do valor do contrato"},
               "chuva_da_prorrogacao":   {"type": "boolean", "description": "true se dias de chuva acima da média podem deixar de contar como atraso; false se o risco climático está no preço"},
               "icamento_responsavel":   {"type": "string",  "enum": ["contratada", "contratante"], "description": "quem fornece guindastes e equipamentos de içamento"},
               "estrutura_fornecida_por":{"type": "string",  "enum": ["contratada", "contratante"], "description": "quem fornece a estrutura metálica principal / os materiais permanentes"},
               "prazo_aditivo_dias":     {"type": "integer", "description": "prazo em dias, contado do fato gerador, para a contratada pleitear aditivo de escopo (cláusula de aditivos)"},
               "reajuste":               {"type": "string",  "description": "índice de reajuste anual, ex.: IPCA ou INCC-DI"},
               "bonus_antecipacao":      {"type": "boolean", "description": "true se há bônus por conclusão antecipada"}
             }, "required": ["multa_dia_pct", "teto_multa_pct", "chuva_da_prorrogacao", "icamento_responsavel",
                             "estrutura_fornecida_por", "prazo_aditivo_dias", "reajuste", "bonus_antecipacao"]}}
           }') AS j
  FROM lakehouse_atlas.gold.contratos_texto
)
SELECT projeto_id,
       CAST(get_json_object(j, '$.multa_dia_pct') AS DOUBLE)          AS multa_dia_pct,
       CAST(get_json_object(j, '$.teto_multa_pct') AS DOUBLE)         AS teto_multa_pct,
       CAST(get_json_object(j, '$.chuva_da_prorrogacao') AS BOOLEAN)  AS chuva_da_prorrogacao,
       get_json_object(j, '$.icamento_responsavel')                   AS icamento_responsavel,
       get_json_object(j, '$.estrutura_fornecida_por')                AS estrutura_fornecida_por,
       CAST(get_json_object(j, '$.prazo_aditivo_dias') AS INT)        AS prazo_aditivo_dias,
       get_json_object(j, '$.reajuste')                               AS reajuste,
       CAST(get_json_object(j, '$.bonus_antecipacao') AS BOOLEAN)     AS bonus_antecipacao,
       arquivo,
       current_timestamp()                                            AS _extraido_em
FROM extraido;

-- 4. A pergunta da diretoria, já respondida em reais -----------------------------
--    Multa estimada = multa/dia × dias de atraso projetado × valor do contrato, com teto.
--    "Atraso excluível" = obra cujo contrato aceita chuva E cujo RDO registra chuva.
CREATE OR REPLACE VIEW lakehouse_atlas.gold.contratos_exposicao
COMMENT 'Exposição contratual de cada obra com contrato digitalizado: atraso projetado, multa estimada (com teto), dias de chuva registrados no RDO e se o contrato permite excluí-los, e quem responde pelo içamento.'
AS
WITH chuva AS (
  SELECT projeto_id, COUNT_IF(causa_atraso = 'chuva') AS rdos_chuva,
         COUNT_IF(causa_atraso = 'falta_equipamento') AS rdos_falta_equipamento
  FROM lakehouse_atlas.gold.rdo_estruturado GROUP BY projeto_id
)
SELECT o.projeto_id, o.obra, o.situacao, o.spi, o.atraso_projetado_dias, o.valor_contrato,
       r.multa_dia_pct, r.teto_multa_pct, r.chuva_da_prorrogacao, r.icamento_responsavel,
       coalesce(c.rdos_chuva, 0) AS rdos_chuva, coalesce(c.rdos_falta_equipamento, 0) AS rdos_falta_equipamento,
       CAST(o.valor_contrato * least(greatest(o.atraso_projetado_dias, 0) * r.multa_dia_pct, r.teto_multa_pct) / 100
            AS DECIMAL(18,2)) AS multa_estimada,
       greatest(o.atraso_projetado_dias, 0) * r.multa_dia_pct > r.teto_multa_pct AS multa_no_teto
FROM lakehouse_atlas.gold.obra_situacao_atual o
JOIN lakehouse_atlas.gold.contratos_resumo r USING (projeto_id)
LEFT JOIN chuva c USING (projeto_id);
