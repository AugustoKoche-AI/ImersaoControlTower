# Prompt 4 · Dashboard e Genie — o dono pergunta em português

**Entrega:** o dashboard de Portfólio (3 páginas) e o Genie Agent da diretoria,
ambos como código no bundle, e o benchmark de 20 perguntas. **O último deploy da noite 3.**
(Até 20/10 era o prompt 6 da noite 2. Mudou para cá: a noite 2 fecha na modelagem.)

> O fechamento da noite: o Genie que errou as quatro perguntas do dono na segunda agora
> acerta. O modelo de IA é o mesmo. Mudou tudo que está embaixo dele.

---

## O que mostrar antes

Abra lado a lado o Genie da noite 1 (bronze, sem curadoria) e faça as perguntas que
ele errou:

```
"Quanto esse atraso vai me custar?"                      → noite 1: "nenhum atraso tem impacto financeiro"
"Tenho gente parada enquanto outro projeto pede gente?"  → noite 1: "não há colaboradores parados"
```

**Enquanto ele trabalha, você explica:**

- **Dashboard como código.** O JSON está no Git, dentro do bundle: tem diff,
  revisão e rollback. Compare o SQL dos datasets com o da noite 1: sem `CASE` de
  número de série, sem `replace`, sem `filter(custom_fields, ...)`. A integração e a
  limpeza moram na silver.
- **Genie como código.** As instruções de negócio (o "hoje" do dataset, as regras de
  corte, onde achar a causa do atraso, o que é "próximo mês") viram arquivo versionado.
- **Benchmark é teste de IA.** 20 perguntas com a resposta certa em SQL. O script roda
  cada uma no Genie e compara com a referência. Mudou a instrução? Roda o benchmark.
  É o mesmo raciocínio do teste da gold.
- **Ordem que importa:** o Genie só é criado se as tabelas já existem. Num workspace
  zerado, faça deploy → run → deploy.

---

## O prompt

```
Continue o bundle na raiz deste repositório. O pipeline, a IA e
as métricas estão prontos. Agora as duas portas para quem não escreve SQL.

1. Dashboard como código
   - scripts/gerar_dashboard.py gera resources/dashboard-portfolio.lvdash.json
     (AI/BI, GRID_V1, queries da gold com nome de tabela PURO, sem catálogo
     nem schema; a silver.entregas_fornecedor vai com o nome completo
     lakehouse_vertice.silver.entregas_fornecedor). Três páginas:
     Portfólio: KPIs da mv_projetos com MEASURE() (carteira, SPI, CPI, estouro
       previsto, projetos em risco, críticos, melancias); barra de estouro
       previsto por projeto colorida por situação (crítico #FF5F46, atenção
       #F6C344, ok #22C2F4); dispersão SPI × CPI; linha de SPI e CPI semanais
       da carteira (SUM(ev)/SUM(pv) por semana no fato_projeto_semana); tabela dos projetos em andamento com o farol
       do gerente ao lado do farol pelo número.
     Pessoas: top 15 pessoas por custo da hora parada (12 semanas), tabela de
       utilização por pessoa e projeto, e barras de causas de bloqueio por
       projeto (status_estruturado, últimos 90 dias).
     Fornecedores: tabela por fornecedor (grafias no cadastro, entregas,
       prazo real ÷ prometido, % no prazo, em atraso hoje) e tabela das
       entregas em atraso hoje, as duas sobre silver.entregas_fornecedor.
     Tema nas cores da Jornada: #0059DB, #22C2F4, fundo #14141A no escuro.
   - resources/dashboard.dashboard.yml: recurso dashboard_portfolio, display
     name "Projeto Farol · Portfólio", dataset_catalog ${var.catalog},
     dataset_schema gold, warehouse ${var.warehouse_id}.
   Antes do deploy, rode cada query do dashboard (prefixando
   lakehouse_vertice.gold. nas tabelas gold) e me mostre a contagem de linhas de cada uma.

2. Genie Agent como código
   - scripts/gerar_genie.py gera resources/farol.geniespace.json
     (serialized_space versão 2; ids de 32 caracteres hex, únicos e em ordem):
     tabelas gold.fato_projeto_semana, gold.projeto_situacao_atual,
     gold.status_estruturado, gold.utilizacao_pessoa_semana e
     silver.entregas_fornecedor, e a metric view gold.mv_projetos; as 4 perguntas do dono como perguntas de
     exemplo; instruções de texto com: quem pergunta (o dono e a diretoria); HOJE =
     2026-10-16 e o que é "últimos 90 dias / 12 semanas / próximo mês"; as
     fórmulas e as regras de corte; mv_projetos para totais de hoje e
     projeto_situacao_atual para ranking; PV/EV/AC acumulados no fato (nunca
     somar semanas); farol e melancia; "por que o projeto X atrasou" responde
     com status_estruturado dos últimos 90 dias (sem sem_bloqueio e
     nao_reportado), mais o SPI e SREs ociosos se a causa for falta_sre;
     gente parada = utilização < 20% em 12 semanas; fornecedor = prazo real ÷
     prometido na silver.entregas_fornecedor; "o que vai dar errado no
     próximo mês" junta as entregas de consultoria em atraso e o change
     freeze de varejo (01/11/2026 a 10/01/2027) nos projetos de e-commerce
     (o modelo de previsão vem na noite 3); "quais clientes" devolve cada
     cliente uma vez. E um exemplo de SQL para
     cada uma das 4 perguntas do dono.
   - resources/genie.genie_space.yml: recurso genie_farol, título
     "Farol · Diretoria".

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle summary --profile <perfil>
  python3 scripts/genie.py perguntar "Farol · Diretoria" "Tenho gente parada enquanto outro projeto pede gente?" --profile <perfil>
  python3 scripts/genie.py benchmark "Farol · Diretoria" aulas/aula-03-modelagem-claude-code/claude-code/prd/genie-benchmark.json --profile <perfil>
Se o benchmark der menos de 16/20, mostre os erros e ajuste a INSTRUÇÃO
(não a pergunta), gere o JSON, faça deploy e rode de novo.
```

