# Databricks notebook source
# MAGIC %md
# MAGIC # Noite 2 · Aquecimento de Python · gabarito

# COMMAND ----------

# MAGIC %md
# MAGIC No Databricks: **New › Notebook**, nome `00_aquecimento_python`, computação **serverless**. Cole uma célula de
# MAGIC cada vez e rode com **Shift+Enter**. Prefere com lacunas para resolver? Importe o
# MAGIC [`00_aquecimento_python.py`](00_aquecimento_python.py) (exercícios) e confira no
# MAGIC [`00_aquecimento_python_gabarito.py`](00_aquecimento_python_gabarito.py). Tente entender cada linha antes de rodar: os comentários explicam.
# MAGIC
# MAGIC ## 1. Variáveis e tipos
# MAGIC
# MAGIC Uma variável é um nome para um valor. O Python descobre o tipo sozinho; o `type()` mostra qual.

# COMMAND ----------

projeto = "PRJ-011"             # str  · texto sempre entre aspas
total_projetos = 60             # int  · número inteiro, sem aspas
carteira_mi = 305.2             # float· número com casas decimais (ponto, não vírgula)
em_andamento = True             # bool · True ou False, com inicial maiúscula

for valor in (projeto, total_projetos, carteira_mi, em_andamento):
    print(valor, type(valor))

# COMMAND ----------

# MAGIC %md
# MAGIC ### f-string
# MAGIC
# MAGIC O `f` antes das aspas liga a interpolação; o que está entre chaves é avaliado como código.

# COMMAND ----------

print(f"A Vértice tem {total_projetos} projetos e R$ {carteira_mi} mi de carteira.")

# formatando dinheiro no padrão brasileiro: milhar com ponto, centavos com vírgula
valor_contrato = 12500000.0
print(f"Contrato: R$ {valor_contrato:,.2f}".replace(",", "X").replace(".", ",").replace("X", "."))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Listas
# MAGIC
# MAGIC Uma lista guarda vários valores em ordem, entre colchetes. O índice começa em 0.

# COMMAND ----------

# os 4 projetos com o pior SPI da carteira (noite 1)
piores = ["PRJ-016", "PRJ-030", "PRJ-039", "PRJ-011"]

print(f"São {len(piores)} projetos")
print("O pior:  ", piores[0])
print("O último:", piores[-1])     # índice negativo conta de trás para frente

ferramentas = ["excel", "clickup", "msproject"]
print("ferramentas:", ferramentas)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Dicionários
# MAGIC
# MAGIC Um dicionário guarda pares **chave: valor**. É assim que uma API, um banco ou um JSON devolvem cada
# MAGIC registro: um projeto é um dicionário.

# COMMAND ----------

projeto = {
    "projeto_id": "PRJ-011",
    "nome": "Checkout e meios de pagamento",
    "ferramenta": "msproject",
    "pct_concluido": 54,      # quanto está pronto
    "pct_esperado": 70,       # quanto devia estar pronto hoje
}

spi = projeto["pct_concluido"] / projeto["pct_esperado"]
print(f"SPI do {projeto['projeto_id']}: {spi:.2f}")      # 0.77: abaixo de 1 é atraso

# COMMAND ----------

# MAGIC %md
# MAGIC ### Dicionário dentro de dicionário
# MAGIC
# MAGIC Leia de fora para dentro: `projeto["cliente"]` devolve outro dicionário, e nele pedimos `["segmento"]`.

# COMMAND ----------

projeto = {"projeto_id": "PRJ-011",
           "cliente": {"nome": "Supermercado Bom Preço", "segmento": "varejo"}}

print(projeto["cliente"]["segmento"])

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. `for` e `if`
# MAGIC
# MAGIC O `for` repete o mesmo passo para cada item; o `if` escolhe o caminho.

# COMMAND ----------

cronogramas = ["PRJ-002", "PRJ-010", "PRJ-012"]

