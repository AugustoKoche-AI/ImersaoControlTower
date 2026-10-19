-- Databricks notebook source
-- MAGIC %md
-- MAGIC ##########################################################################
-- MAGIC NOITE 1 · SQL NA BRONZE: os exemplos 01 a 05 num arquivo só
-- MAGIC ##########################################################################
-- MAGIC Rode de cima para baixo, UM bloco de cada vez: selecione o bloco e Ctrl+Enter.
-- MAGIC Cada bloco diz o que queremos achar, o que cada comando faz e o que deve aparecer.
-- MAGIC
-- MAGIC   EXEMPLO 01  SELECT                   o que existe no catálogo?
-- MAGIC   EXEMPLO 02  ORDER BY, CAST, DISTINCT quais os maiores contratos?
-- MAGIC   EXEMPLO 03  WHERE                    dá para confiar nesse número?
-- MAGIC   EXEMPLO 04  GROUP BY                 para onde vai o dinheiro?
-- MAGIC   EXEMPLO 05  UNION                    quais projetos estão mais atrasados? (pergunta 1)
-- MAGIC
-- MAGIC Depois vem o exemplo-06-quanto-custa-o-atraso.sql (pergunta 2), que usa a view do exemplo 05.
-- MAGIC O nome completo de uma tabela tem 3 partes: catálogo.schema.tabela
-- MAGIC   lakehouse_vertice . bronze . projetos
-- MAGIC
-- MAGIC
-- MAGIC EXEMPLO 01: SELECT — o que existe no catálogo?
-- MAGIC Conceito: SELECT, FROM, LIMIT, COUNT(*)
-- MAGIC Pergunta de negócio: que projetos a Vértice tem, e onde cada um vive?
-- MAGIC Conexão: antes de calcular qualquer coisa, olhe o dado. Sempre.
-- MAGIC
-- MAGIC 1. A primeira olhada no cadastro de projetos do PMO.
-- MAGIC    SELECT *   traga todas as colunas
-- MAGIC    FROM ...   da tabela tal
-- MAGIC    LIMIT 10   só as 10 primeiras linhas
-- MAGIC    Deve aparecer: 10 projetos com cliente, valor do contrato, prazo e a coluna ferramenta
-- MAGIC    (Excel, ClickUp ou MS Project): é onde o cronograma de cada um vive. Repare que a
-- MAGIC    mesma ferramenta aparece escrita de jeitos diferentes. Volta no exemplo 02.

-- COMMAND ----------

SELECT *
FROM lakehouse_vertice.bronze.projetos
LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Quantos projetos a Vértice tem?
-- MAGIC    COUNT(*)   conta as linhas
-- MAGIC    AS nome    dá um nome para a coluna do resultado
-- MAGIC    Deve aparecer: 60.

-- COMMAND ----------

SELECT COUNT(*) AS projetos
FROM lakehouse_vertice.bronze.projetos;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC EXEMPLO 02: ORDER BY, CAST e DISTINCT — os maiores contratos
-- MAGIC Conceito: ORDER BY, CAST, DISTINCT
-- MAGIC Pergunta de negócio: quais são os maiores contratos da Vértice?
-- MAGIC Conexão: na bronze tudo é texto. Sem CAST, o Databricks ordena como palavra.
-- MAGIC
-- MAGIC 1. Os 5 maiores contratos... ou não.
-- MAGIC    ORDER BY coluna DESC   ordena do maior para o menor
-- MAGIC    Deve aparecer: uma lista que PARECE certa, com o PRJ-052 (R$ 8,4 mi) no topo. Está errada.
-- MAGIC    O valor é texto, e texto se ordena letra por letra: '8380000' vem antes de '15275000'
-- MAGIC    porque '8' vem depois de '1', como numa lista telefônica.

-- COMMAND ----------

SELECT projeto_id, nome_projeto, valor_contrato
FROM lakehouse_vertice.bronze.projetos
ORDER BY valor_contrato DESC
LIMIT 5;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. A correção: converter o texto em número antes de ordenar.
-- MAGIC    CAST(coluna AS DECIMAL(18,2))   transforma o texto em número com 2 casas decimais
-- MAGIC    Deve aparecer: o maior contrato de verdade é o PRJ-017, R$ 15,3 mi.

-- COMMAND ----------

SELECT projeto_id, nome_projeto,
       CAST(valor_contrato AS DECIMAL(18,2)) AS valor_numero
FROM lakehouse_vertice.bronze.projetos
ORDER BY valor_numero DESC
LIMIT 5;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. Em quais ferramentas os projetos vivem?
-- MAGIC    DISTINCT   tira as repetições: cada valor aparece uma vez só
-- MAGIC    Deve aparecer: 8 jeitos de escrever 3 ferramentas: 'Excel', 'excel', 'Planilha',
-- MAGIC    'ClickUp', 'Clickup', 'MS Project', 'Project', 'msproject'.
-- MAGIC    É o retrato do problema da Vértice: cada um registra do seu jeito.

