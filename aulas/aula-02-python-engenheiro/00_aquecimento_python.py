# Databricks notebook source
# MAGIC %md
# MAGIC # Noite 2 · Aquecimento de Python
# MAGIC ### Tudo o que você precisa saber antes do pipeline
# MAGIC
# MAGIC Hoje o dado vai sair do **data lake** (o Storage do Supabase, que fala o protocolo S3) e chegar no
# MAGIC Databricks. Para isso você vai usar Python em cinco situações, e este notebook treina essas cinco.
# MAGIC
# MAGIC | # | O que você vai treinar | Onde isso aparece na aula |
# MAGIC |---|---|---|
# MAGIC | 1 | Variáveis e tipos | Guardar o endpoint, o bucket, o nome do arquivo |
# MAGIC | 2 | Listas | A lista das 4 tabelas que o pipeline processa |
# MAGIC | 3 | Dicionários | A resposta de uma API vira dicionário |
# MAGIC | 4 | `for` e funções | Repetir a mesma ingestão para cada arquivo |
# MAGIC | 5 | Bibliotecas | `requests` (API), `boto3` (arquivos no S3), `pandas` (tabelas) |
# MAGIC
# MAGIC **Como usar:** cada célula tem um objetivo e um espaço para você escrever. Tente sozinho primeiro. O
# MAGIC notebook `00_aquecimento_python_gabarito` tem todas as respostas comentadas.
# MAGIC
# MAGIC > Nunca programou em Python? Sem problema. Os exercícios 1 a 6 são de aquecimento e levam 15 minutos.

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Variáveis e tipos
# MAGIC
# MAGIC Uma variável é um nome para um valor. O Python descobre o tipo sozinho; o `type()` mostra qual.
# MAGIC
# MAGIC | Tipo | O que guarda | Exemplo |
# MAGIC |---|---|---|
# MAGIC | `str` | texto | `"PRJ-011"` |
# MAGIC | `int` | número inteiro | `60` |
# MAGIC | `float` | número com decimais | `305.2` |
# MAGIC | `bool` | verdadeiro ou falso | `True` |
# MAGIC
# MAGIC **Objetivo:** criar `carteira_mi` (float, 305.2) e `em_andamento` (bool, True) e imprimir o valor e o tipo
# MAGIC de cada uma.

# COMMAND ----------

projeto = "PRJ-011"
total_projetos = 60
# escreva seu código aqui: crie carteira_mi (float) e em_andamento (bool)


print(projeto, type(projeto))
print(total_projetos, type(total_projetos))

# COMMAND ----------

# MAGIC %md
# MAGIC ### f-string: juntando texto e variável
# MAGIC
# MAGIC A letra `f` antes das aspas permite colocar variáveis dentro do texto, entre chaves.
# MAGIC
# MAGIC **Objetivo:** imprimir a frase `A Vértice tem 60 projetos e R$ 305.2 mi de carteira.` usando as variáveis.

# COMMAND ----------

# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Listas
# MAGIC
# MAGIC Uma lista guarda vários valores em ordem, entre colchetes. O índice começa em 0; `[-1]` é o último.
# MAGIC
# MAGIC **Objetivo:** com a lista dos 4 projetos de pior SPI, imprimir quantos são, o primeiro e o último.

# COMMAND ----------

piores = ["PRJ-016", "PRJ-030", "PRJ-039", "PRJ-011"]

# escreva seu código aqui: len(), piores[0] e piores[-1]


# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Dicionários
# MAGIC
# MAGIC Um dicionário guarda pares **chave: valor**. É assim que uma API, um banco ou um JSON devolvem cada
# MAGIC registro: um projeto é um dicionário.
# MAGIC
# MAGIC **Objetivo:** calcular o SPI do projeto (quanto está pronto ÷ quanto devia estar) e imprimir
# MAGIC `SPI do PRJ-011: 0.77`.

# COMMAND ----------

projeto = {
    "projeto_id": "PRJ-011",
    "nome": "Checkout e meios de pagamento",
    "ferramenta": "msproject",
    "pct_concluido": 54,
    "pct_esperado": 70,
}

# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ### Dicionário dentro de dicionário
# MAGIC
# MAGIC Leia de fora para dentro: `projeto["cliente"]` devolve outro dicionário.
# MAGIC
# MAGIC **Objetivo:** imprimir o segmento do cliente (`varejo`).

# COMMAND ----------

projeto = {"projeto_id": "PRJ-011",
           "cliente": {"nome": "Supermercado Bom Preço", "segmento": "varejo"}}

# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. `for`: repetindo o mesmo passo
# MAGIC
# MAGIC **Objetivo:** para cada projeto da lista, imprimir `Baixando Cronograma PRJ-002.xlsx do data lake...`.

# COMMAND ----------

cronogramas = ["PRJ-002", "PRJ-010", "PRJ-012"]

# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ### `if`: escolhendo o caminho
# MAGIC
# MAGIC A regra da Vértice: SPI abaixo de 0,8 é **crítico**; abaixo de 0,9, **atenção**; o resto, **ok**.
# MAGIC
# MAGIC **Objetivo:** percorrer o dicionário com `.items()` e imprimir a situação de cada projeto.

# COMMAND ----------

spis = {"PRJ-016": 0.63, "PRJ-030": 0.69, "PRJ-039": 0.75, "PRJ-011": 0.77, "PRJ-024": 0.91}

# escreva seu código aqui: for prj, spi in spis.items(): ... if / elif / else


# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Funções
# MAGIC
# MAGIC `def` cria a função, os parâmetros vão entre parênteses e o `return` devolve o resultado. Escreveu uma vez,
# MAGIC usa para os 60 projetos.
# MAGIC
# MAGIC **Objetivo:** escrever `calcular_spi(pct_concluido, pct_esperado)`, que devolve o SPI com 2 casas, e
# MAGIC `situacao(spi)`, que devolve `"crítico"`, `"atenção"` ou `"ok"`. Teste com `calcular_spi(54, 70)`.

# COMMAND ----------

# escreva seu código aqui


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

# escreva seu código aqui: use .strip(), .lower() e .count()


# COMMAND ----------

# MAGIC %md
# MAGIC > **Guarde esta ideia para o pandas:** uma tabela do pandas também tem métodos (`df.head()`,
# MAGIC > `df.describe()`) e uma coluna de texto tem os mesmos métodos do `str`, depois de um `.str`:
# MAGIC > `df["farol"].str.strip().str.lower()`. É o `.lower()` desta seção, aplicado à coluna inteira de uma vez.

# COMMAND ----------

# MAGIC %md
# MAGIC ## 7. Bibliotecas
# MAGIC
# MAGIC Biblioteca é código pronto que alguém escreveu. Você importa e usa. As quatro de hoje:
# MAGIC
# MAGIC | Biblioteca | Serve para |
# MAGIC |---|---|
# MAGIC | `requests` | Conversar com APIs pela internet |
# MAGIC | `pandas` | Trabalhar com tabelas em memória (DataFrame) |
# MAGIC | `boto3` | Ler e gravar arquivos em storage compatível com S3 |
# MAGIC | `io` | Tratar bytes da memória como se fossem arquivo |
# MAGIC
# MAGIC **Objetivo:** importar `requests` e `pandas` e imprimir a versão do pandas (`pd.__version__`).

# COMMAND ----------

# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ## 8. Consumindo uma API
# MAGIC
# MAGIC Uma **API** é uma porta que um sistema abre para outros pedirem dados. Você faz uma requisição HTTP `GET`
# MAGIC em uma URL e recebe a resposta, quase sempre em **JSON**, que em Python vira lista e dicionário.
# MAGIC
# MAGIC A Vértice atende clientes no Brasil inteiro. A API pública do IBGE devolve os 27 estados com a região:
# MAGIC
# MAGIC ```
# MAGIC GET https://servicodados.ibge.gov.br/api/v1/localidades/estados
# MAGIC ```
# MAGIC
# MAGIC **Objetivo:** fazer a requisição, conferir se o status é `200` (deu certo), transformar em lista de
# MAGIC dicionários com `.json()` e imprimir quantos estados vieram e o primeiro deles.
# MAGIC
# MAGIC > Se der erro de conexão, sua conta do Databricks ainda não foi verificada. Veja o `README.md` desta pasta.

