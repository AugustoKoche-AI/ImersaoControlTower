#!/usr/bin/env python3
"""Gera o dataset da Construtora Atlas Engenharia (EPC fictícia).

Uso:
    python3 material/gerar_dataset.py --saida ./dados --seed 42

Só biblioteca padrão. A seed é fixa: todo aluno gera exatamente os mesmos
arquivos e chega aos mesmos números.

O dado é SIMULADO, não sorteado linha a linha: cada obra avança semana a
semana com uma velocidade (chuva, falta de guindaste e equipe fraca atrasam),
cada avanço consome material e gera custo. Por isso SPI, CPI, ociosidade e
ruptura de estoque saem coerentes entre si.

Padrões embutidos (o que os KPIs precisam mostrar):
  1. 8 obras com CPI caindo a partir do 9º mês (aditivos não cobrados)
  2. chuva no Pará entre dezembro e março atrasando 3 obras
  3. a Metalúrgica Norte Aço entrega com lead time 40% acima do prometido
  4. dois guindastes de 90 t parados em MG (P007) enquanto o RDO da obra
     P011, no Pará, reclama de falta de guindaste

A sujeira também é proposital (ver material/CLAUDE.md): limpar é o
conteúdo da noite 2. NÃO conserte o gerador.
"""
from __future__ import annotations

import argparse
import csv
import datetime as dt
import math
import pathlib
import random
import shutil
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from pdf_simples import escrever_pdf  # noqa: E402

HOJE = dt.date(2026, 10, 16)          # o "hoje" do dataset (sexta-feira)
N_PROJETOS = 40
TAREFAS_POR_PROJETO = 200

CPI_CAINDO = ["P002", "P005", "P009", "P014", "P018", "P021", "P027", "P033"]
PARA_CHUVA = ["P003", "P011", "P024"]
EQUIPE_FRACA = ["P016", "P030"]
OBRA_GUINDASTE_PARADO = "P007"         # MG, guindastes ociosos
OBRA_SEM_GUINDASTE = "P011"            # PA, falta guindaste
GUINDASTES_PARADOS = ["EQ0017", "EQ0018"]
FORNECEDOR_ATRASADO = "Metalúrgica Norte Aço Ltda"
PASTAS_GERADAS = ["erp", "cronograma", "rh", "ponto", "frota", "almoxarifado", "rdo", "documentos"]
CONTRATOS_PDF = ["P002", "P005", "P007", "P011", "P014", "P018", "P024", "P033"]

# ---------------------------------------------------------------- cadastros

CLIENTES = {
    "mineracao": ["Mineração Vale do Ferro", "Serra Dourada Mineração", "Companhia Mineira Horizonte",
                  "Bauxita Norte S.A.", "Níquel Carajás Mineração"],
    "oleo_gas": ["Petro Atlântica", "Gás do Recôncavo", "Terminal Oceânico Sul", "Refinaria Guanabara Nova"],
    "agro": ["Agroindustrial Cerrado Verde", "Usina Boa Safra Bioenergia", "Cooperativa Grão Forte",
             "Etanol Pantanal", "Fertilizantes Planalto"],
}
TIPOS_OBRA = {
    "mineracao": ["Planta de beneficiamento", "Correia transportadora de minério", "Usina de pelotização",
                  "Descaracterização de barragem", "Pátio de estocagem de minério"],
    "oleo_gas": ["Unidade de tratamento de gás", "Esferas de armazenamento de GLP", "Dutovia e estação de compressão"],
    "oleo_gas_costa": ["Terminal de GNL", "Base de apoio offshore", "Píer de carregamento",
                       "Unidade de tratamento de gás", "Tancagem de derivados"],
    "agro": ["Usina de etanol de milho", "Planta de esmagamento de soja", "Armazém graneleiro",
             "Unidade de biogás", "Fábrica de fertilizantes"],
}
UFS = {
    "mineracao": ["MG", "PA", "GO", "BA", "MG", "PA"],
    "oleo_gas": ["RJ", "ES", "BA", "SP", "RJ"],
    "agro": ["MT", "GO", "MS", "SP", "MA", "PR", "MT"],
}
MUNICIPIOS = {
    "MG": ["Itabira", "Congonhas", "Paracatu", "Mariana", "Sete Lagoas"],
    "PA": ["Parauapebas", "Canaã dos Carajás", "Marabá", "Barcarena"],
    "GO": ["Catalão", "Rio Verde", "Niquelândia"],
    "BA": ["Camaçari", "Jacobina", "Candeias"],
    "RJ": ["Macaé", "Itaguaí", "Duque de Caxias"],
    "ES": ["Linhares", "Aracruz", "Anchieta"],
    "SP": ["Cubatão", "Paulínia", "Ribeirão Preto"],
    "MT": ["Sorriso", "Lucas do Rio Verde", "Primavera do Leste"],
    "MS": ["Dourados", "Três Lagoas"],
    "MA": ["São Luís", "Balsas"],
    "PR": ["Ponta Grossa", "Cascavel"],
}
# óleo e gás com píer, terminal ou base offshore só em município do litoral
COSTEIROS = {"Macaé", "Itaguaí", "Duque de Caxias", "Linhares", "Aracruz", "Anchieta", "Camaçari", "Candeias",
             "Cubatão", "São Luís", "Barcarena"}
NOMES = ["Ana", "Bruno", "Carla", "Diego", "Elisa", "Fábio", "Gabriela", "Henrique", "Isabela", "João",
         "Karina", "Leonardo", "Marina", "Nelson", "Olívia", "Paulo", "Renata", "Sérgio", "Tatiana", "Vítor"]
SOBRENOMES = ["Almeida", "Barros", "Cardoso", "Duarte", "Esteves", "Ferraz", "Gomes", "Lacerda", "Moura",
              "Nogueira", "Pacheco", "Queiroz", "Rezende", "Siqueira", "Teixeira", "Vasconcelos"]

