#!/usr/bin/env python3
"""Gera o Genie Agent da noite 4, "Farol · Diretoria + Contratos", como JSON.

Uso:
    python3 aulas/aula-04-engenheiro-ia/torre-app/agente/gerar_genie.py --profile SEU-PERFIL
    python3 scripts/genie.py publicar aulas/aula-04-engenheiro-ia/torre-app/agente/diretoria-contratos-genie.json \
        --titulo "Farol · Diretoria + Contratos" --profile SEU-PERFIL

É o Genie da noite 2 com duas camadas a mais: os CONTRATOS de fornecedor e o
MANUAL de tecnologias. O dono não pergunta só "quem está atrasado?": pergunta
"e o que o contrato diz? e o que a nossa regra manda fazer?". O agente cruza o
status (a causa), a gold (o tamanho do problema), a cláusula (o direito) e o
manual (a regra da casa).

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
G = "lakehouse_vertice.gold"


def ident(prefixo: str, n: int) -> str:
    return f"{prefixo}{n:0{32 - len(prefixo)}d}"


def existe(tabela: str, profile: str | None) -> bool:
    if not profile:
        return False
    r = subprocess.run(["databricks", "tables", "exists", tabela, "--profile", profile, "-o", "json"],
                       capture_output=True, text=True)
    return r.returncode == 0 and '"table_exists": true' in r.stdout.replace("\n", " ").replace("  ", " ")


TABELAS = ["contratos_avisos", "contratos_clausulas", "contratos_multa_fornecedor", "contratos_resumo",
           "cobertura_capacidade", "desempenho_fornecedor", "entregas_em_atraso", "manual_secoes",
           "projeto_situacao_atual", "status_estruturado", "utilizacao_pessoa_semana"]
METRICAS = ["mv_projetos"]

INSTRUCOES = [
    "Você é o assessor do DONO da Vértice Tecnologia (empresa de tecnologia, 520 pessoas, 60 projetos de clientes). "
    "Nos contratos de fornecedor e SaaS, a VÉRTICE É A CONTRATANTE e o fornecedor é a CONTRATADA: multa por atraso é "
    "dinheiro que a Vértice pode COBRAR (descontar da fatura do fornecedor). Responda em português, curto, com números em "
    "reais (R$) e índices com 2 casas. Termine com uma recomendação de uma linha quando a pergunta pedir decisão.",
    "HOJE é 16/10/2026. Nunca use current_date(). 'Últimos 90 dias' = data >= DATE'2026-07-18'; "
    "'últimas 12 semanas' = semana > DATE'2026-07-24'; 'próximos 60 dias' = até 15/12/2026.",
    "KPIs: SPI = EV/PV (< 1 é atraso), CPI = EV/AC (< 1 é estouro). Atenção: SPI ou CPI < 0,9; crítico: < 0,8. "
    "Fotografia de hoje: projeto_situacao_atual com status = 'em_andamento' (ou mv_projetos com MEASURE()). "
    "'Em risco' = atenção + crítico somados (hoje são 17), a menos que peçam a quebra por situação.",
    "Causa do atraso: status_estruturado (causa_bloqueio, bloqueio, quem_destrava, dias_impacto) nos últimos 90 dias, "
    "ignorando 'sem_bloqueio' e 'nao_reportado'. Gente parada: utilizacao_pessoa_semana nas últimas 12 semanas, "
    "SUM(horas_apontadas) / SUM(horas_disponiveis) < 0,2.",
    "CONTRATOS: são 8 contratos de fornecedor e SaaS (CodeForge, Pixel Design Studio, QualiTest Brasil, SecureOps Segurança, "
    "DataPrime Analytics, NuvemSul Cloud, Observa360, CodeVault). contratos_resumo tem os campos estruturados "
    "(valor_anual, data_fim_vigencia, renovacao_automatica, aviso_previo_dias, multa_atraso_pct_dia, teto_multa_pct, sla, reajuste). "
    "contratos_clausulas tem o texto de cada cláusula: SEMPRE cite o número da cláusula e um trecho curto quando disser o que o contrato diz. "
    "Para valores de um contrato específico, filtre contratos_resumo por fornecedor com LIKE (ex.: fornecedor LIKE '%NuvemSul%').",
    "MULTA de fornecedor: contratos_multa_fornecedor já calcula multa_cobravel por entrega atrasada "
    "(valor × % ao dia × dias de atraso, com teto). 'Na vigência atual' / 'no contrato atual' = na_vigencia_atual = true; "
    "sem esse qualificador, informe o total e o da vigência atual. Some multa_cobravel; conte entregas com COUNT(*).",
    "AVISO PRÉVIO: contratos_avisos tem data_limite_aviso (fim da vigência menos aviso prévio), dias_ate_limite e "
    "situacao_aviso ('vencido', 'vence em até 60 dias', 'ok'). 'Já passou' = 'vencido'; 'próximos 60 dias' = "
    "'vence em até 60 dias'. Explique o que fazer com a coluna o_que_fazer (depende de renovacao_automatica).",
    "MANUAL: manual_secoes tem as 10 seções do Manual de Tecnologias da Vértice (secao_numero, titulo, texto): stack, ambientes, "
    "deploy, CHANGE FREEZE DE VAREJO (seção 4), ALOCAÇÃO DE SRE (seção 5), severidade, postmortem, STATUS SEMANAL E FAROL "
    "(seção 8), consultorias, segurança. Para 'o que o manual diz' ou 'em qual seção', devolva secao_numero, titulo e texto "
    "da seção, filtrando por titulo com LIKE.",
    "Quando citar um projeto, use projeto_id e nome (ex.: PRJ-011 · Checkout e meios de pagamento - Supermercados Bom Preço).",
]

EXEMPLOS = [
    ("Quanto a Vértice pode cobrar de multa da CodeForge?",
     f"SELECT fornecedor, ROUND(SUM(multa_cobravel), 2) AS multa_total, "
     f"ROUND(SUM(multa_cobravel) FILTER (WHERE na_vigencia_atual), 2) AS multa_na_vigencia_atual, "
     f"COUNT(*) FILTER (WHERE na_vigencia_atual) AS entregas_atrasadas_na_vigencia_atual "
     f"FROM {G}.contratos_multa_fornecedor WHERE fornecedor LIKE '%CodeForge%' GROUP BY fornecedor"),
    ("Quais contratos precisam de decisão por causa do aviso prévio?",
     f"SELECT fornecedor, data_fim_vigencia, aviso_previo_dias, data_limite_aviso, dias_ate_limite, situacao_aviso, o_que_fazer "
     f"FROM {G}.contratos_avisos WHERE situacao_aviso <> 'ok' ORDER BY dias_ate_limite"),
    ("O que o manual diz sobre o change freeze?",
     f"SELECT secao_numero, titulo, texto FROM {G}.manual_secoes WHERE titulo LIKE '%FREEZE%'"),
    ("Por que o PRJ-011 atrasou e o que o manual manda fazer?",
     f"WITH causa AS (SELECT causa_bloqueio, COUNT(*) AS semanas FROM {G}.status_estruturado "
     f"WHERE projeto_id = 'PRJ-011' AND data_status >= DATE'2026-07-18' AND causa_bloqueio NOT IN ('sem_bloqueio', 'nao_reportado') "
     f"GROUP BY causa_bloqueio) "
     f"SELECT c.causa_bloqueio, c.semanas, m.secao_numero, m.titulo, m.texto FROM causa c "
     f"LEFT JOIN {G}.manual_secoes m ON m.secao_numero = CASE c.causa_bloqueio WHEN 'falta_sre' THEN 5 "
     f"WHEN 'change_freeze' THEN 4 WHEN 'dependencia_fornecedor' THEN 9 ELSE 8 END ORDER BY c.semanas DESC"),
    ("Qual a multa por atraso e o teto no contrato da CodeForge?",
     f"SELECT r.fornecedor, r.multa_atraso_pct_dia, r.teto_multa_pct, c.clausula_numero, c.texto "
     f"FROM {G}.contratos_resumo r JOIN {G}.contratos_clausulas c ON c.fornecedor = r.fornecedor AND c.titulo LIKE 'MULTA%' "
     f"WHERE r.fornecedor LIKE '%CodeForge%'"),
    ("Tenho SRE parado que poderia ir para o PRJ-011?",
     f"SELECT colaborador_id, nome, papel, projeto_id, projeto, ROUND(SUM(horas_apontadas) / SUM(horas_disponiveis), 3) AS utilizacao, "
     f"SUM(horas_ociosas) AS horas_ociosas, SUM(custo_ocioso) AS custo_ocioso "
     f"FROM {G}.utilizacao_pessoa_semana WHERE papel = 'sre' AND semana > DATE'2026-07-24' "
     f"GROUP BY ALL HAVING SUM(horas_apontadas) / SUM(horas_disponiveis) < 0.2 ORDER BY utilizacao"),
]

PERGUNTAS = [
    "Quanto a Vértice pode cobrar de multa da CodeForge?",
    "Quais contratos precisam de decisão por causa do aviso prévio?",
    "Por que o PRJ-011 atrasou e o que o manual manda fazer?",
    "Tenho SRE parado que poderia ir para o PRJ-011?",
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
