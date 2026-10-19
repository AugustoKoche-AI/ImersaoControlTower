-- Métricas governadas: os KPIs da Torre, definidos UMA vez.
--
-- Uma metric view guarda a FÓRMULA, não o número. Dashboard, Genie e app pedem
-- MEASURE(spi) e recebem sempre o mesmo cálculo — ninguém mais reescreve SPI
-- num CASE WHEN escondido dentro de um widget.
--
--   gold.mv_projetos         SPI, CPI, EAC, estouro previsto, margem, atraso, melancias (fotografia de hoje)
--   gold.mv_evolucao         SPI e CPI semana a semana, utilização da equipe, horas ociosas
--   gold.mv_pessoas          utilização por pessoa e papel, horas e custo ociosos
--   gold.mv_capacidade       cobertura do banco de horas e dos créditos de cloud, rupturas previstas
--   gold.mv_fornecedores     entregas em atraso, prazo real x prometido
--
-- ATENÇÃO (medido no Free Edition): o YAML precisa da indentação intacta.
-- Rode este arquivo como sql_task do job ou pela API de statements
-- (scripts/run_sql.py). O `aitools tools query` achata os espaços e o
-- Databricks responde METRIC_VIEW_INVALID_VIEW_DEFINITION.

CREATE OR REPLACE VIEW lakehouse_vertice.gold.mv_projetos
WITH METRICS
LANGUAGE YAML
COMMENT 'KPIs dos projetos em andamento na fotografia de hoje (16/10/2026), sobre as tarefas das 3 ferramentas. Regras de corte: SPI ou CPI < 0,9 atenção; < 0,8 crítico.'
AS $$
version: 1.1
source: lakehouse_vertice.gold.projeto_situacao_atual
filter: status = 'em_andamento'
dimensions:
  - name: projeto_id
    expr: projeto_id
    comment: Código do projeto, como PRJ-011
  - name: projeto
    expr: projeto
    comment: Código e nome do projeto
    synonyms: [nome do projeto]
  - name: cliente
    expr: cliente
    synonyms: [conta]
  - name: segmento
    expr: segmento
    comment: varejo, financeiro, saude, logistica ou industria
  - name: ferramenta
    expr: ferramenta
    comment: Onde o projeto é gerenciado - excel, clickup ou msproject
  - name: situacao
    expr: situacao
    comment: ok, atenção ou crítico, pela regra de corte de SPI e CPI
  - name: farol_do_gerente
    expr: farol_do_gerente
    comment: Farol publicado pelo gerente no status desta sexta (verde, amarelo, vermelho)
  - name: farol_calculado
    expr: farol_calculado
    comment: Farol pela regra do manual - verde com SPI >= 0,95, amarelo >= 0,90, vermelho abaixo
  - name: gerente_projeto
    expr: gerente_projeto
    synonyms: [gerente, gestor do projeto]
measures:
  - name: projetos
    expr: COUNT(1)
    comment: Quantidade de projetos em andamento
  - name: carteira
    expr: SUM(valor_contrato)
    comment: Valor de contrato somado, em reais
    synonyms: [valor da carteira, receita contratada]
  - name: spi
    expr: SUM(ev) / SUM(pv)
    comment: Schedule Performance Index = valor agregado / valor planejado. Abaixo de 1 é atraso.
    synonyms: [índice de prazo, desempenho de prazo]
  - name: cpi
    expr: SUM(ev) / SUM(ac)
    comment: Cost Performance Index = valor agregado / custo real. Abaixo de 1 é estouro de custo.
    synonyms: [índice de custo, desempenho de custo]
  - name: eac
    expr: SUM(eac)
    comment: Estimate at Completion = orçamento / CPI. Quanto o projeto vai custar no fim se nada mudar.
    synonyms: [estimativa no término, custo projetado]
  - name: estouro_previsto
    expr: SUM(estouro_previsto)
    comment: EAC menos orçamento, só dos projetos que estouram (projeto abaixo do orçamento não compensa o que estoura)
    synonyms: [estouro de custo, prejuízo previsto, quanto o atraso custa]
  - name: margem_projetada
    expr: (SUM(valor_contrato) - SUM(eac)) / SUM(valor_contrato)
    comment: (valor do contrato - EAC) / valor do contrato, em fração (0,15 = 15%)
  - name: atraso_projetado_medio_dias
    expr: AVG(atraso_projetado_dias)
    comment: Atraso projetado = duração baseline / SPI - duração baseline, média em dias
    synonyms: [desvio de prazo, atraso previsto]
  - name: projetos_em_risco
    expr: COUNT(1) FILTER (WHERE situacao IN ('atenção', 'crítico'))
    comment: Projetos com SPI ou CPI abaixo de 0,9
  - name: projetos_criticos
    expr: COUNT(1) FILTER (WHERE situacao = 'crítico')
    comment: Projetos com SPI ou CPI abaixo de 0,8
  - name: projetos_melancia
    expr: COUNT(1) FILTER (WHERE melancia)
    comment: Projetos com farol verde do gerente e SPI abaixo de 0,9 (verde por fora, vermelho por dentro)
    synonyms: [farol mentiroso, farol errado]
$$;

CREATE OR REPLACE VIEW lakehouse_vertice.gold.mv_evolucao
WITH METRICS
LANGUAGE YAML
COMMENT 'Evolução semanal dos projetos: SPI e CPI acumulados em cada semana (avanço do status semanal), utilização da equipe e horas ociosas. Filtre uma semana para ver a fotografia daquela data.'
AS $$
version: 1.1
source: lakehouse_vertice.gold.fato_projeto_semana
joins:
  - name: dim_projeto
    source: lakehouse_vertice.gold.dim_projeto
    using: [projeto_id]
