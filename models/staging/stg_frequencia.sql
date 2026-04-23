{{ config(tags=["staging", "educacao_raw"]) }}

with source as (
    select * from {{ source("educacao_raw", "frequencia") }}
)
select
    trim(lower(id_escola::text)) as id_escola,
    trim(lower(id_aluno::text)) as id_aluno,
    id_turma::bigint,
    data_inicio::date,
    data_fim::date,
    case when disciplina = 'disciplina_1' then 'lingua_portuguesa'
         when disciplina = 'disciplina_2' then 'ciencias'
         when disciplina = 'disciplina_3' then 'ingles'
         when disciplina = 'disciplina_4' then 'matematica'
         else null
    end as disciplina,
    frequencia::float
from source
