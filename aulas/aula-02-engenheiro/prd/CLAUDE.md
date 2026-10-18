# Torre de Controle · Atlas Engenharia — contexto da noite 2

Projeto técnico da Imersão Jornada de Dados (**19 a 22 de outubro de 2026**, 19h30,
ao vivo no YouTube). Este arquivo é o contexto do projeto: **leia antes de escrever
qualquer código**. Ele vale para os seis prompts da noite 2.

---

## 1. O negócio

A **Construtora Atlas Engenharia** é uma EPC de médio porte: 40 obras industriais
(plantas de beneficiamento, terminais, usinas de etanol) para clientes de
mineração, óleo e gás e agro, R$ 903 mi de carteira. O controle está espalhado em
ERP, cronograma, ponto, frota, almoxarifado e RDO (relatório diário de obra) em
texto livre. A diretoria só descobre que uma obra estourou quando já estourou.

A Torre de Controle responde **três perguntas**:

1. **Quais obras vão estourar prazo ou orçamento?** (SPI, CPI, EAC)
2. **Onde tenho gente e equipamento parado enquanto outra obra está atrasada?**
3. **Que material vai faltar antes de travar uma frente de serviço?**

Regras de corte: SPI ou CPI **< 0,9 = atenção**, **< 0,8 = crítico**.

| KPI | Fórmula |
|---|---|
| SPI | EV ÷ PV (valor agregado ÷ valor planejado). < 1 é atraso |
| CPI | EV ÷ AC (valor agregado ÷ custo real). < 1 é estouro |
| EAC | orçamento ÷ CPI |
| Estouro previsto | EAC − orçamento, só quando positivo |
| Margem projetada | (valor do contrato − EAC) ÷ valor do contrato |
| Atraso projetado (dias) | duração baseline ÷ SPI − duração baseline |
| Ruptura prevista | cobertura (saldo ÷ consumo diário previsto) < dias até a próxima entrega prometida. Se a promessa já venceu, vale o lead time contratado |

**O "hoje" do dataset é 16/10/2026 (sexta).** Nunca use `current_date()`: o número
mudaria todo dia e não bateria com o de ninguém. Escreva `DATE'2026-10-16'`.

---

## 2. Onde está o dado

Catálogo **`lakehouse_atlas`**, criado na noite 1 (pela UI ou por
`aulas/aula-01-analista/00-setup-catalogo.sql`). Schemas `bronze`, `silver`, `gold`
e o volume `bronze.raw` já existem. **A bronze já está carregada** (12 tabelas, tudo
como texto, com a sujeira) e é a ÚNICA entrada da noite 2. Nunca altere a bronze.

| Tabela bronze | Linhas | O que é |
|---|---|---|
| `projetos` | 40 | contrato de cada obra: cliente, setor, UF, valor, orçamento, datas, status |
| `tarefas` | 8.000 | cronograma: baseline, realizado, % concluído, valor planejado |
| `avanco_semanal` | 55.703 | boletim de medição: % de cada tarefa por sexta-feira (só quando muda) |
| `custos` | 19.445 | lançamentos de custo real por categoria |
| `compras` | 13.304 | pedidos: data prometida × data de entrega, lead time |
| `materiais` | 25 | cadastro de material com lead time contratado |
| `estoque` | 40.094 | saldo semanal por obra e material + consumo diário previsto |
| `equipes` | 123 | equipes de campo (com 3 duplicadas) |
| `apontamentos` | 41.190 | horas disponíveis × apontadas por equipe e dia |
| `equipamentos` | 300 | frota e obra atual |
| `uso_equipamentos` | 19.817 | horas operadas por equipamento e semana |
| `rdo` | 13.730 | relatório diário de obra em texto livre |

## 3. A sujeira é proposital — a limpeza é o conteúdo da noite

| # | Sujeira | Onde | Decisão certa |
|---|---|---|---|
| 1 | Data em `yyyy-MM-dd` e `dd/MM/yyyy` | `projetos.data_inicio` (11 de 40) | `coalesce(try_to_date(x,'yyyy-MM-dd'), try_to_date(x,'dd/MM/yyyy'))` |
| 2 | UF `MG`, `mg`, ` MG ` | `projetos.uf` | `upper(trim())` |
| 3 | % concluído acima de 100 (até 117%) | `tarefas.pct_concluido` (52) | **usar a última medição de `avanco_semanal`**, não cortar em 100 |
| 4 | Vírgula decimal `12345,67` | `custos.valor_real` (540) | `replace(',', '.')` antes do CAST. `try_cast` jogaria R$ 16,8 mi fora em silêncio |
| 5 | Estorno como valor negativo | `custos` | **manter** (custo é líquido) e sinalizar `estorno` |
| 6 | Mesmo fornecedor com 4 grafias | `compras.fornecedor` | normalizar para `Metalúrgica Norte Aço Ltda` |
| 7 | Equipe cadastrada duas vezes | `equipes` (EQP014, EQP057, EQP101) | manter o cadastro com `funcao` em minúsculas |
| 8 | Saldo de estoque negativo | `estoque.saldo` (~0,2%) | vira 0 e ganha flag |
| 9 | RDO vazio (`''`, `N/A`, `ver RDO físico`) | `rdo.texto_livre` (82) | **não descartar**: flag `rdo_vazio` |
| 10 | RDO em CAIXA ALTA | `rdo.texto_livre` | `lower()` para a regra de palavra-chave |

