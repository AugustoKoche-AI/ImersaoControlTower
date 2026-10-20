# 🧾 Os prompts, na ordem

O Projeto Farol, a Torre de Controle da Vértice Tecnologia — das planilhas, listas do ClickUp e
cronogramas do Project até o Genie que responde as quatro perguntas do dono — sai de
**prompts colados em sequência no Claude Code**.
Este arquivo é a sequência inteira, na ordem, para quem quer refazer sozinho.

> **Cada prompt termina com um deploy.** Não junte dois: o valor do formato
> está em ver a coisa subir uma camada por vez, e em quebrar cedo quando quebra.

| Noite | Prompts | O que existe no fim |
|---|---|---|
| [**2** · engenheiro de dados](aulas/aula-02-python-engenheiro) | 1 a 6 | bundle, pipeline declarativo que integra as 3 ferramentas, status semanal com IA, a metric view mv_projetos, dashboard e Genie |
| [**3** · cientista de dados](aulas/aula-03-modelagem-claude-code) | 7 a 9 | modelo de estouro em 30 dias no Unity Catalog e o score por projeto |
| [**4** · engenheiro de IA](aulas/aula-04-produtos-de-dados-ia) | 10 a 12 | o agente de contratos, o app da Torre e a decisão gravada no Lakebase |

---

## Antes do primeiro prompt

A noite 1 precisa estar feita: o catálogo `lakehouse_vertice` com a bronze
carregada (13 tabelas). Se não estiver, rode o
[`00-carregar-dados`](aulas/aula-01-analista-sql/00-carregar-dados.py) e o
[`01-ingestao-bronze.sql`](aulas/aula-01-analista-sql/01-ingestao-bronze.sql).

```bash
# 1 · a CLI do Databricks (v0.250 ou mais nova) e o login
brew tap databricks/tap && brew install databricks     # Windows: winget install Databricks.DatabricksCLI
databricks auth login --profile <perfil>
databricks auth profiles                                # o seu aparece com Valid: YES

# 2 · o Claude Code (as skills oficiais do Databricks já vêm em .claude/skills)
npm install -g @anthropic-ai/claude-code

# 3 · conferir que a bronze está lá
python3 scripts/run_sql.py aulas/aula-01-analista-sql/99-verificacao.sql --profile <perfil>
```

**A pasta `aulas/aula-03-modelagem-claude-code/claude-code/meu-vertice/` nasce vazia** — é o prompt 1 que
a preenche. A pasta `vertice/` ao lado é o gabarito. Se você já rodou antes, zere
com `BUNDLE_DIR=aulas/aula-03-modelagem-claude-code/claude-code/meu-vertice bash aulas/aula-03-modelagem-claude-code/claude-code/prd/00-reset.sh <perfil> --apagar`.

Nos prompts abaixo, **troque `<perfil>` pelo seu profile**.

---

## Como usar esta página

1. Copie o bloco do prompt (só o que está dentro do ```)
2. Cole no Claude Code, na raiz do repositório
3. Espere o deploy terminar e **confira o número** antes de ir para o próximo
4. O que conferir em cada um está no arquivo linkado no título

Os arquivos linkados têm o que esta página não tem: o que mostrar antes de
colar, o que falar enquanto o Claude Code trabalha, e a tabela **"se der
errado"**. Se for a primeira vez, siga por eles.

---

