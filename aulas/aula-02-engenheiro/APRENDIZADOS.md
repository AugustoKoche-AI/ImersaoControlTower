# Aprendizados do ensaio da noite 2 · Free Edition, 18/10/2026

Medido no workspace `dbc-84cd5511` (profile `imersao-out26`), construindo o
bundle `atlas` do zero, apagando com `prd/00-reset.sh --apagar` e reconstruindo.

## O que falhou e como foi resolvido

| # | O que aconteceu | Mensagem | Solução adotada |
|---|---|---|---|
| 1 | `lag()` dentro de `SUM()` no pipeline | `It is not allowed to use a window function inside an aggregate function` | CTE com o `lag()` (delta por tarefa) e `SUM` no CTE seguinte |
| 2 | Genie do bundle no deploy do zero | `Failed to fetch tables for the agent ... Table 'lakehouse_atlas.gold.x' does not exist` | O Genie exige as tabelas. Do zero: deploy → run → deploy. Na aula acontece natural: o Genie só entra no prompt 6 |
| 3 | IDs do `serialized_space` | `Duplicate question ID ... first seen in config.sample_questions[0]` | IDs de 32 caracteres: prefixo + número com zero à esquerda até 32 (não truncar) |
| 4 | `bundle destroy` apagou o pipeline, mas não as tabelas | 20 materialized views órfãs na silver e gold | `00-reset.sh` apaga uma a uma via `information_schema` (só silver e gold) |
| 5 | `bundle run` logo após um deploy | `An active update '...' already exists for pipeline` | Esperar o update terminar; não rodar duas vezes |
| 6 | Genie API com erro de rede | `Post ".../start-conversation": EOF` | `scripts/genie.py` com retry (EOF, 429, 5xx) e erro por pergunta no benchmark |
| 7 | Benchmark marcou errado uma resposta certa | Genie devolveu `2270,4`; referência arredondava para `2270` | Comparador com 2 casas e aceitando colunas extras do Genie; referência sem `ROUND(..., 0)` |

## O que funciona (e não funcionava em agosto)

| Recurso | Status em 18/10/2026 |
|---|---|
| Lakeflow Spark Declarative Pipelines serverless em SQL, com `EXPECT ... FAIL UPDATE` | ✅ ~2 min por execução |
| Pipeline escrevendo em dois schemas (silver padrão + `lakehouse_atlas.gold.x`) | ✅ |
| `pipeline_task` dentro do job do bundle (`${resources.pipelines.x.id}`) | ✅ |
| Metric views (`WITH METRICS LANGUAGE YAML`, v1.1, `comment`, `synonyms`, `joins using`, `filter`) | ✅ via `sql_task` ou API de statements |
| Metric view pelo `aitools tools query` | ❌ achata a indentação do YAML |
| `ai_classify` no SQL Warehouse | ✅ ~3,7 linhas/s (500 RDOs em 2 min 15 s) |
| Dashboard e Genie como recurso do bundle (`dashboards`, `genie_spaces`) | ✅ |
| Genie com metric views como fonte (`data_sources.metric_views`) | ✅ |
| Lakebase | ✅ cria projeto (`databricks postgres create-project`) — testado pelo pai |
| Knowledge Assistant e Supervisor Agent | ❌ "legacy feature ... use Genie Agents instead" |

## Tempos medidos

| Etapa | Tempo |
|---|---|
| `bundle validate` | ~3 s |
| `bundle deploy` (primeiro / seguintes) | ~10 s / ~7 s |
| Pipeline silver + gold (primeira execução, com cold start) | ~2 min 30 s |
| Tarefa `rdo_com_ia` (977 RDOs na IA) | ~3 min na 1ª; **6,5 s** na seguinte (MERGE incremental) |
| Job `atlas_torre` completo, do zero | **5 min 31 s** (1ª) e **5 min 42 s** (após reset) |
| `00-reset.sh --apagar` | ~20 s + drop das 20 views |
| Benchmark de 20 perguntas no Genie | ~6 min 25 s · **19/20** na 1ª rodada, **20/20** no Genie recriado do zero |

## Decisões de modelagem que viraram conteúdo de aula

- **% acima de 100 → última medição do boletim**, não `LEAST(pct, 100)`. Isso
  muda o estouro previsto de R$ 41,9 mi (noite 1) para R$ 42,36 mi: o atalho
  escondia R$ 0,46 mi.
- **Ruptura prevista** = cobertura < dias até a próxima entrega **prometida**;
  se a promessa já venceu, conta o lead time contratado. Dá 97 rupturas (o
  `material/validar_padroes.py` usa a versão ingênua `max(0, dias)` e dá 76).
- **IA só onde ela é a certa:** regra para "sem ocorrência" (8.878 RDOs), IA nos
  últimos 90 dias com ocorrência (977), palavra-chave no histórico (3.875).
  `MERGE` incremental: a segunda execução não chama a IA de novo.
