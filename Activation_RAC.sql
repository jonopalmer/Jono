--JUST THE ------THE SF SIDE---------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TEMPORARY TABLE SF_OB_city1 AS (
    SELECT
        CASE WHEN a.COUNTRY_NAME = 'UK' OR COUNTRY_NAME = 'Ireland' THEN 'UKI'
            ELSE COUNTRY_NAME
            END AS COUNTRY_GROUP,
        TO_DATE(DATE_TRUNC('month', CREATED_IN_RIDER_ADMIN_AT)) AS approved_month,
        CASE WHEN FIRST_WORK_DATE <= DATEADD('day', 28, CREATED_IN_RIDER_ADMIN_AT) THEN 1 ELSE 0 END AS activated_28D_OB_city,
        CASE WHEN FIRST_WORK_DATE IS NOT NULL THEN 1 ELSE 0 END AS activated_OB_city,
        CASE WHEN HOURS_WORKED_CUMULATIVE >= 1 THEN 1 ELSE 0 END AS activated_1HOUR_OB_city,
        CASE WHEN FIRST_ORDER_DATE <= DATEADD('day', 28, CREATED_IN_RIDER_ADMIN_AT) THEN 1 ELSE 0 END AS ORDER_1_28D_OB_city,
        CASE WHEN FIRST_ORDER_DATE IS NOT NULL THEN 1 ELSE 0 END AS ORDER_1_OB_city,
        CASE WHEN FIRST_20_ORDERS_DATE <= DATEADD('day', 28, CREATED_IN_RIDER_ADMIN_AT) THEN 1 ELSE 0 END AS ORDER_20_28D_OB_city,
        CASE WHEN FIRST_20_ORDERS_DATE IS NOT NULL THEN 1 ELSE 0 END AS ORDER_20_OB_city,
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
      AND DATE = (SELECT MAX(DATE) FROM production.denormalised.driver_accounting_daily)
     
);

CREATE OR REPLACE TEMPORARY TABLE SF_ob_rider_cityonly AS (
    SELECT
        COUNTRY_GROUP,
        approved_month,
        city,
        activated_28D_OB_city,
        activated_OB_city,
        activated_1HOUR_OB_city,
        ORDER_1_28D_OB_city,
        ORDER_1_OB_city,
        ORDER_20_28D_OB_city,
        ORDER_20_OB_city,
        CREATED_IN_RIDER_ADMIN_AT,
        driver_id
    FROM SF_OB_city1
    WHERE rn = 1
);

CREATE OR REPLACE TEMPORARY TABLE SF_count_ob_riders AS (
    SELECT
        COUNTRY_GROUP,
        approved_month,
        COUNT(driver_id) AS ob_riders_count,
        SUM(activated_28D_OB_city) activated_28D_OB_city,
        sum(activated_OB_city) AS activated_OB_city,
        SUM(activated_1HOUR_OB_city) AS activated_1HOUR_OB_city,
        SUM(ORDER_1_28D_OB_city) AS ORDER_1_28D_OB_city,
        SUM(ORDER_1_OB_city) AS ORDER_1_OB_city,
        SUM(ORDER_20_28D_OB_city) AS ORDER_20_28D_OB_city,
        SUM(ORDER_20_OB_city) AS ORDER_20_OB_city

    FROM SF_ob_rider_cityonly
    GROUP BY COUNTRY_GROUP, approved_month
);

CREATE OR REPLACE TEMPORARY TABLE SF_cities_worked_in AS (
    SELECT 
        a.COUNTRY_GROUP,
        a.approved_month,
        CREATED_IN_RIDER_ADMIN_AT,
        a.driver_id,
        a.city AS ob_city,
        b.city_name AS city_worked,
        CASE 
            WHEN city_worked = ob_city THEN 1 
            ELSE 0 
        END AS matches_ob_city,
        SUM(b.hrs_worked_raw) AS sum_hours_worked
    FROM SF_ob_rider_cityonly AS a 
    LEFT JOIN production.denormalised.driver_hours_worked AS b ON a.driver_id = b.driver_id
    WHERE b.country_name IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland')
        AND TO_DATE(DATE_TRUNC('month', b.date)) >= '2023-11-01' 
    GROUP BY 1, 2, 3, 4, 5, 6
    HAVING sum_hours_worked >= 1
    ORDER BY 1, 2, 3, 4, 5, 6 DESC
);
/* 
CREATE OR REPLACE TEMPORARY TABLE Activation AS (

    SELECT
    COUNTRY_GROUP,
    approved_month,
    --SUM(activated_28D_CW) AS activated_28D_CW,
    SUM(activated_CW) AS activated_CW
    FROM SF_cities_worked_in
    GROUP BY 1, 2
    ORDER BY 1, 2);
*/




CREATE OR REPLACE TEMPORARY TABLE SF_hours_split AS (
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
    GROUP BY 1, 2, 3, 4
    ORDER BY 1, 2
);

CREATE OR REPLACE TEMPORARY TABLE SF_FINAL_QUERY AS
(SELECT
    a.COUNTRY_GROUP AS "Country Group",
    a.approved_month AS "Approved Month",
    b.ob_riders_count AS "Riders Onboarded",
    activated_28D_OB_city AS "Activated 28 Days",
    activated_OB_city AS "Activated",
    activated_1HOUR_OB_city AS "Activated 1 Hour",
    ORDER_1_28D_OB_city AS ">=1 Order 28 Days",
    ORDER_1_OB_city AS ">=1 Order",
    ORDER_20_28D_OB_city AS ">=20 Orders 28 Days",
    ORDER_20_OB_city AS ">=20 Orders",
    COUNT(DISTINCT a.driver_id) AS "Activated 1 Hour DHW",
    ROUND(COUNT(DISTINCT a.driver_id) / NULLIF(b.ob_riders_count, 0), 3) AS "Activated 1 Hour Rate",
    ROUND(COUNT(CASE WHEN a.hours_obcity = 0 THEN 1 END) / COUNT(DISTINCT a.driver_id), 3) AS "% Riders Never Worked in OB City",
    COUNT(CASE WHEN a.hours_obcity = 0 THEN 1 END) AS "Riders Never Worked in OB City",
    ROUND(SUM(a.mostly_worked_elsewhere) / COUNT(DISTINCT a.driver_id), 3) AS "% Riders with >50% Hours Not in OB City",
    ROUND(SUM(a.hours_obcity) / SUM(a.hours_total), 3) AS "% Hours Worked in OB City",
    ROUND(SUM(a.hours_elsewhere) / SUM(a.hours_total), 3) AS "% Hours Worked Outside of OB City",
    ROUND(SUM(a.hours_obcity), 0) AS "Hours Worked in OB City",
    ROUND(SUM(a.hours_elsewhere), 0) AS "Hours Worked Outside of OB City"
FROM SF_hours_split AS a
LEFT JOIN SF_count_ob_riders AS b ON a.approved_month = b.approved_month AND a.COUNTRY_GROUP = b.COUNTRY_GROUP
WHERE a.approved_month >= '2023-11-01' 
GROUP BY 1,2,3,4,5,6,7,8,9,10
ORDER BY 1,2
);

WITH FINAL_FINAL AS
(
SELECT *
FROM SF_FINAL_QUERY
)

SELECT *
FROM FINAL_FINAL
--WHERE approved_month <> '2023-10-01' ----- excluding Oct as SF transition some data in Fountain some SF
ORDER BY 1 DESC, 2 DESC

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
