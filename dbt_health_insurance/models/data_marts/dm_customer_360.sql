{{
  config(
    materialized='table',
    tags=['data_marts', 'analytics', 'customer_360']
  )
}}

/*
    Data Mart: Customer 360 View

    Purpose: Single view of each customer with all health, insurance, and demographic attributes

    Business Questions Answered:
    - What is the complete profile of each customer?
    - Which customers are high-risk or high-cost?
    - Who are the healthiest customers by segment?

    Grain: One row per PersonID (customer level)

    Source: Star Schema (all fact and dimension tables joined)

    Users: Customer Service, Account Managers, Marketing, Care Coordinators
*/

WITH customer_metrics AS (
    SELECT
        -- Customer identifiers
        f.PersonID,

        -- Demographics (from dim_person)
        p.insurance_age,
        p.insurance_gender,
        p.family_status,
        p.is_invalid_age,

        -- Occupation & wealth (from dim_occupation)
        o.occupational_category,
        o.wealth_bracket,

        -- Insurance info (from dim_insurance)
        i.insurance_status,
        i.insurance_sign_up_date,

        -- Health metrics
        f.smartwatch_heart_rate_bpm,
        f.blood_oxygen_percent,
        f.blood_pressure_systolic,
        f.blood_pressure_diastolic,
        f.smartwatch_sleep_hours,
        f.quality_of_sleep_score,
        f.step_count,
        f.activity_level,
        f.sleep_disorder,
        f.smartwatch_stress_level,

        -- Financial metrics
        f.doctor_visits_count,
        f.insurance_cost_year,
        f.cost_to_insurance_amount,
        f.insurance_year,

        -- Quality flags
        f.is_invalid_heart_rate,
        f.is_invalid_steps,
        f.is_missing_blood_oxygen,
        f.is_invalid_blood_oxygen,
        f.is_missing_stress_level

    FROM {{ ref('fact_health_metrics') }} f
    INNER JOIN {{ ref('dim_person') }} p
        ON f.PersonID = p.PersonID
    INNER JOIN {{ ref('dim_occupation') }} o
        ON f.occupation_id = o.occupation_id
    INNER JOIN {{ ref('dim_insurance') }} i
        ON f.insurance_id = i.insurance_id
)

