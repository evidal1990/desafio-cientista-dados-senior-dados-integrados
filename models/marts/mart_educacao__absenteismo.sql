{{ config(materialized="table", tags=["marts", "educacao"]) }}

/*
  Mart de absenteísmo — substitua a agregação placeholder pela métrica de negócio
  (ex.: taxa de alunos abaixo de 75% de frequência por região/escola).
*/
select
  count(*) as total_observacoes_frequencia_aluno
from {{ ref("int_educacao__aluno_frequencia") }}