# disciplina: (fração de início, fração de fim) do prazo baseline, peso no orçamento
DISCIPLINAS = {
    "civil": (0.00, 0.55, 0.26),
    "estrutura_metalica": (0.22, 0.70, 0.20),
    "tubulacao": (0.40, 0.86, 0.15),
    "mecanica": (0.45, 0.88, 0.14),
    "eletrica": (0.50, 0.92, 0.12),
    "instrumentacao": (0.60, 0.94, 0.07),
    "comissionamento": (0.86, 1.00, 0.06),
}
ATIVIDADES = {
    "civil": ["Escavação e reaterro", "Concretagem de fundação", "Armação de pilares", "Forma e concretagem de laje",
              "Base de equipamento", "Drenagem pluvial", "Pavimentação de acesso"],
    "estrutura_metalica": ["Montagem de pórtico", "Montagem de estrutura do galpão", "Torque de parafusos",
                           "Içamento de treliça", "Montagem de passarela", "Cobertura metálica"],
    "tubulacao": ["Pré-fabricação de spool", "Montagem de linha", "Teste hidrostático", "Soldagem de tubulação",
                  "Suportação de tubos"],
    "mecanica": ["Montagem de moinho", "Alinhamento de bomba", "Montagem de correia", "Instalação de redutor",
                 "Nivelamento de equipamento"],
    "eletrica": ["Lançamento de cabos", "Montagem de eletrocalha", "Instalação de painel CCM",
                 "Montagem de subestação", "Aterramento"],
    "instrumentacao": ["Instalação de transmissores", "Montagem de válvulas de controle", "Loop check",
                       "Lançamento de cabos de instrumentação"],
    "comissionamento": ["Testes a frio", "Testes a quente", "Partida assistida", "Punch list"],
}
# material: (descrição, unidade, disciplina, preço unitário R$, lead time dias, qtd base por R$ 20 mi)
MATERIAIS = [
    ("M001", "Cimento CP-II 50kg", "saco", "civil", 38.0, 7, 22000),
    ("M002", "Aço CA-50 vergalhão", "t", "civil", 6200.0, 15, 420),
    ("M003", "Concreto usinado fck 30", "m3", "civil", 520.0, 3, 5200),
    ("M004", "Brita 1", "m3", "civil", 110.0, 5, 3800),
    ("M005", "Compensado para forma 18mm", "chapa", "civil", 145.0, 10, 2600),
    ("M006", "Perfil laminado W 310", "t", "estrutura_metalica", 9800.0, 30, 380),
    ("M007", "Chapa grossa ASTM A36", "t", "estrutura_metalica", 8700.0, 35, 210),
    ("M008", "Parafuso estrutural ASTM A325", "un", "estrutura_metalica", 9.5, 20, 46000),
    ("M009", "Telha trapezoidal TP-40", "m2", "estrutura_metalica", 78.0, 25, 9000),
    ("M010", "Tubo aço carbono 6 pol SCH40", "m", "tubulacao", 410.0, 40, 5200),
    ("M011", "Flange 6 pol classe 150", "un", "tubulacao", 380.0, 30, 900),
    ("M012", "Curva 90 graus 6 pol", "un", "tubulacao", 260.0, 30, 1200),
    ("M013", "Válvula gaveta 6 pol", "un", "tubulacao", 4300.0, 60, 140),
    ("M014", "Eletrodo E7018", "kg", "tubulacao", 32.0, 10, 6500),
    ("M015", "Rolamento autocompensador", "un", "mecanica", 2900.0, 45, 220),
    ("M016", "Correia transportadora 48 pol", "m", "mecanica", 1450.0, 75, 1100),
    ("M017", "Redutor de velocidade", "un", "mecanica", 68000.0, 90, 14),
    ("M018", "Cabo de potência 1kV 95mm2", "m", "eletrica", 98.0, 30, 26000),
    ("M019", "Eletrocalha perfurada 300mm", "m", "eletrica", 120.0, 20, 6800),
    ("M020", "Painel CCM", "un", "eletrica", 185000.0, 90, 6),
    ("M021", "Luminária LED industrial", "un", "eletrica", 640.0, 25, 700),
    ("M022", "Transmissor de pressão", "un", "instrumentacao", 7400.0, 60, 110),
    ("M023", "Cabo de instrumentação 2x1,5mm2", "m", "instrumentacao", 14.0, 20, 32000),
    ("M024", "Válvula de controle 4 pol", "un", "instrumentacao", 38000.0, 90, 24),
    ("M025", "Óleo lubrificante ISO VG 220", "l", "comissionamento", 28.0, 10, 3500),
]
FORNECEDORES = {
    "civil": ["Cimentos Planalto", "Concreteira Rocha Firme", "Aço Brasil Distribuidora"],
    "estrutura_metalica": [FORNECEDOR_ATRASADO, FORNECEDOR_ATRASADO, "Estruturas Minas Forte"],
    "tubulacao": ["Tubos & Conexões Atlântico", "Válvulas Paulista"],
    "mecanica": ["MecParts Industrial", "Transmissão Pesada Ltda"],
    "eletrica": ["Eletro Cabos Sudeste", "Painéis Força Total"],
    "instrumentacao": ["InstruTech Automação"],
    "comissionamento": ["Lubrificantes Nacional"],
}
# a sujeira: o mesmo fornecedor digitado de quatro jeitos no ERP de compras
GRAFIAS_NORTE_ACO = [FORNECEDOR_ATRASADO, "Metalurgica Norte Aco", "METALÚRGICA NORTE AÇO LTDA",
                     "Norte Aço Metalúrgica"]
