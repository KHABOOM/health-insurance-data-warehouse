# Data Marts: Analytics Layer

## 📊 Overview

Data marts are **business-focused analytical tables** built on top of the star schema. Each mart answers specific business questions and is optimized for a particular user group or use case.

**Source:** Star Schema (dim_* and fact_health_metrics)
**Target Dataset:** `raw_dataset_data_marts`
**Purpose:** Pre-aggregated, analysis-ready tables for BI tools and reporting

---

## 🏗️ Architecture

```
Star Schema (dimensional model)
    │
    ├── dim_person
    ├── dim_occupation
    ├── dim_insurance
    └── fact_health_metrics
              │
              ▼
        Data Marts Layer
              │
              ├── dm_health_by_demographics
              ├── dm_insurance_profitability
              ├── dm_sleep_health_analysis
              ├── dm_customer_360
              └── dm_data_quality_dashboard
```

---

## 📋 Data Marts Catalog

### 1. **dm_health_by_demographics**

**Purpose:** Population health analysis by demographic segments

**Business Questions:**
- How do health metrics vary by age and gender?
- Which demographic groups have the poorest health outcomes?
- What is the prevalence of health risk factors by family status?

**Grain:** One row per (age_group, gender, family_status)

**Key Metrics:**
- Average vitals (heart rate, blood pressure, blood oxygen)
- Sleep quality and duration
- Activity levels (step count)
- Healthcare utilization (doctor visits, costs)
- Health risk percentages (elevated HR, low O2, sleep deprivation)

**Target Users:**
- Public Health Analysts
- Insurance Actuaries
- Research Teams
- Wellness Program Managers

**Example Query:**
```sql
SELECT
    age_group,
    gender,
    avg_heart_rate_bpm,
    avg_sleep_hours,
    pct_with_sleep_disorder,
    avg_insurance_cost
FROM `dw-health-insurance-bipm.raw_dataset_data_marts.dm_health_by_demographics`
WHERE age_group = '40-49'
ORDER BY pct_with_sleep_disorder DESC;
```

---

### 2. **dm_insurance_profitability**

**Purpose:** Financial performance analysis by customer segments

**Business Questions:**
- Which occupation/wealth segments are most profitable?
- What is the loss ratio by demographic?
- How many customers are unprofitable?

**Grain:** One row per (occupational_category, wealth_bracket, insurance_status)

**Key Metrics:**
- Total premiums collected vs claims paid
- Net profit and average profit per policy
- Loss ratio (claims/premiums %)
- Healthcare utilization patterns
- Percentage of unprofitable policies

**Target Users:**
- Insurance Underwriters
- Finance Team
- Product Managers
- Pricing Analysts

**Example Query:**
```sql
SELECT
    occupational_category,
    wealth_bracket,
    total_premiums_collected,
    total_claims_paid,
    net_profit,
    loss_ratio_pct,
    pct_unprofitable_policies
FROM `dw-health-insurance-bipm.raw_dataset_data_marts.dm_insurance_profitability`
WHERE insurance_status = 'ACTIVE'
ORDER BY net_profit DESC
LIMIT 10;
```

---

### 3. **dm_sleep_health_analysis**

**Purpose:** Comprehensive sleep health research and insights

**Business Questions:**
- How does sleep quality correlate with other health metrics?
- Which groups have the highest prevalence of sleep disorders?
- What is the relationship between sleep and healthcare costs?

**Grain:** One row per (sleep_disorder, activity_level, stress_level)

**Key Metrics:**
- Sleep duration and quality scores
- Sleep quality distribution (deprived, optimal, oversleeping)
- Related health metrics (vitals, activity)
- Healthcare utilization by sleep health
- Cardiovascular risk indicators

**Target Users:**
- Sleep Medicine Researchers
- Wellness Program Managers
- Clinical Teams
- Health Insurance Product Teams

**Example Query:**
```sql
SELECT
    sleep_disorder,
    activity_level,
    stress_level,
    avg_sleep_hours,
    avg_sleep_quality_score,
    pct_sleep_deprived,
    pct_hypertensive,
    avg_doctor_visits
FROM `dw-health-insurance-bipm.raw_dataset_data_marts.dm_sleep_health_analysis`
WHERE sleep_disorder != 'none'
ORDER BY total_records DESC;
```

---

### 4. **dm_customer_360**

**Purpose:** Complete customer profile with all attributes

**Business Questions:**
- What is the complete profile of each customer?
- Which customers are high-risk or high-cost?
- Who are the most/least profitable customers?

