# Prompt 0 · Aquecimento — uma fonte nova, por API

**Entrega:** os feriados nacionais de 2026 na tabela `lakehouse_vertice.bronze.feriados`, buscados
numa API pública por um script Python. Sem bundle ainda: é o primeiro contato com o Claude Code.

> Na empresa, o dado não chega pronto. Alguém precisa ir buscar, e quando a fonte não tem conector,
> entra o Python. O caminho é o mesmo da noite 1: **extrair** (Python + requests), **pousar** (o JSON
> no volume, do jeito que veio) e **carregar** (`read_files` cria a tabela na bronze).

---

## O que mostrar antes

A API no navegador, para todo mundo ver que é só um JSON:
<https://brasilapi.com.br/api/feriados/v1/2026>. Pergunte: *"quantos dias úteis a Vértice perde em
novembro, bem quando começa o freeze da Black Friday?"*

---

## O prompt

```
Busque os feriados nacionais de 2026 na API
https://brasilapi.com.br/api/feriados/v1/2026
com um script Python (requests). Salve a resposta
em feriados_2026.json, suba o arquivo para
/Volumes/lakehouse_vertice/bronze/raw/feriados/
e crie a tabela lakehouse_vertice.bronze.feriados
com read_files. No fim, mostre os feriados de
novembro com o dia da semana.
Use o profile <perfil>.
```

---

## O que conferir

```sql
SELECT data, feriado, dia_da_semana
FROM lakehouse_vertice.bronze.feriados
WHERE data BETWEEN '2026-11-01' AND '2026-11-30'
ORDER BY data;
-- 02/11 Finados (segunda) · 15/11 Proclamação da República (domingo) · 20/11 Consciência Negra (sexta)
```

14 feriados no ano. Em novembro, **2 caem em dia útil** (o 15/11 é domingo). Testado em 20/10 no
workspace da imersão, ~1 min.

---

## Se der errado

| Sintoma | Causa | O que fazer |
|---|---|---|
| `no such directory: /Volumes/.../raw/feriados` | a pasta nova não existe no volume | `databricks fs mkdir dbfs:/Volumes/lakehouse_vertice/bronze/raw/feriados --profile <perfil>` antes do `cp` |
| `ModuleNotFoundError: requests` | a biblioteca não está instalada no seu Python | `pip install requests`, ou use o `urllib`, que já vem no Python |
| As colunas vieram `date`, `name`, `type`, `weekday` | o `read_files` manteve os nomes do JSON | normal: renomeie no SELECT, ou deixe assim (é a bronze) |
| Travou de vez | — | `python3 aulas/aula-02-engenheiro/00-buscar-feriados.py --profile <perfil>`: faz os três passos e mostra novembro |
