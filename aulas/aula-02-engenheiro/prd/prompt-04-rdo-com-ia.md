# Prompt 4 · RDO com IA — o texto livre vira coluna

**Entrega:** `gold.rdo_estruturado`, com causa do atraso, clima, dias de impacto
e incidente extraídos dos 13.730 RDOs. **Deploy nº 4.**

---

## O que mostrar antes

Um RDO de verdade e a pergunta que ele responde:

```sql
SELECT data, texto_livre FROM lakehouse_atlas.silver.rdo
WHERE projeto_id = 'P011' ORDER BY data DESC LIMIT 5;
-- "Equipe de montagem ociosa por falta de guindaste."
-- "Aguardando guindaste de 90t para içamento; montagem de moinho parada."
```

*"A causa do atraso da P011 está escrita aqui, todo dia, há doze semanas. Ninguém
lê. O Genie de ontem também não leu: respondeu listando tarefas atrasadas."*

E a IA, ao vivo, numa linha:

```sql
SELECT ai_classify('Aguardando guindaste de 90t para içamento',
       array('chuva','falta_material','falta_equipamento','mao_de_obra','retrabalho','cliente','sem_ocorrencia'));
-- falta_equipamento
```

**Enquanto ele trabalha, você explica:**

- **IA custa, e custa por linha.** Medimos neste workspace: ~3,7 RDOs por
  segundo. Os 13,7 mil levariam **uma hora** de warehouse. Então cada ferramenta
  onde ela é a certa:
  - **regra** para o que tem padrão fixo: "Clima: chuvoso", "Impacto estimado de
    3 dias" e o dia sem ocorrência (70% dos RDOs). Custo zero, resposta exata.
  - **IA** (`ai_classify`) para o texto livre com ocorrência dos últimos 90 dias
    (~1.000 RDOs, ~3 minutos).
  - **palavra-chave** para o histórico antigo.
- **`MERGE` incremental.** A tarefa só classifica RDO que ainda não está na
  tabela. Amanhã ela processa só os RDOs de amanhã. Não reprocesse o passado.
- **Confiar e conferir.** A última query da tarefa mostra a distribuição por
  método: dá para comparar o que a IA e a regra disseram.

---

## O prompt

```
Continue o bundle em aulas/aula-02-engenheiro/meu-atlas/. Agora o RDO, que é
texto livre, vira coluna.

Crie src/ia/rdo_estruturado.sql (sql_task, caminho completo das tabelas):

1. CREATE TABLE IF NOT EXISTS lakehouse_atlas.gold.rdo_estruturado com COMMENT
   em cada coluna: rdo_id, projeto_id, data, clima, causa_atraso,
   dias_impacto (DOUBLE), incidente (BOOLEAN), metodo ('regra', 'ia' ou
   'palavra_chave'), texto_livre, _classificado_em.
   NÃO é CREATE OR REPLACE: a tabela acumula, e a IA não pode ser refeita
   a cada execução.

2. MERGE INTO ... WHEN NOT MATCHED THEN INSERT, só com os RDOs da
   silver.rdo que ainda não estão na tabela (LEFT ANTI JOIN). Para cada RDO:
   - metodo = 'regra' se rdo_vazio ou se o texto (em minúsculas) bate com
     'sem ocorr|ocorrências: nenhuma|dia produtivo';
     metodo = 'ia' se data >= DATE'2026-07-18' (últimos 90 dias até
     2026-10-16); senão 'palavra_chave'.
   - causa_atraso: 'nao_reportado' se vazio; 'sem_ocorrencia' pela regra;
     ai_classify(texto_livre, array('chuva', 'falta_material',
     'falta_equipamento', 'mao_de_obra', 'retrabalho', 'cliente',
     'sem_ocorrencia')) para metodo = 'ia' — chame a IA num CTE SÓ com essas
     linhas e junte depois, para nunca chamá-la à toa;
     palavra-chave para o resto, nesta ordem: guindaste|içamento →
     falta_equipamento; cliente|permissão de trabalho → cliente;
     chuva|precipitação|temporal|encharcado → chuva;
     aguardando|falta de|não entregou|em estoque|fornecedor → falta_material;
     efetivo reduzido|faltas|rotatividade|soldadores → mao_de_obra;
     retrabalho|reprovad → retrabalho.
   - clima: regexp_extract de 'clima: (palavra)'.
   - dias_impacto: 'impacto estimado de N dias' → N; 'impacto estimado: 1
     dia' → 1; 'meio turno' → 0,5; 'sem impacto' → 0; senão nulo.
   - incidente: o texto cita 'quase acidente'.

3. No fim, um SELECT da contagem por metodo e causa_atraso, para a saída da
   tarefa mostrar o que a IA fez.

No comentário do topo do arquivo, registre a decisão e o número medido:
ai_classify faz ~3,7 RDOs/s; 13,7 mil levariam ~1 hora; os ~1.000 com
ocorrência dos últimos 90 dias levam ~3 minutos.

Acrescente ao job a tarefa rdo_com_ia, depois de medalhao (em paralelo com
testes_de_qualidade).

Rode e me mostre a saída:
  databricks bundle deploy --profile <perfil>
  databricks bundle run atlas_torre --profile <perfil>
```

---

## O que conferir

```sql
SELECT metodo, COUNT(*) FROM lakehouse_atlas.gold.rdo_estruturado GROUP BY 1;
-- regra ~8.900 · palavra_chave ~3.900 · ia ~980  (total 13.730)

SELECT causa_atraso, COUNT(*) AS rdos, SUM(dias_impacto) AS dias
FROM lakehouse_atlas.gold.rdo_estruturado
WHERE projeto_id = 'P011' AND data >= DATE'2026-07-18'
  AND causa_atraso NOT IN ('sem_ocorrencia', 'nao_reportado')
GROUP BY 1 ORDER BY 2 DESC;
-- falta_equipamento 37 RDOs · 23,5 dias. É ISSO que atrasou a P011.
```

**E agora o momento da noite:** onde está o guindaste que falta no Pará?

```sql
SELECT equipamento_id, modelo, obra, uf, ROUND(SUM(horas_operadas) / SUM(horas_disponiveis), 2) AS uso
FROM lakehouse_atlas.gold.utilizacao_equipamento_semana
WHERE tipo = 'guindaste' AND semana > DATE'2026-07-24'
GROUP BY ALL ORDER BY uso LIMIT 3;
-- EQ0017 e EQ0018, Guindaste 90t, parados em MG (P007) com ~6% de uso.
```

> *"Dois guindastes de 90 toneladas parados em Minas, enquanto o RDO do Pará
> reclama todo dia que falta guindaste. A informação existia. Estava em três
> sistemas que não se falavam."*

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| A tarefa leva mais de 15 minutos | A IA rodou em todos os RDOs | Confira o filtro `metodo = 'ia'` no CTE da IA |
| Segunda execução também demora | Faltou o `LEFT ANTI JOIN` | O MERGE só pode pegar RDO novo |
| `ai_classify` devolve nulo | Texto vazio entrou na IA | RDO vazio vai para a regra (`nao_reportado`) |
| `AI_FUNCTION_...` rate limit | Free Edition limitando chamadas | Rode de novo: o MERGE continua de onde parou |

**Tempo medido:** primeira execução ~3 min (977 RDOs na IA); a partir da
segunda, segundos.
