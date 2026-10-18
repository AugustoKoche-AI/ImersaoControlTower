---

## Fim da noite 2 · confira antes de seguir

```bash
python3 scripts/run_sql.py aulas/aula-02-engenheiro/prd/99-verificacao.sql --profile <perfil>
# 17 linhas, todas "ok"
```

```sql
SELECT situacao, COUNT(*) FROM lakehouse_atlas.gold.obra_situacao_atual GROUP BY 1;
-- crítico 7 · atenção 6 · ok 23 · concluída 4
SELECT MEASURE(estouro_previsto) FROM lakehouse_atlas.gold.mv_obras;
-- R$ 42.364.558,31
```

O job `atlas_torre` tem **5 tarefas** e roda verde de ponta a ponta em ~5 min 40 s.
Se estes números não baterem, não adianta seguir: a noite 3 treina em cima deles.

---

