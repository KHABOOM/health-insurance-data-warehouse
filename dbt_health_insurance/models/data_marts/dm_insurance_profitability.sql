{{
  config(
    materialized='table',
    tags=['data_marts', 'analytics', 'insurance', 'financial']
  )
}}

/*
    Data Mart: Insurance Profitability Analysis

    Purpose: Analyze insurance costs, claims, and profitability by occupation and wealth segments

    Business Questions Answered:
    - Which occupation/wealth segments are most profitable?
    - What is the claim ratio by demographic?
    - How do healthcare utilization patterns vary by socioeconomic status?

    Grain: One row per (occupational_category, wealth_bracket, insurance_status) combination

    Source: Star Schema (fact_health_metrics + dim_occupation + dim_insurance)

    Users: Insurance Underwriters, Finance Team, Product Managers
*/

WITH insurance_metrics AS (
    SELECT
        f.*,
        o.occupational_category,
        o.wealth_bracket,
        i.insurance_status,
        i.insurance_sign_up_date,
        i.is_invalid_signup_date
    FROM {{ ref('fact_health_metrics') }} f
    INNER JOIN {{ ref('dim_occupation') }} o
        ON f.occupation_id = o.occupation_id
    INNER JOIN {{ ref('dim_insurance') }} i
        ON f.insurance_id = i.insurance_id
    WHERE i.is_invalid_signup_date = FALSE
)

SELECT
    -- Segmentation dimensions
    occupational_category,
    wealth_bracket,
    insurance_status,

    -- Customer metrics
    COUNT(DISTINCT PersonID) AS unique_customers,
    COUNT(*) AS total_policy_years,

    -- Revenue metrics (premiums collected)
    ROUND(SUM(insurance_cost_year), 2) AS total_premiums_collected,
    ROUND(AVG(insurance_cost_year), 2) AS avg_annual_premium,
    ROUND(MIN(insurance_cost_year), 2) AS min_premium,
    ROUND(MAX(insurance_cost_year), 2) AS max_premium,

    -- Cost metrics (claims paid)
    ROUND(SUM(cost_to_insurance_amount), 2) AS total_claims_paid,
    ROUND(AVG(cost_to_insurance_amount), 2) AS avg_annual_claims,
    ROUND(MIN(cost_to_insurance_amount), 2) AS min_claims,
    ROUND(MAX(cost_to_insurance_amount), 2) AS max_claims,

    -- Profitability metrics
    ROUND(SUM(insurance_cost_year) - SUM(cost_to_insurance_amount), 2) AS net_profit,
    ROUND(AVG(insurance_cost_year - cost_to_insurance_amount), 2) AS avg_profit_per_policy,

    -- Loss ratio (claims / premiums) - key insurance metric
    ROUND(100.0 * SUM(cost_to_insurance_amount) / NULLIF(SUM(insurance_cost_year), 0), 2) AS loss_ratio_pct,

    -- Healthcare utilization
    ROUND(AVG(doctor_visits_count), 1) AS avg_doctor_visits,
    ROUND(SUM(doctor_visits_count), 0) AS total_doctor_visits,

    -- Risk indicators
    ROUND(100.0 * SUM(CASE WHEN cost_to_insurance_amount > insurance_cost_year THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_unprofitable_policies,
    ROUND(100.0 * SUM(CASE WHEN doctor_visits_count > 10 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_high_utilizers,

    -- Health risk flags (from fact table)
    ROUND(100.0 * SUM(CASE WHEN sleep_disorder != 'none' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_sleep_disorders,
    ROUND(100.0 * SUM(CAST(is_invalid_heart_rate AS INT64)) / COUNT(*), 2) AS pct_invalid_heart_rate,

    -- Metadata
    MIN(insurance_sign_up_date) AS earliest_signup_date,
    MAX(insurance_sign_up_date) AS latest_signup_date,
    CURRENT_TIMESTAMP() AS created_at

FROM insurance_metrics

GROUP BY occupational_category, wealth_bracket, insurance_status

-- Order by profitability (most profitable first)
ORDER BY net_profit DESC
