
---

## Fim da noite 2 · confira antes de seguir

```bash
python3 scripts/run_sql.py aulas/aula-02-engenheiro/prd/99-verificacao.sql --profile <perfil>
# 20 linhas, todas "ok"
```

```sql
SELECT situacao, COUNT(*) FROM lakehouse_vertice.gold.projeto_situacao_atual GROUP BY 1;
-- crítico 7 · atenção 10 · ok 24 · concluído 19
SELECT MEASURE(estouro_previsto), MEASURE(projetos_melancia) FROM lakehouse_vertice.gold.mv_projetos;
-- R$ 6.465.127,22 · 4
```

O job `vertice_farol` tem **6 tarefas** e roda verde de ponta a ponta. Se estes números não
baterem, não adianta seguir: a noite 3 treina em cima deles.

---
