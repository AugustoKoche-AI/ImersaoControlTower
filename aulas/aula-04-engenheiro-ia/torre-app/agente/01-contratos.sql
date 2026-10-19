-- Noite 4 · O agente que lê contrato e manual
--
-- "Quais projetos estão atrasados?" a gold já responde. A pergunta seguinte do
-- dono é sempre outra: "E O QUE O CONTRATO DIZ?" — dá para cobrar multa da
-- consultoria que atrasou? qual contrato renova sozinho se ninguém avisar? e o
-- manual da empresa, o que manda fazer no freeze da Black Friday?
--
-- A resposta está em 9 PDFs no volume (8 contratos de fornecedor e SaaS + o manual
-- de tecnologias). Tudo em SQL:
--   1. ai_parse_document   PDF → elementos (título de seção e texto), UMA vez, guardado
--   2. agrupar             cláusula por cláusula, seção por seção (o Genie cita a fonte)
--   3. ai_extract          texto → colunas TIPADAS (número, data, booleano) com JSON schema
--   4. a conta do dono     multa que dá para cobrar da CodeForge e avisos prévios vencendo
--
-- A lição do passo 3: ai_extract SEM schema devolve texto ("0,5%", "sim"); COM schema
-- tipado devolve 0.5 e true — dado que dá para somar, comparar e filtrar.
--
-- Hoje do dataset: 16/10/2026. Custo medido no Free Edition: ~1 min para os 9 PDFs.

-- 1. PDF → elementos --------------------------------------------------------------
--    ai_parse_document é a chamada cara: roda uma vez e o resultado vira tabela.
CREATE OR REPLACE TABLE lakehouse_vertice.gold.documentos_elementos
COMMENT 'Elementos dos PDFs (contratos de fornecedor e manual de tecnologias) extraídos com ai_parse_document: documento, ordem, tipo (title, section_header, text) e conteúdo.'
AS
WITH arquivos AS (
  SELECT 'contrato' AS tipo_documento, path, content
  FROM read_files('/Volumes/lakehouse_vertice/bronze/raw/documentos/contratos/', format => 'binaryFile')
  UNION ALL
  SELECT 'manual', path, content
  FROM read_files('/Volumes/lakehouse_vertice/bronze/raw/documentos/manual/', format => 'binaryFile')
),
parseado AS (
  SELECT tipo_documento, path,
         try_cast(ai_parse_document(content, map('version', '2.0')):document:elements AS ARRAY<VARIANT>) AS elementos
  FROM arquivos
)
SELECT tipo_documento,
       regexp_extract(path, '([^/]+)\\.pdf$', 1)                AS documento,
       pos                                                      AS ordem,
       e:type::STRING                                           AS tipo,
       regexp_replace(trim(e:content::STRING), '\\s+', ' ')     AS conteudo,
       path                                                     AS arquivo
FROM parseado
LATERAL VIEW posexplode(elementos) AS pos, e;

-- 2a. Uma linha por cláusula --------------------------------------------------------
--     Cada texto pertence ao último título de seção ("CLÁUSULA 6 - MULTA POR ATRASO") que veio antes dele.
CREATE OR REPLACE TABLE lakehouse_vertice.gold.contratos_clausulas
COMMENT 'Cláusulas dos contratos de fornecedor e SaaS da Vértice (uma linha por cláusula): fornecedor, número, título e texto. Use para citar o que o contrato diz sobre multa, SLA, renovação, aviso prévio, reajuste e rescisão.'
AS
WITH marcado AS (
  SELECT *,
         last_value(CASE WHEN tipo = 'section_header' THEN conteudo END, true)
           OVER (PARTITION BY documento ORDER BY ordem) AS secao
  FROM lakehouse_vertice.gold.documentos_elementos
  WHERE tipo_documento = 'contrato'
),
fornecedor AS (
  SELECT documento, trim(regexp_extract(conteudo, 'CONTRATADA: (.+)$', 1)) AS fornecedor
  FROM lakehouse_vertice.gold.documentos_elementos
  WHERE tipo_documento = 'contrato' AND conteudo LIKE 'CONTRATANTE:%'
)
SELECT f.fornecedor,
       CAST(regexp_extract(m.secao, 'CLÁUSULA ([0-9]+)', 1) AS INT)   AS clausula_numero,
       trim(regexp_extract(m.secao, 'CLÁUSULA [0-9]+ - (.+)$', 1))     AS titulo,
       concat_ws(' ', collect_list(m.conteudo))                         AS texto,
       m.documento
FROM marcado m
JOIN fornecedor f USING (documento)
WHERE m.tipo = 'text' AND m.secao LIKE 'CLÁUSULA%'
GROUP BY f.fornecedor, m.secao, m.documento;

