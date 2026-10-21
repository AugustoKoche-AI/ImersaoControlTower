# 🏗️ Noite 3 · Engenheiro de Dados com Claude Code | Imersão Jornada de Dados

**Quarta, 21/10/2026, 19h30.**

**Ao fim desta noite**, a Torre de Controle da Vértice roda sozinha, toda segunda às 6h: busca os
arquivos no data lake, confere se chegaram inteiros, junta Excel, ClickUp e MS Project numa tabela
só, calcula os KPIs com teste, lê a causa de cada atraso no texto do status e atualiza um
**dashboard** que o dono abre. Tudo como código, num repositório seu no GitHub.

> **Formato:** o passo 1 à mão, com a CLI do Databricks (o bundle nasce num repositório novo), e
> os prompts 2 a 5 no Claude Code. Um deploy por passo, um bundle só (`vertice`).
> **Ponto de partida:** o job de ingestão que a turma montou **clicando** na noite 2. No passo 1 ele
> vira código; no prompt 5 o job inteiro alimenta o dashboard.
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
| 1 | **O bundle, à mão** (CLI) | repositório novo com `bundle init`, o job de ontem importado (`bundle generate`), as chaves fora do Git | 2 caixas verdes no DAG · `git status` sem nenhuma chave |
| 2 | **Conferência + silver** | a conferência das 9 tabelas da bronze e o pipeline `vertice_medalhao`: as 3 ferramentas viram `silver.tarefas`, mais 6 tabelas limpas, com `EXPECT` | 9 `ok` · **4.917 tarefas** (Excel 1.643 · ClickUp 2.119 · Project 1.155) · custo R$ 193,35 mi, igual à bronze |
| 3 | **Gold + testes** | `projeto_situacao_atual`, `fato_projeto_semana`, `utilizacao_pessoa_semana` e 10 testes que quebram o job | **7 críticos, 10 em atenção, 4 melancias, R$ 6,47 mi** de estouro previsto |
| 4 | **O job completo** | `status_estruturado` (IA no texto do status) e o job inteiro, de ponta a ponta, toda segunda às 6h | **6 caixas verdes** · PRJ-011: falta de SRE, 12 semanas, 57 dias |
| 5 | **O dashboard** | "Projeto Farol · Portfólio", 3 páginas, como código no bundle | SPI 0,92 · CPI 0,97 · as SREs paradas · a CodeForge ×1,41 |

---

## 🪜 O passo a passo da noite

**A premissa:** o catálogo `lakehouse_vertice` e a bronze já existem (noites 1 e 2), e o job de
ingestão da noite 2 está no workspace. Hoje nada disso é recriado: um **repositório novo**, vazio,
ganha o bundle, e o bundle passa a cuidar do job, que continua lendo e gravando no mesmo catálogo.

### 0 · Confira o ponto de partida (2 min)

```bash
databricks auth profiles                     # o seu profile com Valid: YES
databricks experimental aitools tools query "SHOW TABLES IN lakehouse_vertice.bronze" --profile <perfil>
# 10 tabelas: as 9 da noite 1 + feriados
databricks jobs list --profile <perfil>      # o job de ingestão da noite 2 está aqui
```

