# 🤖 Noite 4 · Engenheiro de IA | Imersão Databricks + Claude Code

> **Quinta, 22/10, 19h30** · 📺 gravação: _link após a live_
>
> **Pergunta da noite:** *"E o dono, que não escreve SQL?"*
> **Você sai com:** um **agente que lê contrato e manual**, o **app do Projeto Farol** com login do workspace,
> um botão de **aprovar** que grava no **Lakebase**, e o **pitch de 3 minutos** para o dono.
> **Formato:** 3 prompts no Claude Code, 3 deploys.

---

## 🧠 A ideia da noite: acesso é entrega

| Noite | O que ficou de pé | O que era preciso saber |
|---|---|---|
| 1 | as 3 ferramentas no catálogo, SPI e CPI | SQL |
| 2 | pipeline, IA nos status, KPIs governados, dashboard, Genie | engenharia de dados |
| 3 | a probabilidade de estouro em 30 dias | ciência de dados |
| **4** | **o app, o agente de contratos e manual, e a aprovação** | **nada** |

Um dado que só o time de dados consegue abrir é um dado que não existe para a empresa. A noite 4 não cria
análise nova sobre os projetos: pega a gold pronta e entrega **uma URL**, **um agente** que responde
"e o que o contrato diz? e o que a nossa regra manda?" e **o caminho de volta** (a decisão vira linha no banco).

As 4 perguntas do dono, e quem responde cada uma hoje:

| Pergunta do dono | Onde a noite 4 responde |
|---|---|
| Quais projetos estão atrasados, e de quais clientes? | app → **Projetos em risco** |
| Quanto esse atraso vai me custar? | app (estouro) + Genie (multa que dá para **cobrar** de fornecedor) |
| Tenho gente parada enquanto outro projeto pede gente? | Genie + **Simulador** (COL0017 → PRJ-011) |
| O que vai dar errado no próximo mês, e o que eu faço agora? | score da noite 3 + avisos prévios + manual (freeze de 01/11) + **Aprovar** |

---

## 🎯 Objetivos

| # | Objetivo | Como você sabe que chegou lá |
|---|---|---|
| 1 | Transformar PDF em dado com IA | `gold.contratos_clausulas` com 72 cláusulas, `gold.manual_secoes` com 10 seções; `contratos_resumo` com multa, aviso prévio e renovação **tipados** |
| 2 | Um agente que cruza causa (status), regra (manual) e direito (contrato) | o Genie responde o PRJ-011 citando a seção 5 do manual e calcula R$ 1,12 mi de multa da CodeForge |
| 3 | Uma URL para o dono | app no ar com login SSO: projetos em risco, simulador, perguntar |
| 4 | Fechar o ciclo da decisão | aprovar grava em `torre.decisoes` (Lakebase) com seu e-mail e horário |
| 5 | Vender o projeto | pitch de 3 minutos com ROI em R$ ([`pitch.md`](pitch.md)) |

---

## 🏛️ Arquitetura

```
                ┌──────────────── noite 4 ───────────────────────────────────────────────────┐
 contratos PDF ─┼─ ai_parse_document ─▶ documentos_elementos ─▶ contratos_clausulas (72)       │
 manual PDF     │                                          └──▶ manual_secoes (10)            │
 (no volume)    │        cláusulas ── ai_extract + JSON schema ─▶ contratos_resumo (8, tipado) │
                │ silver.entregas_fornecedor + resumo ─▶ contratos_multa_fornecedor (R$)      │
                │ resumo ─────────────────────────────▶ contratos_avisos (aviso prévio)       │
 gold (noite 2) ┼─ projeto_situacao_atual · status_estruturado · utilizacao_pessoa_semana ─┐   │
 score (noite 3)┼──────────────────────────────────────────────────────────────────────┐   │   │
                │                                                                      ▼   ▼   │
                │   Genie Agent "Farol · Diretoria + Contratos" ◀── 12 tabelas + mv_projetos   │
                │          ▲                                                                   │
                │          │ aba Perguntar                                                     │
                │   App "Projeto Farol" (Databricks App · AppKit · login SSO)                  │
                │     leitura ── config/queries/*.sql ── SQL warehouse (gold)                  │
                │     escrita ── POST /api/decisoes ──── Lakebase Postgres torre.decisoes      │
                └──────────────────────────────────────────────────────────────────────────────┘
```

