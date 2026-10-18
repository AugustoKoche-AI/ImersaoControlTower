# Prompt 3 · Gold — o produto de dados e as três perguntas

**Entrega:** a gold no mesmo pipeline (`fato_projeto_semana` + 7 tabelas de
consumo) e a tarefa `testes_de_qualidade`, que quebra o job se algo estiver
errado. **Deploy nº 3.**

---

## O que mostrar antes

A lógica da gold é de trás para frente. Escreva no quadro:

```
pergunta da diretoria → KPI → grão → tabela gold → silver que ela lê
"quais obras vão estourar?" → SPI, CPI, EAC → obra × semana → fato_projeto_semana
```

E o porquê de **semana**: o boletim de medição é semanal (toda sexta). Com uma
linha por obra e semana dá para ver a curva do SPI caindo — e é a curva que o
modelo da noite 3 vai aprender.

**Enquanto ele trabalha, você explica:**

- **PV, EV e AC são acumulados.** O EV da semana 40 é tudo que ficou pronto até a
  semana 40. Por isso nunca se soma EV de semanas diferentes da mesma obra — e
  é exatamente o tipo de erro que o Genie da noite 1 cometeu.
- **O EV sai do boletim, não do cronograma.** Para cada tarefa, quanto andou em
  cada medição (o `lag()`), vezes o valor planejado. Somado e acumulado por obra.
- **Ruptura prevista é uma pergunta de tempo.** Não é "saldo baixo"; é "o saldo
  acaba antes de o próximo caminhão chegar?". E se a promessa do fornecedor já
  venceu e o material não veio, ela não vale mais: conta o lead time de um
  pedido novo.
- **Teste que quebra o job.** `raise_error()` dentro de `CASE WHEN`. Melhor o
  dashboard ficar com o dado de ontem do que com o dado errado de hoje.

---

## O prompt

```
Continue o bundle em aulas/aula-02-engenheiro/meu-atlas/. A silver está pronta.
Agora a gold, no MESMO pipeline atlas_medalhao: acrescente o glob
../src/gold/** em libraries. Os arquivos da gold escrevem com o nome completo
lakehouse_atlas.gold.<tabela>; leem a silver pelo nome curto. COMMENT em todas.
O "hoje" é DATE'2026-10-16'. Nunca current_date().

src/gold/01-fato-projeto-semana.sql → lakehouse_atlas.gold.fato_projeto_semana
Uma linha por obra e semana (sexta-feira), da semana do início da obra até
2026-10-16 (sequence(..., INTERVAL 1 WEEK) + explode). Colunas:
- pv: Σ valor_planejado × fração do baseline decorrida até a semana
  (greatest(0, least(1, datediff(semana, inicio)/datediff(fim, inicio))))
- ev: acumulado do avanço medido. Para cada tarefa, delta = pct - lag(pct)
  por data_medicao; ev_semana = Σ valor_planejado × delta / 100; depois soma
  acumulada por obra.
  ARMADILHA MEDIDA: o pipeline recusa função de janela dentro de agregação
  ("It is not allowed to use a window function inside an aggregate
  function"). Faça o lag() num CTE e o SUM no CTE seguinte.
- ac: custo real acumulado (silver.custos por semana, soma acumulada)
- spi = ev/pv, cpi = ev/ac (try_divide, 4 casas), eac = orcamento / cpi
- horas_disponiveis, horas_apontadas e horas_ociosas da semana (apontamentos)
- rupturas_previstas: para cada saldo semanal de estoque, a próxima entrega
  PROMETIDA ainda em aberto naquela data (pedido feito até a data e não
  entregue até a data). Ruptura = consumo_previsto_dia > 0 e
  saldo/consumo < dias até essa entrega; se a promessa já venceu, use o
  lead_time_contratado_dias do material.
- EXPECT pv >= 0 e ev <= orcamento, FAIL UPDATE.

src/gold/02-dim-e-marts.sql
- dim_projeto: obra (projeto_id · nome), cliente, setor, uf, contrato,
  orçamento, datas, duracao_baseline_dias, status, gerente.
- obra_situacao_atual: a fotografia de 2026-10-16 de cada obra (40 linhas):
  pv, ev, ac, spi, cpi, eac, estouro_previsto = greatest(eac - orcamento, 0),
  margem_projetada, atraso_projetado_dias, termino_projetado,
  rupturas_previstas e situacao: 'concluída' se status <> em_andamento;
  'crítico' se SPI ou CPI < 0,8; 'atenção' se < 0,9; senão 'ok'.
- utilizacao_equipe_semana: equipe × semana com horas disponíveis,
  apontadas, ociosas, utilizacao e o spi_da_obra naquela semana.
- utilizacao_equipamento_semana: equipamento × semana com tipo, modelo, obra,
  uf, utilizacao, horas_paradas e custo_ocioso (horas paradas × custo_hora).
- desempenho_fornecedor: por fornecedor normalizado: pedidos, grafias_no_erp,
  lead time prometido e real médios, fator_atraso (real/prometido),
  pct_no_prazo, pedidos_em_atraso, valor_comprado.
- cobertura_estoque: material × obra em andamento HOJE: saldo, consumo,
  cobertura_dias, próxima entrega prometida e fornecedor, dias_ate_reposicao
  e ruptura_prevista (mesma regra do fato).
- pedidos_em_atraso: pedidos em aberto com data prometida antes de hoje.

src/testes/testes.sql (sql_task) — cada teste com raise_error se falhar:
 1 uma linha por equipe na silver
 2 a Norte Aço virou um fornecedor só
 3 a limpeza não mudou o custo total (bronze com replace = silver)
 4 nenhuma tarefa acima de 100%
 5 as 40 obras têm fotografia de hoje
 6 toda obra em andamento tem SPI e CPI
 7 EV de hoje no fato = Σ valor_planejado × pct da silver.tarefas
 8 AC de hoje no fato = soma dos lançamentos até hoje

Acrescente ao job a tarefa testes_de_qualidade, depois de medalhao.

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run atlas_torre --profile <perfil>
```

