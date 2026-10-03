# SQL-Permit Data Dictionary

Complete reference guide for all tables, columns, and metrics in the SQL-Permit project.

---

## Staging Layer (Silver)

Raw data from Salesforce, cleaned and renamed for consistency.

### stg_salesforce__accounts

**Source:** Salesforce `Account` object  
**Materialization:** VIEW  
**Refresh:** Daily (via Salesforce sync)

| Column | Type | Description | Key | Null? |
|--------|------|-------------|-----|-------|
| id | STRING | Unique account identifier | PK | N |
| name | STRING | Account organization name | | N |
| type | STRING | Account classification (Customer, Prospect, Partner) | | Y |
| industry | STRING | Industry classification (Technology, Finance, etc.) | | Y |
| annual_revenue | NUMERIC | Annual revenue in USD | | Y |
| employee_count | INTEGER | Number of employees | | Y |
| billing_street | STRING | Street address | | Y |
| billing_city | STRING | City | | Y |
| billing_state | STRING | State/Province | | Y |
| billing_postal_code | STRING | Postal code | | Y |
| billing_country | STRING | Country | | Y |
| phone | STRING | Phone number | | Y |
| website | STRING | Company website | | Y |
| created_date | TIMESTAMP | Salesforce record creation time | | Y |
| last_modified_date | TIMESTAMP | Last modification time | | Y |
| synced_at | TIMESTAMP | Data warehouse sync timestamp | | Y |

---

### stg_salesforce__opportunities

**Source:** Salesforce `Opportunity` object  
**Materialization:** VIEW  
**Refresh:** Daily (via Salesforce sync)

| Column | Type | Description | Key | Null? |
|--------|------|-------------|-----|-------|
| id | STRING | Unique opportunity identifier | PK | N |
| account_id | STRING | Foreign key to Account | FK | N |
| opportunity_name | STRING | Opportunity/project name | | Y |
| stage_name | STRING | Sales stage (Pipeline, Proposal, Negotiation, Closed Won, Closed Lost) | | Y |
| close_date | DATE | Expected or actual close date | | Y |
| amount | NUMERIC | Opportunity amount in USD | | Y |
| probability_percent | NUMERIC | Win probability 0-100% | | Y |
| weighted_amount | NUMERIC | amount × (probability_percent/100) | | Y |
| forecast_category | STRING | Forecast categorization | | Y |
| opportunity_type | STRING | Opportunity classification | | Y |
| created_date | TIMESTAMP | Record creation time | | Y |
| last_modified_date | TIMESTAMP | Last modification time | | Y |
| synced_at | TIMESTAMP | Data warehouse sync timestamp | | Y |

---

### stg_salesforce__permit_applications

**Source:** Salesforce `Permit_Applications__c` custom object  
**Materialization:** VIEW  
**Refresh:** Daily (via Salesforce sync)

| Column | Type | Description | Key | Null? |
|--------|------|-------------|-----|-------|
| permit_id | STRING | Unique permit application identifier | PK | N |
| opportunity_id | STRING | Foreign key to Opportunity | FK | N |
| status | STRING | Current permit status (Submitted, Under Review, Issued, Rejected) | | N |
| submitted_date | DATE | Application submission date | | Y |
| issued_date | DATE | Permit issuance date (null if not yet issued) | | Y |
| synced_at | TIMESTAMP | Data warehouse sync timestamp | | Y |

**Business Rules:**
- Status values: Submitted, Under Review, Approved, Issued, Rejected, On Hold, Cancelled
- issued_date can only exist if status = 'Issued'
- submitted_date ≤ issued_date (if both non-null)

---

### stg_permit_stages

**Source:** Salesforce `Permit_Stages__c` custom object (Audit Log)  
**Materialization:** VIEW  
**Refresh:** Daily (via Salesforce sync)

| Column | Type | Description | Key | Null? |
|--------|------|-------------|-----|-------|
| stage_event_id | STRING | Unique stage transition event identifier | PK | N |
| permit_id | STRING | Foreign key to Permit Application | FK | N |
| current_status | STRING | Status during this stage event | | N |
| stage_entered_at | TIMESTAMP | Timestamp of stage entry (UTC) | | N |
| entered_by_user_id | STRING | Salesforce User ID who created transition | | Y |
| notes | STRING | Transition notes/comments | | Y |
| created_at | TIMESTAMP | Event record creation time | | Y |
| synced_at | TIMESTAMP | Data warehouse sync timestamp | | Y |

**Notes:**
- One row per status change
- Ordered by stage_entered_at to reconstruct permit journey
- Enables calculation of duration in each stage

---

## Intermediate Layer (Gold)

Aggregated business logic and transformations.

### int_customer_permit_performance

**Source:** Joins accounts + opportunities + permits  
**Materialization:** TABLE  
**Refresh:** Daily  
**Grain:** One row per account

| Column | Type | Description | Key | Null? |
|--------|------|-------------|-----|-------|
| account_id | STRING | Account identifier | PK | N |
| account_name | STRING | Account name | | N |
| account_type | STRING | Account classification | | Y |
| total_permits_submitted | INTEGER | Count of submitted permits | | N |
| total_permits_issued | INTEGER | Count of issued permits | | N |
| avg_turnaround_days | NUMERIC | Average days to issuance (issued permits only) | | N |
| total_project_capex | NUMERIC | Sum of opportunity amounts (USD) | | N |

