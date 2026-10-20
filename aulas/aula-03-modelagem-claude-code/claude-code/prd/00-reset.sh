#!/usr/bin/env bash
# Noite 2 · Reset: apaga tudo que a noite 2 constrói, para provar que os seis prompts bastam.
#
#   bash aulas/aula-03-modelagem-claude-code/claude-code/prd/00-reset.sh <perfil>            # SIMULA: só lista o que sairia
#   bash aulas/aula-03-modelagem-claude-code/claude-code/prd/00-reset.sh <perfil> --apagar   # apaga de verdade
#
# O que sai:   job vertice_farol, pipeline vertice_medalhao, dashboard e Genie da noite 2,
#              e TUDO o que estiver nos schemas silver e gold (varrido pelo information_schema):
#                silver  projetos, tarefas, status_semanal, custos, colaboradores,
#                        apontamentos, entregas_fornecedor            (materialized views)
#                gold    fato_projeto_semana, projeto_situacao_atual,
#                        utilizacao_pessoa_semana                     (materialized views)
#                        status_estruturado                           (tabela da IA)
#                        mv_projetos                                  (metric view)
#              Versão antiga (podem ainda existir em workspaces antigos e saem na mesma varredura):
#                silver  alocacoes, contratos_capacidade, consumo_capacidade, postmortems
#                gold    dim_projeto, desempenho_fornecedor, cobertura_capacidade,
#                        entregas_em_atraso, postmortem_estruturado,
#                        mv_evolucao, mv_pessoas, mv_capacidade, mv_fornecedores
#              Atenção: a varredura também leva o que as noites 3 e 4 gravaram na gold
#              (gold.score_estouro_30d e as tabelas de contratos). O schema ml não é tocado.
# O que FICA:  o catálogo lakehouse_vertice, a BRONZE e o volume com os arquivos
#              (são da noite 1). Este script nunca toca na bronze.
#
# Por padrão o destroy usa o bundle de referência (aulas/aula-03-modelagem-claude-code/claude-code/vertice).
# Se você construiu o seu em outra pasta, passe-a: BUNDLE_DIR=caminho bash 00-reset.sh <perfil> --apagar
set -euo pipefail

PERFIL="${1:?uso: 00-reset.sh <perfil> [--apagar]}"
APAGAR="${2:-}"
RAIZ="$(cd "$(dirname "$0")/../../../.." && pwd)"
BUNDLE_DIR="${BUNDLE_DIR:-$RAIZ/aulas/aula-03-modelagem-claude-code/claude-code/vertice}"
CAT=lakehouse_vertice

sql() { python3 "$RAIZ/scripts/run_sql.py" /dev/stdin --profile "$PERFIL" --quiet --continuar; }

echo "== o que existe hoje em silver e gold"
python3 "$RAIZ/scripts/run_sql.py" /dev/stdin --profile "$PERFIL" <<SQL
SELECT table_schema, table_name, table_type
FROM $CAT.information_schema.tables
WHERE table_schema IN ('silver', 'gold') AND table_name NOT LIKE '\_\_%'
ORDER BY 1, 2
SQL

if [[ "$APAGAR" != "--apagar" ]]; then
  echo
  echo "SIMULAÇÃO. Nada foi apagado. Para apagar de verdade: $0 $PERFIL --apagar"
  echo "Recursos do bundle que sairiam:"
  (cd "$BUNDLE_DIR" && databricks bundle summary --profile "$PERFIL" 2>/dev/null | sed -n '/Resources:/,$p') || true
  exit 0
fi

echo "== 1/2 destroy do bundle (job, pipeline e suas tabelas, dashboard, Genie)"
(cd "$BUNDLE_DIR" && databricks bundle destroy --auto-approve --profile "$PERFIL") || echo "   (nada para destruir)"

echo "== 2/2 o que sobra: metric views, as tabelas de IA e as tabelas do pipeline"
# Medido no Free Edition: apagar o pipeline NÃO apaga as materialized views
# que ele criou. Elas ficam órfãs na silver e na gold — então saem aqui, uma a uma.
# Só silver e gold: a bronze nunca entra nesta lista.
python3 - "$PERFIL" "$CAT" "$RAIZ" <<'PY'
import json, subprocess, sys
perfil, cat, raiz = sys.argv[1:4]
sys.path.insert(0, f"{raiz}/scripts")
import run_sql
wh = run_sql.warehouse_padrao(perfil)
r = run_sql.executar(f"""SELECT table_schema, table_name, table_type FROM {cat}.information_schema.tables
                         WHERE table_schema IN ('silver', 'gold') AND table_name NOT LIKE '\\_\\_%'""", wh, perfil)
for schema, nome, tipo in r.get("result", {}).get("data_array") or []:
    assert schema in ("silver", "gold")
    comando = {"MATERIALIZED_VIEW": "MATERIALIZED VIEW", "STREAMING_TABLE": "TABLE",
               "VIEW": "VIEW", "METRIC_VIEW": "VIEW"}.get(tipo, "TABLE")
    s = run_sql.executar(f"DROP {comando} IF EXISTS {cat}.{schema}.{nome}", wh, perfil)["status"]["state"]
    print(f"   {s:<9} DROP {comando} {schema}.{nome}")
PY

echo "== pronto. Sobrou em silver e gold:"
python3 "$RAIZ/scripts/run_sql.py" /dev/stdin --profile "$PERFIL" <<SQL
SELECT COUNT(*) AS tabelas_restantes
FROM $CAT.information_schema.tables
WHERE table_schema IN ('silver', 'gold') AND table_name NOT LIKE '\_\_%'
SQL
