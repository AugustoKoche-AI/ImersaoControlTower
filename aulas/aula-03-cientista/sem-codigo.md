# Noite 3 sem escrever código (gestão, PMO, financeiro)

Você não precisa treinar o modelo para usar o que ele diz. Três caminhos, do mais
simples ao mais completo.

## 1. A lista de segunda-feira (SQL Editor, copiar e colar)

```sql
SELECT s.ranking, s.projeto_id, p.nome_projeto, p.cliente, s.prob_estouro_30d, s.faixa_risco, s.principais_fatores
FROM lakehouse_vertice.gold.score_estouro_30d s
JOIN lakehouse_vertice.gold.projeto_situacao_atual p USING (projeto_id)
ORDER BY s.ranking;
```

Como ler:

- **prob_estouro_30d = 1,0**: o projeto **já** está abaixo de 0,9. A regra de corte acendeu.
  A coluna de motivos diz por quê (ex.: *"falta de SRE em 4 dos últimos 4 status"*).
- **faixa "medio" ou "alto" com prob < 1**: o projeto está "ok" para a regra, mas o modelo
  vê risco de cruzar em 30 dias. **É aqui que está o valor**: hoje, o **PRJ-024**
  (marketplace de sellers, 46%, a 15 dias do freeze da Black Friday) e o **PRJ-013** (89%, com o
  status e a planilha discordando).
- **"sem sinal de piora"**: pode tirar da pauta.

## 2. O que o modelo vale (para defender na reunião)

```sql
SELECT ROUND(auc, 3) AS acerto_modelo, ROUND(auc_baseline_folga, 3) AS acerto_regra_simples,
       estouros_avisados || ' de ' || estouros_teste AS estouros_avisados,
       ROUND(antecedencia_media_dias) AS dias_de_antecedencia
FROM lakehouse_vertice.ml.modelo_metricas;
```

A frase: *"dos 10 projetos que estouraram desde abril, 9 apareceriam na lista dos 5 mais
arriscados da semana, em média 41 dias antes. A regra de hoje avisou zero antes."*

## 3. Perguntar em português (Genie Code no SQL Editor)

No SQL Editor, abra o assistente e peça:

- *"Liste os projetos de gold.score_estouro_30d com faixa medio ou alto que estão com
  situação ok em gold.projeto_situacao_atual."*
- *"Para o projeto PRJ-024, mostre a evolução semanal de spi e cpi em ml.features_projeto_semana
  desde outubro de 2025."* (repare no que aconteceu no freeze da Black Friday do ano passado)

Confira a resposta com a tabela "O que deve aparecer na tela" do [README](README.md).

> O Genie que responde isso sem você escrever nada, junto com o que dizem os contratos e o
> manual da Vértice, é o primeiro prompt da noite 4.
