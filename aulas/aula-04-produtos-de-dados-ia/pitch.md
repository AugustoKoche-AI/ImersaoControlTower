# O pitch de 3 minutos · Projeto Farol para o dono

O segundo entregável da imersão. **Três minutos, uma pergunta ao vivo, um número em reais.**
O dono não compra "lakehouse": compra **margem que não vai embora**, **gente que não fica parada** e
**decisão que não se perde**.

Todos os números abaixo saem da gold (seed 42, "hoje" = 16/10/2026). Os de ROI são **premissas
explícitas**: troque pelas da sua empresa.

---

## O roteiro (falado)

### 0:00 – 0:30 · O problema
> "Quando eu cheguei na Vértice, ninguém sabia dizer quais projetos estavam atrasados: 20 viviam no Excel, 25 no
> ClickUp e 15 no MS Project. Hoje a resposta é esta: dos **41 projetos em andamento**, **17 estão em
> risco** e 7 já são críticos. Se nada mudar, vamos queimar **R$ 6,5 milhões de margem**. E 4 desses
> projetos estavam com **farol verde** no status de sexta."

### 0:30 – 1:15 · A solução
> "Juntamos as três ferramentas e os sistemas de RH, timesheet, financeiro e compras num lugar só, com os
> KPIs definidos uma vez: SPI, CPI, estouro, margem. Tudo se atualiza sozinho toda segunda às 6h. A IA lê
> os status semanais para achar a causa do atraso, e um modelo avisa quais projetos vão estourar nos
> próximos 30 dias, 41 dias antes, em média. E tudo isso cabe numa tela que o senhor abre no celular."

### 1:15 – 2:15 · A demo (ao vivo, uma pergunta)
Abra o app → **Perguntar** e digite:
> *"Por que o PRJ-011 atrasou?"*

Leia a resposta em voz alta: **falta de SRE em 12 semanas seguidas** (57 dias de impacto declarados nos
status). Depois:
*"Tenho SRE parado que poderia ir para o PRJ-011?"* → **duas SREs seniores a 6% de uso no PRJ-007**, um
projeto que ainda está no desenho: **R$ 179 mil** pagos em 12 semanas sem produzir.
Vá ao **Simulador**, COL0017 → PRJ-011, mostre os **19 dias** de cronograma recuperados e clique **Aprovar**
(se você fez o prompt 4; senão, faça a demo no `farol-torre`, que já grava no Lakebase).
> "A decisão que levava uma semana de WhatsApp foi tomada agora, com o número na frente, e ficou registrada
> com o meu nome e o horário."

### 2:15 – 2:50 · O ROI

| Alavanca | Base (gold, 16/10) | Premissa | Ganho no ano 1 |
|---|---|---|---:|
| Escopo cobrado do cliente | R$ 3,31 mi do estouro previsto está nos 4 projetos em andamento com escopo crescendo sem aditivo (e 42 status com "mudança de escopo" na carteira em 90 dias) | recuperar 50% com change request | **R$ 1,66 mi** |
| Multa de fornecedor *(bônus dos contratos)* | R$ 1,12 mi de multa cobrável da CodeForge na vigência atual (120 entregas atrasadas, 0,5% ao dia, teto de 10%) | descontar 50% das faturas | **R$ 0,56 mi** |
| Gente parada | 2 SREs a 6% de uso: R$ 14,96 mil por semana de custo ocioso | realocar e manter o uso acima de 80% por 1 ano | **R$ 0,78 mi** |
| **Total** | | | **≈ R$ 3,0 mi** (≈ R$ 2,4 mi sem o bônus dos contratos) |
| Custo do projeto | | premissa: plataforma + 1 engenheiro de dados por 6 meses | R$ 0,4 mi |

> "R$ 3 milhões de ganho para R$ 0,4 milhão de custo, e isso sem contar o que a Torre já está avisando:
> o **freeze da Black Friday começa em 01/11** e trava o PRJ-011, o PRJ-003 e o PRJ-024, e o modelo já
> marcou o **PRJ-024** (situação ok hoje, SPI 0,91) com **46% de chance** de estourar no próximo mês: no
> freeze do ano passado o SPI dele foi de 0,99 a 0,70."
>
> *(Se você fez o bônus dos contratos, feche com:)* "E dois contratos (NuvemSul e DataPrime, R$ 21,4 mi
> por ano) renovaram sozinhos em outubro porque ninguém viu o aviso prévio."

### 2:50 – 3:00 · O pedido
> "Proposta: **piloto de 90 dias nos 17 projetos em risco**, com o senhor e os gerentes usando o app toda
> segunda-feira. Se em 90 dias não cobrarmos o primeiro aditivo de escopo, a gente desliga."

---

## Dicas de quem já apresentou

- **Um número por frase.** "R$ 6,5 milhões" fica; "SPI de 0,77" só se alguém perguntar.
- **A demo é UMA pergunta.** Ensaie. Se o Genie demorar, fale do problema enquanto ele pensa.
- **Diga de onde vem cada número.** "Está no status de sexta", "o modelo avisou 9 de 10 estouros no teste". Confiança é rastreabilidade.
- **Premissa é premissa.** Diga "se recuperarmos 50%", nunca "vamos recuperar".
- **Dia de cronograma não é real.** Os 19 dias recuperados no PRJ-011 entram no discurso, não na conta de
  ROI: sem uma multa ou uma receita atrelada, eles não viram dinheiro.

---

## Checklist de publicação

- [ ] Repositório no seu GitHub (o seu `projeto-farol`, com o bundle `vertice` e o app `minha-torre`), README com print do app e do dashboard
- [ ] `99-verificacao.sql` das noites 1, 3 e 4 com tudo `ok` (print)
- [ ] Vídeo de 3 minutos (tela + voz) com a demo da pergunta do PRJ-011 e o clique em **Aprovar**
- [ ] Post no LinkedIn: o problema em uma frase (3 ferramentas, ninguém sabia quem estava atrasado), o print do app, o número (17 projetos em risco, R$ 6,5 mi), o link do repositório e do vídeo; marque **@Jornada de Dados**
- [ ] Nunca publique o `.env`, tokens ou a URL do seu workspace com credencial
