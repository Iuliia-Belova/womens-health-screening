-- 1. Spain vs EU 27: breast examination, 2019
SELECT country_name,
screening_type, year,
duration_label,
screening_rate
FROM screening
WHERE (geo in ('EU27_2020','ES'))
and year = 2019 
and age = 'TOTAL' 
and isced11 = 'TOTAL'
and duration = 'Y_LT2'
AND screening_type = 'breast_xray'
ORDER BY screening_rate DESC;

-- 2. Country ranking: breast examination, 2019

SELECT country_name,
screening_rate,
DENSE_RANK() OVER (
    ORDER BY screening_rate DESC
) AS country_rank
FROM screening
WHERE (geo not in('EU27_2020','EU28'))
and year = 2019 
and age = 'TOTAL' 
and isced11 = 'TOTAL'
and duration = 'Y_LT2'
AND screening_type = 'breast_xray'
ORDER BY country_rank;

-- 3. Cervical smear: comparison with the country average, 2019

SELECT country_name,
screening_rate,
ROUND(
    screening_rate - AVG(screening_rate) OVER (),
    1
) AS difference_from_average,
ROUND(AVG(screening_rate) OVER (), 1) AS country_average,
CASE
    WHEN screening_rate >= AVG(screening_rate) OVER ()
        THEN 'Above average'
    ELSE 'Below average'
END AS comparison
FROM screening
WHERE (geo not in('EU27_2020','EU28'))
and year = 2019 
and age = 'TOTAL' 
and isced11 = 'TOTAL'
and duration = 'Y_LT3'
AND screening_type = 'cervical_smear'
ORDER BY screening_rate DESC;

-- 4. Cervical screening trend: Spain vs EU 27

WITH cervical_trend AS (
    SELECT
        geo,
        country_name,
        year,
        screening_rate,
        LAG(screening_rate) OVER (
            PARTITION BY geo
            ORDER BY year) AS previous_rate
    FROM screening
    WHERE geo IN ('ES', 'EU27_2020')
        AND age = 'TOTAL'
        AND isced11 = 'TOTAL'
        AND duration = 'Y_LT3'
        AND screening_type = 'cervical_smear'
)

SELECT
    geo,
    country_name,
    year,
    screening_rate,
    previous_rate,
    ROUND(screening_rate - previous_rate, 1) AS rate_change
FROM cervical_trend
ORDER BY geo, year;

-- 5. Cervical screening: education gap ranking, 2019

WITH education_rates AS (
    SELECT
        country_name,
        MAX(
            CASE
                WHEN isced11 = 'ED0-2' THEN screening_rate
            END
        ) AS low_education,
        MAX(
            CASE
                WHEN isced11 = 'ED3_4' THEN screening_rate
            END
        ) AS middle_education,
        MAX(
            CASE
                WHEN isced11 = 'ED5-8' THEN screening_rate
            END
        ) AS high_education
    FROM screening
    WHERE screening_type = 'cervical_smear'
        AND duration = 'Y_LT3'
        AND year = 2019
        AND age = 'TOTAL'
        AND isced11 != 'TOTAL'
        AND geo NOT IN ('EU27_2020', 'EU28')
    GROUP BY country_name
)

SELECT
    country_name,
    low_education,
    middle_education,
    high_education,
    ROUND(high_education - low_education, 1) AS education_gap,
    RANK() OVER (
        ORDER BY ROUND(high_education - low_education,1) DESC
    ) AS gap_rank
FROM education_rates
ORDER BY gap_rank, country_name;