**Grain:** One row per PersonID (customer-level)

**Key Metrics:**
- Lifetime value (premiums, claims, profit)
- Current health metrics (vitals, sleep, activity)
- Health risk score (0-16 scale)
- Customer segment (High Value, Profitable, Break Even, High Cost)
- Health status (High Risk, Moderate Risk, Low Risk)

**Target Users:**
- Customer Service Representatives
- Account Managers
- Marketing Teams
- Care Coordinators

**Example Query:**
```sql
SELECT
    PersonID,
    age,
    gender,
    occupational_category,
    customer_segment,
    health_status,
    health_risk_score,
    lifetime_premiums_paid,
    lifetime_claims_amount,
    lifetime_profit_contribution,
    current_heart_rate_bpm,
    current_sleep_disorder
FROM `dw-health-insurance-bipm.raw_dataset_data_marts.dm_customer_360`
WHERE customer_segment = 'High Cost'
  AND health_status = 'High Risk'
ORDER BY health_risk_score DESC
LIMIT 100;
```

---

### 5. **dm_data_quality_dashboard**

**Purpose:** Monitor data quality across all sources and segments

**Business Questions:**
- What is the overall data quality score?
- Which metrics have the highest missing/invalid rates?
- Are there data quality patterns by occupation or wealth?

**Grain:** Multiple rows - overall + by occupation + by wealth bracket

**Key Metrics:**
- Completeness (missing data percentages)
- Validity (invalid data percentages)
- Accuracy (outliers and anomalies)
- Consistency (logical contradictions)
- Overall quality score (0-100)

**Target Users:**
- Data Engineering Team
- Data Stewards
- Analytics Managers
- BI Developers

**Example Query:**
```sql
SELECT
    data_source,
    quality_dimension,
    total_records,
    overall_quality_score,
    missing_blood_oxygen_pct,
    invalid_heart_rate_pct,
    extreme_heart_rate_pct
FROM `dw-health-insurance-bipm.raw_dataset_data_marts.dm_data_quality_dashboard`
WHERE data_source = 'All Sources'
ORDER BY overall_quality_score ASC;
```

---

## 🚀 Deployment

### Build All Data Marts

```bash
# Navigate to dbt project
cd dbt_health_insurance

# Run all data marts (after star schema is built)
dbt run --select data_marts

# Or run individually
dbt run --select dm_health_by_demographics
dbt run --select dm_insurance_profitability
dbt run --select dm_sleep_health_analysis
dbt run --select dm_customer_360
dbt run --select dm_data_quality_dashboard
```

### Dependencies

Data marts depend on the star schema being built first:

```bash
# Full pipeline
dbt run --select star_schema  # Build dimensions and fact table first
dbt run --select data_marts    # Then build data marts
```

---

## 📍 Dataset Location

All data marts are deployed to:

```
Project: dw-health-insurance-bipm
Dataset: raw_dataset_data_marts
```

Full table paths:
- `dw-health-insurance-bipm.raw_dataset_data_marts.dm_health_by_demographics`
- `dw-health-insurance-bipm.raw_dataset_data_marts.dm_insurance_profitability`
- `dw-health-insurance-bipm.raw_dataset_data_marts.dm_sleep_health_analysis`
- `dw-health-insurance-bipm.raw_dataset_data_marts.dm_customer_360`
- `dw-health-insurance-bipm.raw_dataset_data_marts.dm_data_quality_dashboard`

---

## 📊 Row Counts (Approximate)

| Data Mart | Rows | Description |
|-----------|------|-------------|
| `dm_health_by_demographics` | ~100-200 | One row per age group × gender × family status |
| `dm_insurance_profitability` | ~150-300 | One row per occupation × wealth × insurance status |
| `dm_sleep_health_analysis` | ~50-100 | One row per sleep disorder × activity × stress |
| `dm_customer_360` | ~72 | One row per customer (PersonID) |
| `dm_data_quality_dashboard` | ~50 | Overall + by occupation + by wealth |

---

## 🎯 Use Cases by Role

### Insurance Underwriters
**Primary Marts:**
- `dm_insurance_profitability` - Segment performance
- `dm_customer_360` - Individual risk assessment

**Sample Workflow:**
1. Identify unprofitable segments in profitability mart
2. Deep dive into customer profiles in customer_360
3. Adjust pricing or coverage based on insights

---

### Health Analysts
**Primary Marts:**
- `dm_health_by_demographics` - Population health trends
- `dm_sleep_health_analysis` - Sleep disorder patterns

