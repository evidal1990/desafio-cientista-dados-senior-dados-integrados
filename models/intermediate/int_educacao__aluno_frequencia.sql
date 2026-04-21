{{ config(materialized="ephemeral", tags=["intermediate", "educacao"]) }}

/*
  Une frequência ao cadastro de aluno para métricas de presença/absenteísmo.
  Ajuste os nomes das chaves (ex.: id_aluno) conforme o esquema real das fontes.
*/
with frequencia as (
  select * from {{ ref("stg_educacao__frequencia") }}
),
aluno as (
  select * from {{ ref("stg_educacao__aluno") }}
)
select
  frequencia.*,
  aluno.id_aluno as _fk_aluno_resolvido
from frequencia
left join aluno
  on frequencia.id_aluno = aluno.id_aluno
