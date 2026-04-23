{{ config(tags=["staging", "educacao_raw"]) }}

select 
  id_escola::int,
  bairro::int
from {{ source("educacao_raw", "escola") }}
