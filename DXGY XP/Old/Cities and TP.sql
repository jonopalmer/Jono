/*
SELECT
    city_name,
    NULLIF(SUM(orders_delivered), 0) / NULLIF(SUM(rider_hours_worked_dhw_sum_excl_ghost_and_oos_hours), 0) AS throughput_excl_oos_and_ghost_hours,
    SUM(v_hat_raw_0day) / NULLIF(SUM(r_star_raw_0day), 0) AS throughput_target_0_day,
    NULLIF(COALESCE(SUM(rider_hours_on_orders_dhw_sum), 0), 0) / NULLIF(COALESCE(SUM(rider_hours_worked_dhw_sum_excl_ghost_and_oos_hours), 0), 0) AS utilisation_adjusted,
    (SUM(potential_orders_from_hidden_rx) + SUM(orders_delivered)) * SUM(r_star_raw_0day) / NULLIF(SUM(v_hat_raw_0day), 0) AS retro_r_star_plus_hours_from_potential_orders_1,
    COALESCE(SUM(rider_hours_worked_dhw_sum_excl_ghost_and_oos_hours), 0) AS rider_hours_worked_dhw_excl_oos_and_ghost_hours_sum,
    SUM(orders_delivered) AS orders_delivered
FROM production.aggregate.agg_zone_delivery_metrics_hourly
WHERE START_OF_PERIOD_LOCAL >= DATEADD('day', -35, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
    AND START_OF_PERIOD_LOCAL < DATEADD('day', 35, DATEADD('day', -35, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP())))))
    AND CAST(EXTRACT(HOUR FROM TO_TIMESTAMP_NTZ(START_OF_PERIOD_LOCAL)) AS INT) BETWEEN 18 AND 20
    AND COUNTRY_NAME IN ('Ireland', 'UK')
GROUP BY 1
HAVING throughput_excl_oos_and_ghost_hours IS NOT NULL
ORDER BY 2 DESC
*/
;

SELECT
    TO_DATE(START_OF_PERIOD_LOCAL) AS date,
    city_name,
    CASE WHEN HOUR(START_OF_PERIOD_LOCAL) >= 18
            AND HOUR(START_OF_PERIOD_LOCAL) < 21
            AND DAYOFWEEK(START_OF_PERIOD_LOCAL) = 5
            THEN 'Friday SP'
        WHEN HOUR(START_OF_PERIOD_LOCAL) >= 18
            AND HOUR(START_OF_PERIOD_LOCAL) < 21
            THEN 'Dinner peak'
        WHEN HOUR(START_OF_PERIOD_LOCAL) >= 12
            AND HOUR(START_OF_PERIOD_LOCAL) < 14
            THEN 'Lunch peak'
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
        WHEN DAYOFWEEK(START_OF_PERIOD_LOCAL) = 7
            THEN 'Sunday'
    END AS day,
    SUM(orders_delivered) AS orders_delivered,
    ROUND(NULLIF(SUM(orders_delivered), 0) / NULLIF(SUM(rider_hours_worked_dhw_sum_excl_ghost_and_oos_hours), 0),3) AS Throughput

FROM production.aggregate.agg_zone_delivery_metrics_hourly

WHERE START_OF_PERIOD_LOCAL >= DATEADD('week', -5, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
    AND COUNTRY_NAME IN ('Ireland', 'UK')
    AND (peak = 'Dinner peak' OR peak = 'Lunch peak' OR peak = 'Friday SP')
    AND orders_delivered > 0

GROUP BY date, day, city_name, peak    
ORDER BY city_name DESC, date, peak


;