---

## O que conferir

```sql
SELECT situacao, COUNT(*) AS obras, ROUND(SUM(estouro_previsto) / 1e6, 2) AS estouro_mi
FROM lakehouse_atlas.gold.obra_situacao_atual GROUP BY situacao;
-- crítico 7 · atenção 6 · ok 23 · concluída 4

SELECT ROUND(SUM(estouro_previsto) / 1e6, 2) FROM lakehouse_atlas.gold.obra_situacao_atual
WHERE status = 'em_andamento';
-- 42,36. A noite 1 dava 41,9.
```

**Por que o estouro subiu meio milhão?** Na noite 1 cortamos as 52 tarefas de
117% em 100% (`LEAST`). A medição real mostra que várias delas **não estavam
concluídas**: o EV era menor, o CPI pior e o estouro maior. O atalho escondia
R$ 0,46 mi. *Esse é o custo de limpar com valor plausível em vez de valor certo.*

```sql
-- a pergunta 3: o fornecedor que promete e não cumpre
SELECT fornecedor, grafias_no_erp, fator_atraso, pct_no_prazo, pedidos_em_atraso
FROM lakehouse_atlas.gold.desempenho_fornecedor ORDER BY fator_atraso DESC LIMIT 3;
-- Metalúrgica Norte Aço Ltda · 4 grafias · 1,41 · 0% no prazo · 17 em atraso
```

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `window function inside an aggregate function` | `SUM(... lag() ...)` no mesmo SELECT | CTE com o `lag()`, depois o `SUM` |
| `Failed to read dataset ... could not be resolved` | Erro numa tabela anterior do grafo | Leia o primeiro ERROR do evento, não o último |
| Teste 3 falha | Alguma linha de custo foi descartada | Estorno e vírgula ficam; só se converte |
| Teste 7 falha | O EV acumulado somou semanas erradas | O `lag()` tem que ser por tarefa, ordenado por data_medicao |
| 41 linhas em obra_situacao_atual | Join duplicando | `obra_situacao_atual` lê o fato filtrado em `semana = DATE'2026-10-16'` |

**Tempo medido:** pipeline com silver + gold ~2 min 30 s; job completo até os
testes ~3 min 30 s.
