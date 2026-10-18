#!/usr/bin/env python3
"""Gera o dashboard de Portfólio da noite 2 (sobre a GOLD e as metric views).

Uso:  python3 aulas/aula-02-engenheiro/atlas/scripts/gerar_dashboard.py

Escreve resources/dashboard-portfolio.lvdash.json, que o bundle publica no
deploy (resources/dashboard.dashboard.yml). Compare o SQL dos datasets com o
da noite 1: sem CAST, sem replace, sem try_to_date. A limpeza mora na silver.
"""
from __future__ import annotations

import json
import pathlib

SAIDA = pathlib.Path(__file__).resolve().parents[1] / "resources" / "dashboard-portfolio.lvdash.json"

BRL = {"type": "number-currency", "currencyCode": "BRL", "abbreviation": "compact",
       "decimalPlaces": {"type": "max", "places": 1}}
BRL0 = {**BRL, "decimalPlaces": {"type": "max", "places": 0}}
PCT = {"type": "number-percent", "decimalPlaces": {"type": "max", "places": 1}}
NUM2 = {"type": "number-plain", "decimalPlaces": {"type": "max", "places": 2}}
CORES_SITUACAO = [{"value": "crítico", "color": "#FF5F46"}, {"value": "atenção", "color": "#F6C344"},
                  {"value": "ok", "color": "#22C2F4"}]

DATASETS = {
    "ds_kpis": ("KPIs governados (mv_obras)", """
-- Os KPIs vêm da metric view: a fórmula do SPI e do CPI mora num lugar só.
SELECT MEASURE(carteira) AS carteira, MEASURE(spi) AS spi, MEASURE(cpi) AS cpi,
       MEASURE(estouro_previsto) AS estouro_previsto, MEASURE(margem_projetada) AS margem_projetada,
       MEASURE(obras_em_risco) AS obras_em_risco, MEASURE(obras_criticas) AS obras_criticas
FROM mv_obras"""),
    "ds_obras": ("Obras em andamento hoje", """
SELECT projeto_id, obra, cliente, setor, uf, situacao, spi, cpi, estouro_previsto, margem_projetada,
       atraso_projetado_dias, termino_projetado, rupturas_previstas, valor_contrato
FROM obra_situacao_atual
WHERE status = 'em_andamento'"""),
    "ds_evolucao": ("Evolução semanal da carteira", """
SELECT semana, MEASURE(spi) AS spi, MEASURE(cpi) AS cpi, MEASURE(horas_ociosas) AS horas_ociosas
FROM mv_evolucao
WHERE semana >= DATE'2025-03-07'
GROUP BY semana
ORDER BY semana"""),
    "ds_equipamentos": ("Frota nas últimas 12 semanas", """
SELECT equipamento_id, tipo, modelo, obra, uf,
       SUM(horas_operadas) / SUM(horas_disponiveis) AS utilizacao,
       SUM(horas_paradas) AS horas_paradas, SUM(custo_ocioso) AS custo_ocioso
FROM utilizacao_equipamento_semana
WHERE semana > DATE'2026-07-24'
GROUP BY ALL"""),
    "ds_frota_top": ("Frota mais parada (top 15)", """
SELECT concat(equipamento_id, ' · ', modelo, ' · ', projeto_id) AS equipamento, SUM(custo_ocioso) AS custo_ocioso
FROM utilizacao_equipamento_semana
WHERE semana > DATE'2026-07-24'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 15"""),
    "ds_equipe": ("Equipes nas últimas 8 semanas", """
SELECT obra, uf, SUM(horas_ociosas) AS horas_ociosas, SUM(horas_apontadas) / SUM(horas_disponiveis) AS utilizacao,
       MIN(spi_da_obra) AS spi_da_obra
FROM utilizacao_equipe_semana
WHERE semana > DATE'2026-08-21'
GROUP BY ALL"""),
    "ds_estoque": ("Cobertura de estoque hoje", """
SELECT obra, uf, material, disciplina, saldo, cobertura_dias, dias_ate_reposicao,
       proxima_entrega_prometida, fornecedor_proxima_entrega,
       CASE WHEN ruptura_prevista THEN 1 ELSE 0 END AS ruptura
FROM cobertura_estoque"""),
    "ds_fornecedores": ("Desempenho de fornecedor", """
SELECT fornecedor, pedidos, grafias_no_erp, lead_time_prometido_medio, lead_time_real_medio,
       fator_atraso, pct_no_prazo, pedidos_em_atraso
FROM desempenho_fornecedor
ORDER BY fator_atraso DESC"""),
}


def ds(nome):
    titulo, sql = DATASETS[nome]
    return {"name": nome, "displayName": titulo, "queryLines": [l + "\n" for l in sql.strip().split("\n")]}


def pos(x, y, w, h):
    return {"x": x, "y": y, "width": w, "height": h}


