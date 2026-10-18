# Prompt 3 · Score em lote — a probabilidade de estouro em 30 dias

**Entrega:** `gold.score_estouro_30d`, uma linha por obra em andamento com
probabilidade, ranking, faixa e **os motivos em português**, e a tarefa
`ml_score`. O job sai de 5 para **8 tarefas**. **Deploy nº 9.**

---

## O que mostrar antes

Sem endpoint de modelo no Free Edition, o modelo roda **em lote**: dentro do job,
toda manhã, e o resultado vira tabela. Para quem consome não muda nada — o número
está lá às 6h10, no dashboard, no Genie e (amanhã) no app.

Esta tabela é um **contrato** com a noite 4:

```
score_estouro_30d
  projeto_id          STRING
  data_referencia     DATE      2026-10-16
  prob_estouro_30d    DOUBLE    0 a 1 · obra já abaixo de 0,9 = 1,0
  ranking             INT       1 = a mais arriscada
  faixa_risco         STRING    alto (>= 0,5) · medio (>= 0,2) · baixo
  principais_fatores  STRING    "CPI caindo há 4 de 4 semanas; cada R$ 1 gasto no último mês entregou R$ 0,66"
```

**Enquanto ele trabalha, você explica:**

- **Probabilidade sem motivo não gera ação.** O gerente não liga para 0,40; liga
  para *"a 0,01 do corte e falta de equipamento em 10% dos RDOs"*.
- **Quem já está abaixo de 0,9 recebe 1,0.** A regra já acendeu: o modelo não
  tem nada a dizer sobre *se*, só sobre *por quê*.

---

## O prompt

```
Continue o bundle em aulas/aula-02-engenheiro/meu-atlas/. Crie o notebook
src/ml/03-score.py (mesma primeira célula de %pip do 02-modelo) e a tarefa
ml_score (notebook_task, depois de ml_modelo).

1. Carregue o modelo com mlflow.sklearn.load_model("models:/lakehouse_atlas
   .gold.modelo_estouro_30d@prod") — NÃO use spark_udf: no serverless ele
   quebra com InvalidVersion. O sigma vem de gold.modelo_metricas.
2. Pontue as obras com status em_andamento na semana 2026-10-16 de
   gold.features_obra_semana: pior_previsto = indice_min + previsão;
   prob = P(pior < 0,9) com erro normal; quem tem indice_min < 0,9 → 1,0.
3. ranking por prob desc (desempate: indice_min asc); faixa_risco alto se
   >= 0,5, medio se >= 0,2, senão baixo.
4. principais_fatores: os 2 ou 3 sinais mais graves em português, com
   números no padrão brasileiro (vírgula decimal). Sinais: já abaixo do corte
   (sempre primeiro), folga < 0,05 até o corte, CPI caindo nas últimas
   semanas, cpi_ultimas_4s < 0,85 ("cada R$ 1 gasto no último mês entregou
   R$ X"), spi_ultimas_4s < 0,85, falta de equipamento >= 10% dos RDOs,
   chuva >= 20%, falta de material >= 40%, mão de obra >= 15%, ociosidade
   >= 15%, 3+ rupturas previstas. Sem sinal: "sem sinal de piora".
5. Grave lakehouse_atlas.gold.score_estouro_30d com EXATAMENTE as colunas
   projeto_id STRING, data_referencia DATE, prob_estouro_30d DOUBLE,
   ranking INT, faixa_risco STRING, principais_fatores STRING (overwrite).
   COMMENT na tabela e nas colunas: a noite 4 lê daqui.
6. Testes com assert: uma linha por obra em andamento, prob entre 0 e 1,
   ranking único, nenhum motivo vazio.

Rode o job inteiro e me mostre o top 10:
  databricks bundle deploy --profile <perfil>
  databricks bundle run atlas_torre --profile <perfil>
```

---

## O que conferir

```sql
SELECT ranking, projeto_id, prob_estouro_30d, faixa_risco, principais_fatores
FROM lakehouse_atlas.gold.score_estouro_30d ORDER BY ranking LIMIT 15;
-- 13 obras em "alto" com 1,0 (as 13 que a regra já vê)
-- 14 · P034 · 0,40 · medio · a 0,01 do corte de 0,9 (índice 0,91); ...
-- 15 · P024 · 0,15 · baixo · a 0,01 do corte de 0,9 (índice 0,91); ...
```

**O momento "uau":** a regra de corte diz que a **P034 está ok** (SPI 0,91, CPI
0,98). O modelo diz **40% de chance de ela cruzar em 30 dias**, e diz por quê.
É a obra que entra na pauta de segunda-feira **antes** de virar problema.

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `InvalidVersion: '18.x-aarch64-photon-scala2'` | `mlflow.pyfunc.spark_udf` | `mlflow.sklearn.load_model` + pandas |
| `RESOURCE_DOES_NOT_EXIST ... @prod` | o alias não foi criado | rode o `ml_modelo` de novo |
| 40 linhas em vez de 36 | faltou filtrar `status = 'em_andamento'` | join com `silver.projetos` |
| a noite 4 não acha a coluna | nome ou tipo mudou | o contrato acima é fixo: `CAST` explícito na escrita |

**Tempo medido:** ~45 s de notebook. Job completo com as 8 tarefas: estimado em ~8 min (5 min 40 s da noite 2 + ~2 min da noite 3; não medido de ponta a ponta porque o deploy do bundle ficou bloqueado, ver APRENDIZADOS).
