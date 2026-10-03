{#
    Macro: cents_to_dollars

    Converts currency values stored in cents to dollars.
    Useful for consistent formatting of financial data from Salesforce.

    Usage:
        {{ cents_to_dollars('amount_cents') }}

    Example:
        select
            account_id,
            {{ cents_to_dollars('amount') }} as amount_dollars
        from my_table
#}

{%- macro cents_to_dollars(column) -%}
    round({{ column }} / 100.0, 2)
{%- endmacro -%}
