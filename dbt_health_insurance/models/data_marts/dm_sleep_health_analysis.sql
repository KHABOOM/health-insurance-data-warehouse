{{
  config(
    materialized='table',
    tags=['data_marts', 'analytics', 'sleep', 'health']
  )
}}

/*
    Data Mart: Sleep Health Analysis

    Purpose: Comprehensive sleep health analysis combining sleep metrics with other health indicators

    Business Questions Answered:
    - How does sleep quality correlate with other health metrics?
    - Which groups have the highest prevalence of sleep disorders?
    - What is the relationship between sleep and healthcare costs?

    Grain: One row per (sleep_disorder, activity_level, stress_level) combination

    Source: Star Schema (fact_health_metrics with all dimensions)

    Users: Sleep Medicine Researchers, Wellness Program Managers, Clinical Teams
*/

WITH sleep_health_metrics AS (
    SELECT
        f.*,
        p.insurance_age,
        p.insurance_gender,
        o.occupational_category,
        o.wealth_bracket
    FROM {{ ref('fact_health_metrics') }} f
    INNER JOIN {{ ref('dim_person') }} p
        ON f.PersonID = p.PersonID
    INNER JOIN {{ ref('dim_occupation') }} o
        ON f.occupation_id = o.occupation_id
    WHERE f.smartwatch_sleep_hours IS NOT NULL
      AND f.quality_of_sleep_score IS NOT NULL
)

SELECT
    -- Sleep health dimensions
    sleep_disorder,
    activity_level,
    smartwatch_stress_level AS stress_level,

    -- Population metrics
    COUNT(DISTINCT PersonID) AS unique_persons,
    COUNT(*) AS total_records,

    -- Sleep metrics
    ROUND(AVG(smartwatch_sleep_hours), 2) AS avg_sleep_hours,
    ROUND(AVG(quality_of_sleep_score), 2) AS avg_sleep_quality_score,
    ROUND(MIN(smartwatch_sleep_hours), 2) AS min_sleep_hours,
    ROUND(MAX(smartwatch_sleep_hours), 2) AS max_sleep_hours,

    -- Sleep quality distribution
    ROUND(100.0 * SUM(CASE WHEN smartwatch_sleep_hours < 6 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_sleep_deprived,
    ROUND(100.0 * SUM(CASE WHEN smartwatch_sleep_hours >= 7 AND smartwatch_sleep_hours <= 9 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_optimal_sleep,
    ROUND(100.0 * SUM(CASE WHEN smartwatch_sleep_hours > 9 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_oversleeping,

    -- Sleep quality score distribution
    ROUND(100.0 * SUM(CASE WHEN quality_of_sleep_score >= 8 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_good_sleep_quality,
    ROUND(100.0 * SUM(CASE WHEN quality_of_sleep_score <= 5 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_poor_sleep_quality,

    -- Related health metrics
    ROUND(AVG(smartwatch_heart_rate_bpm), 1) AS avg_heart_rate_bpm,
    ROUND(AVG(blood_oxygen_percent), 1) AS avg_blood_oxygen_pct,
    ROUND(AVG(blood_pressure_systolic), 1) AS avg_systolic_bp,
    ROUND(AVG(blood_pressure_diastolic), 1) AS avg_diastolic_bp,

    -- Activity and lifestyle
    ROUND(AVG(step_count), 0) AS avg_daily_steps,
    ROUND(100.0 * SUM(CASE WHEN step_count < 5000 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_sedentary,
    ROUND(100.0 * SUM(CASE WHEN step_count >= 10000 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_active,

    -- Healthcare utilization & costs
    ROUND(AVG(doctor_visits_count), 1) AS avg_doctor_visits,
    ROUND(AVG(insurance_cost_year), 2) AS avg_insurance_cost,
    ROUND(AVG(cost_to_insurance_amount), 2) AS avg_claims_amount,

    -- Cardiovascular risk indicators
    ROUND(100.0 * SUM(CASE WHEN smartwatch_heart_rate_bpm > 100 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_elevated_heart_rate,
    ROUND(100.0 * SUM(CASE WHEN blood_oxygen_percent < 95 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_low_blood_oxygen,
    ROUND(100.0 * SUM(CASE WHEN blood_pressure_systolic >= 140 OR blood_pressure_diastolic >= 90 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_hypertensive,

    -- Demographics summary
    ROUND(AVG(insurance_age), 1) AS avg_age,
    ROUND(100.0 * SUM(CASE WHEN insurance_gender = 'male' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_male,

    -- Data quality
    ROUND(100.0 * SUM(CAST(is_missing_blood_oxygen AS INT64)) / COUNT(*), 2) AS pct_missing_blood_oxygen,
    ROUND(100.0 * SUM(CAST(is_missing_stress_level AS INT64)) / COUNT(*), 2) AS pct_missing_stress_level,

    -- Metadata
    CURRENT_TIMESTAMP() AS created_at

FROM sleep_health_metrics

GROUP BY sleep_disorder, activity_level, stress_level

-- Order by prevalence (most common sleep patterns first)
ORDER BY total_records DESC
