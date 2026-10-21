# Prompt 1 · O modelo: o que vai dar errado no próximo mês

**Entrega:** três tarefas novas no job `vertice_farol` (`ml_features` → `ml_modelo` → `ml_score`) e,
no fim delas, `gold.score_estouro_30d`: os 41 projetos em andamento com a **chance de estourar nos
próximos 30 dias** e o **motivo em português**. **Deploy nº 1 da noite.**

> **Onde fica cada coisa:** o laboratório do cientista (features, métricas, o modelo) mora no schema
> `lakehouse_vertice.ml`. Na `gold` entra só o resultado, `gold.score_estouro_30d`, que o Genie e o
> app vão ler nos prompts 2 e 3.
>
> **Medo de ML?** Ninguém escreve código hoje. O Claude Code escreve; você confere os números e
> entende **cada decisão**. A conversa da aula é sobre as decisões.

---

## O que mostrar antes (5 min)

A pergunta 4 do dono, no quadro:

```
"O que vai dar errado no próximo mês, e o que eu faço agora?"

hoje (regra de corte)        SPI ou CPI < 0,9  →  acende QUANDO já estourou
o que o dono quer            acender ANTES:  30 dias de antecedência
```

E o caso da noite: o **PRJ-024 · Marketplace de sellers**. Para a regra, ele está ok: SPI 0,91,
CPI 0,97. É o marketplace de um cliente de varejo, e o change freeze da Black Friday começa em
**01/11**, daqui a 15 dias. *"Guardem esse projeto. No fim do prompt, o modelo vai dizer outra coisa."*

A tradução para ML, de trás para frente:

```
pergunta → rótulo → grão → features → modelo
"vai estourar em 30 dias?"
   → o pior índice (menor entre SPI e CPI) nas próximas 4 semanas fica < 0,9?
   → projeto × semana (o status do PMO é semanal, toda sexta)
   → tudo que o projeto mostrava NAQUELA sexta
```

Antes de colar o prompt, pergunte à sala: *"que regra simples você usaria para achar os projetos que
vão estourar?"*. Anote as respostas. Elas viram os **baselines**, e o modelo só entra se ganhar delas.

---

## As palavras do prompt (uma frase cada)

| Termo | Em uma frase |
|---|---|
| **Rótulo** | a resposta que queremos prever: *"nas 4 semanas seguintes, o projeto caiu abaixo de 0,9?"* (1 = sim, 0 = não). |
| **Feature** | um sinal que o modelo olha para dar o palpite: o SPI de hoje, quanto ele caiu no mês, quantas pessoas saíram do time. |
| **Treino e teste** | o modelo aprende com uma parte do histórico (treino) e é cobrado numa parte que nunca viu (teste). |
| **Corte no tempo** | o treino é o passado (até 06/03/2026) e o teste é o futuro (de 03/04/2026 em diante), como na vida real. |
| **Vazamento** | quando uma feature, sem querer, já sabe o futuro. O modelo fica brilhante no teste e inútil na segunda-feira. |
| **Baseline** | a regra simples que qualquer um usaria. O modelo só entra se ganhar dela. |
| **AUC** | uma nota de 0,5 a 1: 0,5 é jogar moeda, 1,0 é acertar sempre a ordem "quem estoura antes de quem não estoura". |
| **MLflow e `@prod`** | o caderno de laboratório do modelo; no Unity Catalog o modelo vira um objeto do catálogo, e `@prod` aponta para a versão em uso. |
| **Score em lote** | o modelo roda uma vez por semana, dentro do job, e grava o resultado numa tabela. Ninguém chama o modelo ao vivo. |

---

## Enquanto ele trabalha, você explica (as 5 decisões)

1. **Por que projeto × semana e não só projeto?** Com 60 projetos não existe ML. Com 4.235
   sextas-feiras de projeto, existe: cada sexta é uma foto, e o rótulo é o que veio depois.
2. **Feature só olha para trás.** A regra de ouro. Se uma coluna sabe algo que aconteceu depois da
   sexta da linha, o modelo acerta tudo no teste e erra tudo na segunda-feira. O teste `AUC < 0,98`
   está lá para pegar isso.
3. **Corte no tempo, não aleatório.** Treina até 06/03/2026, testa de 03/04 em diante: 4 semanas de
   folga, que é o horizonte do rótulo. Com divisão aleatória, a semana 20 do projeto vai para o treino
   e a 21 para o teste, e você não tem como saber se o modelo "colou".