> **Por que não Knowledge Assistant / Supervisor Agent?** No Free Edition eles viraram *legacy* e não
> criam mais ("use Genie Agents instead"). O agente é um **Genie** com as cláusulas e o manual em tabelas:
> ele **cita** a fonte porque ela é uma linha, e dá para auditar o SQL.

---

## 🛠️ Passo a passo

### 0. Antes de começar (5 min)

- Noites 1 e 2 rodadas (bronze, silver, gold, `status_estruturado`). A noite 3 (`gold.score_estouro_30d`)
  é **opcional**: sem ela, o app mostra "—" na probabilidade e o Genie publica sem o score.
- CLI do Databricks (`databricks -v` ≥ 0.250), Node 22+, Claude Code; as skills do Databricks já vêm no
  repositório (`.claude/skills/`).
- Login: `databricks auth login --profile <perfil>` e ligue o warehouse.
- **O Free Edition aceita no máximo 3 apps.** Rode `databricks apps list --profile <perfil>` e apague um
  que você não usa mais, se já houver três.

### 1. Os três prompts

| # | Entrega | Deploy | Arquivo |
|---|---|---|---|
| 1 | **O agente que lê contrato e manual** | Genie publicado | [`prd/prompt-01-agente-de-contratos.md`](prd/prompt-01-agente-de-contratos.md) |
| 2 | **O app do Farol**: projetos em risco, simulador, perguntar | `apps deploy` | [`prd/prompt-02-app.md`](prd/prompt-02-app.md) |
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
python3 scripts/run_sql.py aulas/aula-04-engenheiro-ia/99-verificacao.sql --profile <perfil>        # 12 × ok
python3 scripts/genie.py benchmark "Farol · Diretoria + Contratos" \
  aulas/aula-04-engenheiro-ia/prd/genie-benchmark.json --profile <perfil>                         # ≥ 8/10
uv run --no-project --with "psycopg[binary]" python \
  aulas/aula-04-engenheiro-ia/torre-app/scripts/ver_decisoes.py --profile <perfil>                # a sua decisão
