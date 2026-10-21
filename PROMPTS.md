# 🧾 Os prompts, na ordem

O Projeto Farol, a Torre de Controle da Vértice Tecnologia — das planilhas, listas do ClickUp e
cronogramas do Project até o Genie que responde as quatro perguntas do dono — sai de
**prompts colados em sequência no Claude Code**.
Este arquivo é a sequência inteira, na ordem, para quem quer refazer sozinho.

> **Cada prompt termina com um deploy.** Não junte dois: o valor do formato
> está em ver a coisa subir uma camada por vez, e em quebrar cedo quando quebra.

| Noite | Prompts | O que existe no fim |
|---|---|---|
| [**3** · engenheiro de dados](aulas/aula-03-modelagem-claude-code) | o bundle (à mão) e 1 a 4 | o job de ingestão da noite 2 como código, o pipeline que integra as 3 ferramentas, gold com testes, status semanal com IA e o dashboard |
| [**4** · cientista e engenheiro de IA](aulas/aula-04-produtos-de-dados-ia) | 5 a 8 | modelo de estouro em 30 dias no mesmo job, metric view + Genie curado, o app da Torre e a decisão gravada no Lakebase |

---

## Antes do primeiro prompt

As noites 1 e 2 precisam estar feitas: o catálogo `lakehouse_vertice` com a bronze carregada
(9 tabelas + `feriados`) e o **job de ingestão da noite 2** no workspace (os notebooks
[`01_ingestao_api`](aulas/aula-02-python-engenheiro/01_ingestao_api_gabarito.py) e
[`02_ingestao_boto3`](aulas/aula-02-python-engenheiro/02_ingestao_boto3_gabarito.py)).

**O passo 1 não é prompt: é você, com a CLI do Databricks.** Num repositório novo,
`databricks bundle init default-minimal`, depois `databricks bundle generate job` importa o job
de ontem, e as chaves vão para `.databricks/bundle/dev/variable-overrides.json`, fora do Git. O
passo a passo, testado: [`bundle-na-mao.md`](aulas/aula-03-modelagem-claude-code/claude-code/prd/bundle-na-mao.md).
Depois dele, os prompts 1 a 4.

```bash
# 1 · a CLI do Databricks (v0.250 ou mais nova) e o login
brew tap databricks/tap && brew install databricks     # Windows: winget install Databricks.DatabricksCLI
databricks auth login --profile <perfil>
databricks auth profiles                                # o seu aparece com Valid: YES

# 2 · o Claude Code (as skills oficiais do Databricks já vêm em .claude/skills)
npm install -g @anthropic-ai/claude-code

# 3 · conferir que a bronze e o job de ontem estão lá
databricks experimental aitools tools query "SHOW TABLES IN lakehouse_vertice.bronze" --profile <perfil>
databricks jobs list --profile <perfil>
```

O seu bundle mora num **repositório seu**, criado no passo 1. A pasta
`aulas/aula-03-modelagem-claude-code/claude-code/vertice/` é o gabarito. Se você já rodou antes, zere
com `BUNDLE_DIR=aulas/aula-03-modelagem-claude-code/claude-code/meu-vertice bash aulas/aula-03-modelagem-claude-code/claude-code/prd/00-reset.sh <perfil> --apagar`.

Nos prompts abaixo, **troque `<perfil>` pelo seu profile**.

---

## Como usar esta página

