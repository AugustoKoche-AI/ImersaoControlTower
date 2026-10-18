# CLAUDE.md

Material e código da **Imersão Databricks + Claude Code** (Jornada de Dados, 19 a 22/10/2026): construir
ao vivo, em 4 noites de 1h30, a **Torre de Controle de Projetos** da Construtora Atlas Engenharia (EPC fictícia).
Todo o conteúdo é em português e escrito para ser acompanhado ao vivo por um público misto: cerca de metade
nunca programou ou só fez exercícios.

## Organização

Uma pasta por noite, autocontida (README, roteiro, verificação), no mesmo esquema do repositório de agosto
(`lvgalvao/projeto-dados-ia-databricks`):

| Pasta | Noite |
|---|---|
| `aulas/aula-01-analista/` | 1 · navegador: setup, bronze, 6 exemplos SQL, dashboard sobre a bronze, Genie sem curadoria |
| `aulas/aula-02-engenheiro/` | 2 · prompts no Claude Code: bundle `atlas`, pipeline Lakeflow, ai_extract nos RDOs, Metric Views, Genie curado |
| `aulas/aula-03-cientista/` | 3 · prompts: features, modelo de estouro em 30 dias, score em lote |
| `aulas/aula-04-engenheiro-ia/` | 4 · prompts: app da Torre (AppKit) + Lakebase, agente de contratos, pitch |
| `material/` | PRD, gerador do dataset, validador dos padrões, writer de PDF |
| `scripts/` | `run_sql.py`, `genie.py`, `gerar_notebooks.py`, `gerar_slides.py`, `gerar_prompts.py` |
| `slides/` | `_modelo.html` (motor dos slides do jornada-ops) + `aula-NN.slides.html` → `aula-NN.html` |

Exemplos novos na aula 01 seguem `exemplo-NN-tema.sql`, com cabeçalho de conceito, pergunta de negócio e
conexão com a noite seguinte. Depois de editar um exemplo, rode `python3 scripts/gerar_notebooks.py aulas/aula-01-analista`.

## Databricks

- Carregue a skill `databricks-core` antes de qualquer ação, mais a do produto (`databricks-dabs`,
  `databricks-pipelines`, `databricks-metric-views`, `databricks-genie-agents`, `databricks-apps`…).
- **Nunca escolha um profile sozinho.** O profile de desenvolvimento desta imersão é `imersao-out26`
  (workspace `dbc-84cd5511-fa25`, o mesmo de agosto, que também tem `lakehouse_rotaperfume`).
- Ambiente-alvo: **Free Edition, serverless**. Warehouse `Serverless Starter Warehouse` (`666be37e3fededf2`).
- Catálogo **`lakehouse_atlas`**. `CREATE CATALOG` só via SQL: a API do UC recusa no Free Edition.

### O que funciona no Free Edition (medido em 18/10/2026)

- ✅ Lakebase (`databricks postgres create-project`). Em agosto não existia.
- ✅ `ai_extract`, `ai_classify`, `ai_query`; AI/BI; Genie Agents (com modo Agent); Apps.
- ✅ Notebook serverless tem internet e lê arquivo do Git folder (`os.getcwd()` é a pasta do notebook).
- ✅ Metric Views, **mas só pela API de statements**. `databricks experimental aitools tools query` achata a
  indentação e o YAML quebra com `Missing required creator property 'expr'`. Por isso o `scripts/run_sql.py`
  usa `databricks api post /api/2.0/sql/statements`.
- ❌ Knowledge Assistant e Supervisor Agent: "legacy feature, use Genie Agents instead". Não criam mais.
- ❌ Endpoint de modelo próprio: só Foundation Models. Score de ML em lote, gravado na gold.
- Herdado de agosto (ML): `spark_udf` não roda no serverless; XGBoost não carrega de volta (use
  `HistGradientBoostingClassifier`); `mlflow.set_experiment` não cria a pasta pai; serverless traz MLflow 2.x
  (`artifact_path=`); DECIMAL precisa de `.cast("double")` antes de registrar o modelo.
- Herdado de agosto (Apps): `bundle deploy` cria o app parado, o deploy é `databricks apps deploy`; o service
  principal do app precisa de `GRANT USE CATALOG/USE SCHEMA/SELECT`; o warehouse devolve número como string.
- URL de dashboard publicado: `https://<host>/dashboardsv3/<id>/published` (sem `/sql`).

- ⚠️ Registro de modelo no UC falha com o MLflow 2.11 do serverless (`s3:PutObject explicit deny`):
  `%pip install -U "mlflow-skinny[databricks]>=2.21,<3"` + `dbutils.library.restartPython()`.
- Apagar o pipeline não apaga as materialized views: o `00-reset.sh` da noite 2 apaga uma a uma.
- O Genie do bundle exige as tabelas: do zero, a ordem é deploy → run → deploy.
- Editar dashboard ou Genie direto no workspace trava o `bundle deploy` ("modified remotely"):
  leve a mudança para o JSON do repositório e use `--force` só depois disso.
- Lakebase: apagar projeto é exclusão suave por 7 dias e prende o nome (use `delete-project --purge` no reset;
  confira com `list-projects`, não com `get-project`). O build do app roda o typegen **como o service principal**:
  os GRANTs vêm antes do segundo `apps deploy`. Nenhum arquivo `*.geniespace.json` dentro da pasta do app.
