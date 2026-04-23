{{ config(tags=["staging", "educacao_raw"]) }}

select 
  ano::int,
  id_turma::int,
  id_aluno::text
from {{ source("educacao_raw", "turma") }}
