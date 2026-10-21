# Bônus da noite 4 · O agente que lê contrato

Até 21/10 este era o prompt 1 da noite 4. Saiu do roteiro ao vivo para dar lugar ao modelo, ao Genie e
ao app, mas continua inteiro e testado: faça em casa, depois da noite 4.

**O que ele faz:** os 8 contratos de fornecedor em PDF (no volume `bronze.raw/documentos/contratos/`)
viram uma tabela, `gold.contratos`, com `ai_parse_document` (o PDF em pedaços) e `ai_extract` com JSON
schema tipado (o número sai como número: `0.5`, não `"0,5% ao dia"`). Um Genie, "Farol · Diretoria +
Contratos", responde quanto dá para cobrar de multa e qual contrato renova sozinho, citando a cláusula.

| Arquivo | Para que serve |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | o contexto dos contratos (leia junto com o `../prd/CLAUDE.md`) |
| [`prompt-agente-de-contratos.md`](prompt-agente-de-contratos.md) | o prompt, com o que mostrar, o que falar e "se der errado" |
| [`agente/`](agente) | o gabarito: `01-contratos.sql`, `gerar_genie.py`, o JSON do Genie e o job `farol_contratos` |
| [`meu-agente/`](meu-agente) | onde você constrói o seu |
| [`genie-benchmark-contratos.json`](genie-benchmark-contratos.json) | 10 perguntas com SQL de referência |
| [`99-verificacao-contratos.sql`](99-verificacao-contratos.sql) | 11 checagens esperado × obtido |

**Os números (ensaio de 18/10):** 8 contratos, 72 cláusulas · multa cobrável da CodeForge na vigência
atual **R$ 1.122.967,65** (120 entregas atrasadas, 0,5% ao dia, teto de 10%) · NuvemSul e DataPrime
renovaram sozinhos (R$ 21,4 mi por ano) · benchmark 10/10.

**Para ligar ao app:** a multa a cobrar voltaria como KPI do `torre-app` (a conta está em
`99-verificacao-contratos.sql`, CTE `multa`). Lembre que query em `config/queries/` com tabela
inexistente quebra o build: só acrescente depois de `gold.contratos` existir.

```bash
python3 scripts/run_sql.py aulas/aula-04-produtos-de-dados-ia/bonus/agente/01-contratos.sql --profile <perfil>
python3 aulas/aula-04-produtos-de-dados-ia/bonus/agente/gerar_genie.py --profile <perfil>
python3 scripts/genie.py publicar aulas/aula-04-produtos-de-dados-ia/bonus/agente/diretoria-contratos-genie.json \
  --titulo "Farol · Diretoria + Contratos" --profile <perfil>
python3 scripts/genie.py benchmark "Farol · Diretoria + Contratos" \
  aulas/aula-04-produtos-de-dados-ia/bonus/genie-benchmark-contratos.json --profile <perfil>
python3 scripts/run_sql.py aulas/aula-04-produtos-de-dados-ia/bonus/99-verificacao-contratos.sql --profile <perfil>
```
