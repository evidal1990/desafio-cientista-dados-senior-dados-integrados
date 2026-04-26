{{ config(materialized="table", schema="marts", tags=["marts", "raw"]) }}

/*
  Definições
  ----------
  População incluída: linhas de int_media_disciplina_por_aluno (grão aluno × turma) com
  join inner a aluno e turma; notas de lingua portuguesa, matemática e ciências todas não nulas no staging;
  inglês fora do cálculo. Alunos sem bairro são excluídos no intermediate (não entram aqui).

  O que este mart não mede
  ------------------------
  Frequência escolar, escola (além do que já foi filtrado upstream), inglês, evasão,
  comparativos entre anos, incerteza estatística ou inferência para populações fora do
  extract. Não representa alunos sem as três notas, sem par aluno×turma em turma, ou
  excluídos no intermediate.
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
