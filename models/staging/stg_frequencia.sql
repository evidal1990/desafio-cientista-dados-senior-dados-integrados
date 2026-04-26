{{ config(schema="staging", tags=["staging", "raw"]) }}

with raw as (
    select * from {{ source("raw", "frequencia") }}
)
select
    id_escola::bigint,
    trim(lower(id_aluno::text)) as id_aluno,
    id_turma::bigint,
    data_inicio::date,
    data_fim::date,
    case trim(lower(disciplina::text))
        when 'disciplina_1' then 'lingua_portuguesa'
        when 'disciplina_2' then 'ciencias'
        when 'disciplina_3' then 'ingles'
        when 'disciplina_4' then 'matematica'
    end as disciplina,
    frequencia::double precision
from raw
