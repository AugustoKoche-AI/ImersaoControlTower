# Aprendizados do ensaio da noite 2 · Free Edition, 18/10/2026

Medido no workspace `dbc-84cd5511` (profile `imersao-out26`), construindo o
bundle `vertice` sobre a bronze da noite 1.

## O que falhou e como foi resolvido

| # | O que aconteceu | Mensagem | Solução adotada |
|---|---|---|---|
| 1 | Função de janela dentro de agregação no pipeline | `It is not allowed to use a window function inside an aggregate function` | CTE com a janela (`last_value`, `SUM OVER`) e a conta no CTE seguinte |
| 2 | Genie do bundle no deploy do zero | `Failed to fetch tables for the agent ... Table 'lakehouse_vertice.gold.x' does not exist` | O Genie exige as tabelas. Do zero: deploy → run → deploy. Na aula acontece natural: o Genie só entra no prompt 6 |
| 3 | IDs do `serialized_space` | `Duplicate question ID ... first seen in config.sample_questions[0]` | IDs de 32 caracteres: prefixo + número com zero à esquerda até 32 (não truncar) |
| 4 | `bundle destroy` apaga o pipeline, mas não as tabelas | materialized views órfãs na silver e gold | `00-reset.sh` apaga uma a uma via `information_schema` (só silver e gold) |
| 5 | XML do Project lido com `inferColumnTypes => false` | a `Baseline` vira texto (`<Number>0</Number>...`) | No XML e no JSON a inferência fica ligada: é ela que mantém a estrutura |
| 6 | `ai_extract` sem schema | todo campo volta como texto (`"7"`) | Versão 2.0 com JSON schema tipado: `{"dias_impacto":{"type":"number"}}` e `map('version','2.0')` |
| 7 | Genie curado, 1ª rodada do benchmark: 18/20 | ranking feito na metric view com `HAVING` inválido; cliente repetido por projeto | Duas instruções: ranking em `projeto_situacao_atual`; "quais clientes" = um por cliente. 20/20 |
| 8 | "O que vai dar errado no próximo mês?" | `FAILED` | Exemplo de SQL com `UNION ALL` das entregas atrasadas e do freeze da Black Friday (a previsão completa é o modelo da noite 3) |
| 9 | Bundle copiado de outro projeto com a pasta `.databricks/` junto | o deploy editaria os recursos do projeto antigo | Apagar a `.databricks/` local antes do primeiro deploy de um bundle copiado ou renomeado |

## O que funciona (medido em 18/10/2026)

| Recurso | Status |
|---|---|
| Lakeflow Spark Declarative Pipelines serverless em SQL, com `EXPECT ... FAIL UPDATE` | ✅ ~2 min por execução |
| `CREATE TEMPORARY VIEW` dentro do pipeline (uma visão por ferramenta) | ✅ aparecem no grafo, não no catálogo |
| Pipeline escrevendo em dois schemas (silver padrão + `lakehouse_vertice.gold.x`) | ✅ |
| `pipeline_task` dentro do job do bundle (`${resources.pipelines.x.id}`) | ✅ |
| Metric views (`WITH METRICS LANGUAGE YAML`, v1.1, `comment`, `synonyms`, `filter`) | ✅ via `sql_task` ou API de statements |
| Metric view pelo `aitools tools query` | ❌ achata a indentação do YAML |
| `ai_classify` e `ai_extract` versão 2.0 no SQL Warehouse | ✅ ~5 s por texto com as duas; 163 status em ~2 min |
| Dashboard e Genie como recurso do bundle (`dashboards`, `genie_spaces`) | ✅ |
| Genie com metric view como fonte (`data_sources.metric_views`) | ✅ |
| Knowledge Assistant e Supervisor Agent | ❌ "legacy feature ... use Genie Agents instead" |

## Tempos medidos

| Etapa | Tempo |
|---|---|
| `bundle validate` | ~3 s |
| `bundle deploy` (primeiro / seguintes) | ~10 s / ~7 s |
| Pipeline silver + gold (primeira execução, com cold start) | ~2 min |
| Tarefa `status_com_ia` (163 status na IA) | ~2 min |
| Metric view `mv_projetos` | ~10 s |
| Benchmark de 20 perguntas no Genie | ~6 min · **18/20** na 1ª rodada, **20/20** depois de duas instruções |

## Decisões de modelagem que viraram conteúdo de aula

- **A integração é um contrato de colunas.** Cada ferramenta vira uma `TEMPORARY VIEW` com
  as mesmas 13 colunas; a `silver.tarefas` é o `UNION ALL`. O teste 3 prova que nada se
  perdeu: as horas do Excel na silver = a soma das linhas de TOTAL das planilhas.
- **O de-para é dado.** `silver.projetos` diz qual arquivo ou lista é qual projeto. Quando o
  código falta, casa pelo nome do arquivo (Excel) ou da lista (ClickUp), e o
  `EXPECT achou_o_projeto` garante que nenhuma tarefa fica órfã.
- **O histórico vem do status semanal.** As ferramentas só guardam o % de hoje. O fato
  semanal usa o % do status de cada sexta; a fotografia de hoje usa as tarefas. O teste 9
  confere que os dois concordam hoje (diferença < 1%).
- **% acima de 100 → 100 com flag.** Não há medição melhor em outro sistema (as
  ferramentas só guardam o % de hoje): a decisão honesta é cortar e sinalizar (`pct_veio_acima_de_100`, 11 tarefas).
- **IA só onde ela é a certa:** regra para "sem bloqueio" (2.954 status), IA nos últimos 90
  dias com bloqueio (163), palavra-chave no histórico (794). `MERGE` incremental: a segunda
  execução não chama a IA de novo.
- **Simplificar para mostrar o todo** (revisão de 19/10/2026): a bronze foi de 13 para 9
  tabelas, a silver de 11 para 7 e a gold ficou com 3 tabelas, a `status_estruturado` e
  uma metric view (`mv_projetos`). Saíram alocações, contratos e consumo de capacidade,
  postmortems, `dim_projeto` (o cadastro foi para dentro da `projeto_situacao_atual`), as
  tabelas gold de fornecedor (lidas direto da `silver.entregas_fornecedor`) e as outras
  quatro metric views. Uma tarefa de IA, um modelo, poucas tabelas: o tempo da aula vai
  para a integração das 3 ferramentas, que é o centro da noite.
