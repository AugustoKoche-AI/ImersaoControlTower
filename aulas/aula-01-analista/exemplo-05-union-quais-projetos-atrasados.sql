-- ============================================
-- EXEMPLO 05: UNION — as três ferramentas numa fila só
-- ============================================
-- Conceito: UNION ALL, VIEW, CASE, JOIN, WITH
-- Pergunta de negócio: QUAIS PROJETOS ESTÃO MAIS ATRASADOS?
--
-- É a primeira pergunta do dono, e ninguém na Vértice sabia responder: 20 projetos estão
-- no Excel, 25 no ClickUp e 15 no MS Project. Cada ferramenta guarda a mesma informação
-- (a tarefa, quando devia começar e terminar, quanto está pronta, quantas horas) de um jeito.
--
-- O plano:
--   bloco 1   traduzir cada ferramenta para as MESMAS 7 colunas e empilhar as três (UNION ALL)
--   bloco 2   com tudo numa fila só, calcular o atraso de cada projeto (SPI)
-- É um RASCUNHO feito à mão. Na noite 2 isso vira pipeline de verdade (a silver).
--
-- O "hoje" do dataset é 16/10/2026: nunca use current_date() aqui,
-- senão o seu número muda todo dia e não bate com o de ninguém.

-- 1. O rascunho: as tarefas das três ferramentas, no mesmo formato, numa view.
--
--    CREATE OR REPLACE VIEW nome AS ...   guarda a consulta com um nome. Não copia o dado:
--                                         toda vez que alguém lê a view, a consulta roda de novo.
--    UNION ALL                            empilha uma consulta embaixo da outra.
--                                         Regra: todas com as mesmas colunas, na mesma ordem.
--    CASE WHEN ... THEN ... ELSE ... END  o "se" do SQL
--
--    As 7 colunas: projeto_id · ferramenta · tarefa · inicio_baseline · fim_baseline
--                  · pct_concluido · horas       (baseline = o plano original)
--
--    Deve aparecer: OK. A view bronze.rascunho_tarefas aparece no Catalog, com 4.917 tarefas.
CREATE OR REPLACE VIEW lakehouse_vertice.bronze.rascunho_tarefas
COMMENT 'Rascunho da noite 1: tarefas do Excel, ClickUp e MS Project empilhadas à mão. Na noite 2 vira silver.tarefas.'
AS
-- ---------- EXCEL ----------
SELECT -- o projeto está no nome do arquivo: 'Cronograma PRJ-002.xlsx' → pega "PRJ-" + 3 dígitos
       regexp_extract(arquivo, 'PRJ-[0-9]{3}', 0)                         AS projeto_id,
       'excel'                                                            AS ferramenta,
       tarefa,
       -- data com barra ('06/03/2025') → lê como dd/MM/yyyy;
       -- senão é o número de série do Excel (45700 = dias contados desde 30/12/1899)
       CASE WHEN inicio_previsto LIKE '%/%' THEN to_date(inicio_previsto, 'dd/MM/yyyy')
            ELSE date_add(DATE'1899-12-30', CAST(inicio_previsto AS INT)) END   AS inicio_baseline,
       CASE WHEN termino_previsto LIKE '%/%' THEN to_date(termino_previsto, 'dd/MM/yyyy')
            ELSE date_add(DATE'1899-12-30', CAST(termino_previsto AS INT)) END  AS fim_baseline,
       -- '45%' ou '64,4%' → 45 e 64.4;  0.45 → 45;  e LEAST corta quem passou de 100
       LEAST(100, CASE WHEN pct_concluido LIKE '%\%%'
                       THEN CAST(replace(replace(pct_concluido, '%', ''), ',', '.') AS DOUBLE)
                       ELSE CAST(pct_concluido AS DOUBLE) * 100 END)      AS pct_concluido,
       CAST(replace(horas_previstas, 'h', '') AS DOUBLE)                  AS horas
FROM lakehouse_vertice.bronze.excel_tarefas
WHERE tarefa <> 'TOTAL'                     -- fora a linha de TOTAL (exemplo 03)

