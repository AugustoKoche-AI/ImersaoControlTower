# Prompt 1 · O agente que lê contrato — "e o que o contrato diz?"

**Entrega:** 8 contratos em PDF viram três tabelas (texto, cláusulas, resumo
estruturado) e uma view de exposição em R$, e o Genie **"Torre de Controle ·
Diretoria + Contratos"** passa a responder com a cláusula. **Deploy nº 1** = Genie publicado.

> A gold já responde *por que* a obra atrasou. A pergunta seguinte da diretoria é
> sempre a mesma: **"e o que o contrato diz?"** Tem multa? Chuva dá prorrogação?
> O guindaste era nosso ou do cliente? A resposta está em PDF, e PDF não é coluna.

---

## O que mostrar antes

Abra o PDF `contrato_P011.pdf` no volume (`bronze/raw/documentos/contratos/`) e leia
em voz alta as cláusulas 4, 5 e 6. Depois pergunte ao Genie da noite 2:

```
"Por que a obra P011 atrasou e o que o contrato diz sobre isso?"
→ ele acha a causa (falta de guindaste), mas não tem o contrato.
```

**Enquanto o Claude Code trabalha, você explica:**

- **`ai_parse_document`** lê a página, não o arquivo: devolve os elementos (título,
  parágrafo) em VARIANT. Um `concat_ws` junta o texto.
- **Uma linha por cláusula** é o truque que faz o agente **citar** a fonte. O Genie
  não "lembra" do PDF: ele faz `SELECT texto FROM contratos_clausulas WHERE clausula_numero = 6`.
- **`ai_query` com JSON schema** obriga o modelo a devolver número, booleano e enum.
  É a diferença entre "um texto bonito" e um dado que dá para somar. Sem a descrição
  de cada campo, o prazo de aditivo veio 0 em metade dos contratos no ensaio.
- **Knowledge Assistant e Supervisor Agent** viraram legado no Free Edition. O agente
  da Atlas é um Genie com as cláusulas numa tabela: mais simples e auditável.

---

## O prompt

```
Leia aulas/aula-04-engenheiro-ia/prd/CLAUDE.md antes de começar.

Crie a pasta aulas/aula-04-engenheiro-ia/meu-agente/ com o agente que lê os
contratos da Atlas. Perfil: <perfil> (sempre --profile).

1. meu-agente/01-contratos.sql, executável com
   python3 scripts/run_sql.py meu-agente/01-contratos.sql --profile <perfil>
   (use a API de statements, não o aitools query). Quatro objetos na gold,
   com COMMENT em todos (é o que o Genie lê):
   a) gold.contratos_texto: read_files dos PDFs em
      /Volumes/lakehouse_atlas/bronze/raw/documentos/contratos/ (binaryFile),
      ai_parse_document(content), texto = concat_ws dos elementos;
      projeto_id extraído do nome do arquivo (contrato_P011.pdf → P011).
   b) gold.contratos_clausulas: uma linha por cláusula (projeto_id,
      clausula_numero INT, titulo, texto). Normalize os espaços (o PDF quebra
      linha no meio da frase) e corte em "CLÁUSULA N - ".
   c) gold.contratos_resumo: ai_query('databricks-meta-llama-3-3-70b-instruct',
      ..., responseFormat => JSON schema strict) com os campos multa_dia_pct
      (number), teto_multa_pct (number), chuva_da_prorrogacao (boolean),
      icamento_responsavel e estrutura_fornecida_por (enum contratada|contratante),
      prazo_aditivo_dias (integer), reajuste (string), bonus_antecipacao
      (boolean). Descreva cada campo no schema. Lembre: a Atlas é a CONTRATADA.
   d) gold.contratos_exposicao (view): junta obra_situacao_atual, contratos_resumo
      e a contagem de RDOs de chuva e de falta_equipamento; multa_estimada =
      valor_contrato × min(atraso_projetado_dias × multa_dia_pct, teto) / 100 e
      multa_no_teto.

2. meu-agente/gerar_genie.py gera meu-agente/diretoria-contratos-genie.json
   (serialized_space v2, ids de 32 caracteres em ordem) com: contratos_*,
   obra_situacao_atual, rdo_estruturado, utilizacao_equipamento_semana,
   utilizacao_equipe_semana, cobertura_estoque, pedidos_em_atraso,
   desempenho_fornecedor, mv_obras, e score_estouro_30d SÓ se existir.
   Instruções: HOJE = 2026-10-16; a Atlas é a CONTRATADA (nunca "cobrar a
   contratada"); sempre citar número e trecho da cláusula; regras de leitura
   (chuva_da_prorrogacao, içamento da contratada não dá prorrogação, prazo do
   aditivo); "em risco" = atenção + crítico somados. Exemplos de SQL para:
   "Por que a obra P011 atrasou e o que o contrato diz sobre isso?",
   "Qual a multa estimada de cada obra com contrato?",
   "Onde tenho guindaste parado que poderia ir para a P011?".

3. Rode e me mostre:
   python3 scripts/run_sql.py aulas/aula-04-engenheiro-ia/meu-agente/01-contratos.sql --profile <perfil>
   SELECT * EXCEPT(arquivo) FROM lakehouse_atlas.gold.contratos_resumo ORDER BY 1
   python3 aulas/aula-04-engenheiro-ia/meu-agente/gerar_genie.py --profile <perfil>
   python3 scripts/genie.py publicar aulas/aula-04-engenheiro-ia/meu-agente/diretoria-contratos-genie.json \
     --titulo "Torre de Controle · Diretoria + Contratos" --profile <perfil>
   python3 scripts/genie.py perguntar "Torre de Controle · Diretoria + Contratos" \
     "Por que a obra P011 atrasou e o que o contrato diz sobre isso?" --profile <perfil>
   python3 scripts/genie.py benchmark "Torre de Controle · Diretoria + Contratos" \
     aulas/aula-04-engenheiro-ia/prd/genie-benchmark.json --profile <perfil>
NÃO use o título "Torre de Controle · Diretoria": é o Genie da noite 2.
```

