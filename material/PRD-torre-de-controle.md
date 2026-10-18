# PRD — Torre de Controle de Projetos (Imersão Databricks)

Oct 18, 2026 · @Luciano

## Visão geral

Em 4 dias, os alunos constroem no Databricks a **Torre de Controle de Projetos** que uma empresa de engenharia usaria para parar de perder dinheiro em projetos atrasados — e saem sabendo vender esse projeto para a diretoria.

O tema foi o mais votado pelos alunos: área financeira e gestão de projetos. O cenário é uma empresa de engenharia/EPC que executa dezenas de projetos simultâneos para clientes de mineração, óleo e gás e agroindústria, com controle espalhado em ERP, planilhas de cronograma e relatórios diários de obra (RDO) em PDF. A diretoria só descobre que um projeto estourou prazo ou custo quando já estourou.

O produto cobre a plataforma de ponta a ponta: ingestão e transformação (Lakeflow), KPIs governados, dashboards AI/BI, Genie para perguntas em linguagem natural, um Data App com Lakebase para decisões e agentes (Agent Bricks) que explicam o porquê dos desvios. Tudo roda no Databricks Free Edition, então cada aluno reproduz na própria conta.

O mercado-alvo é concreto: o MME projeta R$ 4 trilhões em investimentos em energia e mineração até 2035, e Petrobras, Vale e Gerdau já são clientes Databricks no Brasil.

## Objetivos e métricas de sucesso

O projeto tem dois clientes: a diretoria fictícia que usa a Torre de Controle e o aluno que a constrói. Cada um tem o seu objetivo e a sua métrica.

**Objetivo do produto (dentro do cenário)**

Reduzir o custo de projetos atrasados antecipando desvios de prazo, custo, recursos e estoque com 30 dias de antecedência, em vez de descobri-los no fechamento.

| Métrica do produto | Hoje (cenário) | Meta |
| --- | --- | --- |
| Antecedência média na detecção de estouro de prazo/custo | 0 dias (no fechamento) | 30 dias |
| Tempo para responder "por que a obra X atrasou?" | 2 a 3 dias (consolidar planilhas) | < 1 minuto (Genie) |
| Projetos com SPI/CPI atualizados diariamente | 0% | 100% |
| Rupturas de estoque detectadas antes de parar a frente | não medido | 100% das previstas |
| Decisões de realocação registradas e rastreáveis | e-mail/WhatsApp | 100% no app |

**Objetivo da imersão (para o aluno)**

Sair com um projeto completo de ponta a ponta no portfólio e com o discurso pronto para vender esse projeto à diretoria de uma empresa de projetos intensivos em capital.

| Métrica da imersão | Meta |
| --- | --- |
| Alunos que concluem a Torre de Controle rodando na própria conta Free Edition | ≥ 70% dos inscritos |
| Alunos que publicam o projeto (GitHub + vídeo/LinkedIn) | ≥ 50% |
| Alunos que apresentam o pitch de 3 minutos para a diretoria no dia 4 | ≥ 60% |
| NPS da imersão | ≥ 70 |

Os valores "hoje" do produto são premissas do cenário fictício, usadas para dar escala ao problema; as metas da imersão são as do time da Jornada e podem ser ajustadas.

## Cenário de negócio

A empresa fictícia é a **Construtora Atlas Engenharia**, uma EPC de médio porte com 40 projetos ativos, 1.200 colaboradores e R$ 800 milhões de carteira contratada. Ela executa obras industriais (plantas de beneficiamento, terminais, usinas de biocombustível) para clientes de mineração, óleo e gás e agro.

**As dores, na voz da diretoria**

- "Cada gerente de obra tem a sua planilha. Quando consolido, o número já mudou."
- "Descubro o estouro de custo na medição mensal, quando não dá mais para corrigir."
- "Tenho guindaste parado em Minas e obra atrasada por falta de guindaste no Pará."
- "O RDO é um PDF que ninguém lê. A causa do atraso está lá, mas só descubro na reunião."
- "Estoque de material é controlado no almoxarifado, não no cronograma. Compra chega atrasada ou sobra."

**Personas**

