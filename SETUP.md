# SQL Permit Project - Setup Guide

Step-by-step instructions to get the SQL-Permit dbt project up and running.

## Prerequisites

### 1. Install dbt
```bash
pip install dbt-snowflake  # For Snowflake
# OR
pip install dbt-postgres   # For PostgreSQL
# OR
pip install dbt-bigquery   # For Google BigQuery
```

Verify installation:
```bash
dbt --version
```

### 2. Salesforce API Access
Ensure your Salesforce instance has API access enabled and you have:
- API username/token
- Appropriate permissions for Account, Opportunity, Permit_Application, and Permit_Stages objects

### 3. Data Warehouse Access
- Snowflake: Account ID, user credentials, warehouse
- BigQuery: GCP project, dataset
- PostgreSQL: Host, user, password, database

## Configuration

### Step 1: Create dbt Profile

Copy the example profile to your dbt config directory:

**macOS/Linux:**
```bash
cp profiles.yml.example ~/.dbt/profiles.yml
```

**Windows:**
```powershell
Copy-Item profiles.yml.example -Destination $env:USERPROFILE\.dbt\profiles.yml
```

### Step 2: Update Profile Configuration

Edit `~/.dbt/profiles.yml` with your warehouse credentials:

**For Snowflake:**
```yaml
salesforce:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: xy12345.us-east-1
      user: your_username
      password: your_password
      role: analytics_developer
      database: analytics
      schema: dev
      warehouse: compute_wh
      threads: 4
```

**For BigQuery:**
```yaml
salesforce:
  target: dev
  outputs:
    dev:
      type: bigquery
      project-id: my-gcp-project
      dataset-id: sql_permit_dev
      threads: 4
      location: US
```

### Step 3: Create Salesforce Source Configuration

Create `models/staging/sources_env.yml` with your actual source schema:

```yaml
version: 2

sources:
  - name: salesforce
    description: Raw Salesforce data
    database: raw_data          # Your raw database name
    schema: salesforce_export   # Your Salesforce export schema
    tables:
      - name: accounts
      - name: opportunities
      - name: permit_applications
      - name: permit_stages
```

Alternative: If your sources are already defined elsewhere, update the source references in `models/staging/sources.yml`.

## Installation

### Step 1: Navigate to Project Directory
```bash
cd sql_permit
```

### Step 2: Install dbt Dependencies
```bash
dbt deps
```

This installs any dbt packages defined in `packages.yml` (currently none, but good practice).

### Step 3: Test Database Connection
```bash
dbt debug
```

Expected output:
```
All checks passed!
```

If you see connection errors, verify:
- Credentials in `~/.dbt/profiles.yml`
- Network/firewall access to data warehouse
- Data warehouse is running

## First Run

### Step 1: Run dbt (Development)
```bash
dbt run
```

This will execute all models in order:
1. Staging models (views)
2. Intermediate models (tables)
3. Mart models (tables - incremental)

### Step 2: Run Tests
```bash
dbt test
```

All tests should pass if:
- Source data exists and is valid
- Referential integrity is maintained
- No NULL values in required fields

### Step 3: Generate Documentation
```bash
dbt docs generate
dbt docs serve
```

Open browser to `localhost:8000` to view interactive documentation.

## Verify Success

After a successful run, you should have:

**In your warehouse (schema: dev):**
- `stg_salesforce__accounts` - staging view
- `stg_salesforce__opportunities` - staging view
- `stg_salesforce__permit_applications` - staging view
- `stg_permit_stages` - staging view
- `int_customer_permit_performance` - intermediate table
- `fct_permit_lifecycle` - fact table (incremental)

**Documentation:**
- dbt docs site showing all models, columns, descriptions, lineage

## Common Issues & Solutions

### Issue: "Target database does not exist"
**Solution:** Create the target schema in your data warehouse:
```sql
CREATE SCHEMA dev;  -- Snowflake/PostgreSQL
CREATE DATASET dev; -- BigQuery
```

### Issue: "Source table not found"
**Solution:** Verify source schema name in `sources.yml` matches your actual raw data location.

### Issue: Incremental model fails on first run
**Solution:** Run with full refresh:
```bash
dbt run --full-refresh -s fct_permit_lifecycle
```

### Issue: Tests fail with "referential integrity" errors
**Solution:** 
1. Check data quality in source tables
2. Verify foreign key values exist in referenced tables
3. Temporarily skip tests: `dbt test --skip-tests`

## Regular Maintenance

### Run Daily (or on schedule):
```bash
dbt run
dbt test
```

### Run Monthly (or quarterly):
```bash
dbt run --full-refresh
```

### Monitor Performance:
Check dbt run logs for slow models (look for duration times).

### Update Documentation:
```bash
dbt docs generate
dbt docs serve
```

## Next Steps

1. ✅ Connect to Omni for BI visualization
2. ✅ Create dashboards using `customer_permit_performance` view
3. ✅ Set up dbt Cloud for automated runs and monitoring
4. ✅ Add additional marts/views as business requirements evolve
5. ✅ Configure dbt tests for ongoing data quality monitoring

## Support & Troubleshooting

- Review logs: `dbt run --debug`
- Check dbt docs: https://docs.getdbt.com/
- Validate SQL: Run models manually against warehouse
- Review source data for quality issues

---

**Setup Last Updated:** 2026-10-03  
**dbt Version Tested:** 1.5.0+
