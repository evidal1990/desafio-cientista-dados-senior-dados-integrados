{{ config(materialized="ephemeral", tags=["intermediate", "educacao_raw"]) }}

with frequencia as (
  select * from {{ ref("stg_frequencia") }}
),
aluno as (
  select * from {{ ref("stg_aluno") }}
),
avaliacao as (
  select * from {{ ref("stg_avaliacao") }}
)
select
  aluno.id_aluno,
  avaliacao.bimestre,
  frequencia.disciplina,
  frequencia.frequencia,
  avaliacao.lingua_portuguesa,
  avaliacao.ciencias,
  avaliacao.ingles,
  avaliacao.matematica
from frequencia
left join aluno
  on frequencia.id_aluno = aluno.id_aluno
left join avaliacao
  on frequencia.id_aluno = avaliacao.id_aluno
group by all
