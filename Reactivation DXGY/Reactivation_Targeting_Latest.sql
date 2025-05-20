--- Reactivation Rider List Targeting
-- Active 28 weeks, Inactive 28 Days, no subs, active rider admin and email subscribed
SET country1 = 'UK';
SET country2 = 'Ireland';

-- Step 1: Map zones to onboarding areas
WITH ZONE_T0_AREA AS (
    SELECT 
        z.zone_code, 
        c.onboarding_area
    FROM scratch.riders.zone_drn_id_to_onboarding_area c
    LEFT JOIN production.aggregate.agg_zone_delivery_metrics_hourly z 
        ON c.zone_code = z.zone_code
    WHERE z.country_name IN ($country1, $country2)
    GROUP BY 1, 2
),

-- Step 2: Get rider's current and most common onboarding areas, removing substitutes and parent accounts
RIDER_ZONE AS (
    SELECT
        driver_id, 
        driver_uuid, 
        cur_zone, 
        most_common_zone_code_hrs_worked, 
        ZA.onboarding_area AS current_oa, 
        ZA2.onboarding_area AS most_common_oa
    FROM production.denormalised.driver_accounting_daily AS DAD 
    LEFT JOIN ZONE_T0_AREA AS ZA 
        ON DAD.cur_zone = ZA.zone_code
    LEFT JOIN ZONE_T0_AREA AS ZA2 
        ON DAD.most_common_zone_code_hrs_worked = ZA2.zone_code
    WHERE DATE >= TO_DATE(DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))
      AND DATE < TO_DATE(DATEADD('day', 1, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
      AND cur_country IN ($country1, $country2)
      AND cur_zone IS NOT NULL
      AND is_substitute = 'No'
      AND driver_id NOT IN 
                ( SELECT parent_account_id
                    FROM production.denormalised.driver_accounting_daily AS dad
                    WHERE dad.date >= TO_DATE(DATEADD('day', -1, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
                    AND dad.date < TO_DATE(DATEADD('day', 1, DATEADD('day', -1, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))))
                    AND dad.parent_account_id IS NOT NULL
                )
    GROUP BY 
        driver_id, 
        driver_uuid, 
        cur_zone, 
        most_common_zone_code_hrs_worked, 
        ZA.onboarding_area, 
        ZA2.onboarding_area
),

-- Step 3: Get the last work date for each driver
LW AS (
    SELECT
        driver_uuid, 
        MAX(DATE) AS last_work_date
    FROM production.denormalised.driver_accounting_daily
    WHERE cur_country IN ($country1, $country2)
      AND orders_delivered IS NOT NULL
    GROUP BY driver_uuid
),

-- Step 4: Check if the rider is subscribed to Braze
Braze AS (
    SELECT 
        r.rider_uuid, 
        s.braze_email_subscribe
    FROM production.braze.rider_stats_daily_log AS r
    LEFT JOIN production.braze.braze_riders AS s 
        ON r.rider_uuid = s.user_id
    WHERE r.last_run_at::DATE = CURRENT_DATE
),

-- Step 5: Calculate total orders for each driver over different time periods
ORDERS AS (
    SELECT
        DAD.driver_uuid,
        SUM(CASE WHEN DATE >= TO_DATE(DATEADD('day', -196, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))) THEN orders_delivered ELSE 0 END) AS total_orders,
        SUM(CASE WHEN DATE >= TO_DATE(DATEADD('day', -28, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))) THEN orders_delivered ELSE 0 END) AS weeks_0_4,
        LW.last_work_date,
        SUM(CASE WHEN DATE >= TO_DATE(DATEADD('day', -28, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', LW.last_work_date)))) THEN orders_delivered ELSE 0 END) AS last_4w,
        ROUND(SUM(CASE WHEN DATE >= TO_DATE(DATEADD('day', -196, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', LW.last_work_date)))) THEN orders_delivered ELSE 0 END) / 7, 0) AS last_28w_avg
    FROM production.denormalised.driver_accounting_daily DAD
    LEFT JOIN LW 
        ON LW.driver_uuid = DAD.driver_uuid
    WHERE LW.last_work_date >= TO_DATE(DATEADD('day', -196, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
      AND DATE < TO_DATE(DATEADD('day', 1, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
      AND cur_country IN ($country1, $country2)
    GROUP BY 
        DAD.driver_uuid, 
        LW.last_work_date
)

-- Step 6: Final query to get the reactivation targeting list
SELECT 
    Z.driver_id AS Driver_ID, 
    Z.driver_uuid AS Driver_UUID, 
    cur_zone AS Current_Zone, 
    current_oa AS Current_Onboarding_Area, 
    most_common_oa AS Most_Common_OA, 
    O.last_work_date AS Last_Work_Date, 
    total_orders AS Total_Orders, 
    last_4w AS Orders_Last_4W, 
    last_28w_avg AS Orders_28W_Avg
FROM RIDER_ZONE AS Z
LEFT JOIN ORDERS AS O
    ON Z.driver_uuid = O.driver_uuid
LEFT JOIN production.denormalised.denormalised_driver AS DD 
    ON DD.uuid = Z.driver_uuid
LEFT JOIN Braze AS B 
    ON Z.driver_uuid = B.rider_uuid
WHERE weeks_0_4 = 0
  AND total_orders > 0
  AND DD.status NOT IN ('TERMINATED', 'DISABLED', 'LEFT')
  AND B.braze_email_subscribe <> 'unsubscribed'
ORDER BY Z.driver_id

;



































































































