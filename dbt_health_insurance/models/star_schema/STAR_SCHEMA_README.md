# Star Schema: Health Metrics Data Warehouse

## 📊 Overview

This star schema transforms the flat `attribution` table into a dimensional model optimized for analytics and BI reporting.

**Source:** `attribution` (94,126 rows)
**Target:** 3 dimension tables + 1 fact table

---

## 🏗️ Schema Architecture

```
                    ┌─────────────────┐
                    │  dim_person     │
                    │  (72 rows)      │
                    │  PK: PersonID   │
                    └────────┬────────┘
                             │
                             │
                    ┌────────▼────────────────────────┐
                    │                                 │
         ┌──────────┴─────────┐          ┌───────────┴─────────┐
         │                    │          │                     │
    ┌────▼──────────┐   ┌─────▼──────────┐   ┌────────────────▼─────┐
    │ dim_occupation│   │fact_health_     │   │  dim_insurance       │
    │ (36 rows)     │◄──┤metrics          │──►│  (97 rows)           │
    │ PK:occupation_│   │(~94K rows)      │   │  PK: insurance_id    │
    │    id         │   │                 │   │                      │
    └───────────────┘   │FK: PersonID     │   └──────────────────────┘
                        │FK: occupation_id│
                        │FK: insurance_id │
                        └─────────────────┘
```

---

## 📋 Dimension Tables

### 1. **dim_occupation** (36 rows)

**Purpose:** Store unique occupation and wealth combinations

**Grain:** One row per unique (occupational_category, wealth_bracket) pair

**Primary Key:** `occupation_id` (surrogate key, auto-generated)

**Attributes:**
- `occupational_category` (STRING): engineer, healthcare_worker, it specialist, self-employed, etc.
- `wealth_bracket` (STRING): HIGH, MEDIUM, LOW, UPPER_MIDDLE
- `created_at` (TIMESTAMP): Record creation timestamp

**SQL File:** `dim_occupation.sql`

**Example Rows:**
| occupation_id | occupational_category | wealth_bracket |
|--------------|----------------------|----------------|
| 1 | engineer | HIGH |
| 2 | engineer | LOW |
| 3 | engineer | UPPER_MIDDLE |
| 4 | healthcare_worker | HIGH |

---

### 2. **dim_person** (72 rows)

**Purpose:** Store person demographic attributes

**Grain:** One row per unique PersonID

**Primary Key:** `PersonID` (natural key from attribution)

**Attributes:**
- `insurance_age` (INT64): Age of the person
- `is_invalid_age` (BOOLEAN): Data quality flag for age validation
- `insurance_gender` (STRING): male, female
- `family_status` (STRING): MARRIED, SINGLE, DIVORCED, WIDOWED
- `created_at` (TIMESTAMP): Record creation timestamp

**SQL File:** `dim_person.sql`

**Note:** Handles duplicate PersonIDs by selecting one record deterministically using ROW_NUMBER

**Example Rows:**
| PersonID | insurance_age | insurance_gender | family_status |
|---------|--------------|-----------------|--------------|
| 7 | 72 | male | MARRIED |
| 8 | 58 | female | WIDOWED |
| 12 | 39 | female | DIVORCED |

---

### 3. **dim_insurance** (97 rows)

**Purpose:** Store unique insurance policy combinations

**Grain:** One row per unique (insurance_status, insurance_sign_up_date, is_invalid_signup_date) combination

**Primary Key:** `insurance_id` (surrogate key, auto-generated)

**Attributes:**
- `insurance_status` (STRING): ACTIVE, INACTIVE, PENDING, CANCELLED
- `insurance_sign_up_date` (DATE): Date when insurance was signed up
- `is_invalid_signup_date` (BOOLEAN): Data quality flag for sign-up date
- `created_at` (TIMESTAMP): Record creation timestamp

**SQL File:** `dim_insurance.sql`

