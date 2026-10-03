with source as (
    select * from {{ source('salesforce', 'permit_stages') }}
),

renamed as (
    select
        id as stage_event_id,
        permit_id,
        status as current_status,
        cast(stage_entered_at as timestamp) as stage_entered_at,
        entered_by_user_id,
        notes,
        created_at,
        _fct_synced as synced_at
    from source
),

validated as (
    select
        stage_event_id,
        permit_id,
        current_status,
        stage_entered_at,
        entered_by_user_id,
        notes,
        created_at,
        synced_at
    from renamed
    where stage_event_id is not null
        and permit_id is not null
        and current_status is not null
        and stage_entered_at is not null
)

select * from validated
