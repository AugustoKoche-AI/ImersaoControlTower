# 🛠️ Noite 2: Engenheiro de Dados | Imersão Jornada de Dados

**Terça, 20/10/2026, 19h30.** Ontem a turma subiu a bronze clicando, achou dez
sujeiras na mão e viu o Genie responder **"CPI de 7,01"** com toda a confiança.
Hoje o projeto vira código: **seis prompts no Claude Code, seis deploys**, e no
fim a Torre de Controle roda sozinha todo dia às 6h.

> **Domínio:** Construtora Atlas Engenharia, EPC com 40 obras (mineração, óleo e gás, agro)
> **Pergunta da noite:** *"Como isso roda sozinho todo dia — e certo?"*
> **Conexão:** a gold de hoje é o que a [noite 3](../aula-03-cientista) usa para
> prever qual obra vai estourar em 30 dias.

---

## 🎯 Objetivo da noite

Sair com a **Torre de Controle rodando como produto**, não como consulta:

| Entrega | Onde | Prova de que funcionou |
|---|---|---|
| O projeto como código (bundle) | `meu-atlas/databricks.yml` | `bundle deploy` em 8 segundos |
| A limpeza com contrato | pipeline Lakeflow, 12 tabelas silver | o custo total **não muda** (R$ 572,85 mi) |
| O produto de dados | 8 tabelas gold | 7 obras críticas, 6 em atenção |
| O RDO que vira coluna | `gold.rdo_estruturado` | "P011 atrasou por falta de guindaste" |
| Os KPIs definidos uma vez | 5 metric views (12 KPIs) | `MEASURE(cpi)` igual no SQL, no dashboard e no Genie |
| As portas para a diretoria | dashboard de 3 páginas + Genie | benchmark de **20/20** no ensaio |

---

## 🏗️ A arquitetura

```
                       job atlas_torre  (todo dia às 6h, serverless)
 ┌──────────────────────────────────────────────────────────────────────────────────┐
 │                                                                                  │
 │  conferencia_bronze ──► medalhao ──┬──► testes_de_qualidade ──┐                  │
 │  (sql_task)             (pipeline) │    (sql_task, 8 testes)  ├──► metricas_     │
 │  12 contagens           silver ×12 └──► rdo_com_ia ───────────┘    governadas    │
 │  ou raise_error         gold ×8         (regra + ai_classify       (5 metric     │
 │                         EXPECT          + palavra-chave, MERGE)     views)       │
 └──────────────────────────────────────────────────────────────────────────────────┘
        ▲                                                                  │
   bronze (noite 1)                     dashboard_portfolio ◄── gold + mv_* ──► genie_torre
   12 tabelas, tudo texto                (bundle, 3 páginas)                    (bundle, 20 perguntas)
```

**O pipeline declarativo por dentro** (o grafo que o Lakeflow desenha sozinho):

```
bronze.projetos ─────► silver.projetos ───────► gold.dim_projeto ─────────────┐
bronze.tarefas ──┐                                                              │
bronze.avanco ───┴──► silver.avanco_semanal ─► silver.tarefas ─┐               │
bronze.custos ──────► silver.custos ───────────────────────────┼► gold.fato_projeto_semana ─► gold.obra_situacao_atual
bronze.apontamentos ► silver.apontamentos ─────────────────────┤        (PV, EV, AC, SPI, CPI, EAC, horas, rupturas)
bronze.estoque ─────► silver.estoque ──┐                        │
bronze.compras ─────► silver.compras ──┼────────────────────────┘──► gold.cobertura_estoque · gold.pedidos_em_atraso
bronze.materiais ───► silver.materiais ┘                              gold.desempenho_fornecedor
bronze.equipes ─────► silver.equipes ─────────────► gold.utilizacao_equipe_semana
bronze.equipamentos ► silver.equipamentos ┐
bronze.uso_equip. ──► silver.uso_equipamentos ┴───► gold.utilizacao_equipamento_semana
bronze.rdo ─────────► silver.rdo ─────────(job: rdo_com_ia)──► gold.rdo_estruturado
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
databricks auth login --profile atlas
# abre o navegador; escolha o seu workspace Free Edition e autorize
databricks auth profiles
# atlas   https://dbc-xxxx.cloud.databricks.com   YES
```

