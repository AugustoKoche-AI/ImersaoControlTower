# 🧾 Os prompts, na ordem

O Projeto Farol, a Torre de Controle da Vértice Tecnologia — das planilhas, listas do ClickUp e
cronogramas do Project até o Genie que responde as quatro perguntas do dono — sai de
**prompts colados em sequência no Claude Code**.
Este arquivo é a sequência inteira, na ordem, para quem quer refazer sozinho.

> **Cada prompt termina com um deploy.** Não junte dois: o valor do formato
> está em ver a coisa subir uma camada por vez, e em quebrar cedo quando quebra.

| Noite | Prompts | O que existe no fim |
|---|---|---|
| [**2** · engenheiro de dados](aulas/aula-02-engenheiro) | 1 a 6 | bundle, pipeline declarativo que integra as 3 ferramentas, status semanal com IA, a metric view mv_projetos, dashboard e Genie |
| [**3** · cientista de dados](aulas/aula-03-cientista) | 7 a 9 | modelo de estouro em 30 dias no Unity Catalog e o score por projeto |
| [**4** · engenheiro de IA](aulas/aula-04-engenheiro-ia) | 10 a 12 | o agente de contratos, o app da Torre e a decisão gravada no Lakebase |

---

## Antes do primeiro prompt

A noite 1 precisa estar feita: o catálogo `lakehouse_vertice` com a bronze
carregada (13 tabelas). Se não estiver, rode o
[`00-carregar-dados`](aulas/aula-01-analista/00-carregar-dados.py) e o
[`01-ingestao-bronze.sql`](aulas/aula-01-analista/01-ingestao-bronze.sql).

```bash
# 1 · a CLI do Databricks (v0.250 ou mais nova) e o login
brew tap databricks/tap && brew install databricks     # Windows: winget install Databricks.DatabricksCLI
databricks auth login --profile <perfil>
databricks auth profiles                                # o seu aparece com Valid: YES

# 2 · o Claude Code (as skills oficiais do Databricks já vêm em .claude/skills)
npm install -g @anthropic-ai/claude-code

# 3 · conferir que a bronze está lá
python3 scripts/run_sql.py aulas/aula-01-analista/99-verificacao.sql --profile <perfil>
```

**A pasta `aulas/aula-02-engenheiro/meu-vertice/` nasce vazia** — é o prompt 1 que
a preenche. A pasta `vertice/` ao lado é o gabarito. Se você já rodou antes, zere
com `BUNDLE_DIR=aulas/aula-02-engenheiro/meu-vertice bash aulas/aula-02-engenheiro/prd/00-reset.sh <perfil> --apagar`.

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

## Noite 2 · o pipeline nasce

### Prompt 1 · O bundle

*o projeto nasce como código* · noite 2 · deploy nº 1 (bundle deploy + run) · [texto completo, com o que falar e as armadilhas](aulas/aula-02-engenheiro/prd/prompt-01-bundle.md)