# COMMAND ----------

import requests

URL_IBGE = "https://servicodados.ibge.gov.br/api/v1/localidades/estados"

# escreva seu código aqui: resposta = requests.get(...), veja resposta.status_code e resposta.json()


# COMMAND ----------

# MAGIC %md
# MAGIC Rode esta célula: ela transforma a lista de estados numa tabela do pandas. O `json_normalize` abre o
# MAGIC dicionário `regiao` em colunas.

# COMMAND ----------

import pandas as pd

df_estados = pd.json_normalize(estados)[["sigla", "nome", "regiao.nome"]]
df_estados = df_estados.rename(columns={"regiao.nome": "regiao"})
display(df_estados.head())


# COMMAND ----------

# MAGIC %md
# MAGIC ## 9. pandas: a tabela em memória
# MAGIC
# MAGIC Um **DataFrame** é uma tabela: tem colunas com nome e tipo. Comandos que você vai usar sempre:
# MAGIC
# MAGIC | Comando | O que faz |
# MAGIC |---|---|
# MAGIC | `df.head()` | Primeiras linhas |
# MAGIC | `df.shape` | (linhas, colunas) |
# MAGIC | `df.columns` | Nomes das colunas |
# MAGIC | `df["coluna"]` | Uma coluna |
# MAGIC | `df[df["coluna"] > 10]` | Filtro (o `WHERE` do SQL) |
# MAGIC | `df.groupby("col")["outra"].sum()` | Agrupar e somar (o `GROUP BY` do SQL) |
# MAGIC
# MAGIC **Objetivo:** com o DataFrame de estados, contar quantos estados existem em cada região.

# COMMAND ----------

# escreva seu código aqui


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

# Objetivo: criar o cliente S3 e listar os buckets, para conferir que a conexão funciona.
# Dica: s3.list_buckets() devolve um dicionário; os buckets estão em ["Buckets"], cada um com "Name".

import boto3

# os valores estão na tabela de conexão, no README da noite 2
S3_ENDPOINT = "https://ahebbqgjfrhrytognoew.storage.supabase.co/storage/v1/s3"
S3_REGION = "us-east-2"
S3_BUCKET = "DataLakeVertice"

ACCESS_KEY = "COLE-AQUI"     # passada na aula
SECRET_KEY = "COLE-AQUI"     # passada na aula

# escreva seu código aqui: s3 = boto3.client(...) e depois liste os buckets
# atenção: o Supabase exige o bucket no caminho da URL. Passe também:
#   from botocore.config import Config
#   config=Config(s3={"addressing_style": "path"})


# COMMAND ----------

# MAGIC %md
# MAGIC **Objetivo:** listar os arquivos do bucket `DataLakeVertice`, imprimindo o nome e o tamanho de cada um.
# MAGIC
# MAGIC Dica: `s3.list_objects_v2(Bucket=S3_BUCKET)["Contents"]`, onde cada item tem `"Key"` e `"Size"`.

# COMMAND ----------

# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ## 11. De bytes para tabela
# MAGIC
# MAGIC O `get_object` devolve um dicionário; o conteúdo está em `Body`, e o `.read()` transforma em **bytes**.
# MAGIC O pandas espera um arquivo, e o que temos são bytes na memória: o `io.BytesIO` finge ser um arquivo.
# MAGIC
# MAGIC **Objetivo:** baixar `pmo/projetos.csv`, imprimir quantos bytes vieram, transformar em DataFrame e mostrar
# MAGIC as primeiras linhas.

# COMMAND ----------

import io

# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ## Fechando o aquecimento
# MAGIC
# MAGIC Se você resolveu os 10 exercícios, tem tudo o que precisa para a aula:
# MAGIC
# MAGIC - sabe guardar valores e percorrer listas;
# MAGIC - entende a resposta de uma API e a de um storage S3;
# MAGIC - sabe transformar bytes em tabela com o pandas;
# MAGIC - conhece as bibliotecas que o pipeline usa.
# MAGIC
# MAGIC Siga para o **`01_ingestao_raw`**, onde todos os arquivos do data lake vão para o raw e viram a bronze.
