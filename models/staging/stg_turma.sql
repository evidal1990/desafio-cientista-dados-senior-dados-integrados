{{ config(schema="staging", tags=["staging", "raw"]) }}

with source as (
    select * from {{ source("raw", "turma") }}
)
select
    ano::int,
    id_turma::bigint,
    trim(lower(id_aluno::text)) as id_aluno
from source