```
Leia aulas/aula-02-engenheiro/prd/CLAUDE.md antes de começar.

Crie o projeto da noite 2 em aulas/aula-02-engenheiro/meu-vertice/ como um
Databricks Asset Bundle chamado vertice. Esta é a primeira de seis entregas: as
outras cinco estendem este mesmo bundle, então deixe a estrutura pronta para
crescer (resources/, src/conferencia, src/silver, src/gold, src/ia,
src/metricas, src/testes, scripts/). NÃO copie da pasta vertice/ (é o gabarito).

CONTEXTO DO WORKSPACE
- profile: <perfil>   (sempre passe --profile, nunca deixe implícito)
- descubra o SQL Warehouse com `databricks warehouses list --profile <perfil>`
- Databricks Free Edition: tudo serverless, nunca configure cluster
- o catálogo lakehouse_vertice e os schemas bronze/silver/gold JÁ EXISTEM
  (noite 1). O bundle NÃO cria nem gerencia catálogo nem schema.

1. databricks.yml
   - bundle name: vertice; include: resources/*.yml
   - variables: catalog (default lakehouse_vertice) e warehouse_id (o id que
     você descobriu)
   - targets dev (default) e prod
   - ARMADILHA: NÃO use `mode: development` no dev. Ele prefixa os nomes com
     [dev seu_usuario] e quebra o SQL. Pause o agendamento com
     `presets: { trigger_pause_status: PAUSED }`. Deixe um comentário no YAML
     explicando isso.
   - prod: mode production, root_path em /Workspace/Users/${workspace.current_user.userName}/.bundle/${bundle.name}/${bundle.target}

2. resources/vertice.job.yml
   - job vertice_farol, agendado toda segunda às 6h (America/Sao_Paulo),
     depois do status semanal de sexta
   - uma tarefa por enquanto: conferencia_bronze, sql_task no warehouse
     ${var.warehouse_id} com o arquivo ../src/conferencia/00-conferencia-bronze.sql
   - comentário no topo listando as tarefas que os próximos prompts vão
     acrescentar (medalhao, testes_de_qualidade, status_com_ia,
     metricas_governadas)

3. src/conferencia/00-conferencia-bronze.sql
   Confere as 9 tabelas da bronze contra a contagem esperada (seed 42):
   projetos 60 · status_semanal 3911 · excel_tarefas 1663 · clickup_tarefas 2119 ·
   msproject_tarefas 1260 · colaboradores 523 · apontamentos 30883 ·
   custos 23640 · entregas_fornecedor 640
   Uma linha por tabela com esperado e obtido; se alguma divergir, chame
   raise_error() com uma mensagem que diga qual tabela e o que fazer
   (rodar de novo o 00-carregar-dados e o 01-ingestao-bronze da noite 1).

Rode e me mostre a saída de cada um:
  databricks bundle validate --profile <perfil>
  databricks bundle deploy --profile <perfil>
  databricks bundle run vertice_farol --profile <perfil>
```

### Prompt 2 · Silver

*as três ferramentas viram uma* · noite 2 · deploy nº 2 (bundle deploy + run do pipeline) · [texto completo, com o que falar e as armadilhas](aulas/aula-02-engenheiro/prd/prompt-02-silver.md)

```
Continue o bundle em aulas/aula-02-engenheiro/meu-vertice/. A bronze está
conferida. Agora a silver: integrar as três ferramentas, limpar, tipar e
declarar o contrato.

Crie um pipeline Lakeflow Spark Declarative Pipelines em SQL:
resources/vertice_medalhao.pipeline.yml com name vertice_medalhao, catalog
${var.catalog}, schema silver, serverless: true, photon: true, e libraries com
um glob em ../src/silver/** (o prompt 3 vai acrescentar ../src/gold/**).

Use CREATE OR REFRESH MATERIALIZED VIEW (nunca CREATE OR REPLACE, que não
existe no pipeline) e CREATE TEMPORARY VIEW para as visões intermediárias.
Leia a bronze pelo nome completo lakehouse_vertice.bronze.<tabela>; dentro do
pipeline, referencie as tabelas silver só pelo nome. COMMENT em toda tabela.
Siga a tabela de sujeiras da seção 3 do prd/CLAUDE.md.

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
  databricks bundle deploy --profile <perfil>
  databricks bundle run vertice_medalhao --profile <perfil>
```

### Prompt 3 · Gold

*o produto de dados e as perguntas do dono* · noite 2 · deploy nº 3 (bundle deploy + run) · [texto completo, com o que falar e as armadilhas](aulas/aula-02-engenheiro/prd/prompt-03-gold.md)

```
Continue o bundle em aulas/aula-02-engenheiro/meu-vertice/. A silver está pronta.
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
  databricks bundle deploy --profile <perfil>
  databricks bundle run vertice_farol --profile <perfil>
```

### Prompt 4 · Texto com IA

*o status semanal vira coluna* · noite 2 · deploy nº 4 (bundle deploy + run) · [texto completo, com o que falar e as armadilhas](aulas/aula-02-engenheiro/prd/prompt-04-texto-com-ia.md)

```
Continue o bundle em aulas/aula-02-engenheiro/meu-vertice/. Agora o texto livre
do status semanal vira coluna. Use as funções de IA na versão 2.0
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

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run vertice_farol --profile <perfil>
```

### Prompt 5 · Métricas governadas

*o KPI definido uma vez só* · noite 2 · deploy nº 5 (bundle deploy + run) · [texto completo, com o que falar e as armadilhas](aulas/aula-02-engenheiro/prd/prompt-05-metricas.md)

