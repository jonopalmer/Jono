--- Reactivation Rider List Targeting
-- Active 28 weeks Inactive 28 Days
WITH ZONE_T0_AREA AS(
    SELECT z.zone_code, c.onboarding_area
    FROM scratch.riders.zone_drn_id_to_onboarding_area c
    LEFT JOIN production.aggregate.agg_zone_delivery_metrics_hourly z ON c.zone_code = z.zone_code
    WHERE z.country_name IN ('UK', 'Ireland')
    GROUP BY 1,2
),

RIDER_ZONE AS (
    SELECT
        driver_id, driver_uuid, cur_zone, most_common_zone_code_hrs_worked, ZA.ONBOARDING_AREA AS CUR_OA, ZA2.ONBOARDING_AREA AS AVG_OA
    FROM production.denormalised.driver_accounting_daily AS DAD 
    LEFT JOIN ZONE_T0_AREA AS ZA ON DAD.cur_zone = ZA.zone_code
    LEFT JOIN ZONE_T0_AREA AS ZA2 ON DAD.most_common_zone_code_hrs_worked = ZA2.zone_code

    WHERE DATE >= TO_DATE(DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))
      AND DATE < TO_DATE(DATEADD('day', 1, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
      AND CUR_COUNTRY IN ('Ireland', 'UK')
      AND cur_zone IS NOT NULL
    GROUP BY driver_id, driver_uuid, cur_zone, most_common_zone_code_hrs_worked, ZA.ONBOARDING_AREA, ZA2.ONBOARDING_AREA
),

LW AS(
SELECT
    driver_uuid, MAX(DATE) AS LAST_WORK_DATE
FROM production.denormalised.driver_accounting_daily
WHERE CUR_COUNTRY IN ('Ireland', 'UK') AND ORDERS_DELIVERED IS NOT NULL
GROUP BY driver_uuid
),

ORDERS AS (
    SELECT
        DAD.driver_uuid,
        SUM(CASE WHEN DATE >= TO_DATE(DATEADD('day', -196, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))) THEN ORDERS_DELIVERED ELSE 0 END) AS "Total Orders"
        , SUM(CASE WHEN DATE >= TO_DATE(DATEADD('day', -28, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))) THEN ORDERS_DELIVERED ELSE 0 END) AS "Weeks 0-4"
        , SUM(CASE WHEN DATE >= TO_DATE(DATEADD('day', -56, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))) AND DATE < TO_DATE(DATEADD('day', -28, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))) THEN ORDERS_DELIVERED ELSE 0 END) AS "Weeks 4-8"
        , SUM(CASE WHEN DATE >= TO_DATE(DATEADD('day', -84, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))) AND DATE < TO_DATE(DATEADD('day', -56, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))) THEN ORDERS_DELIVERED ELSE 0 END) AS "Weeks 8-12"
        , SUM(CASE WHEN DATE >= TO_DATE(DATEADD('day', -112, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))) AND DATE < TO_DATE(DATEADD('day', -84, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))) THEN ORDERS_DELIVERED ELSE 0 END) AS "Weeks 12-16"
        , SUM(CASE WHEN DATE >= TO_DATE(DATEADD('day', -140, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))) AND DATE < TO_DATE(DATEADD('day', -112, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))) THEN ORDERS_DELIVERED ELSE 0 END) AS "Weeks 16-20"
        , SUM(CASE WHEN DATE >= TO_DATE(DATEADD('day', -168, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))) AND DATE < TO_DATE(DATEADD('day', -140, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))) THEN ORDERS_DELIVERED ELSE 0 END) AS "Weeks 20-24"
        , SUM(CASE WHEN DATE >= TO_DATE(DATEADD('day', -196, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))) AND DATE < TO_DATE(DATEADD('day', -168, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))) THEN ORDERS_DELIVERED ELSE 0 END) AS "Weeks 24-28"
        , LW.LAST_WORK_DATE
        , SUM(CASE WHEN DATE >= TO_DATE(DATEADD('day', -28, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London',LW.LAST_WORK_DATE)))) THEN ORDERS_DELIVERED ELSE 0 END) AS Last_4W
    FROM production.denormalised.driver_accounting_daily DAD
    LEFT JOIN LW ON LW.driver_uuid = DAD.driver_uuid
    WHERE DATE >= TO_DATE(DATEADD('day', -196, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
      AND DATE < TO_DATE(DATEADD('day', 1, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
      AND CUR_COUNTRY IN ('Ireland', 'UK')
    GROUP BY DAD.driver_uuid, LW.LAST_WORK_DATE
)

SELECT Z.driver_id, Z.driver_uuid, cur_zone, CUR_OA, AVG_OA, "Total Orders", "Weeks 24-28",  "Weeks 20-24",  "Weeks 16-20",  "Weeks 12-16", "Weeks 8-12",  "Weeks 4-8", LAST_WORK_DATE, Last_4W
FROM RIDER_ZONE AS Z
LEFT JOIN ORDERS AS O
ON Z.driver_uuid = O.driver_uuid
WHERE "Weeks 0-4" = 0
    AND "Total Orders" > 0
ORDER BY driver_id
;

-- Last day active - 28 days OV delivered













WITH CTE AS (
SELECT driver_id,
       cluster_name,
       COUNT(CASE WHEN status = 'DELIVERED' THEN 1 ELSE NULL END) AS orders_count
FROM PRODUCTION.denormalised.orders
WHERE order_date >= DATEADD('day', -7, CURRENT_DATE)
    AND TO_CHAR(order_date, 'DY') = 'Sat'
    AND EXTRACT(HOUR FROM TO_TIMESTAMP_NTZ(COALESCE(LOCAL_TIME_DELIVERED_AT, LOCAL_TIME_CREATED_AT, LOCAL_TIME_TARGET_READY_AT))) BETWEEN 11 AND 20
    AND COUNTRY_NAME IN ('UK', 'Ireland')
GROUP BY driver_id, cluster_name
)

SELECT *
FROM CTE
PIVOT 
(
    COUNT(driver_id) 
    FOR orders_count IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100)
) AS pivot_table
ORDER BY cluster_name
;