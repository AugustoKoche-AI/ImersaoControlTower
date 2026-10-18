# 🏗️ Torre de Controle de Projetos · Imersão Databricks + Claude Code

**4 noites, 4 profissões, 1 projeto.** Do dado bruto de uma construtora até um app em que a diretoria
aprova decisões, com IA lendo relatórios de obra e contratos. Tudo no **Databricks Free Edition**, na sua conta.

> **Imersão Jornada de Dados** · ao vivo no YouTube · **19 a 22 de outubro de 2026, às 19h30**
> Domínio: **Construtora Atlas Engenharia**, EPC fictícia com 40 obras e R$ 903 mi de carteira.
> Stack: Databricks Free Edition (serverless), SQL, Python, Lakeflow, Unity Catalog, AI/BI, Genie, Apps, Lakebase e Claude Code.

![Dashboard da noite 1](docs/img/noite1-dashboard-kpis.jpg)

---

## 🧭 O problema

Uma empresa de engenharia toca dezenas de obras ao mesmo tempo para mineração, óleo e gás e agroindústria.
O controle está espalhado: ERP, planilha de cronograma, ponto, frota, almoxarifado e o RDO (relatório
diário de obra), um texto que ninguém lê. **A diretoria só descobre que a obra estourou prazo ou custo
quando já estourou.**

A **Torre de Controle** responde três perguntas, em português e todo dia:

| # | Pergunta | KPIs |
|---|---|---|
| 1 | **Quais obras vão estourar prazo ou orçamento nos próximos 30 dias?** | SPI, CPI, EAC, margem projetada, desvio de prazo, probabilidade de estouro |
| 2 | **Onde tenho gente e equipamento parado enquanto outra obra atrasa?** | utilização de equipe e equipamento, horas ociosas |
| 3 | **Que material vai faltar antes de travar uma frente de serviço?** | cobertura de estoque, ruptura prevista, pedidos em atraso |

Regra de corte: **SPI ou CPI < 0,9 = atenção · < 0,8 = crítico.**

---

## 💼 Vantagens para o negócio

| Hoje, sem a Torre | Com a Torre | Ganho |
|---|---|---|
| Estouro aparece na medição mensal | SPI e CPI de toda obra, todo dia | detectar o desvio até 30 dias antes |
| 2 a 3 dias consolidando planilhas para responder "por que a obra X atrasou?" | Genie responde em português, citando a causa extraída do RDO | de dias para menos de 1 minuto |
| Aditivo de escopo pleiteado tarde (o contrato dá 30 dias, senão perde o direito) | alerta quando o CPI começa a cair | margem recuperada antes da preclusão |
| Guindaste parado em MG enquanto a obra do PA espera guindaste | ociosidade de equipe e equipamento por obra | realocar em vez de alugar |
| Compras descobre a falta quando a frente para | ruptura prevista: cobertura × próxima entrega prometida | frente de serviço não trava |
| Decisão de realocação por WhatsApp e e-mail | aprovação no app, gravada com usuário e horário | decisão rastreável e auditável |

Medido no dado da Atlas ao fim das 4 noites:

| O que a Torre mostra | Valor |
|---|---|
| Obras em risco · críticas | **13 de 36 · 7** |
| Estouro previsto se nada mudar | **R$ 42,36 mi** (gold; R$ 41,9 mi na conta "atalho" da noite 1) |
| Antecedência do modelo de estouro | **6 de 7** estouros avisados, em média **45 dias** antes (a regra atual: zero) |
| Genie em português | **20/20** (portfólio) e **10/10** (contratos) no benchmark |
| Multa estimada da P011 pelo contrato | **R$ 1,88 mi** (178 dias × 0,05% ao dia) |
| Rupturas de material previstas · pedidos em atraso | **97 · 27** (17 da mesma metalúrgica) |
| ROI do pitch (premissas explícitas) | **≈ R$ 12,9 mi** no ano 1 contra R$ 0,6 mi de custo |

**Para o aluno:** um projeto completo de ponta a ponta no GitHub, um dos tipos de entrega que empresas
intensivas em capital (Petrobras, Vale e Gerdau já são clientes Databricks no Brasil) compram, e o pitch
pronto para vender para a diretoria.

---

## 🏛️ Arquitetura

