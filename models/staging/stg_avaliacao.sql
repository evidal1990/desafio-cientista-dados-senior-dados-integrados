{{ config(schema="staging", tags=["staging", "raw"]) }}

with source as (
    select * from {{ source("raw", "avaliacao") }}
)
select
    trim(lower(id_aluno::text)) as id_aluno,
    id_turma::bigint,
    frequencia::float,
    bimestre::int,
    disciplina_1::float as lingua_portuguesa,
    disciplina_2::float as ciencias,
    disciplina_3::float as ingles,
    disciplina_4::float as matematica
from source