**Sample Workflow:**
1. Analyze health outcomes by age/gender
2. Identify at-risk populations
3. Design targeted wellness programs

---

### Customer Service
**Primary Marts:**
- `dm_customer_360` - Complete customer view

**Sample Workflow:**
1. Look up customer by PersonID
2. View health status and risk score
3. Provide personalized service based on segment

---

### Data Engineers
**Primary Marts:**
- `dm_data_quality_dashboard` - Data quality monitoring

**Sample Workflow:**
1. Monitor overall quality score
2. Identify problematic data sources
3. Fix data quality issues at source

---

## 🔄 Refresh Strategy

### Current: Full Refresh (Table Materialization)

Data marts are currently full-refresh tables:
```bash
dbt run --select data_marts --full-refresh
```

### Future: Incremental Updates

For production efficiency, consider converting to incremental:

```sql
{{
  config(
    materialized='incremental',
    unique_key='unique_identifier',
    on_schema_change='fail'
  )
}}

-- Add WHERE clause for incremental logic
{% if is_incremental() %}
WHERE created_at > (SELECT MAX(created_at) FROM {{ this }})
{% endif %}
```

---

## 📈 Performance Optimization

### Pre-Aggregation Benefits

Data marts are **pre-aggregated**, which means:
- ✅ Faster query performance (no real-time aggregation needed)
- ✅ Consistent calculations across all reports
- ✅ Reduced load on star schema tables
- ✅ Business logic encoded once, used many times

### Query Performance

```sql
-- Slow: Aggregate on-the-fly from fact table
SELECT age_group, AVG(heart_rate_bpm)
FROM fact_health_metrics
GROUP BY age_group;

-- Fast: Pre-aggregated in data mart
SELECT age_group, avg_heart_rate_bpm
FROM dm_health_by_demographics;
```

---

## 🔐 Access Control

Grant read-only access to business users:

```sql
-- Grant access to specific data mart
GRANT `roles/bigquery.dataViewer`
ON TABLE `dw-health-insurance-bipm.raw_dataset_data_marts.dm_customer_360`
TO 'user:analyst@company.com';

-- Grant access to entire data marts dataset
GRANT `roles/bigquery.dataViewer`
ON SCHEMA `dw-health-insurance-bipm.raw_dataset_data_marts`
TO 'group:analytics-team@company.com';
```

---

## 📊 BI Tool Integration

### Looker / Tableau / Power BI

Data marts are designed for easy BI integration:

1. **Connect** to BigQuery dataset `raw_dataset_data_marts`
2. **Import** tables (all measures pre-calculated)
3. **Create** visualizations without complex SQL
4. **Share** dashboards with business users

### Sample Dashboard Components

**Executive Dashboard:**
- Revenue/profit trends (`dm_insurance_profitability`)
- Customer segment distribution (`dm_customer_360`)
- Health risk distribution (`dm_health_by_demographics`)

**Operations Dashboard:**
- Data quality scores (`dm_data_quality_dashboard`)
- Healthcare utilization trends (`dm_health_by_demographics`)
- High-risk customer alerts (`dm_customer_360`)

---

## ✅ Data Mart Quality Checks

### Recommended dbt Tests

Create `schema.yml` in `models/data_marts/`:

```yaml
version: 2

models:
  - name: dm_customer_360
    description: "Customer 360 view"
    tests:
      - dbt_utils.row_count:
          min_value: 1
    columns:
      - name: PersonID
        tests:
          - unique
          - not_null

  - name: dm_insurance_profitability
    tests:
      - dbt_utils.row_count:
          min_value: 1
    columns:
      - name: net_profit
        tests:
          - not_null
```

---

## 🎓 Best Practices

### 1. **Naming Convention**
- Prefix: `dm_` (data mart)
- Descriptive names reflecting business purpose
- Avoid technical jargon

### 2. **Documentation**
- Document business logic in SQL comments
- Include example queries in headers
- Define grain clearly

### 3. **Grain Definition**
- Always state the grain (what one row represents)
- Keep grain consistent within each mart
- Don't mix grains in one table

### 4. **Measures vs Dimensions**
- Pre-calculate all measures (aggregations)
- Keep dimension attributes for filtering
- Round numeric values appropriately

### 5. **Performance**
- Limit UNION ALL operations
- Use indexes on commonly filtered columns
- Consider partitioning for large tables

---

**Last Updated:** 2026-01-10
**dbt Version:** 1.7+
**BigQuery Location:** EU
**Source:** Star Schema (raw_dataset_star_schema)
