#!/usr/bin/env bash
# Limpa SÓ a noite 3 e devolve o ambiente ao fim da noite 2.
#
# A noite 2 continua de pé: bronze, silver, gold, métricas, dashboard e Genie.
# Some apenas o que os três prompts de hoje criaram, para você rodar os três de
# novo, do zero, quantas vezes quiser.
#
# Uso:  bash aulas/aula-03-cientista/prd/99-limpar-aula-03.sh <profile> [--apagar] [--gabarito]
#       Sem --apagar ele só MOSTRA o que faria.
#       --gabarito: limpa o workspace mas NÃO mexe em arquivo nenhum (o bundle de
#       referência aulas/aula-02-engenheiro/vertice guarda o src/ml de propósito).
#
# O que apaga:
#   1. as tabelas da noite 3: ml.features_projeto_semana, ml.modelo_metricas e
#      gold.score_estouro_30d (+ as da versão antiga, quando tudo morava na gold)
#   2. as versões e o modelo registrado no Unity Catalog: ml.modelo_estouro_30d
#      (+ gold.modelo_estouro_30d, da versão antiga)
#   3. o experimento do MLflow (/Users/<você>/vertice)
#   4. no seu bundle (meu-vertice): a pasta src/ml e as tarefas ml_* do job; e o redeploy
#   5. a conferência: sai com erro se sobrou alguma coisa
set -euo pipefail

PROFILE="${1:?uso: bash prd/99-limpar-aula-03.sh <profile> [--apagar] [--gabarito]}"
CONFIRMA="${2:-}"
GABARITO="${3:-}"
CATALOGO="${CATALOGO:-lakehouse_vertice}"
RAIZ="$(cd "$(dirname "$0")/../../.." && pwd)"
BUNDLE="$RAIZ/aulas/aula-02-engenheiro/meu-vertice"
# a versão atual: laboratório no schema ml, só o resultado na gold
TABELAS=(ml.features_projeto_semana ml.modelo_metricas gold.score_estouro_30d
         gold.features_projeto_semana gold.modelo_metricas)   # as duas últimas: versão antiga (tudo na gold)
MODELOS=("$CATALOGO.ml.modelo_estouro_30d"
         "$CATALOGO.gold.modelo_estouro_30d")                 # o segundo: versão antiga

echo "profile:  $PROFILE"
echo "tabelas:  ${TABELAS[*]}"
echo "modelos:  ${MODELOS[*]}"
[ "$GABARITO" = "--gabarito" ] && echo "bundle:   (gabarito: nenhum arquivo é tocado)" || echo "bundle:   $BUNDLE (src/ml e tarefas ml_*)"
echo
if [ "$CONFIRMA" != "--apagar" ]; then
  echo "Simulação. Nada foi apagado. Para apagar:  bash $0 $PROFILE --apagar [--gabarito]"
  exit 0
fi

sql() { printf '%s' "$1" > /tmp/_limpar_n3.sql; python3 "$RAIZ/scripts/run_sql.py" /tmp/_limpar_n3.sql --profile "$PROFILE" --quiet --continuar >/dev/null; }

echo "→ tabelas de ML..."
for t in "${TABELAS[@]}"; do sql "DROP TABLE IF EXISTS $CATALOGO.$t"; done

# O delete do modelo RECUSA enquanto houver versão viva ("is not empty").
# E um registro que falhou no meio deixa versão órfã: apague todas.
echo "→ versões e modelos..."
for MODELO in "${MODELOS[@]}"; do
  VERSOES=$(databricks model-versions list "$MODELO" --profile "$PROFILE" -o json 2>/dev/null \
            | grep -oE '"version": *[0-9]+' | grep -oE '[0-9]+' | sort -u || true)
  for v in $VERSOES; do databricks model-versions delete "$MODELO" "$v" --profile "$PROFILE" >/dev/null 2>&1 || true; done
  databricks registered-models delete "$MODELO" --profile "$PROFILE" >/dev/null 2>&1 || echo "   ($MODELO não existia)"
done

echo "→ experimento do MLflow..."
EU=$(databricks current-user me --profile "$PROFILE" -o json | python3 -c 'import sys,json;print(json.load(sys.stdin)["userName"])')
databricks workspace delete "/Users/$EU/vertice" --recursive --profile "$PROFILE" >/dev/null 2>&1 || echo "   (pasta não existia)"

if [ "$GABARITO" != "--gabarito" ] && [ -d "$BUNDLE" ]; then
  echo "→ código local da noite 3 no meu-vertice..."
  rm -rf "$BUNDLE/src/ml"
  for f in "$BUNDLE"/resources/*.job.yml; do
    [ -f "$f" ] || continue
    # tira do job todo bloco de tarefa cujo task_key começa com ml_
    python3 - "$f" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
s = re.sub(r"\n(?:[ \t]*#[^\n]*\n)*[ \t]*- task_key: ml_[\s\S]*?(?=\n[ \t]*(?:#[^\n]*\n[ \t]*)*- task_key: |\Z)", "\n", s)
p.write_text(s.rstrip() + "\n")
PY
  done
  if [ -f "$BUNDLE/databricks.yml" ]; then
    echo "→ redeploy do meu-vertice..."
    (cd "$BUNDLE" && databricks bundle deploy --profile "$PROFILE" 2>&1 | tail -3) || true
  fi
fi

echo
echo "── conferindo ──────────────────────────────────────────────"
RESTO=0; SOBRA_MODELO=0
for esquema in ml gold; do
  n=$(databricks tables list "$CATALOGO" "$esquema" --profile "$PROFILE" -o json 2>/dev/null \
      | grep -cE '"name": *"(features_projeto_semana|modelo_metricas|score_estouro_30d)"' || true)
  RESTO=$((RESTO + ${n:-0}))
  m=$(databricks registered-models list --catalog-name "$CATALOGO" --schema-name "$esquema" --profile "$PROFILE" -o json 2>/dev/null \
      | grep -c 'modelo_estouro_30d' || true)
  SOBRA_MODELO=$((SOBRA_MODELO + ${m:-0}))
done
echo "  tabelas da noite 3 que sobraram: $RESTO"
echo "  modelos da noite 3 que sobraram: $SOBRA_MODELO"
# o schema ml fica (vazio): o prompt 1 recria tudo com CREATE SCHEMA IF NOT EXISTS
if [ "$RESTO" != "0" ] || [ "$SOBRA_MODELO" != "0" ]; then echo "Sobrou coisa. NÃO comece a noite 3 assim."; exit 1; fi
echo "Zerado. Os três prompts têm que reconstruir tudo do nada: comece por prd/prompt-01-features.md."
