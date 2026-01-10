# Data Marts Deployment Guide

## 📍 Dataset Location

**BigQuery Dataset:** `dw-health-insurance-bipm.raw_dataset_data_marts`

All 5 data marts will be deployed to this separate dataset for easy access control and organization.

---

## 🚀 Quick Start

### Step 1: Build Dependencies (Star Schema)

Data marts require the star schema to be built first:

```bash
cd /Users/nikolasjackaltran/Desktop/HWR/DWH/final_project/dbt_health_insurance

# Build star schema first
dbt run --select star_schema
```

### Step 2: Build Data Marts

```bash
# Build all data marts
dbt run --select data_marts

# Or build individually
dbt run --select dm_health_by_demographics
dbt run --select dm_insurance_profitability
dbt run --select dm_sleep_health_analysis
dbt run --select dm_customer_360
dbt run --select dm_data_quality_dashboard
```

### Step 3: Verify Deployment

```sql
-- Check all data marts were created
SELECT table_name, row_count, size_bytes
FROM `dw-health-insurance-bipm.raw_dataset_data_marts.__TABLES__`
ORDER BY table_name;
```

---

## 📊 Expected Output

After deployment, you should see:

```
dw-health-insurance-bipm
└── raw_dataset_data_marts
    ├── dm_health_by_demographics (~150 rows)
    ├── dm_insurance_profitability (~200 rows)
    ├── dm_sleep_health_analysis (~80 rows)
    ├── dm_customer_360 (~72 rows)
    └── dm_data_quality_dashboard (~50 rows)
```

---

## 🔗 Full Pipeline

### Complete Data Warehouse Flow

```bash
# 1. Build staging views (source → staging)
dbt run --select staging

# 2. Build cleaned tables (staging → cleaned)
dbt run --select cleaned

# 3. Build attribution table (cleaned → attribution)
dbt run --select attribution

# 4. Build star schema (attribution → dimensions + fact)
dbt run --select star_schema

# 5. Build data marts (star schema → analytics)
dbt run --select data_marts

# Or run everything
dbt run
```

---

## 📋 Data Marts Summary

| Data Mart | Rows | Grain | Primary Users |
|-----------|------|-------|---------------|
| **dm_health_by_demographics** | ~150 | age_group × gender × family_status | Public Health, Actuaries |
| **dm_insurance_profitability** | ~200 | occupation × wealth × insurance_status | Underwriters, Finance |
| **dm_sleep_health_analysis** | ~80 | sleep_disorder × activity × stress | Sleep Researchers, Wellness |
| **dm_customer_360** | ~72 | PersonID (customer-level) | Customer Service, Sales |
| **dm_data_quality_dashboard** | ~50 | data_source × quality_dimension | Data Engineering, Stewards |

---

## 🎯 Quick Validation Queries

### 1. Check dm_customer_360

```sql
SELECT
    customer_segment,
    health_status,
    COUNT(*) as customers,
    AVG(health_risk_score) as avg_risk_score,
    AVG(lifetime_profit_contribution) as avg_profit
FROM `dw-health-insurance-bipm.raw_dataset_data_marts.dm_customer_360`
GROUP BY customer_segment, health_status
ORDER BY customer_segment, health_status;
```

### 2. Check dm_insurance_profitability

```sql
SELECT
    occupational_category,
    wealth_bracket,
    net_profit,
    loss_ratio_pct,
    unique_customers
FROM `dw-health-insurance-bipm.raw_dataset_data_marts.dm_insurance_profitability`
ORDER BY net_profit DESC
LIMIT 10;
```

### 3. Check dm_data_quality_dashboard

```sql
SELECT
    data_source,
    quality_dimension,
    overall_quality_score,
    total_records
FROM `dw-health-insurance-bipm.raw_dataset_data_marts.dm_data_quality_dashboard`
WHERE data_source = 'All Sources';
```

---

## 🔧 Troubleshooting

### Issue: "Table not found: dim_person"

**Solution:** Build star schema first
```bash
dbt run --select star_schema
dbt run --select data_marts
```

### Issue: "Column not found: PersonID"

**Solution:** Check that fact_health_metrics was built successfully
```bash
dbt run --select fact_health_metrics --full-refresh
dbt run --select data_marts
```

### Issue: Data marts are empty

**Solution:** Verify star schema has data
```sql
SELECT COUNT(*) FROM `dw-health-insurance-bipm.raw_dataset_star_schema.fact_health_metrics`;
SELECT COUNT(*) FROM `dw-health-insurance-bipm.raw_dataset_star_schema.dim_person`;
```

---

## 📈 BI Tool Setup

### Looker

1. Add BigQuery connection
2. Point to `dw-health-insurance-bipm.raw_dataset_data_marts`
3. Create Explores for each data mart
4. Build dashboards using pre-aggregated fields

### Tableau

1. Connect to BigQuery
2. Select `raw_dataset_data_marts` dataset
3. Drag tables to canvas
4. Create calculated fields for custom metrics
5. Publish workbooks

### Power BI

1. Get Data → BigQuery
2. Enter project: `dw-health-insurance-bipm`
3. Select dataset: `raw_dataset_data_marts`
4. Import tables
5. Create relationships (if needed)
6. Build reports

---

## 🔐 Access Control

### Grant BI Team Read Access

```sql
-- Grant read access to data marts dataset
GRANT `roles/bigquery.dataViewer`
ON SCHEMA `dw-health-insurance-bipm.raw_dataset_data_marts`
TO 'group:bi-team@company.com';
```

### Grant Individual User Access

```sql
-- Grant to specific user
GRANT `roles/bigquery.dataViewer`
ON SCHEMA `dw-health-insurance-bipm.raw_dataset_data_marts`
TO 'user:analyst@company.com';
```

---

## 📊 Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                   RAW SOURCES                           │
│  raw_dataset (sleep, smartwatch, insurance)             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                STAGING LAYER (Views)                    │
│  raw_dataset_staging (4 views)                          │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│               CLEANED LAYER (Tables)                    │
│  raw_dataset_cleaned (4 cleaned + 1 attribution)        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│           STAR SCHEMA (Dimensional Model)               │
│  raw_dataset_star_schema                                │
│    ├── dim_person (72 rows)                             │
│    ├── dim_occupation (36 rows)                         │
│    ├── dim_insurance (97 rows)                          │
│    └── fact_health_metrics (~94K rows)                  │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│            DATA MARTS (Analytics Layer)                 │
│  raw_dataset_data_marts                                 │
│    ├── dm_health_by_demographics                        │
│    ├── dm_insurance_profitability                       │
│    ├── dm_sleep_health_analysis                         │
│    ├── dm_customer_360                                  │
│    └── dm_data_quality_dashboard                        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
           ┌──────────────────────┐
           │   BI TOOLS & APPS    │
           │  • Looker            │
           │  • Tableau           │
           │  • Power BI          │
           │  • Custom Dashboards │
           └──────────────────────┘
```

---

**Created:** 2026-01-10  
**dbt Version:** 1.7+  
**BigQuery Location:** EU  
**Total Data Marts:** 5
