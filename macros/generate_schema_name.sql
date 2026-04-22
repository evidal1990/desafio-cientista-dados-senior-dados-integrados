{#-
  Dev (e targets != prod): models sem `+schema` → `vars.raw_schema` (ex.: raw_educacao),
  alinhado às tabelas brutas e à carga Parquet.

  Prod: volta ao padrão dbt (`target.schema` do profile, com sufixo se houver `+schema`).

  Se um model definir `+schema: x`, o schema final é `{{ target.schema }}_x`.
-#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if target.name == 'prod' -%}
        {%- if custom_schema_name is none -%}
            {{ target.schema }}
        {%- else -%}
            {{ target.schema }}_{{ custom_schema_name | trim }}
        {%- endif -%}
    {%- else -%}
        {%- if custom_schema_name is none -%}
            {{ var('raw_schema') }}
        {%- else -%}
            {{ target.schema }}_{{ custom_schema_name | trim }}
        {%- endif -%}
    {%- endif -%}
{%- endmacro %}
