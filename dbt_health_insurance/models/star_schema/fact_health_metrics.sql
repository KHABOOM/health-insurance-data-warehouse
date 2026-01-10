{{
  config(
    materialized='table',
    tags=['star_schema', 'fact', 'health_metrics']
  )
}}

/*
    Fact Table: Health Metrics

    Purpose: Store health and insurance metrics with foreign keys to dimensions

    Grain: One row per attribution record (denormalized from multiple sources)

    Foreign Keys:
    - PersonID: Links to dim_person
    - occupation_id: Links to dim_occupation
    - insurance_id: Links to dim_insurance

    Measures (Numeric):
    - doctor_visits_count: Number of doctor visits
    - insurance_cost_year: Annual insurance cost
    - cost_to_insurance_amount: Cost charged to insurance
    - smartwatch_sleep_hours: Sleep hours from smartwatch
    - quality_of_sleep_score: Sleep quality score (1-10)
    - blood_pressure_systolic: Systolic blood pressure
    - blood_pressure_diastolic: Diastolic blood pressure
    - smartwatch_heart_rate_bpm: Heart rate from smartwatch
    - blood_oxygen_percent: Blood oxygen saturation

    Measures (Categorical):
    - activity_level: Physical activity level
    - sleep_disorder: Type of sleep disorder
    - smartwatch_stress_level: Stress level from smartwatch

    Data Quality Flags:
    - is_invalid_heart_rate: Heart rate validation flag
    - is_invalid_steps: Step count validation flag
    - is_missing_blood_oxygen: Blood oxygen missing flag
    - is_invalid_blood_oxygen: Blood oxygen validation flag
    - is_missing_stress_level: Stress level missing flag

    Source: {{ ref('attribution') }} + dimension lookups
*/

WITH attribution_with_keys AS (
    SELECT
        a.*,

        -- Join to dim_occupation to get occupation_id
        occ.occupation_id,

        -- Join to dim_insurance to get insurance_id
        ins.insurance_id

    FROM {{ ref('attribution') }} AS a

    -- Lookup occupation_id
    LEFT JOIN {{ ref('dim_occupation') }} AS occ
        ON a.occupational_category = occ.occupational_category
        AND a.wealth_bracket = occ.wealth_bracket

    -- Lookup insurance_id
    LEFT JOIN {{ ref('dim_insurance') }} AS ins
        ON a.insurance_status = ins.insurance_status
        AND a.insurance_sign_up_date = ins.insurance_sign_up_date
        AND a.is_invalid_signup_date = ins.is_invalid_signup_date
)

SELECT
    -- Surrogate key for fact table (optional but recommended)
    ROW_NUMBER() OVER (ORDER BY PersonID, insurance_year) AS health_metric_id,

    -- Foreign Keys to Dimensions
    PersonID,                    -- Links to dim_person
    occupation_id,               -- Links to dim_occupation
    insurance_id,                -- Links to dim_insurance

    -- Additional context (degenerate dimension)
    insurance_year,

    -- Numeric Measures
    doctor_visits_count,
    insurance_cost_year,
    cost_to_insurance_amount,
    smartwatch_sleep_hours,
    quality_of_sleep_score,
    blood_pressure_systolic,
    blood_pressure_diastolic,
    smartwatch_heart_rate_bpm,
    blood_oxygen_percent,
    step_count,

    -- Categorical Measures
    activity_level,
    sleep_disorder,
    smartwatch_stress_level,

    -- Data Quality Flags
    is_invalid_heart_rate,
    is_invalid_steps,
    is_missing_blood_oxygen,
    is_invalid_blood_oxygen,
    is_missing_stress_level,

    -- Metadata
    CURRENT_TIMESTAMP() AS created_at

FROM attribution_with_keys

-- Filter out records with missing dimension keys (optional - adjust based on business rules)
WHERE PersonID IS NOT NULL
  AND occupation_id IS NOT NULL
  AND insurance_id IS NOT NULL
