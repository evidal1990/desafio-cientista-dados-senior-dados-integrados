# Desafio dbt — dados educacionais (RMI)

Projeto **dbt Core + Postgres**: staging → intermediate → marts. Dados anonimizados (Parquets no GCS).

---

## Pré-requisitos

- **Git**, **Python 3.10+**, **Docker** (opcional, para Postgres e/ou ambiente dbt).
- Conta Google com acesso ao bucket **público** `gs://case_vagas/rmi/` (ou copiar os ficheiros por outro meio).

---

## 1. Clonar e ambiente Python

```bash
git clone <URL_DO_SEU_REPO> && cd <PASTA_DO_REPO>
python3 -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

---

## 2. Postgres (Docker)

Na máquina host (porta **5432** livre):

```bash
docker run -d --name postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=desafio_rmi_ds \
  -p 5432:5432 \
  postgres:16
```

- **pgAdmin / dbt no host:** Host `localhost`, porta `5432`, base `desafio_rmi_ds`, utilizador `postgres`, palavra-passe `postgres` (ajuste se mudar o `-e`).
- **Remover:** `docker rm -f postgres` (e `docker rmi postgres:16` só depois de remover o contêiner).

---

## 3. Descarregar Parquets para `data/`

Os ficheiros no bucket **não** têm extensão `.parquet` no nome do objeto.

```bash
mkdir -p data
# Se o gsutil reclamar de Python 3.13 no Mac:
export CLOUDSDK_PYTHON=/opt/homebrew/bin/python3.12   # ajuste ao seu python3.12
gsutil -m cp \
  "gs://case_vagas/rmi/aluno" \
  "gs://case_vagas/rmi/avaliacao" \
  "gs://case_vagas/rmi/escola" \
  "gs://case_vagas/rmi/frequencia" \
  "gs://case_vagas/rmi/turma" \
  data/
```

(`data/` está no `.gitignore`; não versionar os binários.)

---

## 4. Criar tabelas brutas no Postgres

O dbt lê **sources** no schema **`raw_educacao`** (variável `raw_schema` no `dbt_project.yml`).

```bash
export POSTGRES_HOST=localhost POSTGRES_USER=postgres POSTGRES_PASSWORD=postgres POSTGRES_DB=desafio_rmi_ds
# opcional: RAW_SCHEMA=raw_educacao  DATA_DIR=./data
python scripts/load_raw_educacao.py
```

Cria o schema se precisar e as tabelas `aluno`, `escola`, `turma`, `frequencia`, `avaliacao`.

---

## 5. Perfil dbt (`profiles.yml`)

- **Nome do profile:** `desafio_rmi_ds` (igual a `profile:` no `dbt_project.yml`).
- Copie `dbt-config/.dbt/profiles.yml` para `~/.dbt/profiles.yml` **ou** use `profiles.yml.example` como modelo.
- Ajuste **host**, **password** e **dbname** se necessário. O ficheiro no repo usa **valores literais** (sem `env_var`).
- **`schema` no profile:** em **dev** está alinhado com `raw_educacao`; em **`--target prod`** usa outro schema (ex.: `desafio_rmi_ds_prod`). Em **dev**, o schema físico dos models **sem** `+schema` segue também `vars.raw_schema` via `macros/generate_schema_name.sql`.

---

## 6. dbt (na raiz do repo, com `.venv` ativo)

```bash
dbt debug
dbt run
dbt test
dbt docs generate && dbt docs serve
```

- **Só staging:** `dbt run --select path:models/staging`
- **`dbt compile`** não cria objetos no warehouse; só **`dbt run`** / **`dbt build`**.

---

## 7. Docker — imagem com dbt

**Build** (na raiz do repositório):

```bash
docker build -t desafio-dbt:dev .
```

**Run** (monta o código em `/work`; Postgres no host no Mac/Windows):

```bash
docker run -it --rm --name desafio-dbt-dev \
  -v "$PWD:/work" -w /work \
  desafio-dbt:dev bash
```

Dentro do contêiner: `cd /work`, ajuste `host` no `/root/.dbt/profiles.yml` para **`host.docker.internal`** se o Postgres correr no **host**. No **Docker em Linux**:

```bash
docker run -it --rm --name desafio-dbt-dev \
  --add-host=host.docker.internal:host-gateway \
  -v "$PWD:/work" -w /work \
  desafio-dbt:dev bash
```

Alternativa de build: `docker build -f dbt-config/Dockerfile -t desafio-dbt:dev dbt-config` — ver [`dbt-config/README.md`](dbt-config/README.md).

**Remover imagem/contêiner dbt:** `docker rm -f desafio-dbt-dev` → `docker rmi desafio-dbt:dev`.

---

## 8. Postgres (Estrutura)

| O quê | Onde |
|--------|--------|
| Tabelas brutas (carga Python) | schema **`raw_educacao`** |
| Views `stg_*` e marts (dev) | mesmo schema **`raw_educacao`** (macro `generate_schema_name`; `target` ≠ `prod`) |
| Marts em **prod** | schema do output **`prod`** no `profiles.yml` |

---

## 9. Resultado dos testes (staging) e padronização

### O que foi padronizado na camada staging

- **Tipos explícitos** nos `stg_*`: conversões com `::text`, `::bigint`, `::date`, `::float` (conforme o model), alinhando a tipagem às descrições em `models/staging/schema.yml`.
- **Nomes de colunas legíveis** em `stg_avaliacao`: a fonte `disciplina_1`…`disciplina_4` expõe-se como `lingua_portuguesa`, `ciencias`, `ingles`, `matematica`.

### Inconsistências encontradas nos dados

Na exploração da base carregada, registaram-se as seguintes situações em **`stg_aluno`** (refletem a fonte `aluno` após o mesmo pipeline de staging):

- **`id_turma`:** nem todos os alunos têm turma associada.
- **`bairro`:** nem todos os alunos têm bairro associado.
- **68** linhas não distintas

Na exploração da base carregada, registaram-se as seguintes situações em **`stg_frequencia`** (refletem a fonte `frequencia` após o mesmo pipeline de staging):

- **1469** linhas não distintas

Até estas lacunas serem tratadas na fonte, em intermediate/marts ou relaxando testes, os testes `not_null` em `id_turma` e `bairro` podem **falhar** com a carga atual.

Na exploração da base carregada, registaram-se as seguintes situações em **`stg_avaliacao`** (refletem a fonte `avaliacao` após o mesmo pipeline de staging):

- **`ciencias`:** nem todos os alunos têm nota de ciencias associada (35931 dados nulos).
- **`ingles`:** nem todos os alunos têm nota de ingles associada (221687 dados nulos).
- **`matematica`:** nem todos os alunos têm nota de matematica associada (35462 dados nulos).
- **`lingua_portuguesa`:** nem todos os alunos têm nota de lingua_portuguesa associada (34609 dados nulos).
- **`frequencia`:** nem todos os alunos têm frequencia associada (1734 dados nulos).
- **34** linhas não distintas

Até estas lacunas serem tratadas na fonte, em intermediate/marts ou relaxando testes, os testes `not_null` em `id_turma` e `bairro` podem **falhar** com a carga atual.

---

## 10. Estrutura útil do repositório

```
models/staging/     # stg_* + _sources.yml
models/intermediate/
models/marts/
scripts/load_raw_educacao.py
dbt-config/.dbt/profiles.yml
Dockerfile
dbt_project.yml
```

---

## 11. Pacotes dbt

Se usar `packages.yml`: `dbt deps` antes de `dbt run`.

---
