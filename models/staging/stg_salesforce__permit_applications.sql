with source as (
    select * from {{ source('salesforce', 'permit_applications') }}
),

renamed as (
    select
        id as permit_id,
        opportunity_id,
        status,
        cast(submitted_date as date) as submitted_date,
        cast(issued_date as date) as issued_date,
        _fct_synced as synced_at
    from source
)

select * from renamed