def texto(nome, md, p):
    return {"widget": {"name": nome, "textbox_spec": md}, "position": p}


def w(nome, dataset, campos, spec, p, desagregado=False):
    return {"widget": {"name": nome, "queries": [{"name": "main_query", "query": {
        "datasetName": dataset, "fields": [{"name": n, "expression": e} for n, e in campos],
        "disaggregated": desagregado}}], "spec": spec}, "position": p}


def kpi(nome, campo, titulo, fmt, p):
    return w(nome, "ds_kpis", [(campo, f"`{campo}`")],
             {"version": 2, "widgetType": "counter",
              "encodings": {"value": {"fieldName": campo, "displayName": titulo, "format": fmt}},
              "frame": {"showTitle": True, "title": titulo}}, p, desagregado=True)


def barra_h(nome, dataset, dim, med, expr, titulo, fmt, p, cor=None):
    enc = {"y": {"fieldName": dim, "scale": {"type": "categorical", "sort": {"by": "x-reversed"}}, "displayName": dim},
           "x": {"fieldName": med, "scale": {"type": "quantitative"}, "displayName": titulo, "format": fmt}}
    campos = [(dim, f"`{dim}`"), (med, expr)]
    if cor:
        campos.append((cor, f"`{cor}`"))
        enc["color"] = {"fieldName": cor, "scale": {"type": "categorical", "mappings": CORES_SITUACAO},
                        "displayName": cor}
    return w(nome, dataset, campos, {"version": 3, "widgetType": "bar", "encodings": enc,
                                     "frame": {"showTitle": True, "title": titulo}}, p)


def tabela(nome, dataset, colunas, titulo, p):
    return w(nome, dataset, [(c, f"`{c}`") for c, *_ in colunas],
             {"version": 2, "widgetType": "table",
              "encodings": {"columns": [dict(fieldName=c, displayName=d, **({"format": f[0]} if f else {}))
                                        for c, d, *f in colunas]},
              "frame": {"showTitle": True, "title": titulo}}, p, desagregado=True)