-- 2b. Uma linha por seção do manual -------------------------------------------------
CREATE OR REPLACE TABLE lakehouse_vertice.gold.manual_secoes
COMMENT 'Manual de Tecnologias e Práticas de Engenharia da Vértice (uma linha por seção): stack padrão, ambientes, política de deploy, CHANGE FREEZE de varejo, alocação de SRE, severidade de incidentes, postmortem, status semanal e farol, uso de consultorias, segurança e LGPD.'
AS
WITH marcado AS (
  SELECT *,
         last_value(CASE WHEN tipo = 'section_header' THEN conteudo END, true)
           OVER (PARTITION BY documento ORDER BY ordem) AS secao
  FROM lakehouse_vertice.gold.documentos_elementos
  WHERE tipo_documento = 'manual'
)
SELECT CAST(regexp_extract(secao, '^([0-9]+)\\.', 1) AS INT)   AS secao_numero,
       trim(regexp_extract(secao, '^[0-9]+\\. (.+)$', 1))     AS titulo,
       concat_ws(' ', collect_list(conteudo))                 AS texto
FROM marcado
WHERE tipo = 'text' AND secao RLIKE '^[0-9]+\\.'
GROUP BY secao;

-- 3a. A lição: ai_extract SEM schema devolve TEXTO ------------------------------------
--     (só leitura) Repare: '0,5%' e 'sim' são strings. Não dá para somar nem comparar.
SELECT f.fornecedor,
       ai_extract(t.texto, '["multa_atraso", "renovacao_automatica", "aviso_previo"]', map('version', '2.0')):response AS sem_schema
FROM (SELECT documento, concat_ws(' ', collect_list(conteudo)) AS texto
      FROM lakehouse_vertice.gold.documentos_elementos WHERE tipo_documento = 'contrato' GROUP BY documento) t
JOIN (SELECT DISTINCT documento, fornecedor FROM lakehouse_vertice.gold.contratos_clausulas) f USING (documento)
LIMIT 3;

-- 3b. COM schema tipado: o contrato vira coluna ---------------------------------------
CREATE OR REPLACE TABLE lakehouse_vertice.gold.contratos_resumo
COMMENT 'Resumo estruturado de cada contrato de fornecedor e SaaS, extraído por IA (ai_extract com JSON schema tipado): objeto, valor anual, fim da vigência, renovação automática, aviso prévio em dias, multa por atraso (% ao dia), teto da multa (%), SLA e índice de reajuste. multa_atraso_pct_dia nulo = contrato sem multa por atraso.'
AS
WITH texto AS (
  SELECT c.documento, c.fornecedor,
         concat_ws(' ', collect_list(concat('CLÁUSULA ', c.clausula_numero, ' - ', c.titulo, ': ', c.texto))) AS texto
  FROM lakehouse_vertice.gold.contratos_clausulas c
  GROUP BY c.documento, c.fornecedor
),
extraido AS (
  SELECT documento, fornecedor,
         ai_extract(texto,
           '{"objeto":                {"type": "string",  "description": "o que o fornecedor presta, em poucas palavras, em português"},
             "valor_anual":           {"type": "number",  "description": "valor anual estimado do contrato, em reais (R$ 14.800.000,00 = 14800000)"},
             "data_fim_vigencia":     {"type": "string",  "description": "último dia da vigência, no formato AAAA-MM-DD"},
             "renovacao_automatica":  {"type": "boolean", "description": "true se o contrato renova sozinho sem manifestação das partes"},
             "aviso_previo_dias":     {"type": "integer", "description": "dias de antecedência do fim da vigência para avisar que NÃO vai renovar (ou para formalizar a renovação, se não for automática)"},
             "multa_atraso_pct_dia":  {"type": "number",  "description": "multa por atraso em % do valor da entrega por dia (0,5% = 0.5). Nulo se não há multa por atraso"},
             "teto_multa_pct":        {"type": "number",  "description": "limite máximo da multa em % do valor da entrega. Nulo se não há multa"},
             "sla":                   {"type": "string",  "description": "o nível de serviço que o fornecedor se obriga a cumprir, copiado do contrato, em português"},
             "reajuste":              {"type": "string",  "description": "índice de reajuste anual, ex.: IPCA"}}',
           map('version', '2.0')) AS j
  FROM texto
)
SELECT fornecedor,
       j:response:objeto::STRING                        AS objeto,
       CAST(j:response:valor_anual::DOUBLE AS DECIMAL(18,2)) AS valor_anual,
       try_to_date(j:response:data_fim_vigencia::STRING) AS data_fim_vigencia,
       j:response:renovacao_automatica::BOOLEAN         AS renovacao_automatica,
       j:response:aviso_previo_dias::INT                AS aviso_previo_dias,
       j:response:multa_atraso_pct_dia::DOUBLE          AS multa_atraso_pct_dia,
       j:response:teto_multa_pct::DOUBLE                AS teto_multa_pct,
       j:response:sla::STRING                           AS sla,
       j:response:reajuste::STRING                      AS reajuste,
       documento,
       current_timestamp()                              AS _extraido_em
