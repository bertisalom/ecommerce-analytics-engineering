{% macro deduplicate_latest_ingestion(partition_by_columns) %}
    {% if partition_by_columns is string %}
        {% set partition_columns = [partition_by_columns] %}
    {% else %}
        {% set partition_columns = partition_by_columns %}
    {% endif %}

    {% if not partition_columns %}
        {{ exceptions.raise_compiler_error("deduplicate_latest_ingestion requires at least one partition key.") }}
    {% endif %}

    qualify row_number() over (
        partition by {{ partition_columns | join(', ') }}
        order by ingested_at desc, ingestion_run_id desc
    ) = 1
{% endmacro %}
