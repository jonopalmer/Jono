  ////OVERALL TEMPORARY TABLE////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR REPLACE TEMPORARY TABLE PRIORITY_CITY_METRICS AS (

////Onboarding Efficiency////////////////////////////////////
WITH DME AS (
    SELECT
        COALESCE(driver_marketing_efficiency.city_detailed, bam_v3_pacing.city_detailed) AS CITY_DETAILEDD,
        DATE_TRUNC('week', COALESCE(driver_marketing_efficiency.DATE, bam_v3_pacing."DATE")) AS WEEKDATE,
        COALESCE(
            (SUM(DISTINCT (CAST(FLOOR(COALESCE(driver_marketing_efficiency.applications_application_city, 0) * (1000000 * 1.0)) AS DECIMAL(38, 0)))
                 + (TO_NUMBER(MD5(driver_marketing_efficiency.primary_key), 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX') % 1.0e27)::NUMERIC(38, 0))
                 - SUM(DISTINCT (TO_NUMBER(MD5(driver_marketing_efficiency.primary_key), 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX') % 1.0e27)::NUMERIC(38, 0))
            ) / CAST((1000000 * 1.0) AS DOUBLE PRECISION), 0
        ) AS Organic_Applicants
    FROM PRODUCTION.MARKETING.DRIVER_MARKETING_EFFICIENCY AS driver_marketing_efficiency
    FULL OUTER JOIN production.aggregate.bam_v3_pacing AS bam_v3_pacing
        ON driver_marketing_efficiency.bam_v3_join_key = bam_v3_pacing.join_key
    WHERE 
        COALESCE(driver_marketing_efficiency.DATE, bam_v3_pacing."DATE") >= DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()::TIMESTAMP_NTZ))) - INTERVAL '735 days' AND
        COALESCE(driver_marketing_efficiency.DATE, bam_v3_pacing."DATE") < DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()::TIMESTAMP_NTZ))) + INTERVAL '735 days' AND
        COALESCE(driver_marketing_efficiency.country_name, bam_v3_pacing."COUNTRY") IN ('Ireland', 'UK') AND
        driver_marketing_efficiency.attribution_medium = 'organic'
    GROUP BY DATE_TRUNC('week', COALESCE(driver_marketing_efficiency.DATE, bam_v3_pacing."DATE")), CITY_DETAILEDD
    HAVING
        COALESCE(
            (SUM(DISTINCT (CAST(FLOOR(COALESCE(driver_marketing_efficiency.applications_application_city, 0) * (1000000 * 1.0)) AS DECIMAL(38, 0)))
                 + (TO_NUMBER(MD5(driver_marketing_efficiency.primary_key), 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX') % 1.0e27)::NUMERIC(38, 0))
                 - SUM(DISTINCT (TO_NUMBER(MD5(driver_marketing_efficiency.primary_key), 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX') % 1.0e27)::NUMERIC(38, 0))
            ) / CAST((1000000 * 1.0) AS DOUBLE PRECISION), 0
        ) IS NOT NULL
),
driver_accounting_daily_query AS (
    SELECT
        driver_accounting_daily.CUR_CITY_DETAILED AS CITY_DETAILED,
        DATE_TRUNC('week', driver_accounting_daily.DATE) AS WEEKDATE,
        Organic_Applicants,
        (COUNT(distinct CASE WHEN (CASE
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
    FROM production.denormalised.driver_accounting_daily AS driver_accounting_daily
    JOIN DME ON DME.CITY_DETAILEDD = driver_accounting_daily.CUR_CITY_DETAILED AND DME.WEEKDATE = DATE_TRUNC('week', driver_accounting_daily.DATE)
    WHERE
        driver_accounting_daily.DATE >= DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()::TIMESTAMP_NTZ))) - INTERVAL '735 days' AND
        driver_accounting_daily.DATE < DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CURRENT_TIMESTAMP()::TIMESTAMP_NTZ))) + INTERVAL '735 days' AND
        driver_accounting_daily.CUR_COUNTRY IN ('Ireland', 'UK') AND
        driver_accounting_daily.DATE >= TO_TIMESTAMP('2013-02-01')::DATE
    GROUP BY DATE_TRUNC('week', driver_accounting_daily.DATE), driver_accounting_daily.CUR_CITY_DETAILED, Organic_Applicants
),

Efficiency AS(
SELECT CITY_DETAILED, WEEKDATE, Organic_Applicants, FLEET_SIZE--, Organic_Applicants/NULLIF(FLEET_SIZE,0) AS Efficiency_Ratio
    , AVG(Organic_Applicants) OVER (ORDER BY CITY_DETAILED, WEEKDATE ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS MA5W_ORGANIC
    , AVG(FLEET_SIZE) OVER (ORDER BY CITY_DETAILED, WEEKDATE ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS MA5W_FLEET_SIZE
    , MA5W_ORGANIC/NULLIF(MA5W_FLEET_SIZE,0) AS MA5W_Ratio

FROM driver_accounting_daily_query
ORDER BY CITY_DETAILED, WEEKDATE)
,

////Gives the largest Cluster in the City Detailed////////////////////////////////////////////
ClusterCD AS (
WITH CTE1 AS(
  SELECT z.zone_code, z.cluster_name, c.city_detailed, SUM(z.orders_delivered) OV
  FROM production.reference.city_detailed c
  LEFT JOIN PRODUCTION.AGGREGATE.AGG_ZONE_DELIVERY_METRICS_HOURLY AS z  
  ON c.zone_code = z.zone_code
  WHERE z.country_name IN ('UK','Ireland')
  AND START_OF_PERIOD_LOCAL > TO_TIMESTAMP('2023-07-03')
  GROUP BY 1, 2, 3
  HAVING OV > 0
),
CTE2 AS (
  SELECT DISTINCT CLUSTER_NAME, CITY_DETAILED, SUM(OV) OVER(PARTITION BY CLUSTER_NAME) ClusterOV
  FROM CTE1
),
CTE3 AS (
  SELECT DISTINCT CITY_DETAILED, MAX(ClusterOV) OVER(PARTITION BY CITY_DETAILED) MaxOV
  FROM CTE2
  ORDER BY CITY_DETAILED
)
SELECT a.CITY_DETAILED, b.CLUSTER_NAME, a.MaxOV 
FROM CTE3 a
LEFT JOIN CTE2 b ON a.MaxOV = b.ClusterOV AND a.CITY_DETAILED = b.CITY_DETAILED
ORDER BY 1
),
////////!!!!!!!!!!!!!!!!"RVSRETRORSTAR WITH PEAK/SP/NP & JOIN CITY DETAIL"////////////////////////////////////////////
TEMP0 AS(
SELECT
    A.CLUSTER_NAME, A.CITY_NAME, B.CITY_DETAILED,
    CASE WHEN is_super_peak_hour = True Then 'super peak'
              WHEN is_peak_lunch_hour = True OR is_peak_dinner_hour = TRUE THEN 'peak'
              ELSE 'non-peak' END AS Hour_Type,
    TO_CHAR(DATE_TRUNC('week', START_OF_PERIOD_LOCAL), 'YYYY-MM-DD') AS WEEKDATE,
    SUM(orders_delivered) DELIVERED,
    SUM(potential_orders_from_hidden_rx) Potential,
    SUM(v_hat_raw_0day) / SUM(r_star_raw_0day) Throuput,
    SUM(rider_hours_worked_dhw_sum_excl_ghost_and_oos_hours)Hours_Worked,
    ROUND((((DELIVERED + Potential)/Throuput)-Hours_Worked)/((DELIVERED+Potential)/Throuput),4) AS R_RSTAR    
FROM
    ClusterCD B
LEFT JOIN PRODUCTION.AGGREGATE.ZONE_DELIVERY_METRICS_HOURLY A
ON A.CLUSTER_NAME = B.CLUSTER_NAME
WHERE
    ((( START_OF_PERIOD_LOCAL  ) >= ((DATEADD('day', -735, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_NTZ))))))) 
    AND ( START_OF_PERIOD_LOCAL  ) < ((DATEADD('day', 735, DATEADD('day', -735, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_NTZ))))))))))     
    AND COUNTRY_NAME IN ('UK','Ireland')

    
