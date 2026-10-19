# 🧩 Noite 2 sem código — a mesma Torre, pela interface

Para quem é de gestão, PMO ou financeiro e não quer abrir um terminal. Você chega no
**mesmo resultado** da trilha com Claude Code: as três ferramentas integradas, gold com
SPI e CPI, causa do atraso tirada do status semanal, KPIs governados, dashboard e Genie.
A diferença: o que é clicado não fica no Git (não tem diff, revisão nem rollback). É o
argumento de por que engenharia existe.

Tudo pelo navegador, no seu workspace Free Edition, sobre a bronze da noite 1.

---

## 1. A limpeza com o Lakeflow Designer (≈ 15 min)

**Jobs & Pipelines → Create → ETL pipeline → Lakeflow Designer** (no menu
lateral aparece também como *Visual Data Prep*).

1. **Source:** `lakehouse_vertice.bronze.custos`.
2. **Transform → Formula:** nova coluna `valor` com
   `CAST(replace(valor, ',', '.') AS DECIMAL(18,2))`.
   Repare: sem o `replace`, 671 linhas viram nulo.
3. **Transform → Formula:** `estorno` = `valor < 0`. Não filtre: estorno é informação.
4. **Destination:** `lakehouse_vertice.silver.custos` → **Run**.
5. Repita para `entregas_fornecedor` com a fórmula do fornecedor:
   `CASE WHEN replace(lower(fornecedor), ' ', '') LIKE '%codeforge%' THEN 'CodeForge Consultoria Ltda' ELSE fornecedor END`.

> O Designer gera SQL por trás. Clique em **View code**: é o mesmo
> `src/silver/03-status-e-custos.sql` do gabarito.

**Atalho:** se o Designer não aparecer no seu workspace, use o **SQL Editor**
com o **Genie Code** (o assistente do editor): escreva *"crie a silver de custos
convertendo a vírgula decimal e marcando estorno"* e revise o SQL antes de rodar.

## 2. As três ferramentas numa tabela, com o Genie Code (≈ 15 min)

**SQL Editor → nova query → ícone do assistente (Genie Code)**:

```
Junte numa view as tarefas de lakehouse_vertice.bronze.excel_tarefas,
lakehouse_vertice.bronze.clickup_tarefas e lakehouse_vertice.bronze.msproject_tarefas,
com as mesmas colunas: projeto_id, ferramenta, tarefa, inicio_baseline, fim_baseline,
pct_concluido (0 a 100) e horas. Cuidado: no Excel a data pode ser número de série e
tem uma linha TOTAL; no ClickUp as datas são milissegundos e o % está em custom_fields;
no MS Project tire as tarefas com Summary = 1. Use bronze.projetos para achar o
projeto. Explique cada passo.
```

Leia a explicação, rode, e compare a contagem com a do gabarito
(`lakehouse_vertice.silver.tarefas`: 4.917 tarefas, 60 projetos). **Peça para ele
explicar o SQL antes de rodar.** Nunca rode o que você não entendeu. Ele lembrou da linha
de TOTAL? Das tarefas-resumo? É exatamente o que um pipeline com teste não esquece.

## 3. A causa do atraso com IA, numa query (≈ 5 min)

```sql
SELECT data_status, texto_status,
       ai_classify(texto_status,
         '["change_freeze","falta_sre","dependencia_fornecedor","rotatividade","mudanca_escopo","bug_retrabalho","aprovacao_cliente","sem_bloqueio"]',
         map('version','2.0')):response[0]::STRING AS causa,
       ai_extract(texto_status,
         '{"bloqueio":{"type":"string"},"dias_impacto":{"type":"number","description":"1 semana = 7"}}',
         map('version','2.0')):response AS extraido
FROM lakehouse_vertice.silver.status_semanal
WHERE projeto_id = 'PRJ-011' AND data_status >= DATE'2026-08-01'
ORDER BY data_status DESC;
```

Conte quantas vezes aparece `falta_sre`. Essa é a resposta que o Genie da noite 1 não deu.

## 4. Um KPI governado pela interface (≈ 10 min)

**Catalog → lakehouse_vertice → gold → Create → Metric view**:

- Source: `lakehouse_vertice.gold.projeto_situacao_atual`, filtro `status = 'em_andamento'`
- Dimensões: `projeto`, `cliente`, `ferramenta`, `situacao`
- Medidas: `spi` = `SUM(ev) / SUM(pv)` · `cpi` = `SUM(ev) / SUM(ac)` ·
  `estouro_previsto` = `SUM(estouro_previsto)`
- Em cada medida, preencha **Comment** e **Synonyms** ("índice de custo" → cpi):
  é o que o Genie lê.

## 5. O dashboard e o Genie (≈ 15 min)

- **Dashboards → Create dashboard → Data → Add data source** → escolha a metric
  view do passo 4. Arraste: contador de `estouro_previsto`, barra de
  `estouro_previsto` por `projeto`, cor por `situacao`.
- **Genie Agents → New** → adicione a metric view, `gold.status_estruturado` e
  `gold.utilizacao_pessoa_semana`. Em **Instructions**, escreva:
  *"Hoje é 16/10/2026. SPI e CPI abaixo de 0,9 é atenção, abaixo de 0,8 é crítico.
  Para 'por que o projeto atrasou', conte as causas do status_estruturado dos últimos 90 dias.
  Gente parada é utilização abaixo de 20% nas últimas 12 semanas."*
- Faça as perguntas do dono: **"Quanto esse atraso vai me custar?"** e
  **"Tenho gente parada enquanto outro projeto pede gente?"**

## O que você acabou de provar

| Trilha | O que fica | Quanto tempo para refazer na segunda que vem |
|---|---|---|
| Sem código | tabelas, dashboard e Genie no workspace | refazer cada clique |
| Com código (Claude Code) | tudo isso **e** o projeto no Git | `databricks bundle deploy` (8 s) |

As duas chegam no mesmo número. Só uma roda sozinha toda segunda às 6h.