FROM extraido;

-- 4a. A conta do dono: quanto dá para cobrar da consultoria que atrasou --------------
--     Multa = valor da entrega × % ao dia × dias de atraso, limitada ao teto do contrato.
--     Entregue com atraso: conta os dias até a entrega. Ainda em aberto: conta até hoje.
CREATE OR REPLACE VIEW lakehouse_vertice.gold.contratos_multa_fornecedor
COMMENT 'Multa contratual que a Vértice pode cobrar de cada fornecedor por entrega atrasada: valor da entrega, dias de atraso (até a entrega ou até hoje, se em aberto), multa % ao dia e teto do contrato, e a multa calculada. na_vigencia_atual = entrega prometida dentro dos 12 meses do contrato vigente (o que dá para descontar das próximas faturas). Some multa_cobravel por fornecedor para o total.'
AS
WITH atrasos AS (
  SELECT e.entrega_id, e.projeto_id, e.fornecedor, e.item, e.valor, e.data_prometida, e.data_entrega,
         CASE WHEN e.data_entrega IS NOT NULL THEN e.dias_de_atraso_na_entrega
              ELSE datediff(DATE'2026-10-16', e.data_prometida) END AS dias_de_atraso,
         e.data_entrega IS NULL                                     AS ainda_em_aberto
  FROM lakehouse_vertice.silver.entregas_fornecedor e
  WHERE (e.data_entrega IS NOT NULL AND e.dias_de_atraso_na_entrega > 0) OR e.em_atraso
)
SELECT a.*, r.multa_atraso_pct_dia, r.teto_multa_pct,
       a.data_prometida > add_months(r.data_fim_vigencia, -12)                                             AS na_vigencia_atual,
       CAST(a.valor * least(a.dias_de_atraso * r.multa_atraso_pct_dia, r.teto_multa_pct) / 100 AS DECIMAL(18,2)) AS multa_cobravel,
       a.dias_de_atraso * r.multa_atraso_pct_dia >= r.teto_multa_pct                                           AS multa_no_teto
FROM atrasos a
JOIN lakehouse_vertice.gold.contratos_resumo r ON lower(r.fornecedor) = lower(a.fornecedor)
WHERE r.multa_atraso_pct_dia IS NOT NULL;

-- 4b. A agenda do dono: aviso prévio vencendo ou vencido ------------------------------
--     Data limite = fim da vigência − aviso prévio. Passou dela sem avisar, o contrato
--     renovou sozinho (renovação automática) ou o serviço corre risco de parar (sem renovação).
CREATE OR REPLACE VIEW lakehouse_vertice.gold.contratos_avisos
COMMENT 'Prazos de aviso prévio dos contratos de fornecedor e SaaS em relação a hoje (16/10/2026): data limite (fim da vigência menos aviso prévio), dias até ela e a situação (vencido, vence em até 60 dias, ok). O que fazer depende de renovacao_automatica.'
AS
SELECT fornecedor, objeto, valor_anual, data_fim_vigencia, renovacao_automatica, aviso_previo_dias,
       date_sub(data_fim_vigencia, aviso_previo_dias)                                AS data_limite_aviso,
       datediff(date_sub(data_fim_vigencia, aviso_previo_dias), DATE'2026-10-16')    AS dias_ate_limite,
       CASE WHEN date_sub(data_fim_vigencia, aviso_previo_dias) < DATE'2026-10-16' THEN 'vencido'
            WHEN datediff(date_sub(data_fim_vigencia, aviso_previo_dias), DATE'2026-10-16') <= 60 THEN 'vence em até 60 dias'
            ELSE 'ok' END                                                            AS situacao_aviso,
       CASE WHEN renovacao_automatica
            THEN 'renova sozinho: avisar até a data limite se NÃO quiser renovar'
            ELSE 'não renova sozinho: formalizar a renovação até a data limite ou o serviço para' END AS o_que_fazer
FROM lakehouse_vertice.gold.contratos_resumo;

-- Conferência rápida (só leitura)
SELECT fornecedor, ROUND(SUM(multa_cobravel), 2) AS multa_cobravel_total,
       ROUND(SUM(multa_cobravel) FILTER (WHERE na_vigencia_atual), 2) AS multa_na_vigencia_atual,
       COUNT(*) AS entregas_atrasadas
FROM lakehouse_vertice.gold.contratos_multa_fornecedor GROUP BY fornecedor ORDER BY multa_cobravel_total DESC;