GROUP BY A.CLUSTER_NAME, A.CITY_NAME, B.CITY_DETAILED, WEEKDATE, Hour_Type
HAVING SUM(orders_delivered) > 0
ORDER BY DELIVERED DESC
),
////////!!!!!!!!!!!!!!!!"PIVOT RVSRETRORSTAR FOR PEAK/SP/NP"////////////////////////////////////////////
TEMP01 AS(
SELECT CLUSTER_NAME, CITY_NAME, CITY_DETAILED, WEEKDATE
    ,"'super peak'"[0][0] SP_Delivered
    ,ROUND("'super peak'"[0][1],3) SP_R_vs_R_Star
    ,"'peak'"[0][0] Peak_Delivered
    ,ROUND("'peak'"[0][1],3) Peak_R_vs_R_Star
    ,"'non-peak'"[0][0] NP_Delivered
    ,ROUND("'non-peak'"[0][1],3) NP_R_vs_R_Star
FROM 
   (SELECT * FROM 
   (
   SELECT CLUSTER_NAME, CITY_NAME, CITY_DETAILED, WEEKDATE, HOUR_TYPE, ARRAY_CONSTRUCT(SUM(DELIVERED),SUM(R_RSTAR))S FROM TEMP0 GROUP BY 1,2,3,4,5)
   PIVOT (ARRAY_AGG(S) FOR HOUR_TYPE IN ('super peak','peak','non-peak')))
   ORDER BY 2,1,3
   ),