for prj in cronogramas:
    print(f"Baixando Cronograma {prj}.xlsx do data lake...")

# COMMAND ----------

# a regra da Vértice: SPI abaixo de 0,8 é crítico; abaixo de 0,9, atenção
spis = {"PRJ-016": 0.63, "PRJ-030": 0.69, "PRJ-039": 0.75, "PRJ-011": 0.77, "PRJ-024": 0.91}

for prj, spi in spis.items():
    if spi < 0.8:
        print(f"{prj}  SPI {spi}: crítico")
    elif spi < 0.9:
        print(f"{prj}  SPI {spi}: atenção")
    else:
        print(f"{prj}  SPI {spi}: ok")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Funções
# MAGIC
# MAGIC `def` cria a função, os parâmetros vão entre parênteses e o `return` devolve o resultado. O texto entre
# MAGIC três aspas é a documentação da função. Escreveu uma vez, usa para os 60 projetos.

# COMMAND ----------

def calcular_spi(pct_concluido, pct_esperado):
    """Índice de prazo: quanto está pronto dividido por quanto devia estar. Abaixo de 1 é atraso."""
    return round(pct_concluido / pct_esperado, 2)


def situacao(spi):
    """A regra de corte da Vértice."""
    if spi < 0.8:
        return "crítico"
    if spi < 0.9:
        return "atenção"
    return "ok"


spi = calcular_spi(54, 70)
print(spi, situacao(spi))                # 0.77 crítico
print(calcular_spi(75, 100), situacao(calcular_spi(75, 100)))   # 0.75 crítico

# COMMAND ----------

# MAGIC %md
# MAGIC ## 6. Métodos: cada tipo traz as suas funções
# MAGIC
# MAGIC Um **método** é uma função que já vem grudada no valor: você escreve o valor, um **ponto** e o nome.
# MAGIC Cada tipo tem os seus: o texto sabe ficar em minúsculas, a lista sabe crescer, o dicionário sabe listar as
# MAGIC chaves. No notebook, digite o valor, o ponto e aperte **Tab** para ver todos.
# MAGIC
# MAGIC | Tipo | Métodos que você vai usar | O que fazem |
# MAGIC |---|---|---|
# MAGIC | `str` | `.lower()` `.upper()` `.strip()` `.replace(a, b)` `.split(sep)` `.startswith(x)` | minúsculas, maiúsculas, tirar espaços, trocar, quebrar, começa com |
# MAGIC | `list` | `.append(x)` `.sort()` `.count(x)` | acrescentar, ordenar, contar |
# MAGIC | `dict` | `.keys()` `.values()` `.items()` `.get(chave, padrão)` | as chaves, os valores, os pares, ler sem dar erro |
# MAGIC
# MAGIC A sujeira da Vértice, que ontem você viu no SQL, se resolve com métodos de texto:

# COMMAND ----------

# o farol do gerente veio escrito de vários jeitos
farol = "  VERDE "
print(farol.strip().lower())                   # "verde": um método depois do outro (encadeamento)

# o custo veio com vírgula decimal: para o Python, isso é texto, não número
valor = "12345,67"
print(float(valor.replace(",", ".")))          # 12345.67

# o projeto está escondido no nome do arquivo
arquivo = "Cronograma PRJ-002.xlsx"
print(arquivo.split(" ")[1].replace(".xlsx", ""))   # "PRJ-002"
print(arquivo.startswith("Cronograma"))             # True

# COMMAND ----------

# lista: acrescentar, contar e ordenar
farois = ["verde", "amarelo", "verde"]
farois.append("vermelho")                      # a lista cresce no lugar
print(farois.count("verde"))                   # 2
farois.sort()
print(farois)                                  # ['amarelo', 'verde', 'verde', 'vermelho']

