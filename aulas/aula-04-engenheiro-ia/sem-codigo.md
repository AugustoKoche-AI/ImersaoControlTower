# Noite 4 sem escrever código

Para quem é de gestão, PMO, financeiro ou jurídico: o mesmo resultado da noite, pela interface.

## 1. O agente que lê contrato e manual, pelo Genie (15 min)

O instrutor (ou o `subir-tudo.sh`) já criou as tabelas de contrato e do manual. Abra
**Genie Agents → Farol · Diretoria + Contratos**, ligue o modo **Agent** e pergunte, nesta ordem:

1. *Por que o PRJ-011 atrasou e o que o manual manda fazer?*
   → falta de SRE em 12 semanas; seção 5 do manual: todo projeto em testes ou implantação precisa de um SRE.
2. *Tenho SRE parado que poderia ir para o PRJ-011?* → COL0017 e COL0018 no PRJ-007, uso de 6%.
3. *Quanto a Vértice pode cobrar de multa da CodeForge?* → R$ 1,12 mi na vigência atual (120 entregas atrasadas).
4. *Quais contratos precisam de decisão por causa do aviso prévio?* → DataPrime e NuvemSul já renovaram sozinhos;
   Observa360 vence em 31/10; QualiTest em 01/12 e **não renova sozinha**.
5. *O que o manual diz sobre o change freeze?* → seção 4: nada de deploy em e-commerce de 01/11 a 10/01.

Clique em **"Show code"** em cada resposta: o Genie mostra o SQL. É assim que se audita um agente.

Abra o PDF `contrato_codeforge_consultoria_ltda.pdf` em
**Catalog → lakehouse_vertice → bronze → raw → documentos → contratos** e confira a cláusula 6 com os próprios olhos.

## 2. O app, pelo Genie App Builder (15 min)

Em **New → App → Build with Genie** (o nome do menu pode variar), descreva:

> *App "Projeto Farol" para o dono da Vértice Tecnologia. Página 1: tabela de projetos de
> lakehouse_vertice.gold.projeto_situacao_atual onde status = 'em_andamento', ordenada por situação
> (crítico, atenção, ok), com SPI, CPI, estouro previsto em R$, atraso projetado em dias e o farol do gerente;
> cards no topo com projetos em risco, críticos e estouro total. Página 2: chat com o Genie
> "Farol · Diretoria + Contratos". Tudo em português.*

Antes, confira em **Compute → Apps** quantos apps você tem: o Free Edition aceita três.

Compare com o app do gabarito (`torre-app/`). O App Builder resolve a leitura; a **aprovação gravando no
Lakebase** com o seu usuário é a parte que pede código (prompt 3).

## 3. O pitch (10 min)

Leia [`pitch.md`](pitch.md) e grave os seus 3 minutos. Use os números do seu workspace: se a seed é 42, eles
são os mesmos do roteiro.
