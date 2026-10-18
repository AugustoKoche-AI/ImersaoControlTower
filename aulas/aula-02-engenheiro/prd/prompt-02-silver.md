# Prompt 2 · Silver — a limpeza com contrato

**Entrega:** o pipeline declarativo `atlas_medalhao` com as 12 tabelas silver,
limpas e tipadas, com as regras de qualidade declaradas como `EXPECT`.
**Deploy nº 2.**

> **A entrega mais importante da noite. Não corte.**

---

## O que mostrar antes

A sujeira **com número**, não com adjetivo. Quatro queries na bronze, três minutos:

```sql
-- 1 · a vírgula decimal: o CAST quebra...
SELECT SUM(CAST(valor_real AS DECIMAL(18,2))) FROM lakehouse_atlas.bronze.custos;
-- [CAST_INVALID_INPUT] The value '31262,81' ... cannot be cast

-- ...e o try_cast "funciona": joga 540 lançamentos fora em silêncio
SELECT ROUND(SUM(try_cast(valor_real AS DECIMAL(18,2))) / 1e6, 2) AS errado,
       ROUND(SUM(CAST(replace(valor_real, ',', '.') AS DECIMAL(18,2))) / 1e6, 2) AS certo
FROM lakehouse_atlas.bronze.custos;
-- 556,09 × 572,85: R$ 16,8 milhões sumiram sem erro nenhum

-- 2 · o mesmo fornecedor, quatro fornecedores
SELECT fornecedor, COUNT(*) FROM lakehouse_atlas.bronze.compras
WHERE lower(fornecedor) LIKE '%norte%' GROUP BY 1;

-- 3 · tarefa 117% concluída
SELECT tarefa_id, pct_concluido FROM lakehouse_atlas.bronze.tarefas
WHERE CAST(pct_concluido AS DOUBLE) > 100 ORDER BY 2 DESC LIMIT 5;

-- 4 · a equipe que existe duas vezes
SELECT * FROM lakehouse_atlas.bronze.equipes WHERE equipe_id = 'EQP014';
```

**Enquanto ele trabalha, você explica:**

- **Declarativo é dizer O QUE, não COMO.** Cada arquivo diz "a silver.custos é
  isto". O Lakeflow lê os `FROM`, descobre a ordem, roda em paralelo o que dá e
  desenha o grafo. Você não escreve orquestração.
- **A tarefa de 117% é a decisão da noite.** A tentação é `LEAST(pct, 100)`: o
  número fica plausível e errado. Só que o valor certo **existe** em outro
  sistema: o boletim de medição semanal. Limpar bem é ir buscar a fonte
  confiável, não inventar um valor bonito. (Na noite 1 cortamos em 100; vamos
  ver quanto isso escondia no prompt 3.)
- **Estorno não é sujeira.** Valor negativo em custo é um lançamento revertido.
  Jogar fora inflaria o custo; manter sem flag polui. Fica, com a coluna `estorno`.
- **`EXPECT ... ON VIOLATION FAIL UPDATE` é contrato.** Se amanhã o ERP mandar
  uma data num terceiro formato, o pipeline para em vez de gravar nulo. A regra
  é da tabela, não do script que rodou naquele dia.

---

## O prompt

