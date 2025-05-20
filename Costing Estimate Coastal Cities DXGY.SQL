-- -- Cost Estimation Coastal Cities DXGY

WITH Weeks AS (
    SELECT
        DATEADD(week, seq4(), '2024-06-17'::DATE) AS week_start_date,
        DATEADD(day, 6, week_start_date) AS week_end_date,
        'Week ' || (seq4() + 1) || ' ' || TO_CHAR(week_start_date, 'DD_MM') AS week_label,
        (seq4() + 1) as week_number 
    FROM TABLE(GENERATOR(ROWCOUNT => 13)) -- 13 weeks from 2024-06-17 to w/e 2024-09-15
),

DriverWeeklyOrders AS (
  SELECT
    w.week_start_date,
    w.week_label,
    w.week_number,
    da.DRIVER_ID,
    da.CLUSTER_NAME,
    COUNT(da.OA_STATUS) AS orders_count
  FROM production.denormalised.denormalised_assignment da
  JOIN Weeks w
    ON da.LOCAL_TIME_OA_CREATED_AT >= w.week_start_date::TIMESTAMP_NTZ 
   AND da.LOCAL_TIME_OA_CREATED_AT < DATEADD(day, 1, w.week_end_date)::TIMESTAMP_NTZ 
  WHERE da.COUNTRY_NAME IN ('UK', 'Ireland')
    AND da.OA_STATUS = 'DELIVERED'
    AND da.DRIVER_ID IS NOT NULL
    AND da.CLUSTER_NAME IN ('MEL-TRB','WSM','DEA','MRG-RMG','DOC','WMT','EXM','CBE','FLM','NWQ','TRU','IOWN','SAU','TAU','NWT-PAI-TQY')
  GROUP BY
    w.week_start_date, w.week_label, w.week_number, da.DRIVER_ID, da.CLUSTER_NAME
),

WeeklyClusterLevelStats AS (
    SELECT
        CLUSTER_NAME,
        week_label,
        week_number,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY orders_count) AS median_orders,
        PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY orders_count) AS p20_orders,
        PERCENTILE_CONT(0.3) WITHIN GROUP (ORDER BY orders_count) AS p30_orders,
        PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY orders_count) AS p40_orders,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY orders_count) AS p75_orders
    FROM DriverWeeklyOrders
    GROUP BY CLUSTER_NAME, week_label, week_number
),

BucketedWeeklyDrivers AS (
  SELECT
    dwo.week_start_date,
    dwo.week_label,
    dwo.week_number,
    dwo.DRIVER_ID,
    dwo.CLUSTER_NAME,
    CASE
      WHEN dwo.orders_count >= 1 AND dwo.orders_count <= 9 THEN '000-009' -- Effective 1-9 due to orders_count >=1 from source
      WHEN dwo.orders_count >= 10 AND dwo.orders_count <= 19 THEN '010-019'
      WHEN dwo.orders_count >= 20 AND dwo.orders_count <= 29 THEN '020-029'
      WHEN dwo.orders_count >= 30 AND dwo.orders_count <= 39 THEN '030-039'
      WHEN dwo.orders_count >= 40 AND dwo.orders_count <= 49 THEN '040-049'
      WHEN dwo.orders_count >= 50 AND dwo.orders_count <= 59 THEN '050-059'
      WHEN dwo.orders_count >= 60 AND dwo.orders_count <= 69 THEN '060-069'
      WHEN dwo.orders_count >= 70 AND dwo.orders_count <= 79 THEN '070-079'
      WHEN dwo.orders_count >= 80 AND dwo.orders_count <= 89 THEN '080-089'
      WHEN dwo.orders_count >= 90 AND dwo.orders_count <= 99 THEN '090-099'
      WHEN dwo.orders_count >= 100 AND dwo.orders_count <= 109 THEN '100-109'
      WHEN dwo.orders_count >= 110 AND dwo.orders_count <= 119 THEN '110-119'
      WHEN dwo.orders_count >= 120 AND dwo.orders_count <= 129 THEN '120-129'
      WHEN dwo.orders_count >= 130 AND dwo.orders_count <= 139 THEN '130-139'
      WHEN dwo.orders_count >= 140 AND dwo.orders_count <= 149 THEN '140-149'
      WHEN dwo.orders_count >= 150 AND dwo.orders_count <= 159 THEN '150-159'
      WHEN dwo.orders_count >= 160 AND dwo.orders_count <= 169 THEN '160-169'
      WHEN dwo.orders_count >= 170 AND dwo.orders_count <= 179 THEN '170-179'
      WHEN dwo.orders_count >= 180 AND dwo.orders_count <= 189 THEN '180-189'
      WHEN dwo.orders_count >= 190 AND dwo.orders_count <= 199 THEN '190-199'
      WHEN dwo.orders_count >= 200 AND dwo.orders_count <= 249 THEN '200-249' 
      WHEN dwo.orders_count >= 250 AND dwo.orders_count <= 299 THEN '250-299' 
      ELSE NULL
    END AS order_bucket
  FROM DriverWeeklyOrders dwo
  WHERE dwo.orders_count >= 1 -- ensures only drivers with orders are bucketed
),

WeeklyDriverCountsPerBucket AS (
  SELECT
    bwd.week_start_date,
    bwd.week_label,
    bwd.week_number,
    bwd.CLUSTER_NAME,
    bwd.order_bucket,
    COUNT(DISTINCT bwd.DRIVER_ID) AS num_drivers
  FROM BucketedWeeklyDrivers bwd
  WHERE bwd.order_bucket IS NOT NULL
  GROUP BY bwd.week_start_date, bwd.week_label, bwd.week_number, bwd.CLUSTER_NAME, bwd.order_bucket
),