UNION ALL
-- ---------- CLICKUP ----------
-- O ClickUp não sabe o que é PRJ-xxx. O cadastro do PMO sabe: guarda o código da lista do ClickUp.
-- O JOIN junta as duas tabelas (c = clickup, p = projetos); o OR casa pelo nome quando falta o código.
-- O % e as datas da baseline estão escondidos numa lista de campos personalizados: o filter()
-- procura o campo pelo nome. As datas e as horas vêm em milissegundos.
SELECT p.projeto_id,
       'clickup',
       c.name,
       to_date(timestamp_millis(CAST(filter(c.custom_fields, f -> f.name = 'Início baseline')[0].value AS BIGINT))),
       to_date(timestamp_millis(CAST(filter(c.custom_fields, f -> f.name = 'Fim baseline')[0].value AS BIGINT))),
       CAST(filter(c.custom_fields, f -> f.name = 'Progresso (%)')[0].value AS DOUBLE),
       c.time_estimate / 3600000                                           -- milissegundos → horas
FROM lakehouse_vertice.bronze.clickup_tarefas c
JOIN lakehouse_vertice.bronze.projetos p
  ON p.codigo_ferramenta = c.list_id OR p.nome_projeto = c.list_name

UNION ALL
-- ---------- MS PROJECT ----------
-- As datas da baseline estão dentro da "caixinha" Baseline; as horas vêm como 'PT40H0M0S' (→ 40).
-- Summary = 0: só as tarefas de verdade. A tarefa-resumo (a fase) soma as de baixo e contaria duas vezes.
SELECT regexp_extract(arquivo, 'PRJ-[0-9]{3}', 0),
       'msproject',
       Name,
       to_date(Baseline.Start),
       to_date(Baseline.Finish),
       CAST(PercentComplete AS DOUBLE),
       CAST(regexp_extract(Work, 'PT([0-9]+)H', 1) AS DOUBLE)
FROM lakehouse_vertice.bronze.msproject_tarefas
WHERE Summary = 0;

-- 2. A resposta: quais projetos estão mais atrasados?
--
--    Gestão de projetos mede atraso com o SPI:
--      horas agregadas  = quanto ESTÁ pronto:        horas da tarefa × % concluído
--      horas planejadas = quanto DEVIA estar pronto:  horas da tarefa × quanto do prazo da tarefa
--                                                     já passou até hoje (de 0 a 1)
--      SPI = agregadas ÷ planejadas      abaixo de 1 é atraso (0,80 = andou 80% do que devia)
--    Regra da Torre: abaixo de 0,9 = atenção; abaixo de 0,8 = crítico.
--
--    WITH valor AS (...)        dá um nome a uma consulta e usa embaixo como se fosse tabela:
--                               primeiro soma as horas por projeto, depois divide
--    datediff(fim, inicio)      dias entre duas datas
--    GREATEST(0, LEAST(1, x))   prende x entre 0 e 1 (tarefa que nem começou = 0; que já devia ter acabado = 1)
--    JOIN ... USING (projeto_id) junta com o cadastro, para trazer o nome e o status do projeto
--
--    Deve aparecer: 41 projetos em andamento. No topo, PRJ-016 (0,63), PRJ-030 (0,69),
--    PRJ-039 (0,75) e PRJ-011 (0,77). A resposta da pergunta 1.
WITH valor AS (
    SELECT projeto_id,
           ferramenta,
           SUM(horas * pct_concluido / 100) AS horas_agregadas,
           SUM(horas * GREATEST(0, LEAST(1,
               datediff(DATE'2026-10-16', inicio_baseline) / datediff(fim_baseline, inicio_baseline)
           )))                               AS horas_planejadas
    FROM lakehouse_vertice.bronze.rascunho_tarefas
    GROUP BY projeto_id, ferramenta
)
SELECT p.projeto_id,
       p.cliente,
       v.ferramenta,
       ROUND(v.horas_agregadas / v.horas_planejadas, 2) AS spi,
       CASE WHEN v.horas_agregadas / v.horas_planejadas < 0.8 THEN 'crítico'
            WHEN v.horas_agregadas / v.horas_planejadas < 0.9 THEN 'atenção'
            ELSE 'ok' END                               AS situacao_prazo
FROM lakehouse_vertice.bronze.projetos p
JOIN valor v USING (projeto_id)
WHERE p.status = 'em_andamento'
ORDER BY spi;
