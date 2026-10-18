# 📊 Noite 1 · Analista | Imersão Databricks + Claude Code

> **Segunda, 19/10, 19h30** · 📺 gravação: _link após a live_
>
> **A cena:** você era engenheiro de dados e acaba de ser promovido a **CTO da Vértice Tecnologia**
> (520 pessoas, 60 projetos de clientes). O dono te chama e pergunta: *"quais projetos estão atrasados?"*
> Ninguém sabe: 20 projetos vivem em planilhas Excel, 25 no ClickUp e 15 no MS Project.
>
> **Pergunta da noite:** *"Quais projetos estão atrasados, e quanto isso custa?"*
> **Você sai com:** as três ferramentas lidas pelo Databricks sem converter nada, o primeiro ranking de
> atraso da carteira inteira, o estouro previsto em reais, o seu primeiro dashboard e um Genie que erra.
> **Conexão:** o rascunho que você junta à mão hoje é o que a [noite 2](../aula-02-engenheiro) integra
> num pipeline. O Genie que erra hoje é o que a noite 2 conserta.

Hoje é tudo **pelo navegador**. Nada para instalar. É a noite de ver **o Databricks inteiro**: catálogo,
volume, SQL, dashboard e Genie.

---

## 🎯 Objetivos da noite

| # | Objetivo | Como você sabe que chegou lá |
|---|---|---|
| 1 | Montar o ambiente no Databricks Free Edition | catálogo `lakehouse_vertice` com `bronze`, `silver`, `gold` e o volume `raw` |
| 2 | Ler Excel, JSON e XML com o mesmo comando | 13 tabelas na bronze, contagens iguais às do `99-verificacao.sql` |
| 3 | Encontrar a sujeira antes que ela vire decisão | os 12 achados do exemplo 03 |
| 4 | Juntar as três ferramentas e responder o dono | SPI dos 41 projetos em andamento (exemplo 05) |
| 5 | Traduzir KPI em dinheiro, e desconfiar do farol | R$ 6,47 mi de estouro previsto e 4 projetos "melancia" (exemplo 06) |
| 6 | Colocar a resposta numa tela e ver o Genie errar | dashboard publicado + as 4 perguntas do dono no Genie da bronze |

---

## 🛠️ Passo a passo

### 1. Crie a conta (5 min)

