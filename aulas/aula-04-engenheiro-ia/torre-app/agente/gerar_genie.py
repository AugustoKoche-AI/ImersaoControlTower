#!/usr/bin/env python3
"""Gera o Genie Agent da noite 4, "Torre de Controle · Diretoria + Contratos", como JSON.

Uso:
    python3 aulas/aula-04-engenheiro-ia/torre-app/agente/gerar_genie.py --profile SEU-PERFIL
    python3 scripts/genie.py publicar aulas/aula-04-engenheiro-ia/torre-app/agente/diretoria-contratos-genie.json \
        --titulo "Torre de Controle · Diretoria + Contratos" --profile SEU-PERFIL

É o Genie da noite 2 com uma camada a mais: os CONTRATOS. A diretoria não
pergunta só "por que atrasou?": pergunta "e o que o contrato diz?". O agente
cruza RDO (a causa), gold (o tamanho do problema) e cláusula (o direito).

A tabela do modelo da noite 3 (gold.score_estouro_30d) entra se existir:
o Genie recusa publicar com tabela inexistente.
"""
from __future__ import annotations

import json
import pathlib
import subprocess
import sys

AQUI = pathlib.Path(__file__).resolve().parent
# Não use a extensão .geniespace.json aqui: o import do código do app recusa
# ("Requested node type [UNKNOWN] is not supported") e o app não sobe.
SAIDA = AQUI / "diretoria-contratos-genie.json"
G = "lakehouse_atlas.gold"


def ident(prefixo: str, n: int) -> str:
    return f"{prefixo}{n:0{32 - len(prefixo)}d}"


def existe(tabela: str, profile: str | None) -> bool:
    if not profile:
        return False
    r = subprocess.run(["databricks", "tables", "exists", tabela, "--profile", profile, "-o", "json"],
                       capture_output=True, text=True)
    return r.returncode == 0 and '"table_exists": true' in r.stdout.replace("\n", " ").replace("  ", " ")


TABELAS = ["contratos_clausulas", "contratos_exposicao", "contratos_resumo", "cobertura_estoque",
           "desempenho_fornecedor", "obra_situacao_atual", "pedidos_em_atraso", "rdo_estruturado",
           "utilizacao_equipamento_semana", "utilizacao_equipe_semana"]
METRICAS = ["mv_obras"]

INSTRUCOES = [
    "Você é o assessor da DIRETORIA da Construtora Atlas Engenharia (EPC, 40 obras). A ATLAS É A CONTRATADA em todos os "
    "contratos; o cliente é a CONTRATANTE. Multa por atraso é CUSTO DA ATLAS, e prorrogação é um direito que a Atlas pleiteia "
    "ao cliente. Nunca recomende 'cobrar a contratada'. Responda em português, curto, "
    "com números em reais (R$) e índices com 2 casas. Termine com uma recomendação de uma linha quando a pergunta pedir decisão.",
    "HOJE é 16/10/2026. Nunca use current_date(). 'Últimos 90 dias' = data >= DATE'2026-07-18'; "
    "'últimas 12 semanas' = semana > DATE'2026-07-24'.",
    "KPIs: SPI = EV/PV (< 1 é atraso), CPI = EV/AC (< 1 é estouro). Atenção: SPI ou CPI < 0,9; crítico: < 0,8. "
    "Fotografia de hoje: obra_situacao_atual (ou mv_obras com MEASURE()). Obras concluídas não entram em risco. "
    "'Em risco' = atenção + crítico SOMADOS num número só (hoje são 13), a menos que peçam a quebra por situação.",
    "Causa do atraso: rdo_estruturado (causa_atraso, dias_impacto), contando os últimos 90 dias e ignorando "
    "'sem_ocorrencia' e 'nao_reportado'.",
    "CONTRATOS: só 8 obras têm contrato digitalizado (P002, P005, P007, P011, P014, P018, P024, P033). "
    "contratos_resumo tem os campos estruturados (multa_dia_pct, teto_multa_pct, chuva_da_prorrogacao, "
    "icamento_responsavel, estrutura_fornecida_por, prazo_aditivo_dias, reajuste, bonus_antecipacao). "
    "contratos_clausulas tem o texto de cada cláusula: SEMPRE cite o número da cláusula e um trecho curto do texto "
    "quando responder o que o contrato diz. contratos_exposicao já calcula a multa estimada em R$ "
    "(valor do contrato × min(atraso projetado × multa diária, teto)).",
    "Regras de leitura do contrato: se chuva_da_prorrogacao = true, os dias de chuva registrados no RDO (comunicados em 48 h) "
    "podem ser excluídos do atraso: diga quantos RDOs e dias de chuva a Atlas pode pleitear e quanto isso reduz a multa; "
    "se false, chuva não afasta multa. Se icamento_responsavel = 'contratada', falta de "
    "guindaste é risco da Atlas e NÃO dá prorrogação. Aditivo de escopo precisa ser pleiteado em prazo_aditivo_dias "
    "dias do fato gerador, senão o direito se perde.",
    "Para 'onde tenho guindaste/equipamento parado', use utilizacao_equipamento_semana nas últimas 12 semanas: "
    "utilização média abaixo de 20% = ocioso. Para gente parada, utilizacao_equipe_semana (horas_ociosas).",
    "Quando citar uma obra, use projeto_id e nome (ex.: P011 · Pátio de estocagem de minério Canaã dos Carajás).",
]