```
Continue o bundle em aulas/aula-02-engenheiro/meu-atlas/. A bronze está
conferida. Agora a silver: limpar, tipar e declarar o contrato.

Crie um pipeline Lakeflow Spark Declarative Pipelines em SQL:
resources/atlas_medalhao.pipeline.yml com name atlas_medalhao, catalog
${var.catalog}, schema silver, serverless: true, photon: true, e libraries com
um glob em ../src/silver/** (o prompt 3 vai acrescentar ../src/gold/**).

Use CREATE OR REFRESH MATERIALIZED VIEW (nunca CREATE OR REPLACE, que não
existe no pipeline). Leia a bronze pelo nome completo
lakehouse_atlas.bronze.<tabela>; dentro do pipeline, referencie as tabelas
silver só pelo nome. COMMENT em toda tabela dizendo o que foi limpo.

Um arquivo por assunto em src/silver/:

01-projetos.sql
- data_inicio vem em yyyy-MM-dd e dd/MM/yyyy: coalesce de dois try_to_date.
  Guarde data_veio_em_formato_br (boolean).
- uf vem 'MG', 'mg', ' MG ': upper(trim()).
- valor_contrato e orcamento_custo (renomeie para orcamento) em DECIMAL(18,2).
- EXPECT data_inicio IS NOT NULL e length(uf) = 2, ambos FAIL UPDATE.

02-cronograma.sql — avanco_semanal e tarefas
- avanco_semanal tipado (data_medicao DATE, pct_concluido DOUBLE), EXPECT
  pct entre 0 e 100.
- tarefas: 52 tarefas têm pct_concluido > 100. NÃO corte em 100. Use a ÚLTIMA
  medição do boletim (o % só sobe, então max(pct) por tarefa no
  avanco_semanal) e marque pct_corrigido_pela_medicao. EXPECT pct entre 0 e
  100 e valor_planejado > 0, FAIL UPDATE.

03-custos.sql
- valor_real tem 540 linhas com vírgula decimal: replace(',', '.') ANTES do
  CAST. Nunca try_cast (jogaria R$ 16,8 mi fora em silêncio).
- estorno (valor negativo) FICA na tabela e ganha a coluna estorno.
- coluna semana = sexta-feira da semana: date_add(date_trunc('WEEK', data), 4).
- EXPECT valor IS NOT NULL, FAIL UPDATE.

04-suprimentos.sql — materiais, compras, estoque
- compras: o mesmo fornecedor vem com 4 grafias ('Metalúrgica Norte Aço
  Ltda', 'Metalurgica Norte Aco', 'METALÚRGICA NORTE AÇO LTDA', 'Norte Aço
  Metalúrgica'). Normalize tudo que tiver 'norte a' para
  'Metalúrgica Norte Aço Ltda' e guarde fornecedor_como_veio.
  data_entrega vazia = pedido em aberto (não é sujeira). Crie
  lead_time_real_dias, em_aberto e em_atraso (em aberto e data_prometida
  antes de DATE'2026-10-16').
- estoque: saldo negativo (erro de inventário) vira 0 com flag.

05-recursos.sql — equipes, apontamentos, equipamentos, uso_equipamentos
- equipes: EQP014, EQP057 e EQP101 aparecem duas vezes (função em CAIXA ALTA,
  UF em minúscula, headcount diferente). DISTINCT não resolve. Mantenha o
  cadastro com funcao em minúsculas (row_number por equipe_id).
- apontamentos e uso_equipamentos com coluna semana (sexta-feira), como em custos.

06-rdo.sql
- rdo: 82 RDOs vazios ('', 'N/A', 'ver RDO físico'). NÃO descarte: flag rdo_vazio.

Acrescente ao job atlas_torre a tarefa medalhao (pipeline_task apontando para
${resources.pipelines.atlas_medalhao.id}), depois de conferencia_bronze.

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run atlas_medalhao --profile <perfil>
```

---

## O que conferir

```sql
-- a limpeza NÃO mudou o custo: o mesmo número da noite 1
SELECT ROUND(SUM(valor) / 1e6, 2) FROM lakehouse_atlas.silver.custos;                 -- 572,85

SELECT COUNT(*), COUNT(DISTINCT equipe_id) FROM lakehouse_atlas.silver.equipes;         -- 120 e 120
SELECT fornecedor, COUNT(DISTINCT fornecedor_como_veio) FROM lakehouse_atlas.silver.compras
WHERE fornecedor LIKE '%Norte%' GROUP BY 1;                                              -- 1 fornecedor, 4 grafias
SELECT COUNT_IF(pct_corrigido_pela_medicao) FROM lakehouse_atlas.silver.tarefas;          -- 52
```

Abra o pipeline no workspace: o grafo com as 12 tabelas e, em cada uma, a aba
**Data quality** mostrando quantas linhas cada `EXPECT` avaliou.

> *"Eu converti 540 valores, juntei quatro fornecedores em um e tirei três
> equipes duplicadas. O custo total não mudou um centavo. É esse o teste."*

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `CREATE OR REPLACE ... not supported` | Sintaxe de SQL comum dentro do pipeline | `CREATE OR REFRESH MATERIALIZED VIEW` |
| `CAST_INVALID_INPUT '31262,81'` | Faltou o `replace` antes do CAST | `CAST(replace(valor_real, ',', '.') AS DECIMAL(18,2))` |
| Pipeline falha em `pct_entre_0_e_100` | Cortou em 100 em vez de usar a medição, ou esqueceu o `CASE` | É o `EXPECT` funcionando: corrija a regra, não o EXPECT |
| `Update is WAITING_FOR_RESOURCES` por 1 min | Serverless acordando | Normal na primeira execução |
| `An active update already exists` | Rodou duas vezes | Espere a atual terminar |

**Tempo medido:** deploy ~8 s; pipeline ~2 min na primeira execução.
