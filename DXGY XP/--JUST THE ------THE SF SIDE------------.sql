--JUST THE ------THE SF SIDE---------------------------------------------------------------------------------------------------------------------------------------------------
WITH SF_OB_city1 AS (
    SELECT
        
        CASE WHEN a.COUNTRY_NAME = 'UK' OR COUNTRY_NAME = 'Ireland' THEN 'UKI'
            ELSE COUNTRY_NAME
            END AS COUNTRY_GROUP,
        TO_DATE(DATE_TRUNC('month', CREATED_IN_RIDER_ADMIN_AT)) AS approved_month,
        CASE WHEN FIRST_WORK_DATE <= DATEADD('day', 28, CREATED_IN_RIDER_ADMIN_AT) THEN 1 ELSE 0 END AS activated_28D,
        CASE WHEN FIRST_ORDER_DATE <= DATEADD('day', 28, CREATED_IN_RIDER_ADMIN_AT) THEN 1 ELSE 0 END AS activated_1_order_28D,
        CASE WHEN FIRST_20_ORDERS_DATE <= DATEADD('day', 28, CREATED_IN_RIDER_ADMIN_AT) THEN 1 ELSE 0 END AS activated_20_order_28D,
        CASE WHEN CURRENT_TIMESTAMP() > DATEADD('day', 28, CREATED_IN_RIDER_ADMIN_AT) THEN 1 ELSE 0 END AS approved_28D,
        CASE WHEN FIRST_WORK_DATE IS NOT NULL THEN 1 ELSE 0 END AS activatedd,
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
        city,
        activated_28D,
        activated_1_order_28D,
        activated_20_order_28D,
        approved_28D,
        activatedd,
        CREATED_IN_RIDER_ADMIN_AT,
        driver_id
    FROM SF_OB_city1
    WHERE rn = 1
),

SF_count_ob_riders AS (
    SELECT
        COUNTRY_GROUP,
        approved_month, 
        CREATED_IN_RIDER_ADMIN_AT,
        COUNT(driver_id) AS ob_riders_count,
        SUM(activated_28D) activated_28D,
        SUM(activated_1_order_28D) activated_1_order_28D,
        SUM(activated_20_order_28D) activated_20_order_28D,
        SUM(approved_28D) AS approved_28D,
        sum(activatedd) AS activatedd
    FROM SF_ob_rider_cityonly
    GROUP BY COUNTRY_GROUP, approved_month, CREATED_IN_RIDER_ADMIN_AT
),

SF_cities_worked_in AS (
    SELECT a.COUNTRY_GROUP,
        a.approved_month,
        CREATED_IN_RIDER_ADMIN_AT,
        a.driver_id,
        a.city AS ob_city,
        b.city_name AS city_worked,
        CASE WHEN MIN(clock_in) IS NULL THEN NULL
            ELSE MIN(clock_in) END AS first_work_date,
        CASE 
            WHEN city_worked = ob_city THEN 1 
            ELSE 0 
        END AS matches_ob_city,
        SUM(b.hrs_worked_raw) AS sum_hours_worked,
        CASE WHEN MIN(clock_in) IS NULL THEN 0 
            WHEN MIN(clock_in) <= DATEADD('day', 28, CREATED_IN_RIDER_ADMIN_AT) THEN 1
            ELSE 0 END AS activated_28DD,
         
        
    FROM SF_ob_rider_cityonly AS a 
    LEFT JOIN production.denormalised.driver_hours_worked AS b ON a.driver_id = b.driver_id
    GROUP BY 1, 2, 3, 4, 5, 6, CREATED_IN_RIDER_ADMIN_AT
    --HAVING sum_hours_worked >= 1
    ORDER BY 1, 2, 3, 4, 5, 6 DESC
)

    SELECT
        COUNTRY_GROUP,
        approved_month,
        CREATED_IN_RIDER_ADMIN_AT,
        first_work_date,
        driver_id,
        activated_28DD,
        SUM(CASE WHEN matches_ob_city = 0 THEN sum_hours_worked ELSE 0 END) AS hours_elsewhere,
        SUM(CASE WHEN matches_ob_city = 1 THEN sum_hours_worked ELSE 0 END) AS hours_obcity,
        SUM(sum_hours_worked) AS hours_total,
        
        CASE WHEN hours_total = 0 THEN 0 ELSE hours_elsewhere / hours_total END AS pct_hours_elsewhere,
        CASE 
            WHEN pct_hours_elsewhere >= 0.5 THEN 1 
            ELSE 0 
        END AS mostly_worked_elsewhere
    FROM SF_cities_worked_in
    GROUP BY 1, 2, 3, 4, 5, 6
    ORDER BY 1, 2
    