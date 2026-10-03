{{
    config(
        materialized='incremental',
        unique_key='stage_event_id',
        partition_by={
            "field": "stage_entered_date",
            "data_type": "date",
            "granularity": "day"
        },
        cluster_by=["permit_id", "current_status"]
    )
}}

with source_data as (
    select
        stage_event_id,
        permit_id,
        current_status,
        stage_entered_at,
        cast(stage_entered_at as date) as stage_entered_date
    from {{ ref('stg_permit_stages') }}
    
    {% if is_incremental() %}
    where stage_entered_at >= (select max(stage_entered_at) from {{ this }})
    {% endif %}
),

ordered_stages as (
    select
        stage_event_id,
        permit_id,
        current_status,
        stage_entered_at,
        stage_entered_date,
        lead(stage_entered_at) over (
            partition by permit_id 
            order by stage_entered_at asc, stage_event_id asc
        ) as next_stage_entered_at
    from source_data
)

select
    stage_event_id,
    permit_id,
    current_status,
    stage_entered_at,
    stage_entered_date,
    next_stage_entered_at,
    case 
        when next_stage_entered_at is not null 
        then timestamp_diff(next_stage_entered_at, stage_entered_at, hour)
        else null
    end as hours_in_stage
from ordered_stages