# Roteiro · Dashboard e Genie (bloco final da noite 1, ~15 min)

O ponto do bloco: **a resposta vira tela**, e o Genie, que parece mágica, **erra com confiança**
quando o dado está espalhado em três ferramentas e nenhum KPI está definido. Isso prepara a noite 2.

## As 4 perguntas do dono

Abra o bloco com a cena: o dono da Vértice chama o novo CTO (você, que até mês passado era
engenheiro de dados) e faz quatro perguntas. São as perguntas da semana inteira:

1. **Quais projetos estão atrasados, e de quais clientes?**
2. **Quanto esse atraso vai me custar?**
3. **Tenho gente parada enquanto outro projeto pede gente?**
4. **O que vai dar errado no próximo mês, e o que eu faço agora?**

Bônus, que a noite 1 já responde: **posso confiar no farol que os gerentes me mostram?**

## 1. O dashboard (7 min)

Abra **Dashboards → Projeto Farol · Noite 1 (bronze)** (ou rode
`python3 aulas/aula-01-analista/gerar_dashboard.py --deploy --profile SEU-PERFIL`).

O que mostrar, nesta ordem:

1. **Os 4 números do topo**: carteira de R$ 208,6 mi em andamento, 17 projetos em risco, 7 críticos e
   **4 projetos com farol verde e SPI abaixo de 0,9**. São os mesmos números dos exemplos 05 e 06:
   o dashboard não inventa nada, é o mesmo SQL.
2. **O gráfico "por ferramenta e situação"**: tem projeto crítico no Excel, no ClickUp e no MS Project.
   Até hoje ninguém via os três lados ao mesmo tempo.
3. **Clique numa barra** do SPI por projeto: a tabela embaixo filtra. Os widgets compartilham o dataset.
4. **A tabela**: coloque lado a lado a coluna "Farol do gerente" e a "Situação". PRJ-012, PRJ-028,
   PRJ-034 e PRJ-042 estão verdes para o gerente e em atenção pelo número.
5. **Abra o dataset** (Edit draft → Data): ele lê o `rascunho_tarefas` do exemplo 05, cheio de `CASE`,
   `replace` e conversão de data. Pergunte: *"e se amanhã alguém montar outro painel e esquecer a linha de TOTAL do Excel?"*
6. **Mostre que é código**: `dashboard-bronze.lvdash.json` no repositório. Versionado, revisável, recriável.

## 2. O Genie (8 min)

Abra **Genie Agents → Farol · Noite 1 (bronze, sem curadoria)**.
Ele tem 8 tabelas da bronze e **nenhuma instrução**. Faça as 4 perguntas do dono, nesta ordem.
Os resultados abaixo foram observados no ensaio de 18/10.

| # | Pergunta do dono | O que o Genie fez | O que comentar |
|---|---|---|---|
| 1 | *Quais projetos estão atrasados, e de quais clientes?* | comparou datas de tarefas do Excel e listou 7 projetos; só o PRJ-011 bate com os 7 críticos ❌ | Ele olhou uma ferramenta só. "Atrasado" não está definido em lugar nenhum. |
| 2 | *Quanto esse atraso vai me custar?* | varia a cada vez e erra sempre: já disse "nenhum atraso está impactando financeiramente" e, no print do README, "27 atrasados" com o PRJ-011 (crítico) de custo negativo ❌ | O estouro previsto é de **R$ 6,47 mi** (exemplo 06). Sem a definição de EAC, ele não tem como saber. |
| 3 | *Tenho gente parada enquanto outro projeto pede gente?* | "não há colaboradores parados" ❌ | Dois SREs seniores apontam 2% a 9% das horas no PRJ-007, e o PRJ-011 pede SRE toda semana. A resposta está no texto do status, que ele não cruzou com o timesheet. |
| 4 | *O que vai dar errado no próximo mês?* | "não pode ser respondida com os dados disponíveis" | Esta é honesta: prever é a noite 3. |

Reserva, para mostrar que ele **sabe** ler texto quando a pergunta aponta o lugar:

- *Por que o projeto PRJ-011 atrasou?* → leu o `status_semanal` e respondeu "falta de SRE: pipeline de deploy
  quebrado e homologação fora do ar" ✅
- *Qual é o CPI de cada projeto?* → calculou valor do contrato ÷ custo e deu CPI entre 1,2 e 6,8 ❌
  (CPI de 6 não existe; ele não sabe o que é CPI na Vértice).

> O Genie pode responder diferente a cada execução. Se ele acertar uma, ótimo: pergunte
> *"e qual a regra de crítico?"* e mostre que ele não conhece o corte de 0,8 da Torre.

**A frase de fechamento:** *"O Genie é tão bom quanto o dado e as definições que você dá a ele. Hoje o
dado está em três ferramentas e cada KPI mora dentro de uma query. Amanhã a gente integra as três
ferramentas num pipeline, define cada KPI uma vez só e ensina o Genie. Aí ele responde as perguntas 1, 2 e 3."*

## Perguntas de reserva (se sobrar tempo)

- *Qual consultoria mais atrasa entregas?* → ele vê 4 "fornecedores" diferentes para a CodeForge.
- *Quantos projetos estão no Excel?* → `ferramenta = 'Excel'` perde "excel" e "Planilha".
