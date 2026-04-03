{% macro generate_schema_name(custom_schema_name, node) %}
    {% set ci_suffix = env_var('DBT_CI_SCHEMA_SUFFIX', '') | trim %}

    {% if custom_schema_name is none %}
        {{ target.schema }}
    {% elif target.name == 'prod' %}
        {{ custom_schema_name | trim }}
    {% elif target.name == 'ci' and ci_suffix %}
        {{ custom_schema_name | trim }}_ci_{{ ci_suffix }}
    {% elif target.name == 'dev' %}
        {{ custom_schema_name | trim }}_{{ target.schema }}
    {% else %}
        {{ custom_schema_name | trim }}
    {% endif %}
{% endmacro %}