PivotedWeeklyData AS (
    SELECT *
    FROM WeeklyDriverCountsPerBucket
    PIVOT (
        SUM(num_drivers)
        FOR order_bucket IN (
            '000-009', '010-019', '020-029', '030-039', '040-049', '050-059', '060-069', '070-079', '080-089', '090-099',
            '100-109', '110-119', '120-129', '130-139', '140-149', '150-159', '160-169', '170-179', '180-189', '190-199',
            '200-249', '250-299'
        )
    ) AS p (week_start_date, week_label, week_number, CLUSTER_NAME, 
            "0", "10", "20", "30", "40", "50", "60", "70", "80", "90",
            "100", "110", "120", "130", "140", "150", "160", "170", "180", "190",
            "200", "250")
),

WeeklyResults AS (
    SELECT
        pwd.CLUSTER_NAME,
        pwd.week_label,
        pwd.week_number,
        wcs.median_orders,
        wcs.p20_orders,
        wcs.p30_orders,
        wcs.p40_orders,
        wcs.p75_orders,
        pwd."0", pwd."10", pwd."20", pwd."30", pwd."40", pwd."50", pwd."60", pwd."70", pwd."80", pwd."90",
        pwd."100", pwd."110", pwd."120", pwd."130", pwd."140", pwd."150", pwd."160", pwd."170", pwd."180", pwd."190",
        pwd."200", pwd."250"
    FROM PivotedWeeklyData pwd
    LEFT JOIN WeeklyClusterLevelStats wcs 
      ON pwd.CLUSTER_NAME = wcs.CLUSTER_NAME 
      AND pwd.week_label = wcs.week_label 
      AND pwd.week_number = wcs.week_number
),

AverageResults AS (
    SELECT
        wr.CLUSTER_NAME,
        'Average' AS week_label,
        9999 AS week_number, -- High number for sorting 'Average' last
        ROUND(AVG(COALESCE(wr.median_orders, 0)), 2) AS median_orders,
        ROUND(AVG(COALESCE(wr.p20_orders, 0)), 2) AS p20_orders,
        ROUND(AVG(COALESCE(wr.p30_orders, 0)), 2) AS p30_orders,
        ROUND(AVG(COALESCE(wr.p40_orders, 0)), 2) AS p40_orders,
        ROUND(AVG(COALESCE(wr.p75_orders, 0)), 2) AS p75_orders,
        ROUND(AVG(COALESCE(wr."0", 0)), 2) AS "0", ROUND(AVG(COALESCE(wr."10", 0)), 2) AS "10", ROUND(AVG(COALESCE(wr."20", 0)), 2) AS "20",
        ROUND(AVG(COALESCE(wr."30", 0)), 2) AS "30", ROUND(AVG(COALESCE(wr."40", 0)), 2) AS "40", ROUND(AVG(COALESCE(wr."50", 0)), 2) AS "50",
        ROUND(AVG(COALESCE(wr."60", 0)), 2) AS "60", ROUND(AVG(COALESCE(wr."70", 0)), 2) AS "70", ROUND(AVG(COALESCE(wr."80", 0)), 2) AS "80",
        ROUND(AVG(COALESCE(wr."90", 0)), 2) AS "90", ROUND(AVG(COALESCE(wr."100", 0)), 2) AS "100", ROUND(AVG(COALESCE(wr."110", 0)), 2) AS "110",
        ROUND(AVG(COALESCE(wr."120", 0)), 2) AS "120", ROUND(AVG(COALESCE(wr."130", 0)), 2) AS "130", ROUND(AVG(COALESCE(wr."140", 0)), 2) AS "140",
        ROUND(AVG(COALESCE(wr."150", 0)), 2) AS "150", ROUND(AVG(COALESCE(wr."160", 0)), 2) AS "160", ROUND(AVG(COALESCE(wr."170", 0)), 2) AS "170",
        ROUND(AVG(COALESCE(wr."180", 0)), 2) AS "180", ROUND(AVG(COALESCE(wr."190", 0)), 2) AS "190", ROUND(AVG(COALESCE(wr."200", 0)), 2) AS "200",
        ROUND(AVG(COALESCE(wr."250", 0)), 2) AS "250"
    FROM WeeklyResults wr
    GROUP BY wr.CLUSTER_NAME
),

CombinedResultsForOrdering AS (
    SELECT
        CLUSTER_NAME,
        week_label,
        week_number, 
        median_orders,
        p20_orders,
        p30_orders,
        p40_orders,
        p75_orders,
        "0", "10", "20", "30", "40", "50", "60", "70", "80", "90",
        "100", "110", "120", "130", "140", "150", "160", "170", "180", "190",
        "200", "250"
    FROM WeeklyResults

    UNION ALL

    SELECT
        CLUSTER_NAME,
        week_label,
        week_number, 
        median_orders,
        p20_orders,
        p30_orders,
        p40_orders,
        p75_orders,
        "0", "10", "20", "30", "40", "50", "60", "70", "80", "90",
        "100", "110", "120", "130", "140", "150", "160", "170", "180", "190",
        "200", "250"
    FROM AverageResults
)

SELECT
    week_label,
    CLUSTER_NAME,
    median_orders,
    p20_orders,
    p30_orders,
    p40_orders,
    p75_orders,
    "0", "10", "20", "30", "40", "50", "60", "70", "80", "90",
    "100", "110", "120", "130", "140", "150", "160", "170", "180", "190",
    "200", "250"
FROM CombinedResultsForOrdering
ORDER BY CLUSTER_NAME, week_number;


