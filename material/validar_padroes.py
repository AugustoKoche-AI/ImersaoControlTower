#!/usr/bin/env python3
"""Confere se o dataset gerado conta a história que a aula precisa.

Uso:  python3 material/validar_padroes.py --dados ./dados

Recalcula, só com a biblioteca padrão, os KPIs do PRD direto dos CSVs e
checa os 4 padrões embutidos. Sai com código 1 se algum padrão sumir:
rode depois de qualquer mudança no gerador.
"""
from __future__ import annotations

import argparse
import collections
import csv
import datetime as dt
import hashlib
import pathlib
import sys

HOJE = dt.date(2026, 10, 16)
CPI_CAINDO = ["P002", "P005", "P009", "P014", "P018", "P021", "P027", "P033"]
PARA_CHUVA = ["P003", "P011", "P024"]


def ler(base: pathlib.Path, nome: str) -> list[dict]:
    with (base / nome).open(encoding="utf-8") as f:
        return list(csv.DictReader(f))


def data(txt: str) -> dt.date:
    txt = txt.strip()
    return dt.datetime.strptime(txt, "%d/%m/%Y").date() if "/" in txt else dt.date.fromisoformat(txt)


def num(txt: str) -> float:
    return float(txt.replace(",", "."))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dados", default="./dados")
    base = pathlib.Path(ap.parse_args().dados)
    ok = True

    def checar(cond: bool, msg: str) -> None:
        nonlocal ok
        ok &= cond
        print(f"  [{'ok' if cond else 'FALHOU'}] {msg}")

    proj = {p["projeto_id"]: p for p in ler(base, "erp/projetos.csv")}
    tarefas = ler(base, "cronograma/tarefas.csv")
    avanco = ler(base, "cronograma/avanco_semanal.csv")
    custos = ler(base, "erp/custos.csv")

    vp = {t["tarefa_id"]: (t["projeto_id"], float(t["valor_planejado"]),
                           data(t["inicio_baseline"]), data(t["fim_baseline"])) for t in tarefas}

    def pv_em(pid: str, d: dt.date) -> float:
        s = 0.0
        for _, (p, v, ini, fim) in ((k, x) for k, x in vp.items() if x[0] == pid):
            f = min(1.0, max(0.0, (d - ini).days / max(1, (fim - ini).days)))
            s += v * f
        return s

    # EV acumulado por projeto em cada sexta (último pct de cada tarefa até a data)
    por_proj = collections.defaultdict(list)
    for a in avanco:
        por_proj[a["projeto_id"]].append((data(a["data_medicao"]), a["tarefa_id"], float(a["pct_concluido"])))
    ac_por = collections.defaultdict(list)
    for c in custos:
        ac_por[c["projeto_id"]].append((data(c["data"]), num(c["valor_real"])))

    def ev_ac(pid: str, d: dt.date) -> tuple[float, float]:
        ult = {}
        for dm, tid, pct in por_proj[pid]:
            if dm <= d:
                ult[tid] = pct
        ev = sum(vp[t][1] * min(p, 100) / 100 for t, p in ult.items())
        ac = sum(v for dd, v in ac_por[pid] if dd <= d)
        return ev, ac

    print(f"\nSPI e CPI acumulados em {HOJE.isoformat()} (ordenado por CPI)")
    linhas = []
    for pid, p in sorted(proj.items()):
        ev, ac = ev_ac(pid, HOJE)
        pv = pv_em(pid, HOJE)
        linhas.append((pid, p["uf"].strip().upper(), p["status"], ev / pv if pv else 0, ev / ac if ac else 0))
    for pid, uf, st, spi, cpi in sorted(linhas, key=lambda x: x[4]):
        marca = " <- CPI caindo" if pid in CPI_CAINDO else (" <- chuva PA" if pid in PARA_CHUVA else "")
        print(f"  {pid} {uf:<3} {st:<13} SPI {spi:5.2f}  CPI {cpi:5.2f}{marca}")

    print("\nPadrão 1 · CPI caindo a partir do 9º mês")
    for pid in CPI_CAINDO:
        ini = data(proj[pid]["data_inicio"])
        serie = []
        for m in (6, 9, 12, 15, 18):
            d = ini + dt.timedelta(days=int(m * 30.4))
            if d > HOJE:
                break
            ev, ac = ev_ac(pid, d)
            serie.append(ev / ac if ac else 0)
        txt = "  ".join(f"m{m}:{c:.2f}" for m, c in zip((6, 9, 12, 15, 18), serie))
        print(f"    {pid} {txt}")
        checar(len(serie) >= 3 and serie[1] >= 0.93 and serie[-1] <= 0.90, f"{pid}: CPI ≥ 0,93 no mês 9 e ≤ 0,90 hoje")

    print("\nPadrão 2 · chuva no Pará (dez–mar)")
    for pid in PARA_CHUVA:
        ini = data(proj[pid]["data_inicio"])
        d1, d2 = max(ini + dt.timedelta(days=60), dt.date(2025, 11, 28)), dt.date(2026, 4, 3)
        e1, _ = ev_ac(pid, d1)
        e2, _ = ev_ac(pid, d2)
        p1, p2 = pv_em(pid, d1), pv_em(pid, d2)
        spi_periodo = (e2 - e1) / (p2 - p1) if p2 > p1 else 0
        checar(spi_periodo < 0.75, f"{pid}: SPI do período chuvoso {spi_periodo:.2f} (< 0,75)")

    print("\nPadrão 3 · lead time real ÷ prometido por fornecedor")
    compras = ler(base, "erp/compras.csv")
    razao = collections.defaultdict(list)
    for c in compras:
        if c["data_entrega"]:
            nome = c["fornecedor"].lower()
            chave = "norte aço (4 grafias)" if "norte" in nome else c["fornecedor"]
            razao[chave].append((data(c["data_entrega"]) - data(c["data_pedido"])).days / int(c["lead_time_dias"]))
    for f, rs in sorted(razao.items(), key=lambda x: -sum(x[1]) / len(x[1])):
        print(f"    {f:<32} {sum(rs) / len(rs):.2f}  ({len(rs)} pedidos)")
    norte = razao["norte aço (4 grafias)"]
    checar(1.33 <= sum(norte) / len(norte) <= 1.47, "Norte Aço entrega com ~40% de atraso")
    atrasados = [c for c in compras if not c["data_entrega"] and data(c["data_prometida"]) < HOJE]
    print(f"    pedidos em atraso hoje: {len(atrasados)}")

    print("\nPadrão 4 · guindastes ociosos em MG × falta de guindaste no PA")
    uso = ler(base, "frota/uso_equipamentos.csv")
    corte = HOJE - dt.timedelta(weeks=12)
    for eq in ("EQ0017", "EQ0018"):
        u = [float(x["horas_operadas"]) / float(x["horas_disponiveis"]) for x in uso
             if x["equipamento_id"] == eq and data(x["semana_inicio"]) >= corte]
        checar(bool(u) and max(u) < 0.12, f"{eq}: utilização máxima {max(u) if u else 0:.0%} nas últimas 12 semanas")
    equip = ler(base, "frota/equipamentos.csv")
    guind_p011 = [e for e in equip if e["projeto_id_atual"] == "P011" and e["tipo"] == "guindaste"]
    checar(not guind_p011, "nenhum guindaste alocado na P011")
    rdo = ler(base, "rdo/rdo.csv")
    falta_g = [r for r in rdo if r["projeto_id"] == "P011" and "guindaste" in r["texto_livre"].lower()
               and data(r["data"]) >= corte]
    checar(len(falta_g) >= 15, f"RDOs da P011 citando guindaste nas últimas 12 semanas: {len(falta_g)}")

    print("\nPergunta 3 · rupturas previstas hoje (cobertura < dias até a próxima entrega prometida)")
    mat = {m["material_id"]: m for m in ler(base, "erp/materiais.csv")}
    hoje_est = {(e["projeto_id"], e["material_id"]): e for e in ler(base, "almoxarifado/estoque.csv")
                if e["data"] == HOJE.isoformat()}
    proxima = {}
    for c in compras:
        if c["status"] == "em_aberto":
            k = (c["projeto_id"], c["material_id"])
            proxima[k] = min(proxima.get(k, c["data_prometida"]), c["data_prometida"])
    rupt = []
    for k, e in hoje_est.items():
        cons = float(e["consumo_previsto_dia"])
        if cons <= 0:
            continue
        cob = float(e["saldo"]) / cons
        dias = (max(0, (dt.date.fromisoformat(proxima[k]) - HOJE).days) if k in proxima
                else int(mat[k[1]]["lead_time_contratado_dias"]))
        if cob < dias:
            rupt.append((k[0], k[1], cob))
    por_disc = collections.Counter(mat[m]["disciplina"] for _, m, _ in rupt)
    print(f"    {len(rupt)} rupturas previstas · por disciplina: {dict(por_disc)}")
    checar(20 <= len(rupt) <= 90, "quantidade de rupturas previstas plausível (20 a 90)")

    print("\nPergunta 2 · horas ociosas por obra (últimas 8 semanas)")
    ap_ = ler(base, "ponto/apontamentos.csv")
    corte8 = HOJE - dt.timedelta(weeks=8)
    ocio = collections.Counter()
    for a in ap_:
        if data(a["data"]) >= corte8:
            ocio[a["projeto_id"]] += max(0.0, float(a["horas_disponiveis"]) - float(a["horas_apontadas"]))
    for pid, h in ocio.most_common(5):
        print(f"    {pid}  {h:,.0f} h ociosas".replace(",", "."))

    print("\nRDO · palavras de causa (amostra para o ai_classify)")
    cont = collections.Counter()
    for r in rdo:
        t = r["texto_livre"].lower()
        for chave in ("chuva", "temporal", "precipitação", "guindaste", "aguardando", "falta de", "efetivo",
                      "retrabalho", "cliente", "sem ocorrências", "nenhuma"):
            if chave in t:
                cont[chave] += 1
    print("   ", dict(cont.most_common()))

    h = hashlib.sha256()
    for f in sorted(base.rglob("*")):
        if f.is_file():
            h.update(f.relative_to(base).as_posix().encode())
            h.update(f.read_bytes())
    print(f"\nsha256 do dataset: {h.hexdigest()[:16]}")
    print("\nTODOS OS PADRÕES OK" if ok else "\nALGUM PADRÃO FALHOU")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