| Persona | O que precisa | Como usa a Torre |
| --- | --- | --- |
| Diretor de operações | Visão de portfólio: quais projetos vão estourar e quanto custa | Dashboard de portfólio + pergunta ao Genie no Teams |
| Gerente de projeto / obra | Status da sua obra, causas de desvio, materiais em risco | Dashboard da obra + agente que explica o RDO |
| PMO / planejamento | Comparar baseline x realizado, simular realocações | Data App: aprova realocação, registra decisão |
| Controller / financeiro | Margem por contrato, curva S de custo, provisão de estouro | Dashboard financeiro + KPIs governados |
| Suprimentos / almoxarifado | Cobertura de estoque x cronograma, pedidos em atraso | Alerta de ruptura + lista de compra sugerida |
| Engenheiro de dados (o aluno) | Construir e operar tudo isso | Lakeflow, Unity Catalog, Agent Bricks, Apps |

Os dados da Atlas são sintéticos, gerados pelo time da Jornada com padrões realistas (sazonalidade de chuva, atraso de fornecedor, rotatividade de equipe), para que os KPIs mostrem desvios de verdade.

## Perguntas de negócio e KPIs governados

A Torre responde três perguntas em português, em tempo real. Cada uma se apoia em KPIs definidos uma única vez como Metrics governadas no Unity Catalog e reutilizadas em dashboards, Genie, app e agentes.

**1. Quais projetos vão estourar prazo ou orçamento nos próximos 30 dias?**

**2. Onde tenho gente e equipamento parado enquanto outra obra está atrasada?**

**3. Que material vai faltar antes de travar uma frente de serviço?**

| KPI | Fórmula | Pergunta | Grão |
| --- | --- | --- | --- |
| SPI (Schedule Performance Index) | Valor agregado ÷ valor planejado | 1 | Projeto, semana |
| CPI (Cost Performance Index) | Valor agregado ÷ custo real | 1 | Projeto, semana |
| Desvio de prazo projetado (dias) | (Duração baseline ÷ SPI) − duração baseline | 1 | Projeto |
| EAC (Estimate at Completion) | Orçamento ÷ CPI | 1 | Projeto |
| Probabilidade de estouro (30 dias) | Modelo de classificação (ML) | 1 | Projeto |
| Margem projetada do contrato | (Receita contratada − EAC) ÷ receita contratada | 1 | Projeto |
| Utilização de equipe | Horas apontadas ÷ horas disponíveis | 2 | Equipe, semana |
| Utilização de equipamento | Horas operadas ÷ horas disponíveis | 2 | Equipamento, semana |
| Horas ociosas em obra com SPI < 0,9 | Soma das horas disponíveis não apontadas | 2 | Projeto |
| Cobertura de estoque (dias) | Saldo em estoque ÷ consumo diário previsto pelo cronograma | 3 | Material, projeto |
| Rupturas previstas | Materiais com cobertura < lead time do fornecedor | 3 | Material, projeto |
| Pedidos de compra em atraso | Pedidos com data prometida < hoje e não entregues | 3 | Projeto |

Regras de corte usadas em alertas e no agente: SPI ou CPI abaixo de 0,9 = atenção; abaixo de 0,8 = crítico; cobertura de estoque menor que o lead time = ruptura prevista.

## Escopo: funcionalidades por camada

Oito camadas, cada uma com um entregável verificável. As camadas 1 a 5 são obrigatórias (o produto funciona sem as demais); 6 a 8 são o diferencial da imersão.

