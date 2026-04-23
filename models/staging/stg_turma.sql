{{ config(tags=["staging", "educacao_raw"]) }}

with source as (
    select * from {{ source("educacao_raw", "turma") }}
)
select
    ano::int,
    id_turma::bigint,
    trim(lower(id_aluno::text)) as id_aluno
from source
