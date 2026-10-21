# Bônus · contexto do agente de contratos

Leia junto com o `CLAUDE.md` da raiz e o [`../prd/CLAUDE.md`](../prd/CLAUDE.md). Este arquivo traz só o que
é dos contratos (era a parte da noite 4 até 21/10).

## O que existe

| Fonte | O que é |
|---|---|
| Volume `bronze.raw/documentos/contratos/` | **8 contratos de fornecedor e SaaS em PDF** (CodeForge, Pixel Design Studio, QualiTest Brasil, SecureOps Segurança, DataPrime Analytics, NuvemSul Cloud, Observa360, CodeVault) |

**A Vértice é a CONTRATANTE** nesses contratos; o fornecedor é a CONTRATADA. Multa por atraso é dinheiro
que a Vértice **cobra** (desconta da fatura do fornecedor).

## O que o bônus constrói

```
8 contratos PDF ──ai_parse_document──▶ silver.documentos_elementos (title, section_header, text)
        │
        └── agrupar pela última section_header ──▶ silver.contratos_clausulas (72)
                 │
                 └── ai_extract com JSON schema TIPADO ──▶ gold.contratos (1 linha por contrato: valor_anual,
                       data_fim_vigencia, renovacao_automatica, aviso_previo_dias, multa_atraso_pct_dia,
                       teto_multa_pct, sla, reajuste, clausulas = texto de todas as cláusulas)

 Multa a cobrar e aviso prévio: CONSULTAS sobre gold.contratos (+ silver.entregas_fornecedor), não tabelas novas.

 Genie "Farol · Diretoria + Contratos"  ◀── gold.contratos + gold + mv_projetos + score (se existir)
```

## Armadilhas medidas (Free Edition, outubro/2026)

| Armadilha | O que fazer |
|---|---|
| **Knowledge Assistant e Supervisor Agent** não criam mais ("legacy feature, use Genie Agents instead") | O agente é um **Genie Agent** com os contratos numa tabela (`gold.contratos`, com o texto das cláusulas). Ele cita a cláusula porque o texto está na linha |
| `ai_parse_document` é a chamada cara | Rode uma vez e guarde os elementos numa tabela. Ele devolve `type` (`title`, `section_header`, `text`): agrupe o texto pela última `section_header`, sem regex de título |
| `ai_extract` sem schema devolve **texto** ("0,5% do valor da entrega...") | Use `ai_extract(texto, '<JSON schema>', map('version','2.0'))` com `type` e `description` por campo: sai `0.5`, `true`, `60`. Leia com `:response:campo::DOUBLE` |
| Sem "em português" na descrição do campo, o modelo escreveu um SLA em italiano ("disponibilità") | Peça o idioma na `description` dos campos de texto |
| A multa histórica da CodeForge (desde 2024) é 3× a da vigência atual | Conte só a vigência atual (`data_prometida > add_months(data_fim_vigencia, -12)`): é o que dá para descontar das próximas faturas |
| O Genie publicado com tabela inexistente falha | Crie as tabelas antes de publicar. A `score_estouro_30d` entra só se existir |
| **Já existe** um Genie "Farol · Diretoria" (noite 4, prompt 2) | O do bônus se chama **"Farol · Diretoria + Contratos"**. `scripts/genie.py publicar` atualiza pelo título |

## Números (seed 42)

| O que | Valor |
|---|---|
| Contratos lidos / cláusulas | 8 / 72 (9 por contrato) |
| Contratos sem multa por atraso (só SLA) | 3 (`multa_atraso_pct_dia` nulo) |
| Multa CodeForge | 0,5% ao dia, teto de 10% |
| Multa cobrável da CodeForge na vigência atual | **R$ 1.122.967,65** (120 entregas atrasadas; R$ 3,24 mi no histórico) |
| Multa cobrável de todos os fornecedores na vigência atual | R$ 1.186.147,46 |
| Aviso prévio já vencido | DataPrime Analytics (01/10) e NuvemSul Cloud (02/10): renovaram sozinhos |
| Aviso prévio vencendo em 60 dias | Observa360 (31/10, 15 dias) e QualiTest Brasil (01/12, **sem renovação automática**) |