**Calculations:**
- `total_permits_submitted = count(permit_id)`
- `total_permits_issued = count(case when status='Issued' then 1)`
- `avg_turnaround_days = avg(date_diff(issued_date, submitted_date, day))` (where status='Issued')
- `total_project_capex = sum(opportunity.amount)`

---

## Mart Layer (Gold)

Final analytics tables optimized for reporting.

### fct_permit_lifecycle ⭐ Key Fact Table

**Source:** stg_permit_stages  
**Materialization:** INCREMENTAL TABLE  
**Grain:** One row per permit stage event  
**Partitioning:** By stage_entered_date (daily)  
**Clustering:** By permit_id, current_status  
**Refresh:** Daily (incremental)

| Column | Type | Description | Key | Null? |
|--------|------|-------------|-----|-------|
| stage_event_id | STRING | Stage transition event ID | PK | N |
| permit_id | STRING | Permit application ID | FK | N |
| current_status | STRING | Status at this event | | N |
| stage_entered_at | TIMESTAMP | When status became active (UTC) | | N |
| stage_entered_date | DATE | Date of stage entry (partition key) | | N |
| next_stage_entered_at | TIMESTAMP | When next status became active (null if current) | | Y |
| hours_in_stage | NUMERIC | Hours between this status and next (null if current) | | Y |

**Incremental Strategy:**
```sql
where stage_entered_at >= (select max(stage_entered_at) from fct_permit_lifecycle)
```

**Business Uses:**
- Permit journey analysis (sequence of statuses)
- Processing time analysis (hours_in_stage)
- Bottleneck identification (which status takes longest?)
- SLA monitoring (turnaround time compliance)

---

## BI Layer

Omni analytics views for dashboarding.

### customer_permit_performance.view (Omni)

**Dimensions (For Filtering/Grouping):**
- `account_id` - Account identifier
- `account_name` - Customer name
- `account_type` - Customer tier classification

**Measures (Aggregated Metrics):**
- `total_permits_submitted` - Volume of applications
- `total_permits_issued` - Approved count
- `permit_approval_rate` - % approved (issued/submitted)
- `avg_turnaround_days` - Processing efficiency (days)
- `total_project_capex` - Revenue/project value ($)
- `avg_project_value` - Average value per permit ($)
- `count_accounts` - Distinct account count

**Typical Dashboard Queries:**
- "Top 10 customers by permit volume"
- "Approval rates by account type"
- "Average turnaround time trends over time"
- "Total project value by region/industry"

---

## Key Metrics & KPIs

### Operational KPIs

| Metric | Formula | Target | Owner |
|--------|---------|--------|-------|
| Overall Approval Rate | issued / submitted | >85% | Operations |
| Avg Turnaround Time | avg(issued_date - submitted_date) | <45 days | Operations |
| Submission Volume | count(submitted) | Trending | Sales |
| Project Pipeline Value | sum(opportunity.amount) | $ Target | Finance |

### Customer KPIs

| Metric | Formula | Interpretation |
|--------|---------|-----------------|
| Permit Approval Rate | (permits_issued / permits_submitted) × 100 | % of submissions approved |
| Avg Project Value | total_capex / permits_submitted | Average $ per application |
| Processing Efficiency | avg_turnaround_days | Days to approval (lower=better) |

---

## Data Quality Rules

### Tests Implemented

| Table | Column | Test Type | Rule |
|-------|--------|-----------|------|
| fct_permit_lifecycle | stage_event_id | Unique | No duplicates |
| fct_permit_lifecycle | stage_event_id | Not Null | Every record has ID |
| fct_permit_lifecycle | permit_id | Not Null | Link to permit required |
| int_customer_permit_performance | account_id | Unique | One row per account |
| stg_salesforce__accounts | id | Unique, Not Null | PK integrity |

### Data Freshness SLAs

| Source | Sync Frequency | Max Age | Alert Threshold |
|--------|----------------|---------|-----------------|
| Salesforce | Daily (12am UTC) | 24 hours | >24h |
| Warehouse | 1h after sync | 25 hours | >25h |

---

## Common Queries

### Find Top Customers by Permit Volume
```sql
select 
    account_name,
    total_permits_submitted,
    total_permits_issued,
    round(100.0 * total_permits_issued / total_permits_submitted, 1) as approval_rate_pct,
    avg_turnaround_days
from int_customer_permit_performance
order by total_permits_submitted desc
limit 20
```

### Analyze Permit Processing by Status
```sql
select 
    current_status,
    count(*) as event_count,
    round(avg(hours_in_stage), 1) as avg_hours_in_status,
    round(max(hours_in_stage), 1) as max_hours_in_status
from fct_permit_lifecycle
group by current_status
order by avg_hours_in_status desc
```

### Identify Process Bottlenecks
```sql
select 
    current_status,
    avg(hours_in_stage) as avg_hours,
    percentile_cont(0.95) within group (order by hours_in_stage) as p95_hours,
    count(*) as event_count
from fct_permit_lifecycle
where hours_in_stage is not null
group by current_status
having avg(hours_in_stage) > 72  -- > 3 days
order by avg_hours desc
```

---

## Updates & Changes

| Date | Change | Impact |
|------|--------|--------|
| 2026-10-03 | Initial project setup | All models created |

---

**Last Updated:** 2026-10-03  
**Project Type:** Practice / Portfolio Project  
**Data:** Synthetic/example data (not production)  
**Questions?** Refer to README.md or SETUP.md
