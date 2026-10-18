#!/usr/bin/env python3
"""Gera o dashboard AI/BI da noite 1 (sobre a BRONZE) como JSON versionado.

Uso:
    python3 aulas/aula-01-analista/gerar_dashboard.py            # só escreve o JSON
    python3 aulas/aula-01-analista/gerar_dashboard.py --deploy --profile SEU-PERFIL

O JSON é o dashboard: nada aqui foi montado clicando. As queries usam o nome
da tabela sem catálogo; catálogo e schema entram no deploy.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import subprocess

AQUI = pathlib.Path(__file__).resolve().parent
SAIDA = AQUI / "dashboard-bronze.lvdash.json"
NOME = "Torre de Controle · Noite 1 (bronze)"

SQL_OBRAS = """-- Tudo na bronze é texto: todo acesso começa com CAST, replace e coalesce de data.
-- É o imposto que a camada silver vai eliminar na noite 2.
WITH t AS (
  SELECT projeto_id,
         CAST(valor_planejado AS DECIMAL(18,2)) AS vp,
         LEAST(CAST(pct_concluido AS DOUBLE), 100) / 100 AS pct,
         GREATEST(0, LEAST(1, datediff(DATE'2026-10-16', CAST(inicio_baseline AS DATE))
                  / datediff(CAST(fim_baseline AS DATE), CAST(inicio_baseline AS DATE)))) AS pct_plan
  FROM tarefas
),
v AS (SELECT projeto_id, SUM(vp * pct_plan) AS pv, SUM(vp * pct) AS ev FROM t GROUP BY projeto_id),
c AS (SELECT projeto_id, SUM(CAST(replace(valor_real, ',', '.') AS DECIMAL(18,2))) AS ac FROM custos GROUP BY projeto_id),
o AS (
  SELECT p.projeto_id, concat(p.projeto_id, ' · ', p.nome_projeto) AS obra, p.cliente, p.setor,
         upper(trim(p.uf)) AS uf,
         CAST(p.valor_contrato AS DECIMAL(18,2)) AS valor_contrato,
         CAST(p.orcamento_custo AS DECIMAL(18,2)) AS orcamento,
         datediff(CAST(p.data_fim_baseline AS DATE),
                  coalesce(try_to_date(p.data_inicio, 'yyyy-MM-dd'), try_to_date(p.data_inicio, 'dd/MM/yyyy'))) AS duracao,
         v.pv, v.ev, c.ac
  FROM projetos p JOIN v USING (projeto_id) JOIN c USING (projeto_id)
  WHERE p.status = 'em_andamento'
)
SELECT projeto_id, obra, cliente, setor, uf, valor_contrato, orcamento,
       ROUND(ev / pv, 2) AS spi,
       ROUND(ev / ac, 2) AS cpi,
       CASE WHEN ev / pv < 0.8 OR ev / ac < 0.8 THEN 'crítico'
            WHEN ev / pv < 0.9 OR ev / ac < 0.9 THEN 'atenção' ELSE 'ok' END AS situacao,
       CASE WHEN ev / pv < 0.8 OR ev / ac < 0.8 THEN 1 ELSE 0 END AS critica,
       CASE WHEN ev / pv < 0.9 OR ev / ac < 0.9 THEN 1 ELSE 0 END AS em_risco,
       GREATEST(0, orcamento / (ev / ac) - orcamento) AS estouro_previsto,
       (valor_contrato - orcamento / (ev / ac)) / valor_contrato AS margem_projetada,
       ROUND(duracao / (ev / pv) - duracao) AS atraso_projetado_dias
FROM o
ORDER BY LEAST(ev / pv, ev / ac)"""

SQL_CUSTOS = """SELECT date_trunc('MONTH', CAST(data AS DATE)) AS mes,
       categoria,
       CAST(replace(valor_real, ',', '.') AS DECIMAL(18,2)) AS valor
