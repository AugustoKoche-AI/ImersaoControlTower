# Aprendizados do ensaio da noite 3 · Free Edition, 18/10/2026

Medido no workspace `dbc-84cd5511` (profile `imersao-out26`), sobre a gold da noite 2 (Vértice Tecnologia).

## O que falhou e como foi resolvido

| # | O que aconteceu | Mensagem | Solução adotada |
|---|---|---|---|
| 1 | **Registrar modelo no Unity Catalog falha em qualquer catálogo** | `S3UploadFailedError ... s3:PutObject ... with an explicit deny in a resource-based policy` | O serverless vem com **MLflow 2.11.4**, que sobe artefato com credencial direta no S3. Com `%pip install -U "mlflow-skinny[databricks]>=2.21,<3"` + `restartPython()` (URL pré-assinada) funciona. **Em agosto não precisava.** |
| 2 | O registro que falha deixa versão órfã | `Function '...' is not empty. The function has 1 model versions(s)` | Apagar versões (`model-versions delete`) antes do modelo; o `99-limpar` faz isso |
| 3 | Janela nomeada com frame no SQL | `PARSE_SYNTAX_ERROR ... missing ')'` em `OVER (w ROWS BETWEEN ...)` | `PARTITION BY ... ORDER BY ... ROWS BETWEEN` por extenso |
| 4 | A tarefa `metricas_governadas` quebrou dentro do job (e não no `run_sql.py`) | `PARSE_SYNTAX_ERROR` no meio do YAML da metric view | A `sql_task` do job corta o arquivo em todo `;`, **inclusive dentro do `$$ ... $$`**. Um comentário do YAML com `;` ("verde >= 0,95; amarelo...") partiu o statement. Nada de `;` dentro do YAML |
| 5 | Notebook do job quebrou com `SyntaxError` numa frase em português | `SyntaxError: invalid syntax` | Célula de texto sem `# MAGIC %md` vira código Python. Toda célula de markdown começa com `# MAGIC %md` |
| 6 | "Só 6 de 11 estouros avisados" na primeira versão | `AssertionError` do teste de 70% | A contagem incluía projeto que cruzou **na semana em que o teste começa** (sem chance de aviso) e projetos que passavam por 0,9 numa semana e voltavam (ruído do status de sexta). Estouro = vinha 4 semanas acima, cruzou e **ficou** abaixo 2 semanas, a partir de 4 semanas de teste: **9 de 10** |
| 7 | O vazamento de demonstração passava no teste | C (índice de +4 semanas como feature) = AUC 0,991 < 0,995 | Com um modelo honesto em 0,92, o limite de "bom demais" desceu para **0,98**: o C é barrado, o A passa com folga |
| 8 | A divisão aleatória não inflou o AUC | A 0,922 · B 0,917 | Desta vez não inflou: a lição muda de "a aleatória mente" para "a aleatória não prova nada; você só descobre depois". A regra continua: divida no tempo |
| 9 | Um projeto "ok" com 88% de chance (PRJ-013; 89% na versão de 19/10) | SPI 0,94 na planilha, 0,90 no status semanal | Sujeira proposital do Excel: uma tarefa digitada com mais de 100%, cortada em 100 na silver, superestima o avanço. O modelo aprende com o status; o score agora avisa *"o cronograma da ferramenta diz 0,94"*. Qualidade de dado é feature |

## Por que o baseline é forte (e o modelo ainda ganha)

O SPI e o CPI são **acumulados**: andam devagar e suavemente. Quem cruza 0,9 em 30 dias
quase sempre já está colado no corte: das 253 semanas elegíveis com índice abaixo de 0,92,
**127** cruzaram; das 980 com índice acima de 0,95, só **40**. Por isso "a folga até o corte"
faz 0,872 e é o baseline a bater.

O modelo ganha (0,922) porque olha o que a folga não vê: o **ritmo do último mês**, o **% físico**
(a feature mais importante), e o texto do status de sexta (freeze, falta de SRE, escopo).

## A simplificação de 19/10/2026

Para mostrar o todo sem gastar tempo em detalhe: o laboratório foi para um schema próprio,
**`lakehouse_vertice.ml`** (`features_projeto_semana`, `modelo_metricas` e o modelo
`modelo_estouro_30d@prod`); na **gold** fica só o resultado, `gold.score_estouro_30d`.
Saíram duas features (`rupturas_capacidade` e `incidentes_8s`: não há mais contratos de
capacidade nem postmortems no projeto) e `saidas_12s` passou a usar o timesheet (quem apontou
hora no projeto). O job ficou com **8 tarefas**.

Remedido em 19/10: AUC 0,92 (classificador 0,90; folga 0,87), **9 de 10** estouros avisados,
**41 dias** antes (era 40), score 18 · 4 · 19, PRJ-024 em **0,46** (era 0,49). Quase nada mudou:
as duas features que saíram pesavam pouco. O notebook do vazamento não foi remedido.

## O que funciona

| Recurso | Status em 18/10/2026 |
|---|---|
| Notebook serverless em job com `%pip install` | ✅ (~20 s a mais) |
| `mlflow.sklearn.log_model` + Unity Catalog + alias `@prod` | ✅ com MLflow >= 2.21 |
| `mlflow.sklearn.load_model("models:/...@prod")` | ✅ |
| `HistGradientBoostingRegressor` / `Classifier` (sklearn do serverless) | ✅ |
| `jobs submit` de um notebook avulso (o do vazamento) com `dbutils.notebook.exit` | ✅ ~26 s |
| `spark_udf`, XGBoost, endpoint próprio | ❌ (herdado de agosto, não retestado) |

## Tempos medidos

| Etapa | Tempo |
|---|---|
| `01-features.sql` no warehouse | ~20 s |
| `02-modelo` (com `%pip`) | ~1 min de execução |
| `03-score` | ~45 s |
| Notebook do vazamento (`jobs submit`) | ~26 s |
| Job `vertice_farol` completo, 9 tarefas (noite 2 + noite 3; hoje são 8) | **4 a 5 min** (4 min 10 s a 5 min 13 s em 3 execuções) |