-- COMMAND ----------

SELECT DISTINCT ferramenta
FROM lakehouse_vertice.bronze.projetos
ORDER BY ferramenta;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC EXEMPLO 03: WHERE — filtrar, e achar a sujeira
-- MAGIC Conceito: WHERE, LIKE, AND, IN, IS NULL
-- MAGIC Pergunta de negócio: dá para confiar nesse número?
-- MAGIC Conexão com a noite 2: tudo que este exemplo acha é o que a silver conserta.
-- MAGIC
-- MAGIC Dado sujo não dá erro: dá um número errado, em silêncio, e a diretoria decide em cima dele.
-- MAGIC
-- MAGIC O WHERE vem depois do FROM e diz QUAIS linhas entram:
-- MAGIC   WHERE coluna = 'valor'      igual a
-- MAGIC   WHERE coluna LIKE '%/%'     "parece com". O % quer dizer "qualquer coisa aqui":
-- MAGIC                               '%/%' = tem uma barra em algum lugar
-- MAGIC
-- MAGIC 1. A data de início em dois formatos na mesma coluna: 14/03/2025 e 2025-03-14.
-- MAGIC    Quantos projetos estão no formato com barra?
-- MAGIC    Deve aparecer: 24 (os outros 36 estão como 2025-03-14). Uma conta de prazo que só
-- MAGIC    entenda um dos formatos erra 24 projetos.

-- COMMAND ----------

SELECT COUNT(*) AS formato_brasileiro
FROM lakehouse_vertice.bronze.projetos
WHERE data_inicio LIKE '%/%';

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Excel: a linha de TOTAL que o gerente deixou no fim de cada planilha.
-- MAGIC    Deve aparecer: 20 linhas, uma por planilha. Quem soma a coluna de horas inteira
-- MAGIC    conta tudo duas vezes.

-- COMMAND ----------

SELECT arquivo, tarefa, horas_previstas
FROM lakehouse_vertice.bronze.excel_tarefas
WHERE tarefa = 'TOTAL';

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. Financeiro: custo com vírgula decimal ('12345,67'). Para o computador, isso não é número.
-- MAGIC    Deve aparecer: 671 lançamentos. O exemplo 04 mostra o estrago.

-- COMMAND ----------

SELECT COUNT(*) AS com_virgula
FROM lakehouse_vertice.bronze.custos
WHERE valor LIKE '%,%';

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. Combinar condições: projetos de VAREJO que estão EM ANDAMENTO.
-- MAGIC    AND   as duas condições precisam valer ao mesmo tempo
-- MAGIC    Deve aparecer: 14 projetos. Varejo é o segmento da Black Friday: o freeze de 01/11 a 10/01 trava os de e-commerce.

-- COMMAND ----------

SELECT projeto_id, cliente, nome_projeto
FROM lakehouse_vertice.bronze.projetos
WHERE status = 'em_andamento'
  AND segmento = 'varejo';

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 5. Os projetos que vivem no Excel. Lembra que a ferramenta está escrita de 8 jeitos (exemplo 02)?
-- MAGIC    IN (...)   "é um destes valores": vale como três igualdades ligadas por OR
-- MAGIC    Deve aparecer: 20 projetos. Com WHERE ferramenta = 'Excel' sairiam menos: os escritos
-- MAGIC    'excel' e 'Planilha' ficariam de fora, sem nenhum aviso.

-- COMMAND ----------

SELECT projeto_id, cliente, ferramenta
FROM lakehouse_vertice.bronze.projetos
WHERE ferramenta IN ('Excel', 'excel', 'Planilha');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 6. Projeto sem o código da ferramenta: ninguém sabe onde está o cronograma dele.
-- MAGIC    IS NULL   a coluna está vazia. Atenção: "= NULL" não funciona, nunca dá verdadeiro.
-- MAGIC    Deve aparecer: 2 projetos (PRJ-009 e PRJ-012).

-- COMMAND ----------

SELECT projeto_id, nome_projeto, ferramenta, codigo_ferramenta
FROM lakehouse_vertice.bronze.projetos
WHERE codigo_ferramenta IS NULL;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 7. A mesma consultoria digitada de vários jeitos em compras.
-- MAGIC    lower(...)   põe tudo em minúscula, para o LIKE achar 'Forge', 'FORGE' e 'forge'
-- MAGIC    Deve aparecer: 4 jeitos de escrever CodeForge. Quem soma "por fornecedor" acha 4 fornecedores.

-- COMMAND ----------