////////!!!!!!!!!!!!!!!!"THE METRICS DZMH"////////////////////////////////////////////
TEMP1 as(
SELECT
    ZONE_CODE, CITY_NAME, CLUSTER_NAME,
    TO_CHAR(DATE_TRUNC('week', START_OF_PERIOD_LOCAL), 'YYYY-MM-DD') AS WEEKDATE,
    ROUND(SUM(sum_rsr_not_visible) / (SUM(sum_asap_restaurants) + SUM(sum_rsr_not_visible)),5) AS RSR,
    ROUND(SUM(cnt_rider_assignments),0) AS DELIVERED,
    ROUND(SUM(CNT_B10_UNACCEPTABLE_LATE_5_TO_15) / SUM(CNT_B10_DENOMINATOR) + SUM(CNT_B10_UNACCEPTABLE_LATE_15_PLUS)/ SUM(CNT_B10_DENOMINATOR),4) Lates,
    ROUND(SUM(assignment_time_error_avg_per_order_secs_sum)/60/SUM(time_lost_to_unassignments_secs_cnt),2) ATE,
    ROUND(SUM(rain_orders_cnt) / NULLIF(SUM(orders_delivered),0),4) Rain,
    ROUND(SUM(sum_erat_secs/60.0)/SUM(cnt_erat),1) ERAT,
    ROUND(SUM(rider_hours_on_orders_dhw_sum)/SUM(rider_hours_worked_dhw_sum),4) Utilisation,
    ROUND(SUM(rider_earnings_excl_non_cpo_adjustments_gbp_total)/SUM(rider_hours_worked_dhw_sum),2) Earnings_All,
    SUM(SURGE_COST_GBP)/ SUM(RIDER_CPO_DELIVERED_ORDERS) Surge
FROM
    PRODUCTION.AGGREGATE.ZONE_DELIVERY_METRICS_HOURLY
WHERE
    --START_OF_PERIOD_LOCAL >= TO_TIMESTAMP('2022-10-03')
    --AND START_OF_PERIOD_LOCAL < TO_TIMESTAMP('2023-07-31')
    ((( START_OF_PERIOD_LOCAL  ) >= ((DATEADD('day', -735, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_NTZ))))))) 
    AND ( START_OF_PERIOD_LOCAL  ) < ((DATEADD('day', 735, DATEADD('day', -735, DATE_TRUNC('week', DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'Europe/London', CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_NTZ))))))))))     
    --START_OF_PERIOD_LOCAL >= dateadd(week, -104, current_date)
    --AND START_OF_PERIOD_LOCAL < TO_TIMESTAMP('2023-07-31')
    AND COUNTRY_NAME IN ('UK','Ireland')




    
