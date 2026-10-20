
---

## Fim da noite 3 · confira antes de seguir

```bash
python3 scripts/run_sql.py aulas/aula-03-modelagem-claude-code/99-verificacao.sql --profile <perfil>
# 17 linhas, todas "ok"
```

```sql
SELECT faixa_risco, COUNT(*) FROM lakehouse_vertice.gold.score_estouro_30d GROUP BY 1;
-- alto 18 · medio 4 · baixo 19
SELECT projeto_id, prob_estouro_30d FROM lakehouse_vertice.gold.score_estouro_30d WHERE projeto_id = 'PRJ-024';
-- PRJ-024 · 0,49  (o e-commerce "ok" que o modelo vê chegando, com o freeze de 01/11 na porta)
```

O job `vertice_farol` agora tem **9 tarefas** e roda verde em ~4 a 5 min. A noite 4 lê
`gold.score_estouro_30d`: se ela não existir, o app mostra "—" na coluna de risco.

---
