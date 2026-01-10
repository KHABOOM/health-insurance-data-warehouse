# Star Schema Deployment Guide

## 📍 Dataset Location

The star schema models are configured to deploy to a **separate dataset** in BigQuery:

```
Project: dw-health-insurance-bipm
Dataset: raw_dataset_star_schema
```

This separation provides:
- ✅ Clear logical separation between cleaned data and analytical models
- ✅ Independent access control for BI/analytics users
- ✅ Easier to grant read-only access to star schema without exposing cleaned tables
- ✅ Better organization and maintainability

---

## 🚀 Deployment Steps

### 1. Run Star Schema Models

```bash
# Navigate to dbt project
cd dbt_health_insurance

# Run all star schema models (creates dataset + tables)
dbt run --select star_schema

# Or run in correct dependency order
dbt run --select dim_occupation dim_person dim_insurance
dbt run --select fact_health_metrics
```

### 2. Verify Deployment

```bash
# Test all models
dbt test --select star_schema
```

### 3. Check BigQuery

After running, you should see:

```
dw-health-insurance-bipm
└── raw_dataset_star_schema
    ├── dim_occupation
    ├── dim_person
    ├── dim_insurance
    └── fact_health_metrics
```

---

## 📊 Expected Table Locations

| Table | Full Path | Rows |
|-------|-----------|------|
| **dim_occupation** | `dw-health-insurance-bipm.raw_dataset_star_schema.dim_occupation` | ~36 |
| **dim_person** | `dw-health-insurance-bipm.raw_dataset_star_schema.dim_person` | ~72 |
| **dim_insurance** | `dw-health-insurance-bipm.raw_dataset_star_schema.dim_insurance` | ~97 |
| **fact_health_metrics** | `dw-health-insurance-bipm.raw_dataset_star_schema.fact_health_metrics` | ~94,000 |

---

## 🔍 Query Examples

### Query from Star Schema Dataset

```sql
-- Query dimensions
SELECT * FROM `dw-health-insurance-bipm.raw_dataset_star_schema.dim_occupation` LIMIT 10;
SELECT * FROM `dw-health-insurance-bipm.raw_dataset_star_schema.dim_person` LIMIT 10;
SELECT * FROM `dw-health-insurance-bipm.raw_dataset_star_schema.dim_insurance` LIMIT 10;

-- Query fact table
SELECT * FROM `dw-health-insurance-bipm.raw_dataset_star_schema.fact_health_metrics` LIMIT 10;
```

### Join Dimensions to Fact Table

```sql
SELECT
    p.PersonID,
    p.insurance_gender,
    p.insurance_age,
    o.occupational_category,
    o.wealth_bracket,
    i.insurance_status,
    f.doctor_visits_count,
    f.quality_of_sleep_score,
    f.smartwatch_heart_rate_bpm
FROM `dw-health-insurance-bipm.raw_dataset_star_schema.fact_health_metrics` f
JOIN `dw-health-insurance-bipm.raw_dataset_star_schema.dim_person` p
    ON f.PersonID = p.PersonID
JOIN `dw-health-insurance-bipm.raw_dataset_star_schema.dim_occupation` o
    ON f.occupation_id = o.occupation_id
JOIN `dw-health-insurance-bipm.raw_dataset_star_schema.dim_insurance` i
    ON f.insurance_id = i.insurance_id
LIMIT 100;
```

---

## 🎯 Configuration

The schema is configured in `dbt_project.yml`:

```yaml
models:
  health_insurance_dw:
    star_schema:
      +materialized: table
      +schema: star_schema
      +tags: ["star_schema", "dimensional"]
```

This means:
- All models in `models/star_schema/` will use **table** materialization
- They will be written to the `star_schema` schema (becomes `raw_dataset_star_schema` in BigQuery)
- Tagged for easy selection with `--select tag:star_schema`

---

## 📦 Dataset Structure

```
dw-health-insurance-bipm (Project)
│
├── raw_dataset (Source data)
│   ├── raw_Sleep_Health_and_Lifestyle_Dataset
│   ├── raw_smartwatch_health_data
│   ├── raw_health_insurance_person_dim
│   └── health_insurance_insurance_facts_raw
│
├── raw_dataset_staging (dbt staging views)
│   ├── stg_sleep_health
│   ├── stg_smartwatch_data
│   ├── stg_health_insurance_person
│   └── stg_health_insurance_facts
│
├── raw_dataset_cleaned (dbt cleaned tables)
│   ├── sleep_health_cleaned
│   ├── smartwatch_data_cleaned
│   ├── health_insurance_person_cleaned
│   ├── health_insurance_facts_cleaned
│   └── attribution
│
└── raw_dataset_star_schema (dbt star schema - NEW!)
    ├── dim_occupation
    ├── dim_person
    ├── dim_insurance
    └── fact_health_metrics
```

---

## 🔐 Access Control (Optional)

You can grant specific users read-only access to just the star schema:

```sql
-- Grant BigQuery Data Viewer role to analytics team
GRANT `roles/bigquery.dataViewer`
ON SCHEMA `dw-health-insurance-bipm.raw_dataset_star_schema`
TO 'user:analyst@company.com';
```

---

## 🔄 Refresh Strategy

### Full Refresh (Recommended for Initial Load)

```bash
dbt run --select star_schema --full-refresh
```

### Incremental Updates (Future Enhancement)

The current models are full-refresh. To make them incremental:

1. Modify fact table to use `materialized='incremental'`
2. Add incremental logic based on `created_at` or `insurance_year`
3. Update dimensions with SCD Type 2 logic

---

## ✅ Post-Deployment Validation

Run these queries to validate deployment:

```sql
-- Check row counts
SELECT 'dim_occupation' as table_name, COUNT(*) as row_count
FROM `dw-health-insurance-bipm.raw_dataset_star_schema.dim_occupation`
UNION ALL
SELECT 'dim_person', COUNT(*)
FROM `dw-health-insurance-bipm.raw_dataset_star_schema.dim_person`
UNION ALL
SELECT 'dim_insurance', COUNT(*)
FROM `dw-health-insurance-bipm.raw_dataset_star_schema.dim_insurance`
UNION ALL
SELECT 'fact_health_metrics', COUNT(*)
FROM `dw-health-insurance-bipm.raw_dataset_star_schema.fact_health_metrics`;

-- Verify referential integrity (should return 0 orphans)
SELECT
    SUM(CASE WHEN p.PersonID IS NULL THEN 1 ELSE 0 END) as orphaned_persons,
    SUM(CASE WHEN o.occupation_id IS NULL THEN 1 ELSE 0 END) as orphaned_occupations,
    SUM(CASE WHEN i.insurance_id IS NULL THEN 1 ELSE 0 END) as orphaned_insurance
FROM `dw-health-insurance-bipm.raw_dataset_star_schema.fact_health_metrics` f
LEFT JOIN `dw-health-insurance-bipm.raw_dataset_star_schema.dim_person` p
    ON f.PersonID = p.PersonID
LEFT JOIN `dw-health-insurance-bipm.raw_dataset_star_schema.dim_occupation` o
    ON f.occupation_id = o.occupation_id
LEFT JOIN `dw-health-insurance-bipm.raw_dataset_star_schema.dim_insurance` i
    ON f.insurance_id = i.insurance_id;
```

---

**Last Updated:** 2026-01-10
**dbt Version:** 1.7+
**BigQuery Location:** EU
