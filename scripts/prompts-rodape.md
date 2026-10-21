---

## Para refazer do zero

Cada noite tem o próprio script de limpeza. Sem `--apagar`, eles apenas
**mostram** o que fariam. Nenhum deles toca na bronze da noite 1.

```bash
bash aulas/aula-03-modelagem-claude-code/claude-code/prd/00-reset.sh <perfil>             # simula
bash aulas/aula-03-modelagem-claude-code/claude-code/prd/00-reset.sh <perfil> --apagar    # apaga silver, gold e os recursos do bundle
bash aulas/aula-04-produtos-de-dados-ia/prd/99-limpar-modelo.sh <perfil>   # simula; --apagar tira features, modelo e score
bash aulas/aula-04-produtos-de-dados-ia/prd/99-limpar-aula-04.sh <perfil>  # simula; --apagar tira o app, o Lakebase e o bônus dos contratos
```