EXEMPLOS = [
    ("Por que a obra P011 atrasou e o que o contrato diz sobre isso?",
     f"WITH causa AS (SELECT causa_atraso, COUNT(*) AS rdos, SUM(coalesce(dias_impacto, 0)) AS dias_impacto "
     f"FROM {G}.rdo_estruturado WHERE projeto_id = 'P011' AND data >= DATE'2026-07-18' "
     f"AND causa_atraso NOT IN ('sem_ocorrencia', 'nao_reportado') GROUP BY causa_atraso) "
     f"SELECT c.causa_atraso, c.rdos, c.dias_impacto, cl.clausula_numero, cl.titulo, cl.texto, "
     f"e.atraso_projetado_dias, e.multa_estimada "
     f"FROM causa c CROSS JOIN {G}.contratos_exposicao e "
     f"LEFT JOIN {G}.contratos_clausulas cl ON cl.projeto_id = 'P011' AND cl.clausula_numero = "
     f"CASE c.causa_atraso WHEN 'chuva' THEN 5 WHEN 'falta_equipamento' THEN 6 WHEN 'falta_material' THEN 7 ELSE 4 END "
     f"WHERE e.projeto_id = 'P011' ORDER BY c.rdos DESC"),
    ("Qual a multa estimada de cada obra com contrato?",
     f"SELECT projeto_id, obra, situacao, atraso_projetado_dias, multa_dia_pct, teto_multa_pct, multa_estimada, multa_no_teto "
     f"FROM {G}.contratos_exposicao ORDER BY multa_estimada DESC"),
    ("Onde tenho guindaste parado que poderia ir para a P011?",
     f"SELECT equipamento_id, modelo, projeto_id, obra, uf, ROUND(AVG(utilizacao), 3) AS utilizacao_media, "
     f"SUM(horas_paradas) AS horas_paradas, SUM(custo_ocioso) AS custo_ocioso "
     f"FROM {G}.utilizacao_equipamento_semana WHERE tipo = 'guindaste' AND semana > DATE'2026-07-24' "
     f"GROUP BY ALL HAVING AVG(utilizacao) < 0.2 ORDER BY utilizacao_media"),
    ("Quantas obras estão em risco?",
     f"SELECT COUNT(*) AS obras_em_risco FROM {G}.obra_situacao_atual "
     f"WHERE status = 'em_andamento' AND situacao IN ('crítico', 'atenção')"),
    ("Em quais contratos a chuva dá direito a prorrogação?",
     f"SELECT r.projeto_id, o.obra, r.chuva_da_prorrogacao, cl.texto AS clausula_5 FROM {G}.contratos_resumo r "
     f"JOIN {G}.obra_situacao_atual o USING (projeto_id) JOIN {G}.contratos_clausulas cl "
     f"ON cl.projeto_id = r.projeto_id AND cl.clausula_numero = 5 ORDER BY r.projeto_id"),
]

PERGUNTAS = [
    "Por que a obra P011 atrasou e o que o contrato diz sobre isso?",
    "Qual a multa estimada de cada obra com contrato?",
    "Onde tenho guindaste parado que poderia ir para a P011?",
    "Quais obras críticas estão expostas a multa?",
]


def montar(profile: str | None) -> dict:
    tabelas = list(TABELAS)
    instr = list(INSTRUCOES)
    if existe(f"{G}.score_estouro_30d", profile):
        tabelas.append("score_estouro_30d")
        instr.append("Probabilidade de estouro nos próximos 30 dias: score_estouro_30d (prob_estouro_30d de 0 a 1, "
                     "ranking, faixa_risco, principais_fatores), modelo treinado na noite 3. Use a data_referencia mais recente.")
    return {
        "version": 2,
        "config": {"sample_questions": [{"id": ident("e1", i), "question": [q]} for i, q in enumerate(PERGUNTAS, 1)]},
        "data_sources": {
            "tables": [{"identifier": f"{G}.{t}"} for t in sorted(tabelas)],
            "metric_views": [{"identifier": f"{G}.{m}"} for m in sorted(METRICAS)],
        },
        "instructions": {
            "text_instructions": [{"id": ident("e2", 1), "content": [l + "\n" for l in instr]}],
            "example_question_sqls": [{"id": ident("e3", i), "question": [q], "sql": [s]}
                                      for i, (q, s) in enumerate(EXEMPLOS, 1)],
        },
    }


def main() -> None:
    profile = sys.argv[sys.argv.index("--profile") + 1] if "--profile" in sys.argv else None
    espaco = montar(profile)
    SAIDA.write_text(json.dumps(espaco, ensure_ascii=False, indent=2), encoding="utf-8")
    n = len(espaco["data_sources"]["tables"])
    print(f"ok: {SAIDA.name} · {n} tabelas · score da noite 3: {'sim' if n > len(TABELAS) else 'ainda não'}")


if __name__ == "__main__":
    main()
