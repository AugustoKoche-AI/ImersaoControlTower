# 🧩 Noite 2 sem código — a mesma Torre, pela interface

Para quem é de gestão, PMO, financeiro ou suprimentos e não quer abrir um
terminal. Você chega no **mesmo resultado** da trilha com Claude Code: silver
limpa, gold com SPI e CPI, causa do atraso tirada do RDO, KPIs governados,
dashboard e Genie. A diferença: o que é clicado não fica no Git (não tem diff,
revisão nem rollback). É o argumento de por que engenharia existe.

Tudo pelo navegador, no seu workspace Free Edition, sobre a bronze da noite 1.

---

## 1. A limpeza com o Lakeflow Designer (≈ 15 min)

**Jobs & Pipelines → Create → ETL pipeline → Lakeflow Designer** (no menu
lateral aparece também como *Visual Data Prep*).

1. **Source:** `lakehouse_atlas.bronze.custos`.
2. **Transform → Formula:** nova coluna `valor` com
   `CAST(replace(valor_real, ',', '.') AS DECIMAL(18,2))`.
   Repare: sem o `replace`, 540 linhas viram nulo.
3. **Transform → Formula:** `estorno` = `valor < 0`. Não filtre: estorno é informação.
4. **Destination:** `lakehouse_atlas.silver.custos` → **Run**.
5. Repita para `compras` com a fórmula do fornecedor:
   `CASE WHEN lower(fornecedor) LIKE '%norte a%' THEN 'Metalúrgica Norte Aço Ltda' ELSE fornecedor END`.

> O Designer gera SQL por trás. Clique em **View code**: é o mesmo
> `src/silver/03-custos.sql` do gabarito.

**Atalho:** se o Designer não aparecer no seu workspace, use o **SQL Editor**
com o **Genie Code** (o assistente do editor): escreva *"crie a silver de custos
convertendo a vírgula decimal e marcando estorno"* e revise o SQL antes de rodar.

## 2. O SPI e o CPI com o Genie Code (≈ 10 min)

**SQL Editor → nova query → ícone do assistente (Genie Code)**:

```
Usando lakehouse_atlas.silver.tarefas e lakehouse_atlas.silver.custos,
calcule por projeto o PV (valor planejado decorrido até 2026-10-16), o EV
(valor_planejado × pct_concluido / 100) e o AC (soma de valor). Depois SPI = EV/PV
e CPI = EV/AC. Explique cada passo.
```

Leia a explicação, rode, e compare com a tabela do gabarito
`lakehouse_atlas.gold.obra_situacao_atual`. **Peça para ele explicar o SQL antes
de rodar.** Nunca rode o que você não entendeu.

## 3. A causa do atraso com IA, numa query (≈ 5 min)

```sql
SELECT data, texto_livre,
       ai_classify(texto_livre, array('chuva','falta_material','falta_equipamento',
                                      'mao_de_obra','retrabalho','cliente','sem_ocorrencia')) AS causa
FROM lakehouse_atlas.silver.rdo
WHERE projeto_id = 'P011' AND data >= DATE'2026-09-01'
ORDER BY data DESC;
```

Conte quantas vezes aparece `falta_equipamento`. Essa é a resposta que o Genie
da noite 1 não deu.

## 4. Um KPI governado pela interface (≈ 10 min)

**Catalog → lakehouse_atlas → gold → Create → Metric view**:

- Source: `lakehouse_atlas.gold.obra_situacao_atual`, filtro `status = 'em_andamento'`
- Dimensões: `obra`, `uf`, `situacao`
- Medidas: `spi` = `SUM(ev) / SUM(pv)` · `cpi` = `SUM(ev) / SUM(ac)` ·
  `estouro_previsto` = `SUM(estouro_previsto)`
- Em cada medida, preencha **Comment** e **Synonyms** ("índice de custo" → cpi):
  é o que o Genie lê.

## 5. O dashboard e o Genie (≈ 15 min)

- **Dashboards → Create dashboard → Data → Add data source** → escolha a metric
  view do passo 4. Arraste: contador de `estouro_previsto`, barra de
  `estouro_previsto` por `obra`, cor por `situacao`.
- **Genie Agents → New** → adicione a metric view, `gold.rdo_estruturado` e
  `gold.utilizacao_equipamento_semana`. Em **Instructions**, escreva:
  *"Hoje é 16/10/2026. SPI e CPI abaixo de 0,9 é atenção, abaixo de 0,8 é crítico.
  Para 'por que a obra atrasou', conte as causas do rdo_estruturado dos últimos 90 dias."*
- Pergunte: **"Por que a obra P011 atrasou?"** e **"Onde tenho guindaste parado?"**

## O que você acabou de provar

| Trilha | O que fica | Quanto tempo para refazer amanhã |
|---|---|---|
| Sem código | tabelas, dashboard e Genie no workspace | refazer cada clique |
| Com código (Claude Code) | tudo isso **e** o projeto no Git | `databricks bundle deploy` (8 s) |

As duas chegam no mesmo número. Só uma roda sozinha às 6h da manhã.
