{{ config(materialized="view", tags=["staging", "educacao"]) }}

select *
from {{ source("raw_educacao", "avaliacao") }}
