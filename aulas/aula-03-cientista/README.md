# 🔮 Noite 3: Cientista de Dados | Imersão Jornada de Dados

**Quarta, 21/10/2026, 19h30.** Ontem a Torre passou a rodar sozinha e a dizer,
todo dia, **quem já estourou**. Hoje ela passa a dizer **quem vai estourar** —
a única pergunta que a diretoria realmente fez:

> **"Quais obras vão estourar prazo ou custo nos próximos 30 dias?"**

> **Domínio:** Construtora Atlas Engenharia, 36 obras em andamento
> **Formato:** 3 prompts no Claude Code, 3 deploys. O mesmo bundle da terça: o job sai de 5 para **8 tarefas**.
> **Conexão:** a tabela de hoje (`gold.score_estouro_30d`) é o que o app da [noite 4](../aula-04-engenheiro-ia) mostra ao diretor.

---

## 🎯 Objetivo da noite

| Entrega | Onde | Prova de que funcionou |
|---|---|---|
| O rótulo e as features, sem olhar o futuro | `gold.features_obra_semana` | 2.874 obras×semana · taxa base **8,4%** |
| O baseline, antes do modelo | notebook `02-modelo` | a regra da folga faz AUC **0,966** |
| O modelo no Unity Catalog | `gold.modelo_estouro_30d@prod` | AUC **0,973** · ganha da regra · 4 testes passam |
| A métrica da diretoria | `gold.modelo_metricas` | **6 de 7** estouros avisados, **45 dias** antes |
| A lista de segunda-feira | `gold.score_estouro_30d` | 36 obras, com probabilidade e **motivo em português** |

---

## 🧠 A ideia da noite: ML é camada, não projeto

Nada de repositório novo, notebook solto ou ambiente à parte. ML entra como
**mais três tarefas do mesmo job**, com os mesmos testes que quebram:

```
                              job atlas_torre (todo dia às 6h)
 conferencia_bronze → medalhao ─┬→ testes_de_qualidade ─┐
                                └→ rdo_com_ia ──────────┴→ metricas_governadas
                                                                  │
                     noite 3 ─────────────────────────────────────┘
                     ml_features ──► ml_modelo ──────────► ml_score
                     (sql_task)      (notebook)             (notebook)
                     obra×semana     baseline, treino,      a lista de hoje,
                     + rótulo        4 testes, MLflow,      com motivo
                                     Unity Catalog @prod    ──► gold.score_estouro_30d ──► app (noite 4)
```

---

## 🏷️ O rótulo (a decisão mais importante da noite)

A Atlas já tem uma regra: **SPI ou CPI abaixo de 0,9 = atenção**. O problema é
que ela acende **quando o estouro já aconteceu**. O rótulo traduz "antecipar":

```
Numa sexta-feira t, para uma obra que AINDA está "ok" (SPI e CPI >= 0,9):

  estoura_30d = 1   se o pior índice (menor entre SPI e CPI) nas 4 semanas seguintes
                    fica abaixo de 0,9
  estoura_30d = 0   senão
```

- **Grão obra × semana**: com 40 obras não existe ML; com 2.874 sextas-feiras de
  obra, existe. Cada sexta é uma foto, o rótulo é o que veio depois.
- **Elegível**: obra com 12+ semanas de vida, não terminada e ainda acima de 0,9.
  Quem já está abaixo, a regra vê; não precisa de modelo.
- **O modelo prevê o número, não só o sim/não**: o pior índice das próximas 4
  semanas. A probabilidade sai do erro dele. A diretoria ganha uma frase que
  entende: *"o CPI desta obra vai a 0,87 em 30 dias"*.

---

## 📋 Os três prompts

| # | Entrega | Arquivo |
|---|---|---|
| 1 | **Features** — o que descreve uma obra que vai estourar | [`prompt-01-features.md`](prd/prompt-01-features.md) |
| 2 | **Modelo e MLflow** — o baseline primeiro | [`prompt-02-modelo.md`](prd/prompt-02-modelo.md) |
| 3 | **Score em lote** — a lista de segunda-feira, com motivo | [`prompt-03-score.md`](prd/prompt-03-score.md) |

Cada arquivo tem o prompt para copiar, o que mostrar antes, o que falar enquanto
o Claude Code trabalha, o que conferir e a tabela **"se der errado"**. A
sequência inteira das noites 2 a 4 está em [`PROMPTS.md`](../../PROMPTS.md).

### Prompt 1 · Features

Uma linha por obra e semana com 21 sinais que **só olham para trás**: nível (SPI,
CPI), tendência (4 e 8 semanas), ritmo do último mês (`cpi_ultimas_4s`: quanto
cada R$ gasto no mês entregou), recursos (ociosidade, rupturas) e o **texto do
RDO** que a IA classificou na noite 2. Mais os dois alvos, que nunca entram como
feature.