```
Continue o bundle em aulas/aula-02-engenheiro/meu-vertice/. Agora os KPIs
governados, numa metric view do Unity Catalog. Uma só.

Crie src/metricas/metricas.sql (sql_task) com CREATE OR REPLACE VIEW
lakehouse_vertice.gold.mv_projetos WITH METRICS LANGUAGE YAML AS $$ ... $$
(version 1.1), comment em toda dimensão e medida que não for óbvia, e
synonyms em português.
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

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run vertice_farol --profile <perfil>
```

### Prompt 6 · Dashboard e Genie

*o dono pergunta em português* · noite 2 · deploy nº 6 (bundle deploy) · [texto completo, com o que falar e as armadilhas](aulas/aula-02-engenheiro/prd/prompt-06-dashboard-e-genie.md)

```
Continue o bundle em aulas/aula-02-engenheiro/meu-vertice/. O pipeline, a IA e
as métricas estão prontos. Agora as duas portas para quem não escreve SQL.

1. Dashboard como código
   - scripts/gerar_dashboard.py gera resources/dashboard-portfolio.lvdash.json
     (AI/BI, GRID_V1, queries da gold com nome de tabela PURO, sem catálogo
     nem schema; a silver.entregas_fornecedor vai com o nome completo
     lakehouse_vertice.silver.entregas_fornecedor). Três páginas:
     Portfólio: KPIs da mv_projetos com MEASURE() (carteira, SPI, CPI, estouro
       previsto, projetos em risco, críticos, melancias); barra de estouro
       previsto por projeto colorida por situação (crítico #FF5F46, atenção
       #F6C344, ok #22C2F4); dispersão SPI × CPI; linha de SPI e CPI semanais
       da carteira (SUM(ev)/SUM(pv) por semana no fato_projeto_semana); tabela dos projetos em andamento com o farol
       do gerente ao lado do farol pelo número.
     Pessoas: top 15 pessoas por custo da hora parada (12 semanas), tabela de
       utilização por pessoa e projeto, e barras de causas de bloqueio por
       projeto (status_estruturado, últimos 90 dias).
     Fornecedores: tabela por fornecedor (grafias no cadastro, entregas,
       prazo real ÷ prometido, % no prazo, em atraso hoje) e tabela das
       entregas em atraso hoje, as duas sobre silver.entregas_fornecedor.
     Tema nas cores da Jornada: #0059DB, #22C2F4, fundo #14141A no escuro.
   - resources/dashboard.dashboard.yml: recurso dashboard_portfolio, display
     name "Projeto Farol · Portfólio", dataset_catalog ${var.catalog},
     dataset_schema gold, warehouse ${var.warehouse_id}.
   Antes do deploy, rode cada query do dashboard (prefixando
   lakehouse_vertice.gold. nas tabelas gold) e me mostre a contagem de linhas de cada uma.

2. Genie Agent como código
   - scripts/gerar_genie.py gera resources/farol.geniespace.json
     (serialized_space versão 2; ids de 32 caracteres hex, únicos e em ordem):
     tabelas gold.fato_projeto_semana, gold.projeto_situacao_atual,
     gold.status_estruturado, gold.utilizacao_pessoa_semana e
     silver.entregas_fornecedor, e a metric view gold.mv_projetos; as 4 perguntas do dono como perguntas de
     exemplo; instruções de texto com: quem pergunta (o dono e o CTO); HOJE =
     2026-10-16 e o que é "últimos 90 dias / 12 semanas / próximo mês"; as
     fórmulas e as regras de corte; mv_projetos para totais de hoje e
     projeto_situacao_atual para ranking; PV/EV/AC acumulados no fato (nunca
     somar semanas); farol e melancia; "por que o projeto X atrasou" responde
     com status_estruturado dos últimos 90 dias (sem sem_bloqueio e
     nao_reportado), mais o SPI e SREs ociosos se a causa for falta_sre;
     gente parada = utilização < 20% em 12 semanas; fornecedor = prazo real ÷
     prometido na silver.entregas_fornecedor; "o que vai dar errado no
     próximo mês" junta as entregas de consultoria em atraso e o change
     freeze de varejo (01/11/2026 a 10/01/2027) nos projetos de e-commerce
     (o modelo de previsão vem na noite 3); "quais clientes" devolve cada
     cliente uma vez. E um exemplo de SQL para
     cada uma das 4 perguntas do dono.
   - resources/genie.genie_space.yml: recurso genie_farol, título
     "Farol · Diretoria".

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle summary --profile <perfil>
  python3 scripts/genie.py perguntar "Farol · Diretoria" "Tenho gente parada enquanto outro projeto pede gente?" --profile <perfil>
  python3 scripts/genie.py benchmark "Farol · Diretoria" aulas/aula-02-engenheiro/prd/genie-benchmark.json --profile <perfil>
Se o benchmark der menos de 16/20, mostre os erros e ajuste a INSTRUÇÃO
(não a pergunta), gere o JSON, faça deploy e rode de novo.
```

