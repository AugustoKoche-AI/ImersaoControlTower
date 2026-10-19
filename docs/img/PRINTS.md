# Prints dos entregáveis

Os slides embutem estes arquivos. Enquanto um print não existe, o slide mostra um quadro
"print pendente" com o nome esperado. Salve cada tela como **JPG** nesta pasta, com o nome
exato, e rode `python3 scripts/gerar_slides.py slides/apresentacao-final.slides.html`.

Dica: janela do navegador em 1600 × 900 (ou tela cheia), tema do Databricks escuro, zoom 100%.
Workspace: `https://dbc-84cd5511-fa25.cloud.databricks.com` (o `?o=1253341796019093` é adicionado sozinho).

## Noite 1 · Analista

| Arquivo | O que mostrar | Onde |
|---|---|---|
| `noite1-volume-excel.jpg` | as 20 planilhas `.xlsx` dentro do volume | Catalog → lakehouse_vertice → bronze → Volumes → raw → `excel/` |
| `noite1-catalogo-bronze.jpg` | as 13 tabelas da bronze (e o `rascunho_tarefas`) | Catalog → lakehouse_vertice → bronze |
| `noite1-dashboard.jpg` | os 4 KPIs e o SPI por projeto | `/dashboardsv3/01f1cb42fb791754957e69d572ed0fa6/published` |
| `noite1-genie-erra.jpg` | a resposta "nenhum atraso está impactando financeiramente" para *Quanto esse atraso vai me custar?* | Genie Agents → **Farol · Noite 1 (bronze, sem curadoria)** (`/genie/rooms/01f1cb43b49b153ba093e02c8e64ba61`) |

## Noite 2 · Engenheiro de Dados

| Arquivo | O que mostrar | Onde |
|---|---|---|
| `noite2-pipeline.jpg` | o grafo do pipeline com as 3 visões desaguando em `silver.tarefas` | `/pipelines/1786b2c7-f994-4582-8418-df46337245a1` |
| `noite2-job.jpg` | o DAG do job verde, com as 9 tarefas | `/jobs/409863010487260` → última execução |
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
