-- gold.postmortem_estruturado: cada postmortem em texto livre vira uma linha com colunas.
--
-- O postmortem é escrito por gente diferente, de jeitos diferentes: a duração vem como
-- "37 minutos", "1h25min" ou "das 14h10 às 15h45". Regra nenhuma pega tudo isso.
-- O ai_extract com um schema TIPADO pega: a duração já sai como número, em minutos,
-- e dá para somar. O ai_classify põe a causa raiz numa lista fechada.
--
-- São só ~100 postmortems: a IA roda em todos, em menos de um minuto, e o MERGE
-- garante que o incidente de amanhã é o único processado amanhã.

CREATE TABLE IF NOT EXISTS lakehouse_vertice.gold.postmortem_estruturado (
  incidente_id       STRING    COMMENT 'Identificador do incidente (INC-0001)',
  projeto_id         STRING    COMMENT 'Projeto relacionado ao incidente',
  data               DATE      COMMENT 'Data do incidente',
  severidade         STRING    COMMENT 'SEV1 (fora do ar), SEV2 (degradado) ou SEV3 (com contorno)',
  servico_afetado    STRING    COMMENT 'Serviço ou sistema afetado (extraído por IA)',
  causa_raiz         STRING    COMMENT 'Causa raiz em poucas palavras (extraída por IA)',
  categoria_causa    STRING    COMMENT 'Categoria da causa: deploy_sem_teste, configuracao, capacidade, dependencia_externa, pipeline_sem_dono',
  duracao_minutos    DOUBLE    COMMENT 'Duração do incidente em minutos (extraída por IA, já convertida)',
  usuarios_afetados  DOUBLE    COMMENT 'Quantos usuários do cliente foram afetados (extraído por IA)',
  texto_postmortem   STRING    COMMENT 'Texto original do postmortem',
  _extraido_em       TIMESTAMP COMMENT 'Quando esta linha foi extraída'
)
COMMENT 'Postmortems estruturados por IA (ai_extract com schema tipado + ai_classify): serviço afetado, causa raiz, categoria da causa, duração em minutos e usuários afetados. Use para responder quais projetos geram mais incidentes e por quê.';

MERGE INTO lakehouse_vertice.gold.postmortem_estruturado AS alvo
USING (
  WITH novos AS (
    SELECT p.*
    FROM lakehouse_vertice.silver.postmortems p
    LEFT ANTI JOIN lakehouse_vertice.gold.postmortem_estruturado e USING (incidente_id)
  ),
  com_ia AS (
    SELECT n.*,
           ai_extract(texto_postmortem,
             '{"servico_afetado":   {"type": "string", "description": "o serviço ou sistema que ficou fora do ar ou degradado"},
               "causa_raiz":        {"type": "string", "description": "a causa raiz do incidente, em poucas palavras"},
               "duracao_minutos":   {"type": "number", "description": "duração total do incidente convertida para minutos (1h25min = 85)"},
               "usuarios_afetados": {"type": "number", "description": "quantos usuários foram afetados"}}',
             map('version', '2.0')) AS extraido,
           ai_classify(texto_postmortem,
             '["deploy_sem_teste","configuracao","capacidade","dependencia_externa","pipeline_sem_dono"]',
             map('version', '2.0')):response[0]::STRING AS categoria_causa
    FROM novos n
  )
  SELECT incidente_id, projeto_id, data, severidade,
         extraido:response:servico_afetado::STRING    AS servico_afetado,
         extraido:response:causa_raiz::STRING         AS causa_raiz,
         categoria_causa,
         extraido:response:duracao_minutos::DOUBLE    AS duracao_minutos,
         extraido:response:usuarios_afetados::DOUBLE  AS usuarios_afetados,
         texto_postmortem,
         current_timestamp()                          AS _extraido_em
  FROM com_ia
) AS novo
ON alvo.incidente_id = novo.incidente_id
WHEN NOT MATCHED THEN INSERT *;

-- Incidentes por categoria de causa (só leitura)
SELECT categoria_causa, COUNT(*) AS incidentes, ROUND(SUM(duracao_minutos) / 60, 1) AS horas_fora_do_ar
FROM lakehouse_vertice.gold.postmortem_estruturado
GROUP BY categoria_causa
ORDER BY incidentes DESC;
