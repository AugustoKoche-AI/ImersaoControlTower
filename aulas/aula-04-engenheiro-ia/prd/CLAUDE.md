# Projeto Farol · Vértice Tecnologia — contexto da noite 4

Noite 4 da Imersão Jornada de Dados (**quinta, 22/10/2026, 19h30**): **Engenheiro de IA**.
Leia este arquivo antes de escrever qualquer código. Ele vale para os três prompts da noite.

> **A pergunta da noite: "E o dono, que não escreve SQL?"**
> Três noites de trabalho estão atrás de um SQL Editor. Hoje o projeto ganha uma URL,
> um agente que lê contrato, e um botão de aprovar. Nenhuma tabela de análise
> nova sobre os projetos: a gold já está pronta. O trabalho é **entregar**.

---

## 1. O que já existe (noites 1 a 3)

Catálogo `lakehouse_vertice`. O "hoje" do dataset é **16/10/2026**: nunca use `current_date()`.

| Tabela / view | O que é |
|---|---|
| `gold.projeto_situacao_atual` | fotografia de hoje por projeto: SPI, CPI, EAC, estouro previsto, margem, atraso projetado, situação (ok, atenção, crítico, concluído), farol do gerente × farol calculado, `melancia` |
| `gold.status_estruturado` | status semanal em colunas: causa_bloqueio (change_freeze, falta_sre, dependencia_fornecedor, rotatividade, mudanca_escopo, bug_retrabalho, aprovacao_cliente, sem_bloqueio, nao_reportado), bloqueio, quem_destrava, dias_impacto |
| `gold.utilizacao_pessoa_semana` | pessoa × projeto × semana: papel, senioridade, utilização, horas e custo ociosos |
| `gold.mv_projetos` | KPIs governados (`MEASURE()`) |
| `gold.score_estouro_30d` | noite 3: `projeto_id, data_referencia, prob_estouro_30d, ranking, faixa_risco, principais_fatores` |
| `silver.entregas_fornecedor` | cada entrega de fornecedor: fornecedor, projeto_id, valor, data_prometida, data_entrega, dias_de_atraso_na_entrega, em_atraso (a CodeForge entrega com prazo ×1,41) |
| Volume `bronze.raw/documentos/contratos/` | **8 contratos de fornecedor e SaaS em PDF** (CodeForge, Pixel Design Studio, QualiTest Brasil, SecureOps Segurança, DataPrime Analytics, NuvemSul Cloud, Observa360, CodeVault) |

**A Vértice é a CONTRATANTE** nesses contratos; o fornecedor é a CONTRATADA. Multa por atraso é dinheiro
que a Vértice **cobra** (desconta da fatura do fornecedor).

## 2. O que a noite 4 constrói

```
 8 contratos PDF ──ai_parse_document──▶ silver.documentos_elementos (title, section_header, text)
        │
        └── agrupar pela última section_header ──▶ silver.contratos_clausulas (72)
                 │
                 └── ai_extract com JSON schema TIPADO ──▶ gold.contratos (1 linha por contrato: valor_anual,
                       data_fim_vigencia, renovacao_automatica, aviso_previo_dias, multa_atraso_pct_dia,
                       teto_multa_pct, sla, reajuste, clausulas = texto de todas as cláusulas)

 Multa a cobrar e aviso prévio: CONSULTAS sobre gold.contratos (+ silver.entregas_fornecedor), não tabelas novas.

 Genie "Farol · Diretoria + Contratos"  ◀── gold.contratos + gold da noite 2 + mv_projetos + score (se existir)
        ▲
        │ aba "Perguntar"
 App "Projeto Farol" (Databricks App, AppKit) ── leitura: config/queries/*.sql no SQL warehouse
        │                                      ── escrita: Lakebase (Postgres) torre.decisoes
        └── Projetos em risco · Simulador de realocação de pessoa · Decisões · Perguntar
```

**Gold enxuta:** a noite 4 cria **uma** tabela na gold (`gold.contratos`). O passo a passo do PDF fica na silver.
Não crie views nem tabelas para a multa ou para os avisos: são perguntas, e o Genie e o app as fazem em SQL.

## 3. Armadilhas medidas neste workspace (Free Edition, outubro/2026)