FUNCOES_EQUIPE = ["civil", "armacao", "montagem_mecanica", "estrutura_metalica", "tubulacao", "soldagem",
                  "eletrica", "instrumentacao", "andaimes"]
TIPOS_EQUIPAMENTO = [  # tipo, modelo, custo/hora, quantidade
    ("guindaste", "Guindaste 90t", 950.0, 24), ("guindaste", "Guindaste 220t", 2100.0, 8),
    ("escavadeira", "Escavadeira 30t", 380.0, 44), ("caminhao_munck", "Caminhão munck 40tm", 260.0, 38),
    ("retroescavadeira", "Retroescavadeira", 190.0, 34), ("plataforma_elevatoria", "PTA 26m", 160.0, 46),
    ("gerador", "Gerador 450kVA", 140.0, 40), ("compressor", "Compressor 750pcm", 120.0, 36),
    ("rolo_compactador", "Rolo compactador", 210.0, 30),
]


# ----------------------------------------------------------------- utilidades

def sextas(inicio: dt.date, fim: dt.date) -> list[dt.date]:
    d = inicio + dt.timedelta(days=(4 - inicio.weekday()) % 7)
    out = []
    while d <= fim:
        out.append(d)
        d += dt.timedelta(days=7)
    return out


def dias_uteis(segunda: dt.date) -> list[dt.date]:
    return [segunda + dt.timedelta(days=i) for i in range(5)]


def iso(d: dt.date | None) -> str:
    return d.isoformat() if d else ""


def br(d: dt.date) -> str:
    return d.strftime("%d/%m/%Y")


def clamp(x: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, x))


def chuvoso(uf: str, d: dt.date, rng: random.Random) -> bool:
    m = d.month
    if uf == "PA":
        p = 0.68 if m in (12, 1, 2, 3) else (0.35 if m in (4, 11) else 0.08)
    elif uf in ("MG", "GO", "MT", "MS", "SP", "RJ", "ES", "PR"):
        p = 0.32 if m in (11, 12, 1, 2, 3) else (0.12 if m in (4, 10) else 0.03)
    else:  # BA, MA
        p = 0.22 if m in (3, 4, 5, 6) else 0.06
    return rng.random() < p


def escrever_csv(caminho: pathlib.Path, cabecalho: list[str], linhas: list[list]) -> None:
    caminho.parent.mkdir(parents=True, exist_ok=True)
    with caminho.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(cabecalho)
        w.writerows(linhas)


# ----------------------------------------------------------------- simulação

