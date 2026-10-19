# Prompt 2 · O app da Torre — o projeto ganha uma URL

**Entrega:** um Databricks App (AppKit, React + TypeScript) com login do workspace e três telas:
**Projetos em risco**, **Simulador de realocação** e **Perguntar** (o Genie do prompt 1 embutido).
**Deploy nº 2** = `databricks apps deploy`.

> Três noites de trabalho estão atrás de um SQL Editor. Um dado que só o time de dados consegue abrir é
> um dado que não existe para a empresa. O dono não abre SQL Editor. Hoje o Farol ganha uma URL.

---

## O que mostrar antes

`databricks apps list --profile <perfil>`: o Free Edition aceita **no máximo 3 apps**. Se já houver
três, apague um que você não usa mais (`databricks apps delete <nome>`).

`databricks apps init` monta um projeto React em menos de 10 segundos. Mostre a árvore:
`config/queries/*.sql` (leitura), `server/server.ts` (rotas), `client/src/pages/` (telas).

**Enquanto o Claude Code trabalha, você explica:**

- **Leitura é arquivo `.sql`.** O `typegen` lê o Unity Catalog e escreve os tipos TypeScript: o `COMMENT`
  que a noite 2 exigiu vira documentação dentro do editor.
- **O app é um usuário.** Ele roda como um service principal que nasce sem acesso a nada. `CAN_USE` no
  warehouse dá o computador, não o dado: sem os `GRANT`, o build falha (`INSUFFICIENT_PERMISSIONS`).
- **O simulador mostra a conta.** O dono não aprova caixa-preta: a tela diz de onde vem cada número
  (horas paradas × 4 semanas, dias de impacto do status ÷ 90 × 30, uma semana de onboarding).
  E o que não vira dinheiro sem premissa (dias de cronograma) fica fora da conta em R$.
- **O número vem como string** do warehouse. `Number()` antes de qualquer conta.

---

## O prompt

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
     estouro previsto e carteira (projeto_situacao_atual), rupturas de capacidade
     (cobertura_capacidade) e multa a cobrar de fornecedor na vigência atual
     (contratos_multa_fornecedor).
   - projetos_risco.sql: projetos em andamento do pior para o melhor, com SPI, CPI, estouro,
     atraso projetado, farol do gerente × calculado, melancia, a causa mais frequente no
     status_estruturado dos últimos 90 dias, os dias de impacto por falta_sre e por
     rotatividade, rupturas de capacidade e multa a cobrar por projeto.
   - pessoas_ociosas.sql: pessoas com utilização < 20% nas últimas 12 semanas
     (utilizacao_pessoa_semana), com horas paradas e custo ocioso MÉDIOS por semana e custo_hora.
   A probabilidade de estouro (gold.score_estouro_30d, da noite 3) NÃO vai em config/queries:
   a tabela pode não existir e quebraria o build. Faça uma rota GET /api/score-estouro no
   servidor que responde {disponivel, linhas}.

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
   USE CATALOG em lakehouse_vertice e USE SCHEMA + SELECT na gold), rode e faça
   databricks apps deploy --profile <perfil>. Me mostre a URL.
```

---

## O que conferir

- `apps validate`: typegen, lint, typecheck, build e testes ✅.
- Sem os `GRANT`, o `apps deploy` falha com `INSUFFICIENT_PERMISSIONS` no typegen do build: **é esperado**.
- Na URL (1ª visita pede **Authorize**): **17 de 41** projetos em risco (7 críticos, 4 com farol verde),
  **R$ 6,5 mi** de estouro, **R$ 1,2 mi** de multa a cobrar de fornecedor, **15** rupturas de capacidade;
  PRJ-016 e PRJ-030 no topo, PRJ-011 com causa "falta de SRE".
- Simulador: **COL0017** (SRE sênior, PRJ-007, uso de 6%) → **PRJ-011** dá **151 h** no mês,
  **R$ 30,1 mil** de ociosidade evitada, **19,0 dias** de cronograma recuperados, R$ 8,0 mil de onboarding
  e **saldo de R$ 22,1 mil** no mês.

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `reached the maximum limit of 3 apps` | o Free Edition aceita 3 apps | apague um app que não usa mais |
| `Error building app` + `INSUFFICIENT_PERMISSIONS` nos logs | o service principal não tem `USE CATALOG` | `bash scripts/conceder-acesso.sh <perfil>` e `apps deploy` de novo |
| `TABLE_OR_VIEW_NOT_FOUND` no `apps validate` | query de `config/queries` aponta para tabela que não existe | tabela opcional vai numa rota do servidor |
| typegen marca tudo `OFFLINE` em 0 s | o `.env` não foi carregado / warehouse parado | `set -a; . ./.env; set +a` e `npm run typegen -- --wait` |
| Valores como `6465127.22` sem formatação | número veio como string | `Number()` (ou `num()` do `lib/dados.ts`) |
| `name must be ≤ 26 characters` | nome do app longo | `minha-torre` |
| Tela pede "Permission Requested" | consentimento OAuth do app (Genie age em seu nome) | Authorize, uma vez |
| Deploy cria o app mas ele fica parado | usou só `bundle deploy` | `databricks apps deploy` |

**Tempo medido (edição anterior, mesmo app):** `apps init` ~10 s; `apps validate` ~9 s; redeploy com
permissão ~45 s a 1 min.