4. **O baseline é forte, e o modelo tem que ganhar dele.** A regra "quem está mais perto do corte"
   faz AUC 0,87. O SPI e o CPI são acumulados, andam devagar: quem cruza 0,9 já estava colado nele.
   O modelo ganha (0,92) porque olha o que a folga não vê: o ritmo do último mês, o % físico e o
   **texto do status** que a IA classificou ontem (freeze, falta de SRE, escopo). A noite 3 vira
   matéria-prima da noite 4.
5. **A métrica do dono não é AUC.** É: *"dos projetos que estouraram depois de abril, quantos
   estariam na lista dos 5 mais arriscados da semana, e quanto tempo antes?"*. E probabilidade sem
   motivo não gera ação: cada projeto sai com **os motivos em português**.

---

## O prompt

```
Leia o CLAUDE.md da raiz. Continue o MESMO bundle vertice na raiz deste
repositório: ML é mais uma camada do job, não um projeto à parte. O "hoje" é
DATE'2026-10-16'. Nunca current_date(). São três tarefas novas, nesta ordem.

ARMADILHAS MEDIDAS NO FREE EDITION (siga todas):
- O serverless vem com MLflow 2.11, e registrar modelo no Unity Catalog
  falha com "s3:PutObject ... explicit deny". Primeira célula de cada
  notebook: %pip install -q -U "mlflow-skinny[databricks]>=2.21,<3"
  e dbutils.library.restartPython() na seguinte.
- XGBoost treina e não carrega de volta: use HistGradientBoosting do sklearn.
- spark_udf quebra no serverless (InvalidVersion): use mlflow.sklearn.load_model + pandas.
- DECIMAL vira Decimal no pandas e quebra o registro: .astype(float).
- mlflow.set_experiment não cria a pasta pai: WorkspaceClient().workspace
  .mkdirs("/Users/<eu>/vertice") antes.
- MLflow 2.x: log_model(..., artifact_path="modelo"), nunca name=.
- Toda célula de texto começa com "# MAGIC %md".
- Janela nomeada com frame (OVER (w ROWS BETWEEN ...)) dá PARSE_SYNTAX_ERROR:
  escreva PARTITION BY e ORDER BY por extenso nas janelas com ROWS BETWEEN.

1. src/ml/01-features.sql (sql_task ml_features, depois de
   testes_de_qualidade E status_com_ia)
   CREATE SCHEMA IF NOT EXISTS lakehouse_vertice.ml e recrie
   lakehouse_vertice.ml.features_projeto_semana: uma linha por projeto e
   semana (sexta), de gold.fato_projeto_semana + gold.projeto_situacao_atual.
   COMMENT na tabela. Toda feature olha SÓ para trás:
   - spi, cpi, indice_min = least(spi, cpi); variação em 4 e 8 semanas
     (d_spi_4s, d_cpi_4s, d_spi_8s, d_cpi_8s, d_indice_min_4s, com lag());
     semanas_cpi_caindo nas últimas 4
   - ritmo do último mês: cpi_ultimas_4s = (ev - ev 4 semanas antes) /
     (ac - ac 4 semanas antes); spi_ultimas_4s o mesmo com pv
   - pct_fisico = ev / orcamento; pct_prazo = dias desde o início / duração
   - ociosidade_4s; pct_consultoria_4s e pct_cloud_4s (silver.custos)
   - saidas_12s: pessoas que apontaram hora no projeto e se desligaram nas
     últimas 12 semanas (silver.apontamentos + silver.colaboradores)
   - status_freeze_4s, status_falta_sre_4s, status_fornecedor_4s,
     status_rotatividade_4s, status_escopo_4s, status_retrabalho_4s,
     status_com_bloqueio_4s: quantos status dos últimos 28 dias tiveram cada
     causa_bloqueio (gold.status_estruturado, qualquer método)
   Os dois alvos, do FUTURO, que nunca entram como feature:
   alvo_pior_indice_30d = menor least(spi, cpi) nas 4 semanas SEGUINTES
   (ROWS BETWEEN 1 FOLLOWING AND 4 FOLLOWING) e estoura_30d = 1 se < 0,9.
   NULL quando ainda não há 4 semanas de futuro (o caso de hoje).
   elegivel = 1 se SPI e CPI >= 0,9, 84+ dias de projeto, ev < 98% do
   orçamento e (em andamento ou semana anterior a hoje).
   No fim, uma query de conferência: linhas, treino, taxa base, linhas de hoje.

2. src/ml/02-modelo.py (notebook_task ml_modelo, widget catalog)
   a. Teste = elegíveis com rótulo e semana >= 2026-04-03. Treino =
      rotulados com semana <= 2026-03-06 e pct_prazo > 0,15. 24 features
      (todas menos segmento, farol_do_gerente, elegivel e os alvos).
   b. BASELINES no teste, impressos ANTES de treinar: regra de corte atual,
      folga até o corte (-indice_min), só o CPI, tendência (-d_indice_min_4s).
   c. HistGradientBoostingRegressor(random_state=42, max_depth=3,
      learning_rate=0.05, max_iter=300, min_samples_leaf=20) prevendo
      alvo_pior_indice_30d - indice_min; sigma = desvio do erro no teste;
      prob = P(pior < 0,9) com erro normal (math.erf). Compare com um
      HistGradientBoostingClassifier sim/não.
   d. Métrica do dono: estouro = projeto que vinha 4 semanas com SPI e CPI
      >= 0,9, cruza e FICA abaixo 2 semanas (pct_prazo > 0,15), a partir de
      4 semanas depois do início do teste. Avisado = esteve no top 5 da
      semana em alguma das 8 semanas anteriores. Imprima avisados/estouros e
      a antecedência média em dias.
   e. Importância por permutação.
   f. assert ANTES de registrar: AUC >= 0,75; AUC < 0,98 (acima é
      vazamento); AUC >= a folga até o corte; avisados >= 70% dos estouros.
   g. Retreine com todos os rotulados, registre
      lakehouse_vertice.ml.modelo_estouro_30d com input_example, alias @prod,
      e grave ml.modelo_metricas (uma linha com versão, AUC, réguas, sigma,
      estouros, avisados, antecedência e a feature principal).

3. src/ml/03-score.py (notebook_task ml_score, depois de ml_modelo)
   Carregue models:/lakehouse_vertice.ml.modelo_estouro_30d@prod com
   mlflow.sklearn.load_model; o sigma vem de ml.modelo_metricas. Pontue os
   projetos em andamento na semana 2026-10-16; quem tem least(spi, cpi) < 0,9
   NA FOTOGRAFIA DE HOJE (gold.projeto_situacao_atual) recebe 1,0. ranking
   por prob; faixa_risco alto >= 0,5, medio >= 0,2, senão baixo.
   principais_fatores: os 2 ou 3 sinais mais graves, em português, números
   com vírgula decimal (já abaixo do corte, status abaixo do corte com o
   cronograma acima, folga < 0,05, CPI caindo, ritmo do mês < 0,85, falta
   de SRE, freeze, rotatividade, escopo, consultoria, ociosidade >= 25%).
   Grave lakehouse_vertice.gold.score_estouro_30d com EXATAMENTE projeto_id
   STRING, data_referencia DATE, prob_estouro_30d DOUBLE, ranking INT,
   faixa_risco STRING, principais_fatores STRING. COMMENT na tabela e nas
   colunas: o Genie e o app leem daqui. assert: uma linha por projeto em
   andamento, prob entre 0 e 1, ranking único, nenhum motivo vazio.

Rode e me mostre a saída:
  databricks bundle validate --profile <perfil>
  databricks bundle deploy --profile <perfil>
  databricks bundle run vertice_farol --profile <perfil>
E no fim: as métricas de ml.modelo_metricas e o top 25 do score com o motivo.
```

