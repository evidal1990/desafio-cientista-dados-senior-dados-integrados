{{ config(materialized="ephemeral", tags=["intermediate", "educacao_raw"]) }}

with avaliacao_sem_duplicados as (
    select distinct
        id_aluno,
		id_turma,
		coalesce(lingua_portuguesa, 0) as lingua_portuguesa,
		coalesce(matematica, 0) as matematica,
		coalesce(ciencias, 0) as ciencias
    from {{ ref("stg_avaliacao") }}
	where 
		lingua_portuguesa is not null
		and matematica is not null
		and ciencias is not null
),

aluno_sem_duplicados as (
    select distinct
        id_turma,
        id_aluno,
		faixa_etaria
    from {{ ref("stg_aluno") }}
),
turma_sem_duplicados as (
    select distinct
        id_turma,
        id_aluno
    from {{ ref("stg_turma") }}
),
media_disciplinas as(
	select 
		av.id_aluno,
		av.id_turma,
		al.faixa_etaria,
		round(avg(lingua_portuguesa)::numeric, 1) as media_lingua_portuguesa,
		round(avg(matematica)::numeric, 1) as media_matematica,
		round(avg(ciencias)::numeric, 1) as media_ciencias
	from
		avaliacao_sem_duplicados av
	inner join
		aluno_sem_duplicados al on al.id_aluno = av.id_aluno
		and al.id_turma = av.id_turma
	inner join
		turma_sem_duplicados tu on tu.id_aluno = av.id_aluno
		and tu.id_turma = av.id_turma
	group by
		av.id_aluno,
		av.id_turma,
		al.faixa_etaria
)

select 
	id_aluno,
	id_turma,
	faixa_etaria,
	case
		when (media_lingua_portuguesa) >= 5.0 
		then 'Aprovado' 
		else 'Reprovado'
	end as resultado_lingua_portuguesa,
	case
		when (media_matematica) >= 5.0 
		then 'Aprovado' 
		else 'Reprovado'
	end as resultado_matematica,
	case
		when (media_ciencias) >= 5.0 
		then 'Aprovado' 
		else 'Reprovado'
	end as resultado_ciencias
from 
	media_disciplinas
order by
		id_aluno,
		id_turma