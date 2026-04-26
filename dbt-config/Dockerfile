# 22.04: Python 3.10+ (dbt-core 1.11 não instala no Python 3.8 do Ubuntu 20.04)
FROM ubuntu:22.04
# Contexto de build = pasta dbt-config/ (onde existe ./.dbt)
COPY ./.dbt /root/.dbt

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl git telnet vim \
        python3 python3-pip python3-venv \
        libpq5 \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --upgrade pip setuptools wheel \
    && pip3 install --no-cache-dir dbt-core==1.11.8 dbt-postgres==1.10.0