SELECT DISTINCT fornecedor
FROM lakehouse_vertice.bronze.entregas_fornecedor
WHERE lower(fornecedor) LIKE '%forge%';

-- COMMAND ----------

-- MAGIC %md
-- MAGIC EXEMPLO 04: GROUP BY — para onde vai o dinheiro da Vértice?
-- MAGIC Conceito: GROUP BY, SUM, replace
-- MAGIC Pergunta de negócio: quanto a Vértice gasta, por categoria de custo?
-- MAGIC Conexão: é a pergunta 2 do dono ("quanto custa?") começando a ter resposta.
-- MAGIC
-- MAGIC A tabela é a bronze.custos: um lançamento de custo por linha (23.640 linhas).
-- MAGIC
-- MAGIC 1. Quanto cada categoria gastou?
-- MAGIC    GROUP BY categoria   junta as linhas da mesma categoria e faz a conta dentro de cada grupo
-- MAGIC    SUM(...)             soma a coluna dentro do grupo
-- MAGIC    O valor é texto, então primeiro CAST para número (exemplo 02).
-- MAGIC    Deve aparecer: um ERRO. É de propósito: '1827,44' não vira número. É a vírgula do exemplo 03.

-- COMMAND ----------

SELECT categoria,
       SUM(CAST(valor AS DECIMAL(18,2))) AS custo
FROM lakehouse_vertice.bronze.custos
GROUP BY categoria;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. A correção: trocar a vírgula por ponto ANTES de converter.
-- MAGIC    replace(valor, ',', '.')   troca ',' por '.'
-- MAGIC    ROUND(x / 1000000, 1)      em milhões, com 1 casa decimal
-- MAGIC    Deve aparecer: pessoal no topo, com R$ 117,8 mi. Empresa de tecnologia gasta com gente:
-- MAGIC    quase dois terços dos R$ 193,35 mi de custo.

-- COMMAND ----------

SELECT categoria,
       ROUND(SUM(CAST(replace(valor, ',', '.') AS DECIMAL(18,2))) / 1000000, 1) AS custo_milhoes
FROM lakehouse_vertice.bronze.custos
GROUP BY categoria
ORDER BY custo_milhoes DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC EXEMPLO 05: UNION — as três ferramentas numa fila só
-- MAGIC Conceito: UNION ALL, VIEW, CASE, JOIN, WITH
-- MAGIC Pergunta de negócio: QUAIS PROJETOS ESTÃO MAIS ATRASADOS?
-- MAGIC
-- MAGIC É a primeira pergunta do dono, e ninguém na Vértice sabia responder: 20 projetos estão
-- MAGIC no Excel, 25 no ClickUp e 15 no MS Project. Cada ferramenta guarda a mesma informação
-- MAGIC (a tarefa, quando devia começar e terminar, quanto está pronta, quantas horas) de um jeito.
-- MAGIC
-- MAGIC O plano, em 5 degraus:
-- MAGIC   bloco 1   o UNION ALL no menor exemplo possível
-- MAGIC   bloco 2   traduzir UMA ferramenta (o Excel) para as 7 colunas
-- MAGIC   bloco 3   as três traduzidas e empilhadas numa view: o rascunho
-- MAGIC   bloco 4   somar as horas: quanto está pronto e quanto devia estar
-- MAGIC   bloco 5   dividir uma pela outra (o SPI) e dar a resposta ao dono
-- MAGIC É um RASCUNHO feito à mão. Na noite 2 isso vira pipeline de verdade (a silver).
-- MAGIC
-- MAGIC O "hoje" do dataset é 16/10/2026: nunca use current_date() aqui,
-- MAGIC senão o seu número muda todo dia e não bate com o de ninguém.
-- MAGIC
-- MAGIC 1. O UNION ALL, no menor exemplo possível.
-- MAGIC    UNION ALL   empilha o resultado de uma consulta embaixo da outra.
-- MAGIC                Regra: todas com as mesmas colunas, na mesma ordem.
-- MAGIC    Deve aparecer: 3 linhas, uma por ferramenta, com quantas linhas cada uma tem.
-- MAGIC    É essa a ideia do exemplo inteiro. O resto é fazer as três ferramentas
-- MAGIC    terem as mesmas colunas, para poder empilhar.

-- COMMAND ----------

