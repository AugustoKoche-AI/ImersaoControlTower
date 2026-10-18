-- Noite 1 · Ingestão bronze
--
-- A bronze preserva o dado como veio. Nada de limpeza aqui: se der problema
-- depois, a gente precisa poder voltar na origem e comparar.
--
-- Duas opções que valem explicar:
--   inferColumnTypes => false  ->  TUDO entra como texto. Se o Databricks
--                                  adivinhasse o tipo, ele erraria as datas que
--                                  vêm em dois formatos e o valor com vírgula
--                                  decimal. A sujeira sumiria antes de a gente ver.
--   EXCEPT (_rescued_data)     ->  descarta a coluna extra que o read_files cria
--                                  sozinho, para a bronze ter só o que veio do CSV.
--
-- As duas colunas técnicas no fim (_ingerido_em, _arquivo_origem) respondem
-- "quando isso entrou?" e "de qual arquivo veio?" — as primeiras perguntas de
-- qualquer investigação.
--
-- Antes de rodar, os arquivos precisam estar no volume (veja o README):
--   /Volumes/lakehouse_atlas/bronze/raw/<sistema>/<arquivo>.csv
--
-- Rode com:
--   python3 scripts/run_sql.py aulas/aula-01-analista/01-ingestao-bronze.sql --profile SEU-PERFIL

-- ---------- erp ----------
-- projetos: o contrato de cada obra: cliente, setor, UF, valor, prazo
CREATE OR REPLACE TABLE lakehouse_atlas.bronze.projetos AS
SELECT * EXCEPT (_rescued_data), current_timestamp() AS _ingerido_em, _metadata.file_path AS _arquivo_origem
FROM read_files('/Volumes/lakehouse_atlas/bronze/raw/erp/projetos.csv',
                format => 'csv', header => true, multiLine => true,
                inferColumnTypes => false);
-- custos: cada lançamento de custo real (mão de obra, material, equipamento...)
CREATE OR REPLACE TABLE lakehouse_atlas.bronze.custos AS
SELECT * EXCEPT (_rescued_data), current_timestamp() AS _ingerido_em, _metadata.file_path AS _arquivo_origem
FROM read_files('/Volumes/lakehouse_atlas/bronze/raw/erp/custos.csv',
                format => 'csv', header => true, multiLine => true,
                inferColumnTypes => false);
-- compras: pedidos de compra: prometido x entregue
CREATE OR REPLACE TABLE lakehouse_atlas.bronze.compras AS
SELECT * EXCEPT (_rescued_data), current_timestamp() AS _ingerido_em, _metadata.file_path AS _arquivo_origem
FROM read_files('/Volumes/lakehouse_atlas/bronze/raw/erp/compras.csv',
                format => 'csv', header => true, multiLine => true,
                inferColumnTypes => false);
-- materiais: cadastro de material e lead time contratado
CREATE OR REPLACE TABLE lakehouse_atlas.bronze.materiais AS
SELECT * EXCEPT (_rescued_data), current_timestamp() AS _ingerido_em, _metadata.file_path AS _arquivo_origem
FROM read_files('/Volumes/lakehouse_atlas/bronze/raw/erp/materiais.csv',
                format => 'csv', header => true, multiLine => true,
                inferColumnTypes => false);

-- ---------- cronograma ----------
-- tarefas: as 8.000 tarefas do cronograma, com baseline e realizado
CREATE OR REPLACE TABLE lakehouse_atlas.bronze.tarefas AS
SELECT * EXCEPT (_rescued_data), current_timestamp() AS _ingerido_em, _metadata.file_path AS _arquivo_origem
FROM read_files('/Volumes/lakehouse_atlas/bronze/raw/cronograma/tarefas.csv',
                format => 'csv', header => true, multiLine => true,
                inferColumnTypes => false);
-- avanco_semanal: o boletim de medição: % concluído de cada tarefa por semana
CREATE OR REPLACE TABLE lakehouse_atlas.bronze.avanco_semanal AS
SELECT * EXCEPT (_rescued_data), current_timestamp() AS _ingerido_em, _metadata.file_path AS _arquivo_origem
FROM read_files('/Volumes/lakehouse_atlas/bronze/raw/cronograma/avanco_semanal.csv',
                format => 'csv', header => true, multiLine => true,
                inferColumnTypes => false);

