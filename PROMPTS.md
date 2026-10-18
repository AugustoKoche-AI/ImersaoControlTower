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

---

## Para refazer do zero

Cada noite tem o próprio script de limpeza. Sem `--apagar`, eles apenas
**mostram** o que fariam. Nenhum deles toca na bronze da noite 1.

```bash
bash aulas/aula-02-engenheiro/prd/00-reset.sh <perfil>             # simula
bash aulas/aula-02-engenheiro/prd/00-reset.sh <perfil> --apagar    # apaga silver, gold e os recursos do bundle
```
