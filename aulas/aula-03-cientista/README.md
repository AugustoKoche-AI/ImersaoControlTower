# 🔮 Noite 3: Cientista de Dados | Imersão Jornada de Dados

**Quarta, 21/10/2026, 19h30.** Ontem a Torre passou a juntar Excel, ClickUp e MS Project
sozinha e a dizer, toda segunda, **quem já estourou**. Hoje ela passa a dizer **quem vai
estourar** — a pergunta 4 do dono:

> **"O que vai dar errado no próximo mês, e o que eu faço agora?"**

> **Domínio:** Vértice Tecnologia, 41 projetos em andamento
> **Formato:** 3 prompts no Claude Code, 3 deploys. O mesmo bundle da terça: o job sai de 6 para **9 tarefas**.
> **Conexão:** a tabela de hoje (`gold.score_estouro_30d`) é o que o app da [noite 4](../aula-04-engenheiro-ia) mostra ao dono.

---

## 🎯 Objetivo da noite

| Entrega | Onde | Prova de que funcionou |
|---|---|---|
| O rótulo e as features, sem olhar o futuro | `gold.features_projeto_semana` | 4.235 projetos×semana · taxa base **16,7%** |
| O baseline, antes do modelo | notebook `02-modelo` | a regra da folga faz AUC **0,872** |
| O modelo no Unity Catalog | `gold.modelo_estouro_30d@prod` | AUC **0,922** · ganha da regra · 4 testes passam |
| A métrica do dono | `gold.modelo_metricas` | **9 de 10** estouros avisados, **40 dias** antes |
| A lista de segunda-feira | `gold.score_estouro_30d` | 41 projetos, com probabilidade e **motivo em português** |

---

## 🧠 A ideia da noite: ML é camada, não projeto

Nada de repositório novo, notebook solto ou ambiente à parte. ML entra como
**mais três tarefas do mesmo job**, com os mesmos testes que quebram:

```
                              job vertice_farol (toda segunda às 6h)
 conferencia_bronze → medalhao ─┬→ testes_de_qualidade ─┐
                                ├→ status_com_ia ───────┼→ metricas_governadas
                                └→ postmortem_com_ia ───┘          │
                     noite 3 ──────────────────────────────────────┘
                     ml_features ──► ml_modelo ──────────► ml_score
                     (sql_task)      (notebook)             (notebook)
                     projeto×semana  baseline, treino,      a lista de hoje,
                     + rótulo        4 testes, MLflow,      com motivo
                                     Unity Catalog @prod    ──► gold.score_estouro_30d ──► app (noite 4)
```

---

## 🏷️ O rótulo (a decisão mais importante da noite)

A Vértice já tem uma regra: **SPI ou CPI abaixo de 0,9 = atenção**. O problema é
que ela acende **quando o estouro já aconteceu**. O rótulo traduz "antecipar":

```
Numa sexta-feira t, para um projeto que AINDA está "ok" (SPI e CPI >= 0,9):

  estoura_30d = 1   se o pior índice (menor entre SPI e CPI) nas 4 semanas seguintes
                    fica abaixo de 0,9
  estoura_30d = 0   senão
```

- **Grão projeto × semana**: com 60 projetos não existe ML; com 4.235 sextas-feiras de
  projeto, existe. Cada sexta é uma foto, o rótulo é o que veio depois.
- **Elegível**: projeto com 12+ semanas de vida, não terminado e ainda acima de 0,9.
  Quem já está abaixo, a regra vê; não precisa de modelo.
- **O modelo prevê o número, não só o sim/não**: o pior índice das próximas 4
  semanas. A probabilidade sai do erro dele. O dono ganha uma frase que
  entende: *"o SPI deste projeto vai a 0,87 em 30 dias"*.

---

## 📋 Os três prompts

| # | Entrega | Arquivo |
|---|---|---|
| 1 | **Features** — o que descreve um projeto que vai estourar | [`prompt-01-features.md`](prd/prompt-01-features.md) |
| 2 | **Modelo e MLflow** — o baseline primeiro | [`prompt-02-modelo.md`](prd/prompt-02-modelo.md) |
| 3 | **Score em lote** — a lista de segunda-feira, com motivo | [`prompt-03-score.md`](prd/prompt-03-score.md) |

Cada arquivo tem o prompt para copiar, o que mostrar antes, o que falar enquanto
o Claude Code trabalha, o que conferir e a tabela **"se der errado"**. A
sequência inteira das noites 2 a 4 está em [`PROMPTS.md`](../../PROMPTS.md).

### Prompt 1 · Features

Uma linha por projeto e semana com 26 sinais que **só olham para trás**: nível (SPI,
CPI), tendência (4 e 8 semanas), ritmo do último mês (`cpi_ultimas_4s`: quanto
cada R$ gasto no mês entregou), gente e capacidade (ociosidade, saídas, banco de
horas acabando), incidentes em produção e o **texto do status semanal** que a IA
classificou na noite 2 (freeze, falta de SRE, consultoria, rotatividade, escopo).
Mais os dois alvos, que nunca entram como feature.

### Prompt 2 · O modelo — o momento da noite

