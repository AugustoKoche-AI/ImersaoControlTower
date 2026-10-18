#!/usr/bin/env bash
# Sobe a noite 4 inteira do zero, na ordem que funciona (é o gabarito dos 3 prompts):
#   1. Lakebase (projeto torre-atlas), se ainda não existe
#   2. contratos: PDF → texto → cláusulas → resumo → exposição (SQL)
#   3. Genie "Torre de Controle · Diretoria + Contratos" (e o id vai para o databricks.yml)
#   4. app: deploy → GRANT para o service principal → deploy (o 1º build falha sem GRANT)
#
# Uso:  bash scripts/subir-tudo.sh <perfil>
set -euo pipefail
PERFIL="${1:?informe o profile}"
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RAIZ="$(cd "$APP_DIR/../../.." && pwd)"
GENIE="Torre de Controle · Diretoria + Contratos"
t0=$(date +%s)
passo() { echo -e "\n[$(( $(date +%s) - t0 ))s] $*"; }

passo "1. Lakebase"
# list-projects (e não get-project): get-project também devolve projeto apagado ("soft delete")
if databricks postgres list-projects --profile "$PERFIL" -o json | grep -q '"projects/torre-atlas"'; then
  echo "projeto torre-atlas já existe"
else
  databricks postgres create-project torre-atlas --profile "$PERFIL" >/dev/null && echo "projeto torre-atlas criado"
fi

passo "2. Contratos (ai_parse_document + ai_query)"
python3 "$RAIZ/scripts/run_sql.py" "$APP_DIR/agente/01-contratos.sql" --profile "$PERFIL" --quiet | grep -E "FALHOU|statement" || true

passo "3. Genie da diretoria"
python3 "$APP_DIR/agente/gerar_genie.py" --profile "$PERFIL"
SAIDA=$(python3 "$RAIZ/scripts/genie.py" publicar "$APP_DIR/agente/diretoria-contratos-genie.json" \
          --titulo "$GENIE" --descricao "Genie da diretoria: obras em risco, causa do atraso (RDO), o que o contrato diz e a probabilidade de estouro. Noite 4." \
          --profile "$PERFIL")
echo "$SAIDA"
SID=$(echo "$SAIDA" | sed -E 's/.*\(([0-9a-f]{32})\).*/\1/')
sed -i.bak -E "s/(genie_space_id: )[0-9a-f]{32}/\1$SID/" "$APP_DIR/databricks.yml" && rm -f "$APP_DIR/databricks.yml.bak"
sed -i.bak -E "s/(DATABRICKS_GENIE_SPACE_ID=)[0-9a-f]{32}/\1$SID/" "$APP_DIR/.env" 2>/dev/null && rm -f "$APP_DIR/.env.bak" || true

passo "4. App"
cd "$APP_DIR"
if ! databricks apps deploy --profile "$PERFIL" 2>&1 | tail -3; then :; fi
bash scripts/conceder-acesso.sh "$PERFIL"
databricks apps deploy --profile "$PERFIL" 2>&1 | tail -3
passo "pronto: $(databricks apps get torre-atlas --profile "$PERFIL" -o json | python3 -c "import json,sys;print(json.load(sys.stdin)['url'])")"
