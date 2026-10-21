# 🏗️ Noite 3 · Engenheiro de Dados com Claude Code | Imersão Jornada de Dados

**Quarta, 21/10/2026, 19h30.**

**Ao fim desta noite**, a Torre de Controle da Vértice roda sozinha, toda segunda às 6h: busca os
arquivos no data lake, confere se chegaram inteiros, junta Excel, ClickUp e MS Project numa tabela
só, calcula os KPIs com teste, lê a causa de cada atraso no texto do status e atualiza um
**dashboard** que o dono abre. Tudo como código, num repositório seu no GitHub.

> **Formato:** o passo 1 à mão, com a CLI do Databricks (o bundle nasce num repositório novo), e
> os prompts 1 a 4 no Claude Code. Um deploy por passo, um bundle só (`vertice`).
> **Ponto de partida:** o job de ingestão que a turma montou **clicando** na noite 2. No passo 1 ele
> vira código; no prompt 4 o job inteiro alimenta o dashboard.
> **Passo a passo completo** (instalação do zero, os 5 prompts prontos para copiar, o gabarito):
> [`claude-code/README.md`](claude-code/README.md).
> **Conexão:** a gold de hoje é o que o modelo, o Genie e o app da [noite 4](../aula-04-produtos-de-dados-ia) usam.

---

## 🎬 O caso da noite: o job que mora num clique

Ontem o job `vertice_ingestao` ficou de pé: a API de feriados e o data lake, todo dia às 6h. Hoje
de manhã ele rodou sozinho, verde. Funciona. Mas:

- ninguém sabe dizer **quem mudou o quê** nele;
- se alguém apagar sem querer, **ninguém sabe recriar**;
- as chaves do Supabase estão **à vista** nos parâmetros da tarefa;
- e ele só **carrega** a bronze. As quatro perguntas do dono continuam sem resposta, porque o dado
  continua sujo e espalhado em três ferramentas.

A noite resolve as quatro coisas, nessa ordem.

---

## 🎯 O que você entrega

| # | Passo | Entrega | Prova de que funcionou |
|---|---|---|---|
| — | **O bundle, à mão** (CLI) | repositório novo com `bundle init`, o job de ontem importado (`bundle generate`), as chaves fora do Git | 2 caixas verdes no DAG · `git status` sem nenhuma chave |
| 1 | **Conferência + silver** | a conferência das 9 tabelas da bronze e o pipeline `vertice_medalhao`: as 3 ferramentas viram `silver.tarefas`, mais 6 tabelas limpas, com `EXPECT` | 9 `ok` · **4.917 tarefas** (Excel 1.643 · ClickUp 2.119 · Project 1.155) · custo R$ 193,35 mi, igual à bronze |
| 2 | **Gold + testes** | `projeto_situacao_atual`, `fato_projeto_semana`, `utilizacao_pessoa_semana` e 10 testes que quebram o job | **7 críticos, 10 em atenção, 4 melancias, R$ 6,47 mi** de estouro previsto |
| 3 | **O job completo** | `status_estruturado` (IA no texto do status) e o job inteiro, de ponta a ponta, toda segunda às 6h | **6 caixas verdes** · PRJ-011: falta de SRE, 12 semanas, 57 dias |
| 4 | **O dashboard** | "Projeto Farol · Portfólio", 3 páginas, como código no bundle | SPI 0,92 · CPI 0,97 · as SREs paradas · a CodeForge ×1,41 |

---

## 🪜 O passo a passo da noite

**A premissa:** o catálogo `lakehouse_vertice` e a bronze já existem (noites 1 e 2), e o job de
ingestão da noite 2 está no workspace. Hoje nada disso é recriado: um **repositório novo**, vazio,
ganha o bundle, e o bundle passa a cuidar do job, que continua lendo e gravando no mesmo catálogo.

### 0 · As ferramentas e o ponto de partida (5 min)

**As três ferramentas da noite.** Confira as versões:

```bash
gh --version            # GitHub CLI
databricks --version    # Databricks CLI, v1.0 ou mais nova (testado na v1.13)
claude --version        # Claude Code
```

Faltou alguma? Instale a que faltar:

```bash
# macOS
brew install gh
brew tap databricks/tap && brew install databricks
curl -fsSL https://claude.ai/install.sh | bash

# Windows (PowerShell)
winget install GitHub.cli
winget install Databricks.DatabricksCLI
irm https://claude.ai/install.ps1 | iex
```

