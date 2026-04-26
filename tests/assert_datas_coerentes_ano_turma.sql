/*
  regra: ano extraído de data_inicio e data_fim (frequência) deve coincidir com ano da turma.
  falha se existir par período × turma com incoerência.
*/

with
	frequencia as (
		select distinct
			id_aluno,
			id_turma,
			data_inicio,
			data_fim
		from
			{{ ref("stg_frequencia") }}
	),
	turma as (
		select distinct
			ano,
			id_aluno,
			id_turma
		from
			{{ ref("stg_turma") }}
	),
	ano_turma_frequencia as (
		select
			f.data_inicio,
			f.data_fim,
			t.ano,
			case
				when extract(
					year
					from
						f.data_inicio
				) = t.ano then 1
				else 0
			end as data_inicio_coerente_com_ano,
			case
				when extract(
					year
					from
						f.data_fim
				) = t.ano then 1
				else 0
			end as data_fim_coerente_com_ano
		from
			frequencia f
		inner join
			turma t on t.id_aluno = f.id_aluno and t.id_turma = f.id_turma
	)
select
	data_inicio,
	data_fim,
	ano,
	data_inicio_coerente_com_ano,
	data_fim_coerente_com_ano
from
	ano_turma_frequencia
where
	data_inicio_coerente_com_ano = 0
	or data_fim_coerente_com_ano = 0
