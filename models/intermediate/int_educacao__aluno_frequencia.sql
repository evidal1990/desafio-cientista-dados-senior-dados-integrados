{{ config(materialized="ephemeral", tags=["intermediate", "educacao_raw"]) }}

with frequencia as (
    select * from {{ ref("stg_frequencia") }}
),
aluno as (
    select * from {{ ref("stg_aluno") }}
),
matricula as (
    select * from {{ ref("stg_turma") }}
)
select
    f.id_aluno,
    f.id_turma,
    f.id_escola,
    f.data_inicio,
    f.data_fim,
    f.disciplina,
    round(f.frequencia::numeric, 2) as frequencia,
    case
        when f.frequencia < 75.0 then 1
        else 0
    end as flag_frequencia_abaixo_75pct
from frequencia as f
left join aluno as a
    on f.id_aluno = a.id_aluno
left join matricula as m
    on f.id_aluno = m.id_aluno
    and f.id_turma = m.id_turma
