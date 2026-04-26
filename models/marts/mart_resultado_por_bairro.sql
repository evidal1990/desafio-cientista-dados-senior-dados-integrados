{{ config(materialized="table", schema="marts", tags=["marts", "raw"]) }}

/*
  Definições
  ----------
  População incluída: igual à de mart_resultado_por_faixa_etaria (via
  int_media_disciplina_por_aluno): aluno × turma com lingua_portuguesa, matemática e ciências não nulas,
  presença em stg_turma e stg_aluno com bairro não nulo. Cada linha do mart é um bairro
  (identificador anonimizado na fonte).

  O que este mart não mede
  ------------------------
  Os mesmos limites da mart por faixa etária (frequência, inglês, inferência externa, etc.).
  Não atribui causas geográficas ao desempenho (correlação ≠ causalidade).
*/
select
    bairro,
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
    bairro