FROM custos"""


def ds(nome: str, titulo: str, sql: str) -> dict:
    linhas = sql.split("\n")
    return {"name": nome, "displayName": titulo, "queryLines": [l + "\n" for l in linhas]}


def texto(nome: str, md: str, pos: tuple[int, int, int, int]) -> dict:
    x, y, w, h = pos
    return {"widget": {"name": nome, "textbox_spec": md}, "position": {"x": x, "y": y, "width": w, "height": h}}


def widget(nome, dataset, campos, spec, pos, desagregado=False):
    x, y, w, h = pos
    return {"widget": {"name": nome,
                       "queries": [{"name": "main_query", "query": {
                           "datasetName": dataset,
                           "fields": [{"name": n, "expression": e} for n, e in campos],
                           "disaggregated": desagregado}}],
                       "spec": spec},
            "position": {"x": x, "y": y, "width": w, "height": h}}


BRL = {"type": "number-currency", "currencyCode": "BRL", "abbreviation": "compact",
       "decimalPlaces": {"type": "max", "places": 1}}


def contador(nome, campo, expr, titulo, fmt, pos):
    return widget(nome, "ds_obras", [(campo, expr)],
                  {"version": 2, "widgetType": "counter",
                   "encodings": {"value": {"fieldName": campo, "displayName": titulo, "format": fmt}},
                   "frame": {"showTitle": True, "title": titulo}}, pos)


def montar() -> dict:
    layout = [
        texto("titulo", "# Torre de Controle · Construtora Atlas Engenharia\n\n"
              "**Quais obras estão atrasadas e quanto isso custa?** Tudo aqui lê a camada **bronze**, "
              "o dado como veio dos sistemas. Repare no SQL dos datasets: `CAST`, `replace` e `try_to_date` "
              "em toda coluna. Hoje do dataset: 16/10/2026.", (0, 0, 12, 2)),
        contador("kpi-carteira", "sum(valor_contrato)", "SUM(`valor_contrato`)", "Carteira em andamento", BRL, (0, 2, 3, 4)),
        contador("kpi-risco", "sum(em_risco)", "SUM(`em_risco`)", "Obras com SPI ou CPI < 0,9",
                 {"type": "number-plain"}, (3, 2, 3, 4)),
        contador("kpi-criticas", "sum(critica)", "SUM(`critica`)", "Obras críticas (< 0,8)",
                 {"type": "number-plain"}, (6, 2, 3, 4)),
        contador("kpi-estouro", "sum(estouro_previsto)", "SUM(`estouro_previsto`)", "Estouro previsto (EAC − orçamento)",
                 BRL, (9, 2, 3, 4)),
        texto("secao-risco", "## Onde está o problema\n\nSPI < 1 é atraso; CPI < 1 é cada real gastando mais do que entrega. "
              "Clique numa barra para filtrar a tabela.", (0, 6, 12, 1)),
        widget("estouro-obra", "ds_obras", [("obra", "`obra`"), ("sum(estouro_previsto)", "SUM(`estouro_previsto`)")],
               {"version": 3, "widgetType": "bar",
                "encodings": {"y": {"fieldName": "obra", "scale": {"type": "categorical",
                                    "sort": {"by": "x-reversed"}}, "displayName": "Obra"},
                              "x": {"fieldName": "sum(estouro_previsto)", "scale": {"type": "quantitative"},
                                    "displayName": "Estouro previsto", "format": BRL}},
                "frame": {"showTitle": True, "title": "Estouro de custo previsto por obra"}}, (0, 7, 7, 7)),
        widget("situacao", "ds_obras", [("situacao", "`situacao`"), ("count(projeto_id)", "COUNT(`projeto_id`)")],
               {"version": 3, "widgetType": "pie",
                "encodings": {"angle": {"fieldName": "count(projeto_id)", "scale": {"type": "quantitative"},
                                        "displayName": "Obras"},
                              "color": {"fieldName": "situacao", "scale": {"type": "categorical", "mappings": [
                                  {"value": "crítico", "color": "#FF5F46"}, {"value": "atenção", "color": "#F6C344"},
                                  {"value": "ok", "color": "#22C2F4"}]}, "displayName": "Situação"}},
                "frame": {"showTitle": True, "title": "Obras em andamento por situação"}}, (7, 7, 5, 7)),
        texto("secao-custo", "## Para onde vai o dinheiro\n\nCusto real por mês e categoria. Sem trocar a vírgula "
              "decimal por ponto, 540 lançamentos somem do total em silêncio.", (0, 14, 12, 1)),
        widget("custo-mes", "ds_custos", [("monthly(mes)", "DATE_TRUNC(\"MONTH\", `mes`)"), ("categoria", "`categoria`"),
                                         ("sum(valor)", "SUM(`valor`)")],
               {"version": 3, "widgetType": "bar",
                "encodings": {"x": {"fieldName": "monthly(mes)", "scale": {"type": "temporal"}, "displayName": "Mês"},
                              "y": {"fieldName": "sum(valor)", "scale": {"type": "quantitative"},
                                    "displayName": "Custo real", "format": BRL},
                              "color": {"fieldName": "categoria", "scale": {"type": "categorical"},
                                        "displayName": "Categoria"}},
                "frame": {"showTitle": True, "title": "Custo real por mês"}}, (0, 15, 12, 6)),
        texto("secao-tabela", "## Todas as obras em andamento\n\nOrdenadas da pior para a melhor. "
              "⚠️ UF ainda vem suja na origem (mg, ' MG '): aqui foi corrigida com `upper(trim())`.", (0, 21, 12, 1)),
        widget("tabela-obras", "ds_obras",
               [(c, f"`{c}`") for c in ("obra", "cliente", "uf", "spi", "cpi", "situacao",
                                         "estouro_previsto", "margem_projetada", "atraso_projetado_dias")],
               {"version": 2, "widgetType": "table",
                "encodings": {"columns": [
                    {"fieldName": "obra", "displayName": "Obra"},
                    {"fieldName": "cliente", "displayName": "Cliente"},
                    {"fieldName": "uf", "displayName": "UF"},
                    {"fieldName": "spi", "displayName": "SPI"},
                    {"fieldName": "cpi", "displayName": "CPI"},
                    {"fieldName": "situacao", "displayName": "Situação"},
                    {"fieldName": "estouro_previsto", "displayName": "Estouro previsto",
                     "format": {"type": "number-currency", "currencyCode": "BRL",
                                "decimalPlaces": {"type": "max", "places": 0}}},
                    {"fieldName": "margem_projetada", "displayName": "Margem projetada",
                     "format": {"type": "number-percent", "decimalPlaces": {"type": "max", "places": 1}}},
                    {"fieldName": "atraso_projetado_dias", "displayName": "Atraso projetado (dias)"}]},
                "frame": {"showTitle": True, "title": "Obras em andamento"}}, (0, 22, 12, 8), desagregado=True),
    ]
    return {
        "datasets": [ds("ds_obras", "Obras em andamento (bronze)", SQL_OBRAS),
                     ds("ds_custos", "Custos (bronze)", SQL_CUSTOS)],
        "pages": [{"name": "noite1", "displayName": "Noite 1", "pageType": "PAGE_TYPE_CANVAS",
                   "layoutVersion": "GRID_V1", "layout": layout}],
        "uiSettings": {"theme": {
            "canvasBackgroundColor": {"light": "#F5F6FC", "dark": "#14141A"},
            "widgetBackgroundColor": {"light": "#FFFFFF", "dark": "#1E1E24"},
            "fontColor": {"light": "#14141A", "dark": "#F5F6FC"},
            "selectionColor": {"light": "#0059DB", "dark": "#22C2F4"},
            "visualizationColors": ["#0059DB", "#22C2F4", "#F6C344", "#FF8A4C", "#9B6BDB", "#3ECF8E", "#6E7180"],
            "widgetHeaderAlignment": "LEFT", "widgetCornerRadius": 12}},
    }


def cli(args: list[str], profile: str) -> dict:
    r = subprocess.run(["databricks", *args, "--profile", profile, "-o", "json"], capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit(r.stderr)
    return json.loads(r.stdout or "{}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--deploy", action="store_true")
    ap.add_argument("--profile")
    ap.add_argument("--catalog", default="lakehouse_atlas")
    a = ap.parse_args()
    painel = montar()
    SAIDA.write_text(json.dumps(painel, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"ok: {SAIDA.name}")
    if not a.deploy:
        return
    if not a.profile:
        raise SystemExit("passe --profile")
    eu = cli(["current-user", "me"], a.profile)["userName"]
    wh = cli(["warehouses", "list"], a.profile)[0]["id"]
    pasta = f"/Workspace/Users/{eu}/imersao-torre"
    subprocess.run(["databricks", "workspace", "mkdirs", pasta, "--profile", a.profile], check=True)
    existentes = [d for d in cli(["lakeview", "list"], a.profile) if d.get("display_name") == NOME]
    base = ["--dataset-catalog", a.catalog, "--dataset-schema", "bronze",
            "--serialized-dashboard", json.dumps(painel, ensure_ascii=False)]
    if existentes:
        did = existentes[0]["dashboard_id"]
        cli(["lakeview", "update", did, *base], a.profile)
    else:
        did = cli(["lakeview", "create", "--display-name", NOME, "--warehouse-id", wh, *base,
                   "--json", json.dumps({"parent_path": pasta})], a.profile)["dashboard_id"]
    cli(["lakeview", "publish", did, "--warehouse-id", wh], a.profile)
    host = subprocess.run(["databricks", "auth", "env", "--profile", a.profile, "-o", "json"],
                          capture_output=True, text=True).stdout
    host = json.loads(host)["env"]["DATABRICKS_HOST"].rstrip("/")
    print(f"publicado: {host}/sql/dashboardsv3/{did}/published")


if __name__ == "__main__":
    main()