def gerar(saida: pathlib.Path, seed: int) -> dict:
    rng = random.Random(seed)

    # ---- projetos -----------------------------------------------------------
    setores = ["mineracao"] * 16 + ["oleo_gas"] * 12 + ["agro"] * 12
    rng.shuffle(setores)
    projetos = []
    usados = set()
    for i in range(N_PROJETOS):
        pid = f"P{i + 1:03d}"
        setor = setores[i]
        if pid in PARA_CHUVA or pid == OBRA_SEM_GUINDASTE:
            setor, uf = "mineracao", "PA"
        elif pid == OBRA_GUINDASTE_PARADO:
            setor, uf = "mineracao", "MG"
        else:
            uf = rng.choice(UFS[setor])
            if uf == "PA":
                uf = "MG"
        if pid in CPI_CAINDO:
            inicio = dt.date(2024, 11, 1) + dt.timedelta(days=rng.randint(0, 210))
            meses = rng.randint(24, 27)
        elif pid in PARA_CHUVA:
            inicio = dt.date(2025, 3, 1) + dt.timedelta(days=rng.randint(0, 150))
            meses = rng.randint(18, 22)
        elif pid == OBRA_GUINDASTE_PARADO:
            inicio, meses = dt.date(2025, 6, 2), 20
        else:
            inicio = dt.date(2024, 10, 1) + dt.timedelta(days=rng.randint(0, 520))
            meses = rng.randint(14, 24)
        duracao = int(meses * 30.4)
        if setor == "oleo_gas":
            uf = rng.choice(["RJ", "ES", "BA", "RJ", "SP"]) if uf not in ("RJ", "ES", "BA", "SP") else uf
        municipio = rng.choice(MUNICIPIOS[uf])
        tipos = TIPOS_OBRA["oleo_gas_costa"] if (setor == "oleo_gas" and municipio in COSTEIROS) else TIPOS_OBRA[setor]
        nome = f"{rng.choice(tipos)} {municipio}"
        while nome in usados:                       # nome de obra é único na carteira
            nome = f"{rng.choice(tipos)} {municipio}" if rng.random() < 0.7 else f"{nome} - fase 2"
        usados.add(nome)
        valor = round(rng.lognormvariate(math.log(19e6), 0.45) / 1000) * 1000
        valor = clamp(valor, 6e6, 62e6)
        orcamento = round(valor * rng.uniform(0.80, 0.86), 2)
        if pid in CPI_CAINDO:
            vel = rng.uniform(0.95, 1.02)
        elif pid in EQUIPE_FRACA:
            vel = rng.uniform(0.80, 0.86)
        else:
            vel = rng.uniform(0.96, 1.05)
        projetos.append(dict(
            id=pid, setor=setor, uf=uf, municipio=municipio,
            cliente=rng.choice(CLIENTES[setor]), nome=nome,
            valor=valor, orcamento=orcamento, inicio=inicio, duracao=duracao,
            fim_baseline=inicio + dt.timedelta(days=duracao), vel=vel,
            custo_base=rng.uniform(0.96, 1.035),
            gerente=f"{rng.choice(NOMES)} {rng.choice(SOBRENOMES)}",
            engenheiro=f"{rng.choice(NOMES)} {rng.choice(SOBRENOMES)}",
        ))

    # ---- tarefas (baseline) --------------------------------------------------
    pesos_disc = [(d, v[2]) for d, v in DISCIPLINAS.items()]
    tarefas = {}  # pid -> lista de dicts
    for p in projetos:
        lista = []
        brutos = []
        for t in range(TAREFAS_POR_PROJETO):
            disc = rng.choices([d for d, _ in pesos_disc], [w for _, w in pesos_disc])[0]
            ini_f, fim_f, _ = DISCIPLINAS[disc]
            a = rng.uniform(ini_f, fim_f - 0.04)
            dur = clamp(rng.uniform(0.035, 0.16), 0.03, fim_f - a)
            brutos.append((disc, a, dur, rng.lognormvariate(0, 0.6)))
        brutos.sort(key=lambda x: (x[1], x[0]))
        soma_peso = {}
        for disc, _, _, w in brutos:
            soma_peso[disc] = soma_peso.get(disc, 0) + w
        for n, (disc, a, dur, w) in enumerate(brutos, 1):
            vp = p["orcamento"] * DISCIPLINAS[disc][2] / sum(v[2] for v in DISCIPLINAS.values()) * w / soma_peso[disc]
            lista.append(dict(
                id=f"{p['id']}-T{n:03d}", disc=disc,
                atividade=rng.choice(ATIVIDADES[disc]),
                a=a * p["duracao"], L=max(7.0, dur * p["duracao"]),
                u=rng.uniform(0.92, 1.12), vp=round(vp, 2),
                ini_real=None, fim_real=None, pct=0.0,
            ))
        tarefas[p["id"]] = lista

    # ---- simulação semanal por obra -------------------------------------------
    hist = {}        # pid -> lista de dicts por semana (sexta)
    avanco = []      # linhas de avanco_semanal
    chuva_dia = {}   # (pid, data) -> bool
    for p in projetos:
        pid = p["id"]
        tau = 0.0
        semanas = []
        concluido = None
        for sexta in sextas(p["inicio"], HOJE):
            segunda = sexta - dt.timedelta(days=4)
            dias = [d for d in dias_uteis(segunda) if d >= p["inicio"]]
            chuvas = 0
            for d in dias:
                c = chuvoso(p["uf"], d, rng)
                chuva_dia[(pid, d)] = c
                chuvas += c
            frac_chuva = chuvas / max(1, len(dias))
            pena = 0.62 if p["uf"] == "PA" else 0.18
            vel = p["vel"] * (1 - pena * frac_chuva) * rng.gauss(1, 0.06)
            sem_guindaste = pid == OBRA_SEM_GUINDASTE and sexta >= HOJE - dt.timedelta(weeks=12)
            if sem_guindaste:
                vel *= 0.72
            vel = clamp(vel, 0.15, 1.25)
            tau += 7 * vel * (len(dias) / 5)
            ev = 0.0
            ev_disc = {}
            for t in tarefas[pid]:
                antes = t["pct"]
                pct = clamp((tau - t["a"]) / (t["L"] * t["u"]), 0.0, 1.0)
                if pct > 0 and t["ini_real"] is None:
                    t["ini_real"] = segunda + dt.timedelta(days=rng.randint(0, 4))
                if pct >= 1 and t["fim_real"] is None:
                    t["fim_real"] = sexta - dt.timedelta(days=rng.randint(0, 2))
                t["pct"] = pct
                if pct != antes:
                    avanco.append([f"{t['id']}", pid, iso(sexta), round(pct * 100, 1)])
                ev += t["vp"] * pct
                ev_disc[t["disc"]] = ev_disc.get(t["disc"], 0) + t["vp"] * pct
            mes = (sexta - p["inicio"]).days / 30.4
            fator = p["custo_base"] * rng.gauss(1, 0.025)
            if pid in CPI_CAINDO and mes >= 9:
                fator += min(0.40, 0.034 * (mes - 9 + 1))
            semanas.append(dict(sexta=sexta, segunda=segunda, vel=vel, chuva=frac_chuva, ev=ev,
                                ev_disc=ev_disc, fator=fator, sem_guindaste=sem_guindaste, dias=dias))
            if all(t["pct"] >= 1 for t in tarefas[pid]):
                concluido = sexta
                break
        p["concluido"] = concluido
        hist[pid] = semanas

    # ---- custos -------------------------------------------------------------
    custos = []
    cat_pesos = [("mao_de_obra", 0.36), ("material", 0.30), ("equipamento", 0.14),
                 ("subcontrato", 0.14), ("indiretos", 0.06)]
    nlanc = 0
    for p in projetos:
        queima = p["orcamento"] * 7 / p["duracao"]
        ev_ant = 0.0
        for s in hist[p["id"]]:
            dev = s["ev"] - ev_ant
            ev_ant = s["ev"]
            ociosidade = queima * 0.30 * max(0.0, 0.95 - s["vel"])
            ac = dev * s["fator"] + ociosidade
            extra = dev * max(0.0, s["fator"] - p["custo_base"] - 0.06)  # aditivo não cobrado
            for cat, w in cat_pesos:
                valor = ac * w
                if cat == "subcontrato":
                    valor += extra * 0.5
                if cat == "mao_de_obra":
                    valor += extra * 0.2 - extra * 0.7 * w
                if valor <= 0:
                    continue
                partes = rng.randint(1, 2) if cat != "indiretos" else 1
                for k in range(partes):
                    nlanc += 1
                    v = round(valor / partes * rng.uniform(0.9, 1.1), 2)
                    d = rng.choice(s["dias"])
                    txt = f"{v:.2f}"
                    if rng.random() < 0.03:                 # sujeira: decimal com vírgula
                        txt = txt.replace(".", ",")
                    custos.append([f"L{nlanc:07d}", p["id"], iso(d), cat,
                                   f"{cat.upper()} {p['id']} semana {iso(s['segunda'])}", txt,
                                   f"CC-{p['id']}-{cat[:3].upper()}"])
                    if rng.random() < 0.015:                # estorno (é informação, não erro)
                        nlanc += 1
                        custos.append([f"L{nlanc:07d}", p["id"], iso(min(HOJE, d + dt.timedelta(days=rng.randint(3, 20)))),
                                       cat, f"ESTORNO ref L{nlanc - 1:07d}", f"{-round(v * rng.uniform(0.2, 1.0), 2):.2f}",
                                       f"CC-{p['id']}-{cat[:3].upper()}"])

    # ---- materiais, compras e estoque ------------------------------------------
    def frac_planejada(pid: str, disc: str, dia_proj: float) -> float:
        tot = sum(t["vp"] for t in tarefas[pid] if t["disc"] == disc)
        acc = sum(t["vp"] * clamp((dia_proj - t["a"]) / t["L"], 0, 1)
                  for t in tarefas[pid] if t["disc"] == disc)
        return acc / tot if tot else 0.0

    compras, estoque = [], []
    rupturas = {}   # (pid, sexta) -> lista de (material, fornecedor)
    npedido = 0
    for p in projetos:
        pid = p["id"]
        escala = p["valor"] / 20e6
        tot_disc = {d: sum(t["vp"] for t in tarefas[pid] if t["disc"] == d) for d in DISCIPLINAS}
        for mid, desc, un, disc, preco, lead, qbase in MATERIAIS:
            Q = qbase * escala * rng.uniform(0.8, 1.2)
            forn_lista = FORNECEDORES[disc]
            saldo, pendentes = 0.0, []   # pendentes: (data_entrega, qtd)
            frac_ant = 0.0
            ini_disc = p["inicio"] + dt.timedelta(days=DISCIPLINAS[disc][0] * p["duracao"] - lead - 14)
            for s in hist[pid]:
                if s["sexta"] < ini_disc:
                    continue
                frac = s["ev_disc"].get(disc, 0) / tot_disc[disc] if tot_disc[disc] else 0
                consumo = Q * max(0.0, frac - frac_ant)
                frac_ant = frac
                chegou = sum(q for d, q in pendentes if d <= s["sexta"])
                pendentes = [(d, q) for d, q in pendentes if d > s["sexta"]]
                saldo += chegou
                if consumo > saldo + 1e-9 and frac < 0.999:
                    rupturas.setdefault((pid, s["sexta"]), []).append((desc, mid))
                saldo = max(0.0, saldo - consumo)
                # previsão do planejamento: próximas 4 semanas na velocidade atual
                dia_proj = (s["sexta"] - p["inicio"]).days
                ritmo = clamp(s["vel"], 0.4, 1.1)
                prev = Q * max(0.0, frac_planejada(pid, disc, dia_proj + 28) - frac_planejada(pid, disc, dia_proj)) * ritmo / 28
                if frac < 0.999 and prev > 0:
                    alvo = prev * (lead + 21)
                    posicao = saldo + sum(q for _, q in pendentes)
                    if posicao < alvo:
                        qtd = max(alvo * 1.3 - posicao, prev * 14)
                        qtd = round(qtd) if un in ("un", "saco", "chapa") else round(qtd, 1)
                        if qtd > 0:
                            npedido += 1
                            forn = rng.choice(forn_lista)
                            fator = rng.uniform(1.30, 1.52) if forn == FORNECEDOR_ATRASADO else rng.uniform(0.85, 1.12)
                            dped = s["sexta"] - dt.timedelta(days=rng.randint(0, 3))
                            dprom = dped + dt.timedelta(days=lead)
                            dent = dped + dt.timedelta(days=round(lead * fator))
                            pendentes.append((dent, qtd))
                            grafia = rng.choice(GRAFIAS_NORTE_ACO) if forn == FORNECEDOR_ATRASADO else forn
                            entregue = dent <= HOJE
                            compras.append([f"PC{npedido:06d}", pid, mid, grafia, qtd,
                                            round(preco * rng.uniform(0.95, 1.08), 2), iso(dped), iso(dprom),
                                            iso(dent) if entregue else "", lead,
                                            "entregue" if entregue else "em_aberto"])
                if frac > 0 or saldo > 0 or pendentes:
                    s_txt = round(saldo, 1)
                    if rng.random() < 0.002:              # sujeira: saldo negativo (erro de inventário)
                        s_txt = -round(rng.uniform(1, 50), 1)
                    estoque.append([pid, mid, iso(s["sexta"]), s_txt, round(prev, 3)])

    # ---- equipes e apontamentos -----------------------------------------------
    equipes, apontamentos = [], []
    napont = 0
    for i in range(120):
        p = projetos[i % N_PROJETOS]
        eid = f"EQP{i + 1:03d}"
        funcao = FUNCOES_EQUIPE[i % len(FUNCOES_EQUIPE)]
        hc = rng.randint(6, 18)
        custo = round(rng.uniform(48, 115), 2)
        equipes.append([eid, funcao, p["uf"], custo, hc, p["id"]])
        for s in hist[p["id"]]:
            for d in s["dias"]:
                napont += 1
                disp = hc * 8.0
                util = 0.32 + 0.62 * min(s["vel"], 1.05) / 1.05 + rng.gauss(0, 0.05)
                if chuva_dia.get((p["id"], d)) and p["uf"] == "PA":
                    util -= 0.25
                if s["sem_guindaste"] and funcao in ("montagem_mecanica", "estrutura_metalica"):
                    util -= 0.30
                util = clamp(util, 0.10, 1.12)            # >1 = hora extra, é legítimo
                apontamentos.append([f"A{napont:07d}", eid, p["id"], iso(d), disp, round(disp * util, 1)])
    for eid in ("EQP014", "EQP057", "EQP101"):            # sujeira: equipe duplicada no cadastro do RH
        orig = next(e for e in equipes if e[0] == eid)
        equipes.append([eid, orig[1].upper(), orig[2].lower(), orig[3], orig[4] + 2, orig[5]])

    # ---- equipamentos e uso semanal ---------------------------------------------
    equipamentos, uso = [], []
    n = 0
    ativos = [p for p in projetos]
    for tipo, modelo, custo, qtd in TIPOS_EQUIPAMENTO:
        for _ in range(qtd):
            n += 1
            eqid = f"EQ{n:04d}"
            if eqid in GUINDASTES_PARADOS:
                p = next(x for x in projetos if x["id"] == OBRA_GUINDASTE_PARADO)
            else:
                p = ativos[rng.randrange(len(ativos))] if rng.random() > 0.07 else None
                if p and p["id"] == OBRA_SEM_GUINDASTE and tipo == "guindaste":
                    p = next(x for x in projetos if x["id"] == "P012")
            modelo_txt = modelo if eqid not in GUINDASTES_PARADOS else "Guindaste 90t"
            equipamentos.append([eqid, tipo, modelo_txt, p["id"] if p else "", p["uf"] if p else "MG",
                                 custo, "proprio" if rng.random() < 0.55 else "locado"])
            if not p:
                continue
            for s in hist[p["id"]]:
                util = clamp(rng.uniform(0.45, 0.85) * min(s["vel"], 1.05), 0.05, 1.0)
                if eqid in GUINDASTES_PARADOS and s["sexta"] >= HOJE - dt.timedelta(weeks=14):
                    util = rng.uniform(0.02, 0.09)
                uso.append([eqid, p["id"], iso(s["segunda"]), 44.0, round(44.0 * util, 1)])

    # ---- RDO (relatório diário de obra) ---------------------------------------
    rdo = []
    nrdo = 0
    frases = {
        "chuva": ["Chuva forte a partir das {h}h paralisou a frente de {ativ}.",
                  "Precipitação intensa durante o turno, serviço de {ativ} suspenso.",
                  "Temporal na região. Equipe recolhida, {ativ} sem avanço.",
                  "Solo encharcado após chuva da madrugada impediu {ativ}."],
        "falta_material": ["Frente de {ativ} parada aguardando {mat}.",
                           "Falta de {mat} no almoxarifado, {ativ} interrompida.",
                           "Fornecedor não entregou {mat} na data prometida. Equipe remanejada.",
                           "Sem {mat} em estoque; {ativ} reprogramada."],
        "falta_equipamento": ["Aguardando guindaste de 90t para içamento; {ativ} parada.",
                              "Sem guindaste disponível na obra, montagem não avançou.",
                              "Içamento adiado: guindaste ainda não mobilizado.",
                              "Equipe de montagem ociosa por falta de guindaste."],
        "mao_de_obra": ["Efetivo reduzido: {n} faltas na equipe de {ativ}.",
                        "Rotatividade alta, equipe de {ativ} incompleta.",
                        "Atraso na mobilização de soldadores qualificados."],
        "retrabalho": ["Retrabalho na {ativ} após reprovação da inspeção.",
                       "Solda reprovada no ensaio, refazendo {ativ}."],
        "cliente": ["Aguardando liberação da permissão de trabalho pelo cliente.",
                    "Interferência com a operação do cliente, frente de {ativ} bloqueada.",
                    "Cliente solicitou alteração de projeto; {ativ} suspensa."],
    }
    impactos = ["Impacto estimado: 1 dia.", "Perda de meio turno.", "Impacto estimado de {d} dias na frente.",
                "", "", "Sem impacto no caminho crítico."]
    for p in projetos:
        pid = p["id"]
        for s in hist[pid]:
            rupt = rupturas.get((pid, s["sexta"]), [])
            ativas = sorted({t["disc"] for t in tarefas[pid] if 0 < t["pct"] < 1}) or ["civil"]
            for d in s["dias"]:
                nrdo += 1
                disc = rng.choice(ativas)
                ativ = rng.choice(ATIVIDADES[disc]).lower()
                efetivo = rng.randint(40, 160)
                causa = None
                if chuva_dia.get((pid, d)) and rng.random() < (0.85 if p["uf"] == "PA" else 0.5):
                    causa = "chuva"
                elif s["sem_guindaste"] and rng.random() < 0.55:
                    causa = "falta_equipamento"
                elif rupt and rng.random() < 0.5:
                    causa = "falta_material"
                elif pid in EQUIPE_FRACA and rng.random() < 0.30:
                    causa = "mao_de_obra"
                else:
                    r = rng.random()
                    causa = ("retrabalho" if r < 0.03 else "cliente" if r < 0.06 else
                             "mao_de_obra" if r < 0.08 else None)
                clima = "chuvoso" if chuva_dia.get((pid, d)) else rng.choice(["ensolarado", "nublado", "ensolarado"])
                partes = [f"RDO {br(d)} - {pid}.", f"Clima: {clima}.", f"Efetivo: {efetivo} colaboradores.",
                          f"Atividades: {rng.choice(ATIVIDADES[disc])}; {rng.choice(ATIVIDADES[rng.choice(ativas)])}."]
                if causa:
                    mat = rng.choice(rupt)[0].lower() if rupt else "perfis metálicos"
                    partes.append("Ocorrências: " + rng.choice(frases[causa]).format(
                        h=rng.randint(9, 15), ativ=ativ, mat=mat, n=rng.randint(3, 12)))
                    partes.append(rng.choice(impactos).format(d=rng.randint(2, 4)))
                else:
                    partes.append(rng.choice(["Ocorrências: sem ocorrências.", "Sem ocorrências relevantes.",
                                              "Ocorrências: nenhuma.", "Dia produtivo, sem ocorrências."]))
                if rng.random() < 0.01:
                    partes.append("Quase acidente registrado na movimentação de carga, DDS reforçado.")
                texto = " ".join(x for x in partes if x)
                r = rng.random()
                if r < 0.006:                               # sujeira: RDO não preenchido
                    texto = rng.choice(["", "N/A", "ver RDO físico"])
                elif r < 0.03:
                    texto = texto.upper()
                rdo.append([f"RDO{nrdo:06d}", pid, iso(d), p["engenheiro"], texto])

    # ---- escrever CSVs --------------------------------------------------------
    linhas_proj = []
    for p in projetos:
        uf = p["uf"]
        r = rng.random()
        if r < 0.15:
            uf = uf.lower()                                 # sujeira: UF em caixa e com espaço
        elif r < 0.25:
            uf = f" {uf} "
        data_ini = br(p["inicio"]) if rng.random() < 0.3 else iso(p["inicio"])   # sujeira: 2 formatos
        status = "concluido" if p["concluido"] else "em_andamento"
        linhas_proj.append([p["id"], p["nome"], p["cliente"], p["setor"], uf, p["municipio"],
                            f"{p['valor']:.2f}", f"{p['orcamento']:.2f}", data_ini, iso(p["fim_baseline"]),
                            status, p["gerente"]])
    escrever_csv(saida / "erp/projetos.csv",
                 ["projeto_id", "nome_projeto", "cliente", "setor", "uf", "municipio", "valor_contrato",
                  "orcamento_custo", "data_inicio", "data_fim_baseline", "status", "gerente_projeto"], linhas_proj)

    linhas_tar = []
    for p in projetos:
        for t in tarefas[p["id"]]:
            pct = round(t["pct"] * 100, 1)
            if rng.random() < 0.006:                        # sujeira: % acima de 100
                pct = round(100 + rng.uniform(1, 18), 1)
            linhas_tar.append([t["id"], p["id"], t["disc"], t["atividade"],
                               iso(p["inicio"] + dt.timedelta(days=round(t["a"]))),
                               iso(p["inicio"] + dt.timedelta(days=round(t["a"] + t["L"]))),
                               iso(t["ini_real"]), iso(t["fim_real"]), pct, f"{t['vp']:.2f}"])
    escrever_csv(saida / "cronograma/tarefas.csv",
                 ["tarefa_id", "projeto_id", "disciplina", "descricao", "inicio_baseline", "fim_baseline",
                  "inicio_real", "fim_real", "pct_concluido", "valor_planejado"], linhas_tar)
    escrever_csv(saida / "cronograma/avanco_semanal.csv",
                 ["tarefa_id", "projeto_id", "data_medicao", "pct_concluido"], avanco)
    escrever_csv(saida / "erp/custos.csv",
                 ["lancamento_id", "projeto_id", "data", "categoria", "descricao", "valor_real", "centro_custo"],
                 custos)
    escrever_csv(saida / "erp/materiais.csv",
                 ["material_id", "descricao", "unidade", "disciplina", "preco_referencia", "lead_time_contratado_dias"],
                 [[m[0], m[1], m[2], m[3], m[4], m[5]] for m in MATERIAIS])
    escrever_csv(saida / "erp/compras.csv",
                 ["pedido_id", "projeto_id", "material_id", "fornecedor", "quantidade", "valor_unitario",
                  "data_pedido", "data_prometida", "data_entrega", "lead_time_dias", "status"], compras)
    escrever_csv(saida / "almoxarifado/estoque.csv",
                 ["projeto_id", "material_id", "data", "saldo", "consumo_previsto_dia"], estoque)
    escrever_csv(saida / "rh/equipes.csv",
                 ["equipe_id", "funcao", "uf_base", "custo_hora", "headcount", "projeto_id_atual"], equipes)
    escrever_csv(saida / "ponto/apontamentos.csv",
                 ["apontamento_id", "equipe_id", "projeto_id", "data", "horas_disponiveis", "horas_apontadas"],
                 apontamentos)
    escrever_csv(saida / "frota/equipamentos.csv",
                 ["equipamento_id", "tipo", "modelo", "projeto_id_atual", "uf_atual", "custo_hora", "propriedade"],
                 equipamentos)
    escrever_csv(saida / "frota/uso_equipamentos.csv",
                 ["equipamento_id", "projeto_id", "semana_inicio", "horas_disponiveis", "horas_operadas"], uso)
    escrever_csv(saida / "rdo/rdo.csv", ["rdo_id", "projeto_id", "data", "responsavel", "texto_livre"], rdo)

    # ---- PDFs: RDOs de amostra e contratos ------------------------------------
    amostra = [r for r in rdo if r[1] in (OBRA_SEM_GUINDASTE, OBRA_GUINDASTE_PARADO, "P024")
               and r[2] >= iso(HOJE - dt.timedelta(days=62)) and len(r[4]) > 10]
    for r in amostra:
        escrever_pdf(saida / f"documentos/rdo/{r[1]}/{r[0]}_{r[2]}.pdf", [
            ("titulo", "Construtora Atlas Engenharia - Relatório Diário de Obra"),
            ("subtitulo", f"Obra {r[1]} · Data {br(dt.date.fromisoformat(r[2]))} · Responsável: {r[3]}"),
            ("espaco", ""), ("normal", r[4]),
        ])
    for pid in CONTRATOS_PDF:
        escrever_pdf(saida / f"documentos/contratos/contrato_{pid}.pdf", contrato(next(x for x in projetos if x["id"] == pid), rng))

    return dict(projetos=len(projetos), tarefas=len(linhas_tar), avanco_semanal=len(avanco), custos=len(custos),
                compras=len(compras), estoque=len(estoque), equipes=len(equipes), apontamentos=len(apontamentos),
                equipamentos=len(equipamentos), uso_equipamentos=len(uso), rdo=len(rdo), materiais=len(MATERIAIS),
                pdf_rdo=len(amostra), pdf_contratos=len(CONTRATOS_PDF))