---

## Fim da noite 2 · confira antes de seguir

```bash
python3 scripts/run_sql.py aulas/aula-02-engenheiro/prd/99-verificacao.sql --profile <perfil>
# 20 linhas, todas "ok"
```

```sql
SELECT situacao, COUNT(*) FROM lakehouse_vertice.gold.projeto_situacao_atual GROUP BY 1;
-- crítico 7 · atenção 10 · ok 24 · concluído 19
SELECT MEASURE(estouro_previsto), MEASURE(projetos_melancia) FROM lakehouse_vertice.gold.mv_projetos;
-- R$ 6.465.127,22 · 4
```

O job `vertice_farol` tem **6 tarefas** e roda verde de ponta a ponta. Se estes números não
baterem, não adianta seguir: a noite 3 treina em cima deles.

---
## Noite 3 · o pipeline passa a prever

### Prompt 7 · Features

*o que descreve um projeto que vai estourar* · noite 3 · deploy nº 7 (bundle deploy) · [texto completo, com o que falar e as armadilhas](aulas/aula-03-cientista/prd/prompt-01-features.md)

```
Leia aulas/aula-02-engenheiro/prd/CLAUDE.md. Vamos continuar o MESMO bundle
em aulas/aula-02-engenheiro/meu-vertice/: ML é mais uma camada do pipeline,
não um projeto à parte. O "hoje" é DATE'2026-10-16'. Nunca current_date().

Crie src/ml/01-features.sql (sql_task). Primeiro CREATE SCHEMA IF NOT EXISTS
lakehouse_vertice.ml (o laboratório do cientista; na gold só vai o score).
Depois recrie lakehouse_vertice.ml.features_projeto_semana: uma linha por
projeto e semana (sexta-feira), a partir de gold.fato_projeto_semana +
gold.projeto_situacao_atual (o cadastro: início, duração, segmento).
COMMENT na tabela. Toda feature olha SÓ para trás (até a sexta da linha):

- spi, cpi, indice_min = least(spi, cpi)
- d_spi_4s, d_cpi_4s, d_spi_8s, d_cpi_8s (variação em 4 e 8 semanas, com lag())
- d_indice_min_4s
- semanas_cpi_caindo: em quantas das últimas 4 semanas o CPI caiu
- cpi_ultimas_4s = (ev - ev de 4 semanas atrás) / (ac - ac de 4 semanas atrás)
- spi_ultimas_4s = o mesmo com pv
- pct_fisico = ev / orcamento; pct_prazo = dias desde o início / duração baseline
- ociosidade_4s = horas ociosas / horas disponíveis das últimas 4 semanas
- pct_consultoria_4s e pct_cloud_4s: participação no custo das últimas
  4 semanas (silver.custos, pela coluna semana)
- saidas_12s: pessoas do squad que se desligaram nas últimas 12 semanas.
  Squad = quem apontou hora no projeto (silver.apontamentos) + data de
  desligamento em silver.colaboradores
- status_freeze_4s, status_falta_sre_4s, status_fornecedor_4s,
  status_rotatividade_4s, status_escopo_4s, status_retrabalho_4s,
  status_com_bloqueio_4s: quantos dos status dos últimos 28 dias tiveram
  cada causa_bloqueio (gold.status_estruturado; vale qualquer método,
  IA ou palavra-chave, porque a causa existe em todas as semanas)

Os dois alvos, do FUTURO, que nunca entram como feature:
- alvo_pior_indice_30d: o menor least(spi, cpi) nas 4 semanas SEGUINTES
  (MIN ... ROWS BETWEEN 1 FOLLOWING AND 4 FOLLOWING)
- estoura_30d: 1 se esse pior índice < 0,9, senão 0
Os dois NULL quando ainda não há 4 semanas de futuro (é o caso de hoje).

elegivel = 1 se SPI e CPI >= 0,9, o projeto tem 84+ dias, ev < 98% do
orçamento e (status = em_andamento ou a semana é anterior a hoje).

ARMADILHA MEDIDA: o Spark não aceita estender uma janela nomeada com frame
(OVER (w ROWS BETWEEN ...) dá PARSE_SYNTAX_ERROR). Escreva o PARTITION BY
e o ORDER BY por extenso nas janelas com ROWS BETWEEN.

No fim do arquivo, uma query de conferência: linhas, linhas de treino
(elegível com rótulo), taxa base e linhas de hoje.

Acrescente ao job vertice_farol a tarefa ml_features (sql_task), depois de
metricas_governadas. Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run vertice_farol --only ml_features --profile <perfil>
```

