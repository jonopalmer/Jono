------- LEAKAGE DATA FOUNTAIN PRE SF FOR EUROPE------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE for onboarding rider city only
WITH FT_ob_rider_cityonly AS (
    SELECT
        CASE WHEN a.COUNTRY_NAME = 'UK' OR a.COUNTRY_NAME = 'Ireland' THEN 'UKI'
            ELSE a.COUNTRY_NAME
            END AS COUNTRY_GROUP,
        TO_DATE(DATE_TRUNC('month', approved_at)) AS approved_month,
        CASE WHEN CURRENT_TIMESTAMP() > DATEADD('day', 28, approved_at) THEN 1 ELSE 0 END AS approved_28D,
        CITY_NAME,
        CAST(driver_id_mapping AS STRING) AS driver_id_string
    FROM production.rider_onboarding.rider_applicants_high_level AS a
    LEFT JOIN production.reference.city_detailed AS b ON a.CITY_DETAILED = b.CITY_DETAILED
    WHERE a.COUNTRY_NAME IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland')
        AND TO_DATE(DATE_TRUNC('month', approved_at)) >= '2021-01-01'
        AND driver_id_mapping IS NOT NULL
        AND applicant_current_stage IN ('Account created', 'Account Created')
    GROUP BY 1, 2, 3, 4
),

-- CTE for counting onboarded riders
FT_count_ob_riders AS (
    SELECT
        CASE WHEN COUNTRY_NAME = 'UK' OR COUNTRY_NAME = 'Ireland' THEN 'UKI'
            ELSE COUNTRY_NAME
            END AS COUNTRY_GROUP,
        TO_DATE(DATE_TRUNC('month', approved_at)) AS approved_month,
        COUNT(DISTINCT CAST(driver_id_mapping AS STRING)) AS ob_riders_count
    FROM production.rider_onboarding.rider_applicants_high_level
    WHERE COUNTRY_NAME IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland')
        AND TO_DATE(DATE_TRUNC('month', approved_at)) >= '2021-01-01' 
        AND driver_id_mapping IS NOT NULL
        AND applicant_current_stage IN ('Account created', 'Account Created')
    GROUP BY 1,2
),

-- CTE for cities worked in
FT_cities_worked_in AS (
    SELECT
        c.COUNTRY_GROUP,
        c.approved_month,
        CAST(a.driver_id AS STRING) AS driver_id_string,
        c.CITY_NAME AS ob_city,
        b.CITY_NAME AS city_worked,
        CASE 
            WHEN city_worked = ob_city THEN 1 
            ELSE 0 
        END AS matches_ob_city,
        SUM(a.hrs_worked_raw) AS sum_hours_worked
    FROM production.denormalised.driver_hours_worked AS a
        LEFT JOIN production.reference.city_detailed AS b ON a.zone_code = b.zone_code
        INNER JOIN FT_ob_rider_cityonly AS c ON CAST(a.driver_id AS STRING) = c.driver_id_string
    WHERE a.COUNTRY_NAME IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland')
        AND TO_DATE(DATE_TRUNC('month', a.date)) >= '2021-01-01' 
    GROUP BY 1, 2, 3, 4, 5, 6
    HAVING sum_hours_worked >= 1
    ORDER BY 1, 2, 3, 4, 5, 6 DESC
),

-- CTE for hours split
FT_hours_split AS (
    SELECT
        COUNTRY_GROUP,
        approved_month,
        driver_id_string,
        SUM(CASE WHEN matches_ob_city = 0 THEN sum_hours_worked ELSE 0 END) AS hours_elsewhere,
        SUM(CASE WHEN matches_ob_city = 1 THEN sum_hours_worked ELSE 0 END) AS hours_obcity,
        SUM(sum_hours_worked) AS hours_total,
        hours_elsewhere / hours_total AS pct_hours_elsewhere,
        CASE 
            WHEN pct_hours_elsewhere >= 0.5 THEN 1 
            ELSE 0 
        END AS mostly_worked_elsewhere
    FROM FT_cities_worked_in
    GROUP BY 1, 2, 3
    ORDER BY 1, 2, 3
),


-- Final SELECT statement
FT_FINAL_QUERY AS(
SELECT
    a.COUNTRY_GROUP,
    a.approved_month,
    b.ob_riders_count AS riders_onboarded,
    COUNT(DISTINCT a.driver_id_string) AS riders_activated,
    ROUND(riders_activated / riders_onboarded, 3) AS activation_rate,
    ROUND(COUNT(CASE WHEN a.hours_obcity = 0 THEN 1 END) / COUNT(DISTINCT a.driver_id_string), 3) AS "% riders never worked in OB city",
    COUNT(CASE WHEN a.hours_obcity = 0 THEN 1 END) AS "riders never worked in OB city",
    ROUND(SUM(a.mostly_worked_elsewhere) / COUNT(DISTINCT a.driver_id_string), 3) AS "% riders >50% hours not in OB city",
    ROUND(SUM(a.hours_obcity) / SUM(a.hours_total), 3) AS "% Hours worked in OB city",
    ROUND(SUM(a.hours_elsewhere) / SUM(a.hours_total), 3) AS "% Hours worked outside of OB city",
    ROUND(SUM(a.hours_obcity), 0) AS "Hours worked in OB city",
    ROUND(SUM(a.hours_elsewhere), 0) AS "Hours worked outside of OB city"
FROM FT_hours_split AS a
LEFT JOIN FT_count_ob_riders AS b ON a.approved_month = b.approved_month AND a.COUNTRY_GROUP = b.COUNTRY_GROUP
GROUP BY 1, 2, 3
ORDER BY 1, 2
),