GROUP BY ZONE_CODE, WEEKDATE, CITY_NAME, CLUSTER_NAME
HAVING DELIVERED > 0
ORDER BY CITY_NAME,WEEKDATE,DELIVERED DESC
),

//////!!!!!!!!!!!!!!!!"Joining DZMH & RvsRetroR with weight for City Detail Split"////////////////////////////////
TEMP3 as(
SELECT x.zone_code, x.CLUSTER_NAME, x.city_name, c.city_detailed, x.WEEKDATE, x.DELIVERED, x.RSR, x.ERAT, x.Utilisation, x.Earnings_All, ROUND(x.Surge,3) AS SURGE, x.ATE, x.Lates, x.Rain
, ROUND(x.DELIVERED/(SUM(x.DELIVERED) OVER(PARTITION BY c.city_detailed, x.WEEKDATE)),4) AS City_Detailed_Split
, ROUND(x.DELIVERED/(SUM(x.DELIVERED) OVER(PARTITION BY x.CLUSTER_NAME, x.WEEKDATE)),4) AS Cluster_Split
, ROUND(SUM(x.DELIVERED) OVER(PARTITION BY c.city_detailed, x.WEEKDATE),0) AS CityDOV
, ROUND(SUM(x.DELIVERED) OVER(PARTITION BY x.CLUSTER_NAME, x.WEEKDATE),0) AS ClusterOV

, (City_Detailed_Split * x.RSR) RSR_X_CDSPLIT
, (City_Detailed_Split * x.ERAT) ERAT_X_CDSPLIT
, (City_Detailed_Split * x.Utilisation) Utilisation_X_CDSPLIT
, (City_Detailed_Split * x.Earnings_All) Earnings_All_X_CDSPLIT
, (City_Detailed_Split * x.Surge) Surge_X_CDSPLIT
, (City_Detailed_Split * x.ATE) ATE_X_CDSPLIT
, (City_Detailed_Split * x.Lates) Lates_X_CDSPLIT
, (City_Detailed_Split * x.Rain) Rain_X_CDSPLIT

FROM production.reference.city_detailed c
FULL JOIN production.AGGREGATE.AGG_ZONE_DELIVERY_METRICS_HOURLY z
ON c.zone_code = z.zone_code
--FULL JOIN TEMP2 y ON c.zone_code = y.zone_code
FULL JOIN TEMP1 x
ON c.zone_code = x.zone_code



WHERE z.country_name IN ('UK','Ireland')
AND z.start_of_period_local = DATEADD(day, -1,DATE_TRUNC('DAY',CURRENT_TIMESTAMP()))
AND z.zone_code <> 'LNTG'
ORDER BY z.city_name, x.WEEKDATE, x.CLUSTER_NAME
),