Antes de treinar, pergunte para a sala que regra simples ela usaria. Depois mostre:

| Regra | AUC |
|---|---|
| a regra de corte atual (< 0,9) | 0,50 — não avisa nada antes |
| a tendência das últimas 4 semanas | **0,48** — pior que jogar uma moeda |
| só o CPI | 0,65 |
| **a folga até o corte** | **0,872** |
| o classificador sim/não (HistGradientBoostingClassifier) | 0,906 |
| **o modelo que prevê o índice** (HistGradientBoostingRegressor) | **0,922** |

**A lição:** a regra de bolso é boa. O modelo só entra porque **ganha** dela — e
isso é um `assert` que quebra a tarefa se um dia deixar de ser verdade.

### Prompt 3 · O score

O modelo roda **em lote** (o Free Edition não tem endpoint de modelo próprio) e
grava a lista de hoje, com motivo:

| # | Projeto | Prob. | Faixa | Motivos |
|---|---|---|---|---|
| 1 | PRJ-016 · Integração com laboratórios | 1,00 | alto | já abaixo do corte: SPI 0,63; ritmo do último mês em 56% do planejado; rotatividade citada em 1 dos últimos 4 status |
| 5 | PRJ-011 · Checkout e meios de pagamento | 1,00 | alto | já abaixo do corte: SPI 0,77; falta de SRE em 4 dos últimos 4 status; 2 incidentes em produção em 8 semanas |
| 6 | PRJ-027 · Migração do mainframe | 1,00 | alto | já abaixo do corte: CPI 0,79; CPI caindo há 3 de 4 semanas (−0,009); cada R$ 1 gasto no último mês entregou R$ 0,67 |
| … | | | | (17 projetos que a regra já vê) |
| 18 | PRJ-013 · Gestão de estoque em tempo real | 0,88 | alto | pelo status semanal o índice já é 0,90: o cronograma da ferramenta diz 0,94 |
| **19** | **PRJ-024 · Marketplace de sellers** | **0,49** | **medio** | **a 0,01 do corte de 0,9 (índice 0,91); banco de horas ou crédito de cloud acaba em menos de 30 dias** |
| 20 | PRJ-026 · Telemedicina | 0,34 | medio | a 0,00 do corte de 0,9 (índice 0,90); consultoria atrasando em 2 dos últimos 4 status |

**O momento "uau":** para a regra de corte, o **PRJ-024 está ok** (SPI 0,91, CPI 0,97).
O modelo dá **49% de chance de ele cruzar em 30 dias** e diz por quê. E tem mais: ele é o
marketplace de sellers de um cliente de varejo. No freeze da Black Friday do ano passado,
o SPI dele caiu de **0,99 para 0,70**. O de 2026 começa em **01/11**, daqui a 15 dias.
O modelo não sabe do calendário; o agente da noite 4, que lê o manual, vai saber.

---

## 💼 A frase para o dono (a métrica que não é AUC)

> *"Dos 10 projetos que estouraram depois de abril, a Torre teria colocado **9** na
> lista dos 5 mais arriscados da semana, em média **40 dias antes**. A regra de
> corte que usamos hoje avisou **zero** antes."*

Quarenta dias é tempo de pedir aditivo de horas (leva 30), trocar gente de projeto
ou renegociar o escopo com o cliente antes de virar atraso.

---

## 🛠️ Passo a passo

**Pré-requisito:** a noite 2 rodou (`gold.fato_projeto_semana`, `gold.status_estruturado`
e `gold.projeto_situacao_atual` existem). Perdeu a noite 2? Use o gabarito como checkpoint:
`cd aulas/aula-02-engenheiro/vertice && databricks bundle deploy --profile SEU-PERFIL &&
databricks bundle run vertice_farol --profile SEU-PERFIL` (~5 min, já inclui as tarefas da noite 3).

1. Abra o Claude Code na raiz do repositório: `claude`.
2. Cole o [prompt 1](prd/prompt-01-features.md). Confira: 4.235 linhas, taxa base 0,167.
3. Cole o [prompt 2](prd/prompt-02-modelo.md). Confira em `gold.modelo_metricas`: AUC 0,92, 9 de 10.
4. Cole o [prompt 3](prd/prompt-03-score.md). Confira o top 25 de `gold.score_estouro_30d`.
5. Rode a verificação:

```bash
python3 scripts/run_sql.py aulas/aula-03-cientista/99-verificacao.sql --profile SEU-PERFIL
# 17 linhas "ok"
```

6. Abra os notebooks de conferência ([`notebooks/`](notebooks)): o que o modelo vale e a demonstração de vazamento.

### Ensaiar de novo, do zero

```bash
bash aulas/aula-03-cientista/prd/99-limpar-aula-03.sh SEU-PERFIL            # simula
bash aulas/aula-03-cientista/prd/99-limpar-aula-03.sh SEU-PERFIL --apagar   # apaga tabelas, modelo,
                                                                           # experimento e o src/ml do meu-vertice
# instrutor, com o gabarito: acrescente --gabarito para limpar só o workspace
```

---

## 🔢 O que deve aparecer na tela