---

## O que conferir

```sql
-- 1 · as features e a taxa base
SELECT COUNT(*) AS linhas,
       COUNT_IF(elegivel = 1 AND estoura_30d IS NOT NULL) AS treino,
       ROUND(AVG(CASE WHEN elegivel = 1 THEN estoura_30d END), 3) AS taxa_base
FROM lakehouse_vertice.ml.features_projeto_semana;
-- 4.235 · 1.643 · 0,167

-- 2 · o modelo contra a regra
SELECT ROUND(auc, 2) AS auc, ROUND(auc_baseline_folga, 2) AS regra, ROUND(auc_classificador, 2) AS sim_nao,
       estouros_avisados, estouros_teste, antecedencia_media_dias
FROM lakehouse_vertice.ml.modelo_metricas;
-- 0,92 · 0,87 · 0,90 · 9 de 10 · 41 dias

-- 3 · a lista de segunda-feira
SELECT s.ranking, s.projeto_id, p.situacao, ROUND(s.prob_estouro_30d, 2) AS prob, s.faixa_risco, s.principais_fatores
FROM lakehouse_vertice.gold.score_estouro_30d s
JOIN lakehouse_vertice.gold.projeto_situacao_atual p USING (projeto_id)
ORDER BY s.ranking LIMIT 25;
-- 1 a 17: os que a regra já vê (7 críticos + 10 em atenção), todos com 1,0
-- 18 · PRJ-013 · ok · 0,89 · alto
-- 19 · PRJ-024 · ok · 0,46 · medio · a 0,01 do corte de 0,9 (índice 0,91)
-- faixas: 18 alto · 4 medio · 19 baixo
```

