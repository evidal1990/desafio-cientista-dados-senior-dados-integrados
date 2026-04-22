{{ config(tags=["staging", "educacao"]) }}

select *
from {{ source("raw_educacao", "turma") }}
