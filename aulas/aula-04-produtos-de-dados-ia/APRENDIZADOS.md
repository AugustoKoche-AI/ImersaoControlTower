# Aprendizados do ensaio da noite 4 · Free Edition, outubro/2026

A noite 4 junta o modelo (parte 1), o Genie, o app e o Lakebase (parte 2). O agente de contratos virou
[bônus](bonus/README.md), mas os aprendizados dele continuam aqui.

Medido no workspace `dbc-84cd5511` (profile `imersao-out26`).

## Parte 1 · O modelo (ensaiado em 18 e 19/10, quando era a noite 3)

Medido no workspace `dbc-84cd5511` (profile `imersao-out26`), sobre a gold (Vértice Tecnologia). Em 21/10 o ML mudou para o prompt 1 da noite 4, sem mudar o código.

### O que falhou e como foi resolvido

| # | O que aconteceu | Mensagem | Solução adotada |
|---|---|---|---|
| 1 | **Registrar modelo no Unity Catalog falha em qualquer catálogo** | `S3UploadFailedError ... s3:PutObject ... with an explicit deny in a resource-based policy` | O serverless vem com **MLflow 2.11.4**, que sobe artefato com credencial direta no S3. Com `%pip install -U "mlflow-skinny[databricks]>=2.21,<3"` + `restartPython()` (URL pré-assinada) funciona. **Em agosto não precisava.** |
| 2 | O registro que falha deixa versão órfã | `Function '...' is not empty. The function has 1 model versions(s)` | Apagar versões (`model-versions delete`) antes do modelo; o `prd/99-limpar-modelo.sh` faz isso |
| 3 | Janela nomeada com frame no SQL | `PARSE_SYNTAX_ERROR ... missing ')'` em `OVER (w ROWS BETWEEN ...)` | `PARTITION BY ... ORDER BY ... ROWS BETWEEN` por extenso |
| 4 | A tarefa `metricas_governadas` quebrou dentro do job (e não no `run_sql.py`) | `PARSE_SYNTAX_ERROR` no meio do YAML da metric view | A `sql_task` do job corta o arquivo em todo `;`, **inclusive dentro do `$$ ... $$`**. Um comentário do YAML com `;` ("verde >= 0,95; amarelo...") partiu o statement. Nada de `;` dentro do YAML |
| 5 | Notebook do job quebrou com `SyntaxError` numa frase em português | `SyntaxError: invalid syntax` | Célula de texto sem `# MAGIC %md` vira código Python. Toda célula de markdown começa com `# MAGIC %md` |
| 6 | "Só 6 de 11 estouros avisados" na primeira versão | `AssertionError` do teste de 70% | A contagem incluía projeto que cruzou **na semana em que o teste começa** (sem chance de aviso) e projetos que passavam por 0,9 numa semana e voltavam (ruído do status de sexta). Estouro = vinha 4 semanas acima, cruzou e **ficou** abaixo 2 semanas, a partir de 4 semanas de teste: **9 de 10** |
| 7 | O vazamento de demonstração passava no teste | C (índice de +4 semanas como feature) = AUC 0,991 < 0,995 | Com um modelo honesto em 0,92, o limite de "bom demais" desceu para **0,98**: o C é barrado, o A passa com folga |
| 8 | A divisão aleatória não inflou o AUC | A 0,922 · B 0,917 | Desta vez não inflou: a lição muda de "a aleatória mente" para "a aleatória não prova nada; você só descobre depois". A regra continua: divida no tempo |
| 9 | Um projeto "ok" com 88% de chance (PRJ-013; 89% na versão de 19/10) | SPI 0,94 na planilha, 0,90 no status semanal | Sujeira proposital do Excel: uma tarefa digitada com mais de 100%, cortada em 100 na silver, superestima o avanço. O modelo aprende com o status; o score agora avisa *"o cronograma da ferramenta diz 0,94"*. Qualidade de dado é feature |

### Por que o baseline é forte (e o modelo ainda ganha)

O SPI e o CPI são **acumulados**: andam devagar e suavemente. Quem cruza 0,9 em 30 dias
quase sempre já está colado no corte: das 253 semanas elegíveis com índice abaixo de 0,92,
**127** cruzaram; das 980 com índice acima de 0,95, só **40**. Por isso "a folga até o corte"
faz 0,872 e é o baseline a bater.