### Prompt 8 · Modelo e MLflow

*o baseline primeiro* · noite 3 · deploy nº 8 (bundle deploy) · [texto completo, com o que falar e as armadilhas](aulas/aula-03-cientista/prd/prompt-02-modelo.md)

```
Continue o bundle em aulas/aula-02-engenheiro/meu-vertice/. Crie o notebook
src/ml/02-modelo.py (# Databricks notebook source, widget catalog) e a
tarefa ml_modelo (notebook_task, depois de ml_features).

ARMADILHAS MEDIDAS NO FREE EDITION (siga todas):
- O serverless vem com MLflow 2.11, e registrar modelo no Unity Catalog
  falha com "s3:PutObject ... explicit deny". Primeira célula:
  %pip install -q -U "mlflow-skinny[databricks]>=2.21,<3"
  e dbutils.library.restartPython() na seguinte.
- XGBoost treina e não carrega de volta: use HistGradientBoosting do sklearn.
- DECIMAL vira Decimal no pandas e quebra o registro: .astype(float).
- mlflow.set_experiment não cria a pasta pai: WorkspaceClient().workspace
  .mkdirs("/Users/<eu>/vertice") antes.
- MLflow 2.x: log_model(..., artifact_path="modelo"), nunca name=.
- Toda célula de texto começa com "# MAGIC %md": sem ela o notebook quebra
  com SyntaxError na linha do texto.

O notebook, nesta ordem:
1. Lê ml.features_projeto_semana (24 features: todas as colunas do prompt 1
   menos segmento, farol_do_gerente, elegivel e os dois alvos). Teste = elegíveis com rótulo e semana >=
   2026-04-03. Treino = rotulados com semana <= 2026-03-06 e pct_prazo > 0,15
   (inclui projetos já abaixo de 0,9: eles ensinam como um projeto afunda).
2. BASELINES no teste, impressos antes de qualquer treino: regra de corte
   atual (0,5), folga até o corte (-indice_min), só o CPI, tendência
   (-d_indice_min_4s).
3. Modelo: HistGradientBoostingRegressor(random_state=42, max_depth=3,
   learning_rate=0.05, max_iter=300, min_samples_leaf=20) prevendo
   alvo_pior_indice_30d - indice_min. pior_previsto = indice_min + previsão.
   sigma = desvio do erro no teste. prob = P(pior < 0,9) com erro normal
   (math.erf). Compare com um HistGradientBoostingClassifier sim/não.
4. Métrica do dono: um estouro é o projeto que vinha 4 semanas com SPI e CPI
   >= 0,9, cruza para baixo e FICA abaixo por 2 semanas seguidas (pct_prazo
   > 0,15), a partir de 4 semanas depois do início do teste. Avisado =
   esteve no top 5 da semana (rank por prob) em alguma das 8 semanas
   anteriores. Imprima avisados/estouros, antecedência média em dias e o
   estouro previsto hoje (gold.projeto_situacao_atual) desses projetos.
5. Importância por permutação.
6. Testes com assert, ANTES de registrar: AUC >= 0,75; AUC < 0,98 (acima
   disso é vazamento); AUC >= a folga até o corte (senão, use a regra);
   avisados >= 70% dos estouros.
7. Retreine com TODOS os rotulados, registre em
   lakehouse_vertice.ml.modelo_estouro_30d com input_example, alias @prod.
8. Grave ml.modelo_metricas (uma linha: versão, auc, todas as réguas,
   sigma, estouros, avisados e quais, antecedência, estouro avisado,
   feature principal).

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run vertice_farol --only ml_modelo --profile <perfil>
```

