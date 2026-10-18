# 🧾 Os prompts, na ordem

A Torre de Controle da Atlas Engenharia — da bronze crua ao Genie que explica
por que a obra atrasou — sai de **prompts colados em sequência no Claude Code**.
Este arquivo é a sequência inteira, na ordem, para quem quer refazer sozinho.

> **Cada prompt termina com um deploy.** Não junte dois: o valor do formato
> está em ver a coisa subir uma camada por vez, e em quebrar cedo quando quebra.

| Noite | Prompts | O que existe no fim |
|---|---|---|
| [**2** · engenheiro de dados](aulas/aula-02-engenheiro) | 1 a 6 | bundle, pipeline declarativo silver + gold, RDO com IA, 5 metric views, dashboard e Genie |
| [**3** · cientista de dados](aulas/aula-03-cientista) | 7 a 9 | modelo de estouro em 30 dias no Unity Catalog e o score em lote |
| [**4** · engenheiro de IA](aulas/aula-04-engenheiro-ia) | 10 a 12 | Genie da diretoria, o app da Torre e o agente de contratos |

---

## Antes do primeiro prompt

A noite 1 precisa estar feita: o catálogo `lakehouse_atlas` com a bronze
carregada (12 tabelas). Se não estiver, rode o
[`00-carregar-dados`](aulas/aula-01-analista/00-carregar-dados.py) e o
[`01-ingestao-bronze.sql`](aulas/aula-01-analista/01-ingestao-bronze.sql).

```bash
# 1 · a CLI do Databricks (v0.250 ou mais nova) e o login
brew tap databricks/tap && brew install databricks     # Windows: winget install Databricks.DatabricksCLI
databricks auth login --profile <perfil>
databricks auth profiles                                # o seu aparece com Valid: YES

# 2 · o Claude Code e as skills oficiais do Databricks
npm install -g @anthropic-ai/claude-code
databricks aitools install

# 3 · conferir que a bronze está lá
python3 scripts/run_sql.py aulas/aula-01-analista/99-verificacao.sql --profile <perfil>
```

**A pasta `aulas/aula-02-engenheiro/meu-atlas/` nasce vazia** — é o prompt 1 que
a preenche. A pasta `atlas/` ao lado é o gabarito. Se você já rodou antes, zere
com `BUNDLE_DIR=aulas/aula-02-engenheiro/meu-atlas bash aulas/aula-02-engenheiro/prd/00-reset.sh <perfil> --apagar`.

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

Crie o projeto da noite 2 em aulas/aula-02-engenheiro/meu-atlas/ como um
Databricks Asset Bundle chamado atlas. Esta é a primeira de seis entregas: as
outras cinco estendem este mesmo bundle, então deixe a estrutura pronta para
crescer (resources/, src/conferencia, src/silver, src/gold, src/ia,
src/metricas, src/testes, scripts/). NÃO copie da pasta atlas/ (é o gabarito).

CONTEXTO DO WORKSPACE
- profile: <perfil>   (sempre passe --profile, nunca deixe implícito)
- descubra o SQL Warehouse com `databricks warehouses list --profile <perfil>`
- Databricks Free Edition: tudo serverless, nunca configure cluster
- o catálogo lakehouse_atlas e os schemas bronze/silver/gold JÁ EXISTEM
  (noite 1). O bundle NÃO cria nem gerencia catálogo nem schema.

