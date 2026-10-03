{%- macro generate_alias_name(custom_alias_name=none, node=none) -%}
    {%- if custom_alias_name is none -%}
        {%- set alias = node.name -%}
    {%- else -%}
        {%- set alias = custom_alias_name -%}
    {%- endif -%}

    {%- if node.get("config", {}).get("alias") -%}
        {{ return(node.get("config", {}).get("alias")) }}
    {%- else -%}
        {{ return(alias) }}
    {%- endif -%}
{%- endmacro -%}