| Métrica | Valor |
|---|---|
| `features_projeto_semana` · linhas de treino · taxa base | 4.235 · 1.643 · 16,7% |
| Teste (a partir de 03/04/2026) | 580 projetos×semana, 70 terminaram o mês abaixo de 0,9 |
| AUC: regra da folga · classificador · **modelo** | 0,872 · 0,906 · **0,922** |
| Erro médio do índice previsto · sigma | 0,016 · 0,021 |
| Estouros avisados no top 5 · antecedência | **9 de 10** · **40,4 dias** |
| Estouro previsto hoje dos projetos avisados | R$ 2,44 mi |
| Feature mais importante (permutação) | `pct_fisico` |
| Score: alto · medio · baixo | 18 · 4 · 19 |
| Projetos "ok" para a regra com risco alto ou médio | 5 (PRJ-013, PRJ-024, PRJ-026, PRJ-053, PRJ-056) |
| O "uau" | **PRJ-024**, 49%: marketplace, colado no corte, e o freeze começa em 01/11 |
| Vazamento: corte no tempo · aleatório · com índice do futuro | 0,922 · 0,917 · **0,991** (barrado pelo teste de 0,98) |

Tudo com `random_state=42` e seed 42: rodando de novo, dá igual (medido: três execuções
do job completo em 18/10 gravaram as mesmas métricas).

---

## 🧯 Se der errado

| Sintoma | Causa | O que fazer |
|---|---|---|
| `s3:PutObject ... explicit deny` ao registrar o modelo | o serverless vem com MLflow 2.11 | `%pip install -U "mlflow-skinny[databricks]>=2.21,<3"` + `restartPython()` na 1ª célula |
| `PARSE_SYNTAX_ERROR ... missing ')'` no SQL das features | janela nomeada com frame (`OVER (w ROWS ...)`) | escreva a janela por extenso |
| `metricas_governadas` falha no job, mas roda no `run_sql.py` | `;` dentro do YAML de uma metric view | a `sql_task` corta em todo `;`: tire o `;` do comentário |
| `SyntaxError` numa frase em português | célula de texto sem `# MAGIC %md` | toda célula de markdown começa com `# MAGIC %md` |
| `BAD_REQUEST: For input string: "None"` | `set_experiment` numa pasta que não existe | `WorkspaceClient().workspace.mkdirs(...)` antes |
| `Object of type Decimal is not JSON serializable` | coluna DECIMAL no `input_example` | `.astype(float)` |
| `InvalidVersion: '18.x-aarch64-photon-scala2'` | `mlflow.pyfunc.spark_udf` no serverless | `mlflow.sklearn.load_model` + pandas |
| `AssertionError: perde da regra simples` | features erradas, ou o dado mudou | é o teste fazendo o trabalho dele: confira o prompt 1 |
| `AssertionError: bom DEMAIS` | feature que vê o futuro | procure `FOLLOWING` fora das colunas `alvo_`/`estoura_` |
| `Function ... is not empty` ao apagar o modelo | versão órfã de um registro que falhou | o `99-limpar` apaga as versões antes |

**Tempos medidos:** features ~20 s · modelo ~1 min · score ~45 s · job completo
com as 9 tarefas **4 a 5 min**.

---

## 🧭 Sem escrever código

[`sem-codigo.md`](sem-codigo.md): como gestão, PMO e financeiro usam o score sem
abrir notebook — a lista no SQL Editor, a pergunta no Genie e a leitura dos motivos.

---

## 🗂️ Arquivos desta pasta

| Arquivo | Para que serve |
|---|---|
| `prd/prompt-01-features.md` · `prompt-02-modelo.md` · `prompt-03-score.md` | os 3 prompts, com roteiro e "se der errado" |
| `prd/99-limpar-aula-03.sh` | apaga só a noite 3 (tabelas, modelo, experimento, `src/ml` do meu-vertice) |
| `99-verificacao.sql` | 17 checagens esperado × obtido |
| `notebooks/01-o-que-o-modelo-vale.sql` | conferência: métricas, lista de segunda e a curva do PRJ-024 |
| `notebooks/02-o-vazamento-de-dado.py` | o mesmo modelo em 3 divisões: honesta, aleatória e com vazamento |
| `sem-codigo.md` | a trilha de gestão |
| `APRENDIZADOS.md` | o que falhou no Free Edition e como resolvemos |
| Gabarito | [`../aula-02-engenheiro/vertice/src/ml/`](../aula-02-engenheiro/vertice/src/ml) + as tarefas `ml_*` em `resources/vertice.job.yml` |

---

## ➡️ Amanhã

A lista existe, com motivo. Mas ela mora numa tabela — e o dono não abre o
SQL Editor. Amanhã ela ganha uma **URL**: o app da Torre, onde o CTO vê a
lista, simula realocar um dos SREs parados no PRJ-007 para o PRJ-011 e
**aprova**, com a decisão gravada no Lakebase. E um agente que lê os contratos
de fornecedor e o manual da Vértice e diz o que fazer antes do freeze. → [aula-04](../aula-04-engenheiro-ia)
