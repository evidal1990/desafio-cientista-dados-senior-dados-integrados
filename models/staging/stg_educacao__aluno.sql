{{ config(tags=["staging", "raw_educacao"]) }}

select *
from {{ source("raw_educacao", "aluno") }}
