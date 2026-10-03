{{
    config(
        materialized='table'
    )
}}

with accounts as (
    select
        id as account_id,
        name as account_name,
        type as account_type
    from {{ ref('stg_salesforce__accounts') }}
),

opportunities as (
    select
        id as opportunity_id,
        account_id,
        amount as project_amount
    from {{ ref('stg_salesforce__opportunities') }}
),

permits as (
    select
        permit_id,
        opportunity_id,
        status,
        submitted_date,
        issued_date,
        case
            when issued_date is not null and submitted_date is not null 
            then date_diff(issued_date, submitted_date, day)
            else null
        end as turnaround_days
    from {{ ref('stg_salesforce__permit_applications') }}
),

joined as (
    select
        a.account_id,
        a.account_name,
        a.account_type,
        o.project_amount,
        p.permit_id,
        p.status,
        p.submitted_date,
        p.issued_date,
        p.turnaround_days
    from accounts a
    inner join opportunities o on a.account_id = o.account_id
    inner join permits p on o.opportunity_id = p.opportunity_id
)

select
    account_id,
    account_name,
    account_type,
    count(permit_id) as total_permits_submitted,
    count(case when status = 'Issued' then 1 end) as total_permits_issued,
    avg(turnaround_days) as avg_turnaround_days,
    sum(project_amount) as total_project_capex
from joined
group by 1, 2, 3