TEMP4 AS (SELECT ZONE_CODE, CLUSTER_NAME, CITY_NAME, CITY_DETAILED, WEEKDATE, DELIVERED --, RSR, ERAT, UTILISATION, EARNINGS_ALL, SURGE, ATE, LATES, RAIN
    , ROUND(SUM(RSR_X_CDSPLIT) OVER(PARTITION BY city_detailed, WEEKDATE),5) AS RSR
    , ROUND(SUM(ERAT_X_CDSPLIT) OVER(PARTITION BY city_detailed, WEEKDATE),2) AS ERAT
    , ROUND(SUM(Utilisation_X_CDSPLIT) OVER(PARTITION BY city_detailed, WEEKDATE),3) AS Utilisation
    , ROUND(SUM(Earnings_All_X_CDSPLIT) OVER(PARTITION BY city_detailed, WEEKDATE),2) AS Earnings
    , ROUND(SUM(Surge_X_CDSPLIT) OVER(PARTITION BY city_detailed, WEEKDATE),2) AS Surge
    , ROUND(SUM(ATE_X_CDSPLIT) OVER(PARTITION BY city_detailed, WEEKDATE),2) AS ATE
    , ROUND(SUM(Lates_X_CDSPLIT) OVER(PARTITION BY city_detailed, WEEKDATE),3) AS Lates
    , ROUND(SUM(Rain_X_CDSPLIT) OVER(PARTITION BY city_detailed, WEEKDATE),2) AS Rain
    , CityDOV
    
FROM TEMP3 
WHERE DELIVERED > 0
ORDER BY CITY_NAME, WEEKDATE, CLUSTER_NAME, City_Detailed_Split DESC
)
SELECT X.CITY_NAME, X.CITY_DETAILED, X.CLUSTER_NAME, X.WEEKDATE, WEEKOFYEAR(TO_DATE(X.WEEKDATE)) AS WEEKNUM, RSR, ERAT, Utilisation, Earnings, Surge, ATE, Lates, NP_R_vs_R_Star "NP R/R*", Peak_R_vs_R_Star "Peak R/R*", SP_R_vs_R_Star "SP R/R*", Rain, CityDOV, ROUND(MA5W_Ratio,4) AS MARATIO
FROM TEMP01 X
LEFT JOIN TEMP4 Y
ON X.CITY_DETAILED = Y.CITY_DETAILED AND X.WEEKDATE = Y.WEEKDATE
LEFT JOIN Efficiency E ON X.CITY_DETAILED = E.CITY_DETAILED AND X.WEEKDATE = E.WEEKDATE
GROUP BY X.CITY_NAME, X.CITY_DETAILED, X.CLUSTER_NAME, X.WEEKDATE, WEEKNUM, RSR, ERAT, Utilisation, Earnings, Surge, ATE, Lates, Rain, CityDOV, "NP R/R*", "Peak R/R*", "SP R/R*", MA5W_Ratio
ORDER BY X.CITY_NAME, X.CITY_DETAILED, WEEKDATE DESC
)

;
//END OF FIRST TABLE!!!!!!!!!!!!///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////// METRICS DATA//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


SELECT * FROM PRIORITY_CITY_METRICS ORDER BY CITY_NAME, CITY_DETAILED, WEEKDATE DESC
;
WITH Scoring AS(
SELECT 
      PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY RSR) AS UPPER_RSR
      , PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY RSR) AS LOWER_RSR
      , PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY ERAT) AS UPPER_ERAT
      , PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY ERAT) AS LOWER_ERAT
      , PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY UTILISATION) AS UPPER_UTILISATION
      , PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY UTILISATION) AS LOWER_UTILISATION
      , PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY EARNINGS) AS UPPER_EARNINGS
      , PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY EARNINGS) AS LOWER_EARNINGS
      , PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY SURGE) AS UPPER_SURGE
      , PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY SURGE) AS LOWER_SURGE
      , PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY ATE) AS UPPER_ATE
      , PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY ATE) AS LOWER_ATE
      , PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY LATES) AS UPPER_LATES
      , PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY LATES) AS LOWER_LATES
      , PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY "NP R/R*") AS UPPER_NP_RR
      , PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY "NP R/R*") AS LOWER_NP_RR
      , PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY "Peak R/R*") AS UPPER_PEAK_RR
      , PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY "Peak R/R*") AS LOWER_PEAK_RR
      , PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY "SP R/R*") AS UPPER_SP_RR
      , PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY "SP R/R*") AS LOWER_SP_RR


      
FROM PRIORITY_CITY_METRICS) 
--GROUP BY 1,2,3,4,5,6
--ORDER BY CITY_NAME, CITY_DETAILED, WEEKDATE DESC
-- SCORES RSR	1 ERAT	2 UTILISATION	1 EARNINGS	3 SURGE	1.5 ATE	1 LATES 0.5	NP R/R*	2 Peak R/R*	3 SP R/R* 4

SELECT CITY_NAME, City_Detailed, Cluster_Name, WEEKDATE, WEEKNUM,
CASE 
    WHEN RSR >= UPPER_RSR THEN 10 
    WHEN RSR <= LOWER_RSR THEN 0 
    ELSE ((RSR - LOWER_RSR)/(UPPER_RSR - LOWER_RSR)) * 10 
