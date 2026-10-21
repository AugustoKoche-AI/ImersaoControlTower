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

> **Enquanto cada prompt roda, leia com a turma:** prompt 1 · [a camada silver](#-enquanto-o-prompt-1-roda-a-camada-silver) ·
> prompt 2 · [a gold e os testes](#-enquanto-o-prompt-2-roda-a-camada-gold-e-os-testes) · prompt 3 · [o job e a IA](#️-enquanto-o-prompt-3-roda-o-job-e-a-ia-no-texto) ·
> prompt 4 · [o dashboard (e AI/BI × Power BI)](#-enquanto-o-prompt-4-roda-o-dashboard)

### 4 · No fim, a prova

```bash
python3 scripts/run_sql.py verificacao.sql --profile DEFAULT
```

Baixe a [`99-verificacao.sql`](claude-code/prd/99-verificacao.sql) como `verificacao.sql`: são
20 linhas `ok`. Algum `CONFIRA`? Compare o arquivo com o [gabarito](claude-code/vertice).

---

## 🥈 Enquanto o prompt 1 roda: a camada silver

O prompt 1 leva alguns minutos. Este é o roteiro para falar enquanto ele trabalha.

### Para que serve

| Camada | O que é | Analogia |
|---|---|---|
| **bronze** | o dado **como chegou**, com toda a sujeira. Ninguém mexe | a caixa de notas fiscais |
| **silver** | o dado **em que dá para confiar**: limpo, tipado, padronizado e integrado | a planilha organizada |
| **gold** | a **resposta** para a pergunta do negócio: KPIs, situação, ranking | o relatório do dono |

**A regra que resume tudo:** a silver tem o **mesmo grão** da bronze (uma linha por tarefa, por
lançamento de custo, por status semanal), só que confiável. Ela ainda **não responde pergunta**:
prepara o dado para a gold responder.

### O que pode e o que não pode na silver

| Operação | Na silver? | Exemplo da Vértice |
|---|---|---|
| **Mudar o tipo** (texto → data, texto → número) | ✅ É o trabalho principal | data em `yyyy-MM-dd` e `dd/MM/yyyy`; número de série do Excel; `'40h'`; `'PT40H0M0S'`; `12345,67` |
| **Padronizar texto** | ✅ Guardando o original ao lado | farol `Verde`/`VERDE`; ferramenta escrita de 8 jeitos; CodeForge de 4 jeitos; status do ClickUp de 12 jeitos |
| **UNION** (empilhar fontes) | ✅ Quando é o **mesmo assunto**, com o **mesmo contrato de colunas** | Excel + ClickUp + MS Project viram `silver.tarefas` |
| **JOIN** | ✅ Para **resolver chave** ou enriquecer a linha | o de-para do PMO diz que a lista 901200095028 do ClickUp é o PRJ-012 |
| **Tirar linha que não é dado** | ✅ Com regra escrita e teste | a linha de TOTAL da planilha; as tarefas-resumo do Project |
| **Deduplicar** | ✅ Com critério declarado | 523 linhas no RH → 520 pessoas |
| **Corrigir valor** | ⚠️ Só por regra, nunca à mão, e com flag | % acima de 100 vira 100, com `pct_veio_acima_de_100` |
| **Jogar fora o que parece estranho** | ❌ Sinalize | status vazio vira `status_vazio`; estorno negativo fica, com `estorno` |
| **Agregar** (SUM por projeto, média) | ❌ Vai para a gold | horas por projeto, custo por mês |
| **Regra de negócio** (SPI, crítico, melancia) | ❌ Vai para a gold | `situacao = 'crítico'` quando SPI < 0,8 |
| **Alterar a bronze ou a fonte** | ❌ Nunca | a sujeira é o retrato do processo; consertar a fonte esconde o problema |

### Boas práticas (as 8 que valem para qualquer projeto)

1. **Mesmo grão da bronze.** Se a silver já soma, você perdeu o detalhe que a próxima pergunta vai pedir.
2. **Guarde o original ao lado.** `ferramenta_como_veio`, `fornecedor_como_veio`, `valor_veio_com_virgula`:
   quando alguém duvidar do número, você mostra de onde veio.
3. **Flag em vez de DELETE.** Linha descartada em silêncio é dinheiro sumindo sem ninguém saber.
4. **Cuidado com o `try_cast`.** Ele "funciona": devolve nulo em vez de erro. Na Vértice, o
   `try_cast` jogaria fora 671 lançamentos com vírgula decimal, R$ 5,4 milhões, sem um aviso.
5. **Teste de conservação.** O que entra tem que sair: custo da silver = custo da bronze
   (R$ 193,35 mi); horas de cada planilha = a linha de TOTAL dela.
6. **Contrato na tabela, não no script.** `CONSTRAINT ... EXPECT (...) ON VIOLATION FAIL UPDATE`:
   se amanhã aparecer "Planilha Google" como ferramenta, o pipeline para em vez de gravar nulo.
7. **Data fixa, nunca `current_date()`.** "Hoje" é 16/10/2026: o número não pode mudar sozinho de um dia para o outro.
8. **`COMMENT` em toda tabela e coluna.** É o que o Genie e o próximo analista vão ler.

### O que ela faz aqui (as 7 tabelas)

| Tabela | O que a silver faz | Confira |
|---|---|---|
| `projetos` | o cadastro do PMO e o **de-para** da integração: datas em 2 formatos, ferramenta de 8 jeitos, código vazio | 60 projetos |
| `tarefas` | **as 3 ferramentas viram uma**: 3 visões com as mesmas colunas e um `UNION ALL`. Excel (sem TOTAL, data de série, `%` de 3 jeitos, `h`), ClickUp (milissegundos, `custom_fields`, 12 status), Project (sem resumo, fase pelo `OutlineLevel`, `PT40H`) | **4.917** (Excel 1.643 · ClickUp 2.119 · Project 1.155) · 11 com % acima de 100 |
| `status_semanal` | farol padronizado, status vazio sinalizado (não descartado) | 3.911 status |
| `custos` | vírgula decimal recuperada, estorno mantido e sinalizado | **R$ 193,35 mi**, igual à bronze · 671 com vírgula |
| `colaboradores` | os 3 cadastros duplicados viram 1 | 520 pessoas |
| `apontamentos` | o timesheet tipado: horas disponíveis × apontadas | |
| `entregas_fornecedor` | a CodeForge de 4 grafias vira 1 fornecedor; prazo real e prometido em dias; `em_atraso` | 5 entregas em atraso, todas da CodeForge |

### Por que um pipeline declarativo

Cada arquivo diz **o que** a tabela é (`CREATE OR REFRESH MATERIALIZED VIEW silver.tarefas AS ...`), não
**como** rodar. O Lakeflow lê os `FROM`, descobre a ordem (primeiro `projetos`, porque `tarefas` depende
do de-para), roda em paralelo o que dá e desenha o grafo. Ninguém escreve orquestração.

### As perguntas que a turma faz

- **"Por que não limpar direto na planilha ou no gerador?"** Porque amanhã chega uma planilha nova
  com a mesma sujeira. A regra na silver vale para sempre; a correção à mão vale uma vez.
- **"O JOIN com o cadastro não é coisa da gold?"** O JOIN que **resolve a chave** (qual projeto é
  esta tarefa) é silver. O JOIN que **monta a resposta** (custo × orçamento por cliente) é gold.
- **"Por que materialized view e não tabela?"** Porque o pipeline recalcula sozinho quando a bronze
  muda. Tabela comum precisaria de alguém para mandar atualizar.
- **"E se uma regra falhar?"** O `EXPECT ... FAIL UPDATE` para o pipeline e diz qual regra e quantas
  linhas. Melhor parar do que gravar número errado.

---

## 🥇 Enquanto o prompt 2 roda: a camada gold e os testes

### Para que serve

A silver é o dado **confiável**. A gold é o dado **útil**: modelado para responder uma pergunta de
negócio, com a regra de negócio já aplicada. Quem abre a gold (o dashboard, o Genie, o app, o
diretor no SQL) não precisa saber que o Excel tinha linha de TOTAL: encontra o SPI pronto.

**A regra que resume tudo:** cada tabela gold existe por causa de uma pergunta. Se ninguém pergunta,
ela não existe.

### O que pode e o que não pode na gold

| Operação | Na gold? | Exemplo da Vértice |
|---|---|---|
| **Agregar** (SUM, COUNT, por projeto, por semana) | ✅ É o trabalho principal | horas e custo por projeto e semana |
| **Regra de negócio** | ✅ Escrita uma vez, num lugar só | `crítico` se SPI ou CPI < 0,8; `atenção` se < 0,9; melancia |
| **JOIN que monta a resposta** | ✅ | cadastro + tarefas + custos → a fotografia do projeto |
| **Mudar o grão** | ✅ Declarando o novo grão | de "uma linha por tarefa" para "uma linha por projeto e semana" |
| **Desnormalizar** (a tabela larga) | ✅ Quando simplifica quem consome | `projeto_situacao_atual` já traz cliente, gerente, contrato e KPIs: sem `dim_projeto` |
| **Limpar dado** | ❌ Volta para a silver | se a gold precisa de `replace(',', '.')`, a silver falhou |
| **Ler da bronze** | ❌ Só da silver | senão a limpeza fica duplicada e diverge |
| **Média de razão** | ❌ Razão das somas | SPI da carteira = `SUM(ev) / SUM(pv)`, não `AVG(spi)`: o projeto pequeno não pesa igual ao grande |

### As 3 tabelas: fotografia, filme e pessoas

| Tabela | Grão | Responde | Confira |
|---|---|---|---|
| `projeto_situacao_atual` | 1 linha por projeto, **hoje** (a fotografia) | perguntas 1 e 2: quem atrasa, de qual cliente, quanto custa | 7 críticos · 10 atenção · 4 melancias · **R$ 6,47 mi** |
| `fato_projeto_semana` | 1 linha por projeto e **semana** (o filme) | desde quando o projeto piora; a tendência do SPI e do CPI | a curva do CPI caindo a partir do 6º mês |
| `utilizacao_pessoa_semana` | 1 linha por pessoa, projeto e semana | pergunta 3: tenho gente parada? | COL0017 e COL0018 a ~5% no PRJ-007 |

**Por que fotografia e filme separados?** As ferramentas só guardam o % de **hoje**. O histórico vem
do status semanal de cada sexta. A fotografia usa as tarefas (mais preciso hoje); o filme usa o
status (o único com passado). O teste 9 garante que os dois contam a mesma história hoje.

### Os 10 testes: melhor o job falhar do que o diretor ver número errado

Os testes rodam depois do pipeline, como uma tarefa do job. Cada um termina em `raise_error()` se
falhar, e o job fica vermelho.

| Tipo | Testes | O que protege |
|---|---|---|
| **Integração** | 1 · 60 projetos têm cronograma · 2 · cada projeto veio de uma ferramenta só | nenhum projeto sumiu ou duplicou na `UNION` |
| **Conservação** | 3 · horas do Excel = linhas de TOTAL · 6 · custo da silver = custo da bronze · 10 · AC do fato = soma dos lançamentos | a limpeza não criou nem sumiu com dado |
| **Unicidade** | 4 · uma linha por pessoa · 5 · a CodeForge virou 1 fornecedor | dedup e padronização funcionaram |
| **Completude** | 7 · 60 fotografias · 8 · todo projeto em andamento tem SPI e CPI | nenhum KPI nulo no dashboard |
| **Coerência** | 9 · EV do status = EV das ferramentas (< 1%) | fotografia e filme não se contradizem |

**`EXPECT` × teste:** o `EXPECT` olha **uma linha** de cada vez ("esta data não é nula"). O teste olha
**a tabela inteira** ("a soma bate", "são 60"). Os dois juntos fecham o contrato.

---

## ⚙️ Enquanto o prompt 3 roda: o job e a IA no texto

### O job: quem roda o quê, em que ordem, e quando

| Conceito | No `vertice_farol` |
|---|---|
| **DAG** (o desenho das dependências) | ingestões em paralelo → conferência → medalhão → testes e IA em paralelo |
| **Dependência** (`depends_on`) | o medalhão só começa com a bronze conferida; a IA só lê a silver pronta |
| **Paralelo** | duas tarefas que não leem uma à outra rodam juntas: os testes não esperam a IA |
| **Agendamento** | toda segunda às 6h (America/Sao_Paulo); no dev fica **pausado** |
| **`max_concurrent_runs: 1`** | duas execuções ao mesmo tempo apagariam a bronze uma da outra |
| **Repair run** | falhou a IA? Refaz só ela e o que vem depois. A ingestão de 3 minutos não roda de novo |

**O DAG é a documentação.** Quem abre o job vê, sem ler código, o caminho do dado da planilha até o
dashboard, e o tempo de cada etapa.

### A IA dentro do SQL

`ai_classify` e `ai_extract` são funções de SQL, como `upper()`: recebem um texto e devolvem uma
coluna. Sem endpoint, sem Python, sem chave de API.

| Função | Faz | Exemplo |
|---|---|---|
| `ai_classify` | **escolhe** uma opção de uma lista fechada | "Sem SRE alocado: pipeline quebrado" → `falta_sre` |
| `ai_extract` | **tira** campos do texto, já tipados (versão 2.0 com JSON schema) | "Impacto estimado: 1 semana" → `dias_impacto = 7` |

### Boas práticas de IA em dados

1. **IA custa por linha.** ~5 s por status neste workspace: os 3,9 mil levariam uma hora.
2. **Cada ferramenta onde ela é a certa:** **regra** para o que tem padrão fixo (três em cada quatro
   status dizem "sem bloqueios"), **IA** só nos 163 textos com bloqueio dos últimos 90 dias (~2 min),
   **palavra-chave** no histórico antigo, onde a resposta não muda decisão.
3. **Incremental (`MERGE` só do que é novo).** A tabela acumula: na semana que vem a IA lê só os
   status da semana que vem. A conta não se paga duas vezes.
4. **Lista fechada.** `ai_classify` com 8 causas permite `GROUP BY`. Texto livre da IA não agrupa.
5. **Guarde o método.** A coluna `metodo` (`regra`, `ia`, `palavra_chave`) diz de onde veio cada
   resposta: quando alguém duvidar, você sabe qual conferir.

---

## 📊 Enquanto o prompt 4 roda: o dashboard

### Para que serve um dashboard (e para que não serve)

| Serve para | Não serve para |
|---|---|
| **acompanhar** o mesmo conjunto de números, toda semana | responder uma pergunta nova (isso é o Genie, amanhã) |
| **comparar** (projeto × projeto, semana × semana, meta × real) | explorar o dado sem saber o que procura |
| **alertar** com cor: crítico em vermelho, melancia na tabela | substituir a regra de negócio: ela mora na gold |

**Boas práticas:** uma página por pergunta do dono, com a pergunta escrita no título; KPI no topo,
detalhe embaixo; razão das somas, nunca média de razão; cor com significado (vermelho = crítico,
não "bonito"); a gold faz a conta e o gráfico só mostra (o SQL de cada gráfico cabe em 5 linhas).

### Dashboard do Databricks (AI/BI) × Power BI

| | **AI/BI (Databricks)** | **Power BI** |
|---|---|---|
| **Onde o dado mora** | lê direto a gold, no SQL warehouse. Não copia o dado | importa uma cópia (modo Import) ou consulta o Databricks pelo conector (DirectQuery) |
| **Atualização** | o job recalcula a gold às 6h: o dashboard já mostra | o refresh do dataset é mais um agendamento para manter |
| **Permissão** | a do Unity Catalog: quem não pode ler a tabela não vê o gráfico | um segundo modelo de permissão (workspace, RLS no modelo) |
| **Como código** | o JSON vai no bundle, com diff, revisão e deploy para dev e prod | o `.pbix` é binário; o formato de projeto (PBIP) melhora, mas é outro fluxo |
| **Linhagem** | do gráfico até a planilha da bronze, no mesmo catálogo | termina no conector: o caminho dentro do Databricks fica de fora |
| **Pergunta em português** | o Genie usa as mesmas tabelas e os mesmos `COMMENT` | Copilot, com outra licença e outro modelo semântico |
| **Licença** | vem com o workspace (paga o warehouse que roda a query) | licença por usuário (Pro/PPU) ou capacidade (Fabric) |
| **Onde o Power BI ganha** | | visuais mais ricos e customizáveis, DAX e modelagem semântica madura, Excel e Teams, a ferramenta que a área de negócio já conhece |

**A resposta honesta para a turma:** não é um ou outro. Se a empresa já vive no Power BI, ele lê a
mesma gold pelo conector, e o trabalho da noite vale do mesmo jeito. O AI/BI ganha quando o time
de dados quer **um lugar só**: o dado, a regra, a permissão, o dashboard e o código no mesmo bundle,
sem uma cópia do dado para manter sincronizada.

---

## 💡 Mais dicas para levar para o trabalho

### Medalhão: bronze, silver, gold

- **Não é obrigatório ter as três.** É um jeito de separar responsabilidades: guardar (bronze),
  confiar (silver), responder (gold). Projeto pequeno pode ter só duas.
- **Um schema por camada** (`bronze`, `silver`, `gold`) facilita a permissão: o analista recebe
  `SELECT` só na gold; a engenharia, nas três.
- **A bronze é reprocessável.** Se a regra da silver mudar, recalcula tudo a partir da bronze. Por
  isso ninguém mexe nela.
- **Cada camada lê só a anterior.** Gold lendo bronze é limpeza duplicada que vai divergir.

### Data mart: a gold de uma área

- **Data mart** é o pedaço da gold feito para **uma área** da empresa: PMO, financeiro, RH. Cada
  um com as suas tabelas, a sua linguagem e as suas permissões.
- Aqui a gold inteira é o **mart do PMO**. Se o financeiro pedir o dele amanhã, nasce um schema
  `gold_financeiro` lendo a **mesma silver**: a limpeza é feita uma vez e serve aos dois.
- **Estrela × tabela larga.** O modelo estrela (uma fato no meio, dimensões em volta: `dim_projeto`,
  `dim_pessoa`) é o clássico do BI e brilha quando muitas fatos dividem as mesmas dimensões. A
  **tabela larga** (*one big table*, como a `projeto_situacao_atual`) é mais simples de consultar e é
  a que o Genie e o dashboard entendem melhor. Com 60 projetos, a larga ganha.
- **Grão escrito no `COMMENT`.** "Uma linha por projeto e semana" no comentário da tabela evita o
  erro mais comum de BI: somar o que não se soma.

### Pipelines (Lakeflow Spark Declarative Pipelines)

- **Materialized view × streaming table.** A MV recalcula o resultado (bom para dado que muda inteiro,
  como a bronze recarregada). A streaming table processa só o que chegou de novo (bom para log,
  evento, arquivo que só acumula).
- **`EXPECT` tem três níveis:** só registrar (`EXPECT`), descartar a linha (`ON VIOLATION DROP ROW`)
  ou parar tudo (`ON VIOLATION FAIL UPDATE`). Dado que vai para o diretor: `FAIL UPDATE`.
- **O event log é o primeiro lugar para olhar.** O erro que importa é o **primeiro**; os seguintes
  costumam ser consequência.
- **Full refresh** recalcula do zero. Use quando mudar a regra de uma tabela que acumula.

### Jobs (Lakeflow Jobs)

- **Tipos de tarefa:** notebook, SQL (no warehouse), pipeline, script Python, dbt, e as de controle:
  `if/else`, `for each` e "rodar outro job".
- **Gatilhos além do horário:** chegada de arquivo num volume, atualização de tabela, ou contínuo.
  "Toda segunda às 6h" é o mais simples, não o único.
- **Por tarefa:** `max_retries` (tentar de novo sozinho), `timeout_seconds` (não deixar rodar para
  sempre) e notificação por e-mail na falha. Configure no mínimo a notificação.
- **Parâmetros do job** (`${var.…}` no bundle, `{{job.parameters.x}}` na tarefa): o mesmo job roda
  para dev e prod mudando só o valor.
- **Repair run** refaz só o que falhou. **`max_concurrent_runs: 1`** evita duas execuções brigando
  pela mesma tabela.
- **Histórico em SQL:** as tabelas de sistema (`system.lakeflow.job_run_timeline`) mostram tempo e
  resultado de cada execução, para montar o seu próprio painel de saúde dos jobs.

### Dashboards (AI/BI)

- **Dataset e gráfico são coisas separadas.** Uma query (dataset) alimenta vários gráficos. Menos
  queries, menos custo de warehouse e números coerentes entre si.
- **Filtros e parâmetros:** um filtro de cliente ou segmento no topo vale para a página inteira; o
  clique num gráfico filtra os outros (*cross-filter*).
- **Rascunho × publicado.** Você edita o rascunho; o diretor vê o publicado. Ao publicar, escolha se
  quem vê usa **as suas credenciais** (vê o mesmo que você) ou **as dele** (vale a permissão do Unity
  Catalog de cada um).
- **Agendamento e assinatura:** o dashboard publicado pode atualizar sozinho e mandar um PDF por
  e-mail toda segunda, depois do job.
- **Edite no código, não na tela.** Mudou no workspace, o próximo `bundle deploy` recusa
  ("modified remotely"). A mudança vai para o script que gera o JSON.

### Unity Catalog: a cola de tudo

- **Linhagem:** abra a `gold.projeto_situacao_atual` no Catalog Explorer, aba **Lineage**, e veja o
  caminho até as planilhas da bronze, sem ninguém ter desenhado.
- **`COMMENT` é documentação viva:** aparece no Catalog Explorer, no dashboard e é o que o Genie lê
  amanhã.
- **`GRANT` por camada:** `GRANT SELECT ON SCHEMA lakehouse_vertice.gold TO analistas`. A silver e a
  bronze ficam com quem constrói.

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
