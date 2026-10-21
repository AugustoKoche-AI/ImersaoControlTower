# Bônus · O agente que lê contrato: "e o que o contrato diz?"

**Entrega:** os 8 contratos de fornecedor em PDF viram **uma tabela na gold**, `gold.contratos` (um contrato
por linha, com colunas tipadas e o texto das cláusulas), e o Genie **"Farol · Diretoria + Contratos"** passa a
responder em R$ e em datas, citando a cláusula. **Deploy nº 1** = Genie publicado.

> A gold já responde *quem* está atrasado e *por quê*. A pergunta seguinte do dono é sempre outra:
> **"e o que o contrato diz?"** Dá para cobrar multa da consultoria que atrasou? Qual contrato renova
> sozinho se ninguém avisar? A resposta está em PDF, e PDF não é coluna.

---

## O que mostrar antes

Abra o PDF `contrato_codeforge_consultoria_ltda.pdf` no volume (`bronze/raw/documentos/contratos/`)
e leia em voz alta as cláusulas 4 (renovação) e 6 (multa). Depois pergunte ao Genie da noite 2:

```
"Quanto a Vértice pode cobrar de multa da CodeForge?"
→ ele sabe que a CodeForge atrasa (×1,41), mas não tem o contrato.
```

**Enquanto o Claude Code trabalha, você explica:**

- **`ai_parse_document`** lê a página, não o arquivo: devolve os elementos com o **tipo**
  (`title`, `section_header`, `text`). É a chamada cara: roda uma vez e vira tabela.
- **Uma linha por cláusula** (na silver) é o que permite montar o texto do contrato com o número de cada
  cláusula na frente. Esse texto vai para a coluna `clausulas` da `gold.contratos`, e é de lá que o Genie
  **cita** a fonte: ele não "lembra" do PDF, ele lê a linha.
- **`ai_extract` sem schema** devolve texto: `"0,5% do valor da entrega atrasada por dia corrido"`.
  **Com JSON schema tipado**, devolve `0.5`. É a diferença entre "um texto bonito" e um dado que dá para
  somar. A descrição de cada campo é o que a IA lê: escreva como se fosse para um estagiário.
- **Knowledge Assistant e Supervisor Agent** viraram legado no Free Edition. O agente da Vértice é um
  Genie com os contratos numa tabela: mais simples e auditável (dá para ver o SQL).

---

## O prompt