END AS RSR_SCORE,
CASE
    WHEN ERAT >= UPPER_ERAT THEN 20
    WHEN ERAT <= LOWER_ERAT THEN 0
    ELSE ((ERAT - LOWER_ERAT)/(UPPER_ERAT - LOWER_ERAT)) * 20
END AS ERAT_SCORE,
CASE
    WHEN UTILISATION >= UPPER_UTILISATION THEN 10
    WHEN UTILISATION <= LOWER_UTILISATION THEN 0
    ELSE ((UTILISATION - LOWER_UTILISATION)/(UPPER_UTILISATION - LOWER_UTILISATION)) * 10
END AS UTILISATION_SCORE,
CASE
    WHEN EARNINGS >= UPPER_EARNINGS THEN 30
    WHEN EARNINGS <= LOWER_EARNINGS THEN 0
    ELSE ((EARNINGS - LOWER_EARNINGS)/(UPPER_EARNINGS - LOWER_EARNINGS)) * 30
END AS EARNINGS_SCORE,
CASE
    WHEN SURGE >= UPPER_SURGE THEN 15
    WHEN SURGE <= LOWER_SURGE THEN 0
    ELSE ((SURGE - LOWER_SURGE)/(UPPER_SURGE - LOWER_SURGE)) * 15
END AS SURGE_SCORE,
CASE
    WHEN ATE >= UPPER_ATE THEN 10
    WHEN ATE <= LOWER_ATE THEN 0
    ELSE ((ATE - LOWER_ATE)/(UPPER_ATE - LOWER_ATE)) * 10
END AS ATE_SCORE,
CASE
    WHEN LATES >= UPPER_LATES THEN 5
    WHEN LATES <= LOWER_LATES THEN 0
    ELSE ((LATES - LOWER_LATES)/(UPPER_LATES - LOWER_LATES)) * 5
END AS LATES_SCORE,
CASE
    WHEN "NP R/R*" >= UPPER_NP_RR THEN 20
    WHEN "NP R/R*" <= LOWER_NP_RR THEN 0
    ELSE (("NP R/R*" - LOWER_NP_RR)/(UPPER_NP_RR - LOWER_NP_RR)) * 20
END AS NP_RR_SCORE,
CASE
    WHEN "Peak R/R*" >= UPPER_PEAK_RR THEN 30
    WHEN "Peak R/R*" <= LOWER_PEAK_RR THEN 0
    ELSE (("Peak R/R*" - LOWER_PEAK_RR)/(UPPER_PEAK_RR - LOWER_PEAK_RR)) * 30
END AS PEAK_RR_SCORE,
CASE
    WHEN "SP R/R*" >= UPPER_SP_RR THEN 40
    WHEN "SP R/R*" <= LOWER_SP_RR THEN 0
    ELSE (("SP R/R*" - LOWER_SP_RR)/(UPPER_SP_RR - LOWER_SP_RR)) * 40
END AS SP_RR_SCORE,
RSR_SCORE + ERAT_SCORE + UTILISATION_SCORE + EARNINGS_SCORE + SURGE_SCORE + ATE_SCORE + LATES_SCORE + NP_RR_SCORE + PEAK_RR_SCORE + SP_RR_SCORE AS SUM

      
FROM PRIORITY_CITY_METRICS
FULL JOIN Scoring
WHERE WEEKDATE >= '2023-01-01'
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
ORDER BY CITY_NAME, CITY_DETAILED, WEEKDATE DESC
;





SELECT CITY_NAME, City_Detailed, Cluster_Name, WEEKDATE, WEEKNUM, RSR, 
      CASE 
          WHEN RSR >= PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY RSR) THEN 10
          WHEN RSR <= PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY RSR) THEN 0
          ELSE (RSR - PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY RSR))/((PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY RSR) - PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY RSR))*10)
      END AS RSR_SCORE


--PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY RSR) AS percentile_value, PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY RSR) AS percentile_value, PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY ERAT) AS percentile_value
FROM METRICS
GROUP BY 1,2,3,4,5,6


;
