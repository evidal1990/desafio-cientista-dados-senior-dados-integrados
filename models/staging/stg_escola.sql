{{ config(tags=["staging", "educacao_raw"]) }}

with source as (
    select * from {{ source("educacao_raw", "escola") }}
)
select
    id_escola::int,
    bairro::int
from source