### Prompt 2 · O modelo — o momento da noite

Antes de treinar, pergunte para a sala que regra simples ela usaria. Depois mostre:

| Regra | AUC |
|---|---|
| a regra de corte atual (< 0,9) | 0,50 — não avisa nada antes |
| a tendência das últimas 4 semanas | **0,47** — pior que jogar uma moeda |
| só o CPI | 0,81 |
| **a folga até o corte** | **0,966** |
| o classificador sim/não (HistGradientBoostingClassifier) | 0,947 — **perde da regra** |
| **o modelo que prevê o índice** (HistGradientBoostingRegressor) | **0,973** |

**A lição:** ao contrário de agosto, aqui a regra de bolso é excelente. O
classificador "de prateleira" perde dela. O modelo só entra porque **ganha** — e
isso é um `assert` que quebra a tarefa se um dia deixar de ser verdade.

### Prompt 3 · O score

O modelo roda **em lote** (o Free Edition não tem endpoint de modelo próprio) e
grava a lista de hoje, com motivo:

| # | Obra | Prob. | Faixa | Motivos |
|---|---|---|---|---|
| 1 | P030 | 1,00 | alto | já abaixo do corte: SPI 0,78; problema de mão de obra em 15% dos RDOs; 17% das horas da equipe paradas |
| 2 | P011 | 1,00 | alto | já abaixo do corte: SPI 0,78; falta de equipamento em 70% dos RDOs; 28% das horas da equipe paradas |
| 3 | P018 | 1,00 | alto | já abaixo do corte: CPI 0,79; CPI caindo há 4 de 4 semanas (−0,006); cada R$ 1 gasto no último mês entregou R$ 0,66 |
| … | | | | (13 obras que a regra já vê) |
| **14** | **P034** | **0,40** | **medio** | **a 0,01 do corte de 0,9 (índice 0,91); falta de equipamento em 10% dos RDOs; falta de material em 50% dos RDOs** |
| 15 | P024 | 0,15 | baixo | a 0,01 do corte de 0,9 (índice 0,91); falta de material em 45% dos RDOs |

**O momento "uau":** para a regra de corte, a **P034 está ok**. O modelo dá
**40% de chance de ela cruzar em 30 dias** e diz por quê. É a obra que entra na
pauta de segunda **antes** de virar problema.

---

## 💼 A frase para a diretoria (a métrica que não é AUC)

> *"Das 7 obras que estouraram depois de abril, a Torre teria colocado **6** na
> lista das 5 mais arriscadas da semana, em média **45 dias antes**. A regra de
> corte que usamos hoje avisou **zero** antes. Essas 6 obras somam **R$ 8,4 mi**
> de estouro previsto hoje."*

Com o contrato da noite 4 (aditivo tem 30 dias para ser pleiteado, senão o
direito preclui), 45 dias de antecedência é a diferença entre cobrar e perder.

---

## 🛠️ Passo a passo

**Pré-requisito:** a noite 2 rodou (`gold.fato_projeto_semana`, `gold.rdo_estruturado`
e `gold.obra_situacao_atual` existem). Perdeu a noite 2? Use o gabarito como checkpoint:
`cd aulas/aula-02-engenheiro/atlas && databricks bundle deploy --profile SEU-PERFIL &&
databricks bundle run atlas_torre --profile SEU-PERFIL` (~6 min, já inclui as tarefas da noite 3).

1. Abra o Claude Code na raiz do repositório: `claude`.
2. Cole o [prompt 1](prd/prompt-01-features.md). Confira: 2.874 linhas, taxa base 0,084.
3. Cole o [prompt 2](prd/prompt-02-modelo.md). Confira em `gold.modelo_metricas`: AUC 0,97, 6 de 7.
4. Cole o [prompt 3](prd/prompt-03-score.md). Confira o top 15 de `gold.score_estouro_30d`.
5. Rode a verificação:

```bash
python3 scripts/run_sql.py aulas/aula-03-cientista/99-verificacao.sql --profile SEU-PERFIL
# 15 linhas "ok"
```

6. Abra os notebooks de conferência ([`notebooks/`](notebooks)): o que o modelo vale e a demonstração de vazamento.

### Ensaiar de novo, do zero

```bash
bash aulas/aula-03-cientista/prd/99-limpar-aula-03.sh SEU-PERFIL            # simula
bash aulas/aula-03-cientista/prd/99-limpar-aula-03.sh SEU-PERFIL --apagar   # apaga tabelas, modelo,
                                                                           # experimento e o src/ml do meu-atlas
# instrutor, com o gabarito: acrescente --gabarito para limpar só o workspace
```

