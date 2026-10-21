# farol-torre · gabarito do app da noite 4

O app **Projeto Farol** da Vértice Tecnologia (Databricks App, AppKit: React + TypeScript + Express). É o
resultado dos prompts 3 e 4 da noite 4, e o **plano B** da aula: suba antes de entrar ao vivo.
Para construir o seu, siga [`../prd/prompt-03-app.md`](../prd/prompt-03-app.md).

```
torre-app/
├── config/queries/                   leitura no SQL warehouse (typegen gera os tipos)
│   ├── kpis.sql · projetos_risco.sql · pessoas_ociosas.sql
├── server/
│   ├── server.ts                     plugins analytics, genie, lakebase, server; sem cache
│   ├── routes/score.ts               score do modelo (prompt 1), opcional ({disponivel:false} se não existir)
│   ├── routes/decisoes.ts            Lakebase: schema torre, tabela decisoes, GET/POST com zod
│   └── decisoes.test.ts              vitest do schema que protege o endpoint que escreve
├── client/src/pages/                 Projetos em risco · Simulador · Decisões · Perguntar (GenieChat)
├── scripts/
│   ├── conceder-acesso.sh            GRANTs do service principal (sem eles o build falha)
│   ├── subir-tudo.sh                 Lakebase + id do Genie + deploy, na ordem certa
│   └── ver_decisoes.py               lê torre.decisoes direto no Postgres (prova da gravação)
├── databricks.yml                    app + recursos (warehouse, genie, postgres)
└── app.yaml                          npm run start + envs (warehouse, genie, LAKEBASE_ENDPOINT)
```

O app lê a gold do bundle `vertice` (noite 3), o score `gold.score_estouro_30d` (noite 4, prompt 1) e
conversa com o Genie **"Farol · Diretoria"** (noite 4, prompt 2). O agente de contratos, que antes vivia
aqui em `agente/`, virou bônus: [`../bonus/`](../bonus).

## Do zero

```bash
databricks apps list --profile <perfil>        # o Free Edition aceita no máximo 3 apps
bash aulas/aula-04-produtos-de-dados-ia/torre-app/scripts/subir-tudo.sh <perfil>
```

1. cria o projeto Lakebase `farol-torre` (7 s);
2. acha o id do Genie "Farol · Diretoria" pelo título e grava no `databricks.yml`;
3. `bundle deploy` → `conceder-acesso.sh` → `apps deploy` (o build falha sem os GRANTs).

## Dia a dia

```bash
cd aulas/aula-04-produtos-de-dados-ia/torre-app
set -a; . ./.env; set +a; npm run typegen -- --wait   # tipos das queries (warehouse ligado)
npm run typecheck && npm run lint && npm test
databricks apps validate --profile <perfil>
databricks apps deploy   --profile <perfil>
databricks apps logs farol-torre --profile <perfil>
uv run --no-project --with "psycopg[binary]" python scripts/ver_decisoes.py --profile <perfil>
```

> Testou local com `npm run dev`? O schema `torre` do Lakebase nasceu com você como dono. Apague-o antes do
> primeiro deploy, para o service principal do app criar o dele.

## Rotas do servidor

| Rota | O que faz |
|---|---|
| `POST /api/analytics/query/<kpis\|projetos_risco\|pessoas_ociosas>` | as queries de `config/queries` (plugin analytics) |
| `GET /api/score-estouro` | probabilidade de estouro em 30 dias do modelo, ou `{disponivel:false}` |
| `GET /api/quem-sou` | e-mail do usuário logado (header `x-forwarded-email`) |
| `GET /api/decisoes` | as 200 decisões mais recentes |
| `POST /api/decisoes` | grava uma decisão (zod: `PRJ-000`, `COL0000`, origem ≠ destino, justificativa ≥ 10) |
| Genie | plugin genie, alias `default` → "Farol · Diretoria" |
