# Prompt 1 · Features — o que descreve uma obra que vai estourar

**Entrega:** `gold.features_obra_semana` (uma linha por obra e semana, só olhando
para trás, com os dois alvos) e a tarefa `ml_features` no job. **Deploy nº 7.**

---

## O que mostrar antes

A pergunta da diretoria, escrita no quadro:

```
"Quais obras vão estourar nos próximos 30 dias?"

hoje (regra de corte)        SPI ou CPI < 0,9  →  acende QUANDO já estourou
o que a diretoria quer        acender ANTES:  30 dias de antecedência
```

E a tradução para ML, de trás para frente:

```
pergunta → rótulo → grão → features → modelo
"vai estourar em 30 dias?"
   → o pior índice (menor entre SPI e CPI) nas próximas 4 semanas fica < 0,9?
   → obra × semana (o boletim de medição é semanal)
   → tudo que a obra mostrava NAQUELA sexta
```

**A regra de ouro da noite:** feature só olha para trás. Se uma coluna sabe algo
que aconteceu depois da sexta-feira da linha, o modelo fica brilhante no treino e
inútil na segunda-feira. O prompt 2 vai provar isso.

**Enquanto ele trabalha, você explica:**

- **Por que obra × semana e não só obra?** Com 40 obras não existe ML. Com 2.874
  semanas de obra, existe: cada sexta é uma foto, e o rótulo é o que veio depois.
- **Elegível.** A pergunta só faz sentido para obra que ainda está acima de 0,9
  (quem já está abaixo, a regra vê), com 12+ semanas de vida e não terminada.
- **Os sinais.** Nível (SPI, CPI), tendência (quanto caiu em 4 e 8 semanas),
  ritmo do último mês (`cpi_ultimas_4s` = quanto cada R$ gasto no mês entregou),
  recursos (ociosidade, rupturas) e **o texto do RDO**, que a IA classificou na
  noite 2. A noite 2 vira matéria-prima da noite 3.

---

## O prompt

```
Leia aulas/aula-02-engenheiro/prd/CLAUDE.md. Vamos continuar o MESMO bundle
em aulas/aula-02-engenheiro/meu-atlas/: ML é mais uma camada do pipeline,
não um projeto à parte. O "hoje" é DATE'2026-10-16'. Nunca current_date().

Crie src/ml/01-features.sql (sql_task) que recria a tabela
lakehouse_atlas.gold.features_obra_semana: uma linha por obra e semana
(sexta-feira), a partir de gold.fato_projeto_semana + gold.dim_projeto.
COMMENT na tabela. Toda feature olha SÓ para trás (até a sexta da linha):

- spi, cpi, indice_min = least(spi, cpi)
- d_spi_4s, d_cpi_4s, d_cpi_8s (variação em 4 e 8 semanas, com lag())
- d_indice_min_4s
- semanas_cpi_caindo: em quantas das últimas 4 semanas o CPI caiu
- cpi_ultimas_4s = (ev - ev de 4 semanas atrás) / (ac - ac de 4 semanas atrás)
- spi_ultimas_4s = o mesmo com pv
- pct_fisico = ev / orcamento; pct_prazo = dias desde o início / duração baseline
- ociosidade_4s = horas ociosas / horas disponíveis das últimas 4 semanas
- rupturas_previstas da semana
- pct_subcontrato_4s e pct_mao_de_obra_4s: participação no custo das
  últimas 4 semanas (silver.custos, pela coluna semana)
- rdo_chuva_4s, rdo_falta_material_4s, rdo_falta_equipamento_4s,
  rdo_mao_de_obra_4s, rdo_com_ocorrencia_4s: fração dos RDOs dos últimos
  28 dias com cada causa (gold.rdo_estruturado)

Os dois alvos, do FUTURO, que nunca entram como feature:
- alvo_pior_indice_30d: o menor least(spi, cpi) nas 4 semanas SEGUINTES
  (MIN ... ROWS BETWEEN 1 FOLLOWING AND 4 FOLLOWING)
- estoura_30d: 1 se esse pior índice < 0,9, senão 0
Os dois NULL quando ainda não há 4 semanas de futuro (é o caso de hoje).

elegivel = 1 se SPI e CPI >= 0,9, a obra tem 84+ dias, ev < 98% do
orçamento e (status = em_andamento ou a semana é anterior a hoje).

ARMADILHA MEDIDA: o Spark não aceita estender uma janela nomeada com frame
(OVER (w ROWS BETWEEN ...) dá PARSE_SYNTAX_ERROR). Escreva o PARTITION BY
e o ORDER BY por extenso nas janelas com ROWS BETWEEN.

No fim do arquivo, uma query de conferência: linhas, linhas de treino
(elegível com rótulo), taxa base e linhas de hoje.

Acrescente ao job atlas_torre a tarefa ml_features (sql_task), depois de
metricas_governadas. Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run atlas_torre --only ml_features --profile <perfil>
```

---

## O que conferir

```sql
SELECT COUNT(*) AS linhas,
       COUNT_IF(elegivel = 1 AND estoura_30d IS NOT NULL) AS treino,
       ROUND(AVG(CASE WHEN elegivel = 1 THEN estoura_30d END), 3) AS taxa_base,
       COUNT_IF(semana = DATE'2026-10-16') AS hoje
FROM lakehouse_atlas.gold.features_obra_semana;
-- 2.874 · 1.535 · 0,084 · 40
```

**A taxa base é 8,4%.** De cada 100 semanas de obra "ok", 8 terminam o mês
abaixo de 0,9. Achar essas 8 antes é o trabalho do modelo.

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `PARSE_SYNTAX_ERROR ... missing ')'` | `OVER (w ROWS BETWEEN ...)` | janela por extenso nas que têm frame |
| `TABLE_OR_VIEW_NOT_FOUND gold.rdo_estruturado` | a tarefa `rdo_com_ia` da noite 2 não rodou | `bundle run atlas_torre` inteiro uma vez |
| taxa base perto de 0 ou de 50% | rótulo olhando a semana errada | `1 FOLLOWING AND 4 FOLLOWING`, nunca `CURRENT ROW` |
| `hoje` = 0 | a gold não chega a 2026-10-16 | confira `MAX(semana)` em `fato_projeto_semana` |

**Tempo medido:** ~20 s no warehouse.