| # | Camada | Funcionalidade Databricks | O que construímos | Entregável |
| --- | --- | --- | --- | --- |
| 1 | Ingestão | Lakeflow Connect, Auto Loader, Volumes | ERP simulado em Postgres (CDC), cronogramas em CSV, RDOs em PDF num Volume | Tabelas bronze: projetos, tarefas, apontamentos, estoque, compras, rdo\_raw |
| 2 | Transformação | Lakeflow Declarative Pipelines (SQL), ai\_extract, ai\_classify | Medalhão bronze → prata → ouro; RDO em texto vira colunas (causa do atraso, clima, incidente) | Pipeline declarativo com expectations de qualidade; tabela ouro fato\_projeto\_semana |
| 3 | Métricas | Metrics (Unity Catalog metric views) | SPI, CPI, EAC, utilização, cobertura definidos uma vez | 12 KPIs governados, consultáveis por SQL e Genie |
| 4 | Dashboards | AI/BI Dashboards | Portfólio (todas as obras), Obra (drill-down), Financeiro, Estoque | 4 dashboards publicados na interface Genie (ex-Databricks One) |
| 5 | Conversa com dados | Genie Agent (ex-Genie Spaces), app do Genie no Teams/Slack | Agente que responde as 3 perguntas e explica "por quê" em Agent Mode | Genie Agent com instruções, exemplos SQL e benchmark de 20 perguntas |
| 6 | Data App | Databricks Apps, AppKit ou Python (Streamlit/Dash), Lakebase | Torre de Controle: lista de obras em risco, simulador de realocação, aprovação com registro em Lakebase | App publicado com login SSO; tabela de decisões no Lakebase |
| 7 | Agentes | Agent Bricks: Knowledge Assistant, Supervisor Agent, funções Unity Catalog, MLflow 3 | KA sobre contratos e normas; função UC que simula realocação; Supervisor orquestra Genie + KA + função | Endpoint do Supervisor com avaliação MLflow (10 cenários) |
| 8 | ML | Notebooks, Model Serving, MLflow | Modelo de probabilidade de estouro em 30 dias, servido como tool do Supervisor | Endpoint de serving com AUC ≥ 0,75 no dado sintético |

Para o público de gestão (não-dev), as camadas 2, 4 e 6 têm uma trilha no-code em paralelo: Lakeflow Designer, Genie Code para gerar SQL e Genie App Builder para o app.

## Fora de escopo e premissas

**Fora de escopo nesta edição**

- Integração com ERPs reais (SAP, TOTVS): o ERP é simulado em Postgres.
- Cronograma com rede de precedência completa (CPM): usamos baseline x realizado por tarefa, sem recalcular caminho crítico.
- Controle de qualidade e segurança do trabalho (NCs, acidentes): aparecem apenas como campos extraídos do RDO.
- Mobile nativo para apontamento em campo: o app roda no navegador.
- Multi-tenant ou multi-empresa: uma única empresa, um único workspace.
- Deploy em produção com CI/CD e Asset Bundles: mencionado no dia 4, não executado.

**Premissas**

- Cada aluno tem uma conta Databricks Free Edition criada antes do dia 1, que já inclui Lakebase, Agent Bricks, Lakeflow Designer e Genie Code.
- Os dados sintéticos e os PDFs de RDO são fornecidos pela Jornada num repositório público; o aluno não precisa gerar dados.
- As funcionalidades em Preview (Lakeflow Designer, telemetria de Apps, Genie no Teams) são demonstradas pelo instrutor; o aluno constrói só com o que está GA ou Public Preview no Free Edition.
- Modelos de linguagem usados por ai\_extract, Genie e Agent Bricks são os servidos pelo próprio Databricks; nenhuma chave externa é necessária.
- Limites do Free Edition (compute serverless, cotas) são suficientes para o volume de dados proposto (até 2 milhões de linhas por tabela).

## Modelo de dados sintético

Nove tabelas de origem, uma por sistema simulado, mais dois produtos de dados na camada ouro. Volumes dimensionados para 40 projetos ao longo de 24 meses.

| Tabela (bronze) | Origem simulada | Colunas principais | Linhas |
| --- | --- | --- | --- |
| projetos | ERP | projeto\_id, cliente, setor (mineração/O&G/agro), uf, valor\_contrato, data\_inicio, data\_fim\_baseline, status | 40 |
| tarefas | Cronograma (CSV/MS Project) | tarefa\_id, projeto\_id, disciplina, inicio\_baseline, fim\_baseline, inicio\_real, fim\_real, pct\_concluido, valor\_planejado | 8.000 |
| apontamentos | Sistema de ponto | apontamento\_id, projeto\_id, equipe\_id, data, horas\_apontadas, horas\_disponiveis | 600.000 |
| equipes | RH | equipe\_id, funcao, uf\_base, custo\_hora, headcount | 120 |
| equipamentos | Frota | equipamento\_id, tipo, projeto\_id\_atual, horas\_operadas\_dia, horas\_disponiveis\_dia, custo\_hora | 300 |
| custos | ERP financeiro | lancamento\_id, projeto\_id, data, categoria, valor\_real, centro\_custo | 400.000 |
| estoque | Almoxarifado | projeto\_id, material\_id, data, saldo, consumo\_dia | 1.500.000 |
| compras | ERP compras | pedido\_id, projeto\_id, material\_id, fornecedor, qtd, data\_pedido, data\_prometida, data\_entrega, lead\_time\_dias | 20.000 |
| rdo\_raw | PDFs no Volume | rdo\_id, projeto\_id, data, texto\_livre, caminho\_pdf | 25.000 |