---

## O que conferir

- `bundle summary` mostra a URL do dashboard e do Genie.
- As quatro perguntas do dono, no Genie:
  1. *atrasados e de quais clientes* → 17 projetos de 13 clientes, com SPI e CPI;
  2. *quanto custa* → **R$ 6,47 mi** de estouro previsto, margem projetada de 20%;
  3. *gente parada* → as duas SREs do PRJ-007 a ~5% de utilização, ~450 h paradas e
     ~R$ 90 mil de custo ocioso cada uma (e o PRJ-011 pedindo SRE no status);
  4. *o que vai dar errado no próximo mês* → as 5 entregas atrasadas da CodeForge e o
     freeze de 01/11 nos projetos de e-commerce. A resposta completa (qual projeto vai
     estourar em 30 dias) é o modelo da noite 3.
- O benchmark passa de **16/20**. No ensaio de 18/10: 18/20 na primeira rodada (ranking
  pela metric view e cliente repetido) e **20/20** depois de duas instruções.

> *"Ontem ele disse que o atraso não custava nada. Hoje ele diz quanto custa, quem está
> parado e o que vai quebrar no mês que vem. O modelo é o mesmo. A diferença foi tudo
> que a gente construiu nas últimas duas horas."*

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `Table 'lakehouse_vertice.gold.x' does not exist` no deploy | O Genie foi criado antes do job rodar | `bundle run vertice_farol` e deploy de novo |
| `Duplicate question ID` | ids não únicos no JSON do Genie | Gere ids de 32 caracteres com prefixo diferente por tipo |
| `must be sorted by id` | Lista fora de ordem | Ordene por id; tabelas por identifier |
| Widget "no selected fields to visualize" | `fields[].name` ≠ `encodings.fieldName` | Os dois nomes têm que ser idênticos |
| Dashboard vazio | Query com catálogo hardcoded ou sem `dataset_schema` | Nome puro no SQL + `dataset_catalog`/`dataset_schema` no YAML |
| "O que vai dar errado" volta FAILED | Pergunta aberta, duas fontes | Um exemplo de SQL com `UNION ALL` das entregas em atraso e do freeze resolve |

**Tempo medido:** deploy ~10 s; benchmark de 20 perguntas ~6 min.
