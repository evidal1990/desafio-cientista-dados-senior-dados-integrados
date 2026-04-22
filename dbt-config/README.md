# dbt-config (Docker + profile)

A imagem base é **Ubuntu 22.04** (Python 3.10+). No Ubuntu 20.04 o `pip` não oferece **dbt-core 1.11** (só versões antigas para Python 3.8).

Use uma **tag própria** na build (ex.: `desafio-dbt:dev`), não `ubuntu:20.04`, para não sobrescrever a imagem oficial do Docker Hub.

Há **dois** jeitos válidos de buildar; o erro `"/.dbt": not found` aparece quando o `COPY` aponta para uma pasta que **não existe no contexto** (ex.: `Dockerfile` na raiz com `COPY ./.dbt` sem existir `.dbt/` na raiz).

## Build da imagem

**A — Raiz do clone** (usa o `Dockerfile` na raiz; o `COPY` referencia `dbt-config/.dbt`):

```bash
docker build -t desafio-dbt:dev .
```

**B — Raiz, Dockerfile dentro de `dbt-config/`** (contexto = pasta `dbt-config`, onde está `.dbt/`):

```bash
docker build -f dbt-config/Dockerfile -t desafio-dbt:dev dbt-config
```

**C — Só dentro de `dbt-config/`**:

```bash
cd dbt-config
docker build -t desafio-dbt:dev .
```

O **contexto** (último argumento em A/B ou `.` em C) tem de conter a pasta `.dbt/` que o `COPY` usa.

## Rodar o contêiner

Use a **imagem que você buildou** (`desafio-dbt:dev`), não `ubuntu:22.04` puro — essa imagem oficial não tem o dbt.

O nome do **contêiner** (`--name`) só pode usar `[a-zA-Z0-9_.-]` — **não use `:`** (ex.: `--name desafio-dbt-dev`, nunca `desafio-dbt:dev` no `--name`).

Na **raiz do repositório** (credenciais ficam em `dbt-config/.dbt/profiles.yml`, não em variáveis de ambiente do dbt):

```bash
docker run -it --rm --name desafio-dbt-dev \
  -v "$PWD:/work" -w /work \
  desafio-dbt:dev bash
```

**Rede:** com Postgres no **host** (Mac/Windows), edite `host` no `profiles.yml` **antes** do `docker build` para `host.docker.internal` (dentro do contêiner, `localhost` é o próprio contêiner).

Dentro do contêiner, o profile copiado na build fica em `/root/.dbt/`. Com `-w /work`, rode `dbt debug` na pasta do projeto clonada.
