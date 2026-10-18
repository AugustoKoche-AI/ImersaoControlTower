---

## Para refazer do zero

Cada noite tem o próprio script de limpeza. Sem `--apagar`, eles apenas
**mostram** o que fariam. Nenhum deles toca na bronze da noite 1.

```bash
bash aulas/aula-02-engenheiro/prd/00-reset.sh <perfil>             # simula
bash aulas/aula-02-engenheiro/prd/00-reset.sh <perfil> --apagar    # apaga silver, gold e os recursos do bundle
```
