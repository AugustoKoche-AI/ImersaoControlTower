# 🛠️ Noite 2: Engenheiro de Dados | Imersão Jornada de Dados

**Terça, 20/10/2026, 19h30.** Ontem o novo CTO da Vértice leu Excel, ClickUp e MS Project
com o mesmo comando, juntou as três ferramentas à mão numa view e viu o Genie errar as
quatro perguntas do dono ("nenhum atraso custa nada"). Hoje é a noite da **integração**:
**seis prompts no Claude Code, seis deploys**, e no fim a Torre roda sozinha toda segunda
às 6h, com as três ferramentas num modelo só.

> **Domínio:** Vértice Tecnologia, 60 projetos de clientes em Excel (20), ClickUp (25) e MS Project (15)
> **Pergunta da noite:** *"Como as três ferramentas viram uma — e isso roda sozinho, certo?"*
> **Conexão:** a gold de hoje é o que a [noite 3](../aula-03-cientista) usa para
> prever qual projeto vai estourar em 30 dias.

---

## 🎯 Objetivo da noite

Sair com a **Torre de Controle rodando como produto**, não como consulta:

| Entrega | Onde | Prova de que funcionou |
|---|---|---|
| O projeto como código (bundle) | `meu-vertice/databricks.yml` | `bundle deploy` em 8 segundos |
| **A integração** com contrato | pipeline Lakeflow, `silver.tarefas` + 12 tabelas silver | 60 projetos, 4.917 tarefas, nenhuma órfã; o custo total **não muda** (R$ 193,35 mi) |
| O produto de dados | 7 tabelas gold | 7 projetos críticos, 10 em atenção, 4 melancias |
| O texto que vira coluna | `gold.status_estruturado` e `gold.postmortem_estruturado` | "PRJ-011 atrasou por falta de SRE, 12 semanas seguidas" |
| Os KPIs definidos uma vez | 5 metric views | `MEASURE(cpi)` igual no SQL, no dashboard e no Genie |
| As portas para o dono | dashboard de 3 páginas + Genie | as 4 perguntas do dono certas; benchmark de **20/20** |

---

## 🏗️ A arquitetura

```
                       job vertice_farol  (toda segunda às 6h, serverless)
 ┌────────────────────────────────────────────────────────────────────────────────────┐
 │                                                                                    │
 │  conferencia_bronze ──► medalhao ──┬──► testes_de_qualidade ──┐                    │
 │  (sql_task)             (pipeline) │    (sql_task, 10 testes) │                    │
 │  13 contagens           silver ×13 ├──► status_com_ia ────────┼──► metricas_       │
 │  ou raise_error         gold ×7    │    (regra + ai_classify  │    governadas      │
 │                         EXPECT     │     + ai_extract, MERGE) │    (5 metric       │
 │                                    └──► postmortem_com_ia ────┘     views)         │
 └────────────────────────────────────────────────────────────────────────────────────┘
        ▲                                                                  │
   bronze (noite 1)                      dashboard_portfolio ◄── gold + mv_* ──► genie_farol
   13 tabelas: CSV, Excel, JSON, XML      (bundle, 3 páginas)                    (bundle, 20 perguntas)
```

**O pipeline declarativo por dentro** (o grafo que o Lakeflow desenha sozinho):

```
bronze.projetos ─────────► silver.projetos (o de-para) ──┐
bronze.excel_tarefas ────► tarefas_excel ─────┐          │
bronze.clickup_tarefas ──► tarefas_clickup ───┼─► silver.tarefas ─┬─► gold.projeto_situacao_atual (hoje)
bronze.msproject_tarefas ► tarefas_msproject ─┘   (UNION ALL)     │
bronze.status_semanal ───► silver.status_semanal ─────────────────┼─► gold.fato_projeto_semana (histórico)
bronze.custos ───────────► silver.custos ─────────────────────────┤
bronze.apontamentos ─────► silver.apontamentos ──┐                │
bronze.colaboradores ────► silver.colaboradores ─┴────────────────┴─► gold.utilizacao_pessoa_semana
bronze.entregas_forn. ───► silver.entregas_fornecedor ──────────────► gold.desempenho_fornecedor · gold.entregas_em_atraso
bronze.contratos_cap. ───► silver.contratos_capacidade ─┐
bronze.consumo_cap. ─────► silver.consumo_capacidade ───┴───────────► gold.cobertura_capacidade
bronze.postmortems ──────► silver.postmortems ──(job: postmortem_com_ia)──► gold.postmortem_estruturado
                           silver.status_semanal ──(job: status_com_ia)───► gold.status_estruturado
```

