# Prompt 2 · Métricas e Genie: o dono pergunta em português

**Entrega:** a metric view `gold.mv_projetos` (a fórmula de cada KPI num lugar só, tarefa
`metricas_governadas` no job) e o Genie Agent **"Farol · Diretoria"** como recurso do bundle, lendo a
gold, a metric view e o score do prompt 1. Testado com um benchmark de 20 perguntas. **Deploy nº 2.**

> Na segunda, o Genie da noite 1 errou as quatro perguntas do dono ("nenhum atraso custa nada"). O
> modelo de IA dele é o mesmo de hoje. Mudou tudo que está embaixo: o dado integrado e testado, a
> fórmula escrita uma vez, o score e as instruções de negócio.

---

## O que mostrar antes (3 min)

O problema que a metric view resolve, em uma imagem: a mesma pergunta, três respostas.

```
SQL da noite 1 ...... CPI do PRJ-009 = 0,77   (EV / AC, com CASE e replace)
Genie da noite 1 .... CPI do PRJ-009 = 1,9    (inventou: valor do contrato ÷ custo)
Planilha do PMO ..... CPI do PRJ-009 = ?      (cada gerente calcula de um jeito)
```

*"Quando o dono recebe três números, ele não confia em nenhum. A fórmula do CPI precisa morar num
lugar só."*

Depois, abra o Genie da noite 1 ("Farol · Noite 1 (bronze, sem curadoria)") e faça as perguntas que ele errou:

```
"Quanto esse atraso vai me custar?"                      → noite 1: "nenhum atraso tem impacto financeiro"
"Tenho gente parada enquanto outro projeto pede gente?"  → noite 1: "não há colaboradores parados"
```

**Enquanto ele trabalha, você explica:**

- **Metric view guarda a FÓRMULA, não o número.** `MEASURE(cpi)` no Genie, no SQL e no app é sempre
  `SUM(ev) / SUM(ac)`, recalculado no grão que a pergunta pedir (projeto, cliente, segmento,
  ferramenta, carteira). Razão não se soma: o CPI da carteira é ΣEV ÷ ΣAC, não a média dos CPIs.
- **`comment` e `synonyms` são para o Genie.** "índice de custo" e "desempenho de custo" passam a
  significar CPI; "farol mentiroso" passa a significar melancia.
- **Genie como código.** As instruções de negócio (o "hoje" do dataset, as regras de corte, onde achar a
  causa do atraso, o que é "próximo mês") viram arquivo versionado, com diff e revisão.
- **A pergunta 4 agora tem resposta completa.** "O que vai dar errado no próximo mês" junta três
  fontes: o **score** (os projetos "ok" com risco alto ou médio, com o motivo), as entregas de
  consultoria atrasadas e o change freeze da Black Friday nos e-commerces. O PRJ-024 aparece duas
  vezes: 46% no modelo **e** no freeze. É o que o modelo sozinho não via.
- **Benchmark é teste de IA.** 20 perguntas com a resposta certa em SQL. O script roda cada uma no
  Genie e compara. Mudou a instrução? Roda o benchmark. É o mesmo raciocínio do teste da gold.
- **Ordem que importa:** o Genie só é criado se as tabelas já existem (a metric view nasce no job).
  Do zero: deploy → run → deploy.

---

## O prompt