```
 FONTES (7 sistemas)          LAKEHOUSE · UNITY CATALOG · lakehouse_atlas              CONSUMO
 ───────────────────          ──────────────────────────────────────────────           ────────────────────
 ERP: projetos, custos,  ─┐   ┌──────────┐   ┌──────────────┐   ┌───────────────┐     ┌ AI/BI Dashboards
      compras, materiais  │   │  BRONZE  │   │    SILVER    │   │     GOLD      │     │   (portfólio, obra)
 Cronograma (tarefas,     ├──▶│ como veio│──▶│ limpo, tipado│──▶│ fato_projeto_ │──┬─▶├ Genie Agent
      avanço semanal)     │   │ tudo     │   │ expectations │   │ semana, marts │  │  │   (perguntas em PT)
 Ponto · Frota            │   │ texto    │   │ ai_extract   │   │ Metric Views  │  │  ├ App da Torre
 Almoxarifado             │   └──────────┘   │ nos RDOs     │   │ (12 KPIs)     │  │  │   + Lakebase (decisões)
 RDO (texto) + PDFs ──────┘     noite 1      └──────────────┘   └───────────────┘  │  └ Agente que lê
 Contratos (PDF)                                  noite 2            noite 2       │      contratos (noite 4)
                                                                                    │
                                     Modelo de estouro em 30 dias (MLflow, UC) ◀───┘ noite 3
```

Os KPIs são definidos **uma vez** (Metric Views no Unity Catalog) e reusados no dashboard, no Genie, no app e no agente.

---

## 🗓️ As 4 noites

| Noite | Data | Profissão | A pergunta | O que existe no fim | Como constrói | Pasta |
|---|---|---|---|---|---|---|
| **1** | seg 19/10 | Analista | Quais obras estão atrasadas e quanto custa? | bronze, SPI/CPI em SQL, R$ de estouro, 1º dashboard, Genie que erra | navegador (SQL Editor) | [`aula-01-analista`](aulas/aula-01-analista) |
| **2** | ter 20/10 | Engenheiro de Dados | Como isso roda sozinho todo dia? | pipeline Lakeflow, silver com testes, IA nos RDOs, 12 KPIs em Metric Views, dashboard de 3 páginas, Genie 20/20 | 6 prompts no Claude Code | [`aula-02-engenheiro`](aulas/aula-02-engenheiro) |
| **3** | qua 21/10 | Cientista de Dados | Quais vão estourar nos próximos 30 dias? | modelo no Unity Catalog (AUC 0,973), score por obra com motivo | 3 prompts no Claude Code | [`aula-03-cientista`](aulas/aula-03-cientista) |
| **4** | qui 22/10 | Engenheiro de IA | E o diretor que não escreve SQL? | agente que lê contrato (Genie 10/10), app da Torre com aprovação no Lakebase, pitch de 3 min | 3 prompts no Claude Code | [`aula-04-engenheiro-ia`](aulas/aula-04-engenheiro-ia) |

**Apresentações** (abra o `.html` no navegador; ← → navega, F tela cheia):
[visão geral do case](slides/visao-geral.html) ·
[noite 1](slides/aula-01.html) · [noite 2](slides/aula-02.html) · [noite 3](slides/aula-03.html) · [noite 4](slides/aula-04.html)

```
  noite 1             noite 2               noite 3                noite 4
  ───────             ───────               ───────                ───────
  a query          →  vira pipeline     →   vira previsão     →    vira produto
  quebra no           que roda sozinho      "quais vão             app, agente e o
  dado sujo           e define o KPI        estourar?"             pitch para a diretoria
```

Cada pasta é **autocontida** (README, roteiro, verificação e checkpoint). Perdeu uma noite? Comece da próxima.
Toda noite tem uma **trilha sem código** para gestão, PMO e financeiro.

---

## 🚀 Comece por aqui (5 minutos, sem instalar nada)