SELECT 'excel'     AS ferramenta, COUNT(*) AS linhas FROM lakehouse_vertice.bronze.excel_tarefas
UNION ALL
SELECT 'clickup'   AS ferramenta, COUNT(*) AS linhas FROM lakehouse_vertice.bronze.clickup_tarefas
UNION ALL
SELECT 'msproject' AS ferramenta, COUNT(*) AS linhas FROM lakehouse_vertice.bronze.msproject_tarefas;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Traduzir UMA ferramenta: o Excel nas 7 colunas.
-- MAGIC    As 7 colunas: projeto_id · ferramenta · tarefa · inicio_baseline · fim_baseline
-- MAGIC                  · pct_concluido · horas       (baseline = o plano original)
-- MAGIC    CASE WHEN ... THEN ... ELSE ... END   o "se" do SQL
-- MAGIC    Deve aparecer: datas de verdade (mesmo onde a planilha tinha 45700) e % de 0 a 100.

-- COMMAND ----------

SELECT -- o projeto está no nome do arquivo: 'Cronograma PRJ-002.xlsx' → pega "PRJ-" + 3 dígitos
       regexp_extract(arquivo, 'PRJ-[0-9]{3}', 0)                         AS projeto_id,
       'excel'                                                            AS ferramenta,
       tarefa,
       -- data com barra ('06/03/2025') → lê como dd/MM/yyyy;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC -- senão é o número de série do Excel (45700 = dias contados desde 30/12/1899)

-- COMMAND ----------

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
LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. O rascunho: as três ferramentas traduzidas e empilhadas, guardadas numa view.
-- MAGIC    CREATE OR REPLACE VIEW nome AS ...   guarda a consulta com um nome. Não copia o dado:
-- MAGIC                                         toda vez que alguém lê a view, a consulta roda de novo.
-- MAGIC    O Excel é o bloco 2. O ClickUp e o MS Project fazem a mesma tradução, cada um com o seu
-- MAGIC    problema (explicado no comentário de cada parte). Entre eles, o UNION ALL do bloco 1.
-- MAGIC    Deve aparecer: OK. A view bronze.rascunho_tarefas aparece no Catalog.

-- COMMAND ----------

CREATE OR REPLACE VIEW lakehouse_vertice.bronze.rascunho_tarefas
COMMENT 'Rascunho da noite 1: tarefas do Excel, ClickUp e MS Project empilhadas à mão. Na noite 2 vira silver.tarefas.'
AS
-- ---------- EXCEL ----------
SELECT -- o projeto está no nome do arquivo: 'Cronograma PRJ-002.xlsx' → pega "PRJ-" + 3 dígitos
       regexp_extract(arquivo, 'PRJ-[0-9]{3}', 0)                         AS projeto_id,
       'excel'                                                            AS ferramenta,
       tarefa,
       -- data com barra ('06/03/2025') → lê como dd/MM/yyyy;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC -- senão é o número de série do Excel (45700 = dias contados desde 30/12/1899)

-- COMMAND ----------

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

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. Com tudo numa fila só, as horas de cada projeto.
-- MAGIC    horas agregadas  = quanto ESTÁ pronto:        horas da tarefa × % concluído
-- MAGIC    horas planejadas = quanto DEVIA estar pronto:  horas da tarefa × quanto do prazo da tarefa
-- MAGIC                                                   já passou até hoje (de 0 a 1)
-- MAGIC    datediff(fim, inicio)      dias entre duas datas
-- MAGIC    GREATEST(0, LEAST(1, x))   prende x entre 0 e 1: tarefa que nem começou = 0; que já devia ter acabado = 1
-- MAGIC    Deve aparecer: dois números por projeto. Onde o primeiro é bem menor que o segundo, atrasou.

-- COMMAND ----------

SELECT projeto_id,
       ferramenta,
       ROUND(SUM(horas * pct_concluido / 100)) AS horas_agregadas,
       ROUND(SUM(horas * GREATEST(0, LEAST(1,
           datediff(DATE'2026-10-16', inicio_baseline) / datediff(fim_baseline, inicio_baseline)
       ))))                                     AS horas_planejadas
FROM lakehouse_vertice.bronze.rascunho_tarefas
GROUP BY projeto_id, ferramenta
ORDER BY projeto_id;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 5. A resposta para o dono: o SPI de cada projeto em andamento.
-- MAGIC    SPI = agregadas ÷ planejadas      abaixo de 1 é atraso (0,80 = andou 80% do que devia)
-- MAGIC    Regra da Torre: abaixo de 0,9 = atenção; abaixo de 0,8 = crítico.
-- MAGIC
-- MAGIC    WITH valor AS (...)          dá um nome à consulta do bloco 4 e usa embaixo, como se fosse
-- MAGIC                                 uma tabela: primeiro soma, depois divide
-- MAGIC    JOIN ... USING (projeto_id)  junta com o cadastro, para trazer o cliente e o status
-- MAGIC    Deve aparecer: 41 projetos em andamento. No topo, PRJ-016 (0,63), PRJ-030 (0,69),
-- MAGIC    PRJ-039 (0,75) e PRJ-011 (0,77). A resposta da pergunta 1.

-- COMMAND ----------

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
