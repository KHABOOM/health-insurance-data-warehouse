{{
  config(
    materialized='table',
    tags=['data_marts', 'analytics', 'data_quality', 'monitoring']
  )
}}

/*
    Data Mart: Data Quality Dashboard

    Purpose: Monitor data quality metrics across all health and insurance data

    Business Questions Answered:
    - What is the overall data quality across different sources?
    - Which metrics have the highest rate of missing or invalid values?
    - Are there patterns in data quality issues by demographic segments?

    Grain: One row per (data_source, quality_dimension) combination

    Source: Star Schema (fact_health_metrics)

    Users: Data Engineering Team, Data Stewards, Analytics Managers
*/

WITH quality_metrics AS (
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
)

SELECT
    -- Data source categorization
    'All Sources' AS data_source,
    'Overall' AS quality_dimension,

    -- Volume metrics
    COUNT(*) AS total_records,
    COUNT(DISTINCT PersonID) AS unique_persons,

    -- Completeness metrics (missing data)
    SUM(CAST(is_missing_blood_oxygen AS INT64)) AS missing_blood_oxygen_count,
    ROUND(100.0 * SUM(CAST(is_missing_blood_oxygen AS INT64)) / COUNT(*), 2) AS missing_blood_oxygen_pct,

    SUM(CAST(is_missing_stress_level AS INT64)) AS missing_stress_level_count,
    ROUND(100.0 * SUM(CAST(is_missing_stress_level AS INT64)) / COUNT(*), 2) AS missing_stress_level_pct,

    -- Validity metrics (invalid data)
    SUM(CAST(is_invalid_heart_rate AS INT64)) AS invalid_heart_rate_count,
    ROUND(100.0 * SUM(CAST(is_invalid_heart_rate AS INT64)) / COUNT(*), 2) AS invalid_heart_rate_pct,

    SUM(CAST(is_invalid_steps AS INT64)) AS invalid_steps_count,
    ROUND(100.0 * SUM(CAST(is_invalid_steps AS INT64)) / COUNT(*), 2) AS invalid_steps_pct,

    SUM(CAST(is_invalid_blood_oxygen AS INT64)) AS invalid_blood_oxygen_count,
    ROUND(100.0 * SUM(CAST(is_invalid_blood_oxygen AS INT64)) / COUNT(*), 2) AS invalid_blood_oxygen_pct,

    -- Accuracy metrics (outliers and anomalies)
    SUM(CASE WHEN smartwatch_heart_rate_bpm < 40 OR smartwatch_heart_rate_bpm > 200 THEN 1 ELSE 0 END) AS extreme_heart_rate_count,
    ROUND(100.0 * SUM(CASE WHEN smartwatch_heart_rate_bpm < 40 OR smartwatch_heart_rate_bpm > 200 THEN 1 ELSE 0 END) / COUNT(*), 2) AS extreme_heart_rate_pct,

    SUM(CASE WHEN smartwatch_sleep_hours < 2 OR smartwatch_sleep_hours > 16 THEN 1 ELSE 0 END) AS extreme_sleep_hours_count,
    ROUND(100.0 * SUM(CASE WHEN smartwatch_sleep_hours < 2 OR smartwatch_sleep_hours > 16 THEN 1 ELSE 0 END) / COUNT(*), 2) AS extreme_sleep_hours_pct,

    SUM(CASE WHEN step_count = 0 OR step_count > 50000 THEN 1 ELSE 0 END) AS extreme_step_count_count,
    ROUND(100.0 * SUM(CASE WHEN step_count = 0 OR step_count > 50000 THEN 1 ELSE 0 END) / COUNT(*), 2) AS extreme_step_count_pct,

    -- Consistency metrics
    SUM(CASE WHEN insurance_cost_year < 0 OR cost_to_insurance_amount < 0 THEN 1 ELSE 0 END) AS negative_cost_count,
    ROUND(100.0 * SUM(CASE WHEN insurance_cost_year < 0 OR cost_to_insurance_amount < 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS negative_cost_pct,

    SUM(CASE WHEN cost_to_insurance_amount > insurance_cost_year * 3 THEN 1 ELSE 0 END) AS excessive_claims_count,
    ROUND(100.0 * SUM(CASE WHEN cost_to_insurance_amount > insurance_cost_year * 3 THEN 1 ELSE 0 END) / COUNT(*), 2) AS excessive_claims_pct,

    -- Overall quality score (100 - average of all error percentages)
    ROUND(100.0 - (
        (100.0 * SUM(CAST(is_missing_blood_oxygen AS INT64)) / COUNT(*)) +
        (100.0 * SUM(CAST(is_missing_stress_level AS INT64)) / COUNT(*)) +
        (100.0 * SUM(CAST(is_invalid_heart_rate AS INT64)) / COUNT(*)) +
        (100.0 * SUM(CAST(is_invalid_steps AS INT64)) / COUNT(*)) +
        (100.0 * SUM(CAST(is_invalid_blood_oxygen AS INT64)) / COUNT(*))
    ) / 5, 2) AS overall_quality_score,

    -- Metadata
    CURRENT_TIMESTAMP() AS created_at

FROM quality_metrics

UNION ALL

-- Quality by occupational category
SELECT
    'By Occupation' AS data_source,
    occupational_category AS quality_dimension,
    COUNT(*) AS total_records,
    COUNT(DISTINCT PersonID) AS unique_persons,
    SUM(CAST(is_missing_blood_oxygen AS INT64)) AS missing_blood_oxygen_count,
    ROUND(100.0 * SUM(CAST(is_missing_blood_oxygen AS INT64)) / COUNT(*), 2) AS missing_blood_oxygen_pct,
    SUM(CAST(is_missing_stress_level AS INT64)) AS missing_stress_level_count,
    ROUND(100.0 * SUM(CAST(is_missing_stress_level AS INT64)) / COUNT(*), 2) AS missing_stress_level_pct,
    SUM(CAST(is_invalid_heart_rate AS INT64)) AS invalid_heart_rate_count,
    ROUND(100.0 * SUM(CAST(is_invalid_heart_rate AS INT64)) / COUNT(*), 2) AS invalid_heart_rate_pct,
    SUM(CAST(is_invalid_steps AS INT64)) AS invalid_steps_count,
    ROUND(100.0 * SUM(CAST(is_invalid_steps AS INT64)) / COUNT(*), 2) AS invalid_steps_pct,
    SUM(CAST(is_invalid_blood_oxygen AS INT64)) AS invalid_blood_oxygen_count,
    ROUND(100.0 * SUM(CAST(is_invalid_blood_oxygen AS INT64)) / COUNT(*), 2) AS invalid_blood_oxygen_pct,
    SUM(CASE WHEN smartwatch_heart_rate_bpm < 40 OR smartwatch_heart_rate_bpm > 200 THEN 1 ELSE 0 END) AS extreme_heart_rate_count,
    ROUND(100.0 * SUM(CASE WHEN smartwatch_heart_rate_bpm < 40 OR smartwatch_heart_rate_bpm > 200 THEN 1 ELSE 0 END) / COUNT(*), 2) AS extreme_heart_rate_pct,
    SUM(CASE WHEN smartwatch_sleep_hours < 2 OR smartwatch_sleep_hours > 16 THEN 1 ELSE 0 END) AS extreme_sleep_hours_count,
    ROUND(100.0 * SUM(CASE WHEN smartwatch_sleep_hours < 2 OR smartwatch_sleep_hours > 16 THEN 1 ELSE 0 END) / COUNT(*), 2) AS extreme_sleep_hours_pct,
    SUM(CASE WHEN step_count = 0 OR step_count > 50000 THEN 1 ELSE 0 END) AS extreme_step_count_count,
    ROUND(100.0 * SUM(CASE WHEN step_count = 0 OR step_count > 50000 THEN 1 ELSE 0 END) / COUNT(*), 2) AS extreme_step_count_pct,
    SUM(CASE WHEN insurance_cost_year < 0 OR cost_to_insurance_amount < 0 THEN 1 ELSE 0 END) AS negative_cost_count,
    ROUND(100.0 * SUM(CASE WHEN insurance_cost_year < 0 OR cost_to_insurance_amount < 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS negative_cost_pct,
    SUM(CASE WHEN cost_to_insurance_amount > insurance_cost_year * 3 THEN 1 ELSE 0 END) AS excessive_claims_count,
    ROUND(100.0 * SUM(CASE WHEN cost_to_insurance_amount > insurance_cost_year * 3 THEN 1 ELSE 0 END) / COUNT(*), 2) AS excessive_claims_pct,
    ROUND(100.0 - (
        (100.0 * SUM(CAST(is_missing_blood_oxygen AS INT64)) / COUNT(*)) +
        (100.0 * SUM(CAST(is_missing_stress_level AS INT64)) / COUNT(*)) +
        (100.0 * SUM(CAST(is_invalid_heart_rate AS INT64)) / COUNT(*)) +
        (100.0 * SUM(CAST(is_invalid_steps AS INT64)) / COUNT(*)) +
        (100.0 * SUM(CAST(is_invalid_blood_oxygen AS INT64)) / COUNT(*))
    ) / 5, 2) AS overall_quality_score,
    CURRENT_TIMESTAMP() AS created_at
FROM quality_metrics
GROUP BY occupational_category

UNION ALL

-- Quality by wealth bracket
SELECT
    'By Wealth Bracket' AS data_source,
    wealth_bracket AS quality_dimension,
    COUNT(*) AS total_records,
    COUNT(DISTINCT PersonID) AS unique_persons,
    SUM(CAST(is_missing_blood_oxygen AS INT64)) AS missing_blood_oxygen_count,
    ROUND(100.0 * SUM(CAST(is_missing_blood_oxygen AS INT64)) / COUNT(*), 2) AS missing_blood_oxygen_pct,
    SUM(CAST(is_missing_stress_level AS INT64)) AS missing_stress_level_count,
    ROUND(100.0 * SUM(CAST(is_missing_stress_level AS INT64)) / COUNT(*), 2) AS missing_stress_level_pct,
    SUM(CAST(is_invalid_heart_rate AS INT64)) AS invalid_heart_rate_count,
    ROUND(100.0 * SUM(CAST(is_invalid_heart_rate AS INT64)) / COUNT(*), 2) AS invalid_heart_rate_pct,
    SUM(CAST(is_invalid_steps AS INT64)) AS invalid_steps_count,
    ROUND(100.0 * SUM(CAST(is_invalid_steps AS INT64)) / COUNT(*), 2) AS invalid_steps_pct,
    SUM(CAST(is_invalid_blood_oxygen AS INT64)) AS invalid_blood_oxygen_count,
    ROUND(100.0 * SUM(CAST(is_invalid_blood_oxygen AS INT64)) / COUNT(*), 2) AS invalid_blood_oxygen_pct,
    SUM(CASE WHEN smartwatch_heart_rate_bpm < 40 OR smartwatch_heart_rate_bpm > 200 THEN 1 ELSE 0 END) AS extreme_heart_rate_count,
    ROUND(100.0 * SUM(CASE WHEN smartwatch_heart_rate_bpm < 40 OR smartwatch_heart_rate_bpm > 200 THEN 1 ELSE 0 END) / COUNT(*), 2) AS extreme_heart_rate_pct,
    SUM(CASE WHEN smartwatch_sleep_hours < 2 OR smartwatch_sleep_hours > 16 THEN 1 ELSE 0 END) AS extreme_sleep_hours_count,
    ROUND(100.0 * SUM(CASE WHEN smartwatch_sleep_hours < 2 OR smartwatch_sleep_hours > 16 THEN 1 ELSE 0 END) / COUNT(*), 2) AS extreme_sleep_hours_pct,
    SUM(CASE WHEN step_count = 0 OR step_count > 50000 THEN 1 ELSE 0 END) AS extreme_step_count_count,
    ROUND(100.0 * SUM(CASE WHEN step_count = 0 OR step_count > 50000 THEN 1 ELSE 0 END) / COUNT(*), 2) AS extreme_step_count_pct,
    SUM(CASE WHEN insurance_cost_year < 0 OR cost_to_insurance_amount < 0 THEN 1 ELSE 0 END) AS negative_cost_count,
    ROUND(100.0 * SUM(CASE WHEN insurance_cost_year < 0 OR cost_to_insurance_amount < 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS negative_cost_pct,
    SUM(CASE WHEN cost_to_insurance_amount > insurance_cost_year * 3 THEN 1 ELSE 0 END) AS excessive_claims_count,
    ROUND(100.0 * SUM(CASE WHEN cost_to_insurance_amount > insurance_cost_year * 3 THEN 1 ELSE 0 END) / COUNT(*), 2) AS excessive_claims_pct,
    ROUND(100.0 - (
        (100.0 * SUM(CAST(is_missing_blood_oxygen AS INT64)) / COUNT(*)) +
        (100.0 * SUM(CAST(is_missing_stress_level AS INT64)) / COUNT(*)) +
        (100.0 * SUM(CAST(is_invalid_heart_rate AS INT64)) / COUNT(*)) +
        (100.0 * SUM(CAST(is_invalid_steps AS INT64)) / COUNT(*)) +
        (100.0 * SUM(CAST(is_invalid_blood_oxygen AS INT64)) / COUNT(*))
    ) / 5, 2) AS overall_quality_score,
    CURRENT_TIMESTAMP() AS created_at
FROM quality_metrics
GROUP BY wealth_bracket

ORDER BY data_source, quality_dimension
