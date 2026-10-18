# 🧾 Os prompts, na ordem

A Torre de Controle da Atlas Engenharia — da bronze crua ao Genie que explica
por que a obra atrasou — sai de **prompts colados em sequência no Claude Code**.
Este arquivo é a sequência inteira, na ordem, para quem quer refazer sozinho.

> **Cada prompt termina com um deploy.** Não junte dois: o valor do formato
> está em ver a coisa subir uma camada por vez, e em quebrar cedo quando quebra.

| Noite | Prompts | O que existe no fim |
|---|---|---|
| [**2** · engenheiro de dados](aulas/aula-02-engenheiro) | 1 a 6 | bundle, pipeline declarativo silver + gold, RDO com IA, 5 metric views, dashboard e Genie |
| [**3** · cientista de dados](aulas/aula-03-cientista) | 7 a 9 | modelo de estouro em 30 dias no Unity Catalog e o score em lote |
| [**4** · engenheiro de IA](aulas/aula-04-engenheiro-ia) | 10 a 12 | Genie da diretoria, o app da Torre e o agente de contratos |

---

## Antes do primeiro prompt

A noite 1 precisa estar feita: o catálogo `lakehouse_atlas` com a bronze
carregada (12 tabelas). Se não estiver, rode o
[`00-carregar-dados`](aulas/aula-01-analista/00-carregar-dados.py) e o
[`01-ingestao-bronze.sql`](aulas/aula-01-analista/01-ingestao-bronze.sql).

```bash
# 1 · a CLI do Databricks (v0.250 ou mais nova) e o login
brew tap databricks/tap && brew install databricks     # Windows: winget install Databricks.DatabricksCLI
databricks auth login --profile <perfil>
databricks auth profiles                                # o seu aparece com Valid: YES

# 2 · o Claude Code e as skills oficiais do Databricks
npm install -g @anthropic-ai/claude-code
databricks aitools install

# 3 · conferir que a bronze está lá
python3 scripts/run_sql.py aulas/aula-01-analista/99-verificacao.sql --profile <perfil>
```

**A pasta `aulas/aula-02-engenheiro/meu-atlas/` nasce vazia** — é o prompt 1 que
a preenche. A pasta `atlas/` ao lado é o gabarito. Se você já rodou antes, zere
com `BUNDLE_DIR=aulas/aula-02-engenheiro/meu-atlas bash aulas/aula-02-engenheiro/prd/00-reset.sh <perfil> --apagar`.

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

