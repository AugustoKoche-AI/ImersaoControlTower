# Aprendizados do ensaio da noite 4 · Free Edition, 18/10/2026

Medido no workspace `dbc-84cd5511` (profile `imersao-out26`): construído, apagado com
`prd/99-limpar-aula-04.sh --apagar` e reconstruído do zero com `torre-app/scripts/subir-tudo.sh`.

## O que falhou e como foi resolvido

| # | O que aconteceu | Mensagem | Solução adotada |
|---|---|---|---|
| 1 | Knowledge Assistant e Supervisor Agent | `... is now a legacy feature. New instances can no longer be created ... use Genie Agents instead` | Agente = Genie Agent + cláusulas numa tabela (`ai_parse_document`) |
| 2 | `ai_query` com schema sem descrição | `prazo_aditivo_dias` = 0 em 4 dos 8 contratos (o certo é 30) | `description` em cada campo do JSON schema → 8/8 |
| 3 | Genie recomendou "cobrar a contratada" | (perspectiva errada: a Atlas É a contratada) | Instrução explícita: Atlas = CONTRATADA, multa é custo da Atlas |
| 4 | Benchmark: "quantas obras em risco?" | Genie devolveu 2 linhas (crítico 7, atenção 6) | Exemplo de SQL com `COUNT(*)` único + "em risco = um número só" → 10/10 |
| 5 | `typegen` local | todas as queries `OFFLINE` em 0,00 s | `set -a; . ./.env; set +a` antes do `npm run typegen` |
| 6 | Query de `config/queries` com tabela de outra noite | `apps validate`: `TABLE_OR_VIEW_NOT_FOUND` (o build faz typegen `--wait`) | Score da noite 3 lido por rota do servidor (`routes/score.ts`) que responde `{disponivel:false}` |
| 7 | 1º `apps deploy` | `Error building app` · `INSUFFICIENT_PERMISSIONS: User does not have USE CATALOG` | `scripts/conceder-acesso.sh` (GRANT ao service principal) e deploy de novo. O build roda o typegen **como o app** |
| 8 | Arquivo `*.geniespace.json` dentro do app | `Failed to import into the snapshot folder ... Requested node type [UNKNOWN] is not supported` | Renomear para `diretoria-contratos-genie.json` |
| 9 | Projeto Lakebase apagado | `get-project` continua respondendo (tem `delete_time`); o app falha com `Postgres branch ... does not exist` | Checar com `list-projects` |
| 10 | Recriar projeto Lakebase com o mesmo nome | `A soft-deleted project currently has this resource name ... delete ... with purge = true` | `delete-project --purge` no reset (ou `undelete-project`) |
| 11 | A `score_estouro_30d` sumiu no meio do ensaio | `Failed to fetch tables for the agent ... score_estouro_30d does not exist` | A noite 3 estava recriando a tabela; o gerador do Genie só inclui o score se ela existir |
| 12 | Abrir o app no navegador | tela "Permission Requested" (consentimento OAuth, escopo `dashboards.genie`) | Esperado: Authorize uma vez. Os testes automáticos usaram `Authorization: Bearer $(databricks auth token)` |
| 13 | `databricks psql` | precisa do `psql` instalado | `scripts/ver_decisoes.py` com psycopg + `generate-database-credential` |

## O que funciona (e não funcionava em agosto)

| Recurso | Status em 18/10/2026 |
|---|---|
| Lakebase: `create-project` | ✅ **6,4 s**; branch `production` e database `databricks_postgres` automáticos |
| App + Lakebase (plugin `lakebase()`, recurso `postgres`) | ✅ o service principal cria o schema `torre` e grava; o dono do projeto lê pelo psycopg |
| `ai_parse_document` em PDF | ✅ ~25 a 30 s para 8 contratos (parse + extração) |
| `ai_query` com `responseFormat` JSON schema `strict` | ✅ tipos e enums respeitados |
| Genie com tabela de cláusulas citando a fonte | ✅ benchmark **10/10**, pergunta-âncora correta |
| AppKit 0.76 `apps init --features analytics,lakebase,genie` | ✅ ~10 s |
| Header `x-forwarded-email` com o usuário do SSO | ✅ gravado em `torre.decisoes.usuario` |

## Tempos medidos

| Etapa | Tempo |
|---|---|
| `apps init` | ~10 s |
| `apps validate` (typegen, lint, typecheck, build, testes) | ~9 s |
| 1º `apps deploy` (cria o compute; falha no build sem GRANT) | 4 min 35 s |
| `apps deploy` com permissão | 45 s a 1 min 3 s |
| Lakebase `create-project` | 6,4 s |
| SQL dos contratos (4 objetos) | 25 a 30 s; job `torre_contratos` 28 s |
| Benchmark de 10 perguntas | ~3 min |
| `99-limpar-aula-04.sh --apagar` | ~12 s (+ ~40 s até o app sumir) |
| `subir-tudo.sh` do zero | ~3 min 30 s + redeploy de 1 min |

## Para o CLAUDE.md da raiz

- Lakebase: apagar é **soft delete por 7 dias** e prende o nome; use `--purge` em reset e `list-projects` para checar existência.
- App: o **build** roda o typegen como o service principal → GRANT antes do 2º deploy; tabela opcional não pode estar em `config/queries`.
- App: não ponha arquivo `*.geniespace.json` dentro da pasta do app.
- Genie: a Atlas é a **contratada**; instrua o agente sobre o lado do contrato.
