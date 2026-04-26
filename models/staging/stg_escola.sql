{{ config(schema="staging", tags=["staging", "raw"]) }}

with raw as (
    select * from {{ source("raw", "escola") }}
)
select
    id_escola::bigint,
    bairro::bigint
from raw