```

---

## 🔢 O que deve aparecer na tela

| O quê | Valor |
|---|---|
| Contratos lidos / cláusulas / seções do manual | 8 / 72 / 10 |
| `ai_extract` sem schema | `"0,2% do valor da entrega atrasada por dia corrido, limitada a 5%..."` (texto) |
| `ai_extract` com schema | `multa_atraso_pct_dia = 0.2`, `teto_multa_pct = 5.0` (número) |
| Multa da CodeForge | 0,5% ao dia, teto de 10% |
| Multa a cobrar da CodeForge na vigência atual | **R$ 1.122.967,65** (120 entregas atrasadas; R$ 3,24 mi desde 2024) |
| Aviso prévio vencido | DataPrime e NuvemSul (renovaram sozinhos em 01 e 02/10; R$ 21,4 mi por ano) |
| Aviso prévio nos próximos 60 dias | Observa360 (31/10) e QualiTest (01/12, **sem renovação automática**) |
| App: em risco · críticos · melancias · estouro | **17 de 41** · 7 · 4 · **R$ 6,5 mi** |
| App: multa a cobrar · rupturas de capacidade | R$ 1,2 mi (todos os fornecedores) · 15 |
| Simulador COL0017 (PRJ-007) → PRJ-011 | 151 h no mês · R$ 30,1 mil de ociosidade evitada · **19,0 dias** recuperados · onboarding R$ 8,0 mil · saldo R$ 22,1 mil |
| Benchmark do Genie | **10/10** no ensaio |

### A pergunta-âncora, como o Genie respondeu no ensaio (18/10)

> *"O projeto PRJ-011 atrasou por **falta de SRE**, que foi reportada em **12 semanas**. O manual (seção 5,
> 'ALOCAÇÃO DE SRE') orienta que todo projeto nas fases de testes ou implantação precisa de pelo menos um SRE
> alocado, sendo o PMO responsável por revisar essa alocação semanalmente."*

Na sequência: *"Tenho SRE parado que poderia ir para o PRJ-011?"* → **COL0017 e COL0018**, SREs seniores no
**PRJ-007** (ainda no discovery), uso de 5 a 6%, R$ 179,5 mil de custo ocioso em 12 semanas.
**E o simulador transforma essa resposta numa decisão aprovada.**

---

## ⏱️ Roteiro da noite (75 min úteis)

| Bloco | Min | O quê |
|---|---:|---|
| Abertura | 8 | o arco das 4 noites; as 4 perguntas do dono; "e quem não escreve SQL?" |
| Prompt 1 · contratos, manual + Genie | 20 | abrir o PDF da CodeForge, colar o prompt, mostrar o ai_extract sem e com schema; a pergunta-âncora |
| Prompt 2 · o app | 22 | `apps list` (limite de 3), `apps init`, as queries, o GRANT ao vivo, o deploy, a URL |
| Prompt 3 · aprovação | 12 | Lakebase em 7 s, o botão, a linha no Postgres |
| Pitch | 10 | os 3 minutos, ao vivo, com a demo da pergunta |
| Fecho | 3 | publicar: GitHub + vídeo + LinkedIn ([`pitch.md`](pitch.md#checklist-de-publicação)) |

**Se atrasar:** o prompt 3 vira demonstração (rode `subir-tudo.sh` antes da aula). Nunca corte o pitch.

---

## 🧯 Se der errado

| Sintoma | Causa | O que fazer |
|---|---|---|
| `Knowledge Assistant is now a legacy feature` | o Free Edition não cria mais KA nem Supervisor | é o motivo do agente ser um Genie |
| Genie: "a Vértice deve pagar a multa" | o modelo não sabe quem é a contratante | instrução explícita (já está no `gerar_genie.py`) |
| Publicar Genie: `score_estouro_30d does not exist` | noite 3 não rodou ou está recriando a tabela | rode o gerador de novo: ele só inclui o score se existir |
| Sobrescreveu o Genie da noite 2 | publicou com o título "Farol · Diretoria" | use "Farol · Diretoria + Contratos"; restaure a noite 2 com `bundle deploy` do `vertice` |
| `reached the maximum limit of 3 apps` | o Free Edition aceita 3 apps | apague um app que não usa mais |
| `apps deploy`: `INSUFFICIENT_PERMISSIONS` | service principal sem GRANT | `bash torre-app/scripts/conceder-acesso.sh <perfil>` e deploy de novo |
| `apps validate`: `TABLE_OR_VIEW_NOT_FOUND` | query de `config/queries` com tabela opcional | tabela opcional vai em rota do servidor (`routes/score.ts`) |
| `Requested node type [UNKNOWN] is not supported` | arquivo `*.geniespace.json` dentro do app | renomeie para `*-genie.json` |
| `permission denied for schema torre` | o schema foi criado por você no `npm run dev` | apague o schema `torre` e reinicie o app |
| `A soft-deleted project currently has this resource name` | apagou o Lakebase sem `--purge` | `databricks postgres delete-project projects/<id> --purge` ou `undelete-project` |
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
| `99-verificacao.sql` | 12 checagens esperado × obtido |
| `torre-app/` | o gabarito: app + agente + job + scripts |
| `meu-agente/`, `minha-torre/` | onde você constrói |
| `pitch.md` | o pitch de 3 minutos e o checklist de publicação |
| `sem-codigo.md` | trilha sem código |
| `APRENDIZADOS.md` | o que falhou no ensaio e como foi resolvido |
| Slides | [`slides/aula-04.html`](../../slides/aula-04.html) (abra no navegador, ← → navega, F tela cheia) |
