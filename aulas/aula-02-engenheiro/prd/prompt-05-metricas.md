# Prompt 5 · Métricas governadas — o KPI definido uma vez só

**Entrega:** uma metric view no Unity Catalog, `mv_projetos`, com os KPIs da Torre,
e a tarefa `metricas_governadas` fechando o job. **Deploy nº 5.**

---

## O que mostrar antes

O problema que a metric view resolve, em uma imagem: a mesma pergunta, três respostas.

```
SQL da noite 1 ...... CPI do PRJ-009 = 0,77   (EV / AC, com CASE e replace)
Genie da noite 1 .... CPI do PRJ-009 = 1,9    (inventou: valor do contrato ÷ custo)
Planilha do PMO ..... CPI do PRJ-009 = ?      (cada gerente calcula de um jeito)
```

*"Quando o dono recebe três números, ele não confia em nenhum. A fórmula do CPI
precisa morar num lugar só."*

**Enquanto ele trabalha, você explica:**

- **Metric view guarda a FÓRMULA, não o número.** `MEASURE(cpi)` no dashboard, no
  Genie e no SQL é sempre `SUM(ev) / SUM(ac)` — recalculado no grão que a pergunta
  pedir (projeto, cliente, segmento, ferramenta, carteira).
- **Razão não se soma.** O CPI da carteira não é a média dos CPIs dos projetos: é
  ΣEV ÷ ΣAC. A metric view faz isso certo sozinha, porque a medida é a fórmula.
- **`comment` e `synonyms` são para o Genie.** "índice de custo" e "desempenho de
  custo" passam a significar CPI; "farol mentiroso" passa a significar melancia.
- **Uma só, de propósito.** É a que o dashboard, o Genie e o app usam para os números
  da diretoria. Evolução, pessoas e fornecedores o Genie responde direto nas tabelas.
- **Armadilha medida:** o YAML da metric view precisa da indentação intacta. Pelo
  `aitools tools query` ela falha; como `sql_task` (ou `scripts/run_sql.py`) funciona.

---

## O prompt

```
Continue o bundle em aulas/aula-02-engenheiro/meu-vertice/. Agora os KPIs
governados, numa metric view do Unity Catalog. Uma só.

Crie src/metricas/metricas.sql (sql_task) com CREATE OR REPLACE VIEW
lakehouse_vertice.gold.mv_projetos WITH METRICS LANGUAGE YAML AS $$ ... $$
(version 1.1), comment em toda dimensão e medida que não for óbvia, e
synonyms em português.
- source: lakehouse_vertice.gold.projeto_situacao_atual, com
  filter status = 'em_andamento'.
- Dimensões: projeto_id, projeto, cliente, segmento, ferramenta, situacao,
  farol_do_gerente, farol_calculado, gerente_projeto.
- Medidas: projetos, carteira (SUM valor_contrato), spi (SUM(ev)/SUM(pv)),
  cpi (SUM(ev)/SUM(ac)), eac, estouro_previsto, margem_projetada
  ((SUM(valor_contrato) - SUM(eac)) / SUM(valor_contrato)),
  atraso_projetado_medio_dias, projetos_em_risco, projetos_criticos,
  projetos_melancia (COUNT FILTER WHERE melancia).

ARMADILHAS MEDIDAS: o YAML precisa da indentação intacta (teste com
python3 scripts/run_sql.py <arquivo> --profile <perfil>), e NUNCA use ';'
dentro do YAML, nem num comment: a sql_task do job corta o arquivo em todo ';'.

Acrescente ao job a tarefa metricas_governadas, depois de
testes_de_qualidade E status_com_ia.

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run vertice_farol --profile <perfil>
```

---

## O que conferir

```sql
SELECT MEASURE(spi) AS spi, MEASURE(cpi) AS cpi, MEASURE(estouro_previsto) AS estouro,
       MEASURE(projetos_criticos) AS criticos, MEASURE(projetos_melancia) AS melancias
FROM lakehouse_vertice.gold.mv_projetos;
-- 0,92 · 0,97 · R$ 6,47 mi · 7 · 4

-- o mesmo KPI, em outro grão, sem reescrever fórmula nenhuma
SELECT ferramenta, MEASURE(spi) AS spi, MEASURE(projetos_em_risco) AS em_risco
FROM lakehouse_vertice.gold.mv_projetos GROUP BY ferramenta ORDER BY spi;
```

Abra o DAG do job: **cinco tarefas**, com `testes_de_qualidade` e `status_com_ia` em
paralelo no meio. É a tela da noite.

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `METRIC_VIEW_INVALID_VIEW_DEFINITION ... Missing required creator property 'expr'` | Rodou pelo `aitools tools query` | `sql_task` ou `scripts/run_sql.py` |
| A tarefa roda antes da IA | `depends_on` só com testes | Precisa depender das duas |
| `metricas_governadas` falha no job, mas roda pelo `run_sql.py` | Um `;` dentro do YAML (num comment) | A `sql_task` corta o arquivo em todo `;`: troque por vírgula |

**Tempo medido:** ~10 s para a metric view. Job completo do zero: ~5 min.
