# Databricks notebook source
# MAGIC %md
# MAGIC # Noite 1 · Carregar os dados da Atlas Engenharia
# MAGIC
# MAGIC Rode este notebook **uma vez**, de cima para baixo (botão **Run all**). Ele:
# MAGIC
# MAGIC 1. cria o catálogo `lakehouse_atlas`, os schemas `bronze`, `silver`, `gold` e o volume `bronze.raw`
# MAGIC 2. gera os arquivos dos sistemas da obra **direto no volume** (ERP, cronograma, ponto, frota, almoxarifado, RDO e os PDFs)
# MAGIC 3. confere que os 4 padrões da história estão lá
# MAGIC
# MAGIC Nada para baixar nem subir: o gerador está neste repositório (`material/gerar_dataset.py`) e a seed é fixa,
# MAGIC então o seu dado é **idêntico** ao do instrutor.
# MAGIC
# MAGIC > Para abrir este notebook você clonou o repositório como **Git folder**
# MAGIC > (Workspace → Create → Git folder → `https://github.com/lvgalvao/ImersaoControlTower`).

# COMMAND ----------

dbutils.widgets.text("catalogo", "lakehouse_atlas")
CATALOGO = dbutils.widgets.get("catalogo")

import os, pathlib, sys

AULA = pathlib.Path(os.getcwd())                 # a pasta deste notebook dentro do Git folder
RAIZ = AULA.parents[1]
print("repositório em", RAIZ)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. O catálogo
# MAGIC Roda o `00-setup-catalogo.sql`, o mesmo arquivo que dá para rodar no SQL Editor.

# COMMAND ----------

sql = (AULA / "00-setup-catalogo.sql").read_text(encoding="utf-8").replace("lakehouse_atlas", CATALOGO)
comandos = [c.strip() for c in sql.split(";")
            if any(l.strip() and not l.strip().startswith("--") for l in c.splitlines())]
for c in comandos:
    spark.sql(c)
    print("ok:", next(l for l in c.splitlines() if l.strip() and not l.strip().startswith("--"))[:80])

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Os arquivos dos sistemas, direto no volume

# COMMAND ----------

sys.path.insert(0, str(RAIZ / "material"))
import gerar_dataset

destino = pathlib.Path(f"/Volumes/{CATALOGO}/bronze/raw")
for pasta in gerar_dataset.PASTAS_GERADAS:
    if (destino / pasta).exists():
        import shutil
        shutil.rmtree(destino / pasta)
contagens = gerar_dataset.gerar(destino, seed=42)
for k, v in contagens.items():
    print(f"{k:<18} {v:>9,}".replace(",", "."))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Conferência: a história está no dado?
# MAGIC Recalcula SPI e CPI direto dos arquivos e checa os 4 padrões
# MAGIC (CPI caindo, chuva no Pará, fornecedor atrasado, guindaste parado).

# COMMAND ----------

import subprocess
r = subprocess.run([sys.executable, str(RAIZ / "material" / "validar_padroes.py"), "--dados", str(destino)],
                   capture_output=True, text=True)
print(r.stdout[-2500:])
assert r.returncode == 0, r.stderr or "algum padrão falhou"

# COMMAND ----------

# MAGIC %md
# MAGIC ## Pronto
# MAGIC Agora abra o **`01-ingestao-bronze.sql`** no SQL Editor e rode tudo: os arquivos viram as 12 tabelas da bronze.
