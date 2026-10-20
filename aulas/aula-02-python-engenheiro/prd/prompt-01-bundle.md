# Prompt 1 · O bundle — o projeto nasce como código

**Entrega:** o bundle `vertice` com o job `vertice_farol` e a primeira tarefa, a
conferência da bronze. **Deploy nº 1.**

---

## O que mostrar antes

Abra o Catalog Explorer na `lakehouse_vertice.bronze`: as 9 tabelas que a turma
subiu ontem, clicando, e o rascunho das três ferramentas feito à mão no exemplo 05.
Pergunte: *"sexta que vem os gerentes atualizam as planilhas, o ClickUp e o Project.
Quem roda tudo de novo? Na mão?"* Hoje o projeto vira código: versionado, revisável,
e roda sozinho toda segunda às 6h.

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
  calcular qualquer KPI, o job confere se o dado das três ferramentas chegou
  inteiro. Se não chegou, ele para — e o dashboard fica com o dado da semana
  passada em vez de meio dado.

---

## O prompt

```
Leia o CLAUDE.md da raiz do repositório antes de começar.

Crie o projeto da noite 2 na raiz deste repositório como um
Databricks Asset Bundle chamado vertice. Esta é a primeira de seis entregas: as
outras cinco estendem este mesmo bundle, então deixe a estrutura pronta para
crescer (resources/, src/conferencia, src/silver, src/gold, src/ia,
src/metricas, src/testes, scripts/). Não copie de outro projeto: construa.

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

---

## O que conferir

```bash
databricks bundle summary --profile <perfil>     # o job vertice_farol aparece, com URL
```

Abra o job no workspace: **uma caixa no DAG**, verde. Clique na tarefa: as 9
linhas com `ok`. Esse desenho vai crescer a noite inteira.

**A prova de que a conferência tem dente:** troque um número esperado (por
exemplo `projetos 61`), faça deploy e rode. O job falha com a mensagem que você
escreveu. Desfaça e rode de novo.

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `cannot configure default credentials` | Faltou `--profile` ou o login expirou | `databricks auth login --profile <perfil>` |
| `Schema 'dev_fulano_bronze' does not exist` | Usou `mode: development` | Troque por `presets: { trigger_pause_status: PAUSED }` |
| `TABLE_OR_VIEW_NOT_FOUND bronze.x` | A noite 1 não foi feita | Rode `00-carregar-dados` e `01-ingestao-bronze.sql` da aula 01 |
| A conferência falha em uma tabela | Carga parcial na noite 1 | Rode o `00-carregar-dados` e o `01-ingestao-bronze` de novo |

**Tempo medido:** deploy em ~8 s; run em ~40 s (a maior parte é o warehouse
acordando).