-- ---------- rh ----------
-- equipes: as equipes de campo e onde estão alocadas
CREATE OR REPLACE TABLE lakehouse_atlas.bronze.equipes AS
SELECT * EXCEPT (_rescued_data), current_timestamp() AS _ingerido_em, _metadata.file_path AS _arquivo_origem
FROM read_files('/Volumes/lakehouse_atlas/bronze/raw/rh/equipes.csv',
                format => 'csv', header => true, multiLine => true,
                inferColumnTypes => false);

-- ---------- ponto ----------
-- apontamentos: horas disponíveis x horas apontadas, por equipe e dia
CREATE OR REPLACE TABLE lakehouse_atlas.bronze.apontamentos AS
SELECT * EXCEPT (_rescued_data), current_timestamp() AS _ingerido_em, _metadata.file_path AS _arquivo_origem
FROM read_files('/Volumes/lakehouse_atlas/bronze/raw/ponto/apontamentos.csv',
                format => 'csv', header => true, multiLine => true,
                inferColumnTypes => false);

-- ---------- frota ----------
-- equipamentos: guindastes, escavadeiras, munck... e em que obra estão
CREATE OR REPLACE TABLE lakehouse_atlas.bronze.equipamentos AS
SELECT * EXCEPT (_rescued_data), current_timestamp() AS _ingerido_em, _metadata.file_path AS _arquivo_origem
FROM read_files('/Volumes/lakehouse_atlas/bronze/raw/frota/equipamentos.csv',
                format => 'csv', header => true, multiLine => true,
                inferColumnTypes => false);
-- uso_equipamentos: horas operadas por equipamento e semana
CREATE OR REPLACE TABLE lakehouse_atlas.bronze.uso_equipamentos AS
SELECT * EXCEPT (_rescued_data), current_timestamp() AS _ingerido_em, _metadata.file_path AS _arquivo_origem
FROM read_files('/Volumes/lakehouse_atlas/bronze/raw/frota/uso_equipamentos.csv',
                format => 'csv', header => true, multiLine => true,
                inferColumnTypes => false);

-- ---------- almoxarifado ----------
-- estoque: saldo semanal de cada material em cada obra
CREATE OR REPLACE TABLE lakehouse_atlas.bronze.estoque AS
SELECT * EXCEPT (_rescued_data), current_timestamp() AS _ingerido_em, _metadata.file_path AS _arquivo_origem
FROM read_files('/Volumes/lakehouse_atlas/bronze/raw/almoxarifado/estoque.csv',
                format => 'csv', header => true, multiLine => true,
                inferColumnTypes => false);

-- ---------- rdo ----------
-- rdo: o relatório diário de obra, em texto livre
CREATE OR REPLACE TABLE lakehouse_atlas.bronze.rdo AS
SELECT * EXCEPT (_rescued_data), current_timestamp() AS _ingerido_em, _metadata.file_path AS _arquivo_origem
FROM read_files('/Volumes/lakehouse_atlas/bronze/raw/rdo/rdo.csv',
                format => 'csv', header => true, multiLine => true,
                inferColumnTypes => false);

-- ---------- conferência ----------
-- 12 tabelas. Se alguma vier com 0 linhas, o arquivo não subiu para o volume.
SELECT 'projetos' AS tabela, COUNT(*) AS linhas FROM lakehouse_atlas.bronze.projetos
UNION ALL SELECT 'custos', COUNT(*) FROM lakehouse_atlas.bronze.custos
UNION ALL SELECT 'compras', COUNT(*) FROM lakehouse_atlas.bronze.compras
UNION ALL SELECT 'materiais', COUNT(*) FROM lakehouse_atlas.bronze.materiais
UNION ALL SELECT 'tarefas', COUNT(*) FROM lakehouse_atlas.bronze.tarefas
UNION ALL SELECT 'avanco_semanal', COUNT(*) FROM lakehouse_atlas.bronze.avanco_semanal
UNION ALL SELECT 'equipes', COUNT(*) FROM lakehouse_atlas.bronze.equipes
UNION ALL SELECT 'apontamentos', COUNT(*) FROM lakehouse_atlas.bronze.apontamentos
UNION ALL SELECT 'equipamentos', COUNT(*) FROM lakehouse_atlas.bronze.equipamentos
UNION ALL SELECT 'uso_equipamentos', COUNT(*) FROM lakehouse_atlas.bronze.uso_equipamentos
UNION ALL SELECT 'estoque', COUNT(*) FROM lakehouse_atlas.bronze.estoque
UNION ALL SELECT 'rdo', COUNT(*) FROM lakehouse_atlas.bronze.rdo
ORDER BY linhas DESC;
