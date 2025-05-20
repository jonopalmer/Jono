SELECT
    city_name,
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

    ROUND(COALESCE(SUM( agg_zone_delivery_metrics_hourly.SURGE_COST_LOCAL  ), 0) / NULLIF(COALESCE(SUM(agg_zone_delivery_metrics_hourly.RIDER_CPO_DELIVERED_ORDERS ), 0), 0),3) AS Surge_CPO,
    --AVG(ROUND(NULLIF(SUM(orders_delivered), 0) / NULLIF(SUM(rider_hours_worked_dhw_sum_excl_ghost_and_oos_hours), 0),3)) OVER (PARTITION BY city_name) AS avg_throughput


FROM production.aggregate.agg_zone_delivery_metrics_hourly

WHERE START_OF_PERIOD_LOCAL >= DATEADD('week', -5, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()))))
    AND COUNTRY_NAME IN ('Ireland', 'UK')
    AND DAYOFWEEK(START_OF_PERIOD_LOCAL) BETWEEN 1 AND 5
    AND (HOUR(START_OF_PERIOD_LOCAL) BETWEEN 12 AND 14 OR HOUR(START_OF_PERIOD_LOCAL) BETWEEN 18 AND 21)

    AND orders_delivered > 0

GROUP BY city_name  
ORDER BY throughput DESC, city_name DESC

;