```
Continue o bundle vertice na raiz deste repositório. O modelo e o score
estão prontos. Agora a fórmula de cada KPI num lugar só, e o Genie que o
dono vai usar.

1. Métricas governadas: src/metricas/metricas.sql (sql_task)
   CREATE OR REPLACE VIEW lakehouse_vertice.gold.mv_projetos WITH METRICS
   LANGUAGE YAML AS $$ ... $$ (version 1.1), comment em toda dimensão e
   medida que não for óbvia, e synonyms em português.
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

2. Genie Agent como código
   - scripts/gerar_genie.py gera resources/farol.geniespace.json
     (serialized_space versão 2; ids de 32 caracteres hex, únicos e em ordem):
     tabelas gold.fato_projeto_semana, gold.projeto_situacao_atual,
     gold.status_estruturado, gold.utilizacao_pessoa_semana,
     gold.score_estouro_30d e silver.entregas_fornecedor, e a metric view
     gold.mv_projetos; as 4 perguntas do dono como perguntas de exemplo.
   - Instruções de texto: quem pergunta (o dono e a diretoria); HOJE =
     2026-10-16 e o que é "últimos 90 dias / 12 semanas / próximo mês"; as
     fórmulas e as regras de corte; mv_projetos para totais de hoje e
     projeto_situacao_atual para ranking; PV/EV/AC acumulados no fato (nunca
     somar semanas); farol e melancia; "por que o projeto X atrasou" responde
     com status_estruturado dos últimos 90 dias (sem sem_bloqueio e
     nao_reportado), mais o SPI e SREs ociosos se a causa for falta_sre;
     gente parada = utilização < 20% em 12 semanas; fornecedor = prazo real ÷
     prometido na silver.entregas_fornecedor; "o que vai dar errado no
     próximo mês" junta o score (projetos com situacao = 'ok' e faixa alto ou
     medio, com principais_fatores), as entregas de consultoria em atraso e o
     change freeze de varejo (01/11/2026 a 10/01/2027) nos projetos de
     e-commerce; probabilidade de estouro sai da score_estouro_30d na
     data_referencia mais recente; "quais clientes" devolve cada cliente
     uma vez.
   - Um exemplo de SQL para cada uma das 4 perguntas do dono, e um para
     "qual a chance de o PRJ-024 estourar no próximo mês?".
   - resources/genie.genie_space.yml: recurso genie_farol, título
     "Farol · Diretoria", warehouse ${var.warehouse_id}.

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run vertice_farol --only metricas_governadas --profile <perfil>
  databricks bundle deploy --profile <perfil>
  databricks bundle summary --profile <perfil>
  python3 scripts/genie.py perguntar "Farol · Diretoria" "O que vai dar errado no próximo mês, e o que eu faço agora?" --profile <perfil>
  python3 scripts/genie.py benchmark "Farol · Diretoria" aulas/aula-04-produtos-de-dados-ia/prd/genie-benchmark-diretoria.json --profile <perfil>
Se o benchmark der menos de 16/20, mostre os erros e ajuste a INSTRUÇÃO
(não a pergunta), gere o JSON, faça deploy e rode de novo.
```

> **O `genie.py` e o benchmark** vêm do repositório do curso: o passo 0 do
> [README](../README.md#0-antes-de-começar-5-min) baixa os dois para o seu repositório.

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

As quatro perguntas do dono, no Genie:

1. *atrasados e de quais clientes* → 17 projetos, com SPI e CPI;
2. *quanto custa* → **R$ 6,47 mi** de estouro previsto, margem projetada de 20%;
3. *gente parada* → as duas SREs do PRJ-007 a ~5% de utilização, e o PRJ-011 pedindo SRE no status;
4. *o que vai dar errado no próximo mês* → os projetos "ok" com risco alto ou médio no modelo (entre
   eles o **PRJ-024, 46%**), as 5 entregas atrasadas da CodeForge e o freeze de 01/11 nos e-commerces.

O benchmark de 20 perguntas: **20/20** no ensaio de 18/10, sem o score. Com o score nas tabelas e a
instrução nova da pergunta 4: *a medir no ensaio*.

> *"Na segunda ele disse que o atraso não custava nada. Hoje ele diz quanto custa, quem está parado,
> qual projeto vai estourar no mês que vem e por quê. O modelo de IA é o mesmo. A diferença foi tudo
> que a gente construiu nas três noites."*

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `METRIC_VIEW_INVALID_VIEW_DEFINITION ... Missing required creator property 'expr'` | Rodou pelo `aitools tools query` | `sql_task` ou `scripts/run_sql.py` |
| `metricas_governadas` falha no job, mas roda pelo `run_sql.py` | Um `;` dentro do YAML (num comment) | A `sql_task` corta o arquivo em todo `;`: troque por vírgula |
| `Table 'lakehouse_vertice.gold.x' does not exist` no deploy | O Genie foi criado antes de a tabela existir | `bundle run vertice_farol` e deploy de novo |
| `Duplicate question ID` | ids não únicos no JSON do Genie | ids de 32 caracteres com prefixo diferente por tipo |
| `must be sorted by id` | lista fora de ordem | ordene por id; tabelas por identifier |
| `modified remotely` no deploy | o Genie foi editado no workspace | leve a mudança para o `gerar_genie.py` e use `--force` só depois disso |
| "O que vai dar errado" volta FAILED | pergunta aberta, três fontes | o exemplo de SQL com `UNION ALL` (score, entregas, freeze) resolve |
| O Genie diz que o PRJ-016 tem "100% de chance" como novidade | não filtrou os que já estão abaixo do corte | instrução: no futuro, interessa `situacao = 'ok'` com faixa alto ou medio |

**Tempo medido:** metric view ~10 s; deploy ~10 s; benchmark de 20 perguntas ~6 min (18/10).
