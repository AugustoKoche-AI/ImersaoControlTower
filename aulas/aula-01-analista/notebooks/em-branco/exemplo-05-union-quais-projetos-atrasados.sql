-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 05: UNION — as três ferramentas numa fila só
-- MAGIC Conceito: UNION ALL, VIEW, CASE, JOIN, WITH
-- MAGIC Pergunta de negócio: QUAIS PROJETOS ESTÃO MAIS ATRASADOS?
-- MAGIC
-- MAGIC É a primeira pergunta do dono, e ninguém na Vértice sabia responder: 20 projetos estão
-- MAGIC no Excel, 25 no ClickUp e 15 no MS Project. Cada ferramenta guarda a mesma informação
-- MAGIC (a tarefa, quando devia começar e terminar, quanto está pronta, quantas horas) de um jeito.
-- MAGIC
-- MAGIC O plano:
-- MAGIC   bloco 1   traduzir cada ferramenta para as MESMAS 7 colunas e empilhar as três (UNION ALL)
-- MAGIC   bloco 2   com tudo numa fila só, calcular o atraso de cada projeto (SPI)
-- MAGIC É um RASCUNHO feito à mão. Na noite 2 isso vira pipeline de verdade (a silver).
-- MAGIC
-- MAGIC O "hoje" do dataset é 16/10/2026: nunca use current_date() aqui,
-- MAGIC senão o seu número muda todo dia e não bate com o de ninguém.
-- MAGIC
-- MAGIC 1. O rascunho: as tarefas das três ferramentas, no mesmo formato, numa view.
-- MAGIC
-- MAGIC    CREATE OR REPLACE VIEW nome AS ...   guarda a consulta com um nome. Não copia o dado:
-- MAGIC                                         toda vez que alguém lê a view, a consulta roda de novo.
-- MAGIC    UNION ALL                            empilha uma consulta embaixo da outra.
-- MAGIC                                         Regra: todas com as mesmas colunas, na mesma ordem.
-- MAGIC    CASE WHEN ... THEN ... ELSE ... END  o "se" do SQL
-- MAGIC
-- MAGIC    As 7 colunas: projeto_id · ferramenta · tarefa · inicio_baseline · fim_baseline
-- MAGIC                  · pct_concluido · horas       (baseline = o plano original)
-- MAGIC
-- MAGIC    Deve aparecer: OK. A view bronze.rascunho_tarefas aparece no Catalog, com 4.917 tarefas.

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC -- senão é o número de série do Excel (45700 = dias contados desde 30/12/1899)

-- COMMAND ----------

-- escreva aqui a sua query


-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. A resposta: quais projetos estão mais atrasados?
-- MAGIC
-- MAGIC    Gestão de projetos mede atraso com o SPI:
-- MAGIC      horas agregadas  = quanto ESTÁ pronto:        horas da tarefa × % concluído
-- MAGIC      horas planejadas = quanto DEVIA estar pronto:  horas da tarefa × quanto do prazo da tarefa
-- MAGIC                                                     já passou até hoje (de 0 a 1)
-- MAGIC      SPI = agregadas ÷ planejadas      abaixo de 1 é atraso (0,80 = andou 80% do que devia)
-- MAGIC    Regra da Torre: abaixo de 0,9 = atenção; abaixo de 0,8 = crítico.
-- MAGIC
-- MAGIC    WITH valor AS (...)        dá um nome a uma consulta e usa embaixo como se fosse tabela:
-- MAGIC                               primeiro soma as horas por projeto, depois divide
-- MAGIC    datediff(fim, inicio)      dias entre duas datas
-- MAGIC    GREATEST(0, LEAST(1, x))   prende x entre 0 e 1 (tarefa que nem começou = 0; que já devia ter acabado = 1)
-- MAGIC    JOIN ... USING (projeto_id) junta com o cadastro, para trazer o nome e o status do projeto
-- MAGIC
-- MAGIC    Deve aparecer: 41 projetos em andamento. No topo, PRJ-016 (0,63), PRJ-030 (0,69),
-- MAGIC    PRJ-039 (0,75) e PRJ-011 (0,77). A resposta da pergunta 1.

-- COMMAND ----------

-- escreva aqui a sua query

