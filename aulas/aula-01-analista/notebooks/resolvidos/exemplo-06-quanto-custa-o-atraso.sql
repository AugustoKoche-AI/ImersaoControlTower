-- Databricks notebook source
-- MAGIC %md
-- MAGIC EXEMPLO 06: quanto custa? CPI, EAC, prazo projetado e o farol do gerente
-- MAGIC Conceito: CTE encadeada, aritmética de KPI, janela (SUM OVER), comparação
-- MAGIC Pergunta de negócio: SE NADA MUDAR, QUANTO A VÉRTICE VAI PERDER? E O FAROL MOSTRA ISSO?
-- MAGIC
-- MAGIC   valor agregado (EV) = orçamento × (horas agregadas ÷ horas totais)
-- MAGIC   CPI = EV / custo real           < 1 é estouro (cada R$ 1 gasto entregou menos de R$ 1)
-- MAGIC   EAC (estimativa no término) = orçamento / CPI
-- MAGIC   estouro previsto            = EAC − orçamento
-- MAGIC   margem projetada            = (valor do contrato − EAC) / valor do contrato
-- MAGIC   atraso projetado (dias)     = duração / SPI − duração
-- MAGIC
-- MAGIC Usa o rascunho do exemplo 05 (bronze.rascunho_tarefas): rode o 05 antes.

-- COMMAND ----------

WITH valor AS (
    SELECT projeto_id,
           SUM(horas)                       AS horas_totais,
           SUM(horas * pct_concluido / 100) AS horas_agregadas,
           SUM(horas * GREATEST(0, LEAST(1,
               datediff(DATE'2026-10-16', inicio_baseline) / datediff(fim_baseline, inicio_baseline)
           )))                               AS horas_planejadas
    FROM lakehouse_vertice.bronze.rascunho_tarefas
    GROUP BY projeto_id
),
custo AS (
    SELECT projeto_id, SUM(CAST(replace(valor, ',', '.') AS DECIMAL(18,2))) AS ac
    FROM lakehouse_vertice.bronze.custos
    GROUP BY projeto_id
),
farol AS (
    -- o último status de cada projeto: o farol que o gerente publicou nesta sexta
    SELECT projeto_id, lower(farol) AS farol
    FROM lakehouse_vertice.bronze.status_semanal
    QUALIFY ROW_NUMBER() OVER (PARTITION BY projeto_id ORDER BY data_status DESC) = 1
),
projeto AS (
    SELECT p.projeto_id, p.nome_projeto, p.cliente,
           CAST(p.valor_contrato  AS DECIMAL(18,2)) AS valor_contrato,
           CAST(p.orcamento_custo AS DECIMAL(18,2)) AS orcamento,
           -- a data de início vem em dois formatos: tenta um, depois o outro
           datediff(CAST(p.data_fim_baseline AS DATE),
                    coalesce(try_to_date(p.data_inicio, 'yyyy-MM-dd'),
                             try_to_date(p.data_inicio, 'dd/MM/yyyy'))) AS duracao_dias,
           v.horas_agregadas / v.horas_planejadas                         AS spi,
           CAST(p.orcamento_custo AS DECIMAL(18,2)) * v.horas_agregadas / v.horas_totais / c.ac AS cpi,
           f.farol
    FROM lakehouse_vertice.bronze.projetos p
    JOIN valor v USING (projeto_id)
    JOIN custo c USING (projeto_id)
    JOIN farol f USING (projeto_id)
    WHERE p.status = 'em_andamento'
)
SELECT projeto_id, nome_projeto, cliente,
       ROUND(spi, 2)                                                AS spi,
       ROUND(cpi, 2)                                                AS cpi,
       farol                                                        AS farol_do_gerente,
       ROUND(orcamento / cpi / 1e6, 2)                              AS eac_milhoes,
       ROUND((orcamento / cpi - orcamento) / 1e6, 2)                AS estouro_milhoes,
       ROUND(100 * (valor_contrato - orcamento / cpi) / valor_contrato, 1) AS margem_projetada_pct,
       ROUND(duracao_dias / spi - duracao_dias)                     AS atraso_projetado_dias,
       -- só soma quem estoura: projeto com CPI > 1 não "compensa" o que queima margem
       ROUND(SUM(GREATEST(0, orcamento / cpi - orcamento)) OVER () / 1e6, 2) AS estouro_total_carteira_milhoes
FROM projeto
ORDER BY LEAST(spi, cpi)
LIMIT 20;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC O farol mente? O manual da Vértice diz: verde só com SPI ≥ 0,95.
-- MAGIC Quantos projetos o gerente pintou de verde com o número dizendo outra coisa?

-- COMMAND ----------

WITH valor AS (
    SELECT projeto_id,
           SUM(horas * pct_concluido / 100) / SUM(horas * GREATEST(0, LEAST(1,
               datediff(DATE'2026-10-16', inicio_baseline) / datediff(fim_baseline, inicio_baseline)))) AS spi
    FROM lakehouse_vertice.bronze.rascunho_tarefas
    GROUP BY projeto_id
)
SELECT v.projeto_id, ROUND(v.spi, 2) AS spi, lower(s.farol) AS farol_do_gerente
FROM valor v
JOIN lakehouse_vertice.bronze.projetos p USING (projeto_id)
JOIN lakehouse_vertice.bronze.status_semanal s USING (projeto_id)
WHERE p.status = 'em_andamento'
  AND s.data_status = '2026-10-16'
  AND lower(s.farol) = 'verde'
  AND v.spi < 0.9
ORDER BY v.spi;
