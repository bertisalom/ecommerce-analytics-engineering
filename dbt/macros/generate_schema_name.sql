{% macro generate_schema_name(custom_schema_name, node) %}
    {% set ci_suffix = env_var('DBT_CI_SCHEMA_SUFFIX', '') | trim %}

    {% if custom_schema_name is none %}
        {% set base_schema = target.schema %}
    {% else %}
        {% set base_schema = custom_schema_name | trim %}
    {% endif %}

    {% if target.name == 'ci' and ci_suffix %}
        {{ base_schema }}_ci_{{ ci_suffix }}
    {% else %}
        {{ base_schema }}
    {% endif %}
{% endmacro %}
