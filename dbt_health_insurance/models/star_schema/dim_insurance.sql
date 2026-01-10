{{
  config(
    materialized='table',
    tags=['star_schema', 'dimension', 'insurance']
  )
}}

/*
    Dimension: Insurance

    Purpose: Store unique insurance policy combinations

    Grain: One row per unique insurance status + sign-up date combination

    Surrogate Key: insurance_id (auto-generated)

    Attributes:
    - insurance_status: Status of insurance (ACTIVE, INACTIVE, etc.)
    - insurance_sign_up_date: Date when insurance was signed up
    - is_invalid_signup_date: Data quality flag for sign-up date

    Source: {{ ref('attribution') }}
*/

WITH distinct_insurance AS (
    SELECT DISTINCT
        insurance_status,
        insurance_sign_up_date,
        is_invalid_signup_date
    FROM {{ ref('attribution') }}
    WHERE insurance_status IS NOT NULL
)

SELECT
    -- Surrogate key generation using ROW_NUMBER
    ROW_NUMBER() OVER (ORDER BY insurance_status, insurance_sign_up_date) AS insurance_id,

    -- Dimension attributes
    insurance_status,
    insurance_sign_up_date,
    is_invalid_signup_date,

    -- Metadata
    CURRENT_TIMESTAMP() AS created_at

FROM distinct_insurance

-- Ensure deterministic ordering for consistent surrogate key assignment
ORDER BY insurance_status, insurance_sign_up_date
