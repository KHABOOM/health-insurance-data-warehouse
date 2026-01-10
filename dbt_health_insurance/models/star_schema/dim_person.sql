{{
  config(
    materialized='table',
    tags=['star_schema', 'dimension', 'person']
  )
}}

/*
    Dimension: Person

    Purpose: Store person demographic attributes

    Grain: One row per unique PersonID

    Natural Key: PersonID (from attribution table)

    Attributes:
    - insurance_age: Age of the person
    - is_invalid_age: Data quality flag for age
    - insurance_gender: Gender
    - family_status: Marital/family status

    Source: {{ ref('attribution') }}
*/

WITH person_attributes AS (
    SELECT
        PersonID,
        insurance_age,
        is_invalid_age,
        insurance_gender,
        family_status,
        -- Use ROW_NUMBER to pick one record per PersonID (arbitrary but deterministic)
        ROW_NUMBER() OVER (
            PARTITION BY PersonID
            ORDER BY insurance_age, insurance_gender, family_status
        ) AS row_num
    FROM {{ ref('attribution') }}
    WHERE PersonID IS NOT NULL
)

SELECT
    -- Natural key (already exists from attribution)
    PersonID,

    -- Demographic attributes
    insurance_age,
    is_invalid_age,
    insurance_gender,
    family_status,

    -- Metadata
    CURRENT_TIMESTAMP() AS created_at

FROM person_attributes
WHERE row_num = 1

-- Ensure unique PersonID
ORDER BY PersonID