### Prompt 9 · Score em lote

*a probabilidade de estouro em 30 dias* · noite 3 · deploy nº 9 (bundle deploy) · [texto completo, com o que falar e as armadilhas](aulas/aula-03-cientista/prd/prompt-03-score.md)

```
Continue o bundle em aulas/aula-02-engenheiro/meu-vertice/. Crie o notebook
src/ml/03-score.py (mesma primeira célula de %pip do 02-modelo) e a tarefa
ml_score (notebook_task, depois de ml_modelo).

1. Carregue o modelo com mlflow.sklearn.load_model("models:/lakehouse_vertice
   .ml.modelo_estouro_30d@prod") — NÃO use spark_udf: no serverless ele
   quebra com InvalidVersion. O sigma vem de ml.modelo_metricas.
2. Pontue os projetos em andamento na semana 2026-10-16 de
   ml.features_projeto_semana, com join em gold.projeto_situacao_atual:
   pior_previsto = indice_min + previsão; prob = P(pior < 0,9) com erro
   normal; quem tem least(spi, cpi) < 0,9 NA FOTOGRAFIA DE HOJE → 1,0.
3. ranking por prob desc (desempate: índice de hoje asc); faixa_risco alto
   se >= 0,5, medio se >= 0,2, senão baixo.
4. principais_fatores: os 2 ou 3 sinais mais graves em português, com
   números no padrão brasileiro (vírgula decimal). Sinais: já abaixo do
   corte (sempre primeiro), status semanal abaixo do corte e cronograma
   acima (as fontes não batem), folga < 0,05 até o corte, CPI caindo nas
   últimas semanas, cpi_ultimas_4s < 0,85 ("cada R$ 1 gasto no último mês
   entregou R$ X"), spi_ultimas_4s < 0,85, falta de SRE em 2+ dos últimos 4
   status, change freeze em 2+, rotatividade (saídas em 12 semanas ou citada
   no status), escopo crescendo em 2+, consultoria atrasando em 2+,
   ociosidade >= 25%. Sem sinal: "sem sinal de piora".
5. Grave lakehouse_vertice.gold.score_estouro_30d com EXATAMENTE as colunas
   projeto_id STRING, data_referencia DATE, prob_estouro_30d DOUBLE,
   ranking INT, faixa_risco STRING, principais_fatores STRING (overwrite).
   COMMENT na tabela e nas colunas: a noite 4 lê daqui.
6. Testes com assert: uma linha por projeto em andamento, prob entre 0 e 1,
   ranking único, nenhum motivo vazio.

Rode o job inteiro e me mostre o top 25:
  databricks bundle deploy --profile <perfil>
  databricks bundle run vertice_farol --profile <perfil>
```

---

## Fim da noite 3 · confira antes de seguir

```bash
python3 scripts/run_sql.py aulas/aula-03-cientista/99-verificacao.sql --profile <perfil>
# 17 linhas, todas "ok"
```

```sql
SELECT faixa_risco, COUNT(*) FROM lakehouse_vertice.gold.score_estouro_30d GROUP BY 1;
-- alto 18 · medio 4 · baixo 19
SELECT projeto_id, prob_estouro_30d FROM lakehouse_vertice.gold.score_estouro_30d WHERE projeto_id = 'PRJ-024';
-- PRJ-024 · 0,49  (o e-commerce "ok" que o modelo vê chegando, com o freeze de 01/11 na porta)
```

O job `vertice_farol` agora tem **9 tarefas** e roda verde em ~4 a 5 min. A noite 4 lê
`gold.score_estouro_30d`: se ela não existir, o app mostra "—" na coluna de risco.

---
## Noite 4 · o projeto ganha uma URL

### Prompt 10 · O agente que lê contrato

*o PDF que ninguém lê vira resposta* · noite 4 · deploy nº 10 (Genie publicado) · [texto completo, com o que falar e as armadilhas](aulas/aula-04-engenheiro-ia/prd/prompt-01-agente-de-contratos.md)

