# Aprendizados do ensaio da noite 4 · Free Edition, outubro/2026

Medido no workspace `dbc-84cd5511` (profile `imersao-out26`). A primeira parte vale para qualquer case: são
as armadilhas da plataforma. A segunda é do case da Vértice (18/10/2026).

## O que falhou e como foi resolvido (plataforma)

| # | O que aconteceu | Mensagem | Solução adotada |
|---|---|---|---|
| 1 | Knowledge Assistant e Supervisor Agent | `... is now a legacy feature. New instances can no longer be created ... use Genie Agents instead` | Agente = Genie Agent + cláusulas e seções do manual em tabelas (`ai_parse_document`) |
| 2 | Extração estruturada sem descrição dos campos | campo inteiro veio 0 em metade dos documentos (edição de agosto, com `ai_query`) | `description` em cada campo do JSON schema |
| 3 | `typegen` local | todas as queries `OFFLINE` em 0,00 s | `set -a; . ./.env; set +a` e `npm run typegen -- --wait` |
| 4 | Query de `config/queries` com tabela de outra noite | `apps validate`: `TABLE_OR_VIEW_NOT_FOUND` (o build faz typegen `--wait`) | Score da noite 3 lido por rota do servidor (`routes/score.ts`) que responde `{disponivel:false}` |
| 5 | 1º `apps deploy` | `Error building app` · `INSUFFICIENT_PERMISSIONS: User does not have USE CATALOG` | `scripts/conceder-acesso.sh` (GRANT ao service principal) e deploy de novo. O build roda o typegen **como o app** |
| 6 | Arquivo `*.geniespace.json` dentro do app | `Failed to import into the snapshot folder ... Requested node type [UNKNOWN] is not supported` | Renomear para `diretoria-contratos-genie.json` |
| 7 | Projeto Lakebase apagado | `get-project` continua respondendo (tem `delete_time`); o app falha com `Postgres branch ... does not exist` | Checar com `list-projects` |
| 8 | Recriar projeto Lakebase com o mesmo nome | `A soft-deleted project currently has this resource name ... delete ... with purge = true` | `delete-project --purge` no reset (ou `undelete-project`) |
| 9 | Tabela de outra noite sumindo no meio do ensaio | `Failed to fetch tables for the agent ... does not exist` | O gerador do Genie só inclui o score se a tabela existir |
| 10 | Abrir o app no navegador | tela "Permission Requested" (consentimento OAuth, escopo `dashboards.genie`) | Esperado: Authorize uma vez. Testes automáticos usam `Authorization: Bearer $(databricks auth token)` |
| 11 | `databricks psql` | precisa do `psql` instalado | `scripts/ver_decisoes.py` com psycopg + `generate-database-credential` |
| 12 | **Limite de apps do Free Edition** | `Failed to create app farol-torre. Workspace ... has reached the maximum limit of 3 apps.` | Apagar um app antigo antes do prompt 2 (`databricks apps list` / `apps delete`) |
| 13 | Testar o app local (`npm run dev`) antes do deploy | o schema `torre` nasce com **você** como dono; o service principal não escreve nele depois | Apague o schema `torre` antes do 1º deploy (o app recria) |
| 14 | Estado local do bundle de outro app (`.databricks/`) | o próximo deploy alteraria o app antigo | Apague `.databricks/` da pasta ao renomear o app |

## O que aprendemos com o case da Vértice

| # | O que aconteceu | Solução adotada |
|---|---|---|
| 1 | `ai_extract` **sem schema** (lista de nomes) devolve frase: `"0,2% do valor da entrega atrasada por dia corrido, limitada a 5%"` | É a lição da aula: com o JSON schema tipado (versão 2.0), sai `0.2` e `5.0` |
| 2 | Com schema, o SLA da CodeVault veio em italiano ("disponibilità mensal") | `"description": "... copiado do contrato, em português"` |
| 3 | Cortar cláusula por regex de título falha quando o texto começa com "A CONTRATADA" (maiúsculas) | Usar o `type = 'section_header'` que o `ai_parse_document` já devolve |
| 4 | Multa da CodeForge: R$ 3,24 mi no histórico desde 2024 | Separar `na_vigencia_atual` (R$ 1,12 mi): é o que dá para descontar das próximas faturas |
| 5 | Benchmark do Genie de contratos | **10/10** de primeira, com instrução "a Vértice é a CONTRATANTE" e "na vigência atual = na_vigencia_atual" |

## O que funciona

| Recurso | Status |
|---|---|
| Lakebase: `create-project` | ✅ **7 s**; branch `production` e database `databricks_postgres` automáticos |
| App + Lakebase (plugin `lakebase()`, recurso `postgres`) | ✅ o app cria o schema `torre` e grava; o dono do projeto lê pelo psycopg |
| `ai_parse_document` em PDF | ✅ elementos com tipo (`title`, `section_header`, `text`) |
| `ai_extract` versão 2.0 com JSON schema | ✅ número, booleano e inteiro tipados; 8/8 contratos certos |
| Genie com cláusulas e manual citando a fonte | ✅ benchmark **10/10** |
| AppKit `apps init --features analytics,lakebase,genie` | ✅ ~10 s |
| Header `x-forwarded-email` com o usuário do SSO | ✅ gravado em `torre.decisoes.usuario` |

## Tempos medidos

| Etapa | Tempo |
|---|---|
| SQL dos contratos e do manual (9 PDFs: parse + extração) | ~1 min |
| Lakebase `create-project` | 7 s |
| Benchmark de 10 perguntas | ~3 min |
| `apps init` | ~10 s (edição de agosto) |
| `apps deploy` com permissão | 45 s a 1 min (edição de agosto) |
