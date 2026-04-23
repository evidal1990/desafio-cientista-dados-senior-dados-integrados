{{ config(tags=["staging", "educacao_raw"]) }}

select 
  id_escola::int,
  id_aluno::text,
  id_turma::int,
  data_inicio::date,
  data_fim::date,
  disciplina::text,
  frequencia::float
from {{ source("educacao_raw", "frequencia") }}
