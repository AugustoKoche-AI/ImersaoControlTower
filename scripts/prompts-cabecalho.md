# 🧾 Os prompts, na ordem

O Projeto Farol, a Torre de Controle da Vértice Tecnologia — das planilhas, listas do ClickUp e
cronogramas do Project até o Genie que responde as quatro perguntas do dono — sai de
**prompts colados em sequência no Claude Code**.
Este arquivo é a sequência inteira, na ordem, para quem quer refazer sozinho.

> **Cada prompt termina com um deploy.** Não junte dois: o valor do formato
> está em ver a coisa subir uma camada por vez, e em quebrar cedo quando quebra.

| Noite | Prompts | O que existe no fim |
|---|---|---|
| [**3** · engenheiro de dados](aulas/aula-03-modelagem-claude-code) | 1 (à mão) e 2 a 5 | o job de ingestão da noite 2 como código, o pipeline que integra as 3 ferramentas, gold com testes, status semanal com IA e o dashboard |
| [**4** · cientista e engenheiro de IA](aulas/aula-04-produtos-de-dados-ia) | 6 a 9 | modelo de estouro em 30 dias no mesmo job, metric view + Genie curado, o app da Torre e a decisão gravada no Lakebase |

---

## Antes do primeiro prompt

As noites 1 e 2 precisam estar feitas: o catálogo `lakehouse_vertice` com a bronze carregada
(9 tabelas + `feriados`) e o **job de ingestão da noite 2** no workspace (os notebooks
[`01_ingestao_api`](aulas/aula-02-python-engenheiro/01_ingestao_api_gabarito.py) e
[`02_ingestao_boto3`](aulas/aula-02-python-engenheiro/02_ingestao_boto3_gabarito.py)).

**O passo 1 não é prompt: é você, com a CLI do Databricks.** Num repositório novo,
`databricks bundle init default-minimal`, depois `databricks bundle generate job` importa o job
de ontem, e as chaves vão para `.databricks/bundle/dev/variable-overrides.json`, fora do Git. O
passo a passo, testado: [`passo-01-bundle-na-mao.md`](aulas/aula-03-modelagem-claude-code/claude-code/prd/passo-01-bundle-na-mao.md).
Os prompts começam no 2.

```bash
# 1 · a CLI do Databricks (v0.250 ou mais nova) e o login
brew tap databricks/tap && brew install databricks     # Windows: winget install Databricks.DatabricksCLI
databricks auth login --profile <perfil>
databricks auth profiles                                # o seu aparece com Valid: YES

# 2 · o Claude Code (as skills oficiais do Databricks já vêm em .claude/skills)
npm install -g @anthropic-ai/claude-code

# 3 · conferir que a bronze e o job de ontem estão lá
databricks experimental aitools tools query "SHOW TABLES IN lakehouse_vertice.bronze" --profile <perfil>
databricks jobs list --profile <perfil>
```

O seu bundle mora num **repositório seu**, criado no passo 1. A pasta
`aulas/aula-03-modelagem-claude-code/claude-code/vertice/` é o gabarito. Se você já rodou antes, zere
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