---

## O que conferir

- `contratos_clausulas`: **88 linhas** (11 por contrato).
- `contratos_resumo`: chuva dá prorrogação em **P002, P011, P014**; içamento do cliente só na **P005**;
  bônus por antecipação em **P018 e P033**.
- `contratos_exposicao`: P011 com **R$ 1.876.298,00** de multa estimada; P005 **no teto**.
- O Genie responde a pergunta da P011 com **falta de equipamento (37 RDOs, 23,5 dias)**, cita a
  **cláusula 6** (guindaste é da contratada, não dá prorrogação) e a **cláusula 5** (chuva pode ser
  pleiteada se registrada no RDO em 48 h).
- Benchmark: **≥ 8/10** (no ensaio: 9/10 na 1ª rodada, **10/10** depois de ensinar que "em risco" é um número só).

> *"O Genie não leu o PDF agora. Ele leu ontem à noite, uma vez, e guardou cada cláusula numa linha.
> Hoje ele só faz um SELECT. É por isso que ele cita a fonte, e é por isso que dá para auditar."*

---

## Se der errado

| Sintoma | Causa | Correção |
|---|---|---|
| `contratos_texto.texto` vazio | caminho do volume errado | `LIST '/Volumes/lakehouse_atlas/bronze/raw/documentos/contratos/'` |
| `contratos_clausulas` com 8 linhas | o split não achou "CLÁUSULA N - " | normalize espaços antes do split (`regexp_replace(texto, '\\s+', ' ')`) |
| `prazo_aditivo_dias = 0` em alguns contratos | campo sem descrição no schema | descreva cada campo no JSON schema |
| Genie: "recomendo cobrar a contratada" | o modelo não sabe que a Atlas é a contratada | instrução explícita: a Atlas é a CONTRATADA |
| `Table ... score_estouro_30d does not exist` ao publicar | a noite 3 ainda não rodou (ou está recriando a tabela) | o gerador só inclui o score se a tabela existir; rode de novo |
| Benchmark erra "quantas obras em risco?" com 2 linhas | o Genie quebrou por situação | exemplo de SQL com `COUNT(*)` único e a instrução "em risco = um número só" |

**Tempo medido:** SQL dos contratos ~30 s (8 PDFs); publicar o Genie ~5 s; benchmark de 10 perguntas ~3 min.