**Camada ouro (produtos de dados)**

| Tabela | Grão | Conteúdo |
| --- | --- | --- |
| fato\_projeto\_semana | projeto × semana | PV, EV, AC, SPI, CPI, EAC, horas disponíveis, horas apontadas, rupturas previstas, prob\_estouro\_30d |
| rdo\_estruturado | rdo | causa\_atraso (classificada), clima, incidente, frente\_afetada, dias\_impacto — gerado por ai\_extract/ai\_classify a partir de rdo\_raw |

**Padrões embutidos nos dados** (para que os KPIs mostrem desvios reais): 8 projetos com CPI caindo a partir do mês 9; chuva no Pará entre dezembro e março atrasando 3 obras; um fornecedor de estrutura metálica com lead time 40% acima do prometido; dois guindastes ociosos em Minas enquanto obra no Pará aponta falta de guindaste no RDO.

## Arquitetura no Databricks

&#91;embedded content: arquitetura · 4 camadas, fontes ao consumo\]

Os dados entram pela esquerda, são governados no centro e consumidos pela direita; o fluxo é um só, e os KPIs são definidos uma única vez nas Metrics. O App grava decisões no Lakebase (Postgres) e o Supervisor Agent usa Genie, Knowledge Assistant, uma função Unity Catalog e o endpoint de ML como ferramentas.

## Roteiro dos 4 dias

Cada dia termina com algo rodando na conta do aluno. O dia 4 fecha com o pitch para a diretoria, que é o segundo entregável da imersão.

| Dia | Tema | O que o aluno constrói | Entregável do dia | Trilha no-code |
| --- | --- | --- | --- | --- |
| 1 | Fundação de dados | Workspace, Unity Catalog, ingestão das 9 fontes com Lakeflow Connect e Auto Loader, pipeline bronze → prata → ouro em SQL, ai\_extract nos RDOs | fato\_projeto\_semana e rdo\_estruturado populados e com expectations passando | Lakeflow Designer monta o mesmo pipeline visualmente |
| 2 | KPIs e dashboards | 12 Metrics governadas; dashboards de Portfólio, Obra, Financeiro e Estoque; Genie Agent com instruções e 20 perguntas de benchmark | Dashboards publicados; Genie responde as 3 perguntas com SQL correto | Genie Code gera e explica o SQL dos KPIs |
| 3 | App e agentes | Lakebase provisionado; app Torre de Controle (lista de risco, simulador, aprovação); Knowledge Assistant sobre contratos; função UC de realocação; Supervisor Agent | App com login SSO gravando decisões; Supervisor responde "por que a obra X atrasou e o que fazer" | Genie App Builder gera o app a partir de uma descrição |
| 4 | ML, operação e pitch | Modelo de estouro em 30 dias servido como tool; monitoramento com MLflow; Jobs agendados; pitch de 3 minutos com ROI estimado | Projeto no GitHub + vídeo de 3 minutos para a diretoria | Mesmo pitch, foco em requisitos e ROI |

**Estrutura de cada dia** (4 horas): 40 min de contexto de negócio e demo do instrutor; 2h30 de construção guiada em blocos de 30 min com checkpoint; 50 min de dúvidas, revisão em dupla e publicação do entregável.

## Critérios de aceite por entregável

Um entregável está pronto quando todos os seus critérios passam na conta do aluno, sem ajuda do instrutor.