---

## 🚀 Passo a passo — do zero até o primeiro deploy

A noite 1 foi toda pelo navegador. A noite 2 precisa de terminal. São seis
passos, e o passo 3 é o erro que quase todo mundo vê.

### 1. Python 3.12 e Git

```bash
python3 --version     # 3.10 a 3.12. Evite 3.13 para as bibliotecas do Databricks
git --version
```

### 2. A CLI do Databricks (v0.250 ou mais nova)

```bash
# macOS
brew tap databricks/tap && brew install databricks
# Windows
winget install Databricks.DatabricksCLI
# Linux
curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh

databricks -v
```

### 3. O login (e o erro que todo mundo vê)

```bash
databricks auth login --profile vertice
# abre o navegador; escolha o seu workspace Free Edition e autorize
databricks auth profiles
# vertice   https://dbc-xxxx.cloud.databricks.com   YES
```

Se aparecer `refresh token is invalid` ou `Valid: NO`, rode o `auth login` de
novo. Daqui em diante, **todo comando leva `--profile vertice`** (ou o nome que
você escolheu). Nos prompts, troque `<perfil>` por ele.

### 4. O repositório e a bronze da noite 1

```bash
git clone https://github.com/lvgalvao/ImersaoControlTower.git
cd ImersaoControlTower
python3 scripts/run_sql.py aulas/aula-01-analista/99-verificacao.sql --profile vertice
# 22 linhas "ok". Se não, faça a noite 1 primeiro (00-carregar-dados + 01-ingestao-bronze + exemplo 05)
```

### 5. O Claude Code e as skills do Databricks

```bash
npm install -g @anthropic-ai/claude-code
claude                            # abra na RAIZ do repositório
```

As **skills oficiais do Databricks** (bundles, pipelines, metric views, Genie, AI functions)
já vêm no repositório, em `.claude/skills/`. Para atualizar: `databricks aitools update`.

### 6. Guard rails antes de dar acesso ao workspace

Em `.claude/settings.json`, negue o que não tem volta:

```json
{
  "permissions": {
    "deny": ["Bash(databricks bundle destroy*)", "Bash(databricks bundle deploy --target prod*)",
             "Bash(git push --force*)", "Bash(rm -rf*)"]
  }
}
```

Pronto: cole o **prompt 1**.

---

## 🧾 Os 6 prompts

Cada prompt termina com um deploy. **Enquanto o Claude Code trabalha, o
professor explica o conceito** — o tempo de espera vira aula. O texto exato de
cada um está no arquivo; a sequência inteira está em [`PROMPTS.md`](../../PROMPTS.md).

| # | Arquivo | Entrega | Conceito da noite | Tempo medido |
|---|---|---|---|---|
| 1 | [`prompt-01-bundle.md`](prd/prompt-01-bundle.md) | bundle + job + conferência da bronze | projeto como código; conferência antes de transformação | ~40 s |
| 2 | [`prompt-02-silver.md`](prd/prompt-02-silver.md) | pipeline declarativo, `silver.tarefas` + 12 tabelas | **a integração é um contrato de colunas**; o de-para é dado; `EXPECT` é contrato | ~2 min |
| 3 | [`prompt-03-gold.md`](prd/prompt-03-gold.md) | fato projeto × semana + 6 tabelas gold + 10 testes | o grão; de onde vem o histórico; teste que quebra o job | ~3 min |
| 4 | [`prompt-04-texto-com-ia.md`](prd/prompt-04-texto-com-ia.md) | `status_estruturado` e `postmortem_estruturado` | `ai_classify` escolhe, `ai_extract` tira (com tipo); IA custa por linha | ~2 min |
| 5 | [`prompt-05-metricas.md`](prd/prompt-05-metricas.md) | 5 metric views | a fórmula mora num lugar só | ~20 s |
| 6 | [`prompt-06-dashboard-e-genie.md`](prd/prompt-06-dashboard-e-genie.md) | dashboard + Genie + benchmark | dashboard e IA como código; benchmark é teste | ~6 min |