```
Leia aulas/aula-04-engenheiro-ia/prd/CLAUDE.md antes de começar. Use a skill
databricks-ai-functions.

Crie a pasta aulas/aula-04-engenheiro-ia/meu-agente/ com o agente que lê os 8
contratos de fornecedor da Vértice. Perfil: <perfil> (sempre --profile).
Objetivo: gold enxuta. Só UMA tabela nova na gold; nada de views.

1. meu-agente/01-contratos.sql, executável com
   python3 scripts/run_sql.py meu-agente/01-contratos.sql --profile <perfil>
   (API de statements, não o aitools query). COMMENT em toda tabela (é o que o Genie lê).
   a) silver.documentos_elementos: read_files (binaryFile) dos PDFs em
      /Volumes/lakehouse_vertice/bronze/raw/documentos/contratos/,
      ai_parse_document(content, map('version','2.0')), posexplode dos elementos:
      documento, ordem, tipo (title/section_header/text), conteudo.
   b) silver.contratos_clausulas: uma linha por cláusula (fornecedor, clausula_numero INT,
      titulo, texto). Cada texto pertence à última section_header "CLÁUSULA N - TÍTULO"
      antes dele (last_value ignorando nulos). O fornecedor sai da linha "CONTRATADA: ...".
   c) Um SELECT de demonstração com ai_extract SEM schema (lista de nomes de campo) em 3
      contratos, para a turma ver que volta texto.
   d) gold.contratos, uma linha por contrato: ai_extract(texto do contrato, JSON schema,
      map('version','2.0')) com objeto, valor_anual (number), data_fim_vigencia (string
      AAAA-MM-DD), renovacao_automatica (boolean), aviso_previo_dias (integer),
      multa_atraso_pct_dia (number, nulo se não há), teto_multa_pct (number), sla e
      reajuste (string). Descrição em cada campo; "em português" nos campos de texto.
      Leia com :response:campo::TIPO. Guarde também clausulas = o texto de todas as
      cláusulas, cada uma com "CLÁUSULA N - TÍTULO:" na frente.
   e) No fim, duas CONSULTAS (não views) sobre gold.contratos, com hoje = 16/10/2026:
      - multa a cobrar por fornecedor: silver.entregas_fornecedor entregue com atraso ou
        em aberto vencida; dias de atraso até a entrega (ou até hoje); multa = valor ×
        least(dias × multa % ao dia, teto) / 100; só o prometido na vigência atual
        (data_prometida > add_months(data_fim_vigencia, -12));
      - aviso prévio: data limite = data_fim_vigencia − aviso_previo_dias e dias até ela.

2. meu-agente/gerar_genie.py: escreve meu-agente/diretoria-contratos-genie.json (NÃO use a
   extensão .geniespace.json) com gold.contratos, gold.projeto_situacao_atual,
   gold.status_estruturado, gold.utilizacao_pessoa_semana, silver.entregas_fornecedor e a
   metric view gold.mv_projetos. Inclua gold.score_estouro_30d SÓ se existir (databricks
   tables exists). Instruções: a Vértice é a CONTRATANTE (multa é dinheiro que ela cobra);
   hoje = 16/10/2026; cite o número da cláusula; a conta da multa e do aviso prévio acima.
   Exemplos de SQL para "quanto cobrar da CodeForge", "aviso prévio", "por que o PRJ-011
   atrasou" e "tenho SRE parado para o PRJ-011".

3. Publique e teste:
   python3 scripts/genie.py publicar meu-agente/diretoria-contratos-genie.json \
     --titulo "Farol · Diretoria + Contratos" --profile <perfil>
   python3 scripts/genie.py benchmark "Farol · Diretoria + Contratos" \
     aulas/aula-04-engenheiro-ia/prd/genie-benchmark.json --profile <perfil>
   Se errar, ajuste as instruções (não as perguntas) e publique de novo.
```

### Prompt 11 · O app da Torre

*a Torre na tela do dono* · noite 4 · deploy nº 11 (apps deploy) · [texto completo, com o que falar e as armadilhas](aulas/aula-04-engenheiro-ia/prd/prompt-02-app.md)

