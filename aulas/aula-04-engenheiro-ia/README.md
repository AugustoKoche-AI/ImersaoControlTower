# 🤖 Noite 4 · Engenheiro de IA | Imersão Databricks + Claude Code

> **Quinta, 22/10, 19h30** · 📺 gravação: _link após a live_
>
> **Pergunta da noite:** *"E o diretor que não escreve SQL?"*
> **Você sai com:** um **agente que lê contrato**, o **app da Torre** com login do workspace, um botão de
> **aprovar** que grava no **Lakebase**, e o **pitch de 3 minutos** para a diretoria.
> **Formato:** 3 prompts no Claude Code, 3 deploys.

---

## 🧠 A ideia da noite: acesso é entrega

| Noite | O que ficou de pé | O que era preciso saber |
|---|---|---|
| 1 | o dado no catálogo, SPI e CPI | SQL |
| 2 | pipeline, KPIs governados, dashboard, Genie | engenharia de dados |
| 3 | a probabilidade de estouro em 30 dias | ciência de dados |
| **4** | **o app, o agente de contratos e a aprovação** | **nada** |

Um dado que só o time de dados consegue abrir é um dado que não existe para a empresa. A noite 4 não cria
análise nova: pega a gold pronta e entrega **uma URL**, **um agente** que responde "e o que o contrato
diz?" e **o caminho de volta** (a decisão vira linha no banco).

---

## 🎯 Objetivos

| # | Objetivo | Como você sabe que chegou lá |
|---|---|---|
| 1 | Transformar PDF em dado com IA | `gold.contratos_clausulas` com 88 cláusulas; `contratos_resumo` com multa, chuva e içamento tipados |
| 2 | Um agente que cruza causa (RDO) com direito (contrato) | o Genie responde a P011 citando as cláusulas 5 e 6 e a multa de R$ 1,88 mi |
| 3 | Uma URL para a diretoria | app no ar com login SSO: obras em risco, simulador, perguntar |
| 4 | Fechar o ciclo da decisão | aprovar grava em `torre.decisoes` (Lakebase) com seu e-mail e horário |
| 5 | Vender o projeto | pitch de 3 minutos com ROI em R$ ([`pitch.md`](pitch.md)) |

---

## 🏛️ Arquitetura

```
                ┌──────────────── noite 4 ─────────────────────────────────────────────┐
 contratos PDF ─┼─ ai_parse_document ─▶ contratos_texto ─▶ contratos_clausulas (88)      │
 (8, no volume) │                                   └─ ai_query + JSON schema ─▶ contratos_resumo
                │                                                                ▼     │
 gold (noite 2) ┼─ obra_situacao_atual + rdo_estruturado ─────────────▶ contratos_exposicao (multa R$)
 score (noite 3)┼──────────────────────────────────────────────────────────────┐       │
                │                                                              ▼       │
                │   Genie Agent "Torre de Controle · Diretoria + Contratos" ◀── 11 tabelas + mv_obras
                │          ▲                                                           │
                │          │ aba Perguntar                                             │
                │   App "Torre de Controle" (Databricks App · AppKit · login SSO)      │
                │     leitura ── config/queries/*.sql ── SQL warehouse (gold)          │
                │     escrita ── POST /api/decisoes ──── Lakebase Postgres torre.decisoes
                └──────────────────────────────────────────────────────────────────────┘
```

> **Por que não Knowledge Assistant / Supervisor Agent?** No Free Edition eles viraram *legacy* e não
> criam mais ("use Genie Agents instead", testado em 18/10). O agente é um **Genie** com as cláusulas
> numa tabela: ele **cita** a cláusula porque ela é uma linha, e dá para auditar o SQL.

---

## 🛠️ Passo a passo

### 0. Antes de começar (5 min)

- Noites 1 e 2 rodadas (bronze, silver, gold, `rdo_estruturado`). A noite 3 (`gold.score_estouro_30d`)
  é **opcional**: sem ela, o app mostra "—" na probabilidade e o Genie publica sem o score.
- CLI do Databricks (`databricks -v` ≥ 0.250), Node 22+, Claude Code, e as skills do Databricks
  (`databricks aitools install`).