**O login nas três:**

```bash
gh auth login                                   # GitHub.com · HTTPS · navegador
databricks auth login --profile DEFAULT         # abre o navegador: entre no seu Free Edition
claude                                          # na primeira vez pede o login; depois saia com /exit
```

**O ponto de partida no workspace:**

```bash
databricks auth profiles                        # DEFAULT com Valid: YES
databricks experimental aitools tools query "SHOW TABLES IN lakehouse_vertice.bronze" --profile DEFAULT
# 10 tabelas: as 9 da noite 1 + feriados
databricks jobs list --profile DEFAULT          # o job de ingestão da noite 2 está aqui
```

Do zero, com editor e Git: [passos 1 a 9 do passo a passo completo](claude-code/README.md#-antes-de-tudo-o-passo-a-passo-do-zero).

### 1 · O bundle, à mão, com a CLI (5 min, sem Claude Code)

Só copiar e colar. Detalhes e "se der errado" em [`bundle-na-mao.md`](claude-code/prd/bundle-na-mao.md).
Troque `DEFAULT` pelo seu profile, se tiver outro nome.

```bash
mkdir -p ~/projetos && cd ~/projetos
gh repo create vertice --public --clone          # já tem um "vertice" no GitHub? use outro nome AQUI e no init
databricks bundle init default-minimal --profile DEFAULT     # nome: vertice · o resto: Enter
cd ~/projetos/vertice
ls databricks.yml                                             # TEM que aparecer: daqui até o claude, tudo roda nesta pasta

databricks jobs list --profile DEFAULT                       # copie o id do job "Ingestão"
databricks bundle generate job --existing-job-id <id> --profile DEFAULT
```

As chaves do Supabase saem do YAML (o repositório é público) e vão para a `.databricks/`, que o
Git ignora. Cole o bloco inteiro:

```bash
python3 - <<'PY'
import json, pathlib, re
arquivo = pathlib.Path("resources/ingestão.job.yml")
assert arquivo.exists(), "não achei resources/ingestão.job.yml: rode na pasta do bundle (cd ~/projetos/vertice) e depois do generate"
yml = arquivo.read_text()
chaves = {"s3_access_key_id": "AWS_ACCESS_KEY_ID", "s3_secret_access_key": "AWS_SECRET_ACCESS_KEY"}
valores = {}
for var, param in chaves.items():
    valores[var] = re.search(rf"{param}: (.+)", yml).group(1).strip().strip("\"'")
    yml = re.sub(rf"{param}: .+", f"{param}: ${{var.{var}}}", yml)
yml = "variables:\n" + "".join(f"  {v}:\n    description: chave do data lake (o valor fica fora do Git)\n" for v in chaves) + "\n" + yml
arquivo.write_text(yml)
pasta = pathlib.Path(".databricks/bundle/dev"); pasta.mkdir(parents=True, exist_ok=True)
(pasta / "variable-overrides.json").write_text(json.dumps(valores))
print("ok: as chaves saíram do YAML e foram para", pasta / "variable-overrides.json")
PY
```

```bash
databricks bundle validate --profile DEFAULT                 # Validation OK!
databricks bundle deploy   --profile DEFAULT

git add . && git status                                      # .databricks/ NÃO aparece
git commit -m "passo 1: o job de ontem vira código" && git push -u origin HEAD
```

**O Claude Code disse que não achou o job importado (ou o `generate` deu erro)?** O `generate` rodou
fora da pasta do bundle. Refaça só esta parte, de dentro da pasta onde está o `databricks.yml`:

```bash
cd ~/projetos/vertice                                        # ou a pasta onde você rodou o init
ls databricks.yml                                            # tem que aparecer
databricks bundle generate job --existing-job-id <id> --profile DEFAULT --force
```

Cole de novo o bloco das chaves (acima) e rode `validate`, `deploy`, `commit` e `push`. Depois
saia do Claude Code (`/exit`), abra de novo **nesta pasta** (`claude`) e cole o prompt 1. O
`--force` reescreve o `ingestão.job.yml` do zero, então o bloco das chaves funciona de novo.

### 2 · As skills do Databricks e o Claude Code

```bash
databricks aitools install --agents claude-code --scope project --skills-only --experimental
claude
```

O `aitools install` põe as skills oficiais do Databricks em `.claude/skills/` (CLI, bundles,
pipelines, dashboards...): é o manual que o Claude Code consulta antes de cada comando.

Sempre na raiz do repositório `vertice`. O prompt 1 começa arrumando o bundle (nomes, agendamento,
o `CLAUDE.md` do curso) e depois faz a silver.

#### O Claude Code em 5 minutos (antes do prompt 1)

O Claude Code é uma conversa dentro do terminal: você escreve em português, ele lê os arquivos da
pasta, escreve código e roda comandos, sempre pedindo licença antes (a não ser no modo auto). Tudo
que começa com `/` é um comando dele; o resto é conversa.

| Digite | O que acontece | Exemplo |
|---|---|---|
| `/model` | abre a lista de modelos. Opus pensa melhor, Sonnet é mais rápido | `/model` → escolha com as setas → Enter |
| `Shift+Tab` | troca o **modo**. Cada aperto passa para o próximo; o rodapé da tela mostra qual está ligado (veja abaixo) | aperte até aparecer `plan mode on` |
| `@` + nome do arquivo | anexa o arquivo à sua mensagem: ele lê antes de responder. Ao digitar `@` aparece a lista de arquivos | `explique a seção 3 do @CLAUDE.md em 3 linhas` |
| `!` + comando | roda o comando **no seu terminal**, sem sair do Claude Code, e a saída entra na conversa (ele vê o resultado) | `! databricks bundle validate --profile DEFAULT` |
| `Esc` | para o que ele está fazendo agora | ele começou a fazer algo errado → `Esc` → corrija em português |
| `Esc` `Esc` (ou `/rewind`) | mostra as mensagens anteriores: escolha uma e ele volta a conversa **e os arquivos** para aquele ponto | desfazer um prompt inteiro |
| `/context` | quanto da "memória" da conversa já foi usada | se passar de ~80%, `/clear` entre um prompt e outro |
| `/clear` | começa uma conversa nova. O `CLAUDE.md` continua valendo | entre o prompt 2 e o 3, se a conversa ficou longa |
| `/voice` | dita a mensagem em vez de digitar (se aparecer na sua versão) | `/voice` → fale → Enter |
| `/help` · `/exit` | a lista de todos os comandos · sair | |

**Os modos (o `Shift+Tab`):**

| Rodapé | Modo | Quando usar |
|---|---|---|
| (nada) | **normal**: pede licença a cada arquivo e a cada comando | para entender o que ele faz, passo a passo |
| `accept edits on` | edita arquivos sem perguntar; comando ainda pede licença | quando você já confia no plano |
| `plan mode on` | **só planeja**: lê, pensa e devolve um plano, sem mexer em nada | antes de um prompt grande (o prompt 1) |
| `auto mode` | faz tudo sozinho; um verificador barra o que for perigoso | depois de aprovar o plano |

**Não rode `/init`.** O `/init` escreve um `CLAUDE.md` novo, resumindo a pasta. O nosso já existe e
é o PRD do curso (o negócio, as sujeiras do dado, as armadilhas do Free Edition): o prompt 1 baixa
e lê esse arquivo. O `/init` jogaria isso fora.

**O ritmo da noite:**

1. **Prompt 1 em plan.** `Shift+Tab` até `plan mode on`, cole o prompt. Ele lê o `CLAUDE.md` e o
   bundle e devolve um plano. Leia com a turma: arrumou o bundle (sem `mode: development`, job
   `vertice_farol`, pausado)? Tirou a linha de TOTAL, as tarefas-resumo, a vírgula decimal? Se
   faltar algo, escreva a correção antes de aprovar.
2. **Aprove e vá para auto.** Ele executa sozinho até o deploy e o run.
3. **Quando o auto recusar** ("Credential Leakage", "Irreversible Deletion"): não é erro. Ele barrou
   um comando que mexe com chave ou apaga dado, e mostra qual é. Rode você, com `!` na frente.
4. **Prompts 2 a 4 direto em auto.** O plano do 1 ensinou o caminho.

### 3 · Os prompts 1 a 4, um de cada vez

Copie o prompt do arquivo, troque `<perfil>` pelo seu profile, cole no Claude Code e aprove os
comandos que ele pedir (leia antes). No fim de cada um, confira e salve no GitHub.

| # | Copie de | O Claude Code faz | Confira | Commit |
|---|---|---|---|---|
| 1 | [`prompt-01-silver.md`](claude-code/prd/prompt-01-silver.md) | a conferência da bronze e o pipeline `vertice_medalhao` com as 7 tabelas da silver | 9 `ok` · 4.917 tarefas · R$ 193,35 mi | `prompt 1: conferência e silver` |
| 2 | [`prompt-02-gold.md`](claude-code/prd/prompt-02-gold.md) | as 3 tabelas da gold e os 10 testes | 7 críticos · 4 melancias · R$ 6,47 mi | `prompt 2: gold e testes` |
| 3 | [`prompt-03-job-completo.md`](claude-code/prd/prompt-03-job-completo.md) | IA no status e o job inteiro, toda segunda às 6h | 6 caixas verdes em ~8 min · PRJ-011 `falta_sre` 12 semanas | `prompt 3: job completo` |
| 4 | [`prompt-04-dashboard.md`](claude-code/prd/prompt-04-dashboard.md) | o dashboard "Projeto Farol · Portfólio" no bundle | SPI 0,92 · CPI 0,97 · publique | `prompt 4: dashboard` |

```bash
git add . && git commit -m "prompt 1: conferência e silver" && git push
```

**O Claude Code recusou um comando por causa das chaves** (*"Credential Leakage"*, no modo
automático)? Não contorne: rode você mesmo, com `!` na frente, o comando que ele mostrar, por
exemplo `! databricks bundle deploy --profile DEFAULT`. O `!` roda na pasta onde o Claude Code
está, que já é a raiz: não precisa de `cd`.

### 4 · No fim, a prova

```bash
python3 scripts/run_sql.py verificacao.sql --profile DEFAULT
```

Baixe a [`99-verificacao.sql`](claude-code/prd/99-verificacao.sql) como `verificacao.sql`: são
20 linhas `ok`. Algum `CONFIRA`? Compare o arquivo com o [gabarito](claude-code/vertice).

---

## 📖 As palavras da noite (uma frase cada)

| Termo | Em uma frase |
|---|---|
| **Bundle** | o projeto inteiro (job, pipeline, dashboard) descrito em arquivos, com um `databricks.yml` na raiz. `bundle deploy` sobe tudo igual em qualquer workspace. |
| **`bundle generate`** | o caminho de volta: lê um job que já existe no workspace e escreve o YAML e os notebooks dele. |
| **Variável do bundle** | um valor que o YAML usa (`${var.s3_access_key_id}`) sem estar escrito nele. O segredo fica num arquivo fora do Git. |
| **Silver** | a camada limpa e tipada: cada sujeira da bronze resolvida uma vez, com regra escrita. |
| **Gold** | a camada que responde às perguntas: uma tabela por pergunta do dono, nem uma a mais. |
| **Pipeline declarativo** | você diz **o que** cada tabela é; o Lakeflow descobre a ordem, roda em paralelo o que dá e desenha o grafo. |
| **`EXPECT`** | uma regra da tabela. Se o dado violar, o pipeline para em vez de gravar errado. |
| **SPI e CPI** | prazo e custo. 1,0 é "no plano"; abaixo de 0,9 é atenção; abaixo de 0,8 é crítico. |
| **Melancia** | o projeto verde por fora e vermelho por dentro: farol do gerente verde, SPI abaixo de 0,9. |
| **`ai_classify` / `ai_extract`** | funções SQL de IA: a primeira escolhe uma causa numa lista fechada; a segunda tira campos (com tipo) de um texto. |
| **DAG** | o desenho do job: cada caixa é uma tarefa, cada seta diz quem espera quem. |

---

## 🏛️ Arquitetura

```
   data lake (Supabase)   API de feriados
            │                   │
            ▼                   ▼
 ┌──────── job vertice_farol · toda segunda às 6h ───────────────────────────────────────┐
 │ ingestao_data_lake ─┐                                                                  │
 │ ingestao_feriados ──┴─▶ conferencia_bronze ─▶ medalhao ─┬─▶ testes_de_qualidade        │
 │   (noite 2, agora       9 contagens             silver ×7  └─▶ status_com_ia            │
 │    como código)         ou raise_error          gold ×3        (regra + IA + MERGE)     │
 └────────────────────────────────────────────────────────────────────────────────────────┘
                                                      │
                                                      ▼
                                     dashboard "Projeto Farol · Portfólio"
```

O bundle tem 3 recursos: o job, o pipeline e o dashboard. O desenho detalhado, tabela por tabela,
está no [passo a passo](claude-code/README.md), na seção "O desenho do que você vai construir".

---

## ⏱️ Roteiro da noite (90 min)

| Bloco | Min | O quê |
|---|---:|---|
| Abertura | 8 | o job de ontem no workspace (verde às 6h); as 4 perguntas do dono ainda sem resposta; "o que mora num clique" |
| Passo 1 · o bundle à mão | 15 | `bundle init`, `bundle generate`, as chaves fora do Git; o `git status` limpo; pausar o job de ontem |
| Prompt 1 · silver | 20 | as 4 sujeiras com número (TOTAL, tarefas-resumo, vírgula, CodeForge); o grafo do pipeline; os `EXPECT` |
| Prompt 2 · gold + testes | 15 | de trás para frente: pergunta → KPI → grão → tabela; os 7 críticos e os R$ 6,47 mi; as SREs paradas |
| Prompt 3 · o job completo | 15 | a IA ao vivo em duas linhas; o PRJ-011; as 6 caixas verdes; o Repair run |
| Prompt 4 · dashboard | 10 | o SQL da noite 1 × o de hoje; publicar; o dono vê a Torre |
| Fecho | 7 | commit e push; o que vem amanhã (modelo, Genie, app) |

**Se atrasar:** o prompt 1 nunca é cortado (é a integração, a entrega mais importante). O prompt 4
vira demonstração com o gabarito (`python3 scripts/gerar_dashboard.py` + `bundle deploy`).

**Antes da aula (instrutor):** rode o reset da noite 3 (`claude-code/prd/00-reset.sh`), confira que
o job de ingestão da noite 2 está verde e que a bronze tem as 9 tabelas, e deixe o gabarito com o
`variable-overrides.json` pronto para o plano B.

---

## 🔢 O que deve aparecer na tela

| Métrica | Valor |
|---|---|
| Bronze conferida (9 tabelas) | projetos 60 · status 3.911 · Excel 1.663 · ClickUp 2.119 · Project 1.260 · RH 523 · timesheet 30.883 · custos 23.640 · entregas 640 |
| Tarefas na silver | 4.917 (Excel 1.643 · ClickUp 2.119 · MS Project 1.155) |
| Custo real total (silver = bronze) | R$ 193,35 mi |
| Projetos em andamento · críticos · em atenção | 41 · **7** · **10** |
| SPI · CPI da carteira | 0,92 · 0,97 |
| Estouro previsto (em andamento) | **R$ 6,47 mi** |
| Margem projetada | 20,4% |
| Melancias | 4: PRJ-012, PRJ-028, PRJ-034, PRJ-042 |
| SREs paradas (12 semanas) | COL0017 e COL0018, no PRJ-007, ~5,5% de uso |
| PRJ-011 nos últimos 90 dias | falta de SRE: 12 semanas, 57 dias de impacto |
| Status classificados por IA / regra / palavra-chave | 163 / 2.954 / 794 |
| CodeForge | prazo ×1,41, 0% no prazo, 5 entregas em atraso |

Tudo de uma vez: `python3 scripts/run_sql.py aulas/aula-03-modelagem-claude-code/claude-code/prd/99-verificacao.sql --profile DEFAULT` (20 × ok).

---

## 🗂️ Arquivos desta pasta

| Arquivo | Para que serve |
|---|---|
| [`claude-code/README.md`](claude-code/README.md) | o passo a passo: instalação do zero, o passo 1 e os prompts 1 a 4 prontos para copiar, o que conferir |
| [`claude-code/prd/`](claude-code/prd) | o passo 1 à mão e os prompts 1 a 4 (com o que mostrar, o que falar e "se der errado"), o `CLAUDE.md` da turma, a verificação e o reset |
| [`claude-code/vertice/`](claude-code/vertice) | **o gabarito**: o bundle completo, testado |
| [`claude-code/APRENDIZADOS.md`](claude-code/APRENDIZADOS.md) | o que falhou no Free Edition e como foi resolvido |

---

## ➡️ Amanhã

A Torre diz **quem já estourou**. A pergunta 4 do dono é outra: **o que vai dar errado no próximo
mês?** Amanhã o mesmo job ganha um modelo que avisa 41 dias antes, o dono ganha um Genie que acerta
as quatro perguntas em português, e a Torre ganha uma URL: o app. → [aula-04](../aula-04-produtos-de-dados-ia)
