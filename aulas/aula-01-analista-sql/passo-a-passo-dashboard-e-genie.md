# Passo a passo · Dashboard e Genie da noite 1 (pela interface)

Tudo aqui é clique, cópia e cola. Antes de começar, rode o **exemplo 05** (ele cria a view
`bronze.rascunho_tarefas`, que junta as 3 ferramentas e que o dashboard lê).

---

## Parte 1 · O dashboard "Projeto Farol · Noite 1 (bronze)" (~15 min)

### 1. Criar o dashboard

1. Menu da esquerda → **Dashboards** → **Create dashboard** (canto superior direito).
2. Clique no nome "New dashboard" lá em cima e troque para **Projeto Farol · Noite 1 (bronze)**.

Um dashboard tem duas partes: a aba **Data** (as consultas SQL, chamadas de *datasets*) e as páginas do
**canvas** (os gráficos, que leem os datasets).

### 2. Criar os 2 datasets (aba Data)

1. Clique na aba **Data** → **+ Create from SQL**.
2. Cole o conteúdo de [`dashboard-dataset-projetos.sql`](dashboard-dataset-projetos.sql) e clique **Run**.
   Devem aparecer **41 linhas**, uma por projeto em andamento, com SPI, CPI, situação, estouro previsto…
3. Clique no nome do dataset e troque para **Projetos em andamento**.
4. De novo **+ Create from SQL**, cole [`dashboard-dataset-custos.sql`](dashboard-dataset-custos.sql), **Run** e
   renomeie para **Custos por mês**.

> Repare no SQL do primeiro dataset: `CAST`, `replace`, `try_to_date` em toda coluna. É o preço de ler a bronze.
> Na noite 2 esse SQL encolhe para 3 linhas, porque a limpeza passa a morar na silver.

### 3. Criar os gráficos (canvas)

Volte para a página do canvas.

**O jeito rápido: um prompt para o dashboard inteiro.** Com os 2 datasets criados, abra o **Assistant** no canvas
e cole:

```
Monte um dashboard da carteira de projetos usando os datasets "Projetos em andamento"
e "Custos por mês". No topo, 4 contadores: a soma de valor_contrato (título "Carteira
em andamento", em reais), a soma de em_risco ("Projetos com SPI ou CPI < 0,9"), a soma
de critico ("Projetos críticos (< 0,8)") e a soma de melancia ("Farol verde com
SPI < 0,9"). Embaixo, à esquerda, barras horizontais com o SPI de cada projeto, do
menor para o maior, cor pela situacao. À direita, barras empilhadas com a quantidade
de projetos por ferramenta, cor pela situacao. Depois, barras empilhadas do custo
(soma de valor) por mês, cor pela categoria, do dataset "Custos por mês". No fim, uma
tabela com projeto, cliente, ferramenta, spi, cpi, situacao, farol, estouro_previsto
e atraso_projetado_dias, ordenada por spi.
```

Confira os gráficos. Se algum sair diferente, refaça só ele com o prompt da tabela abaixo.

**Gráfico por gráfico:** na barra de baixo, **Add a visualization**, e solte o quadro na página. Dá para montar de
dois jeitos:

- **Com o assistente:** no quadro novo, digite o prompt da tabela abaixo e aperte Enter. O Databricks Assistant
  escolhe o tipo de gráfico e os campos. Confira e ajuste no painel da direita.
- **À mão:** no painel da direita, escolha o **Dataset**, a **Visualization** e os campos.

