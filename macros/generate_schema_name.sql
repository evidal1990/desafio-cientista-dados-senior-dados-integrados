{#-
  Dev (e targets != prod):
  - `+schema: staging` | `intermediate` | `marts` → nomes físicos literais (**`staging`**, **`intermediate`**, **`marts`**),
    sem prefixar `target.schema` (evita `raw_educacao_staging` só pelo `schema:` do profile).
  - Sem `+schema` → `vars.raw_schema` (tabelas brutas / models sem custom).
  - As **sources** usam `vars.raw_schema` em `_sources.yml` (carga Python).

  Prod:
  - Sem `+schema` → `target.schema`.
  - Com `+schema` → `target.schema` + `_` + custom (ex.: `desafio_rmi_ds_prod_staging`).

  Intermediate `ephemeral` não cria relação no warehouse.
-#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is not none and custom_schema_name | trim | lower == 'marts' -%}
        marts
    {%- elif target.name == 'prod' -%}
        {%- if custom_schema_name is none -%}
            {{ target.schema }}
        {%- else -%}
            {{ target.schema }}_{{ custom_schema_name | trim }}
        {%- endif -%}
    {%- else -%}
        {%- if custom_schema_name is not none and custom_schema_name | trim | lower in ['staging', 'intermediate'] -%}
            {{ custom_schema_name | trim }}
        {%- elif custom_schema_name is none -%}
            {{ var('raw_schema') }}
        {%- else -%}
            {{ target.schema }}_{{ custom_schema_name | trim }}
        {%- endif -%}
    {%- endif -%}
{%- endmacro %}
