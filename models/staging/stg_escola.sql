{{ config(tags=["staging", "educacao_raw"]) }}

with raw as (
    select * from {{ source("educacao_raw", "escola") }}
)
select
    id_escola::bigint,
    bairro::bigint
from raw
