# Prompt 1 · O agente que lê contrato e manual — "e o que o contrato diz?"

**Entrega:** 8 contratos de fornecedor e o manual de tecnologias em PDF viram tabelas (elementos,
cláusulas, seções do manual, resumo tipado), duas views que respondem o dono em R$ e em datas
(multa a cobrar e aviso prévio), e o Genie **"Farol · Diretoria + Contratos"** passa a responder
citando a cláusula e a seção do manual. **Deploy nº 1** = Genie publicado.

> A gold já responde *quem* está atrasado e *por quê*. A pergunta seguinte do dono é sempre outra:
> **"e o que o contrato diz?"** Dá para cobrar multa da consultoria que atrasou? Qual contrato renova
> sozinho se ninguém avisar? E o manual da casa, o que manda fazer? A resposta está em PDF, e PDF não é coluna.

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
- **Uma linha por cláusula** é o truque que faz o agente **citar** a fonte. O Genie não "lembra" do
  PDF: ele faz `SELECT texto FROM contratos_clausulas WHERE titulo LIKE 'MULTA%'`. O mesmo vale para o manual.
- **`ai_extract` sem schema** devolve texto: `"0,5% do valor da entrega atrasada por dia corrido"`.
  **Com JSON schema tipado**, devolve `0.5`. É a diferença entre "um texto bonito" e um dado que dá para
  somar. A descrição de cada campo é o que a IA lê: escreva como se fosse para um estagiário.
- **Knowledge Assistant e Supervisor Agent** viraram legado no Free Edition. O agente da Vértice é um
  Genie com as cláusulas e o manual em tabelas: mais simples e auditável (dá para ver o SQL).

---

## O prompt

```
Leia aulas/aula-04-engenheiro-ia/prd/CLAUDE.md antes de começar. Use a skill
databricks-ai-functions.

Crie a pasta aulas/aula-04-engenheiro-ia/meu-agente/ com o agente que lê os
contratos de fornecedor e o manual da Vértice. Perfil: <perfil> (sempre --profile).

1. meu-agente/01-contratos.sql, executável com
   python3 scripts/run_sql.py meu-agente/01-contratos.sql --profile <perfil>
   (API de statements, não o aitools query). Na gold, com COMMENT em tudo (é o que o Genie lê):
   a) gold.documentos_elementos: read_files (binaryFile) dos PDFs em
      /Volumes/lakehouse_vertice/bronze/raw/documentos/contratos/ e .../manual/,
      ai_parse_document(content, map('version','2.0')), posexplode dos elementos:
      tipo_documento, documento, ordem, tipo (title/section_header/text), conteudo.
   b) gold.contratos_clausulas: uma linha por cláusula (fornecedor, clausula_numero INT,
      titulo, texto). Cada texto pertence à última section_header "CLÁUSULA N - TÍTULO"
      antes dele (last_value ignorando nulos). O fornecedor sai da linha "CONTRATADA: ...".
   c) gold.manual_secoes: uma linha por seção do manual (secao_numero, titulo, texto), mesmo método.
   d) Um SELECT de demonstração com ai_extract SEM schema (lista de nomes de campo) em 3
      contratos, para a turma ver que volta texto.
   e) gold.contratos_resumo: ai_extract(texto, JSON schema, map('version','2.0')) com os campos
      objeto, valor_anual (number), data_fim_vigencia (string AAAA-MM-DD), renovacao_automatica
      (boolean), aviso_previo_dias (integer), multa_atraso_pct_dia (number, nulo se não há),
      teto_multa_pct (number), sla e reajuste (string). Descrição em cada campo; peça
      "em português" nos campos de texto. Leia com :response:campo::TIPO.
   f) view gold.contratos_multa_fornecedor: silver.entregas_fornecedor entregue com atraso ou
      em aberto vencida; dias de atraso até a entrega (ou até 16/10/2026); multa_cobravel =
      valor × least(dias × multa % ao dia, teto) / 100; na_vigencia_atual = data_prometida
      nos 12 meses que terminam no fim da vigência.
   g) view gold.contratos_avisos: data_limite_aviso = fim da vigência − aviso prévio,
      dias até ela a partir de 16/10/2026, situacao_aviso (vencido / vence em até 60 dias / ok)
      e o_que_fazer conforme renovacao_automatica.

2. meu-agente/gerar_genie.py: escreve meu-agente/diretoria-contratos-genie.json (NÃO use a
   extensão .geniespace.json) com as tabelas contratos_*, manual_secoes, projeto_situacao_atual,
   status_estruturado, utilizacao_pessoa_semana, cobertura_capacidade, entregas_em_atraso,
   desempenho_fornecedor e a metric view mv_projetos. Inclua gold.score_estouro_30d SÓ se
   existir (databricks tables exists). Instruções: a Vértice é a CONTRATANTE (multa é dinheiro
   que ela cobra); hoje = 16/10/2026; cite cláusula e seção do manual; "na vigência atual" =
   na_vigencia_atual; manual: freeze é a seção 4, SRE a 5, farol a 8. Exemplos de SQL para
   "quanto cobrar da CodeForge", "aviso prévio" e "o que o manual diz sobre o freeze".

3. Publique e teste:
   python3 scripts/genie.py publicar meu-agente/diretoria-contratos-genie.json \
     --titulo "Farol · Diretoria + Contratos" --profile <perfil>
   python3 scripts/genie.py benchmark "Farol · Diretoria + Contratos" \
     aulas/aula-04-engenheiro-ia/prd/genie-benchmark.json --profile <perfil>
   Se errar, ajuste as instruções (não as perguntas) e publique de novo.
```

---

## O que conferir

- `gold.contratos_clausulas` com **72** linhas (9 por contrato) e `gold.manual_secoes` com **10**.
- O SELECT sem schema mostra `"multa_atraso": "0,2% do valor da entrega atrasada por dia corrido, limitada a 5%..."`.
- `contratos_resumo`: CodeForge com `multa_atraso_pct_dia = 0.5` e `teto_multa_pct = 10.0`; QualiTest com
  `renovacao_automatica = false`; NuvemSul com aviso prévio de 90 dias.
- `contratos_multa_fornecedor`: **R$ 1.122.967,65** a cobrar da CodeForge na vigência atual (120 entregas;
  R$ 3,24 mi no histórico desde 2024).
- `contratos_avisos`: DataPrime e NuvemSul **vencidos** (renovaram sozinhos em 01 e 02/10); Observa360 vence
  em 15 dias (31/10) e QualiTest em 46 (01/12), e a QualiTest **não renova sozinha**.
- Benchmark: **10/10** no ensaio.

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

**Tempo medido:** os 9 PDFs (parse + extração) em ~1 min no SQL warehouse serverless.
