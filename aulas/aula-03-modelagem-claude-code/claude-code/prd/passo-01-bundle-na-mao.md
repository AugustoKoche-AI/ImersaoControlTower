# Passo 1 · O bundle, à mão, com a CLI

**Entrega:** um repositório novo, `vertice`, que já é um bundle, com o job de ingestão da noite 2
**importado** como código (`vertice_farol`), as chaves do Supabase fora do Git, e o primeiro
`bundle deploy`. **Sem Claude Code:** cada comando é digitado por você, para entender o que o
Claude Code vai estender nos prompts 2 a 5.

> **A premissa:** o catálogo `lakehouse_vertice`, a bronze e o job de ingestão da noite 2 já
> existem no workspace. Nada disso é recriado: o bundle passa a cuidar do job, que continua
> gravando no mesmo catálogo.

Testado em 21/10/2026 com a CLI v1.13. Troque `<perfil>` pelo seu profile em todos os comandos.

---

## 1 · Crie o bundle (e o repositório) com `bundle init`

```bash
mkdir -p ~/projetos && cd ~/projetos
databricks bundle init default-minimal --profile <perfil>
# Unique name for this project: vertice
cd vertice
git init -b main
ls -a        # databricks.yml  .gitignore  CLAUDE.md  AGENTS.md  README.md  pyproject.toml ...
```

O `default-minimal` é o esqueleto vazio: um `databricks.yml` e nenhum recurso. O `.gitignore` dele
**já deixa a `.databricks/` de fora**, e é lá que as chaves vão morar.

Troque o `CLAUDE.md` que o template trouxe pelo do curso (o negócio, as sujeiras do dado, as
armadilhas do Free Edition), e baixe o script de SQL da verificação:

```bash
curl -fsSL -o CLAUDE.md https://raw.githubusercontent.com/lvgalvao/ImersaoControlTower/main/aulas/aula-03-modelagem-claude-code/claude-code/prd/CLAUDE.md
mkdir -p scripts && curl -fsSL -o scripts/run_sql.py https://raw.githubusercontent.com/lvgalvao/ImersaoControlTower/main/scripts/run_sql.py
```

## 2 · Arrume o `databricks.yml`

O template vem com `mode: development`, que prefixa **tudo** com `[dev seu_usuario]`, inclusive as
tabelas do pipeline do prompt 2, e o SQL quebra. Apague o arquivo inteiro e cole este (troque o
`host` pelo seu e o `warehouse_id` pelo de `databricks warehouses list --profile <perfil>`):

```yaml
bundle:
  name: vertice

include:
  - resources/*.yml

variables:
  catalog:
    default: lakehouse_vertice
  warehouse_id:
    default: SEU_WAREHOUSE_ID
  s3_access_key_id:
    description: chave do data lake (o valor fica em .databricks/bundle/dev/variable-overrides.json)
  s3_secret_access_key:
    description: segredo do data lake (idem, fora do Git)

targets:
  dev:
    default: true
    # NÃO use mode: development: ele prefixa os nomes e quebra o SQL.
    presets:
      trigger_pause_status: PAUSED
    workspace:
      host: https://SEU-WORKSPACE.cloud.databricks.com
```

## 3 · Importe o job de ontem com `bundle generate`

```bash
databricks jobs list --profile <perfil>
# 911505081060072   Ingestão        ← o id do SEU job de ingestão (o nome varia)

databricks bundle generate job --existing-job-id <id> --profile <perfil>
# File successfully saved to src/01_ingestao_api_gabarito.py
# File successfully saved to src/02_ingestao_boto3_gabarito.py
# Job configuration successfully saved to resources/ingestão.job.yml
```

O caminho de volta: o `generate` lê o job que você montou clicando e escreve o YAML e os notebooks.
Ninguém reescreve do zero.

## 4 · Arrume o job importado

```bash
mv "resources/ingestão.job.yml" resources/vertice.job.yml
```

Abra `resources/vertice.job.yml` e mude **6 coisas**:

| Onde | Estava | Fica |
|---|---|---|
| a chave do job (2ª linha) | `ingestão:` | `vertice_farol:` |
| `name:` | `Ingestão` | `vertice_farol` |
| `task_key` da API | `IngestaoApi` (ou o seu nome) | `ingestao_feriados` |
| `task_key` do data lake | `IngestaoAWS` (ou o seu nome) | `ingestao_data_lake` |
| `AWS_ACCESS_KEY_ID:` e `AWS_SECRET_ACCESS_KEY:` | a chave em texto | `${var.s3_access_key_id}` e `${var.s3_secret_access_key}` |
| `schedule:` › `pause_status:` | `UNPAUSED` | `PAUSED` (o `presets` **não** muda um valor escrito no YAML) |

O `S3_ENDPOINT` e a região podem ficar em texto: não são segredo.

## 5 · As chaves, fora do Git

```bash
mkdir -p .databricks/bundle/dev
cat > .databricks/bundle/dev/variable-overrides.json <<'JSON'
{"s3_access_key_id": "COLE_A_CHAVE", "s3_secret_access_key": "COLE_O_SEGREDO"}
JSON
```

Os valores estão nos **Parameters** da tarefa do data lake, no job de ontem (ou no seu notebook
da noite 2). Confira que nada vazou:

```bash
git status                                   # .databricks/ NÃO aparece
grep -rn "<6 primeiros caracteres da chave>" --exclude-dir=.databricks .   # nenhuma linha
```

## 6 · Deploy e run

```bash
databricks bundle validate --profile <perfil>     # Validation OK!
databricks bundle deploy   --profile <perfil>     # Created jobs.vertice_farol
databricks bundle run vertice_farol --profile <perfil>
```

Abra o `vertice_farol` no workspace: **duas caixas verdes**, as duas ingestões em paralelo.

**Agora o job de ontem se aposenta:** abra o job "Ingestão" e clique em **Pause** no agendamento.
Dois jobs recarregando a mesma bronze às 6h é pedir para um apagar a tabela enquanto o outro lê.
(Não apague: o histórico de ontem é bom de mostrar.)

## 7 · Salve no GitHub e abra o Claude Code

```bash
gh repo create projeto-farol --public --source=. --remote=origin
git add . && git commit -m "passo 1: o job de ontem vira código" && git push -u origin main

databricks aitools install --agents claude-code --scope project --skills-only --experimental
claude                                       # na raiz do repositório
```

Daqui em diante é prompt: o 2 começa com a conferência da bronze e a silver.

> *"O job de ontem continua igual. A diferença é que agora ele é um arquivo. Se alguém mexer,
> o Git mostra o quê, quem e quando. Se o workspace sumir, um `bundle deploy` traz tudo de volta."*

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `cannot configure default credentials` | Faltou `--profile` ou o login expirou | `databricks auth login --profile <perfil>` |
| `no value assigned to required variable s3_access_key_id` | O `variable-overrides.json` não existe ou está em outra pasta | `.databricks/bundle/dev/variable-overrides.json`, ao lado do `databricks.yml` |
| `AssertionError: preencha: [...]` na `ingestao_data_lake` | A variável não chegou como parâmetro | Confira `${var.…}` no `base_parameters` e rode `bundle validate -o json` |
| `Schema 'dev_fulano_bronze' does not exist` | Sobrou o `mode: development` | O `databricks.yml` do passo 2 |
| O job novo rodou às 6h junto com o antigo | `pause_status: UNPAUSED` no YAML ou o job antigo não foi pausado | Passo 4 (última linha) e o **Pause** do passo 6 |
| A chave aparece no `git status` | `.databricks/` fora do `.gitignore` | Acrescente e rode `git rm --cached` no arquivo |
| `bundle generate` reclama que o arquivo existe | Rodou duas vezes | `--force` ou apague `resources/` e `src/` antes |

**Para ir além:** `databricks bundle deployment bind vertice_farol <id do job de ontem>` faz o bundle
**adotar** o job antigo em vez de criar outro, e o histórico continua no mesmo lugar.

**Tempo medido (21/10):** deploy em ~8 s; run em ~3 min (a ingestão do data lake é a maior parte).