| Entregável | Critérios de aceite |
| --- | --- |
| Pipeline (dia 1) | As 9 tabelas bronze existem no catálogo com a contagem esperada (±1%); o pipeline roda do zero em menos de 15 min; expectations de qualidade (chaves não nulas, datas válidas, pct\_concluido entre 0 e 100) passam; rdo\_estruturado tem causa\_atraso preenchida em ≥ 90% dos RDOs |
| Metrics e dashboards (dia 2) | As 12 Metrics retornam o mesmo valor por SQL, dashboard e Genie; o dashboard de Portfólio mostra os 8 projetos com CPI caindo; drill-down de obra abre em menos de 3 s |
| Genie Agent (dia 2) | Acerta ≥ 16 das 20 perguntas do benchmark (SQL gerado dá o mesmo resultado que a resposta de referência); responde "por que a obra X atrasou?" citando a causa extraída do RDO |
| App Torre de Controle (dia 3) | Abre com login SSO do workspace; lista obras com SPI ou CPI < 0,9; simulador mostra impacto de mover uma equipe; aprovação grava linha na tabela decisoes do Lakebase com usuário e timestamp |
| Knowledge Assistant (dia 3) | Responde 5 perguntas sobre os contratos de teste citando o trecho e o arquivo |
| Supervisor Agent (dia 3) | Nos 10 cenários de avaliação MLflow, escolhe a ferramenta certa em ≥ 8 e a resposta final é marcada como correta por um juiz LLM em ≥ 7 |
| Modelo de estouro (dia 4) | AUC ≥ 0,75 no holdout do dado sintético; endpoint responde em menos de 1 s; registrado no Unity Catalog com versão |
| Pitch (dia 4) | 3 minutos, cobre problema, solução, demonstração ao vivo de uma pergunta e ROI estimado em reais; publicado em vídeo |

## Riscos e dependências

| Risco | Impacto | Mitigação |
| --- | --- | --- |
| Funcionalidade sai de Preview ou muda de nome antes da imersão (Genie, Lakeflow Designer, Apps) | Material desatualizado no dia | Revisar release notes 7 dias antes; roteiro usa só o que está GA no Free Edition para o aluno construir |
| Cota do Free Edition insuficiente para 1,5 milhão de linhas de estoque | Pipeline lento ou falha | Oferecer versão reduzida (10%) do dataset; medir tempo de execução no ensaio |
| Qualidade do ai\_extract nos RDOs sintéticos abaixo de 90% | KPI de causa de atraso não confiável | Gerar RDOs com template fixo e vocabulário controlado; prompt com exemplos |
| Aluno não-dev trava na camada 3 (app) | Abandono no dia 3 | Trilha no-code com Genie App Builder e app pronto no repositório para quem quiser só configurar |
| Supervisor Agent escolhe a ferramenta errada | Demo falha ao vivo | Benchmark de 10 cenários ensaiado; instruções do agente com exemplos de roteamento |
| Dataset sintético sem desvios visíveis | Dashboards "verdes", sem história | Padrões embutidos (seção Modelo de dados) validados antes da gravação |

**Dependências**

- Repositório público com dados sintéticos, PDFs de RDO, contratos de teste e código de referência, pronto 2 semanas antes do dia 1.
- Contas Free Edition criadas pelos alunos antes do dia 1 (e-mail de onboarding com passo a passo).
- Ensaio completo dos 4 dias por um instrutor numa conta Free Edition limpa.

## Próximos passos

- [ ] Validar nome e perfil da empresa fictícia (Atlas Engenharia) e as 3 perguntas de negócio
- [ ] Definir datas da imersão e abrir inscrições
- [ ] Gerar o dataset sintético e os PDFs de RDO com os padrões embutidos
- [ ] Construir a solução de referência completa numa conta Free Edition e medir tempos
- [ ] Escrever o benchmark de 20 perguntas do Genie e os 10 cenários do Supervisor
- [ ] Preparar a trilha no-code (Designer, Genie Code, App Builder) e o app pronto no repositório
- [ ] Definir responsável por cada dia e pelo material de pré-imersão

Em aberto: nome definitivo da imersão, carga horária por dia (4 h proposta) e se o pitch do dia 4 será avaliado com premiação.
