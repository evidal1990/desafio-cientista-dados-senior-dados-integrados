{{ config(materialized="table", schema="marts", tags=["marts", "raw"]) }}

/*
  Percentual de alunos aprovados e reprovados por disciplina e faixa etária.
*/
select
    faixa_etaria,
    count(*) as total_alunos,
    round(
        count(*) filter (where resultado_lingua_portuguesa = 'Aprovado')::numeric
            / nullif(count(*), 0) * 100,
        2
    ) as pct_alunos_aprovados_lingua_portuguesa,
    round(
        count(*) filter (where resultado_lingua_portuguesa = 'Reprovado')::numeric
            / nullif(count(*), 0) * 100,
        2
    ) as pct_alunos_reprovados_lingua_portuguesa,
    round(
        count(*) filter (where resultado_matematica = 'Aprovado')::numeric
            / nullif(count(*), 0) * 100,
        2
    ) as pct_alunos_aprovados_matematica,
    round(
        count(*) filter (where resultado_matematica = 'Reprovado')::numeric
            / nullif(count(*), 0) * 100,
        2
    ) as pct_alunos_reprovados_matematica,
    round(
        count(*) filter (where resultado_ciencias = 'Aprovado')::numeric
            / nullif(count(*), 0) * 100,
        2
    ) as pct_alunos_aprovados_ciencias,
    round(
        count(*) filter (where resultado_ciencias = 'Reprovado')::numeric
            / nullif(count(*), 0) * 100,
        2
    ) as pct_alunos_reprovados_ciencias
from {{ ref("int_media_disciplina_por_aluno") }}
group by
    faixa_etaria
