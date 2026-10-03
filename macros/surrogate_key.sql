{#
    Macro: surrogate_key

    Generates a consistent surrogate key by hashing one or more columns.
    Useful for creating deterministic unique identifiers.

    Usage:
        {{ surrogate_key(['column1', 'column2']) }}

    Example:
        select
            {{ surrogate_key(['account_id', 'permit_id']) }} as permit_account_key,
            *
        from my_table
#}

{%- macro surrogate_key(column_list) -%}
    cast(md5(concat_ws('||', {% for col in column_list %}cast({{ col }} as varchar){% if not loop.last %}, {% endif %}{% endfor %})) as varchar)
{%- endmacro -%}
