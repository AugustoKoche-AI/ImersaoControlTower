# Prompt 4 (opcional) · A aprovação: a decisão sai do WhatsApp

**Entrega:** o botão **Aprovar / Recusar** do simulador grava a decisão no **Lakebase** (Postgres) com
o usuário do login e o horário, e a tela **Decisões** mostra o histórico. **Deploy nº 4** = `databricks apps deploy`.

> **Opcional.** Entra se sobrar tempo depois do app. Se não sobrar, mostre o botão **Aprovar** no
> `farol-torre` (o gabarito já tem o Lakebase) e deixe este prompt como lição de casa. Nunca corte o pitch.

> Até hoje, mover uma SRE de um projeto para outro era decidido por WhatsApp, e ninguém sabia quem
> aprovou, quando e por quê. A Torre fecha o ciclo: o dado vira decisão, e a decisão vira dado.

---

## O que mostrar antes

No simulador, escolha **COL0017 (SRE sênior, PRJ-007, uso de 6%)** → **PRJ-011**. A tela mostra o ganho.
Pergunte: *"e agora, quem aprova? onde isso fica registrado?"*

**Enquanto o Claude Code trabalha, você explica:**

- **Por que Postgres e não uma tabela Delta?** Delta é ótima para analisar milhões de linhas; Postgres é
  feito para gravar **uma linha por clique**, com chave, transação e leitura imediata. Lakebase é o
  Postgres gerenciado do Databricks, e **funciona no Free Edition** (em agosto não funcionava).
- **O app cria o próprio schema.** O service principal não enxerga o `public`: ele cria `torre` na subida
  e vira dono dele.
- **Quem clicou.** O app roda como service principal, mas grava o e-mail do header `x-forwarded-email`,
  que o Databricks Apps injeta depois do login SSO.
- **A porta que escreve é a mais vigiada:** validação zod (projeto no padrão `PRJ-000`, pessoa `COL0000`,
  justificativa mínima, decisão só `aprovada` ou `recusada`) e teste automatizado.

---

## O prompt

```
Leia o CLAUDE.md da raiz e aulas/aula-04-produtos-de-dados-ia/prd/CLAUDE.md. Use as skills
databricks-apps e databricks-lakebase. O app minha-torre já está no ar (prompt 3).

1. Lakebase:
   databricks postgres create-project minha-torre --profile <perfil>
   e descubra branch e database (list-branches, list-databases).
   Adicione ao databricks.yml as variáveis postgres_branch e postgres_database e o recurso
   do app `postgres` (CAN_CONNECT_AND_CREATE); no app.yaml a env LAKEBASE_ENDPOINT
   (valueFrom: postgres); no server o plugin lakebase().

2. server/routes/decisoes.ts, registrado em onPluginsReady:
   - cria o schema torre e a tabela torre.decisoes (id serial, projeto_origem, projeto_destino,
     recurso_id, tipo 'pessoa', decisao aprovada|recusada, justificativa,
     horas_recuperadas_mes, economia_mes, dias_recuperados, usuario,
     criado_em timestamptz default now()).
   - GET /api/quem-sou, GET /api/decisoes (200 mais recentes), POST /api/decisoes com zod
     (exporte o schema): projeto ^PRJ-\d{3}$, pessoa ^COL\d{4}$, origem ≠ destino,
     justificativa de 10 a 1000 caracteres, números com z.coerce. Grave o usuário do header
     x-forwarded-email.
   - server/decisoes.test.ts (vitest) testando o schema: aceita válida, recusa justificativa
     curta, projeto fora do padrão, pessoa fora do padrão e decisão inválida.

3. Cliente: no simulador, textarea de justificativa + botões Aprovar e Recusar (desabilitados
   com menos de 10 caracteres) que fazem POST e mostram "Decisão nº X aprovada e registrada
   por <e-mail>". Nova tela Decisões com o histórico (nº, quando, pessoa origem → destino,
   decisão, justificativa, ociosidade evitada no mês, por quem).

4. typecheck, lint, test, apps validate, apps deploy --profile <perfil>.
   Prove a gravação: crie scripts/ver_decisoes.py que lê torre.decisoes direto no Postgres
   (psycopg, senha = token de `databricks postgres generate-database-credential <endpoint>`)
   e rode com uv run --no-project --with "psycopg[binary]" python ... --profile <perfil>
```

---

## O que conferir

- Logs do app (`databricks apps logs minha-torre --profile <perfil>`): `[decisoes] torre.decisoes pronta`.
- Aprovar COL0017 → PRJ-011 mostra **"Decisão nº 1 aprovada e registrada por <seu e-mail>"**.
- `ver_decisoes.py` lista a linha **direto do Postgres**, com o seu e-mail, o horário, R$ 30.123,20 e 19,0 dias.
- Mandar `P007` no lugar de `PRJ-007` responde `Invalid string: must match pattern /^PRJ-\d{3}$/` (400).

> *"Esta linha é o rótulo de amanhã. Daqui a três meses dá para perguntar: as realocações aprovadas
> melhoraram o SPI do projeto destino? O dado que sai da Torre volta para ela."*

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `[decisoes] não consegui criar a tabela: permission denied for schema public` | tentou criar no `public` | crie e use o schema `torre` |
| `permission denied for schema torre` no app publicado | você rodou `npm run dev` antes e o schema `torre` é seu, não do app | apague o schema `torre` (você é o dono) e reinicie o app: ele recria |
| `relation "torre.decisoes" does not exist` | o `onPluginsReady` falhou na subida | veja os logs; confira o recurso `postgres` no `databricks.yml` e o `LAKEBASE_ENDPOINT` no `app.yaml` |
| POST devolve 400 | validação zod (justificativa curta, código errado) | é a proteção funcionando: leia a mensagem |
| `ver_decisoes.py`: `password authentication failed` | token expirado ou usuário errado | gere de novo; o usuário é o seu e-mail do workspace |
| `A soft-deleted project currently has this resource name` | apagou o Lakebase sem `--purge` | `databricks postgres delete-project projects/<id> --purge` |

**Tempo medido:** criar o projeto Lakebase **7 s**; a gravação aparece na hora.
