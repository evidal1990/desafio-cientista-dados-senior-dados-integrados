/*
  Regra: para cada data_inicio na lista ordenada de períodos distintos, a *seguinte*
  data_inicio (lead) deve ser *maior* que a actual (ordem temporal estrita entre períodos).

  Só avalia linhas onde existe próximo valor (lead não nulo). a última linha não tem
  próxima data e não entra no filtro — evita falso positivo do padrão coalesce(lead, x)=x.
*/

with
	lista_datas_inicio as (
		select distinct
			data_inicio,
			data_fim
		from
			{{ ref("stg_frequencia") }}
		order by
			data_inicio,
			data_fim
	),
	validacao_datas_de_inicio as (
		select
			data_inicio,
			lead(data_inicio) over (
				order by
					data_inicio,
					data_fim
			) as proxima_data_inicio,
			lead(data_inicio) over (
				order by
					data_inicio,
					data_fim
			) > data_inicio as proxima_data_inicio_maior_que_anterior
		from
			lista_datas_inicio
	)
select
	data_inicio,
	proxima_data_inicio,
	proxima_data_inicio_maior_que_anterior
from
	validacao_datas_de_inicio
where
	proxima_data_inicio is not null
	and proxima_data_inicio_maior_que_anterior = false