**O teste de uma boa limpeza:** o custo total não muda (R$ 572,85 mi na bronze
com `replace` = R$ 572,85 mi na silver).

## 4. Arquitetura da noite 2

```
bronze (noite 1)
   │
   ▼  job atlas_torre
conferencia_bronze ── medalhao (pipeline Lakeflow) ──┬── testes_de_qualidade ──┐
   sql_task            silver ×12  →  gold ×8       └── rdo_com_ia ───────────┴── metricas_governadas
                                                                                   (5 metric views)
   dashboard_portfolio (bundle) · genie_torre (bundle)
```

- **Um bundle só**, chamado `atlas`, em `aulas/aula-02-engenheiro/meu-atlas/`.
  A pasta `aulas/aula-02-engenheiro/atlas/` é o **gabarito**: não copie dela, a
  graça da noite é construir.
- **Silver e gold num pipeline declarativo** (Lakeflow Spark Declarative Pipelines,
  SQL, serverless). Silver = schema padrão do pipeline; gold = nome completo
  `lakehouse_atlas.gold.x`. Um arquivo por assunto em `src/silver/` e `src/gold/`.
  Qualidade com `CONSTRAINT ... EXPECT (...) ON VIOLATION FAIL UPDATE`.
- **RDO com IA, testes e métricas como `sql_task`** no warehouse, com o caminho
  completo das tabelas (`lakehouse_atlas.gold.x`).
- **Dashboard e Genie como recursos do bundle** (`resources/*.yml` + JSON).

## 5. Armadilhas medidas neste workspace (Free Edition, outubro/2026)

| Armadilha | O que fazer |
|---|---|
| `mode: development` prefixa nomes com `[dev usuario]` | Não use. No target `dev` use `presets: { trigger_pause_status: PAUSED }` |
| Função de janela dentro de agregação dá erro no pipeline | Calcule o `lag()` num CTE e agregue no CTE seguinte |
| `CREATE OR REPLACE` não existe no pipeline | Use `CREATE OR REFRESH MATERIALIZED VIEW` |
| Metric view falha com `METRIC_VIEW_INVALID_VIEW_DEFINITION` pelo `aitools tools query` | O YAML perde a indentação. Rode como `sql_task` ou com `python3 scripts/run_sql.py` (API de statements) |
| `ai_classify` faz ~3,7 RDOs por segundo | IA só nos RDOs **com ocorrência** dos **últimos 90 dias** (~1.000); regra para "sem ocorrência"; palavra-chave no histórico; `MERGE` incremental |
| Genie do bundle falha no deploy com `Table ... does not exist` | O Genie precisa das tabelas existindo. Do zero: deploy → run → deploy |
| Apagar o pipeline **não** apaga as materialized views | O `prd/00-reset.sh` apaga silver e gold uma a uma |
| `databricks fs` em Volume | Exige o prefixo `dbfs:` (`dbfs:/Volumes/...`) |

## 6. Convenções

- snake_case e português, como na bronze. Caminho completo nas `sql_task`.
- `COMMENT` em toda tabela da silver e da gold: é o que o Genie lê.
- Comentário pensando em quem assiste ao vivo pela primeira vez. SQL legível > SQL esperto.
- Sempre `--profile <perfil>` nos comandos `databricks`. Nunca deixe implícito.
- Warehouse: descubra com `databricks warehouses list --profile <perfil>` (o Free Edition tem um, o Serverless Starter Warehouse).

## 7. Números que servem como teste (seed 42)

| O que | Valor |
|---|---|
| Obras em andamento | 36 (4 concluídas) |
| Obras críticas / em atenção | **7 / 6** |
| Estouro previsto (em andamento) | **R$ 42,36 mi** (a noite 1, com o atalho do `LEAST(pct,100)`, dava R$ 41,9 mi) |
| SPI / CPI da carteira | 0,95 / 0,94 |
| Custo real total | R$ 572,85 mi |
| Rupturas previstas hoje | 97 de 851 itens monitorados |
| Pedidos em atraso | 27 (17 da Norte Aço) |
| Norte Aço: lead time real ÷ prometido | 1,41 (0% no prazo) |
| Guindastes com < 20% de uso (12 semanas) | EQ0017 e EQ0018, na P007 (MG) |
| P011: principal causa nos RDOs (90 dias) | falta de equipamento, 37 RDOs, 23,5 dias de impacto |

A conferência completa está em `prd/99-verificacao.sql`.
