# Prints dos entregáveis

Os slides embutem estes arquivos. Enquanto um print não existe, o slide mostra um quadro
"print pendente" com o nome esperado. Salve cada tela como **JPG** nesta pasta, com o nome
exato, e rode `python3 scripts/gerar_slides.py slides/imersao.slides.html`.

Dica: janela do navegador em 1600 × 900 (ou tela cheia), tema do Databricks escuro, zoom 100%.
Workspace: `https://dbc-84cd5511-fa25.cloud.databricks.com` (o `?o=1253341796019093` é adicionado sozinho).

## Noite 1 · Analista

| Arquivo | O que mostrar | Onde |
|---|---|---|
| `noite1-volume-excel.jpg` | as 20 planilhas `.xlsx` dentro do volume | Catalog → lakehouse_vertice → bronze → Volumes → raw → `excel/` |
| `noite1-catalogo-bronze.jpg` | as 13 tabelas da bronze (e o `rascunho_tarefas`) | Catalog → lakehouse_vertice → bronze |
| `noite1-dashboard.jpg` | os 4 KPIs e o SPI por projeto | `/dashboardsv3/01f1cb42fb791754957e69d572ed0fa6/published` |
| `noite1-genie-erra.jpg` | a resposta errada para *Quanto esse atraso vai me custar?* (no print: "27 atrasados" e o PRJ-011 com custo negativo; em outra execução, "nenhum atraso está impactando financeiramente") | Genie Agents → **Farol · Noite 1 (bronze, sem curadoria)** (`/genie/rooms/01f1cb43b49b153ba093e02c8e64ba61`) |

## Noite 2 · Engenheiro de Dados

| Arquivo | O que mostrar | Onde |
|---|---|---|
| `noite2-pipeline.jpg` | o grafo do pipeline com as 3 visões desaguando em `silver.tarefas` | `/pipelines/1786b2c7-f994-4582-8418-df46337245a1` |
| `noite2-job.jpg` | o DAG do job verde, com as 8 tarefas | `/jobs/409863010487260` → última execução |
| `noite2-dashboard.jpg` | a página Portfólio (KPIs, estouro por projeto, SPI × CPI) | `/dashboardsv3/01f1cb4e13141255a1daf9dcb8be8448/published` |
| `noite2-genie.jpg` | a resposta para *Tenho gente parada enquanto outro projeto pede gente?* (as duas SREs) | Genie Agents → **Farol · Diretoria** (`/genie/rooms/01f1cb4e131b18adb111de397e84664b`) |

## Noite 3 · Cientista de Dados

| Arquivo | O que mostrar | Onde |
|---|---|---|
| `noite3-modelo.jpg` | o modelo `modelo_estouro_30d` com o alias **@prod** e as versões | Catalog → lakehouse_vertice → gold → Models |
| `noite3-score.jpg` | as linhas de `gold.score_estouro_30d` (prob, ranking, motivos) | Catalog → gold → score_estouro_30d → Sample Data (ou SQL Editor) |

## Noite 4 · Engenheiro de IA

| Arquivo | O que mostrar | Onde |
|---|---|---|
| `noite4-app.jpg` | a página Projetos do app, com KPIs, causa e risco do modelo | `https://farol-torre-1253341796019093.aws.databricksapps.com` (o 1º acesso pede **Authorize**) |
| `noite4-simulador.jpg` | o simulador COL0017 → PRJ-011, antes de clicar Aprovar | app → Simulador |
| `noite4-genie-contratos.jpg` | a resposta para *Quanto de multa podemos cobrar da CodeForge?* | Genie Agents → **Farol · Diretoria + Contratos** (`/genie/rooms/01f1cb513eb91dd58208123de3d84ad4`) |
| `noite4-decisao.jpg` | a decisão aprovada na aba Decisões do app (gravada no Lakebase) | app → Decisões |

> Ainda faltam `noite4-app.jpg`, `noite4-simulador.jpg` e `noite4-decisao.jpg`: o 1º acesso ao app pede
> **Authorize** (consentimento OAuth), que precisa ser clicado por uma pessoa.

## Ontem × agora (README raiz e apresentação final)

| Arquivo | O que mostra |
|---|---|
| `ontem-excel-sujo.jpg` | `bronze.excel_tarefas`: data ora texto, ora número de série do Excel |
| `ontem-clickup-json.jpg` | `bronze.clickup_tarefas`: responsável e campos dentro de listas JSON |
| `ontem-msproject-xml.jpg` | `bronze.msproject_tarefas`: baseline e datas aninhados |
| `agora-silver-tarefas.jpg` | `silver.tarefas`: as 3 ferramentas num formato só |
| `agora-gold.jpg` | o schema `gold` com as tabelas prontas para o dono |

## Recursos do Databricks (apêndice de `slides/imersao.slides.html`)

| Arquivo | Tela |
|---|---|
| `recurso-workspace-bundle.jpg` | Workspace → `.bundle/vertice/dev/files/src/ml` |
| `recurso-notebook.jpg` | notebook `02-modelo` |
| `recurso-serverless.jpg` | Compute → Serverless |
| `recurso-sql-warehouse.jpg` | Compute → SQL warehouses |
| `recurso-compute-lakebase.jpg` | SQL Editor → escolher compute (warehouse ou Lakebase Postgres) |
| `recurso-catalogo.jpg` | Catalog → `lakehouse_vertice` (5 schemas) |
| `recurso-ingestao-conectores.jpg` | Data Ingestion → conectores |
| `recurso-jobs-pipelines.jpg` | Jobs & Pipelines filtrado por "vertice" |
| `recurso-lineage-lista.jpg` · `recurso-lineage-grafo.jpg` | `gold.projeto_situacao_atual` → Lineage |
| `recurso-metric-view.jpg` | `gold.mv_projetos` (11 medidas) |
| `recurso-query-history.jpg` | Query History com as consultas dos Genies |
| `recurso-genie-perguntas.jpg` · `recurso-genie-instrucoes.jpg` | Genie: perguntas sugeridas e instruções |
| `recurso-lakebase-projeto.jpg` · `recurso-lakebase-tabela.jpg` | Lakebase → `farol-torre` e a tabela `torre.decisoes` |
| `recurso-app-authorize.jpg` | 1º acesso ao app `farol-torre` (Authorize) |

### Noite 3 · ensaio de 21/10 (run 869509423701450 do vertice_farol)

| Arquivo | O que mostra |
|---|---|
| `noite3-job-passo1.jpg` | as duas ingestões (`ingestao_data_lake`, `ingestao_feriados`) verdes: o job de ontem como código |
| `noite3-job-completo.jpg` | o DAG da noite 3: ingestões → conferência → medalhão → IA e testes (recortado antes do ML da noite 4) |
| `noite3-job-timeline.jpg` | o Timeline das 6 tarefas da noite 3, com o tempo de cada uma |
| `noite3-pipeline-tabelas.jpg` | as tabelas do `vertice_medalhao`, com linhas e expectations cumpridas |
| `noite3-dashboard.jpg` | a página Portfólio do "Projeto Farol · Portfólio" (rascunho, antes do Publish) |
| `noite3-dashboard-graficos.jpg` | o Portfólio publicado: estouro previsto por projeto (cor = situação) e SPI × CPI |
