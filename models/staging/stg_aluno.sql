{{ config(tags=["staging", "educacao_raw"]) }}

select 
  id_aluno::text,
  id_turma::int,
  faixa_etaria::text,
  bairro::int
from {{ source("educacao_raw", "aluno") }}
