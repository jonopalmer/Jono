SELECT
    driver_accounting_daily.CUR_CITY_DETAILED,
    ( COUNT(distinct CASE WHEN (CASE
           WHEN 'Weekly' IN ('Daily','daily') THEN driver_accounting_daily.growth_accounting_daily_status
           WHEN 'Weekly' IN ('Weekly','weekly intervals') THEN driver_accounting_daily.growth_accounting_weekly_status
           WHEN 'Weekly' IN ('Monthly','monthly intervals') THEN driver_accounting_daily.growth_accounting_monthly_status
          ELSE NULL END) = 'retained' THEN (CASE WHEN 'yes' = 'yes'    
      THEN CAST(driver_accounting_daily.driver_id AS STRING) ELSE CAST(MD5(driver_accounting_daily.driver_id) AS STRING) END) END)  ) + ( COUNT(distinct CASE WHEN (CASE
           WHEN 'Weekly' IN ('Daily','daily') THEN driver_accounting_daily.growth_accounting_daily_status
           WHEN 'Weekly' IN ('Weekly','weekly intervals') THEN driver_accounting_daily.growth_accounting_weekly_status
           WHEN 'Weekly' IN ('Monthly','monthly intervals') THEN driver_accounting_daily.growth_accounting_monthly_status
          ELSE NULL END) = 'new_rider' THEN (CASE WHEN 'yes' = 'yes'  
      THEN CAST(driver_accounting_daily.driver_id AS STRING) ELSE CAST(MD5(driver_accounting_daily.driver_id) AS STRING) END) END)  ) + ( COUNT(distinct CASE WHEN (CASE
           WHEN 'Weekly' IN ('Daily','daily') THEN driver_accounting_daily.growth_accounting_daily_status
           WHEN 'Weekly' IN ('Weekly','weekly intervals') THEN driver_accounting_daily.growth_accounting_weekly_status
           WHEN 'Weekly' IN ('Monthly','monthly intervals') THEN driver_accounting_daily.growth_accounting_monthly_status
          ELSE NULL END) = 'resurrected' THEN (CASE WHEN 'yes' = 'yes'
      THEN CAST(driver_accounting_daily.driver_id AS STRING) ELSE CAST(MD5(driver_accounting_daily.driver_id) AS STRING) END) END)  )   AS FLEET_SIZE
FROM production.denormalised.driver_accounting_daily_with_rlv AS driver_accounting_daily
WHERE ((( driver_accounting_daily.DATE  ) >= ((TO_DATE(DATEADD('day', -7, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_NTZ)))))))) AND ( driver_accounting_daily.DATE  ) < ((TO_DATE(DATEADD('day', 7, DATEADD('day', -7, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_NTZ))))))))))) AND (driver_accounting_daily.CUR_COUNTRY ) IN ('Ireland', 'UK') AND (driver_accounting_daily.DATE ) >= (TO_DATE(TO_TIMESTAMP('2013-02-01')))
GROUP BY 1
ORDER BY
    2 DESC
FETCH NEXT 500 ROWS ONLY
    