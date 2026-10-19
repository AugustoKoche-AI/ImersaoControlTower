# Prompt 1 · Features — o que descreve um projeto que vai estourar

**Entrega:** `ml.features_projeto_semana` (uma linha por projeto e semana, só olhando
para trás, com os dois alvos) e a tarefa `ml_features` no job. **Deploy nº 7.**

> **Por que um schema `ml`?** Features, métricas e o modelo são o laboratório do cientista:
> passo intermediário, não resposta para a diretoria. Na `gold` entra só o resultado
> (`gold.score_estouro_30d`, no prompt 3).

---

## O que mostrar antes

A pergunta 4 do dono, escrita no quadro:

```
"O que vai dar errado no próximo mês, e o que eu faço agora?"

hoje (regra de corte)        SPI ou CPI < 0,9  →  acende QUANDO já estourou
o que o dono quer            acender ANTES:  30 dias de antecedência
```

E a tradução para ML, de trás para frente:

```
pergunta → rótulo → grão → features → modelo
"vai estourar em 30 dias?"
   → o pior índice (menor entre SPI e CPI) nas próximas 4 semanas fica < 0,9?
   → projeto × semana (o status do PMO é semanal, toda sexta)
   → tudo que o projeto mostrava NAQUELA sexta
```

**A regra de ouro da noite:** feature só olha para trás. Se uma coluna sabe algo
que aconteceu depois da sexta-feira da linha, o modelo fica brilhante no treino e
inútil na segunda-feira. O prompt 2 vai provar isso.

**Enquanto ele trabalha, você explica:**

- **Por que projeto × semana e não só projeto?** Com 60 projetos não existe ML. Com
  4.235 sextas-feiras de projeto, existe: cada sexta é uma foto, e o rótulo é o que veio depois.
- **Elegível.** A pergunta só faz sentido para projeto que ainda está acima de 0,9
  (quem já está abaixo, a regra vê), com 12+ semanas de vida e não terminado.
- **Os sinais.** Nível (SPI, CPI), tendência (quanto caiu em 4 e 8 semanas),
  ritmo do último mês (`cpi_ultimas_4s` = quanto cada R$ gasto no mês entregou),
  gente e custo (ociosidade, saídas do time, peso da consultoria) e **o texto do
  status semanal**, que a IA classificou na noite 2 (freeze, falta de SRE,
  consultoria, rotatividade, escopo). A noite 2 vira matéria-prima da noite 3.

---

## O prompt

```
Leia aulas/aula-02-engenheiro/prd/CLAUDE.md. Vamos continuar o MESMO bundle
em aulas/aula-02-engenheiro/meu-vertice/: ML é mais uma camada do pipeline,
não um projeto à parte. O "hoje" é DATE'2026-10-16'. Nunca current_date().

Crie src/ml/01-features.sql (sql_task). Primeiro CREATE SCHEMA IF NOT EXISTS
lakehouse_vertice.ml (o laboratório do cientista; na gold só vai o score).
Depois recrie lakehouse_vertice.ml.features_projeto_semana: uma linha por
projeto e semana (sexta-feira), a partir de gold.fato_projeto_semana +
gold.projeto_situacao_atual (o cadastro: início, duração, segmento).
COMMENT na tabela. Toda feature olha SÓ para trás (até a sexta da linha):

- spi, cpi, indice_min = least(spi, cpi)
- d_spi_4s, d_cpi_4s, d_spi_8s, d_cpi_8s (variação em 4 e 8 semanas, com lag())
- d_indice_min_4s
- semanas_cpi_caindo: em quantas das últimas 4 semanas o CPI caiu
- cpi_ultimas_4s = (ev - ev de 4 semanas atrás) / (ac - ac de 4 semanas atrás)
- spi_ultimas_4s = o mesmo com pv
- pct_fisico = ev / orcamento; pct_prazo = dias desde o início / duração baseline
- ociosidade_4s = horas ociosas / horas disponíveis das últimas 4 semanas
- pct_consultoria_4s e pct_cloud_4s: participação no custo das últimas
  4 semanas (silver.custos, pela coluna semana)
- saidas_12s: pessoas do squad que se desligaram nas últimas 12 semanas.
  Squad = quem apontou hora no projeto (silver.apontamentos) + data de
  desligamento em silver.colaboradores
- status_freeze_4s, status_falta_sre_4s, status_fornecedor_4s,
  status_rotatividade_4s, status_escopo_4s, status_retrabalho_4s,
  status_com_bloqueio_4s: quantos dos status dos últimos 28 dias tiveram
  cada causa_bloqueio (gold.status_estruturado; vale qualquer método,
  IA ou palavra-chave, porque a causa existe em todas as semanas)

Os dois alvos, do FUTURO, que nunca entram como feature:
- alvo_pior_indice_30d: o menor least(spi, cpi) nas 4 semanas SEGUINTES
  (MIN ... ROWS BETWEEN 1 FOLLOWING AND 4 FOLLOWING)
- estoura_30d: 1 se esse pior índice < 0,9, senão 0
Os dois NULL quando ainda não há 4 semanas de futuro (é o caso de hoje).

elegivel = 1 se SPI e CPI >= 0,9, o projeto tem 84+ dias, ev < 98% do
orçamento e (status = em_andamento ou a semana é anterior a hoje).

ARMADILHA MEDIDA: o Spark não aceita estender uma janela nomeada com frame
(OVER (w ROWS BETWEEN ...) dá PARSE_SYNTAX_ERROR). Escreva o PARTITION BY
e o ORDER BY por extenso nas janelas com ROWS BETWEEN.

No fim do arquivo, uma query de conferência: linhas, linhas de treino
(elegível com rótulo), taxa base e linhas de hoje.

Acrescente ao job vertice_farol a tarefa ml_features (sql_task), depois de
metricas_governadas. Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run vertice_farol --only ml_features --profile <perfil>
```

---

## O que conferir

```sql
SELECT COUNT(*) AS linhas,
       COUNT_IF(elegivel = 1 AND estoura_30d IS NOT NULL) AS treino,
       ROUND(AVG(CASE WHEN elegivel = 1 THEN estoura_30d END), 3) AS taxa_base,
       COUNT_IF(semana = DATE'2026-10-16') AS hoje
FROM lakehouse_vertice.ml.features_projeto_semana;
-- 4.235 · 1.643 · 0,167 · 60
```

**A taxa base é 16,7%.** De cada 100 semanas de projeto "ok", 17 terminam o mês
abaixo de 0,9. Achar essas 17 antes é o trabalho do modelo.

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `PARSE_SYNTAX_ERROR ... missing ')'` | `OVER (w ROWS BETWEEN ...)` | janela por extenso nas que têm frame |
| `SCHEMA_NOT_FOUND ... ml` | faltou o `CREATE SCHEMA IF NOT EXISTS lakehouse_vertice.ml` | ele vem antes da tabela, no mesmo arquivo |
| `TABLE_OR_VIEW_NOT_FOUND gold.status_estruturado` | a tarefa `status_com_ia` da noite 2 não rodou | `bundle run vertice_farol` inteiro uma vez |
| taxa base perto de 0 ou de 50% | rótulo olhando a semana errada | `1 FOLLOWING AND 4 FOLLOWING`, nunca `CURRENT ROW` |
| `hoje` = 0 | a gold não chega a 2026-10-16 | confira `MAX(semana)` em `fato_projeto_semana` |
| as colunas `status_*` quase sempre zero no histórico | filtrou `metodo = 'ia'` | a IA só cobre 90 dias; use a `causa_bloqueio` de todos os métodos |

**Tempo medido:** ~20 s no warehouse.
