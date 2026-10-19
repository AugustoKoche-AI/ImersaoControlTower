#!/usr/bin/env bash
# Sobe a noite 4 inteira do zero, na ordem que funciona (é o gabarito dos 3 prompts):
#   1. Lakebase (projeto farol-torre), se ainda não existe
#   2. contratos e manual: PDF → elementos → cláusulas e seções → resumo tipado → multa e avisos (SQL)
#   3. Genie "Farol · Diretoria + Contratos" (e o id vai para o databricks.yml)
#   4. app: bundle deploy → GRANT para o service principal → apps deploy (o build falha sem GRANT)
#
# Uso:  bash scripts/subir-tudo.sh <perfil>
set -euo pipefail
PERFIL="${1:?informe o profile}"
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RAIZ="$(cd "$APP_DIR/../../.." && pwd)"
GENIE="Farol · Diretoria + Contratos"
t0=$(date +%s)
passo() { echo -e "\n[$(( $(date +%s) - t0 ))s] $*"; }

passo "1. Lakebase"
# list-projects (e não get-project): get-project também devolve projeto apagado ("soft delete")
if databricks postgres list-projects --profile "$PERFIL" -o json | grep -q '"projects/farol-torre"'; then
  echo "projeto farol-torre já existe"
else
  databricks postgres create-project farol-torre --profile "$PERFIL" >/dev/null && echo "projeto farol-torre criado"
fi

passo "2. Contratos e manual (ai_parse_document + ai_extract com schema)"
python3 "$RAIZ/scripts/run_sql.py" "$APP_DIR/agente/01-contratos.sql" --profile "$PERFIL" --quiet | grep -E "FALHOU|statement" || true

passo "3. Genie da diretoria"
python3 "$APP_DIR/agente/gerar_genie.py" --profile "$PERFIL"
SAIDA=$(python3 "$RAIZ/scripts/genie.py" publicar "$APP_DIR/agente/diretoria-contratos-genie.json" \
          --titulo "$GENIE" --descricao "O dono pergunta em português sobre os projetos, os contratos de fornecedor e o manual da Vértice." \
          --profile "$PERFIL")
echo "$SAIDA"
SID=$(echo "$SAIDA" | sed -E 's/.*\(([0-9a-f]{32})\).*/\1/')
sed -i.bak -E "s/(genie_space_id: )[0-9a-f]{32}/\1$SID/" "$APP_DIR/databricks.yml" && rm -f "$APP_DIR/databricks.yml.bak"
sed -i.bak -E "s/(DATABRICKS_GENIE_SPACE_ID=)[0-9a-f]{32}/\1$SID/" "$APP_DIR/.env" 2>/dev/null && rm -f "$APP_DIR/.env.bak" || true

passo "4. App (o Free Edition aceita no máximo 3 apps: confira com databricks apps list)"
cd "$APP_DIR"
databricks bundle deploy --profile "$PERFIL" 2>&1 | tail -3      # cria o app e o service principal
bash scripts/conceder-acesso.sh "$PERFIL"                          # sem isso o build falha no typegen
databricks apps deploy --profile "$PERFIL" 2>&1 | tail -3
passo "pronto: $(databricks apps get farol-torre --profile "$PERFIL" -o json | python3 -c "import json,sys;print(json.load(sys.stdin)['url'])")"
