{{
  config(
    materialized='table',
    tags=['cleaned', 'attribution', 'synthetic']
  )
}}

/*
    Attribution Model - Synthetic Join Key Generation

    WARNING: This model uses FABRICATED join keys to create synthetic relationships
    between unrelated datasets. The relationships are RANKOM and NOT based on actual
    person identifiers.

    Purpose: Analytics/Testing with blind joins across all cleaned tables

    Logic:
    1. Generate RANKom join_id for each table using ROW_NUMBER() OVER (ORDER BY RANK())
    2. Perform INNER JOINs on fabricated join_id
    3. Use join_id as new PersonID (overwrites real identifiers)

    Data Sources:
    - sleep_health_cleaned
    - smartwatch_data_cleaned
    - health_insurance_person_cleaned
    - health_insurance_facts_cleaned

    Output: Fully populated synthetic attribution table limited by smallest table's row count
*/

WITH

-- Step 1: Generate synthetic join keys for sleep_health_cleaned
sleep_with_join_id AS (
    SELECT
        CAST(FLOOR(RAND() * 120) + 1 AS INT64) AS join_id,
        person_id AS original_sleep_person_id,
        -- Exclude: gender, age, occupation, sleep_duration_hours, physical_activity_level,
        -- stress_level, heart_rate_bpm, daily_steps
        quality_of_sleep_score,
        blood_pressure_systolic,
        blood_pressure_diastolic,
        bmi_category,
        sleep_disorder,
        is_invalid_sleep_duration,
        is_invalid_heart_rate,
        is_invalid_age,
        is_invalid_steps,
        is_invalid_blood_pressure,
        loaded_at AS sleep_loaded_at
    FROM {{ ref('sleep_health_cleaned') }}
),

-- Step 2: Generate synthetic join keys for smartwatch_data_cleaned
smartwatch_with_join_id AS (
    SELECT
        CAST(FLOOR(RAND() * 120) + 1 AS INT64) AS join_id,
        user_id AS original_smartwatch_user_id,
        heart_rate_bpm AS smartwatch_heart_rate_bpm,
        blood_oxygen_percent,
        step_count,
        sleep_duration_hours AS smartwatch_sleep_hours,
        activity_level,
        stress_level AS smartwatch_stress_level,
        is_missing_stress_level,
        is_missing_blood_oxygen,
        is_invalid_heart_rate AS smartwatch_is_invalid_hr,
        is_invalid_blood_oxygen,
        is_invalid_step_count,
        is_invalid_sleep_duration AS smartwatch_is_invalid_sleep,
        loaded_at AS smartwatch_loaded_at
    FROM {{ ref('smartwatch_data_cleaned') }}
),

-- Step 3: Generate synthetic join keys for health_insurance_person_cleaned
person_with_join_id AS (
    SELECT
        CAST(FLOOR(RAND() * 120) + 1 AS INT64) AS join_id,
        person_id AS original_insurance_person_id,
        gender AS insurance_gender,
        age AS insurance_age,
        family_status,
        insurance_status,
        wealth_bracket,
        birthdate,
        insurance_sign_up_date,
        address,
        occupational_category,
        is_invalid_age AS insurance_is_invalid_age,
        is_invalid_birthdate,
        is_invalid_signup_date,
        loaded_at AS insurance_person_loaded_at
    FROM {{ ref('health_insurance_person_cleaned') }}
),

-- Step 4: Generate synthetic join keys for health_insurance_facts_cleaned
facts_with_join_id AS (
    SELECT
        CAST(FLOOR(RAND() * 120) + 1 AS INT64) AS join_id,
        person_id AS original_facts_person_id,
        year AS insurance_year,
        doctor_visits_count,
        insurance_cost_year,
        cost_to_insurance_amount,
        is_missing_doctor_visits,
        is_missing_insurance_cost,
        is_invalid_year,
        is_invalid_doctor_visits,
        is_invalid_cost_year,
        is_invalid_cost_to_insurance,
        loaded_at AS facts_loaded_at
    FROM {{ ref('health_insurance_facts_cleaned') }}
)

-- Step 5: Blind Join - INNER JOIN on fabricated join_id
-- Final SELECT with join_id AS PersonID (new Primary Key)
SELECT
    -- PRIMARY KEY: Synthetic join_id replaces all original person identifiers
    sleep.join_id AS PersonID,

    -- Original identifiers preserved for reference (optional)
    sleep.original_sleep_person_id,
    smartwatch.original_smartwatch_user_id,
    person.original_insurance_person_id,
    facts.original_facts_person_id,

    -- Sleep Health columns (excluded: gender, age, occupation, sleep_duration_hours,
    -- physical_activity_level, stress_level, heart_rate_bpm, daily_steps)
    sleep.quality_of_sleep_score,
    sleep.blood_pressure_systolic,
    sleep.blood_pressure_diastolic,
    sleep.bmi_category,
    sleep.sleep_disorder,
    sleep.is_invalid_sleep_duration,
    sleep.is_invalid_heart_rate,
    sleep.is_invalid_age,
    sleep.is_invalid_steps,
    sleep.is_invalid_blood_pressure,
    sleep.sleep_loaded_at,

    -- Smartwatch columns
    smartwatch.smartwatch_heart_rate_bpm,
    smartwatch.blood_oxygen_percent,
    smartwatch.step_count,
    smartwatch.smartwatch_sleep_hours,
    smartwatch.activity_level,
    smartwatch.smartwatch_stress_level,
    smartwatch.is_missing_stress_level,
    smartwatch.is_missing_blood_oxygen,
    smartwatch.smartwatch_is_invalid_hr,
    smartwatch.is_invalid_blood_oxygen,
    smartwatch.is_invalid_step_count,
    smartwatch.smartwatch_is_invalid_sleep,
    smartwatch.smartwatch_loaded_at,

    -- Insurance Person columns
    person.insurance_gender,
    person.insurance_age,
    person.family_status,
    person.insurance_status,
    person.wealth_bracket,
    person.birthdate,
    person.insurance_sign_up_date,
    person.address,
    person.occupational_category,
    person.insurance_is_invalid_age,
    person.is_invalid_birthdate,
    person.is_invalid_signup_date,
    person.insurance_person_loaded_at,

    -- Insurance Facts columns
    facts.insurance_year,
    facts.doctor_visits_count,
    facts.insurance_cost_year,
    facts.cost_to_insurance_amount,
    facts.is_missing_doctor_visits,
    facts.is_missing_insurance_cost,
    facts.is_invalid_year,
    facts.is_invalid_doctor_visits,
    facts.is_invalid_cost_year,
    facts.is_invalid_cost_to_insurance,
    facts.facts_loaded_at

FROM sleep_with_join_id AS sleep

INNER JOIN smartwatch_with_join_id AS smartwatch
    ON sleep.join_id = smartwatch.join_id

INNER JOIN person_with_join_id AS person
    ON sleep.join_id = person.join_id

INNER JOIN facts_with_join_id AS facts
    ON sleep.join_id = facts.join_id

-- Result limited by smallest table's row count due to INNER JOIN
