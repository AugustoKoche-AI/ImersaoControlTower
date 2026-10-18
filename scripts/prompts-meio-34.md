---

## Fim da noite 3 · confira antes de seguir

```bash
python3 scripts/run_sql.py aulas/aula-03-cientista/99-verificacao.sql --profile <perfil>
# 15 linhas, todas "ok"
```

```sql
SELECT faixa_risco, COUNT(*) FROM lakehouse_atlas.gold.score_estouro_30d GROUP BY 1;
-- alto 13 · medio 1 · baixo 22
SELECT projeto_id, prob_estouro_30d FROM lakehouse_atlas.gold.score_estouro_30d WHERE projeto_id = 'P034';
-- P034 · 0,40  (a obra "ok" que o modelo vê chegando)
```

O job `atlas_torre` agora tem **8 tarefas** e roda verde em ~4 min 20 s. A noite 4 lê
`gold.score_estouro_30d`: se ela não existir, o app mostra "—" na coluna de risco.

---
