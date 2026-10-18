-- gold.rdo_estruturado: o RDO em texto livre vira coluna.
--
-- "Por que a obra atrasou?" A resposta está escrita no RDO, em português livre,
-- por um engenheiro no fim do dia. Aqui ela vira dado: causa_atraso, clima,
-- dias_impacto e incidente.
--
-- Três ferramentas, cada uma onde ela é a certa:
--   · REGRA     para o que é padrão fixo: "Clima: chuvoso", "Impacto estimado de 3 dias",
--                e o dia sem ocorrência (70% dos RDOs). Custo zero, resposta exata.
--   · IA        ai_classify() para o texto livre COM ocorrência dos últimos 90 dias.
--   · PALAVRA-CHAVE  para o histórico antigo, onde a IA custaria uma hora de warehouse.
--
-- Medido no Free Edition: ai_classify faz ~3,7 RDOs por segundo. Os 13,7 mil
-- RDOs levariam ~1 hora; os ~600 com ocorrência nos últimos 90 dias levam ~3 minutos.
--
-- E o MERGE só processa RDO que ainda não está na tabela: rodar de novo amanhã
-- custa só os RDOs de amanhã. IA cobra por chamada — não reprocesse o passado.

CREATE TABLE IF NOT EXISTS lakehouse_atlas.gold.rdo_estruturado (
  rdo_id           STRING    COMMENT 'Identificador do RDO',
  projeto_id       STRING    COMMENT 'Obra',
  data             DATE      COMMENT 'Dia do relatório',
  clima            STRING    COMMENT 'Clima declarado no RDO: ensolarado, nublado ou chuvoso',
  causa_atraso     STRING    COMMENT 'Causa da ocorrência: chuva, falta_material, falta_equipamento, mao_de_obra, retrabalho, cliente, sem_ocorrencia ou nao_reportado',
  dias_impacto     DOUBLE    COMMENT 'Impacto declarado em dias (meio turno = 0,5). Nulo quando o RDO não diz.',
  incidente        BOOLEAN   COMMENT 'O RDO registra quase acidente ou incidente de segurança',
  metodo           STRING    COMMENT 'Como a causa foi obtida: regra, ia ou palavra_chave',
  texto_livre      STRING    COMMENT 'Texto original do RDO',
  _classificado_em TIMESTAMP COMMENT 'Quando esta linha foi classificada'
)
COMMENT 'RDO estruturado: causa do atraso, clima, dias de impacto e incidente extraídos do texto livre (regra + ai_classify + palavra-chave).';

MERGE INTO lakehouse_atlas.gold.rdo_estruturado AS alvo
USING (
  WITH novos AS (
    SELECT r.*, lower(coalesce(r.texto_livre, '')) AS t
    FROM lakehouse_atlas.silver.rdo r
    LEFT ANTI JOIN lakehouse_atlas.gold.rdo_estruturado e ON e.rdo_id = r.rdo_id
  ),
  marcado AS (
    SELECT *,
           CASE WHEN rdo_vazio THEN 'regra'
                WHEN t RLIKE 'sem ocorr|ocorrências: nenhuma|dia produtivo' THEN 'regra'
                WHEN data >= DATE'2026-07-18' THEN 'ia'              -- últimos 90 dias até 16/10/2026
                ELSE 'palavra_chave' END AS metodo
    FROM novos
  ),
  com_ia AS (
    SELECT rdo_id, ai_classify(texto_livre, array('chuva', 'falta_material', 'falta_equipamento',
                                                  'mao_de_obra', 'retrabalho', 'cliente', 'sem_ocorrencia')) AS causa_ia
    FROM marcado WHERE metodo = 'ia'
  )
  SELECT m.rdo_id, m.projeto_id, m.data,
         nullif(regexp_extract(m.t, 'clima: ([a-zçã]+)', 1), '')                  AS clima,
         CASE WHEN m.rdo_vazio THEN 'nao_reportado'
              WHEN m.metodo = 'regra' THEN 'sem_ocorrencia'
              WHEN m.metodo = 'ia' THEN i.causa_ia
              WHEN m.t RLIKE 'guindaste|içamento' THEN 'falta_equipamento'
              WHEN m.t RLIKE 'cliente|permissão de trabalho' THEN 'cliente'
              WHEN m.t RLIKE 'chuva|precipitação|temporal|encharcado' THEN 'chuva'
              WHEN m.t RLIKE 'aguardando|falta de|não entregou|em estoque|fornecedor' THEN 'falta_material'
              WHEN m.t RLIKE 'efetivo reduzido|faltas|rotatividade|soldadores' THEN 'mao_de_obra'
              WHEN m.t RLIKE 'retrabalho|reprovad' THEN 'retrabalho'
              ELSE 'sem_ocorrencia' END                                         AS causa_atraso,
         CASE WHEN m.t RLIKE 'impacto estimado de [0-9]+ dias'
                   THEN CAST(regexp_extract(m.t, 'impacto estimado de ([0-9]+) dias', 1) AS DOUBLE)
              WHEN m.t LIKE '%impacto estimado: 1 dia%' THEN 1.0
              WHEN m.t LIKE '%meio turno%' THEN 0.5
              WHEN m.t LIKE '%sem impacto%' THEN 0.0 END                        AS dias_impacto,
         m.t LIKE '%quase acidente%'                                            AS incidente,
         m.metodo,
         m.texto_livre,
         current_timestamp()                                                    AS _classificado_em
  FROM marcado m
  LEFT JOIN com_ia i USING (rdo_id)
) AS novo
ON alvo.rdo_id = novo.rdo_id
WHEN NOT MATCHED THEN INSERT *;

-- Quanto a IA e a palavra-chave concordam, nos RDOs em que as duas poderiam ser usadas?
-- (só leitura: o resultado aparece na saída da tarefa)
SELECT metodo, causa_atraso, COUNT(*) AS rdos
FROM lakehouse_atlas.gold.rdo_estruturado
GROUP BY metodo, causa_atraso
ORDER BY metodo, rdos DESC;
