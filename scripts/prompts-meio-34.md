
---

## Fim da noite 3 · confira antes de seguir

```bash
python3 scripts/run_sql.py aulas/aula-03-modelagem-claude-code/claude-code/prd/99-verificacao.sql --profile <perfil>
# 20 linhas, todas "ok"
```

```sql
SELECT situacao, COUNT(*) FROM lakehouse_vertice.gold.projeto_situacao_atual GROUP BY 1;
-- crítico 7 · atenção 10 · ok 24 · concluído 19
SELECT ROUND(SUM(estouro_previsto) / 1e6, 2), COUNT_IF(melancia)
FROM lakehouse_vertice.gold.projeto_situacao_atual WHERE status = 'em_andamento';
-- 6,47 · 4
```

O job `vertice_farol` tem **6 tarefas** (2 de ingestão, conferência, medalhão, testes, IA) e roda
verde de ponta a ponta. Se estes números não baterem, não adianta seguir: a noite 4 treina o
modelo em cima deles.

---
