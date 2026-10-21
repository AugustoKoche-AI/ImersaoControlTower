# Passo 1 · O bundle, à mão, com a CLI

**Entrega:** um repositório novo, `vertice`, que já é um bundle, com o job de ingestão da noite 2
importado como código e as chaves do Supabase fora do Git. Só comandos para copiar e colar; a
arrumação fina (nomes, `mode: development`, agendamento) o Claude Code faz no prompt 1.

> **A premissa:** o catálogo `lakehouse_vertice`, a bronze e o job de ingestão da noite 2 já
> existem no workspace. Nada disso é recriado.

Testado em 21/10/2026 com a CLI v1.13. Os comandos usam o profile `DEFAULT`: se o seu tiver outro
nome, troque (`databricks auth profiles` mostra os seus).

---

## 1 · O repositório e o bundle

```bash
mkdir -p ~/projetos && cd ~/projetos
gh repo create vertice --public --clone          # já tem um "vertice" no GitHub? use outro nome AQUI e no init
databricks bundle init default-minimal --profile DEFAULT
cd ~/projetos/vertice
ls databricks.yml       # TEM que aparecer: daqui até o claude, tudo roda nesta pasta
```

O `init` pergunta o nome: responda **`vertice`** (a pasta que o `gh` acabou de criar). Nas outras
perguntas, **Enter**. O `.gitignore` do template já deixa a `.databricks/` fora do Git, e é lá que
as chaves vão morar.

## 2 · O job de ontem vira código

```bash
databricks jobs list --profile DEFAULT
# 911505081060072   Ingestão        ← copie o id do SEU job de ingestão

databricks bundle generate job --existing-job-id <id> --profile DEFAULT
# Job configuration successfully saved to resources/ingestão.job.yml
```

## 3 · As chaves, fora do Git

O `generate` escreveu as chaves do Supabase em texto no YAML, e o repositório é público. Cole o
bloco inteiro: ele troca cada chave por uma variável (`${var.s3_access_key_id}`) e guarda o valor
em `.databricks/bundle/dev/variable-overrides.json`, que não vai para o Git.

```bash
python3 - <<'PY'
import json, pathlib, re
arquivo = pathlib.Path("resources/ingestão.job.yml")
assert arquivo.exists(), "não achei resources/ingestão.job.yml: rode na pasta do bundle (cd ~/projetos/vertice) e depois do generate"
yml = arquivo.read_text()
chaves = {"s3_access_key_id": "AWS_ACCESS_KEY_ID", "s3_secret_access_key": "AWS_SECRET_ACCESS_KEY"}
valores = {}
for var, param in chaves.items():
    valores[var] = re.search(rf"{param}: (.+)", yml).group(1).strip().strip("\"'")
    yml = re.sub(rf"{param}: .+", f"{param}: ${{var.{var}}}", yml)
yml = "variables:\n" + "".join(f"  {v}:\n    description: chave do data lake (o valor fica fora do Git)\n" for v in chaves) + "\n" + yml
arquivo.write_text(yml)
pasta = pathlib.Path(".databricks/bundle/dev"); pasta.mkdir(parents=True, exist_ok=True)
(pasta / "variable-overrides.json").write_text(json.dumps(valores))
print("ok: as chaves saíram do YAML e foram para", pasta / "variable-overrides.json")
PY

grep -n "AWS_" "resources/ingestão.job.yml"     # as duas chaves agora são ${var.…}
```

## 4 · Deploy e GitHub

```bash
databricks bundle validate --profile DEFAULT     # Validation OK!
databricks bundle deploy   --profile DEFAULT

git add . && git status                          # .databricks/ NÃO aparece
git commit -m "passo 1: o job de ontem vira código" && git push -u origin HEAD
```

No workspace aparece o job **`[dev seu_usuario] Ingestão`**, criado pelo bundle. O prefixo é do
`mode: development` do template: o prompt 1 tira e renomeia o job para `vertice_farol`.

## 5 · Abra o Claude Code

```bash
claude
```

Daqui em diante é prompt. O 2 começa arrumando o bundle e depois faz a conferência da bronze e a silver.

---

## Se der errado

| Sintoma | Correção |
|---|---|
| `unable to locate bundle root` no `generate`, ou `FileNotFoundError` no bloco do passo 3 | Você está fora da pasta do bundle. `cd ~/projetos/vertice` e rode de novo a partir do `generate` |
| O Claude Code diz que não acha o job importado | Ele abriu na pasta errada, ou o `generate` não rodou. Saia (`/exit`), `cd ~/projetos/vertice`, `ls resources/` (tem que ter o `.job.yml`) e abra de novo |
| `cannot configure default credentials` | `databricks auth login --profile DEFAULT` |
| `failed to initialize template, one or more files already exist` | A pasta `vertice` não está vazia: o `gh repo create` vai **sem** `--add-readme` |
| `no value assigned to required variable s3_access_key_id` | Faltou o bloco do passo 3 (ou ele rodou fora da pasta `vertice`) |
| `AttributeError: 'NoneType'` no bloco do passo 3 | O YAML já estava sem as chaves: rode o `generate` de novo com `--force` |
| A chave aparece no `git status` | `.databricks/` fora do `.gitignore`: acrescente e rode `git rm --cached` no arquivo |

**Tempo medido (21/10):** ~5 min, a maior parte digitando o nome e copiando o id.
