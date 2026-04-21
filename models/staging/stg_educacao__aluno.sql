{{ config(materialized="view", tags=["staging", "educacao"]) }}

select *
from {{ source("educacao_raw", "aluno") }}
