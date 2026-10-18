# torre-atlas · gabarito da noite 4

O app **Torre de Controle** da Atlas Engenharia (Databricks App, AppKit 0.76: React + TypeScript +
Express) e o **agente que lê contrato**, num bundle só. É o resultado dos 3 prompts da noite 4.
Para construir o seu, siga [`../prd/`](../prd) na pasta [`../minha-torre/`](../minha-torre).

```
torre-app/
├── agente/
│   ├── 01-contratos.sql              PDF → texto → cláusulas → resumo (ai_query + JSON schema) → exposição em R$
│   ├── gerar_genie.py                gera o Genie "Torre de Controle · Diretoria + Contratos"
│   └── diretoria-contratos-genie.json  (gerado; NÃO use .geniespace.json: o import do app recusa)
├── config/queries/                   leitura no SQL warehouse (typegen gera os tipos)
│   ├── kpis.sql · obras_risco.sql · recursos_ociosos.sql
├── server/
│   ├── server.ts                     plugins analytics, genie, lakebase, server; sem cache
│   ├── routes/decisoes.ts            Lakebase: schema torre, tabela decisoes, GET/POST com zod
│   ├── routes/score.ts               score da noite 3, opcional ({disponivel:false} se não existir)
│   └── decisoes.test.ts              vitest do schema que protege o endpoint que escreve
├── client/src/pages/                 Obras em risco · Simulador · Decisões · Perguntar (GenieChat)
├── resources/contratos.job.yml       job torre_contratos (sql_task com agente/01-contratos.sql)
├── scripts/
│   ├── conceder-acesso.sh            GRANTs do service principal (sem eles o build falha)
│   ├── subir-tudo.sh                 a noite 4 inteira do zero, na ordem certa
│   └── ver_decisoes.py               lê torre.decisoes direto no Postgres (prova da gravação)
├── databricks.yml                    app + recursos (warehouse, genie, postgres) + job
└── app.yaml                          npm run start + envs (warehouse, genie, LAKEBASE_ENDPOINT)
```

## Do zero

```bash
bash aulas/aula-04-engenheiro-ia/torre-app/scripts/subir-tudo.sh <perfil>      # ~4 a 5 min
```

1. cria o projeto Lakebase `torre-atlas` (6 s);
2. roda `agente/01-contratos.sql` (~25 s para os 8 PDFs);
3. gera e publica o Genie e grava o id dele no `databricks.yml`;
4. `apps deploy` → `conceder-acesso.sh` → `apps deploy` (o 1º build falha sem os GRANTs).

## Dia a dia

```bash
cd aulas/aula-04-engenheiro-ia/torre-app
set -a; . ./.env; set +a; npm run typegen      # tipos das queries (warehouse ligado)
npm run typecheck && npm run lint && npm test
databricks apps validate --profile <perfil>
databricks apps deploy   --profile <perfil>     # ~45 s a 1 min
databricks bundle run torre_contratos --profile <perfil>   # reprocessa os contratos (~28 s)
databricks apps logs torre-atlas --profile <perfil>
uv run --no-project --with "psycopg[binary]" python scripts/ver_decisoes.py --profile <perfil>
```

## Rotas do servidor

| Rota | O que faz |
|---|---|
| `POST /api/analytics/query/<kpis\|obras_risco\|recursos_ociosos>` | as queries de `config/queries` (plugin analytics) |
| `GET /api/score-estouro` | probabilidade de estouro da noite 3, ou `{disponivel:false}` |
| `GET /api/quem-sou` | e-mail do usuário logado (header `x-forwarded-email`) |
| `GET /api/decisoes` | as 200 decisões mais recentes |
| `POST /api/decisoes` | grava uma decisão (zod: `P000`, origem ≠ destino, justificativa ≥ 10) |
| Genie | plugin genie, alias `default` → "Torre de Controle · Diretoria + Contratos" |
