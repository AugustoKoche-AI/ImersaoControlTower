# PRD — Projeto Farol: a Torre de Controle de Projetos (Imersão Databricks)

Out 18, 2026 · @Luciano

## Visão geral

Em 4 noites, os alunos constroem no Databricks a **Torre de Controle de Projetos** de uma empresa de tecnologia —
e saem sabendo vender esse projeto para o dono da empresa.

A narrativa: **você é o único profissional de dados** da Vértice Tecnologia, e faz o trabalho de analista, engenheiro, cientista e engenheiro de IA. O primeiro grande
case é simples de dizer e difícil de fazer: ninguém sabe quais projetos estão atrasados, porque cada gerente controla o
seu numa ferramenta — planilhas Excel, ClickUp ou MS Project — e o PMO consolida tudo à mão, toda sexta.

O produto cobre a plataforma de ponta a ponta: ingestão de qualquer formato (`read_files` com Excel, JSON e XML),
integração e transformação (Lakeflow), IA sobre texto livre (`ai_classify`, `ai_extract`, `ai_parse_document`), KPIs
governados (Metric Views), dashboards AI/BI, Genie, um modelo de previsão (MLflow + Unity Catalog), um Data App com
Lakebase para registrar decisões, e um agente que lê os contratos de fornecedor. Tudo roda no **Databricks Free
Edition**, então cada aluno reproduz na própria conta, construindo com o **Claude Code** e as skills oficiais do Databricks.

## Objetivos e métricas de sucesso

O projeto tem dois clientes: o dono da Vértice, que usa a Torre, e o aluno, que a constrói.

**Objetivo do produto (dentro do cenário):** responder, toda segunda de manhã, as quatro perguntas do dono:

1. **Quais projetos estão atrasados, e de quais clientes?**
2. **Quanto esse atraso vai me custar?**
3. **Tenho gente parada enquanto outro projeto pede gente?**
4. **O que vai dar errado no próximo mês, e o que eu faço agora?**

| Métrica do produto | Hoje (cenário) | Com a Torre |
| --- | --- | --- |
| Projetos com SPI/CPI atualizados toda semana | 0% (cada ferramenta de um jeito) | 100% das 3 ferramentas |
| Tempo para responder "por que o projeto X atrasou?" | dias (ler status de cada gerente) | < 1 minuto (Genie) |
| Antecedência na detecção de estouro | 0 dias (o cliente reclama) | ~41 dias (modelo da noite 3) |
| Farol confiável | farol do gerente | farol calculado pelo número |
| Decisões de realocação registradas | e-mail/WhatsApp | 100% no app, com dono e horário |

**Objetivo da imersão (para o aluno):** sair com um projeto de ponta a ponta no GitHub e com o pitch pronto.

| Métrica da imersão | Meta |
| --- | --- |
| Alunos que concluem a Torre rodando na própria conta Free Edition | ≥ 70% dos inscritos |
| Alunos que publicam o projeto (GitHub + vídeo/LinkedIn) | ≥ 50% |
| Alunos que apresentam o pitch de 3 minutos no dia 4 | ≥ 60% |
| NPS da imersão | ≥ 70 |

## Cenário de negócio

A **Vértice Tecnologia** (fictícia) desenvolve e implanta sistemas para grandes clientes de varejo, financeiro, saúde,
logística e indústria: 60 projetos (41 em andamento), R$ 305 mi de carteira, 520 pessoas.

| Fonte | Onde mora | O que traz |
| --- | --- | --- |
| Cronogramas | 20 planilhas Excel · 25 listas do ClickUp (JSON) · 15 arquivos do MS Project (XML) | tarefas, baseline, realizado, % concluído, horas |
| PMO | cadastro de projetos (o de-para) + status semanal em texto livre | ferramenta de cada projeto, farol do gerente, bloqueios |
| RH e timesheet | colaboradores, alocações, apontamentos semanais | quem está onde e quanto trabalhou |
| Financeiro | lançamentos de custo | pessoal, consultoria, cloud, licenças, despesas |
| Compras | entregas das consultorias | prometido × entregue |
| Documentos | 8 contratos de fornecedor/SaaS (PDF) | multa, SLA, renovação, aviso prévio |

### Personas

| Persona | O que precisa | Como usa a Torre |
| --- | --- | --- |
| Dono / diretoria | quais projetos atrasam, de quais clientes, quanto custa | dashboard + perguntas ao Genie |
| Profissional de dados (o aluno) | construir e operar tudo isso | bundle, pipeline, modelo, app, com Claude Code |
| PMO | as 3 ferramentas numa visão só, simular realocação | app: simula, aprova e registra |
| Gerente de projeto | a causa do desvio, sem farol de enfeite | causa extraída do status semanal |
| Financeiro | margem por contrato, estouro previsto, multa de fornecedor | EAC, margem e exposição contratual governados |
| Compras | consultoria que atrasa | ranking de fornecedor e multa cobrável |

