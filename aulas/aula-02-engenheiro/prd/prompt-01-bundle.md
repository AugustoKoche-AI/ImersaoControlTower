# Prompt 1 · O bundle — o projeto nasce como código

**Entrega:** o bundle `atlas` com o job `atlas_torre` e a primeira tarefa, a
conferência da bronze. **Deploy nº 1.**

---

## O que mostrar antes

Abra o Catalog Explorer na `lakehouse_atlas.bronze`: as 12 tabelas que a turma
subiu ontem, clicando. Pergunte: *"amanhã chega o dado novo do ERP. Quem roda
tudo de novo? Na mão?"* Hoje o projeto vira código: versionado, revisável, e
roda sozinho às 6h.

```bash
databricks -v                        # precisa ser v0.250 ou mais nova
databricks auth profiles             # o seu profile aparece como Valid: YES?
databricks warehouses list --profile <perfil>
```

**Enquanto ele trabalha, você explica:**

- **Bundle = o projeto inteiro num `databricks.yml`.** Job, pipeline, dashboard e
  Genie viram arquivos no Git. `bundle deploy` sobe tudo igual na máquina de
  qualquer pessoa do time. Clique não tem diff; YAML tem.
- **Por que não `mode: development`.** Ele prefixa tudo com `[dev seu_usuario]`
  — inclusive os datasets do pipeline — e o SQL da noite quebra. Pausamos o
  agendamento na mão com `presets`.
- **A primeira tarefa é uma conferência, não uma transformação.** Antes de
  calcular qualquer KPI, o pipeline confere se o dado chegou inteiro. Se não
  chegou, ele para — e o dashboard fica com o dado de ontem em vez de meio dado.

---

## O prompt

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

---

## O que conferir

```bash
databricks bundle summary --profile <perfil>     # o job atlas_torre aparece, com URL
```

Abra o job no workspace: **uma caixa no DAG**, verde. Clique na tarefa: as 12
linhas com `ok`. Esse desenho vai crescer a noite inteira.

**A prova de que a conferência tem dente:** troque um número esperado (por
exemplo `projetos 41`), faça deploy e rode. O job falha com a mensagem que você
escreveu. Desfaça e rode de novo.

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `cannot configure default credentials` | Faltou `--profile` ou o login expirou | `databricks auth login --profile <perfil>` |
| `Schema 'dev_fulano_bronze' does not exist` | Usou `mode: development` | Troque por `presets: { trigger_pause_status: PAUSED }` |
| `TABLE_OR_VIEW_NOT_FOUND bronze.x` | A noite 1 não foi feita | Rode `00-carregar-dados` e `01-ingestao-bronze.sql` da aula 01 |
| A conferência falha em uma tabela | Upload parcial na noite 1 | Rode o `00-carregar-dados` de novo (ele recria tudo) |

**Tempo medido:** deploy em ~8 s; run em ~40 s (a maior parte é o warehouse
acordando).