O contexto que o Claude Code lê antes de cada prompt está em
[`prd/CLAUDE.md`](prd/CLAUDE.md): o negócio, as 19 sujeiras, a arquitetura e as
armadilhas do Free Edition já medidas.

### O momento "agora entendi"

- **Prompt 2:** vinte planilhas, vinte e cinco listas e quinze cronogramas viram **uma
  tabela**. As horas de cada planilha batem com a linha de TOTAL que o gerente deixou, as
  tarefas-resumo do Project saem, e **o custo total não muda um centavo**.
- **Prompt 3:** as duas SREs paradas no PRJ-007 aparecem no timesheet: 5% de utilização.
- **Prompt 4:** a pergunta "por que o PRJ-011 atrasou?" ganha resposta — **falta de SRE**,
  12 semanas seguidas no status, 57 dias de impacto declarado. Junto com o prompt 3, é a
  pergunta 3 do dono respondida: tem gente parada num projeto enquanto o outro pede gente.
- **Prompt 6:** o Genie que errou as perguntas do dono ontem acerta as quatro, e as 20 do
  benchmark.

---

## 🔢 O que deve aparecer na tela

Se um número seu divergir, o erro está no código, não no dado (seed 42).
[`prd/99-verificacao.sql`](prd/99-verificacao.sql) confere tudo de uma vez (20 linhas).

| Métrica | Valor |
|---|---|
| Tarefas na silver | 4.917 (Excel 1.643 · ClickUp 2.119 · MS Project 1.155) |
| Custo real total (silver = bronze) | R$ 193,35 mi |
| Pessoas únicas | 520 (523 linhas no RH) |
| Grafias da CodeForge unificadas | 4 → 1 |
| Projetos em andamento · críticos · em atenção | 41 · **7** · **10** |
| SPI · CPI da carteira | 0,92 · 0,97 |
| Estouro previsto (em andamento) | **R$ 6,47 mi** — o mesmo do rascunho da noite 1 |
| Margem projetada da carteira | 20,4% |
| Melancias (farol verde, SPI < 0,9) | 4: PRJ-012, PRJ-028, PRJ-034, PRJ-042 |
| Rupturas de capacidade previstas | 15 de 56 contratos (11 de cloud, 4 de banco de horas) |
| Entregas em atraso | 5, todas da CodeForge |
| CodeForge: prazo real ÷ prometido | 1,41 (0% no prazo) |
| SREs com < 20% de uso (12 semanas) | COL0017 e COL0018, no PRJ-007, ~450 h paradas cada |
| PRJ-011 nos últimos 90 dias | falta de SRE: 12 semanas, 57 dias de impacto |
| Status classificados por IA / regra / palavra-chave | 163 / 2.954 / 794 |
| Postmortems estruturados | 101 (deploy sem teste é a causa nº 1: 44) |

### 🔍 Por que o estouro é igual ao da noite 1?

Porque a fotografia de hoje (`projeto_situacao_atual`) faz a mesma conta do rascunho, sobre
as mesmas tarefas — agora com contrato, teste e reprocessamento automático. O que a noite 2
acrescenta é o que a noite 1 não tinha como fazer: o **histórico** (o fato semanal, que vem
do status de cada sexta), a **causa** (a IA lendo o texto) e as **pessoas** (o timesheet).

