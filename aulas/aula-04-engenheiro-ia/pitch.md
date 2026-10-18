# O pitch de 3 minutos · Torre de Controle para a diretoria

O segundo entregável da imersão. **Três minutos, uma pergunta ao vivo, um número em reais.**
A diretoria não compra "lakehouse": compra **margem que não vai embora** e **decisão que não se perde**.

Todos os números abaixo saem da gold (seed 42, "hoje" = 16/10/2026). Os de ROI são **premissas
explícitas**: troque pelas da sua empresa.

---

## O roteiro (falado)

### 0:00 – 0:30 · O problema
> "Hoje a Atlas tem **36 obras em andamento e R$ 795 milhões** em carteira. **13 delas estão em risco**
> e 7 já são críticas. Se nada mudar, vamos queimar **R$ 42 milhões de margem**. E a gente só ia
> descobrir isso na medição mensal, quando não dá mais para corrigir."

### 0:30 – 1:15 · A solução
> "Juntamos os 7 sistemas da obra (ERP, cronograma, ponto, frota, almoxarifado, o RDO e os contratos)
> num lugar só, com os KPIs definidos uma vez: SPI, CPI, estouro, ruptura de material. A IA lê os 13 mil
> RDOs para achar a causa do atraso e lê os contratos para dizer o que a gente pode pleitear. Um modelo
> avisa quais obras vão estourar nos próximos 30 dias. E tudo isso cabe numa tela que qualquer diretor abre."

### 1:15 – 2:15 · A demo (ao vivo, uma pergunta)
Abra o app → **Perguntar** e digite:
> *"Por que a obra P011 atrasou e o que o contrato diz sobre isso?"*

Leia a resposta em voz alta: **falta de guindaste (23,5 dias perdidos)**; pela **cláusula 6**, isso é risco
nosso e não dá prorrogação; pela **cláusula 5**, os dias de chuva podem ser pleiteados; **multa estimada de
R$ 1,88 milhão**. Depois: *"Onde tenho guindaste parado?"* → **dois guindastes de 90 t parados em Paracatu**.
Vá ao **Simulador**, EQ0017 → P011, mostre os 7,8 dias evitados e clique **Aprovar**.
> "A decisão que levava uma semana de WhatsApp foi tomada agora, com o número na frente, e ficou registrada
> com o meu nome e o horário."

### 2:15 – 2:50 · O ROI

| Alavanca | Base (gold, 16/10) | Premissa | Ganho no ano 1 |
|---|---|---|---:|
| Aditivo pleiteado no prazo (o contrato dá 30 dias) | estouro previsto R$ 42,36 mi, concentrado em 8 obras com CPI caindo desde o 9º mês | recuperar 25% | **R$ 10,6 mi** |
| Multa contratual evitada | R$ 6,97 mi de multa estimada nas 8 obras com contrato | reduzir 20% do atraso (realocação + pleito de chuva) | **R$ 1,4 mi** |
| Ociosidade de frota | EQ0017 + EQ0018: R$ 951 mil de custo ocioso em 12 semanas | realocar em vez de alugar, 1 trimestre | **R$ 0,95 mi** |
| **Total** | | | **≈ R$ 12,9 mi** |
| Custo do projeto | | premissa: plataforma + 2 engenheiros por 6 meses | R$ 0,6 mi |

> "R$ 12,9 milhões de ganho para R$ 0,6 milhão de custo. E isso sem contar as **97 rupturas de material**
> que a Torre já está prevendo hoje, nem os **27 pedidos em atraso** (R$ 4 milhões, 17 da mesma metalúrgica)."

### 2:50 – 3:00 · O pedido
> "Proposta: **piloto de 90 dias nas 13 obras em risco**, com a diretoria usando o app toda segunda-feira.
> Se em 90 dias não recuperarmos o primeiro aditivo, a gente desliga."

---

## Dicas de quem já apresentou

- **Um número por frase.** "R$ 42 milhões" fica; "SPI de 0,78" só se alguém perguntar.
- **A demo é UMA pergunta.** Ensaie. Se o Genie demorar, fale do problema enquanto ele pensa.
- **Diga de onde vem cada número.** "Está no RDO de ontem", "está na cláusula 6". Confiança é rastreabilidade.
- **Premissa é premissa.** Diga "se recuperarmos 25%", nunca "vamos recuperar".

---

## Checklist de publicação

- [ ] Repositório no seu GitHub (fork de `lvgalvao/ImersaoControlTower` ou o seu `meu-atlas` + `minha-torre`), README com print do app
- [ ] `99-verificacao.sql` das noites 1, 2 e 4 com tudo `ok` (print)
- [ ] Vídeo de 3 minutos (tela + voz) com a demo da pergunta da P011 e o clique em **Aprovar**
- [ ] Post no LinkedIn: o problema em uma frase, o print do app, o número (R$ 42 mi em risco), o link do repositório e do vídeo; marque **@Jornada de Dados**
- [ ] Nunca publique o `.env`, tokens ou a URL do seu workspace com credencial
