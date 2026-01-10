{{
  config(
    materialized='table',
    tags=['data_marts', 'analytics', 'demographics']
  )
}}

/*
    Data Mart: Health Metrics by Demographics

    Purpose: Aggregate health metrics by demographic segments for population health analysis

    Business Questions Answered:
    - How do health metrics vary by age group and gender?
    - Which demographic segments have the poorest health outcomes?
    - What is the average sleep quality across different age groups?

    Grain: One row per (age_group, gender, family_status) combination

    Source: Star Schema (fact_health_metrics + dim_person)

    Users: Public Health Analysts, Insurance Actuaries, Research Teams
*/

WITH health_with_demographics AS (
    SELECT
        f.*,
        p.insurance_age,
        p.insurance_gender,
        p.family_status,
        p.is_invalid_age
    FROM {{ ref('fact_health_metrics') }} f
    INNER JOIN {{ ref('dim_person') }} p
        ON f.PersonID = p.PersonID
    WHERE p.is_invalid_age = FALSE
      AND f.is_invalid_heart_rate = FALSE
)

SELECT
    -- Demographic dimensions
    CASE
        WHEN insurance_age < 30 THEN '18-29'
        WHEN insurance_age < 40 THEN '30-39'
        WHEN insurance_age < 50 THEN '40-49'
        WHEN insurance_age < 60 THEN '50-59'
        WHEN insurance_age < 70 THEN '60-69'
        ELSE '70+'
    END AS age_group,

    insurance_gender AS gender,
    family_status,

    -- Population metrics
    COUNT(DISTINCT PersonID) AS unique_persons,
    COUNT(*) AS total_records,

    -- Health vitals - averages
    ROUND(AVG(smartwatch_heart_rate_bpm), 1) AS avg_heart_rate_bpm,
    ROUND(AVG(blood_oxygen_percent), 1) AS avg_blood_oxygen_pct,
    ROUND(AVG(blood_pressure_systolic), 1) AS avg_systolic_bp,
    ROUND(AVG(blood_pressure_diastolic), 1) AS avg_diastolic_bp,

    -- Sleep metrics
    ROUND(AVG(smartwatch_sleep_hours), 2) AS avg_sleep_hours,
    ROUND(AVG(quality_of_sleep_score), 2) AS avg_sleep_quality_score,

    -- Activity metrics
    ROUND(AVG(step_count), 0) AS avg_daily_steps,

    -- Healthcare utilization
    ROUND(AVG(doctor_visits_count), 1) AS avg_doctor_visits,
    ROUND(AVG(insurance_cost_year), 2) AS avg_insurance_cost,
    ROUND(AVG(cost_to_insurance_amount), 2) AS avg_claims_amount,

    -- Health risk indicators (percentages)
    ROUND(100.0 * SUM(CASE WHEN smartwatch_heart_rate_bpm > 100 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_elevated_heart_rate,
    ROUND(100.0 * SUM(CASE WHEN blood_oxygen_percent < 95 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_low_blood_oxygen,
    ROUND(100.0 * SUM(CASE WHEN smartwatch_sleep_hours < 6 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_sleep_deprived,
    ROUND(100.0 * SUM(CASE WHEN sleep_disorder != 'none' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_with_sleep_disorder,

    -- Data quality metrics
    ROUND(100.0 * SUM(CAST(is_missing_blood_oxygen AS INT64)) / COUNT(*), 2) AS pct_missing_blood_oxygen,
    ROUND(100.0 * SUM(CAST(is_missing_stress_level AS INT64)) / COUNT(*), 2) AS pct_missing_stress_level,

    -- Metadata
    CURRENT_TIMESTAMP() AS created_at

FROM health_with_demographics

GROUP BY age_group, gender, family_status

-- Order by age group and gender for readability
ORDER BY age_group, gender, family_status