| Baseline | AUC no teste |
|---|---|
| a regra de corte atual (< 0,9) | 0,50: não avisa nada antes, por definição |
| a tendência das últimas 4 semanas | 0,48: pior que jogar uma moeda |
| só o CPI | 0,65 |
| a folga até o corte | **0,87** |
| **o modelo** | **0,92** |

*(teste: 580 semanas de projeto a partir de 03/04/2026, 70 delas terminaram o mês abaixo de 0,9)*

**A frase para o dono:** *"dos 10 projetos que estouraram depois de abril, a Torre teria colocado 9
na lista dos 5 mais arriscados da semana, em média 41 dias antes. Hoje, a regra de corte avisa zero
antes."* Quarenta e um dias é tempo de pedir aditivo de horas, trocar gente de projeto ou renegociar
o escopo antes de virar atraso.

**O momento "uau":** a regra diz que o **PRJ-024 está ok**. O modelo dá **46% de chance de ele
cruzar 0,9 em 30 dias**, e diz por quê: está a 0,01 do corte. E o freeze da Black Friday começa em
01/11 e trava deploy. O modelo não sabe do calendário; o Genie do prompt 2 vai juntar os dois.

**A lição de qualidade:** o **PRJ-013** tem 89% de chance com SPI 0,94 na planilha. O status de sexta
diz 43% concluído; a planilha soma 45%, porque uma tarefa foi digitada com mais de 100% e a silver
cortou em 100. O modelo aprendeu com o status, e o motivo avisa que as fontes não batem.

**Para mostrar o vazamento** (se sobrar tempo, ou como lição de casa): o notebook
[`../notebooks/02-o-vazamento-de-dado.py`](../notebooks/02-o-vazamento-de-dado.py) treina o mesmo
modelo três vezes. Corte no tempo 0,92, aleatório 0,92, com o índice do futuro como feature **0,99**:
brilhante e inútil, e o `assert < 0,98` barra.

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `s3:PutObject ... explicit deny` no `log_model` | MLflow 2.11 do serverless | `%pip install -U "mlflow-skinny[databricks]>=2.21,<3"` + restart |
| `PARSE_SYNTAX_ERROR ... missing ')'` nas features | `OVER (w ROWS BETWEEN ...)` | janela por extenso nas que têm frame |
| `TABLE_OR_VIEW_NOT_FOUND gold.status_estruturado` | a tarefa `status_com_ia` da noite 3 não rodou | `bundle run vertice_farol` inteiro uma vez |
| taxa base perto de 0 ou de 50% | rótulo olhando a semana errada | `1 FOLLOWING AND 4 FOLLOWING`, nunca `CURRENT ROW` |
| `BAD_REQUEST: For input string: "None"` | pasta do experimento não existe | `workspace.mkdirs` antes do `set_experiment` |
| `Object of type Decimal is not JSON serializable` | coluna DECIMAL no `input_example` | `.astype(float)` |
| `SyntaxError` numa frase em português | célula de texto sem `# MAGIC %md` | toda célula de texto começa com `# MAGIC %md` |
| `AssertionError: perde da regra simples` | features ou janela erradas | é o teste fazendo o trabalho dele: confira o passo 1 |
| `AssertionError: bom DEMAIS` | alguma feature vê o futuro | procure `FOLLOWING` fora dos alvos |
| `InvalidVersion: '18.x-aarch64-photon-scala2'` | `spark_udf` no score | `mlflow.sklearn.load_model` + pandas |
| 60 linhas no score em vez de 41 | faltou filtrar `status = 'em_andamento'` | join com `gold.projeto_situacao_atual` |
| `Function ... is not empty` ao apagar o modelo | versão órfã de um registro que falhou | `prd/99-limpar-modelo.sh` apaga as versões antes |

**Tempo medido (19/10):** features ~20 s · modelo ~1 min (+ ~1 min de partida do serverless) · score
~45 s. O job inteiro, agora com a ingestão na frente: *a medir no ensaio*.

Ensaiar de novo, do zero (só o ML; não toca na noite 3):

```bash
bash aulas/aula-04-produtos-de-dados-ia/prd/99-limpar-modelo.sh <perfil>             # simula
bash aulas/aula-04-produtos-de-dados-ia/prd/99-limpar-modelo.sh <perfil> --apagar    # apaga
```