**Example Rows:**
| insurance_id | insurance_status | insurance_sign_up_date | is_invalid_signup_date |
|-------------|-----------------|----------------------|----------------------|
| 1 | ACTIVE | 2015-01-15 | false |
| 2 | ACTIVE | 2016-03-22 | false |
| 3 | INACTIVE | 2014-08-10 | false |

---

## 📈 Fact Table

### **fact_health_metrics** (~94,000 rows)

**Purpose:** Store health and insurance metrics with foreign keys to dimensions

**Grain:** One row per attribution record (denormalized from multiple sources)

**Primary Key:** `health_metric_id` (surrogate key, auto-generated)

**Foreign Keys:**
- `PersonID` → `dim_person.PersonID`
- `occupation_id` → `dim_occupation.occupation_id`
- `insurance_id` → `dim_insurance.insurance_id`

**Degenerate Dimensions:**
- `insurance_year` (INT64): Year of insurance record

**Numeric Measures:**
- `doctor_visits_count` (INT64): Number of doctor visits
- `insurance_cost_year` (FLOAT64): Annual insurance cost
- `cost_to_insurance_amount` (FLOAT64): Cost charged to insurance
- `smartwatch_sleep_hours` (FLOAT64): Sleep hours from smartwatch
- `quality_of_sleep_score` (INT64): Sleep quality score (1-10)
- `blood_pressure_systolic` (INT64): Systolic blood pressure
- `blood_pressure_diastolic` (INT64): Diastolic blood pressure
- `smartwatch_heart_rate_bpm` (FLOAT64): Heart rate from smartwatch
- `blood_oxygen_percent` (FLOAT64): Blood oxygen saturation percentage
- `step_count` (FLOAT64): Daily step count

**Categorical Measures:**
- `activity_level` (STRING): Physical activity level
- `sleep_disorder` (STRING): Type of sleep disorder (none, insomnia, sleep apnea)
- `smartwatch_stress_level` (STRING): Stress level from smartwatch

**Data Quality Flags (BOOLEAN):**
- `is_invalid_heart_rate`: Heart rate validation flag
- `is_invalid_steps`: Step count validation flag
- `is_missing_blood_oxygen`: Blood oxygen missing flag
- `is_invalid_blood_oxygen`: Blood oxygen validation flag
- `is_missing_stress_level`: Stress level missing flag

**SQL File:** `fact_health_metrics.sql`

---

## 🚀 Usage

### Build the Star Schema

```bash
# Run all star schema models
dbt run --select star_schema

# Or run individually in order
dbt run --select dim_occupation
dbt run --select dim_person
dbt run --select dim_insurance
dbt run --select fact_health_metrics
```

### Query Examples

**1. Average sleep quality by occupation and wealth:**
```sql
SELECT
    o.occupational_category,
    o.wealth_bracket,
    AVG(f.quality_of_sleep_score) as avg_sleep_quality,
    COUNT(*) as record_count
FROM `raw_dataset_cleaned.fact_health_metrics` f
JOIN `raw_dataset_cleaned.dim_occupation` o
    ON f.occupation_id = o.occupation_id
GROUP BY o.occupational_category, o.wealth_bracket
ORDER BY avg_sleep_quality DESC
LIMIT 10;
```

**2. Health metrics by age group and gender:**
```sql
SELECT
    CASE
        WHEN p.insurance_age < 30 THEN '18-29'
        WHEN p.insurance_age < 40 THEN '30-39'
        WHEN p.insurance_age < 50 THEN '40-49'
        WHEN p.insurance_age < 60 THEN '50-59'
        ELSE '60+'
    END as age_group,
    p.insurance_gender,
    AVG(f.smartwatch_heart_rate_bpm) as avg_heart_rate,
    AVG(f.blood_oxygen_percent) as avg_blood_oxygen,
    AVG(f.smartwatch_sleep_hours) as avg_sleep_hours
FROM `raw_dataset_cleaned.fact_health_metrics` f
JOIN `raw_dataset_cleaned.dim_person` p
    ON f.PersonID = p.PersonID
GROUP BY age_group, p.insurance_gender
ORDER BY age_group, p.insurance_gender;
```

