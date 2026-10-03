with source as (
    select * from {{ source('salesforce', 'accounts') }}
),

renamed as (
    select
        id,
        name,
        type,
        industry,
        annual_revenue,
        employee_count,
        billing_street,
        billing_city,
        billing_state,
        billing_postal_code,
        billing_country,
        phone,
        website,
        created_date,
        last_modified_date,
        _fct_synced as synced_at
    from source
)

select * from renamed