def montar() -> dict:
    portfolio = [
        texto("titulo", "# Torre de Controle · Portfólio\n\n**Quais obras vão estourar prazo ou orçamento?** "
              "Agora sobre a camada **gold** e as **métricas governadas** (`mv_obras`): o SPI do card é o mesmo "
              "SPI do Genie e do SQL. Hoje do dataset: 16/10/2026.", pos(0, 0, 12, 3)),
        kpi("kpi-carteira", "carteira", "Carteira em andamento", BRL0, pos(0, 3, 4, 4)),
        kpi("kpi-spi", "spi", "SPI da carteira", NUM2, pos(4, 3, 4, 4)),
        kpi("kpi-cpi", "cpi", "CPI da carteira", NUM2, pos(8, 3, 4, 4)),
        kpi("kpi-risco", "obras_em_risco", "Obras em risco (< 0,9)", {"type": "number-plain"}, pos(0, 7, 4, 4)),
        kpi("kpi-criticas", "obras_criticas", "Obras críticas (< 0,8)", {"type": "number-plain"}, pos(4, 7, 4, 4)),
        kpi("kpi-estouro", "estouro_previsto", "Estouro previsto", BRL0, pos(8, 7, 4, 4)),
        barra_h("estouro-obra", "ds_obras", "obra", "sum(estouro_previsto)", "SUM(`estouro_previsto`)",
                "Estouro previsto por obra", BRL, pos(0, 11, 7, 8), cor="situacao"),
        w("spi-cpi", "ds_obras", [("spi", "`spi`"), ("cpi", "`cpi`"), ("situacao", "`situacao`"), ("obra", "`obra`")],
          {"version": 3, "widgetType": "scatter",
           "encodings": {"x": {"fieldName": "spi", "scale": {"type": "quantitative"}, "displayName": "SPI (prazo)"},
                         "y": {"fieldName": "cpi", "scale": {"type": "quantitative"}, "displayName": "CPI (custo)"},
                         "color": {"fieldName": "situacao", "scale": {"type": "categorical", "mappings": CORES_SITUACAO},
                                   "displayName": "Situação"}},
           "frame": {"showTitle": True, "title": "Prazo × custo: cada ponto é uma obra"}}, pos(7, 11, 5, 8), True),
        w("evolucao", "ds_evolucao", [("semana", "`semana`"), ("spi", "`spi`"), ("cpi", "`cpi`")],
          {"version": 3, "widgetType": "line",
           "encodings": {"x": {"fieldName": "semana", "scale": {"type": "temporal"}, "displayName": "Semana"},
                         "y": {"scale": {"type": "quantitative"}, "fields": [
                             {"fieldName": "spi", "displayName": "SPI"}, {"fieldName": "cpi", "displayName": "CPI"}]}},
           "frame": {"showTitle": True, "title": "SPI e CPI da carteira, semana a semana"}}, pos(0, 19, 12, 6), True),
        tabela("tabela-obras", "ds_obras", [
            ("obra", "Obra"), ("cliente", "Cliente"), ("uf", "UF"), ("situacao", "Situação"),
            ("spi", "SPI", NUM2), ("cpi", "CPI", NUM2), ("estouro_previsto", "Estouro previsto", BRL),
            ("margem_projetada", "Margem projetada", PCT), ("atraso_projetado_dias", "Atraso projetado (dias)"),
            ("termino_projetado", "Término projetado"), ("rupturas_previstas", "Rupturas previstas")],
               "Obras em andamento", pos(0, 25, 12, 8)),
    ]
    recursos = [
        texto("titulo-recursos", "# Gente e máquina parada\n\n**Onde tenho equipamento ocioso enquanto outra obra está "
              "atrasada?** Utilização das últimas 12 semanas (frota) e 8 semanas (equipes).", pos(0, 0, 12, 2)),
        barra_h("frota-ociosa", "ds_frota_top", "equipamento", "sum(custo_ocioso)", "SUM(`custo_ocioso`)",
                "Custo de equipamento parado (top 15)", BRL, pos(0, 2, 6, 8)),
        tabela("guindastes", "ds_equipamentos", [
            ("equipamento_id", "Equipamento"), ("modelo", "Modelo"), ("obra", "Obra"), ("uf", "UF"),
            ("utilizacao", "Utilização", PCT), ("horas_paradas", "Horas paradas"),
            ("custo_ocioso", "Custo ocioso", BRL)], "Frota: do mais parado ao mais usado", pos(6, 2, 6, 8)),
        barra_h("equipe-ociosa", "ds_equipe", "obra", "sum(horas_ociosas)", "SUM(`horas_ociosas`)",
                "Horas ociosas de equipe por obra", {"type": "number-plain"}, pos(0, 10, 12, 8)),
    ]
    suprimentos = [
        texto("titulo-sup", "# Material que vai faltar\n\n**Que material acaba antes da próxima entrega chegar?** "
              "Ruptura prevista = cobertura em dias menor que os dias até a próxima entrega prometida "
              "(ou o lead time, se a promessa já venceu).", pos(0, 0, 12, 2)),
        barra_h("rupturas-obra", "ds_estoque", "obra", "sum(ruptura)", "SUM(`ruptura`)",
                "Rupturas previstas por obra", {"type": "number-plain"}, pos(0, 2, 6, 8)),
        tabela("fornecedores", "ds_fornecedores", [
            ("fornecedor", "Fornecedor"), ("grafias_no_erp", "Grafias no ERP"), ("pedidos", "Pedidos"),
            ("lead_time_prometido_medio", "Lead time prometido"), ("lead_time_real_medio", "Lead time real"),
            ("fator_atraso", "Real ÷ prometido", NUM2), ("pct_no_prazo", "No prazo", PCT),
            ("pedidos_em_atraso", "Em atraso hoje")], "Fornecedores: quem promete e não cumpre", pos(6, 2, 6, 8)),
        tabela("estoque", "ds_estoque", [
            ("obra", "Obra"), ("material", "Material"), ("saldo", "Saldo"), ("cobertura_dias", "Cobertura (dias)"),
            ("dias_ate_reposicao", "Dias até repor"), ("fornecedor_proxima_entrega", "Fornecedor"),
            ("ruptura", "Ruptura prevista")], "Cobertura por material e obra", pos(0, 10, 12, 8)),
    ]
    pagina = lambda n, t, l: {"name": n, "displayName": t, "pageType": "PAGE_TYPE_CANVAS",
                              "layoutVersion": "GRID_V1", "layout": l}
    return {
        "datasets": [ds(n) for n in DATASETS],
        "pages": [pagina("portfolio", "Portfólio", portfolio), pagina("recursos", "Recursos", recursos),
                  pagina("suprimentos", "Suprimentos", suprimentos)],
        "uiSettings": {"theme": {
            "canvasBackgroundColor": {"light": "#F5F6FC", "dark": "#14141A"},
            "widgetBackgroundColor": {"light": "#FFFFFF", "dark": "#1E1E24"},
            "fontColor": {"light": "#14141A", "dark": "#F5F6FC"},
            "selectionColor": {"light": "#0059DB", "dark": "#22C2F4"},
            "visualizationColors": ["#0059DB", "#22C2F4", "#F6C344", "#FF8A4C", "#9B6BDB", "#3ECF8E", "#6E7180"],
            "widgetHeaderAlignment": "LEFT", "widgetCornerRadius": 12}},
    }


if __name__ == "__main__":
    SAIDA.write_text(json.dumps(montar(), ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"ok: {SAIDA}")