# dicionário: chaves, valores e o .get, que não quebra se a chave não existir
projeto = {"projeto_id": "PRJ-011", "cliente": "Supermercado Bom Preço", "spi": 0.77}
print(list(projeto.keys()))
print(projeto.get("cpi", "sem CPI"))           # "sem CPI", em vez de KeyError
for chave, valor in projeto.items():
    print(f"{chave}: {valor}")

# COMMAND ----------

# MAGIC %md
# MAGIC **Objetivo:** a lista abaixo tem o farol de 5 status. Deixe todos iguais (sem espaço, minúsculos) e conte
# MAGIC quantos são verdes.

# COMMAND ----------

status = [" Verde", "VERDE", "verde ", "Amarelo", "vermelho"]

limpos = [s.strip().lower() for s in status]   # o mesmo método para cada item
print(limpos)
print(limpos.count("verde"), "verdes")         # 3

# COMMAND ----------

# MAGIC %md
# MAGIC > **Guarde esta ideia para o pandas:** uma tabela do pandas também tem métodos (`df.head()`,
# MAGIC > `df.describe()`) e uma coluna de texto tem os mesmos métodos do `str`, depois de um `.str`:
# MAGIC > `df["farol"].str.strip().str.lower()`. É o `.lower()` desta seção, aplicado à coluna inteira de uma vez.
# MAGIC
# MAGIC ## 7. Bibliotecas

# COMMAND ----------

import requests
import pandas as pd

print("pandas", pd.__version__)
print("requests", requests.__version__)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 8. Consumindo uma API
# MAGIC
# MAGIC A Vértice atende clientes no Brasil inteiro. A API pública do IBGE devolve os 27 estados com a região de
# MAGIC cada um. `status_code` 200 significa "deu certo"; o `raise_for_status()` interrompe a execução se vier
# MAGIC erro, o que evita seguir o pipeline com dado vazio.

# COMMAND ----------

URL_IBGE = "https://servicodados.ibge.gov.br/api/v1/localidades/estados"

resposta = requests.get(URL_IBGE, timeout=60)
resposta.raise_for_status()

estados = resposta.json()          # JSON vira lista de dicionários

print("status:", resposta.status_code)
print("estados recebidos:", len(estados))
print("primeiro:", estados[0])

# COMMAND ----------

# MAGIC %md
# MAGIC ## 9. pandas

# COMMAND ----------

# a lista de dicionários vira tabela; o json_normalize abre o dicionário "regiao" em colunas
df_estados = pd.json_normalize(estados)[["sigla", "nome", "regiao.nome"]]
df_estados = df_estados.rename(columns={"regiao.nome": "regiao"})
display(df_estados.head())

print("formato (linhas, colunas):", df_estados.shape)
print("colunas:", list(df_estados.columns))

# contagem por região: o GROUP BY do pandas
por_regiao = df_estados.groupby("regiao").size().sort_values(ascending=False)
print(por_regiao)

# filtro: o WHERE do pandas
display(df_estados[df_estados["regiao"] == "Norte"])

# COMMAND ----------

# MAGIC %md
# MAGIC ## 10. boto3: lendo arquivos do data lake
# MAGIC
# MAGIC O **boto3** é a biblioteca da AWS para falar com o **S3**, o serviço de arquivos na nuvem. O Storage do
# MAGIC **Supabase** fala o mesmo protocolo, então o mesmo código serve para os dois: muda só o `endpoint_url`.
# MAGIC
# MAGIC | Termo | O que é |
# MAGIC |---|---|
# MAGIC | **Bucket** | A pasta raiz, o "balde" |
# MAGIC | **Key** | O caminho do arquivo dentro do bucket, por exemplo `pmo/projetos.csv` |
# MAGIC | **Endpoint** | O endereço do serviço |
# MAGIC | **Access key / secret** | Usuário e senha da máquina |
# MAGIC
# MAGIC Aqui, no aquecimento, a chave fica no código para ficar simples de ver. No notebook de ingestão ela sai
# MAGIC do código e passa a chegar pelo ambiente (`os.environ`).

