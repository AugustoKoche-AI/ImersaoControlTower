# Aprendizados do ensaio da noite 3 · Free Edition, 18/10/2026

Medido no workspace `dbc-84cd5511` (profile `imersao-out26`), sobre a gold da noite 2.

## O que falhou e como foi resolvido

| # | O que aconteceu | Mensagem | Solução adotada |
|---|---|---|---|
| 1 | **Registrar modelo no Unity Catalog falha em qualquer catálogo** (inclusive `workspace.default` e o `lakehouse_rotaperfume` de agosto) | `S3UploadFailedError ... s3:PutObject ... with an explicit deny in a resource-based policy` | O serverless vem com **MLflow 2.11.4**, que sobe artefato com credencial direta no S3. Com `%pip install -U "mlflow-skinny[databricks]>=2.21,<3"` + `restartPython()` (MLflow 2.22.5, URL pré-assinada) funciona. **Em agosto não precisava.** |
| 2 | O registro que falha deixa versão órfã | `Function '...' is not empty. The function has 1 model versions(s)` | Apagar versões (`model-versions delete`) antes do modelo; o `99-limpar` faz isso |
| 3 | Janela nomeada com frame no SQL | `PARSE_SYNTAX_ERROR ... missing ')'` em `OVER (w ROWS BETWEEN ...)` | `PARTITION BY ... ORDER BY ... ROWS BETWEEN` por extenso |
| 4 | `bundle deploy` recusou | `dashboard "dashboard_portfolio" has been modified remotely` | Com autorização do Luciano: `bundle deploy --force`. Antes disso o ML foi testado com `jobs submit`. Regra: leve a edição para o JSON antes de forçar |
| 5 | Classificador sim/não perde da regra simples | AUC 0,947 × 0,966 da "folga até o corte" | Prever o **pior índice** (regressor) e derivar a probabilidade do erro: AUC 0,973, ganha nos 3 cortes testados (fev, mar, abr) |
| 6 | Vazamento "óbvio" que não vaza | CPI de +4 semanas como feature: AUC 0,972 (o alvo é o pior entre SPI e CPI) | A demonstração usa o **pior índice de +4 semanas**: AUC 0,997, barrado pelo `assert auc < 0.995` |

## Por que o dado torna o baseline tão forte

O SPI e o CPI são **acumulados**: andam devagar e suavemente. Quem cruza 0,9 em
30 dias já está, quase sempre, entre 0,90 e 0,95. Por isso "a folga até o corte"
faz 0,966 e é o baseline a bater. Das 1.141 semanas elegíveis com índice >= 0,95,
só 5 cruzaram em 30 dias.

Isso é conteúdo, não defeito: é o caso real em que **a regra simples é boa** e o
modelo precisa provar que ganha (e o teste quebra a tarefa se um dia não ganhar).

## O que funciona

| Recurso | Status em 18/10/2026 |
|---|---|
| Notebook serverless em job com `%pip install` | ✅ (~20 s a mais) |
| `mlflow.sklearn.log_model` + Unity Catalog + alias `@prod` | ✅ com MLflow >= 2.21 |
| `mlflow.sklearn.load_model("models:/...@prod")` | ✅ |
| `HistGradientBoostingRegressor` / `Classifier` (sklearn do serverless) | ✅ |
| `spark_udf`, XGBoost, endpoint próprio | ❌ (herdado de agosto, não retestado) |

## Tempos medidos

| Etapa | Tempo |
|---|---|
| `01-features.sql` no warehouse | ~8 a 20 s |
| `02-modelo` (com `%pip`) | ~55 s de execução |
| `03-score` | ~45 s |
| Limpeza completa (`99-limpar --apagar --gabarito`) | ~12 s |
| Reconstrução do zero (features + modelo + score) | ~2 min |
| Job `atlas_torre` completo, 8 tarefas (noite 2 + noite 3) | **5 min 45 s** |