Se aparecer `refresh token is invalid` ou `Valid: NO`, rode o `auth login` de
novo. Daqui em diante, **todo comando leva `--profile atlas`** (ou o nome que
você escolheu). Nos prompts, troque `<perfil>` por ele.

### 4. O repositório e a bronze da noite 1

```bash
git clone https://github.com/lvgalvao/ImersaoControlTower.git
cd ImersaoControlTower
python3 scripts/run_sql.py aulas/aula-01-analista/99-verificacao.sql --profile atlas
# 18 linhas "ok". Se não, faça a noite 1 primeiro (00-carregar-dados + 01-ingestao-bronze)
```

### 5. O Claude Code e as skills do Databricks

```bash
npm install -g @anthropic-ai/claude-code
databricks aitools install        # skills oficiais: bundles, pipelines, metric views, Genie
claude                            # abra na RAIZ do repositório
```

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
| 2 | [`prompt-02-silver.md`](prd/prompt-02-silver.md) | pipeline declarativo, 12 tabelas silver | **a limpeza é o conteúdo**; `EXPECT` é contrato | ~2 min |
| 3 | [`prompt-03-gold.md`](prd/prompt-03-gold.md) | fato obra × semana + 7 tabelas gold + 8 testes | o grão; PV/EV/AC acumulados; teste que quebra o job | ~3 min 30 s |
| 4 | [`prompt-04-rdo-com-ia.md`](prd/prompt-04-rdo-com-ia.md) | `rdo_estruturado` | IA custa por linha: regra, IA e palavra-chave | ~3 min |
| 5 | [`prompt-05-metricas.md`](prd/prompt-05-metricas.md) | 5 metric views, 12 KPIs | a fórmula mora num lugar só | ~20 s |
| 6 | [`prompt-06-dashboard-e-genie.md`](prd/prompt-06-dashboard-e-genie.md) | dashboard + Genie + benchmark | dashboard e IA como código; benchmark é teste | ~6 min |

O contexto que o Claude Code lê antes de cada prompt está em
[`prd/CLAUDE.md`](prd/CLAUDE.md): o negócio, as 10 sujeiras, a arquitetura e as
armadilhas do Free Edition já medidas.

### O momento "agora entendi"

- **Prompt 2:** quatro fornecedores viram um, 540 valores com vírgula voltam
  para a soma, três equipes duplicadas somem — e **o custo total não muda um
  centavo**. É esse o teste de uma boa limpeza.
- **Prompt 4:** a pergunta "por que a P011 atrasou?" ganha resposta —
  **falta de guindaste**, 37 RDOs em 90 dias — e dois guindastes de 90 t
  aparecem **parados em Minas**.
- **Prompt 6:** o Genie que errou ontem acerta as 20 perguntas do benchmark.

---

## 🔢 O que deve aparecer na tela

Se um número seu divergir, o erro está no código, não no dado (seed 42).
[`prd/99-verificacao.sql`](prd/99-verificacao.sql) confere tudo de uma vez (17 linhas).

| Métrica | Valor |
|---|---|
| Custo real total (silver = bronze) | R$ 572,85 mi |
| Equipes únicas | 120 (123 linhas no RH) |
| Grafias da Norte Aço unificadas | 4 → 1 |
| Tarefas acima de 100% corrigidas pela medição | 52 |
| Obras em andamento · críticas · em atenção | 36 · **7** · **6** |
| SPI · CPI da carteira | 0,95 · 0,94 |
| Estouro previsto (em andamento) | **R$ 42,36 mi** |
| Margem projetada da carteira | 12,5% |
| Rupturas de estoque previstas | 97 de 851 itens |
| Pedidos em atraso | 27 (17 da Norte Aço) |
| Norte Aço: lead time real ÷ prometido | 1,41 (0% no prazo) |
| Guindastes com < 20% de uso (12 semanas) | EQ0017 e EQ0018, na P007 (MG) |
| P011 nos últimos 90 dias | falta de equipamento: 37 RDOs, 23,5 dias de impacto |
| RDOs classificados por IA / regra / palavra-chave | 977 / 8.878 / 3.875 |