1. Copie o bloco do prompt (só o que está dentro do ```)
2. Cole no Claude Code, na raiz do repositório
3. Espere o deploy terminar e **confira o número** antes de ir para o próximo
4. O que conferir em cada um está no arquivo linkado no título

Os arquivos linkados têm o que esta página não tem: o que mostrar antes de
colar, o que falar enquanto o Claude Code trabalha, e a tabela **"se der
errado"**. Se for a primeira vez, siga por eles.

---

## Noite 3 · a Torre roda sozinha

### Prompt 1 · Conferência + silver

*a bronze conferida e as três ferramentas viram uma* · noite 3 · bundle deploy + run do pipeline · [texto completo, com o que falar e as armadilhas](aulas/aula-03-modelagem-claude-code/claude-code/prd/prompt-01-silver.md)

```
Use as skills databricks-core, databricks-dabs e databricks-pipelines.
Sempre --profile DEFAULT.

Primeiro, o contexto do curso: troque o CLAUDE.md da raiz (o do template)
por este, e leia antes de continuar:
  curl -fsSL -o CLAUDE.md https://raw.githubusercontent.com/lvgalvao/ImersaoControlTower/main/aulas/aula-03-modelagem-claude-code/claude-code/prd/CLAUDE.md
  mkdir -p scripts && curl -fsSL -o scripts/run_sql.py https://raw.githubusercontent.com/lvgalvao/ImersaoControlTower/main/scripts/run_sql.py

O bundle vertice está na raiz: eu criei à mão com bundle init
default-minimal e importei o job de ontem com bundle generate
(resources/ingestão.job.yml, com as chaves do data lake já em variáveis).
NÃO mexa nos valores das chaves, nem no
.databricks/bundle/dev/variable-overrides.json, nem no catálogo e nos
schemas (já existem). Se um comando for recusado por causa das chaves,
pare e me mostre o comando para eu rodar com `!`.

Confira antes: o databricks.yml está na pasta onde você abriu, e existe
resources/*.job.yml com as chaves em ${var.…}. Se faltar, NÃO rode o
bundle generate (ele grava as chaves em texto): pare e me diga qual passo
do bundle-na-mao.md refazer.

Antes de tudo, arrume o bundle:
- databricks.yml: tire o mode: development do target dev (ele prefixa os
  nomes) e ponha presets: trigger_pause_status: PAUSED. Variáveis catalog
  (default lakehouse_vertice) e warehouse_id (descubra com
  databricks warehouses list); saem as variáveis catalog/schema do template.
  Mova os dois notebooks que o generate pôs em src/ para src/ingestao/
  (ajuste o notebook_path). Apague fixtures/ e tests/ do template.
- o job: renomeie o arquivo para resources/vertice.job.yml, a chave e o
  name para vertice_farol, as tarefas para ingestao_feriados (a da API) e
  ingestao_data_lake (a do boto3), e schedule.pause_status para PAUSED. O
  bloco variables das duas chaves pode ir para o databricks.yml.
- depois do deploy, pause o agendamento do job antigo "Ingestão" (dois jobs
  recarregando a mesma bronze às 6h brigam). Não apague.

0. Antes da silver, a conferência da bronze: src/conferencia/00-conferencia-bronze.sql,
   sql_task no warehouse ${var.warehouse_id}, tarefa conferencia_bronze no job,
   depois das duas ingestões. Confere as 9 tabelas contra a contagem esperada
   (seed 42): projetos 60 · status_semanal 3911 · excel_tarefas 1663 ·
   clickup_tarefas 2119 · msproject_tarefas 1260 · colaboradores 523 ·
   apontamentos 30883 · custos 23640 · entregas_fornecedor 640
   (bronze.feriados fica de fora: cresce a cada execução). Uma linha por
   tabela com esperado e obtido; se alguma divergir, raise_error() dizendo
   qual tabela e onde olhar (a saída da tarefa ingestao_data_lake).

Agora a silver: integrar as três ferramentas, limpar, tipar e declarar o
contrato.

Crie um pipeline Lakeflow Spark Declarative Pipelines em SQL:
resources/vertice_medalhao.pipeline.yml com name vertice_medalhao, catalog
${var.catalog}, schema silver, serverless: true, photon: true, e libraries com
um glob em ../src/silver/** (o prompt 2 vai acrescentar ../src/gold/**).

Use CREATE OR REFRESH MATERIALIZED VIEW (nunca CREATE OR REPLACE, que não
existe no pipeline) e CREATE TEMPORARY VIEW para as visões intermediárias.
Leia a bronze pelo nome completo lakehouse_vertice.bronze.<tabela>; dentro do
pipeline, referencie as tabelas silver só pelo nome. COMMENT em toda tabela.
Siga a tabela de sujeiras da seção 3 do CLAUDE.md.

Um arquivo por assunto em src/silver/:

01-projetos.sql — o cadastro do PMO (é o de-para da integração)
- data_inicio em yyyy-MM-dd e dd/MM/yyyy: coalesce de dois try_to_date.
- ferramenta escrita de 8 jeitos → 'excel', 'clickup' ou 'msproject'
  (guarde ferramenta_como_veio). codigo_ferramenta vazio → NULL.
- EXPECT data_inicio IS NOT NULL e ferramenta IN (...), FAIL UPDATE.

02-tarefas.sql — AS TRÊS FERRAMENTAS VIRAM UMA
Três CREATE TEMPORARY VIEW com as MESMAS colunas (projeto_id, ferramenta,
id_na_ferramenta, fase, tarefa, responsavel, inicio_baseline, fim_baseline,
inicio_real, fim_real, pct_como_veio, horas, status_na_ferramenta):
- tarefas_excel: projeto pelo de-para (codigo_ferramenta = arquivo) e, se o
  código faltar, o PRJ-xxx do nome do arquivo. Datas: com '/' é dd/MM/yyyy,
  senão é número de série do Excel: date_add(DATE'1899-12-30', CAST(x AS INT)).
  %: com '%' tire o '%' e troque vírgula por ponto; sem '%' é fração (× 100).
  Horas: tire o 'h'. TIRE a linha onde tarefa = 'TOTAL'.
- tarefas_clickup: projeto pelo de-para (codigo_ferramenta = list_id) e, se o
  código faltar, pelo nome da lista. Datas em milissegundos:
  to_date(timestamp_millis(CAST(x AS BIGINT))). % e baseline estão em
  custom_fields: filter(custom_fields, f -> f.name = 'Progresso (%)')[0].value
  (e 'Início baseline', 'Fim baseline', 'Fase'). Horas = time_estimate / 3600000.
  Status de 12 jeitos → concluida / a_fazer / em_andamento.
- tarefas_msproject: projeto pelo de-para (codigo_ferramenta = arquivo). Só
  Summary = 0 (as tarefas-resumo somam as de baixo). A fase é a última
  tarefa-resumo de OutlineLevel 1 antes da tarefa:
  last_value(CASE WHEN OutlineLevel = 1 THEN Name END, true) OVER (PARTITION
  BY arquivo ORDER BY UID). Baseline.Start/Finish, ActualStart/ActualFinish,
  PercentComplete, horas de 'PT40H0M0S'.
MATERIALIZED VIEW tarefas = UNION ALL das três, com tarefa_id
(projeto-ferramenta-id), pct_concluido = least(pct_como_veio, 100) e a flag
pct_veio_acima_de_100. EXPECT projeto_id IS NOT NULL (achou_o_projeto),
pct entre 0 e 100 e horas > 0, todos FAIL UPDATE.

03-status-e-custos.sql
- status_semanal: data_status DATE, farol em minúsculas (EXPECT farol IN
  ('verde','amarelo','vermelho') FAIL UPDATE), pct_concluido INT, flag
  status_vazio ('', 'N/A', 'ver ata da reunião') — NÃO descarte.
- custos: valor com 671 vírgulas decimais: replace(',', '.') ANTES do CAST,
  nunca try_cast. estorno (negativo) FICA, com a coluna estorno. semana =
  sexta da semana: date_add(date_trunc('WEEK', data), 4).

04-pessoas.sql
- colaboradores: COL0102, COL0257 e COL0433 aparecem duas vezes (nome e papel
  em CAIXA ALTA). Mantenha o cadastro com papel em minúsculas (row_number).
- apontamentos com semana = semana_inicio + 4 (sexta).

05-fornecedores.sql — entregas_fornecedor: a CodeForge vem de 4 jeitos
('CodeForge Consultoria Ltda', 'Codeforge Consultoria', 'CODEFORGE CONSULTORIA
LTDA', 'Code Forge Consultoria'): normalize (replace(lower(x), ' ', '') LIKE
'%codeforge%') e guarde fornecedor_como_veio. data_entrega vazia = em aberto
(não é sujeira). prazo_prometido_dias, prazo_real_dias,
dias_de_atraso_na_entrega, em_aberto e em_atraso (em aberto e data_prometida
antes de DATE'2026-10-16').

São 7 tabelas na silver, nem uma a mais: projetos, tarefas, status_semanal,
custos, colaboradores, apontamentos e entregas_fornecedor.

Acrescente ao job vertice_farol a tarefa medalhao (pipeline_task apontando
para ${resources.pipelines.vertice_medalhao.id}), depois de conferencia_bronze.

Rode e me mostre a saída:
  databricks bundle validate --profile DEFAULT
  databricks bundle deploy --profile DEFAULT
  databricks bundle run vertice_farol --profile DEFAULT
E no fim, numa tabela: cada tarefa do job, quanto tempo levou e o resultado.
```

### Prompt 2 · Gold + testes

*o produto de dados e as perguntas do dono* · noite 3 · bundle deploy + run · [texto completo, com o que falar e as armadilhas](aulas/aula-03-modelagem-claude-code/claude-code/prd/prompt-02-gold.md)

```
Continue o bundle na raiz deste repositório. A silver está pronta.
Agora a gold, no MESMO pipeline vertice_medalhao: acrescente o glob
../src/gold/** em libraries. Os arquivos da gold escrevem com o nome completo
lakehouse_vertice.gold.<tabela>; leem a silver pelo nome curto. COMMENT em todas.
O "hoje" é DATE'2026-10-16'. Nunca current_date().

src/gold/01-fato-projeto-semana.sql → lakehouse_vertice.gold.fato_projeto_semana
Uma linha por projeto e semana (sexta-feira), da semana do início até
2026-10-16 (sequence(..., INTERVAL 1 WEEK) + explode). Colunas:
- pv: orçamento × Σ horas × fração do baseline decorrida até a semana ÷ Σ horas
  (greatest(0, least(1, datediff(semana, inicio)/datediff(fim, inicio))))
- ev: orçamento × pct_concluido do status_semanal daquela sexta ÷ 100. Projeto
  concluído não publica mais: use o último % (last_value(pct, true) OVER).
- ac: custo real acumulado (silver.custos por semana, soma acumulada)
- spi = ev/pv, cpi = ev/ac (try_divide, 4 casas), eac = orcamento / cpi
- farol_do_gerente (o último farol publicado)
- horas_disponiveis, horas_apontadas e horas_ociosas da semana (apontamentos)
- EXPECT pv >= 0 e ev <= orcamento, FAIL UPDATE.

src/gold/02-situacao-e-pessoas.sql
- projeto_situacao_atual: a fotografia de 2026-10-16 de cada projeto (60
  linhas). Traz o cadastro (projeto = projeto_id · nome, cliente, segmento,
  tipo_projeto, ferramenta, gerente_projeto, valor_contrato, orcamento,
  data_inicio, data_fim_baseline, duracao_baseline_dias, status) e os KPIs
  calculados sobre silver.tarefas (o % de hoje das ferramentas): pv, ev, ac, spi, cpi, eac, estouro_previsto = greatest(eac - orcamento, 0),
  margem_projetada, atraso_projetado_dias, termino_projetado, situacao
  ('concluído' se status <> em_andamento; 'crítico' se SPI ou CPI < 0,8;
  'atenção' se < 0,9; senão 'ok'), farol_do_gerente (status de hoje),
  farol_calculado (regra do manual: verde >= 0,95; amarelo >= 0,90) e
  melancia (em andamento, farol do gerente verde e SPI < 0,9).
- utilizacao_pessoa_semana: pessoa × projeto × semana com nome, papel,
  senioridade, horas disponíveis, apontadas, ociosas, utilizacao,
  custo_ocioso (horas ociosas × custo_hora) e o spi_do_projeto naquela semana.
Não crie dim_projeto nem tabela gold de fornecedor: o cadastro já está na
projeto_situacao_atual, e fornecedor é lido direto da silver.entregas_fornecedor.

src/testes/testes.sql (sql_task) — cada teste com raise_error se falhar:
 1 os 60 projetos têm cronograma na silver.tarefas
 2 cada projeto veio de UMA ferramenta, a do cadastro do PMO
 3 as horas do Excel na silver = a soma das linhas de TOTAL das planilhas
 4 uma linha por pessoa na silver
 5 a CodeForge virou um fornecedor só
 6 a limpeza não mudou o custo total (bronze com replace = silver)
 7 os 60 projetos têm fotografia de hoje
 8 todo projeto em andamento tem SPI e CPI
 9 o EV de hoje do status semanal bate com o das ferramentas (diferença < 1%)
10 AC de hoje no fato = soma dos lançamentos até hoje

Acrescente ao job a tarefa testes_de_qualidade, depois de medalhao.

Rode e me mostre a saída:
  databricks bundle deploy --profile DEFAULT
  databricks bundle run vertice_farol --profile DEFAULT
```

### Prompt 3 · O job completo

*a Torre roda sozinha, e lê o texto do status com IA* · noite 3 · bundle deploy + run · [texto completo, com o que falar e as armadilhas](aulas/aula-03-modelagem-claude-code/claude-code/prd/prompt-03-job-completo.md)

```
Continue o bundle na raiz deste repositório. A gold e os testes estão
prontos. Agora a última camada da noite, e o job inteiro rodando sozinho.

1. O texto livre do status vira coluna. Use as funções de IA na versão 2.0
   (map('version','2.0')); o resultado é VARIANT, lido com ':response'.

   src/ia/status_estruturado.sql (sql_task, caminho completo das tabelas)
   a. CREATE TABLE IF NOT EXISTS lakehouse_vertice.gold.status_estruturado com
      COMMENT em cada coluna: projeto_id, data_status, farol, causa_bloqueio,
      bloqueio, quem_destrava, dias_impacto (DOUBLE), metodo ('regra', 'ia' ou
      'palavra_chave'), texto_status, _classificado_em.
      NÃO é CREATE OR REPLACE: a tabela acumula, e a IA não pode ser refeita
      a cada execução.
   b. MERGE INTO ... WHEN NOT MATCHED THEN INSERT, só com os status da
      silver.status_semanal que ainda não estão na tabela (LEFT ANTI JOIN por
      projeto_id e data_status). Para cada status:
      - metodo = 'regra' se status_vazio ou se o texto (minúsculas) diz
        'bloqueios: nenhum', 'sem bloqueios' ou 'nada relevante';
        'ia' se data_status >= DATE'2026-07-18' (últimos 90 dias);
        senão 'palavra_chave'.
      - causa_bloqueio: 'nao_reportado' se vazio; 'sem_bloqueio' na regra;
        na IA, ai_classify com a lista ["change_freeze","falta_sre",
        "dependencia_fornecedor","rotatividade","mudanca_escopo",
        "bug_retrabalho","aprovacao_cliente","sem_bloqueio"]; na
        palavra-chave, RLIKE: freeze|congelamento|janela de deploy →
        change_freeze; sre|infraestrutura|ambiente de homologação → falta_sre;
        forge|consultoria|fornecedor → dependencia_fornecedor; saída de|
        rotatividade|onboarding → rotatividade; escopo|change request|regra de
        negócio → mudanca_escopo; bugs|regressão|refazendo → bug_retrabalho;
        aprovação do cliente|homologação do cliente → aprovacao_cliente.
      - só na IA: ai_extract com JSON schema tipado: bloqueio (string),
        quem_destrava (string), dias_impacto (number, "1 semana = 7").
      - dias_impacto fora da IA: regex em 'impacto estimado de N dias' e
        'impacto estimado: 1 semana' (= 7).
   c. No fim, um SELECT de leitura: quantos status por metodo e causa.

   Acrescente ao job a tarefa status_com_ia, depois de medalhao (em paralelo
   com testes_de_qualidade).

2. O job inteiro
   - confira em resources/vertice.job.yml a ordem: ingestao_feriados e
     ingestao_data_lake em paralelo → conferencia_bronze → medalhao →
     testes_de_qualidade e status_com_ia em paralelo
   - agendamento toda segunda às 6h (America/Sao_Paulo); no dev ele fica
     pausado pelo preset, e está certo
   - max_concurrent_runs: 1 (duas execuções ao mesmo tempo apagariam a
     bronze uma da outra)
   - atualize o comentário do topo com as 6 tarefas e o que cada uma faz

Rode e me mostre a saída:
  databricks bundle validate --profile DEFAULT
  databricks bundle deploy --profile DEFAULT
  databricks bundle run vertice_farol --profile DEFAULT
E no fim, numa tabela: cada tarefa do job, quanto tempo levou e o resultado.
```

### Prompt 4 · O dashboard

*o dono vê a Torre* · noite 3 · bundle deploy · [texto completo, com o que falar e as armadilhas](aulas/aula-03-modelagem-claude-code/claude-code/prd/prompt-04-dashboard.md)

```
Continue o bundle na raiz deste repositório. O job está pronto e a gold
atualizada. Agora o dashboard, como código. Use a skill
databricks-aibi-dashboards.

1. scripts/gerar_dashboard.py gera resources/dashboard-portfolio.lvdash.json
   (AI/BI, GRID_V1). As queries da gold usam o nome de tabela PURO, sem
   catálogo nem schema; a silver.entregas_fornecedor vai com o nome completo
   lakehouse_vertice.silver.entregas_fornecedor. Três páginas:

   Portfólio
   - KPIs da carteira em andamento, calculados na projeto_situacao_atual
     (WHERE status = 'em_andamento'): carteira (SUM(valor_contrato)), SPI
     (SUM(ev)/SUM(pv)), CPI (SUM(ev)/SUM(ac)), estouro previsto, projetos em
     risco (atenção + crítico), críticos e melancias. Razão é SUM/SUM, nunca
     AVG de razão.
   - barra de estouro previsto por projeto, colorida por situação
     (crítico #FF5F46, atenção #F6C344, ok #22C2F4)
   - dispersão SPI × CPI, um ponto por projeto
   - linha de SPI e CPI semanais da carteira (SUM(ev)/SUM(pv) por semana no
     fato_projeto_semana, a partir de 2025-03-07)
   - tabela dos projetos em andamento com o farol do gerente ao lado do
     farol pelo número e a coluna melancia

   Pessoas
   - top 15 pessoas por custo da hora parada (utilizacao_pessoa_semana,
     semana > 2026-07-24, as últimas 12 semanas)
   - tabela de utilização por pessoa e projeto, da mais parada à mais ocupada
   - barras de causas de bloqueio por projeto (status_estruturado, últimos
     90 dias, sem 'sem_bloqueio' e 'nao_reportado')

   Fornecedores (sobre silver.entregas_fornecedor)
   - tabela por fornecedor: grafias no cadastro, entregas, prazo real ÷
     prometido, % no prazo, em atraso hoje
   - tabela das entregas em atraso hoje

   Tema nas cores da Jornada: #0059DB, #22C2F4, fundo #14141A no escuro.
   Um título de texto em cada página com a pergunta do dono que ela responde.

2. resources/dashboard.dashboard.yml: recurso dashboard_portfolio, display
   name "Projeto Farol · Portfólio", file_path para o JSON, dataset_catalog
   ${var.catalog}, dataset_schema gold, warehouse_id ${var.warehouse_id}.

Antes do deploy, rode cada query do dashboard (prefixando
lakehouse_vertice.gold. nas tabelas da gold) e me mostre a contagem de linhas
de cada uma e os valores dos KPIs.

Rode e me mostre a saída:
  python3 scripts/gerar_dashboard.py
  databricks bundle validate --profile DEFAULT
  databricks bundle deploy --profile DEFAULT
  databricks bundle summary --profile DEFAULT
```

---

## Fim da noite 3 · confira antes de seguir

```bash
python3 scripts/run_sql.py aulas/aula-03-modelagem-claude-code/claude-code/prd/99-verificacao.sql --profile <perfil>
# 20 linhas, todas "ok"
```

```sql
SELECT situacao, COUNT(*) FROM lakehouse_vertice.gold.projeto_situacao_atual GROUP BY 1;
-- crítico 7 · atenção 10 · ok 24 · concluído 19
SELECT ROUND(SUM(estouro_previsto) / 1e6, 2), COUNT_IF(melancia)
FROM lakehouse_vertice.gold.projeto_situacao_atual WHERE status = 'em_andamento';
-- 6,47 · 4
```

O job `vertice_farol` tem **6 tarefas** (2 de ingestão, conferência, medalhão, testes, IA) e roda
verde de ponta a ponta. Se estes números não baterem, não adianta seguir: a noite 4 treina o
modelo em cima deles.

---
## Noite 4 · a Torre prevê, responde e ganha uma URL

### Prompt 5 · O modelo

*o que vai dar errado no próximo mês* · noite 4 · bundle deploy + run · [texto completo, com o que falar e as armadilhas](aulas/aula-04-produtos-de-dados-ia/prd/prompt-01-modelo.md)

```
Leia o CLAUDE.md da raiz. Continue o MESMO bundle vertice na raiz deste
repositório: ML é mais uma camada do job, não um projeto à parte. O "hoje" é
DATE'2026-10-16'. Nunca current_date(). São três tarefas novas, nesta ordem.

ARMADILHAS MEDIDAS NO FREE EDITION (siga todas):
- O serverless vem com MLflow 2.11, e registrar modelo no Unity Catalog
  falha com "s3:PutObject ... explicit deny". Primeira célula de cada
  notebook: %pip install -q -U "mlflow-skinny[databricks]>=2.21,<3"
  e dbutils.library.restartPython() na seguinte.
- XGBoost treina e não carrega de volta: use HistGradientBoosting do sklearn.
- spark_udf quebra no serverless (InvalidVersion): use mlflow.sklearn.load_model + pandas.
- DECIMAL vira Decimal no pandas e quebra o registro: .astype(float).
- mlflow.set_experiment não cria a pasta pai: WorkspaceClient().workspace
  .mkdirs("/Users/<eu>/vertice") antes.
- MLflow 2.x: log_model(..., artifact_path="modelo"), nunca name=.
- Toda célula de texto começa com "# MAGIC %md".
- Janela nomeada com frame (OVER (w ROWS BETWEEN ...)) dá PARSE_SYNTAX_ERROR:
  escreva PARTITION BY e ORDER BY por extenso nas janelas com ROWS BETWEEN.

1. src/ml/01-features.sql (sql_task ml_features, depois de
   testes_de_qualidade E status_com_ia)
   CREATE SCHEMA IF NOT EXISTS lakehouse_vertice.ml e recrie
   lakehouse_vertice.ml.features_projeto_semana: uma linha por projeto e
   semana (sexta), de gold.fato_projeto_semana + gold.projeto_situacao_atual.
   COMMENT na tabela. Toda feature olha SÓ para trás:
   - spi, cpi, indice_min = least(spi, cpi); variação em 4 e 8 semanas
     (d_spi_4s, d_cpi_4s, d_spi_8s, d_cpi_8s, d_indice_min_4s, com lag());
     semanas_cpi_caindo nas últimas 4
   - ritmo do último mês: cpi_ultimas_4s = (ev - ev 4 semanas antes) /
     (ac - ac 4 semanas antes); spi_ultimas_4s o mesmo com pv
   - pct_fisico = ev / orcamento; pct_prazo = dias desde o início / duração
   - ociosidade_4s; pct_consultoria_4s e pct_cloud_4s (silver.custos)
   - saidas_12s: pessoas que apontaram hora no projeto e se desligaram nas
     últimas 12 semanas (silver.apontamentos + silver.colaboradores)
   - status_freeze_4s, status_falta_sre_4s, status_fornecedor_4s,
     status_rotatividade_4s, status_escopo_4s, status_retrabalho_4s,
     status_com_bloqueio_4s: quantos status dos últimos 28 dias tiveram cada
     causa_bloqueio (gold.status_estruturado, qualquer método)
   Os dois alvos, do FUTURO, que nunca entram como feature:
   alvo_pior_indice_30d = menor least(spi, cpi) nas 4 semanas SEGUINTES
   (ROWS BETWEEN 1 FOLLOWING AND 4 FOLLOWING) e estoura_30d = 1 se < 0,9.
   NULL quando ainda não há 4 semanas de futuro (o caso de hoje).
   elegivel = 1 se SPI e CPI >= 0,9, 84+ dias de projeto, ev < 98% do
   orçamento e (em andamento ou semana anterior a hoje).
   No fim, uma query de conferência: linhas, treino, taxa base, linhas de hoje.

2. src/ml/02-modelo.py (notebook_task ml_modelo, widget catalog)
   a. Teste = elegíveis com rótulo e semana >= 2026-04-03. Treino =
      rotulados com semana <= 2026-03-06 e pct_prazo > 0,15. 24 features
      (todas menos segmento, farol_do_gerente, elegivel e os alvos).
   b. BASELINES no teste, impressos ANTES de treinar: regra de corte atual,
      folga até o corte (-indice_min), só o CPI, tendência (-d_indice_min_4s).
   c. HistGradientBoostingRegressor(random_state=42, max_depth=3,
      learning_rate=0.05, max_iter=300, min_samples_leaf=20) prevendo
      alvo_pior_indice_30d - indice_min; sigma = desvio do erro no teste;
      prob = P(pior < 0,9) com erro normal (math.erf). Compare com um
      HistGradientBoostingClassifier sim/não.
   d. Métrica do dono: estouro = projeto que vinha 4 semanas com SPI e CPI
      >= 0,9, cruza e FICA abaixo 2 semanas (pct_prazo > 0,15), a partir de
      4 semanas depois do início do teste. Avisado = esteve no top 5 da
      semana em alguma das 8 semanas anteriores. Imprima avisados/estouros e
      a antecedência média em dias.
   e. Importância por permutação.
   f. assert ANTES de registrar: AUC >= 0,75; AUC < 0,98 (acima é
      vazamento); AUC >= a folga até o corte; avisados >= 70% dos estouros.
   g. Retreine com todos os rotulados, registre
      lakehouse_vertice.ml.modelo_estouro_30d com input_example, alias @prod,
      e grave ml.modelo_metricas (uma linha com versão, AUC, réguas, sigma,
      estouros, avisados, antecedência e a feature principal).

3. src/ml/03-score.py (notebook_task ml_score, depois de ml_modelo)
   Carregue models:/lakehouse_vertice.ml.modelo_estouro_30d@prod com
   mlflow.sklearn.load_model; o sigma vem de ml.modelo_metricas. Pontue os
   projetos em andamento na semana 2026-10-16; quem tem least(spi, cpi) < 0,9
   NA FOTOGRAFIA DE HOJE (gold.projeto_situacao_atual) recebe 1,0. ranking
   por prob; faixa_risco alto >= 0,5, medio >= 0,2, senão baixo.
   principais_fatores: os 2 ou 3 sinais mais graves, em português, números
   com vírgula decimal (já abaixo do corte, status abaixo do corte com o
   cronograma acima, folga < 0,05, CPI caindo, ritmo do mês < 0,85, falta
   de SRE, freeze, rotatividade, escopo, consultoria, ociosidade >= 25%).
   Grave lakehouse_vertice.gold.score_estouro_30d com EXATAMENTE projeto_id
   STRING, data_referencia DATE, prob_estouro_30d DOUBLE, ranking INT,
   faixa_risco STRING, principais_fatores STRING. COMMENT na tabela e nas
   colunas: o Genie e o app leem daqui. assert: uma linha por projeto em
   andamento, prob entre 0 e 1, ranking único, nenhum motivo vazio.

Rode e me mostre a saída:
  databricks bundle validate --profile <perfil>
  databricks bundle deploy --profile <perfil>
  databricks bundle run vertice_farol --profile <perfil>
E no fim: as métricas de ml.modelo_metricas e o top 25 do score com o motivo.
```

### Prompt 6 · Métricas + Genie

*o dono pergunta em português* · noite 4 · bundle deploy + run + deploy · [texto completo, com o que falar e as armadilhas](aulas/aula-04-produtos-de-dados-ia/prd/prompt-02-genie.md)

```
Continue o bundle vertice na raiz deste repositório. O modelo e o score
estão prontos. Agora a fórmula de cada KPI num lugar só, e o Genie que o
dono vai usar.

1. Métricas governadas: src/metricas/metricas.sql (sql_task)
   CREATE OR REPLACE VIEW lakehouse_vertice.gold.mv_projetos WITH METRICS
   LANGUAGE YAML AS $$ ... $$ (version 1.1), comment em toda dimensão e
   medida que não for óbvia, e synonyms em português.
   - source: lakehouse_vertice.gold.projeto_situacao_atual, com
     filter status = 'em_andamento'.
   - Dimensões: projeto_id, projeto, cliente, segmento, ferramenta, situacao,
     farol_do_gerente, farol_calculado, gerente_projeto.
   - Medidas: projetos, carteira (SUM valor_contrato), spi (SUM(ev)/SUM(pv)),
     cpi (SUM(ev)/SUM(ac)), eac, estouro_previsto, margem_projetada
     ((SUM(valor_contrato) - SUM(eac)) / SUM(valor_contrato)),
     atraso_projetado_medio_dias, projetos_em_risco, projetos_criticos,
     projetos_melancia (COUNT FILTER WHERE melancia).
   ARMADILHAS MEDIDAS: o YAML precisa da indentação intacta (teste com
   python3 scripts/run_sql.py <arquivo> --profile <perfil>), e NUNCA use ';'
   dentro do YAML, nem num comment: a sql_task do job corta o arquivo em todo ';'.
   Acrescente ao job a tarefa metricas_governadas, depois de
   testes_de_qualidade E status_com_ia.

2. Genie Agent como código
   - scripts/gerar_genie.py gera resources/farol.geniespace.json
     (serialized_space versão 2; ids de 32 caracteres hex, únicos e em ordem):
     tabelas gold.fato_projeto_semana, gold.projeto_situacao_atual,
     gold.status_estruturado, gold.utilizacao_pessoa_semana,
     gold.score_estouro_30d e silver.entregas_fornecedor, e a metric view
     gold.mv_projetos; as 4 perguntas do dono como perguntas de exemplo.
   - Instruções de texto: quem pergunta (o dono e a diretoria); HOJE =
     2026-10-16 e o que é "últimos 90 dias / 12 semanas / próximo mês"; as
     fórmulas e as regras de corte; mv_projetos para totais de hoje e
     projeto_situacao_atual para ranking; PV/EV/AC acumulados no fato (nunca
     somar semanas); farol e melancia; "por que o projeto X atrasou" responde
     com status_estruturado dos últimos 90 dias (sem sem_bloqueio e
     nao_reportado), mais o SPI e SREs ociosos se a causa for falta_sre;
     gente parada = utilização < 20% em 12 semanas; fornecedor = prazo real ÷
     prometido na silver.entregas_fornecedor; "o que vai dar errado no
     próximo mês" junta o score (projetos com situacao = 'ok' e faixa alto ou
     medio, com principais_fatores), as entregas de consultoria em atraso e o
     change freeze de varejo (01/11/2026 a 10/01/2027) nos projetos de
     e-commerce; probabilidade de estouro sai da score_estouro_30d na
     data_referencia mais recente; "quais clientes" devolve cada cliente
     uma vez.
   - Um exemplo de SQL para cada uma das 4 perguntas do dono, e um para
     "qual a chance de o PRJ-024 estourar no próximo mês?".
   - resources/genie.genie_space.yml: recurso genie_farol, título
     "Farol · Diretoria", warehouse ${var.warehouse_id}.

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run vertice_farol --only metricas_governadas --profile <perfil>
  databricks bundle deploy --profile <perfil>
  databricks bundle summary --profile <perfil>
  python3 scripts/genie.py perguntar "Farol · Diretoria" "O que vai dar errado no próximo mês, e o que eu faço agora?" --profile <perfil>
  python3 scripts/genie.py benchmark "Farol · Diretoria" aulas/aula-04-produtos-de-dados-ia/prd/genie-benchmark-diretoria.json --profile <perfil>
Se o benchmark der menos de 16/20, mostre os erros e ajuste a INSTRUÇÃO
(não a pergunta), gere o JSON, faça deploy e rode de novo.
```

### Prompt 7 · O app da Torre

*a Torre na tela do dono* · noite 4 · apps deploy · [texto completo, com o que falar e as armadilhas](aulas/aula-04-produtos-de-dados-ia/prd/prompt-03-app.md)

```
Leia o CLAUDE.md da raiz e aulas/aula-04-produtos-de-dados-ia/prd/CLAUDE.md.
Use as skills databricks-apps e databricks-app-design. A gold, o score
(gold.score_estouro_30d) e o Genie "Farol · Diretoria" já existem.

1. Confira `databricks apps list --profile <perfil>` (limite de 3 apps no
   Free Edition). Descubra o id do Genie "Farol · Diretoria" e crie o app
   numa pasta minha-torre/ na raiz deste repositório:
   databricks apps init --name minha-torre \
     --features analytics,genie \
     --set analytics.sql-warehouse.id=<warehouse> \
     --set genie.genie-space.id=<id do Genie "Farol · Diretoria"> \
     --set "genie.genie-space.name=Farol · Diretoria" \
     --run none --profile <perfil>
   O app é um bundle próprio, dentro da pasta do bundle vertice. Acrescente
   ao databricks.yml da RAIZ (o do vertice) sync: { exclude: ["minha-torre/**"] },
   senão o deploy do vertice sobe o node_modules do app inteiro.

2. config/queries (apague os exemplos do template):
   - kpis.sql: projetos em andamento, em risco (atenção + crítico),
     críticos, melancias, estouro previsto e carteira
     (projeto_situacao_atual), e alto risco em 30 dias (faixa_risco = 'alto'
     na data_referencia mais recente de score_estouro_30d).
   - projetos_risco.sql: projetos em andamento do pior para o melhor, com
     SPI, CPI, estouro, atraso projetado, farol do gerente × calculado,
     melancia, a causa mais frequente no status_estruturado dos últimos 90
     dias e os dias de impacto por falta_sre e por rotatividade.
   - pessoas_ociosas.sql: pessoas com utilização < 20% nas últimas 12
     semanas (utilizacao_pessoa_semana), com horas paradas e custo ocioso
     MÉDIOS por semana e custo_hora.
   A probabilidade por projeto (gold.score_estouro_30d) vem de uma rota
   GET /api/score-estouro no servidor que responde {disponivel, linhas}:
   se a tabela não existir, a tela mostra "—" em vez de quebrar o build.

3. Telas (português, R$, índices com 2 casas, Number() em tudo que vem do
   warehouse):
   - Projetos em risco: 4 KPIs (em risco, estouro previsto, carteira, alto
     risco em 30 dias) + tabela (situação com cor: crítico vermelho, atenção
     âmbar; farol do gerente com 🍉 quando é melancia; coluna P(estouro)).
   - Simulador: escolher uma pessoa ociosa e um projeto destino (só atenção
     ou crítico; para SRE, ordene pelos dias de falta_sre); mostrar horas no
     mês (× 4 semanas), ociosidade que deixa de ser paga, dias de cronograma
     recuperados (dias de impacto da causa nos últimos 90 dias ÷ 90 × 30),
     mobilização = horas de onboarding (editável, 40) × custo_hora, e saldo.
     Explique a conta num <details>.
   - Perguntar: <GenieChat alias="default" />.
   Sem cache no createApp. Título "Projeto Farol".

4. npm run typecheck, npm run lint, databricks apps validate.
   Depois: databricks bundle deploy --profile <perfil> (cria o app e o
   service principal). Crie scripts/conceder-acesso.sh (lê o
   service_principal_client_id com apps get e dá USE CATALOG em
   lakehouse_vertice e USE SCHEMA + SELECT na gold e na silver), rode e
   faça databricks apps deploy --profile <perfil>. Me mostre a URL.
```

### Prompt 8 · A aprovação no Lakebase

*a decisão fica registrada (opcional)* · noite 4 · apps deploy · [texto completo, com o que falar e as armadilhas](aulas/aula-04-produtos-de-dados-ia/prd/prompt-04-aprovacao-lakebase.md)

```
Leia o CLAUDE.md da raiz e aulas/aula-04-produtos-de-dados-ia/prd/CLAUDE.md. Use as skills
databricks-apps e databricks-lakebase. O app minha-torre já está no ar (prompt 3).

1. Lakebase:
   databricks postgres create-project minha-torre --profile <perfil>
   e descubra branch e database (list-branches, list-databases).
   Adicione ao databricks.yml as variáveis postgres_branch e postgres_database e o recurso
   do app `postgres` (CAN_CONNECT_AND_CREATE); no app.yaml a env LAKEBASE_ENDPOINT
   (valueFrom: postgres); no server o plugin lakebase().

2. server/routes/decisoes.ts, registrado em onPluginsReady:
   - cria o schema torre e a tabela torre.decisoes (id serial, projeto_origem, projeto_destino,
     recurso_id, tipo 'pessoa', decisao aprovada|recusada, justificativa,
     horas_recuperadas_mes, economia_mes, dias_recuperados, usuario,
     criado_em timestamptz default now()).
   - GET /api/quem-sou, GET /api/decisoes (200 mais recentes), POST /api/decisoes com zod
     (exporte o schema): projeto ^PRJ-\d{3}$, pessoa ^COL\d{4}$, origem ≠ destino,
     justificativa de 10 a 1000 caracteres, números com z.coerce. Grave o usuário do header
     x-forwarded-email.
   - server/decisoes.test.ts (vitest) testando o schema: aceita válida, recusa justificativa
     curta, projeto fora do padrão, pessoa fora do padrão e decisão inválida.

3. Cliente: no simulador, textarea de justificativa + botões Aprovar e Recusar (desabilitados
   com menos de 10 caracteres) que fazem POST e mostram "Decisão nº X aprovada e registrada
   por <e-mail>". Nova tela Decisões com o histórico (nº, quando, pessoa origem → destino,
   decisão, justificativa, ociosidade evitada no mês, por quem).

4. typecheck, lint, test, apps validate, apps deploy --profile <perfil>.
   Prove a gravação: crie scripts/ver_decisoes.py que lê torre.decisoes direto no Postgres
   (psycopg, senha = token de `databricks postgres generate-database-credential <endpoint>`)
   e rode com uv run --no-project --with "psycopg[binary]" python ... --profile <perfil>
```
---

## Para refazer do zero

Cada noite tem o próprio script de limpeza. Sem `--apagar`, eles apenas
**mostram** o que fariam. Nenhum deles toca na bronze da noite 1.

```bash
bash aulas/aula-03-modelagem-claude-code/claude-code/prd/00-reset.sh <perfil>             # simula
bash aulas/aula-03-modelagem-claude-code/claude-code/prd/00-reset.sh <perfil> --apagar    # apaga silver, gold e os recursos do bundle
bash aulas/aula-04-produtos-de-dados-ia/prd/99-limpar-modelo.sh <perfil>   # simula; --apagar tira features, modelo e score
bash aulas/aula-04-produtos-de-dados-ia/prd/99-limpar-aula-04.sh <perfil>  # simula; --apagar tira o app, o Lakebase e o bônus dos contratos
```
