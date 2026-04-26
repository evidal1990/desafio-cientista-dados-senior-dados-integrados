# dbt-config (Docker + profile)

A imagem base é **Ubuntu 22.04** (Python 3.10+). No Ubuntu 20.04 o `pip` não oferece **dbt-core 1.11** (só versões antigas para Python 3.8).

Use uma **tag própria** na build (ex.: `desafio-dbt:dev`), não `ubuntu:20.04`, para não sobrescrever a imagem oficial do Docker Hub.

Há **dois** jeitos válidos de buildar; o erro `"/.dbt": not found` aparece quando o `COPY` aponta para uma pasta que **não existe no contexto** (ex.: `Dockerfile` na raiz com `COPY ./.dbt` sem existir `.dbt/` na raiz).

## Build da imagem

**Raiz, Dockerfile dentro de `dbt-config/`** (contexto = pasta `dbt-config`, onde está `.dbt/`):

```bash
docker build -f dbt-config/Dockerfile -t desafio-dbt:dev dbt-config
```

O **contexto** (último argumento em A/B ou `.` em C) tem de conter a pasta `.dbt/` que o `COPY` usa.

## Remover contêiner e imagem `desafio-dbt:dev`

O `docker build -t desafio-dbt:dev` cria uma **imagem**. Um **contêiner** só existe depois de um `docker run` (por exemplo `--name desafio-dbt-dev`).

Parar e remover o contêiner (ajuste o nome se for outro):

```bash
docker rm -f desafio-dbt-dev
```

Remover a **imagem** (após não haver contêiner usando ela; veja com `docker ps -a`):

```bash
docker rmi desafio-dbt:dev
```

## Postgres com Docker (opcional)

Para ter o Postgres na porta **5432** do host (pgAdmin / dbt em `localhost`):

```bash
docker run -d --name educacao -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:16
```

Se o contêiner `postgres` já existir: `docker rm -f postgres` antes de rodar de novo. A imagem cria o banco padrão **`postgres`** (usuário `postgres`). Crie também o banco **`desafio_rmi_ds`** se o seu profile apontar para ele, por exemplo no pgAdmin ou com `docker exec -it postgres psql -U postgres -c "CREATE DATABASE desafio_rmi_ds;"`.

**Apagar a imagem `postgres:16` no Docker Desktop:** primeiro remova **todo** contêiner que a use (senão aparece *Image is in use*). Se o contêiner se chama `postgres`:

```bash
docker rm -f postgres
docker rmi postgres:16
```

Se o nome for outro, liste com `docker ps -a`, remova com `docker rm -f <nome_ou_id>` e só então `docker rmi postgres:16`.

## Rodar o contêiner

Use a **imagem que você buildou** (`desafio-dbt:dev`), não `ubuntu:22.04` puro — essa imagem oficial não tem o dbt.

O nome do **contêiner** (`--name`) só pode usar `[a-zA-Z0-9_.-]` — **não use `:`** (ex.: `--name desafio-dbt-dev`, nunca `desafio-dbt:dev` no `--name`).

Na **raiz do repositório** (credenciais ficam em `dbt-config/.dbt/profiles.yml`, não em variáveis de ambiente do dbt):

```bash
docker run -it --rm --name desafio-dbt-dev \
  -v "$PWD:/work" -w /work \
  desafio-dbt:dev bash
```

**Rede (Postgres no host, dbt no contêiner):** em `dbt-config/.dbt/profiles.yml` use `host: localhost` só se o Postgres estiver **dentro do mesmo contêiner** (não é o caso usual). Para Postgres na **máquina host**:

| Onde roda o Docker | O que fazer |
|--------------------|-------------|
| **Docker Desktop** (Mac / Windows) | `host: host.docker.internal` no `profiles.yml` costuma resolver. |
| **Linux** (`docker` nativo) | `host.docker.internal` **não existe** por padrão → erro `[Errno 8] nodename nor servname provided, or not known`. Suba o contêiner com **`--add-host=host.docker.internal:host-gateway`** (Docker 20.10+) **ou** use no profile o IP do bridge (ex.: `172.17.0.1`) / hostname real do host. |

Exemplo **Linux** (mantém `host.docker.internal` resolvendo para o host):

```bash
docker run -it --rm --name desafio-dbt-dev \
  --add-host=host.docker.internal:host-gateway \
  -v "$PWD:/work" -w /work \
  desafio-dbt:dev bash
```

Se o profile usa **literais** (`host: host.docker.internal`), **não** é necessário `-e POSTGRES_HOST=...` para o dbt — essas variáveis só importam para scripts que você rodar com `python` e leitura de `os.environ`.

Dentro do contêiner, o profile copiado na build fica em `/root/.dbt/`. Com `-w /work`, rode `dbt debug` na pasta do projeto clonada.
