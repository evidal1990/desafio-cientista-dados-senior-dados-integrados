/*
  Regra: em cada par (data_inicio, data_fim) distinto, data_fim deve ser maior que data_inicio.
  Teste falha se existir linha com data_fim <= data_inicio (marca 0 no case).
*/

with
	validacao_data_inicio_data_fim as (
		select distinct
			data_inicio,
			data_fim,
			case
				when data_fim > data_inicio
				then 1
				else 0
			end as data_fim_maior_data_inicio
		from
			{{ ref("stg_frequencia") }}
	)
select
	data_inicio,
	data_fim,
	data_fim_maior_data_inicio
from
	validacao_data_inicio_data_fim
where
	data_fim_maior_data_inicio = 0