## KPIs

| KPI | Definição | Noite |
| --- | --- | --- |
| SPI | horas agregadas ÷ horas planejadas (baseline) | 1, 2 |
| CPI | EV ÷ custo real, com EV = orçamento × horas agregadas ÷ horas totais | 1, 2 |
| EAC · estouro previsto · margem projetada | orçamento ÷ CPI · EAC − orçamento (só positivo) · (contrato − EAC) ÷ contrato | 1, 2 |
| Atraso projetado | duração ÷ SPI − duração | 1, 2 |
| Farol calculado · melancia | verde ≥ 0,95, amarelo ≥ 0,90 · farol do gerente verde com SPI < 0,9 | 1, 2 |
| Utilização · horas e custo ociosos | apontadas ÷ disponíveis; < 20% em 12 semanas = parado | 2 |
| Prazo real ÷ prometido do fornecedor | média por fornecedor normalizado | 2 |
| Probabilidade de estouro em 30 dias | modelo: o pior índice cruza 0,9 em até 4 semanas | 3 |
| Multa cobrável · aviso prévio vencendo | contrato × entregas atrasadas · fim da vigência − aviso prévio | 4 |

Regra de corte: SPI ou CPI < 0,9 = atenção; < 0,8 = crítico. "Hoje" do dataset: 16/10/2026.

## Padrões embutidos no dado (seed 42)

1. 8 projetos com CPI caindo a partir do 6º mês (escopo cresce sem aditivo).
2. O change freeze da Black Friday (01/11 a 10/01) trava os 3 projetos de e-commerce; o de 2026 começa em 01/11.
3. A consultoria CodeForge entrega com prazo 41% acima do prometido e aparece escrita de 4 jeitos.
4. Duas SREs seniores a ~5% no PRJ-007 (ainda no discovery) enquanto o status do PRJ-011 pede SRE há 12 semanas.
5. Dois squads com rotatividade alta (PRJ-016 e PRJ-030), os piores SPI da carteira.
6. Bônus: 4 projetos com farol verde e SPI abaixo de 0,9.

A sujeira é proposital e é o conteúdo da noite 2: cada ferramenta com seu formato de data, percentual e hora; linha de
TOTAL na planilha; tarefas-resumo no Project; status escrito de 12 jeitos; ferramenta escrita de 8 jeitos; vírgula
decimal; estornos; pessoa duplicada; status vazio.

## Escopo por noite

| Noite | Chapéu | Entrega | Como constrói |
| --- | --- | --- | --- |
| 1 | Analista | bronze lendo Excel, JSON e XML; 6 exemplos SQL até o SPI das 3 ferramentas (UNION à mão); dashboard; Genie sem curadoria que erra | navegador |
| 2 | Engenheiro de Dados | bundle; pipeline Lakeflow que integra as 3 ferramentas (silver.tarefas); gold; IA nos status semanais; a metric view mv_projetos; dashboard e Genie curado | 6 prompts no Claude Code |
| 3 | Cientista de Dados | features projeto × semana; modelo de estouro em 30 dias (MLflow + UC); score por projeto com motivos | 3 prompts |
| 4 | Engenheiro de IA | agente de contratos (ai_parse_document + ai_extract tipado + Genie); app da Torre (AppKit) com simulador e aprovação no Lakebase; pitch | 3 prompts |



## Fora de escopo

- Conectores reais com Excel Online, ClickUp e MS Project (a ingestão é por arquivo exportado no volume).
- Endpoint de modelo próprio (o Free Edition só serve modelos de base): o score roda em lote e grava na gold.
- Knowledge Assistant e Supervisor Agent (marcados como legado no Free Edition): o agente é Genie sobre tabelas extraídas.

## Riscos

| Risco | Mitigação |
| --- | --- |
| Free Edition muda entre o ensaio e a aula | tudo medido em 18/10/2026; `APRENDIZADOS.md` por noite |
| Limite de 3 apps no Free Edition | o aluno usa a própria conta; no workspace do instrutor, liberar um app antes da noite 4 |
| IA lenta ou cara | IA só nos textos com bloqueio dos últimos 90 dias; MERGE incremental |
| Aluno perde uma noite | cada pasta é autocontida, com gabarito e verificação |
