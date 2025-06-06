SELECT DISTINCT
    CM.ZONE_CODE, 
    CAMPAIGN_START_AT_LOCAL, 
    CAMPAIGN_END_AT_LOCAL, 
    AMOUNT_MULTIPLIER - 1 AS AMOUNT_MULTIPLIER, 
    DATE_TRUNC('DAY', CAMPAIGN_START_AT_LOCAL) AS CAMPAIGN_START_AT_LOCAL_DAY,
    REASON,
    DZMH.CLUSTER_NAME
FROM PRODUCTION.DENORMALISED.CAMPAIGN_MANAGER CM
LEFT JOIN production.aggregate.agg_zone_delivery_metrics_hourly DZMH
    ON CM.ZONE_CODE = DZMH.ZONE_CODE

WHERE CM.COUNTRY_NAME IN ('UK', 'Ireland')
    AND TIME(CAMPAIGN_START_AT_LOCAL) BETWEEN TO_TIME('18:00:00') AND TO_TIME('21:00:00')
    AND DAYOFWEEK(CAMPAIGN_START_AT_LOCAL) IN (5, 6)
    AND CAMPAIGN_START_AT_LOCAL >= DATEADD(week, -5, CURRENT_DATE) 
    AND CAMPAIGN_START_AT_LOCAL <= CURRENT_DATE
ORDER BY CAMPAIGN_START_AT_LOCAL_DAY DESC, CM.ZONE_CODE ASC, CAMPAIGN_START_AT_LOCAL ASC;

