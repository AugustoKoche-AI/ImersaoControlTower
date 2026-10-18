# Torre de Controle · Atlas Engenharia — contexto da noite 4

Noite 4 da Imersão Jornada de Dados (**quinta, 22/10/2026, 19h30**): **Engenheiro de IA**.
Leia este arquivo antes de escrever qualquer código. Ele vale para os três prompts da noite.

> **A pergunta da noite: "E o diretor que não escreve SQL?"**
> Três noites de trabalho estão atrás de um SQL Editor. Hoje o projeto ganha uma URL,
> um agente que lê contrato e um botão de aprovar. Nenhuma tabela de análise nova:
> a gold já está pronta. O trabalho é **entregar**.

---

## 1. O que já existe (noites 1 a 3)

Catálogo `lakehouse_atlas`. O "hoje" do dataset é **16/10/2026**: nunca use `current_date()`.

| Tabela / view | O que é |
|---|---|
| `gold.obra_situacao_atual` | fotografia de hoje por obra: SPI, CPI, EAC, estouro previsto, margem, atraso projetado, situação (ok, atenção, crítico, concluída) |
| `gold.rdo_estruturado` | RDO em colunas: causa_atraso (chuva, falta_material, falta_equipamento, mao_de_obra, retrabalho, cliente, sem_ocorrencia, nao_reportado), dias_impacto |
| `gold.utilizacao_equipamento_semana` | equipamento × semana: utilização, horas paradas, custo ocioso |
| `gold.utilizacao_equipe_semana` | equipe × semana: horas ociosas, utilização |
| `gold.cobertura_estoque`, `gold.pedidos_em_atraso`, `gold.desempenho_fornecedor` | suprimentos |
| `gold.mv_obras` (+ 4 metric views) | KPIs governados (`MEASURE()`) |
| `gold.score_estouro_30d` | noite 3: `projeto_id, data_referencia, prob_estouro_30d, ranking, faixa_risco, principais_fatores` |
| `silver.equipes` | cadastro limpo de equipe (custo_hora, headcount) |
| Volume `bronze.raw/documentos/contratos/` | **8 contratos EPC em PDF** (P002, P005, P007, P011, P014, P018, P024, P033) |

**A Atlas é a CONTRATADA** em todos os contratos; o cliente é a CONTRATANTE. Multa por atraso é custo da Atlas;
prorrogação é um direito que a Atlas pleiteia.

## 2. O que a noite 4 constrói

```
 PDFs de contrato ──ai_parse_document──▶ gold.contratos_texto ──split──▶ gold.contratos_clausulas
                                                   │
                                                   └─ai_query + JSON schema─▶ gold.contratos_resumo ─┐
 gold.obra_situacao_atual + rdo_estruturado ──────────────────────────────────▶ gold.contratos_exposicao (multa estimada)
                                                                                                       │
 Genie "Torre de Controle · Diretoria + Contratos"  ◀── gold + metric views + contratos + score ◀──────┘
        ▲
        │ aba "Perguntar"
 App "Torre de Controle" (Databricks App, AppKit) ── leitura: config/queries/*.sql no SQL warehouse
        │                                         ── escrita: Lakebase (Postgres) torre.decisoes
        └── Obras em risco · Simulador de realocação · Decisões · Perguntar
```

## 3. Armadilhas medidas neste workspace (Free Edition, outubro/2026)

| Armadilha | O que fazer |
|---|---|
| **Knowledge Assistant e Supervisor Agent** não criam mais ("legacy feature, use Genie Agents instead") | O agente é um **Genie Agent** com as cláusulas numa tabela. Ele cita a cláusula porque ela é uma linha |
| `ai_query` devolve texto livre | Passe `responseFormat` com **JSON schema** (`strict: true`, enums, descrição por campo). Sem descrição, `prazo_aditivo_dias` veio 0 em metade dos contratos |
| O Genie publicado com tabela inexistente falha | Crie as tabelas antes de publicar. A `score_estouro_30d` entra só se existir |
| **Já existe** um Genie "Torre de Controle · Diretoria" (noite 2) | O da noite 4 se chama **"Torre de Controle · Diretoria + Contratos"**. `scripts/genie.py publicar` atualiza pelo título: não sobrescreva o da noite 2 |
| `bundle deploy` cria o app **parado** | O deploy do app é `databricks apps deploy --profile <perfil>` (dentro da pasta do app) |
| O app é um **usuário do Unity Catalog** e nasce sem acesso | Depois do 1º deploy: `GRANT USE CATALOG`, `USE SCHEMA`, `SELECT` para o service principal (`apps get` → `service_principal_client_id`). Sem isso o **build** falha no typegen com `INSUFFICIENT_PERMISSIONS` |
| Query em `config/queries/` com tabela inexistente **quebra o build** (typegen `--wait`) | Tabela de outra noite (o score) é lida por uma rota do servidor que responde `{disponivel:false}` |
| `npm run typegen` fora do deploy dá `OFFLINE` em 0 s | Exporte o `.env` antes (`set -a; . ./.env; set +a`) e deixe o warehouse ligado |
| O warehouse devolve **todo número como string** | `Number()` antes de formatar; `z.coerce.number()` no servidor |
| Lakebase: o service principal **não enxerga o schema `public`** | O app cria o próprio schema (`torre`) na subida, em `onPluginsReady` |
| A 1ª visita ao app pede **consentimento OAuth** ("Permission Requested") | É esperado: o app pede para agir em seu nome (Genie). Clique em Authorize uma vez |

## 4. Convenções

- Nome do app: **≤ 26 caracteres**, minúsculas e hífen (`minha-torre`, `torre-atlas`).
- Leitura = `config/queries/*.sql`. Escrita = rota do servidor + Lakebase, com validação zod.
- Toda decisão grava o **e-mail de quem clicou** (header `x-forwarded-email`), não o service principal.
- Telas em português, números em `R$` e índices com 2 casas.
- Sempre `--profile <perfil>`.

## 5. Números que servem como teste (seed 42)

| O que | Valor |
|---|---|
| Obras em risco / críticas | **13 / 7** |
| Estouro previsto | **R$ 42,36 mi** |
| Contratos lidos / cláusulas | 8 / 88 (11 por contrato) |
| Chuva dá prorrogação | P002, P011, P014 |
| Içamento do cliente (contratante) | só P005 |
| Multa estimada P011 | **R$ 1.876.298,00** (178 dias × 0,05% = 8,9%, abaixo do teto de 10%) |
| Multa no teto | P005 (80 dias × 0,15% = 12% > teto de 8%) |
| Soma das multas estimadas (8 obras) | R$ 6,97 mi |
| Guindastes ociosos | EQ0017 e EQ0018 na P007 (MG), uso de 5 a 6%, R$ 951 mil de custo ocioso em 12 semanas |
| Benchmark do Genie | 10/10 no ensaio |
