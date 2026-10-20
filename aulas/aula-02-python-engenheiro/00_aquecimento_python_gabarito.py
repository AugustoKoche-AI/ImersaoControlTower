# Databricks notebook source
# MAGIC %md
# MAGIC # Noite 2 · Aquecimento de Python · gabarito

# COMMAND ----------

# MAGIC %md
# MAGIC No Databricks: **New › Notebook**, nome `00_aquecimento_python`, computação **serverless**. Cole uma célula de
# MAGIC cada vez e rode com **Shift+Enter**. Tente entender cada linha antes de rodar: os comentários explicam.
# MAGIC
# MAGIC ## 1. Variáveis e tipos

# COMMAND ----------

nome_tabela = "vendas"          # str  · texto sempre entre aspas
total_vendas = 3020             # int  · número inteiro, sem aspas
receita_total = 974077.28       # float· número com casas decimais (ponto, não vírgula)
pipeline_ativo = True           # bool · True ou False, com inicial maiúscula

for valor in (nome_tabela, total_vendas, receita_total, pipeline_ativo):
    print(valor, type(valor))

# COMMAND ----------

# MAGIC %md
# MAGIC ### f-string
# MAGIC
# MAGIC O `f` antes das aspas liga a interpolação; o que está entre chaves é avaliado como código.

# COMMAND ----------

print(f"A tabela {nome_tabela} tem {total_vendas} linhas.")

# formatando número: milhar com ponto e 2 casas decimais
print(f"Receita: R$ {receita_total:,.2f}".replace(",", "X").replace(".", ",").replace("X", "."))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Listas

# COMMAND ----------

tabelas = ["vendas", "produtos", "clientes", "preco_competidores"]

print(f"São {len(tabelas)} tabelas")
print("Primeira:", tabelas[0])
print("Última:  ", tabelas[-1])     # índice negativo conta de trás para frente

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Dicionários

# COMMAND ----------

venda = {
    "id_venda": "sal_adff6978b0c6",
    "canal": "loja_fisica",
    "quantidade": 2,
    "preco_unitario": 64.79,
}

receita = venda["quantidade"] * venda["preco_unitario"]
print(f"Receita da venda {venda['id_venda']}: R$ {receita:.2f}")

# COMMAND ----------

# MAGIC %md
# MAGIC ### Dicionário dentro de dicionário
# MAGIC
# MAGIC Leia de fora para dentro: `estado["regiao"]` devolve outro dicionário, e nele pedimos `["nome"]`.

# COMMAND ----------

estado = {"sigla": "AM", "nome": "Amazonas", "regiao": {"id": 1, "sigla": "N", "nome": "Norte"}}

print(estado["regiao"]["nome"])

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. `for` e `if`

# COMMAND ----------

tabelas = ["vendas", "produtos", "clientes", "preco_competidores"]

for tabela in tabelas:
    print(f"Baixando {tabela}.parquet do data lake...")

# COMMAND ----------

quantidades = [1, 3, 2, 5, 1]

for quantidade in quantidades:
    if quantidade > 2:
        print(f"{quantidade} unidades: venda grande")
    else:
        print(f"{quantidade} unidades: venda pequena")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Funções
# MAGIC
# MAGIC `def` cria a função, os parâmetros vão entre parênteses e o `return` devolve o resultado. O texto entre
# MAGIC três aspas é a documentação da função.

# COMMAND ----------

def calcular_receita(quantidade, preco_unitario):
    """Receita de uma venda, arredondada em 2 casas."""
    return round(quantidade * preco_unitario, 2)


print(calcular_receita(2, 64.79))      # 129.58
print(calcular_receita(1, 1286.09))    # 1286.09

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
# MAGIC `status_code` 200 significa "deu certo". O `raise_for_status()` interrompe a execução se vier erro, o que
# MAGIC evita seguir o pipeline com dado vazio.

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
# MAGIC > Na aula a chave fica no notebook, para ser simples de ver. Em produção ela sai daqui e vai para o
# MAGIC > secret scope do Databricks, o que entra amanhã.

# COMMAND ----------

import boto3

# copie do Supabase: Project Settings → Storage → S3 access keys
S3_ENDPOINT = "https://COLE-AQUI.storage.supabase.co/storage/v1/s3"
S3_REGION = "COLE-AQUI"
S3_BUCKET = "vertice"

ACCESS_KEY = "XXXX"
SECRET_KEY = "XXXX"

s3 = boto3.client(
    "s3",
    endpoint_url=S3_ENDPOINT,
    region_name=S3_REGION,
    aws_access_key_id=ACCESS_KEY,
    aws_secret_access_key=SECRET_KEY,
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
# MAGIC ## Erros comuns neste esquenta
# MAGIC
# MAGIC | Erro | O que aconteceu |
# MAGIC |---|---|
# MAGIC | `IndentationError` | Faltou o recuo de 4 espaços dentro do `for`, do `if` ou da função |
# MAGIC | `NameError: name 'x' is not defined` | A variável não existe: você rodou a célula fora de ordem |
# MAGIC | `KeyError: 'regiao'` | A chave não existe no dicionário; confira a grafia |
# MAGIC | `KeyError: 'Contents'` | O bucket está vazio ou o nome está errado |
# MAGIC | `ModuleNotFoundError` | Biblioteca não instalada: rode `%pip install <nome>` |
# MAGIC | `ConnectionError` ao chamar a API | Conta do Databricks ainda não verificada |
# MAGIC | `EndpointConnectionError` | Endpoint errado; confira o endereço do Storage |
# MAGIC | `InvalidAccessKeyId` / `SignatureDoesNotMatch` | Chave ou segredo errados |
# MAGIC
# MAGIC ## Fechando o esquenta
# MAGIC
# MAGIC Se você resolveu os 11 exercícios, tem tudo o que precisa para a aula:
# MAGIC
# MAGIC - sabe guardar valores e percorrer listas;
# MAGIC - entende a resposta de uma API e a de um storage S3;
# MAGIC - sabe transformar bytes em tabela com o pandas;
# MAGIC - conhece as bibliotecas que o pipeline usa.
# MAGIC
# MAGIC Siga para o **`01_ingestao_api`**: a primeira ingestão da noite, a dos feriados.