dimensions:
  - name: semana
    expr: semana
    comment: Sexta-feira da semana
  - name: mes
    expr: DATE_TRUNC('MONTH', semana)
  - name: projeto_id
    expr: projeto_id
  - name: projeto
    expr: dim_projeto.projeto
  - name: cliente
    expr: dim_projeto.cliente
  - name: segmento
    expr: dim_projeto.segmento
  - name: ferramenta
    expr: dim_projeto.ferramenta
measures:
  - name: spi
    expr: SUM(ev) / SUM(pv)
    comment: SPI acumulado até a semana (use com uma semana filtrada ou agrupando por semana)
  - name: cpi
    expr: SUM(ev) / SUM(ac)
    comment: CPI acumulado até a semana
  - name: utilizacao_equipe
    expr: SUM(horas_apontadas) / SUM(horas_disponiveis)
    comment: Horas apontadas / horas disponíveis da equipe do projeto na semana
  - name: horas_ociosas
    expr: SUM(horas_ociosas)
    comment: Horas disponíveis não apontadas
  - name: rupturas_capacidade
    expr: SUM(rupturas_capacidade)
    comment: Contratos de capacidade com saldo para menos de 30 dias na semana
$$;

CREATE OR REPLACE VIEW lakehouse_vertice.gold.mv_pessoas
WITH METRICS
LANGUAGE YAML
COMMENT 'Utilização das pessoas por projeto e semana (timesheet): horas disponíveis, apontadas e ociosas, e o custo da hora parada. Responde: tenho gente parada enquanto outro projeto pede gente?'
AS $$
version: 1.1
source: lakehouse_vertice.gold.utilizacao_pessoa_semana
dimensions:
  - name: semana
    expr: semana
  - name: colaborador_id
    expr: colaborador_id
  - name: nome
    expr: nome
    synonyms: [pessoa, colaborador]
  - name: papel
    expr: papel
    comment: dev_backend, dev_frontend, dev_mobile, qa, sre, tech_lead, product_owner, designer_ux, engenheiro_dados
    synonyms: [função, cargo]
  - name: senioridade
    expr: senioridade
  - name: projeto_id
    expr: projeto_id
  - name: projeto
    expr: projeto
measures:
  - name: utilizacao
    expr: SUM(horas_apontadas) / SUM(horas_disponiveis)
    comment: Horas apontadas / horas disponíveis. Abaixo de 0,2 é gente praticamente parada.
    synonyms: [ocupação, uso]
  - name: horas_ociosas
    expr: SUM(horas_ociosas)
    comment: Horas disponíveis não apontadas
    synonyms: [horas paradas]
  - name: custo_ocioso
    expr: SUM(custo_ocioso)
    comment: Horas ociosas x custo/hora da pessoa, em reais
  - name: pessoas
    expr: COUNT(DISTINCT colaborador_id)
$$;

CREATE OR REPLACE VIEW lakehouse_vertice.gold.mv_capacidade
WITH METRICS
LANGUAGE YAML
COMMENT 'Capacidade contratada dos projetos em andamento hoje (16/10/2026): banco de horas de consultoria e créditos de cloud, cobertura em dias e rupturas previstas (saldo para menos de 30 dias, o prazo de um aditivo).'
AS $$
version: 1.1
source: lakehouse_vertice.gold.cobertura_capacidade
dimensions:
  - name: projeto_id
    expr: projeto_id
  - name: projeto
    expr: projeto
  - name: fornecedor
    expr: fornecedor
  - name: tipo
    expr: tipo
    comment: banco_de_horas (consultoria, em horas) ou creditos_cloud (em reais)
  - name: ruptura_prevista
    expr: ruptura_prevista
measures:
  - name: contratos
    expr: COUNT(1)
  - name: rupturas_previstas
    expr: COUNT(1) FILTER (WHERE ruptura_prevista)
    comment: Contratos cujo saldo acaba em menos de 30 dias
    synonyms: [rupturas de capacidade, saldo acabando]
  - name: cobertura_media_dias
    expr: AVG(cobertura_dias)
    comment: Saldo / consumo previsto por dia, média em dias
$$;

CREATE OR REPLACE VIEW lakehouse_vertice.gold.mv_fornecedores
WITH METRICS
LANGUAGE YAML
COMMENT 'Entregas das consultorias (fornecedor normalizado): prazo real x prometido e entregas em atraso hoje.'
AS $$
version: 1.1
source: lakehouse_vertice.silver.entregas_fornecedor
dimensions:
  - name: fornecedor
    expr: fornecedor
    synonyms: [consultoria, parceiro]
  - name: projeto_id
    expr: projeto_id
  - name: mes_pedido
    expr: DATE_TRUNC('MONTH', data_pedido)
measures:
  - name: entregas
    expr: COUNT(1)
  - name: entregas_em_atraso
    expr: COUNT(1) FILTER (WHERE em_atraso)
    comment: Entregas em aberto com data prometida anterior a hoje
  - name: prazo_real_medio_dias
    expr: AVG(prazo_real_dias)
  - name: fator_atraso
    expr: AVG(prazo_real_dias / prazo_prometido_dias)
    comment: Prazo real / prazo prometido, média. 1,41 = entrega 41% depois do prometido.
$$;
