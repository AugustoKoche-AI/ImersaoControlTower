# Databricks notebook source
# MAGIC %md
# MAGIC # Noite 2 · Aquecimento de Python
# MAGIC ### Tudo o que você precisa antes de buscar o dado da Vértice
# MAGIC
# MAGIC Hoje o dado sai do **Supabase** (o banco dos sistemas e o storage dos arquivos) e de uma **API**, e
# MAGIC chega na bronze do Databricks. Para isso você vai usar Python em cinco situações:
# MAGIC
# MAGIC | # | O que você vai treinar | Onde isso aparece hoje |
# MAGIC |---|---|---|
# MAGIC | 1 | Variáveis e tipos | o endereço do banco, o nome da tabela |
# MAGIC | 2 | Listas | as 9 tabelas da bronze |
# MAGIC | 3 | Dicionários | cada projeto, cada feriado, cada linha que vem do banco |
# MAGIC | 4 | `for`, `if` e funções | repetir a mesma ingestão para cada tabela e cada arquivo |
# MAGIC | 5 | Bibliotecas | `requests` (API e storage), `pandas` (tabelas), `psycopg2` (banco) |
# MAGIC
# MAGIC **Como usar:** cada célula tem um objetivo. Tente sozinho primeiro; as respostas estão no
# MAGIC `00_aquecimento_python_gabarito`. Nunca programou? Os exercícios 1 a 6 levam 15 minutos.

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Variáveis e tipos
# MAGIC
# MAGIC | Tipo | O que guarda | Exemplo |
# MAGIC |---|---|---|
# MAGIC | `str` | texto | `"PRJ-011"` |
# MAGIC | `int` | número inteiro | `60` |
# MAGIC | `float` | número com decimais | `305.2` |
# MAGIC | `bool` | verdadeiro ou falso | `True` |
# MAGIC
# MAGIC **Objetivo:** criar `carteira_mi` (float, 305.2) e `em_andamento` (bool, True) e imprimir valor e tipo.

# COMMAND ----------

projeto = "PRJ-011"
total_projetos = 60
# escreva seu código aqui


print(projeto, type(projeto))
print(total_projetos, type(total_projetos))
print(carteira_mi, type(carteira_mi))
print(em_andamento, type(em_andamento))

# COMMAND ----------

# MAGIC %md
# MAGIC ### f-string: texto com variável dentro
# MAGIC
# MAGIC **Objetivo:** imprimir `A Vértice tem 60 projetos e R$ 305.2 mi de carteira.` usando as variáveis.

# COMMAND ----------

# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Listas
# MAGIC
# MAGIC Uma lista guarda vários valores em ordem, entre colchetes. `len()` conta; `[0]` pega o primeiro.
# MAGIC
# MAGIC **Objetivo:** criar a lista `ferramentas` com `"excel"`, `"clickup"` e `"msproject"`, imprimir quantas
# MAGIC são e a primeira.

# COMMAND ----------

# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Dicionários
# MAGIC
# MAGIC Um dicionário guarda pares **chave: valor**. É assim que uma API e um banco devolvem cada registro.
# MAGIC
# MAGIC **Objetivo:** criar o dicionário `prj` do PRJ-011 (cliente `"Supermercado Bom Preço"`, ferramenta
# MAGIC `"msproject"`, spi `0.77`) e imprimir só o SPI.

# COMMAND ----------

# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ### Lista de dicionários: o formato de quase toda API
# MAGIC
# MAGIC **Objetivo:** imprimir o nome de cada feriado da lista abaixo.

# COMMAND ----------

feriados = [
    {"date": "2026-11-02", "name": "Finados", "weekday": "segunda-feira"},
    {"date": "2026-11-15", "name": "Proclamação da República", "weekday": "domingo"},
    {"date": "2026-11-20", "name": "Dia da consciência negra", "weekday": "sexta-feira"},
]
# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. `for` e `if`
# MAGIC
# MAGIC **Objetivo:** contar quantos feriados da lista acima caem em **dia útil** (não é sábado nem domingo).

# COMMAND ----------

# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Funções
# MAGIC
# MAGIC Uma função é um pedaço de código com nome, para usar quantas vezes quiser.
# MAGIC
# MAGIC **Objetivo:** escrever `nome_completo(tabela)` que devolve `lakehouse_vertice.bronze.<tabela>` e usar
# MAGIC num `for` com as 9 tabelas.

# COMMAND ----------

tabelas = ["projetos", "status_semanal", "excel_tarefas", "clickup_tarefas", "msproject_tarefas",
           "colaboradores", "apontamentos", "custos", "entregas_fornecedor"]
# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ## 6. Bibliotecas
# MAGIC
# MAGIC Ninguém escreve tudo do zero. `import` traz uma biblioteca pronta.
# MAGIC
# MAGIC | Biblioteca | Para quê | Hoje |
# MAGIC |---|---|---|
# MAGIC | `requests` | conversar com a web (HTTP) | a API e o storage |
# MAGIC | `pandas` | tabela pequena, em memória | o resultado do banco |
# MAGIC | `psycopg2` | conversar com o Postgres | o banco dos sistemas |
# MAGIC | `pyspark` (`spark`) | tabela grande, no catálogo | gravar a bronze |
# MAGIC
# MAGIC **Objetivo:** importar `requests` e `pandas` e imprimir a versão de cada um.

# COMMAND ----------

# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ## 7. Consumindo uma API
# MAGIC
# MAGIC `requests.get(url)` pede; `.json()` transforma a resposta em lista e dicionário do Python.
# MAGIC
# MAGIC **Objetivo:** buscar `https://brasilapi.com.br/api/feriados/v1/2026` e imprimir quantos feriados vieram.

# COMMAND ----------

# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ## 8. pandas: a lista vira tabela
# MAGIC
# MAGIC **Objetivo:** transformar `todos` num DataFrame e mostrar só os de novembro.

# COMMAND ----------

# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ## 9. Um arquivo do storage
# MAGIC
# MAGIC O storage do Supabase entrega arquivo por URL, igual a uma API. O `manifesto.json` lista o que tem lá.
# MAGIC
# MAGIC **Objetivo:** baixar o manifesto e imprimir quantos arquivos tem em cada pasta.
# MAGIC (O endereço `STORAGE` está no README da noite 2.)

# COMMAND ----------

STORAGE = "https://COLE-AQUI.supabase.co/storage/v1/object/public/vertice"
# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ## 10. Uma tabela do banco
# MAGIC
# MAGIC **Objetivo:** conectar no banco com o usuário `aluno` e trazer 5 projetos com `pd.read_sql`.
# MAGIC (Os dados de conexão estão no README da noite 2.)

# COMMAND ----------

# MAGIC %pip install psycopg2-binary --quiet

# COMMAND ----------

import psycopg2
import pandas as pd
# escreva seu código aqui


# COMMAND ----------

# MAGIC %md
# MAGIC ## Erros comuns
# MAGIC
# MAGIC | Erro | O que é |
# MAGIC |---|---|
# MAGIC | `NameError` | usou uma variável antes de criar (rode a célula de cima) |
# MAGIC | `KeyError: 'nome'` | a chave do dicionário não existe: confira o nome exato |
# MAGIC | `IndentationError` | o espaço do começo da linha importa no Python |
# MAGIC | `ConnectionError` | sem internet: a computação é serverless? a conta está verificada? |
# MAGIC | `ModuleNotFoundError: psycopg2` | rode a célula do `%pip install` |
# MAGIC
# MAGIC Pronto. Agora os notebooks 01, 02 e 03 fazem isso de verdade, para as 9 tabelas da bronze.
