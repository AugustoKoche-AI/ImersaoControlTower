-- Métricas governadas: os 12 KPIs da Torre, definidos UMA vez.
--
-- Uma metric view guarda a FÓRMULA, não o número. Dashboard, Genie e app pedem
-- MEASURE(spi) e recebem sempre o mesmo cálculo — ninguém mais reescreve SPI
-- num CASE WHEN escondido dentro de um widget.
--
--   gold.mv_obras            SPI, CPI, EAC, estouro previsto, margem projetada, atraso projetado
--   gold.mv_evolucao         SPI e CPI semana a semana, utilização de equipe, horas ociosas
--   gold.mv_equipamentos     utilização de equipamento, horas e custo parados
--   gold.mv_suprimentos      cobertura de estoque, rupturas previstas
--   gold.mv_fornecedores     pedidos em atraso, lead time real x prometido
--
-- ATENÇÃO (medido no Free Edition): o YAML precisa da indentação intacta.
-- Rode este arquivo como sql_task do job ou pela API de statements
-- (scripts/run_sql.py). O `aitools tools query` achata os espaços e o
-- Databricks responde METRIC_VIEW_INVALID_VIEW_DEFINITION.

CREATE OR REPLACE VIEW lakehouse_atlas.gold.mv_obras
WITH METRICS
LANGUAGE YAML
COMMENT 'KPIs de obra em andamento na fotografia de hoje (16/10/2026). Regras de corte: SPI ou CPI < 0,9 atenção; < 0,8 crítico.'
AS $$
version: 1.1
source: lakehouse_atlas.gold.obra_situacao_atual
filter: status = 'em_andamento'
dimensions:
  - name: projeto_id
    expr: projeto_id
    comment: Código da obra, como P011
  - name: obra
    expr: obra
    comment: Código e nome da obra
    synonyms: [projeto, empreendimento]
  - name: cliente
    expr: cliente
  - name: setor
    expr: setor
    comment: mineracao, oleo_gas ou agro
  - name: uf
    expr: uf
    synonyms: [estado]
  - name: situacao
    expr: situacao
    comment: ok, atenção ou crítico, pela regra de corte de SPI e CPI
  - name: gerente_projeto
    expr: gerente_projeto
    synonyms: [gerente]
measures:
  - name: obras
    expr: COUNT(1)
    comment: Quantidade de obras em andamento
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
    comment: Estimate at Completion = orçamento / CPI. Quanto a obra vai custar no fim se nada mudar.
    synonyms: [estimativa no término, custo projetado]
  - name: estouro_previsto
    expr: SUM(estouro_previsto)
    comment: EAC menos orçamento, só das obras que estouram (obra abaixo do orçamento não compensa a que estoura)
    synonyms: [estouro de custo, prejuízo previsto]
  - name: margem_projetada
    expr: (SUM(valor_contrato) - SUM(eac)) / SUM(valor_contrato)
    comment: (valor do contrato - EAC) / valor do contrato, em fração (0,15 = 15%)
  - name: atraso_projetado_medio_dias
    expr: AVG(atraso_projetado_dias)
    comment: Desvio de prazo projetado = duração baseline / SPI - duração baseline, média em dias
    synonyms: [desvio de prazo, atraso previsto]
  - name: obras_em_risco
    expr: COUNT(1) FILTER (WHERE situacao IN ('atenção', 'crítico'))
    comment: Obras com SPI ou CPI abaixo de 0,9
  - name: obras_criticas
    expr: COUNT(1) FILTER (WHERE situacao = 'crítico')
    comment: Obras com SPI ou CPI abaixo de 0,8
$$;

CREATE OR REPLACE VIEW lakehouse_atlas.gold.mv_evolucao
WITH METRICS
LANGUAGE YAML
COMMENT 'Evolução semanal das obras: SPI e CPI acumulados em cada semana, utilização da equipe e horas ociosas. Filtre uma semana para ver a fotografia daquela data.'
AS $$
version: 1.1
source: lakehouse_atlas.gold.fato_projeto_semana
joins:
  - name: dim_obra
    source: lakehouse_atlas.gold.dim_projeto
    using: [projeto_id]
dimensions:
  - name: semana
    expr: semana
    comment: Sexta-feira da semana
  - name: mes
    expr: DATE_TRUNC('MONTH', semana)
  - name: projeto_id
    expr: projeto_id
  - name: obra
    expr: dim_obra.obra
  - name: uf
    expr: dim_obra.uf
  - name: setor
    expr: dim_obra.setor