SELECT
    -- Customer ID
    PersonID,

    -- Demographics
    insurance_age AS age,
    insurance_gender AS gender,
    family_status,
    occupational_category,
    wealth_bracket,

    -- Insurance status
    insurance_status,
    insurance_sign_up_date,
    DATE_DIFF(CURRENT_DATE(), insurance_sign_up_date, YEAR) AS years_as_customer,

    -- Lifetime value metrics (aggregated across all years)
    COUNT(*) AS total_policy_years,
    ROUND(SUM(insurance_cost_year), 2) AS lifetime_premiums_paid,
    ROUND(SUM(cost_to_insurance_amount), 2) AS lifetime_claims_amount,
    ROUND(SUM(insurance_cost_year) - SUM(cost_to_insurance_amount), 2) AS lifetime_profit_contribution,
    ROUND(SUM(doctor_visits_count), 0) AS lifetime_doctor_visits,

    -- Average annual metrics
    ROUND(AVG(insurance_cost_year), 2) AS avg_annual_premium,
    ROUND(AVG(cost_to_insurance_amount), 2) AS avg_annual_claims,
    ROUND(AVG(doctor_visits_count), 1) AS avg_annual_doctor_visits,

    -- Current health metrics (most recent values using ANY_VALUE)
    ROUND(ANY_VALUE(smartwatch_heart_rate_bpm), 1) AS current_heart_rate_bpm,
    ROUND(ANY_VALUE(blood_oxygen_percent), 1) AS current_blood_oxygen_pct,
    ROUND(ANY_VALUE(blood_pressure_systolic), 1) AS current_systolic_bp,
    ROUND(ANY_VALUE(blood_pressure_diastolic), 1) AS current_diastolic_bp,
    ROUND(ANY_VALUE(smartwatch_sleep_hours), 2) AS current_sleep_hours,
    ROUND(ANY_VALUE(quality_of_sleep_score), 1) AS current_sleep_quality,
    ROUND(ANY_VALUE(step_count), 0) AS current_daily_steps,
    ANY_VALUE(activity_level) AS current_activity_level,
    ANY_VALUE(sleep_disorder) AS current_sleep_disorder,
    ANY_VALUE(smartwatch_stress_level) AS current_stress_level,

    -- Health risk score (simple scoring model)
    (
        CASE WHEN ANY_VALUE(smartwatch_heart_rate_bpm) > 100 THEN 2 ELSE 0 END +
        CASE WHEN ANY_VALUE(blood_oxygen_percent) < 95 THEN 2 ELSE 0 END +
        CASE WHEN ANY_VALUE(blood_pressure_systolic) >= 140 THEN 3 ELSE 0 END +
        CASE WHEN ANY_VALUE(smartwatch_sleep_hours) < 6 THEN 2 ELSE 0 END +
        CASE WHEN ANY_VALUE(sleep_disorder) != 'none' THEN 3 ELSE 0 END +
        CASE WHEN ANY_VALUE(step_count) < 5000 THEN 1 ELSE 0 END +
        CASE WHEN AVG(doctor_visits_count) > 10 THEN 3 ELSE 0 END
    ) AS health_risk_score,

    -- Customer segment classification
    CASE
        WHEN ROUND(SUM(insurance_cost_year) - SUM(cost_to_insurance_amount), 2) > 5000 THEN 'High Value'
        WHEN ROUND(SUM(insurance_cost_year) - SUM(cost_to_insurance_amount), 2) > 0 THEN 'Profitable'
        WHEN ROUND(SUM(insurance_cost_year) - SUM(cost_to_insurance_amount), 2) > -5000 THEN 'Break Even'
        ELSE 'High Cost'
    END AS customer_segment,

    -- Health status classification
    CASE
        WHEN (
            CASE WHEN ANY_VALUE(smartwatch_heart_rate_bpm) > 100 THEN 2 ELSE 0 END +
            CASE WHEN ANY_VALUE(blood_oxygen_percent) < 95 THEN 2 ELSE 0 END +
            CASE WHEN ANY_VALUE(blood_pressure_systolic) >= 140 THEN 3 ELSE 0 END +
            CASE WHEN ANY_VALUE(smartwatch_sleep_hours) < 6 THEN 2 ELSE 0 END +
            CASE WHEN ANY_VALUE(sleep_disorder) != 'none' THEN 3 ELSE 0 END +
            CASE WHEN ANY_VALUE(step_count) < 5000 THEN 1 ELSE 0 END +
            CASE WHEN AVG(doctor_visits_count) > 10 THEN 3 ELSE 0 END
        ) >= 8 THEN 'High Risk'
        WHEN (
            CASE WHEN ANY_VALUE(smartwatch_heart_rate_bpm) > 100 THEN 2 ELSE 0 END +
            CASE WHEN ANY_VALUE(blood_oxygen_percent) < 95 THEN 2 ELSE 0 END +
            CASE WHEN ANY_VALUE(blood_pressure_systolic) >= 140 THEN 3 ELSE 0 END +
            CASE WHEN ANY_VALUE(smartwatch_sleep_hours) < 6 THEN 2 ELSE 0 END +
            CASE WHEN ANY_VALUE(sleep_disorder) != 'none' THEN 3 ELSE 0 END +
            CASE WHEN ANY_VALUE(step_count) < 5000 THEN 1 ELSE 0 END +
            CASE WHEN AVG(doctor_visits_count) > 10 THEN 3 ELSE 0 END
        ) >= 4 THEN 'Moderate Risk'
        ELSE 'Low Risk'
    END AS health_status,

    -- Data quality flags
    MAX(CAST(is_invalid_age AS INT64)) AS has_invalid_age,
    MAX(CAST(is_invalid_heart_rate AS INT64)) AS has_invalid_heart_rate,
    MAX(CAST(is_missing_blood_oxygen AS INT64)) AS has_missing_blood_oxygen,

    -- Metadata
    MIN(insurance_year) AS first_policy_year,
    MAX(insurance_year) AS most_recent_policy_year,
    CURRENT_TIMESTAMP() AS created_at

FROM customer_metrics

GROUP BY
    PersonID,
    insurance_age,
    insurance_gender,
    family_status,
    occupational_category,
    wealth_bracket,
    insurance_status,
    insurance_sign_up_date

-- Order by lifetime value (most valuable customers first)
ORDER BY lifetime_profit_contribution DESC