### 🔍 Por que o estouro mudou de R$ 41,9 mi para R$ 42,36 mi?

Na noite 1 o `exemplo-06` cortou as 52 tarefas de 117% em 100% (`LEAST`). É o
atalho mais comum — e está errado. A silver vai buscar o **% medido de verdade**
no boletim semanal: várias dessas tarefas não estavam concluídas. Com menos
valor agregado, o CPI piora e o estouro sobe **R$ 0,46 mi**.

> *"Limpar com um valor plausível escondeu meio milhão de reais. Limpar com o
> valor certo é ir buscar a fonte que mede, não inventar o número que parece bom."*

---

## 🆘 Se der errado ao vivo

| Sintoma | Causa | Correção |
|---|---|---|
| `refresh token is invalid` | Login expirado | `databricks auth login --profile <perfil>` |
| `dev_fulano_silver` não existe | `mode: development` no target | `presets: { trigger_pause_status: PAUSED }` |
| `window function inside an aggregate function` | `SUM(lag(...))` no pipeline | `lag()` num CTE, `SUM` no seguinte |
| `CAST_INVALID_INPUT '31262,81'` | Vírgula decimal | `replace(',', '.')` antes do CAST |
| `METRIC_VIEW_INVALID_VIEW_DEFINITION` | Rodou a metric view pelo `aitools tools query` | `sql_task` ou `scripts/run_sql.py` |
| Deploy falha: `Table ... does not exist` (Genie) | Genie criado antes das tabelas | `bundle run atlas_torre` e deploy de novo |
| A tarefa de IA leva 15+ minutos | IA rodando no histórico inteiro | Filtro dos 90 dias + regra para "sem ocorrência" |
| Um prompt não entrega | — | O gabarito está em [`atlas/`](atlas): compare o arquivo |

### Para zerar e recomeçar

```bash
bash aulas/aula-02-engenheiro/prd/00-reset.sh <perfil>              # SIMULA: mostra o que sairia
BUNDLE_DIR=aulas/aula-02-engenheiro/meu-atlas \
  bash aulas/aula-02-engenheiro/prd/00-reset.sh <perfil> --apagar   # apaga silver, gold e os recursos do bundle
```

A bronze e o volume nunca são apagados (são da noite 1).

### Para rodar o gabarito inteiro de uma vez

```bash
cd aulas/aula-02-engenheiro/atlas
databricks bundle deploy --profile <perfil>
databricks bundle run atlas_torre --profile <perfil>      # ~5 min 40 s do zero
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
| `prd/99-verificacao.sql` | os 17 números da noite, esperado × obtido |
| `prd/00-reset.sh` | zera a noite 2 (simula por padrão) |
| `atlas/` | **o gabarito**: o bundle completo, testado do zero |
| `atlas/scripts/gerar_dashboard.py`, `gerar_genie.py` | dashboard e Genie gerados por código |
| `meu-atlas/` | onde o **seu** bundle nasce no prompt 1 |
| `sem-codigo.md` | a trilha pela interface |
| `APRENDIZADOS.md` | o que falhou no ensaio do Free Edition e como foi resolvido |

## ➡️ Amanhã

A gold sabe dizer **quais obras estão** em risco hoje. A pergunta da diretoria
é outra: **quais vão estourar nos próximos 30 dias?** A `fato_projeto_semana`
tem a curva de cada obra, semana a semana — é exatamente o que um modelo precisa
para aprender o padrão antes de ele virar estouro: [noite 3](../aula-03-cientista).
