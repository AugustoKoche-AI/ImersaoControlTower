# farol-torre · gabarito da noite 4

O app **Projeto Farol** da Vértice Tecnologia (Databricks App, AppKit: React + TypeScript + Express) e o
**agente que lê contrato e manual**, num bundle só. É o resultado dos 3 prompts da noite 4.
Para construir o seu, siga [`../prd/`](../prd) na pasta [`../minha-torre/`](../minha-torre).

```
torre-app/
├── agente/
│   ├── 01-contratos.sql              PDF → elementos → cláusulas e seções do manual → resumo (ai_extract com
│   │                                 JSON schema tipado) → multa a cobrar e avisos prévios
│   ├── gerar_genie.py                gera o Genie "Farol · Diretoria + Contratos"
│   └── diretoria-contratos-genie.json  (gerado; NÃO use .geniespace.json: o import do app recusa)
├── config/queries/                   leitura no SQL warehouse (typegen gera os tipos)
│   ├── kpis.sql · projetos_risco.sql · pessoas_ociosas.sql
├── server/
│   ├── server.ts                     plugins analytics, genie, lakebase, server; sem cache
│   ├── routes/decisoes.ts            Lakebase: schema torre, tabela decisoes, GET/POST com zod
│   ├── routes/score.ts               score da noite 3, opcional ({disponivel:false} se não existir)
│   └── decisoes.test.ts              vitest do schema que protege o endpoint que escreve
├── client/src/pages/                 Projetos em risco · Simulador · Decisões · Perguntar (GenieChat)
├── resources/contratos.job.yml       job farol_contratos (sql_task com agente/01-contratos.sql)
├── scripts/
│   ├── conceder-acesso.sh            GRANTs do service principal (sem eles o build falha)
│   ├── subir-tudo.sh                 a noite 4 inteira do zero, na ordem certa
│   └── ver_decisoes.py               lê torre.decisoes direto no Postgres (prova da gravação)
├── databricks.yml                    app + recursos (warehouse, genie, postgres) + job
└── app.yaml                          npm run start + envs (warehouse, genie, LAKEBASE_ENDPOINT)
```

## Do zero

```bash
databricks apps list --profile <perfil>        # o Free Edition aceita no máximo 3 apps
bash aulas/aula-04-engenheiro-ia/torre-app/scripts/subir-tudo.sh <perfil>
```

1. cria o projeto Lakebase `farol-torre` (7 s);
2. roda `agente/01-contratos.sql` (~1 min para os 9 PDFs);
3. gera e publica o Genie e grava o id dele no `databricks.yml`;
4. `apps deploy` → `conceder-acesso.sh` → `apps deploy` (o build falha sem os GRANTs).

## Dia a dia

```bash
cd aulas/aula-04-engenheiro-ia/torre-app
set -a; . ./.env; set +a; npm run typegen -- --wait   # tipos das queries (warehouse ligado)
npm run typecheck && npm run lint && npm test
databricks apps validate --profile <perfil>
databricks apps deploy   --profile <perfil>
databricks bundle run farol_contratos --profile <perfil>   # reprocessa contratos e manual (~1 min)
databricks apps logs farol-torre --profile <perfil>
uv run --no-project --with "psycopg[binary]" python scripts/ver_decisoes.py --profile <perfil>
```

> Testou local com `npm run dev`? O schema `torre` do Lakebase nasceu com você como dono. Apague-o antes do
> primeiro deploy, para o service principal do app criar o dele.

## Rotas do servidor

| Rota | O que faz |
|---|---|
| `POST /api/analytics/query/<kpis\|projetos_risco\|pessoas_ociosas>` | as queries de `config/queries` (plugin analytics) |
| `GET /api/score-estouro` | probabilidade de estouro da noite 3, ou `{disponivel:false}` |
| `GET /api/quem-sou` | e-mail do usuário logado (header `x-forwarded-email`) |
| `GET /api/decisoes` | as 200 decisões mais recentes |
| `POST /api/decisoes` | grava uma decisão (zod: `PRJ-000`, `COL0000`, origem ≠ destino, justificativa ≥ 10) |
| Genie | plugin genie, alias `default` → "Farol · Diretoria + Contratos" |
