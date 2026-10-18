# Prompt 3 · A aprovação — a decisão sai do WhatsApp

**Entrega:** o botão **Aprovar / Recusar** do simulador grava a decisão no **Lakebase**
(Postgres) com o usuário do login e o horário, e a tela **Decisões** mostra o histórico.
**Deploy nº 3** = `databricks apps deploy`.

> Até hoje a realocação do guindaste era decidida por WhatsApp e ninguém sabia quem
> aprovou, quando e por quê. A Torre fecha o ciclo: o dado vira decisão, e a decisão
> vira dado.

---

## O que mostrar antes

No simulador, escolha **EQ0017 (Guindaste 90t, P007, uso 6%)** → **P011**. A tela mostra o ganho.
Pergunte: *"e agora, quem aprova? onde isso fica registrado?"*

**Enquanto o Claude Code trabalha, você explica:**

- **Por que Postgres e não uma tabela Delta?** Delta é ótima para analisar milhões de
  linhas; Postgres é feito para gravar **uma linha por clique**, com chave, transação e
  leitura imediata. Lakebase é o Postgres gerenciado do Databricks, e **funciona no
  Free Edition** (em agosto não funcionava: a gravação era numa tabela Delta).
- **O app cria o próprio schema.** O service principal não enxerga o `public`: ele cria
  `torre` na subida e vira dono dele.
- **Quem clicou.** O app roda como service principal, mas grava o e-mail do header
  `x-forwarded-email`, que o Databricks Apps injeta depois do login SSO.
- **A porta que escreve é a mais vigiada:** validação zod (código da obra no padrão
  `P000`, justificativa mínima, decisão só `aprovada` ou `recusada`) e teste automatizado.

---

## O prompt

```
Leia aulas/aula-04-engenheiro-ia/prd/CLAUDE.md. Use as skills databricks-apps e
databricks-lakebase. O app minha-torre já está no ar (prompt 2).

1. Lakebase:
   databricks postgres create-project minha-torre --profile <perfil>
   e descubra branch e database (list-branches, list-databases).
   Adicione ao databricks.yml as variáveis postgres_branch e postgres_database e
   o recurso do app `postgres` (CAN_CONNECT_AND_CREATE); no app.yaml a env
   LAKEBASE_ENDPOINT (valueFrom: postgres); no server o plugin lakebase().

2. server/routes/decisoes.ts, registrado em onPluginsReady:
   - cria o schema torre e a tabela torre.decisoes (id serial, projeto_origem,
     projeto_destino, recurso_id, tipo equipamento|equipe, decisao
     aprovada|recusada, justificativa, horas_recuperadas_mes, economia_mes,
     multa_evitada, usuario, criado_em timestamptz default now()).
   - GET /api/quem-sou, GET /api/decisoes (200 mais recentes),
     POST /api/decisoes com zod (exporte o schema): projeto no padrão
     ^P\d{3}$, origem ≠ destino, justificativa de 10 a 1000 caracteres,
     números com z.coerce. Grave o usuário do header x-forwarded-email.
   - server/decisoes.test.ts (vitest) testando o schema: aceita válida,
     recusa justificativa curta, código fora do padrão e decisão inválida.

3. Cliente: no simulador, textarea de justificativa + botões Aprovar e
   Recusar (desabilitados com menos de 10 caracteres) que fazem POST e mostram
   "Decisão nº X aprovada e registrada por <e-mail>". Nova tela Decisões com o
   histórico (nº, quando, recurso origem → destino, decisão, justificativa,
   multa evitada, por quem).

4. typecheck, lint, test, apps validate, apps deploy --profile <perfil>.
   Prove a gravação: crie scripts/ver_decisoes.py que lê torre.decisoes direto
   no Postgres (psycopg, senha = token de
   `databricks postgres generate-database-credential <endpoint>`) e rode com
   uv run --no-project --with "psycopg[binary]" python ... --profile <perfil>
```

---

## O que conferir

- Logs do app (`databricks apps logs minha-torre --profile <perfil>`): `[decisoes] torre.decisoes pronta`.
- Aprovar EQ0017 → P011 mostra **"Decisão nº 1 aprovada e registrada por <seu e-mail>"**.
- `ver_decisoes.py` lista a linha **direto do Postgres**, com o seu e-mail e o horário.
- Tentar origem = destino responde `Origem e destino são a mesma obra` (400).

> *"Esta linha é o rótulo de amanhã. Daqui a três meses dá para perguntar: as realocações
> aprovadas melhoraram o SPI da obra destino? O dado que sai da Torre volta para ela."*

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `[decisoes] não consegui criar a tabela: permission denied for schema public` | tentou criar no `public` | crie e use o schema `torre` |
| `relation "torre.decisoes" does not exist` | o `onPluginsReady` falhou na subida | veja os logs; confira o recurso `postgres` no `databricks.yml` e o `LAKEBASE_ENDPOINT` no `app.yaml` |
| POST devolve 400 | validação zod (justificativa curta, código errado) | é a proteção funcionando: leia a mensagem |
| `ver_decisoes.py`: `password authentication failed` | token expirado ou usuário errado | gere de novo; o usuário é o seu e-mail do workspace |
| `psql not found` | o CLI `databricks psql` precisa do psql instalado | use o `ver_decisoes.py` (psycopg) |

**Tempo medido:** criar o projeto Lakebase **6,4 s**; deploy ~1 min; gravação aparece na hora.
