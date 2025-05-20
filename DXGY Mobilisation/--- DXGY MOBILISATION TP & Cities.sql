--- DXGY MOBILISATION TP & Cities
WITH CTE AS(

SELECT
    count( distinct driver_id) as driver_count,
    TO_DATE(local_time_oa_created_at) AS date,
    cluster_name,
    CASE WHEN HOUR(local_time_oa_created_at) >= 18
            AND HOUR(local_time_oa_created_at) < 21
            AND DAYOFWEEK(local_time_oa_created_at) = 5
            THEN 'Friday SP'
        WHEN HOUR(local_time_oa_created_at) >= 18
            AND HOUR(local_time_oa_created_at) < 21
            AND DAYOFWEEK(local_time_oa_created_at) = 6
            THEN 'Saturday SP'
        END AS peak,
    COUNT(CASE WHEN oa_status = 'DELIVERED' THEN 1 END) AS oa_delivered

FROM production.denormalised.denormalised_assignment
WHERE TO_DATE(local_time_oa_created_at) > TO_DATE('2024-08-28')
    AND (peak = 'Saturday SP' OR peak = 'Friday SP')
    AND COUNTRY_NAME IN ('Ireland', 'UK')
GROUP BY date, cluster_name, peak
ORDER BY cluster_name, date DESC, peak DESC
),
CTE2 AS(
SELECT
    TO_DATE(START_OF_PERIOD_LOCAL) AS date,
    cluster_name,
    CASE WHEN HOUR(START_OF_PERIOD_LOCAL) >= 18
            AND HOUR(START_OF_PERIOD_LOCAL) < 21
            AND DAYOFWEEK(START_OF_PERIOD_LOCAL) = 5
            THEN 'Friday SP'
        WHEN HOUR(START_OF_PERIOD_LOCAL) >= 18
            AND HOUR(START_OF_PERIOD_LOCAL) < 21
            AND DAYOFWEEK(START_OF_PERIOD_LOCAL) = 6
            THEN 'Saturday SP'
    END AS peak,
    CASE WHEN DAYOFWEEK(START_OF_PERIOD_LOCAL) = 1
            THEN 'Monday'
        WHEN DAYOFWEEK(START_OF_PERIOD_LOCAL) = 2
            THEN 'Tuesday'
        WHEN DAYOFWEEK(START_OF_PERIOD_LOCAL) = 3
            THEN 'Wednesday'
        WHEN DAYOFWEEK(START_OF_PERIOD_LOCAL) = 4
            THEN 'Thursday'
        WHEN DAYOFWEEK(START_OF_PERIOD_LOCAL) = 5
            THEN 'Friday'
        WHEN DAYOFWEEK(START_OF_PERIOD_LOCAL) = 6
            THEN 'Saturday'
        ELSE 'Sunday'
    END AS day,
    SUM(orders_delivered) AS orders_delivered,
    ROUND(COALESCE(SUM(rider_hours_worked_dhw_sum_excl_ghost_and_oos_hours), 0),3) AS Rider_hours,
    ROUND(NULLIF(SUM(orders_delivered), 0) / NULLIF(SUM(rider_hours_worked_dhw_sum_excl_ghost_and_oos_hours), 0),3) AS Throughput,
    ROUND(SUM(v_hat_raw_0day) / NULLIF(SUM(r_star_raw_0day), 0),3) AS throughput_target,
    ROUND(NULLIF(COALESCE(SUM(rider_hours_on_orders_dhw_sum), 0), 0) / NULLIF(COALESCE(SUM(rider_hours_worked_dhw_sum_excl_ghost_and_oos_hours), 0), 0),3) AS utilisation_adjusted,
    ROUND(
    (COALESCE(SUM(rider_hours_worked_dhw_sum_excl_ghost_and_oos_hours), 0)
    - (SUM(potential_orders_from_hidden_rx) + SUM(orders_delivered)) * SUM(r_star_raw_0day) / NULLIF(SUM(v_hat_raw_0day), 0) )
    / ((SUM(potential_orders_from_hidden_rx) + SUM(orders_delivered)) * SUM(r_star_raw_0day) / NULLIF(SUM(v_hat_raw_0day), 0))
    ,3) AS "R vs Retro R",
    ROUND(COALESCE(SUM( SURGE_COST_LOCAL  ), 0) / NULLIF(COALESCE(SUM(RIDER_CPO_DELIVERED_ORDERS ), 0), 0),3) AS Surge_CPO,
    ROUND(COALESCE(SUM( DROP_FEE_COST_NAS_GBP  ), 0) / NULLIF(COALESCE(SUM(RIDER_CPO_DELIVERED_ORDERS ), 0), 0),3) AS Base_CPO,
    AVG(ROUND(NULLIF(SUM(orders_delivered), 0) / NULLIF(SUM(rider_hours_worked_dhw_sum_excl_ghost_and_oos_hours), 0),3)) OVER (PARTITION BY cluster_name) AS avg_throughput


FROM production.aggregate.agg_zone_delivery_metrics_hourly

WHERE START_OF_PERIOD_LOCAL >= DATEADD('week', -5, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
    AND COUNTRY_NAME IN ('Ireland', 'UK')
    AND (peak = 'Saturday SP' OR peak = 'Friday SP')
    AND orders_delivered > 0

GROUP BY date, day, cluster_name, peak    
ORDER BY avg_throughput DESC, cluster_name DESC, date, peak
)

SELECT 
    a.date,
    a.cluster_name,
    a.peak,
    a.day,
    a.orders_delivered,
    a.Rider_hours,
    a.Throughput,
    a.throughput_target,
    a.utilisation_adjusted,
    a."R vs Retro R",
    a.Surge_CPO,
    a.avg_throughput,
    b.driver_count,
    b.oa_delivered,
    a.Base_CPO  

FROM CTE2 a
LEFT JOIN CTE b ON a.cluster_name = b.cluster_name AND a.date = b.date AND a.peak = b.peak
ORDER BY a.cluster_name, a.date DESC, a.peak DESC


;