**3. Insurance cost analysis by status:**
```sql
SELECT
    i.insurance_status,
    EXTRACT(YEAR FROM i.insurance_sign_up_date) as signup_year,
    AVG(f.insurance_cost_year) as avg_cost,
    AVG(f.cost_to_insurance_amount) as avg_claimed,
    AVG(f.doctor_visits_count) as avg_visits,
    COUNT(*) as policy_count
FROM `raw_dataset_cleaned.fact_health_metrics` f
JOIN `raw_dataset_cleaned.dim_insurance` i
    ON f.insurance_id = i.insurance_id
GROUP BY i.insurance_status, signup_year
ORDER BY signup_year DESC, i.insurance_status;
```

**4. Data quality report:**
```sql
SELECT
    COUNT(*) as total_records,
    SUM(CAST(is_invalid_heart_rate AS INT64)) as invalid_heart_rate_count,
    SUM(CAST(is_missing_blood_oxygen AS INT64)) as missing_blood_oxygen_count,
    SUM(CAST(is_invalid_blood_oxygen AS INT64)) as invalid_blood_oxygen_count,
    SUM(CAST(is_missing_stress_level AS INT64)) as missing_stress_level_count,
    ROUND(100.0 * SUM(CAST(is_invalid_heart_rate AS INT64)) / COUNT(*), 2) as invalid_hr_pct
FROM `raw_dataset_cleaned.fact_health_metrics`;
```

---

## 📊 Benefits of Star Schema

### ✅ **Performance**
- Optimized for analytical queries (fewer joins)
- Smaller dimension tables fit in memory
- Pre-aggregated surrogate keys reduce join complexity

### ✅ **Simplicity**
- Easy to understand for business users
- Intuitive query patterns
- Clear relationship between facts and dimensions

### ✅ **Flexibility**
- Easy to add new measures to fact table
- Easy to add new attributes to dimensions
- Supports complex business questions

### ✅ **Data Quality**
- Dimensions enforce referential integrity
- Surrogate keys handle changing data
- Quality flags enable data validation queries

---

## 🔗 Referential Integrity

All fact table foreign keys are validated through LEFT JOINs to dimensions. Records without matching dimension keys are **filtered out** to maintain referential integrity.

**Validation Query:**
```sql
-- Check for orphaned records (should return 0)
SELECT
    SUM(CASE WHEN PersonID IS NULL THEN 1 ELSE 0 END) as missing_person,
    SUM(CASE WHEN occupation_id IS NULL THEN 1 ELSE 0 END) as missing_occupation,
    SUM(CASE WHEN insurance_id IS NULL THEN 1 ELSE 0 END) as missing_insurance
FROM `raw_dataset_cleaned.fact_health_metrics`;
```

---

## 📝 Data Lineage

```
attribution (flat table)
    │
    ├─► dim_occupation (distinct occupational_category + wealth_bracket)
    │
    ├─► dim_person (distinct PersonID with deduplication)
    │
    ├─► dim_insurance (distinct insurance_status + sign_up_date combination)
    │
    └─► fact_health_metrics (joins back to all 3 dimensions)
```

---

## 🎯 Next Steps

1. **Add Tests:** Create dbt tests for referential integrity
2. **Create Views:** Add semantic layer views for common queries
3. **Add Incremental Logic:** Convert to incremental models for production
4. **Add SCD Type 2:** Track dimension changes over time
5. **Add Aggregate Tables:** Create summary tables for dashboards

---

**Created:** 2026-01-10
**Source Model:** `attribution.sql`
**Schema Type:** Star Schema (Kimball)
**Database:** BigQuery (dw-health-insurance-bipm)
