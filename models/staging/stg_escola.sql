{{ config(tags=["staging", "educacao_raw"]) }}

with source as (
    select * from {{ source("educacao_raw", "escola") }}
)
select
    trim(lower(id_escola::text)) as id_escola,
    bairro::bigint as bairro
from source