O modelo ganha (0,922) porque olha o que a folga não vê: o **ritmo do último mês**, o **% físico**
(a feature mais importante), e o texto do status de sexta (freeze, falta de SRE, escopo).

### A simplificação de 19/10/2026

Para mostrar o todo sem gastar tempo em detalhe: o laboratório foi para um schema próprio,
**`lakehouse_vertice.ml`** (`features_projeto_semana`, `modelo_metricas` e o modelo
`modelo_estouro_30d@prod`); na **gold** fica só o resultado, `gold.score_estouro_30d`.
Saíram duas features (`rupturas_capacidade` e `incidentes_8s`: não há mais contratos de
capacidade nem postmortems no projeto) e `saidas_12s` passou a usar o timesheet (quem apontou
hora no projeto). O job ficou com **8 tarefas**.

Remedido em 19/10: AUC 0,92 (classificador 0,90; folga 0,87), **9 de 10** estouros avisados,
**41 dias** antes (era 40), score 18 · 4 · 19, PRJ-024 em **0,46** (era 0,49). Quase nada mudou:
as duas features que saíram pesavam pouco. O notebook do vazamento não foi remedido.

### O que funciona

| Recurso | Status em 18/10/2026 |
|---|---|
| Notebook serverless em job com `%pip install` | ✅ (~20 s a mais) |
| `mlflow.sklearn.log_model` + Unity Catalog + alias `@prod` | ✅ com MLflow >= 2.21 |
| `mlflow.sklearn.load_model("models:/...@prod")` | ✅ |
| `HistGradientBoostingRegressor` / `Classifier` (sklearn do serverless) | ✅ |
| `jobs submit` de um notebook avulso (o do vazamento) com `dbutils.notebook.exit` | ✅ ~26 s |
| `spark_udf`, XGBoost, endpoint próprio | ❌ (herdado de agosto, não retestado) |

### Tempos medidos

| Etapa | Tempo |
|---|---|
| `01-features.sql` no warehouse | ~20 s |
| `02-modelo` (com `%pip`) | ~1 min de execução |
| `03-score` | ~45 s |
| Notebook do vazamento (`jobs submit`) | ~26 s |
| Job `vertice_farol` completo, 9 tarefas (desenho de 18/10, sem a ingestão) | **4 a 5 min** (4 min 10 s a 5 min 13 s em 3 execuções) |
| Job completo com a ingestão na frente (desenho de 21/10) | *a medir no ensaio* |

## Parte 2 · Genie, app, Lakebase e contratos (ensaio de 18/10)

### O que falhou e como foi resolvido (plataforma)

