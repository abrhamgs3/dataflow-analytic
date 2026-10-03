with source as (
    select * from {{ source('salesforce', 'opportunities') }}
),

renamed as (
    select
        id,
        account_id,
        name as opportunity_name,
        stage_name,
        close_date,
        amount,
        probability_percent,
        forecast_category,
        type as opportunity_type,
        created_date,
        last_modified_date,
        _fct_synced as synced_at
    from source
),

calculated as (
    select
        *,
        round(amount * (probability_percent / 100), 2) as weighted_amount
    from renamed
)

select * from calculated