--------THE SF SIDE---------------------------------------------------------------------------------------------------------------------------------------------------
SF_OB_city1 AS (
    SELECT
        
        CASE WHEN a.COUNTRY_NAME = 'UK' OR COUNTRY_NAME = 'Ireland' THEN 'UKI'
            ELSE COUNTRY_NAME
            END AS COUNTRY_GROUP,
        TO_DATE(DATE_TRUNC('month', CREATED_IN_RIDER_ADMIN_AT)) AS approved_month,
        CASE WHEN CURRENT_TIMESTAMP() > DATEADD('day', 28, CREATED_IN_RIDER_ADMIN_AT) THEN 1 ELSE 0 END AS approved_28D,
        CREATED_IN_RIDER_ADMIN_AT,
        CITY,
        driver_id,
        ROW_NUMBER() OVER (PARTITION BY RIDER_UUID ORDER BY CREATED_IN_RIDER_ADMIN_AT ASC, CITY) AS rn
    FROM PRODUCTION.RIDERS.RIDER_LIFECYCLE_LATEST_STATUS AS a
    LEFT JOIN production.denormalised.driver_accounting_daily AS b ON CAST(a.RIDER_UUID AS STRING) = CAST(b.DRIVER_UUID AS STRING)
    WHERE ONBOARDING_PLATFORM = 'salesforce'
      AND LIFECYCLE_MAIN_STAGE = 'application'
      AND COUNTRY_NAME IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland')
      AND IS_CREATED_ON_ADMIN = 'TRUE'
      AND TO_DATE(DATE_TRUNC('month', CREATED_IN_RIDER_ADMIN_AT)) >= '2023-11-01'
),

SF_ob_rider_cityonly AS (
    SELECT
        COUNTRY_GROUP,
        approved_month,
        CITY,
        driver_id
    FROM SF_OB_city1
    WHERE rn = 1
),

SF_count_ob_riders AS (
    SELECT
        COUNTRY_GROUP,
        approved_month, 
        COUNT(driver_id) AS ob_riders_count
    FROM SF_ob_rider_cityonly
    GROUP BY COUNTRY_GROUP, approved_month
),

SF_cities_worked_in AS (
    SELECT a.COUNTRY_GROUP,
        a.approved_month,
        a.driver_id,
        a.city AS ob_city,
        b.city_name AS city_worked,
        CASE 
            WHEN city_worked = ob_city THEN 1 
            ELSE 0 
        END AS matches_ob_city,
        SUM(b.hrs_worked_raw) AS sum_hours_worked
    FROM SF_ob_rider_cityonly AS a 
    INNER JOIN production.denormalised.driver_hours_worked AS b ON a.driver_id = b.driver_id
    WHERE b.country_name IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland')
        AND TO_DATE(DATE_TRUNC('month', b.date)) >= '2023-11-01' 
    GROUP BY 1, 2, 3, 4, 5, 6
    HAVING sum_hours_worked >= 1
    ORDER BY 1, 2, 3, 4, 5, 6 DESC
),

SF_hours_split AS (
    SELECT
        COUNTRY_GROUP,
        approved_month,
        driver_id,
        SUM(CASE WHEN matches_ob_city = 0 THEN sum_hours_worked ELSE 0 END) AS hours_elsewhere,
        SUM(CASE WHEN matches_ob_city = 1 THEN sum_hours_worked ELSE 0 END) AS hours_obcity,
        SUM(sum_hours_worked) AS hours_total,
        hours_elsewhere / hours_total AS pct_hours_elsewhere,
        CASE 
            WHEN pct_hours_elsewhere >= 0.5 THEN 1 
            ELSE 0 
        END AS mostly_worked_elsewhere
    FROM SF_cities_worked_in
    GROUP BY 1, 2, 3
    ORDER BY 1, 2
),

SF_FINAL_QUERY AS
(SELECT
    a.COUNTRY_GROUP,
    a.approved_month,
    b.ob_riders_count AS riders_onboarded,
    COUNT(DISTINCT a.driver_id) AS riders_activated,
    ROUND(riders_activated / riders_onboarded, 3) AS activation_rate,
    ROUND(COUNT(CASE WHEN a.hours_obcity = 0 THEN 1 END) / COUNT(DISTINCT a.driver_id), 3) AS "% riders never worked in OB city",
    COUNT(CASE WHEN a.hours_obcity = 0 THEN 1 END) AS "riders never worked in OB city",
    ROUND(SUM(a.mostly_worked_elsewhere) / COUNT(DISTINCT a.driver_id), 3) AS "% riders >50% hours not in OB city",
    ROUND(SUM(a.hours_obcity) / SUM(a.hours_total), 3) AS "% Hours worked in OB city",
    ROUND(SUM(a.hours_elsewhere) / SUM(a.hours_total), 3) AS "% Hours worked outside of OB city",
    ROUND(SUM(a.hours_obcity), 0) AS "Hours worked in OB city",
    ROUND(SUM(a.hours_elsewhere), 0) AS "Hours worked outside of OB city"
FROM SF_hours_split AS a
LEFT JOIN SF_count_ob_riders AS b ON a.approved_month = b.approved_month AND a.COUNTRY_GROUP = b.COUNTRY_GROUP
WHERE a.approved_month >= '2023-11-01'
GROUP BY 1, 2,3
ORDER BY 1,2
),

FINAL_FINAL AS
(
SELECT *
FROM FT_FINAL_QUERY

UNION ALL

SELECT *
FROM SF_FINAL_QUERY
)

SELECT *
FROM FINAL_FINAL
WHERE approved_month <> '2023-10-01' ----- excluding Oct as SF transition some data in Fountain some SF
ORDER BY 1,2

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