# COMMAND ----------

import boto3

# os valores estão na tabela de conexão, no começo deste README
S3_ENDPOINT = "https://ahebbqgjfrhrytognoew.storage.supabase.co/storage/v1/s3"
S3_REGION = "us-east-2"
S3_BUCKET = "DataLakeVertice"

ACCESS_KEY = "COLE-AQUI"     # passada na aula
SECRET_KEY = "COLE-AQUI"     # passada na aula

from botocore.config import Config

s3 = boto3.client(
    "s3",
    endpoint_url=S3_ENDPOINT,
    region_name=S3_REGION,
    aws_access_key_id=ACCESS_KEY,
    aws_secret_access_key=SECRET_KEY,
    config=Config(s3={"addressing_style": "path"}),   # o Supabase só entende o bucket no caminho da URL
)

# Listar buckets
response = s3.list_buckets()

for bucket in response["Buckets"]:
    print(bucket["Name"])

# COMMAND ----------

# MAGIC %md
# MAGIC Agora os arquivos de dentro do bucket. A resposta é um dicionário: os arquivos ficam em `Contents`, e
# MAGIC cada um tem `Key` (o nome) e `Size` (o tamanho em bytes).

# COMMAND ----------

response = s3.list_objects_v2(Bucket=S3_BUCKET)

for objeto in response["Contents"]:
    print(f"{objeto['Key']:<30} {objeto['Size']:>10,} bytes")

# a forma curta, com list comprehension
arquivos = [objeto["Key"] for objeto in response["Contents"]]
print("\narquivos:", arquivos)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 11. De bytes para tabela
# MAGIC
# MAGIC O `get_object` devolve um dicionário; o conteúdo está em `Body`, e o `.read()` transforma em bytes. O
# MAGIC pandas espera um arquivo, e o que temos são bytes na memória: o `io.BytesIO` finge ser um arquivo.

# COMMAND ----------

import io

objeto = s3.get_object(Bucket=S3_BUCKET, Key="pmo/projetos.csv")
conteudo = objeto["Body"].read()
print(f"{len(conteudo):,} bytes baixados")

df_projetos = pd.read_csv(io.BytesIO(conteudo))
print(df_projetos.shape)
display(df_projetos.head())

# COMMAND ----------

# MAGIC %md
# MAGIC ## Erros comuns neste aquecimento
# MAGIC
# MAGIC | Erro | O que aconteceu |
# MAGIC |---|---|
# MAGIC | `IndentationError` | Faltou o recuo de 4 espaços dentro do `for`, do `if` ou da função |
# MAGIC | `NameError: name 'x' is not defined` | A variável não existe: você rodou a célula fora de ordem |
# MAGIC | `KeyError: 'regiao'` | A chave não existe no dicionário; confira a grafia |
# MAGIC | `KeyError: 'Contents'` | O bucket está vazio ou o nome está errado |
# MAGIC | `ConnectionError` ao chamar a API | Conta do Databricks ainda não verificada |
# MAGIC | `EndpointConnectionError` | Endpoint errado; confira o endereço do Storage |
# MAGIC | `InvalidAccessKeyId` / `SignatureDoesNotMatch` | Chave ou segredo errados |
# MAGIC
# MAGIC ## Fechando o aquecimento
# MAGIC
# MAGIC Se você resolveu os 11 exercícios, tem tudo o que precisa para a aula:
# MAGIC
# MAGIC - sabe guardar valores e percorrer listas;
# MAGIC - entende a resposta de uma API e a de um storage S3;
# MAGIC - sabe transformar bytes em tabela com o pandas;
# MAGIC - conhece as bibliotecas que o pipeline usa.
# MAGIC
# MAGIC Siga para o **`01_ingestao_api`**: a primeira ingestão da noite, a dos feriados.
