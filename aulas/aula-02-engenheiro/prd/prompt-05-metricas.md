# Prompt 5 · Métricas governadas — o KPI definido uma vez só

**Entrega:** 5 metric views no Unity Catalog com os 12 KPIs da Torre, e a tarefa
`metricas_governadas` fechando o job. **Deploy nº 5.**

---

## O que mostrar antes

O problema que a metric view resolve, em uma imagem: a mesma pergunta, três
respostas.

```
SQL da noite 1 ...... CPI da P018 = 0,79   (EV / AC, com CAST e replace)
Genie da noite 1 .... CPI da P018 = 3,26   (inventou a fórmula, multiplicou o JOIN)
Planilha do PMO ..... CPI da P018 = ?      (cada gerente calcula de um jeito)
```

*"Quando a diretoria recebe três números, ela não confia em nenhum. A fórmula do
CPI precisa morar num lugar só."*

**Enquanto ele trabalha, você explica:**

- **Metric view guarda a FÓRMULA, não o número.** `MEASURE(cpi)` no dashboard, no
  Genie e no SQL é sempre `SUM(ev) / SUM(ac)` — recalculado no grão que a
  pergunta pedir (obra, UF, setor, carteira).
- **Razão não se soma.** O CPI da carteira não é a média dos CPIs das obras: é
  ΣEV ÷ ΣAC. A metric view faz isso certo sozinha, porque a medida é a fórmula.
- **`comment` e `synonyms` são para o Genie.** "índice de custo" e "desempenho de
  custo" passam a significar CPI.
- **Armadilha medida:** o YAML da metric view precisa da indentação intacta. Pelo
  `aitools tools query` ela falha; como `sql_task` (ou `scripts/run_sql.py`) funciona.

---

## O prompt

```
Continue o bundle em aulas/aula-02-engenheiro/meu-atlas/. Agora os KPIs
governados, como metric views do Unity Catalog.

Crie src/metricas/metricas.sql (sql_task) com CREATE OR REPLACE VIEW ...
WITH METRICS LANGUAGE YAML AS $$ ... $$, version 1.1, comment e synonyms em
português nas medidas principais:

1. lakehouse_atlas.gold.mv_obras — source gold.obra_situacao_atual,
   filter status = 'em_andamento'.
   Dimensões: projeto_id, obra, cliente, setor, uf, situacao, gerente_projeto.
   Medidas: obras, carteira, spi = SUM(ev)/SUM(pv), cpi = SUM(ev)/SUM(ac),
   eac, estouro_previsto, margem_projetada =
   (SUM(valor_contrato) - SUM(eac)) / SUM(valor_contrato),
   atraso_projetado_medio_dias, obras_em_risco (situação atenção ou crítico),
   obras_criticas.
2. lakehouse_atlas.gold.mv_evolucao — source gold.fato_projeto_semana com
   join em gold.dim_projeto (using projeto_id). Dimensões semana, mes, obra,
   uf, setor. Medidas spi, cpi, utilizacao_equipe, horas_ociosas,
   rupturas_previstas. Comente que PV/EV/AC são acumulados.
3. lakehouse_atlas.gold.mv_equipamentos — source
   gold.utilizacao_equipamento_semana: utilizacao_equipamento, horas_paradas,
   custo_ocioso por tipo, modelo, obra, uf, semana.
4. lakehouse_atlas.gold.mv_suprimentos — source gold.cobertura_estoque:
   rupturas_previstas, cobertura_media_dias, itens_monitorados.
5. lakehouse_atlas.gold.mv_fornecedores — source silver.compras com join em
   gold.dim_projeto: pedidos, pedidos_em_atraso, lead_time_real_medio_dias,
   fator_atraso_fornecedor (real / prometido).

No fim do arquivo, um SELECT com MEASURE() das medidas de mv_obras, para a
saída da tarefa provar que as views respondem.

ARMADILHA MEDIDA: rodar metric view pelo `databricks experimental aitools
tools query` achata a indentação do YAML e dá
METRIC_VIEW_INVALID_VIEW_DEFINITION. Rode como sql_task do job ou com
python3 scripts/run_sql.py <arquivo> --profile <perfil>.

Acrescente ao job a tarefa metricas_governadas, depois de
testes_de_qualidade E de rdo_com_ia.

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run atlas_torre --profile <perfil>
```

---

## O que conferir

```sql
SELECT MEASURE(spi) AS spi, MEASURE(cpi) AS cpi, MEASURE(estouro_previsto) AS estouro,
       MEASURE(obras_criticas) AS criticas
FROM lakehouse_atlas.gold.mv_obras;
-- 0,95 · 0,94 · R$ 42,36 mi · 7

-- o mesmo KPI, em outro grão, sem reescrever fórmula nenhuma
SELECT uf, MEASURE(cpi) AS cpi, MEASURE(obras_em_risco) AS em_risco
FROM lakehouse_atlas.gold.mv_obras GROUP BY uf ORDER BY cpi;
```

Abra o DAG do job: **cinco tarefas**, com o paralelismo de `testes` e
`rdo_com_ia` no meio. É a tela da noite.

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `METRIC_VIEW_INVALID_VIEW_DEFINITION ... Missing required creator property 'expr'` | Rodou pelo `aitools tools query` | `sql_task` ou `scripts/run_sql.py` |
| `Failed to parse YAML` em `on:` | YAML 1.1 lê `on` como booleano | Use `using: [projeto_id]` no join |
| `UNRESOLVED_COLUMN` numa dimensão de join | Faltou o prefixo do join | `dim_obra.uf`, não `uf` |
| A tarefa roda antes do RDO | `depends_on` só com testes | Precisa depender das duas |

**Tempo medido:** ~20 s para as 5 metric views. Job completo do zero: **5 min 40 s**.
