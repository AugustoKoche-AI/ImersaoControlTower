#!/usr/bin/env python3
"""Gera o Genie Agent da Torre (noite 2) como JSON versionado.

Uso:  python3 aulas/aula-02-engenheiro/atlas/scripts/gerar_genie.py

Escreve resources/torre.geniespace.json, que o bundle publica no deploy
(resources/genie.genie_space.yml). O modelo de IA é o mesmo da noite 1: o que
muda é tudo que está embaixo dele — gold limpa, COMMENT em toda tabela,
métricas governadas e estas instruções.
"""
from __future__ import annotations

import json
import pathlib

SAIDA = pathlib.Path(__file__).resolve().parents[1] / "resources" / "torre.geniespace.json"
G = "lakehouse_atlas.gold"


def ident(prefixo: str, n: int) -> str:
    return f"{prefixo}{n:0{32 - len(prefixo)}d}"   # 32 caracteres hex, únicos e ordenados


INSTRUCOES = [
    "Você é o analista da Torre de Controle da Construtora Atlas Engenharia, uma EPC com 40 obras de mineração, óleo e gás e agro. Responda em português, com números em reais (R$) e índices com 2 casas.",
    "HOJE é 16/10/2026 (sexta-feira). Nunca use current_date(). 'Últimos 90 dias' = data >= DATE'2026-07-18'; 'últimas 12 semanas' = semana > DATE'2026-07-24'; 'últimas 8 semanas' = semana > DATE'2026-08-21'.",
    "Definições: SPI = EV / PV (abaixo de 1 é atraso). CPI = EV / AC (abaixo de 1 é estouro de custo). EAC = orçamento / CPI. Estouro previsto = EAC - orçamento, só quando positivo. Regras de corte: SPI ou CPI < 0,9 = atenção; < 0,8 = crítico.",
    "Para SPI, CPI, EAC, estouro, margem e contagem de obras em risco da fotografia de hoje, use a metric view mv_obras com MEASURE(), ou a tabela obra_situacao_atual. Obras concluídas não entram nas contagens de risco (filtre status = 'em_andamento' ou use mv_obras, que já filtra).",
    "Para evolução no tempo use fato_projeto_semana ou mv_evolucao. PV, EV e AC em fato_projeto_semana são ACUMULADOS até a semana: nunca some semanas diferentes da mesma obra.",
    "'Por que a obra X atrasou?': responda com a tabela rdo_estruturado (causa_atraso, dias_impacto), contando as causas dos últimos 90 dias e ignorando 'sem_ocorrencia' e 'nao_reportado'. Complete com o SPI da obra em obra_situacao_atual e, se a causa for falta_equipamento, mostre equipamentos do mesmo tipo ociosos em outras obras (utilizacao_equipamento_semana).",
    "Gente e equipamento parado: utilizacao_equipe_semana (horas_ociosas, utilizacao) e utilizacao_equipamento_semana (utilizacao, custo_ocioso). Utilização baixa = abaixo de 20%.",
    "Material que vai faltar: cobertura_estoque, coluna ruptura_prevista (o estoque acaba antes da próxima entrega prometida). Fornecedor: desempenho_fornecedor (fator_atraso = lead time real / prometido) e pedidos_em_atraso.",
    "Quando perguntarem por código de obra, responda com projeto_id (ex.: P011) e inclua o nome da obra.",
]

EXEMPLOS = [
    ("Por que a obra P011 atrasou?",
     f"SELECT r.causa_atraso, COUNT(*) AS rdos, SUM(coalesce(r.dias_impacto, 0)) AS dias_de_impacto, MAX(o.spi) AS spi_da_obra "
     f"FROM {G}.rdo_estruturado r JOIN {G}.obra_situacao_atual o ON o.projeto_id = r.projeto_id "
     f"WHERE r.projeto_id = 'P011' AND r.data >= DATE'2026-07-18' AND r.causa_atraso NOT IN ('sem_ocorrencia', 'nao_reportado') "
     f"GROUP BY r.causa_atraso ORDER BY rdos DESC"),
    ("Quais obras vão estourar prazo ou orçamento?",
     f"SELECT projeto_id, obra, situacao, ROUND(spi, 2) AS spi, ROUND(cpi, 2) AS cpi, estouro_previsto, atraso_projetado_dias "
     f"FROM {G}.obra_situacao_atual WHERE situacao IN ('crítico', 'atenção') ORDER BY least(spi, cpi)"),
    ("Onde tenho guindaste parado?",
     f"SELECT equipamento_id, modelo, projeto_id, obra, uf, ROUND(SUM(horas_operadas) / SUM(horas_disponiveis), 3) AS utilizacao, SUM(custo_ocioso) AS custo_ocioso "
     f"FROM {G}.utilizacao_equipamento_semana WHERE tipo = 'guindaste' AND semana > DATE'2026-07-24' "
     f"GROUP BY ALL HAVING SUM(horas_operadas) / SUM(horas_disponiveis) < 0.2 ORDER BY utilizacao"),
    ("Que material vai faltar nas obras críticas?",
     f"SELECT c.projeto_id, c.obra, c.material, c.cobertura_dias, c.dias_ate_reposicao, c.fornecedor_proxima_entrega "
     f"FROM {G}.cobertura_estoque c JOIN {G}.obra_situacao_atual o USING (projeto_id) "
     f"WHERE c.ruptura_prevista AND o.situacao = 'crítico' ORDER BY c.cobertura_dias"),
    ("Qual o SPI e o CPI da carteira?",
     f"SELECT MEASURE(spi) AS spi, MEASURE(cpi) AS cpi, MEASURE(estouro_previsto) AS estouro_previsto FROM {G}.mv_obras"),
]

PERGUNTAS = ["Quais projetos vão estourar prazo ou orçamento?",
             "Onde tenho gente e equipamento parado enquanto outra obra está atrasada?",
             "Que material vai faltar antes de travar uma frente de serviço?",
             "Por que a obra P011 atrasou?"]

TABELAS = ["cobertura_estoque", "desempenho_fornecedor", "dim_projeto", "fato_projeto_semana", "obra_situacao_atual",
           "pedidos_em_atraso", "rdo_estruturado", "utilizacao_equipamento_semana", "utilizacao_equipe_semana"]
METRICAS = ["mv_equipamentos", "mv_evolucao", "mv_fornecedores", "mv_obras", "mv_suprimentos"]


def montar() -> dict:
    return {
        "version": 2,
        "config": {"sample_questions": [{"id": ident("b1", i), "question": [q]} for i, q in enumerate(PERGUNTAS, 1)]},
        "data_sources": {
            "tables": [{"identifier": f"{G}.{t}"} for t in sorted(TABELAS)],
            "metric_views": [{"identifier": f"{G}.{m}"} for m in sorted(METRICAS)],
        },
        "instructions": {
            "text_instructions": [{"id": ident("c1", 1), "content": [l + "\n" for l in INSTRUCOES]}],
            "example_question_sqls": [{"id": ident("d1", i), "question": [q], "sql": [s]}
                                      for i, (q, s) in enumerate(EXEMPLOS, 1)],
        },
    }


if __name__ == "__main__":
    SAIDA.write_text(json.dumps(montar(), ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"ok: {SAIDA}")