- O primeiro acesso ao app pede consentimento OAuth ("Authorize"), feito por uma pessoa. Testes automáticos
  usam `Authorization: Bearer $(databricks auth token)`.
- Nomes de Genie são únicos por título no `scripts/genie.py`: "Noite 1 (bronze, sem curadoria)", "Diretoria"
  (noite 2, do bundle) e "Diretoria + Contratos" (noite 4).

Aprendizados detalhados de cada noite: `aulas/<noite>/APRENDIZADOS.md`.

## Dataset

`python3 material/gerar_dataset.py --saida ./dados --seed 42` (só stdlib, cerca de 1,6 s, 12 MB) e
`python3 material/validar_padroes.py --dados ./dados` (sai com 1 se um padrão sumir).

- **"Hoje" = 2026-10-16.** Nunca `current_date()`.
- **A sujeira é conteúdo, não bug.** Nunca conserte o gerador para limpar dado. A limpeza é na silver (noite 2).
- **Seed fixa.** Mudou o gerador? Rode o validador, regere, recarregue a bronze e atualize os números esperados
  em `aulas/aula-01-analista/99-verificacao.sql`, nos READMEs e nos slides, nessa ordem.
- Padrões que os KPIs precisam mostrar: CPI caindo a partir do 9º mês em `P002 P005 P009 P014 P018 P021 P027 P033`;
  chuva no Pará em `P003 P011 P024`; Metalúrgica Norte Aço com lead time ×1,41 e escrita de 4 jeitos;
  guindastes `EQ0017`/`EQ0018` ociosos na `P007` (MG) enquanto a `P011` (PA) reclama de guindaste no RDO;
  equipe fraca em `P016 P030`.
- Ruptura prevista = cobertura (saldo ÷ consumo previsto/dia) < dias até a próxima entrega prometida
  (promessa já vencida ou sem pedido em aberto: lead time contratado). Dá **97** hoje, igual em
  `gold.cobertura_estoque` e no `validar_padroes.py`. A fórmula ingênua do PRD (cobertura < lead time) dá 181.

## Números de referência

Noite 2 (gold): estouro R$ 42,36 mi (a noite 1 dá R$ 41,9 mi porque corta % > 100 com `LEAST`, o que é ponto de aula) ·
SPI/CPI da carteira 0,95/0,94 · 97 rupturas · 27 pedidos em atraso · Genie 20/20.
Noite 3: AUC 0,973 (regra atual 0,50; folga 0,966) · 6 de 7 estouros no top 5, 45 dias antes · P034 "ok" com prob 0,40.
Noite 4: 88 cláusulas · multa P011 R$ 1,88 mi · simulador EQ0017 → P011: 7,8 dias e R$ 82,6 mil · ROI ≈ R$ 12,9 mi.

### Noite 1

40 obras (36 em andamento) · carteira R$ 903,0 mi (R$ 794,8 mi em andamento) · custo real R$ 572,85 mi
(R$ 556,09 mi com `try_cast`, ou seja, 540 lançamentos perdidos) · 13 obras em risco, 7 críticas · estouro previsto
R$ 41,9 mi (soma só dos positivos) · P011 com +178 dias de atraso projetado.

## Comandos

```bash
python3 scripts/run_sql.py <arquivo.sql> --profile imersao-out26 [--continuar] [--quiet]
python3 aulas/aula-01-analista/gerar_dashboard.py --deploy --profile imersao-out26
python3 scripts/genie.py publicar <espaco.json> --titulo "..." --profile imersao-out26
python3 scripts/genie.py perguntar "<título>" "pergunta" --profile imersao-out26
python3 scripts/genie.py benchmark "<título>" <benchmark.json> --profile imersao-out26
python3 scripts/gerar_notebooks.py aulas/aula-01-analista [--importar --profile imersao-out26]
python3 scripts/gerar_slides.py slides/aula-01.slides.html
python3 scripts/gerar_prompts.py                 # regera o PROMPTS.md a partir de aulas/*/prd/prompt-*.md
```

## Slides

Visual da Jornada (Poppins, `#14141A`, azul `#0059DB`, ciano `#22C2F4`), o mesmo motor das apresentações do time
(`jornada-ops/scripts/apresentacao_time.py`). Escreva só as `<section class="slide">` em `slides/aula-NN.slides.html`
e rode o `gerar_slides.py`. `[[IMG:docs/img/x.jpg]]` embute o print; `[[RODAPE]]` põe logo e número da página.
Todo número do slide sai de uma query rodada; cite a fonte no README da noite.

## Convenções

- Código e comentários para quem assiste ao vivo pela primeira vez: SQL legível, não esperto.
- Tabelas e colunas em snake_case e português. Referência completa `lakehouse_atlas.<schema>.<tabela>` nos `.sql`;
  nome sem catálogo **dentro** do JSON do dashboard (catálogo e schema entram no deploy).
- Sempre `--profile`. Nada de `mode: development` no bundle (prefixa os schemas). Use `presets.trigger_pause_status`.
- Responda em português, curto e direto.