| # | Gráfico | Prompt para o assistente | À mão (painel da direita) |
|---|---|---|---|
| 1 | Carteira em andamento | `Contador com a soma de valor_contrato, em reais, título "Carteira em andamento"` | Counter · Value: SUM(valor_contrato) |
| 2 | Projetos em risco | `Contador com a soma de em_risco, título "Projetos com SPI ou CPI < 0,9"` | Counter · Value: SUM(em_risco) |
| 3 | Críticos | `Contador com a soma de critico, título "Projetos críticos (< 0,8)"` | Counter · Value: SUM(critico) |
| 4 | Melancias | `Contador com a soma de melancia, título "Farol verde com SPI < 0,9"` | Counter · Value: SUM(melancia) |
| 5 | SPI por projeto | `Barras horizontais com o SPI de cada projeto, do menor para o maior, cor pela situacao` | Bar · Y: projeto · X: MIN(spi) · Color: situacao |
| 6 | Por ferramenta | `Barras empilhadas com a quantidade de projetos por ferramenta, cor pela situacao` | Bar · X: ferramenta · Y: COUNT(projeto_id) · Color: situacao |
| 7 | Custo por mês | `Barras empilhadas do custo (soma de valor) por mês, cor pela categoria, dataset Custos por mês` | Bar · X: mes (mensal) · Y: SUM(valor) · Color: categoria |
| 8 | Tabela | `Tabela com projeto, cliente, ferramenta, spi, cpi, situacao, farol, estouro_previsto e atraso_projetado_dias` | Table · as 9 colunas |

**Os números que devem aparecer:** carteira **R$ 208,6 mi** · **17** em risco · **7** críticos · **4** melancias.

Dicas:
- Clique numa barra do gráfico 5: o resto da página filtra junto (todos leem o mesmo dataset).
- **Add a text box** (barra de baixo) para pôr títulos de seção, em Markdown.

### 4. Publicar

**Publish** (canto superior direito) → **Publish**. O link "View published" é o que a diretoria abre: ela vê o
painel sem poder editar.

> **Atalho do instrutor:** o mesmo dashboard está como código em
> [`dashboard-bronze.lvdash.json`](dashboard-bronze.lvdash.json). Para recriar igual:
> `python3 aulas/aula-01-analista/gerar_dashboard.py --deploy --profile SEU-PERFIL`.

---

## Parte 2 · O Genie "Farol · Noite 1 (bronze, sem curadoria)" (~10 min)

### 1. Criar o Genie

1. Menu da esquerda → **Genie** (aparece como *Genie Agents*) → **+ New**.
2. Em **Connect your data**, escolha `lakehouse_vertice` → `bronze` e marque estas 8 tabelas:
   `projetos`, `status_semanal`, `excel_tarefas`, `clickup_tarefas`, `msproject_tarefas`, `colaboradores`,
   `apontamentos`, `custos`.
3. **Create**. Renomeie (clique no título) para **Farol · Noite 1 (bronze, sem curadoria)**.

Não escreva nenhuma instrução. É de propósito: hoje a gente quer ver o que ele faz sozinho.

### 2. Faça as 4 perguntas do dono (copie e cole, uma de cada vez)

```
Quais projetos estão atrasados, e de quais clientes?
```
```
Quanto esse atraso vai me custar?
```
```
Tenho gente parada enquanto outro projeto pede gente?
```
```
O que vai dar errado no próximo mês?
```

Abra **Show code** em cada resposta: dá para ver o SQL que ele escreveu.

### 3. O que comparar

| Pergunta | O certo (dos exemplos 05 e 06) | O que o Genie costuma fazer |
|---|---|---|
| Quem atrasa | 7 críticos: PRJ-016, 030, 039, 009, 011, 027, 054 | olha uma ferramenta só e erra a lista |
| Quanto custa | R$ 6,47 mi de estouro previsto | "nenhum atraso tem impacto financeiro" |
| Gente parada | 2 SREs a 2–9% no PRJ-007 | "não há colaboradores parados" |
| Próximo mês | (é a noite 3) | "não dá para responder com estes dados" |

Perguntas de reserva:

```
Por que o projeto PRJ-011 atrasou?
```
(ele acerta: lê o status semanal e acha "falta de SRE")

```
Qual consultoria mais atrasa as entregas?
```
(ele vê 4 CodeForges diferentes)

> **A frase de fechamento:** o Genie é tão bom quanto o dado e as definições que você dá a ele. Hoje o dado
> está em três ferramentas e o KPI mora dentro de cada query. Na noite 2 a gente integra, define o KPI uma
> vez só e ensina o Genie. Aí ele acerta.