1. Crie a conta grátis: [databricks.com/learn/free-edition](https://www.databricks.com/learn/free-edition).
2. No Databricks: **Workspace → Create → Git folder** → `https://github.com/lvgalvao/ImersaoControlTower`.
3. Abra `aulas/aula-01-analista/00-carregar-dados` → **Run all**. O catálogo nasce e os dados são gerados direto no volume.
4. Abra `aulas/aula-01-analista/01-ingestao-bronze.sql` no **SQL Editor** → rode tudo.
5. Rode `aulas/aula-01-analista/99-verificacao.sql`. As 18 linhas devem dar `ok`.

Daí em diante, siga o [README da noite 1](aulas/aula-01-analista/README.md).

### Para as noites 2 a 4 (terminal)

```bash
git clone https://github.com/lvgalvao/ImersaoControlTower.git && cd ImersaoControlTower

# CLI do Databricks (>= 0.250) e login: cria o profile e salva a credencial
brew install databricks/tap/databricks        # ou: curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh
databricks auth login --profile imersao        # escolha um nome e use SEMPRE --profile

# Claude Code
npm install -g @anthropic-ai/claude-code
claude                                         # na raiz do repositório
```

Os prompts de cada noite, na ordem e prontos para colar: [`PROMPTS.md`](PROMPTS.md).

---

## 🗄️ O dataset

Gerado por [`material/gerar_dataset.py`](material/gerar_dataset.py): só biblioteca padrão do Python, **seed fixa 42**,
cerca de 12 MB. O "hoje" do dataset é **16/10/2026**. Todo aluno gera exatamente os mesmos bytes.

```bash
python3 material/gerar_dataset.py --saida ./dados --seed 42
python3 material/validar_padroes.py --dados ./dados      # confere os 4 padrões da história
```

| Sistema | Tabelas | Linhas |
|---|---|---:|
| ERP | `projetos` · `custos` · `compras` · `materiais` | 40 · 19.445 · 13.304 · 25 |
| Cronograma | `tarefas` · `avanco_semanal` | 8.000 · 55.703 |
| RH e ponto | `equipes` · `apontamentos` | 123 · 41.190 |
| Frota | `equipamentos` · `uso_equipamentos` | 300 · 19.817 |
| Almoxarifado | `estoque` | 40.094 |
| Obra | `rdo` (texto livre) | 13.730 |
| Documentos | RDOs em PDF · contratos EPC em PDF | 135 · 8 |

**O dado é simulado, não sorteado:** cada obra avança semana a semana. Chuva, falta de guindaste e equipe
fraca atrasam; cada avanço consome material e gera custo. Por isso SPI, CPI, ociosidade e ruptura saem
coerentes entre si. **Padrões embutidos:**

1. 8 obras com CPI caindo a partir do 9º mês (aditivo não cobrado);
2. chuva no Pará de dezembro a março atrasando 3 obras;
3. a Metalúrgica Norte Aço entrega com lead time 41% acima do prometido;
4. dois guindastes de 90 t parados em MG enquanto o RDO de uma obra no Pará reclama de falta de guindaste.

**A sujeira é proposital** e é o conteúdo da noite 2: data em dois formatos, UF em caixa mista, % concluído
acima de 100, vírgula decimal, estorno negativo, equipe duplicada, fornecedor escrito de quatro jeitos e RDO vazio.
Não "conserte" o gerador.

---

## 📁 Estrutura

```
aulas/
├── aula-01-analista/          navegador: catálogo, bronze, 6 exemplos SQL, dashboard, Genie sem curadoria
├── aula-02-engenheiro/        Claude Code: bundle atlas, pipeline Lakeflow, IA nos RDOs, Metric Views, Genie curado
├── aula-03-cientista/         Claude Code: features, modelo de estouro em 30 dias, score por obra
└── aula-04-engenheiro-ia/     Claude Code: app da Torre + Lakebase, agente de contratos, pitch
material/
├── gerar_dataset.py           o gerador (seed 42)
├── validar_padroes.py         confere que a história está no dado
├── pdf_simples.py             escreve os PDFs de RDO e contrato sem dependência
└── PRD-torre-de-controle.md   a especificação da imersão
scripts/
├── run_sql.py                 roda um .sql no warehouse, statement por statement (API de statements)
├── genie.py                   publica um Genie a partir de JSON, pergunta e roda benchmark
├── gerar_notebooks.py         .sql dos exemplos → notebooks resolvidos e em branco
├── gerar_slides.py            fragmento de slides → apresentação HTML no visual da Jornada
└── gerar_prompts.py           monta o PROMPTS.md a partir dos prompts de cada noite
slides/                        as apresentações de cada noite (abra o .html no navegador)
docs/img/                      prints do workspace usados nos READMEs e slides
```

---

## ✅ Testes

| O que | Comando | Esperado |
|---|---|---|
| Dataset reproduzível | gerar duas vezes e comparar (`diff -rq`) | idênticos |
| Padrões da história | `python3 material/validar_padroes.py --dados ./dados` | `TODOS OS PADRÕES OK` |
| Noite 1 no workspace | `python3 scripts/run_sql.py aulas/aula-01-analista/99-verificacao.sql --profile P` | 18 × `ok` |
| Genie da noite 1 | `python3 scripts/genie.py perguntar "Torre de Controle · Noite 1 (bronze, sem curadoria)" "Qual é o CPI de cada obra?" --profile P` | resposta errada, de propósito |
| Job completo (noites 2 e 3) | `cd aulas/aula-02-engenheiro/atlas && databricks bundle deploy --profile P && databricks bundle run atlas_torre --profile P` | 8 tarefas verdes, ~4 a 6 min |
| Noite 2 | `python3 scripts/run_sql.py aulas/aula-02-engenheiro/prd/99-verificacao.sql --profile P` | 17 × `ok` |
| Genie da noite 2 | `python3 scripts/genie.py benchmark "Torre de Controle · Diretoria" aulas/aula-02-engenheiro/prd/genie-benchmark.json --profile P` | 20/20 |
| Noite 3 | `python3 scripts/run_sql.py aulas/aula-03-cientista/99-verificacao.sql --profile P` | 15 × `ok` |
| Noite 4 | `python3 scripts/run_sql.py aulas/aula-04-engenheiro-ia/99-verificacao.sql --profile P` | 11 × `ok` |
| Genie de contratos | `python3 scripts/genie.py benchmark "Torre de Controle · Diretoria + Contratos" aulas/aula-04-engenheiro-ia/prd/genie-benchmark.json --profile P` | 10/10 |
| App + Lakebase | `cd aulas/aula-04-engenheiro-ia/torre-app && npm test` e `python3 scripts/ver_decisoes.py` | 4 testes; a aprovação aparece no Postgres |
| Do zero | `prd/00-reset.sh --apagar` (noite 2), `99-limpar-aula-03.sh`, `99-limpar-aula-04.sh --apagar` e rodar de novo | ensaiado em 18/10: as 4 noites reconstroem |

---

## 🧪 O que funciona no Free Edition (testado em 18/10/2026)

| Recurso | Status | Como usamos |
|---|---|---|
| Unity Catalog, volumes, SQL warehouse serverless | ✅ | `CREATE CATALOG` via SQL (a API recusa no Free Edition) |
| Notebook serverless com internet | ✅ | o `00-carregar-dados` roda o gerador dentro do workspace |
| `ai_extract`, `ai_classify`, `ai_query` | ✅ | causa do atraso a partir do texto do RDO |
| Metric Views | ✅ | só pela API de statements: o `aitools query` achata a indentação do YAML |
| AI/BI Dashboards, Genie Agents (com modo Agent) | ✅ | dashboard como JSON e Genie como JSON |
| Databricks Apps | ✅ | app da Torre (noite 4) |
| **Lakebase** (Postgres) | ✅ **novo**: em agosto não existia | `torre.decisoes`, gravada pelo app (projeto criado em 6,4 s) |
| `ai_parse_document` em PDF | ✅ ~25 a 30 s para 8 contratos | as 88 cláusulas viram tabela |
| Lakeflow Declarative Pipelines (SQL) com `EXPECT` | ✅ ~2 min 30 s | silver × 12 e gold × 8 |
| Registro de modelo no Unity Catalog | ⚠️ falha com o MLflow do serverless (`s3:PutObject ... explicit deny`) | `%pip install -U "mlflow-skinny[databricks]>=2.21,<3"` + `restartPython()` |
| Knowledge Assistant e Supervisor Agent | ❌ "legacy", não cria mais | agente de contratos com `ai_parse_document` + Genie |
| Endpoint de modelo próprio (Model Serving) | ❌ só modelos de base | o score de estouro roda em lote e grava na gold |

---

## 🔑 Convenções

- Catálogo **`lakehouse_atlas`**, schemas `bronze` / `silver` / `gold`, volume `bronze.raw`.
- Tabelas e colunas em snake_case e português, iguais às do CSV.
- "Hoje" é sempre `DATE'2026-10-16'`, nunca `current_date()`.
- Sempre `--profile` nos comandos do Databricks.
- A bronze guarda o dado **como veio**. Limpeza é na silver.

---

Feito pela [Jornada de Dados](https://suajornadadedados.com.br). Dados e empresas fictícios.
