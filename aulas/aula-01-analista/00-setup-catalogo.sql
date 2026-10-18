-- Noite 1 · Setup do ambiente
-- Cria a casa onde o dado vai morar: um catálogo, três schemas e um volume.
--
-- Rode no SQL Editor (selecione tudo e Ctrl+Enter) ou pelo terminal:
--   python3 scripts/run_sql.py aulas/aula-01-analista/00-setup-catalogo.sql --profile SEU-PERFIL

-- O catálogo é o topo da hierarquia no Unity Catalog: catálogo > schema > tabela.
CREATE CATALOG IF NOT EXISTS lakehouse_atlas
  COMMENT 'Imersão Jornada de Dados · Torre de Controle da Construtora Atlas Engenharia';

-- Os três schemas são as três camadas do medalhão. Criamos os três agora,
-- mesmo que hoje só a bronze receba dado: o desenho vem antes do código.
CREATE SCHEMA IF NOT EXISTS lakehouse_atlas.bronze
  COMMENT 'Ingestão crua. O dado como veio de cada sistema da obra, sujeira inclusa.';
CREATE SCHEMA IF NOT EXISTS lakehouse_atlas.silver
  COMMENT 'Limpo, deduplicado e tipado. Preenchido na noite 2.';
CREATE SCHEMA IF NOT EXISTS lakehouse_atlas.gold
  COMMENT 'KPIs de obra (SPI, CPI, EAC, cobertura de estoque), prontos para consumo. Noite 2.';

-- O volume guarda ARQUIVO, não tabela: os CSVs dos sistemas e os PDFs (RDOs e contratos).
CREATE VOLUME IF NOT EXISTS lakehouse_atlas.bronze.raw
  COMMENT 'Arquivos originais: ERP, cronograma, ponto, frota, almoxarifado, RDO e contratos em PDF.';