> *"O rascunho de ontem acertou o número. Mas ele só existia na minha query. Hoje o mesmo
> número tem dono, teste e roda toda segunda sem eu abrir o computador."*

---

## 🆘 Se der errado ao vivo

| Sintoma | Causa | Correção |
|---|---|---|
| `refresh token is invalid` | Login expirado | `databricks auth login --profile <perfil>` |
| `dev_fulano_silver` não existe | `mode: development` no target | `presets: { trigger_pause_status: PAUSED }` |
| Pipeline falha em `achou_o_projeto` | Arquivo que não casou com o de-para | Fallback pelo nome do arquivo (Excel) e da lista (ClickUp) |
| `CAST_INVALID_INPUT '1827,44'` | Vírgula decimal | `replace(',', '.')` antes do CAST |
| `METRIC_VIEW_INVALID_VIEW_DEFINITION` | Rodou a metric view pelo `aitools tools query` | `sql_task` ou `scripts/run_sql.py` |
| Deploy falha: `Table ... does not exist` (Genie) | Genie criado antes das tabelas | `bundle run vertice_farol` e deploy de novo |
| A tarefa de IA leva 15+ minutos | IA rodando no histórico inteiro | Filtro dos 90 dias + regra para "sem bloqueio" |
| Um prompt não entrega | — | O gabarito está em [`vertice/`](vertice): compare o arquivo |

### Para zerar e recomeçar

```bash
bash aulas/aula-02-engenheiro/prd/00-reset.sh <perfil>              # SIMULA: mostra o que sairia
BUNDLE_DIR=aulas/aula-02-engenheiro/meu-vertice \
  bash aulas/aula-02-engenheiro/prd/00-reset.sh <perfil> --apagar   # apaga silver, gold e os recursos do bundle
```

A bronze e o volume nunca são apagados (são da noite 1).

### Para rodar o gabarito inteiro de uma vez

```bash
cd aulas/aula-02-engenheiro/vertice
databricks bundle deploy --profile <perfil>
databricks bundle run vertice_farol --profile <perfil>    # silver, gold, IA, testes, métricas e (noite 3) o modelo
databricks bundle deploy --profile <perfil>               # 2º deploy: o Genie precisa das tabelas
python3 ../../../scripts/run_sql.py ../prd/99-verificacao.sql --profile <perfil>
```

---

## 🧩 Sem código: a mesma noite pela interface

Para quem é de gestão, PMO ou financeiro: [`sem-codigo.md`](sem-codigo.md) refaz
as entregas clicando — Lakeflow Designer, Genie Code, metric view pela UI,
dashboard e Genie. O resultado é o mesmo; o que muda é que ele não fica no Git.

---

## 📁 O que tem aqui

| Caminho | O que é |
|---|---|
| `prd/CLAUDE.md` | contexto do projeto para o Claude Code |
| `prd/prompt-01..06-*.md` | os 6 prompts, com o que mostrar, o que falar e "se der errado" |
| `prd/genie-benchmark.json` | 20 perguntas com o SQL de referência |
| `prd/99-verificacao.sql` | os 20 números da noite, esperado × obtido |
| `prd/00-reset.sh` | zera a noite 2 (simula por padrão) |
| `vertice/` | **o gabarito**: o bundle completo, testado |
| `vertice/scripts/gerar_dashboard.py`, `gerar_genie.py` | dashboard e Genie gerados por código |
| `meu-vertice/` | onde o **seu** bundle nasce no prompt 1 |
| `sem-codigo.md` | a trilha pela interface |
| `APRENDIZADOS.md` | o que falhou no ensaio do Free Edition e como foi resolvido |

## ➡️ Amanhã

A gold sabe dizer **quais projetos estão** em risco hoje. A pergunta 4 do dono é outra:
**o que vai dar errado no próximo mês?** A `fato_projeto_semana` tem a curva de cada projeto,
semana a semana, e o `status_estruturado` tem as causas — é exatamente o que um modelo precisa
para aprender o padrão antes de ele virar estouro: [noite 3](../aula-03-cientista).