- Login: `databricks auth login --profile <perfil>` e ligue o warehouse.

### 1. Os três prompts

| # | Entrega | Deploy | Arquivo |
|---|---|---|---|
| 1 | **O agente que lê contrato** | Genie publicado | [`prd/prompt-01-agente-de-contratos.md`](prd/prompt-01-agente-de-contratos.md) |
| 2 | **O app da Torre**: obras em risco, simulador, perguntar | `apps deploy` | [`prd/prompt-02-app.md`](prd/prompt-02-app.md) |
| 3 | **A aprovação no Lakebase** | `apps deploy` | [`prd/prompt-03-aprovacao-lakebase.md`](prd/prompt-03-aprovacao-lakebase.md) |

Cole cada prompt (o bloco ```` ``` ```` da seção **"O prompt"**) no Claude Code, na raiz do repositório,
trocando `<perfil>`. O contexto que o Claude Code lê primeiro é [`prd/CLAUDE.md`](prd/CLAUDE.md).
Você constrói em [`meu-agente/`](meu-agente) e [`minha-torre/`](minha-torre); o gabarito está em
[`torre-app/`](torre-app).

### 2. Ou suba o gabarito inteiro (5 min)

```bash
bash aulas/aula-04-engenheiro-ia/torre-app/scripts/subir-tudo.sh <perfil>
```

### 3. Confira

```bash
python3 scripts/run_sql.py aulas/aula-04-engenheiro-ia/99-verificacao.sql --profile <perfil>        # 11 × ok
python3 scripts/genie.py benchmark "Torre de Controle · Diretoria + Contratos" \
  aulas/aula-04-engenheiro-ia/prd/genie-benchmark.json --profile <perfil>                         # ≥ 8/10
uv run --no-project --with "psycopg[binary]" python \
  aulas/aula-04-engenheiro-ia/torre-app/scripts/ver_decisoes.py --profile <perfil>                # a sua decisão
```

---

## 🔢 O que deve aparecer na tela

| O quê | Valor |
|---|---|
| Contratos lidos / cláusulas | 8 / 88 |
| Chuva dá prorrogação | P002, P011, P014 |
| Guindaste por conta do cliente | só P005 |
| Multa estimada da P011 | **R$ 1.876.298,00** (178 dias × 0,05% = 8,9%, teto de 10%) |
| Multa no teto | P005 (12% contra teto de 8%) |
| Soma das multas estimadas (8 obras) | **R$ 6,97 mi** |
| App: obras em risco · críticas · estouro · rupturas | **13 de 36** · 7 · **R$ 42,4 mi** · 97 |
| Simulador EQ0017 (P007) → P011 | 166 h no mês · R$ 157,6 mil de ociosidade · 7,8 dias evitados · ~R$ 82,6 mil de multa evitada |
| Genie, pergunta-âncora | falta de equipamento (37 RDOs, 23,5 dias) + cláusula 6 (não dá prorrogação) + cláusula 5 (chuva pode ser pleiteada) + multa R$ 1,88 mi |
| Benchmark do Genie | **10/10** no ensaio |

### A pergunta-âncora, como o Genie respondeu no ensaio (18/10)

> *"A obra P011 atrasou principalmente por falta de equipamento (37 RDOs, 23,5 dias de impacto), seguida
> de chuva (6 RDOs, 5 dias)… O contrato prevê que a Atlas não pode pedir prorrogação por falta de guindaste
> (Cláusula 6: 'A indisponibilidade de equipamento não constitui motivo para prorrogação de prazo'), nem por
> atraso de fornecedores (Cláusula 7), mas pode pleitear exclusão dos dias de chuva excedentes se comunicados
> corretamente (Cláusula 5)…"*

Na sequência: *"Onde tenho guindaste parado que poderia ir para a P011?"* → **EQ0017 e EQ0018**, Guindaste
90t na **P007 (Paracatu, MG)**, uso de 5 a 6%, R$ 951 mil de custo ocioso em 12 semanas. **E o simulador
transforma essa resposta numa decisão aprovada.**

---

## ⏱️ Roteiro da noite (75 min úteis)

| Bloco | Min | O quê |
|---|---:|---|
| Abertura | 8 | o arco das 4 noites; "e quem não escreve SQL?" |
| Prompt 1 · contratos + Genie | 20 | abrir o PDF da P011, colar o prompt, explicar ai_parse_document e JSON schema enquanto roda; a pergunta-âncora |
| Prompt 2 · o app | 22 | `apps init`, as queries, o 1º deploy que **falha** (GRANT ao vivo), o redeploy, a URL |
| Prompt 3 · aprovação | 12 | Lakebase em 6 s, o botão, a linha no Postgres |
| Pitch | 10 | os 3 minutos, ao vivo, com a demo da pergunta |
| Fecho | 3 | publicar: GitHub + vídeo + LinkedIn ([`pitch.md`](pitch.md#checklist-de-publicação)) |

**Se atrasar:** o prompt 3 vira demonstração (rode `subir-tudo.sh` antes da aula). Nunca corte o pitch.

---

## 🧯 Se der errado

| Sintoma | Causa | O que fazer |
|---|---|---|
| `Knowledge Assistant is now a legacy feature` | o Free Edition não cria mais KA nem Supervisor | é o motivo do agente ser um Genie |
| Genie: "recomendo cobrar a contratada" | o modelo não sabe que a Atlas é a contratada | instrução explícita (já está no `gerar_genie.py`) |
| Publicar Genie: `score_estouro_30d does not exist` | noite 3 não rodou ou está recriando a tabela | rode o gerador de novo: ele só inclui o score se existir |
| Sobrescreveu o Genie da noite 2 | publicou com o título "Torre de Controle · Diretoria" | use "… · Diretoria + Contratos"; restaure a noite 2 com `bundle deploy` do `atlas` |
| 1º `apps deploy`: `INSUFFICIENT_PERMISSIONS` | service principal sem GRANT | `bash torre-app/scripts/conceder-acesso.sh <perfil>` e deploy de novo |
| `apps validate`: `TABLE_OR_VIEW_NOT_FOUND` | query de `config/queries` com tabela opcional | tabela opcional vai em rota do servidor (`routes/score.ts`) |
| `Requested node type [UNKNOWN] is not supported` | arquivo `*.geniespace.json` dentro do app | renomeie para `*-genie.json` |
| `Postgres branch ... does not exist` | o projeto Lakebase foi apagado (soft delete) | `list-projects` (não `get-project`) para checar; recrie |
| `A soft-deleted project currently has this resource name` | apagou sem `--purge` | `databricks postgres delete-project projects/<id> --purge` ou `undelete-project` |
| App pede "Permission Requested" | consentimento OAuth (o Genie age em seu nome) | **Authorize**, uma vez |
| Tela com números sem formato | o warehouse devolve número como string | `num()` / `Number()` |

Limpar só a noite 4 para ensaiar de novo (simula; `--apagar` apaga; nunca toca nas noites 1 a 3):

```bash
bash aulas/aula-04-engenheiro-ia/prd/99-limpar-aula-04.sh <perfil>
```

---

## 🧭 Sem escrever código (trilha de gestão)

Veja [`sem-codigo.md`](sem-codigo.md): o mesmo resultado com o **Genie** (pergunta-âncora e benchmark na
mão) e com o **Genie App Builder** (o app descrito em português).

---

## 🗂️ Arquivos

| Arquivo | Para que serve |
|---|---|
| `prd/CLAUDE.md` | contexto que o Claude Code lê antes dos prompts |
| `prd/prompt-0N-*.md` | os 3 prompts, com o que mostrar, o que falar e "se der errado" |
| `prd/genie-benchmark.json` | 10 perguntas com SQL de referência |
| `prd/99-limpar-aula-04.sh` | apaga só a noite 4 |
| `99-verificacao.sql` | 11 checagens esperado × obtido |
| `torre-app/` | o gabarito: app + agente + job + scripts |
| `meu-agente/`, `minha-torre/` | onde você constrói |
| `pitch.md` | o pitch de 3 minutos e o checklist de publicação |
| `sem-codigo.md` | trilha sem código |
| `APRENDIZADOS.md` | o que falhou no ensaio e como foi resolvido |