```
Leia aulas/aula-04-engenheiro-ia/prd/CLAUDE.md. Use as skills databricks-apps e
databricks-app-design.

1. Confira `databricks apps list --profile <perfil>` (limite de 3 apps no Free Edition).
   Mova aulas/aula-04-engenheiro-ia/meu-agente/ para dentro do app (minha-torre/agente/)
   e crie o app:
   cd aulas/aula-04-engenheiro-ia && databricks apps init --name minha-torre \
     --features analytics,genie \
     --set analytics.sql-warehouse.id=<warehouse> \
     --set genie.genie-space.id=<id do Genie "Farol · Diretoria + Contratos"> \
     --set "genie.genie-space.name=Farol · Diretoria + Contratos" \
     --run none --profile <perfil>
   Inclua no databricks.yml um job farol_contratos (sql_task com agente/01-contratos.sql)
   em resources/contratos.job.yml.

2. config/queries (apague os exemplos do template):
   - kpis.sql: projetos em andamento, em risco (atenção+crítico), críticos, melancias,
     estouro previsto e carteira (projeto_situacao_atual), alto risco em 30 dias
     (faixa_risco = 'alto' na data_referencia mais recente de score_estouro_30d) e multa a
     cobrar de fornecedor, calculada na própria query com gold.contratos +
     silver.entregas_fornecedor (a mesma conta do prompt 1, só a vigência atual).
   - projetos_risco.sql: projetos em andamento do pior para o melhor, com SPI, CPI, estouro,
     atraso projetado, farol do gerente × calculado, melancia, a causa mais frequente no
     status_estruturado dos últimos 90 dias, os dias de impacto por falta_sre e por
     rotatividade e multa a cobrar por projeto (mesma conta da multa).
   - pessoas_ociosas.sql: pessoas com utilização < 20% nas últimas 12 semanas
     (utilizacao_pessoa_semana), com horas paradas e custo ocioso MÉDIOS por semana e custo_hora.
   A probabilidade por projeto (gold.score_estouro_30d, da noite 3) vem de uma rota
   GET /api/score-estouro no servidor que responde {disponivel, linhas}.

3. Telas (português, R$, índices com 2 casas, Number() em tudo que vem do warehouse):
   - Projetos em risco: 4 KPIs + tabela (situação com cor: crítico vermelho, atenção âmbar;
     farol do gerente com 🍉 quando é melancia), coluna P(estouro) com "—" sem o modelo.
   - Simulador: escolher uma pessoa ociosa e um projeto destino (só atenção/crítico; para SRE,
     ordene pelos dias de falta_sre); mostrar horas no mês (× 4 semanas), ociosidade que deixa
     de ser paga, dias de cronograma recuperados (dias de impacto da causa nos últimos 90 dias
     ÷ 90 × 30), mobilização = horas de onboarding (editável, 40) × custo_hora, e saldo.
     Explique a conta num <details>.
   - Perguntar: <GenieChat alias="default" />.
   Sem cache no createApp. Título "Projeto Farol".

4. npm run typecheck, npm run lint, npm test, databricks apps validate.
   Depois: databricks bundle deploy --profile <perfil> (cria o app e o service principal).
   Crie scripts/conceder-acesso.sh (lê o service_principal_client_id com apps get e dá
   USE CATALOG em lakehouse_vertice e USE SCHEMA + SELECT na gold e na silver), rode e faça
   databricks apps deploy --profile <perfil>. Me mostre a URL.
```

### Prompt 12 · A aprovação no Lakebase

*a decisão fica registrada* · noite 4 · deploy nº 12 (apps deploy) · [texto completo, com o que falar e as armadilhas](aulas/aula-04-engenheiro-ia/prd/prompt-03-aprovacao-lakebase.md)

```
Leia aulas/aula-04-engenheiro-ia/prd/CLAUDE.md. Use as skills databricks-apps e
databricks-lakebase. O app minha-torre já está no ar (prompt 2).

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
bash aulas/aula-02-engenheiro/prd/00-reset.sh <perfil>             # simula
bash aulas/aula-02-engenheiro/prd/00-reset.sh <perfil> --apagar    # apaga silver, gold e os recursos do bundle
bash aulas/aula-03-cientista/prd/99-limpar-aula-03.sh <perfil>     # simula; --apagar tira features, modelo e score
bash aulas/aula-04-engenheiro-ia/prd/99-limpar-aula-04.sh <perfil> # simula; --apagar tira contratos, app e Lakebase
```
