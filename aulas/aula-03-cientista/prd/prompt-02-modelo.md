# Prompt 2 · Modelo e MLflow — o baseline primeiro

**Entrega:** o modelo `gold.modelo_estouro_30d` no Unity Catalog com alias
`@prod`, a tabela `gold.modelo_metricas` e a tarefa `ml_modelo`. **Deploy nº 8.**

---

## O que mostrar antes

Pergunte para a sala, **antes** de treinar: *"que regra simples você usaria para
achar as obras que vão estourar?"*. Anote as respostas. As três que sempre
aparecem estão no notebook:

| Regra | AUC no teste |
|---|---|
| a regra de corte atual (< 0,9) | 0,50 — não avisa nada antes, por definição |
| a tendência das últimas 4 semanas | **0,47** — pior que jogar uma moeda |
| só o CPI | 0,81 |
| **a folga até o corte** (quem está mais perto de 0,9) | **0,966** |

*(teste: 531 semanas de obra elegíveis a partir de 03/04/2026, 39 estouros)*

**O momento da noite:** a regra de bolso é **excelente**. Ao contrário de agosto,
aqui o baseline é duro de bater. O modelo só tem o direito de existir se ganhar
dele — e esse é um dos `assert` que quebram a tarefa.

**Enquanto ele trabalha, você explica:**

- **Corte no tempo, não aleatório.** Treina até 06/03/2026, testa de 03/04 em
  diante: 4 semanas de folga, que é o horizonte do rótulo. Com divisão aleatória,
  a semana 20 da obra vai para o treino e a semana 21 para o teste: o modelo "cola".
- **Prever o número, não o sim/não.** O classificador sim/não fica em 0,947 e
  **perde** da regra. O que ganha é prever **o pior índice das próximas 4
  semanas** (um regressor) e tirar a probabilidade do erro dele. Bônus: a
  diretoria ganha uma frase que entende, *"o CPI vai a 0,87 em 30 dias"*.
- **A métrica da diretoria não é AUC.** É: *"das obras que estouraram depois de
  abril, quantas estariam na minha lista das 5 mais arriscadas, e quanto tempo
  antes?"*.

---

## O prompt

```
Continue o bundle em aulas/aula-02-engenheiro/meu-atlas/. Crie o notebook
src/ml/02-modelo.py (# Databricks notebook source, widget catalog) e a
tarefa ml_modelo (notebook_task, depois de ml_features).

ARMADILHAS MEDIDAS NO FREE EDITION (siga todas):
- O serverless vem com MLflow 2.11, e registrar modelo no Unity Catalog
  falha com "s3:PutObject ... explicit deny". Primeira célula:
  %pip install -q -U "mlflow-skinny[databricks]>=2.21,<3"
  e dbutils.library.restartPython() na seguinte.
- XGBoost treina e não carrega de volta: use HistGradientBoosting do sklearn.
- DECIMAL vira Decimal no pandas e quebra o registro: .astype(float).
- mlflow.set_experiment não cria a pasta pai: WorkspaceClient().workspace
  .mkdirs("/Users/<eu>/atlas") antes.
- MLflow 2.x: log_model(..., artifact_path="modelo"), nunca name=.

O notebook, nesta ordem:
1. Lê gold.features_obra_semana. Teste = elegíveis com rótulo e semana >=
   2026-04-03. Treino = rotulados com semana <= 2026-03-06 e pct_prazo > 0,15
   (inclui obras já abaixo de 0,9: elas ensinam como uma obra afunda).
2. BASELINES no teste, impressos antes de qualquer treino: regra de corte
   atual (0,5), folga até o corte (-indice_min), só o CPI, tendência
   (-d_indice_min_4s).
3. Modelo: HistGradientBoostingRegressor(random_state=42, max_depth=3,
   learning_rate=0.05, max_iter=300, min_samples_leaf=20) prevendo
   alvo_pior_indice_30d - indice_min. pior_previsto = indice_min + previsão.
   sigma = desvio do erro no teste. prob = P(pior < 0,9) com erro normal
   (math.erf). Compare com um HistGradientBoostingClassifier sim/não.
4. Métrica da diretoria: um estouro é a primeira semana em que uma obra
   que estava >= 0,9 antes do teste cruza para baixo. Avisado = esteve no
   top 5 da semana (rank por prob) em alguma das 8 semanas anteriores.
   Imprima avisados/estouros, antecedência média em dias e o estouro
   previsto hoje (gold.obra_situacao_atual) dessas obras.
5. Importância por permutação.
6. Testes com assert, ANTES de registrar: AUC >= 0,75; AUC < 0,995 (acima
   disso é vazamento); AUC >= a folga até o corte (senão, use a regra);
   avisados >= 70% dos estouros.
7. Retreine com TODOS os rotulados, registre em
   lakehouse_atlas.gold.modelo_estouro_30d com input_example, alias @prod.
8. Grave gold.modelo_metricas (uma linha: versão, auc, baselines, sigma,
   estouros, avisados, antecedência, estouro avisado, feature principal).

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run atlas_torre --only ml_modelo --profile <perfil>
```

---

## O que conferir

```sql
SELECT versao, ROUND(auc, 4) AS auc, ROUND(auc_baseline_folga, 4) AS regra,
       ROUND(auc_classificador, 4) AS sim_nao, estouros_avisados, estouros_teste,
       antecedencia_media_dias, ROUND(estouro_previsto_avisado / 1e6, 1) AS mi
FROM lakehouse_atlas.gold.modelo_metricas;
-- 0,9733 · 0,9664 · 0,9465 · 6 de 7 · 45,5 dias · R$ 8,4 mi
```

**A frase para a diretoria:** *"das 7 obras que estouraram depois de abril, a
Torre teria colocado 6 na lista das 5 mais arriscadas, em média 45 dias antes.
Hoje, a regra de corte avisa zero antes."*

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `s3:PutObject ... explicit deny` no `log_model` | MLflow 2.11 do serverless | `%pip install -U "mlflow-skinny[databricks]>=2.21,<3"` + restart |
| `BAD_REQUEST: For input string: "None"` | pasta do experimento não existe | `workspace.mkdirs` antes do `set_experiment` |
| `Object of type Decimal is not JSON serializable` | coluna DECIMAL no input_example | `.astype(float)` nas features |
| `AssertionError: perde da regra simples` | features ou janela erradas | confira o prompt 1; é o teste fazendo o trabalho dele |
| `AssertionError: bom DEMAIS` | alguma feature vê o futuro | procure `FOLLOWING` fora dos alvos |
| Modelo com versões órfãs depois de falhar | o registro cria a versão antes do upload | `99-limpar-aula-03.sh` apaga versões e modelo |

**Tempo medido:** ~1 min de notebook + ~1 min de partida do serverless
(o `%pip` custa ~20 s).