[databricks.com/learn/free-edition](https://www.databricks.com/learn/free-edition): sem cartão. Tudo roda em **serverless**: você não cria cluster.

### 2. Traga o repositório para dentro do Databricks (2 min)

**Workspace → Create → Git folder** → cole `https://github.com/lvgalvao/ImersaoControlTower` → **Create Git folder**.

O repositório inteiro aparece no seu workspace, inclusive o gerador de dados.

### 3. Gere os dados direto no volume (3 min)

Abra `aulas/aula-01-analista/00-carregar-dados` e clique **Run all**. O notebook:

1. roda o [`00-setup-catalogo.sql`](00-setup-catalogo.sql): catálogo, 3 schemas e o volume `bronze.raw`;
2. roda o [`material/gerar_dataset.py`](../../material/gerar_dataset.py) escrevendo em `/Volumes/lakehouse_vertice/bronze/raw/`;
3. roda o [`material/validar_padroes.py`](../../material/validar_padroes.py), que junta as três ferramentas em Python e
   confere os 5 padrões da história. Termina com `TODOS OS PADRÕES OK`.

> **Prefere fazer à mão?** Rode `00-setup-catalogo.sql` no SQL Editor, gere os dados no seu computador
> (`python3 material/gerar_dataset.py --saida ./dados`) e suba cada pasta com **Upload to this volume**
> mantendo a estrutura `raw/<sistema>/<arquivo>`.

### 4. Crie a bronze (2 min)

Abra [`01-ingestao-bronze.sql`](01-ingestao-bronze.sql) no **SQL Editor**, selecione tudo e rode. A última query mostra as 13 tabelas com as linhas de cada uma.

### 5. Confira (1 min)

Rode o exemplo 05 (ele cria o rascunho que a verificação usa) e depois [`99-verificacao.sql`](99-verificacao.sql). As 22 linhas devem dar `ok`.

---

## 🗄️ O dado: Vértice Tecnologia

Empresa de tecnologia que desenvolve e implanta sistemas para grandes clientes: **60 projetos** (41 em andamento),
**R$ 305,2 mi** de carteira (R$ 208,6 mi em andamento), **520 pessoas**, clientes de varejo, financeiro, saúde,
logística e indústria. O "hoje" do dataset é **16/10/2026**.

```
Volume /Volumes/lakehouse_vertice/bronze/raw
├── pmo/          projetos · status_semanal        (cadastro do PMO e o status de toda sexta, em texto livre)
├── excel/        20 planilhas .xlsx               (uma por projeto, cada gerente do seu jeito)
├── clickup/      25 exports .json da API          (uma lista por projeto, tarefas dentro)
├── msproject/    15 arquivos .xml                 (uma <Task> por tarefa, com fases e baseline)
├── rh/           colaboradores · alocacoes
├── timesheet/    apontamentos                     (horas disponíveis × apontadas, por pessoa e semana)
├── financeiro/   custos
├── compras/      entregas_fornecedor · contratos_capacidade · consumo_capacidade
├── incidentes/   postmortems                      (texto livre)
└── documentos/   contratos/*.pdf (8) · manual/manual_de_tecnologias.pdf
```

| Tabela | Linhas | O que é | ⚠️ Cuidado |
|---|---:|---|---|
| `projetos` | 60 | cadastro do PMO: cliente, valor, prazo e **em qual ferramenta** o projeto vive | `data_inicio` em 2 formatos; ferramenta escrita de 8 jeitos; 2 projetos sem código |
| `status_semanal` | 3.911 | avanço, farol e bloqueios de cada sexta | farol do gerente é otimista; textos vazios |
| `excel_tarefas` | 1.663 | as 20 planilhas | data em texto **ou** número de série; % como "45%" ou 0.45; linha de TOTAL; % > 100 |
| `clickup_tarefas` | 2.119 | as 25 listas do ClickUp | datas em milissegundos; status escrito de 12 jeitos; % dentro de uma lista de campos |
| `msproject_tarefas` | 1.260 | os 15 cronogramas do Project | horas em `PT40H0M0S`; 105 tarefas-resumo que somam as de baixo |
| `colaboradores` | 523 | as 520 pessoas | 3 pessoas duplicadas |
| `alocacoes` | 517 | quem está em qual projeto, e quando | |
| `apontamentos` | 30.883 | horas disponíveis × apontadas por semana | hora extra (> 100%) é legítima |
| `custos` | 23.640 | lançamentos de custo real | 671 com vírgula decimal; estornos negativos |
| `entregas_fornecedor` | 640 | entregas das consultorias: prometido × entregue | a CodeForge escrita de 4 jeitos |
| `contratos_capacidade` | 93 | banco de horas de consultoria e créditos de cloud | |
| `consumo_capacidade` | 6.070 | saldo semanal de cada contrato | saldos negativos (erro de lançamento) |
| `postmortems` | 101 | relato de cada incidente em produção | texto livre |

> **Por que CSV e Excel entram como texto?** Se o Databricks adivinhasse os tipos, `14/03/2025` virava nulo,
> `12345,67` virava erro e o número de série do Excel virava um número qualquer. A bronze preserva o problema
> para que ele seja resolvido, não escondido. JSON e XML entram com a estrutura inferida: é ela que diz o que
> está dentro de quê.

### Os 5 padrões que o dado esconde (a história da semana)

1. **8 projetos com CPI caindo a partir do 6º mês**: o cliente pede mais, o time faz, ninguém cobra o aditivo.
2. **O change freeze da Black Friday** (01/11 a 10/01) trava os 3 projetos de e-commerce (PRJ-003, PRJ-011, PRJ-024).
3. **A consultoria CodeForge** entrega com prazo **41% acima** do prometido, e aparece escrita de 4 jeitos.
4. **Dois SREs seniores ociosos no PRJ-007**, que ainda está no desenho, enquanto o status do PRJ-011 pede SRE toda semana.
5. **Dois squads com rotatividade alta** (PRJ-016 e PRJ-030): os dois piores SPI da carteira.

Hoje você vê os sintomas (atraso, estouro e o farol que não bate). As causas aparecem nas noites 2 e 4.

---

## 🎯 Os 6 exemplos

Cada exemplo usa o anterior. Rode no SQL Editor ou use os notebooks (veja abaixo).

| # | Arquivo | Conceito | Pergunta de negócio |
|---|---|---|---|
| 01 | [`exemplo-01-primeiro-select.sql`](exemplo-01-primeiro-select.sql) | `SELECT`, `LIMIT`, `COUNT` | Que projetos a Vértice tem? Como é cada ferramenta por dentro? |
| 02 | [`exemplo-02-order-by-e-distinct.sql`](exemplo-02-order-by-e-distinct.sql) | `ORDER BY`, `DISTINCT`, `CAST` | Quais os maiores contratos? Quanto vale a carteira? |
| 03 | [`exemplo-03-where-e-a-sujeira.sql`](exemplo-03-where-e-a-sujeira.sql) | `WHERE`, `LIKE`, `FILTER`, `HAVING` | **Dá para confiar nesse número?** |
| 04 | [`exemplo-04-group-by-custo-no-tempo.sql`](exemplo-04-group-by-custo-no-tempo.sql) | `GROUP BY`, `date_trunc`, `try_cast` | Quanto a Vértice gasta por mês? (a 1ª query **quebra de propósito**) |
| 05 | [`exemplo-05-union-quais-projetos-atrasados.sql`](exemplo-05-union-quais-projetos-atrasados.sql) | `UNION ALL`, `WITH`, `CASE`, `JOIN` | **Quais projetos estão mais atrasados?** (as 3 ferramentas numa fila só) |
| 06 | [`exemplo-06-quanto-custa-o-atraso.sql`](exemplo-06-quanto-custa-o-atraso.sql) | CTE encadeada, janela `OVER()`, `QUALIFY` | **Quanto o atraso custa? O farol mostra isso?** |

Pelo terminal (opcional):

```bash
python3 scripts/run_sql.py aulas/aula-01-analista/exemplo-05-union-quais-projetos-atrasados.sql --profile SEU-PERFIL
python3 scripts/run_sql.py aulas/aula-01-analista/exemplo-04-group-by-custo-no-tempo.sql --profile SEU-PERFIL --continuar
```

### Os KPIs, em uma linha cada

```
planejado   = Σ horas da tarefa × % do prazo baseline já decorrido   (quanto DEVIA estar pronto)
agregado    = Σ horas da tarefa × % concluído (corta em 100%)       (quanto ESTÁ pronto)
SPI = agregado / planejado        < 1 é atraso

EV  valor agregado = orçamento × agregado / horas totais
AC  custo real     = Σ custos (vírgula trocada por ponto)
CPI = EV / AC                     < 1 é estouro
EAC = orçamento / CPI             estouro previsto = EAC − orçamento
margem projetada = (contrato − EAC) / contrato
atraso projetado (dias) = duração / SPI − duração

atenção: SPI ou CPI < 0,9          crítico: SPI ou CPI < 0,8
```

### 📓 Notebooks para dar (e acompanhar) a aula

[`notebooks/`](notebooks) tem os 6 exemplos em duas versões, geradas dos `.sql` por
[`scripts/gerar_notebooks.py`](../../scripts/gerar_notebooks.py):

- `notebooks/resolvidos/`: cada bloco é uma célula, com a query pronta;
- `notebooks/em-branco/`: a mesma explicação, com a célula vazia para escrever ao vivo.

No Git folder eles já aparecem. Para importar por fora:

```bash
python3 scripts/gerar_notebooks.py aulas/aula-01-analista --importar --profile SEU-PERFIL
```

---

## 🔢 O que deve aparecer na tela

Se o seu número divergir, o erro está na query, não no dado: a seed é fixa.

| Métrica | Valor |
|---|---|
| Carteira total · em andamento | R$ 305,2 mi · R$ 208,6 mi (41 projetos) |
| Custo real total | R$ 193,35 mi (com `try_cast`: R$ 187,94 mi → **671 lançamentos e R$ 5,4 mi somem**) |
| Maior categoria de custo | pessoal (folha alocada), R$ 117,8 mi |
| Projetos em atenção · críticos | 10 · 7 |
| Piores SPI | PRJ-016 0,63 · PRJ-030 0,69 · PRJ-039 0,75 · PRJ-011 0,77 |
| Piores CPI | PRJ-009 0,77 · PRJ-027 0,79 · PRJ-005 0,81 |
| Estouro previsto da carteira | **R$ 6,47 mi** (só projetos que estouram) |
| Maior estouro | PRJ-021, R$ 1,78 mi |
| Maior atraso projetado | PRJ-016, +298 dias · PRJ-011, +155 dias |
| Farol verde com SPI < 0,9 | 4 projetos: PRJ-012, PRJ-028, PRJ-034, PRJ-042 |

---

## 📊 O dashboard e o Genie

Roteiro completo, com as 4 perguntas do dono e o que esperar: [`roteiro-genie-e-dashboard.md`](roteiro-genie-e-dashboard.md).

O dashboard é **código**: [`gerar_dashboard.py`](gerar_dashboard.py) escreve o
[`dashboard-bronze.lvdash.json`](dashboard-bronze.lvdash.json) e publica.

```bash
python3 aulas/aula-01-analista/gerar_dashboard.py --deploy --profile SEU-PERFIL
```

O Genie da noite 1 fica direto na bronze, **sem instrução nenhuma**, de propósito:
[`genie-bronze.json`](genie-bronze.json).

```bash
python3 scripts/genie.py publicar aulas/aula-01-analista/genie-bronze.json \
  --titulo "Farol · Noite 1 (bronze, sem curadoria)" --profile SEU-PERFIL
python3 scripts/genie.py perguntar "Farol · Noite 1 (bronze, sem curadoria)" \
  "Quais projetos estão atrasados, e de quais clientes?" --profile SEU-PERFIL
```

---

## 🧯 Se der errado

| Sintoma | Causa | O que fazer |
|---|---|---|
| `00-carregar-dados` não acha `material/gerar_dataset.py` | o notebook foi importado solto, fora do Git folder | abra pelo Git folder (passo 2) |
| `PERMISSION_DENIED` ao criar catálogo | workspace que não é seu | use a sua conta Free Edition |
| `01-ingestao-bronze` dá `PATH_NOT_FOUND` | os arquivos não estão em `raw/<sistema>/` | rode o `00-carregar-dados` de novo |
| Tabela com 0 linhas | upload manual numa pasta errada | confira `/Volumes/lakehouse_vertice/bronze/raw/pmo/projetos.csv` |
| `CAST_INVALID_INPUT` no exemplo 04 | **é de propósito** | é o ponto da aula: a vírgula decimal |
| Exemplo 06 ou verificação: `rascunho_tarefas` não existe | o exemplo 05 não rodou | rode o exemplo 05 inteiro |
| SPI/CPI diferentes dos da tabela | `current_date()` no lugar de `DATE'2026-10-16'` | use a data fixa |
| Warehouse demora no primeiro comando | o serverless está ligando | espere uns 10 segundos |
| Dashboard em branco | o warehouse estava parado | atualize a página depois de 10 segundos |

---

## 🧭 Sem escrever código (trilha de gestão)

Para quem é de gestão, PMO ou financeiro e quer acompanhar sem SQL:

1. faça os passos 1 a 4 (só cliques e **Run all**);
2. abra o **dashboard** publicado e responda as perguntas do dono olhando para ele;
3. use o **Genie** com as 4 perguntas do roteiro e compare com a tabela "O que deve aparecer na tela";
4. no SQL Editor, use o **Genie Code** (o assistente do editor) e peça: *"junte as tarefas de bronze.excel_tarefas,
   bronze.clickup_tarefas e bronze.msproject_tarefas e calcule o SPI por projeto, com hoje = 2026-10-16"*.
   Compare com o exemplo 05: ele lembrou da linha de TOTAL e das tarefas-resumo?

---

## 🗂️ Arquivos desta pasta

| Arquivo | Para que serve |
|---|---|
| `00-carregar-dados.py` | notebook: catálogo + gera os dados no volume + confere os padrões |
| `00-setup-catalogo.sql` | catálogo, schemas e volume (também roda no SQL Editor) |
| `01-ingestao-bronze.sql` | CSV, Excel, JSON e XML viram 13 tabelas Delta |
| `exemplo-01..06-*.sql` | os 6 exemplos da noite |
| `99-verificacao.sql` | esperado × obtido, 22 checagens |
| `notebooks/` | os exemplos em notebook, resolvidos e em branco |
| `gerar_dashboard.py` · `dashboard-bronze.lvdash.json` | o dashboard como código |
| `genie-bronze.json` | o Genie sem curadoria (para errar) |
| `roteiro-genie-e-dashboard.md` | o bloco sem código da aula |
| Slides | [`slides/aula-01.html`](../../slides/aula-01.html) (abra no navegador, ← → navega, F tela cheia) |

---

## ➡️ Amanhã

Você juntou as três ferramentas **dentro de uma view**, com `CASE`, `replace`, número de série do Excel e
milissegundos do ClickUp. Dá certo uma vez. Na terceira query, alguém esquece a linha de TOTAL, e o número muda.

Amanhã é a noite da **integração**: as três ferramentas viram um modelo só num pipeline escrito com Claude Code,
testado e agendado, com os KPIs definidos uma vez só e a IA lendo os status semanais e os postmortems para achar
a causa do atraso. → [aula-02](../aula-02-engenheiro)

**Lição de casa:** instale a [CLI do Databricks](https://docs.databricks.com/dev-tools/cli/install.html)
e o [Claude Code](https://claude.com/claude-code), e rode `databricks auth login`.
