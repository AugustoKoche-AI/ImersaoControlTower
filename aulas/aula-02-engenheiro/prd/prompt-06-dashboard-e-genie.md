# Prompt 6 · Dashboard e Genie — a diretoria pergunta em português

**Entrega:** o dashboard de Portfólio (3 páginas) e o Genie Agent da diretoria,
ambos como código no bundle, e o benchmark de 20 perguntas. **Deploy nº 6.**

> O fechamento da noite: o Genie que respondeu "CPI de 7,01" ontem agora acerta.
> O modelo de IA é o mesmo. Mudou tudo que está embaixo dele.

---

## O que mostrar antes

Abra lado a lado o Genie da noite 1 (bronze, sem curadoria) e faça a mesma
pergunta que ele errou:

```
"Qual é o CPI de cada obra?"           → noite 1: 7,01 (JOIN multiplicou as linhas)
"Por que a obra P011 atrasou?"         → noite 1: lista de tarefas atrasadas
```

**Enquanto ele trabalha, você explica:**

- **Dashboard como código.** O JSON está no Git, dentro do bundle: tem diff,
  revisão e rollback. Compare o SQL dos datasets com o da noite 1: sem `CAST`,
  sem `replace`, sem `try_to_date`. A limpeza mora na silver.
- **Genie como código.** As instruções de negócio (o "hoje" do dataset, as
  regras de corte, onde achar a causa do atraso) viram arquivo versionado.
- **Benchmark é teste de IA.** 20 perguntas com a resposta certa em SQL. O
  script roda cada uma no Genie e compara com a referência. Mudou a instrução?
  Roda o benchmark. É o mesmo raciocínio do teste da gold.
- **Ordem que importa:** o Genie só é criado se as tabelas já existem. Num
  workspace zerado, faça deploy → run → deploy.

---

## O prompt

```
Continue o bundle em aulas/aula-02-engenheiro/meu-atlas/. O pipeline e as
métricas estão prontos. Agora as duas portas para quem não escreve SQL.

1. Dashboard como código
   - scripts/gerar_dashboard.py gera resources/dashboard-portfolio.lvdash.json
     (AI/BI, GRID_V1, queries com nome de tabela PURO, sem catálogo nem
     schema). Três páginas:
     Portfólio: KPIs da mv_obras com MEASURE() (carteira, SPI, CPI, obras em
       risco, críticas, estouro previsto); barra de estouro previsto por obra
       colorida por situação (crítico #FF5F46, atenção #F6C344, ok #22C2F4);
       dispersão SPI × CPI; linha de SPI e CPI semanais da carteira
       (mv_evolucao); tabela das obras em andamento.
     Recursos: top 15 equipamentos por custo ocioso (12 semanas), tabela da
       frota com utilização, horas ociosas de equipe por obra (8 semanas).
     Suprimentos: rupturas previstas por obra, tabela de fornecedores
       (grafias no ERP, lead time prometido x real, % no prazo, em atraso) e
       tabela de cobertura por material.
     Tema nas cores da Jornada: #0059DB, #22C2F4, fundo #14141A no escuro.
   - resources/dashboard.dashboard.yml: recurso dashboard_portfolio, display
     name "Torre de Controle · Portfólio", dataset_catalog ${var.catalog},
     dataset_schema gold, warehouse ${var.warehouse_id}.
   Antes do deploy, rode cada query do dashboard (prefixando
   lakehouse_atlas.gold.) e me mostre a contagem de linhas de cada uma.

2. Genie Agent como código
   - scripts/gerar_genie.py gera resources/torre.geniespace.json
     (serialized_space versão 2; ids de 32 caracteres hex, únicos e em ordem):
     tabelas gold (cobertura_estoque, desempenho_fornecedor, dim_projeto,
     fato_projeto_semana, obra_situacao_atual, pedidos_em_atraso,
     rdo_estruturado, utilizacao_equipamento_semana, utilizacao_equipe_semana)
     e as 5 metric views mv_*; as 4 perguntas de exemplo (as 3 da diretoria +
     "Por que a obra P011 atrasou?"); uma instrução de texto com: HOJE =
     2026-10-16 e o que é "últimos 90 dias / 12 semanas / 8 semanas"; as
     fórmulas e as regras de corte; usar mv_obras para KPIs de hoje; PV/EV/AC
     acumulados no fato (nunca somar semanas); "por que a obra X atrasou"
     responde com rdo_estruturado dos últimos 90 dias, sem sem_ocorrencia e
     nao_reportado, mais o SPI e equipamentos ociosos se a causa for
     falta_equipamento. E 5 exemplos de SQL, um deles para a P011.
   - resources/genie.genie_space.yml: recurso genie_torre, título
     "Torre de Controle · Diretoria".

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle summary --profile <perfil>
  python3 scripts/genie.py perguntar "Torre de Controle · Diretoria" "Por que a obra P011 atrasou?" --profile <perfil>
  python3 scripts/genie.py benchmark "Torre de Controle · Diretoria" aulas/aula-02-engenheiro/prd/genie-benchmark.json --profile <perfil>
Se o benchmark der menos de 16/20, mostre os erros e ajuste a INSTRUÇÃO
(não a pergunta), gere o JSON, faça deploy e rode de novo.
```

---

## O que conferir

- `bundle summary` mostra a URL do dashboard e do Genie.
- O Genie, perguntado "Por que a obra P011 atrasou?", responde **falta de
  equipamento (37 RDOs, 23,5 dias de impacto)**, com SPI 0,78. Na pergunta
  seguinte, "Onde tenho guindaste parado?", ele aponta EQ0017 e EQ0018 na P007 (MG).
- O benchmark passa de **16/20**. No ensaio: 19/20 na primeira rodada (o erro era
  arredondamento na referência) e **20/20** depois de corrigida, no Genie recriado do zero.

> *"Ontem ele respondeu CPI de 7. Hoje ele explica por que a obra do Pará atrasou
> e onde está o guindaste que falta. O modelo é o mesmo. A diferença foi tudo que a
> gente construiu nas últimas duas horas."*

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `Table 'lakehouse_atlas.gold.x' does not exist` no deploy | O Genie foi criado antes do job rodar | `bundle run atlas_torre` e deploy de novo |
| `Duplicate question ID` | ids não únicos no JSON do Genie | Gere ids de 32 caracteres com prefixo diferente por tipo |
| `must be sorted by id` | Lista fora de ordem | Ordene por id; tabelas por identifier |
| Widget "no selected fields to visualize" | `fields[].name` ≠ `encodings.fieldName` | Os dois nomes têm que ser idênticos |
| Dashboard vazio | Query com catálogo hardcoded ou sem `dataset_schema` | Nome puro no SQL + `dataset_catalog`/`dataset_schema` no YAML |
| Benchmark erra só por casas decimais | Referência arredondada diferente do Genie | O comparador usa 2 casas; não arredonde a referência para inteiro |

**Tempo medido:** deploy ~10 s; benchmark de 20 perguntas ~6 min.