Login vencido? `databricks auth login --profile <perfil>`. Instalação do zero (editor, Git, CLI,
Claude Code): [passos 1 a 9 do passo a passo completo](claude-code/README.md#-antes-do-prompt-1-o-passo-a-passo-do-zero).

### 1 · O bundle, à mão, com a CLI (15 min, sem Claude Code)

O passo a passo completo, testado, está em [`passo-01-bundle-na-mao.md`](claude-code/prd/passo-01-bundle-na-mao.md).
O resumo:

```bash
cd ~/projetos
databricks bundle init default-minimal --profile <perfil>     # nome: vertice
cd vertice && git init -b main
curl -fsSL -o CLAUDE.md https://raw.githubusercontent.com/lvgalvao/ImersaoControlTower/main/aulas/aula-03-modelagem-claude-code/claude-code/prd/CLAUDE.md
mkdir -p scripts && curl -fsSL -o scripts/run_sql.py https://raw.githubusercontent.com/lvgalvao/ImersaoControlTower/main/scripts/run_sql.py

# databricks.yml: troque pelo do passo 2 do arquivo (sem mode: development, com as variáveis)

databricks jobs list --profile <perfil>                        # o id do job de ontem
databricks bundle generate job --existing-job-id <id> --profile <perfil>
mv "resources/ingestão.job.yml" resources/vertice.job.yml
# no YAML: vertice_farol, ingestao_feriados, ingestao_data_lake, ${var.s3_...}, PAUSED

mkdir -p .databricks/bundle/dev                                # as chaves, fora do Git
echo '{"s3_access_key_id": "...", "s3_secret_access_key": "..."}' > .databricks/bundle/dev/variable-overrides.json

databricks bundle validate --profile <perfil>
databricks bundle deploy   --profile <perfil>
databricks bundle run vertice_farol --profile <perfil>        # 2 caixas verdes, ~3 min

gh repo create projeto-farol --public --source=. --remote=origin
git add . && git commit -m "passo 1: o job de ontem vira código" && git push -u origin main
```

Confira: `git status` não mostra a `.databricks/`, e o job "Ingestão" de ontem fica **pausado**
(dois jobs recarregando a mesma bronze às 6h brigam).

### 2 · Abra o Claude Code na raiz

```bash
databricks aitools install --agents claude-code --scope project --skills-only --experimental
claude
```

Sempre na raiz do repositório `vertice`: é dali que todo comando roda.

### 3 · Os prompts 2 a 5, um de cada vez

Copie o prompt do arquivo, troque `<perfil>` pelo seu profile, cole no Claude Code e aprove os
comandos que ele pedir (leia antes). No fim de cada um, confira e salve no GitHub.

| # | Copie de | O Claude Code faz | Confira | Commit |
|---|---|---|---|---|
| 2 | [`prompt-02-silver.md`](claude-code/prd/prompt-02-silver.md) | a conferência da bronze e o pipeline `vertice_medalhao` com as 7 tabelas da silver | 9 `ok` · 4.917 tarefas · R$ 193,35 mi | `prompt 2: conferência e silver` |
| 3 | [`prompt-03-gold.md`](claude-code/prd/prompt-03-gold.md) | as 3 tabelas da gold e os 10 testes | 7 críticos · 4 melancias · R$ 6,47 mi | `prompt 3: gold e testes` |
| 4 | [`prompt-04-job-completo.md`](claude-code/prd/prompt-04-job-completo.md) | IA no status e o job inteiro, toda segunda às 6h | 6 caixas verdes em ~8 min · PRJ-011 `falta_sre` 12 semanas | `prompt 4: job completo` |
| 5 | [`prompt-05-dashboard.md`](claude-code/prd/prompt-05-dashboard.md) | o dashboard "Projeto Farol · Portfólio" no bundle | SPI 0,92 · CPI 0,97 · publique | `prompt 5: dashboard` |

```bash
git add . && git commit -m "prompt 2: conferência e silver" && git push
```

**O Claude Code recusou um comando por causa das chaves** (*"Credential Leakage"*, no modo
automático)? Não contorne: rode você mesmo, com `!` na frente, o comando que ele mostrar, por
exemplo `! databricks bundle deploy --profile <perfil>`. O `!` roda na pasta onde o Claude Code
está, que já é a raiz: não precisa de `cd`.

### 4 · No fim, a prova

```bash
python3 scripts/run_sql.py verificacao.sql --profile <perfil>
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
| Prompt 2 · silver | 20 | as 4 sujeiras com número (TOTAL, tarefas-resumo, vírgula, CodeForge); o grafo do pipeline; os `EXPECT` |
| Prompt 3 · gold + testes | 15 | de trás para frente: pergunta → KPI → grão → tabela; os 7 críticos e os R$ 6,47 mi; as SREs paradas |
| Prompt 4 · o job completo | 15 | a IA ao vivo em duas linhas; o PRJ-011; as 6 caixas verdes; o Repair run |
| Prompt 5 · dashboard | 10 | o SQL da noite 1 × o de hoje; publicar; o dono vê a Torre |
| Fecho | 7 | commit e push; o que vem amanhã (modelo, Genie, app) |

**Se atrasar:** o prompt 2 nunca é cortado (é a integração, a entrega mais importante). O prompt 5
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

Tudo de uma vez: `python3 scripts/run_sql.py aulas/aula-03-modelagem-claude-code/claude-code/prd/99-verificacao.sql --profile <perfil>` (20 × ok).

---

## 🗂️ Arquivos desta pasta

| Arquivo | Para que serve |
|---|---|
| [`claude-code/README.md`](claude-code/README.md) | o passo a passo: instalação do zero, o passo 1 e os prompts 2 a 5 prontos para copiar, o que conferir |
| [`claude-code/prd/`](claude-code/prd) | o passo 1 à mão e os prompts 2 a 5 (com o que mostrar, o que falar e "se der errado"), o `CLAUDE.md` da turma, a verificação e o reset |
| [`claude-code/vertice/`](claude-code/vertice) | **o gabarito**: o bundle completo, testado |
| [`claude-code/APRENDIZADOS.md`](claude-code/APRENDIZADOS.md) | o que falhou no Free Edition e como foi resolvido |

---

## ➡️ Amanhã

A Torre diz **quem já estourou**. A pergunta 4 do dono é outra: **o que vai dar errado no próximo
mês?** Amanhã o mesmo job ganha um modelo que avisa 41 dias antes, o dono ganha um Genie que acerta
as quatro perguntas em português, e a Torre ganha uma URL: o app. → [aula-04](../aula-04-produtos-de-dados-ia)
