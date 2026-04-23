{{ config(tags=["staging", "educacao_raw"]) }}

with source as (
    select * from {{ source("educacao_raw", "frequencia") }}
)
select
    id_escola::int,
    trim(lower(id_aluno::text)) as id_aluno,
    id_turma::int,
    data_inicio::date,
    data_fim::date,
    trim(lower(disciplina::text)) as disciplina,
    frequencia::float
from source
