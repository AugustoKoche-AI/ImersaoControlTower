# Prompt 2 · O app da Torre — o projeto ganha uma URL

**Entrega:** um Databricks App (AppKit, React + TypeScript) com login do workspace e três
telas: **Obras em risco**, **Simulador de realocação** e **Perguntar** (o Genie do prompt 1
embutido). **Deploy nº 2** = `databricks apps deploy`.

> Três noites de trabalho estão atrás de um SQL Editor. Um dado que só o time de dados
> consegue abrir é um dado que não existe para a empresa. Hoje ele ganha uma URL.

---

## O que mostrar antes

`databricks apps init` monta um projeto React em menos de 10 segundos. Mostre a árvore:
`config/queries/*.sql` (leitura), `server/server.ts` (rotas), `client/src/pages/` (telas).

**Enquanto o Claude Code trabalha, você explica:**

- **Leitura é arquivo `.sql`.** O `typegen` lê o Unity Catalog e escreve os tipos
  TypeScript: o `COMMENT` que a noite 2 exigiu vira documentação dentro do editor.
- **O app é um usuário.** Ele roda como um service principal que nasce sem acesso a
  nada. `CAN_USE` no warehouse dá o computador, não o dado: sem os `GRANT`, o build
  falha (`INSUFFICIENT_PERMISSIONS`) e depois toda tela carrega vazia.
- **O simulador mostra a conta.** Diretor não aprova caixa-preta: a tela diz de onde
  vem cada número (horas paradas × 4 semanas, dias de impacto do RDO ÷ 90 × 30, multa
  diária do contrato).
- **O número vem como string** do warehouse. `Number()` antes de qualquer conta.

---

## O prompt

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

---

## O que conferir

- `apps validate`: typegen, lint, typecheck, build e testes ✅.
- O 1º `apps deploy` falha com `INSUFFICIENT_PERMISSIONS` no typegen do build: **é esperado**.
  Depois dos `GRANT`, o deploy sobe em ~45 s a ~1 min.
- Na URL (1ª visita pede **Authorize**): **13 de 36** obras em risco, **R$ 42,4 mi** de estouro,
  97 rupturas; P030 e P011 no topo; P011 com multa estimada de **R$ 1.876.298**.
- Simulador: EQ0017 (P007) → P011 dá **166 h** no mês, **R$ 157,6 mil** de ociosidade que vira
  produção, **7,8 dias** evitados e cerca de **R$ 82,6 mil** de multa evitada.

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `Error building app` + `INSUFFICIENT_PERMISSIONS` nos logs | o service principal não tem `USE CATALOG` | `bash scripts/conceder-acesso.sh <perfil>` e `apps deploy` de novo |
| `TABLE_OR_VIEW_NOT_FOUND` no `apps validate` | query de `config/queries` aponta para tabela que não existe | tabela opcional vai numa rota do servidor |
| typegen marca tudo `OFFLINE` em 0 s | o `.env` não foi carregado / warehouse parado | `set -a; . ./.env; set +a` e ligue o warehouse |
| Valores como `42364558.31` sem formatação | número veio como string | `Number()` (ou `num()` do `lib/dados.ts`) |
| `name must be ≤ 26 characters` | nome do app longo | `minha-torre` |
| Tela pede "Permission Requested" | consentimento OAuth do app (Genie age em seu nome) | Authorize, uma vez |
| Deploy cria o app mas ele fica parado | usou `bundle deploy` | `databricks apps deploy` |

**Tempo medido:** `apps init` ~10 s; `apps validate` ~9 s; 1º `apps deploy` 4 min 35 s (falha esperada);
redeploy com permissão ~45 s a 1 min.
