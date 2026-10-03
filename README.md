# SQL Permit Project

A data transformation and analytics project built with **dbt** and **Omni** that tracks permit lifecycle management and customer permit performance metrics from Salesforce.

## 📋 Project Overview

This project transforms raw Salesforce permit application data into analytics-ready models for business intelligence. It provides:

- **Permit Lifecycle Tracking**: Monitor the progression of permits through various operational stages
- **Customer Performance Metrics**: Analyze permit submission rates, issuance rates, and turnaround times by customer
- **Operational Insights**: Track permit processing efficiency and project valuations tied to permits

## 🏗️ Data Architecture

### Medallion Architecture (Bronze → Silver → Gold)

```
Salesforce Sources (Raw Data)
    ↓
Staging Layer (Silver) - Cleaned, renamed, validated
    ├── stg_salesforce__accounts
    ├── stg_salesforce__opportunities
    ├── stg_salesforce__permit_applications
    └── stg_permit_stages
    ↓
Intermediate Layer - Business logic, aggregations
    └── int_customer_permit_performance
    ↓
Marts Layer (Gold) - Analytics-ready tables
    └── fct_permit_lifecycle
    ↓
BI Layer (Omni) - Visualization layer
    └── customer_permit_performance.view.yaml
```

## 📁 Directory Structure

```
sql_permit/
├── models/
│   ├── staging/              # Raw data transformations
│   │   ├── stg_salesforce__accounts.sql
│   │   ├── stg_salesforce__opportunities.sql
│   │   ├── stg_salesforce__permit_applications.sql
│   │   └── stg_permit_stages.sql
│   ├── intermediate/         # Business logic & aggregations
│   │   └── int_customer_permit_performance.sql
│   └── marts/                # Final analytics tables
│       ├── fct_permit_lifecycle.sql
│       └── fct_permit_lifecycle.yml
├── omni/
│   └── views/
│       └── customer_permit_performance.view.yaml
├── dbt_project.yml           # dbt project configuration
└── README.md                 # This file
```

## 📊 Key Models

### Staging Models

#### `stg_salesforce__accounts`
Source: Salesforce Accounts table
- Core account information (id, name, type, industry)
- Contact details (phone, website)
- Location data (billing address)
- Audit timestamps (created_date, last_modified_date)

#### `stg_salesforce__opportunities`
Source: Salesforce Opportunities table
- Opportunity details (name, stage, close date)
- Financial metrics (amount, probability, weighted_amount)
- Opportunity classification (type, forecast_category)
- Links to accounts and permits

#### `stg_salesforce__permit_applications`
Source: Salesforce Permit Applications table
- Permit identifiers and status tracking
- Application timeline (submitted_date, issued_date)
- Links to opportunities for financial context
- Data sync audit trail

#### `stg_permit_stages`
Source: Salesforce Permit Stages table (Activity/Audit Log)
- Stage event tracking (id, permit_id, status)
- Timestamp of stage entry
- User audit information (entered_by_user_id)
- Validation rules to ensure data quality

### Intermediate Models

#### `int_customer_permit_performance`
**Materialization**: Table  
**Purpose**: Customer-level permit aggregation

Metrics:
- `total_permits_submitted`: Count of all permit applications
- `total_permits_issued`: Count of successfully issued permits
- `avg_turnaround_days`: Average days from submission to issuance
- `total_project_capex`: Sum of project valuations tied to permits

Dimensions:
- account_id, account_name, account_type

### Fact Models

#### `fct_permit_lifecycle` ⭐ Key Table
**Materialization**: Incremental  
**Partitioning**: By stage_entered_date (daily)  
**Clustering**: By permit_id, current_status

**Purpose**: Track permit stage transitions and duration analysis

Columns:
- `stage_event_id`: Unique identifier for each stage event (Primary Key)
- `permit_id`: Reference to permit application
- `current_status`: Status at this stage
- `stage_entered_at`: When the permit entered this status
- `stage_entered_date`: Date partition key
- `next_stage_entered_at`: When permit transitioned to next status
- `hours_in_stage`: Duration spent in current status (hours)

**Why Incremental?**
- Permit_stages table grows continuously with audit events
- Only new events since last run need processing
- Incremental loads improve performance and reduce warehouse costs

## 🔍 BI Layer

### Omni View: `customer_permit_performance`

Interactive dashboard view providing:
- **Dimensions**: account_id, account_name, account_type
- **Measures**:
  - total_permits_submitted (Sum)
  - total_permits_issued (Sum)
  - avg_turnaround_days (Average, format: 0.0 days)
  - total_project_capex (Sum, currency format: $)

## 🚀 Getting Started

### Prerequisites

1. **dbt** installed (v1.0.0 or later)
   ```bash
   pip install dbt-snowflake  # or dbt-postgres, dbt-bigquery depending on your warehouse
   ```

2. **Salesforce API Access** with source tables available

3. **Omni** account for BI visualization (optional)

### Setup

1. **Clone/download the project**
   ```bash
   cd sql_permit
   ```

2. **Configure dbt profile** (`~/.dbt/profiles.yml`)
   ```yaml
   salesforce:
     target: dev
     outputs:
       dev:
         type: snowflake  # or your warehouse
         account: [your-account]
         user: [your-username]
         password: [your-password]
         role: [your-role]
         database: [your-database]
         schema: analytics_dev
         threads: 4
         client_session_keep_alive: false
   ```

3. **Create sources YAML** (`models/staging/sources.yml`)
   Define your Salesforce source tables:
   ```yaml
   version: 2
   sources:
     - name: salesforce
       description: Raw data from Salesforce
       tables:
         - name: accounts
         - name: opportunities
         - name: permit_applications
         - name: permit_stages
   ```

4. **Run dbt**
   ```bash
   dbt deps
   dbt seed
   dbt run
   dbt test
   ```

## 📈 Data Quality & Testing

Key tests implemented:

- **Uniqueness**: stage_event_id in fct_permit_lifecycle
- **Not Null**: permit_id, current_status, stage_entered_at
- **Referential Integrity**: permit_id and account_id foreign keys
- **Date Validation**: submitted_date ≤ issued_date

Run tests with:
```bash
dbt test
```

## 🔄 Incremental Strategy

The `fct_permit_lifecycle` model uses incremental loading:

```sql
{% if is_incremental() %}
  where stage_entered_at >= (select max(stage_entered_at) from {{ this }})
{% endif %}
```

This ensures only new permit stage events are processed on subsequent runs, improving performance for tables with high-volume event logs.

## 🐛 Common Issues & Troubleshooting

### Missing Source Tables
Ensure all Salesforce source tables are defined in `models/staging/sources.yml`:
- accounts
- opportunities
- permit_applications
- permit_stages

### Incremental Failures
If `fct_permit_lifecycle` fails, reset the model:
```bash
dbt run --full-refresh
```

### Null Turnaround Days
Days are only calculated when both `submitted_date` AND `issued_date` are present. Submitted-but-not-yet-issued permits will have NULL values (expected behavior).

## 📚 Additional Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [Omni Analytics Docs](https://docs.omnilytics.com/)
- [Salesforce Schema Reference](https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects.htm)

## 👤 Author

Created as part of the SQL-Permit analytics initiative.

---

**Last Updated**: 2026-10-03  
**Status**: Production Ready
