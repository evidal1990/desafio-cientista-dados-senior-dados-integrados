{{ config(tags=["staging", "educacao_raw"]) }}

select 
  id_aluno::text,
  id_turma::int,
  frequencia::float,
  bimestre::int,
  disciplina_1::float as lingua_portuguesa,
  disciplina_2::float as ciencias,
  disciplina_3::float as ingles,
  disciplina_4::float as matematica
from {{ source("educacao_raw", "avaliacao") }}
