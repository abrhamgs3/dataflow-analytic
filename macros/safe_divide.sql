{#
    Macro: safe_divide

    Safely divides two numbers, returning null if denominator is zero.
    Prevents division by zero errors in calculated fields.

    Usage:
        {{ safe_divide(numerator, denominator) }}

    Example:
        select
            account_id,
            {{ safe_divide('total_permits_issued', 'total_permits_submitted') }} as approval_rate
        from my_table
#}

{%- macro safe_divide(numerator, denominator, decimals=2) -%}
    case
        when {{ denominator }} = 0 then null
        else round({{ numerator }} / {{ denominator }}, {{ decimals }})
    end
{%- endmacro -%}
