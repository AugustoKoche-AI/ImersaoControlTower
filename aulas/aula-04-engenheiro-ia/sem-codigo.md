# Noite 4 sem escrever código

Para quem é de gestão, PMO, financeiro ou jurídico: o mesmo resultado da noite, pela interface.

## 1. O agente que lê contrato, pelo Genie (15 min)

O instrutor (ou o `subir-tudo.sh`) já criou as tabelas de contrato. Abra
**Genie Agents → Torre de Controle · Diretoria + Contratos**, ligue o modo **Agent** e pergunte, nesta ordem:

1. *Por que a obra P011 atrasou e o que o contrato diz sobre isso?*
   → falta de equipamento (37 RDOs, 23,5 dias), chuva; cláusula 6 (guindaste é da Atlas, não dá prorrogação);
   cláusula 5 (chuva pode ser pleiteada se registrada no RDO em 48 h); multa estimada R$ 1,88 mi.
2. *Onde tenho guindaste parado que poderia ir para a P011?* → EQ0017 e EQ0018 na P007 (MG).
3. *Qual obra com contrato já está com a multa no teto?* → P005.
4. *Em quais contratos a chuva dá direito a prorrogação?* → P002, P011, P014.

Clique em **"Show code"** em cada resposta: o Genie mostra o SQL. É assim que se audita um agente.

Abra o PDF `contrato_P011.pdf` em **Catalog → lakehouse_atlas → bronze → raw → documentos → contratos**
e confira a cláusula 6 com os próprios olhos.

## 2. O app, pelo Genie App Builder (15 min)

Em **New → App → Build with Genie** (o nome do menu pode variar), descreva:

> *App "Torre de Controle" para a diretoria da Atlas Engenharia. Página 1: tabela de obras de
> lakehouse_atlas.gold.obra_situacao_atual onde status = 'em_andamento', ordenada por situação
> (crítico, atenção, ok), com SPI, CPI, estouro previsto em R$ e atraso projetado em dias; cards no topo
> com obras em risco, críticas e estouro total. Página 2: chat com o Genie "Torre de Controle · Diretoria +
> Contratos". Tudo em português.*

Compare com o app do gabarito (`torre-app/`). O App Builder resolve a leitura; a **aprovação gravando no
Lakebase** com o seu usuário é a parte que pede código (prompt 3).

## 3. O pitch (10 min)

Leia [`pitch.md`](pitch.md) e grave os seus 3 minutos. Use os números do seu workspace: se a seed é 42, eles
são os mesmos do roteiro.
