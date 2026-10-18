-- ============================================
-- EXEMPLO 01: SELECT — o que existe no catálogo?
-- ============================================
-- Conceito: SELECT, FROM, LIMIT, COUNT(*)
-- Pergunta de negócio: que projetos a Vértice tem na carteira, e onde cada um vive?
-- Conexão: antes de calcular qualquer KPI, olhe o dado. Sempre.

-- 1. A primeira olhada: 10 linhas do cadastro de projetos do PMO
SELECT *
FROM lakehouse_vertice.bronze.projetos
LIMIT 10;

-- 2. Quanta coisa a Vértice tem? Projetos, tarefas em cada ferramenta, pessoas, status semanais
SELECT
    (SELECT COUNT(*) FROM lakehouse_vertice.bronze.projetos)          AS projetos,
    (SELECT COUNT(*) FROM lakehouse_vertice.bronze.excel_tarefas)     AS linhas_no_excel,
    (SELECT COUNT(*) FROM lakehouse_vertice.bronze.clickup_tarefas)   AS tarefas_no_clickup,
    (SELECT COUNT(*) FROM lakehouse_vertice.bronze.msproject_tarefas) AS tarefas_no_project,
    (SELECT COUNT(*) FROM lakehouse_vertice.bronze.colaboradores)     AS colaboradores,
    (SELECT COUNT(*) FROM lakehouse_vertice.bronze.status_semanal)    AS status_semanais;

-- 3. O mesmo tipo de informação, três caras diferentes. Olhe uma tarefa de cada ferramenta:
--    Excel: datas como texto OU como número (45930?), % como '45%' OU como 0.45
SELECT tarefa, inicio_previsto, termino_previsto, pct_concluido, horas_previstas, arquivo
FROM lakehouse_vertice.bronze.excel_tarefas
LIMIT 5;

--    ClickUp: status é uma estrutura, datas são milissegundos, o % está dentro de uma lista de campos
SELECT list_name, name, status, start_date, time_estimate, custom_fields
FROM lakehouse_vertice.bronze.clickup_tarefas
LIMIT 5;

--    MS Project: horas no formato 'PT40H0M0S' e uma baseline dentro de cada tarefa
SELECT arquivo, Name, Summary, OutlineLevel, Work, PercentComplete, Baseline
FROM lakehouse_vertice.bronze.msproject_tarefas
LIMIT 5;

-- 4. O status semanal: toda sexta o gerente escreve, em texto livre, como está o projeto.
--    A causa do atraso está aqui dentro. Na noite 2, a IA vai tirar ela daqui.
SELECT data_status, projeto_id, farol, pct_concluido, texto_status
FROM lakehouse_vertice.bronze.status_semanal
WHERE projeto_id = 'PRJ-011'
ORDER BY data_status DESC
LIMIT 5;