---

## 🔢 O que deve aparecer na tela

| Métrica | Valor |
|---|---|
| `features_obra_semana` · linhas de treino · taxa base | 2.874 · 1.535 · 8,4% |
| Teste (a partir de 03/04/2026) | 531 obras×semana, 39 estouros |
| AUC: regra da folga · classificador · **modelo** | 0,966 · 0,947 · **0,973** |
| Erro médio do índice previsto · sigma | 0,007 · 0,010 |
| Estouros avisados no top 5 · antecedência | **6 de 7** · **45,5 dias** |
| Estouro previsto hoje das obras avisadas | R$ 8,4 mi |
| Feature mais importante (permutação) | `ociosidade_4s` |
| Score: alto · medio · baixo | 13 · 1 · 22 |
| A obra "ok" mais arriscada | **P034**, 40% |
| Vazamento: corte no tempo · aleatório · com índice do futuro | 0,974 · 0,984 · **0,997** (barrado pelo teste) |

Tudo com `random_state=42` e seed 42: rodando de novo, dá igual (medido: limpeza
completa e reconstrução em 18/10 reproduziram os 15 números da verificação).

---

## 🧯 Se der errado

| Sintoma | Causa | O que fazer |
|---|---|---|
| `s3:PutObject ... explicit deny` ao registrar o modelo | o serverless vem com MLflow 2.11 | `%pip install -U "mlflow-skinny[databricks]>=2.21,<3"` + `restartPython()` na 1ª célula |
| `PARSE_SYNTAX_ERROR ... missing ')'` no SQL das features | janela nomeada com frame (`OVER (w ROWS ...)`) | escreva a janela por extenso |
| `BAD_REQUEST: For input string: "None"` | `set_experiment` numa pasta que não existe | `WorkspaceClient().workspace.mkdirs(...)` antes |
| `Object of type Decimal is not JSON serializable` | coluna DECIMAL no `input_example` | `.astype(float)` |
| `InvalidVersion: '18.x-aarch64-photon-scala2'` | `mlflow.pyfunc.spark_udf` no serverless | `mlflow.sklearn.load_model` + pandas |
| `AssertionError: perde da regra simples` | features erradas, ou o dado mudou | é o teste fazendo o trabalho dele: confira o prompt 1 |
| `AssertionError: bom DEMAIS` | feature que vê o futuro | procure `FOLLOWING` fora das colunas `alvo_`/`estoura_` |
| `Function ... is not empty` ao apagar o modelo | versão órfã de um registro que falhou | o `99-limpar` apaga as versões antes |
| `bundle deploy`: *dashboard has been modified remotely* | alguém editou o dashboard da noite 2 na tela | traga a edição para o JSON ou, se puder perder, `--force` (decisão de quem é dono do dashboard) |

**Tempos medidos:** features ~8 s · modelo ~55 s · score ~45 s · job completo
com as 8 tarefas **5 min 45 s**.

---

## 🧭 Sem escrever código

[`sem-codigo.md`](sem-codigo.md): como gestão, PMO e financeiro usam o score sem
abrir notebook — a lista no SQL Editor, a pergunta no Genie e a leitura dos motivos.

---

## 🗂️ Arquivos desta pasta

| Arquivo | Para que serve |
|---|---|
| `prd/prompt-01-features.md` · `prompt-02-modelo.md` · `prompt-03-score.md` | os 3 prompts, com roteiro e "se der errado" |
| `prd/99-limpar-aula-03.sh` | apaga só a noite 3 (tabelas, modelo, experimento, `src/ml` do meu-atlas) |
| `99-verificacao.sql` | 15 checagens esperado × obtido |
| `notebooks/01-o-que-o-modelo-vale.sql` | conferência: métricas, lista de segunda e a curva da P034 |
| `notebooks/02-o-vazamento-de-dado.py` | o mesmo modelo em 3 divisões: honesta, aleatória e com vazamento |
| `sem-codigo.md` | a trilha de gestão |
| `APRENDIZADOS.md` | o que falhou no Free Edition e como resolvemos |
| Gabarito | [`../aula-02-engenheiro/atlas/src/ml/`](../aula-02-engenheiro/atlas/src/ml) + as tarefas `ml_*` em `resources/atlas.job.yml` |

---

## ➡️ Amanhã

A lista existe, com motivo. Mas ela mora numa tabela — e o diretor não abre o
SQL Editor. Amanhã ela ganha uma **URL**: o app da Torre, onde o gestor vê a
lista, simula a realocação de um guindaste parado em MG para a P011 no Pará e
**aprova**, com a decisão gravada no Lakebase. E um agente que lê o contrato e
diz se o atraso dá multa. → [aula-04](../aula-04-engenheiro-ia)