| Armadilha | O que fazer |
|---|---|
| **Knowledge Assistant e Supervisor Agent** não criam mais ("legacy feature, use Genie Agents instead") | O agente é um **Genie Agent** com os contratos numa tabela (`gold.contratos`, com o texto das cláusulas). Ele cita a cláusula porque o texto está na linha |
| `ai_parse_document` é a chamada cara | Rode uma vez e guarde os elementos numa tabela. Ele devolve `type` (`title`, `section_header`, `text`): agrupe o texto pela última `section_header`, sem regex de título |
| `ai_extract` sem schema devolve **texto** ("0,5% do valor da entrega...") | Use `ai_extract(texto, '<JSON schema>', map('version','2.0'))` com `type` e `description` por campo: sai `0.5`, `true`, `60`. Leia com `:response:campo::DOUBLE` |
| Sem "em português" na descrição do campo, o modelo escreveu um SLA em italiano ("disponibilità") | Peça o idioma na `description` dos campos de texto |
| A multa histórica da CodeForge (desde 2024) é 3× a da vigência atual | Conte só a vigência atual (`data_prometida > add_months(data_fim_vigencia, -12)`): é o que dá para descontar das próximas faturas |
| O Genie publicado com tabela inexistente falha | Crie as tabelas antes de publicar. A `score_estouro_30d` entra só se existir |
| **Já existe** um Genie "Farol · Diretoria" (noite 2) | O da noite 4 se chama **"Farol · Diretoria + Contratos"**. `scripts/genie.py publicar` atualiza pelo título |
| **O Free Edition aceita no máximo 3 apps por workspace** (`reached the maximum limit of 3 apps`) | Antes do prompt 2, confira `databricks apps list`; apague um app que você não usa mais |
| `bundle deploy` cria o app **parado** | O deploy do código é `databricks apps deploy --profile <perfil>` (dentro da pasta do app) |
| O app é um **usuário do Unity Catalog** e nasce sem acesso | Depois do `bundle deploy`: `GRANT USE CATALOG`, `USE SCHEMA` e `SELECT` na gold para o service principal (`apps get` → `service_principal_client_id`). Sem isso o **build** falha no typegen com `INSUFFICIENT_PERMISSIONS` |
| Query em `config/queries/` com tabela inexistente **quebra o build** (typegen `--wait`) | Tabela de outra noite (o score) é lida por uma rota do servidor que responde `{disponivel:false}` |
| `npm run typegen` fora do deploy dá `OFFLINE` em 0 s | Exporte o `.env` antes (`set -a; . ./.env; set +a`) e rode `npm run typegen -- --wait` |
| O warehouse devolve **todo número como string** | `Number()` antes de formatar; `z.coerce.number()` no servidor |
| Lakebase: o service principal **não enxerga o schema `public`** e não escreve em schema de outro dono | O app cria o próprio schema (`torre`) na subida. Se você testou local antes (`npm run dev`), apague o schema `torre` que **você** criou antes do deploy |
| A 1ª visita ao app pede **consentimento OAuth** ("Permission Requested") | É esperado: o app pede para agir em seu nome (Genie). Clique em Authorize uma vez |

## 4. Convenções

- Nome do app: **≤ 26 caracteres**, minúsculas e hífen (`minha-torre`, `farol-torre`).
- Leitura = `config/queries/*.sql`. Escrita = rota do servidor + Lakebase, com validação zod
  (projeto `PRJ-000`, pessoa `COL0000`, tipo `pessoa`).
- Toda decisão grava o **e-mail de quem clicou** (header `x-forwarded-email`), não o service principal.
- Telas em português, números em `R$` e índices com 2 casas.
- Sempre `--profile <perfil>`.

## 5. Números que servem como teste (seed 42)

| O que | Valor |
|---|---|
| Projetos em risco / críticos / melancias | **17 / 7 / 4** (de 41 em andamento) |
| Estouro previsto | **R$ 6,47 mi** |
| Contratos lidos / cláusulas | 8 / 72 (9 por contrato) |
| Contratos sem multa por atraso (só SLA) | 3 (`multa_atraso_pct_dia` nulo) |
| Multa CodeForge | 0,5% ao dia, teto de 10% |
| Multa cobrável da CodeForge na vigência atual | **R$ 1.122.967,65** (120 entregas atrasadas; R$ 3,24 mi no histórico) |
| Multa cobrável de todos os fornecedores na vigência atual | R$ 1.186.147,46 |
| Aviso prévio já vencido | DataPrime Analytics (01/10) e NuvemSul Cloud (02/10): renovaram sozinhos |
| Aviso prévio vencendo em 60 dias | Observa360 (31/10, 15 dias) e QualiTest Brasil (01/12, **sem renovação automática**) |
| SREs ociosos | COL0017 e COL0018 no PRJ-007, uso de 5 a 6%, R$ 179,5 mil de custo ocioso em 12 semanas |
| PRJ-011 | 12 semanas com `falta_sre`, 57 dias de impacto declarados em 90 dias |
| Simulador COL0017 (PRJ-007) → PRJ-011 | 151 h no mês · R$ 30,1 mil de ociosidade evitada · 19,0 dias recuperados · onboarding R$ 8,0 mil · saldo R$ 22,1 mil |
| App · KPI "Alto risco em 30 dias" | 18 (faixa_risco = 'alto' no score da noite 3) |
| Benchmark do Genie | ≥ 8/10 (10 perguntas) |