| # | O que aconteceu | Mensagem | Solução adotada |
|---|---|---|---|
| 1 | Knowledge Assistant e Supervisor Agent | `... is now a legacy feature. New instances can no longer be created ... use Genie Agents instead` | Agente = Genie Agent + contratos em tabela (`ai_parse_document` + `ai_extract` → `gold.contratos`) |
| 2 | Extração estruturada sem descrição dos campos | campo inteiro veio 0 em metade dos documentos (edição de agosto, com `ai_query`) | `description` em cada campo do JSON schema |
| 3 | `typegen` local | todas as queries `OFFLINE` em 0,00 s | `set -a; . ./.env; set +a` e `npm run typegen -- --wait` |
| 4 | Query de `config/queries` com tabela de outra noite | `apps validate`: `TABLE_OR_VIEW_NOT_FOUND` (o build faz typegen `--wait`) | Score da noite 3 lido por rota do servidor (`routes/score.ts`) que responde `{disponivel:false}` |
| 5 | 1º `apps deploy` | `Error building app` · `INSUFFICIENT_PERMISSIONS: User does not have USE CATALOG` | `scripts/conceder-acesso.sh` (GRANT ao service principal) e deploy de novo. O build roda o typegen **como o app** |
| 6 | Arquivo `*.geniespace.json` dentro do app | `Failed to import into the snapshot folder ... Requested node type [UNKNOWN] is not supported` | Renomear para `diretoria-contratos-genie.json` |
| 7 | Projeto Lakebase apagado | `get-project` continua respondendo (tem `delete_time`); o app falha com `Postgres branch ... does not exist` | Checar com `list-projects` |
| 8 | Recriar projeto Lakebase com o mesmo nome | `A soft-deleted project currently has this resource name ... delete ... with purge = true` | `delete-project --purge` no reset (ou `undelete-project`) |
| 9 | Tabela de outra noite sumindo no meio do ensaio | `Failed to fetch tables for the agent ... does not exist` | O gerador do Genie só inclui o score se a tabela existir |
| 10 | Abrir o app no navegador | tela "Permission Requested" (consentimento OAuth, escopo `dashboards.genie`) | Esperado: Authorize uma vez. Testes automáticos usam `Authorization: Bearer $(databricks auth token)` |
| 11 | `databricks psql` | precisa do `psql` instalado | `scripts/ver_decisoes.py` com psycopg + `generate-database-credential` |
| 12 | **Limite de apps do Free Edition** | `Failed to create app farol-torre. Workspace ... has reached the maximum limit of 3 apps.` | Apagar um app antigo antes do prompt 2 (`databricks apps list` / `apps delete`) |
| 13 | Testar o app local (`npm run dev`) antes do deploy | o schema `torre` nasce com **você** como dono; o service principal não escreve nele depois | Apague o schema `torre` antes do 1º deploy (o app recria) |
| 14 | Estado local do bundle de outro app (`.databricks/`) | o próximo deploy alteraria o app antigo | Apague `.databricks/` da pasta ao renomear o app |

### O que aprendemos com o case da Vértice

| # | O que aconteceu | Solução adotada |
|---|---|---|
| 1 | `ai_extract` **sem schema** (lista de nomes) devolve frase: `"0,2% do valor da entrega atrasada por dia corrido, limitada a 5%"` | É a lição da aula: com o JSON schema tipado (versão 2.0), sai `0.2` e `5.0` |
| 2 | Com schema, o SLA da CodeVault veio em italiano ("disponibilità mensal") | `"description": "... copiado do contrato, em português"` |
| 3 | Cortar cláusula por regex de título falha quando o texto começa com "A CONTRATADA" (maiúsculas) | Usar o `type = 'section_header'` que o `ai_parse_document` já devolve |
| 4 | Multa da CodeForge: R$ 3,24 mi no histórico desde 2024 | Contar só o prometido na vigência atual (`data_prometida > add_months(data_fim_vigencia, -12)`): R$ 1,12 mi, o que dá para descontar das próximas faturas |
| 5 | Benchmark do Genie de contratos | **10/10** de primeira no ensaio de 18/10 (desenho antigo), com instrução "a Vértice é a CONTRATANTE" e a regra da vigência atual escrita na instrução |

### O que funciona

| Recurso | Status |
|---|---|
| Lakebase: `create-project` | ✅ **7 s**; branch `production` e database `databricks_postgres` automáticos |
| App + Lakebase (plugin `lakebase()`, recurso `postgres`) | ✅ o app cria o schema `torre` e grava; o dono do projeto lê pelo psycopg |
| `ai_parse_document` em PDF | ✅ elementos com tipo (`title`, `section_header`, `text`) |
| `ai_extract` versão 2.0 com JSON schema | ✅ número, booleano e inteiro tipados; 8/8 contratos certos |
| Genie com contratos citando a cláusula | ✅ benchmark **10/10** no ensaio de 18/10 (desenho antigo, com o manual); rodar de novo com `gold.contratos` |
| AppKit `apps init --features analytics,lakebase,genie` | ✅ ~10 s |
| Header `x-forwarded-email` com o usuário do SSO | ✅ gravado em `torre.decisoes.usuario` |

### Tempos medidos

| Etapa | Tempo |
|---|---|
| SQL dos contratos (8 PDFs: parse + extração) | ~1 min |
| Lakebase `create-project` | 7 s |
| Benchmark de 10 perguntas | ~3 min |
| `apps init` | ~10 s (edição de agosto) |
| `apps deploy` com permissão | 45 s a 1 min (edição de agosto) |
