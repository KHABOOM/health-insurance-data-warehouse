{{
  config(
    materialized='table',
    tags=['star_schema', 'dimension', 'occupation']
  )
}}

/*
    Dimension: Occupation

    Purpose: Store unique combinations of occupational category and wealth bracket

    Grain: One row per unique occupation-wealth combination

    Surrogate Key: occupation_id (auto-generated)

    Attributes:
    - occupational_category: Type of occupation
    - wealth_bracket: Income/wealth level

    Source: {{ ref('attribution') }}
*/

WITH distinct_occupations AS (
    SELECT DISTINCT
        occupational_category,
        wealth_bracket
    FROM {{ ref('attribution') }}
    WHERE occupational_category IS NOT NULL
      AND wealth_bracket IS NOT NULL
)

SELECT
    -- Surrogate key generation using ROW_NUMBER
    ROW_NUMBER() OVER (ORDER BY occupational_category, wealth_bracket) AS occupation_id,

    -- Dimension attributes
    occupational_category,
    wealth_bracket,

    -- Metadata
    CURRENT_TIMESTAMP() AS created_at

FROM distinct_occupations

-- Ensure deterministic ordering for consistent surrogate key assignment
ORDER BY occupational_category, wealth_bracket
