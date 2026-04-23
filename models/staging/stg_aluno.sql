{{ config(tags=["staging", "educacao_raw"]) }}

with source as (
    select * from {{ source("educacao_raw", "aluno") }}
)
select
    trim(lower(id_aluno::text)) as id_aluno,
    id_turma::bigint,
    trim(lower(faixa_etaria::text)) as faixa_etaria,
    bairro::bigint
from source