measures:
  - name: spi
    expr: SUM(ev) / SUM(pv)
    comment: SPI acumulado até a semana (use com uma semana filtrada ou agrupando por semana)
  - name: cpi
    expr: SUM(ev) / SUM(ac)
    comment: CPI acumulado até a semana
  - name: utilizacao_equipe
    expr: SUM(horas_apontadas) / SUM(horas_disponiveis)
    comment: Horas apontadas / horas disponíveis das equipes de campo
    synonyms: [produtividade da equipe, ocupação]
  - name: horas_ociosas
    expr: SUM(horas_ociosas)
    comment: Horas disponíveis não apontadas (gente parada)
    synonyms: [ociosidade, horas paradas]
  - name: rupturas_previstas
    expr: SUM(rupturas_previstas)
    comment: Materiais que acabam antes da próxima entrega prometida, somados por semana
$$;

CREATE OR REPLACE VIEW lakehouse_atlas.gold.mv_equipamentos
WITH METRICS
LANGUAGE YAML
COMMENT 'Uso da frota por semana: utilização, horas e custo parados de guindastes, escavadeiras e demais equipamentos.'
AS $$
version: 1.1
source: lakehouse_atlas.gold.utilizacao_equipamento_semana
dimensions:
  - name: equipamento_id
    expr: equipamento_id
  - name: tipo
    expr: tipo
    comment: guindaste, escavadeira, caminhao_munck, retroescavadeira, plataforma_elevatoria, gerador, compressor, rolo_compactador
  - name: modelo
    expr: modelo
  - name: obra
    expr: obra
  - name: projeto_id
    expr: projeto_id
  - name: uf
    expr: uf
  - name: semana
    expr: semana
measures:
  - name: utilizacao_equipamento
    expr: SUM(horas_operadas) / SUM(horas_disponiveis)
    comment: Horas operadas / horas disponíveis
    synonyms: [uso do equipamento, ocupação da frota]
  - name: horas_paradas
    expr: SUM(horas_paradas)
  - name: custo_ocioso
    expr: SUM(custo_ocioso)
    comment: Horas paradas × custo por hora do equipamento, em reais
$$;

CREATE OR REPLACE VIEW lakehouse_atlas.gold.mv_suprimentos
WITH METRICS
LANGUAGE YAML
COMMENT 'Cobertura de estoque e rupturas previstas por material e obra, hoje (16/10/2026).'
AS $$
version: 1.1
source: lakehouse_atlas.gold.cobertura_estoque
dimensions:
  - name: obra
    expr: obra
  - name: projeto_id
    expr: projeto_id
  - name: uf
    expr: uf
  - name: material
    expr: material
  - name: disciplina
    expr: disciplina
  - name: fornecedor_proxima_entrega
    expr: fornecedor_proxima_entrega
measures:
  - name: rupturas_previstas
    expr: COUNT(1) FILTER (WHERE ruptura_prevista)
    comment: Materiais cujo estoque acaba antes da próxima entrega prometida chegar
    synonyms: [material que vai faltar, falta de material]
  - name: cobertura_media_dias
    expr: AVG(cobertura_dias)
    comment: Saldo / consumo diário previsto, em dias
  - name: itens_monitorados
    expr: COUNT(1)
$$;

CREATE OR REPLACE VIEW lakehouse_atlas.gold.mv_fornecedores
WITH METRICS
LANGUAGE YAML
COMMENT 'Pedidos de compra por fornecedor (normalizado): atraso de entrega e lead time real x prometido.'
AS $$
version: 1.1
source: lakehouse_atlas.silver.compras
joins:
  - name: dim_obra
    source: lakehouse_atlas.gold.dim_projeto
    using: [projeto_id]
dimensions:
  - name: fornecedor
    expr: fornecedor
  - name: obra
    expr: dim_obra.obra
  - name: material_id
    expr: material_id
measures:
  - name: pedidos
    expr: COUNT(1)
  - name: pedidos_em_atraso
    expr: COUNT(1) FILTER (WHERE em_atraso)
    comment: Pedidos em aberto com data prometida anterior a hoje
    synonyms: [compras atrasadas]
  - name: lead_time_real_medio_dias
    expr: AVG(lead_time_real_dias)
  - name: fator_atraso_fornecedor
    expr: AVG(lead_time_real_dias / lead_time_prometido_dias)
    comment: Lead time real / prometido. 1,4 = entrega 40% depois do prometido.
$$;

-- Os 12 KPIs, um de cada, para conferir que todas as metric views respondem
SELECT MEASURE(spi) AS spi, MEASURE(cpi) AS cpi, MEASURE(eac) AS eac, MEASURE(estouro_previsto) AS estouro_previsto,
       MEASURE(margem_projetada) AS margem_projetada, MEASURE(atraso_projetado_medio_dias) AS atraso_dias,
       MEASURE(obras_criticas) AS obras_criticas
FROM lakehouse_atlas.gold.mv_obras;