```
Leia aulas/aula-04-produtos-de-dados-ia/prd/CLAUDE.md e aulas/aula-04-produtos-de-dados-ia/bonus/CLAUDE.md antes de começar. Use a skill
databricks-ai-functions.

Crie a pasta aulas/aula-04-produtos-de-dados-ia/bonus/meu-agente/ com o agente que lê os 8
contratos de fornecedor da Vértice. Perfil: <perfil> (sempre --profile).
Objetivo: gold enxuta. Só UMA tabela nova na gold; nada de views.

1. meu-agente/01-contratos.sql, executável com
   python3 scripts/run_sql.py meu-agente/01-contratos.sql --profile <perfil>
   (API de statements, não o aitools query). COMMENT em toda tabela (é o que o Genie lê).
   a) silver.documentos_elementos: read_files (binaryFile) dos PDFs em
      /Volumes/lakehouse_vertice/bronze/raw/documentos/contratos/,
      ai_parse_document(content, map('version','2.0')), posexplode dos elementos:
      documento, ordem, tipo (title/section_header/text), conteudo.
   b) silver.contratos_clausulas: uma linha por cláusula (fornecedor, clausula_numero INT,
      titulo, texto). Cada texto pertence à última section_header "CLÁUSULA N - TÍTULO"
      antes dele (last_value ignorando nulos). O fornecedor sai da linha "CONTRATADA: ...".
   c) Um SELECT de demonstração com ai_extract SEM schema (lista de nomes de campo) em 3
      contratos, para a turma ver que volta texto.
   d) gold.contratos, uma linha por contrato: ai_extract(texto do contrato, JSON schema,
      map('version','2.0')) com objeto, valor_anual (number), data_fim_vigencia (string
      AAAA-MM-DD), renovacao_automatica (boolean), aviso_previo_dias (integer),
      multa_atraso_pct_dia (number, nulo se não há), teto_multa_pct (number), sla e
      reajuste (string). Descrição em cada campo; "em português" nos campos de texto.
      Leia com :response:campo::TIPO. Guarde também clausulas = o texto de todas as
      cláusulas, cada uma com "CLÁUSULA N - TÍTULO:" na frente.
   e) No fim, duas CONSULTAS (não views) sobre gold.contratos, com hoje = 16/10/2026:
      - multa a cobrar por fornecedor: silver.entregas_fornecedor entregue com atraso ou
        em aberto vencida; dias de atraso até a entrega (ou até hoje); multa = valor ×
        least(dias × multa % ao dia, teto) / 100; só o prometido na vigência atual
        (data_prometida > add_months(data_fim_vigencia, -12));
      - aviso prévio: data limite = data_fim_vigencia − aviso_previo_dias e dias até ela.

2. meu-agente/gerar_genie.py: escreve meu-agente/diretoria-contratos-genie.json (NÃO use a
   extensão .geniespace.json) com gold.contratos, gold.projeto_situacao_atual,
   gold.status_estruturado, gold.utilizacao_pessoa_semana, silver.entregas_fornecedor e a
   metric view gold.mv_projetos. Inclua gold.score_estouro_30d SÓ se existir (databricks
   tables exists). Instruções: a Vértice é a CONTRATANTE (multa é dinheiro que ela cobra);
   hoje = 16/10/2026; cite o número da cláusula; a conta da multa e do aviso prévio acima.
   Exemplos de SQL para "quanto cobrar da CodeForge", "aviso prévio", "por que o PRJ-011
   atrasou" e "tenho SRE parado para o PRJ-011".

3. Publique e teste:
   python3 scripts/genie.py publicar meu-agente/diretoria-contratos-genie.json \
     --titulo "Farol · Diretoria + Contratos" --profile <perfil>
   python3 scripts/genie.py benchmark "Farol · Diretoria + Contratos" \
     aulas/aula-04-produtos-de-dados-ia/bonus/genie-benchmark-contratos.json --profile <perfil>
   Se errar, ajuste as instruções (não as perguntas) e publique de novo.
```

---

## O que conferir

- `silver.contratos_clausulas` com **72** linhas (9 por contrato) e `gold.contratos` com **8**.
- O SELECT sem schema mostra `"multa_atraso": "0,2% do valor da entrega atrasada por dia corrido, limitada a 5%..."`.
- `gold.contratos`: CodeForge com `multa_atraso_pct_dia = 0.5` e `teto_multa_pct = 10.0`; QualiTest com
  `renovacao_automatica = false`; NuvemSul com aviso prévio de 90 dias; 3 contratos sem multa por atraso.
- Consulta da multa: **R$ 1.122.967,65** a cobrar da CodeForge na vigência atual (120 entregas;
  R$ 3,24 mi no histórico desde 2024).
- Consulta do aviso prévio: DataPrime e NuvemSul **vencidos** (renovaram sozinhos em 01 e 02/10); Observa360
  vence em 15 dias (31/10) e QualiTest em 46 (01/12), e a QualiTest **não renova sozinha**.
- `99-verificacao.sql`: **11 × ok**. Benchmark: **≥ 8/10**.

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `Knowledge Assistant is now a legacy feature` | o Free Edition não cria mais KA nem Supervisor | é o motivo do agente ser um Genie |
| Cláusula com o título colado no texto | cortou por regex de título | use o `type = 'section_header'` do ai_parse_document |
| `multa_atraso_pct_dia` vem como texto | ai_extract sem schema (lista de nomes) | passe o JSON schema com `"type": "number"` |
| Campo de texto em outra língua | o modelo improvisou | `"description": "... em português"` |
| Genie: "a Vértice deve pagar a multa" | o modelo não sabe quem é a contratante | instrução explícita: a Vértice é a CONTRATANTE |
| Publicar Genie: `score_estouro_30d does not exist` | a noite 3 não rodou | o gerador só inclui o score se a tabela existir |
| Sobrescreveu o Genie da noite 2 | publicou com o título "Farol · Diretoria" | use "Farol · Diretoria + Contratos"; restaure a noite 2 com `bundle deploy` do `vertice` |

**Tempo medido:** os 8 PDFs (parse + extração) em ~1 min no SQL warehouse serverless.