1. databricks.yml
   - bundle name: atlas; include: resources/*.yml
   - variables: catalog (default lakehouse_atlas) e warehouse_id (o id que
     você descobriu)
   - targets dev (default) e prod
   - ARMADILHA: NÃO use `mode: development` no dev. Ele prefixa os nomes com
     [dev seu_usuario] e quebra o SQL. Pause o agendamento com
     `presets: { trigger_pause_status: PAUSED }`. Deixe um comentário no YAML
     explicando isso.
   - prod: mode production, root_path em /Workspace/Users/${workspace.current_user.userName}/.bundle/${bundle.name}/${bundle.target}

2. resources/atlas.job.yml
   - job atlas_torre, agendado todo dia às 6h (America/Sao_Paulo)
   - uma tarefa por enquanto: conferencia_bronze, sql_task no warehouse
     ${var.warehouse_id} com o arquivo ../src/conferencia/00-conferencia-bronze.sql
   - comentário no topo listando as tarefas que os próximos prompts vão
     acrescentar (medalhao, testes_de_qualidade, rdo_com_ia, metricas_governadas)

3. src/conferencia/00-conferencia-bronze.sql
   Confere as 12 tabelas da bronze contra a contagem esperada (seed 42):
   projetos 40 · tarefas 8000 · avanco_semanal 55703 · custos 19445 ·
   compras 13304 · materiais 25 · estoque 40094 · equipes 123 ·
   apontamentos 41190 · equipamentos 300 · uso_equipamentos 19817 · rdo 13730
   Uma linha por tabela com esperado e obtido; se alguma divergir, chame
   raise_error() com uma mensagem que diga qual tabela e o que fazer
   (rodar de novo o 00-carregar-dados e o 01-ingestao-bronze da noite 1).

Rode e me mostre a saída de cada um:
  databricks bundle validate --profile <perfil>
  databricks bundle deploy --profile <perfil>
  databricks bundle run atlas_torre --profile <perfil>
```

### Prompt 2 · Silver

*a limpeza com contrato* · noite 2 · deploy nº 2 (bundle deploy + run do pipeline) · [texto completo, com o que falar e as armadilhas](aulas/aula-02-engenheiro/prd/prompt-02-silver.md)

```
Continue o bundle em aulas/aula-02-engenheiro/meu-atlas/. A bronze está
conferida. Agora a silver: limpar, tipar e declarar o contrato.

Crie um pipeline Lakeflow Spark Declarative Pipelines em SQL:
resources/atlas_medalhao.pipeline.yml com name atlas_medalhao, catalog
${var.catalog}, schema silver, serverless: true, photon: true, e libraries com
um glob em ../src/silver/** (o prompt 3 vai acrescentar ../src/gold/**).

Use CREATE OR REFRESH MATERIALIZED VIEW (nunca CREATE OR REPLACE, que não
existe no pipeline). Leia a bronze pelo nome completo
lakehouse_atlas.bronze.<tabela>; dentro do pipeline, referencie as tabelas
silver só pelo nome. COMMENT em toda tabela dizendo o que foi limpo.

Um arquivo por assunto em src/silver/:

01-projetos.sql
- data_inicio vem em yyyy-MM-dd e dd/MM/yyyy: coalesce de dois try_to_date.
  Guarde data_veio_em_formato_br (boolean).
- uf vem 'MG', 'mg', ' MG ': upper(trim()).
- valor_contrato e orcamento_custo (renomeie para orcamento) em DECIMAL(18,2).
- EXPECT data_inicio IS NOT NULL e length(uf) = 2, ambos FAIL UPDATE.

02-cronograma.sql — avanco_semanal e tarefas
- avanco_semanal tipado (data_medicao DATE, pct_concluido DOUBLE), EXPECT
  pct entre 0 e 100.
- tarefas: 52 tarefas têm pct_concluido > 100. NÃO corte em 100. Use a ÚLTIMA
  medição do boletim (o % só sobe, então max(pct) por tarefa no
  avanco_semanal) e marque pct_corrigido_pela_medicao. EXPECT pct entre 0 e
  100 e valor_planejado > 0, FAIL UPDATE.

03-custos.sql
- valor_real tem 540 linhas com vírgula decimal: replace(',', '.') ANTES do
  CAST. Nunca try_cast (jogaria R$ 16,8 mi fora em silêncio).
- estorno (valor negativo) FICA na tabela e ganha a coluna estorno.
- coluna semana = sexta-feira da semana: date_add(date_trunc('WEEK', data), 4).
- EXPECT valor IS NOT NULL, FAIL UPDATE.

04-suprimentos.sql — materiais, compras, estoque
- compras: o mesmo fornecedor vem com 4 grafias ('Metalúrgica Norte Aço
  Ltda', 'Metalurgica Norte Aco', 'METALÚRGICA NORTE AÇO LTDA', 'Norte Aço
  Metalúrgica'). Normalize tudo que tiver 'norte a' para
  'Metalúrgica Norte Aço Ltda' e guarde fornecedor_como_veio.
  data_entrega vazia = pedido em aberto (não é sujeira). Crie
  lead_time_real_dias, em_aberto e em_atraso (em aberto e data_prometida
  antes de DATE'2026-10-16').
- estoque: saldo negativo (erro de inventário) vira 0 com flag.

05-recursos.sql — equipes, apontamentos, equipamentos, uso_equipamentos
- equipes: EQP014, EQP057 e EQP101 aparecem duas vezes (função em CAIXA ALTA,
  UF em minúscula, headcount diferente). DISTINCT não resolve. Mantenha o
  cadastro com funcao em minúsculas (row_number por equipe_id).
- apontamentos e uso_equipamentos com coluna semana (sexta-feira), como em custos.

06-rdo.sql
- rdo: 82 RDOs vazios ('', 'N/A', 'ver RDO físico'). NÃO descarte: flag rdo_vazio.

Acrescente ao job atlas_torre a tarefa medalhao (pipeline_task apontando para
${resources.pipelines.atlas_medalhao.id}), depois de conferencia_bronze.

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run atlas_medalhao --profile <perfil>
```

### Prompt 3 · Gold

*o produto de dados e as três perguntas* · noite 2 · deploy nº 3 (bundle deploy + run) · [texto completo, com o que falar e as armadilhas](aulas/aula-02-engenheiro/prd/prompt-03-gold.md)

```
Continue o bundle em aulas/aula-02-engenheiro/meu-atlas/. A silver está pronta.
Agora a gold, no MESMO pipeline atlas_medalhao: acrescente o glob
../src/gold/** em libraries. Os arquivos da gold escrevem com o nome completo
lakehouse_atlas.gold.<tabela>; leem a silver pelo nome curto. COMMENT em todas.
O "hoje" é DATE'2026-10-16'. Nunca current_date().

src/gold/01-fato-projeto-semana.sql → lakehouse_atlas.gold.fato_projeto_semana
Uma linha por obra e semana (sexta-feira), da semana do início da obra até
2026-10-16 (sequence(..., INTERVAL 1 WEEK) + explode). Colunas:
- pv: Σ valor_planejado × fração do baseline decorrida até a semana
  (greatest(0, least(1, datediff(semana, inicio)/datediff(fim, inicio))))
- ev: acumulado do avanço medido. Para cada tarefa, delta = pct - lag(pct)
  por data_medicao; ev_semana = Σ valor_planejado × delta / 100; depois soma
  acumulada por obra.
  ARMADILHA MEDIDA: o pipeline recusa função de janela dentro de agregação
  ("It is not allowed to use a window function inside an aggregate
  function"). Faça o lag() num CTE e o SUM no CTE seguinte.
- ac: custo real acumulado (silver.custos por semana, soma acumulada)
- spi = ev/pv, cpi = ev/ac (try_divide, 4 casas), eac = orcamento / cpi
- horas_disponiveis, horas_apontadas e horas_ociosas da semana (apontamentos)
- rupturas_previstas: para cada saldo semanal de estoque, a próxima entrega
  PROMETIDA ainda em aberto naquela data (pedido feito até a data e não
  entregue até a data). Ruptura = consumo_previsto_dia > 0 e
  saldo/consumo < dias até essa entrega; se a promessa já venceu, use o
  lead_time_contratado_dias do material.
- EXPECT pv >= 0 e ev <= orcamento, FAIL UPDATE.

src/gold/02-dim-e-marts.sql
- dim_projeto: obra (projeto_id · nome), cliente, setor, uf, contrato,
  orçamento, datas, duracao_baseline_dias, status, gerente.
- obra_situacao_atual: a fotografia de 2026-10-16 de cada obra (40 linhas):
  pv, ev, ac, spi, cpi, eac, estouro_previsto = greatest(eac - orcamento, 0),
  margem_projetada, atraso_projetado_dias, termino_projetado,
  rupturas_previstas e situacao: 'concluída' se status <> em_andamento;
  'crítico' se SPI ou CPI < 0,8; 'atenção' se < 0,9; senão 'ok'.
- utilizacao_equipe_semana: equipe × semana com horas disponíveis,
  apontadas, ociosas, utilizacao e o spi_da_obra naquela semana.
- utilizacao_equipamento_semana: equipamento × semana com tipo, modelo, obra,
  uf, utilizacao, horas_paradas e custo_ocioso (horas paradas × custo_hora).
- desempenho_fornecedor: por fornecedor normalizado: pedidos, grafias_no_erp,
  lead time prometido e real médios, fator_atraso (real/prometido),
  pct_no_prazo, pedidos_em_atraso, valor_comprado.
- cobertura_estoque: material × obra em andamento HOJE: saldo, consumo,
  cobertura_dias, próxima entrega prometida e fornecedor, dias_ate_reposicao
  e ruptura_prevista (mesma regra do fato).
- pedidos_em_atraso: pedidos em aberto com data prometida antes de hoje.

src/testes/testes.sql (sql_task) — cada teste com raise_error se falhar:
 1 uma linha por equipe na silver
 2 a Norte Aço virou um fornecedor só
 3 a limpeza não mudou o custo total (bronze com replace = silver)
 4 nenhuma tarefa acima de 100%
 5 as 40 obras têm fotografia de hoje
 6 toda obra em andamento tem SPI e CPI
 7 EV de hoje no fato = Σ valor_planejado × pct da silver.tarefas
 8 AC de hoje no fato = soma dos lançamentos até hoje

Acrescente ao job a tarefa testes_de_qualidade, depois de medalhao.

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run atlas_torre --profile <perfil>
```

### Prompt 4 · RDO com IA

*o texto livre vira coluna* · noite 2 · deploy nº 4 (bundle deploy + run) · [texto completo, com o que falar e as armadilhas](aulas/aula-02-engenheiro/prd/prompt-04-rdo-com-ia.md)

```
Continue o bundle em aulas/aula-02-engenheiro/meu-atlas/. Agora o RDO, que é
texto livre, vira coluna.

Crie src/ia/rdo_estruturado.sql (sql_task, caminho completo das tabelas):

1. CREATE TABLE IF NOT EXISTS lakehouse_atlas.gold.rdo_estruturado com COMMENT
   em cada coluna: rdo_id, projeto_id, data, clima, causa_atraso,
   dias_impacto (DOUBLE), incidente (BOOLEAN), metodo ('regra', 'ia' ou
   'palavra_chave'), texto_livre, _classificado_em.
   NÃO é CREATE OR REPLACE: a tabela acumula, e a IA não pode ser refeita
   a cada execução.

2. MERGE INTO ... WHEN NOT MATCHED THEN INSERT, só com os RDOs da
   silver.rdo que ainda não estão na tabela (LEFT ANTI JOIN). Para cada RDO:
   - metodo = 'regra' se rdo_vazio ou se o texto (em minúsculas) bate com
     'sem ocorr|ocorrências: nenhuma|dia produtivo';
     metodo = 'ia' se data >= DATE'2026-07-18' (últimos 90 dias até
     2026-10-16); senão 'palavra_chave'.
   - causa_atraso: 'nao_reportado' se vazio; 'sem_ocorrencia' pela regra;
     ai_classify(texto_livre, array('chuva', 'falta_material',
     'falta_equipamento', 'mao_de_obra', 'retrabalho', 'cliente',
     'sem_ocorrencia')) para metodo = 'ia' — chame a IA num CTE SÓ com essas
     linhas e junte depois, para nunca chamá-la à toa;
     palavra-chave para o resto, nesta ordem: guindaste|içamento →
     falta_equipamento; cliente|permissão de trabalho → cliente;
     chuva|precipitação|temporal|encharcado → chuva;
     aguardando|falta de|não entregou|em estoque|fornecedor → falta_material;
     efetivo reduzido|faltas|rotatividade|soldadores → mao_de_obra;
     retrabalho|reprovad → retrabalho.
   - clima: regexp_extract de 'clima: (palavra)'.
   - dias_impacto: 'impacto estimado de N dias' → N; 'impacto estimado: 1
     dia' → 1; 'meio turno' → 0,5; 'sem impacto' → 0; senão nulo.
   - incidente: o texto cita 'quase acidente'.

3. No fim, um SELECT da contagem por metodo e causa_atraso, para a saída da
   tarefa mostrar o que a IA fez.

No comentário do topo do arquivo, registre a decisão e o número medido:
ai_classify faz ~3,7 RDOs/s; 13,7 mil levariam ~1 hora; os ~1.000 com
ocorrência dos últimos 90 dias levam ~3 minutos.

Acrescente ao job a tarefa rdo_com_ia, depois de medalhao (em paralelo com
testes_de_qualidade).

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run atlas_torre --profile <perfil>
```

### Prompt 5 · Métricas governadas

*o KPI definido uma vez só* · noite 2 · deploy nº 5 (bundle deploy + run) · [texto completo, com o que falar e as armadilhas](aulas/aula-02-engenheiro/prd/prompt-05-metricas.md)

```
Continue o bundle em aulas/aula-02-engenheiro/meu-atlas/. Agora os KPIs
governados, como metric views do Unity Catalog.

Crie src/metricas/metricas.sql (sql_task) com CREATE OR REPLACE VIEW ...
WITH METRICS LANGUAGE YAML AS $$ ... $$, version 1.1, comment e synonyms em
português nas medidas principais:

1. lakehouse_atlas.gold.mv_obras — source gold.obra_situacao_atual,
   filter status = 'em_andamento'.
   Dimensões: projeto_id, obra, cliente, setor, uf, situacao, gerente_projeto.
   Medidas: obras, carteira, spi = SUM(ev)/SUM(pv), cpi = SUM(ev)/SUM(ac),
   eac, estouro_previsto, margem_projetada =
   (SUM(valor_contrato) - SUM(eac)) / SUM(valor_contrato),
   atraso_projetado_medio_dias, obras_em_risco (situação atenção ou crítico),
   obras_criticas.
2. lakehouse_atlas.gold.mv_evolucao — source gold.fato_projeto_semana com
   join em gold.dim_projeto (using projeto_id). Dimensões semana, mes, obra,
   uf, setor. Medidas spi, cpi, utilizacao_equipe, horas_ociosas,
   rupturas_previstas. Comente que PV/EV/AC são acumulados.
3. lakehouse_atlas.gold.mv_equipamentos — source
   gold.utilizacao_equipamento_semana: utilizacao_equipamento, horas_paradas,
   custo_ocioso por tipo, modelo, obra, uf, semana.
4. lakehouse_atlas.gold.mv_suprimentos — source gold.cobertura_estoque:
   rupturas_previstas, cobertura_media_dias, itens_monitorados.
5. lakehouse_atlas.gold.mv_fornecedores — source silver.compras com join em
   gold.dim_projeto: pedidos, pedidos_em_atraso, lead_time_real_medio_dias,
   fator_atraso_fornecedor (real / prometido).

No fim do arquivo, um SELECT com MEASURE() das medidas de mv_obras, para a
saída da tarefa provar que as views respondem.

ARMADILHA MEDIDA: rodar metric view pelo `databricks experimental aitools
tools query` achata a indentação do YAML e dá
METRIC_VIEW_INVALID_VIEW_DEFINITION. Rode como sql_task do job ou com
python3 scripts/run_sql.py <arquivo> --profile <perfil>.

Acrescente ao job a tarefa metricas_governadas, depois de
testes_de_qualidade E de rdo_com_ia.

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run atlas_torre --profile <perfil>
```

### Prompt 6 · Dashboard e Genie

*a diretoria pergunta em português* · noite 2 · deploy nº 6 (bundle deploy) · [texto completo, com o que falar e as armadilhas](aulas/aula-02-engenheiro/prd/prompt-06-dashboard-e-genie.md)

```
Continue o bundle em aulas/aula-02-engenheiro/meu-atlas/. O pipeline e as
métricas estão prontos. Agora as duas portas para quem não escreve SQL.

1. Dashboard como código
   - scripts/gerar_dashboard.py gera resources/dashboard-portfolio.lvdash.json
     (AI/BI, GRID_V1, queries com nome de tabela PURO, sem catálogo nem
     schema). Três páginas:
     Portfólio: KPIs da mv_obras com MEASURE() (carteira, SPI, CPI, obras em
       risco, críticas, estouro previsto); barra de estouro previsto por obra
       colorida por situação (crítico #FF5F46, atenção #F6C344, ok #22C2F4);
       dispersão SPI × CPI; linha de SPI e CPI semanais da carteira
       (mv_evolucao); tabela das obras em andamento.
     Recursos: top 15 equipamentos por custo ocioso (12 semanas), tabela da
       frota com utilização, horas ociosas de equipe por obra (8 semanas).
     Suprimentos: rupturas previstas por obra, tabela de fornecedores
       (grafias no ERP, lead time prometido x real, % no prazo, em atraso) e
       tabela de cobertura por material.
     Tema nas cores da Jornada: #0059DB, #22C2F4, fundo #14141A no escuro.
   - resources/dashboard.dashboard.yml: recurso dashboard_portfolio, display
     name "Torre de Controle · Portfólio", dataset_catalog ${var.catalog},
     dataset_schema gold, warehouse ${var.warehouse_id}.
   Antes do deploy, rode cada query do dashboard (prefixando
   lakehouse_atlas.gold.) e me mostre a contagem de linhas de cada uma.

2. Genie Agent como código
   - scripts/gerar_genie.py gera resources/torre.geniespace.json
     (serialized_space versão 2; ids de 32 caracteres hex, únicos e em ordem):
     tabelas gold (cobertura_estoque, desempenho_fornecedor, dim_projeto,
     fato_projeto_semana, obra_situacao_atual, pedidos_em_atraso,
     rdo_estruturado, utilizacao_equipamento_semana, utilizacao_equipe_semana)
     e as 5 metric views mv_*; as 4 perguntas de exemplo (as 3 da diretoria +
     "Por que a obra P011 atrasou?"); uma instrução de texto com: HOJE =
     2026-10-16 e o que é "últimos 90 dias / 12 semanas / 8 semanas"; as
     fórmulas e as regras de corte; usar mv_obras para KPIs de hoje; PV/EV/AC
     acumulados no fato (nunca somar semanas); "por que a obra X atrasou"
     responde com rdo_estruturado dos últimos 90 dias, sem sem_ocorrencia e
     nao_reportado, mais o SPI e equipamentos ociosos se a causa for
     falta_equipamento. E 5 exemplos de SQL, um deles para a P011.
   - resources/genie.genie_space.yml: recurso genie_torre, título
     "Torre de Controle · Diretoria".

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle summary --profile <perfil>
  python3 scripts/genie.py perguntar "Torre de Controle · Diretoria" "Por que a obra P011 atrasou?" --profile <perfil>
  python3 scripts/genie.py benchmark "Torre de Controle · Diretoria" aulas/aula-02-engenheiro/prd/genie-benchmark.json --profile <perfil>
Se o benchmark der menos de 16/20, mostre os erros e ajuste a INSTRUÇÃO
(não a pergunta), gere o JSON, faça deploy e rode de novo.
```
---

## Fim da noite 2 · confira antes de seguir

```bash
python3 scripts/run_sql.py aulas/aula-02-engenheiro/prd/99-verificacao.sql --profile <perfil>
# 17 linhas, todas "ok"
```

```sql
SELECT situacao, COUNT(*) FROM lakehouse_atlas.gold.obra_situacao_atual GROUP BY 1;
-- crítico 7 · atenção 6 · ok 23 · concluída 4
SELECT MEASURE(estouro_previsto) FROM lakehouse_atlas.gold.mv_obras;
-- R$ 42.364.558,31
```

O job `atlas_torre` tem **5 tarefas** e roda verde de ponta a ponta em ~5 min 40 s.
Se estes números não baterem, não adianta seguir: a noite 3 treina em cima deles.

---

## Noite 3 · o pipeline passa a prever

### Prompt 7 · Features

*o que descreve uma obra que vai estourar* · noite 3 · deploy nº 7 (bundle deploy) · [texto completo, com o que falar e as armadilhas](aulas/aula-03-cientista/prd/prompt-01-features.md)

```
Leia aulas/aula-02-engenheiro/prd/CLAUDE.md. Vamos continuar o MESMO bundle
em aulas/aula-02-engenheiro/meu-atlas/: ML é mais uma camada do pipeline,
não um projeto à parte. O "hoje" é DATE'2026-10-16'. Nunca current_date().

Crie src/ml/01-features.sql (sql_task) que recria a tabela
lakehouse_atlas.gold.features_obra_semana: uma linha por obra e semana
(sexta-feira), a partir de gold.fato_projeto_semana + gold.dim_projeto.
COMMENT na tabela. Toda feature olha SÓ para trás (até a sexta da linha):

- spi, cpi, indice_min = least(spi, cpi)
- d_spi_4s, d_cpi_4s, d_cpi_8s (variação em 4 e 8 semanas, com lag())
- d_indice_min_4s
- semanas_cpi_caindo: em quantas das últimas 4 semanas o CPI caiu
- cpi_ultimas_4s = (ev - ev de 4 semanas atrás) / (ac - ac de 4 semanas atrás)
- spi_ultimas_4s = o mesmo com pv
- pct_fisico = ev / orcamento; pct_prazo = dias desde o início / duração baseline
- ociosidade_4s = horas ociosas / horas disponíveis das últimas 4 semanas
- rupturas_previstas da semana
- pct_subcontrato_4s e pct_mao_de_obra_4s: participação no custo das
  últimas 4 semanas (silver.custos, pela coluna semana)
- rdo_chuva_4s, rdo_falta_material_4s, rdo_falta_equipamento_4s,
  rdo_mao_de_obra_4s, rdo_com_ocorrencia_4s: fração dos RDOs dos últimos
  28 dias com cada causa (gold.rdo_estruturado)

Os dois alvos, do FUTURO, que nunca entram como feature:
- alvo_pior_indice_30d: o menor least(spi, cpi) nas 4 semanas SEGUINTES
  (MIN ... ROWS BETWEEN 1 FOLLOWING AND 4 FOLLOWING)
- estoura_30d: 1 se esse pior índice < 0,9, senão 0
Os dois NULL quando ainda não há 4 semanas de futuro (é o caso de hoje).

elegivel = 1 se SPI e CPI >= 0,9, a obra tem 84+ dias, ev < 98% do
orçamento e (status = em_andamento ou a semana é anterior a hoje).

ARMADILHA MEDIDA: o Spark não aceita estender uma janela nomeada com frame
(OVER (w ROWS BETWEEN ...) dá PARSE_SYNTAX_ERROR). Escreva o PARTITION BY
e o ORDER BY por extenso nas janelas com ROWS BETWEEN.

No fim do arquivo, uma query de conferência: linhas, linhas de treino
(elegível com rótulo), taxa base e linhas de hoje.

Acrescente ao job atlas_torre a tarefa ml_features (sql_task), depois de
metricas_governadas. Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run atlas_torre --only ml_features --profile <perfil>
```

### Prompt 8 · Modelo e MLflow

*o baseline primeiro* · noite 3 · deploy nº 8 (bundle deploy) · [texto completo, com o que falar e as armadilhas](aulas/aula-03-cientista/prd/prompt-02-modelo.md)

```
Continue o bundle em aulas/aula-02-engenheiro/meu-atlas/. Crie o notebook
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
  .mkdirs("/Users/<eu>/atlas") antes.
- MLflow 2.x: log_model(..., artifact_path="modelo"), nunca name=.

O notebook, nesta ordem:
1. Lê gold.features_obra_semana. Teste = elegíveis com rótulo e semana >=
   2026-04-03. Treino = rotulados com semana <= 2026-03-06 e pct_prazo > 0,15
   (inclui obras já abaixo de 0,9: elas ensinam como uma obra afunda).
2. BASELINES no teste, impressos antes de qualquer treino: regra de corte
   atual (0,5), folga até o corte (-indice_min), só o CPI, tendência
   (-d_indice_min_4s).
3. Modelo: HistGradientBoostingRegressor(random_state=42, max_depth=3,
   learning_rate=0.05, max_iter=300, min_samples_leaf=20) prevendo
   alvo_pior_indice_30d - indice_min. pior_previsto = indice_min + previsão.
   sigma = desvio do erro no teste. prob = P(pior < 0,9) com erro normal
   (math.erf). Compare com um HistGradientBoostingClassifier sim/não.
4. Métrica da diretoria: um estouro é a primeira semana em que uma obra
   que estava >= 0,9 antes do teste cruza para baixo. Avisado = esteve no
   top 5 da semana (rank por prob) em alguma das 8 semanas anteriores.
   Imprima avisados/estouros, antecedência média em dias e o estouro
   previsto hoje (gold.obra_situacao_atual) dessas obras.
5. Importância por permutação.
6. Testes com assert, ANTES de registrar: AUC >= 0,75; AUC < 0,995 (acima
   disso é vazamento); AUC >= a folga até o corte (senão, use a regra);
   avisados >= 70% dos estouros.
7. Retreine com TODOS os rotulados, registre em
   lakehouse_atlas.gold.modelo_estouro_30d com input_example, alias @prod.
8. Grave gold.modelo_metricas (uma linha: versão, auc, baselines, sigma,
   estouros, avisados, antecedência, estouro avisado, feature principal).

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run atlas_torre --only ml_modelo --profile <perfil>
```

### Prompt 9 · Score em lote

*a probabilidade de estouro em 30 dias* · noite 3 · deploy nº 9 (bundle deploy) · [texto completo, com o que falar e as armadilhas](aulas/aula-03-cientista/prd/prompt-03-score.md)

```
Continue o bundle em aulas/aula-02-engenheiro/meu-atlas/. Crie o notebook
src/ml/03-score.py (mesma primeira célula de %pip do 02-modelo) e a tarefa
ml_score (notebook_task, depois de ml_modelo).

1. Carregue o modelo com mlflow.sklearn.load_model("models:/lakehouse_atlas
   .gold.modelo_estouro_30d@prod") — NÃO use spark_udf: no serverless ele
   quebra com InvalidVersion. O sigma vem de gold.modelo_metricas.
2. Pontue as obras com status em_andamento na semana 2026-10-16 de
   gold.features_obra_semana: pior_previsto = indice_min + previsão;
   prob = P(pior < 0,9) com erro normal; quem tem indice_min < 0,9 → 1,0.
3. ranking por prob desc (desempate: indice_min asc); faixa_risco alto se
   >= 0,5, medio se >= 0,2, senão baixo.
4. principais_fatores: os 2 ou 3 sinais mais graves em português, com
   números no padrão brasileiro (vírgula decimal). Sinais: já abaixo do corte
   (sempre primeiro), folga < 0,05 até o corte, CPI caindo nas últimas
   semanas, cpi_ultimas_4s < 0,85 ("cada R$ 1 gasto no último mês entregou
   R$ X"), spi_ultimas_4s < 0,85, falta de equipamento >= 10% dos RDOs,
   chuva >= 20%, falta de material >= 40%, mão de obra >= 15%, ociosidade
   >= 15%, 3+ rupturas previstas. Sem sinal: "sem sinal de piora".
5. Grave lakehouse_atlas.gold.score_estouro_30d com EXATAMENTE as colunas
   projeto_id STRING, data_referencia DATE, prob_estouro_30d DOUBLE,
   ranking INT, faixa_risco STRING, principais_fatores STRING (overwrite).
   COMMENT na tabela e nas colunas: a noite 4 lê daqui.
6. Testes com assert: uma linha por obra em andamento, prob entre 0 e 1,
   ranking único, nenhum motivo vazio.

Rode o job inteiro e me mostre o top 10:
  databricks bundle deploy --profile <perfil>
  databricks bundle run atlas_torre --profile <perfil>
```
---

## Fim da noite 3 · confira antes de seguir

```bash
python3 scripts/run_sql.py aulas/aula-03-cientista/99-verificacao.sql --profile <perfil>
# 15 linhas, todas "ok"
```

```sql
SELECT faixa_risco, COUNT(*) FROM lakehouse_atlas.gold.score_estouro_30d GROUP BY 1;
-- alto 13 · medio 1 · baixo 22
SELECT projeto_id, prob_estouro_30d FROM lakehouse_atlas.gold.score_estouro_30d WHERE projeto_id = 'P034';
-- P034 · 0,40  (a obra "ok" que o modelo vê chegando)
```

O job `atlas_torre` agora tem **8 tarefas** e roda verde em ~4 min 20 s. A noite 4 lê
`gold.score_estouro_30d`: se ela não existir, o app mostra "—" na coluna de risco.

---
## Noite 4 · o projeto ganha uma URL

### Prompt 10 · O agente que lê contrato

*o PDF que ninguém lê vira resposta* · noite 4 · deploy nº 10 (Genie publicado) · [texto completo, com o que falar e as armadilhas](aulas/aula-04-engenheiro-ia/prd/prompt-01-agente-de-contratos.md)

```
Leia aulas/aula-04-engenheiro-ia/prd/CLAUDE.md antes de começar.

Crie a pasta aulas/aula-04-engenheiro-ia/meu-agente/ com o agente que lê os
contratos da Atlas. Perfil: <perfil> (sempre --profile).

1. meu-agente/01-contratos.sql, executável com
   python3 scripts/run_sql.py meu-agente/01-contratos.sql --profile <perfil>
   (use a API de statements, não o aitools query). Quatro objetos na gold,
   com COMMENT em todos (é o que o Genie lê):
   a) gold.contratos_texto: read_files dos PDFs em
      /Volumes/lakehouse_atlas/bronze/raw/documentos/contratos/ (binaryFile),
      ai_parse_document(content), texto = concat_ws dos elementos;
      projeto_id extraído do nome do arquivo (contrato_P011.pdf → P011).
   b) gold.contratos_clausulas: uma linha por cláusula (projeto_id,
      clausula_numero INT, titulo, texto). Normalize os espaços (o PDF quebra
      linha no meio da frase) e corte em "CLÁUSULA N - ".
   c) gold.contratos_resumo: ai_query('databricks-meta-llama-3-3-70b-instruct',
      ..., responseFormat => JSON schema strict) com os campos multa_dia_pct
      (number), teto_multa_pct (number), chuva_da_prorrogacao (boolean),
      icamento_responsavel e estrutura_fornecida_por (enum contratada|contratante),
      prazo_aditivo_dias (integer), reajuste (string), bonus_antecipacao
      (boolean). Descreva cada campo no schema. Lembre: a Atlas é a CONTRATADA.
   d) gold.contratos_exposicao (view): junta obra_situacao_atual, contratos_resumo
      e a contagem de RDOs de chuva e de falta_equipamento; multa_estimada =
      valor_contrato × min(atraso_projetado_dias × multa_dia_pct, teto) / 100 e
      multa_no_teto.

2. meu-agente/gerar_genie.py gera meu-agente/diretoria-contratos-genie.json
   (serialized_space v2, ids de 32 caracteres em ordem) com: contratos_*,
   obra_situacao_atual, rdo_estruturado, utilizacao_equipamento_semana,
   utilizacao_equipe_semana, cobertura_estoque, pedidos_em_atraso,
   desempenho_fornecedor, mv_obras, e score_estouro_30d SÓ se existir.
   Instruções: HOJE = 2026-10-16; a Atlas é a CONTRATADA (nunca "cobrar a
   contratada"); sempre citar número e trecho da cláusula; regras de leitura
   (chuva_da_prorrogacao, içamento da contratada não dá prorrogação, prazo do
   aditivo); "em risco" = atenção + crítico somados. Exemplos de SQL para:
   "Por que a obra P011 atrasou e o que o contrato diz sobre isso?",
   "Qual a multa estimada de cada obra com contrato?",
   "Onde tenho guindaste parado que poderia ir para a P011?".

3. Rode e me mostre:
   python3 scripts/run_sql.py aulas/aula-04-engenheiro-ia/meu-agente/01-contratos.sql --profile <perfil>
   SELECT * EXCEPT(arquivo) FROM lakehouse_atlas.gold.contratos_resumo ORDER BY 1
   python3 aulas/aula-04-engenheiro-ia/meu-agente/gerar_genie.py --profile <perfil>
   python3 scripts/genie.py publicar aulas/aula-04-engenheiro-ia/meu-agente/diretoria-contratos-genie.json \
     --titulo "Torre de Controle · Diretoria + Contratos" --profile <perfil>
   python3 scripts/genie.py perguntar "Torre de Controle · Diretoria + Contratos" \
     "Por que a obra P011 atrasou e o que o contrato diz sobre isso?" --profile <perfil>
   python3 scripts/genie.py benchmark "Torre de Controle · Diretoria + Contratos" \
     aulas/aula-04-engenheiro-ia/prd/genie-benchmark.json --profile <perfil>
NÃO use o título "Torre de Controle · Diretoria": é o Genie da noite 2.
```

### Prompt 11 · O app da Torre

*a Torre na tela do gestor* · noite 4 · deploy nº 11 (apps deploy) · [texto completo, com o que falar e as armadilhas](aulas/aula-04-engenheiro-ia/prd/prompt-02-app.md)

```
Leia aulas/aula-04-engenheiro-ia/prd/CLAUDE.md. Use as skills databricks-apps e
databricks-app-design.

1. Mova aulas/aula-04-engenheiro-ia/meu-agente/ para dentro do app (passo 2,
   como minha-torre/agente/) e crie o app:
   cd aulas/aula-04-engenheiro-ia && databricks apps init --name minha-torre \
     --features analytics,genie \
     --set analytics.sql-warehouse.id=<warehouse> \
     --set genie.genie-space.id=<id do Genie "Torre de Controle · Diretoria + Contratos"> \
     --set "genie.genie-space.name=Torre de Controle · Diretoria + Contratos" \
     --run none --profile <perfil>
   Inclua no databricks.yml um job torre_contratos (sql_task com
   agente/01-contratos.sql) em resources/contratos.job.yml.

2. config/queries (apague os exemplos do template):
   - kpis.sql: obras em andamento, em risco (atenção+crítico), críticas,
     estouro previsto, carteira e rupturas previstas (obra_situacao_atual).
   - obras_risco.sql: obras em andamento da pior para a melhor, com SPI, CPI,
     estouro, atraso projetado, a causa mais frequente no RDO dos últimos 90
     dias, dias de impacto por falta_equipamento e por mao_de_obra, e
     multa_dia_pct / multa_estimada de contratos_exposicao (LEFT JOIN).
   - recursos_ociosos.sql: equipamentos com utilização média < 20% nas
     últimas 12 semanas e as 15 equipes com mais horas ociosas, com horas
     paradas e custo ocioso MÉDIOS por semana (custo da equipe vem de
     silver.equipes.custo_hora).
   A probabilidade de estouro (gold.score_estouro_30d, da noite 3) NÃO vai em
   config/queries: a tabela pode não existir e quebraria o build. Faça uma
   rota GET /api/score-estouro no servidor que responde {disponivel, linhas}.

3. Telas (português, R$, índices com 2 casas, Number() em tudo que vem do warehouse):
   - Obras em risco: 4 KPIs + tabela (situação com cor: crítico vermelho,
     atenção âmbar), coluna P(estouro) com "—" quando o modelo não existe.
   - Simulador: escolher recurso ocioso e obra destino (só atenção/crítico);
     mostrar horas recuperadas no mês (× 4 semanas), ociosidade que deixa de
     ser paga, dias de atraso evitados (dias de impacto da causa nos últimos
     90 dias ÷ 90 × 30), multa evitada (dias × multa diária × valor do
     contrato) e saldo com custo de mobilização editável. Explique a conta
     num <details>.
   - Perguntar: <GenieChat alias="default" />.
   Sem cache no createApp. Atualize o título do app.

4. npm run typecheck, npm run lint, npm test, databricks apps validate.
   Depois: databricks apps deploy --profile <perfil>. O primeiro deploy VAI
   falhar no build por falta de permissão: crie scripts/conceder-acesso.sh
   (lê o service_principal_client_id com apps get e dá USE CATALOG, USE
   SCHEMA + SELECT na gold, USE SCHEMA na silver e SELECT em silver.equipes),
   rode e faça o deploy de novo. Me mostre a URL.
```

### Prompt 12 · A aprovação no Lakebase

*a decisão fica registrada* · noite 4 · deploy nº 12 (apps deploy) · [texto completo, com o que falar e as armadilhas](aulas/aula-04-engenheiro-ia/prd/prompt-03-aprovacao-lakebase.md)

```
Leia aulas/aula-04-engenheiro-ia/prd/CLAUDE.md. Use as skills databricks-apps e
databricks-lakebase. O app minha-torre já está no ar (prompt 2).

1. Lakebase:
   databricks postgres create-project minha-torre --profile <perfil>
   e descubra branch e database (list-branches, list-databases).
   Adicione ao databricks.yml as variáveis postgres_branch e postgres_database e
   o recurso do app `postgres` (CAN_CONNECT_AND_CREATE); no app.yaml a env
   LAKEBASE_ENDPOINT (valueFrom: postgres); no server o plugin lakebase().

2. server/routes/decisoes.ts, registrado em onPluginsReady:
   - cria o schema torre e a tabela torre.decisoes (id serial, projeto_origem,
     projeto_destino, recurso_id, tipo equipamento|equipe, decisao
     aprovada|recusada, justificativa, horas_recuperadas_mes, economia_mes,
     multa_evitada, usuario, criado_em timestamptz default now()).
   - GET /api/quem-sou, GET /api/decisoes (200 mais recentes),
     POST /api/decisoes com zod (exporte o schema): projeto no padrão
     ^P\d{3}$, origem ≠ destino, justificativa de 10 a 1000 caracteres,
     números com z.coerce. Grave o usuário do header x-forwarded-email.
   - server/decisoes.test.ts (vitest) testando o schema: aceita válida,
     recusa justificativa curta, código fora do padrão e decisão inválida.

3. Cliente: no simulador, textarea de justificativa + botões Aprovar e
   Recusar (desabilitados com menos de 10 caracteres) que fazem POST e mostram
   "Decisão nº X aprovada e registrada por <e-mail>". Nova tela Decisões com o
   histórico (nº, quando, recurso origem → destino, decisão, justificativa,
   multa evitada, por quem).

4. typecheck, lint, test, apps validate, apps deploy --profile <perfil>.
   Prove a gravação: crie scripts/ver_decisoes.py que lê torre.decisoes direto
   no Postgres (psycopg, senha = token de
   `databricks postgres generate-database-credential <endpoint>`) e rode com
   uv run --no-project --with "psycopg[binary]" python ... --profile <perfil>
```
---

## Para refazer do zero

Cada noite tem o próprio script de limpeza. Sem `--apagar`, eles apenas
**mostram** o que fariam. Nenhum deles toca na bronze da noite 1.

```bash
bash aulas/aula-02-engenheiro/prd/00-reset.sh <perfil>             # simula
bash aulas/aula-02-engenheiro/prd/00-reset.sh <perfil> --apagar    # apaga silver, gold e os recursos do bundle
```
