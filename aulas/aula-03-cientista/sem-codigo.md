# Noite 3 sem escrever código (gestão, PMO, financeiro)

Você não precisa treinar o modelo para usar o que ele diz. Três caminhos, do mais
simples ao mais completo.

## 1. A lista de segunda-feira (SQL Editor, copiar e colar)

```sql
SELECT ranking, projeto_id, prob_estouro_30d, faixa_risco, principais_fatores
FROM lakehouse_atlas.gold.score_estouro_30d
ORDER BY ranking;
```

Como ler:

- **prob_estouro_30d = 1,0**: a obra **já** está abaixo de 0,9. A regra de corte acendeu.
  A coluna de motivos diz por quê (ex.: *"falta de equipamento em 70% dos RDOs"*).
- **faixa "medio" ou "alto" com prob < 1**: a obra está "ok" para a regra, mas o modelo
  vê risco de cruzar em 30 dias. **É aqui que está o valor**: hoje, a **P034** (40%).
- **"sem sinal de piora"**: pode tirar da pauta.

## 2. O que o modelo vale (para defender na reunião)

```sql
SELECT ROUND(auc, 3) AS acerto_modelo, ROUND(auc_baseline_folga, 3) AS acerto_regra_simples,
       estouros_avisados || ' de ' || estouros_teste AS estouros_avisados,
       ROUND(antecedencia_media_dias) AS dias_de_antecedencia
FROM lakehouse_atlas.gold.modelo_metricas;
```

A frase: *"das 7 obras que estouraram desde abril, 6 apareceriam na lista das 5 mais
arriscadas da semana, em média 45 dias antes. A regra de hoje avisou zero antes."*

## 3. Perguntar em português (Genie Code no SQL Editor)

No SQL Editor, abra o assistente e peça:

- *"Liste as obras de gold.score_estouro_30d com faixa medio ou alto que estão com
  situação ok em gold.obra_situacao_atual."*
- *"Para a obra P034, mostre a evolução semanal de spi e cpi em gold.features_obra_semana
  desde junho de 2026."*

Confira a resposta com a tabela "O que deve aparecer na tela" do [README](README.md).

> O Genie da diretoria, que responde isso sem você escrever nada, é o primeiro prompt da noite 4.