def contrato(p: dict, rng: random.Random) -> list[tuple[str, str]]:
    """Contrato EPC com cláusulas que mudam de obra para obra (é o que o agente precisa ler)."""
    multa_dia = rng.choice([0.05, 0.08, 0.10, 0.15])
    teto = rng.choice([5, 8, 10])
    chuva_exclui = p["id"] in ("P011", "P003", "P002", "P014")
    icamento_contratada = p["id"] not in ("P005",)
    estrutura_cliente = p["id"] == "P005"
    bonus = p["id"] in ("P018", "P033")
    reajuste = rng.choice(["IPCA", "INCC-DI"])
    retencao = rng.choice([5, 10])
    valor = f"R$ {p['valor']:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    clausulas = [
        ("CLÁUSULA 1 - OBJETO",
         f"Execução, em regime de empreitada global (EPC), das obras de {p['nome']}, no município de "
         f"{p['municipio']}/{p['uf']}, compreendendo engenharia, suprimentos, construção, montagem e comissionamento."),
        ("CLÁUSULA 2 - VALOR",
         f"O valor global do contrato é de {valor}, com medições mensais e retenção técnica de {retencao}% "
         f"de cada medição, liberada no aceite final."),
        ("CLÁUSULA 3 - PRAZO",
         f"O prazo de execução é de {p['duracao']} dias corridos, contados da ordem de serviço emitida em "
         f"{br(p['inicio'])}, com término contratual em {br(p['fim_baseline'])}."),
        ("CLÁUSULA 4 - MULTA POR ATRASO",
         f"O atraso na conclusão sujeita a CONTRATADA a multa de {str(multa_dia).replace('.', ',')}% do valor "
         f"global por dia corrido, limitada a {teto}% do valor do contrato. A multa é descontada da medição "
         f"seguinte à sua aplicação."),
        ("CLÁUSULA 5 - EVENTOS CLIMÁTICOS",
         ("Dias de chuva que excederem a média histórica mensal do INMET para a região não serão computados "
          "como atraso, desde que registrados no RDO do dia e comunicados à fiscalização em até 48 horas.")
         if chuva_exclui else
         ("Os riscos climáticos, inclusive chuvas acima da média, estão incluídos no preço e no prazo e não "
          "dão direito a prorrogação nem afastam a aplicação de multa.")),
        ("CLÁUSULA 6 - EQUIPAMENTOS DE IÇAMENTO",
         ("O fornecimento, a mobilização e a manutenção de guindastes e demais equipamentos de içamento são de "
          "responsabilidade exclusiva da CONTRATADA. A indisponibilidade de equipamento não constitui motivo "
          "para prorrogação de prazo.") if icamento_contratada else
         ("Os guindastes de grande porte (acima de 150 t) serão disponibilizados pela CONTRATANTE, mediante "
          "programação com 15 dias de antecedência.")),
        ("CLÁUSULA 7 - SUPRIMENTOS",
         ("A estrutura metálica principal será fornecida pela CONTRATANTE. Atrasos na entrega desse material "
          "dão direito à prorrogação de prazo na mesma proporção.") if estrutura_cliente else
         ("Todos os materiais e equipamentos permanentes são de fornecimento da CONTRATADA. Atrasos de "
          "fornecedores da CONTRATADA não justificam prorrogação de prazo.")),
        ("CLÁUSULA 8 - ADITIVOS",
         "Alterações de escopo solicitadas pela CONTRATANTE serão objeto de aditivo, que deve ser pleiteado "
         "pela CONTRATADA em até 30 dias do fato gerador, sob pena de preclusão do direito ao reequilíbrio."),
        ("CLÁUSULA 9 - REAJUSTE",
         f"Os preços serão reajustados anualmente pelo índice {reajuste}, tendo como data-base o mês da proposta."),
        ("CLÁUSULA 10 - BÔNUS POR ANTECIPAÇÃO",
         ("A conclusão antecipada dará à CONTRATADA bônus de 0,05% do valor global por dia de antecipação, "
          "limitado a 3%.") if bonus else "Não há bônus por antecipação neste contrato."),
        ("CLÁUSULA 11 - RELATÓRIOS",
         "A CONTRATADA entregará RDO diário e relatório semanal de avanço físico e financeiro (curva S), "
         "com indicadores SPI e CPI, até a segunda-feira seguinte."),
    ]
    blocos = [("titulo", f"CONTRATO EPC Nº ATL-{p['id']}-{p['inicio'].year}"),
              ("subtitulo", f"CONTRATANTE: {p['cliente']}  ·  CONTRATADA: Construtora Atlas Engenharia S.A."),
              ("espaco", "")]
    for titulo, texto in clausulas:
        blocos += [("subtitulo", titulo), ("normal", texto), ("espaco", "")]
    blocos += [("normal", f"{p['municipio']}, {br(p['inicio'] - dt.timedelta(days=20))}."),
               ("normal", "Documento fictício gerado para a Imersão Jornada de Dados.")]
    return blocos


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--saida", default="./dados")
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()
    saida = pathlib.Path(args.saida)
    for pasta in PASTAS_GERADAS:                    # recomeça do zero, sem sobra de execução anterior
        if (saida / pasta).exists():
            shutil.rmtree(saida / pasta)
    contagens = gerar(saida, args.seed)
    print(f"Dataset da Atlas Engenharia gerado em {saida}/ (seed {args.seed}, hoje = {HOJE.isoformat()})")
    for k, v in contagens.items():
        print(f"  {k:<18} {v:>9,}".replace(",", "."))
    return 0


if __name__ == "__main__":
    sys.exit(main())
