# Prompt 3 · Score em lote — a probabilidade de estouro em 30 dias

**Entrega:** `gold.score_estouro_30d`, uma linha por projeto em andamento com
probabilidade, ranking, faixa e **os motivos em português**, e a tarefa
`ml_score`. O job sai de 6 para **9 tarefas**. **Deploy nº 9.**

---

## O que mostrar antes

Sem endpoint de modelo no Free Edition, o modelo roda **em lote**: dentro do job,
toda segunda de manhã, e o resultado vira tabela. Para quem consome não muda nada —
o número está lá às 6h10, no dashboard, no Genie e (amanhã) no app.

Esta tabela é um **contrato** com a noite 4:

```
score_estouro_30d
  projeto_id          STRING
  data_referencia     DATE      2026-10-16
  prob_estouro_30d    DOUBLE    0 a 1 · projeto já abaixo de 0,9 = 1,0
  ranking             INT       1 = o mais arriscado
  faixa_risco         STRING    alto (>= 0,5) · medio (>= 0,2) · baixo
  principais_fatores  STRING    "já abaixo do corte: SPI 0,77; falta de SRE em 4 dos últimos 4 status"
```

**Enquanto ele trabalha, você explica:**

- **Probabilidade sem motivo não gera ação.** O gerente não liga para 0,49; liga
  para *"a 0,01 do corte e o crédito de cloud acaba em menos de 30 dias"*.
- **Quem já está abaixo de 0,9 recebe 1,0.** A regra já acendeu: o modelo não
  tem nada a dizer sobre *se*, só sobre *por quê*. A régua de "abaixo" é a
  fotografia de hoje (`gold.projeto_situacao_atual`), a mesma do dashboard e do Genie.

---

## O prompt

```
Continue o bundle em aulas/aula-02-engenheiro/meu-vertice/. Crie o notebook
src/ml/03-score.py (mesma primeira célula de %pip do 02-modelo) e a tarefa
ml_score (notebook_task, depois de ml_modelo).

1. Carregue o modelo com mlflow.sklearn.load_model("models:/lakehouse_vertice
   .gold.modelo_estouro_30d@prod") — NÃO use spark_udf: no serverless ele
   quebra com InvalidVersion. O sigma vem de gold.modelo_metricas.
2. Pontue os projetos em andamento na semana 2026-10-16 de
   gold.features_projeto_semana, com join em gold.projeto_situacao_atual:
   pior_previsto = indice_min + previsão; prob = P(pior < 0,9) com erro
   normal; quem tem least(spi, cpi) < 0,9 NA FOTOGRAFIA DE HOJE → 1,0.
3. ranking por prob desc (desempate: índice de hoje asc); faixa_risco alto
   se >= 0,5, medio se >= 0,2, senão baixo.
4. principais_fatores: os 2 ou 3 sinais mais graves em português, com
   números no padrão brasileiro (vírgula decimal). Sinais: já abaixo do
   corte (sempre primeiro), status semanal abaixo do corte e cronograma
   acima (as fontes não batem), folga < 0,05 até o corte, CPI caindo nas
   últimas semanas, cpi_ultimas_4s < 0,85 ("cada R$ 1 gasto no último mês
   entregou R$ X"), spi_ultimas_4s < 0,85, falta de SRE em 2+ dos últimos 4
   status, change freeze em 2+, rotatividade (saídas em 12 semanas ou citada
   no status), escopo crescendo em 2+, consultoria atrasando em 2+, 2+
   incidentes em 8 semanas, ociosidade >= 25%, ruptura de capacidade.
   Sem sinal: "sem sinal de piora".
5. Grave lakehouse_vertice.gold.score_estouro_30d com EXATAMENTE as colunas
   projeto_id STRING, data_referencia DATE, prob_estouro_30d DOUBLE,
   ranking INT, faixa_risco STRING, principais_fatores STRING (overwrite).
   COMMENT na tabela e nas colunas: a noite 4 lê daqui.
6. Testes com assert: uma linha por projeto em andamento, prob entre 0 e 1,
   ranking único, nenhum motivo vazio.

Rode o job inteiro e me mostre o top 25:
  databricks bundle deploy --profile <perfil>
  databricks bundle run vertice_farol --profile <perfil>
```

---

## O que conferir

```sql
SELECT s.ranking, s.projeto_id, p.situacao, s.prob_estouro_30d, s.faixa_risco, s.principais_fatores
FROM lakehouse_vertice.gold.score_estouro_30d s
JOIN lakehouse_vertice.gold.projeto_situacao_atual p USING (projeto_id)
ORDER BY s.ranking LIMIT 25;
-- 1 a 17: os 17 projetos que a regra já vê (7 críticos + 10 em atenção), todos com 1,0
-- 18 · PRJ-013 · ok · 0,88 · alto  · pelo status semanal o índice já é 0,90: o cronograma da ferramenta diz 0,94; ...
-- 19 · PRJ-024 · ok · 0,49 · medio · a 0,01 do corte de 0,9 (índice 0,91); banco de horas ou crédito de cloud acaba em menos de 30 dias
-- 20 · PRJ-026 · ok · 0,34 · medio · a 0,00 do corte de 0,9 (índice 0,90); consultoria atrasando em 2 dos últimos 4 status
```

**O momento "uau":** a regra de corte diz que o **PRJ-024 está ok** (SPI 0,91,
CPI 0,97). O modelo dá **49% de chance de ele cruzar em 30 dias**, e diz por quê: está
colado no corte e o crédito de cloud acaba antes de dar tempo de aprovar mais. E o
PRJ-024 é o **marketplace de sellers**: o manual da Vértice diz que o change freeze
da Black Friday começa em **01/11**. O modelo não sabe disso; o agente da noite 4 vai saber.

E o **PRJ-013** mostra outra lição: 88% de chance com SPI 0,94 na planilha. O status
de sexta diz 43% concluído; a planilha soma 45%, porque uma tarefa foi digitada com
mais de 100% e a silver cortou em 100. O modelo aprendeu com o status, e o motivo
avisa que as duas fontes não batem. **Qualidade de dado é feature.**

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `InvalidVersion: '18.x-aarch64-photon-scala2'` | `mlflow.pyfunc.spark_udf` | `mlflow.sklearn.load_model` + pandas |
| `RESOURCE_DOES_NOT_EXIST ... @prod` | o alias não foi criado | rode o `ml_modelo` de novo |
| 60 linhas em vez de 41 | faltou filtrar `status = 'em_andamento'` | join com `gold.projeto_situacao_atual` |
| projeto "atenção" no dashboard com prob abaixo de 1,0 | usou o índice do status semanal para o "já abaixo" | a régua é a fotografia de hoje (`projeto_situacao_atual`) |
| a noite 4 não acha a coluna | nome ou tipo mudou | o contrato acima é fixo: `CAST` explícito na escrita |

**Tempo medido:** ~45 s de notebook. Job completo com as 9 tarefas: **4 a 5 min** (medido em 18/10).
